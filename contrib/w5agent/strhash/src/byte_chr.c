/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */

#include "byte.h"

unsigned int 
byte_chr(const char *s, unsigned int n, int searched)
{
	char ch=searched;
	const char *p=s;

	for (;;) {
		if (!n) break; 
		if (*p == ch) break; ++p; --n;

		if (!n) break; 
		if (*p == ch) break; ++p; --n;

		if (!n) break; 
		if (*p == ch) break; ++p; --n;

		if (!n) break; 
		if (*p == ch) break; ++p; --n;
	}
	return p - s;
}
