/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef OPEN_H
#define OPEN_H

int open_append(const char *);
int open_append_mode(const char *,int);
int open_append_blocking(const char *,int);
int open_excl(const char *fname);
int open_excl_mode(const char *fname,int mode);
int open_read(const char *);
int open_read_blocking(const char *);
int open_trunc(const char *fn);
int open_trunc_mode(const char *fname,int mode);
int open_trunc_blocking(const char *fname,int mode);
int open_write(const char *fname);
int open_write_blocking(const char *fname);
int open_readwrite(const char *fname);
int open_readwrite_blocking(const char *fname);

#endif
