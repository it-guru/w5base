/* reimplementation of gen_alloc.h by djb@cr.yp.to.
 * placed in the public domain by uwe@ohse.de.
 */
#ifndef GEN_ALLOC_H
#define GEN_ALLOC_H

/* note: this has to be compatible or lots of stuff breaks. */
#define GEN_ALLOC_typedef(typename,basetype,basename,lenname,allocname) \
	typedef struct typename { \
		basetype *basename; \
		unsigned int lenname; \
		unsigned int allocname; \
	} typename;

#endif
