#!/bin/sh
# Build Scid (chess database) from source against Tcl/Tk 8.6 so it runs with
# Tiny Core's tcl8.6/tk8.6 extensions. Build on Ubuntu 22.04 (glibc <= Tiny Core's).
# Requires: cmake, build-essential, tcl8.6-dev, tk8.6-dev, git, squashfs-tools.
# Usage: scripts/build-scid.sh [dest-dir]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"
DEST=${1:-$ROOT/$OUT_DIR/optional}
WORK=$ROOT/$OUT_DIR/scid-src
SCID_TAG=${SCID_TAG:-v5.1.0}
mkdir -p "$DEST" "$WORK"; cd "$WORK"

[ -d scid ] || git clone -q --depth 1 --branch "$SCID_TAG" https://github.com/benini/scid.git
S="$WORK/stage"; rm -rf "$S" build; mkdir build
cmake -S scid -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local >/dev/null
cmake --build build -j"$(nproc)"
DESTDIR="$S" cmake --install build
rm -f "$DEST/scid.tcz"
mksquashfs "$S" "$DEST/scid.tcz" -noappend -quiet
(cd "$DEST" && md5sum scid.tcz > scid.tcz.md5.txt)
# Tiny Core dependency file consumed by tce-load
printf 'tcl8.6.tcz\ntk8.6.tcz\n' > "$DEST/scid.tcz.dep"
echo "built scid.tcz"
