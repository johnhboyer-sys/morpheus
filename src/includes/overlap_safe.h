/* Morpheus copies strings within one buffer (e.g. nextkey.c, mkend.c:
 * strcpy(s, s+1)). Overlapping strcpy is undefined behaviour, and macOS's
 * _FORTIFY_SOURCE traps on it. Force-included by build-macos.sh so every
 * strcpy becomes a memmove: identical for disjoint buffers, defined for
 * overlapping ones. */
#ifndef MORPHEUS_OVERLAP_SAFE_H
#define MORPHEUS_OVERLAP_SAFE_H
#include <string.h>
#undef strcpy
#define strcpy(d, s) ((char *)memmove((d), (s), strlen(s) + 1))
#endif
