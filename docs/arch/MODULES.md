# 14 个业务域详细规划

> 配套：[ARCHITECTURE.md](ARCHITECTURE.md) 定分层与规则，本文定每域的**文件归属、接口、状态、依赖、验收**。
> 所有「现有文件」均为实测路径，账本条目继承自 hbxs0571 的 `docs/parity/`。

---

## 通用约束（每域都适用）

| 项 | 规则 |
| --- | --- |
| 目录 | `feature/<域>/{page,view,store,model,sheet}`，无内容不建目录 |
| 单文件 | ≤ 800 行 |
| 单组件 `@State` | ≤ 25 个 |
| 状态 | 域内唯一 `@Observed class XxxStore`，外部通过 `@ObjectLink` 引入 |
| 跨域 | 禁止 import 其他域内部文件；只能走 `domain/usecase` 或 `shared/` |
| 页面 | 只有一个 `page/XxxPage.ets` 作为 NavDestination 入口 |

---

## 1. `feature/reader` — 阅读器

**优先级：P0（最重、状态最多、性能核心）**

| 项 | 内容 |
| --- | --- |
| 现有文件 | `pages/ReaderPage.ets`(9,866 行 / 99 State)、`ReaderSettingsPage`(45)、`ReaderSearchPage`、`ReaderBookmarkEditor`、`ReaderMarkingEditor`、`ReaderTextProcessingSheet`、`ReaderAloudSettingsPage`、`pages/LocalReaderPaginator.ets`、`reader/` 10 文件、`reader/m3/` |
| 状态 | 183 个 → `ReaderStore`（目标 ≤ 25 字段） |
| 账本 | `TXT-READER.md`(316 KB)、`ZIP-BOOKMARK.md`(64 KB)、`READER-CONFIG.md`(203 KB) |

### 目标结构

```
feature/reader/
├── page/ReaderPage.ets          # 组装：Canvas + Chrome + Sheet 宿主，<500 行
├── view/
│   ├── ReaderCanvasView.ets     # 接 ReaderCanvasSurface，只读 store 快照
│   ├── ReaderChromeView.ets     # 顶栏/底栏/进度条
│   ├── ReaderMenuView.ets       # 菜单取色链、翻页键、快捷标注
│   └── ReaderAloudBar.ets       # 朗读条（与 readaloud 域协作）
├── store/ReaderStore.ets        # 唯一域 Store
├── sheet/                       # 目录/设置/搜索/标注编辑器
└── model/                       # 阅读器私有：分页结果、锚点、样式
```

### ReaderStore 字段草案（183 → 22）

| 分组 | 字段 | 来源状态数 |
| --- | --- | --- |
| 书籍会话 | `book` / `chapterTitle` / `chapterIndex` / `pageIndex` / `totalPages` | ~30 |
| 排版参数 | `fontSize` / `lineSpacing` / `paragraphSpacing` / `letterSpacing` / `paragraphIndent` / `textBold` / `textItalic` / `titleMode` | ~22 |
| 渲染态 | `content` / `replaceRules` / `paginationResult` / `renderVersion` | ~20 |
| 交互态 | `menuOpen` / `catalogOpen` / `selectionMode` / `selectedRange` | ~40 |
| 朗读 | `aloudPlaying` / `aloudVoice` / `aloudSpeed` | ~7 |
| 搜索 | `searchQuery` / `searchResults` / `searchNav` | ~10 |
| 其它 | 剩余按需归并 | ~54 |

### 接口契约

```typescript
@Observed
export class ReaderStore {
  get book(): Book;
  get chapterTitle(): string;
  get pageIndex(): number;

  openBook(book: Book, chapter?: string): Promise<void>;
  setChapter(index: number): Promise<void>;
  applyTypography(patch: TypographyPatch): void;
  toggleMenu(): void;
  saveProgress(): void;
}
```

### 验收

- `ReaderPage.ets` < 500 行，`@Prop` 入参 **22 → 1**
- 翻页帧率不低于现状（用现有 `ReaderChapterPageCache` 打点对比）
- 账本 `TXT-READER.md` 已接条目零回退

### 风险

