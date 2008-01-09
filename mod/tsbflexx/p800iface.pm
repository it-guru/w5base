package tsbflexx::p800iface;
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
      new kernel::Field::Linenumber( 
                  name              =>'linenumber',
                  label             =>'No.'),

      new kernel::Field::Id( 
                  name              =>'id',
                  autogen           =>0,
                  searchable        =>0,
                  align             =>'left',
                  htmlwidth         =>'80px',
                  sqlorder          =>'desc',
                  label             =>'MeasureID',
                  dataobjattr       =>'ta_application_data.id',
                  ),
                                  
      new kernel::Field::Text(    
                  name              =>'billno',
                  htmlwidth         =>'70px',
                  id                =>1,      
                  label             =>'Billing Month',
                  dataobjattr       =>'ta_application_data.messperiode'),
                                   
      new kernel::Field::Text(     
                  name              =>'contractnumber',
                  id                =>1,      
                  htmlwidth         =>'70px',
                  label             =>'Contract number',
                  dataobjattr       =>'ta_application_data.vertragsnr'),
                                   
      new kernel::Field::Select(   
                  name              =>'measurand',
                  id                =>1,      
                  label             =>'Measurand',
                  htmlwidth         =>'200px',
                  selectwidth       =>'200px',
                  value             =>[qw(1 2 3)],
                  transprefix =>'measurand.',
                  dataobjattr       =>'ta_application_data.messgroesse'),
                                   
      new kernel::Field::Number(   
                  name              =>'amount',
                  align             =>'right',
                  precision         =>2,
                  htmlwidth         =>'20px',
                  label             =>'Amount',
                  dataobjattr       =>'ta_application_data.anzahl'),
                                   
      new kernel::Field::Date(     
                  name              =>'cdate',
                  readonly          =>1,
                  timezone          =>'CET',
                  label             =>'Created/Modified',
                  dataobjattr       =>'ta_application_data.datecreated'),
   );
   $self->setDefaultView(qw(linenumber billno contractnumber measurand 
                            amount cdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsbflexx"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("ta_application_data");
   return(1);
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
   return("ALL") if ($self->IsMemberOf("admin"));
   return(undef);
}

1;
