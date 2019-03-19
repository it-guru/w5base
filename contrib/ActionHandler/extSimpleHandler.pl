#!/usr/bin/perl
use strict;

use POSIX ":sys_wait_h";
use IO::Socket;
use IO::Select;
use Sys::Syslog qw(:standard :macros);

my @triggerList;
my %CONFIG;
my %child; # child pids
my $S;     # server socket
my $ss;    # socket selector
my $PIDFILE="/var/run/extSimpleHandler/extSimpleHandler.pid";

$SIG{INT} = \&Shutdown;
$SIG{TERM} = \&Shutdown;
$SIG{HUP} = \&Reload;

$0="extSimpleHandler.pl";

sub Reload
{
   msg("ERROR","reload extSimpleHandler not suppored");
}


sub Shutdown
{
   msg("INFO","Shutdown extSimpleHandler");
   if (defined($S)){
      $S->close();
   }
   #unlink($PIDFILE);  # this should be done by systemd
   exit(1);
}



# Step 1: Read Config
#printf STDOUT ("Level 0: start load of configuration\n");
if ($ENV{EXTSIMPLEHANDLERCONFIG} ne "1"){
   printf STDERR ("ERROR: PL-Script not called by startup shell script\n");
   exit(1)
}
# In this simple case, the config is loaded bei Enviroment Variables.
# As result of this defininition, all config parameters are located
# in %ENV  and Command Parameters are in @ARGV
# After Load, all needed parameters need to be get a basic check!
$CONFIG{HANDLER_PORT}=$ENV{HANDLER_PORT};

# Step 2: Install Signal Handler




# Step 3: Allocated Port Listener

$S=new IO::Socket::INET (
    LocalHost => '0.0.0.0',     LocalPort => $CONFIG{HANDLER_PORT},
    Proto => 'tcp', Timeout => 5, Listen => 5,  Blocking=>0
);
die("fail to listen on $CONFIG{HANDLER_PORT}") if (!defined($S));

if ( -d "/var/run/extSimpleHandler"){
   if (open(F,">$PIDFILE")){
      printf F ("%d\n",$$);
      close(F);
   }
}


$ss=IO::Select->new();  # create a socket selector
$ss->add($S);  # Server socket
# Step 3: Continous Process loop
my $hourTimer=time();
my $t1=1800;
msg("INFO","Starting extSimpleHandler ...");
while(1) {
   # Handling Network triggers 
   my ($ready)=IO::Select->select($ss,undef,undef,1.0);
   foreach my $fh (@$ready) {
      if ($fh==$S){
         $ss->add($S->accept());  # add new client socket
      }
      else{
         my $buffer;
         if (!sysread($fh,$buffer,1024*32)){  # Max Request size = 32k
            $ss->remove($fh);
            close($fh);
         }
         my @buf=split(/\s*[\n\r]{1,2}/,$buffer);
         foreach my $buf (@buf){
            if (my ($path)=$buf=~m/^GET\s+(\S+)\s+HTTP\/1\..\s*$/){
               push(@triggerList,{path=>$path});
            }
         }
         printf $fh ("HTTP/1.0 200 OK\n");
         printf $fh ("Content-type: text/plain\n");
         printf $fh ("Connection: Closed\n");
         printf $fh ("\n");
         printf $fh ("OK\n");
         $ss->remove($fh);
         close($fh);
      }
   }
   if ($#triggerList!=-1){
      foreach my $reqrec (@triggerList){
         my $url=$reqrec->{path};
         msg("INFO","got web request trigger '".$url."'");
      }
      @triggerList=();
      StartEventProcess(\@triggerList);
   }
   if (time()-$t1>$hourTimer){
      $hourTimer=time();
      msg("INFO","zycle t1=$t1 timer trigger");
      StartEventProcess("t1");
   }
   {   # handle child terminations
      my $kid;
      do{
        $kid=waitpid(-1,WNOHANG);
        if ($kid>0){
           foreach my $k (keys(%child)){
              if ($kid eq $child{$k}){
                 delete($child{$k});
              }
           }
        }
      }while($kid>0); 
   }
}

sub msg   # send messages to syslog (as planed from unix parents :-) )
{
   my $facility=shift;
   my $txt=shift;
   if ($facility eq "ERROR"){
      syslog(LOG_ERR,$txt);
   }
   else{
      syslog(LOG_INFO,$txt);
   }
}


sub StartEventProcess
{
   my $triggerList=shift;

   if (!exists($child{t1}) || !kill(0,$child{t1})){
      my $pid;
      if (!defined($pid=fork())){
         msg("ERROR","fork EventProcess failed");
         die("Cannot fork() - $!");
      }
      if ($pid==0){
         msg("INFO","StartEventProcess");
         { # prepare EventProcess task to run "clean"
            # fixup signal handling
            foreach my $signame (keys(%SIG)){
               $SIG{$signame} = 'DEFAULT';
            }
            $SIG{ALRM}=sub{
               my $msg="EventProcess died by process timeout";
               msg("ERROR",$msg);
               die($msg);
            };
            alarm(600); # EventProcess max time is 60 seconds
            # fixup file handles
            for(my $c=0;$c<254;$c++){  # ensure, that all filehandles are closed
               POSIX::close($c);
            }
         }
         # run procedure
         my $exitcode=EventProcess();
         msg("INFO","EndEventProcess");
         exit($exitcode);
      }
      else{
         $child{t1}=$pid;
      }
   }
}

sub EventProcess
{
   my $c;
   for(my $c=0;$c<3;$c++){
      die("parent died") if (getppid()==1);
      msg("INFO","in EventProcess handler");
      sleep(2);
   }
   return(0);
}






