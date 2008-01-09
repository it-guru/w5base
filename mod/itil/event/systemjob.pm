package itil::event::systemjob;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use vars qw(@ISA);
use Data::Dumper;
use kernel;
use kernel::Event;
use Fcntl ':flock';
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("systemjob","SystemJob");
   return(1);
}

sub ProcessCommand
{
   my $self=shift;
   my ($wf,$WfRec,$sys,$job)=@_;

   $self->SetJobState($wf,$WfRec,4);


   my $statedir=$self->Config->Param("W5ServerState");
   msg(DEBUG,"statedir=%s",$statedir); 
   $statedir.="/ServerJob";
   if ( ! -d $statedir){
      msg(DEBUG,"create '%s'",$statedir); 
      if (!mkdir($statedir)){
         msg(ERROR,"create '%s' failed",$statedir); 
      }
   }
   $statedir.="/".$WfRec->{id};
   if ( ! -d $statedir){
      msg(DEBUG,"create '%s'",$statedir); 
      if (!mkdir($statedir,0777)){
         msg(ERROR,"create '%s' failed",$statedir); 
      }
   }
   if (!-d $statedir){
      $self->SetJobState($wf,$WfRec,22,
                         "ERROR: can't create statedir '$statedir'");
      return(undef);
   }

   #open(FLOCK,">>$statedir/job.mon") && close(FLOCK);
   #if (!open(FLOCK,"<$statedir/job.mon") || !flock(FLOCK,LOCK_EX|LOCK_NB)){
   #   return({exitcode=>1,msg=>'already monitored'});
   #}
   my $ctrlip=undef;
   if (ref($sys->{ipaddresses}) eq "ARRAY"){
      foreach my $ip (@{$sys->{ipaddresses}}){
         $ctrlip=$ip->{name} if ($ip->{addresstyp}==0);
      }
      foreach my $ip (@{$sys->{ipaddresses}}){
         $ctrlip=$ip->{name} if ($ip->{iscontrolpartner});
      }
   }
   if (!defined($ctrlip)){
      $self->SetJobState($wf,$WfRec,22,"ERROR: can't find a useable ip");
      return(undef);
   }
   if (!-f "$statedir/job.pid" && !$self->isJobRunning($statedir,$WfRec)){
      $self->StoreResult($wf,$statedir,$WfRec,8);
      if (!open(CMD,">$statedir/cmd.sh")){
         $self->SetJobState($wf,$WfRec,22,"ERROR: can't create command");
         return(undef);
      }
      print CMD <<EOFL;
#!/bin/sh
PATH=bin:/usr/local/bin:/usr/bin:/bin
if test -f .W5Base.ControlCenter; then
   . .W5Base.ControlCenter
fi
CC_CTRLIP=$ctrlip
export CC_CTRLIP
REMOTE_USER="$WfRec->{openusername}"
export REMOTE_USER
sleep 1
perl <<EOFPERLCODE
use vars(qw(\$PARAM));
EOFL
      my $h=$WfRec->{additional};
      $h={Datafield2Hash($h)};
      CompressHash($h);
      my $pcode=Data::Dumper->Dump([$h], [qw($PARAM)]);
      $pcode.=$job->{pcode};
      my $remoteuser=$job->{remoteuser};
      $remoteuser="w5base" if ($remoteuser=~m/^\s*$/);
      $wf->Store($WfRec->{id},{pcode=>$pcode});
      $pcode=~s/\\/\\\\/g;
      $pcode=~s/\$/\\\$/g;
      $pcode.=<<EOFL;

EOFPERLCODE
BACK=\$?
if [ "\$CC_PROXY" != "1" ]; then
   echo "EXITCODE:\$BACK:"
fi
exit \$BACK
EOFL
      print CMD ($pcode);
      close(CMD);
      msg(DEBUG,"env '%s'",Dumper(\%ENV));
      my $remotecmd="cat >ControlCenter.cmd.sh && sh ControlCenter.cmd.sh";
      my $sshparam="-o BatchMode=yes -o StrictHostKeyChecking=no ".
                   "-o ForwardX11=no -T";
      if (!($sys->{ccproxy}=~m/^\s*$/)){
         $remotecmd="cat >ControlCenter.cmd.sh && ".
                    "sh ControlCenter.cmd.sh";
         $remotecmd="CC_PROXY=1 CC_TARGET=$sys->{name} && ".
                    "export CC_PROXY && export CC_TARGET && ".
                    "echo \"ControlCenter: starting PROXY command\" && ".
                    "$remotecmd && ".
                    "echo \"\" && ".
                    "echo \"ControlCenter: starting systemjob\" && ".
                    "cat ControlCenter.cmd.sh | ".
                    "ssh $sshparam $remoteuser\@$ctrlip \"$remotecmd\"";
         $ctrlip=$sys->{ccproxy};
      }
      my $PATH="bin:/usr/local/bin:/usr/bin:/bin";
      my $cmd="cat cmd.sh | ssh $sshparam $remoteuser\@$ctrlip '$remotecmd'";
      msg(DEBUG,"cmd='%s'",$cmd); 
      $SIG{INT}='IGNORE';
      my $finecommand="cd $statedir && nohup $cmd > $statedir/job.stdout.log ".
                      "2>$statedir/job.stderr.log & ".
                      "echo \$! >$statedir/job.pid";
      $wf->Store($WfRec->{id},{command=>$finecommand});
      system($finecommand);
      $SIG{INT}='DEFAULT';
      sleep(1);
   }
   my $loopcount=0;
   my $loopstore=5;
   while($self->isJobRunning($statedir,$WfRec)){
      $loopcount++;
      if ($loopcount>$loopstore){
         $loopstore*=2 if ($loopstore<60);
         $loopcount=0;
         $self->StoreResult($wf,$statedir,$WfRec,4);
      }
      msg(DEBUG,"wait ($$ for wfheadid=$WfRec->{id})"); 
      sleep(1);
   }
   msg(DEBUG,"wait"); 
   $self->StoreResult($wf,$statedir,$WfRec,21);
   if (!$self->isJobRunning($statedir,$WfRec)){
      unlink("$statedir/job.pid");
      unlink("$statedir/cmd.sh");
      unlink("$statedir/job.mon");
      unlink("$statedir/job.stdout.log");
      unlink("$statedir/job.stderr.log");
      rmdir("$statedir");
   }
}

