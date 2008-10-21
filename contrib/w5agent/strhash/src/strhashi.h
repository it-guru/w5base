/*
 * Copyright (C) 2000-2002 Uwe Ohse, uwe@ohse.de
 * This is free software, licensed under the terms of the GNU Lesser
 * General Public License Version 2.1, of which a copy is stored at:
 *    http://www.ohse.de/uwe/licenses/LGPL-2.1
 * Later versions may or may not apply, see 
 *    http://www.ohse.de/uwe/licenses/
 * for information after a newer version has been published.
 */
#ifndef strhashi_h
#define strhashi_h

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif
#include "uint32.h"

#ifdef DJBLIBS

#include "alloc.h"
#include "byte.h"
#include "error.h"
#define strhash_alloc(x) ((void *)alloc((x)))
#define strhash_free(x) alloc_free((void *)(x))
#define strhash_copy(to,n,from) byte_copy((to),(n),(from))

#else /* no DJBLIBS */

#include <stdlib.h>
#include <errno.h>
#include <string.h>
#define error_noent ENOENT
#define error_nomem ENOMEM
#define strhash_alloc(x) malloc((x))
#define strhash_free(x) free((x))
#define strhash_copy(to,n,from) memcpy((to),(from),(n))
#endif

/* internal:
 * key is used as a flag: if key is 0 then nothing was ever at that place.
 * if key is not 0 and keylen is 0 then something once was at that place.
 * this is used to speed up searches for nonexisting records.
 */

struct strhash_entry {
	uint32 hash;
	uint32 datalen;
	uint32 keylen;
	union {
		void *dataptr;
		char data[sizeof(void *)];
	} u;
};

void strhash_get(struct strhash_entry *, char **key, char **data);
#define strhash_allocated(x) (x & KLUDGEBIT)
#define strhash_reallen(x) (x & ~(KLUDGEBIT))

#define KLUDGEBIT 0x80000000

/* note: 
   KLUDGEBIT for key means:    key follows entry.
   NO KLUDGEBIT for key means: ptr to key follows entry.
   KLUDGEBIT for data means: 
        if (len > size(void *)) then u.dataptr points to malloced space.
		                        else u.data holds the data.
   NO KLUDGEBIT for data means: u.dataptr points to space.
*/      
#endif
