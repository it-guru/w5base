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


int strhash_enter(strhash *lv0,
	int keyalloc, const char *key, uint32 keylen,
    int dataalloc, const char *data, uint32 datalen)
{
	uint32 h;
	uint32 h0;
	uint32 h1;
	struct strhash_entry *lv2;
	struct strhash_entry ** entries;
	unsigned int i;
	unsigned int need;

	if ((keylen & KLUDGEBIT) || (datalen & KLUDGEBIT)) {
		errno=error_noent;
		return -1;
	}

	h=lv0->hashfunc(key,keylen);
	h0=h % lv0->mod;
	h1=h / lv0->mod;

	entries=lv0->tab[h0].entries;
	if (entries == 0) {
		entries=strhash_alloc(sizeof(void *) * lv0->startsize);
		if (!entries) {
			errno=error_nomem;
			return -1;
		}
		lv0->tab[h0].entries=entries;
		for (i=0;i<lv0->startsize;i++) 
			entries[i]=(struct strhash_entry *)0;
		lv0->tab[h0].space=lv0->startsize;
		lv0->tab[h0].count=0;
	}
	if (lv0->tab[h0].space/2<=lv0->tab[h0].count) {
		/* enlarge lv1 table, duplicate size */
		struct strhash_entry **n;
		unsigned int nspace=lv0->tab[h0].space * 2;
		unsigned int ospace=lv0->tab[h0].space;
		n = strhash_alloc(sizeof(struct strhash_entry) * nspace);
		if (!n) {
			errno=error_nomem; /* in case !djblibs */
			return -1;
		}
		for (i=0;i<nspace;i++)
			n[i]=0;
		for (i=0;i<ospace;i++)
			if (entries[i] && entries[i]!=(void *)&entries[i]) {
				uint32 hn;
				hn=entries[i]->hash/lv0->mod;
				hn%=nspace; /* new slot */
				while (1) {
					if (!n[hn]) 
						break;
					hn++;
					if (hn==nspace) 
						hn=0;
				}
				n[hn]=entries[i];
			}
		strhash_free(entries);
		lv0->tab[h0].entries=n;
		entries=n;
		lv0->tab[h0].space=nspace;
	}
	h1%=lv0->tab[h0].space;
	i=h1;
	while (1) {
		if (!entries[i] || (void *)entries[i]==(void *)&entries[i]) 
			break;
		i++;
		if (i==lv0->tab[h0].space) i=0;
	}
	/* got free slot */
	need=sizeof(struct strhash_entry);
	if (keyalloc)
		need+=keylen;
	else
		need+=sizeof(char *);
	lv2=strhash_alloc(need);
	if (!lv2) {
		errno=error_nomem; 
		return -1;
	}

	if (dataalloc && datalen<=sizeof(void *)) {
		strhash_copy(lv2->u.data,datalen,data);
		lv2->datalen=datalen|KLUDGEBIT;
	} else if (dataalloc) {
		lv2->u.dataptr=strhash_alloc(datalen);
		if (!lv2->u.dataptr) {
			strhash_free(lv2);
			errno=error_nomem;
			return -1;
		}
		lv2->datalen=datalen|KLUDGEBIT;
		strhash_copy(lv2->u.dataptr,datalen,data);
	} else {
		union { const char *cc; char *c; } d;
		d.cc=data;
		lv2->u.dataptr=d.c;
		lv2->datalen=datalen;
	}
	lv2->keylen=keylen;
	if (keyalloc) {
		lv2->keylen|=KLUDGEBIT;
		strhash_copy((char *) &lv2[1],keylen,key);
	} else {
		union { const char *cc; char *c; } d;
		d.cc=key;
		*(char **)&lv2[1]=d.c;
	}
	lv2->hash=h;
	entries[i]=lv2;
	lv0->tab[h0].count++;
	return 1;
}

