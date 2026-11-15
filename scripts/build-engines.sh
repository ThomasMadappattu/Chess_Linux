#!/bin/sh
# Build chess engines that Tiny Core does not package, as static binaries
# wrapped into .tcz (squashfs) extensions. Run on a Linux x86_64 build host.
# Requires: build-essential, git, curl, squashfs-tools.
# Usage: scripts/build-engines.sh [dest-dir]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"
DEST=${1:-$ROOT/$OUT_DIR/optional}
WORK=$ROOT/$OUT_DIR/engines-src
mkdir -p "$DEST" "$WORK"

STOCKFISH_TAG=${STOCKFISH_TAG:-sf_17.1}
GNUCHESS_VER=${GNUCHESS_VER:-6.2.9}

pack() { # name staging-dir
  rm -f "$DEST/$1.tcz"
  mksquashfs "$2" "$DEST/$1.tcz" -noappend -quiet
  (cd "$DEST" && md5sum "$1.tcz" > "$1.tcz.md5.txt")
  echo "built $1.tcz"
}

# --- Stockfish ---
cd "$WORK"
[ -d Stockfish ] || git clone --depth 1 --branch "$STOCKFISH_TAG" https://github.com/official-stockfish/Stockfish.git
(cd Stockfish/src && make -j"$(nproc)" build ARCH=x86-64 COMP=gcc EXTRALDFLAGS=-static)
S="$WORK/stage-stockfish"; rm -rf "$S"; mkdir -p "$S/usr/local/bin"
install -m 755 Stockfish/src/stockfish "$S/usr/local/bin/stockfish"
pack stockfish "$S"

# --- GNU Chess ---
[ -f gnuchess.tar.gz ] || curl -fsSL -o gnuchess.tar.gz "https://ftp.gnu.org/gnu/chess/gnuchess-$GNUCHESS_VER.tar.gz"
rm -rf "gnuchess-$GNUCHESS_VER"; tar xzf gnuchess.tar.gz
(cd "gnuchess-$GNUCHESS_VER" && ./configure --prefix=/usr/local --without-readline LDFLAGS=-static >/dev/null && make -j"$(nproc)" >/dev/null)
S="$WORK/stage-gnuchess"; rm -rf "$S"
(cd "gnuchess-$GNUCHESS_VER" && make install DESTDIR="$S" >/dev/null)
strip "$S/usr/local/bin/gnuchess" || true
pack gnuchess "$S"
