package tssc::location;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Location ID',
                dataobjattr   =>'locationm1.location'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Location name',
                ignorecase    =>1,
                dataobjattr   =>'locationm1.location_name'),

      new kernel::Field::Text(
                name          =>'company',
                label         =>'Company',
                ignorecase    =>1,
                dataobjattr   =>'locationm1.company'),

      new kernel::Field::Text(
                name          =>'address1',
                htmlwidth     =>'200px',
                label         =>'Street address',
                dataobjattr   =>'locationm1.address'),

      new kernel::Field::Select(
                name          =>'country',
                htmleditwidth =>'50px',
                label         =>'Country',
                vjointo       =>'base::isocountry',
                vjoinon       =>['country'=>'token'],
                vjoindisp     =>'token',
                dataobjattr   =>'locationm1.country'),

      new kernel::Field::Text(
                name          =>'zipcode',
                label         =>'ZIP Code',
                dataobjattr   =>'locationm1.zip'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                ignorecase    =>1,
                dataobjattr   =>'locationm1.city'),

   );
   $self->setDefaultView(qw(id fullname address1 country location));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/location.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="scadm1.locationm1";
   return($from);
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}




1;
