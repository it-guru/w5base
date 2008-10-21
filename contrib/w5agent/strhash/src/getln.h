/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef GETLN_H
#define GETLN_H

#include "buffer.h"
#include "stralloc.h"

extern int getln(buffer *,stralloc *,int *got_termchar,int termchar);

#endif
