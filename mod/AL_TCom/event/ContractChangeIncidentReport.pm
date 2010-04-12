package AL_TCom::event::ContractChangeIncidentReport;
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

   $self->RegisterEvent("ContractChangeIncidentReport",
                        "ContractChangeIncidentReport");
   return(1);
}

sub ContractChangeIncidentReport
{
   my $self=shift;
   my %param=@_;
   my %flt;

   $self->{contract}=[grep(!/^\s*$/,split(/[,\s;]+/,$param{contract}))];
   if ($#{$self->{contract}}==-1){
      return({exitcode=>1,msg=>"no contract restriction"});
   }
   msg(INFO,"report for %s",join(" ",@{$self->{contract}}));
#
#   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
#   $appl->SetFilter({customer=>$flt{customer}});
#   $self->{'onlyApplId'}={};
#   foreach my $arec ($appl->getHashList(qw(id customerprio criticality))){
#     $self->{'onlyApplId'}->{$arec->{id}}=$arec;
#   }

   $param{'defaultFilenamePrefix'}="Contract-Report_";
   $param{'defaultEventend'}=">now-3M" if ($param{'defaultEventend'} eq "");
   %param=kernel::XLSReport::StdReportParamHandling($self,%param);

   #msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   my $wf=getModuleObject($self->Config,"base::workflow");

   $wf->AddFields(
      new kernel::Field::Textarea(
                name          =>'DESC',
                label         =>'Workflow Beschreibung',
                htmldetail    =>0),
   );
 
   

   my @control=(
                {DataObj=>$wf,
                 sheet=>'ProcessReport',
                 filter=>{
                          eventend=>$param{'eventend'},
                          class=>[qw(
                                     AL_TCom::workflow::change
                                     AL_TCom::workflow::incident
                                     AL_TCom::workflow::businesreq
                                  )],
                          isdeleted=>'0'
                         },
                 #order=>'eventendrev',
                 lang=>'de',
                 recPreProcess=>\&recPreProcess,
                 view=>[qw(id 
                           srcid
                           class
                           eventstart 
                           eventend
                           name
                           affectedapplication
                           affectedcontract
                           involvedcustomer
                           wffields.tcomcodrelevant
                           wffields.tcomcodcause
                           wffields.tcomcodcomments
                           wffields.tcomworktime
                           DESC
                           wffields.incidentdescription
                           wffields.changedescription
                           description
                           )]
                }
               );


   $out->Process(@control);
   msg(INFO,"end Report to $param{'filename'}");

   return({exitcode=>0,msg=>"OK"});
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;
   msg(INFO,"process %s (%s)",$rec->{id},$rec->{class});

   my $found=0;

   return(0) if (!ref($rec->{affectedapplicationid}) eq "ARRAY");
   foreach my $cid (@{$self->{'contract'}}){
      if (my @a=grep(/^$cid$/,@{$rec->{affectedcontract}})){
         $found++;
         last;
      }   
   }
   return(0) if (!$found);
   msg(INFO,"found");
   my @newrecview;
   my $desc="";
   foreach my $fld (@$recordview){
      my $name=$fld->Name;
      if ($name eq "incidentdescription" ||
          $name eq "changedescription"   ||
          $name eq "description"){
         my $d=$fld->RawValue($rec);
         $desc.=$d;
      }
      else{
         push(@newrecview,$fld);
      }
   }
   $desc=~s/[^a-z0-9\n =#_\-\.,:;!\?\*+"\/>\$]//gi;
   my $maxdesc=16000;
   if (length($desc)>$maxdesc-3){
      $desc=substr($desc,0,$maxdesc-3)."...";
   }
   $rec->{DESC}=$desc;

   @{$recordview}=@newrecview;
   return(1);
}





1;
