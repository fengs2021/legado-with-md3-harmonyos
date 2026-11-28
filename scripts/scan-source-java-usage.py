#!/usr/bin/env python3
"""统计书源里 java 网络调用的用法形态，判断有多少条真的走不到 ArkWeb 运行时。

口径（对应 docs/booksource/JAVA-BRIDGE-RECHECK.md）：
  · full_js      ：规则以 @js: / <js> 开头 —— 整段脚本，RuleExecutionService.executeFullJsFieldBatch，走 ArkWeb
  · embedded_js  ：规则中间带 <js>…</js> 段 —— extractEmbeddedJsProcessor，按能力路由，命中网络方法即 ArkWeb
  · post_js      ：规则以 "@js:" 结尾（如 "选择器@js: 脚本"）—— extractPostProcessorJs，走 ArkWeb
  · template     ：只有 {{java.xxx}} 模板 —— 走 JsRuntime 同步替换层，**这里没有网络能力**，才真踩坑

用法：python3 scripts/scan-source-java-usage.py <bookSource.json>
退出码：0 正常；2 参数缺失
"""
import json
import re
import sys
import collections

NET = re.compile(r"java\.(ajax|ajaxAll|connect|post|head|delete|patch)\b")
# java.put 在源里九成是「写变量 (k,v)」，不是 HTTP PUT，统计网络调用时排除，避免虚高
FIELD_KEYS = {"ruleSearch", "ruleBookInfo", "ruleToc", "ruleContent", "ruleExplore"}
FULL_JS = re.compile(r"^\s*(@js:|<js>)")
EMBED_JS = re.compile(r"<js>", re.I)
POST_JS = re.compile(r"@js:\s*\S")
TPL = re.compile(r"\{\{[\s\S]*?java\.")


def classify(value: str) -> str:
    if FULL_JS.match(value):
        return "full_js"
    if EMBED_JS.search(value):
        return "embedded_js"
    if POST_JS.search(value):
        return "post_js"
    if TPL.search(value):
        return "template"
    return "other"


def main() -> int:
    if len(sys.argv) < 2:
        print("用法: python3 scripts/scan-source-java-usage.py <bookSource.json>", file=sys.stderr)
        return 2
    sources = json.load(open(sys.argv[1], encoding="utf-8"))
    buckets = collections.Counter()
    methods = collections.Counter()
    risky = []
    for source in sources:
        kinds = set()
        for key, rule in source.items():
            if key not in FIELD_KEYS or not isinstance(rule, dict):
                continue
            for field_name, value in rule.items():
                if not isinstance(value, str):
                    continue
                hit = NET.search(value)
                if not hit:
                    continue
                for m in NET.finditer(value):
                    methods[m.group(0)] += 1
                kinds.add(classify(value))
                if classify(value) == "template":
                    risky.append((source.get("bookSourceName") or "",
                                  key + "." + field_name, value[:100].replace("\n", " ")))
        if kinds:
            buckets["+".join(sorted(kinds))] += 1

    total = sum(buckets.values())
    print("书源总数:", len(sources))
    print("含 java 网络调用的书源:", total)
    for shape, count in buckets.most_common():
        print("  {:32s} {}".format(shape, count))
    print()
    print("方法分布:", dict(methods))
    print()
    print("纯模板形态（JsRuntime 通道求不出来）:", buckets.get("template", 0))
    for name, field, text in risky[:10]:
        print("  -", name, "|", field, "|", text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
