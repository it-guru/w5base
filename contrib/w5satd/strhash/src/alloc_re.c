/* reimplementation of alloc_re by djb@cr.yp.to.
 * placed in the public domain by uwe@ohse.de
 */
#include "alloc.h"
#include "byte.h"

int 
alloc_re(char **old, unsigned int oldsize, unsigned int newsize)
{
	char *neu; /* hate c++ */

	neu = alloc(newsize);
	if (!neu) return 0;
	byte_copy(neu,oldsize,*old);
	alloc_free(*old);
	*old = neu;
	return 1;
}
