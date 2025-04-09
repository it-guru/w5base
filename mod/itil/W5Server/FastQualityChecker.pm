package itil::W5Server::FastQualityChecker;
use strict;
use kernel;
use kernel::date;
use kernel::W5Server;
use IO::Select;
use IO::Socket;
use FileHandle;
use POSIX;
use Time::HiRes(qw(sleep));

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

   my $insleep=1;
   $self->{'CheckSpool'}=[];

   my $opmode=$self->getParent->Config->Param("W5BaseOperationMode");
   my $ro=0;
   if ($opmode eq "readonly"){
      $ro=1;
   }
   my $spoolRefresh=time()-290;

   my $statepath=$self->Config->Param("W5ServerState");
   $statepath=~s/\/$//;
   my $socket_path=$statepath."/FastQualityChecker.sock";
   msg(DEBUG,"open socket : ".$socket_path);
   unlink($socket_path);
   my $main_socket=IO::Socket::UNIX->new(
      Local => $socket_path,
      Type      => SOCK_STREAM,
      Listen    => 5 
   );
   my $readable_handles = new IO::Select();
   $readable_handles->add($main_socket);


   while(1){
      if (!$ro){
         my $current=time();
         my ($year,$month,$day,$hour,$min,$sec)=Time_to_Date("GMT",$current);
         if ($hour>=7 and $hour<=18){
            $insleep=0;
         }
         else{
            # nightly check, if a QualityCheck process is running. If not,
            # FastQualityChecks can also be done at night.
            my $joblog=getModuleObject($self->Config,"base::joblog");
            $joblog->SetFilter({
               'name'=>'base::event::QualityCheck::QualityCheck',
               'event'=>'QualityCheck',
               'cdate'=>'>now-12h',
               'exitcode'=>'[EMPTY]'
            });
            my @l=$joblog->getHashList(qw(id));
            if ($#l==-1){
               $insleep=0;    # no nightly QualityCheck is currently running
            }
            else{
               $insleep=1;
               for(my $c=0;$c<300;$c++){
                  $self->handleCommandSocket($readable_handles);
               }
            }
            $self->handleCommandSocket($main_socket,$readable_handles);
         }
         if (time()-$spoolRefresh>300){
            $spoolRefresh=time();
            ###################################################################
            # Spool Refreh can be seperated in the itil::W5Server  the        #
            # FastQualityCheck will be moved in the future to base::W5Server  #
            ###################################################################
            if (1){  # put tokens in CheckSpool
               my $o=getModuleObject($self->Config,"itil::system");
               ###################################################################
               msg(INFO,"FastQualityChecker: doSpoolRefresh for shortly inst");
               $o->SetFilter({
                   cistatusid=>\'4',
                   instdate=>'<now-1h AND >now-2h',
                   itcloudareaid=>"![EMPTY]",
                   lastqcheck=>'<now-1h AND >now-2h'
               });
               my @l=$o->getHashList(qw(instdate lastqcheck id  mdate));
               foreach my $rec (@l){
                  my $token="itil::system::".$rec->{id};
                  if (!in_array($self->{'CheckSpool'},$token)){
                     push(@{$self->{'CheckSpool'}},$token);
                  }
               }
               ###################################################################
               msg(INFO,"FastQualityChecker: doSpoolRefresh for last 25h inst");
               $o->SetFilter({
                   cistatusid=>\'4',
                   instdate=>'<now-25h AND >now-26h',
                   itcloudareaid=>"![EMPTY]",
                   lastqcheck=>'<now-12h AND >now-26h'
               });
               my @l=$o->getHashList(qw(instdate lastqcheck id mdate));
               foreach my $rec (@l){
                  my $token="itil::system::".$rec->{id};
                  if (!in_array($self->{'CheckSpool'},$token)){
                     push(@{$self->{'CheckSpool'}},$token);
                  }
               }
               ###################################################################
            }
         }
         my $nent=$#{$self->{'CheckSpool'}}+1;
         msg(INFO,"FastQualityChecker: $nent in spool");
         if ($nent==0){
            $self->handleCommandSocket($main_socket,$readable_handles);
         }
         if ((!$insleep) &&
             ($#{$self->{'CheckSpool'}}!=-1)){
            my $st=time();
            PLOOP: while(my $token=shift(@{$self->{'CheckSpool'}})){
               my ($dataobj,$id)=$token=~m/^(.*)::([^:]+)$/;
               msg(INFO,"FastQualityChecker: start process id $id at $dataobj from spool");
               my $o=getModuleObject($self->Config,$dataobj);
               if (defined($o)){
                  $o->SetFilter({
                     id=>\$id,
                     lastqcheck=>'<now-55m',
                     cistatusid=>\'4',
                  });
                  my @l=$o->getHashList(qw(id lastqcheck qcstate mdate cistatusid));
                  if ($#l==-1){
                     msg(INFO,"FastQualityChecker: id $id hast lost need ".
                              "to qcheck since is in spool");
                     
                  }
                  else{
                     foreach my $rec (@l){
                        msg(INFO,"FastQualityChecker: qcheck result for id $id : ".
                                 $rec->{qcstate});
                     }
                  }
                  sleep(1);
                  if ($st-time()>60){
                     last PLOOP;
                  }
               }
            }
            $self->handleCommandSocket($main_socket,$readable_handles);
            $self->handleCommandSocket($main_socket,$readable_handles);
            $self->handleCommandSocket($main_socket,$readable_handles);
         }
      }
      $self->handleCommandSocket($main_socket,$readable_handles);
   }
}

sub handleCommandSocket
{
   my $self=shift;
   my $main_socket=shift;
   my $readable_handles=shift;

   my ($newsock)=IO::Select->select($readable_handles,undef,undef,1);
   foreach my $sock (@$newsock) {         # in slots
      if ($sock==$main_socket){
         my $new_sock=$sock->accept();
         $readable_handles->add($new_sock);
      } 
      else{
         my $buf=<$sock>;
         if ($buf){
            my $command=trim($buf);
            $self->processConsoleCommand($sock,$command);
         }
         else{
            $readable_handles->remove($sock);
            close($sock);
         }
      }
   }
}

sub processConsoleCommand
{
   my $self=shift;
   my $client=shift;
   my $command=shift;

   my @cmdline=split(/\s+/,$command);

   if ($cmdline[0] eq ""){
      printf $client ("Hello\n");
   }
   elsif (lc($cmdline[0]) eq lc("time")){
      printf $client ("time:%s\n",time());
   }
   elsif (lc($cmdline[0]) eq lc("CheckSpool")){
      printf $client ("CheckSpool:\n%s\n",join("\n",@{$self->{'CheckSpool'}}));
   }
   elsif (lc($cmdline[0]) eq lc("FastQualityCheck")){
      my $token=$cmdline[1]."::".$cmdline[2];
      printf $client ("FastQualityCheck: added %s\n",$token);
      push(@{$self->{'CheckSpool'}},$token);
   }
   else{
      printf $client ("ERROR: unkown command '%s'\n",$command);
   }
}




sub reload
{
   my $self=shift;
   $self->{doForceCleanup}++;
}










1;


