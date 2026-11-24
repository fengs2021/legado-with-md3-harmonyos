# 迁移执行清单

> 配套：[ARCHITECTURE.md](ARCHITECTURE.md) 阶段划分 → 本文展开为**可逐条勾选的任务**。
> 原则：**每一步都编译通过、都可回退**。任何一步失败就回 `main`，不允许带着红构建前进。

---

## 0. 基线冻结

| # | 任务 | 验收命令 | 状态 |
| --- | --- | --- | --- |
| 0.1 | fork 到 `fengs2021`，`main` 保持与上游一致 | `git remote -v` 显示 origin + upstream | ☐ |
| 0.2 | 建 `refactor/nav-stack` 分支 | `git branch` | ☐ |
| 0.3 | 跑一次基线构建，记录产物 | `hvigorw assembleHap` | ☐ |
| 0.4 | 记录基线指标（见下表） | `python3 scripts/gen-state-plan.py` | ☐ |

### 基线指标（改完要对比）

| 指标 | 基线值 | 目标值 |
| --- | --- | --- |
| `Index.ets` 行数 | 13,104 | < 800 |
| `Index.ets` `@State` 数 | 342 | < 80 |
| `ReaderPage.ets` 行数 | 9,866 | < 500 |
| `ReaderPage.ets` `@Prop` 入参 | 22 | 1 |
| 最大文件 | 675 KB (`Index.ets`) | < 60 KB |
| `NavPathStack` 使用 | 0 | ≥ 1 |
| `AppRoute`/`ProfileRoute` 枚举 | 52 | 0（改常量） |
| 账本已接条目 | 1,040 / 1,226 | 1,226 |

---

## 阶段 A · 骨架先行（不改业务逻辑）

### A1 建目录与常量

| # | 任务 | 产出 | 验收 | 状态 |
| --- | --- | --- | --- | --- |
| A1.1 | 建 `shell/ store/ feature/ domain/ data/ engine/ platform/ shared/` 目录 | 空目录 + `.gitkeep` | 编译通过 | ☐ |
| A1.2 | 写 `store/AppStorageKeys.ets` | 所有持久键常量 | 无散落字符串 | ☐ |
| A1.3 | 写 `shell/router/RouteName.ets` | 52 个路由名常量 | 编译通过 | ☐ |
| A1.4 | 写 `shell/router/RouteParam.ets` | 路由参数 class | 编译通过 | ☐ |

### A2 引入 NavPathStack

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| A2.1 | 写 `shell/router/AppRouter.ets`（push/pop/replace/clear） | 编译通过 | ☐ |
| A2.2 | 写 `shell/router/RouteTable.ets`（路由名 → 页面 builder） | 编译通过 | ☐ |
| A2.3 | `AppShell` 包 `Navigation`，挂 `navDestination` | 首页可显示 | ☐ |
| A2.4 | 迁第 1 条路由（建议 `bookInfo`）做样板 | 能进能回 | ☐ |
| A2.5 | 按 ROUTER.md 3.2/3.3 逐条迁移，每条单独提交 | 每步编译 + 可达 | ☐ |
| A2.6 | 删 `AppRoute`/`ProfileRoute` 枚举与 8 个 `*ReturnRoute` | `grep` 归零 | ☐ |

### A3 拆主壳

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| A3.1 | `Index.ets` → `shell/AppShell.ets` | 改名后编译通过 | ☐ |
| A3.2 | 抽 `AppTabBar.ets`（承接 `selectedTab`） | Tab 切换正常 | ☐ |
| A3.3 | 抽 `AppTopBar.ets` | 顶栏正常 | ☐ |
| A3.4 | 抽 `OverlayHost.ets`（承接 4 个浮层状态） | 浮层正常 | ☐ |
| A3.5 | 抽 `AppStartGate.ets`（首启门禁） | 首次启动流程正常 | ☐ |
| A3.6 | `AppShell.ets` < 800 行 | `wc -l` | ☐ |

---

## 阶段 B · 状态下沉（收益最大）

### B1 主题 54 状态

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| B1.1 | 建 `store/ThemeStore.ets`（`@Observed`） | 编译通过 | ☐ |
| B1.2 | 54 个 `theme*` 迁入，字段合并到 ≤ 20 | `@State` 342 → 288 | ☐ |
| B1.3 | 切换主题不重启、不整页重渲染 | 手动验 | ☐ |
| B1.4 | 14 套调色板 + 纯黑 + 背景图全部正常 | 手动验 | ☐ |

### B2 阅读器 183 状态（最关键）

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| B2.1 | 建 `feature/reader/store/ReaderStore.ets` | 编译通过 | ☐ |
| B2.2 | 迁移「书籍会话」组（~30 状态） | 开书能读 | ☐ |
| B2.3 | 迁移「排版参数」组（~22 状态） | 改字号生效 | ☐ |
| B2.4 | 迁移「渲染态」组（~20 状态） | 正文渲染正常 | ☐ |
| B2.5 | 迁移「交互态」组（~40 状态） | 菜单/目录/选区正常 | ☐ |
| B2.6 | 迁移「朗读」+「搜索」组 | 朗读/搜索正常 | ☐ |
| B2.7 | 剩余归并，`ReaderPage` 入参 22 → 1 | `@Prop` 计数 = 1 | ☐ |

