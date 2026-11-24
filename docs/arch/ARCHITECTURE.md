# legado-harmonyos 架构重规划

> 版本：v0.1 规划稿 | 基线：`hbxs0571/legado-with-md3-harmonyos` @ v0.1.0 (2026-11-22)
> 本文档只做设计，不含实现。所有数字均来自对 305 个 `.ets` 文件的实测，不是估算。

---

## 0. 为什么必须重规划（实测病灶）

| 病灶 | 实测值 | 后果 |
| --- | --- | --- |
| `pages/Index.ets` 单文件 | **13,104 行 / 675 KB** | 编译慢、无法 review、无法并行开发 |
| `Index.ets` 持有 `@State` | **342 个** | 任一状态变化触发整个主壳 `build()` 重算 |
| 其中属于阅读器的 | 179 个 | 阅读器状态被提升到 App 顶层 |
| 其中属于主题的 | 54 个 | 主题切换导致全 App 重渲染 |
| 其中属于路由栈的 | 8 个（`route` + 7 个 `*ReturnRoute`） | 手写导航栈 |
| `ReaderPage.ets` | 9,866 行 / 99 个 `@State` / 22 个 `@Prop @Watch` | 改字号要穿透 22 层入参链 |
| 全工程 `NavPathStack` 使用 | **0 处** | 无系统路由，靠枚举 + 布尔量拼装 |
| `pages/` 目录职责 | 50 个文件混装页面 / Sheet / Editor / Paginator | 无法按层约束依赖 |
| `data/` 目录职责 | 121 个文件混装仓储 / 引擎 / 扫描器 / Schema | 仓储与算法耦合，无法单测 |

**结论**：现有结构在「功能已实现 85%」的同时，已经到达「再加功能就变慢」的临界点。重规划的目的不是重写，**是把已实现的 11.3 万行搬到能继续长大的骨架上**。

---

## 1. 目标与硬约束

### 1.1 目标（按优先级）

1. **还原度可度量**：以 `docs/parity/` 1226 条账本为唯一口径，从 1040 → 1226，每补一条抹一格。
2. **单文件可维护**：任何 `.ets` **≤ 800 行**，任何组件 `@State` **≤ 25 个**。
3. **可编译可回归**：每次提交都能 `hvigorw assembleHap` 通过，核心链（开书 / 翻页 / 书源搜索）不掉。
4. **可并行开发**：模块间靠接口契约通信，两人同时改不同 feature 域不冲突。

### 1.2 硬约束（技术事实，不可绕）

| 约束 | 内容 | 影响 |
| --- | --- | --- |
| 语言 | **ArkTS 严格模式**：禁止 `any`/`unknown` 自由使用，禁止结构化类型，禁止运行时动态属性 | 不能做 TS 式依赖注入容器，接口必须显式 class/interface |
| SDK | `compatibleSdkVersion: 6.0.0(20)`，API 20 + ArkUI 单套控件体系 | 无 Miuix 双引擎，主题靠 token 层自建 |
| 渲染 | ArkUI 声明式，`@State` 变化触发所在组件 `build()` | 状态必须尽量下沉到叶子 |
| 许可 | GPL-3.0（继承上游 478,804 行 Kotlin 的血统） | fork 必须开源，保留 NOTICE |
| 分发 | 无正式签名链，仅 unsigned HAP | 自建签名流程（本机 HoKit / DevEco） |

---

## 2. 分层架构

### 2.1 四层 + 两横切

```
┌──────────────────────────────────────────────────────────────┐
│  entryability/    Ability 生命周期 / 窗口 / 首启门禁          │
├──────────────────────────────────────────────────────────────┤
│  shell/           主壳：Tab 容器、顶栏、底栏、浮层宿主、路由坑  │
├──────────────────────────────────────────────────────────────┤
│  feature/         14 个业务域，每域自带 page/view/store        │
├──────────────────────────────────────────────────────────────┤
│  domain/          模型 + 用例（纯逻辑，零 UI 依赖，可单测）     │
├──────────────────────────────────────────────────────────────┤
│  data/            仓储 + RDB + 文件 + 迁移                     │
├──────────────────────────────────────────────────────────────┤
│  platform/        系统能力适配（WebDAV/TTS/文件/网络/PDF）     │
└──────────────────────────────────────────────────────────────┘
   横切 1：shared/   UI 原子（UiTokens / Typography / settings 控件 / motion）
   横切 2：engine/   纯算法（排版 / 章节扫描 / EPUB·MOBI 解析 / 净化 / 分页）
```

### 2.2 依赖方向（单向，编译期可查）

