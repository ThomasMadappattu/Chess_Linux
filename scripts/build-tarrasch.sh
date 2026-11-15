#!/bin/sh
# Build Tarrasch Chess GUI (wxWidgets/GTK2) and pack it as tarrasch.tcz.
# wxWidgets is linked statically (minimal feature set, bundled image libs) so only
# gtk2.tcz is needed at runtime and no shared wx libraries are loaded into RAM.
# Build on Ubuntu 22.04. Requires: build-essential libgtk2.0-dev libx11-dev
#   libxxf86vm-dev libsm-dev git squashfs-tools curl
# Usage: scripts/build-tarrasch.sh [dest-dir]
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"
DEST=${1:-$ROOT/$OUT_DIR/optional}
WORK=$ROOT/$OUT_DIR/tarrasch-src
WX_VER=${WX_VER:-3.0.5.1}
TARRASCH_REF=${TARRASCH_REF:-tarrasch-v3.13b}
mkdir -p "$DEST" "$WORK"; cd "$WORK"

# --- static wxWidgets (3.0.x is what Tarrasch targets) ---
if [ ! -x wx-install/bin/wx-config ]; then
  [ -f wx.tar.bz2 ] || curl -fL -o wx.tar.bz2 \
    "https://github.com/wxWidgets/wxWidgets/releases/download/v$WX_VER/wxWidgets-$WX_VER.tar.bz2"
  rm -rf wx-src; mkdir wx-src; tar -xjf wx.tar.bz2 -C wx-src --strip-components=1
  (cd wx-src && ./configure --prefix="$WORK/wx-install" --with-gtk=2 --disable-shared \
      --disable-debug --disable-webview --disable-mediactrl --disable-tests \
      --with-libpng=builtin --with-libjpeg=builtin --with-zlib=builtin \
      --with-expat=builtin --without-libtiff --without-opengl \
      CXXFLAGS="-O2 -w" >/dev/null && make -j"$(nproc)" >/dev/null && make install >/dev/null)
fi
export PATH="$WORK/wx-install/bin:$PATH"

# --- Tarrasch ---
rm -rf tarrasch; git clone -q --depth 1 --branch "$TARRASCH_REF" https://github.com/billforsternz/tarrasch-chess-gui.git tarrasch
cd tarrasch/src
# Link only the wx libraries that were built; keep default C++ flags but tolerate old-style code
sed -i 's|wx-config --libs all|wx-config --libs std,aui,richtext,html,xml|; s|-g -std=c++11|-O2 -w -fpermissive -std=gnu++14|' Makefile
make -j"$(nproc)"
cd ..

S="$WORK/stage"; rm -rf "$S"; mkdir -p "$S/usr/local/bin" "$S/usr/local/share/tarrasch"
install -m 755 tarrasch "$S/usr/local/share/tarrasch/tarrasch"
strip "$S/usr/local/share/tarrasch/tarrasch" || true
cp install/book.pgn install/Tarrasch.ini install/licence.txt "$S/usr/local/share/tarrasch/" 2>/dev/null || true
cp -r install/web "$S/usr/local/share/tarrasch/" 2>/dev/null || true
cat > "$S/usr/local/bin/tarrasch" <<'EOF'
#!/bin/sh
# Tarrasch looks for book.pgn next to the binary
cd /usr/local/share/tarrasch && exec ./tarrasch "$@"
EOF
chmod 755 "$S/usr/local/bin/tarrasch"

rm -f "$DEST/tarrasch.tcz"
mksquashfs "$S" "$DEST/tarrasch.tcz" -noappend -quiet
(cd "$DEST" && md5sum tarrasch.tcz > tarrasch.tcz.md5.txt)
printf 'gtk2.tcz\n' > "$DEST/tarrasch.tcz.dep"
echo "built tarrasch.tcz"
