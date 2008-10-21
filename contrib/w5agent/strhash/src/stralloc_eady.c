/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "stralloc.h"
#include "gen_alloci.h"

int
stralloc_ready(stralloc *x,unsigned int n)
{
	return  gen_alloc_ready(
		&x->s,
		sizeof(*x->s),
		&x->len,
		&x->a,
		n);
}
