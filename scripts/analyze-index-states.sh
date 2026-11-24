#!/bin/bash
# analyze-index-states.sh — 统计 Index.ets 的 @State 并按归属分派
# 用法: ./scripts/analyze-index-states.sh [ets_root]
# 产出: build/index-split-report.txt
set -eo pipefail
ROOT=${1:-legado-harmonyos/entry/src/main/ets}
IDX="$ROOT/pages/Index.ets"
[ -f "$IDX" ] || { echo "找不到 $IDX"; exit 1; }
echo "# Index.ets 状态分派报告"
echo "总行数: $(wc -l < "$IDX")"
echo "@State 总数: $(grep -c "@State" "$IDX" || true)"
echo "@Builder: $(grep -c "@Builder" "$IDX" || true)"
echo "@Watch: $(grep -c "@Watch" "$IDX" || true)"
echo "私有方法: $(grep -cE "^  (private |async )?[a-zA-Z_]+[(]" "$IDX" || true)"
echo
echo "## 按归属分派"
awk '/@State/ {
  s = $0
  sub(/^[ \t]*@State[ \t]*/, "", s)
  if (s ~ /^@Watch/) sub(/^@Watch[(][^)]*[)][ \t]*/, "", s)
  if (match(s, /^[a-zA-Z_][a-zA-Z0-9_]*/)) print substr(s, RSTART, RLENGTH)
}' "$IDX" | sort -u | awk '{
  n = $0
  if (n ~ /ReturnRoute$/)                      b["DEL_ROUTER"]++
  else if (n ~ /^(show|is[A-Z].*Visible)/)     b["OVERLAY"]++
  else if (n == "route" || n == "selectedTab") b["NAV_STACK"]++
  else if (n ~ /^read/)                        b["READER"]++
  else if (n ~ /^(theme|palette)/)             b["THEME_STORE"]++
  else if (n ~ /^(book|shelf|group)/)          b["BOOKSHELF_STORE"]++
  else                                         b["KEEP_SHELL"]++
}
END { split("DEL_ROUTER READER THEME_STORE NAV_STACK BOOKSHELF_STORE OVERLAY KEEP_SHELL", o, " ")
      for (i = 1; i <= 7; i++) printf "%-18s %d\n", o[i], b[o[i]] + 0 }
'
echo
echo "## 判读"
echo "应移出 Index : READER + THEME_STORE + DEL_ROUTER + NAV_STACK"
echo "留在 Index 壳: KEEP_SHELL + OVERLAY + BOOKSHELF_STORE"
