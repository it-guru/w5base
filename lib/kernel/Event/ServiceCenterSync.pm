package kernel::Event::ServiceCenterSync;
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
use kernel;
use Data::Dumper;

sub ServiceCenterLogin
{
   my $self=shift;
   my $dbname=shift;

   {  # loading config informations for dbname
      my %p;
      $p{serv}=$self->Config->Param('DATAOBJSERV');
      $p{user}=$self->Config->Param('DATAOBJUSER');
      $p{pass}=$self->Config->Param('DATAOBJPASS');
      $p{base}=$self->Config->Param('DATAOBJBASE');
      $self->{_SC}->{$dbname}={};
     
      foreach my $v (qw(serv user pass base)){
         if ((ref($p{$v}) ne "HASH" || !defined($p{$v}->{$dbname})) &&
             $v ne "base"){
            return(sprintf("Connect(%s): no essential information '%s'",
                           $dbname,$v));
         }
         if (defined($p{$v}->{$dbname}) && $p{$v}->{$dbname} ne ""){
            $self->{_SC}->{$dbname}->{$v}=$p{$v}->{$dbname};
         }
      }
      if (!defined($self->{_SC}->{$dbname}->{base})){
         $self->{_SC}->{$dbname}->{base}="undefined";
      }
   }
   #
   # SC Connect/Logon
   #
   my $sc;
   eval('use SC::Customer::'.$self->{_SC}->{$dbname}->{base}.';'.
        '$sc=new SC::Customer::'.$self->{_SC}->{$dbname}->{base}.'();');
   if ($@ ne "" || !defined($sc)){
      my $msg=$@;
      return(sprintf("SC::Customer::%s is not correctly installed\n%s",
                     $self->{_SC}->{$dbname}->{base},$@));
   }
   
   msg(INFO,"SC($dbname) base =%s",$self->{_SC}->{$dbname}->{base});
   msg(INFO,"SC($dbname) serv =%s",$self->{_SC}->{$dbname}->{serv});
   msg(INFO,"SC($dbname) user =%s",$self->{_SC}->{$dbname}->{user});
   msg(INFO,"SC($dbname) pass =%s",$self->{_SC}->{$dbname}->{pass});
   if (!$sc->Connect($self->{_SC}->{$dbname}->{serv},
                     $self->{_SC}->{$dbname}->{user},
                     $self->{_SC}->{$dbname}->{pass})){
      return(sprintf("Connect to %s failed",$self->{_SC}->{$dbname}->{serv}));
   }
   msg(DEBUG,"Connect($dbname) OK");
   if (!$sc->Login()){
      return(sprintf("Login to %s failed",$self->{_SC}->{$dbname}->{serv}));
   }
   msg(DEBUG,"Login($dbname)   OK");
   $self->{_SC}->{$dbname}->{sc}=$sc;
   $sc->setDebugDirectory("/tmp");
   return(undef);
}

sub ServiceCenterLogout
{
   my $self=shift;
   my $dbname=shift;

   if (!defined($self->{_SC}->{$dbname}->{sc})){
      return("missing login to $dbname");
   }
   if (!$self->{_SC}->{$dbname}->{sc}->Logout()){
      return(sprintf("Logout from %s failed",$self->{_SC}->{$dbname}->{serv}));
   }
   delete($self->{_SC}->{$dbname}->{sc});
   msg(DEBUG,"Logout($dbname)  OK");
   return(undef);
}

