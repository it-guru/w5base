package TASTEOS::qrule::compareApplGrp;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares a W5Base ApplicationGroup to a TasteOS 
system (which is a application in W5Base spelling).

=head3 IMPORTS

- name of cluster

=head3 HINTS

Sync to TasteOS

[de:]

Syncronisation der Anwendungsgruppen in Darwin mit den "Systemen"
in TasteOS.

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::applgrp"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=shift;

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4);
   return(undef)   if ($rec->{applgrpid} eq "");

   my $lobj=getModuleObject($dataobj->Config,"itil::lnkapplsystem");

   $lobj->SetFilter({
      applgrpid=>\$rec->{id},
      systemcistatusid=>[4],
      applcistatusid=>[4]
   });

   my @l=$lobj->getHashList(qw(systemid applgrpid id));
   my %ul;
   foreach my $lrec (@l){
      $ul{$lrec->{applgrpid}."-".$lrec->{systemid}}=$lrec;
   }
printf STDERR ("fifi ul=%s\n",Dumper(\%ul));
   @l=values(%ul);



   my @systemid;
   map({push(@systemid,$_->{systemid});} @l);

   #printf STDERR ("l=%s\n",Dumper(\@l));
   #printf STDERR ("n=%d\n",$#l+1);
   #printf STDERR ("systemid=%s\n",join(",",@systemid));

   my $laddobj=getModuleObject($dataobj->Config,"itil::addlnkapplgrpsystem");
   $laddobj->SetFilter({
      applgrpid=>\$rec->{id},
      systemid=>\@systemid
   });
   my $opladdobj=$laddobj->Clone();
   $laddobj->SetCurrentView(qw(systemid applgrpid additional id));
   my $ladd=$laddobj->getHashIndexed(qw(systemid));
   printf STDERR ("addl=%s\n",Dumper($ladd));


   my $tsossys=getModuleObject($dataobj->Config,"TASTEOS::tsossystem");
   my $tsosmac=getModuleObject($dataobj->Config,"TASTEOS::tsosmachine");


   $tsossys->ResetFilter();
   $tsossys->SetFilter({ictoNumber=>$rec->{applgrpid}});
   $tsossys->SetCurrentView(qw(id ictoNumber machines));
   my $curSys=$tsossys->getHashIndexed(qw(ictoNumber));
#printf STDERR ("curSys getHashIndexed=%s\n",Dumper($curSys));

   #printf STDERR ("curSys=%s\n",Dumper($curSys));



   my $TSOSsystemid=$rec->{additional}->{TasteOS_SystemID}->[0];


   $tsossys->ResetFilter();
   $tsossys->SetFilter({id=>$TSOSsystemid});  # check if systemid still exists
   my ($srec,$msg)=$tsossys->getOnlyFirst(qw(id name));
   if (!defined($srec)){
      $TSOSsystemid=undef;
   }

   my @delList;
   my @idl;
   if (ref($curSys->{ictoNumber}->{$rec->{applgrpid}}) eq "ARRAY"){
      @idl=map({$_->{id}} @{$curSys->{ictoNumber}->{$rec->{applgrpid}}});
   }
   else{
      if (ref($curSys->{ictoNumber}) eq "HASH"){
         @idl=$curSys->{ictoNumber}->{$rec->{applgrpid}}->{id};
      }
   }
printf STDERR ("fifi idl=%s\n",Dumper(\@idl));
   if ($#idl!=-1){
      if ($TSOSsystemid ne "" &&
          in_array(\@idl,$TSOSsystemid)){  # cleanup andere ICTOs
         push(@delList,grep(!/^$TSOSsystemid$/,@idl));
      }
      else{
         @delList=@idl;
         $TSOSsystemid=undef;
      }
   }
printf STDERR ("fifi delList=%s\n",Dumper(\@delList));
   foreach my $id (@delList){  # cleanup old system records (not stored local)
      if ($id ne ""){
         $tsossys->ValidatedDeleteRecord({id=>$id});
      }
   }
