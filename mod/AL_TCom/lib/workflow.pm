package AL_TCom::lib::workflow;
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



sub isPostReflector
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   
   if (defined($rec) && 
       ref($rec->{affectedapplicationid}) eq "ARRAY" &&
       $#{$rec->{affectedapplicationid}}!=-1 &&
       $self->getParent->IsMemberOf("admin","w5base.cod")){
      return(1);
   }
   else{
      my %user=();
      my $userid=$self->getParent->getCurrentUserId();
      CHK: {
         my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                       [qw(REmployee RApprentice RFreelancer RBoss)],
                                 "both");
         my @grpids=keys(%grp);

         if (ref($rec->{affectedapplicationid}) eq "ARRAY" &&
             $#{$rec->{affectedapplicationid}}!=-1){

            my @applid=@{$rec->{affectedapplicationid}};
            my $appl=getModuleObject($self->Config,"itil::appl");
            $appl->SetFilter(id=>\@applid);
            my @fl=qw(semid sem2id tsmid tsm2id opmid opm2id);
            my @tl=qw(businessteamid);
            my @l=$appl->getHashList(@fl,@tl);
            foreach my $rec (@l){
               foreach my $f (@fl){
                  if ($rec->{$f}==$userid){
                     return(1);
                     last CHK;
                  }
               }
               if (defined($rec->{businessteamid})){
                  if (grep(/^$rec->{businessteamid}$/,@grpids)){
                     return(1);
                     last CHK;
                  }
               }
            }
         }
         if (ref($rec->{affectedcontractid}) eq "ARRAY" &&
             $#{$rec->{affectedcontractid}}!=-1){
            my @contid=@{$rec->{affectedcontractid}};
            my $cont=getModuleObject($self->Config,"itil::custcontract");
            $cont->SetFilter(id=>\@contid);
            my @fl=qw(semid sem2id);
            my @l=$cont->getHashList(@fl);
            foreach my $rec (@l){
               foreach my $f (@fl){
                  if ($rec->{$f}==$userid){
                     return(1);
                     last CHK;
                  }
               }
            }
         }
      }
   }
   return(0);
}


sub tcomcodcause
{
#
#   Veraltet ab 30.11.2008 laut ServiceManagement
#
#   return(qw(undef
#             devsupport
#             pilot
#             firstconfig
#             testinstallation
#             documentation
#             rollout
#             install
#             installfix
#             installminor
#             installmajor
#             fallback
#             desrecoverytest
#             uninstall
#             bcardcare
#             ETAplan 
#             ETArelization 
#             ETAbusiness 
#             ETApromblemanalyse 
#             ETAtestSIT1 
#             ETAtestSIT2
#             ETAtestSIT3
#             ETAtestSIT4 
#             SOXreq
#             TECreq
#             misc));
#
   return(qw(
   undef
   appl.add.impl
   appl.add.baseext
   appl.add.devsup
   appl.add.pilot
   appl.add.inst
   appl.add.fcfg
   appl.add.test
   appl.add.doc
   appl.add.rollout
   appl.add.fixes
   appl.add.minor
   appl.add.major
   appl.add.fallback
   appl.add.rectest
   appl.add.uninst
   appl.base.base
   db.addeff.baseext
   db.addfix.swinst
   db.addfix.firstcfg
   db.addfix.fcfgcompl
   db.addfix.initdoc
   db.addfix.ftest
   db.addfix.upd
   db.addfix.dbserv
   db.addeff.haserv
   db.addeff.3th
   db.addeff.licinv
   db.addeff.rtest
   db.addeff.licprov
   db.addeff.maint
   db.base.base
   eta.baseeff.ETAbusiness
   eta.baseeff.ETAplan
   eta.baseeff.ETApromblemanalyse
   eta.baseeff.ETArelization
   eta.baseeff.ETAtestSIT1
   eta.baseeff.ETAtestSIT2
   eta.baseeff.ETAtestSIT3
   eta.baseeff.ETAtestSIT4
   eta.addeff.etaproject
   eta.addeff.etabusiness
   eta.baseeff.etabusinear
   eta.baseeff.etabusioffs
   eta.baseeff.etabusioffon
   eta.addeff.etabusisencons
   eta.baseeff.BPQworkingcycle
   eta.baseeff.BPQinstall
   eta.baseeff.BPQerrorh
   eta.baseeff.BPQadmin
   eta.baseeff.BPQcoordination
   eta.baseeff.BPQsyscheck

   ));
}


sub tcomworktimeadd
{
   my $self=shift;
   my $current=shift;
   my $min=$current->{tcomworktime};
   if ($min>60){
      my $s=sprintf("%.2lf",$min/60);
      return(" ( =${s} h)");
   }
   return(undef);
}

sub minUnformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;

   return({}) if ($self->readonly);
   if (defined($formated)){
      my $d=$formated;
      $d=$d->[0] if (ref($d) eq "ARRAY");
      my $used=$d;
      $used=~s/,/./g;
      if (my ($h)=$used=~m/^\s*([\d\.]+)\s*h\s*$/){
         $d=$h*60;
      }
      $formated=[$d];
   }
   return($self->kernel::Field::Number::Unformat($formated,$rec));
}










1;