sub CloseIncident
{
   my $self=shift;
   my $dbname=shift;
   my $wf=shift;
   my $wfact=shift;
   my $wfrec=shift;
   my $incident=shift;

   if (!defined($self->{_SC}->{$dbname}->{sc})){
      return("missing login to $dbname");
   }
   my %search=();
   if (!defined($wfrec->{srcid}) || $wfrec->{srcid} eq ""){
      if (defined($incident->{'referral.no'})){
         $incident->{'referral.no'}=uc($incident->{'referral.no'});
         $search{'referral.no'}=$incident->{'referral.no'};
      }
      if (keys(%search)==-1){
         return("missing key information");
      }
      $search{'search.open.flag'}="active";
   }
   else{
      $search{'search.open.flag'}="either";
      $search{'number'}=$wfrec->{srcid};
   }

   msg(DEBUG,Dumper(\%search));
   my $scResult=$self->{_SC}->{$dbname}->{sc}->IncidentSearch(%search);
printf STDERR ("fifi CloseIncident res=%s\n",Dumper($scResult));
   if (defined($scResult) && defined($scResult->{recordid})){
      if (!($self->{_SC}->{$dbname}->{sc}->IncidentClose())){
         return("Close failed: ".$self->{_SC}->{$dbname}->{sc}->LastMessage());
      }
      $search{'search.open.flag'}="closed";
      $search{'number'}=$wfrec->{srcid};
      my $r=$self->{_SC}->{$dbname}->{sc}->IncidentSearch(%search);
      if (defined($r) && defined($r->{recordid})){
         $self->SyncActions($self->{DBname},$wf,$wfact,$wfrec,$incident);
      }
   }
   return(undef);
}
sub RefreshIncident
{
   my $self=shift;
   my $dbname=shift;
   my $wf=shift;
   my $wfact=shift;
   my $wfrec=shift;
   my $incident=shift;

   if (!defined($self->{_SC}->{$dbname}->{sc})){
      return("missing login to $dbname");
   }
   my %search=();
   if (!defined($wfrec->{srcid}) || $wfrec->{srcid} eq ""){
      if (defined($incident->{'referral.no'})){
         $incident->{'referral.no'}=uc($incident->{'referral.no'});
         $search{'referral.no'}=$incident->{'referral.no'};
      }
      if (keys(%search)==-1){
         return("missing key information");
      }
      $search{'search.open.flag'}="active";
   }
   else{
      $search{'search.open.flag'}="either";
      $search{'number'}=$wfrec->{srcid};
   }
   delete($incident->{number});
   delete($incident->{LastMessage});
   msg(DEBUG,"SC search Incident");
   msg(DEBUG,Dumper(\%search));
   my $scResult=$self->{_SC}->{$dbname}->{sc}->IncidentSearch(%search);
printf STDERR ("fifi srcid=$wfrec->{'srcid'} scResult=%s\n",Dumper($scResult));
   if (!defined($scResult) && $wfrec->{'srcid'} ne ""){
      $search{'search.open.flag'}="closed";
      $search{'number'}=$wfrec->{'srcid'};
      delete($search{'referral.no'});
printf STDERR ("fifi search=%s\n",Dumper(\%search));
      $scResult=$self->{_SC}->{$dbname}->{sc}->IncidentSearch(%search);
   }
printf STDERR ("fifi res=%s\n",Dumper($scResult));
   if (defined($scResult) && defined($scResult->{recordid})){
      %{$incident}=%{$scResult};
      $incident->{number}=$scResult->{recordid};  #to have always number as ref
      #start refresh of w5base
   }
   else{
      #create incident in SC
      my $IncidentNumber;
      msg(DEBUG,"SC create Incident");
      msg(DEBUG,Dumper($incident));
      if ($wfrec->{srcid} eq ""){
         if (!defined($IncidentNumber=
                    $self->{_SC}->{$dbname}->{sc}->IncidentCreate($incident))){
            return("ServiceCenter: CreateIncident failed");
         }
         $incident->{number}=$IncidentNumber;
         $incident->{LastMessage}=$self->{_SC}->{$dbname}->{sc}->LastMessage();
      }
      else{
         $incident->{number}=$wfrec->{srcid};
      }
   }
   return(undef);
}

sub SCdate2w5base
{
   my $d=shift;

   msg(DEBUG,"date0=$d");
   if (defined($d) && $d ne ""){
      $d=~s/\//./g;
   }
   msg(DEBUG,"date1=$d");
   return($d);
}


sub SyncActions
{
   my $self=shift;
   my $dbname=shift;
   my $wf=shift;
   my $wfact=shift;
   my $wfrec=shift;
   my $incident=shift;
   my $app=$self->getParent();

   msg(DEBUG,"I:%s",Dumper($incident));

   my $changed=0;
   if (defined($incident->{activity}) &&
       ref($incident->{activity}) eq "ARRAY"){
      msg(DEBUG,"start sync");
      my $pointer=$wfrec->{headref}->{ScActionPointer}->[0];
      my $stateid=$wfrec->{stateid};
      $pointer=0 if (!defined($pointer));
      my @act=reverse(@{$incident->{activity}});
      foreach my $act (@act){       # add actions
      #   next        if ($act->{type} eq "Open");
         msg(DEBUG,"a=".Dumper($act));
         $stateid=16 if ($act->{type}=~m/resolved/i);
         $stateid=4  if ($act->{type}=~m/reopen/i);
         $stateid=4  if ($act->{type}=~m/update/i);
         $stateid=21 if ($act->{type}=~m/closed/i);
         if ($pointer<$act->{thenumber}){
            $pointer=$act->{thenumber};
            my $mdate=SCdate2w5base($act->{sysmodtime});
            $mdate=$app->ExpandTimeExpression($mdate,"en","CET");
   msg(DEBUG,"date2=$mdate");
            if (ref($act->{description}) eq "ARRAY"){
               $act->{description}=join("\n",@{$act->{description}});
            }
            $wfact->ValidatedInsertRecord({
                               wfheadid=>$wfrec->{id},
                               name=>'note',
                               mdate=>$mdate,
                               comments=>"$act->{sysmoduser}: $act->{type}\n".
                                         $act->{description}});
            $changed++;
         }
      }
      if ($pointer ne $wfrec->{headref}->{ScActionPointer}->[0] ||
          $stateid ne $wfrec->{headref}->{stateid}){ # update headref
         my %headref=%{$wfrec->{headref}};
         $headref{ScActionPointer}=[$pointer]; 
         $wfrec->{headref}=\%headref;
         if ($wfrec->{stateid} ne $stateid){
            $changed++;
            $wfrec->{stateid}=$stateid;
         }
      }
   }
   if ($changed){
      $wfrec->{srcload}=$app->ExpandTimeExpression("now","en","GMT");;
   }
   msg(DEBUG,"headref=%s",Dumper($wfrec->{headref}));
   $wf->ValidatedUpdateRecord($wfrec,
                       {srcid=>$incident->{number},
                        srcload=>$incident->{srcload},
                        headref=>$wfrec->{headref},
                        stateid=>$wfrec->{stateid},
                        srcsys=>$self->{SCTagPrefix}},
                       {id=>\$wfrec->{id}});
}




1;
