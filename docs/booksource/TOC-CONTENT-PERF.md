# 目录与正文加载性能：实测结论与对齐上游的修法

日期：2026-11-28　　对应书源链路：搜索 → 详情 → 目录 → 正文

## 一、先把「慢」量出来，别猜

用引擎自带的规则解析器跑真机同款页面（992 章的目录页 82 KB，真书源规则）——
脚本 `third_party/harmony-book-source-engine/scripts/toc-perf-probe.mjs`：

| 环节 | 耗时（桌面 Node，真机约 2~5 倍） |
| --- | --- |
| `getElements(chapterList)` | 9 ms |
| 992 章逐条取 name/url（每条 new 一个 AnalyzeRule） | 49 ms |
| 同上但复用单实例 + setContent（上游做法） | 36 ms |

结论：**解析根本不是瓶颈**，整本 992 章解析不到 100 ms。上游那套「复用 AnalyzeRule + 预切规则」
只值 13 ms，不值得为此改结构。

同一页面从本机直连源站：`ttfb 0.48 s`、`total 1.8~6.4 s`（同一 URL 两次差异巨大，是源站侧的拖延）。
真机 app.log 的实测值：

```
[Toc] start source=⚡📂鬼吹灯 url=http://www.gdbzkz.la/jianke/
[Toc] ok count=992 ms=1317        # 目录：1.3 s，全是网络
[Content] ok len=6921 ms=1388      # 正文：1.4 s，全是网络
```

所以「慢」的成因是 **每次都重新联网抓一遍**，不是解析、不是写库。

## 二、上游是怎么做的（Android 侧实证）

| 环节 | 上游实现 | 证据 |
| --- | --- | --- |
| 目录来源 | **读库**，Room 同步 DAO 直读 `bookChapterDao` | `ReadBookViewModel.kt:226-283`（成功后 `delByBook` + `insert`） |
| 重抓时机 | `ReadBook.upToc()`：`now - book.lastCheckTime < 600000` 直接 return，且 `chapterSize - durChapterIndex - 1 >= 3` 也 return | `ReadBook.kt:1098-1130` |
| 换列表条件 | 只有 `cList.size > chapterSize` 才整表替换 | 同上 |
| 正文净化 | `HtmlFormatter.formatKeepImg(content, redirectUrl)` + `unescapeHtml4` | `BookContent.kt:242-262` |
| 全书替换 | `replaceRegex` 作用在拼接后的正文上，先逐行 trim | `BookContent.kt:174-181` |

## 三、本地原来的三处偏差（都是「不慢但对不上上游」或「真的慢」）

### 1. 在线目录不落库、每次打开都重抓（主因）

`BookRepository.loadChapters` 的在线分支原来只有一条路：`provider.getChapterList(book)` → 网络。
拉回来的章节只进内存缓存 `chapterCache`，**不进 chapters 表**。
取库验证（`hap-build/legado.db`）：

```
books: 间客 totalChapterNum=992 lastCheckTime=0
chapters: 只有本地 TXT 的 2 行，间客 0 行
```

即：整本目录抓了 992 章、只留了个计数，下次打开重来。打开阅读器时 `ReaderPage:2095` 也调它，
于是「读一章」被一笔 1.3 s 的目录请求挡住——正文慢有一半是这个。

### 2. 目录页每行重建整本标题数组（卡顿主因）

`CatalogPage.isCurrentChapter` → `this.book.chapterIndex ?? this.getAllChapters().indexOf(...)`，
而 `getAllChapters()` 每次都 `push` 出一个 992 条的新数组。它被**每个渲染行**调用一次，
滚动时等于每帧拷几千个字符串 + `indexOf` 线性扫，GC 抖动就是「滑动卡」。

### 3. 正文没过 HtmlFormatter

`getContent` 直接把 `getStringList(content)` 拼起来返回。`@html` 取正文的源（本机这个源就是
`id.content@html`）会把 `<div id="content" class="showtxt">`、`<br />`、`&nbsp;` 原样交给阅读器，
真机截图里满屏标签，分页数从 9 页涨到 19 页——排版变慢也是它。

## 四、改法（都按上游结构落）

| 文件 | 改动 |
| --- | --- |
| `data/BookRepository.ets` | `loadChapters` 拆成外层去重 + `loadChaptersInner`：在线书**先读 chapters 表**，有就直接返回；没有才联网，抓到后 `saveChapters` 落库 + `touchTocMeta` 回写 `totalChapterNum/lastCheckTime/latestChapterTitle` |
| 同上 | `chapterLoads`（bookUrl → Promise）合并同书并发加载，对应上游 `WebBook.chapterListJobs` |
| 同上 | `saveChapters` 改多行 `INSERT OR REPLACE`（每批 50 行、900 个绑定值）。**不能用 `store.batchInsert`**：它按 ValuesBucket 的键拼 SQL 且不加反引号，chapters 有列叫 `index`（SQLite 关键字）→ 语句准备失败，hilog 报 `BatchInsert:statement is nullptr, table:chapters`，且**不抛异常**，1992 行全丢 |
| `pages/CatalogPage.ets` | 当前章下标缓存成 `resolvedChapterIndex`，一行只算一次；`共 N 章` 直接用 `chapterRows.length` |
| 同上 | `refreshTocInBackground`：目录先用库里的即时显示，`TocRefreshUseCase.needsCheck`（10 分钟门）成立时才后台刷新，章数变了才换列表 |
| `bookSource/HtmlFormatter.ets` | 新增，移植上游 `utils/HtmlFormatter.kt`（`format` / `formatKeepImg` / 实体反转义） |
| `bookSource/WebBookService.ets` | `getContent` 每页过 `formatKeepImg` + `unescapeHtml`；收尾按 `replaceRegex` 做全书替换 |
| `bookSource/OnlineBookService.ets` | 缓存读写统一走 `writeCacheFile`；读到旧版本落盘的未净化 HTML 时**自愈**并回写 |
| `lib/AppLog.ets` | 落盘改 `fileIo.writeSync(fd, string)`。原来走 `TextEncoder().encodeInto()`，实测一个字节都写不进去，app.log 长期 0 字节 |
| `entryability/EntryAbility.ets` | `onCreate` 打一行 `[Boot]` 自检，日志链路不通能立刻看出来 |

## 五、改完的实测（同一台真机，`hap-build/app.log`）

```
# 首次打开（库里没有目录）
[Toc] start source=棉花小说（优） url=http://www.mianhuatang8.net/4_4073/
[Toc] ok count=1295 ms=1333
[Content] ok len=6921 ms=1388

# 重启后再打开同一本（目录已在库里）
[Boot] onCreate filesDir=/data/storage/el2/base/haps/entry/files
[Content] ok len=7353 ms=1532        # 没有 [Toc] 行 = 一次网络都没发
```

取库核对：`chapters: http://www.mianhuatang8.net/4_4073/ → 1295 行`，`lastCheckTime` 已写。
正文同章页数：19 页（带 HTML）→ 9 页（净化后）。

## 六、还没做的

| 项 | 说明 |
| --- | --- |
| 连接复用 | 引擎 `HttpClient` 每次 `http.createHttp()` 后 `destroy()`，没有 keep-alive；本机实测同站 `conn=0.25 s`，每请求都要重付一次。改动在 `third_party` 里，风险中等，单独一批做 |
| 首开仍需一次网络 | 与上游一致（上游加书时就抓目录）。若要更早，可在「加入书架」时预抓并落库 |
| 规则预切 | 上游 `splitSourceRule` 只省 13 ms/992 章，不做 |

