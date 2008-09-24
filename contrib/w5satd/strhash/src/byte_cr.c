/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "byte.h"

void
byte_copyr (char *to, unsigned int n, const char *from)
{
	for (;;) {
		if (!n--) return;
		to[n]=from[n];

		if (!n--) return;
		to[n]=from[n];

		if (!n--) return;
		to[n]=from[n];

		if (!n--) return;
		to[n]=from[n];
	}
}
