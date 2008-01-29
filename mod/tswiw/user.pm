package tswiw::user;
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
   
   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tswiw"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->setBase("o=People,o=WiW");
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                    label      =>'No.'),

      new kernel::Field::Id(       name       =>'id',
                                   label      =>'PersonalID',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   dataobjattr=>'wiwid'),

      new kernel::Field::Text(     name       =>'uid',
                                   label      =>'UserID',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   dataobjattr=>'uid'),

      new kernel::Field::Text(     name       =>'surname',
                                   label      =>'Surname',
                                   size       =>'10',
                                   dataobjattr=>'sn'),

      new kernel::Field::Text(     name       =>'givenname',
                                   label      =>'Givenname',
                                   size       =>'10',
                                   dataobjattr=>'givenname'),

      new kernel::Field::Email(    name       =>'email',
                                   label      =>'E-Mail',
                                   size       =>'10',
                                   dataobjattr=>'mail'),
                                  
      new kernel::Field::Email(    name       =>'email2',
                                   label      =>'E-Mail2',
                                   size       =>'10',
                                   dataobjattr=>'MailAlternateAddress'),
                                  
      new kernel::Field::TextDrop( name       =>'office',
                                   label      =>'Office',
                                   group      =>'office',
                                   vjointo    =>'tswiw::orgarea',
                                   vjoinon    =>['touid'=>'touid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::Text(     name       =>'office_phone',
                                   group      =>'office',
                                   label      =>'Phonenumber',
                                   dataobjattr=>'telephoneNumber'),

      new kernel::Field::Text(     name       =>'office_mobile',
                                   group      =>'office',
                                   label      =>'Moible-Phonenumber',
                                   dataobjattr=>'mobileNumber'),

      new kernel::Field::Text(     name       =>'office_facsimile',
                                   group      =>'office',
                                   label      =>'FAX-Number',
                                   dataobjattr=>'facsimileTelephoneNumber'),

      new kernel::Field::Text(     name       =>'office_room',
                                   group      =>'office',
                                   label      =>'Room',
                                   dataobjattr=>'roomNumber'),

      new kernel::Field::Text(     name       =>'office_street',
                                   group      =>'office',
                                   label      =>'Street',
                                   dataobjattr=>'street'),

      new kernel::Field::Text(     name       =>'office_zipcode',
                                   group      =>'office',
                                   label      =>'ZIP-Code',
                                   dataobjattr=>'postalCode'),

      new kernel::Field::Text(     name       =>'office_location',
                                   group      =>'office',
                                   label      =>'Location',
                                   dataobjattr=>'l'),

      new kernel::Field::Text(     name       =>'touid',
                                   group      =>'office',
                                   label      =>'tOuID',
                                   dataobjattr=>'tOuID'),

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


1;
