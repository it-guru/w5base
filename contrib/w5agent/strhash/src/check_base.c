#include "strhash.h"
#include "strhash_io.h"
#include "attributes.h"
#include "open.h"
#include "error.h"
#include "buffer.h"
#include "bailout.h"
#include "fmt.h"
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#ifndef NR
#define NR 1000000
#endif

strhash handle;

/* sprintf(...,"%d",...) used to dominate the run time. This wasn't too
 * funny as i wasn't profiling libc.
 * I continue to be astonished about the inefficiency of the standard
 * C library functions.
 */
//static void tostr(char *buf, int x) attribute_regparm(2);
static void
tostr(char *buf, int x)
{
#if 0
	int l;
	if (x<0) {
		*buf++='-';
		x*=-1;
	}
	l=x;
	do {
		buf++;
		l/=10;
	} while (l);
	buf[0]='\0';
	do {
		buf--;
		buf[0]='0'+ (x%10);
		x/=10;
	} while (x);
#elif 1
  unsigned int p=0;

  if (x<0) {
    buf[p++]='-';
    x*=-1;
  }
  if (x<10)p++;
  else if (x<100)p+=2;
  else if (x<1000)p+=3;
  else if (x<10000)p+=4;
  else if (x<100000)p+=5;
  else if (x<1000000)p+=6;
  else if (x<10000000)p+=7;
  buf[p--]='\0';
  do {
    buf[p--]='0'+ (x%10);
    x/=10;
  } while (x);
#else
  unsigned int xx;
  unsigned int p=0;

  if (x<0) {
    buf[p++]='-';
    x*=-1;
  }

  xx=x;
  do {
    xx/=10;
    p++;
  } while (xx);
  buf[p--]='\0';
  do {
    buf[p--]='0'+ (x%10);
    x/=10;
  } while (x);
#endif
}
#define puts(x) warning(0,x,0,0,0)

