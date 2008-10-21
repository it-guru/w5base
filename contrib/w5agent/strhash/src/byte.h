/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef BYTE_H
#define BYTE_H

unsigned int byte_chr(const char *s, unsigned int n, int searched);
unsigned int byte_rchr(const char *s,unsigned int n, int searched);
void byte_copy(char *to, unsigned int n,const char *from);
void byte_copyr (char *to, unsigned int n, const char *from);
int byte_diff(const char *s,unsigned int n,const char *t);
void byte_zero(char *s,unsigned int n);

#define byte_equal(s,n,t) (!byte_diff((s),(n),(t)))

#endif
