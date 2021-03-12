package tsacinv::event::AMsapInstanceImport;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{srcsys}="SAPIIMP";

   

   return($self);
}

sub AMsapInstanceImport
{
   my $self=shift;
   my $app=$self->getParent;

   my $lnkappl=getModuleObject($self->Config,"tsacinv::lnkapplappl");


   $lnkappl->SetFilter({type=>\'SAP',deleted=>'0'});
   $lnkappl->SetCurrentView(qw(ALL));


   my $pcnt=0;
   my $store={};
   my ($rec,$msg)=$lnkappl->getFirst();
   if (defined($rec)){
      do{
         last if (!defined($rec));
         $pcnt+=$self->ProcessRecord($rec,$store);
         ($rec,$msg)=$lnkappl->getNext();
      } until(!defined($rec));
   }
   $self->FineProcess($store);

   return({exicode=>0,exitmsg=>"pcnt=$pcnt"});
}


sub FineProcess
{
   my $self=shift;
   my $store=shift;
   my $app=$self->getParent;;

   #print STDERR Dumper($store);
   #
   my $swi=$app->getPersistentModuleObject("W5BaseInst","TS::swinstance");


   my %prodcomp=();
   foreach my $k (sort(keys(%{$store->{child}}))){
      print Dumper($store->{child}->{$k});
      if ($store->{child}->{$k}->{prodcomp} ne ""){
         $prodcomp{$store->{child}->{$k}->{prodcomp}}++;
      }
   }
   msg(INFO,"prodcomp mapping check:");
   foreach my $prodcomp (sort(keys(%prodcomp))){
      printf STDERR ("'%s' = \n",$prodcomp);
   }
exit(1);
   foreach my $k (sort(keys(%{$store->{child}}))){
      my $rec=$store->{child}->{$k};
      my $refcnt=$rec->{cnt};
      my $name=$k;
      $name=~s/\s+/ /g;
      $name=~s/[^a-z0-9_]/_/ig;
      my @p=sort(keys(%{$rec->{parent}}));
      my $parent=$p[0];

      #if ($refcnt!=1){
      #   printf STDERR ("Instance: $k (fixed: $name)\n");
      #   printf STDERR ("ERROR: refcnt=$refcnt at @p\n");
      #}


      my $w5appid=$rec->{parent}->{$parent}->{w5baseid};

      if ($w5appid ne ""){
         my %soll;
         if ($#{$rec->{system}}==-1){
            $soll{$name}={
               name=>$name,
               addname=>"",
               runon=>'0',
               swtype=>'primary',
               applid=>$w5appid,
               srcsys=>$self->{srcsys},
               acinmassingmentgroup=>$rec->{iassignment},
               cistatusid=>"4"
            };
         }
         else{
            my $mode="primary";
            foreach my $sysrec (@{$rec->{system}}){
               $soll{$name."-".$sysrec->{name}}={
                  name=>$name,
                  addname=>$sysrec->{name},
                  runon=>'0',
                  swtype=>$mode,
                  system=>$sysrec->{name},
                  systemid=>$sysrec->{id},
                  applid=>$w5appid,
                  acinmassingmentgroup=>$rec->{iassignment},
                  srcsys=>$self->{srcsys},
                  cistatusid=>"4"
               };
               $mode="secondary" if ($mode eq "primary");
            }
         }

         $swi->ResetFilter();
         $swi->SetFilter({name=>\$name,cistatusid=>"<6"});
         my @cur=$swi->getHashList(qw(ALL));


         foreach my $oldrec (@cur){
            if ($oldrec->{srcsys} ne $self->{srcsys}){
               msg(ERROR,"name colisition for $oldrec->{fullname}");
            }
            else{
               if (exists($soll{$oldrec->{name}."-".$oldrec->{addname}})){
                  if ($swi->ValidatedUpdateRecord($oldrec,
                        $soll{$oldrec->{name}."-".$oldrec->{addname}},
                      {id=>\$oldrec->{id}})){
                     $soll{$oldrec->{name}."-".$oldrec->{addname}}=
                         $oldrec->{id};
                  }
               }
            }
         }
         foreach my $k (keys(%soll)){
            if (ref($soll{$k}) eq "HASH"){
               my $swiid=$swi->ValidatedInsertRecord($soll{$k});
               $soll{$k}=$swiid;
            }
         }
         msg(INFO,"software instance handled by w5baseid ".
                  join(",",values(%soll)));
      }
   }
}


sub ProcessRecord
{
   my $self=shift;
   my $rec=shift;
   my $store=shift;
   my $app=$self->getParent;;


   my $applid=$rec->{parent_applid};

   return(0) if ($applid eq "");

   my $w5appl=$app->getPersistentModuleObject("W5BaseAppl","itil::appl");
   my $w5sys=$app->getPersistentModuleObject("W5BaseSys","itil::system");

   $w5appl->SetFilter({applid=>\$applid});

   my ($w5applrec,$msg)=$w5appl->getOnlyFirst(qw(id applid));

   return(0) if (!defined($w5applrec));


   my $amappl=$app->getPersistentModuleObject("AMapp","tsacinv::appl");

   $amappl->SetFilter({
      applid=>\$rec->{child_applid},
      deleted=>0,
      status=>'!"out of operation"',
      assignmentgroup=>'TIT.TSI.INT.AO.CO05 '.
                       'TIT.TSI.INT.AO.CO06 '.
                       'TIT.TSI.INT.AO.CO07'
   });
   my ($amapplrec,$msg)=$amappl->getOnlyFirst(qw(ALL));

   return(0) if (!defined($amapplrec));  # Instance-Anwendung existiert nicht

   my %systemid;
   foreach my $sysrec (@{$amapplrec->{systems}}){
      $systemid{$sysrec->{systemid}}++;
   }
   $w5sys->SetFilter({systemid=>[keys(%systemid)],cistatusid=>"<5 AND >3"});

   my @system=$w5sys->getHashList(qw(name systemid id));

   my $syscnt=$#system+1;
   if ($#system>0){
      msg(ERROR,"logical system not unique for $rec->{child}");
   }

   my @sys;
   foreach my $sysrec (@system){
      push(@sys,{
         name=>$sysrec->{name},
         id=>$sysrec->{id},
      });
   }


  
   return(0) if (!defined($w5applrec));

   if (!exists($store->{child}->{$rec->{child}})){
      $store->{child}->{$rec->{child}}={
         name=>$rec->{child},
         syscnt=>$syscnt,
         system=>\@sys,
         parent=>{
         },
         iassignment=>$amapplrec->{iassignmentgroup},
         assignment=>$amapplrec->{assignmentgroup},
         prodcomp=>$amapplrec->{prodcomp}
      };
   }
   $store->{child}->{$rec->{child}}->{cnt}++;
   $store->{child}->{$rec->{child}}->{parent}->{$rec->{parent}}={
       applid=>$rec->{parent_applid},
       w5baseid=>$w5applrec->{id}
   };

   #printf STDERR Dumper($store->{child}->{$rec->{child}});


   return(1);
}





1;
