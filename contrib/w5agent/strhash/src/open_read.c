/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include <sys/types.h>
#include <fcntl.h>
#include "open.h"

int open_read(const char *fn)
{ return open(fn,O_RDONLY | O_NDELAY); }
int open_read_blocking(const char *fn)
{ return open(fn,O_RDONLY); }
