#!/usr/bin/env bash
# link-ohmodules-md3.sh — 给 legado-harmonyos 手工铺 oh_modules（本机无 ohpm）
#   与 legadoC 版的差别：quickjs 的 libquickjs 类型目录在 quickjs 包内部，
#   不是 entry/src/main/cpp/types/libquickjs。
set -eo pipefail
ROOT=$(cd "${1:?需要工程根目录}" && pwd)
cd "$ROOT"
rm -rf oh_modules entry/oh_modules

Q="$ROOT/third_party/harmony-book-source-engine/quickjs"
SE="$ROOT/third_party/harmony-book-source-engine/sourceengine"
LT="$Q/src/main/cpp/types/libquickjs"

mkdir -p entry/oh_modules/.ohpm/@devzeng+quickjs@0.1.0/oh_modules/@devzeng
mkdir -p entry/oh_modules/.ohpm/@legado+sourceengine@1.0.0/oh_modules/@legado
mkdir -p entry/oh_modules/.ohpm/libquickjs.so@1.0.0/oh_modules
mkdir -p entry/oh_modules/@devzeng entry/oh_modules/@legado

ln -sfn "$Q" entry/oh_modules/.ohpm/@devzeng+quickjs@0.1.0/oh_modules/@devzeng/quickjs
ln -sfn "$SE" entry/oh_modules/.ohpm/@legado+sourceengine@1.0.0/oh_modules/@legado/sourceengine
ln -sfn "$LT" entry/oh_modules/.ohpm/libquickjs.so@1.0.0/oh_modules/libquickjs.so
ln -sfn "$Q" entry/oh_modules/@devzeng/quickjs
ln -sfn "$SE" entry/oh_modules/@legado/sourceengine
ln -sfn "$LT" entry/oh_modules/libquickjs.so

# sourceengine 自己也要能解析 @devzeng/quickjs（它是独立 module）
mkdir -p "$SE/oh_modules/@devzeng"
ln -sfn "$Q" "$SE/oh_modules/@devzeng/quickjs"
mkdir -p "$Q/oh_modules"
ln -sfn "$LT" "$Q/oh_modules/libquickjs.so"

for p in entry/oh_modules/@devzeng/quickjs/Index.ts \
         entry/oh_modules/@legado/sourceengine/Index.ts \
         entry/oh_modules/libquickjs.so/Index.d.ts; do
  [ -e "$p" ] || { echo "link-ohmodules-md3: 断链 $p" >&2; exit 1; }
done
echo "link-ohmodules-md3: ok"