```
shell ──▶ feature ──▶ domain ──▶ (无出边)
  │          │           ▲
  │          ▼           │
  └────▶ shared      data ──▶ domain
                       │
                       ▼
                    platform
engine ◀── feature / domain / data（被调用，不反向依赖）
```

**铁律（违反即架构腐化）**：

1. `domain/` **禁止** import `data/`、`platform/`、`feature/`、`@ohos.*` UI 相关。
2. `feature/` **禁止** import 另一个 `feature/` 的内部实现；跨域协作只能走 `domain/` 的用例或 `shared/` 组件。
3. `data/` **禁止** import `feature/`。
4. 任何层**禁止** import `pages/Index.ets`（该类文件将被删除）。
5. `engine/` 保持纯函数，可使用 `@ohos.*` 的**非 UI** 能力（如 `taskpool`、`fileIo`），但不得触碰 `@State`。

### 2.3 目录结构（目标态）

```
entry/src/main/ets/
├── entryability/
│   ├── EntryAbility.ets
│   └── AppStartGate.ets              # 首启门禁（原 Index.ets:247-251）
├── shell/
│   ├── AppShell.ets                  # 原 Index.ets 的主壳部分，目标 <800 行
│   ├── components/
│   │   ├── AppTabBar.ets             # selectedTab 归此
│   │   ├── AppTopBar.ets             # 原 TopBar.ets 迁入
│   │   ├── OverlayHost.ets           # 原 4 个 OVERLAY 状态归此
│   │   └── ShellMetrics.ets
│   └── router/
│       ├── AppRoute.ets              # 保留枚举，转为路由名常量
│       ├── AppRouter.ets             # NavPathStack 封装：push/pop/replace/back
│       ├── RouteTable.ets            # 路由名 → WrappedBuilder 映射
│       └── RouteParam.ets            # 每个路由的参数契约（强类型 class）
├── store/                            # 全局状态（L1）
│   ├── AppStorageKeys.ets            # 所有 AppStorage 键集中声明，禁止散落字符串
│   ├── ThemeStore.ets                # 原 54 个 theme* 状态
│   ├── SettingsStore.ets             # 应用设置聚合
│   └── SessionStore.ets              # 当前书 / 当前章节 / 播放态
├── feature/
│   ├── reader/
│   │   ├── page/ReaderPage.ets       # 只做组装，目标 <500 行
│   │   ├── view/                     # ReaderCanvas / ReaderChrome / ReaderMenu
│   │   ├── store/ReaderStore.ets     # 原 179 个阅读器状态
│   │   ├── sheet/                    # 阅读器各类浮层
│   │   └── model/                    # 阅读器私有模型
│   ├── bookshelf/   ├── bookinfo/   ├── discover/   ├── search/
│   ├── source/      ├── subscription/ ├── profile/  ├── theme/
│   ├── backup/      ├── readaloud/   ├── readrecord/ ├── catalog/
│   └── import/                       # 本地导入
│       └── （每域：page/ view/ store/ model/）
├── domain/
│   ├── model/                        # 原 model/ 25 个文件迁入
│   └── usecase/                      # 跨仓储编排（TocRefreshUseCase 已存在，扩）
├── data/
│   ├── repository/                   # 原 *Repository.ets
│   ├── rdb/                          # RdbSchema.ets + 迁移
│   ├── file/                         # EPUB/MOBI/ZIP 读写
│   └── backup/                       # 原 BackupRepository 拆分
├── engine/                           # 原 data/ 里的算法抽出
│   ├── layout/                       # ReaderTextLayoutEngine / ChineseLineBreaker
│   ├── scan/                         # TxtChapterScanner / LocalTextReSegmenter
│   ├── parse/                        # Epub/Mobi/Umd/Pdf 解析
│   ├── purify/                       # BookContentProcessEngine
│   └── paginate/                     # 分页与页缓存
├── platform/
│   ├── webdav/                       # 原 lib/WebDav*.ets
│   ├── tts/                          # HttpTts / 系统 TTS
│   ├── fs/                           # 文件选择器、目录、归档
│   └── net/                          # 网络探测、代理
├── shared/
│   ├── ui/                           # UiTokens / TopBar / RichIntro / BookCard …
│   ├── settings/                     # 原 components/settings/ 9 个控件
│   ├── typography/                   # TypographyTokens
│   └── motion/                       # CubicBezier
└── reader-m3/                        # 原 reader/m3（M3 dynamic color，独立保留）
```

---

## 3. 状态管理规范（三层模型）

现有 342 个 `@State` 全部平铺在 `Index`，根因是没有状态归属规则。新规则按**生命周期**分三层：

