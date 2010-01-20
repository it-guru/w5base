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

   #msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->AddFields(
      new kernel::Field::Boolean(
                name          =>'THOME_isTop50',
                label         =>'T-Home Top50',
                htmldetail    =>0),
      new kernel::Field::Boolean(
                name          =>'THOME_isTop20',
                label         =>'T-Home Top20',
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
                           mandator
                           affectedapplication
                           involvedcustomer
                           wffields.changedescription
                           description
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
                           mandator
                           affectedapplication
                           involvedcustomer
                           wffields.incidentdescription
                           description
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
   foreach my $applid (@{$rec->{affectedapplicationid}}){
      if (my @a=grep(/^$applid$/,keys(%{$self->{'onlyApplId'}}))){
         $found++;
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
   return(1);
}





1;
