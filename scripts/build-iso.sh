#!/bin/sh
# Remaster the Tiny Core ISO: add extensions under /cde, overlay config, icewm.
# Requires: curl, xorriso, cpio, gzip.
# Usage: scripts/build-iso.sh
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
. "$ROOT/config/build.conf"
B="$ROOT/$OUT_DIR"; mkdir -p "$B"

case $TC_ARCH in
  x86_64) SRC_ISO=TinyCorePure64-$TC_RELEASE.iso; KERNEL=vmlinuz64; INITRD=corepure64.gz ;;
  *)      SRC_ISO=TinyCore-$TC_RELEASE.iso;       KERNEL=vmlinuz;   INITRD=core.gz ;;
esac

[ -f "$B/$SRC_ISO" ] || curl -fL -o "$B/$SRC_ISO" "$TC_MIRROR/$TC_VERSION/$TC_ARCH/release/$SRC_ISO"
[ -d "$B/optional" ] || sh "$ROOT/scripts/fetch-packages.sh"

W="$B/iso"; rm -rf "$W"; mkdir -p "$W"
xorriso -osirrox on -indev "$B/$SRC_ISO" -extract / "$W" 2>/dev/null
chmod -R u+w "$W"

# Extensions (the "cde" boot code loads /cde/onboot.lst from the CD)
mkdir -p "$W/cde/optional"
cp "$B"/optional/* "$W/cde/optional/"
: > "$W/cde/onboot.lst"
grep -v '^[[:space:]]*\(#\|$\)' "$ROOT/config/onboot.list" > "$B/.onboot"
while read -r p; do
  [ -f "$W/cde/optional/${p%.tcz}.tcz" ] && echo "${p%.tcz}.tcz" >> "$W/cde/onboot.lst"
done < "$B/.onboot"
rm -f "$B/.onboot"

# Overlay initrd, loaded after the stock one
(cd "$ROOT/overlay" && find . | cpio -o -H newc --quiet | gzip -9) > "$W/boot/overlay.gz"

cat > "$W/boot/isolinux/isolinux.cfg" <<EOF
DEFAULT chesscore
PROMPT 0
TIMEOUT 50
LABEL chesscore
  KERNEL /boot/$KERNEL
  INITRD /boot/$INITRD,/boot/overlay.gz
  APPEND quiet cde waitusb=5 host=chesscore
EOF

xorriso -as mkisofs -iso-level 3 -V CHESSCORE -o "$B/$ISO_NAME" \
  -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table "$W"
echo "Built $B/$ISO_NAME"