`ReaderTextLayoutEngine.ets`、`ReaderCanvasSurface.ets`(157 KB)、`ReaderPageCurl.ets` 是**性能核心**，重构时**只搬不改**；改动必须单独提交并保留性能打点。

---

## 2. `feature/bookshelf` — 书架

**优先级：P0**

| 项 | 内容 |
| --- | --- |
| 现有 | `BookshelfPage`(55 State)、`BookshelfManagePage`(32)、`BookGroupCard`、`BookCard`、`BookCover`、`data/BookshelfLayoutRepository`、`data/BookGroupRepository`、`data/PrivateAccessRepository` |
| 状态 | 13 个 → `BookshelfStore` |
| 账本 | `BOOKSHELF.md`(250 KB)、`ZIP-BOOKSHELF-LAYOUT.md`(84 KB) |
| 未接 | 智能伴生分组；**指纹解锁**（`PrivateAccessRepository.isPrivateBook` / `requiresPrivateUnlock` 已实现且有调用方，只差解锁入口） |

### 目标结构

```
feature/bookshelf/
├── page/BookshelfPage.ets       # 组装 + 布局切换
├── page/BookshelfManagePage.ets # 分组管理
├── view/BookGrid.ets            # 网格三档（标准/紧凑/仅封面）
├── view/BookList.ets            # 列表档
├── view/GroupHeader.ets
├── store/BookshelfStore.ets
└── model/                       # 布局差异九字段
```

### 验收

- 三档网格 + 列表档视觉不回归
- 分组拖拽、封面冷启、私密书锁定路径可走通

---

## 3. `feature/source` — 书源

**优先级：P0（37 条 F 类是最高 ROI 的接线活）**

| 项 | 内容 |
| --- | --- |
| 现有 | `BookSourceManagePage`、`BookSourceEditPage`、`BookSourceDebugPage`、`SourceLoginPage`、`SourceWebPage`、`bookSource/` 19 文件（含 `SearchResultMerger`、`ChapterDownloadQueue`）、`components/booksource/` 4 文件、`data/BookSourceRepository` |
| 状态 | 6 个 `source*` / `search*` 相关 |
| 引擎 | `third_party/harmony-book-source-engine`(sourceengine + quickjs) **已落地** |
| 账本未接 | **F 类 37 条 = 引擎已落地、缺消费方接线** |

### 关键事实（继承自上游实测）

- 只承诺 **A1/A2 纯 URL 源**，准入实测通过率 **60%**
- **A3/A4/C 类受引擎语法与 `java.*` 桥限制**——这些不是接线能解决的，属 K 类「要扩大工」
- 已落地 12 批（P0–P11）：904 条书源管理、多源并发搜索、在线书入架、缓存优先正文

### 未接明细（KI-BS1–BS6）

书源回调、简介标记渲染、批量换源/下载、在线进度持久化、旧版书源导入

### 验收

- F 类 37 条逐条在 `docs/parity/` 抹格
- 真机联网验证（现状多为模拟器）

---

## 4. `feature/theme` — 主题

**优先级：P1（54 状态，且有两个可突破的「平台无解」）**

| 项 | 内容 |
| --- | --- |
| 现有 | `ThemeSettingsPage`、`ThemeManagePage`、`CustomThemePage`、`ThemeItemDivider`、`ThemeSelectors`、`data/Theme*` 10 文件、`components/UiTokens.ets`、`components/typography/TypographyTokens.ets`、`reader/m3/` |
| 状态 | 54 个 → `ThemeStore`（L1） |
| 账本 | `ZIP-THEME.md`(169 KB)，91 行对照 |

### 两个「平台无解」的突破方案

**A3 Monet 壁纸动态取色** — 上游判死依据是 `@ohos.arkui.theme.d.ts` 无壁纸取色入口（SDK 零命中，取证成立）。但：

```
reader/m3/dynamiccolor/dynamic_scheme.ets   ← M3 HCT 取色算法已移植
```

只要拿到**种子色**就能算全套 `ColorScheme`，不需要系统 API。种子来源三选一：

1. 主题背景图取主色像素（`@ohos.multimedia.image` 读 PixelMap 采样）
2. 用户手选色球
3. 书封主色（工程里已有 `bookCoverColor`）

