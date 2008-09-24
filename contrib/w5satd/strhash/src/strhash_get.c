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

void 
strhash_get(struct strhash_entry *e, char **key, char **data)
{
	if (key) {
		if (strhash_allocated(e->keylen))
			*key=(char *)&e[1];
		else
			*key=*(char **)&e[1];
	}
	if (data) {
		if (strhash_allocated(e->datalen)) {
			if (strhash_reallen(e->datalen) > sizeof(void *))
				*data=e->u.dataptr;
			else
				*data=e->u.data;
		} else
			*data=e->u.dataptr;
	}
}

