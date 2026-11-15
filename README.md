<p align="center"><img src="docs/images/chessix-logo.svg" alt="Chessix Linux" width="480"></p>

# Chessix Linux

> **Revive old PCs. Play better chess.**

## Mission

Millions of perfectly good computers are thrown away because modern software
has outgrown them. Chessix Linux gives them a second life: a tiny,
fast, free operating system built on [Tiny Core Linux](http://tinycorelinux.net)
with the lightweight IceWM desktop, preloaded with free chess software, so
anyone - a school club, a local chess society, a student, a retiree - can turn
a forgotten machine into a complete chess workstation, with no cost and no
e-waste.

**For chess enthusiasts:** play, analyse, study and manage game databases with
Cute Chess, Scid, PyChess, Lucas Chess, Stockfish, Ethereal and GNU Chess, plus DOSBox-X
for classic DOS chess programs.

**For the planet and your wallet:** reuse hardware instead of discarding it.

## Build

    sh scripts/fetch-packages.sh   # download .tcz extensions + deps
    sh scripts/build-engines.sh    # static engines -> .tcz
    sh scripts/build-iso.sh        # build/chesscore-*.iso

GitHub Actions builds the ISO automatically. Details: [docs/scripts.md](docs/scripts.md).
