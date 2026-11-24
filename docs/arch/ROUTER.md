# 路由设计（NavPathStack 迁移）

> 配套 [ARCHITECTURE.md](ARCHITECTURE.md) 第 4 节。本文给出**完整路由表、参数契约、迁移对照**。

---

## 1. 现状：两套枚举 + 手写栈

实测：

| 项 | 值 |
| --- | --- |
| `AppRoute` 枚举 | **18 个**（`model/Book.ets:194`） |
| `ProfileRoute` 枚举 | **34 个**（`model/Book.ets:217`） |
| `NavPathStack` 使用 | **0 处** |
| 顶层路由 `@State` | `route` + `selectedTab` + 6 个 `*ReturnRoute` |

### 病灶

```typescript
// ProfileRoute 34 个枚举全部由 ProfileSubPages.ets 一个文件承接
// 该文件：396 KB / 181 个 @State
export enum ProfileRoute {
  BOOK_SOURCE_MANAGE, BOOK_SOURCE_EDIT, REPLACE_RULES, REPLACE_RULE_EDIT,
  DICTIONARY_RULE_EDIT, TXT_TOC_RULES, TXT_TOC_RULE_PREVIEW, DICTIONARY_RULES,
  HIGHLIGHT_TAG_RULE_EDIT, HIGHLIGHT_TAG_RULES, AI_CHAT, APP_SETTINGS,
  APP_THEME_SETTINGS, APP_CUSTOM_THEME, APP_THEME_MANAGE, APP_OTHER_SETTINGS,
  APP_READ_SETTINGS, APP_ALOUD_SETTINGS, ALOUD_ENGINE, APP_COVER_SETTINGS,
  APP_DOWNLOAD_CACHE_SETTINGS, APP_BACKUP_SETTINGS, APP_AI_SETTINGS,
  APP_TRANSLATION_SETTINGS, APP_PRIVACY_SETTINGS, APP_LAB_SETTINGS,
  ALL_BOOKMARKS, READ_RECORDS, READ_RECORD_OVERVIEW, CACHE_MANAGEMENT,
  BOOKSHELF_MANAGE, FILE_MANAGER, PRIVACY_NOTICE, OPEN_SOURCE_LICENSE, ABOUT
}
```

一个文件里 if/else 分发 34 个页面 → 181 个状态全挤在一处。

---

## 2. 目标：单一 NavPathStack

```typescript
// shell/router/AppRouter.ets
export class AppRouter {
  private static readonly stack: NavPathStack = new NavPathStack();

  static get pathStack(): NavPathStack { return AppRouter.stack; }

  static push(name: RouteName, param?: Object): void {
    AppRouter.stack.pushPathByName(name, param);
  }

  static pop(): void { AppRouter.stack.pop(); }

  static replace(name: RouteName, param?: Object): void {
    AppRouter.stack.replacePathByName(name, param);
  }

  static clear(): void { AppRouter.stack.clear(); }
}
```

---

## 3. 完整路由表（52 个）

### 3.1 主壳 Tab（不进栈，`AppTabBar` L3 `@State`）

| 原枚举 | 名称 | 承接 |
| --- | --- | --- |
| `HOME` | `home` | `feature/discover/page/HomePage.ets` |
| `BOOKSHELF` | `bookshelf` | `feature/bookshelf/page/BookshelfPage.ets` |
| `DISCOVER` | `discover` | `feature/discover/page/DiscoverPage.ets` |
| `SUBSCRIPTIONS` | `subscriptions` | `feature/discover/page/SubscriptionPage.ets` |
| `PROFILE` | `profile` | `feature/profile/page/ProfilePage.ets` |

### 3.2 阅读链（原 `AppRoute` 剩余 13 个）

