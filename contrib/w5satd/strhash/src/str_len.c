/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "str.h"

unsigned int 
str_len(const char *s)
{
	unsigned int i=0;
	for (;;) {
		if (!s[i]) return i;
		i++;

		if (!s[i]) return i;
		i++;

		if (!s[i]) return i;
		i++;

		if (!s[i]) return i;
		i++;
	}
}
