/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "alloc.h"
#include "gen_alloci.h"
int 
gen_alloc_ready(char **bptr, unsigned int bsize, unsigned int *len, 
	unsigned int *a, unsigned int newa)
{
	if (!*bptr) {
		*bptr=alloc(bsize * newa);
		if (!*bptr)
			return 0;
		*a=newa;
		*len=0;
		return 1;
	}
	if (newa > *a) {
		if (newa/8 < 16)
			newa+=16;
		else
			newa+=newa/8;
		if (!alloc_re(bptr,*a * bsize,  newa *bsize))
			return 0;
		*a=newa;
	}
	return 1;
}
