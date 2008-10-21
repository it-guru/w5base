/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */

/* this implementation tries to mimic the original closely. */

#include "alloc.h"
#include "error.h"
#include <stdlib.h>

/* This must be a power of 2. */
/* XXX: This assumes that this alignment is enough. */
#define ALIGNMENT (16)

/* sysconf(_SC_PAGESIZE) would be better. oh well. */
#define BUFFERSIZE 4096

/* a bit of magic to stop overly clever compilers? */
typedef union { char c[ALIGNMENT]; double d; } aligned;
static aligned buf[BUFFERSIZE / ALIGNMENT];

static unsigned int free_space = BUFFERSIZE; /* amount of free space in buf */

char *
alloc(unsigned int bytes)
{
	bytes += ALIGNMENT - (bytes & (ALIGNMENT -1));
	if (bytes > free_space) {
		char *p;
		p = malloc(bytes);
		if (!p) {
			/* write(2,"out of memory\n",14); */
			errno = error_nomem;
		}
		return p;
	}
	free_space -= bytes; 
	return ((char *)buf) + free_space;
}

void 
alloc_free(char *s)
{
	if (s >= ((char *)buf) && s < ((char *)buf) + BUFFERSIZE)
		return; /* too bad we can't free the space */
	free(s);
}