| 原枚举 | 新路由名 | 参数契约 | 承接文件 |
| --- | --- | --- | --- |
| `READER` | `reader` | `ReaderParam(bookId, chapterIndex?, pageIndex?)` | `feature/reader/page/ReaderPage.ets` |
| `CATALOG` | `catalog` | `CatalogParam(bookId)` | `feature/catalog/page/CatalogPage.ets` |
| `READER_SETTINGS` | `readerSettings` | `ReaderSettingsParam(bookId)` | `feature/reader/sheet/ReaderSettingsPage.ets` |
| `READER_SEARCH` | `readerSearch` | `ReaderSearchParam(bookId)` | `feature/reader/sheet/ReaderSearchPage.ets` |
| `BOOK_INFO` | `bookInfo` | `BookInfoParam(book)` | `feature/bookinfo/page/BookInfoPage.ets` |
| `BOOK_INFO_EDIT` | `bookInfoEdit` | `BookInfoEditParam(book)` | `feature/bookinfo/page/BookInfoEditPage.ets` |
| `READ_ALOUD_SETTINGS` | `readAloudSettings` | `AloudParam(bookId)` | `feature/readaloud/page/ReadAloudSettingsPage.ets` |
| `SEARCH` | `search` | `SearchParam(query?, group?, scope?)` | `feature/search/page/SearchPage.ets` |
| `LOCAL_BOOK_IMPORT` | `localBookImport` | `ImportParam(candidates)` | `feature/import/page/LocalBookImportPage.ets` |
| `SUBSCRIPTION_RULES` | `subscriptionRules` | — | `feature/discover/page/SubscriptionRulesPage.ets` |
| `SUBSCRIPTION_FAVORITES` | `subscriptionFavorites` | — | `feature/discover/page/SubscriptionFavoritesPage.ets` |
| `SUBSCRIPTION_SOURCE_MANAGE` | `subscriptionSourceManage` | — | `feature/discover/page/SubscriptionSourceManagePage.ets` |
| `PROFILE_SUBPAGE` | **删除** | — | 由 34 个独立路由取代（见 3.3） |

### 3.3 设置群（原 `ProfileRoute` 34 个 → 独立路由）

**关键改造**：`PROFILE_SUBPAGE` 这个「万能分发入口」必须拆开，34 个枚举各走各的 `pushPathByName`。

| 原枚举 | 新路由名 | 目标域 |
| --- | --- | --- |
| `APP_SETTINGS` | `appSettings` | `feature/profile/page/AppSettingsPage.ets` |
| `APP_OTHER_SETTINGS` | `appOtherSettings` | `feature/profile/page/OtherSettingsPage.ets` |
| `APP_READ_SETTINGS` | `appReadSettings` | `feature/reader/sheet/AppReadSettingsPage.ets` |
| `APP_ALOUD_SETTINGS` | `appAloudSettings` | `feature/readaloud/page/AppReadAloudSettingsPage.ets` |
| `ALOUD_ENGINE` | `aloudEngine` | `feature/readaloud/page/ReadAloudEnginePage.ets` |
| `APP_THEME_SETTINGS` | `appThemeSettings` | `feature/theme/page/ThemeSettingsPage.ets` |
| `APP_CUSTOM_THEME` | `appCustomTheme` | `feature/theme/page/CustomThemePage.ets` |
| `APP_THEME_MANAGE` | `appThemeManage` | `feature/theme/page/ThemeManagePage.ets` |
| `APP_COVER_SETTINGS` | `appCoverSettings` | `feature/profile/page/AppCoverSettingsPage.ets` |
| `APP_DOWNLOAD_CACHE_SETTINGS` | `appDownloadCacheSettings` | `feature/profile/page/AppDownloadCacheSettingsPage.ets` |
| `APP_BACKUP_SETTINGS` | `appBackupSettings` | `feature/backup/page/BackupSettingsPage.ets` |
| `APP_AI_SETTINGS` | `appAiSettings` | `feature/profile/page/AppAiSettingsPage.ets` |
| `APP_TRANSLATION_SETTINGS` | `appTranslationSettings` | `feature/profile/page/AppTranslationSettingsPage.ets` |
| `APP_PRIVACY_SETTINGS` | `appPrivacySettings` | `feature/profile/page/AppPrivacySettingsPage.ets` |
| `APP_LAB_SETTINGS` | `appLabSettings` | `feature/profile/page/AppLabSettingsPage.ets` |
| `BOOK_SOURCE_MANAGE` | `bookSourceManage` | `feature/source/page/BookSourceManagePage.ets` |
| `BOOK_SOURCE_EDIT` | `bookSourceEdit` | `feature/source/page/BookSourceEditPage.ets` |
| `REPLACE_RULES` | `replaceRules` | `feature/source/page/ReplaceRulesPage.ets` |
| `REPLACE_RULE_EDIT` | `replaceRuleEdit` | `feature/source/page/ReplaceRuleEditPage.ets` |
| `TXT_TOC_RULES` | `txtTocRules` | `feature/source/page/TxtTocRulesPage.ets` |
| `TXT_TOC_RULE_PREVIEW` | `txtTocRulePreview` | `feature/source/page/TxtTocRulePreviewPage.ets` |
| `DICTIONARY_RULES` | `dictionaryRules` | `feature/source/page/DictionaryRulesPage.ets` |
| `DICTIONARY_RULE_EDIT` | `dictionaryRuleEdit` | `feature/source/page/DictionaryRuleEditPage.ets` |
| `HIGHLIGHT_TAG_RULES` | `highlightTagRules` | `feature/source/page/HighlightTagRulesPage.ets` |
| `HIGHLIGHT_TAG_RULE_EDIT` | `highlightTagRuleEdit` | `feature/source/page/HighlightTagRuleEditPage.ets` |
| `ALL_BOOKMARKS` | `allBookmarks` | `feature/reader/page/AllBookmarksPage.ets` |
| `READ_RECORDS` | `readRecords` | `feature/readrecord/page/ReadRecordsPage.ets` |
| `READ_RECORD_OVERVIEW` | `readRecordOverview` | `feature/readrecord/page/ReadRecordOverviewPage.ets` |
| `CACHE_MANAGEMENT` | `cacheManagement` | `feature/profile/page/CacheManagementPage.ets` |
| `BOOKSHELF_MANAGE` | `bookshelfManage` | `feature/bookshelf/page/BookshelfManagePage.ets` |
| `FILE_MANAGER` | `fileManager` | `feature/import/page/FileManagerPage.ets` |
| `AI_CHAT` | `aiChat` | `feature/profile/page/AiChatPage.ets`（范围待决策） |
| `PRIVACY_NOTICE` | `privacyNotice` | `feature/profile/page/PrivacyNoticePage.ets` |
| `OPEN_SOURCE_LICENSE` | `openSourceLicense` | `feature/profile/page/OpenSourceLicensePage.ets` |
| `ABOUT` | `about` | `feature/profile/page/AboutPage.ets` |

