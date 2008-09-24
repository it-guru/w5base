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

void strhash_delete(strhash *lv0)
{
	struct strhash_entry **entries;
	uint32 h0;
	uint32 h1;
	uint32 h;

	h=lv0->hash;
	h0=h % lv0->mod;
	h1=h / lv0->mod;
	h1=(h1+lv0->loop-1) % lv0->tab[h0].space;
	entries=lv0->tab[h0].entries;

	if (strhash_allocated(entries[h1]->datalen)
		&& strhash_reallen(entries[h1]->datalen) >sizeof(void *))
		strhash_free(entries[h1]->u.dataptr);
	strhash_free(entries[h1]);
	entries[h1]=(void *)&entries[h1];
	lv0->tab[h0].count--;
}

