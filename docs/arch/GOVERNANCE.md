# 增量治理方案（承接 docs/ARCHITECTURE.md 第七.4 节）

> **本文件不推翻任何既有结论。** 仓库根 `docs/ARCHITECTURE.md` 已用 202 行论证「不重构」，
> 并给出替代路径：*跨页面共享的新状态一律进 `@ObservedV2` 单例 Store，存量不动*。
> 本文做三件事：① 用新实测数据量化「不立规矩」的失控速度；② 把那条规矩落成可执行的写法；
> ③ 给出三个现在就能做、且不波及现有页面的动作。

---

## 0. 与既有文档的关系

| 文档 | 职责 | 本文关系 |
| --- | --- | --- |
| `docs/ARCHITECTURE.md`（202 行，2026-11-11） | 上游 vs 本地结构差异、**为什么不重构** | **前置结论，不推翻** |
| `docs/PROJECT.md` | 六个核心模块的优先队列与边界 | **排期以它为准**，本文不改队列 |
| `docs/CODE-CONVENTIONS.md` | 编码规约 | 本文的规矩应并入其第八节 |
| `docs/parity/`（1,226 条） | 还原度唯一口径 | 本文不改口径 |
| 本文 | 增量治理的可执行细则 | — |

**本文取代的功能**：曾有一版规划主张「四层架构 + domain/usecase 层 + 全量拆 pages/」，
经核对与 `docs/ARCHITECTURE.md` 第七.1–7.4 冲突，已撤回。理由见下节。

---

## 1. 为什么撤回「补四层」方案

`docs/ARCHITECTURE.md` 已取证（GitHub + 本地 SDK 双处）：「没有可 `ohpm install` 的依赖注入容器或状态管理库」，
且 ArkTS 状态管理是语言级内置。据此：

| 上游构件 | 结论 |
| --- | --- |
| Koin 依赖注入 | 本地 `new XxxRepository(` 全仓 0 处，仓储是静态方法，无物可注入 → 不搬 |
| Gateway 接口层（59 个） | 无多实现与测试替身场景 → 不搬 |
| UseCase（51 个） | 本地 `UseCase` 命中 6 处全是注释 → 选择性搬 |
| **ViewModel（99 个）** | `@ObservedV2` + `@Trace` 可等价 → **唯一该搬的一层** |
| Flow / StateFlow | 无等价物，`@Trace` + `@Monitor` 顶，补不回背压 → 不搬 |

改造成本对照（作者估算）：只做 Store 化 **2,000–3,000 行**；全量对齐四层 **2–3 万行**，等于重做界面层。

---

## 2. 新证据：失控速度（本文新增）

`docs/ARCHITECTURE.md` 2026-11-11 实测 `Index.ets` = **10,189 行 / 294 个 `@State`**（文中数字）。
本次对同一文件按同一口径复测，并回溯到该文档写作当日：

| 时点 | commit | `Index.ets` 行数 | `@State` 数 | 期间改动该文件的提交 |
| --- | --- | --- | --- | --- |
| 2026-11-11 | `d416ae5` | 9,527 | 292 | — |
| 2026-11-24 | HEAD | **13,104** | **342** | **84** |
| 增量（13 天） | — | **+3,577（+37.6%）** | **+50** | — |

折算：**+275 行/天、+3.8 个 `@State`/天**。

复测命令：

```bash
cd legado-harmonyos
wc -l < entry/src/main/ets/pages/Index.ets
grep -c '@State' entry/src/main/ets/pages/Index.ets
# 回溯：
REV=$(git log --before=2026-11-12 --format='%H' -1)
git show $REV:entry/src/main/ets/pages/Index.ets | wc -l
```

**这条数据的意义**：作者主张「立规矩堵住 `@Prop` 增量」，但没给失控速率。
按 275 行/天外推，一年内 `Index.ets` 将达约 10 万行——这不是「能不能维护」的问题，是编译与序列化的物理上限问题。
**规矩越早立，省下的返工越多。**

