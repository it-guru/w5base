package tsisem::user;
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
                dataobjattr   =>'cms_person.objectid'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmlwidth     =>'250',
                searchable    =>0,
                onRawValue    =>\&mkFullname,
                depend        =>['surname','email','givenname','distname']),

      new kernel::Field::Text(
                name          =>'distname',
                label         =>'distinguished name',
                searchable    =>0,
                dataobjattr   =>'cms_person.distinguished_name'),

      new kernel::Field::Text(
                name          =>'title',
                label         =>'Title',
                dataobjattr   =>'cms_person.title'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'cms_person.name'),

      new kernel::Field::Text(
                name          =>'givenname',
                label         =>'Givenname',
                ignorecase    =>1,
                dataobjattr   =>'cms_person.givenname'),

      new kernel::Field::Text(
                name          =>'surname',
                label         =>'Surname',
                ignorecase    =>1,
                dataobjattr   =>'cms_person.surname'),

      new kernel::Field::Text(
                name          =>'preferredmedium',
                group         =>'contact',
                label         =>'Preferred contact medium',
                searchable    =>0,
                dataobjattr   =>'cms_person.preferredmedium'),

      new kernel::Field::Text(
                name          =>'email',
                group         =>'contact',
                label         =>'E-Mail',
                ignorecase    =>1,
                dataobjattr   =>'cms_person.primaryemail'),

      new kernel::Field::Phonenumber(
                name          =>'office_phone',
                group         =>'contact',
                label         =>'Phonenumber',
                dataobjattr   =>'cms_person.officephonenumber'),

      new kernel::Field::Phonenumber(
                name          =>'office_mobile',
                group         =>'contact',
                label         =>'Mobile-Phonenumber',
                dataobjattr   =>'cms_person.mobilephonenumber'),

      new kernel::Field::Phonenumber(
                name          =>'office_facsimile',
                group         =>'contact',
                label         =>'FAX-Number',
                dataobjattr   =>'cms_person.faxnumber'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'cms_person.createtime'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'cms_person.lastmodifiedtime'),
   );
   $self->setDefaultView(qw(fullname surname givenname email));
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
   return(qw(header name default contact source));
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
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="cms_person";
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
