package tsacinv::event::ImportAssetCenterCO;
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

   $self->RegisterEvent("ImportAssetCenterCO","ImportAssetCenterCO");
   return(1);
}

sub ImportAssetCenterCO
{
   my $self=shift;

   my $co=getModuleObject($self->Config,"tsacinv::costcenter");
   my $w5co=getModuleObject($self->Config,"itil::costcenter");

   $self->{acsys}=getModuleObject($self->Config,"tsacinv::system");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   $self->{user}=getModuleObject($self->Config,"base::user");
   $self->{mandator}=getModuleObject($self->Config,"base::mandator");

   $co->SetFilter({bc=>\'AL T-COM'});
   my @l=$co->getHashList(qw(name bc description));
   foreach my $rec (@l){
     msg(INFO,"co=$rec->{name}");
     next if (!($rec->{name}=~m/^\d{5,20}$/));
     $w5co->ResetFilter();
     $w5co->SetFilter({name=>\$rec->{name}});
     my ($w5rec,$msg)=$w5co->getOnlyFirst(qw(name));
     my $newrec={cistatusid=>4,
                 fullname=>$rec->{description},
                 comments=>"authority at AssetCenter",
                 srcload=>NowStamp(),
                 name=>$rec->{name}};
     if (!defined($w5rec)){
        $w5co->ValidatedInsertRecord($newrec);
     }
     else{
        $w5co->ValidatedUpdateRecord($w5rec,$newrec,{name=>\$rec->{name}});
     }
     $self->VerifyAssetCenterData($rec->{name},$rec->{bc}); 
   }
   return({exitcode=>0}); 
}


sub VerifyAssetCenterData
{
   my $self=shift;
   my $conumber=shift;
   my $altbc=shift;

   if ($altbc eq "AL T-COM"){
      my $acsys=$self->{acsys};
      $acsys->ResetFilter();
      $acsys->SetFilter({conumber=>\$conumber});
      my @syslist=$acsys->getHashList(qw(systemid applications));
      if ($#syslist!=-1){
         foreach my $sysrec (@syslist){
            if (!defined($sysrec->{applications}) ||
                ref($sysrec->{applications}) ne "ARRAY" ||
                $#{$sysrec->{applications}}==-1){
               if (!defined($self->{configmgr}->{$altbc})){
                  $self->{user}->SetFilter({posix=>\'hmerx'});
                  my ($urec,$msg)=$self->{user}->getOnlyFirst(qw(userid));
                  $self->{configmgr}->{$altbc}=$urec->{userid};
               }
               #############################################################
               # Issue Create
               #
               my $wf=$self->{wf};
               my $issue={name=>"DataIssue: AssetCenter: no applications ".
                                "on systemid '$sysrec->{systemid}'",
                          class=>'base::workflow::DataIssue',
                          step=>'base::workflow::DataIssue::dataload',
                          eventstart=>NowStamp("en"),
                          srcload=>NowStamp("en"),
                          directlnktype=>'tsacinv::event::ImportAssetCenterCO',
                          directlnkid=>'0',
                          mandatorid=>['200'],
                          mandator=>['AL T-Com'],
                          directlnkmode=>$sysrec->{systemid},
                          detaildescription=>'This is the description'};
               if (defined($self->{configmgr}->{$altbc})){
                  $issue->{openusername}="Config Manager";
                  $issue->{openuser}=$self->{configmgr}->{$altbc};
                  $issue->{fwdtargetid}=$self->{configmgr}->{$altbc};
                  $issue->{fwdtarget}="base::user";
               }
               $wf->ResetFilter();
               $wf->SetFilter({stateid=>"<20",class=>\$issue->{class},
                               directlnktype=>\$issue->{directlnktype},
                               directlnkid=>\$issue->{directlnkid},
                               directlnkmode=>\$issue->{directlnkmode}});
               my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
               $W5V2::OperationContext="QualityCheck";
               if (!defined($WfRec)){
                  my $bk=$wf->Store(undef,$issue);
               }
               else{
                  map({delete($issue->{$_})} qw(eventstart class step));
                  my $bk=$wf->Store($WfRec,$issue);
               }
               #############################################################
exit(1);
            }
         }
      }
   }
}



1;
