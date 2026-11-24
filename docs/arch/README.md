# legado-harmonyos 架构重规划 · 文档索引

> 目标：把已有的 11.3 万行 ArkTS（1040/1226 条已接）迁入一个**能继续长大**的骨架，再补到 1226/1226。
> 基线仓库：`hbxs0571/legado-with-md3-harmonyos` @ v0.1.0（2026-11-22）
> 本规划全部数字来自对 305 个 `.ets` 文件与 2,657 个 `.kt` 上游文件的实测。

---

## 文档地图

| 文档 | 内容 | 读者 |
| --- | --- | --- |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 病灶实测、四层架构、依赖铁律、状态三层模型、4 阶段路线 | 先读这个 |
| [MODULES.md](MODULES.md) | 14 个业务域的职责/文件归属/接口/状态/验收 | 分模块干活时读 |
| [ROUTER.md](ROUTER.md) | 52 条路由完整映射、参数契约、8 个路由状态迁移 | 做阶段 A 时读 |
| [STATE.md](STATE.md) | **335 个 `@State` 逐条归属表**（脚本生成，勿手改） | 做阶段 B 时读 |
| [MIGRATION.md](MIGRATION.md) | 可逐条勾选的任务清单 + 质量门禁 + 回退策略 | 每天照着做 |
| [DECISIONS.md](DECISIONS.md) | 关键决策记录（为什么不用 KMP、为什么 fork 而不是重写） | 有疑问时读 |

---

## 一页纸结论

### 现状（实测）

| 项 | 值 |
| --- | --- |
| 上游 Android MD3 | 2,657 个 `.kt` / **478,804 行 Kotlin** / 505 个 Compose 文件 |
| 已有鸿蒙移植 | 305 个 `.ets` / **约 11.3 万行 ArkTS** |
| 还原度账本 | **1,226 条 = 已接 1,040 / 未接 155 / 不适用 31** |
| 最大单文件 | `pages/Index.ets` **13,104 行 / 675 KB / 342 个 `@State`** |
| 路由 | 52 个枚举，**0 处 `NavPathStack`**，手写返回栈 |

### 判断

1. **不从零开分支**。已有人做到 85%，重做 11 万行 ArkTS 不划算；接手它的账本当规格书。
2. **先治结构，再补功能**。342 状态挤在一个组件里，每加一条功能都变慢——这是它一个月只到 85% 的物理原因。
3. **还原度用账本度量**，不用感觉。1226 条 × 28 类 ZIP × 读/写/忽略项三级。
4. **两条「平台无解」可突破**：Monet 取色（手上有 M3 HCT 算法）、双主题引擎（已两层 token）。

### 四个阶段

| 阶段 | 内容 | 产出 |
| --- | --- | --- |
| **A** 骨架先行 | 建目录、引入 `NavPathStack`、拆主壳 | `Index.ets` 13,104 → <800 行 |
| **B** 状态下沉 | 183 阅读器状态 → `ReaderStore`；54 主题 → `ThemeStore`；拆 `ProfileSubPages` | `@State` 342 → <80 |
| **C** 层归位 | `data/` 算法抽 `engine/`；`pages/` 拆到 `feature/*`；写 import 门禁 | 依赖方向全绿 |
| **D** 补 155 条 | 按 ROI：L55 → A/C/D12 → F37 → E20 → I/J18 → G7 → K/H3 | 1266/1226 全绿 |

---

## 目录骨架（目标态）

```
entry/src/main/ets/
├── entryability/     Ability 生命周期 + 首启门禁
├── shell/            主壳：AppShell / AppTabBar / AppTopBar / OverlayHost
│   └── router/       NavPathStack 封装 + 52 条路由表 + 参数契约
├── store/            全局 L1：ThemeStore / SettingsStore / SessionStore
├── feature/          14 个业务域，每域 page/view/store/sheet/model
│   ├── reader/  bookshelf/  bookinfo/  discover/  search/  source/
│   ├── subscription/  profile/  theme/  backup/  readaloud/
│   └── readrecord/  catalog/  import/
├── domain/           模型 + 用例（零 UI 依赖，可单测）
├── data/             仓储 + RDB + 文件 + 备份
├── engine/           纯算法：layout / scan / parse / purify / paginate
├── platform/         系统能力：webdav / tts / audio / fs / net
├── shared/           UI 原子：ui / settings / typography / motion
└── reader-m3/        M3 dynamic color（原 reader/m3，独立保留）
```

---

## 马上要做的第一件事

按 [MIGRATION.md](MIGRATION.md) 阶段 A1：建目录 + `AppStorageKeys` + `RouteName` 常量。**不改任何业务逻辑，编译必须通过。**

---

## 关联文档（继承自基线仓库，不作改动）

| 文档 | 用途 |
| --- | --- |
| `docs/parity/`（10 文件，1.4 MB） | **1226 条还原度账本，唯一验收口径** |
| `docs/KNOWN-ISSUES.md`（409 KB） | 已知问题逐条消账 |
| `docs/VALIDATION.md`（292 KB） | 设备验证记录 |
| `docs/COMPOSE-ARKUI-MAP.md`（15 KB） | Compose → ArkUI 迁移对照，写代码时查 |
| `docs/PARITY-RULES.md`（26 KB） | 盘点规约与验收等级定义 |
