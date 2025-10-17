package ewu2::contact;
#  W5Base Framework
#  Copyright (C) 118  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>"DevLabContactID",
                group         =>'source',
                dataobjattr   =>"\"CONTACTS\".\"ID\""),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmlwidth     =>'250',
                searchable    =>0,
                htmldetail    =>0,
                nowrap        =>1,
                onRawValue    =>\&mkFullname,
                depend        =>['surname','email','givenname','deleted']),

      new kernel::Field::Text(
                name          =>'name',
                ignorecase    =>1,
                label         =>"Name",
                dataobjattr   =>"\"CONTACTS\".\"UNAME\""),

      new kernel::Field::Text(
                name          =>'givenname',
                ignorecase    =>1,
                label         =>"Givenname",
                dataobjattr   =>"\"CONTACTS\".\"VORNAME\""),

      new kernel::Field::Text(
                name          =>'surname',
                ignorecase    =>1,
                label         =>"Surname",
                dataobjattr   =>"\"CONTACTS\".\"NACHNAME\""),

      new kernel::Field::Boolean(
                name          =>'deleted',
                htmldetail    =>0,
                label         =>"marked as delete",
                dataobjattr   =>"decode(\"CONTACTS\".\"DELETED_AT\",NULL,0,1)"),

      new kernel::Field::Email(
                name          =>'email',
                ignorecase    =>1,
                label         =>"E-Mail",
                dataobjattr   =>"\"CONTACTS\".\"EMAIL\""),

      new kernel::Field::Email(
                name          =>'email2',
                ignorecase    =>1,
                htmldetail    =>'NotEmpty',
                label         =>"E-Mail 2",
                dataobjattr   =>"\"CONTACTS\".\"EMAIL2\""),

      new kernel::Field::Text(
                name          =>'phone',
                label         =>"Phonenumber",
                dataobjattr   =>"\"CONTACTS\".\"TELEFON\""),

      new kernel::Field::Text(
                name          =>'phone2',
                label         =>"Phonenumber 2",
                dataobjattr   =>"\"CONTACTS\".\"TELEFON2\""),

      new kernel::Field::Text(
                name          =>'abteilung',
                label         =>"Abteilung",
                dataobjattr   =>"\"CONTACTS\".\"ABTEILUNG\""),

      new kernel::Field::Text(
                name          =>'firma',
                label         =>"Firma",
                dataobjattr   =>"\"CONTACTS\".\"FIRMA\""),

      new kernel::Field::Text(
                name          =>'type',
                label         =>"Type",
                dataobjattr   =>"\"CONTACTS\".\"TYPE\""),

      new kernel::Field::Textarea(
                name          =>'text',
                label         =>"Text",
                dataobjattr   =>"\"CONTACTS\".\"TEXT\""),

      new kernel::Field::Text(
                name          =>'lockversion',
                htmldetail    =>0,
                label         =>"Lock Version",
                dataobjattr   =>"\"CONTACTS\".\"LOCK_VERSION\""),

      new kernel::Field::Text(
                name          =>'ldapdn',
                label         =>"Ldap Dn",
                dataobjattr   =>"\"CONTACTS\".\"LDAP_DN\""),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>"Creation-Date",
                timezone      =>'CET',
                group         =>'source',
                dataobjattr   =>"\"CONTACTS\".\"CREATED_AT\""),

      new kernel::Field::CDate(
                name          =>'mdate',
                label         =>"Modification-Date",
                timezone      =>'CET',
                group         =>'source',
                dataobjattr   =>"\"CONTACTS\".\"UPDATED_AT\""),

      new kernel::Field::Date(
                name          =>'ddeletedat',
                group         =>'source',
                timezone      =>'CET',
                label         =>"Deletion-Date",
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"CONTACTS\".\"DELETED_AT\""),

   );
   $self->{use_distinct}=0;
   #$self->{workflowlink}={ };
   $self->setDefaultView(qw(fullname email phone));
   $self->setWorktable("\"CONTACTS\"");
   return($self);
}


sub mkFullname
{
   my $self=shift;
   my $current=shift;

   my $fullname="";
   my $name=$current->{surname};
   if ($name ne ""){
      $name=lc($name);
      $name=~tr/ÄÖÜ/äöü/;
      $name=~s/^([a-z])/uc($1)/ge;
      $name=~s/[\s-]([a-z])/uc($1)/ge;
   }
   $fullname.=$name;
   $fullname.=", " if ($fullname ne "" && $current->{givenname} ne "");
   $fullname.=$current->{givenname};
   if ($current->{email} ne ""){
      $fullname.=" " if ($fullname ne "");
      $fullname.="(".lc($current->{email}).")";
   }
   if ($current->{deleted}){
      $fullname.="[0]";
   }

   return($fullname);
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"ewu2"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}



sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  ""!".$self->T("CI-Status(6)","base::cistatus").""");
#   }
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }

}




sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}






sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}


1;