→ 判定从「平台无解」改为「**可实现，成本 2–3 天**」。

**A7 主题引擎切换（Miuix/Material）** — 判死依据是「SDK 只有一套 ArkUI 控件体系」。但工程已有两层 token 抽象：

```
components/UiTokens.ets                     ← 尺寸/圆角/动效
components/typography/TypographyTokens.ets  ← 字阶
```

套两套 palette + 两套组件尺寸档即双引擎，不需要两套控件。
→ 判定改为「**可实现，成本 3–5 天**」。

### 验收

- 54 状态归 `ThemeStore`，切主题不重启、不整页重渲染
- 14 套调色板 + 自定义配色 + 纯黑 + 背景图 + 容器卡片样式全部不回归

---

## 5. `feature/readaloud` — 朗读 / 有声书

**优先级：P1（G 类 7 条 = 最重的功能缺口）**

| 项 | 内容 |
| --- | --- |
| 现有 | `ReadAloudPlayerPage`、`ReadAloudEnginePage`、`ReadAloudConfigPanel`、`readaloud/` 4 文件、`components/ReadAloudGlassWidgets.ets`、`data/HttpTtsRepository`、`data/ReadAloudSettingsRepository`、`data/ReadAloudVoiceRepository`、`model/HttpTts.ets`、`model/ReadAloudVoice.ets` |
| 现状 | 系统 TTS + HTTP TTS 两条链**已落地**；README 称「有声书未接，只保留 bookType 标记」 |
| 缺口 | **音频书播放器**（本地音频文件播放、章节音频、进度、后台媒体通知） |

### 需要补的

1. `platform/audio/` — 用 `@ohos.multimedia.avplayer` 封播放器
2. `feature/readaloud/page/AudioBookPlayerPage.ets`
3. 媒体通知（`@ohos.multimedia.avsession`）——工程已有 `media-notification` 痕迹
4. `bookType = AUDIO` 的书进入独立播放器而非文本渲染

### 验收

G 类 7 条抹格；后台播放、锁屏控制、耳机按键可验

---

## 6. `feature/profile` — 我的 / 设置群

**优先级：P1（第二大病区，181 状态）**

| 项 | 内容 |
| --- | --- |
| 现有 | `ProfilePage`、`ProfileSubPages.ets`(**396 KB / 181 State**)、`OtherSettingsPage`(27)、`AppBackupSettingsPage`、`AppCoverSettingsPage`(17)、`AppDownloadCacheSettingsPage`、`AppLabSettingsPage`、`AppPrivacySettingsPage`、`AppReadAloudSettingsPage`、`AppTranslationSettingsPage`、`AppAiSettingsPage`、`OnboardingPage`、`PrivacyNoticePage`、`OpenSourceLicensePage` |
| 状态 | 181 → 按设置分组拆成 6 个 Store |

### 拆分方案（181 → 每组 ≤ 30）

| 子模块 | 承接 | 状态估计 |
| --- | --- | --- |
| `settings/general` | `OtherSettingsPage` + 主题入口 | ~30 |
| `settings/backup` | `AppBackupSettingsPage` | ~4 |
| `settings/cover` | `AppCoverSettingsPage` | ~17 |
| `settings/storage` | `AppDownloadCacheSettingsPage` | ~8 |
| `settings/privacy` | `AppPrivacySettingsPage` | ~10 |
| `settings/experimental` | `AppLabSettingsPage` + `AppAiSettingsPage` + `AppTranslationSettingsPage` | ~20 |
| `settings/readaloud` | `AppReadAloudSettingsPage` | ~10 |
| `settings/about` | `Onboarding` / `PrivacyNotice` / `License` | 0（纯静态） |

---

## 7. `feature/backup` — 备份恢复

**优先级：P0（28 类 ZIP 是「还原度」的核心度量）**

| 项 | 内容 |
| --- | --- |
| 现有 | `data/BackupRepository.ets`(**217 KB**)、`data/EpubExporter`、`data/EpubWriter`、`data/ReaderBookmarkExporter`/`Importer`、`data/LocalBookRestorePlanner`、`AppBackupSettingsPage`、`lib/WebDav*.ets` 3 文件 |
| 状态 | 4 个 → `BackupStore` |
| 账本 | `docs/parity/STATUS.md` 28 类：**已接 19 / 部分 5 / 不适用 2**；`docs/BACKUP-RESTORE.md`(54 KB) |

