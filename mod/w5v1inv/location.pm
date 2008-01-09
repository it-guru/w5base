package w5v1inv::location;
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
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->AddFields(
      new kernel::Field::Id(      name    =>'id',
                                  label   =>'W5BaseID',
                                  size    =>'10',
                                  dataobjattr  =>'sysloc.id'),
      new kernel::Field::Text(    name    =>'name',
                                  label   =>'Callname',
                                  size    =>'20',
                                  dataobjattr  =>'sysloc.callname'),
      new kernel::Field::Text(    name    =>'address1',
                                  label   =>'Strasse',
                                  size    =>'20',
                                  dataobjattr  =>'sysloc.strasse'),
      new kernel::Field::Text(    name    =>'zipcode',
                                  label   =>'PLZ',
                                  size    =>'20',
                                  dataobjattr  =>'sysloc.plz'),
      new kernel::Field::Text(    name    =>'location',
                                  label   =>'Ort',
                                  size    =>'20',
                                  dataobjattr  =>'sysloc.ort'),
   );
   $self->setDefaultView(qw(id name));
   return($self);
}

sub SkinBase
{
   return("w5v1inv");
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(ALL));

}


sub getSqlFrom
{
   my $self=shift;

   return("sysloc");
}


1;
