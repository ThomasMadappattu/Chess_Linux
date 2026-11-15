#!/bin/sh
# Package Python chess apps (PyChess, Lucas Chess) as .tcz extensions.
# The app source is bundled; Python dependencies not shipped by Tiny Core are
# installed by pip into ~/.chesscore/<app>-venv on first launch (needs network).
# Requires: git, squashfs-tools.
# Usage: scripts/build-python-apps.sh [dest-dir]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"
DEST=${1:-$ROOT/$OUT_DIR/optional}
WORK=$ROOT/$OUT_DIR/pyapps-src
mkdir -p "$DEST" "$WORK"

PYCHESS_TAG=${PYCHESS_TAG:-1.0.5}   # 1.1+ needs Python >= 3.11, Tiny Core has 3.9

pack() { # name stage
  rm -f "$DEST/$1.tcz"
  mksquashfs "$2" "$DEST/$1.tcz" -noappend -quiet
  (cd "$DEST" && md5sum "$1.tcz" > "$1.tcz.md5.txt")
  [ -z "${3:-}" ] || printf "%s\n" $3 > "$DEST/$1.tcz.dep"
}

# launcher <stage> <name> <app-dir> <pip-packages> <entry command>
launcher() {
  cat > "$1/usr/local/bin/$2" <<EOF
#!/bin/sh
V="\$HOME/.chesscore/$2-venv"
if [ ! -x "\$V/bin/python3" ]; then
  echo "First run: installing Python dependencies for $2 (needs network)..."
  python3 -m venv --system-site-packages "\$V" || exit 1
  "\$V/bin/pip" install $4 || exit 1
fi
cd $3
exec "\$V/bin/python3" $5 "\$@"
EOF
  chmod 755 "$1/usr/local/bin/$2"
}

cd "$WORK"

# --- PyChess ---
rm -rf pychess; git clone -q --depth 1 --branch "$PYCHESS_TAG" https://github.com/pychess/pychess.git
S="$WORK/stage-pychess"; rm -rf "$S"; mkdir -p "$S/usr/local/bin" "$S/usr/local/share"
rm -rf pychess/.git; cp -r pychess "$S/usr/local/share/pychess"
launcher "$S" pychess /usr/local/share/pychess '"SQLAlchemy<2" pexpect websockets' 'pychess'
pack pychess "$S" "python3.9.tcz python3.9-pip.tcz pygobject.tcz gtk3.tcz gtksourceview.tcz gtksourceview-gir.tcz py3.9cairo.tcz python3.9-psutil.tcz"; echo "built pychess.tcz"

# --- Lucas Chess ---
rm -rf lucaschess; git clone -q --depth 1 https://github.com/lukasmonk/lucaschessR2.git lucaschess
S="$WORK/stage-lucaschess"; rm -rf "$S"; mkdir -p "$S/usr/local/bin" "$S/usr/local/share"
rm -rf lucaschess/.git; cp -r lucaschess "$S/usr/local/share/lucaschess"
launcher "$S" lucaschess /usr/local/share/lucaschess/bin 'chardet sortedcontainers python-chess pillow pyside2 psutil polib deep_translator requests urllib3 idna certifi bs4' 'LucasR.py'
pack lucaschess "$S" "python3.9.tcz python3.9-pip.tcz libGL.tcz Xorg-7.7-lib.tcz"; echo "built lucaschess.tcz"
