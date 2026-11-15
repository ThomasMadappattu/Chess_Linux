# Scripts and configuration

## Overview
ChessCore remasters the official Tiny Core Linux ISO. Chess applications and
IceWM are added as `.tcz` extensions in `/cde` on the CD (loaded via the `cde`
boot code), and a small overlay initrd configures the IceWM session.

```
fetch-packages.sh  ->  build/optional/*.tcz
build-iso.sh       ->  build/chesscore-<release>-<arch>.iso
```

## config/build.conf
Variables (override via environment): `TC_VERSION` (15.x), `TC_RELEASE` (15.0),
`TC_ARCH` (default `x86_64`; the Tiny Core repo only ships chess software for x86_64), `TC_MIRROR`, `OUT_DIR`, `ISO_NAME`.

## config/packages.list
Extensions to download (one per line, `#` comments). Dependencies are read
from each `.dep` file and fetched recursively. Names unavailable for the chosen
architecture are skipped and written to `build/missing.txt` - not all chess
packages exist on every arch/release, so check that file.

## config/onboot.list
Subset written to `/cde/onboot.lst`; only entries actually downloaded are kept.

## scripts/fetch-packages.sh `[list] [dest]`
Downloads `.tcz`, `.tcz.md5.txt`, `.tcz.dep` from `$TC_MIRROR/$TC_VERSION/$TC_ARCH/tcz`,
verifies md5, recurses through dependencies. Needs `curl`, `md5sum`.

## scripts/build-engines.sh
The Tiny Core repo has no chess engines (only the `cutechess` GUI on x86_64), so
this script compiles Stockfish (`STOCKFISH_TAG`), GNU Chess (`GNUCHESS_VER`) and Ethereal (`ETHEREAL_TAG`, classical eval)
from source as static binaries and packs each into a `.tcz` (squashfs) in
`build/optional/`. Needs `build-essential git curl squashfs-tools`.

## scripts/build-scid.sh
Builds Scid (`SCID_TAG`, default v5.1.0) with CMake against Tcl/Tk 8.6 and packs `scid.tcz`
(`.dep`: tcl8.6, tk8.6). Build on Ubuntu 22.04 so glibc is compatible with Tiny Core.

## scripts/build-chessx.sh
Builds ChessX (CHESSX_REF, default master) with qmake against Qt 5 and packs chessx.tcz (.dep: qt-5.x-all).

## scripts/build-tarrasch.sh
Builds Tarrasch Chess GUI (TARRASCH_REF, default tarrasch-v3.13b) against a statically linked, minimal wxWidgets (WX_VER, default 3.0.5.1, GTK2, bundled image libs) so only gtk2.tcz is loaded at runtime (low RAM). Installs to /usr/local/share/tarrasch with a /usr/local/bin/tarrasch launcher.

## data/
Sample game database (Lichess open database, CC0) - see data/README.md.

## DOSBox-X
**DOSBox-X** comes straight from the Tiny Core repo (`dosbox-x.tcz`).

## scripts/build-iso.sh
1. Downloads the stock ISO (`TinyCorePure64-*`).
2. Extracts it with `xorriso`, copies extensions to `cde/optional`, writes `cde/onboot.lst`.
3. Copies `overlay/` to a staging dir, unpacks the Windows XP IceWM themes (`themes/icewm-WindowsXP.tar.gz`, Silver variant selected in `~/.icewm/preferences`; Olive and Zune are also included) into it, and packs it into `boot/overlay.gz` (cpio newc) used as a second initrd.
4. Rewrites `isolinux.cfg` with two boot entries and builds a bootable ISO: **shell** (default for now, kernel arg `text`: no X, log in as `tc` and run `startx` manually; `sudo -i` gives root) and **desktop** (auto-starts X/IceWM). Append `chessdebug` to the kernel line to dump X diagnostics to `ttyS0`.

Needs `xorriso`, `cpio`, `gzip`, `curl`.

## overlay/
- `home/tc/.xsession` - starts `icewm-session`.
- `home/tc/.icewm/menu`, `toolbar` - chess launchers.
- `opt/bootlocal.sh` - fixes ownership of `/home/tc` at boot.

## GitHub Actions (`.github/workflows/build.yml`)
Builds x86_64 on push, PR, manually, and weekly (to pick up updated
Tiny Core packages). The ISO and `missing.txt` are uploaded as artifacts; tags
(`v*`) also publish a release.

## Testing
`qemu-system-x86_64 -m 2048 -cdrom build/chesscore-15.0-x86_64.iso`

## Notes
Package availability and exact command names depend on the Tiny Core
repository; the build was not run or booted in this authoring environment.
