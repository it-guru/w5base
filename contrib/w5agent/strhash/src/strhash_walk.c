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

void strhash_walkstart(strhash *lv0) { lv0->wx=lv0->wy=0; }

int 
strhash_walk(strhash *lv0, char **key, uint32 *keylen,
    char **data, uint32 *datalen)
{
	unsigned int i;
	for (i=lv0->wx;i<lv0->mod;i++,lv0->wy=0) {
		struct strhash_entry **entries;
		uint32 j;
		entries=lv0->tab[i].entries;
		if (!entries) continue;
		for (j=lv0->wy;j<lv0->tab[i].space;j++) {
			if (!entries[j]) continue;
			if (entries[j]==(void*) &entries[j]) continue;
			lv0->wx=i;
			lv0->wy=j+1;
			if (keylen) *keylen=entries[j]->keylen & ~(KLUDGEBIT);
			if (datalen) *datalen=entries[j]->datalen & ~(KLUDGEBIT);
			strhash_get(entries[j],key,data);
			return 1;
		}
	}
	return 0;
}

