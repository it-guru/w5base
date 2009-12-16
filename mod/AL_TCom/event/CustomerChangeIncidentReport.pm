package AL_TCom::event::CustomerChangeIncidentReport;
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
use kernel::Field;

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

   $self->RegisterEvent("CustomerChangeIncidentReport",
                        "CustomerChangeIncidentReport");
   return(1);
}

sub CustomerChangeIncidentReport
{
   my $self=shift;
   my %param=@_;
   my %flt;
   if ($param{customer} ne ""){
      my $c=$param{customer};
      $flt{customer}="$param{customer} $param{customer}.*";
   }
   else{
      return({exitcode=>1,msg=>"no customer restriction"});
   }

   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter({customer=>$flt{customer}});
   $self->{'onlyApplId'}={};
   foreach my $arec ($appl->getHashList(qw(id customerprio criticality))){
     $self->{'onlyApplId'}->{$arec->{id}}=$arec;
   }
   $param{'defaultFilenamePrefix'}="Prozess-Report_";
   $param{'defaultEventend'}=">now-3M";
   %param=kernel::XLSReport::StdReportParamHandling($self,%param);

   msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->AddFields(
      new kernel::Field::Boolean(
                name          =>'_isTop50',
                label         =>'Top50',
                htmldetail    =>0),
      new kernel::Field::Boolean(
                name          =>'_isTop20',
                label         =>'Top20',
                htmldetail    =>0)
   );
 
   

   my @control=(
                {DataObj=>$wf,
                 sheet=>'Change',
                 filter=>{
                          eventend=>$param{'eventend'},
#                         id=>[qw(12524007040002 
#                                 12524003600004 
#                                 12524003410006 
#                                 12523985200008 12519937850002
#                                 12523949370006 12524222410002
#                                 12523931520002 12519740670002
#                                 12523197890002 12522986780002 12519740670002
#                                 12523277660002)],
                          isdeleted=>'0',
                          class=>['AL_TCom::workflow::change']
                         },
                 order=>'eventendrev',
                 lang=>'de',
                 recPreProcess=>\&recPreProcess,
                 view=>[qw(id srcid
                           eventstart 
                           eventend
                           class
                           affectedapplication
                           involvedcustomer
                           wffields.changedescription
                           description
                           _isTop50
                           _isTop20
                           additional.ServiceCenterCoordinator
                           additional.ServiceCenterReason 
                           additional.ServiceCenterImpact 
                           additional.ServiceCenterRisk 
                           additional.ServiceCenterType 
                           additional.ServiceCenterUrgency 
                           additional.ServiceCenterPriority 
                           wffields.tcomcodrelevant
                           wffields.tcomcodcause
                           wffields.tcomcodcomments
                           wffields.tcomworktime
                           )]
                },
                {DataObj=>$wf,
                 sheet=>'Incident',
                 filter=>{
                         eventend=>$param{'eventend'},
#                         id=>[qw(12524007040002 
#                                 12524003600004 
#                                 12524003410006 
#                                 12523985200008 12519937850002
#                                 12523949370006 12524222410002
#                                 12523931520002 12519740670002
#                                 12523197890002 12522986780002 12519740670002
#                                 12523277660002)],
                          isdeleted=>'0',
                          class=>['AL_TCom::workflow::incident']
                         },
                 order=>'eventendrev',
                 lang=>'de',
                 recPreProcess=>\&recPreProcess,
                 view=>[qw(id srcid
                           eventstart 
                           eventend
                           class
                           affectedapplication
                           involvedcustomer
                           wffields.incidentdescription
                           description
                           _isTop50
                           _isTop20
                           wffields.tcomcodrelevant
                           wffields.tcomcodcause
                           wffields.tcomcodcomments
                           wffields.tcomworktime
                           )]
                },
               );


   $out->Process(@control);
   msg(INFO,"end Report to $param{'filename'}");

   return({exitcode=>0,msg=>"OK"});
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   my $found=0;

   return(0) if (!ref($rec->{affectedapplicationid}) eq "ARRAY");
   $rec->{_isTop50}=0;
   $rec->{_isTop20}=0;
   foreach my $applid (@{$rec->{affectedapplicationid}}){
      if (my @a=grep(/^$applid$/,keys(%{$self->{'onlyApplId'}}))){
         $found++;
         foreach my $aid (@a){
            my $arec=$self->{'onlyApplId'}->{$aid};
            if ($arec->{customerprio}==1){
               if ($arec->{criticality} eq "CRcritical"){
                  $rec->{_isTop50}=1 if (!$rec->{_isTop50});
                  $rec->{_isTop20}=1 if (!$rec->{_isTop20});
               }
               if ($arec->{criticality} eq "CRhigh"){
                  $rec->{_isTop50}=1 if (!$rec->{_isTop50});
               }
            }
         }
      }   
   }
   return(0) if (!$found);
   my @newrecview;
   foreach my $fld (@$recordview){
      my $name=$fld->Name;
  #    next if ($name eq "incidentdescription");
  #    next if ($name eq "changedescription");
      push(@newrecview,$fld);
   }

   @{$recordview}=@newrecview;
#   return(0) if ($rec->{eventstatclass}!=1 &&
#                 $rec->{eventstatclass}!=2 &&
#                 $rec->{eventstatclass}!=3);
#   if ($#{$self->{'loopBuffer'}}==-1 &&
#       exists($rec->{eventinmrelations}->{treelist})){
#      $self->{'loopBuffer'}=$rec->{eventinmrelations}->{treelist};
#      delete($rec->{eventinmrelations}->{treelist});
#      $self->{'loopCount'}=1;
#   }
#   $rec->{SCrelationPathNo}=$self->{'loopCount'};
#   if ($#{$self->{'loopBuffer'}}!=-1){
#      my $loop=shift(@{$self->{'loopBuffer'}});
#      $self->{'loopCount'}++;
#      $rec->{SCrelationIncidentNo}=$loop->[0];
#      $rec->{SCrelationProblemNo}=$loop->[1];
#      $rec->{SCrelationChangeNo}=$loop->[2];
#
#      # recharge incident detail data
#      $rec->{SCrelationIncidentState}=undef;
#      $rec->{SCrelationIncidentDesc}=undef;
#      if ($rec->{SCrelationIncidentNo} ne ""){
#         my $sc=getModuleObject($self->Config,"tssc::inm");
#         $sc->SetFilter({incidentnumber=>\$rec->{SCrelationIncidentNo}});
#         my ($screc,$msg)=$sc->getOnlyFirst(qw(status name));
#         if (defined($screc)){
#            $rec->{SCrelationIncidentState}=$screc->{status};
#            $rec->{SCrelationIncidentDesc}=$screc->{name};
#         }
#      }
#      # recharge problem detail data
#      $rec->{SCrelationProblemState}=undef;
#      $rec->{SCrelationProblemDesc}=undef;
#      if ($rec->{SCrelationProblemNo} ne ""){
#         my $sc=getModuleObject($self->Config,"tssc::prm");
#         $sc->SetFilter({problemnumber=>\$rec->{SCrelationProblemNo}});
#         my ($screc,$msg)=$sc->getOnlyFirst(qw(status name cause solution
#                                               closetype solutiontype));
#         if (defined($screc)){
#            $rec->{SCrelationProblemState}=$screc->{status};
#            $rec->{SCrelationProblemDesc}=$screc->{name};
#            $rec->{SCrelationProblemCause}=$screc->{cause};
#            if (my ($clust)=$screc->{cause}=~m/^\s*(.*)\s*------------------/){
#               $rec->{SCrelationProblemRCluster}=$clust;
#            }
#            $rec->{SCrelationProblemSolution}=$screc->{solution};
#            $rec->{SCrelationProblemCloseType}=
#                         $sc->DataObj_findtemplvar({current=>$screc,
#                                                    mode=>'XlsV01'},
#                                                   "closetype","formated");
#            $rec->{SCrelationProblemSolutionType}=
#                         $sc->DataObj_findtemplvar({current=>$screc,
#                                                    mode=>'XlsV01'},
#                                                   "solutiontype","formated");
#         }
#      }
#      # recharge change detail data
#      $rec->{SCrelationChangeState}=undef;
#      $rec->{SCrelationChangeDesc}=undef;
#      if ($rec->{SCrelationChangeNo} ne ""){
#         my $sc=getModuleObject($self->Config,"tssc::chm");
#         $sc->SetFilter({changenumber=>\$rec->{SCrelationChangeNo}});
#         my ($screc,$msg)=$sc->getOnlyFirst(qw(status name 
#                                               plannedstart plannedend));
#         if (defined($screc)){
#            $rec->{SCrelationChangeState}=$screc->{status};
#            $rec->{SCrelationChangeDesc}=$screc->{name};
#            $rec->{SCrelationChangeStart}=$screc->{plannedstart};
#                  #       $sc->DataObj_findtemplvar({current=>$screc,
#                  #                                  mode=>'XlsV01'},
#                  #                                 "plannedstart","formated");
#            $rec->{SCrelationChangeEnd}=$screc->{plannedend};
#                  #       $sc->DataObj_findtemplvar({current=>$screc,
#                  #                                  mode=>'XlsV01'},
#                  #                                 "plannedend","formated");
#         }
#      }
#
#      return(2) if ($#{$self->{'loopBuffer'}}!=-1);
#   }
   return(1);
}





1;
