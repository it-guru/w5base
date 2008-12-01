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
use Data::Dumper;
use kernel;



sub isPostReflector
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   
   if (defined($rec) && 
       ref($rec->{affectedcontractid}) eq "ARRAY" &&
       $#{$rec->{affectedcontractid}}!=-1){
      my @p800ids;
      if (my ($y,$m)=$rec->{eventend}=~m/^(\d{4})-(\d{2})-.*$/){
         foreach my $contractid (@{$rec->{affectedcontractid}}){
            push(@p800ids,"$m/$y-$contractid");
         }
         if ($#p800ids!=-1){
            my $wf=$self->getPersistentModuleObject("p800repcheck",
                                                    "base::workflow");
            $wf->SetFilter({srcid=>\@p800ids,
                            stateid=>\'8',
                            srcsys=>\"AL_TCom::event::mkp800"});
            my @l=$wf->getHashList(qw(id));
            return() if ($#l!=-1);
         }
      }
   }

   if (defined($rec) && 
       ref($rec->{affectedapplicationid}) eq "ARRAY" &&
       $#{$rec->{affectedapplicationid}}!=-1 &&
       $self->getParent->IsMemberOf("admin","admin.cod")){
      return(1);
   }
   else{
      my %user=();
      my $userid=$self->getParent->getCurrentUserId();
      CHK: {
         my %grp=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                               ["REmployee","RChief"],
                                               "both");
         my @grpids=keys(%grp);

         if (ref($rec->{affectedapplicationid}) eq "ARRAY" &&
             $#{$rec->{affectedapplicationid}}!=-1){

            my @applid=@{$rec->{affectedapplicationid}};
            my $appl=getModuleObject($self->Config,"itil::appl");
            $appl->SetFilter(id=>\@applid);
            my @fl=qw(semid sem2id tsmid tsm2id);
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
   appl.base.mon
   appl.base.rep
   appl.base.tuning
   appl.base.opchange
   appl.base.doc
   appl.base.control
   appl.base.usermgmt
   appl.base.confmgmt
   appl.base.relmgmt
   appl.base.capmgmt
   appl.base.secmgmt
   appl.base.inm
   appl.base.prm
   appl.base.conmgmt
   appl.base.recov
   appl.base.waround
   appl.base.arundown
   appl.base.sdesign
   appl.base.slamgmt
   appl.base.escmgmt
   appl.base.slumpm
   appl.baseext.mon
   appl.baseext.rep
   appl.baseext.tuning
   appl.baseext.change
   appl.baseext.doc
   appl.baseext.control
   appl.baseext.usrmgmt
   appl.baseext.cfm
   appl.baseext.relmgmt
   appl.baseext.capmgmt
   appl.baseext.secmgmt
   appl.baseext.inm
   appl.baseext.prm
   appl.baseext.conmgmt
   appl.baseext.recov
   appl.baseext.waround
   appl.baseext.arundown
   appl.baseext.sdesign
   appl.baseext.slamgmt
   appl.baseext.escmgmt
   appl.baseext.slumpm
   appl.addfix.devsup
   appl.addfix.pilot
   appl.addfix.inst
   appl.addfix.firstcfg
   appl.addfix.testinst
   appl.addfix.doc
   appl.addfix.rollout
   appl.addfix.fixes
   appl.addfix.minorrel
   appl.addfix.majorrel
   appl.addfix.fallback
   appl.addfix.desrec
   appl.addfix.applunin
   appl.add.devsup
   appl.add.pilot
   appl.add.inst
   appl.add.firstcfg
   appl.add.testinst
   appl.add.doc
   appl.add.rollout
   appl.add.fixes
   appl.add.minorrel
   appl.add.majorrel
   appl.add.fallback
   appl.add.desrec
   appl.add.applunin
   db.base.swmon
   db.base.swinvent
   db.base.swrep
   db.base.swinstall
   db.base.swdeinst
   db.base.swrundown
   db.base.dbservice
   db.base.cfm
   db.base.recov
   db.base.doc
   db.base.secmgmt
   db.base.support
   db.base.waround
   db.baseext.swmon
   db.baseext.swinvent
   db.baseext.swrep
   db.baseext.swinstall
   db.baseext.swdeinst
   db.baseext.swrundown
   db.baseext.dbservice
   db.baseext.cfm
   db.baseext.recov
   db.baseext.doc
   db.baseext.secmgmt
   db.baseext.support
   db.baseext.waround
   db.addfix.inst
   db.addfix.firstcfg
   db.addfix.fstcfgrac
   db.addfix.docbhb
   db.addfix.ftest
   db.addfix.swupd
   db.addfix.dbsnonbhb
   db.addfix.hastandby
   db.addfix.licinvent
   db.addfix.desrec
   db.addfix.licdeliv
   db.addfix.swmaint
   db.add.hastandby
   db.add.3thwarent
   db.add.licinvent
   db.add.desrec
   db.add.licdeliv
   db.add.swmaint
   ETAbusiness
   ETAplan
   ETApromblemanalyse
   ETArelization
   ETAtestSIT1
   ETAtestSIT2
   ETAtestSIT3
   ETAtestSIT4
   ));
}










1;
