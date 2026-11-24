#!/usr/bin/env python3
"""gen-state-plan.py - 逐条分派 Index.ets 的 @State，产出 STATE.md
用法: python3 scripts/gen-state-plan.py [ets_root] [out.md]
"""
import re, sys, os
from collections import Counter

BT = chr(96)  # 反引号，避免与本文件宿主模板冲突

root = sys.argv[1] if len(sys.argv) > 1 else "legado-harmonyos/entry/src/main/ets"
out  = sys.argv[2] if len(sys.argv) > 2 else "legado-harmonyos-plan/STATE.md"
src  = os.path.join(root, "pages/Index.ets")
text = open(src, encoding="utf-8").read()
lines = text.splitlines()

pat = re.compile(r"@State\s*(?:@Watch\([^)]*\)\s*)?([A-Za-z_][A-Za-z0-9_]*)")
found = []
for i, ln in enumerate(lines, 1):
    m = pat.search(ln)
    if m:
        found.append((i, m.group(1), ln.strip()))

def classify(name):
    n = name
    if n.endswith("ReturnRoute"):
        return ("删除-路由", "shell/router", "NavPathStack 自动管理返回栈")
    if n in ("route", "selectedTab"):
        return ("删除-路由", "shell/router", "NavPathStack / AppTabBar L3")
    if re.match(r"^(reader|read|showReader|shareReader|selectedChapter|pendingBookmarkTarget)", n):
        return ("下沉-L2", "feature/reader", "ReaderStore")
    if re.match(r"^(theme|palette|color|dark|showTheme)", n):
        return ("下沉-L1", "store/ThemeStore", "AppStorage + ThemeStore")
    if re.match(r"^(web[Dd]av|backup|restore|restoreIgnoreKeys)", n):
        return ("归位", "feature/backup", "BackupStore")
    if re.match(r"^(bookSource|source|login|debug|replace|txtToc|dict|highlight)", n):
        return ("归位", "feature/source", "SourceStore / 对应页 L3")
    if re.match(r"^(book|shelf|notShelf|refreshingBook|group|localBook|selectedBook)", n):
        return ("归位", "feature/bookshelf", "BookshelfStore")
    if re.match(r"^(search|discover|explore)", n):
        return ("归位", "feature/search", "SearchStore")
    if re.match(r"^(home|rss|subscribe|subscription)", n):
        return ("归位", "feature/discover", "对应域 Store")
    if re.match(r"^(profile|setting|app)", n):
        return ("归位", "feature/profile", "SettingsStore")
    if re.match(r"^(log|webDavTesting)", n):
        return ("归位", "platform", "AppLog / 调试页 L3")
    if re.match(r"^(show|is[A-Z].*Visible|[a-z]+Open|.*Sheet|.*Dialog)", n):
        return ("留壳-L3", "shell/components/OverlayHost", "组件级 @State")
    return ("留壳", "shell/AppShell", "主壳自身状态（需逐条复核）")

rows = [(ln, name, *classify(name)) for ln, name, raw in found]
buckets = Counter(r[2] for r in rows)
targets = Counter(r[3] for r in rows)

os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w", encoding="utf-8") as f:
    f.write("# 342 个 @State 逐条归属表\n\n")
    f.write("> 由 " + BT + "scripts/gen-state-plan.py" + BT + " 生成，勿手工编辑。源 " + BT + "pages/Index.ets" + BT + "\n")
    f.write("> 改规则请改脚本再重新生成，不要直接编辑本表。\n\n")
    f.write("实测匹配总数：**" + str(len(rows)) + " 个**\n\n")
    f.write("## 分派汇总\n\n| 处置 | 条数 |\n| --- | --- |\n")
    for k, v in buckets.most_common():
        f.write("| " + k + " | " + str(v) + " |\n")
    f.write("\n## 目标归属汇总\n\n| 目标位置 | 条数 |\n| --- | --- |\n")
    for k, v in targets.most_common():
        f.write("| " + BT + k + BT + " | " + str(v) + " |\n")
    f.write("\n## 逐条明细\n\n| 行号 | 状态名 | 处置 | 目标 | 备注 |\n| --- | --- | --- | --- | --- |\n")
    for ln, name, disp, tgt, note in sorted(rows):
        f.write("| " + str(ln) + " | " + BT + name + BT + " | " + disp + " | " + BT + tgt + BT + " | " + note + " |\n")
print("写入 " + out + "：" + str(len(rows)) + " 条")
for k, v in buckets.most_common():
    print("  " + k + ": " + str(v))
