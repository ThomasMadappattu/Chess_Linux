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
this script compiles Stockfish (`STOCKFISH_TAG`) and GNU Chess (`GNUCHESS_VER`)
from source as static binaries and packs each into a `.tcz` (squashfs) in
`build/optional/`. Needs `build-essential git curl squashfs-tools`.

## scripts/build-iso.sh
1. Downloads the stock ISO (`TinyCorePure64-*`).
2. Extracts it with `xorriso`, copies extensions to `cde/optional`, writes `cde/onboot.lst`.
3. Packs `overlay/` into `boot/overlay.gz` (cpio newc) used as a second initrd.
4. Rewrites `isolinux.cfg` (kernel args `cde host=chesscore`) and builds a bootable ISO.

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
