#!/bin/sh
# Build Morpheus and its Greek stem library on macOS (Apple clang, BSD make).
#
# Three things the stock makefiles need on a current Mac:
#  - The code is pre-ANSI C. Modern clang rejects implicit int and implicit
#    function declarations, so they are downgraded to warnings.
#  - Several routines strcpy between overlapping buffers. macOS's
#    _FORTIFY_SOURCE turns that into a trap (buildend crashes in nextkey),
#    so fortify is switched off. It does not change what Morpheus computes.
#  - macOS ships the lex library as -ll, not -lfl.
# The Greek stem build also has to run twice: `make all` builds the verb
# index before the derivation tables it reads exist, so the first run leaves
# regular verbs (λέγω, ἔχω) unindexed. The second run sees the tables.
#
# Usage: ./build-macos.sh        (from the repository root)
# Then:  MORPHLIB=stemlib bin/cruncher < wordlist > crunched
set -eu
cd "$(dirname "$0")"
ROOT=$(pwd)

CFLAGS="-std=gnu89 -w -O0 -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 \
 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion \
 -Wno-incompatible-pointer-types -Wno-return-type -I../includes"

(cd src && make CC=cc LOADLIBES=-ll LEXLIB=-ll CFLAGS="$CFLAGS" \
  && make CC=cc LOADLIBES=-ll LEXLIB=-ll CFLAGS="$CFLAGS" install)

PATH="$PATH:$ROOT/bin"; export PATH
cd stemlib/Greek
for pass in 1 2; do
  echo "stem library, pass $pass"
  MORPHLIB=.. make CC=cc CFLAGS="-std=gnu89 -w -D_FORTIFY_SOURCE=0"
done

cd "$ROOT"
printf 'le/gein\n' | MORPHLIB=stemlib bin/cruncher | grep -q 'le/gw' \
  || { echo "check failed: λέγειν is not parsed as λέγω" >&2; exit 1; }
echo "Morpheus built; λέγειν parses as λέγω."
