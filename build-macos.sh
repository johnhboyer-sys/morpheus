#!/bin/sh
# Build Morpheus and its Greek stem library on macOS (Apple clang, BSD make).
#
# What the stock build needs on a current Mac:
#  - The code is pre-ANSI C. Modern clang rejects implicit int and implicit
#    function declarations, so they are downgraded to warnings.
#  - Several routines copy within one buffer (strcpy in nextkey.c and
#    mkend.c, strcat in zap2ndbreath.c). That is undefined behaviour, and
#    macOS's _FORTIFY_SOURCE traps on it. src/includes/overlap_safe.h is
#    force-included into every compile and turns strcpy and strcat into
#    memmove-based functions, defined for overlapping buffers. Fortify stays
#    on, so any other overlap still traps instead of passing.
#  - Every run rebuilds from clean, so objects from an older build with
#    different flags are never reused.
#  - stemlib/Greek/stemsrc/nom.irreg and vbs.irreg are committed upstream
#    data and are deliberately NOT regenerated: rebuilding them with this
#    buildword loses accents (Διός comes out *dios) and drops forms
#    (Πύκνα). The script fails if a build ever changes them.
#  - macOS ships the lex library as -ll, not -lfl.
#  - stemlib/Greek/makefile now builds the derivation tables before the verb
#    index that reads them (previously regular verbs such as λέγω came out
#    unparsed). The stem build is forced serial: its steps share files.
#
# Usage: ./build-macos.sh        (from anywhere)
# Then:  MORPHLIB=stemlib bin/cruncher < wordlist > crunched
set -eu
cd "$(dirname "$0")"
ROOT=$(pwd)
case $ROOT in
  *[[:space:]]*) echo "build-macos.sh: move the checkout to a path without spaces ($ROOT)" >&2; exit 1 ;;
esac
SAFE="-include $ROOT/src/includes/overlap_safe.h"
MAKEFLAGS=; export MAKEFLAGS

CFLAGS="-std=gnu89 -w -O0 $SAFE \
 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion \
 -Wno-incompatible-pointer-types -Wno-return-type -I../includes"

(cd src && make clean >/dev/null 2>&1 || true)
rm -rf bin
(cd stemlib/Greek && rm -f stemsrc/stripref stemsrc/zapfirstf stemsrc/headnolen stemsrc/goodstem stemsrc/flatlems)

(cd src && make CC=cc LOADLIBES=-ll LEXLIB=-ll CFLAGS="$CFLAGS" \
  && make CC=cc LOADLIBES=-ll LEXLIB=-ll CFLAGS="$CFLAGS" install)

PATH="$ROOT/bin:$PATH"; export PATH
(cd stemlib/Greek && MORPHLIB=.. make CC=cc CFLAGS="-std=gnu89 -w $SAFE")

if [ -d .git ] && ! git diff --quiet -- stemlib/Greek/stemsrc/nom.irreg stemlib/Greek/stemsrc/vbs.irreg; then
  echo "build-macos.sh: the build changed the committed nom.irreg/vbs.irreg; restore them with git checkout" >&2
  exit 1
fi

out=$(printf 'le/gein\n' | MORPHLIB=stemlib bin/cruncher) \
  || { echo "check failed: cruncher exited with an error" >&2; exit 1; }
case $out in
  *le/gw*) echo "Morpheus built; λέγειν parses as λέγω." ;;
  *) echo "check failed: λέγειν is not parsed as λέγω" >&2; exit 1 ;;
esac