---

## 3. 规矩：新状态一律进 `@ObservedV2` 单例 Store

### 3.1 硬约束（V1/V2 混用限制，必须遵守）

依官方《状态管理V1和V2混用指导（API 19+）》，以下三条是编译/运行时硬限制：

| 写法 | 结果 |
| --- | --- |
| `@Component` 里写 `private store = XxxStore.get();`（普通成员） | ✅ 允许 |
| `@Component` 里写 `@State store = new XxxStore();` | ❌ 编译报错 |
| `class Sub extends ObservedV2Class` 再做 `@State` | ❌ 运行时报错 |
| `@ObservedV2` 装饰 struct | ❌ 只能装饰 class |
| `@Trace` 装饰 Function 类型属性 | ❌ 改了不刷新 |

基线已在 `97c653b` 抬到 `6.0.0(20)`，`enableV2Compatibility` / `makeV1Observed`（`@since 19`）
与 `AppStorageV2`（`@since 12`）**均可用**。

### 3.2 Store 标准写法

```typescript
// entry/src/main/ets/store/ExampleStore.ets
/**
 * 域 Store 范式。要点：
 *  1. 单例：private static instance + get()，不用 DI。
 *  2. @ObservedV2 装饰 class，字段用 @Trace，变化才触发刷新。
 *  3. 对外只暴露 getter 与语义方法，禁止外部直接改字段。
 *  4. 组件侧写 `private store = XxxStore.get();`（普通成员，不是 @State）。
 */
@ObservedV2
export class ExampleStore {
  private static instance: ExampleStore | null = null;

  @Trace private _value: string = '';

  static get(): ExampleStore {
    if (ExampleStore.instance === null) {
      ExampleStore.instance = new ExampleStore();
    }
    return ExampleStore.instance;
  }

  get value(): string { return this._value; }

  setValue(v: string): void { this._value = v; }
}
```

### 3.3 组件侧接入

```typescript
@Component
export struct SomeView {
  // 普通成员，不加 @State —— 加了就编译报错
  private store: ExampleStore = ExampleStore.get();

  build() {
    Text(this.store.value)   // @Trace 变化触发本组件刷新
  }
}
```

### 3.4 落地前必须先验一件事

`docs/ARCHITECTURE.md` 第七.3 留了一个**未实测项**：`@ObservedV2` 类作为 V1 `@Component` 的普通成员时，
`@Trace` 属性变化能否触发刷新（官方文档说可以，但第一个 Store 落地时要花五分钟验证）。

**验证脚本（第一个 Store 前先跑）**：

```typescript
@ObservedV2
class Counter {
  @Trace count: number = 0;
}

@Component
struct Probe {
  private c: Counter = new Counter();
  build() {
    Column() {
      Text(String(this.c.count))            // 期望：从 0 变 1
      Button('+1').onClick(() => { this.c.count++; })
    }
  }
}
```

不变化 = 该路径不可用，退回 `enableV2Compatibility` + `@State`（`@since 19`，基线已支持）。

---

## 4. 三个现在就能做的动作（不波及现有页面）

### 动作 1：立规矩（文档 + 模板）

| # | 内容 | 落点 |
| --- | --- | --- |
| 1.1 | 规矩写入 `docs/CODE-CONVENTIONS.md` 第八节 | 文档 |
| 1.2 | Store 模板 + 探针样本入库 | `store/ExampleStore.ets`（示范） |
| 1.3 | 跑一次 3.4 的探针，把结论写回 `docs/ARCHITECTURE.md` 第七.3 的「未实测」处 | 文档 |

**收益**：此后新功能不再往 `Index.ets` 加 `@State`，膨胀速率从 275 行/天压到接近 0（对主壳而言）。

### 动作 2：收敛 `ReaderSettingsPage` 的四处挂载

`docs/ARCHITECTURE.md` 第七.5 已登记该问题，本次复测确认仍然存在且行号已漂移：

