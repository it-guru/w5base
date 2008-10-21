/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#include "fmt.h"

#define FMT_UFUNC(name,type,base,charset) \
unsigned int \
fmt_##name(char *t, type num) \
{ type num2; unsigned int len; \
  for (len=1,num2=num; num2>=base; num2/=base) len++; \
  if (t) { \
    unsigned int len2=len; \
  	do { t[--len2]=charset[num%base]; num/=base; } while(num); \
  } \
  return len; \
}

#define FMT_UFUNC_PAD(name,type,base,charset,padchar) \
unsigned int \
fmt_##name(char *t, type num, unsigned int minlen) \
{ type num2; unsigned int len; \
  for (len=1,num2=num; num2>=base; num2/=base) len++; \
  if (t) { \
    unsigned int len2=minlen > len ? minlen : len ; \
  	do { t[--len2]=charset[num%base]; num/=base; } while(num); \
	while (len2) { t[--len2]=padchar; } \
  } \
  return len > minlen ? len : minlen ; \
}

