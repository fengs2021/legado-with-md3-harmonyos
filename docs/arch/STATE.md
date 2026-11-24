# 342 个 @State 逐条归属表

> 由 `scripts/gen-state-plan.py` 生成，勿手工编辑。源 `pages/Index.ets`
> 改规则请改脚本再重新生成，不要直接编辑本表。

实测匹配总数：**335 个**

## 分派汇总

| 处置 | 条数 |
| --- | --- |
| 下沉-L2 | 183 |
| 下沉-L1 | 54 |
| 归位 | 51 |
| 留壳 | 36 |
| 删除-路由 | 8 |
| 留壳-L3 | 3 |

## 目标归属汇总

| 目标位置 | 条数 |
| --- | --- |
| `feature/reader` | 183 |
| `store/ThemeStore` | 54 |
| `shell/AppShell` | 36 |
| `feature/bookshelf` | 19 |
| `feature/source` | 10 |
| `shell/router` | 8 |
| `feature/backup` | 8 |
| `feature/profile` | 5 |
| `feature/discover` | 5 |
| `feature/search` | 4 |
| `shell/components/OverlayHost` | 3 |

## 逐条明细

| 行号 | 状态名 | 处置 | 目标 | 备注 |
| --- | --- | --- | --- | --- |
| 245 | `appBottomInset` | 归位 | `feature/profile` | SettingsStore |
| 247 | `showAppStartGate` | 留壳-L3 | `shell/components/OverlayHost` | 组件级 @State |
| 249 | `privateReady` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 250 | `appStartPassword` | 归位 | `feature/profile` | SettingsStore |
| 251 | `appStartPasswordError` | 归位 | `feature/profile` | SettingsStore |
| 254 | `route` | 删除-路由 | `shell/router` | NavPathStack / AppTabBar L3 |
| 255 | `readerReturnRoute` | 删除-路由 | `shell/router` | NavPathStack 自动管理返回栈 |
| 256 | `bookInfoReturnRoute` | 删除-路由 | `shell/router` | NavPathStack 自动管理返回栈 |
| 257 | `catalogReturnRoute` | 删除-路由 | `shell/router` | NavPathStack 自动管理返回栈 |
| 258 | `readerControlsOpenOnReturn` | 下沉-L2 | `feature/reader` | ReaderStore |
| 259 | `settingsReturnRoute` | 删除-路由 | `shell/router` | NavPathStack 自动管理返回栈 |
| 260 | `readerSettingsOpenBottomActionConfig` | 下沉-L2 | `feature/reader` | ReaderStore |
| 261 | `searchReturnRoute` | 删除-路由 | `shell/router` | NavPathStack 自动管理返回栈 |
| 262 | `searchPageQuery` | 归位 | `feature/search` | SearchStore |
| 264 | `readerSearchQuery` | 下沉-L2 | `feature/reader` | ReaderStore |
| 265 | `searchPageGroup` | 归位 | `feature/search` | SearchStore |
| 266 | `searchPageSourceScope` | 归位 | `feature/search` | SearchStore |
| 267 | `searchPageExactMatch` | 归位 | `feature/search` | SearchStore |
| 268 | `profileDetailReturnRoute` | 删除-路由 | `shell/router` | NavPathStack 自动管理返回栈 |
| 269 | `profileSubpage` | 归位 | `feature/profile` | SettingsStore |
| 270 | `profileSettingsReturn` | 归位 | `feature/profile` | SettingsStore |
| 272 | `bookshelfManageGroupName` | 归位 | `feature/bookshelf` | BookshelfStore |
| 274 | `localBookImportCandidates` | 归位 | `feature/bookshelf` | BookshelfStore |
| 276 | `localBookArchiveUri` | 归位 | `feature/bookshelf` | BookshelfStore |
| 277 | `localBookArchiveTitle` | 归位 | `feature/bookshelf` | BookshelfStore |
| 278 | `selectedTab` | 删除-路由 | `shell/router` | NavPathStack / AppTabBar L3 |
| 279 | `selectedBook` | 归位 | `feature/bookshelf` | BookshelfStore |
| 281 | `changeSourceBook` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 283 | `batchChangeSourceBooks` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 285 | `loginSourceUrl` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 290 | `loginSheetVisible` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 292 | `debugSourceUrl` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 294 | `sourceWebUrl` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 295 | `readerStartAtChapterBeginning` | 下沉-L2 | `feature/reader` | ReaderStore |
| 296 | `selectedChapter` | 下沉-L2 | `feature/reader` | ReaderStore |
| 297 | `books` | 归位 | `feature/bookshelf` | BookshelfStore |
| 303 | `notShelfBooks` | 归位 | `feature/bookshelf` | BookshelfStore |
| 305 | `refreshingBookIds` | 归位 | `feature/bookshelf` | BookshelfStore |
| 306 | `bookGroups` | 归位 | `feature/bookshelf` | BookshelfStore |
| 308 | `bookshelfLayout` | 归位 | `feature/bookshelf` | BookshelfStore |
| 310 | `coverSettings` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 311 | `readTimeRecords` | 下沉-L2 | `feature/reader` | ReaderStore |
| 312 | `readRecordDetails` | 下沉-L2 | `feature/reader` | ReaderStore |
| 313 | `readRecordSummaries` | 下沉-L2 | `feature/reader` | ReaderStore |
| 314 | `readerBookmarks` | 下沉-L2 | `feature/reader` | ReaderStore |
| 315 | `readerMarkings` | 下沉-L2 | `feature/reader` | ReaderStore |
| 317 | `bookmarkSortDescending` | 归位 | `feature/bookshelf` | BookshelfStore |
| 318 | `replaceRules` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 320 | `txtTocRules` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 322 | `highlightTagRules` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 324 | `bookInfoDeleteAlert` | 归位 | `feature/bookshelf` | BookshelfStore |
| 326 | `editingReplaceRule` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 328 | `replaceRuleSeed` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 330 | `editingBookSource` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 332 | `replaceRuleSortMode` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 333 | `replaceEnableDefault` | 归位 | `feature/source` | SourceStore / 对应页 L3 |
| 334 | `readerReplaceEnabled` | 下沉-L2 | `feature/reader` | ReaderStore |
| 335 | `readerReplaceUsesDefault` | 下沉-L2 | `feature/reader` | ReaderStore |
| 336 | `bookmarkEditor` | 归位 | `feature/bookshelf` | BookshelfStore |
| 337 | `bookmarkEditorIsNew` | 归位 | `feature/bookshelf` | BookshelfStore |
| 338 | `markingEditor` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 339 | `markingEditorIsNew` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 340 | `readerBookmarkTargetPosition` | 下沉-L2 | `feature/reader` | ReaderStore |
| 341 | `readerBookmarkTargetRevision` | 下沉-L2 | `feature/reader` | ReaderStore |
| 346 | `readerSearchNavItems` | 下沉-L2 | `feature/reader` | ReaderStore |
| 347 | `readerSearchNavIndex` | 下沉-L2 | `feature/reader` | ReaderStore |
| 349 | `pendingBookmarkTarget` | 下沉-L2 | `feature/reader` | ReaderStore |
| 350 | `readerContent` | 下沉-L2 | `feature/reader` | ReaderStore |
| 352 | `chapterLoading` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 359 | `readerAdjacentChapterPayload` | 下沉-L2 | `feature/reader` | ReaderStore |
| 365 | `readerFontSize` | 下沉-L2 | `feature/reader` | ReaderStore |
| 366 | `readerParagraphSpacing` | 下沉-L2 | `feature/reader` | ReaderStore |
| 367 | `readerLineSpacing` | 下沉-L2 | `feature/reader` | ReaderStore |
| 368 | `readerLetterSpacing` | 下沉-L2 | `feature/reader` | ReaderStore |
| 369 | `readerParagraphIndent` | 下沉-L2 | `feature/reader` | ReaderStore |
| 370 | `readerTextFont` | 下沉-L2 | `feature/reader` | ReaderStore |
| 371 | `readerTitleFont` | 下沉-L2 | `feature/reader` | ReaderStore |
| 372 | `readerSystemTypefaces` | 下沉-L2 | `feature/reader` | ReaderStore |
| 373 | `readerTextItalic` | 下沉-L2 | `feature/reader` | ReaderStore |
| 374 | `readerTextBold` | 下沉-L2 | `feature/reader` | ReaderStore |
| 375 | `readerTextShadow` | 下沉-L2 | `feature/reader` | ReaderStore |
| 376 | `readerShadowRadius` | 下沉-L2 | `feature/reader` | ReaderStore |
| 377 | `readerShadowDx` | 下沉-L2 | `feature/reader` | ReaderStore |
| 378 | `readerShadowDy` | 下沉-L2 | `feature/reader` | ReaderStore |
| 379 | `readerTextShadowColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 380 | `readerTextShadowColorN` | 下沉-L2 | `feature/reader` | ReaderStore |
| 381 | `readerUnderline` | 下沉-L2 | `feature/reader` | ReaderStore |
| 382 | `readerDottedLine` | 下沉-L2 | `feature/reader` | ReaderStore |
| 383 | `readerUnderlineColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 384 | `readerUnderlineColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 385 | `readerUnderlineHeight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 386 | `readerUnderlinePadding` | 下沉-L2 | `feature/reader` | ReaderStore |
| 387 | `readerUnderlineExtend` | 下沉-L2 | `feature/reader` | ReaderStore |
| 388 | `readerDottedBase` | 下沉-L2 | `feature/reader` | ReaderStore |
| 389 | `readerDottedRatio` | 下沉-L2 | `feature/reader` | ReaderStore |
| 390 | `readerTextFullJustify` | 下沉-L2 | `feature/reader` | ReaderStore |
| 391 | `readerTextBottomJustify` | 下沉-L2 | `feature/reader` | ReaderStore |
| 392 | `paperIndex` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 393 | `dayPaperIndex` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 394 | `nightPaperIndex` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 399 | `backgroundStyles` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 407 | `readerNightMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 408 | `shareReaderStyleLayout` | 下沉-L2 | `feature/reader` | ReaderStore |
| 409 | `showReaderBottomActionText` | 下沉-L2 | `feature/reader` | ReaderStore |
| 410 | `readerBottomIconStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 411 | `readerBottomItemsPerRow` | 下沉-L2 | `feature/reader` | ReaderStore |
| 412 | `readerBottomRowCount` | 下沉-L2 | `feature/reader` | ReaderStore |
| 413 | `readerBottomActions` | 下沉-L2 | `feature/reader` | ReaderStore |
| 416 | `readerTopActions` | 下沉-L2 | `feature/reader` | ReaderStore |
| 419 | `readerMoreActions` | 下沉-L2 | `feature/reader` | ReaderStore |
| 427 | `readerReadMenuLensRadius` | 下沉-L2 | `feature/reader` | ReaderStore |
| 433 | `readerReadBarStyleFollowPage` | 下沉-L2 | `feature/reader` | ReaderStore |
| 438 | `readerShowMenuIcon` | 下沉-L2 | `feature/reader` | ReaderStore |
| 443 | `readerShowReadTitleAddition` | 下沉-L2 | `feature/reader` | ReaderStore |
| 445 | `readerMenuAlpha` | 下沉-L2 | `feature/reader` | ReaderStore |
| 446 | `readerProgressBehavior` | 下沉-L2 | `feature/reader` | ReaderStore |
| 447 | `readerReadSliderMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 448 | `readerPageTouchSlop` | 下沉-L2 | `feature/reader` | ReaderStore |
| 450 | `readerLastMarkingStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 451 | `readerPaddingSettings` | 下沉-L2 | `feature/reader` | ReaderStore |
| 452 | `readerScreenOrientation` | 下沉-L2 | `feature/reader` | ReaderStore |
| 453 | `readerKeepLight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 454 | `readerVolumeKeyPage` | 下沉-L2 | `feature/reader` | ReaderStore |
| 455 | `readerKeyPageOnLongPress` | 下沉-L2 | `feature/reader` | ReaderStore |
| 456 | `readerNoAnimScrollPage` | 下沉-L2 | `feature/reader` | ReaderStore |
| 458 | `readerPrevKeys` | 下沉-L2 | `feature/reader` | ReaderStore |
| 460 | `readerNextKeys` | 下沉-L2 | `feature/reader` | ReaderStore |
| 462 | `readerMouseWheelPage` | 下沉-L2 | `feature/reader` | ReaderStore |
| 464 | `readerExpandTextMenu` | 下沉-L2 | `feature/reader` | ReaderStore |
| 466 | `readerShowSelectMenuIcon` | 下沉-L2 | `feature/reader` | ReaderStore |
| 468 | `readerTextSelectMenuConfig` | 下沉-L2 | `feature/reader` | ReaderStore |
| 470 | `readerDoubleHorizontalPage` | 下沉-L2 | `feature/reader` | ReaderStore |
| 472 | `readerAutoSuggestDayNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 474 | `readerDisableReturnKey` | 下沉-L2 | `feature/reader` | ReaderStore |
| 476 | `readerAutoChangeSource` | 下沉-L2 | `feature/reader` | ReaderStore |
| 478 | `readerDefaultSourceChangeAll` | 下沉-L2 | `feature/reader` | ReaderStore |
| 480 | `readerReadBrightness` | 下沉-L2 | `feature/reader` | ReaderStore |
| 482 | `readerShowBrightnessView` | 下沉-L2 | `feature/reader` | ReaderStore |
| 484 | `readerBrightnessVwPos` | 下沉-L2 | `feature/reader` | ReaderStore |
| 486 | `readerBrightnessAuto` | 下沉-L2 | `feature/reader` | ReaderStore |
| 488 | `readerReadBodyToLh` | 下沉-L2 | `feature/reader` | ReaderStore |
| 490 | `readerUseZhLayout` | 下沉-L2 | `feature/reader` | ReaderStore |
| 492 | `readerPaddingDisplayCutouts` | 下沉-L2 | `feature/reader` | ReaderStore |
| 494 | `readerAdaptSpecialStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 496 | `readerReadMenuBottomCornerRadius` | 下沉-L2 | `feature/reader` | ReaderStore |
| 498 | `readerReadMenuFloatingBottomBar` | 下沉-L2 | `feature/reader` | ReaderStore |
| 500 | `readerReadMenuBottomBarBlurMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 502 | `readerReadMenuBottomBarBlurStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 504 | `readerReadMenuBottomBarLiquidGlassButtons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 506 | `readerReadMenuBlurAlpha` | 下沉-L2 | `feature/reader` | ReaderStore |
| 508 | `readerReadMenuTopBarTitleCapsule` | 下沉-L2 | `feature/reader` | ReaderStore |
| 510 | `readerTitleBarMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 512 | `readerTitleBarCompact` | 下沉-L2 | `feature/reader` | ReaderStore |
| 514 | `readerTitleBarIconStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 516 | `readerReadMenuTopBarBlurMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 518 | `readerReadMenuTopBarBlurStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 520 | `readerReadMenuTopBarLiquidGlassButtons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 522 | `readerReadMenuTopBarMergeButtons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 524 | `readerReadBarStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 526 | `readerMenuPaletteStyle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 528 | `readerMenuColorMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 530 | `readerMenuBgColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 532 | `readerMenuBgColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 534 | `readerMenuContainerColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 536 | `readerMenuContainerColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 538 | `readerMenuAccentColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 540 | `readerMenuAccentColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 542 | `readerMenuBorderWidth` | 下沉-L2 | `feature/reader` | ReaderStore |
| 544 | `readerMenuBorderColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 546 | `readerMenuBorderColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 548 | `readerMenuBlurRadius` | 下沉-L2 | `feature/reader` | ReaderStore |
| 550 | `readerMenuTextColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 552 | `readerMenuTextColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 554 | `readerMenuBlurColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 556 | `readerMenuBlurColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 558 | `readerShowTitleBarIcons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 559 | `readerTitleBarIconPosition` | 下沉-L2 | `feature/reader` | ReaderStore |
| 560 | `readerReadMenuFloatingIconLiquidGlass` | 下沉-L2 | `feature/reader` | ReaderStore |
| 566 | `readerFloatingIcons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 569 | `readerTitleBarCustomIcons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 570 | `readerReadMenuCustomIcons` | 下沉-L2 | `feature/reader` | ReaderStore |
| 572 | `readerDayNightReminderDismissedDark` | 下沉-L2 | `feature/reader` | ReaderStore |
| 574 | `readerDayNightReminderDismissedLight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 576 | `readerDayNightReminderText` | 下沉-L2 | `feature/reader` | ReaderStore |
| 578 | `readerDayNightReminderTargetNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 585 | `readerReadingAnchorEnabled` | 下沉-L2 | `feature/reader` | ReaderStore |
| 586 | `readerSwipeToAddBookmark` | 下沉-L2 | `feature/reader` | ReaderStore |
| 588 | `readerBookmarkBadgeSize` | 下沉-L2 | `feature/reader` | ReaderStore |
| 590 | `readerBookmarkBadgeImage` | 下沉-L2 | `feature/reader` | ReaderStore |
| 591 | `readerSelectText` | 下沉-L2 | `feature/reader` | ReaderStore |
| 593 | `readerSliderVibrator` | 下沉-L2 | `feature/reader` | ReaderStore |
| 595 | `readerSelectVibrator` | 下沉-L2 | `feature/reader` | ReaderStore |
| 600 | `readerChineseConverterType` | 下沉-L2 | `feature/reader` | ReaderStore |
| 602 | `readerTextColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 603 | `readerTextColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 605 | `readerTextAccentColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 606 | `readerTextAccentColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 612 | `readerBgStr` | 下沉-L2 | `feature/reader` | ReaderStore |
| 613 | `readerBgStrNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 614 | `readerBgType` | 下沉-L2 | `feature/reader` | ReaderStore |
| 615 | `readerBgTypeNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 616 | `readerBgAlpha` | 下沉-L2 | `feature/reader` | ReaderStore |
| 617 | `readerDarkStatusIcon` | 下沉-L2 | `feature/reader` | ReaderStore |
| 618 | `readerDarkStatusIconNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 620 | `readerTitleMode` | 下沉-L2 | `feature/reader` | ReaderStore |
| 621 | `readerTitleSize` | 下沉-L2 | `feature/reader` | ReaderStore |
| 622 | `readerTitleSizeRelative` | 下沉-L2 | `feature/reader` | ReaderStore |
| 623 | `readerTitleTopSpacing` | 下沉-L2 | `feature/reader` | ReaderStore |
| 624 | `readerTitleBottomSpacing` | 下沉-L2 | `feature/reader` | ReaderStore |
| 625 | `readerTitleColor` | 下沉-L2 | `feature/reader` | ReaderStore |
| 626 | `readerTitleColorNight` | 下沉-L2 | `feature/reader` | ReaderStore |
| 627 | `readerTitleBold` | 下沉-L2 | `feature/reader` | ReaderStore |
| 628 | `readerTitleLineSpacingExtra` | 下沉-L2 | `feature/reader` | ReaderStore |
| 629 | `readerTitleLineSpacingSub` | 下沉-L2 | `feature/reader` | ReaderStore |
| 630 | `readerTitleSegType` | 下沉-L2 | `feature/reader` | ReaderStore |
| 631 | `readerTitleSegScaling` | 下沉-L2 | `feature/reader` | ReaderStore |
| 632 | `readerTitleSegDistance` | 下沉-L2 | `feature/reader` | ReaderStore |
| 633 | `readerTitleSegFlag` | 下沉-L2 | `feature/reader` | ReaderStore |
| 635 | `readerRemoveRepeatedTitle` | 下沉-L2 | `feature/reader` | ReaderStore |
| 636 | `readerMaxLengthWithNoToc` | 下沉-L2 | `feature/reader` | ReaderStore |
| 637 | `eyeProtectionEnabled` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 638 | `eyeProtectionAutoNight` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 639 | `eyeProtectionSchedule` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 640 | `eyeProtectionIntensity` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 641 | `eyeProtectionStartTime` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 642 | `eyeProtectionEndTime` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 643 | `eyeProtectionMinute` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 644 | `readerAnchorOriginBook` | 下沉-L2 | `feature/reader` | ReaderStore |
| 645 | `readerAnchorOriginChapter` | 下沉-L2 | `feature/reader` | ReaderStore |
| 646 | `readerAnchorJumpCount` | 下沉-L2 | `feature/reader` | ReaderStore |
| 647 | `readerTocUseReplace` | 下沉-L2 | `feature/reader` | ReaderStore |
| 648 | `readerTocShowWordCount` | 下沉-L2 | `feature/reader` | ReaderStore |
| 649 | `readerClickImageBehavior` | 下沉-L2 | `feature/reader` | ReaderStore |
| 650 | `readerClickRegionActions` | 下沉-L2 | `feature/reader` | ReaderStore |
| 651 | `readerHideStatusBar` | 下沉-L2 | `feature/reader` | ReaderStore |
| 652 | `readerHideNavigationBar` | 下沉-L2 | `feature/reader` | ReaderStore |
| 653 | `readerImagePreviewOpen` | 下沉-L2 | `feature/reader` | ReaderStore |
| 654 | `readerImagePreviewCloseRevision` | 下沉-L2 | `feature/reader` | ReaderStore |
| 655 | `autoReadSpeed` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 656 | `readerPageAnimation` | 下沉-L2 | `feature/reader` | ReaderStore |
| 657 | `readerPageAnimationEInk` | 下沉-L2 | `feature/reader` | ReaderStore |
| 658 | `readerAnimationSpeed` | 下沉-L2 | `feature/reader` | ReaderStore |
| 659 | `readerInfoSettings` | 下沉-L2 | `feature/reader` | ReaderStore |
| 660 | `backupBusy` | 归位 | `feature/backup` | BackupStore |
| 661 | `backupStatusMessage` | 归位 | `feature/backup` | BackupStore |
| 662 | `backupIgnoreKeys` | 归位 | `feature/backup` | BackupStore |
| 663 | `restoreIgnoreKeys` | 归位 | `feature/backup` | BackupStore |
| 664 | `backupCategoryOptions` | 归位 | `feature/backup` | BackupStore |
| 665 | `webDavSettings` | 归位 | `feature/backup` | BackupStore |
| 666 | `webDavTesting` | 归位 | `feature/backup` | BackupStore |
| 667 | `webDavBackupNames` | 归位 | `feature/backup` | BackupStore |
| 668 | `onboardingLoaded` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 677 | `themeColorsReady` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 678 | `onboardingComplete` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 685 | `themeMode` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 687 | `themePaletteIndex` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 694 | `themeFontScale` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 696 | `themeShowStatusBar` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 703 | `themeSwipeAnimation` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 705 | `bookInfoFollowCoverColor` | 归位 | `feature/bookshelf` | BookshelfStore |
| 707 | `bookInfoNetworkCoverBackground` | 归位 | `feature/bookshelf` | BookshelfStore |
| 709 | `bookInfoDefaultCoverBackground` | 归位 | `feature/bookshelf` | BookshelfStore |
| 711 | `bookInfoAuthorSearchFallback` | 归位 | `feature/bookshelf` | BookshelfStore |
| 713 | `themeContainerOpacity` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 715 | `themeDisableGroupCorner` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 717 | `themeOverrideCardCorner` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 719 | `themeCardCornerRadius` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 721 | `themeOverrideCardBorder` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 723 | `themeCardBorderWidth` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 725 | `themeCardBorderColorDay` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 727 | `themeCardBorderColorNight` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 729 | `themeEnableItemDivider` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 731 | `themeItemDividerWidth` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 733 | `themeItemDividerLength` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 735 | `themeItemDividerColor` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 737 | `themeEnableContainerBackgroundImage` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 739 | `themeLargeContainerBackgroundLight` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 741 | `themeLargeContainerBackgroundDark` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 743 | `themeItemBackgroundLight` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 745 | `themeItemBackgroundDark` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 747 | `themePureBlack` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 749 | `themeBackgroundImage` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 751 | `themeBackgroundImageNight` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 753 | `themeBackgroundBlur` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 755 | `themeBackgroundNightBlur` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 757 | `themeShowHome` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 759 | `themeShowDiscovery` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 761 | `themeShowRss` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 763 | `themeDefaultHomePage` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 765 | `themeMainNavigationOrder` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 773 | `bookshelfLoading` | 归位 | `feature/bookshelf` | BookshelfStore |
| 775 | `themeLabelVisibilityMode` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 780 | `themeTabletInterface` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 782 | `navigatorWidthVp` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 783 | `navigatorHeightVp` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 785 | `themePredictiveBack` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 787 | `themeReaderSharedElement` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 789 | `themeEnableBlur` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 790 | `themeEnableProgressiveBlur` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 791 | `themeUseFlexibleTopAppBar` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 792 | `themeTopBarButtonStyle` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 793 | `themeMergeTopBarActions` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 794 | `themeShowBottomView` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 795 | `themeUseFloatingBottomBar` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 796 | `themeUseFloatingBottomBarLiquidGlass` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 797 | `themeBottomBarLensRadius` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 798 | `themeTopBarBlurRadius` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 799 | `themeBottomBarBlurRadius` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 800 | `themeTopBarBlurAlpha` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 801 | `themeBottomBarBlurAlpha` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 802 | `themeTopBarOpacity` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 803 | `themeBottomBarOpacity` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 805 | `themeAppFontPath` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 812 | `themeCustomColors` | 下沉-L1 | `store/ThemeStore` | AppStorage + ThemeStore |
| 813 | `homeDashboardSections` | 归位 | `feature/discover` | 对应域 Store |
| 814 | `homeGoalMinutes` | 归位 | `feature/discover` | 对应域 Store |
| 815 | `homeTodayReadMinutes` | 归位 | `feature/discover` | 对应域 Store |
| 816 | `homeWebDavBackupName` | 归位 | `feature/discover` | 对应域 Store |
| 817 | `homeWebDavState` | 归位 | `feature/discover` | 对应域 Store |
| 823 | `readAloudActive` | 下沉-L2 | `feature/reader` | ReaderStore |
| 825 | `readAloudSpan` | 下沉-L2 | `feature/reader` | ReaderStore |
| 827 | `readAloudSettings` | 下沉-L2 | `feature/reader` | ReaderStore |
| 829 | `httpTtsSources` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 830 | `httpTtsVoices` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 831 | `httpTtsSelection` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 833 | `showAloudConfig` | 留壳-L3 | `shell/components/OverlayHost` | 组件级 @State |
| 835 | `aloudStateNum` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 836 | `aloudUnitIndex` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 837 | `aloudUnitTotal` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 839 | `aloudCurrentText` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 840 | `aloudNextText` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 841 | `aloudTexts` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 843 | `showReadAloudPlayer` | 留壳-L3 | `shell/components/OverlayHost` | 组件级 @State |
| 845 | `playerBgMode` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
| 846 | `aloudVoiceName` | 留壳 | `shell/AppShell` | 主壳自身状态（需逐条复核） |
