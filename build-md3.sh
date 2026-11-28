#!/usr/bin/env bash
# build-md3.sh — 编译参考鸿蒙项目 legado-harmonyos（legado-with-MD3 移植）
#   构建在 /root 的 ext4 盘做（/mnt/d 是 drvfs，hvigor 会卡 IO），产物 HAP 拷回工作区
set -eo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SDK_ROOT=/root/ohos-hms/sdk-hms-4052b12129c566db2033
BUILD_ROOT=/root/legado-md3-build
LOG=${BUILD_LOG:-/root/legado-md3-build.log}
NODE_HEAP=${NODE_HEAP:-16384}

export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=http://127.0.0.1:7890
export HTTP_PROXY=$http_proxy HTTPS_PROXY=$https_proxy ALL_PROXY=$all_proxy
export no_proxy=127.0.0.1,localhost,::1

mkdir -p "$BUILD_ROOT"
echo "[md3] sync $(date '+%H:%M:%S')"
rsync -a --delete --checksum \
  --exclude 'node_modules' --exclude 'build' --exclude '.git' --exclude 'oh_modules' \
  --exclude '.hvigor' --exclude 'local.properties' --exclude '.cxx' \
  "$HERE/" "$BUILD_ROOT/proj/" >/dev/null
ln -sfn "$HERE/node_modules" "$BUILD_ROOT/proj/node_modules"
printf 'sdk.dir=%s\n' "$SDK_ROOT" > "$BUILD_ROOT/proj/local.properties"
bash "$HERE/scripts/link-ohmodules-md3.sh" "$BUILD_ROOT/proj" >/dev/null 2>&1 || \
  echo "[md3] WARN: link-ohmodules 失败"

cd "$BUILD_ROOT/proj"
echo "[md3] build $(date '+%H:%M:%S') heap=${NODE_HEAP}M log=$LOG"
START=$(date +%s)
env -u DEVECO_SDK_HOME \
  HVIGOR_USER_HOME=/root/ohos-sdk-build/hvigor-home \
  OHOS_BASE_SDK_HOME="$SDK_ROOT" \
  PATH="/mnt/e/tools/ohbuild/jdk/bin:$PATH" \
  node --max-old-space-size=$NODE_HEAP node_modules/@ohos/hvigor/bin/hvigor.js \
  --mode module -p product=default -p module=entry@default assembleHap \
  --no-daemon --no-parallel > "$LOG" 2>&1
RC=$?
COST=$(( $(date +%s) - START ))
grep -E 'ERROR|COMPILE RESULT' "$LOG" | tail -12 || true
HAP_REL=entry/build/default/outputs/default/entry-default-unsigned.hap
if [ $RC -eq 0 ] && [ -f "$BUILD_ROOT/proj/$HAP_REL" ]; then
  mkdir -p "$HERE/entry/build/default/outputs/default"
  cp "$BUILD_ROOT/proj/$HAP_REL" "$HERE/$HAP_REL"
  echo "[md3] OK (${COST}s) -> $HERE/$HAP_REL ($(du -h "$HERE/$HAP_REL" | cut -f1))"
else
  echo "[md3] FAIL rc=$RC (${COST}s) log=$LOG"
fi
exit $RC