printf STDERR ("fifi delEnd\n");



   my $tsossysrec={
      name=>$rec->{fullname},
      ictoNumber=>$rec->{applgrpid},
      description=>NowStamp("en")
   };

   sub insNewTSOSsys
   {
      my $nrec=shift;

      my $newid=$tsossys->ValidatedInsertRecord($nrec);
      if ($newid ne ""){
         $TSOSsystemid=$newid;
         my %add=%{$rec->{additional}};
         $add{TasteOS_SystemID}=$newid;
         $dataobj->ValidatedUpdateRecord(
            $rec,{additional=>\%add},
            {id=>$rec->{id}}
         );
      }
      return($newid);
   }

   if ($TSOSsystemid eq ""){
      $TSOSsystemid=insNewTSOSsys($tsossysrec);
   }
   else{
      my $bk=$tsossys->ValidatedUpdateRecord(
         {},$tsossysrec,
         {id=>$TSOSsystemid
      });
   }
   #printf STDERR ("fifi upd TSOSsystemid=$TSOSsystemid\n");
   sub insNewTSOSmac
   {
      my $nrec=shift;
      my $lrec=shift;
      my $ladd=shift;

      my $newid=$tsosmac->ValidatedInsertRecord($nrec);
      if ($newid ne ""){
         if (!exists($ladd->{$lrec->{systemid}})){
            my %add=(TasteOS_MachineID=>$newid);
            #printf STDERR ("fifi insNewTSOSmac $newid\n");
            
            $opladdobj->ValidatedInsertRecord({
               systemid=>$lrec->{systemid},
               applgrpid=>$lrec->{applgrpid},
               additional=>\%add
            });
         }
         else{
            #printf STDERR ("fifi insNewTSOSmac update $newid in id=".$ladd->{$lrec->{systemid}}->{id}."\n");
            my %add=%{$ladd->{$lrec->{systemid}}->{additional}};
            $add{TasteOS_MachineID}=$newid;
            $opladdobj->ValidatedUpdateRecord(
               $ladd->{$lrec->{systemid}},
               {additional=>\%add},
               {id=>$ladd->{$lrec->{systemid}}->{id}}
            );
         }
      }
      return($newid);
   }



   if ($TSOSsystemid ne ""){
      foreach my $lrec (@l){
         my $TSOSmachineid;
         if (exists($ladd->{systemid}->{$lrec->{systemid}})){
            $TSOSmachineid=$ladd->{systemid}->{$lrec->{systemid}}->{additional}->{TasteOS_MachineID}->[0];
         }
         #printf STDERR ("fifi TSOSmachineid for $lrec->{systemid} : $TSOSmachineid\n");
         my $tsosmacrec={
            name=>$lrec->{system},
            systemid=>$TSOSsystemid
         };

         $tsosmac->ResetFilter();
         $tsosmac->SetFilter({id=>$TSOSmachineid});
         my ($mrec,$msg)=$tsosmac->getOnlyFirst(qw(id name systemid));
         if (!defined($mrec)){
            $TSOSmachineid=undef;
         }
         if ($TSOSmachineid eq ""){
            my $newid=insNewTSOSmac($tsosmacrec,$lrec,$ladd->{systemid});
         }
         else{
            my $bk=$tsosmac->ValidatedUpdateRecord(
               {},$tsosmacrec,
               {id=>$TSOSmachineid
            });
         }

      }
   }


   $tsossys->ResetFilter();
   $tsossys->SetFilter({name=>\"Default System",ictoNumber=>\""});
   my ($defrec,$msg)=$tsossys->getOnlyFirst(qw(id name machines));
   if (defined($defrec)){
      if (ref($defrec->{machines}) eq "ARRAY"){
         foreach my $mrec (@{$defrec->{machines}}){
            $tsosmac->ResetFilter();
            $tsosmac->ValidatedDeleteRecord({id=>$mrec->{id}});
         }
      }
   }





   my @result=$self->HandleQRuleResults("TasteOS",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
