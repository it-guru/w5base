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

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     name       =>'uid',
                                   label      =>'UserID',
                                   size       =>'10',
                                   htmlwidth  =>'130',
                                   align      =>'left',
                                   sortvalue  =>'asc',
                                   dataobjattr=>'uid'),

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
                                   label      =>'E-Mail (alternate)',
                                   size       =>'10',
                                   dataobjattr=>'MailAlternateAddress'),
                                  
      new kernel::Field::Email(    name       =>'email3',
                                   label      =>'E-Mail (routing)',
                                   size       =>'10',
                                   dataobjattr=>'MailRoutingAddress'),
                                  
      new kernel::Field::TextDrop( name       =>'office',
                                   label      =>'Office',
                                   group      =>'office',
                                   vjointo    =>'tswiw::orgarea',
                                   vjoinon    =>['touid'=>'touid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::Text(     name       =>'office_state',
                                   group      =>'office',
                                   label      =>'Status',
                                   dataobjattr=>'organizationalstatus'),

      new kernel::Field::Text(     name       =>'office_wrs',
                                   group      =>'office',
                                   label      =>'Workrelationship',
                                   dataobjattr=>'tTypeOfWorkrelationship'),

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

      new kernel::Field::Phonenumber(name     =>'office_phone',
                                   group      =>'office',
                                   label      =>'Phonenumber',
                                   dataobjattr=>'telephoneNumber'),

      new kernel::Field::Phonenumber(name     =>'office_mobile',
                                   group      =>'office',
                                   label      =>'Moible-Phonenumber',
                                   dataobjattr=>'mobile'),

      new kernel::Field::Phonenumber(name     =>'office_facsimile',
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

      new kernel::Field::Boolean(  name       =>'isVSNFD',
                                   group      =>'status',
                                   label      =>'is VS-NfD instructed',
                                   dataobjattr=>'tVsNfd'),

      new kernel::Field::Text(     name       =>'country',
                                   group      =>'status',
                                   label      =>'Country',
                                   dataobjattr=>'C'),

      new kernel::Field::Text(     name       =>'office_address',
                                   group      =>'status',
                                   label      =>'postalAddress',
                                   dataobjattr=>'postalAddress'),

      new kernel::Field::Text(     name       =>'office_organisation',
                                   group      =>'status',
                                   label      =>'Organisation',
                                   dataobjattr=>'o'),

      new kernel::Field::Text(     name       =>'office_orgunit',
                                   group      =>'status',
                                   label      =>'Orgunit',
                                   dataobjattr=>'ou'),

      new kernel::Field::Text(     name       =>'sex',
                                   group      =>'status',
                                   label      =>'Sex',
                                   dataobjattr=>'tSex'),

      new kernel::Field::Text(     name       =>'lang',
                                   group      =>'status',
                                   label      =>'preferrredLanguage',
                                   dataobjattr=>'preferredLanguage'),

      new kernel::Field::Text(     name       =>'winlogon',
                                   group      =>'status',
                                   label      =>'Window Domain Logon',
                                   dataobjattr=>'tADlogin'),

      new kernel::Field::Text(     name       =>'photoURL',
                                   group      =>'status',
                                   label      =>'photoURL',
                                   dataobjattr=>'tPhotoURL'),


   );
   $self->setDefaultView(qw(id uid surname givenname email));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tswiw"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{tswiw}));
   return(0);
}



sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions());
   #return($self->SUPER::getValidWebFunctions(),qw(ImportUser));
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


