package TS::event::NOR_Report;
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


   $self->RegisterEvent("NOR_Report","NOR_Report");
   return(1);
}

sub NOR_Report
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

   $flt{mandator}="!Extern";
   $flt{cistatusid}="<=5";

   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter(\%flt);
   my $t=$appl->getHashIndexed(qw(id));

   %flt=(srcparentid=>[keys(%{$t->{id}})]);


   if ($param{'filename'} eq ""){
      my $names;
      if ($param{customer} ne ""){
         $names.="_" if ($names ne "");
         $names="CUSTOMER-$param{customer}";
      }
      if ($param{name} ne ""){
         $names.="_" if ($names ne "");
         $names.="APP-$param{name}";
      }
      $names="ALL" if ($names eq "");
      $names=substr($names,0,40)."___" if (length($names)>40);
      $names=~s/[^a-z0-9]/_/gi;
      my ($year, $month)=$self->Today_and_Now("GMT");
      my $t=sprintf("%04d_%02d",$year, $month);
      $param{'filename'}=[
          "webfs:/Reports/NOR/W5BaseDarwin-NOR-Report_${names}.$t.xls",
          "webfs:/Reports/NOR/W5BaseDarwin-NOR-Report_${names}.cur.xls"];
   }
   msg(INFO,"start Report to $param{'filename'}");
 

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   $flt{'isactive'}='1 [EMPTY]'; 

   my $cacheReseter=sub{
      $W5V2::CacheCount++;
      if ($W5V2::CacheCount>50){
         $W5Base::CacheCount=0;
         $W5V2::Context={};
         $W5V2::Cache={};
      }
      return(1);
   }

   my @control=({DataObj=>'TS::appladv',
                 filter=>\%flt,
                 recPreProcess=>$cacheReseter,
                 view=>[qw(fullname id name isactive dstate databoss 
                           modules normodelbycustomer itnormodel 
                           processingpersdata scddata)]},

                {DataObj=>'TS::applnor',
                 filter=>\%flt,
                 recPreProcess=>$cacheReseter,
                 view=>[qw(fullname id name custcontract isactive 
                           dstate databoss normodel
                           SUMMARYdeliveryCountry
                           SUMMARYisCountryCompliant
                           SUMMARYisSCDconform
                           SUMMARYappliedNOR mdate owner)]},
                );

   $out->Process(@control);


#   $self->{workbook}=$self->XLSopenWorkbook();
#   if (!($self->{workbook}=$self->XLSopenWorkbook())){
#      return({exitcode=>1,msg=>'fail to create tempoary workbook'});
#   }


   return({exitcode=>0,msg=>'OK'});
}





1;
