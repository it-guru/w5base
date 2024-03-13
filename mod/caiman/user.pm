package caiman::user;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->setBase("ou=Employment,o=dtag");
   $self->setLdapQueryPageSize(99);
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                    label    =>'No.'),

      new kernel::Field::Text(     name       =>'tcid',
                                   label      =>'tCID',
                                   size       =>'10',
                                   group      =>'status',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   dataobjattr=>'tCID'),

      new kernel::Field::Id(       name       =>'twrid',
                                   label      =>'WorkRelationID',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   group      =>'status',
                                   sortvalue  =>'asc',
                                   dataobjattr=>'tWrID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     name       =>'uid',
                                   label      =>'UserID (uid)',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   sortvalue  =>'asc',
                                   dataobjattr=>'uid'),

      new kernel::Field::Text(     name       =>'wiwid',
                                   label      =>'WiWid',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   sortvalue  =>'asc',
                                   dataobjattr=>'twiw-uid'),

      new kernel::Field::Text(     name       =>'fullname',
                                   label      =>'Fullname',
                                   searchable =>0,
                                   onRawValue =>sub{
                                      my $self=shift;
                                      my $current=shift;
                                      my $d=$current->{surname};
                                      my $v=$current->{givenname};
                                      $d.=", " if ($d ne "" && $v ne "");
                                      $d.=$v;
                                      $d.=" " if ($d ne "");
                                      if ($current->{email} ne ""){
                                         $d.="($current->{email})";
                                      }
                                      return($d);
                                   },
                                   depend     =>['surname','givenname',
                                   'email']),

      new kernel::Field::Text(     name       =>'surname',
                                   label      =>'Surname',
                                   dataobjattr=>'sn'),

      new kernel::Field::Text(     name       =>'givenname',
                                   label      =>'Givenname',
                                   dataobjattr=>'givenname'),

      new kernel::Field::Boolean(  name       =>'active',
                                   value      =>['false','true'],
                                   label      =>'Aktiv',
                                   dataobjattr=>'tisActive'),

      new kernel::Field::Boolean(  name       =>'primary',
                                   value      =>['false','true'],
                                   label      =>'Primary',
                                   dataobjattr=>'tisPrimary'),

      new kernel::Field::Email(    name       =>'email',
                                   label      =>'E-Mail',
                                   dataobjattr=>'mail'),
                                  
      new kernel::Field::Email(    name       =>'email2',
                                   label      =>'E-Mail (tWRmail)',
                                   htmldetail =>'NotEmpty',
                                   dataobjattr=>'tWRmail'),
                                  
      new kernel::Field::Email(    name       =>'email3',
                                   label  =>'E-Mail (tWRmailAlternateAddress)',
                                   htmldetail =>'NotEmpty',
                                   dataobjattr=>'tWRmailAlternateAddress'),
                                  
      new kernel::Field::TextDrop( name       =>'office',
                                   label      =>'Office',
                                   group      =>'office',
                                   dataobjattr=>'tOuLD'),

      new kernel::Field::Text(     name       =>'shortname',
                                   label      =>'tOuSD',
                                   htmldetail =>'NotEmpty',
                                   group      =>'office',
                                   dataobjattr=>'tOuSD'),

      new kernel::Field::Text(     name       =>'office_state',
                                   group      =>'office',
                                   label      =>'Status',
                                   dataobjattr=>'tWrHrState'),

      new kernel::Field::Text(     name       =>'office_wrs',
                                   group      =>'office',
                                   label      =>'Workrelationship',
                                   htmldetail =>'NotEmpty',
                                   dataobjattr=>'tTypeOfEmployee'),

      new kernel::Field::Text(     name       =>'office_persnum',
                                   group      =>'office',
                                   label      =>'Personal-Number',
                                   dataobjattr=>'employeeNumber'),

      new kernel::Field::Text(     name       =>'office_costcenter',
                                   group      =>'office',
                                   label      =>'CostCenter',
                                   dataobjattr=>'tCostCenterNo'),

      new kernel::Field::Text(     name       =>'office_accarea',
                                   group      =>'office',
                                   label      =>'Accounting Area',
                                   dataobjattr=>'tCostCenterAccountingArea'),

      new kernel::Field::Text(     name       =>'office_sisnumber',
                                   group      =>'office',
                                   label      =>'SIS Number',
                                   dataobjattr=>'tTSISnumber'),

      #new kernel::Field::Phonenumber(name     =>'office_phone',
      #                             group      =>'office',
      #                             label      =>'Phonenumber',
      #                             dataobjattr=>'telephoneNumber'),

      #new kernel::Field::Phonenumber(name     =>'office_mobile',
      #                             group      =>'office',
      #                             label      =>'Mobile-Phonenumber',
      #                             dataobjattr=>'mobile'),

      #new kernel::Field::Phonenumber(name     =>'office_facsimile',
      #                             group      =>'office',
      #                             label      =>'FAX-Number',
      #                             dataobjattr=>'facsimileTelephoneNumber'),

      #new kernel::Field::Text(     name       =>'office_room',
      #                             group      =>'office',
      #                             label      =>'Room',
      #                             dataobjattr=>'roomNumber'),

      new kernel::Field::Text(     name       =>'office_organisation',
                                   group      =>'office',
                                   label      =>'Organisation',
                                   dataobjattr=>'toLD'),

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

      # f�llt weg und wird (vermutlich) durch torgoid ersetzt
      #
      #new kernel::Field::Interface(name       =>'toucid',
      #                             group      =>'office',
      #                             label      =>'tOuCID',
      #                             dataobjattr=>'tOuCID'),

      new kernel::Field::Text(     name       =>'torgoid',
                                   group      =>'office',
                                   label      =>'tOrgOID',
                                   dataobjattr=>'tOrgOID'),

      # war auch in CIAM nicht freigegeben
      #
      #new kernel::Field::Boolean(  name       =>'isVSNFD',
      #                             group      =>'status',
      #                             label      =>'is VS-NfD instructed',
      #                             dataobjattr=>'tVsNfd'),

      new kernel::Field::Text(     name       =>'country',
                                   group      =>'status',
                                   label      =>'Country',
                                   dataobjattr=>'C'),

      new kernel::Field::Text(     name       =>'sex',
                                   group      =>'status',
                                   label      =>'Sex',
                                   dataobjattr=>'tSex'),

      new kernel::Field::Date(     name       =>'demployment',
                                   group      =>'status',
                                   dayonly    =>1,
                                   searchable =>0,
                                   label      =>'date of employment',
                                   dataobjattr=>'tDateOfEmployment'),

      #new kernel::Field::Date(     name       =>'ddismissal',
      #                             group      =>'status',
      #                             dayonly    =>1,
      #                             searchable =>0,
      #                             label      =>'date of dismissal',
      #                             dataobjattr=>'tDateOfDismissal'),

      #new kernel::Field::Text(     name       =>'lang',
      #                             group      =>'status',
      #                             label      =>'preferrredLanguage',
      #                             dataobjattr=>'preferredLanguage'),

   );
   $self->setDefaultView(qw(id wrid uid surname givenname email));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"caiman"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{tsciam}));
   return(0);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


#sub SetFilter
#{
#   my $self=shift;
#
#   my @bk=$self->SUPER::SetFilter(@_);
#   $self->Limit(1000,0,1);     # keine gute Idee - das wuerde vermutlich
#                               # das Paging durcheinander bringen
#   return(@bk);
#}



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

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_active"))){
     Query->Param("search_active"=>"\"".$self->T("boolean.true")."\"");
   }
   if (!defined(Query->Param("search_primary"))){
     Query->Param("search_primary"=>"\"".$self->T("boolean.true")."\"");
   }
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}



1;
