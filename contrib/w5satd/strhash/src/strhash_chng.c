/*
 * Copyright (C) 2000-2002 Uwe Ohse, uwe@ohse.de
 * This is free software, licensed under the terms of the GNU Lesser
 * General Public License Version 2.1, of which a copy is stored at:
 *    http://www.ohse.de/uwe/licenses/LGPL-2.1
 * Later versions may or may not apply, see 
 *    http://www.ohse.de/uwe/licenses/
 * for information after a newer version has been published.
 */
#include "strhashi.h"
#include "strhash.h"

int strhash_change(strhash *lv0,
    int dataalloc, const char *data, uint32 datalen)
{
	struct strhash_entry **entries;
	uint32 h0;
	uint32 h1;
	uint32 h;
	char *d;
	int allocated=0;

	h=lv0->hash;
	h0=h % lv0->mod;
	h1=h / lv0->mod;
	h1=(h1+lv0->loop-1) % lv0->tab[h0].space;
	entries=lv0->tab[h0].entries;

	if (dataalloc && datalen > sizeof(void *)) {
		d=strhash_alloc(datalen);
		if (!d)  {
			errno=error_nomem;
			return -1;
		}
		allocated=1;
		strhash_copy(d,datalen,data);
	} else {
		union { const char *cc; char *c; } dq;
		dq.cc=data;
		d=dq.c;
	}
	if (strhash_allocated(entries[h1]->datalen))
		if (strhash_reallen(entries[h1]->datalen) > sizeof(void *))
			strhash_free(entries[h1]->u.dataptr);
	if (dataalloc) {
		if (allocated)
			entries[h1]->u.dataptr=d;
		else
			strhash_copy(entries[h1]->u.data,datalen,d);
	} else
		entries[h1]->u.dataptr=d;
	entries[h1]->datalen=datalen;
	if (dataalloc)
		entries[h1]->datalen|=KLUDGEBIT;
	return 1;
}

