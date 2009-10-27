package AL_TCom::event::CustomerBTBreport;
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


   $self->RegisterEvent("CustomerBTBreport","CustomerBTBreport");
   return(1);
}

sub CustomerBTBreport
{
   my $self=shift;
   my %param=@_;
   my %flt;
   msg(DEBUG,"param=%s",Dumper(\%param));
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

   $param{'defaultFilenamePrefix'}="BTB-Report_";
   %param=kernel::XLSReport::StdReportParamHandling($self,%param);

   msg(INFO,"start Report to %s",join(", ",@{$param{'filename'}}));
   my $t0=time();
 

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   $flt{'cistatusid'}='4';

   my @control=({DataObj=>'base::workflow',
                 sheet=>'BTB',
                 filter=>{eventend=>$param{'eventend'},
                          isdeleted=>'0',
                          class=>'AL_TCom::workflow::diary'},
                 order=>'eventendrev',
                 lang=>'de',
                 recPreProcess=>\&recPreProcess,
                 view=>[qw(eventendday 
                           affectedapplication
                           affectedapplicationid
                           affectedcontract id 
                           name detaildescription
                           wffields.tcomcodcomments
                           wffields.tcomcodcause
                           wffields.tcomcodrelevant
                           wffields.tcomworktime
                           shortactionlog)]},
                );

   $out->Process(@control);
   my $trep=time()-$t0;
   msg(INFO,"end Report to $param{'filename'} ($trep sec)");



#   $self->{workbook}=$self->XLSopenWorkbook();
#   if (!($self->{workbook}=$self->XLSopenWorkbook())){
#      return({exitcode=>1,msg=>'fail to create tempoary workbook'});
#   }


   return({exitcode=>0,msg=>"OK (time $trep sec)"});
}

sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   my $found=0;
   return(0) if (!$rec->{tcomcodrelevant});
   foreach my $applid (@{$self->{'onlyApplId'}}){
      if (grep(/^$applid$/,@{$rec->{affectedapplicationid}})){
         $found++;
      }   
   }
   return(0) if (!$found);
   my @newrecview;
   foreach my $fld (@$recordview){
      my $name=$fld->Name;
      next if ($name eq "affectedapplicationid");
      next if ($name eq "tcomcodrelevant");
      push(@newrecview,$fld);
   }
   @{$recordview}=@newrecview;

   return(1);
}





1;
