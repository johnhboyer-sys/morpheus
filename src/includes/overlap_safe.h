/* Morpheus copies strings within one buffer (nextkey.c, mkend.c:
 * strcpy(s, s+1); zap2ndbreath.c: strcat(s, s+4)). Overlapping strcpy and
 * strcat are undefined behaviour, and macOS's _FORTIFY_SOURCE traps on them.
 * build-macos.sh force-includes this header into every compile. strcpy and
 * strcat become functions built on memmove: identical for disjoint buffers,
 * defined for overlapping ones. Functions, not macros, so each argument is
 * evaluated exactly once (stdiomorph.c passes argv[optind++]). */
#ifndef MORPHEUS_OVERLAP_SAFE_H
#define MORPHEUS_OVERLAP_SAFE_H
#include <string.h>
static inline char *morpheus_strcpy(char *d, const char *s)
{
	return (char *)memmove(d, s, strlen(s) + 1);
}
static inline char *morpheus_strcat(char *d, const char *s)
{
	size_t dl = strlen(d), sl = strlen(s);
	memmove(d + dl, s, sl + 1);
	return d;
}
#undef strcpy
#undef strcat
#define strcpy morpheus_strcpy
#define strcat morpheus_strcat
#endif
