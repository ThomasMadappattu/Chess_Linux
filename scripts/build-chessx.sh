#!/bin/sh
# Build ChessX (Qt5 chess database/GUI) and pack it as chessx.tcz.
# Build on Ubuntu 22.04 (Qt 5.15, glibc compatible with Tiny Core 15).
# Requires: qtbase5-dev qttools5-dev-tools qtmultimedia5-dev libqt5svg5-dev
#           libqt5texttospeech5-dev(optional) zlib1g-dev git squashfs-tools
# Usage: scripts/build-chessx.sh [dest-dir]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"
DEST=${1:-$ROOT/$OUT_DIR/optional}
WORK=$ROOT/$OUT_DIR/chessx-src
CHESSX_REF=${CHESSX_REF:-master}
mkdir -p "$DEST" "$WORK"; cd "$WORK"

rm -rf chessx; git clone -q --depth 1 --branch "$CHESSX_REF" https://github.com/Isarhamster/chessx.git
cd chessx
lrelease -silent chessx.pro >/dev/null 2>&1 || true
qmake PREFIX=/usr/local CONFIG+=release chessx.pro
make -j"$(nproc)"

S="$WORK/stage"; rm -rf "$S"; mkdir -p "$S/usr/local/bin" "$S/usr/local/share/chessx"
BIN=$(find . -maxdepth 2 -type f -name chessx -perm -u+x | head -n1)
install -m 755 "$BIN" "$S/usr/local/bin/chessx"
strip "$S/usr/local/bin/chessx" || true
cp -r data i18n "$S/usr/local/share/chessx/" 2>/dev/null || cp -r data "$S/usr/local/share/chessx/"

rm -f "$DEST/chessx.tcz"
mksquashfs "$S" "$DEST/chessx.tcz" -noappend -quiet
(cd "$DEST" && md5sum chessx.tcz > chessx.tcz.md5.txt)
printf 'qt-5.x-all.tcz\n' > "$DEST/chessx.tcz.dep"
echo "built chessx.tcz"
