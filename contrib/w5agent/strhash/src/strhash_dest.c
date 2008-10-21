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

void 
strhash_destroy(strhash *lv0)
{
	unsigned int i;
#ifdef COUNTIT
	unsigned long dl=0,ol=0,el=0,tl=0;
	for (i=0;i<lv0->mod;i++) {
		if (lv0->tab[i].entries) {
			unsigned int j;
			struct strhash_entry **entries=lv0->tab[i].entries;
			tl+=sizeof(lv0->tab[i]);
			for (j=0;j<lv0->tab[i].space;j++) {
				el+=4;
				if (entries[j] && entries[j] != (void *) &entries[j]) {
					if (strhash_allocated(entries[j]->keylen)) {
						uint32 u=strhash_reallen(entries[j]->keylen);
						if (u>4) u-=4; /* union "overhead" */
						dl+=u;
					}
					if (strhash_allocated(entries[j]->datalen))
						dl+=strhash_reallen(entries[j]->datalen);
					ol+=sizeof(*entries[j]);
				}
			}
		}
	}
printf("dl=%lu ol=%lu el=%lu tl=%lu\n",dl,ol,el,tl);
#endif

	for (i=0;i<lv0->mod;i++) {
		if (lv0->tab[i].entries) {
			unsigned int j;
			struct strhash_entry **entries=lv0->tab[i].entries;
			for (j=0;j<lv0->tab[i].space;j++)
				if (entries[j] && entries[j] != (void *) &entries[j]) {
					if (strhash_allocated(entries[j]->datalen)
						&& strhash_reallen(entries[j]->datalen)
							> sizeof(void *))
							strhash_free(entries[j]->u.dataptr);
					strhash_free(entries[j]);
				}
			strhash_free(entries);
		}
	}
	strhash_free(lv0->tab);
}

