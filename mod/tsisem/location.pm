package tsisem::location;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   $self->{use_distinct}=0;
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'ObjectID',
                dataobjattr   =>'cms_location.objectid'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                label         =>'Location name',
                dataobjattr   =>'cms_location.name'),

      new kernel::Field::Text(
                name          =>'address1',
                htmlwidth     =>'200px',
                label         =>'Street address',
                dataobjattr   =>'cms_location.street'),

      new kernel::Field::Select(
                name          =>'country',
                htmleditwidth =>'50px',
                label         =>'Country',
                vjointo       =>'base::isocountry',
                vjoinon       =>['country'=>'token'],
                vjoindisp     =>'token',
                dataobjattr   =>'lower(cms_location.country_isocode)'),

      new kernel::Field::Text(
                name          =>'zipcode',
                label         =>'ZIP Code',
                dataobjattr   =>'cms_location.postalcode'),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                dataobjattr   =>'cms_location.city'),


      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'cms_location.createtime'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'cms_location.lastmodifiedtime'),
   );
   $self->setDefaultView(qw(zipcode location address1 name));
   return($self);
}

sub mkFullname
{
   my $self=shift;
   my $current=shift;

   my $fullname="";
   my $name=$current->{surname};
   $name=~s/^\s*[\.\*,\s\-]+\s*$//;
   $fullname.=$name;
   my $givenname=$current->{givenname};
   $givenname=~s/^\s*[\.\*,\s\-]+\s*$//;
   $fullname.=", " if ($fullname ne "" && $givenname ne "");
   $fullname.=$givenname;
   if ($current->{email} ne ""){
      $fullname.=" " if ($fullname ne "");
      $fullname.="(".lc($current->{email}).")";
   }
   else{
      if ($current->{distname} ne ""){
         $fullname.=" " if ($fullname ne "");
         $fullname.="(".lc($current->{distname}).")";
      }
   }

   return($fullname);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header name default source));
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsisem"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/location.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="cms_location";
   return($from);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   
   return("ALL") if ($self->IsMemberOf("admin"));
   return("default","source","header");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
