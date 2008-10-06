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

   $self->{loadstart}=NowStamp("en");
   $self->{acsys}=getModuleObject($self->Config,"tsacinv::system");
   $self->{w5sys}=getModuleObject($self->Config,"itil::system");
   $self->{wf}=getModuleObject($self->Config,"base::workflow");
   $self->{user}=getModuleObject($self->Config,"base::user");
   $self->{mandator}=getModuleObject($self->Config,"base::mandator");

   $co->SetFilter({bc=>['AL T-COM']});
   my @l=$co->getHashList(qw(name bc description sememail));
   my $cocount=0;
   foreach my $rec (@l){
     msg(INFO,"co=$rec->{name}");
     next if (!($rec->{name}=~m/^\d{5,20}$/));
     $w5co->ResetFilter();
     $w5co->SetFilter({name=>\$rec->{name}});
     my ($w5rec,$msg)=$w5co->getOnlyFirst(qw(ALL));
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
     $self->VerifyAssetCenterData($rec);
     #last if ($cocount++==80);
   }


   my $wf=$self->{wf};
   $wf->ResetFilter();
   $wf->SetFilter({stateid=>"<20",class=>\'base::workflow::DataIssue',
                   directlnktype=>[$self->Self],
                   srcload=>"<\"$self->{loadstart}\""});
   $wf->SetCurrentView(qw(ALL));
   $wf->ForeachFilteredRecord(sub{
       my $WfRec=$_;
       my $bk=$wf->Store($WfRec,{stateid=>25});
   });

   return({exitcode=>0}); 
}


sub VerifyAssetCenterData
{
   my $self=shift;
   my $corec=shift;
   my $conumber=$corec->{name};
   my $altbc=$corec->{bc};

   if ($altbc eq "AL T-COM"){
      my $wf=$self->{wf};
      my $acsys=$self->{acsys};
      my $w5sys=$self->{w5sys};
      $acsys->ResetFilter();
      $acsys->SetFilter({conumber=>\$conumber});
      my @syslist=$acsys->getHashList(qw(systemid systemname applications));
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
               my $desc="[W5TRANSLATIONBASE=".$self->Self."]\n";
               $desc.="There are no application relations in AssetCenter\n"; 

               $w5sys->ResetFilter();
               $w5sys->SetFilter({systemid=>\$sysrec->{systemid}});
               my ($w5sysrec,$msg)=$w5sys->getOnlyFirst(qw(id applications
                                                           cistatusid));
               if (!defined($w5sysrec)){
                  $desc.="- SystemID not found in W5Base/Darwin\n";
               }
               else{
                  if (!defined($w5sysrec->{applications}) ||
                      ref($w5sysrec->{applications}) ne "ARRAY" ||
                      $#{$w5sysrec->{applications}}==-1){
                     $desc.="- no application relations found in ".
                            "W5Base/Darwin\n";
                  }
               }


               #############################################################
               # Issue Create
               #
               my $issue={name=>"DataIssue: AssetCenter: no applications ".
                                "on systemid \"$sysrec->{systemid}\" ".
                                "($sysrec->{systemname})",
                          class=>'base::workflow::DataIssue',
                          step=>'base::workflow::DataIssue::dataload',
                          eventstart=>NowStamp("en"),
                          srcload=>NowStamp("en"),
                          directlnktype=>$self->Self,
                          directlnkid=>'0',
                          altaffectedobjectname=>$sysrec->{systemid},
                          mandatorid=>['200'],
                          mandator=>['AL T-Com'],
                          directlnkmode=>$sysrec->{systemid},
                          detaildescription=>$desc};
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
#exit(1) if ($sysrec->{systemid} eq "S01312120");

            }
         }
      }
   }

}



1;
