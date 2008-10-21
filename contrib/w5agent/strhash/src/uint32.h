/* Reimplementation of Daniel J. Bernsteins uint library.
 * (C) 2001 Uwe Ohse, <uwe@ohse.de>.
 *   Report any bugs to <uwe@ohse.de>.
 * Placed in the public domain.
 */
#ifndef UINT32_H
#define UINT32_H

#include "typesize.h"
typedef uo_uint32_t uint32;

void uint32_pack(char *target,uint32);
void uint32_pack_big(char *target,uint32);
void uint32_unpack(const char *source,uint32 *);
void uint32_unpack_big(const char *source,uint32 *);

#endif