sub StoreResult
{
   my $self=shift;
   my $wf=shift;
   my $statedir=shift;
   my $WfRec=shift;
   my $stateid=shift;

   my $stdout;
   my $stderr;
   my %rec=();
   if ($stateid==8){
      if ($wf->Action->StoreRecord(
          $WfRec->{id},"note",
          {translation=>'itil::workflow::systemjob'},"Job init")){
      }
      $rec{eventstart}=$self->getParent->ExpandTimeExpression('now');
   }
   if ($stateid==21){
      if ($wf->Action->StoreRecord(
          $WfRec->{id},"note",
          {translation=>'itil::workflow::systemjob'},"Job finish")){
      }
      $rec{eventend}=$self->getParent->ExpandTimeExpression('now');
      $rec{closedate}=$self->getParent->ExpandTimeExpression('now');
   }
   else{
      $rec{eventend}=undef;
      $rec{closedate}=undef;
   }
   if (open(F,"<$statedir/job.stdout.log")){
      my @stdout=<F>;
      if ($#stdout!=-1){
         if (my ($exitcode)=$stdout[$#stdout]=~m/^EXITCODE:(\d+):\s*$/){
            $stateid=22 if ($exitcode!=0);
         }
      }
      else{
         $stateid=23 if ($stateid==21);
      }
      $stdout=join("",@stdout);
      close(F);
   }
   if (open(F,"<$statedir/job.stderr.log")){
      $stderr=join("",<F>);
      close(F);
   }
   $stateid=22 if ($stdout eq "" && $stderr ne "" && $stateid==21);
   my $desc=$stdout;
   if ($stderr ne ""){
      $stderr.="\n\n" if ($stdout ne "");
      $desc="ERROR:\n".$stderr.$desc;
   }
   $rec{detaildescription}=$desc;
   $rec{stateid}=$stateid if (defined($stateid));
   
   $wf->Store($WfRec->{id},\%rec);
}

sub isJobRunning
{
   my $self=shift;
   my $statedir=shift;
   my $WfRec=shift;

   my $pid;
   if (open(STF,"<$statedir/job.pid")){
      $pid=<STF>;
      $pid=~s/\s*$//;
      close(STF);
   }
   if ($pid ne ""){
      if (kill(0,$pid)){
         return(1);
      }
   }
   return(0);
}

sub SetJobState
{
   my $self=shift;
   my $wf=shift;
   my $WfRec=shift;
   my $stateid=shift;
   my $msg=shift;

   my $step='itil::workflow::systemjob::process';
   my %rec=(step=>$step,stateid=>$stateid);
   $rec{detaildescription}=$msg if (defined($msg));
   $wf->Store($WfRec->{id},\%rec);
}

sub SystemJob
{
   my $self=shift;
   my $id=shift;
   msg(DEBUG,"Processing Workflow $id");
   my $wf=getModuleObject($self->Config,"base::workflow");
   $wf->SetFilter({id=>\$id,class=>\'itil::workflow::systemjob'});
   my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
   if (defined($WfRec)){
      my $jobid=$WfRec->{jobid};
      my $systemid=$WfRec->{affectedsystemid};
      if (ref($WfRec->{affectedsystemid}) eq "ARRAY"){
         $systemid=$WfRec->{affectedsystemid}->[0];
      }
      my $osjob=getModuleObject($self->Config,"itil::systemjob");
      my $osys=getModuleObject($self->Config,"itil::system");
      if ($jobid ne "" && $systemid ne "" && defined($osjob) && defined($osys)){
         $osys->SetFilter({id=>\$systemid});
         my ($sys,$msg)=$osys->getOnlyFirst(qw(ipaddresses ccproxy name));
         $osjob->SetFilter({id=>\$jobid});
         my ($job,$msg)=$osjob->getOnlyFirst(qw(ALL));
         msg(INFO,"job=%s",Dumper($job));
         msg(INFO,"sys=%s",Dumper($sys));
         msg(INFO,"WfRec=%s",Dumper($WfRec));
         $self->ProcessCommand($wf,$WfRec,$sys,$job);
         return({exitcode=>'0'});
      }
   }
   return({exitcode=>'1'});
}


1;
