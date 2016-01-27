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
use File::Temp qw(tempfile);

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

   foreach my $sig (qw(__DIE__ __WARN__ INT)){
      $SIG{$sig}=sub{
          my $loc="";
          my @loc = caller(1);
          if ($_[0] ne "INT"){
             $loc.=sprintf("$sig generated at line $loc[2] in $loc[1]:%s\n",@_);

             my $max_depth = 30;
             my $i = 1;

             while ( (my @call_details = (caller($i++))) && ($i<$max_depth) ) {
               $loc.=sprintf("$i $call_details[1]($call_details[2]) ".
                             "in $call_details[3]\n");
             }

             $self->NotifyAdmin(
                 "Reporter DIE pid=$$:",$loc);
          }
          exit(1);
      };
   }

  my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }



   while(1){
      if (!$ro){
         $self->Reporter();
      }
      sleep(600);
   }
}

sub Reporter
{
   my $self=shift;
   my $ppid=getppid();
 
   my $reportjob=getModuleObject($self->Config,"base::reportjob");
   $reportjob->BackendSessionName("ForceUncached");



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
       if (!$Reporter{reportjob}->Ping()){
          sleep(120); # etwas warten - dann sollte die DB wieder da sein
          die("lost connection to database - Restart needed");
       }
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
                                               \%cons,$sock,
                                               \@slot,
                                               $command);
               }
               else{
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
       die('lost my parent W5Server process - not good') if (getppid()==1);
   }
   #######################################################################
}

