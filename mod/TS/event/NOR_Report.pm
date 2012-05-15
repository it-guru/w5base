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


   $self->RegisterEvent("NOR_Report","NOR_Report",
                        timeout=>3600);
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



   my $o=getModuleObject($self->Config,"TS::applnor");

   $o->AddFields(
      new kernel::Field::Text(
                name          =>'sdmcluster',
                label         =>'SDM Cluster',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("SDM C&U extern");
                }),
      new kernel::Field::Text(
                name          =>'customertopname',
                label         =>'Kundenname',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("DTAG");
                }),
      new kernel::Field::Text(
                name          =>'customersgpno',
                label         =>'SGP-Nr',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("3000900");
                }),
      new kernel::Field::Text(
                name          =>'customergpnr',
                label         =>'GP-Nr',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("");
                }),
      new kernel::Field::Text(
                name          =>'delmgrposix',
                label         =>'WIW Kennung',
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'posix',
                ),
      new kernel::Field::Text(
                name          =>'delmgremail',
                label         =>'eMail',
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'email',
                ),
      new kernel::Field::Link(
                name          =>'clustersecid',
                label         =>'Cluster Security ID',
                onRawValue    =>sub{
                   return("11634962040001");
                }),
      new kernel::Field::Text(
                name          =>'clustersec',
                label         =>'Cluster Security',
                vjointo       =>'base::user',
                vjoinon       =>['clustersecid'=>'userid'],
                vjoindisp     =>'fullname',
                ),
      new kernel::Field::Text(
                name          =>'clustersecposix',
                label         =>'WiW Kennung',
                vjointo       =>'base::user',
                vjoinon       =>['clustersecid'=>'userid'],
                vjoindisp     =>'posix',
                ),
      new kernel::Field::Text(
                name          =>'clustersecemail',
                label         =>'eMail',
                vjointo       =>'base::user',
                vjoinon       =>['clustersecid'=>'userid'],
                vjoindisp     =>'email',
                ),
      new kernel::Field::Text(
                name          =>'norcheck',
                label         =>'Status der NOR Prüfung',
                depend        =>['dstateid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("offen") if ($current->{dstateid}<=10);
                   return("erfolgt");
                }),
      new kernel::Field::Text(
                name          =>'norstatus',
                label         =>'NOR Status',
                depend        =>['normodel'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fld=$self->getParent->getField("normodel");
                   my $d=$fld->RawValue($current);
                   return("go") if ($d eq "S");
                   return("go") if ($d eq "D3");
                   return("no go");
                }),
      new kernel::Field::Text(
                name          =>'nearshorenogo',
                label         =>'NOGO Grund Vertraglich Rechtlich',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("");
                }),
      new kernel::Field::Text(
                name          =>'nearshorego',
                label         =>'Nearshore Verlagerung derzeit möglich',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("");
                }),
      new kernel::Field::Text(
                name          =>'blnorstatus',
                label         =>'NOR Status',
                depend        =>['dstateid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fld=$self->getParent->getField("normodel");
                   my $d=$fld->RawValue($current);
                   return("go") if ($d eq "S");
                   return("no go");
                }),
      new kernel::Field::Text(
                name          =>'blnearshorenogo',
                label         =>'NOGO Grund Vertraglich Rechtlich',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("");
                }),
      new kernel::Field::Text(
                name          =>'blnearshorego',
                label         =>'Offshore Verlagerung derzeit möglich',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("");
                }),
      new kernel::Field::Text(
                name          =>'restrictions',
                label         =>'Ggf. Einschränkung',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return("");
                }),
      new kernel::Field::Text(
                name          =>'isdelta',
                label         =>'Abweichung Betriebsmodel Vorgabe/Realität',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fld=$self->getParent->getField("normodel");
                   my $d1=$fld->RawValue($current);
                   my $fld=$self->getParent->getField("SUMMARYappliedNOR");
                   my $d2=$fld->RawValue($current);
                   if ($d1 eq $d2){
                      return("nein");
                   }
                   return("ja");
                }),
      new kernel::Field::Text(
                name          =>'applname',
                label         =>'Anwendungsname',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return($current->{name});
                }),
   );

   $o->getField("customer")->{label}="GP Name";
   $o->getField("custcontract")->{label}="Vertragsnummer";
   $o->getField("conumber")->{label}="CO-Auftrag bzw. ZGSL-Nr./VKL-Nr.";
   $o->getField("name")->{label}="Bemerkung zu\n".
                                 "CO-Auftrag ILV / VKL Nr\n".
                                 "Leistungsgegenstand";
   $o->getField("mdate")->{label}="NOR-Nachweis erstellt/update am";
   $o->getField("normodel")->{label}="Betriebsmodell nach Kunde (CBM-Angabe)";
   $o->getField("SUMMARYappliedNOR")->{label}=
                      "Betriebsmodell nach Realsituation (SDM-Angabe)";
   
   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();

   $flt{'isactive'}='1 [EMPTY]'; 

   my @control=(
                {DataObj=>$o,
                 filter=>\%flt,
                 recPreProcess=>\&recPreProcess,
                 view=>[qw(sdmcluster 
                           customertopname
                           customersgpno
                           customergpnr
                           customer
                           delmgr
                           delmgrposix delmgremail
                           clustersec clustersecposix clustersecemail
                           custcontract
                           conumber name
                           norcheck
                           mdate
                           norstatus
                           nearshorenogo
                           nearshorego
                           blnorstatus
                           blnearshorenogo
                           blnearshorego
                           restrictions
                           normodel
                           SUMMARYappliedNOR
                           isdelta applname
                           )],
                });

   $out->Process(@control);

   return({exitcode=>0,msg=>'OK'});
}


sub recPreProcess
{
   my ($self,$DataObj,$rec,$recordview,$reproccount)=@_;

   if (!defined($self->{buffer})){
      if (ref($rec->{custcontract}) eq "ARRAY"){
         $self->{buffer}=[@{$rec->{custcontract}}];
      }
      else{
         $self->{buffer}=[split(/[;,]\s*/,$rec->{custcontract})];
      }
   }
   if (defined($self->{buffer})){
      #####################################################################
      # reprocess buffer
      my $r=shift(@{$self->{buffer}});
      $rec->{custcontract}=$r;
      if ($#{$self->{buffer}}==-1){
         delete($self->{buffer});
      }
      else{
         return(2);
      }
   }
   return(1);
}







1;
