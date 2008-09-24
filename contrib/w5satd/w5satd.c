#include <sys/types.h>
#include <sys/socket.h>
#include <signal.h>
#include <stdio.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <stdlib.h>
#include <netinet/in.h>
#include <netdb.h>
#include <time.h>
#include <curl.h>
#include <mhash.h>
#include <strhash.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


 
void *connectionthread(void *somelist);
MHASH MsgState;

strhash HostTable;
 
int main(int nArg, char* pszArgs[])
{
   int listenfd, connfd, i;
   int paramlist[10];
   for (i=0; i<10; i++) paramlist[i]=0;
   socklen_t clilen;
   struct sockaddr_in clientaddr,serveraddr;

   int sz = getpagesize();
   int fd;
   char *m;
   int c;
   for(c=0;c<=15000;c++){
      char fname[255];
      sprintf(fname,"test%04d.txt",c);
      if ((fd=open(fname, O_RDWR|O_CREAT,0777))!=-1){
         lseek(fd,16*sz,SEEK_SET);
         write(fd,"",1);
         lseek(fd,0,SEEK_SET);
         printf("file is open sz=%d\n",sz);
         m=mmap(0,sz*2,PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
         close(fd);
         printf("ok m=%ld\n",m);
         if (m!=MAP_FAILED){
            printf("ok\n");
            char *s="Hallo Welt\nDies ist ein Test--\n";
            memcpy(m,s,strlen(s));
            printf("fifi memcpy\n");
         }
         else{
           printf("error in %d\n",c);
           exit(1);
         }
      }
      else{
         printf("error %s\n",strerror(errno));
      }
   }
   exit(0);

   if (strhash_create(&HostTable,2,32,strhash_hash)==-1){
      fprintf(stderr,"fail to create HostTable\n");
      exit(1);
   }
   char *h="w8n00378.bmbg01.telekom.de";
   if (strhash_enter(&HostTable, 1,h,strlen(h), 1,"te\nst",5)==-1){
      fprintf(stderr,"fail to host %s\n",h);
      exit(1);
   }
   h="w8n00379.bmbg01.telekom.de";
   if (strhash_enter(&HostTable, 1,h,strlen(h), 1,"Hallo",5)==-1){
      fprintf(stderr,"fail to host %s\n",h);
      exit(1);
   }
   int vl;
   char *v;
   char *k="w8n00378.bmbg01.telekom.de";
   if(strhash_lookup(&HostTable, k,strlen(k),&v,&vl)){
      printf("found %s\n",v);
   }
   k="w8n00379.bmbg01.telekom.de";
   if(strhash_lookup(&HostTable, k,strlen(k),&v,&vl)){
      printf("found %s\n",v);
   }

   k="w8n0037x.bmbg01.telekom.de";
   if(strhash_lookup(&HostTable, k,strlen(k),&v,&vl)){
      printf("found %s\n",k);
   }
   else{
      printf("not found %s\n",k);
   }


   strhash_destroy(&HostTable);
   




   MsgState=mhash_init(MHASH_MD5);





  if (nArg!=2) {
    printf("usage: <command> <port>\n");
   return 0;
  }
  signal(SIGPIPE, SIG_IGN);
  listenfd=socket(AF_INET,SOCK_STREAM,0);
  bzero(&serveraddr,sizeof(serveraddr));
  serveraddr.sin_family=AF_INET;
  serveraddr.sin_addr.s_addr=htonl(INADDR_ANY);
  serveraddr.sin_port=htons(atoi(pszArgs[1]));
  if (bind(listenfd,(struct sockaddr*)&serveraddr,sizeof(serveraddr))){
     perror("bind");
     exit(-1);
  }
  listen(listenfd,1024);
  pthread_t tid;
  pthread_attr_t attr;
  
  while(1) {
     clilen=sizeof(clientaddr);
     connfd=accept(listenfd,(struct sockaddr*)&clientaddr,&clilen);
     printf("executing new thread for connection %d.\n",connfd);
     paramlist[0]=connfd;
     pthread_create(&tid,NULL,(void*)connectionthread,(void *)paramlist);
  }
  return 0;
}
 
void *connectionthread(void *somelist)
{
   fd_set rfds;
   int retval;
   struct timeval tv;
   int  bytes;

  // insert your client code here
   pthread_detach(pthread_self());
   int* paramlist=(int*)somelist;
   int connfd,i;
   connfd=paramlist[0];
   char buffer[1024];
   char cmdbuffer[1024];
   int  cmdhash;

   for (i=0; i<1024; i++) buffer[i]=0;
   sprintf(buffer,"Hello connection %d\n",connfd);
   printf("thread spawned for connection %d\n",connfd);
   
   FD_ZERO(&rfds);
   FD_SET(connfd, &rfds);
   FD_SET(0, &rfds);
   tv.tv_sec = 5;
   tv.tv_usec = 0;

   retval = select(connfd+1, &rfds, NULL, NULL, &tv);

   if (retval == -1){
       perror("select()");
   }
   else if (retval){
       printf("Data is available now.\n");
       /* FD_ISSET(0, &rfds) will be true. */
       bytes=recv(connfd,cmdbuffer,sizeof(cmdbuffer)-1,MSG_DONTWAIT);
       if (bytes==-1){
          perror("recv() from socket failed\n");
       }
       else{
          cmdbuffer[bytes]='\0';
          cmdhash=mhash(MsgState,buffer,strlen(buffer)); 
          printf("\n[new message]: %s  hash=%d\n", cmdbuffer,cmdhash);
       }
       // while(1) {
           sleep(1);
          if (sendto(connfd,buffer,strlen(buffer),0,NULL,MSG_NOSIGNAL)==-1){
              //break;
              perror("sendto");
          }
       // }
   }
   else{
       fprintf(stderr,"No data within five seconds.\n");
   }
   close(connfd);
   printf("thread close for connection %d\n",connfd);
   return(NULL);
}
