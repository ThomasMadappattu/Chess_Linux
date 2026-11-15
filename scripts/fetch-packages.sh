#!/bin/sh
# Download Tiny Core extensions (+ .dep, .md5.txt) and their dependencies.
# Usage: scripts/fetch-packages.sh [packages.list] [dest-dir]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"

LIST=${1:-$ROOT/config/packages.list}
DEST=${2:-$ROOT/$OUT_DIR/optional}
BASE="$TC_MIRROR/$TC_VERSION/$TC_ARCH/tcz"
mkdir -p "$DEST"
MISSING="$DEST/../missing.txt"; : > "$MISSING"

fetch() { # name.tcz -> 0 on success
  curl -fsSL --retry 3 -o "$DEST/$1" "$BASE/$1" || { rm -f "$DEST/$1"; return 1; }
  curl -fsSL -o "$DEST/$1.md5.txt" "$BASE/$1.md5.txt" || rm -f "$DEST/$1.md5.txt"
  curl -fsSL -o "$DEST/$1.dep" "$BASE/$1.dep" 2>/dev/null || rm -f "$DEST/$1.dep"
  if [ -f "$DEST/$1.md5.txt" ]; then
    (cd "$DEST" && md5sum -c "$1.md5.txt" >/dev/null) || { rm -f "$DEST/$1"; return 1; }
  fi
}

get() {
  n=${1%.tcz}.tcz
  [ -f "$DEST/$n" ] && return 0
  if fetch "$n"; then
    echo "fetched $n"
    if [ -f "$DEST/$n.dep" ]; then
      while read -r d; do [ -n "$d" ] && get "$d"; done < "$DEST/$n.dep"
    fi
  else
    echo "WARN: $n not available for $TC_ARCH" >&2
    echo "$n" >> "$MISSING"
  fi
}

grep -v '^[[:space:]]*\(#\|$\)' "$LIST" > "$DEST/../.pkgs"
while read -r p; do get "$p"; done < "$DEST/../.pkgs"
rm -f "$DEST/../.pkgs"
echo "Done. $(ls "$DEST"/*.tcz 2>/dev/null | wc -l) extensions in $DEST; missing list: $MISSING"