| 层 | 载体 | 适用 | 现有对应 | 目标条数 |
| --- | --- | --- | --- | --- |
| **L1 应用级** | `AppStorage` + `PersistentStorage` | 跨页长期存在、需持久化 | 54 个 `theme*` + 设置类 | ≤ 15 个键 |
| **L2 域级** | `@Observed class` + `@ObjectLink` | 一个业务域内跨组件共享 | 179 个 `reader*` + 书架类 | 每域 1 个 Store |
| **L3 组件级** | `@State` / `@Prop` | 瞬时 UI 状态（展开/悬停/动画进度） | 浮层、动画 | 每组件 ≤ 25 |

### 3.1 判定树（写代码时照这个走）

```
这个状态需要跨页面存活吗？
├─ 是 → 需要持久化吗？
│        ├─ 是 → L1 AppStorage（键必须在 AppStorageKeys.ets 登记）
│        └─ 否 → L2 域 Store（@Observed）
└─ 否 → 只在一个组件内用吗？
         ├─ 是 → L3 @State
         └─ 否 → L2 域 Store
```

### 3.2 L2 域 Store 范式（ArkTS 严格模式下唯一可行写法）

```typescript
// feature/reader/store/ReaderStore.ets
@Observed
export class ReaderStore {
  // 只暴露不可变快照 + 显式方法，禁止外部直接改字段
  private _book: Book = EMPTY_BOOK;
  private _chapterTitle: string = '';
  private _pageIndex: number = 0;
  private _fontSize: number = 24;

  get book(): Book { return this._book; }
  get chapterTitle(): string { return this._chapterTitle; }

  setChapter(book: Book, title: string): void {
    this._book = book;
    this._chapterTitle = title;
    this._pageIndex = 0;
  }
}
```

**关键收益**：`ReaderPage` 现在是 22 个 `@Prop @Watch` 入参，改为 **1 个 `@ObjectLink store: ReaderStore`**。改字号从「穿 22 层」变成「调 1 个方法」。

### 3.3 禁止事项

- ❌ 新增 `@State` 到 `AppShell`（除 Tab 索引与浮层开关）
- ❌ 用 `AppStorage` 存 UI 瞬时状态（如 sheet 是否展开）
- ❌ 跨域直接读写另一个域的 Store 字段（必须走 usecase 或暴露方法）
- ❌ 在 `build()` 里做业务计算

---

## 4. 路由规范（NavPathStack）

### 4.1 现状问题

```typescript
// 现有：手写导航栈
@State route: AppRoute = AppRoute.HOME;
@State readerReturnRoute: AppRoute = AppRoute.BOOKSHELF;   // 7 个这样的
@State bookInfoReturnRoute: AppRoute = AppRoute.BOOKSHELF;
@State catalogReturnRoute: AppRoute = AppRoute.READER;
// … 每加一个页面，要新增一个 returnRoute + 在 3 处维护返回逻辑
```

### 4.2 目标态

用系统 `NavPathStack`，返回栈自动管理：

```typescript
// shell/router/AppRouter.ets
export class AppRouter {
  private static stack: NavPathStack = new NavPathStack();

  static get pathStack(): NavPathStack { return AppRouter.stack; }

  static pushBookInfo(book: Book): void {
    AppRouter.stack.pushPathByName(RouteName.BOOK_INFO, new BookInfoParam(book));
  }

  static pop(): void { AppRouter.stack.pop(); }
}
```

### 4.3 参数契约

每个路由一个参数 class，禁止裸传 `object`（ArkTS 严格模式不允许结构化类型推断）：

```typescript
// shell/router/RouteParam.ets
export class BookInfoParam {
  book: Book;
  constructor(book: Book) { this.book = book; }
}
```

### 4.4 迁移映射（8 个路由状态 → NavPathStack）

| 现有状态 | 新归属 |
| --- | --- |
| `route` | `NavPathStack` 栈顶，删除 |
| `selectedTab` | `AppTabBar` 的 L3 `@State` |
| `readerReturnRoute` | 删除，`stack.pop()` 自动回 |
| `bookInfoReturnRoute` | 删除 |
| `catalogReturnRoute` | 删除 |
| `settingsReturnRoute` | 删除 |
| `searchReturnRoute` | 删除 |
| `profileDetailReturnRoute` / `profileSettingsReturn` | 删除 |

**净减少 8 个顶层状态 + 344 个方法里约 60 个路由方法。**

---

## 5. 模块规划（14 个业务域）

每条给出：**职责 / 现有文件归属 / 对外接口 / 状态归属 / 账本覆盖**。

