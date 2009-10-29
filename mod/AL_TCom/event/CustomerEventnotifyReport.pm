package AL_TCom::event::CustomerEventnotifyReport;
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

   $self->RegisterEvent("CustomerEventnotifyReport",
                        "CustomerEventnotifyReport");
   return(1);
}

sub CustomerEventnotifyReport
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
   $self->{'onlyApplId'}=[];
   foreach my $arec ($appl->getHashList(qw(id))){
      push(@{$self->{'onlyApplId'}},$arec->{id});
   }
   $param{'defaultFilenamePrefix'}="Eventinfo-Report_";
   %param=kernel::XLSReport::StdReportParamHandling($self,%param);

   msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   $flt{'cistatusid'}='4';

   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->AddFields(
      new kernel::Field::Text(
                name          =>'SCrelationPathNo',
                xlsbgcolor    =>'#EBE5E5',
                xlswidth      =>'10',
                label         =>'ServiceCenter Path',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationIncidentNo',
                label         =>'ServiceCenter Incident',
                xlsbgcolor    =>'#F1F79B',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationIncidentState',
                label         =>'SC Incident State',
                xlsbgcolor    =>'#F1F79B',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationIncidentDesc',
                label         =>'SC Incident Description',
                xlsbgcolor    =>'#F1F79B',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationProblemNo',
                label         =>'ServiceCenter Problem',
                xlsbgcolor    =>'#F7DBC2',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationProblemState',
                label         =>'SC Problem State',
                xlsbgcolor    =>'#F7DBC2',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationProblemDesc',
                label         =>'SC Problem Description',
                xlsbgcolor    =>'#F7DBC2',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationProblemCause',
                label         =>'SC Problem Cause',
                xlsbgcolor    =>'#F7DBC2',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationChangeNo',
                label         =>'ServiceCenter Change',
                xlsbgcolor    =>'#E2C2F7',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationChangeState',
                label         =>'SC Change State',
                xlsbgcolor    =>'#E2C2F7',
                htmldetail    =>0),
      new kernel::Field::Text(
                name          =>'SCrelationChangeDesc',
                label         =>'SC Change Description',
                xlsbgcolor    =>'#E2C2F7',
                htmldetail    =>0)
   );
 
   

   my @control=({DataObj=>$wf,
                 sheet=>'Ereignisinfo',
                 filter=>{eventend=>$param{'eventend'},
#                         id=>\'12502631710002',
                          isdeleted=>'0',
                          class=>'AL_TCom::workflow::eventnotify'},
                 order=>'eventendrev',
                 lang=>'de',
                 recPreProcess=>\&recPreProcess,
#                 view=>[qw(eventendday 
#                           affectedapplication
#                           affectedapplicationid
#                           affectedcontract id 
#                           name detaildescription
#                           shortactionlog
#                           wffields.eventinmrelations)]
                 view=>[qw(
                           affectedapplication
                           wffields.eventstatclass

                           eventstart 
                           eventend
                           eventduration
                           wffields.eventdesciption

                           SCrelationPathNo

                           SCrelationIncidentNo
                           SCrelationIncidentState
                           SCrelationIncidentDesc

                           SCrelationProblemNo
                           SCrelationProblemState
                           SCrelationProblemDesc

                           SCrelationChangeNo
                           SCrelationChangeState
                           SCrelationChangeDesc

                           wffields.eventinmrelations)]
                },
               );
   $self->{'loopBuffer'}=[];
   $self->{'loopCount'}=0;
   $out->Process(@control);
   msg(INFO,"end Report to $param{'filename'}");

   return({exitcode=>0,msg=>"OK"});
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   my $found=0;
   foreach my $applid (@{$self->{'onlyApplId'}}){
      if (grep(/^$applid$/,@{$rec->{affectedapplicationid}})){
         $found++;
      }   
   }
   return(0) if (!$found);
   return(0) if ($rec->{eventstatclass}!=1 &&
                 $rec->{eventstatclass}!=2 &&
                 $rec->{eventstatclass}!=3);
   my @newrecview;
   foreach my $fld (@$recordview){
      my $name=$fld->Name;
      next if ($name eq "affectedapplicationid");
      next if ($name eq "eventinmrelations");
      next if ($name eq "SCrelationPathNo");
      push(@newrecview,$fld);
   }
   @{$recordview}=@newrecview;
   if ($#{$self->{'loopBuffer'}}==-1 &&
       exists($rec->{eventinmrelations}->{treelist})){
      $self->{'loopBuffer'}=$rec->{eventinmrelations}->{treelist};
      delete($rec->{eventinmrelations}->{treelist});
      $self->{'loopCount'}=1;
   }
   $rec->{SCrelationPathNo}=$self->{'loopCount'};
   if ($#{$self->{'loopBuffer'}}!=-1){
      my $loop=shift(@{$self->{'loopBuffer'}});
      $self->{'loopCount'}++;
      $rec->{SCrelationIncidentNo}=$loop->[0];
      $rec->{SCrelationProblemNo}=$loop->[1];
      $rec->{SCrelationChangeNo}=$loop->[2];

      # recharge incident detail data
      $rec->{SCrelationIncidentState}=undef;
      $rec->{SCrelationIncidentDesc}=undef;
      if ($rec->{SCrelationIncidentNo} ne ""){
         my $sc=getModuleObject($self->Config,"tssc::inm");
         $sc->SetFilter({incidentnumber=>\$rec->{SCrelationIncidentNo}});
         my ($screc,$msg)=$sc->getOnlyFirst(qw(status name));
         if (defined($screc)){
            $rec->{SCrelationIncidentState}=$screc->{status};
            $rec->{SCrelationIncidentDesc}=$screc->{name};
         }
      }
      # recharge problem detail data
      $rec->{SCrelationProblemState}=undef;
      $rec->{SCrelationProblemDesc}=undef;
      if ($rec->{SCrelationProblemNo} ne ""){
         my $sc=getModuleObject($self->Config,"tssc::prm");
         $sc->SetFilter({problemnumber=>\$rec->{SCrelationProblemNo}});
         my ($screc,$msg)=$sc->getOnlyFirst(qw(status name cause));
         if (defined($screc)){
            $rec->{SCrelationProblemState}=$screc->{status};
            $rec->{SCrelationProblemDesc}=$screc->{name};
            $rec->{SCrelationProblemCause}=$screc->{cause};
         }
      }
      # recharge change detail data
      $rec->{SCrelationChangeState}=undef;
      $rec->{SCrelationChangeDesc}=undef;
      if ($rec->{SCrelationChangeNo} ne ""){
         my $sc=getModuleObject($self->Config,"tssc::chm");
         $sc->SetFilter({changenumber=>\$rec->{SCrelationChangeNo}});
         my ($screc,$msg)=$sc->getOnlyFirst(qw(status description));
         if (defined($screc)){
            $rec->{SCrelationChangeState}=$screc->{status};
            $rec->{SCrelationChangeDesc}=$screc->{description};
         }
      }

      return(2) if ($#{$self->{'loopBuffer'}}!=-1);
   }
   return(1);
}





1;