sub processConsoleCommand
{
   my $self=shift;
   my $reporter=shift;
   my $cons=shift;
   my $client=shift;
   my $slot=shift;
   my $command=shift;
   my $reportjob=$reporter->{reportjob};

   if ($command eq ""){
   }
   elsif ($command eq "uptime"){
      printf $client ("uptime: %d\n",$reporter->{start});
   }
   elsif ((my $module)=$command=~m/^run\s+(\S+)$/){
      if (exists($reportjob->{Reporter}->{$module})){
         $self->addTask($module);
         $reportjob->{Reporter}->{$module}->{lastrun}=NowStamp("en");
         printf $client ("OK\n"); 
      }
      else{
         printf $client ("ERROR: Invalid module name '%s'\n",$module); 
      }
   }
   #elsif ($command eq "exit"){
   #   close($client);
   #}
   elsif ($command eq "status"){
      my %d=%$reporter;
      delete($d{reportjob});
      my $d=Dumper(\%d);
      $d=~s/^.*?{/{/;
      printf $client ("status: %s\n",$d);
      printf $client ("Loaded modules:\n");
      my @run;
      foreach my $s (@{$slot}){
         if (defined($s) && ref($s) eq "HASH" &&
             defined($s->{task})){
            push(@run,$s->{task}->{name});
         }
      }
      foreach my $module (sort(keys(%{$reportjob->{Reporter}}))){
         my $r="";
         if (in_array(\@run,$module)){
            $r="running";
         }
         printf $client ("- %-42s %s %s\n",$module,
                         $reportjob->{Reporter}->{$module}->{lastrun},
                         $r);
      }
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
      $s->add($slot->{stdout}) if (defined($slot->{stdout}));
      $s->add($slot->{stderr}) if (defined($slot->{stderr}));
      my @ready=$s->can_read(0);
      foreach my $fh (@ready){
         my $line=<$fh>;
         #$self->broadcast("fifi - $? - handleSlotIO: (read on=$fh) err=$slot->{stderr} out=$slot->{stdout} line=$line");
         if (!defined($line)){
            if ($fh eq $slot->{stdout}){
               $slot->{stdout}=undef;
            }
            if ($fh eq $slot->{stderr}){
               $slot->{stderr}=undef;
            }
         }
         else{
            $line=~s/\s*$//;
            my $taskname=$slot->{task}->{name};
            my $module=$reporter->{reportjob}->{Reporter}->{$taskname};
            if ($fh eq $slot->{stdout}){
               $module->stdout($line,$slot->{task},$reporter);
            }
            elsif ($fh eq $slot->{stderr}){
               $module->stderr($line,$slot->{task},$reporter);
            }
            else{
               $self->broadcast("fifi handleSlotIO: seltsamer fh=$fh");
               last;
            }
         }
         $readedlines++;
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
         my $pid=$slot->[$c]->{pid};
         my $sysexitcode=waitpid($pid,WNOHANG);
         my $sysexitcodestate=$?;
         $self->handleSlotIO($reporter,$slot->[$c]);
         if ($sysexitcode>0){
            
            my $exitcode=$sysexitcodestate>>8;
            my $sig=$sysexitcodestate&127;
            if ($sig!=0){
               push(@{$slot->[$c]->{task}->{stderr}},
                    "terminated by Signal($sig)\n"); 
               $exitcode=1;
            }
            $slot->[$c]->{task}->{waitpidresult}=$sysexitcode; 
            $slot->[$c]->{task}->{exitcode}=$exitcode; 
            my $module=$slot->[$c]->{task}->{name};
            $self->broadcast("Finish ".$module." slot $c at ".
                             "PID $pid(sig=$sig;exitcode=$exitcode)");
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
               push(@{$slot->[$c]->{task}->{stderr}},"$pid seams died\n"); 
               $slot->[$c]->{task}->{exitcode}=1; 
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
               close(STDIN);
               $SIG{PIPE}='DEFAULT';
               $SIG{INT}='DEFAULT';
               $SIG{TERM}='DEFAULT';
               $SIG{QUIT}='DEFAULT';
               $SIG{HUP}='DEFAULT';
               $SIG{CHLD}='DEFAULT';

               open(STDERR, ">&".fileno($newSTDERR));
               open(STDOUT, ">&".fileno($newSTDOUT));

               W5Server::CloseAllOpenFieldHandles();    
               W5Server::MakeAllDBHsForkSafe();

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
               my $joblog=getModuleObject($self->Config,"base::joblog");
               if (defined($joblog)){
                  my $id=$joblog->ValidatedInsertRecord({
                     event=>$self->Self,
                     name=>"JobStart:$task->{name}",
                     exitcode=>0,
                     pid=>$pid,
                     exitstate=>'starting',
                     exitmsg=>''});
               }
               else{
                  die("fail to create joblog object");
               }
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


sub NotifyAdmin
{
   my $self=shift;
   my $subject=shift;
   my $text=shift;

   my @sendmailpath=qw(/usr/local/sbin/sendmail 
                       /sbin/sendmail 
                       /usr/sbin/sendmail 
                       /usr/lib/sendmail
                       /usr/lib/sbin/sendmail);
   my $sendmail=undef;
   foreach my $s (@sendmailpath){
      if (-x $s){
         $sendmail=$s;
         last;
      }
   }
   if (!defined($sendmail)){
      printf STDERR ("ERROR no sendmail found\n");
      exit(1);
   }

   my $user=$self->Config->Param("W5SERVERSERVICE");
   my $sitename=$self->Config->Param("SITENAME");
   if ($user eq ""){
      $user=$self->Config->Param("W5SERVERUSER");
   }
   if ($sitename ne ""){
      $sitename="W5Server: $sitename";
   }
   else{
      $sitename="W5Server";
   }
   $sitename=~s/["']//g;
   $user="root" if ($user eq "");
   my ($fh,$filename)=tempfile();
   if (defined($fh)){
      printf $fh ("cat << EOF | $sendmail -t\n");
      printf $fh ("To: %s\n",$user);
      printf $fh ("From: %s\n","\"$sitename\" <W5Server>");
      printf $fh ("Subject: %s\n",$subject);
      printf $fh ("Content-Type: text/plain; charset=\"iso-8859-1\"\n\n");
      print $fh ($text);
      print $fh "\nEOF\n";
      close($fh);
      system("sh $filename");
      unlink($filename);
   }
}











1;


