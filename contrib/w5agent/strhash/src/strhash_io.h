/*
 * Copyright (C) 2000-2002 Uwe Ohse, uwe@ohse.de
 * This is free software, licensed under the terms of the GNU Lesser
 * General Public License Version 2.1, of which a copy is stored at:
 *    http://www.ohse.de/uwe/licenses/LGPL-2.1
 * Later versions may or may not apply, see 
 *    http://www.ohse.de/uwe/licenses/
 * for information after a newer version has been published.
 */
#ifndef strhash_io_h
#define strhash_io_h

#include "strhash.h"
#include "buffer.h"

int strhash_save(strhash *, buffer *);
int strhash_load(strhash *, buffer *);
#endif
