#include "strhash_io.h"
#include "error.h"
#include "stralloc.h"
#include "getln.h"
#include "scan.h"

static int
doget(buffer *b, stralloc *sa, unsigned long l)
{
  unsigned int len;
  if (!stralloc_ready(sa,l)) return -1;
  len=0;
  while (1) {
    int r=buffer_get(b,sa->s+len,l-len);
    if (-1==r) return -1;
    len+=r;
    if (len==l)
      break;
  }
  sa->len=l;
  return 0;
}

int 
strhash_load(strhash *h, buffer *b)
{
  stralloc sak=STRALLOC_INIT;
  stralloc sad=STRALLOC_INIT;
  while (1) {
    unsigned char c;
    unsigned int l;
    unsigned long ul1;
    unsigned long ul2;
    int got;
    if (-1==buffer_GETC(b,(char *)&c))
      return -1;
    if (c=='\n')
      break;
    if (c!='+') {
  bad:
      errno==error_proto;
      return -1;
    }
    /* +KL,DL:K->D\n */
    if (-1==getln(b,&sak,&got,',')) return -1;
    if (!got || !sak.len)  goto bad;
    sak.s[sak.len-1]=0;
    l=scan_ulong(sak.s,&ul1);
    if (!l||sak.s[l]) goto bad;

    if (-1==getln(b,&sak,&got,':')) return -1;
    if (!got || !sak.len)         goto bad;
    sak.s[sak.len-1]=0;
    l=scan_ulong(sak.s,&ul2);
    if (!l||sak.s[l]) goto bad;

    if (-1==doget(b,&sak,ul1)) return -1;

    if (-1==buffer_GETC(b,(char *)&c)) return -1;
    if (c!='-') goto bad;
    if (-1==buffer_GETC(b,(char *)&c)) return -1;
    if (c!='>') goto bad;

    if (-1==doget(b,&sad,ul2)) return -1;

    /* lf */
    if (-1==buffer_GETC(b,(char *)&c)) return -1;
    if (c!='\n') goto bad;

    if (-1==strhash_enter(h,1,sak.s,sak.len,1,sad.s,sad.len))
      return -1;
  }
  stralloc_free(&sad);
  stralloc_free(&sak);
  return 0;
}