### B3 拆 ReaderPage

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| B3.1 | 抽 `view/ReaderCanvasView.ets` | 正文显示正常 | ☐ |
| B3.2 | 抽 `view/ReaderChromeView.ets` | 顶底栏正常 | ☐ |
| B3.3 | 抽 `view/ReaderMenuView.ets` | 菜单正常 | ☐ |
| B3.4 | 抽 `sheet/` 各浮层 | 浮层正常 | ☐ |
| B3.5 | `ReaderPage.ets` < 500 行 | `wc -l` | ☐ |
| B3.6 | **翻页性能打点对比不劣化** | 见下表 | ☐ |

### 性能基线（B3.6 必须记录）

| 场景 | 指标 | 基线 | 改后 |
| --- | --- | --- | --- |
| 开书到首屏 | ms | 待测 | — |
| 单击翻页 | ms | 待测 | — |
| 连续翻 20 页 | ms/页 | 待测 | — |
| 改字号重排 | ms | 待测 | — |

### B4 拆 ProfileSubPages

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| B4.1 | 按 ROUTER.md 3.3 拆成 34 个独立页面文件 | 每个 < 800 行 | ☐ |
| B4.2 | 181 个 `@State` 按 6 组 Store 分配 | 每组 ≤ 30 | ☐ |
| B4.3 | `ProfileSubPages.ets` 删除 | 文件不存在 | ☐ |

---

## 阶段 C · 层归位

| # | 任务 | 验收 | 状态 |
| --- | --- | --- | --- |
| C1 | `data/` 算法抽到 `engine/`（`TxtChapterScanner`/`EpubWriter`/`LocalTextReSegmenter`/`BookContentProcessEngine`/`RdbSchema` 除外） | `data/` 只剩仓储+RDB+文件 | ☐ |
| C2 | `pages/` 的 Sheet/Editor/Paginator 归 `feature/*/sheet` | `pages/` 目录删除 | ☐ |
| C3 | `model/` → `domain/model`；`*UseCase` → `domain/usecase` | 依赖方向全绿 | ☐ |
| C4 | `lib/` → `platform/` + `shared/utils` | 编译通过 | ☐ |
| C5 | `reader/` → `engine/layout` + `engine/paginate`；`reader/m3` 独立 | 编译通过 | ☐ |
| C6 | 拆 `data/BackupRepository.ets`（217 KB → 读写分离 4 文件） | 备份往返正常 | ☐ |
| C7 | 写 import 边界检查脚本，接 CI | 违反即失败 | ☐ |

---

## 阶段 D · 补 155 条（功能回填）

| 批次 | 内容 | 条数 | 前置 | 状态 |
| --- | --- | --- | --- | --- |
| D1 | L 类纯本地未做 | 55 | 无 | ☐ |
| D2 | A 类已验改表 + C 类 PDF 真机验 + D 类取证 | 12 | 真机 | ☐ |
| D3 | F 类在线书源消费方接线 | 37 | 引擎已有 | ☐ |
| D4 | E 类原判「不接」退回 | 20 | 无 | ☐ |
| D5 | I 类数据层 + J 类前置模块 | 18 | 先建表/引擎 | ☐ |
| D6 | G 类有声书播放器 | 7 | `platform/audio` | ☐ |
| D7 | K 类 rar/7z + H 类 AI 决策 | 3 | 引库 / 决策 | ☐ |

---

## 阶段 E · 两个「平台无解」的突破

| # | 任务 | 成本 | 状态 |
| --- | --- | --- | --- |
| E1 | A3 Monet 取色：从背景图/书封取种子色 → `dynamic_scheme.ets` 算全套 | 2–3 天 | ☐ |
| E2 | A7 双引擎：`UiTokens` 套两套 palette + 两档尺寸 | 3–5 天 | ☐ |

---

## 质量门禁（每步都要过）

| 检查 | 阈值 | 命令 |
| --- | --- | --- |
| 单文件行数 | ≤ 800 | `find . -name '*.ets' -exec wc -l {} + \| awk '$1>800'` |
| 单组件 `@State` | ≤ 25 | `grep -c '@State' <file>` |
| 依赖方向 | 违反即失败 | `scripts/check-imports.sh`（C7 产出） |
| 裸 `any` | 0 | `grep -rn ': any' --include=*.ets` |
| 构建 | 通过 | `hvigorw assembleHap` |
| 账本一致性 | 七表行数一致 | `python3 scripts/parity-rows.py`（继承） |

---

## 回退策略

| 场景 | 动作 |
| --- | --- |
| 单步失败 | `git checkout -- .` 回到上一个绿色提交 |
| 阶段失败 | `git checkout main`，该阶段重做 |
| 构建环境坏 | 恢复 `build-profile.json5` 与 `oh-package-lock.json5` |
| upstream 更新 | `git fetch upstream && git rebase upstream/main`，冲突逐文件处理 |

**纪律**：每一步一个 commit，commit message 带阶段号（如 `A2.4: 迁移 bookInfo 路由`）。
