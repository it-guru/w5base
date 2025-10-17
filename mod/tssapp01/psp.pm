package tssapp01::psp;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'"tssapp01::psp".w5id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                nowrap        =>1,
                label         =>'PSP Name',
                dataobjattr   =>'"tssapp01::psp".w5name'),

      new kernel::Field::Text(
                name          =>'accarea',
                label         =>'Accounting Area',
                dataobjattr   =>'"tssapp01::psp".w5accarea'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'"tssapp01::psp".status'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'"tssapp01::psp".w5description'),

      new kernel::Field::Text(
                name          =>'sapcustomer',
                label         =>'SAP Customer',
                dataobjattr   =>'"tssapp01::psp".sapcustomer'),

      new kernel::Field::Link(
                name          =>'etype',
                label         =>'Type',
                dataobjattr   =>'"tssapp01::psp".w5etype'),

      new kernel::Field::Text(
                name          =>'bpmark',
                label         =>'Bussinessprocess mark',
                weblinkto     =>'tssapp01::gpk',
                weblinkon     =>['bpmark'=>'name'],
                dataobjattr   =>'"tssapp01::psp".bpmark'),

      new kernel::Field::Text(
                name          =>'ictono',
                label         =>'ICTO-ID',
                dataobjattr   =>'"tssapp01::psp".ictono'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                group         =>'contacts',
                label         =>'Projectmanager EMail',
                vjointo       =>'tsciam::user',
                vjoinon       =>['databosswiw'=>'wiwid'],
                vjoindisp     =>'email'),

      new kernel::Field::Text(
                name          =>'databosswiw',
                group         =>'contacts',
                label         =>'Projectmanager WIW ID',
                dataobjattr   =>'"tssapp01::psp".w5responsiblewiw'),


      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP hierarchy',
                group         =>'saphier',
                ignorecase    =>1,
                dataobjattr   =>'"tssapp01::psp".saphier'),

      new kernel::Field::Text(
                name          =>'saphier1',
                label         =>'SAP hierarchy 1',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier1'),

      new kernel::Field::Text(
                name          =>'saphier2',
                label         =>'SAP hierarchy 2',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier2'),

      new kernel::Field::Text(
                name          =>'saphier3',
                label         =>'SAP hierarchy 3',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier3'),

      new kernel::Field::Text(
                name          =>'saphier4',
                label         =>'SAP hierarchy 4',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier4'),

      new kernel::Field::Text(
                name          =>'saphier5',
                label         =>'SAP hierarchy 5',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier5'),

      new kernel::Field::Text(
                name          =>'saphier6',
                label         =>'SAP hierarchy 6',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier6'),

      new kernel::Field::Text(
                name          =>'saphier7',
                label         =>'SAP hierarchy 7',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier7'),

      new kernel::Field::Text(
                name          =>'saphier8',
                label         =>'SAP hierarchy 8',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier8'),

      new kernel::Field::Text(
                name          =>'saphier9',
                label         =>'SAP hierarchy 9',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier9'),

      new kernel::Field::Text(
                name          =>'saphier10',
                label         =>'SAP hierarchy 10',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::psp".saphier10'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'"tssapp01::psp".w5createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'"tssapp01::psp".w5modifydate'),

      new kernel::Field::Boolean(
                name          =>'isdeleted',
                uivisible     =>0,
                label         =>'is deleted',
                dataobjattr   =>'"tssapp01::psp".isdeleted'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"\"tssapp01::psp\".w5modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(\"tssapp01::psp\".w5id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"tssapp01::psp".w5srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"tssapp01::psp".w5srcid'),

   );
   $self->setDefaultView(qw(name description cdate mdate));
   $self->setWorktable("\"tssapp01::psp\"");

   #$self->{history}={
   #   update=>[
   #      'local'
   #   ]
   #};
   return($self);
}

sub getSAPhierSQL
{
   my $tab=shift;
   $tab="\"tssapp01::psp\"" if ($tab eq "");
   my $saphierfield;
   for(my $c=1;$c<=10;$c++){
      $saphierfield.="||'.'||" if ($saphierfield ne "");
      $saphierfield.="decode(${tab}.saphier${c},NULL,'-',${tab}.saphier${c})";
   }
   $saphierfield="($saphierfield)";
   return($saphierfield);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{etype}='PSP';
   if (exists($newrec->{isdeleted}) && $newrec->{isdeleted} eq ""){
      $newrec->{isdeleted}="0";
   }

   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default contacts saphier source));
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub CO2PSP_Translator
{
   my $self=shift;
   my $co=shift;
   my $mode=shift;   

   $mode="top" if (!defined($mode));

   return() if (!($co=~m/^\S{10}$/));

   # aus Performance gründen wird das über eine Schleife (nicht über
   # eine ODER Suche) durchgeführt!
   foreach my $pref ("E-","R-","Q-"){   # X- not supported at now
      $self->ResetFilter();
      $self->SetFilter({name=>$pref.$co});
      my ($saprec,$msg)=$self->getOnlyFirst(qw(name));
      return($saprec->{name}) if (defined($saprec));
   }
   return();
}





1;
