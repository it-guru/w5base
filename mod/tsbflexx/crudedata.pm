package tsbflexx::crudedata;
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
                                     searchable    =>'0',
                                     sqlorder      =>'desc',
         label       =>'FakturaID',
         dataobjattr =>
    '(ltrim(convert(char,bflexx_cod_reporting.vertrags_id))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_reporting.re_nr))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_reporting.re_nr))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_reporting.smod_id))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_reporting.leistungsklasse_id)))'),

      new kernel::Field::Text(       name          =>'billno',
                                     htmlwidth     =>'70px',
         label       =>'Billing Month',
         dataobjattr =>'rtrim(convert(char,bflexx_cod_reporting.re_nr))'),

      new kernel::Field::Text(       name          =>'contractnumber',
                                     htmlwidth     =>'70px',
         label       =>'Contract number',
         dataobjattr =>'bflexx_cod_reporting.vertrags_nr'),

      new kernel::Field::Text(       name          =>'contractdesc',
                                     htmlwidth     =>'280px',
         label       =>'Contract description',
         dataobjattr =>'bflexx_cod_reporting.app_name'),

      new kernel::Field::Text(       name          =>'name',
                                     htmlwidth     =>'400px',
         label       =>'Product description',
         dataobjattr =>'bflexx_cod_reporting.leistungsklasse'),

      new kernel::Field::Number(     name          =>'amount',
                                     align         =>'right',
                                     precision     =>2,
         label       =>'Amount',
         dataobjattr =>'bflexx_cod_reporting.menge'),

   );
   $self->setDefaultView(qw(linenumber contractnumber contractdesc billno name amount));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsbflexx"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("bflexx_cod_reporting");
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/finance/load/bflexxjpg?".$cgi->query_string());
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
