#include "strhash_io.h"
#include "fmt.h"
#include "error.h"

#define W(s,l)  \
  if (-1==buffer_put(b,s,l)) return -1;

int 
strhash_save(strhash *h, buffer *b)
{
  strhash_walkstart(h);

  while (1) {
    unsigned char *k;
    unsigned char *d;
    char nb[11];
    uint32 kl,dl;
    int r=strhash_walk(h,(char **)&k,&kl,(char **)&d,&dl);
    if (!r)
      break;
    W("+",1);
    W(nb,fmt_ulong(nb,kl));
    W(",",1);
    W(nb,fmt_ulong(nb,dl));
    W(":",1);
    W(k,kl);
    W("->",2);
    W(d,dl);
    W("\n",1);
  }
  W("\n",1);
  if (-1==buffer_flush(b)) return -1;
  return 0;
}