#sub ImportUser
#{
#   my $self=shift;
#
#   my $importname=Query->Param("importname");
#   if (Query->Param("DOIT")){
#      if ($self->Import({importname=>$importname})){
#         Query->Delete("importname");
#         $self->LastMsg(OK,"user has been successfuly imported");
#      }
#      Query->Delete("DOIT");
#   }
#
#
#   print $self->HttpHeader("text/html");
#   print $self->HtmlHeader(style=>['default.css','work.css',
#                                   'kernel.App.Web.css'],
#                           static=>{importname=>$importname},
#                           body=>1,form=>1,
#                           title=>"WhoIsWho Import");
#   print $self->getParsedTemplate("tmpl/minitool.user.import",{});
#   print $self->HtmlBottom(body=>1,form=>1);
#}
#
#
########################################################################
## this is a nativ call, witch can be used by any other module to
## import WhoIsWho Users in W5Base by specifing WhoIsWhoID oder email.
## It returns undef on fail and the id of the new user on success
##
#sub GetW5BaseUserID
#{
#   my $self=shift;
#   my $importname=shift;
#
#   return(undef) if ($importname eq "");
#   if (ref($importname)){
#      return(undef);
#   }
#   my $flt={posix=>\$importname};
#   if ($importname=~m/\@/){
#      $flt={emails=>\$importname};
#   }
#   my $user=getModuleObject($self->Config,"base::user");
#   $user->SetFilter($flt);
#   my ($userrec,$msg)=$user->getOnlyFirst(qw(fullname posix userid));
#   if (defined($userrec)){
#      return($userrec->{userid});
#   }
#   else{
#      if ($importname=~m/\@/){
#         $self->ResetFilter();
#         $self->SetFilter([{email=>$importname},
#                           {email2=>$importname},
#                           {email3=>$importname}]);
#         my ($wiwrec,$msg)=$self->getOnlyFirst(qw(uid));
#         if (defined($wiwrec) && $wiwrec->{uid} ne ""){
#            my $uid=$wiwrec->{uid};
#            if (ref($uid) eq "ARRAY"){
#               @$uid=grep(!/[A-Z]/,@$uid);
#               $uid=$uid->[0];
#            }
#            return($self->GetW5BaseUserID($uid));
#         }
#      }
#      return($self->Import({importname=>$importname,quiet=>1}));
#   }
#   return(undef);
#}
#
#
#sub Import
#{
#   my $self=shift;
#   my $param=shift;
#
#   my $flt; 
#   if ($param->{importname} ne ""){
#      if ($param->{importname}=~m/\@/){
#         $param->{email}=$param->{importname};
#      }
#      else{
#         $param->{userid}=$param->{importname};
#      }
#   }
#   my $q="";
#   if ($param->{userid} ne ""){
#      my $id=$param->{userid};
#      $id=~s/[\s\*\?]//g;
#      $flt={uid=>\$id};
#      $q="userid=$id";
#   } 
#   if ($param->{email} ne ""){
#      my $email=$param->{email};
#      $email=~s/[\s\*\?]//g;
#      $flt=[{email=>\$email},{email2=>\$email}];
#      $q="email=$email";
#   } 
#   if (!defined($flt)){
#      $self->LastMsg(ERROR,"no acceptable filter");
#      return(undef);
#   }
#   $self->ResetFilter();
#   $self->SetFilter($flt);
#   my @l=$self->getHashList(qw(uid surname givenname email));
#   if ($#l==-1){
#      if (!$param->{quiet}){
#         $self->LastMsg(ERROR,"contact '$q' not found in ".
#                              "WhoIsWho while Import");
#      }
#      return(undef);
#   }
#   if ($#l>0){
#      if (!$param->{quiet}){
#         $self->LastMsg(ERROR,"contact not unique in WhoIsWho");
#      }
#      return(undef);
#   }
#
#
#   my $wiwrec=$l[0];
#   if ($wiwrec->{surname}=~m/_duplicate_/i){
#      if (!$param->{quiet}){
#         $self->LastMsg(ERROR,
#               "_duplicate_ are not allowed to import from WhoIsWho");
#      }
#      return(undef);
#   }
#   my $user=getModuleObject($self->Config,"base::user");
#   $user->SetFilter([{'email'=>$wiwrec->{email}},{posix=>$wiwrec->{uid}}]);
#   my ($userrec,$msg)=$user->getOnlyFirst(qw(ALL));
#   my $identifyby=undef;
#   if (defined($userrec)){
#      if ($userrec->{cistatusid}==4){
#         return($userrec->{userid});
#      }
#      $identifyby=$user->ValidatedUpdateRecord($userrec,{cistatusid=>4},
#                                               {userid=>\$userrec->{userid}});
#   }
#   else{
#      my $uidlist=$wiwrec->{uid};
#      $uidlist=[$uidlist] if (ref($uidlist) ne "ARRAY");
#      my @posix=grep(!/^[A-Z]{1,3}\d+$/,@{$uidlist});
#      my $posix=$posix[0];
#      $identifyby=$user->ValidatedInsertRecord({
#                                     cistatusid=>4,
#                                     usertyp=>'extern',
#                                     allowifupdate=>1,
#                                     surname=>$wiwrec->{surname},
#                                     givenname=>$wiwrec->{givenname},
#                                     posix=>$posix,
#                                     email=>$wiwrec->{email}});
#   }
#   if (defined($identifyby) && $identifyby!=0){
#      $user->ResetFilter();
#      $user->SetFilter({'userid'=>\$identifyby});
#      my ($rec,$msg)=$user->getOnlyFirst(qw(ALL));
#      if (defined($rec)){
#         my $qc=getModuleObject($self->Config,"base::qrule");
#         $qc->setParent($user);
#         $qc->nativQualityCheck($user->getQualityCheckCompat($rec),$rec);
#      }
#   }
#   return($identifyby);
#}


1;
