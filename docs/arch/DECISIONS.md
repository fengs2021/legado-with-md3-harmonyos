# 关键决策记录（ADR）

> 每条记录：背景 → 选项 → 决定 → 理由 → 后果。有疑问先看这里。

---

## ADR-001：fork 已有移植，不从上游 Android 从零移植

**背景**：上游 `HapeLee/legado-with-MD3` 有 2,657 个 `.kt` / 478,804 行 Kotlin / 505 个 Compose 文件。已有鸿蒙移植做到 1,040/1,226 条（85%）。

**选项**：
1. 从 Kotlin 上游从零移植到 ArkTS
2. fork `hbxs0571/legado-with-md3-harmonyos` 继续
3. 用 Kotlin Multiplatform 共享业务层

**决定**：选 2。

**理由**：
- 从零要重写约 11 万行 ArkTS 才能达到当前完成度，且没有更快的方法——那个人一个月做到 85% 靠的是把 parity 对照表当规格书逐条迁移，重做不会更快。
- 它的 `docs/parity/`（1.4 MB、1,226 条）本身就是最值钱的资产：现成的规格书 + 进度表 + 验收口径。
- 选 3 不成立，见 ADR-002。

**后果**：继承它的全部技术债（342 状态、675 KB 单文件、0 路由），因此必须先做阶段 A/B/C 治理。

---

## ADR-002：不用 Kotlin Multiplatform 共享业务层

**背景**：上游是 Kotlin + Compose，理论上可以 KMP 共享 domain 层，只重写 UI。

**选项**：
1. KMP 编译到 OpenHarmony（Kotlin/Native ohos target）
2. Compose Multiplatform 加 ohos 后端
3. ArkTS 全量重写

**决定**：选 3。

**理由**：
- Kotlin/Native 无成熟 OpenHarmony target；社区 kotlin-ohos 未到生产可用。
- Compose Multiplatform 无 ohos 后端，且鸿蒙侧无 Skia 渲染通道。
- ArkTS 严格模式虽有限制（禁 `any`、禁结构化类型），但 `hbxs0571` 已用 11 万行证明可行，含排版引擎、翻页动画、EPUB/MOBI 解析这些重活。

**后果**：业务逻辑与 UI 不能共享，上游 Kotlin 更新需要人工跟（`git fetch upstream` + 逐条对照）。

---

## ADR-003：先治结构，再补功能

**背景**：`Index.ets` 13,104 行 / 342 个 `@State`，342 个状态挤在一个 `struct` 里，任一变化触发整个主壳 `build()` 重算。

**选项**：
1. 直接补 155 条未接功能
2. 先做结构治理（阶段 A/B/C），再补功能

**决定**：选 2。

**理由**：
- 342 状态 → 每加一个功能都要在 13,104 行里找位置，且让主壳更慢。补功能的代码也会堆进旧结构，等于二次返工。
- 结构治理不动业务逻辑，风险可控（每步编译通过、可回退）。
- 治理完 `@State` 342 → <80，后续每条功能的边际成本大幅下降。

**后果**：短期看不到新功能，但 D 阶段会快得多。

---

## ADR-004：用系统 NavPathStack，不用自研路由

**背景**：现状 `@State route: AppRoute` + 6 个 `*ReturnRoute` 手写返回栈，52 个枚举，0 处 `NavPathStack`。

**选项**：
1. 继续维护自研路由（补 returnRoute）
2. 换 ArkUI `Navigation` + `NavPathStack`

**决定**：选 2。

**理由**：
- `NavPathStack` 自动管理返回栈，`pushPathByName(name, param, onPop)` 直接拿返回值，8 个路由状态与约 60 个路由方法可删。
- 系统路由支持转场动画（含共享元素动画的基础），为后续补「封面→详情 morph」铺路。
- 自研路由每加一页要改 3 处，是 342 状态的直接成因之一。

**后果**：迁移期需逐条改 52 个路由点，但每条独立可验证。

---

## ADR-005：状态三层模型（L1 AppStorage / L2 域 Store / L3 组件）

**背景**：342 个 `@State` 全部平铺在 `Index`，无归属规则。

**决定**：按生命周期分三层，用判定树决定归属（见 ARCHITECTURE.md 3.1）。

**理由**：
- ArkUI 的 `@State` 变化触发所在组件 `build()`，状态必须尽量下沉到叶子。
- 域 Store 用 `@Observed` + `@ObjectLink`，是 ArkTS 严格模式下唯一可行的跨组件共享方案（不能用 TS 式依赖注入）。
- `ReaderPage` 现在 22 个 `@Prop @Watch` 入参 → 改 1 个 `@ObjectLink store`，改字号不再穿透 22 层。

**后果**：`AppStorageKeys.ets` 成为强制登记点，禁止散落字符串键。

---

## ADR-006：800 行 / 25 状态 / import 白名单 三条硬门禁

**背景**：现状最大文件 675 KB，最大单组件 342 状态，层间无依赖约束。

**决定**：
| 门禁 | 阈值 | 依据 |
| --- | --- | --- |
| 单文件 | ≤ 800 行 | 超过后 review 成本陡增，ArkTS 编译也变慢 |
| 单组件 `@State` | ≤ 25 | 超过后重渲染范围不可控 |
| import 方向 | 白名单 | 防止 `feature` 互相 import 形成网状耦合 |

**后果**：CI 里加 3 个检查脚本，违反即构建失败。

---

## ADR-007：还原度以 parity 账本为唯一口径

**背景**：「尽量还原」是主观描述，必须有可度量的定义。

**决定**：以继承的 `docs/parity/` 七表 1,226 条为唯一验收口径，每补一条抹一格。

**理由**：
- 该账本已是三级口径（读 / 写 / 忽略项）× 28 类 ZIP 兼容，且有 `scripts/parity-rows.py` 可复算。
- 避免「感觉差不多了」的自欺。

**后果**：不接受「功能上等价」这类口头结论，必须在表里改状态并附证据（如 `TXT-READER.md:500` 的构造样本上机记录）。

---

## ADR-008：两条「平台无解」改为「可实现」

**背景**：上游把 A3 Monet 取色、A7 双主题引擎判为「平台无此能力」，取证是 SDK 零命中。

**决定**：推翻这两条判定。

**理由**：
- A3：`reader/m3/dynamiccolor/dynamic_scheme.ets` **已含 M3 HCT 取色算法**，只需种子色（背景图主色 / 手选色球 / 书封主色），不需要系统壁纸 API。取证只证明了「系统没给」，没证明「做不到」。
- A7：`UiTokens.ets` + `TypographyTokens.ets` 已是两层抽象，套两套 palette + 两档尺寸即双引擎，不需要两套控件体系。

**后果**：只剩 E7（intent/effect 分层）是真无解——上游自己都没实现。

---

## ADR-009：账本里的「155 条未接」按 ROI 排，不按顺序排

**背景**：155 条按卡点分 12 类，难度差异极大。

**决定**：D 阶段顺序 = L55 → A/C/D12 → F37 → E20 → I/J18 → G7 → K/H3。

**理由**：
- L 类 55 条是纯本地功能，平台已支持、只缺入口或面板，最快见效。
- F 类 37 条引擎已落地，纯接线，第二快。
- G 类 7 条要有声书播放器，需新增 `platform/audio`，最重，放最后。
