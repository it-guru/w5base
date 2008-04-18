package tsbflexx::invoice;
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
      new kernel::Field::Linenumber( name     =>'linenumber',
                                     label      =>'No.'),


      new kernel::Field::Id(         name          =>'id',
                                     sqlorder      =>'desc',
         label       =>'FakturaID',
         dataobjattr =>'(bflexx_cod_faktura.vertrags_nr+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_faktura.faktura_monat))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_faktura.account_nr))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_faktura.leistungs_monat)))'),

      new kernel::Field::Link(       name          =>'fbelllink',
                                     sqlorder      =>'desc',
         label       =>'BillModuleID',
         dataobjattr =>'(bflexx_cod_faktura.faktura_monat+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_faktura.vertrags_nr)))'),

      new kernel::Field::Text(       name          =>'billno',
         label       =>'Billing Month',
         dataobjattr =>'bflexx_cod_faktura.faktura_monat'),

      new kernel::Field::Text(       name          =>'contractnumber',
                                     htmlwidth     =>'100px',
         label       =>'Contract number',
         dataobjattr =>'bflexx_cod_faktura.vertrags_nr'),

      new kernel::Field::Text(       name          =>'contractdesc',
                                     htmlwidth     =>'200px',
         label       =>'Contract description',
         dataobjattr =>'bflexx_cod_faktura.vertragsbezeichnung'),

      new kernel::Field::Text(       name          =>'name',
                                     htmlwidth     =>'450px',
         label       =>'Product description',
         dataobjattr =>'bflexx_cod_faktura.artikel_bezeichnung'),

      new kernel::Field::Number(     name          =>'amount',
                                     align         =>'right',
                                     precision     =>2,
         label       =>'Amount',
         dataobjattr =>'bflexx_cod_faktura.menge'),

      new kernel::Field::Currency(   name          =>'cost',
         unit        =>'EUR',
         label       =>'Cost',
         dataobjattr =>'bflexx_cod_faktura.gesamtpreis_monat_euro'),

   );
   $self->setDefaultView(qw(linenumber contractnumber billno name amount));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsbflexx"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("bflexx_cod_faktura");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/finance/load/bflexx.jpg?".$cgi->query_string());
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

1;
