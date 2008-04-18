package tsbflexx::custbill;
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
         label       =>'BillID',
         dataobjattr =>'(bflexx_cod_stammdaten.vertrags_nr+"-"+'.
                       'bflexx_cod_stammdaten.re_nr)'),
                                                  
      new kernel::Field::Text(       name          =>'name',
         label       =>'Contract Number',
         dataobjattr =>'bflexx_cod_stammdaten.vertrags_nr'),

      new kernel::Field::Text(       name          =>'billno',
         label       =>'Billing Month',
         dataobjattr =>'bflexx_cod_stammdaten.re_nr'),

      new kernel::Field::Link(       name          =>'belllink',
         label       =>'BillModuleID',
         dataobjattr =>'(bflexx_cod_stammdaten.re_nr+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_stammdaten.la_id))+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_stammdaten.re_nr_int)))'),

      new kernel::Field::Link(       name          =>'fbelllink',
         label       =>'BillModuleID',
         dataobjattr =>'(bflexx_cod_stammdaten.re_nr+\'-\'+'.
    'rtrim(convert(char,bflexx_cod_stammdaten.vertrags_nr)))'),

      new kernel::Field::Text(       name          =>'contractname',
                                     htmlwidth     =>'200px',
         label       =>'Contract Description',
         dataobjattr =>'bflexx_cod_stammdaten.ag_kurzbezeichnung'),

      new kernel::Field::Text(       name          =>'costcenter',
         label       =>'Cost Center',
         dataobjattr =>'bflexx_cod_stammdaten.co_nr'),

      new kernel::Field::Text(       name          =>'customer',
         label       =>'Customer',
         dataobjattr =>'bflexx_cod_stammdaten.kunde'),

      new kernel::Field::SubList(    name       =>'modules',
                                     label      =>'Ordered Modules',
                                     group      =>'modules',
                                     vjointo    =>'tsbflexx::orderedmod',
                                     vjoinon    =>['belllink'=>'belllink'],
                                     vjoindisp  =>['name','env']),

      new kernel::Field::SubList(    name       =>'invoice',
                                     label      =>'Invoice',
                                     group      =>'invoice',
                                     vjointo    =>'tsbflexx::invoice',
                                     vjoinon    =>['fbelllink'=>'fbelllink'],
                                     vjoindisp  =>['name','amount','cost']),



   );
   $self->setDefaultView(qw(linenumber billno name contractname customer));
   return($self);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   return(qw(header default modules invoice));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/finance/load/bflexx.jpg?".$cgi->query_string());
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsbflexx"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("bflexx_cod_stammdaten");
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

1;
