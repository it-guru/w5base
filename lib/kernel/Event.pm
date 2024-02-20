package kernel::Event;
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::App;
use kernel::Universal;

@ISA=qw(kernel::App);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub Init                  # at this method, the registration must be done
{
   my $self=shift;

   my $pack=ref($self);
   $pack=~s/^.*:://;
   if ($self->can($pack)){
      msg(DEBUG,"auto RegisterEvent '$pack'");
      $self->RegisterEvent($pack,ref($self)."::".$pack);
   }
   return(1);
}

sub RegisterEvent
{
   my $self=shift;
   my $name=shift;
   my $method=shift;
   my %param=@_;
   my $p=$self->getParent();
   $p->{Events}={} if (!defined($p->{Events}));
   $p->{Events}->{$name}=[] if (!defined($p->{Events}->{$name}));
   if (!ref($method) && !($method=~m/::/)){
      my $c=caller();
      $method=$c."::".$method;
   }
   my $timeout=60*60;
   $timeout=$param{timeout} if (defined($param{timeout}));
   push(@{$p->{Events}->{$name}},{name=>$name,
                                  timeout=>$timeout, 
                                  obj=>$self,
                                  method=>$method});
}

sub getLastRunDate
{
   my $self=shift;
   my $status=shift;
   my $method=shift;
   my $count;
   $status="ok" if (!defined($status));
   $count=1 if (!defined($count));
   $method=(caller(1))[3] if (!defined($method));
   my $joblog=getModuleObject($self->Config,"base::joblog");
   return(undef) if (!defined($joblog));
   $joblog->SetFilter(name=>\$method,exitstate=>\$status);
   $joblog->Limit($count);
   my @l=$joblog->getHashList(qw(id exitstate exitcode cdate mdate));
   #printf STDERR ("getLastRunDate: status=$status count=$count method=$method\n");
   if ($#l>=0){
      #printf STDERR ("d:%s\n",Dumper(\$l[0]));
      return($l[0]->{mdate},$l[0]->{exitcode});
   }
   return(undef);
}

sub W5ServerCall
{
   my $self=shift;
   my $method=shift;
   my @param=@_;

   if (!defined($self->Cache->{W5Server})){
      msg(ERROR,"no W5Server connection for call '%s'",$method);
      return(undef);
   }
   my $bk;
   my $retry=15;
   while(!defined($bk=$self->Cache->{W5Server}->Call($method,@param))){
      sleep(1);
      $retry--;
      last if ($retry<=0);
   }
   return($bk);
}

sub getPersistentModuleObject    # kann u.U. demnächst durch die App.pm ersetzt
{                                # werden
   my $self=shift;
   my $label=shift;
   my $module=shift;

   $module=$label if (!defined($module) || $module eq "");
   if (!defined($self->{$label})){
      my $config=$self->Config();
      my $m=getModuleObject($config,$module);
      $self->{$label}=$m
   }
   if (defined($self->{$label}) && $self->{$label}->can("ResetFilter")){
      $self->{$label}->ResetFilter();
   }
   return($self->{$label});
}




sub Config()
{
   my $self=shift;
   return($self->getParent->Config);
}

sub ServerGoesDown()
{
   my $self=shift;
   return(1) if (exists($self->{ServerGoesDown}));
   return(0);
}

sub ipcStore
{
   my $self=shift;
   my $data=shift;
   if (ref($data) ne "HASH"){
      $data={state=>$data};
   }
   my ($package, $filename, $line, $subroutine, $hasargs,
       $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
   $data->{method}=$subroutine if (!defined($data->{method}));

   return($self->getParent->ipcStore($data));
}

sub CreateIntervalEvent($$$)
{
   my $self=shift;
   my $name=shift;
   my $interval=shift;   # in seconds
   my $p=$self->getParent();
   $p->{Timer}={} if (!defined($p->{Timer}));
   $p->{Timer}->{$name}={lastevent=>time(),
                         interval=>$interval,
                         obj=>$self,
                         event=>$name};
}



sub robustEventObjectInitialize
{
   my $self=shift;
   my $pStaleRetry=shift;  # stale retry is given, if within $ast all calls
   my $ast=shift;          # have an exitcode !=0
   my $O=shift;
   my @O;
   if (ref($_[0]) eq "ARRAY"){
      @O=@{$_[0]};
   }
   else{
      @O=@_;
   }
   
   my $staleRetry=1;

   my $eventNameInJobLog=(caller(1))[3];
   if ($ast ne ""){
      my $joblog=getModuleObject($self->Config,"base::joblog");
      $joblog->SetFilter({name=>[$eventNameInJobLog],
                          exitcode=>'!0',
                          cdate=>'>now-'.$ast});
      $joblog->SetCurrentOrder('cdate');
      my @jobList=$joblog->getHashList(qw(id exitcode cdate));
      if ($#jobList!=-1){
         $staleRetry=$#jobList+1;
         foreach my $jrec (@jobList){                 # moeglicherweise sollten
            $staleRetry-- if ($jrec->{exitcode}!=0);  # hier nur negative exits
         }                                            # als stale indicator sein
         $staleRetry=1 if (!$staleRetry); # only if all are not 0 - 
      }                                   # stale is given
   }
   $$pStaleRetry=$staleRetry;
   msg(INFO,"stale $eventNameInJobLog = $staleRetry");

   #######################################################################
   # Optimal Init-Structure for Events with instable Backends (REST f.e.)
   #
   foreach my $objname (@O){
      msg(INFO,"load object $objname");
      my $o=getModuleObject($self->Config,$objname);
      if ($o->isSuspended()){ 
         return({exitcode=>0,exitmsg=>'ok - dataobj is suspended'});
      }
      if (!$o->Ping()){
         my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
         if ($staleRetry){
            if ($infoObj->NotifyInterfaceContacts($o)){
               return({exitcode=>0,
                       exitmsg=>"missing ".$objname." - ".
                                'NotifyInterfaceContacts notified'});
            }
            my @msg=$self->LastMsg();
            foreach my $msg (@msg){
               printf STDERR ("%s\n",$msg);
            }
         }
         return({
            exitcode=>1,
            exitmsg=>'missing necessary dataobj '.$objname.
                     ' NotifyInterfaceContacts not posible'
         });
      }
      $O->{$objname}=$o;
   }
   #######################################################################
   return();
}






1;

