package TS::event::ITILfullRep;
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


   $self->RegisterEvent("ITILfullRep","ITILfullRep");
   return(1);
}

sub ITILfullRep
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
      msg(DEBUG,"no customer restriction");
   }
   if ($param{name} ne ""){
      my $c=$param{name};
      $flt{name}="$param{name}";
   }
   else{
      msg(DEBUG,"no name restriction");
   }


   my @keys=qw(name id conumber customer);
   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter(\%flt);
   $appl->SetCurrentView(@keys);
   my $eventend=">now";
   if ($param{year} ne ""){
      $eventend="($param{year})";
   }
   if ($param{eventend} ne ""){
      $eventend="$param{eventend}";
   }
   my $t=$appl->getHashIndexed(@keys);
   if ($param{'filename'} eq ""){
      my $names=join("_",keys(%{$t->{name}}));
      $names=substr($names,0,40)."___" if (length($names)>40);
      my $tstr=$eventend;
      $tstr=~s/</less_/gi;
      $tstr=~s/>/more_/gi;
      $tstr=~s/[^a-z0-9]/_/gi;
      $names=~s/[^a-z0-9]/_/gi;
      $param{'filename'}="/tmp/FullIT-Report_${names}_${tstr}.xls";
   }
   msg(INFO,"start Report to $param{'filename'}");
   my $t0=time();
 

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   $flt{'cistatusid'}='4';

   my @control=({DataObj=>'itil::appl',
                 filter=>\%flt,
                 view=>[qw(name mandator id applid conumber customer
                           criticality customerprio)]},

                {DataObj=>'itil::system',
                 filter=>{cistatusid=>'4',applications=>[keys(%{$t->{name}})]},
                 view=>[qw(name systemid applicationnames asset 
                           memory cpucount osrelease)]},

                {DataObj=>'itil::asset',
                 filter=>{cistatusid=>'4',applications=>[keys(%{$t->{name}})]},
                 view=>[qw(name systemids 
                           hwmodel serialno memory cpucount 
                           applicationnames)]},

                {DataObj=>'base::workflow',
                 sheet=>'Change',
                 filter=>{eventend=>$eventend,
                          isdeleted=>'0',
                          class=>'AL_TCom::workflow::change',
                          affectedapplicationid=>[keys(%{$t->{id}})]},
                 order=>'NONE',
                 view=>[qw(name id srcid eventstart eventend 
                           additional.ServiceCenterReason 
                           additional.ServiceCenterImpact 
                           additional.ServiceCenterRisk 
                           additional.ServiceCenterType 
                           additional.ServiceCenterUrgency 
                           additional.ServiceCenterPriority 
                           additional.ServiceCenterCloseCode
                           additional.ServiceCenterState 
                           additional.ServiceCenterCategory  
                           wffields.changedescription)]},

                {DataObj=>'base::workflow',
                 sheet=>'Incident',
                 filter=>{eventend=>$eventend,
                          isdeleted=>'0',
                          class=>'AL_TCom::workflow::incident',
                          affectedapplicationid=>[keys(%{$t->{id}})]},
                 order=>'NONE',
                 view=>[qw(name id srcid eventstart eventend
                           additional.ServiceCenterPriority 
                           additional.ServiceCenterReason 
                           additional.ServiceCenterDowntimeStart 
                           additional.ServiceCenterDowntimeEnd 
                           wffields.incidentdescription)]},

                {DataObj=>'base::workflow',
                 sheet=>'BTB',
                 filter=>{eventend=>$eventend,
                          isdeleted=>'0',
                          class=>'AL_TCom::workflow::diary',
                          affectedapplicationid=>[keys(%{$t->{id}})]},
                 order=>'NONE',
                 view=>[qw(name id eventstart eventend
                           detaildescription)]}
                );

   $out->Process(@control);
   my $trep=time()-$t0;
   msg(INFO,"end Report to $param{'filename'} ($trep sec)");



#   $self->{workbook}=$self->XLSopenWorkbook();
#   if (!($self->{workbook}=$self->XLSopenWorkbook())){
#      return({exitcode=>1,msg=>'fail to create tempoary workbook'});
#   }


   return({exitcode=>0,msg=>'OK'});
}





1;
