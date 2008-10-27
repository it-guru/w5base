#include "config.h"
#include "version.h"

#include <stdbool.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/uio.h>

#include <errno.h>
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#include <pwd.h>
#ifdef HAVE_GRP_H
#include <grp.h>
#endif
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#ifdef TIME_WITH_SYS_TIME
#include <time.h>
#endif
#include <unistd.h>


#include "getdate.h"
#include "w5bb.h"


#define MAXCMDLEN 25


int is_w5bbrequest( httpd_conn* hc )
{
   int c,cc;
   char *chkbuf;
   char cmdbuffer[MAXCMDLEN];

   for(cc=0;cc<255;c++){
      chkbuf=&hc->read_buf[cc];
      if (*chkbuf!=' ' && *chkbuf!='\t'){
         break;
      }
   }
   *cmdbuffer=0;
   for(c=0;c<MAXCMDLEN;c++){
      if (chkbuf[c]==' ' || chkbuf[c]=='\t' || chkbuf[c]=='\n'){
         strncpy(cmdbuffer,chkbuf,c);
         cmdbuffer[c]=0;
         hc->checked_idx=c+cc;
         break;
      }
   }
   while(hc->read_buf[hc->checked_idx]==' ' ||
         hc->read_buf[hc->checked_idx]=='\t') hc->checked_idx++;
   if (!strcmp(cmdbuffer,"status")){
      return(W5BBREQ_STATUS); 
   }
   else if (!strcmp(cmdbuffer,"page")){
      return(W5BBREQ_PAGE); 
   }
   else if (!strcmp(cmdbuffer,"combo")){
      return(W5BBREQ_COMBO); 
   }
   syslog( LOG_INFO, "is_w5bbrequest(): cmdbuffer='%s'", cmdbuffer );

   return(0);
}

#define MAXSTR 255
#define MAXLONGSTR 1024

typedef struct {
   int  msgtype;
   char rawmsglabel[MAXLONGSTR];
   char hostname[MAXSTR];
   char service[MAXSTR];
   char msgcolor[MAXSTR];
   char msgdate[MAXSTR];
   char shortdesc[MAXLONGSTR];
   char rawdate[MAXLONGSTR];
   time_t time;
} w5bbmsg;

int parse_msgcolor(int op, httpd_conn* hc , w5bbmsg* m)
{
   int c;
   char* chkbuf;

   chkbuf=&hc->read_buf[hc->checked_idx];
   for(c=0;c<MAXLONGSTR;c++){
      if (chkbuf[c]==' ' || chkbuf[c]=='\t'){
         strncpy(m->msgcolor,chkbuf,c);
         m->msgcolor[c]=0;
         hc->checked_idx+=c; 
         break;
      }
   }
   while(hc->read_buf[hc->checked_idx]==' ' ||
         hc->read_buf[hc->checked_idx]=='\t') hc->checked_idx++;
   return(1);
}


int parse_msgdate(int op, httpd_conn* hc , w5bbmsg* m)
{
   int c;
   char* chkbuf;
   char str_mon[MAXSTR], str_wday[MAXSTR],rawdate[MAXSTR];
   int  tm_sec, tm_min, tm_hour, tm_mday, tm_year;
   long tm_mon, tm_wday;
   int  nChar;
   time_t t;
   struct timespec  tm;


   chkbuf=&hc->read_buf[hc->checked_idx];
   bool r=get_date(&tm,"Wed Oct 22 19:51:17 CEST 2008",NULL); 
   t=tm.tv_sec;
   
   fprintf(stderr,"fifi 01 r=%d\n",r);
   if (t==(time_t) -1){
      fprintf(stderr,"fifi time error\n");
   }
   else{
      m->time=t;
      strcpy(m->rawdate,rawdate);
      hc->checked_idx+=nChar;
      fprintf(stderr,"found %s\n",asctime(localtime(&t)));
   }
 //  while(hc->read_buf[hc->checked_idx]==' ' ||
 //        hc->read_buf[hc->checked_idx]=='\t') hc->checked_idx++;

   return(1);
}

int parse_shortdesc(int op, httpd_conn* hc , w5bbmsg* m)
{
   int c;
   char* chkbuf;
   char str_mon[MAXSTR], str_wday[MAXSTR],timezone[MAXSTR];
   int  tm_sec, tm_min, tm_hour, tm_mday, tm_year;
   long tm_mon, tm_wday;
   int  nChar;
   time_t t;

   chkbuf=&hc->read_buf[hc->checked_idx];
   for(c=0;c<MAXLONGSTR;c++){
      if (chkbuf[c]=='\n' || chkbuf[c]=='\r'){
         strncpy(m->shortdesc,chkbuf,c);
         m->shortdesc[c]=0;
         hc->checked_idx+=c; 
         break;
      }
   }

   while(hc->read_buf[hc->checked_idx]==' ' || 
         hc->read_buf[hc->checked_idx]=='\r' ||
         hc->read_buf[hc->checked_idx]=='\n' ||
         hc->read_buf[hc->checked_idx]=='\t') hc->checked_idx++;

   return(1);
}

int parse_rawmsglabel(int op, httpd_conn* hc , w5bbmsg* m)
{
   int c;
   char* chkbuf;

   chkbuf=&hc->read_buf[hc->checked_idx];
   for(c=0;c<MAXLONGSTR;c++){
      if (chkbuf[c]==' ' || chkbuf[c]=='\t'){
         strncpy(m->rawmsglabel,chkbuf,c);
         m->rawmsglabel[c]=0;
         hc->checked_idx+=c; 
         break;
      }
   }
   for(c=0;c<MAXSTR;c++){
      if (m->rawmsglabel[c]=='.'){
         strncpy(m->hostname,m->rawmsglabel,c);
         m->hostname[c]=0;
         if (strlen(&m->rawmsglabel[c])<MAXSTR){
            strcpy(m->service,&m->rawmsglabel[c+1]);
         }
         chkbuf=m->hostname;
         while(*chkbuf){
            if (*chkbuf==',') *chkbuf='.';
            chkbuf++;
         }
         break;
      }
   }
   while(hc->read_buf[hc->checked_idx]==' ' ||
         hc->read_buf[hc->checked_idx]=='\t') hc->checked_idx++;

   return(1);
}

int process_w5bbrequest(int op, httpd_conn* hc )
{
   w5bbmsg m;

   (void) memset( &m, 0, sizeof(m) );
   m.msgtype=op;
   if (op==W5BBREQ_STATUS){
      fprintf(stderr,"W5BBREQ_STATUS message\n");
      fprintf(stderr,"pre parse=%s\n",&hc->read_buf[hc->checked_idx]);
      parse_rawmsglabel(op,hc,&m);
      fprintf(stderr,"rawmsglabel=%s\n",m.rawmsglabel);
      fprintf(stderr,"hostname=%s\n",m.hostname);
      fprintf(stderr,"service=%s\n",m.service);
      parse_msgcolor(op,hc,&m);
      fprintf(stderr,"msgcolor=%s\n",m.msgcolor);
      parse_msgdate(op,hc,&m);
  //    parse_shortdesc(op,hc,&m);
  //    fprintf(stderr,"shortdesc=%s\n",m.shortdesc);
  //   fprintf(stderr,"post parse=%s\n",&hc->read_buf[hc->checked_idx]);
      syslog( LOG_INFO, "process status msg");
      return(1);
   }
   else if (op==W5BBREQ_PAGE){
      syslog( LOG_INFO, "process page msg");
      return(1);
   }
   else if (op==W5BBREQ_COMBO){
      syslog( LOG_INFO, "process combo msg");
      return(1);
   }

   return(0);
}


