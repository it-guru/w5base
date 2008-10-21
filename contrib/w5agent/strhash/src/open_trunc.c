/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include <sys/types.h>
#include <fcntl.h>
#include "open.h"

int open_trunc(const char *fn)
{ return open(fn,O_WRONLY | O_NDELAY | O_TRUNC | O_CREAT,0644); }

int open_trunc_mode(const char *fname,int mode)
{ return open(fname,O_WRONLY | O_TRUNC | O_CREAT | O_NDELAY,mode); }

int open_trunc_blocking(const char *fname,int mode)
{ return open(fname,O_WRONLY | O_TRUNC | O_CREAT ,mode); }

