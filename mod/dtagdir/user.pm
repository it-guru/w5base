package dtagdir::user;
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
use kernel::DataObj::LDAP;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"dtagdir"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->setBase("");
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                    label      =>'No.'),

      new kernel::Field::Text(     name       =>'cn',
                                   label      =>'CommonName',
                                   dataobjattr=>'cn'),

      new kernel::Field::Id(       name       =>'id',
                                   label      =>'PersonalID',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   dataobjattr=>'mail'),

      new kernel::Field::Text(     name       =>'fullname',
                                   label      =>'Fullname',
                                   dataobjattr=>'cn'),

      new kernel::Field::Text(     name       =>'surname',
                                   label      =>'Surname',
                                   size       =>'10',
                                   dataobjattr=>'sn'),

      new kernel::Field::Text(     name       =>'givenname',
                                   label      =>'Givenname',
                                   size       =>'10',
                                   dataobjattr=>'givenName'),

      new kernel::Field::Email(    name       =>'email',
                                   label      =>'E-Mail',
                                   size       =>'10',
                                   dataobjattr=>'mail'),
                                  
      new kernel::Field::Email(    name       =>'email2',
                                   label      =>'E-Mail2',
                                   size       =>'10',
                                   dataobjattr=>'mailAlternateAddress'),
                                  
      new kernel::Field::Text(     name       =>'org_name',
                                   group      =>'office',
                                   label      =>'Organisation',
                                   dataobjattr=>'collectiveOrganizationName'),

      new kernel::Field::Text(     name       =>'office_street',
                                   searchable =>0,
                                   group      =>'office',
                                   label      =>'Street',
                                   dataobjattr=>'street'),

      new kernel::Field::Text(     name       =>'office_zipcode',
                                   searchable =>0,
                                   group      =>'office',
                                   label      =>'ZIP-Code',
                                   dataobjattr=>'postalCode'),

      new kernel::Field::Text(     name       =>'office_location',
                                   group      =>'office',
                                   label      =>'Location',
                                   dataobjattr=>'l'),

      new kernel::Field::Text(     name       =>'org_department',
                                   group      =>'office',
                                   label      =>'Department',
                                   dataobjattr=>'departmentNumber'),

      new kernel::Field::Text(     name       =>'office_phone',
                                   searchable =>0,
                                   group      =>'office',
                                   label      =>'Phonenumber',
                                   dataobjattr=>'telephoneNumber'),

      new kernel::Field::Text(     name       =>'office_facsimile',
                                   searchable =>0,
                                   group      =>'office',
                                   label      =>'FAX-Number',
                                   dataobjattr=>'facsimileTelephoneNumber'),

      new kernel::Field::Text(     name       =>'office_house',
                                   searchable =>0,
                                   group      =>'office',
                                   label      =>'House',
                                   dataobjattr=>'houseIdentifier'),

      new kernel::Field::Text(     name       =>'office_room',
                                   searchable =>0,
                                   group      =>'office',
                                   label      =>'Room',
                                   dataobjattr=>'roomNumber'),

      new kernel::Field::Text(     name       =>'org_id',
                                   group      =>'id',
                                   label      =>'OrgID',
                                   dataobjattr=>'collectiveDtagOrganizationOZ'),

      new kernel::Field::Text(     name       =>'orge_id',
                                   group      =>'id',
                                   label      =>'OrgeID',
                                   dataobjattr=>'collectiveDtagOrgeOZ'),

#
# dtaghrportaluniqueID
# dtagDatenQuelle
# dtagsaphirReferenzID
# Department-Number
# dtagResourtDescription
# collectivedtagPillar
# dtagSex
#


   );
   $self->setDefaultView(qw(id uid surname givenname email));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
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
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default office id));
}




1;