---

## 4. 参数契约基类

ArkTS 严格模式禁止结构化类型，所有参数必须是显式 class：

```typescript
// shell/router/RouteParam.ets
export class ReaderParam {
  bookId: string;
  chapterIndex: number;
  pageIndex: number;
  constructor(bookId: string, chapterIndex: number = 0, pageIndex: number = 0) {
    this.bookId = bookId;
    this.chapterIndex = chapterIndex;
    this.pageIndex = pageIndex;
  }
}

export class BookInfoParam {
  book: Book;
  constructor(book: Book) { this.book = book; }
}
```

### 返回结果（替代 `*ReturnRoute`）

用 `NavPathStack.pushPathByName(name, param, onPop)` 的回调拿返回值：

```typescript
AppRouter.pathStack.pushPathByName(
  RouteName.BOOK_SOURCE_EDIT,
  new BookSourceEditParam(source),
  (info: NavPathInfo) => {
    const result: BookSourceEditResult = info.param as BookSourceEditResult;
    this.onSourceEdited(result);
  }
);
```

---

## 5. 迁移对照（8 个路由状态 → 0 个）

| 现有 `@State` | 迁移方式 | 删除后由谁负责 |
| --- | --- | --- |
| `route: AppRoute` | 删除 | `NavPathStack` 栈顶 |
| `selectedTab: number` | 保留但下沉 | `AppTabBar` 的 L3 `@State` |
| `readerReturnRoute` | 删除 | `stack.pop()` |
| `bookInfoReturnRoute` | 删除 | `stack.pop()` |
| `catalogReturnRoute` | 删除 | `stack.pop()` |
| `settingsReturnRoute` | 删除 | `stack.pop()` |
| `searchReturnRoute` | 删除 | `stack.pop()` |
| `profileDetailReturnRoute` | 删除 | `stack.pop()` |
| `profileSettingsReturn` | 删除 | `stack.pop()` |
| `readerControlsOpenOnReturn` | 删除 | `ReaderStore.menuOpen` |

**净效果**：顶层 `@State` −8，`Index.ets` 里约 **60 个路由方法**删除。

---

## 6. 实施顺序（A2 步骤展开）

1. 建 `shell/router/` 四个文件（`AppRoute` 转 `RouteName`、`AppRouter`、`RouteTable`、`RouteParam`）
2. `AppShell` 外层包 `Navigation(AppRouter.pathStack)`，`.navDestination(RouteTable.builder)`
3. 每次只迁一条路由：把 `@State route = X` 的切换点换成 `AppRouter.push(RouteName.X)`，编译验证，提交
4. 迁完 52 条后删 `AppRoute` / `ProfileRoute` 枚举与全部 `*ReturnRoute`
5. `ProfileSubPages.ets` 按 34 条拆成独立文件（最后做，因为它最大）

### 验收

- 所有页面可达、返回键行为与现状一致
- 深链/返回栈顺序正确
- `Index.ets` 中 `AppRoute` 引用归零
