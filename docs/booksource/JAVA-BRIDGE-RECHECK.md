# java 桥复核：KI-BS4「107 源不可用」不成立（2026-11-28）

> 起因：KI-BS4 记「`java.*` 桥 32 方法未支持，影响 904 源里的 107 条（11.8%）」。
> 本次按可复跑口径重算，结论是**这个数字把「规则形态」和「运行时」混在一起了**。

## 一、先分清运行时

引擎里跑两套 JS 运行时，`java` 对象的完整度不同：

| 通道 | 入口 | java 能力 | 谁在用 |
| --- | --- | --- | --- |
| ArkWeb `BookSourceStageWebRuntime` | `RuleExecutionService.executeFullJsFieldBatch` / `executePostProcessorJsFieldBatch` | 完整：`FULL_JAVA_METHODS` 60+ 个，含 `ajax/ajaxAll/post/put/head`；ajax 走「占位 → 宿主执行 → 重放脚本」 | 整段 `@js:`、`<js>` 段、`选择器@js:` 后缀 |
| QuickJS 轻量 `JsRuntime` | 选择器 + 值级 `java.*` 同步替换 | 30 个纯计算方法 + 会话级变量/登录态（见提交 `aa7c593`） | 只有 `{{java.xxx}}` 模板 |

所以「用没用到 `java.ajax`」不等于「跑不跑得了」——要看规则写成哪种形态。

## 二、可复跑统计

```bash
python3 scripts/scan-source-java-usage.py <bookSource.json>   # 3405 条真实源
```

口径：`java.put` 在源里九成是「写变量 (k,v)」不是 HTTP PUT，统计网络调用时排除。

| 形态 | 条数 | 运行时 | 能否跑 `java.ajax` |
| --- | --- | --- | --- |
| `full_js`（整段 `@js:`/`<js>` 开头） | 226 | ArkWeb | ✅ |
| `embedded_js`（规则中段 `<js>…</js>`） | 87（+12 混合） | ArkWeb（能力路由命中网络方法） | ✅ |
| `post_js`（`选择器@js: 脚本`） | 17 | ArkWeb（`executePostProcessorJsFieldBatch`） | ✅ |
| **`template`（只有 `{{java.xxx}}`）** | **0** | JsRuntime 同步替换 | ❌ 但**一条都没有** |

方法分布：`java.ajax` 610、`java.post` 20、`java.ajaxAll` 14、`java.head` 12、`java.connect` 7。

**含 java 网络调用的源共 351 条（10.3%），其中 351 条都能走 ArkWeb；纯模板形态为 0 条。**

## 三、结论与更正

1. **KI-BS4 的「107 源不可用」不成立**。那个数字对应的是「规则里出现网络方法」的源，不是「跑不起来」的源。
2. **不需要重构 `RuleExecutionService` 的字段分派**。之前我据此计划的「把选择器字段整体交给 ArkWeb」是伪需求。
3. 仍然存在的真实缺口只有一条：**引擎没有「按书源持久化登录态」的端口**（`core/host/SourceEngineHost.ts` 只有 cookie / 限流 / 脚本执行 / Web 会话 / 诊断五个端口），所以 `java.getLoginHeader` / `putLoginInfo` 这批是**会话级模拟**（同一次运行内读写一致、跨运行不丢），见提交 `aa7c593`。
4. 未抽查的尾巴：`other` 形态 6 条（脚本既不以 `@js:` 开头、也不含 `<js>`、也不是 `@js:` 后缀），需要逐条看，但不影响上述结论的量级。

## 四、顺带修掉的可观测性问题

旧行为：值级 `java.ajax` 求不出来时，`JsRuntime` 会把表达式**原样当字符串返回**，调用方拿到的是 `java.ajax('…')` 这串代码，真机上只表现为「正文/书名变成一串代码」，日志里什么都没有。
现在命中 `ajax/ajaxAll/connect/post/put/head/delete/patch` 时打 `console.warn`（带表达式前 80 字），可经 hilog 与 `app.log` 统计。求值行为不变（提交 `cb98cfe`）。
