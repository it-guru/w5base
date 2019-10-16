package tsadsEMEA1::user;
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

# Attribute im ADS LDAP:
# accountExpires             lastLogoff                    postalCode                            
# badPasswordTime            lastLogon                     primaryGroupID
# badPwdCount                lastLogonTimestamp            proxyAddresses
# c                          legacyExchangeDN              publicDelegatesBL
# cn                         lockoutTime                   pwdLastSet
# co                         logonCount                  replicatedObjectVersion
# codePage                   logonHours                    replicationSignature
# company                    mail                          result
# countryCode                mailNickname                  roomNumber
# department                 mAPIRecipient                 sAMAccountName
# description                mDBOverHardQuotaLimit         sAMAccountType
# displayName                mDBOverQuotaLimit             search
# distinguishedName          mDBStorageQuota               showInAddressBook
# division                   mDBUseDefaults                sIDHistory
# dLMemDefault               mobile                        sn
# dSCorePropagationData      msExchAssistantName           st
# employeeID                 msExchAuditDelegate           streetAddress
# employeeType               msExchBlockedSendersHash      submissionContLength
# extensionAttribute11       msExchHomeServerName          tcDS-SyncAttribute01
# extensionAttribute15       msExchMailboxAuditEnable      tcDS-SyncAttribute02
# extensionAttribute4        tcDS-SyncAttribute03
# extensionAttribute6        tcDS-SyncAttribute04
# extensionData              msExchMailboxGuid             tcDS-SyncAttribute05
# facsimileTelephoneNumber   tcDS-SyncAttribute06
# givenName                  msExchOmaAdminWirelessEnable  telephoneNumber
# homeDirectory              msExchOWAPolicy               userAccountControl
# homeDrive                  msExchPoliciesExcluded        userCertificate
# homeMDB                    msExchRBACPolicyLink          userPrincipalName
# instanceType               msExchRecipientDisplayType    uSNChanged
# l                          msExchRecipientTypeDetails    uSNCreated
# msTSExpireDate             msExchSafeSendersHash         whenChanged
# msTSLicenseVersion         msExchTextMessagingState      whenCreated          
# msTSLicenseVersion2        msExchUMDtmfMap
# msTSLicenseVersion3        msExchUserAccountControl
# msTSManagingLS             msExchUserCulture
# name                       msExchVersion
# objectCategory             msExchWhenMailboxCreated
# objectClass                msRTCSIP-OriginatorSid
# objectGUID                                     
# objectSid                                      


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->setBase("OU=Users,OU=DE,DC=emea1,DC=cds,DC=t-internal,DC=com");
   $self->AddFields(
      new kernel::Field::Linenumber(name     =>'linenumber',
                                    label      =>'No.'),

      new kernel::Field::Id(       name       =>'id',
                                   label      =>'ObjectID',
                                   group      =>'source',
                                   align      =>'left',
                                   dataobjattr=>'distinguishedName'),

      new kernel::Field::Text(     name       =>'fullname',
                                   label      =>'Fullname',
                                   searchable =>0,
                                   htmldetail =>0,
                                   dataobjattr=>'displayName'),

      new kernel::Field::Text(     name       =>'surname',
                                   label      =>'Surname',
                                   dataobjattr=>'sn'),

      new kernel::Field::Text(     name       =>'givenname',
                                   label      =>'Givenname',
                                   dataobjattr=>'givenName'),

      new kernel::Field::Email(    name       =>'email',
                                   label      =>'E-Mail',
                                   dataobjattr=>'mail'),

      new kernel::Field::Text(     name       =>'addresses',
                                   group      =>'addresses',
                                   label      =>'Adresses',
                                   dataobjattr=>'proxyAddresses'),

      new kernel::Field::Text(     name       =>'company',
                                   label      =>'Company',
                                   dataobjattr=>'company'),

      new kernel::Field::Text(     name       =>'division',
                                   label      =>'Division',
                                   dataobjattr=>'division'),

      new kernel::Field::Text(     name       =>'department',
                                   label      =>'Department',
                                   dataobjattr=>'department'),

      new kernel::Field::Text(     name       =>'location',
                                   label      =>'Location',
                                   dataobjattr=>'l'),

      new kernel::Field::Text(     name       =>'room',
                                   label      =>'room number',
                                   dataobjattr=>'roomNumber'),

      new kernel::Field::Text(     name       =>'groups',
                                   group      =>'groups',
                                   label      =>'Groups',
                                   dataobjattr=>'memberOf'),

      new kernel::Field::Textarea( name       =>'usercert',
                                   group      =>'usercert',
                                   searchable =>0,
                                   htmldetail =>0,
                                   label      =>'userCertificate',
                                   dataobjattr=>'userCertificate'),

      new kernel::Field::Text(     name       =>'employeeID',
                                   label      =>'employeeID',
                                   searchable =>0,
                                   group      =>'source',
                                   dataobjattr=>'employeeID'),

      new kernel::Field::Text(     name       =>'sAMAccountName',
                                   label      =>'sAMAccountName',
                                   searchable =>0,
                                   group      =>'source',
                                   dataobjattr=>'sAMAccountName'),


   );
   $self->setDefaultView(qw(surname givenname email company 
                            division department location room));
   return($self);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","addresses","groups","usercert","source");
}




sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tsadsEMEA1"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{tsadsEMEA1}));
   return(0);
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
