package base::W5Server::Reporter;
use strict;
use IO::Select;
use IO::Socket;
use kernel;
use kernel::date;
use kernel::W5Server;
use FileHandle;
use POSIX;
use vars (qw(@ISA));
@ISA=qw(kernel::W5Server);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub process
{
   my $self=shift;

   while(1){
      $self->Reporter();
      sleep(600);
   }
}

sub Reporter
{
   my $self=shift;
 
   my $reportjob=getModuleObject($self->Config,"base::reportjob");



   #######################################################################
   #
   #  Unix-Socket command reader
   #
   my $statepath=$self->Config->Param("W5ServerState");
   my $socket_path=$statepath."/reporter.sock";
   unlink($socket_path);
   my $main_socket=IO::Socket::UNIX->new(Local => $socket_path,
                                Type      => SOCK_STREAM,
                                Listen    => 5 );
   my $readable_handles = new IO::Select();
   $readable_handles->add($main_socket);
   my @slot=(undef,undef,undef,undef,undef);
   $self->{task}=[];
   my %cons=();
   my $last_taskCreator=0;
   $self->{console}=\%cons;
   my %Reporter=(start=>time(),reportjob=>$reportjob,tasklist=>$self->{task});
   while (1) {  #Infinite loop
       my ($newsock)=IO::Select->select($readable_handles,undef,undef,1);
       $Reporter{loopcount}++;
       $Reporter{consolen}=keys(%cons);
       $self->slotHandler(\%Reporter,\@slot);  # executes tasks if is space 
       foreach my $sock (@$newsock) {      # in slots
           if ($sock == $main_socket) {
               my $new_sock = $sock->accept();
               $readable_handles->add($new_sock);
               $cons{$new_sock}={handle=>$new_sock};
           } else {
               my $buf = <$sock>;
               if ($buf) {
                   my $command=$buf;
                   $command=~s/\s*$//;
                   $self->processConsoleCommand(\%Reporter,
                                                \%cons,$sock,$command);
               } else {
                   delete($cons{$sock});
                   $readable_handles->remove($sock);
                   close($sock);
               }
           }
       }   
       if ($last_taskCreator==0 ||
           $last_taskCreator<time()-30){  # call taskCreator every half minute
          $self->taskCreator(\%Reporter);     
          $last_taskCreator=time();
       }
   }
   #######################################################################
}

sub processConsoleCommand
{
   my $self=shift;
   my $reporter=shift;
   my $cons=shift;
   my $client=shift;
   my $command=shift;
   my $reportjob=$reporter->{reportjob};

   if ($command eq ""){
   }
   elsif ($command eq "uptime"){
      printf $client ("uptime: %d\n",$reporter->{start});
   }
   elsif ($command eq "exit"){
      close($client);
   }
   elsif ($command eq "status"){
      my %d=%$reporter;
      delete($d{reportjob});
      printf $client ("status: %s\n",Dumper(\%d));
   }
   elsif ($command eq "shutdown"){
      $self->Shutdown();
      exit(0);
   }
   else{
      printf $client ("ERROR: unkown command '%s'\n",$command);
   }

}


sub taskCreator
{
   my $self=shift;
   my $reporter=shift;
   my $task=shift;
   my $reportjob=$reporter->{reportjob};

   foreach my $r (values(%{$reportjob->{Reporter}})){
       $r->taskCreator($self,$reporter);
   }
}

sub addTask
{
   my $self=shift;
   my $name=shift;
   my $param=shift;

   $param->{maxstderr}=128 if (!exists($param->{maxstderr}));
   $param->{maxstdout}=128 if (!exists($param->{maxstdout}));
   if ($#{$self->{task}}<100){  # max 100 task in queue
      $self->broadcast("receive a new task request for $name");
      push(@{$self->{task}},{name=>$name,stdout=>[],stderr=>[],
                             param=>$param,
                             requesttime=>time()});
      return(1);
   }
   return(0);
}


sub Shutdown
{
   my $self=shift;

}


