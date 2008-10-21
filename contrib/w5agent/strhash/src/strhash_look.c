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


static struct strhash_entry * 
ifind(strhash *lv0,uint32 keylen, const char *key, unsigned int *ind,
	unsigned int *ind0)
{
	uint32 h;
	uint32 h0;
	uint32 h1;
	struct strhash_entry **entries;
	unsigned int i;

	if (!lv0->loop) 
		lv0->hash=lv0->hashfunc(key,keylen);

	h=lv0->hash;
	h0=h % lv0->mod;
	h1=h / lv0->mod;

	entries=lv0->tab[h0].entries;
	if (!entries) return 0; /* obviously not found */
	h1%=lv0->tab[h0].space;
	
	i=(h1+lv0->loop) % lv0->tab[h0].space;
	while (entries[i]) { /* completely empty slot have never been used */
		uint32 thiskeylen;
		lv0->loop++;
		if (entries[i]==(void *)&(entries[i])) { /* deleted entry */
	  isnt:
			i++;
			if (i==lv0->tab[h0].space) i=0;
			if (i==h1)
				break;
			continue;
		}
		if (entries[i]->hash!=h) 
			goto isnt;
		thiskeylen=entries[i]->keylen;
		if (keylen!=strhash_reallen(thiskeylen))
			goto isnt;
		{
			unsigned int j;
			char *cmp;
			if (strhash_allocated(thiskeylen))
				cmp=(char *) &entries[i][1];
			else
				cmp=*(char **)&entries[i][1];
			for (j=0;j<keylen;j++) {
				if (key[j]!=cmp[j])
					goto isnt;
			}
			*ind=i;
			*ind0=h0;
			return entries[i];
		}
	}
	return 0; /* not found */
}
void strhash_lookupstart(strhash *lv0) { lv0->loop=0; }

int 
strhash_lookup(strhash *lv0,const char *key, uint32 keylen,
    char **data, uint32 *datalen)
{
	strhash_lookupstart(lv0);
	return strhash_lookupnext(lv0,key,keylen,data,datalen);
}

int strhash_lookupnext(strhash *lv0,const char *key, uint32 keylen,
    char **data, uint32 *datalen)
{
	struct strhash_entry *entry;
	unsigned int i;
	uint32 h0;
	if (keylen & KLUDGEBIT) {
		errno=error_noent;
		return -1;
	}
	entry=ifind(lv0,keylen,key,&i,&h0);
	if (!entry) return 0;
	if (datalen) *datalen=strhash_reallen(entry->datalen);
	strhash_get(entry,0,data);
	return 1;
}