static void 
testfunc(unsigned int mod)
{
	unsigned int i;
	char buf1[1024];
	char buf2[1024];
	char flag[1000];
	if (-1==strhash_create(&handle,mod,32,strhash_hash))
		xbailout(100,errno,"create",0,0,0);
	puts("1->Enter");
	for (i=0;i<NR;i++) {
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (-1==strhash_enter(&handle,
			1,buf1,strlen(buf1)+1,
			1,buf2,strlen(buf2)+1))
		  xbailout(100,errno,"failed to enter ",buf1,0,0);
	}
	puts("2->find");
	for (i=0;i<NR;i++) {
		char *p;
		uint32 pl;
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,&p,&pl))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (0!=memcmp(buf2,p,pl))
			xbailout(100,0,"found ",buf1,buf2,p);
	}
	puts("3->Overwrite 50% of keys");
	memcpy(buf2,"add",3);
	for (i=0;i<NR;i+=2) {
		tostr(buf1,i);
		tostr(buf2+3,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,0,0))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (1!=strhash_change(&handle,
			1,buf2,strlen(buf2)+1))
		  xbailout(100,errno,"failed to change ",buf1,0,0);
	}
	puts("4->compare changed 50% of keys");
	memcpy(buf2,"add",3);
	for (i=0;i<NR;i+=2) {
		char *p;
		uint32 pl;
		tostr(buf1,i);
		tostr(buf2+3,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,&p,&pl))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (0!=memcmp(buf2,p,pl))
			xbailout(100,0,"found ",buf1,buf2,p);
	}
	puts("5->(Re)Overwrite 50% of keys");
	for (i=0;i<NR;i+=2) {
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,0,0))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (1!=strhash_change(&handle, 1,buf2,strlen(buf2)+1))
		  xbailout(100,errno,"failed to change ",buf1,0,0);
	}
	puts("6->find 50% keys");
	for (i=0;i<NR;i+=2) {
		char *p;
		uint32 pl;
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,&p,&pl))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (0!=memcmp(buf2,p,pl))
			xbailout(100,0,"found ",buf1,buf2,p);
	}
	puts("7->find other 50%");
	for (i=1;i<NR;i+=2) {
		char *p;
		uint32 pl;
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,&p,&pl))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (0!=memcmp(buf2,p,pl))
			xbailout(100,0,"found ",buf1,buf2,p);
	}
	puts("8->delete 50%");
	for (i=0;i<NR;i+=2) {
		tostr(buf1,i);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,0,0))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		strhash_delete(&handle);
	}
	puts("9->find deleted 50%");
	for (i=0;i<NR;i+=2) {
		char *p;
		uint32 pl;
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (0!=strhash_lookup(&handle,buf1,strlen(buf1)+1,&p,&pl))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
	}
	puts("10->find still existing 50%");
	for (i=1;i<NR;i+=2) {
		char *p;
		uint32 pl;
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (1!=strhash_lookup(&handle,buf1,strlen(buf1)+1,&p,&pl))
		  xbailout(100,errno,"failed to lookup ",buf1,0,0);
		if (0!=memcmp(buf2,p,pl))
			xbailout(100,0,"found ",buf1,buf2,p);
	}
	puts("11->Reenter deleted");
	for (i=0;i<NR;i+=2) {
		tostr(buf1,i);
		tostr(buf2,i+NR);
		if (-1==strhash_enter(&handle,
			1,buf1,strlen(buf1)+1,
			1,buf2,strlen(buf2)+1))
		  xbailout(100,errno,"failed to enter ",buf1,0,0);
	}
	puts("12->Enter duplicate keys");
	{
		strcpy(buf1,"key");
		for (i=0;i<sizeof(flag);i++) {
			tostr(buf2,i);
			if (-1==strhash_enter(&handle,
				1,buf1,strlen(buf1)+1,
				1,buf2,strlen(buf2)+1))
			  xbailout(100,errno,"failed to enter ",buf1,0,0);
			flag[i]=0;
		}
	}
	puts("13->Find duplicate keys");
	{
		unsigned long x;
		char *p;
		uint32 pl;
		strcpy(buf1,"key");
		strhash_lookupstart(&handle);
		i=0;
		while (strhash_lookupnext(&handle,
			buf1,strlen(buf1)+1, &p,&pl)) {
			i++;
			x=strtoul(p,0,10);
			if (x<sizeof(flag)) {
			  if (flag[x])
			  xbailout(100,0,"found ",p," twice",0);
			  flag[x]=1;
			}
			else
			  xbailout(100,0,"found wrong value ",p,0,0);
		}
		if (i!=sizeof(flag))
		  xbailout(100,0,"found different number of entries",0,0,0);
	}
	puts("14->Delete every second duplicate");
	{
		unsigned long x;
		char *p;
		uint32 pl;
		strcpy(buf1,"key");
		strhash_lookupstart(&handle);
		i=0;
		while (strhash_lookupnext(&handle,
			buf1,strlen(buf1)+1, &p,&pl)) {
			i++;
			x=strtoul(p,0,10);
			if (x&1)  {
				strhash_delete(&handle);
				flag[x]=2;
			} else
				flag[x]=3;
		}
		if (i!=sizeof(flag))
		  xbailout(100,0,"found different number of entries",0,0,0);
	}
	puts("15->Change remaining duplicate keys");
	{
		unsigned long x;
		char *p;
		uint32 pl;
		strcpy(buf1,"key");
		strhash_lookupstart(&handle);
		i=0;
		while (strhash_lookupnext(&handle,
			buf1,strlen(buf1)+1, &p,&pl)) {
			i++;
			x=strtoul(p,0,10);
			if (x<sizeof(flag)) {
				if (flag[x]==2)
				  xbailout(100,0,"found deleted value ",p,0,0);
				if (flag[x]==1)
				  xbailout(100,0,"found value twice ",p,0,0);
				if (flag[x]!=3)
				  xbailout(100,0,"found value with flag != 3: ",p,0,0);
				flag[x]=4;
				buf2[fmt_ulong(buf2,x+sizeof(flag))]=0;
				strhash_change(&handle,1,buf2,strlen(buf2)+1);
			}
			else
			    xbailout(100,0,"found wrong value ",p,0,0);
		}
		if (i!=sizeof(flag)/2)
		  xbailout(100,0,"found different number of entries",0,0,0);
	}
	puts("16->walk table");
	{
		char *k;
		char *v;
		uint32 kl;
		uint32 vl;
		i=0;
		strhash_walkstart(&handle);
		while (strhash_walk(&handle, &k,&kl,&v,&vl)) 
			i++;
		if (i!=sizeof(flag)/2 + NR)
		  xbailout(100,0,"walk found different number of entries",
		    0,0,0);
	}
	puts("17->Delete remaining duplicate keys");
	{
		unsigned long x;
		char *p;
		uint32 pl;
		strcpy(buf1,"key");
		strhash_lookupstart(&handle);
		i=0;
		while (strhash_lookupnext(&handle,
			buf1,strlen(buf1)+1, &p,&pl)) {
			i++;
			x=strtoul(p,0,10);
			if (x<sizeof(flag))
			    xbailout(100,0,"found wrong value ",p,0,0);
			x-=sizeof(flag);
			if (x<sizeof(flag)) {
			  if (flag[x]!=4)
			    xbailout(100,0,"found value with flag != 4: ",
			      p,0,0);
			  strhash_delete(&handle);
			}
			else
			    xbailout(100,0,"found wrong value ",p,0,0);
		}
		if (i!=sizeof(flag)/2)
		  xbailout(100,0,"found different number of entries", 0,0,0);
	}
	puts("18->Search for duplicate keys");
	{
	  if (strhash_lookup(&handle,"key",4,0,0))
	    xbailout(100,0,"found deleted key???",0,0,0);
	}
	puts("19->destroy table");
	strhash_destroy(&handle);
}
static void 
testfunc2(void)
{
  unsigned int i;
  char buf1[1024];
  char buf2[1024];
  if (-1==strhash_create(&handle,4,32,strhash_hash))	
    xbailout(100,errno,"failed to create hash",0,0,0);
  for (i=0;i<NR/1000;i++) {
    tostr(buf1,i);
    tostr(buf2,i+NR);
    if (-1==strhash_enter(&handle,
	1,buf1,strlen(buf1),
	1,buf2,strlen(buf2)))
    xbailout(100,errno,"failed to enter ",buf1,0,0);
  }
  if (-1==strhash_enter(&handle, 1,"'",1, 1,"\"",1))
    xbailout(100,errno,"failed to enter data",0,0,0);
  if (-1==strhash_enter(&handle, 1,"",1, 1,"test",4))
    xbailout(100,errno,"failed to enter data",0,0,0);
  if (-1==strhash_enter(&handle, 1,"test",4, 1,"te\nst",5))
    xbailout(100,errno,"failed to enter data",0,0,0);
  if (-1==strhash_enter(&handle, 1,"test",4, 1,"te\nst",5))
    xbailout(100,errno,"failed to enter data",0,0,0);
  for (i=0;i<256;i++)
    buf1[i]=i;
  if (-1==strhash_enter(&handle, 1,buf1,256, 1,buf1,256))
    xbailout(100,errno,"failed to enter data",0,0,0);

  {
    char bspace[4096];
    buffer b;
    int fd;

    fd=open_trunc("check_base.hash2");
    if (-1==fd) 
      xbailout(100,errno,"failed to open_trunc check_base.hash2",0,0,0);
    buffer_init(&b,(buffer_op_t)write,fd,bspace,sizeof(bspace));
    if (-1==strhash_save(&handle,&b))
      xbailout(100,errno,"failed to save hash to check_base.hash2",0,0,0);
    close(fd);


    strhash_destroy(&handle);
    if (-1==strhash_create(&handle,4,32,strhash_hash))
      xbailout(100,errno,"failed to create hash",0,0,0);
    fd=open_read("check_base.hash2");
    if (-1==fd) 
      xbailout(100,errno,"failed to open_read check_base.hash2",0,0,0);
    buffer_init(&b,(buffer_op_t)read,fd,bspace,sizeof(bspace));
    if (-1==strhash_load(&handle,&b)) 
      xbailout(100,errno,"failed to read hash from check_base.hash2",0,0,0);
    close(fd);

    fd=open_trunc("check_base.hash3");
    if (-1==fd) 
      xbailout(1111,errno,"failed to open_trunc check_base.hash3",0,0,0);
    buffer_init(&b,(buffer_op_t)write,fd,bspace,sizeof(bspace));
    if (-1==strhash_save(&handle,&b))
      xbailout(1111,errno,"failed to save hash to check_base.hash3",0,0,0);
    close(fd);
  }

  strhash_destroy(&handle);
}

int main(void)
{
	int i;
	for (i=1;i<=256;i*=2) {
	  char nb[FMT_ULONG];
	  nb[fmt_ulong(nb,i)]=0;
	  warning(0,"testing with mod ",nb,0,0);
	  testfunc(i);
	}
	testfunc2();
	puts("done");
	exit(0);
}