sub handleSlotIO
{
   my $self=shift;
   my $reporter=shift;
   my $slot=shift;

   while(1){
      my $readedlines=0;
      my $s=new IO::Select();
      $s->add($slot->{stdout});
      $s->add($slot->{stderr});
      my @ready=$s->can_read(0);
      for(my $c=0;$c<=$#ready;$c++){
         my $fh=$ready[$c];
         my $line=<$fh>;
         if ($line){
            $line=~s/\s*$//;
            my $taskname=$slot->{task}->{name};
            my $module=$reporter->{reportjob}->{Reporter}->{$taskname};
            if ($fh eq $slot->{stdout}){
               $module->stdout($line,$slot->{task},$reporter);
               $readedlines++;
            }
            if ($fh eq $slot->{stderr}){
               $module->stderr($line,$slot->{task},$reporter);
               $readedlines++;
            }
         }
      }
      last if (!$readedlines);
   }
}







sub slotHandler
{
   my $self=shift;
   my $reporter=shift;
   my $slot=shift;

   $reporter->{runningJobs}=0;
   $reporter->{maxSlots}=$#{$slot}+1;
   $reporter->{usedSlots}=0;
   $SIG{CHLD}='DEFAULT';
   for(my $c=0;$c<=$#{$slot};$c++){
      if (defined($slot->[$c])){
         $reporter->{usedSlots}++;
         $self->handleSlotIO($reporter,$slot->[$c]);
         my $pid=$slot->[$c]->{pid};
         if ((my $sysexitcode=waitpid($pid,WNOHANG))>0){
            my $sig=$?>>8;
            $slot->[$c]->{task}->{waitpidresult}=$sysexitcode; 
            $slot->[$c]->{task}->{exitcode}=$sig; 
            my $module=$slot->[$c]->{task}->{name};
            $self->broadcast("Finish ".$module." slot $c at PID $pid($sig)");
            my $reportermodules=$reporter->{reportjob}->{Reporter};
            $reportermodules->{$module}->Finish($slot->[$c]->{task},$reporter);
            $slot->[$c]=undef;
         }
         else{
            if (kill(0,$pid)){
               $reporter->{runningJobs}++;
            }
            else{
               my $module=$slot->[$c]->{task}->{name};
               $self->broadcast("seltsam $pid scheint tot zu sein");
               my $reportermodules=$reporter->{reportjob}->{Reporter};
               $reportermodules->{$module}->Finish($slot->[$c]->{task},
                                                   $reporter);
               $slot->[$c]=undef;
            }
         }
         
      }
      else{
         my $task=shift(@{$self->{task}});    # load next task from queue
         if (defined($task)){
            $slot->[$c]={task=>$task};
            my ($rSTDERR,$newSTDERR);
            pipe($rSTDERR,$newSTDERR);
            my ($rSTDOUT,$newSTDOUT);
            pipe($rSTDOUT,$newSTDOUT);
            $slot->[$c]->{stdout}=$rSTDOUT;
            $slot->[$c]->{stderr}=$rSTDERR;
            my $pid=fork();                   # fork the task 
            if ($pid==0){
               $|=1;
               close(STDIN);
               $SIG{PIPE}='DEFAULT';
               $SIG{INT}='DEFAULT';
               $SIG{TERM}='DEFAULT';
               $SIG{QUIT}='DEFAULT';
               $SIG{HUP}='DEFAULT';
               $SIG{CHLD}='DEFAULT';

               open(STDERR, ">&".fileno($newSTDERR));
               open(STDOUT, ">&".fileno($newSTDOUT));
               for(my $cc=3;$cc<254;$cc++){  # ensure, that all 
                  POSIX::close($cc);       # filehandles are closed
               }
               $0.="(".$task->{name}.")";
               my $reportermodules=$reporter->{reportjob}->{Reporter};
               my $bk=$reportermodules->{$task->{name}}->Process();
               if (defined($bk) && $bk>0){
                  printf STDERR ("existcode:$bk\n");
                  exit($bk);
               }
               exit(0);
            }
            else{
               $self->broadcast("starting job $task->{name} at ".
                                "slot $c on pid $pid");
               $slot->[$c]->{pid}=$pid;
               $reporter->{jobcount}++
            }
         }
      }
   }

}

sub broadcast
{
   my $self=shift;
   my $msg=shift;

   foreach my $cons (values(%{$self->{console}})){
      my $h=$cons->{handle};
      printf $h ("%s: %s\n",NowStamp("en"),$msg);
   }
}




sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