| 现有挂载点 | 说明 |
| --- | --- |
| `Index.ets:10948` | 第 1 份 |
| `Index.ets:11858` | 第 2 份 |
| `Index.ets:12266` | 第 3 份 |
| `Index.ets:12571` | 第 4 份 |

同一页面挂了四份，合计约 **1,200 行**，且键集不一致（作者实测第 2 份缺 1 个键、第 3 份缺 11 个、第 4 份缺 15 个）。
后果：每次改阅读设置要同步改四处，漏改一处就是静默不一致。

**做法**：抽一个 `ReaderSettingsHost` 组件（参数为打开的入口枚举），四处改为 `ReaderSettingsHost({ entry: SettingsEntry.XXX })`，
键集收敛为一处常量。**这是纯机械改动，不动业务逻辑，收益立刻可见（少约 1,000 行）。**

### 动作 3：朗读的两个硬前置

`docs/ARCHITECTURE.md` 第七.6 明确：动朗读之前要先补两个薄东西，而不是继续往 `Index.ets` 加回调。本次确认两者**都还是零**：

| 前置 | 现状 | 内容 |
| --- | --- | --- |
| 事件广播 | `@ohos.events.emitter` **零命中** | 几十行，只做「某类数据变了」的通知，不承载状态 |
| 播放器持有者 | 无 | 跟页面生命周期创建/销毁的实例，不是静态字段 |
| `@ObservedV2` Store | **零命中** | 播放状态、进度、音色的落点 |

三者都是**新增文件**，不波及现有页面，可以独立提交。

---

## 5. 明确不做的事（避免再次跑偏）

| 不做 | 理由 |
| --- | --- |
| 补 `domain/` + `usecase/` 层 | ArkTS 无 Flow/Koin，等于自造框架（`docs/ARCHITECTURE.md` 第七.1） |
| 全量拆 `pages/` 到 `feature/` | 2–3 万行改动，等于重做界面层；且会让六个模块返工（第七.4） |
| 把 `data/` 的算法抽到 `engine/` | 现有仓储是静态工具类，抽离不改可测性问题，反增加 import 面 |
| 引入第三方 ORM / DI / 状态库 | 生态没有可安装的；SDK 26 已移除 `@ohos.data.orm`（第五.3） |
| 把路由改成 `NavPathStack` | **待评估**：可减少约 100 处 `AppRoute` 分支，但与六模块无直接关系，需先证收益再排期 |
| 存量 `@State` / `@Prop` 大规模迁移 | 第七.4：**存量不动**，收尾时再收 |

---

## 6. 与六模块队列的关系

`docs/PROJECT.md` 的队列（书架 → 阅读器 → 朗读 → 阅读记录 → 外观 → 备份）不变。
本文的三个动作是**横切**的：

| 模块 | 本文如何介入 |
| --- | --- |
| 书架 / 阅读器 | 动作 1（规矩）生效；动作 2（收敛设置页挂载）在改阅读器时一并做 |
| 朗读 | 动作 3 是它的硬前置，必须先做完 |
| 阅读记录 / 外观 / 备份 | 动作 1 生效；新增状态一律进 Store |

**顺序建议**：动作 1 → 动作 2（跟阅读器模块同批）→ 动作 3（朗读模块开工前）。

---

## 7. 验收

| 项 | 判据 |
| --- | --- |
| 规矩生效 | `Index.ets` 的 `@State` 数不再增长（当前 342 作为基线） |
| 探针结论 | `@ObservedV2` 普通成员路径可用性有实测记录，写回 `docs/ARCHITECTURE.md` |
| 挂载收敛 | `ReaderSettingsPage` 在 `Index.ets` 的挂载点从 4 → 1，`Index.ets` 减少约 1,000 行 |
| 朗读前置 | `emitter`、播放器持有者、朗读 Store 三个文件存在且被朗读模块引用 |
| 构建 | 每次改动后 `assembleHap` 通过（仓库 AGENTS.md 硬要求） |
