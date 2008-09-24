/*
 * reimplementation of Daniel Bernstein's unix library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef GEN_ALLOC_I_H
#define GEN_ALLOC_I_H

extern int gen_alloc_ready(char **bptr, unsigned int bsize, unsigned int *len, 
	unsigned int *a, unsigned int newa);
extern int gen_alloc_readyplus(char **bptr, unsigned int bsize, 
	unsigned int *len, unsigned int *a, unsigned int newa);
extern int gen_alloc_append(char **bptr, unsigned int bsize, unsigned int *len, 
	unsigned int *a, const char *neu);

#endif
