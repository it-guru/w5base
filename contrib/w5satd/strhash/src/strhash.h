/*
 * Copyright (C) 2000-2002 Uwe Ohse, uwe@ohse.de
 * This is free software, licensed under the terms of the GNU Lesser
 * General Public License Version 2.1, of which a copy is stored at:
 *    http://www.ohse.de/uwe/licenses/LGPL-2.1
 * Later versions may or may not apply, see 
 *    http://www.ohse.de/uwe/licenses/
 * for information after a newer version has been published.
 */
#ifndef strhash_h
#define strhash_h

#include "uint32.h"

typedef uint32 (*strhash_hashfunc)(const char *buf, unsigned int len);

struct strhash_entry;

typedef struct {
	struct strhash_entry **entries;
	uint32 count;
	uint32 space;
} strhash_lv0;

typedef struct {
	unsigned int startsize;
	unsigned int mod;
	strhash_lv0 *tab;
	strhash_hashfunc hashfunc;

	unsigned int wx; /* walk */
	uint32 wy; /* walk */
	uint32 hash; /* lookup */
	uint32 loop; /* lookup */
} strhash;


int strhash_create(strhash *, unsigned int mod, unsigned int startsize,
	strhash_hashfunc);
void strhash_destroy(strhash *);
uint32 strhash_hash(const char *buf, unsigned int len);

int strhash_enter(strhash *,int keyalloc, const char *key, uint32 keylen,
	int dataalloc, const char *data, uint32 datalen);

void strhash_lookupstart(strhash *);
int strhash_lookupnext(strhash *,const char *key, uint32 keylen,
	char **data, uint32 *datalen);
int strhash_lookup(strhash *,const char *key, uint32 keylen, 
	char **data, uint32 *datalen);
void strhash_delete(strhash *);
int strhash_change(strhash *,int dataalloc, const char *data, uint32 datalen);

void strhash_walkstart(strhash *);
int strhash_walk(strhash *, char **key, uint32 *keylen,
    char **data, uint32 *datalen);

#endif