### 结构

```
feature/backup/
├── page/BackupSettingsPage.ets
├── store/BackupStore.ets
├── model/                    # 28 类类别定义、忽略项
└── view/                     # 类别勾选、进度

data/backup/
├── BackupWriter.ets          # 原 BackupRepository 写侧
├── BackupReader.ets          # 读侧（26 处 entry.name 判断）
├── CategoryRegistry.ets      # 28 类登记
└── PassthroughCache.ets      # 透传档（原 legado_backup_passthrough）
```

**217 KB 的 `BackupRepository.ets` 必须拆**：读写分离 + 类别登记独立 + 透传独立。

### 验收

- 28 类逐类读/写/忽略项三列在账本上闭合
- 上游 ZIP → 本地 → 上游往返不丢字段

---

## 8–14. 其余 7 域（简版规划）

| 域 | 现有文件 | 状态 | 关键缺口 | 优先级 |
| --- | --- | --- | --- | --- |
| `bookinfo` | `BookInfoPage`(19)、`BookInfoEditPage`(18)、`BookKnowledgeSheet`、`MarkdownIntro`、`RichIntro` | 5 | 共享元素动画（封面→详情 morph） | P2 |
| `discover` | `DiscoverPage`、`HomepageModuleRepository`、`HomepageCustomSet`、`HomepageModule` | 5 | 首页模块管理声明式化 | P2 |
| `search` | `SearchPage`、`bookSource/SearchResultMerger`、`ReaderSearchHistory` | 5 | 多源并发已接，跨源合并已接 | P2 |
| `subscription` | `SubscriptionPage`、`SubscriptionSubPages`、`RssSource`/`RssStar`/`RuleSub` | 计入 profile | **RSS 拉取未排期**，页面入口仍是占位 | P3 |
| `readrecord` | `ReadRecordOverviewPage`、`ReadRecordHeatmap`、`ReadRecordRepository`、`ReadRecordOverview` | 3 | 章节维度统计、跨午夜持久化、字数采集 | P2 |
| `catalog` | `CatalogPage`、`TxtTocRulePreviewPage`、`data/TocRefreshUseCase` | — | 目录扫描已用 taskpool（51 MB TXT 不触发看门狗） | P2 |
| `import` | `LocalBookImportPage`、`FileManagerPage`、`ArchiveImporter`、`EpubRepository`、`UmdRepository`、`PdfRepository` | — | **智能扫描目录未接**；PDF 6 条待真机验 | P1 |

---

## 附：文件归位总账（现有 → 目标）

| 现有位置 | 文件数 | 目标 | 动作 |
| --- | --- | --- | --- |
| `pages/` | 50 | 分散到 `feature/*/page` + `feature/*/sheet` | 全部迁移，`pages/` 目录删除 |
| `pages/Index.ets` | 1 | `shell/AppShell.ets` + `shell/components/*` | 拆分，675 KB → 多文件 |
| `components/`（平铺 24） | 24 | `shared/ui` | 迁移 |
| `components/settings/` | 9 | `shared/settings` | 迁移 |
| `components/typography` / `motion` / `booksource` | 3 目录 | `shared/typography` / `shared/motion` / `feature/source/view` | 迁移 |
| `data/` | 121 | `data/repository` `data/rdb` `data/file` `data/backup` + `engine/*` | **必须拆分**：仓储留、算法出 |
| `model/` | 25 | `domain/model` | 迁移 |
| `lib/` | 8 | `platform/webdav` `platform/net` + `shared/utils` | 迁移 |
| `reader/` | 10 + `m3/` | `engine/layout` `engine/paginate` + `reader-m3` | 拆分 |
| `bookSource/` | 19 | `feature/source/engine` | 迁移 |
| `readaloud/` | 4 | `feature/readaloud/service` | 迁移 |
| `entryability/` | 1 | `entryability/` + `AppStartGate` | 拆分门禁 |
