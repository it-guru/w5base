#include "config.h"
#include "version.h"

#include <stdbool.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/uio.h>

#include <sys/stat.h>

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
   else if (!strcmp(cmdbuffer,"data")){
      return(W5BBREQ_DATA); 
   }
   else if (!strcmp(cmdbuffer,"combo")){
      return(W5BBREQ_COMBO); 
   }
   syslog( LOG_INFO, "is_w5bbrequest(): cmdbuffer='%s'", cmdbuffer );

   return(0);
}

int mkSpoolPath(httpd_conn* hc,char *spoolpath,char *spoolfile)
{
   struct stat bbdir;
   char requestfile[MAXPATHLEN+1];

   strcpy(spoolpath,W5BBDIR);
   if (strlen(spoolpath)<MAXPATHLEN-1 &&
       spoolpath[strlen(spoolpath)-1]!='/') (void) strcat( spoolpath,"/");
   if (strlen(spoolpath)<MAXPATHLEN-5) (void) strcat( spoolpath,"spool");

   sprintf(requestfile,"%015ld.txt",hc->request_num);

   strcpy(spoolfile,spoolpath);
   if (strlen(spoolfile)<MAXPATHLEN-1 &&
       spoolfile[strlen(spoolfile)-1]!='/') (void) strcat( spoolfile,"/");
   if (strlen(spoolfile)<MAXPATHLEN-20) (void) strcat(spoolfile,requestfile);

   if (!stat(spoolpath,&bbdir)){
      if (S_ISDIR(bbdir.st_mode)){
         if (!access(spoolpath,W_OK|X_OK)){
           // fprintf(stderr,"DEBUG: access to %s OK\n",spoolpath);
            return(1);
         }
         else{
            syslog(LOG_ERR,"incorrect rights on %s to handel w5bb request!",
                   spoolpath );
         }
      }
      else{
         syslog(LOG_ERR,"spool path %s is not a directory!",spoolpath );
      }
   }
   else{
      if (stat(W5BBDIR,&bbdir)){
         mkdir(W5BBDIR,0777); 
      }
      if (stat(spoolpath,&bbdir)){
         mkdir(spoolpath,0777); 
      }
   }
   syslog(LOG_ERR,"insuficent rights to access to %s to handel w5bb request!",
          spoolpath );
   return(0);
}


int process_w5bbrequest(int op, httpd_conn* hc )
{
   struct stat bbdir;
   char spoolpath[MAXPATHLEN+1];
   char spoolfile[MAXPATHLEN+1];
   int  fh,r,wc,reqsize=0,wrsize;
   char buf[128];
   
   if (mkSpoolPath(hc,spoolpath,spoolfile)){
      if (fh=open(spoolfile,O_CREAT|O_RDWR,S_IWUSR|S_IRUSR)){
         //fprintf(stderr,"OK spoolfile=%s readsize=%d fh=%d\n",
         //               spoolfile,hc->read_size,fh);
         wrsize=hc->read_size;
         if (strlen(hc->read_buf)<wrsize){
            wrsize=strlen(hc->read_buf);
         }    
         wc=write(fh,hc->read_buf,wrsize);
         reqsize+=wc;
         //fprintf(stderr,"fifi01 conn_fd=%d errno=%d\n",hc->conn_fd,errno);
         while(reqsize<1024*1024*10){
         //fprintf(stderr,"fifi02-0 read=%d\n",sizeof(buf));
            errno=0;
            memset(buf,0,sizeof(buf));
            r=read(hc->conn_fd,buf,sizeof(buf)-1);
         //fprintf(stderr,"fifi02-1 r=%d errno=%d\n",r,errno);
            if ( r < 0 && ( errno == EINTR || errno == EAGAIN )){
         //fprintf(stderr,"fifi03\n");
              sleep( 1 );
              continue;
            }
            if ( r <= 0 ) break;
         //fprintf(stderr,"fifi04\n");
            if (strlen(buf)<r){
               r=strlen(buf);
            }
            
            wc=write(fh,buf,r);
            reqsize+=wc;
         }
         write(fh,"\n",1);
         //fprintf(stderr,"fifi05\n");
         close(fh);
         return(1);
      }
   }
   return(0);
}


