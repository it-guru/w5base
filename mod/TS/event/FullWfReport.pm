package TS::event::FullWfReport;
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
use kernel;
use kernel::Event;
use kernel::XLSReport;

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub FullWfReport
{
   my $self=shift;
   my %param=@_;
   my %flt;
   msg(DEBUG,"param=%s",Dumper(\%param));
#   if ($param{name} ne ""){
#      my $c=$param{name};
#      $flt{name}="$param{name}";
#   }
#   else{
#      msg(DEBUG,"no name restriction");
#   }
   if ($param{year} eq ""){
      my ($year,$month)=$self->Today_and_Now("GMT");
      $param{year}=$year;
   }
   if ($param{filename} eq ""){
      $param{filename}="/tmp/FullWorkflowReport$param{year}.xls";
   }
   msg(INFO,"loading appl cache ...");
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetCurrentView(qw(id businessteamid));

   $self->{appl}=$appl->getHashIndexed(qw(id businessteamid));
   msg(INFO,"... appl cache done");

   msg(INFO,"loading grp cache ...");
   my $grp=getModuleObject($self->Config,"base::grp");
   $grp->SetCurrentView(qw(grpid fullname));

   $self->{grp}=$grp->getHashIndexed(qw(grpid fullname));
   msg(INFO,"... grp cache done");

   msg(INFO,"start Report to $param{'filename'}");
   my $t0=time();
 

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'bteam',
                label         =>'aktuelles Betriebsteam',
                htmldetail    =>0)
   );

   my @control=();

   for(my $m=1;$m<=12;$m++){
      my $month=sprintf("%02d",$m);
      push(@control,{
         DataObj=>$wf,
         sheet=>'Incident ('.$month.'/'.$param{year}.')',
         filter=>{eventend=>'('.$month.'/'.$param{year}.')',
                  isdeleted=>\'0',
                  #name=>'Reboot*',
                  class=>['AL_TCom::workflow::incident']
         },
         lang=>'de',
         recPreProcess=>\&recPreProcess,
         order=>'NONE',
         view=>[qw(srcid affectedapplication bteam 
                   name srcid eventstart eventend
                   additional.ServiceCenterPriority 
                   additional.ServiceCenterHomeAssignment
                   additional.ServiceCenterInvolvedAssignment
                   affectedapplicationid)]},
      );
      push(@control,{
         DataObj=>$wf,
         sheet=>'Problem ('.$month.'/'.$param{year}.')',
         filter=>{eventend=>'('.$month.'/'.$param{year}.')',
                  isdeleted=>\'0',
                  #name=>'SIUX*',
                  class=>['AL_TCom::workflow::problem']
         },
         lang=>'de',
         recPreProcess=>\&recPreProcess,
         order=>'NONE',
         view=>[qw(srcid affectedapplication bteam
                   name srcid eventstart eventend
                   additional.ServiceCenterPriority 
                   additional.ServiceCenterHomeAssignment
                   additional.ServiceCenterReason
                   additional.ServiceCenterAssignedTo
                   additional.ServiceCenterTriggeredBy
                   affectedapplicationid)]},
      );
   }

   $out->Process(@control);
   my $trep=time()-$t0;
   msg(INFO,"end Report to $param{'filename'} ($trep sec)");

   return({exitcode=>0,msg=>'OK'});
}


sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;
   my $applid=$rec->{affectedapplicationid};
   $applid=[$applid] if (ref($applid) ne "ARRAY");

   ########################################################################
   # modify record view
   my @newrecview;
   foreach my $fld (@$recordview){
      my $name=$fld->Name;
      next if ($name eq "affectedapplicationid");
      push(@newrecview,$fld);
   }
   @{$recordview}=@newrecview;


   printf("process %s (%s)\n",$rec->{srcid},$rec->{eventend});

   my %teams;
   foreach my $applid (@{$applid}){
      my ($teamid);
      if (!exists($self->{appl}->{id}->{$applid})){
         $teams{'MissingCurrentApplicationData'}++;
      }
      elsif (!defined($self->{appl}->{id}->{$applid}->{businessteamid}) ||
             $self->{appl}->{id}->{$applid}->{businessteamid} eq ""){
         $teams{'MissingApplicationBusinessTeam'}++;
      }
      else{
         $teamid=$self->{appl}->{id}->{$applid}->{businessteamid};
      }
      if (defined($teamid)){
         if (!exists($self->{grp}->{grpid}->{$teamid})){
            $teams{'MissingBusinessTeamGroupInformation'}++;
         }
         else{
            $teams{$self->{grp}->{grpid}->{$teamid}->{fullname}}++; 
         }
      }
   }
   $rec->{bteam}=join(", ",sort(keys(%teams)));

   return(1);

}





1;
