/* reimplementation by uo, placed in the public domain */
#ifndef ALLOC_H
#define ALLOC_H

extern /*@null@*//*@out@*/char *alloc(unsigned int len);
extern void alloc_free(char *s);
extern int alloc_re(char **s,unsigned int oldsize, unsigned int newsize);

#endif
