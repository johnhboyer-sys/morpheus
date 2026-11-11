#!/bin/sh
# Build Morpheus and its Greek stem library on macOS (Apple clang, BSD make).
#
# What the stock build needs on a current Mac:
#  - The code is pre-ANSI C. Modern clang rejects implicit int and implicit
#    function declarations, so they are downgraded to warnings.
#  - Several routines strcpy within one buffer (nextkey.c, mkend.c). That is
#    undefined behaviour, and macOS's _FORTIFY_SOURCE traps on it.
#    src/includes/overlap_safe.h is force-included into every compile and
#    turns strcpy into memmove, which is defined for overlapping buffers.
#    Fortify stays on, so any other overlap still traps instead of passing.
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
SAFE="-include $ROOT/src/includes/overlap_safe.h"
MAKEFLAGS=; export MAKEFLAGS

CFLAGS="-std=gnu89 -w -O0 $SAFE \
 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion \
 -Wno-incompatible-pointer-types -Wno-return-type -I../includes"

(cd src && make CC=cc LOADLIBES=-ll LEXLIB=-ll CFLAGS="$CFLAGS" \
  && make CC=cc LOADLIBES=-ll LEXLIB=-ll CFLAGS="$CFLAGS" install)

PATH="$ROOT/bin:$PATH"; export PATH
(cd stemlib/Greek && MORPHLIB=.. make CC=cc CFLAGS="-std=gnu89 -w $SAFE")

out=$(printf 'le/gein\n' | MORPHLIB=stemlib bin/cruncher) \
  || { echo "check failed: cruncher exited with an error" >&2; exit 1; }
case $out in
  *le/gw*) echo "Morpheus built; λέγειν parses as λέγω." ;;
  *) echo "check failed: λέγειν is not parsed as λέγω" >&2; exit 1 ;;
esac
