/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "scan.h"
#include "case.h"

#define SCAN_FUNC_XINIT(charset) \
static signed char tab[256]; static int init_done; \
static void do_init(void) { unsigned int i; \
  case_init_lwrtab(); \
  for (i=0;i<256;i++) tab[i]=-1; \
  for (i=0;charset[i];i++) { \
    unsigned char c=charset[i]; \
	tab[c]=i; \
	c=case_lwrtab[c]; \
	tab[c]=i; \
  } \
  init_done=1; \
} 

#define SCAN_FUNC_INIT(charset) \
static signed char tab[256]; static int init_done; \
static void do_init(void) { unsigned int i; \
  for (i=0;i<256;i++) tab[i]=-1; \
  for (i=0;charset[i];i++) { \
    unsigned char c=charset[i]; \
	tab[c]=i; \
  } \
  init_done=1; \
}

#define SCAN_FUNC_DO(name,type,base) \
unsigned int \
scan_##name(const char *s, type *num) \
{ type num2=0; unsigned int i; \
  if (!init_done) do_init(); \
  i=0; \
  while (1) { \
  	signed char c=tab[(unsigned int)(unsigned char)s[i]]; \
	if (c==-1) break; \
	num2=num2*base+c; \
	i++; \
  } \
  *num=num2; \
  return i; \
}

#define SCAN_UFUNC(name,type,base,charset) \
SCAN_FUNC_INIT(charset) \
SCAN_FUNC_DO(name,type,base)

#define SCAN_XFUNC(name,type,base,charset) \
SCAN_FUNC_XINIT(charset) \
SCAN_FUNC_DO(name,type,base)

#define SCAN_FUNC(name,type) \
unsigned int \
scan_##name(const char *s,type *num) \
{ int sign; unsigned int len; unsigned type num2; \
  len=scan_plusminus(s,&sign);  \
  len+= scan_u##name(s+len,&num2); \
  if (sign<0) *num=-num2; \
  else        *num=num2; \
  return len; \
}
