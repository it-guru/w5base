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

   sub insNewTSOSmac
   {
      my $dataobj=shift;
      my $tsosmac=shift;
      my $opladdobj=shift;
      my $rec=shift;
      my $nrec=shift;
      my $lrec=shift;
      my $ladd=shift;

      my $newid=$tsosmac->ValidatedInsertRecord($nrec);
      if ($newid ne ""){
         if (!exists($ladd->{$lrec->{systemid}})){
            my %add=(TasteOS_MachineID=>$newid);
            #printf STDERR ("fifi insNewTSOSmac $newid\n");
            
#printf STDERR ("fifi insert new MachineID=$newid\n");
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
#printf STDERR ("fifi update new MachineID=$newid\n");
            $opladdobj->ValidatedUpdateRecord(
               $ladd->{$lrec->{systemid}},
               {additional=>\%add},
               {id=>$ladd->{$lrec->{systemid}}->{id}}
            );
         }
      }
      return($newid);
   }

   sub insNewTSOSsys
   {
      my $dataobj=shift;
      my $tsossys=shift;
      my $rec=shift;
      my $nrec=shift;

      my $newid=$tsossys->ValidatedInsertRecord($nrec);
#      printf STDERR ("create new SystemID=$newid\n");
      if ($newid ne ""){
         my %add=%{$rec->{additional}};
         $add{TasteOS_SystemID}=$newid;
         my $bk=$dataobj->ValidatedUpdateRecord(
            $rec,{additional=>\%add},
            {id=>$rec->{id}}
         );
         #printf STDERR ("update system $rec->{id} bk=$bk\n");
      }
      return($newid);
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
   my %contact;

   return(0,undef) if ($rec->{cistatusid}!=4);
   return(undef)   if ($rec->{applgrpid} eq "");

   my $appl=getModuleObject($dataobj->Config,"itil::appl");
   $appl->SetFilter({
      applgrpid=>\$rec->{id},
      cistatusid=>[4]
   });
   my @a=$appl->getHashList(qw(tsmid tsm2id applmgrid contacts));
   foreach my $arec (@a){
      foreach my $fld (qw(tsmid tsm2id applmgrid)){
         if ($arec->{$fld} ne ""){
            $contact{$arec->{$fld}}={};
         }
      }
      foreach my $crec (@{$arec->{contacts}}){
         my $roles=$crec->{roles};
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         if ($crec->{target} eq "base::user" &&
             in_array($roles,"applmgr2")){
            $contact{$crec->{targetid}}={};
         }
      }
   }
   if (keys(%contact)){
      my $user=getModuleObject($dataobj->Config,"base::user");
      $user->SetFilter({cistatusid=>[4],userid=>[keys(%contact)]});
      foreach my $urec ($user->getHashList(qw(email userid))){
         $contact{$urec->{userid}}=$urec;
      }
   }


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
#printf STDERR ("fifi ul=%s\n",Dumper(\%ul));
   @l=values(%ul);



   my @systemid;
   map({push(@systemid,$_->{systemid});} @l);

   #printf STDERR ("l=%s\n",Dumper(\@l));
   #printf STDERR ("n=%d\n",$#l+1);
   #printf STDERR ("systemid=%s\n",join(",",@systemid));

   my $laddobj=getModuleObject($dataobj->Config,"itil::addlnkapplgrpsystem");
   $laddobj->SetFilter({ applgrpid=>\$rec->{id} });
     # systemid=>\@systemid
   my $opladdobj=$laddobj->Clone();
   $laddobj->SetCurrentView(qw(systemid system applgrpid applgrp 
                               additional id));
   my $ladd=$laddobj->getHashIndexed(qw(systemid));

   foreach my $systemid (keys(%{$ladd->{systemid}})){
       my $TSOSmachineid;
       if (in_array(\@systemid,$systemid)){
          if (exists($ladd->{systemid}->{$systemid})){
             $TSOSmachineid=$ladd->{systemid}->{$systemid}->{additional}->{TasteOS_MachineID}->[0];
          }
          if ($TSOSmachineid ne ""){
             $ladd->{TasteOS_MachineID}->{$TSOSmachineid}=
                $ladd->{systemid}->{$systemid};
          }
       }
       else{
          #printf STDERR ("needs to delete $systemid\n");
          my $oldrec=$ladd->{systemid}->{$systemid};
          if (exists($oldrec->{additional}->{TasteOS_MachineID})){
             my %add=%{$oldrec->{additional}};
             delete($add{TasteOS_MachineID});
             my $opladdobj=$laddobj->Clone();
             $opladdobj->ValidatedUpdateRecord(
                $oldrec,
                {additional=>\%add},
                {id=>\$oldrec->{id}}
             );
          }
          delete($ladd->{systemid}->{$systemid});
       }
   }




  # printf STDERR ("addl=%s\n",Dumper($ladd));

   my $tsossys=getModuleObject($dataobj->Config,"TASTEOS::tsossystem");
   my $tsossysacl=getModuleObject($dataobj->Config,"TASTEOS::tsossystemacl");
   my $tsosmac=getModuleObject($dataobj->Config,"TASTEOS::tsosmachine");
   #printf STDERR ("rec=%s\n",Dumper($rec));


   $tsossys->ResetFilter();
   $tsossys->SetFilter({ictoNumber=>$rec->{applgrpid}});
   $tsossys->SetCurrentView(qw(id ictoNumber machines));
   my $curSys=$tsossys->getHashIndexed(qw(ictoNumber));
#printf STDERR ("curSys getHashIndexed=%s\n",Dumper($curSys));


   my $dd=Dumper($rec->{additional});


   my $TSOSsystemid=$rec->{additional}->{TasteOS_SystemID}->[0];

   if ($TSOSsystemid ne ""){
      $tsossys->ResetFilter();
      $tsossys->SetFilter({id=>$TSOSsystemid}); # check if systemid still exists
      my ($srec,$msg)=$tsossys->getOnlyFirst(qw(id name));
      if (!defined($srec)){
         msg(WARN,"stored systemid $TSOSsystemid does not exists in TasteOS");
         $TSOSsystemid=undef;
      }
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
   foreach my $id (@delList){  # cleanup old system records (not stored local)
      if ($id ne ""){
         msg(WARN,"drop systemid $id in TasteOS");
         $tsossys->ValidatedDeleteRecord({id=>$id});
      }
   }



   my $tsossysrec={
      name=>$rec->{fullname},
      ictoNumber=>$rec->{applgrpid},
      description=>NowStamp("en")
   };

   if ($TSOSsystemid eq ""){
      $TSOSsystemid=insNewTSOSsys($dataobj,$tsossys,$rec,$tsossysrec);
   }
   else{
      my $bk=$tsossys->ValidatedUpdateRecord(
         {},$tsossysrec,
      {id=>$TSOSsystemid});
      $tsossys->ResetFilter();
      $tsossys->SetFilter({id=>$TSOSsystemid});
      my ($srec,$msg)=$tsossys->getOnlyFirst(qw(ALL));

      if (defined($srec)){
         my @delList;
         foreach my $mrec (@{$srec->{machines}}){
            if (!exists($ladd->{TasteOS_MachineID}->{$mrec->{id}})){
               push(@delList,$mrec->{id});
            }
         }
         #printf STDERR "delList=".Dumper(\@delList);
         foreach my $machineid (@delList){
            $tsosmac->ResetFilter();
            $tsosmac->ValidatedDeleteRecord({id=>$machineid});
         }
      }


   }
   #printf STDERR ("fifi upd TSOSsystemid=$TSOSsystemid\n");



   if ($TSOSsystemid ne "" &&
       in_array($rec->{applgrpid},["ICTO-20324"])){
      foreach my $lrec (@l){
         my $TSOSmachineid;
         if (exists($ladd->{systemid}->{$lrec->{systemid}})){
            $TSOSmachineid=$ladd->{systemid}->{$lrec->{systemid}}->{additional}->{TasteOS_MachineID}->[0];
         }
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
            my $newid=insNewTSOSmac($dataobj, $tsosmac,$opladdobj,
                                    $rec,$tsosmacrec,$lrec,$ladd->{systemid});
         }
         else{
            if ($mrec->{systemid} ne $tsosmacrec->{systemid} ||
                $mrec->{name}     ne $tsosmacrec->{name}){
               my $bk=$tsosmac->ValidatedUpdateRecord(
                  {},$tsosmacrec,
                  {id=>$TSOSmachineid
               });
            }
         }

      }











      my @email=sort(map({$_->{email}} values(%contact)));
      msg(INFO,sprintf("set acl of TasteOS system $TSOSsystemid to %s\n",
            join(",",@email)));
      if ($#email!=-1){
         foreach my $email (@email){
            if ($email ne ""){
               my $bk=$tsossysacl->ValidatedInsertRecord({
                  systemid=>$TSOSsystemid,
                  email=>$email,
                  readwrite=>1
               });
               msg(INFO,"insert of $email = $bk");
            }
         }
      }
   }


   $tsossys->ResetFilter();
   $tsossys->SetFilter({name=>'!"Default System"',ictoNumber=>\""});
   my @l=$tsossys->getHashList(qw(ALL));
   foreach my $delsys (@l){
       $tsossys->ResetFilter();
       $tsossys->ValidatedDeleteRecord({id=>$delsys->{id}});
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
