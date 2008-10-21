/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "stralloc.h"
#include "byte.h"

int
stralloc_catb (stralloc * sa, const char *str, unsigned int len)
{
	if (!stralloc_readyplus (sa, len + 1))
		return 0;
	byte_copy (sa->s + sa->len, len, str);
	sa->len += len;
	sa->s[sa->len] = 'Z'; /* djb */
	return 1;
}