### 5.1 `feature/reader` — 阅读器（最重，优先重做）

| 项 | 内容 |
| --- | --- |
| 现有文件 | `pages/ReaderPage.ets`(9866)、`ReaderSettingsPage`(45 状态)、`ReaderSearchPage`、`ReaderBookmarkEditor`、`ReaderMarkingEditor`、`ReaderTextProcessingSheet`、`ReaderAloudSettingsPage`、`reader/` 10 文件 + `reader/m3/` |
| 状态 | 179 个 → 1 个 `ReaderStore`（目标 ≤ 25 个字段） |
| 拆分 | `page/` 组装 ｜ `view/ReaderCanvas`(渲染) `view/ReaderChrome`(菜单) `view/ReaderPager`(翻页手势) ｜ `store/` ｜ `sheet/` |
| 对外接口 | `ReaderStore`（`@ObjectLink`）、`ReaderLauncher.open(book, chapter)` |
| 账本 | `TXT-READER.md` 316 KB、`ZIP-BOOKMARK.md` 64 KB、`READER-CONFIG.md` 203 KB |
| 风险 | 排版引擎 `ReaderTextLayoutEngine` + `ReaderCanvasSurface`(157 KB) 是性能核心，重构时**只搬不改** |

### 5.2 `feature/bookshelf` — 书架

| 项 | 内容 |
| --- | --- |
| 现有 | `BookshelfPage`(55 状态)、`BookshelfManagePage`(32)、`CatalogPage`、`BookGroupCard`、`data/BookshelfLayoutRepository` |
| 状态 | 13 个 → `BookshelfStore` |
| 账本 | `BOOKSHELF.md`(250 KB)、`ZIP-BOOKSHELF-LAYOUT.md`(84 KB) |
| 未接 | 智能伴生分组；指纹解锁（`PrivateAccessRepository` 已有，缺调用） |

### 5.3 `feature/source` — 书源（第二重）

| 项 | 内容 |
| --- | --- |
| 现有 | `BookSourceManagePage`、`BookSourceEditPage`、`BookSourceDebugPage`、`SourceLoginPage`、`SourceWebPage`、`bookSource/` 19 文件、`components/booksource/` 4 文件 |
| 状态 | 6 个 `search*` + 书源专属 |
| 引擎 | 依赖 `third_party/harmony-book-source-engine`（QuickJS） |
| 账本未接 | 37 条 F 类 = 引擎已落地缺消费方接线（**最高 ROI 的接线活**） |
| 关键约束 | 只承诺 A1/A2 纯 URL 源（准入实测 60%）；A3/A4/C 受引擎语法与 `java.*` 桥限制 |

### 5.4 `feature/theme` — 主题（54 状态大户）

| 项 | 内容 |
| --- | --- |
| 现有 | `ThemeSettingsPage`、`ThemeManagePage`、`CustomThemePage`、`data/Theme*` 10 文件、`reader/m3/` |
| 状态 | 54 个 → `ThemeStore`（L1 AppStorage + L2 混合） |
| 突破点 | **A3 Monet 取色可做**：`reader/m3/dynamiccolor/dynamic_scheme.ets` 已含 M3 HCT 算法，只需种子色（背景图取主色 / 用户选色） |
| 突破点 | **A7 双引擎可做**：`UiTokens.ets` + `TypographyTokens.ets` 已是两层抽象，套两套 palette 即双引擎 |

### 5.5 其余 10 域（简表）

| 域 | 现有文件 | 状态数 | 备注 |
| --- | --- | --- | --- |
| `bookinfo` | `BookInfoPage`(19)、`BookInfoEditPage`(18) | 5 | 共享元素动画未接 |
| `discover` | `DiscoverPage` | 5 | `exploreUrl` 四种写法已解析 |
| `search` | `SearchPage` | 5 | 多源并发已接 |
| `subscription` | `SubscriptionPage`、`SubscriptionSubPages` | — | RSS 拉取未排期 |
| `profile` | `ProfilePage`、`ProfileSubPages`(**181 状态**)、9 个 `App*SettingsPage` | 181 | **第二大病区**，须先拆 Settings 分组 |
| `backup` | `BackupRepository`(217 KB)、`AppBackupSettingsPage` | 4 | 28 类 ZIP，已接 19 |
| `readaloud` | `ReadAloudPlayerPage`、`ReadAloudEnginePage`、`readaloud/` 4 文件 | — | **G 类 7 条 = 有声书播放器，最重缺口** |
| `readrecord` | `ReadRecordOverviewPage`、`ReadRecordHeatmap` | 3 | 章节维度统计未做 |
| `catalog` | `CatalogPage` | — | — |
| `import` | `LocalBookImportPage`、`FileManagerPage`、`LocalReaderPaginator` | — | 智能扫描目录未接 |

---

## 6. 迁移路线（4 阶段，每阶段可独立验收）

### 阶段 A · 骨架先行（不动业务逻辑）

| 步骤 | 动作 | 验收 |
| --- | --- | --- |
| A1 | 建目录骨架 + `AppStorageKeys` + `RouteName` 常量 | 编译通过，零行为变化 |
| A2 | 引入 `Navigation` + `NavPathStack`，把所有 `push(route)` 换成 `stack.pushPathByName` | 全页面可达，返回键正确 |
| A3 | 删除 8 个路由状态 + 对应方法 | `@State` 342 → 334，编译通过 |
| A4 | `Index.ets` 改名 `AppShell.ets`，抽出 Tab/顶栏/浮层 | 单文件 < 800 行 |

### 阶段 B · 状态下沉（收益最大）

| 步骤 | 动作 | 验收 |
| --- | --- | --- |
| B1 | 建 `ThemeStore`，迁 54 个 `theme*` | `@State` 334 → 280；切主题不重启 |
| B2 | 建 `ReaderStore`，迁 179 个 `reader*` | `@State` 280 → 101；`ReaderPage` 入参 22 → 1 |
| B3 | 拆分 `ReaderPage.ets` 9866 行 → page/view/store/sheet | 每文件 < 800 行，翻页性能不降 |
| B4 | 拆 `ProfileSubPages.ets` 181 状态 | `@State` → < 80 |

### 阶段 C · 层归位（结构治理）

| 步骤 | 动作 | 验收 |
| --- | --- | --- |
| C1 | `data/` 里算法抽到 `engine/` | `data/` 只剩仓储 + RDB + 文件 |
| C2 | `pages/` 里 Sheet/Editor/Paginator 归位到 `feature/*/sheet` | `pages/` 目录消失 |
| C3 | `model/` → `domain/model`，`*UseCase` 归 `domain/usecase` | 依赖方向全绿 |
| C4 | 写 import 边界检查脚本（CI 门禁） | 违反依赖方向即构建失败 |

### 阶段 D · 补 155 条（功能回填，按 ROI）

| 批次 | 内容 | 条数 | 前置 |
| --- | --- | --- | --- |
| D1 | L 类纯本地未做 | 55 | 无 |
| D2 | A 类已验改表 + C 类 PDF 真机验 + D 类取证 | 12 | 真机 |
| D3 | F 类在线书源消费方接线 | 37 | 引擎已有 |
| D4 | E 类原判「不接」退回 | 20 | 无 |
| D5 | I 类数据层 + J 类前置模块 | 18 | 先建表/引擎 |
| D6 | G 类有声书播放器 | 7 | `readaloud` 域重做 |
| D7 | K 类 rar/7z + H 类 AI 范围决策 | 3 | 引三方库 / 决策 |

**阶段 A+B+C 是「把已实现的 1040 条搬进新骨架」，阶段 D 才是「新增功能」。先 A/B/C 再 D，否则 D 的代码会继续堆进旧结构。**

---

## 7. 质量门禁（CI 可执行）

| 检查 | 阈值 | 实现 |
| --- | --- | --- |
| 单文件行数 | ≤ 800 | `wc -l` 脚本 |
| 单组件 `@State` | ≤ 25 | grep 计数 |
| 依赖方向 | 违反即失败 | import 白名单脚本 |
| `any`/`unknown` 裸用 | 0 | grep |
| 账本一致性 | 七表行数与 `parity-rows.py` 一致 | 已有 `docs-check.yml` 扩展 |
| 构建 | `hvigorw assembleHap` 通过 | GitHub Actions |

---

## 8. 本文档与其他文档的关系

| 文档 | 职责 |
| --- | --- |
| **本文（ARCHITECTURE.md）** | 总体架构、分层、依赖规则、迁移阶段 |
| `MODULES.md` | 14 个域的逐域详细规划（接口、状态字段、时序） |
| `ROUTER.md` | 路由表、参数契约、迁移对照 |
| `STATE.md` | 342 状态逐条归属表 |
| `docs/parity/`（继承） | 1226 条还原度账本，**唯一验收口径** |
| `docs/KNOWN-ISSUES.md`（继承） | 409 KB 已知问题，逐条消账 |

---

*生成时间：2026-11-24 | 基于 305 个 .ets 实测 | 设计目标：11.3 万行 ArkTS 迁入可继续生长的骨架*
