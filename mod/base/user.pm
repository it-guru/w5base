package base::user;
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
use kernel::App::Web::InterviewLink;
use kernel::DataObj::DB;
use kernel::Field;
use DateTime::TimeZone;
use base::workflow::mailsend;
use base::lib::RightsOverview;
use kernel::CIStatusTools;
use kernel::MandatorDataACL;

@ISA=qw(kernel::App::Web::Listedit 
        kernel::DataObj::DB 
        kernel::App::Web::InterviewLink
        kernel::CIStatusTools kernel::MandatorDataACL
        base::lib::RightsOverview);



sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}={
      update=>[
         'local'
      ]
   };

   my $UserQueryAbbortFocus=$self->Config->Param("UserQueryAbbortCountFocus");

   if ($UserQueryAbbortFocus<4){
      $UserQueryAbbortFocus="4";
   }
   if ($UserQueryAbbortFocus>24){
      $UserQueryAbbortFocus="24";
   }

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Contact(
                name          =>'fullname',
                htmlwidth     =>'280',
                group         =>'default',
                readonly      =>1,
                prepRawValue  =>sub{
                   my $self=shift;
                   my $d=shift;
                   my $current=shift;
                   my $secstate=$self->getParent->getCurrentSecState();
                   if ($W5V2::OperationContext eq "WebFrontend"){
                      if ($secstate<2){
                         my $userid=$self->getParent->getCurrentUserId();
                         if (!defined($userid) ||
                              $current->{userid}!=$userid){
                            sub ureplEmail
                            {
                               my $e=$_[0];
                               $e=~s/[a-z]/?/g;
                               return("($e)");
                            } 
                            $d=~s/\((.*\@.*)\)/ureplEmail($1)/e; 
                         }
                      }
                   }
                   return($d);
                },
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;
                   return(0) if ($mode eq "HtmlDetail" && 
                                 !defined($param{current}));
                   return(1);
                },
                vjoinon       =>'userid',
                label         =>'Fullname',
                dataobjattr   =>'contact.fullname'),

      new kernel::Field::Text(
                name          =>'phonename',
                htmlwidth     =>'280',
                group         =>'default',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>['surname','givenname',
                                 'office_phone','office_mobile'],
                label         =>'Phonename',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $secstate=$self->getParent->getCurrentSecState();
                   my $d=$current->{surname};
                   $d.=", " if ($d ne "" && $current->{givenname} ne "");
                   $d.=$current->{givenname} if ($current->{givenname} ne "");
                   if ($secstate>1){
                      $d.="\n" if ($d ne "" && $current->{office_phone} ne "");
                      if ($current->{office_phone} ne ""){
                         $d.=$current->{office_phone};
                      }
                      $d.="\n" if ($d ne "" && $current->{office_mobile} ne "");
                      if ($current->{office_mobile} ne ""){
                         $d.=$current->{office_mobile};
                      }
                   }
                   return($d);
                }),

      new kernel::Field::Text(
                name          =>'purename',
                htmlwidth     =>'280',
                group         =>'default',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>['surname','givenname'],
                label         =>'pure name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $secstate=$self->getParent->getCurrentSecState();
                   my $d=$current->{surname};
                   $d.=", " if ($d ne "" && $current->{givenname} ne "");
                   $d.=$current->{givenname} if ($current->{givenname} ne "");
                   return($d);
                }),


      new kernel::Field::Select(
                name          =>'usertyp',
                label         =>'Usertype',
                selectfix     =>1,
                jsonchanged   =>\&getOnChangedScript,
                htmleditwidth =>'100px',
                default       =>'extern',
                value         =>[qw(extern service user function genericAPI)],
                dataobjattr   =>'contact.usertyp'),

      new kernel::Field::Link(
                name          =>'usertypid',
                label         =>'nativ Usertyp',
                dataobjattr   =>'contact.usertyp'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                explore       =>100,
                group         =>['default','admcomments'],
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0) if ($self->getParent->IsMemberOf("admin"));
                   return(0) if (defined($rec) && 
                                 in_array([qw(3 4 5 )],$rec->{cistatusid}) &&
                                 $self->getParent->IsMemberOf(
                                  $rec->{managedbyid},["RContactAdmin"],
                                  "down"));
                   return(1) if (defined($rec) && 
                                 $rec->{cistatusid}>2 &&
                                 !$self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                label         =>'CI-State',
                depend        =>['managedbyid'],
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>">0 AND <7"},
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                group         =>'default',
                default       =>'2',
                label         =>'CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Id(
                name          =>'userid',
                label         =>'W5BaseID',
                size          =>'10',
                group         =>'userid',
                readonly      =>1,
                dataobjattr   =>'contact.userid'),

      new kernel::Field::RecordUrl(),
                                  
      new kernel::Field::Select(
                name          =>'salutation',
                label         =>'Salutation',
                searchable    =>0,
                transprefix   =>'SAL.',
                group         =>'default',
                default       =>'',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;
                   my $usertyp=Query->Param("Formated_usertyp");
                   if (defined($param{current}) && 
                       defined($param{current}->{usertyp})){
                      $usertyp=$param{current}->{usertyp};
                   }
                   return(0) if ($usertyp eq "service" ||
                                 $usertyp eq "function" ||
                                 $usertyp eq "genericAPI");
                   return(1);
                },
                htmleditwidth =>'90px',
                value         =>["","f","m"],
                dataobjattr   =>'contact.salutation'),

      new kernel::Field::Text(
                name          =>'givenname',
                depend        =>['usertyp'],
                readonly      =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   if ($current->{usertyp} ne "service"){
                                      return(0);
                                   }
                                   return(1);
                                },
                group         =>'default',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;
                   my $usertyp=Query->Param("Formated_usertyp");
                   if (defined($param{current}) && 
                       defined($param{current}->{usertyp})){
                      $usertyp=$param{current}->{usertyp};
                   }
                   return(0) if ($usertyp eq "service" ||
                                 $usertyp eq "function" ||
                                 $usertyp eq "genericAPI");
                   return(1);
                },
                explore       =>200,
                label         =>'Givenname',
                dataobjattr   =>'contact.givenname'),
                                  
      new kernel::Field::Text(
                name          =>'surname',
                group         =>'default',
                explore       =>300,
                depend        =>['usertyp'],
                readonly      =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   if ($current->{usertyp} ne "function"){
                                      return(0);
                                   }
                                   return(1);
                                },
                label         =>'Surname',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;
                   my $usertyp=Query->Param("Formated_usertyp");
                   if (defined($param{current}) && 
                       defined($param{current}->{usertyp})){
                      $usertyp=$param{current}->{usertyp};
                   }
                   return(0) if ($usertyp eq "service" ||
                                 $usertyp eq "function" ||
                                 $usertyp eq "genericAPI");
                   return(1);
                },
                dataobjattr   =>'contact.surname'),

      new kernel::Field::Text(
                name          =>'contactdesc',
                group         =>'default',
                explore       =>300,
                depend        =>['usertyp'],
                readonly      =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   if ($current->{usertyp} ne "function"){
                                      return(0);
                                   }
                                   return(1);
                                },
                label         =>'contact description',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;
                   my $usertyp=Query->Param("Formated_usertyp");
                   if (defined($param{current}) && 
                       defined($param{current}->{usertyp})){
                      $usertyp=$param{current}->{usertyp};
                   }
                   return(1) if ($usertyp eq "service" ||
                                 $usertyp eq "function" ||
                                 $usertyp eq "genericAPI");
                   return(0);
                },
                dataobjattr   =>'contact.surname'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'primary E-Mail',
                prepRawValue   =>
                   sub{
                      my $self=shift;
                      my $d=shift;
                      my $current=shift;
                      my $secstate=$self->getParent->getCurrentSecState();
                      if ($W5V2::OperationContext ne "QualityCheck" &&
                          $W5V2::OperationContext ne "Enrichment" &&
                          $secstate<2){
                         my $userid=$self->getParent->getCurrentUserId();
                         if (!defined($userid) ||
                              $current->{userid}!=$userid){
                            sub replEmail
                            {
                               my $e=$_[0];
                               $e=~s/[a-z]/?/g;
                               return("$e");
                            } 
                            $d=~s/(.*\@.*)/replEmail($1)/e; 
                         }
                      }
                      return($d);
                   },
                dataobjattr   =>'contact.email'),

      new kernel::Field::SubList(
                name          =>'emails',
                label         =>'E-Mail addresses',
                readonly      =>1,
                group         =>'userid',
                vjointo       =>'base::useremail',
                vjoinbase     =>{'cistatusid'=>'<=5'}, # this is neassary for
                vjoinon       =>['userid'=>'userid'],  # intial logon process!
                vjoindisp     =>['email','cistatus','emailtyp'],
                vjoininhash   =>['id','email','cistatusid','emailtyp']),

      new kernel::Field::SubList(
                name          =>'allemails',
                label         =>'all related E-Mail addresses',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'userid',
                vjointo       =>'base::useremail',
                vjoinon       =>['userid'=>'userid'],  
                vjoindisp     =>['email','cistatus','emailtyp'],
                vjoininhash   =>['id','email','cistatusid','emailtyp']),

      new kernel::Field::Date(
                name          =>'gtcack',
                label         =>'GTC acknowledge date',
                readonly      =>1,
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                group         =>'userro',
                dataobjattr   =>'contact.gtcack'),
                                  
      new kernel::Field::Textarea(
                name          =>'gtctxt',
                label         =>'GTC text',
                readonly      =>1,
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>0,
                group         =>'userro',
                dataobjattr   =>'contact.gtctxt'),
                                  
      new kernel::Field::Number(
                name          =>'killtimeout',
                label         =>'limit query duration',
                precision     =>0,
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                unit          =>'sec',
                group         =>'userro',
                dataobjattr   =>'contact.killtimeout'),

      new kernel::Field::Text(
                name          =>'posix',
                label         =>'POSIX-Identifier',
                group         =>'userid',
                dataobjattr   =>'contact.posix_identifier'),

      new kernel::Field::Text(
                name          =>'dsid',
                label         =>'Directory-Identifier',
                group         =>'userid',
                dataobjattr   =>'contact.ds_identifier'),

      new kernel::Field::SubList(
                name          =>'accounts',
                label         =>'Accounts',
                allowcleanup  =>1,
                readonly      =>1,
                depend        =>['usertyp'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   if ($current->{usertyp} eq "extern"){
                      return(0);
                   }
                   return(1);
                },
                group         =>'userro',
                vjointo       =>'base::useraccount',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['account','cdate','lastlogon'],
                vjoininhash   =>['account','userid']),

      new kernel::Field::Phonenumber(
                name          =>'office_mobile',
                group         =>'office',
                label         =>'Mobile-Phonenumber',
                dataobjattr   =>'contact.office_mobile'),

      new kernel::Field::Phonenumber(
                name          =>'office_phone',
                group         =>['office','nativcontact'],
                label         =>'Phonenumber',
                dataobjattr   =>'contact.office_phone'),

      new kernel::Field::Text(
                name          =>'office_organisation',
                group         =>'office',
                label         =>'Organisation',
                dataobjattr   =>'contact.office_orgname'),

      new kernel::Field::Text(
                name          =>'office_street',
                group         =>'office',
                label         =>'Street',
                dataobjattr   =>'contact.office_street'),

      new kernel::Field::Text(
                name          =>'office_zipcode',
                group         =>'office',
                label         =>'ZIP-Code',
                dataobjattr   =>'contact.office_zipcode'),

      new kernel::Field::Text(
                name          =>'office_location',
                group         =>'office',
                label         =>'Location',
                dataobjattr   =>'contact.office_location'),

      new kernel::Field::Text(
                name          =>'office_room',
                group         =>'office',
                htmldetail    =>'NotEmpty',
                label         =>'Room number',
                dataobjattr   =>'contact.office_room'),

      new kernel::Field::Phonenumber(
                name          =>'office_facsimile',
                group         =>['office','nativcontact'],
                label         =>'FAX-Number',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'contact.office_facsimile'),

      new kernel::Field::Text(
                name          =>'office_elecfacsimile',
                group         =>'office',
                label         =>'electronical FAX-Number',
                dataobjattr   =>'contact.office_elecfacsimile'),

      new kernel::Field::Select(
                name          =>'country',
                htmleditwidth =>'50px',
                group         =>'office',
                label         =>'Country',
                vjointo       =>'base::isocountry',
                vjoinon       =>['country'=>'token'],
                vjoindisp     =>'token',
                dataobjattr   =>'contact.country'),

      new kernel::Field::Number(
                name          =>'office_persnum',
                group         =>'officeacc',
                label         =>'Personal-Number',
                uploadable    =>0,
                dataobjattr   =>'contact.office_persnum'),

      new kernel::Field::Text(
                name          =>'office_costcenter',
                group         =>'officeacc',
                uploadable    =>0,
                weblinkto     =>'finance::costcenter',
                weblinkon     =>['costcenterid'=>'id'],
                label         =>'CostCenter',
                dataobjattr   =>'contact.office_costcenter'),

      new kernel::Field::Number(
                name          =>'office_accarea',
                group         =>'officeacc',
                uploadable    =>0,
                label         =>'Accounting Area',
                dataobjattr   =>'contact.office_accarea'),

      new kernel::Field::Text(
                name          =>'office_sisnumber',
                group         =>'officeacc',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'SIS Number',
                dataobjattr   =>'contact.office_sisnumber'),

      new kernel::Field::Link(
                name          =>'costcenterid',
                group         =>'officeacc',
                label         =>'CostCenterID',
                depend        =>['office_accarea','office_costcenter'],
                onRawValue    =>sub {
                                   my $self=shift;
                                   my $current=shift;
                                   my $app=$self->getParent();
                                   my $co=getModuleObject($app->Config,
                                                         "finance::costcenter");
                                   if (defined($co)){
                                      $co->SetFilter({
                                         accarea=>\$current->{office_accarea},
                                         name=>\$current->{office_costcenter}});
                                      my ($rec,$msg)=$co->getOnlyFirst("id");
                                      if (defined($rec)){
                                         return($rec->{id});
                                      }
                                   }
                                   return(undef);
                                }),

      new kernel::Field::Text(
                name          =>'private_street',
                group         =>'private',
                label         =>'private Street',
                dataobjattr   =>'contact.private_street'),

      new kernel::Field::Text(
                name          =>'private_zipcode',
                group         =>'private',
                label         =>'private ZIP-Code',
                dataobjattr   =>'contact.private_zipcode'),

      new kernel::Field::Text(
                name          =>'private_location',
                group         =>'private',
                label         =>'private Location',
                dataobjattr   =>'contact.private_location'),

      new kernel::Field::Phonenumber(
                name          =>'private_facsimile',
                group         =>'private',
                label         =>'private FAX-Number',
                dataobjattr   =>'contact.private_facsimile'),

      new kernel::Field::Phonenumber(
                name          =>'private_elecfacsimile',
                group         =>'private',
                label         =>'private electronical FAX-Number',
                dataobjattr   =>'contact.private_elecfacsimile'),

      new kernel::Field::Phonenumber(
                name          =>'private_mobile',
                group         =>'private',
                label         =>'private Mobile-Phonenumber',
                dataobjattr   =>'contact.private_mobile'),

      new kernel::Field::Phonenumber(
                name          =>'private_phone',
                group         =>'private',
                label         =>'private Phonenumber',
                dataobjattr   =>'contact.private_phone'),

#      new kernel::Field::Text(
#                name          =>'persidentno',
#                group         =>'personrelated',
#                label         =>'personal identifier number',
#                dataobjattr   =>'contact.persidentno'),

#      new kernel::Field::Date(
#                name          =>'dateofbirth',
#                dayonly       =>1,
#                group         =>'private',
#                label         =>'date of birth',
#                dataobjattr   =>'contact.dateofbirth'),

#      new kernel::Field::Text(
#                name          =>'driverlicno',
#                group         =>'personrelated',
#                label         =>'driver license number',
#                dataobjattr   =>'contact.driverlicno'),
#
#      new kernel::Field::Text(
#                name          =>'eurocarno',
#                group         =>'personrelated',
#                label         =>'EURO Car-rent driver number',
#                dataobjattr   =>'contact.eurocarno'),
#
#      new kernel::Field::Text(
#                name          =>'sixtcarno',
#                group         =>'personrelated',
#                label         =>'SIXT Car-rent driver number',
#                dataobjattr   =>'contact.sixtcarno'),

      new kernel::Field::Date(
                name          =>'dateofworksafty',
                dayonly       =>1,
                group         =>'introdution',
                label         =>'date of "Work Safety" introduction',
                dataobjattr   =>'contact.dateofworksafty'),

      new kernel::Field::Interface(
                name          =>'dateofworksafty_edt',
                group         =>'introdution',
                label         =>'date of "Work Safety" introduction EDT',
                dataobjattr   =>'contact.dateofworksafty_edt'),

      new kernel::Field::Date(
                name          =>'dateofdatapriv',
                dayonly       =>1,
                group         =>'introdution',
                label         =>'date of "Data Privacy" introduction',
                dataobjattr   =>'contact.dateofdatapriv'),

      new kernel::Field::Interface(
                name          =>'dateofdatapriv_edt',
                group         =>'introdution',
                label         =>'date of "Data Privacy" introduction EDT',
                dataobjattr   =>'contact.dateofdatapriv_edt'),

      new kernel::Field::Date(
                name          =>'dateofcorruprot',
                dayonly       =>1,
                group         =>'introdution',
                label         =>'date of "Corruption Protection" introduction',
                dataobjattr   =>'contact.dateofcorruprot'),

      new kernel::Field::Interface(
                name          =>'dateofcorruprot_edt',
                group         =>'introdution',
                label         =>'date of "Corruption Protection" introduction EDT',
                dataobjattr   =>'contact.dateofcorruprot_edt'),

      new kernel::Field::Date(
                name          =>'dateofvsnfd',
                dayonly       =>1,
                group         =>'introdution',
                label         =>'date of "VSnfD" introduction',
                dataobjattr   =>'contact.dateofvsnfd'),

      new kernel::Field::Interface(
                name          =>'dateofvsnfd_edt',
                group         =>'introdution',
                label         =>'date of "VSnfD" introduction EDT',
                dataobjattr   =>'contact.dateofvsnfd_edt'),

      new kernel::Field::Date(
                name          =>'dateofsecretpro',
                dayonly       =>1,
                group         =>'introdution',
                label         =>'date of "Secret Protection" introduction',
                dataobjattr   =>'contact.dateofsecretpro'),

      new kernel::Field::Interface(
                name          =>'dateofsecretpro_edt',
                group         =>'introdution',
                label         =>'date of "Secret Protection" introduction EDT',
                dataobjattr   =>'contact.dateofsecretpro_edt'),

      new kernel::Field::Select(
                name          =>'tz',
                label         =>'Timezone',
                uploadable    =>0,
                group         =>'userparam',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'contact.timezone'),

      new kernel::Field::Select(
                name          =>'lang',
                label         =>'Language',
                htmleditwidth =>'50px',
                group         =>'userparam',
                value         =>['',LangTable()],
                dataobjattr   =>'contact.lang'),

      new kernel::Field::Select(
                name          =>'pagelimit',
                label         =>'Pagelimit',
                unit          =>'Entries',
                uploadable    =>0,
                htmleditwidth =>'50px',
                group         =>'userparam',
                value         =>[qw(10 15 20 30 40 50 100)],
                default       =>'20',
                dataobjattr   =>'contact.pagelimit'),

      new kernel::Field::Select(
                name          =>'dialermode',
                uploadable    =>0,
                label         =>'PC Phone Dialer Mode',
                jsonchanged   =>\&getDialerChangeScript,
                jsoninit      =>\&getDialerChangeScript,
                htmleditwidth =>'50%',
                group         =>'userparam',
                value         =>[
                                  '',
                                  "Cisco WebDialer V1",
                                  "HTML-Dial-Tag",
                                  "HTML-0Dial-Tag"
                               ],
                dataobjattr   =>'contact.dialermode'),

      new kernel::Field::Text(
                name          =>'dialeripref',
                uploadable    =>0,
                group         =>'userparam',
                label         =>'PC Phone own country code',
                dataobjattr   =>'contact.dialeripref'),

      new kernel::Field::Text(
                name          =>'dialerurl',
                group         =>'userparam',
                uploadable    =>0,
                label         =>'PC Phone Dialer URL',
                dataobjattr   =>'contact.dialerurl'),

      new kernel::Field::Select(
                name          =>'winsize',
                uploadable    =>0,
                label         =>'Window-Size',
                htmleditwidth =>'50%',
                group         =>'userparam',
                default       =>'normal',
                value         =>['normal','large','persi',
                                 'f800','f1024','vmax600','vmax800'],
                container     =>'options'),

      new kernel::Field::Select(
                name          =>'winhandling',
                uploadable    =>0,
                label         =>'Window-Handling',
                htmleditwidth =>'50%',
                group         =>'userparam',
                default       =>'normal',
                value         =>['windefault','winminimal','winonlyone'],
                dataobjattr   =>'contact.winhandling'),

      new kernel::Field::Textarea(
                name          =>'w5mailsig',
                uploadable    =>0,
                searchable    =>0,
                group         =>'userparam',
                label         =>'W5Base Mail Signatur',
                dataobjattr   =>'contact.w5mailsig'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                vjoinon       =>['userid'=>'refid'],
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::Select(
                name          =>'sms',
                label         =>'SMS Notification',
                uivisible   =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if ($self->getParent->Config->Param("SMSInterfaceScript") 
                       eq ""){
                      return(0);
                   }
                },
                group         =>'control',
                transprefix   =>'SMS.',
                htmldetail    =>sub{
                   my $self=shift;
                   if ($self->getParent->Config->Param("SMSInterfaceScript") 
                       eq ""){
                      return(0);
                   }
                   return(1);
                },
                default       =>'',
#                value         =>['',qw( officealways officenight officeday
#                                        homealways   homenight   homeday)],
                value         =>['',qw( officealways
                                        homealways)],
                container     =>'options'),

      new kernel::Field::Select(
                name          =>'secstate',
                uploadable    =>0,
                label         =>'security state',
                value         =>['1','2','3','4'],
                transprefix   =>'SECSTATE.',
                group         =>'userro',
                dataobjattr   =>'contact.secstate'),

      new kernel::Field::Link(
                name          =>'secstateid',
                label         =>'Sec-StateID',
                dataobjattr   =>'contact.secstate'),

      new kernel::Field::Text(
                name          =>'ipacl',
                uploadable    =>1,
                label         =>'IP access control',
                group         =>'userro',
                dataobjattr   =>'contact.ipacl'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'contact.allowifupdate'),

      new kernel::Field::Boolean(
                name          =>'isw5support',
                group         =>'control',
                label         =>'use contact as central W5Base support',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0) if ($self->getParent->IsMemberOf("admin"));
                   return(1);
                },
                dataobjattr   =>'contact.isw5support'),

      new kernel::Field::Boolean(
                name          =>'banalprotect',
                group         =>'control',
                label         =>'protection against banal informations',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0) if ($self->getParent->IsMemberOf("admin"));
                   return(1);
                },
                dataobjattr   =>'contact.banalprotect'),

      new kernel::Field::Textarea(
                name          =>'ssh1publickey',
                label         =>'SSH1 Public Key',
                group         =>'userid',
                htmldetail    =>0,
                dataobjattr   =>'contact.ssh1publickey'),

      new kernel::Field::Textarea(
                name          =>'ssh2publickey',
                label         =>'SSH2 Public Key',
                group         =>'userid',
                htmldetail    =>0,
                dataobjattr   =>'contact.ssh2publickey'),

      new kernel::Field::Textarea(
                name          =>'similarcontacts',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'similar contacts',
                depend        =>['userid','email','surname','givenname'],
                searchable    =>0,
                onRawValue    =>\&findSimilarContacts,
                group         =>'qc'),

      new kernel::Field::Container(
                name          =>'options',
                dataobjattr   =>'contact.options'),

      new kernel::Field::Container(
                name          =>'formdata',
                dataobjattr   =>'contact.formdata'),

      new kernel::Field::File(
                name          =>'picture',
                label         =>'picture',
                content       =>'image/jpg',
                types         =>['jpg','jpeg'],
                maxsize       =>1024*1024,
                searchable    =>0,
                uploadable    =>0,
                group         =>'picture',
                dataobjattr   =>'contact.picture'),

      new kernel::Field::Date(
                name          =>'lastlogon',
                readonly      =>1,
                group         =>'userro',
                searchable    =>0,
                depend        =>["accounts"],
                onRawValue    =>\&getLastLogon,
                label         =>'Last-Logon'),

      new kernel::Field::Number(
                name          =>'userquerybreakcount',
                group         =>'userro',
                readonly      =>1,
                label         =>'relevant user query abort count',
                dataobjattr   =>"(select count(*) from userquerybreak where ".
                                "userquerybreak.userid=contact.userid and ".
                                "userquerybreak.createdate>".
                                   "DATE_SUB(NOW(), ".
                                   "INTERVAL $UserQueryAbbortFocus HOUR))"),

      new kernel::Field::Text(
                name          =>'lastlang',
                readonly      =>1,
                group         =>'userro',
                depend        =>["accounts"],
                onRawValue    =>\&getLastLogon,
                searchable    =>0,
                label         =>'Last-Lang'),

      new kernel::Field::Text(
                name          =>'talklang', 
                readonly      =>1,
                htmldetail    =>0,
                group         =>'userro',
                depend        =>["accounts","lang"],
                onRawValue    =>\&getLastLogon,
                searchable    =>0,
                label         =>'Talk-Lang'),

      new kernel::Field::Date(
                name          =>'lastexternalseen',
                readonly      =>1,
                group         =>'userro',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                dayonly       =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Last-External-Seen',
                dataobjattr   =>'contact.lastexternalseen'),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'userro',
                label         =>'Creator',
                dataobjattr   =>'contact.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'userro',
                label         =>'last Editor',
                dataobjattr   =>'contact.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'userro',
                label         =>'Editor Account',
                dataobjattr   =>'contact.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'userro',
                label         =>'real Editor Account',
                dataobjattr   =>'contact.realeditor'),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'userro',
                dataobjattr   =>'contact.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                group         =>'userro',
                dataobjattr   =>'contact.modifydate'),

      new kernel::Field::Group(
                name          =>'managedby',
                label         =>'managed by group',
                vjoinon       =>'managedbyid',
                group         =>'userid'),

      new kernel::Field::Link(
                name          =>'managedbyid',
                group         =>'default',   # to allow write on create
                selectfix     =>1,
                dataobjattr   =>'contact.managedby'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"contact.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(contact.userid,35,'0')"),

      new kernel::Field::Date(
                name          =>'planneddismissaldate',
                readonly      =>1,
                group         =>'userro',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                dayonly       =>1,
                htmldetail    =>'NotEmpty',
                label         =>'planned dismissal date',
                dataobjattr   =>'contact.planneddismissaldate'),

      new kernel::Field::Date(
                name          =>'notifieddismissaldate',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'userro',
                uivisible     =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                dayonly       =>1,
                label         =>'notified dismissal date',
                dataobjattr   =>'contact.notifieddismissaldate'),


      new kernel::Field::Link(
                name          =>'lastknownbossid',
                label         =>'last known boss IDs',
                dataobjattr   =>'contact.lastknownboss'),

      new kernel::Field::SubList(
                name          =>'lastknownboss',
                label         =>'last known boss',
                htmldetail    =>0,
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   my $current=shift;
                   my $mode=shift;

                   if ($flt->{userid} eq ""){
                      $flt->{userid}="-99";
                   }
                   return($flt);
                },
                group         =>'userro',
                searchable    =>0, # nicht suchbar, da kein db join möglich!
                vjointo       =>'base::user',
                vjoinon       =>['lastknownbossid'=>'userid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Link(
                name          =>'lastknownpbossid',
                label         =>'last known project boss IDs',
                selectfix     =>1,
                dataobjattr   =>'contact.lastknownpboss'),

      new kernel::Field::SubList(
                name          =>'lastknownpboss',
                label         =>'last known project boss',
                htmldetail    =>0,
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   my $current=shift;
                   my $mode=shift;

                   if ($flt->{userid} eq ""){
                      $flt->{userid}="-99";
                   }
                   return($flt);
                },
                group         =>'userro',
                searchable    =>0, # nicht suchbar, da kein db join möglich!
                vjointo       =>'base::user',
                vjoinon       =>['lastknownpbossid'=>'userid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::SubList(
                name          =>'groups',
                label         =>'Groups',
                group         =>'groups',
                subeditmsk    =>'subedit.user',
                allowcleanup  =>1,
                forwardSearch =>1,
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['group','grpweblink','roles'],
                vjoininhash   =>['group','grpid','roles','cdate',
                                 'is_orggrp','is_projectgrp']),

      new kernel::Field::Text(
                name          =>'groupnames',
                label         =>'Groupnames',
                group         =>'groups',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['group']),

      new kernel::Field::Text(
                name          =>'orgunits',
                label         =>'organisational Units',
                preferArray   =>1,
                group         =>'groups',
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'base::lnkgrpuserrole',
                vjoinbase     =>['nativrole'=>[orgRoles()],
                                 'grpcistatusid'=>"4 5"],
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['grpfullname']),

      new kernel::Field::SubList(
                name          =>'roles',
                label         =>'Roles',
                group         =>'roles',
                htmldetail    =>'0',
                subeditmsk    =>'subedit.user',
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['lineroles'],
                vjoininhash   =>['lineroles']),

      new kernel::Field::SubList(
                name          =>'usersubst',
                label         =>'Substitiutions',
                allowcleanup  =>1,
                group         =>'usersubst',
                subeditmsk    =>'subedit.user',
                vjointo       =>'base::usersubst',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['dstaccount','active','cdate'],
                vjoininhash   =>['dstaccount','active','cdate',
                                 'usersubstcontactusertyp',
                                 'usersubstcontactcistatusid']),

      new kernel::Field::Text(
                name          =>'allphones',
                explore       =>400,
                label         =>'all native phone numbers',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                group         =>'userro',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>formPhoneSql(qw(contact.office_phone
                                                contact.office_mobile
                                                contact.private_phone
                                                contact.private_mobile ))),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments', 
                label         =>'Comments',
                dataobjattr   =>'contact.comments'),

      new kernel::Field::Textarea(
                name          =>'admcomments',
                group         =>'admcomments', 
                history       =>0,
                label         =>'Admin Comments',
                dataobjattr   =>'contact.admcomments'),

      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'contact.lastqcheck'),

      new kernel::Field::Date(
                name          =>'lastorgchangedt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last organisational change',
                dataobjattr   =>'contact.lorgchangedt')
   );
   $self->{CI_Handling}={uniquename=>"fullname",
                         activator=>["admin","w5base.base.user"],
                         uniquesize=>255};
   $self->setWorktable("contact");
   $self->LoadSubObjs("user");
   $self->setDefaultView(qw(fullname cistatus usertyp));
   return($self);
}


sub getOnChangedScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;
if (mode=="onchange"){
   document.forms[0].submit();
}
EOF
   return($d);
}


sub getDialerChangeScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;
var dialermode=document.forms[0].elements['Formated_dialermode'];
var dialerurl=document.forms[0].elements['Formated_dialerurl'];
if (dialermode){
   var v=dialermode.options[dialermode.selectedIndex].value;
   if (v.match(/Cisco/)){
      dialerurl.disabled=false;
   }
   else{
      dialerurl.disabled=true;
   }
}


EOF
   return($d);
}



sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;  # prevent list of contact entries of type=altemail
   my $where="contact.usertyp ".
             "in ('extern','service','user','function','genericAPI')";
   return($where);
}


sub formPhoneSql
{
   my $s="";
   

   while(my $v=shift){
      $s.=",' '," if ($s ne "");
      $s.="if ($v<>'',".
          "replace(replace(replace($v,'/',''),'-',''),' ',''),'')";
   }
   if ($s ne ""){
      $s="concat($s)";
      $s="replace($s,'  ',' ')";
      $s="replace($s,'  ',' ')";
      $s="trim($s)";
      $s="replace($s,' ','; ')";
   }
   else{
      $s="'-'";
   }
   return($s);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);

   }
   return($self->SetFilter(@flt));
}

sub getLastLogon
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name();
   my $userid=$current->{userid};
   if (!defined($self->getParent->Context->{LogonData}->{$userid})){
      my $accounts=$self->getParent->getField("accounts");
      my $l=$accounts->RawValue($current);
      my @accounts=grep(!/^\s*$/,map({$_->{account}} @$l));
      return(undef) if ($#accounts==-1);
      my $ul=$self->getParent->getPersistentModuleObject("ul",
                                                         "base::userlogon");
      $ul->SetFilter({account=>\@accounts,
                      logonbrowser=>'!SOAP::* !curl/* !Jakarta*'}
                     ); # exclude SOAP (and other automation) logons
      $ul->Limit(1);
      my ($ulrec,$msg)=$ul->getOnlyFirst(qw(logondate lang));
      if (defined($ulrec)){
         $self->getParent->Context->{LogonData}->{$userid}=$ulrec;
      }
   }
   if (defined($self->getParent->Context->{LogonData}->{$userid})){
      my $ulrec=$self->getParent->Context->{LogonData}->{$userid};
      return($ulrec->{logondate}) if ($name eq "lastlogon");
      return($ulrec->{lang}) if ($name eq "lastlang");
      return($ulrec->{lang}) if ($name eq "talklang");
   }
   if ($name eq "talklang"){
      my $lang=$current->{lang};
      $lang="en" if ($lang eq "");
      return($lang);
   }
   return("");
}

sub findSimilarContacts            # check for similar contacts to reduce
{                                  # the posibility of double created contacts
   my $self=shift;
   my $current=shift;
   my %res;

   my $user=$self->getParent->Clone();
   my $chkemail=$current->{email};
   $chkemail=~s/\@.*/\@*/;
   my @flt;
   if ($chkemail ne ""){
      push(@flt,{email=>$chkemail});
   }
   if ($current->{surname} ne "" && $current->{givenname} ne ""){
      push(@flt,{surname=>\$current->{surname},
                 givenname=>\$current->{givenname}});
   }
   if ($current->{office_phone} ne ""){
      push(@flt,{office_phone=>\$current->{office_phone}});
   }
   if ($#flt!=-1){
      $user->SetFilter(\@flt);
      foreach my $rec ($user->getHashList(qw(fullname))){
         if ($rec->{userid}!=$current->{userid}){
            $res{$rec->{userid}}=$rec->{fullname};
         }
      }
      return(join("\n",sort(values(%res))));
   }
   return(undef);
}



sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $userid=$self->getCurrentUserId();
   my $usertyp=effVal($oldrec,$newrec,"usertyp");
   if (!$self->IsMemberOf("admin")){
      if (!defined($oldrec)){
         if ($usertyp eq "" || $usertyp eq "user"){
            $self->LastMsg(ERROR,"you are not authorized to create this ".
                                 "usertype");
            return(0);
         }
      }
      delete($newrec->{secstate});
      if (!defined($oldrec)){
         my %a=$self->getGroupsOf($userid, [qw(RContactAdmin)], 'direct');
         my @idl=keys(%a);
         if ($#idl!=-1){
            if ($idl[0] ne ""){
               $newrec->{managedbyid}=$idl[0];
            }
         }
         else{
           my @igrpid=$self->getInitiatorGroupsOf($userid);
           if ($igrpid[0] ne ""){
               $newrec->{managedbyid}=$igrpid[0];
           }
         }
      }
   }
   if (defined($oldrec) && $oldrec->{userid}==$userid){
      delete($newrec->{cistatusid});
   }
   else{
      if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}

sub postQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   my $userid=$rec->{userid};

   if ($userid ne ""){
      my %upd;
      my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");
      $lnk->SetFilter({
         userid=>\$userid,
         rawnativroles=>[orgRoles()],
         grpcistatusid=>[3,4,5]
      });
      my @grp;
      my @orggroups=$lnk->getHashList(qw(grpid nativroles 
                                         is_orggrp is_projectgrp
                                         mdate)); 
      my %grp;
      my $grpobj=getModuleObject($self->Config,"base::grp");
      my $latestmdate;
      foreach my $lnkrec (@orggroups){
         my $roles=$lnkrec->{nativroles};
         if (!defined($latestmdate) || $latestmdate eq "" ||
             $latestmdate lt $lnkrec->{mdate}){
            $latestmdate=$lnkrec->{mdate};
         } 
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         $roles=[map({$_->{nativrole}} @{$roles})];
         if (in_array($roles,"RBoss")){ # TL Handling
            $grpobj->ResetFilter();
            $grpobj->SetFilter({grpid=>\$lnkrec->{grpid}});
            foreach my $grprec ($grpobj->getHashList(qw(parentid 
                                                     is_orggrp is_projectgrp))){
               push(@grp,$grprec->{parentid});
               $grp{$grprec->{grpid}}={
                  is_orggrp=>$grprec->{is_orggrp},
                  is_projectgrp=>$grprec->{is_projectgrp}
               };
            }
         }
         else{
            push(@grp,$lnkrec->{grpid});
            $grp{$lnkrec->{grpid}}={
               is_orggrp=>$lnkrec->{is_orggrp},
               is_projectgrp=>$lnkrec->{is_projectgrp}
            }
         }
      }
      if ($rec->{lastorgchangedt} ne $latestmdate){
         $upd{lastorgchangedt}=$latestmdate;
      }

      if ($#grp!=-1){
         my $recursecnt=0;
         do{
            $recursecnt++;
            $lnk->ResetFilter();
            $lnk->SetFilter({grpid=>\@grp,rawnativroles=>\"RBoss"});
            foreach my $lnkrec ($lnk->getHashList(qw(userid grpid
                                                     is_orggrp is_projectgrp))){
               $grp{$lnkrec->{grpid}}->{boss}=$lnkrec->{userid};
            }
            @grp=();
            foreach my $grpid (keys(%grp)){
               if (!exists($grp{$grpid}->{boss}) &&
                   !exists($grp{$grpid}->{parentid})){
                  $grpobj->ResetFilter();
                  $grpobj->SetFilter({grpid=>\$grpid});
                  foreach my $grprec ($grpobj->getHashList(qw(parentid))){
                     if ($grprec->{parentid} ne ""){
                        $grp{$grpid}->{parentid}=$grprec->{parentid};
                        push(@grp,$grprec->{parentid});
                        # type of parent will be "virtual" inherit from 
                        # subgroup to document the origin of the posible
                        # found boss
                        $grp{$grprec->{parentid}}={
                           is_projectgrp=>$grp{$grpid}->{is_projectgrp}, 
                           is_orggrp=>$grp{$grpid}->{is_orggrp}, 
                        };
                     }
                  }
               }
            }
         }while(!($recursecnt>2 || $#grp==-1));
      }
      my %oboss;
      my %pboss;
      foreach my $grpid (keys(%grp)){
         if ($grp{$grpid}->{is_projectgrp}){
            $pboss{$grp{$grpid}->{boss}}++;
         }
         else{
            $oboss{$grp{$grpid}->{boss}}++;  # auch is_orggrp=0 wird als Org 
         }                                   # boss verwendet (falls kein org
      }                                      # attribut gesetzt)

      my $oboss=trim(join(" ",sort(grep(!/^$userid$/,keys(%oboss)))));
      if (($oboss ne "")  && $oboss ne $rec->{lastknownbossid}){
         $oboss=undef if ($oboss eq "");
         $upd{lastknownbossid}=$oboss;
      }
      my $pboss=trim(join(" ",sort(grep(!/^$userid$/,keys(%pboss)))));
      if (($pboss ne "")  && $pboss ne $rec->{lastknownpbossid}){
         $pboss=undef if ($pboss eq "");
         $upd{lastknownpbossid}=$pboss;
      }

      if (keys(%upd)){
         my $op=$self->Clone();
         $op->ValidatedUpdateRecord($rec,\%upd,{userid=>\$userid});
      }
   }

   return(1);
}


sub prepareToWasted
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   foreach my $v (qw( dateofdatapriv dateofdatapriv_edt
                      dateofworksafty dateofworksafty_edt
                      dateofcorruprot dateofcorruprot_edt
                      dateofvsnfd dateofvsnfd_edt
                      dateofsecretpro dateofsecretpro_edt
                      private_elecfacsimile private_facsimile private_mobile
                      private_phone private_street private_location
                      private_zipcode persidentno
                      posix dsid srcsys srcid srcload )){
      $newrec->{$v}=undef;
   }


   return(1);   # if undef, no wasted Transfer is allowed
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   if (!defined($cistatusid) && !defined($oldrec)){
      $newrec->{cistatusid}=1;
   } 
   if (effChangedVal($oldrec,$newrec,"cistatusid")==7){
      $newrec->{email}=undef;
      return(1);
   }

   if (!defined($oldrec)){
      $newrec->{secstate}=$self->Config->Param("DefaultUserSecState");
   }

   my $usertyp=effVal($oldrec,$newrec,"usertyp");
   # field resets based on usertype
   if ($usertyp eq "function"){
      if (effVal($oldrec,$newrec,"surname") ne "FMB"){
         $newrec->{surname}="FMB";
      }
   }
   if ($usertyp eq "service"){
      if (effVal($oldrec,$newrec,"givenname") ne ""){
         $newrec->{givenname}="";
      }
   }
   if (exists($newrec->{contactdesc}) && $newrec->{contactdesc} ne ""){
      $newrec->{surname}=$newrec->{contactdesc};
   }
   if ($usertyp eq "function" || $usertyp eq "service"){
      foreach my $v (qw(office_mobile
                        private_street
                        private_zipcode
                        private_location
                        private_facsimile
                        private_elecfacsimile
                        private_mobile
                        private_phone
                        office_room
                        office_location
                        office_street
                        office_zipcode
                        country)){
         if (effVal($oldrec,$newrec,$v) ne ""){
            $newrec->{$v}="";
         }
      }
   }
   if (effChangedVal($oldrec,$newrec,"usertyp") &&
       (defined($oldrec) && $oldrec->{usertyp} eq "function")){
      if ($#{$oldrec->{contacts}}!=-1){
         $self->LastMsg(ERROR,
                        "usertyp change not allowed with existing contacts");
         return(0);
      }
   }
   if (effChangedVal($oldrec,$newrec,"usertyp") &&
       $newrec->{usertyp} eq "genericAPI"){
      if ($#{$oldrec->{groups}}!=-1){
         $self->LastMsg(ERROR,
                        "usertyp change not allowed with existing groups");
         return(0);
      }
   }
   if (effChangedVal($oldrec,$newrec,"planneddismissaldate")){
      if (effVal($oldrec,$newrec,"notifieddismissaldate") ne ""){
         $newrec->{notifieddismissaldate}=undef;
      }
   }

   if ($usertyp ne "service" &&
       effVal($oldrec,$newrec,"surname") eq "" &&
       effVal($oldrec,$newrec,"givenname") eq ""){
         if (my ($p1,$p2)=effVal($oldrec,$newrec,"email")
                         =~m/^(\S{2,})\.(\S{2,})\@.*$/){
            $newrec->{givenname}=$p1;
            $newrec->{surname}=$p2;
            $newrec->{givenname}=~s/^([a-z])/uc($1)/ge;
            $newrec->{givenname}=~s/([\s-][a-z])/uc($1)/ge;
            $newrec->{surname}=~s/^([a-z])/uc($1)/ge;
            $newrec->{surname}=~s/([\s-][a-z])/uc($1)/ge;
         }
   }
   if ((defined($newrec->{surname}) ||
        defined($newrec->{givenname}) ||
        defined($newrec->{email}) ||
        !defined($oldrec))){
      my $fullname="";
      my $givenname=effVal($oldrec,$newrec,"givenname");
      my $surname=effVal($oldrec,$newrec,"surname");
      my $email=effVal($oldrec,$newrec,"email");
      if ($usertyp ne "service"){
         if ($email eq "" || ($email=~m/^"/)){
            $self->LastMsg(ERROR,"invalid email address");
            return(0);
         }
      }
      $fullname.=$surname;
      $fullname.=", " if ($fullname ne "" && $givenname ne "");
      $fullname.=$givenname;
      if ($email ne ""){
         $email=" (".$email.")" if ($fullname ne "");
         $fullname.=$email;
      }
      $newrec->{fullname}=$fullname;
   }
   if (effVal($oldrec,$newrec,"fullname")=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid fullname");
      return(0);
   }
   if (exists($newrec->{ipacl})){
      my @l=split(/[;,]\s*/,$newrec->{ipacl});
      my @ok;
      foreach my $ip (@l){
         next if ($ip eq "");
         if (my ($o1,$o2,$o3,$o4)=$ip=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/){
            if (($o1<0 || $o1 >255 ||
                 $o2<0 || $o2 >255 ||
                 $o3<0 || $o3 >255 ||
                 $o4<0 || $o4 >255)||
                ($o1==0 && $o2==0 && $o3==0 && $o4==0) ||
                ($o1==255 && $o2==255 && $o3==255 && $o4==255)){
               $self->LastMsg(ERROR,
                      sprintf($self->T("invalid IPV4 address '\%s'"),$ip));
               return(0);
            }
            push(@ok,$ip);
         }
         elsif (my ($o1,$o2,$o3,$o4,$o5,$o6,$o7,$o8)=$ip
                   =~m/^([0-9a-f]{4}):([0-9a-f]{4}):([0-9a-f]{4}):([0-9a-f]{4}):([0-9a-f]{4}):([0-9a-f]{4}):([0-9a-f]{4}):([0-9a-f]{4})$/){
             push(@ok,$ip);
         }
         else{
            $self->LastMsg(ERROR,"unknown ip-address format '$ip'");
            return(0);
         }
      }
      $newrec->{ipacl}=join(", ",sort(@ok));
      if ($newrec->{ipacl} eq ""){
         $newrec->{ipacl}=undef;
      }
   }
   #######################################################################
   # SSH 1 Key Handling
   my $sshpublickey=effVal($oldrec,$newrec,"ssh1publickey");
   if ($sshpublickey eq ""){
      if (defined($sshpublickey)){
         $newrec->{ssh1publickey}=undef;
      }
   }
   else{
      if (defined($newrec->{ssh1publickey})){
         my $fail=0;
         $sshpublickey=~s/\s*$//;
         my %k;
         foreach my $sshkey (split(/[\r]{0,1}\n/,$sshpublickey)){
            if (!($sshkey=~m/^\s*$/)){
               $sshkey=~s/^\s*//;
               $sshkey=~s/\s*$//;
               if ($sshkey=~m/^\d+\s\d+\s+\d{100,600}/){
                  $k{$sshkey}=1;
               }
               else{
                  $fail++;
               }
            }
         }
         if ($fail){
            $self->LastMsg(ERROR,"invalid SSH1 key format");
            return(undef);
         }
         else{
            $sshpublickey=join("\n",sort(keys(%k)));
         }
         $newrec->{ssh1publickey}=$sshpublickey;
      }
   }
   #######################################################################
   # SSH 2 Key Handling
   my $sshpublickey=effVal($oldrec,$newrec,"ssh2publickey");
   if ($sshpublickey eq ""){
      if (defined($sshpublickey)){
         $newrec->{ssh2publickey}=undef;
      }
   }
   else{
      if (defined($newrec->{ssh2publickey})){
         my $fail=0;
         $sshpublickey=~s/\s*$//;
         my %k;
         foreach my $sshkey (split(/[\r]{0,1}\n/,$sshpublickey)){
            if (!($sshkey=~m/^\s*$/)){
               $sshkey=~s/^\s*//;
               $sshkey=~s/\s*$//;
               if (($sshkey=~m/^ssh-(dss|rsa|ed25519|dsa)
                               \s+\S{50,600}/x) ||
                   ($sshkey=~m/^(ecdsa-sha2-nistp256)
                               \s+\S{50,600}/x)){
                  $k{$sshkey}=1;
               }
               else{
                  $fail++;
               }
            }
         }
         if ($fail){
            $self->LastMsg(ERROR,"invalid SSH2 key format");
            return(undef);
         }
         else{
            $sshpublickey=join("\n",sort(keys(%k)));
         }
         $newrec->{ssh2publickey}=$sshpublickey;
      }
   }
   if (!defined($oldrec) && !exists($newrec->{allowifupdate}) &&
       $newrec->{usertyp} eq "extern"){
      $newrec->{allowifupdate}=1;
   }
   #######################################################################
   my $fullname=effVal($oldrec,$newrec,"fullname");
   if ($usertyp eq "service" && $fullname && !($fullname=~m/^service/)){
      $newrec->{fullname}="service: ".$fullname;
   }
   msg(INFO,"fullname=$fullname");
   if ($fullname eq "" || ($fullname=~m/;/)){
      $self->LastMsg(ERROR,"invalid given or resulted fullname");
      return(0);
   }
   if (exists($newrec->{dsid})){
      $newrec->{dsid}=undef if ($newrec->{dsid} eq "");
   }
   if (defined($newrec->{posix})){
      $newrec->{posix}=undef if ($newrec->{posix} eq "");
      if (my $posix=effVal($oldrec,$newrec,"posix")){
         if (!($posix=~m/^[a-z,0-9,_,-]+$/)){
            $self->LastMsg(ERROR,"invalid posix identifier specified");
            return(0); 
         }
      }
   }
   foreach my $dateof (qw(dateofdatapriv dateofworksafty dateofcorruprot 
                          dateofvsnfd dateofsecretpro)){
      if (effChanged($oldrec,$newrec,$dateof)){
         $newrec->{"${dateof}_edt"}=$ENV{REMOTE_USER}.";".NowStamp("en");
      } 
   }
   if (defined($newrec->{email})){
      $newrec->{email}=undef if ($newrec->{email} eq "");
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   if (exists($newrec->{killtimeout})){
      if (effVal($oldrec,$newrec,"killtimeout")<600){
         $newrec->{killtimeout}=600;
      }
      if (effVal($oldrec,$newrec,"killtimeout")>10800){
         $newrec->{killtimeout}=10800;
      }
   }

   return(1);
}

sub FinishWrite
{  
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{cistatusid}) && 
       $newrec->{cistatusid}==7 &&
       (defined($oldrec) && $oldrec->{cistatusid}!=7)){
      my $userid=$oldrec->{userid};
      my $j=getModuleObject($self->Config,"base::useraccount");
      $j->BulkDeleteRecord({'userid'=>\$userid});
      my $j=getModuleObject($self->Config,"base::useremail");
      $j->BulkDeleteRecord({'userid'=>\$userid,usertyp=>\'altemail'});
      my $j=getModuleObject($self->Config,"base::lnkgrpuser");
      $j->BulkDeleteRecord({'userid'=>\$userid});
      return(1);
   }
   $self->InvalidateCache($oldrec) if (defined($oldrec));
   $self->ValidateUserCache();
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   $self->NotifyAddOrRemoveObject($oldrec,$newrec,"fullname",
                                  "STEVuserchanged",110000001);

   if (!defined($oldrec) && defined($newrec) &&
       $newrec->{usertyp} eq "genericAPI"){
      my $curUser=$ENV{REMOTE_USER};
      if ($curUser ne "" && $curUser ne "anonymous"){
         my $o=getModuleObject($self->Config,"base::usersubst");
         $o->ValidatedInsertRecord({
            userid=>$newrec->{userid},
            dstaccount=>$curUser,
            active=>1
         });
      }
   }

   return(1);
}

sub InvalidateCache
{
   my $self=shift;
   my $oldrec=shift;
   if (ref($oldrec->{accounts}) eq "ARRAY"){
      foreach my $rec (@{$oldrec->{accounts}}){
         $self->InvalidateUserCache($rec->{account});
      }
   }
}

sub isUploadValid  
{
   my $self=shift;
   return(0) if (!$self->IsMemberOf("admin"));
   return(1);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","name","header") if (!defined($rec));
   return(qw(header default)) if (defined($rec) && $rec->{cistatusid}==7);
   my @pic;
   my $userid=$self->getCurrentUserId();
   my @gl;
   my $allowAPIkeyAccess=$self->allowAPIkeyAccess($rec);;
   if ($self->IsMemberOf(["admin","support"])){
      push(@pic,"picture","roles","interview","history");
   }
   if ($rec->{usertyp} eq "extern"){
      @gl=qw(header name default comments userid userro control 
                office private qc);
      if ($self->IsMemberOf(["admin","support"])){
         push(@gl,"history");
      }
   }  
   elsif ($rec->{usertyp} eq "function"){
      if ($self->IsMemberOf(["admin","support"])){
         @gl=qw(header name default nativcontact comments contacts
                   control userid userro qc history);
      }
      else{
         @gl=qw(header name default nativcontact comments 
                contacts userid userro qc);
      }
   }  
   elsif ($rec->{usertyp} eq "service"){
      @gl=qw(header name default comments groups nativcontact usersubst 
             userid userro control userparam qc);
      if ($self->IsMemberOf(["admin","support"])){
         push(@gl,"history");
      }
   }  
   elsif ($rec->{usertyp} eq "genericAPI"){
      @gl=qw(header name default comments nativcontact usersubst 
             userid userro control userparam qc usersubst source);
      if ($self->IsMemberOf(["admin","support"])){
         push(@gl,"history");
      }
   }  
   else{
      @gl=(@pic,
             qw(default name office officeacc private userparam groups 
                userid userro control usersubst header qc interview));
   }
   if ($self->IsMemberOf(["admin","support"])){
      push(@gl,"admcomments");
   }
   my $secstate=$self->getCurrentSecState();

   if ($rec->{userid}!=$userid && 
       $W5V2::OperationContext ne "QualityCheck" &&
       !(($rec->{managedbyid}!=1 && $rec->{managedbyid}!=0) &&
         $self->IsMemberOf($rec->{managedbyid},["RContactAdmin"],"down"))){
      if ($secstate<2){
         my @flt=qw(name admcomments header);
         push(@flt,"usersubst","control","userro") if ($allowAPIkeyAccess);
         my $flt=join("|",@flt);
         @gl=grep(/^($flt)$/x,@gl);
      }
      elsif ($secstate<3){
         my @flt=qw(name admcomments header office default groups contacts 
                     comments nativcontact userid qc);
         push(@flt,"usersubst") if ($rec->{usertyp} eq "service" ||
                                    $rec->{usertyp} eq "genericAPI");
         push(@flt,"usersubst","control","userro") if ($allowAPIkeyAccess);
         my $flt=join("|",@flt);
         @gl=grep(/^($flt)$/x,@gl);
      }
      elsif ($secstate<4){
         my @flt=qw(name admcomments header office officeacc private contacts 
                     default groups comments nativcontact userid usersubst 
                     control qc userro history);
         my $flt=join("|",@flt);
         @gl=grep(/^($flt)$/x,@gl);
      }
   }
   if ($userid==$rec->{userid}){
      push(@gl,"personrelated","introdution","history","interview");
   }
   else{
      # check if the user has a direct boss
      if ($rec->{usertyp} eq "user"){
         my $g=$self->getField("groups")->RawValue($rec);
         if (ref($g) eq "ARRAY"){
            foreach my $grp (@$g){
               if (ref($grp->{roles}) eq "ARRAY"){
                  foreach my $orole ($self->orgRoles()){
                     if (grep(/^$orole$/,@{$grp->{roles}})){
                        if ($self->IsMemberOf($grp->{grpid},
                                              ["RBoss","RBoss2"],"direct")){
                           push(@gl,"personrelated","introdution","private",
                                    "history",
                                    "officeacc","interview");
                        }
                     }
                  }
               }
            }
         }
         if (!grep(/^personrelated$/,@gl)){
            if ($self->IsMemberOf("admin")){ 
               push(@gl,"personrelated","introdution","private","interview");
            }
         }
      }
   }
   return(@gl);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   if (defined($rec) && $rec->{cistatusid}==7){
      return($self->SUPER::getHtmlDetailPages($p,$rec));
   }
   my @pages=$self->SUPER::getHtmlDetailPages($p,$rec);
   if (defined($rec) && $rec->{cistatusid}>2 && $rec->{cistatusid}<7){
      push(@pages,"RView"=>$self->T("Rights overview"));
   }
   return(@pages);
}


sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "RView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "RView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"RightsOverview?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub allowHtmlFullList
{
   my $self=shift;
   return(0) if ($self->getCurrentSecState()<4);
   return(1);
}

sub allowFurtherOutput
{
   my $self=shift;
   return(0) if ($self->getCurrentSecState()<4);
   return(1);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub validateSearchQuery
{
   my $self=shift;

   my $allphones=Query->Param("search_allphones");
   if (defined($allphones) && $allphones ne ""){
      if ($allphones=~m/^[0-9 \+]+$/){
         $allphones=~s/\+\d\d/*/g; 
         my @w=split(/\s+/,$allphones);
         $allphones=join(" ",map({'*'.$_.'*'} @w));
         Query->Param("search_allphones"=>$allphones);
      }
   }

   return($self->SUPER::validateSearchQuery());
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","name","office","comments") if (!defined($rec));
   return(undef) if (!defined($rec));
   if ($self->IsMemberOf("admin")){
      my @l=(qw(default name office private userparam 
                groups usersubst control admcomments
                comments header picture nativcontact userro 
                personrelated introdution
                interview officeacc userid));
      if ($rec->{usertyp} eq "function"){
         push(@l,"contacts");
      }
      return(@l);
   }
   my $userid=$self->getCurrentUserId();
   if ($userid eq $rec->{userid} ||
       ($rec->{creator}==$userid && $rec->{cistatusid}<3)){
      my @l=("name","userparam","office","officeacc","private","nativcontact",
             "usersubst","control","officeacc","personrelated","introdution",
             "officeacc","interview","comments");
      if ($rec->{usertyp} eq "function"){
         push(@l,"contacts");
      }
      return($self->expandByDataACL(undef,@l));
   }
   # check if the user has a direct boss
   my $g=$self->getField("groups")->RawValue($rec);
   if (ref($g) eq "ARRAY"){
      foreach my $grp (@$g){
         if (ref($grp->{roles}) eq "ARRAY"){
            foreach my $orole ($self->orgRoles()){
               if (grep(/^$orole$/,@{$grp->{roles}})){
                  if ($self->IsMemberOf($grp->{grpid},["RBoss","RBoss2"],
                                        "direct")){
                     my @l=("personrelated","introdution","private",
                            "officeacc","interview","office");
                     return($self->expandByDataACL(undef,@l));
                     last;
                  }
               }
            }
         }
      }
   }
   if ($rec->{managedbyid}!=1 && $rec->{managedbyid}!=0 && 
       $rec->{cistatusid}<6){
      if ($self->IsMemberOf($rec->{managedbyid},["RContactAdmin"],"down")){
         my @l=("introdution","private","officeacc","office",
                "comments","control","name");
         return($self->expandByDataACL(undef,@l));
      }
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   return(1) if ($rec->{creator}==$userid && $rec->{cistatusid}<3);

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $rec=shift;
   my $userid="user";
   if (defined($rec)){
      $userid=$rec->{userid} if ($rec->{userid} ne "");
   }
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/userpic/$userid.jpg?".$cgi->query_string());
}



sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   return(1);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   $self->InvalidateCache($oldrec) if (defined($oldrec));
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   $self->NotifyAddOrRemoveObject($oldrec,undef,"fullname",
                                  "STEVuserchanged",110000001);
   return($self->SUPER::FinishDelete($oldrec));
}

sub getValidWebFunctions
{  
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(MyDetail SSHPublicKey 
          APIKeys AddrBook RightsOverview RightsOverviewLoader ImportUser)); 
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("base::user");
}





sub AddrBook
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>$self->T("Address book"));
   print $self->HtmlBottom(body=>1,form=>1);
}

sub APIKeys
{
   my $self=shift;
   my $userid=Query->Param("userid");
   $self->ResetFilter(); 
   $self->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>$self->T("Modify/View W5BaseAPI Keys"));
   printf("<script language=JavaScript>");
   printf("function dropAPI(id){");
   printf(" document.forms[0].elements['dropid'].value=id;");
   printf(" document.forms[0].submit();");
   printf("}");
   printf("</script>");
   if (defined($urec)){
      my $allowAPIkeyAccess=$self->allowAPIkeyAccess($urec);;
      my $ua=getModuleObject($self->Config,"base::useraccount");
      print $self->getParsedTemplate("tmpl/base.contact.APIKeys.head");
      if ($self->IsMemberOf("admin") ||
          $self->getCurrentUserId()==$urec->{userid} ||
          $allowAPIkeyAccess){ 
         my $ipaddr=Query->Param("ipaddr");
         $ipaddr=~s/[^0-9a-f.:, ]/x/gi;
         if ((my $dropid=Query->Param("dropid")) ne ""){
            $ua->SetFilter({account=>\$dropid,userid=>\$userid});
            my ($acrec,$msg)=$ua->getOnlyFirst(qw(ALL));
            if (defined($acrec)){
               $ua->ValidatedDeleteRecord($acrec);
            }
         }
         if (Query->Param("add") ne ""){
            my $apinum=$userid*time();
            my $apiname=base36($apinum);
            my $random_number1=int(rand(8888888888888))*time();
            my $random_number2=int(rand(9999999999999))*time();
            my $apitoken=lc(sprintf("%s%s%s",base36($userid),
                                 base36($random_number1*$random_number1),
                                 base36(time()*$random_number1)));
            $apitoken=TextShorter($apitoken,40);
            my $newkey={
               account=>'API-ACCOUNT/'.$apiname,
               ipacl=>$ipaddr,
               userid=>$userid,
               apitoken=>$apitoken
            };
            $ua->ValidatedInsertRecord($newkey);
         }
         my @msglist;
         my $msg="&nbsp;";
         if ($self->LastMsg()!=0){
            @msglist=$self->LastMsg();
         }
         else{
            $ipaddr=""; 
         }
         printf("<hr>");
         printf("<table margin=5 border=0 width=100%>");
         printf("<tr>");
         printf("<td width=1%% nowrap>%s</td>",
                $self->T("IP-Address(es):"));
         printf("<td><input type=text ".
                "style=\"width:100%\" value=\"%s\" name=ipaddr></td>",$ipaddr);
         printf("<td width=1%>".
                "<input style=\"cursor:pointer\" ".
                 "type=submit value=\"%s\" name=add></td>",
                    $self->T("create new key"));
         printf("</tr>");
         printf("</table>");

         @msglist=map({quoteHtml($_)} @msglist);
         $msg="<div class=lastmsg style=\"margin-left:3px\">".
              join("<br>\n",map({
           if ($_=~m/^ERROR/){
              $_="<font style=\"color:red;\">".$_."</font>";
           }
           if ($_=~m/^WARN/){
              $_="<font style=\"color:brown;\">".$_."</font>";
           }
           $_;
         } @msglist))."</div>";
         printf("%s",$msg);
         printf("<hr>");
         print("<input type=hidden name=userid value=\"$userid\">");
         print("<input type=hidden name=dropid value=\"\">");
      }
      $ua->ResetFilter();
      $ua->SetFilter({apitoken=>"![EMPTY]",userid=>\$userid});
      my @l=$ua->getHashList(qw(ALL));
      printf("<div style=\"width:100%;height:170px;overflow:auto\">");
      printf("<table border=0 margin=5 cellspacing=3 cellpadding=3 width=100%>");
      foreach my $apirec (@l){
        printf("<tr><td>");
        my $del="<img style=\"cursor:pointer\" title=\"".
                $self->T("delete key")."\" ".
                "onclick=\"dropAPI('".$apirec->{account}."');\" ".
                "src=\"../../base/load/minidelete.gif\" border=0>";
        printf("<table style=\"border-width:1px;border-style:solid\" ".
               "width=100%>");
        printf("<tr><td>%s</td><td width=40 rowspan=2 align=right ".
               "valign=top>%s</td></tr>",
               $apirec->{account},$del);
        printf("<tr><td>API-Key:%s</td></tr>",$apirec->{apitoken});
        printf("<tr><td colspan=2>IP-ACL:%s</td></tr>",$apirec->{ipacl});
        printf("</table>");
        printf("</td></tr>");
      }
      printf("</table>");
      printf("</div>");
   }
   print $self->HtmlBottom(body=>1,form=>1);
}


sub preQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;
   my $param=shift;

   if ($rec->{cistatusid}==4){
      if ($rec->{usertyp} eq "genericAPI"){
         my $allOk=0;
         foreach my $srec (@{$rec->{usersubst}}){
            if ($srec->{usersubstcontactusertyp} eq "user" &&
                $srec->{usersubstcontactcistatusid}==4){
               $allOk++;
            }
         }
         if (!$allOk){
            $self->ValidatedUpdateRecord($rec,{cistatusid=>6},{
                   userid=>\$rec->{userid}
            });
         }
      }
   }

}

sub SSHPublicKey
{
   my $self=shift;
   my $userid=Query->Param("userid");
   $self->ResetFilter(); 
   $self->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           body=>1,form=>1,
                           title=>$self->T("Modify/View SSH Public Key"));
   if (defined($urec)){
      my $opt={static=>{ssh1publickey=>$urec->{ssh1publickey},
                        ssh2publickey=>$urec->{ssh2publickey}}};
      if ($self->IsMemberOf("admin") ||
          $self->getCurrentUserId()==$urec->{userid}){ 
         if (Query->Param("save") ne ""){
            my $ssh1publickey=Query->Param("ssh1publickey");
            my $ssh2publickey=Query->Param("ssh2publickey");
            $opt->{static}->{ssh1publickey}=$ssh1publickey;
            $opt->{static}->{ssh2publickey}=$ssh2publickey;
            if ($self->ValidatedUpdateRecord($urec,
                         {ssh1publickey=>$ssh1publickey,
                          ssh2publickey=>$ssh2publickey},{userid=>\$userid})){
               $self->LastMsg(OK,"key has been stored");
            }
         }
         print $self->getParsedTemplate("tmpl/base.contact.SSHPublicKey.rw",$opt);
         print("<input type=hidden name=userid value=\"$userid\">");
      }
      else{
         print $self->getParsedTemplate("tmpl/base.contact.SSHPublicKey.ro",$opt);
      }
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub MyDetail
{
   my ($self)=@_;
   my $userid="?";
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{userid})){
      $userid=$UserCache->{userid};
   }
   Query->Param("userid"=>$userid);
   return($self->Detail());
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default name)) if ($param{mode} eq "HtmlDetail" &&
                                       !defined($param{current}));
   return(qw(header name picture default admcomments 
             comments nativcontact office 
             officeacc private personrelated introdution contacts
             userparam control groups usersubst userid userro ));
}

sub allowAPIkeyAccess
{
   my $self=shift;
   my $rec=shift;

   my $allowAPIkeyAccess=0;

   if (defined($rec) && $rec->{usertyp} eq "genericAPI"){
      foreach my $rec (@{$rec->{usersubst}}){
         if ($ENV{REMOTE_USER} eq $rec->{dstaccount} &&
             $rec->{active} eq "1"){
            $allowAPIkeyAccess++;
         }
      }
   }

   return($allowAPIkeyAccess);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   my @f;
   if (defined($rec) && ( ($self->getCurrentSecState()>1 && (
                            $rec->{ssh1publickey} ne "" || 
                            $rec->{ssh2publickey} ne ""))  || 
                         ($userid==$rec->{userid} ||
                          $self->IsMemberOf("admin")))){ 
      push(@f,($self->T("SSH Public Key")=>'SSHPublicKey'));
   }

   my $allowAPIkeyAccess=$self->allowAPIkeyAccess($rec);;

   if (defined($rec) &&
       ($rec->{userid} eq $userid || 
        $self->IsMemberOf("admin") ||
        $allowAPIkeyAccess)){
      if ($self->getCurrentSecState()>1 || $allowAPIkeyAccess>0){ 
         push(@f,($self->T("API-Keys")=>'APIKeys'));
      }
   }
   return(@f,$self->SUPER::getDetailFunctions($rec));
}

sub getDetailFunctionsCode
{
   my $self=shift;
   my $rec=shift;
   my $idname=$self->IdField->Name();
   my $id=$rec->{$idname};
   my $d=<<EOF;
function SSHPublicKey(id)
{
   showPopWin('SSHPublicKey?userid=$id',null,360,FinishSSHPublicKey);
}
function APIKeys(id)
{
   showPopWin('APIKeys?userid=$id',500,390,FinishAPIKeys);
}
function FinishSSHPublicKey()
{
}

function FinishAPIKeys()
{
}

EOF
   return($d.$self->SUPER::getDetailFunctionsCode($rec));
}


#
# This is the native API for all W5Base Modules to get the W5BaseID of
# a contact with AutoImport Option  (see: */ext/userImport.pm)
#
sub GetW5BaseUserID
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;   # userid | email | posix | dsid
   my $param=shift;

   if (($name=~m/\@/) && $useAs eq ""){
      $useAs="email";
   }

   if ($useAs eq "" || $name=~m/^\s*$/ || $name=~m/\s/ ||
       ($useAs ne "email" && 
        $useAs ne "posix" &&
        $useAs ne "userid" &&
        $useAs ne "dsid")){
      msg(ERROR,"invalid call '$name'/$useAs of GetW5BaseUserID ".
                "in base::user!");
      Stacktrace();
   }
   for(my $loopcnt=0;$loopcnt<2;$loopcnt++){
      $self->ResetFilter();
      if ($useAs eq "email"){
         my $n=lc($name);
         $self->SetFilter({emails=>\$n,cistatusid=>[3,4,5]});
      }
      elsif ($useAs eq "posix"){
         $self->SetFilter({posix=>\$name,cistatusid=>[3,4,5]});
      }
      elsif ($useAs eq "dsid"){
         $self->SetFilter({dsid=>\$name,cistatusid=>[3,4,5]});
      }
      elsif ($useAs eq "userid"){
         $self->SetFilter({userid=>\$name,cistatusid=>[3,4,5]});
      }
      else{
         return(undef);
      }
      my ($userrec,$msg)=$self->getOnlyFirst(qw(fullname posix userid dsid));
      if (defined($userrec)){
         if (wantarray()){
            return($userrec->{userid},{
                fullname=>$userrec->{fullname},
                posix=>$userrec->{posix},
                dsid=>$userrec->{dsid},
            });
         }
         else{
            return($userrec->{userid});
         }
      }
      if ($loopcnt==0){
         # try Import

         # e.g. 'tsciam::hans' forces import of user hans from ciam only
         my @parts=split('::',$name,2); 
         if ($#parts>0) {
            ($param->{force},$name)=@parts;
         }

         my @iobj=$self->getImportObjs($name,$useAs,$param);
         foreach my $k (@iobj) {
            msg(INFO,"try Import for $name ($useAs) with=$k");
            if (my $userid=$self->{userImport}->{$k}->processImport(
                   $name,$useAs,$param)){
               $name=$userid;
               $useAs="userid";
               last;
            }
         }
      }
   }

   return(undef);
}


sub getImportObjs
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;
   my @ret;

   if (!exists($self->{userImport})){
      $self->LoadSubObjs("ext/userImport","userImport");
   }

   if (defined($param->{force})) {
      my $src=$param->{force}.'::ext::userImport';
      push(@ret,$src) if (exists($self->{userImport}{$src}));
      return(@ret);
   }
   
   my %p;
   foreach my $k (sort(keys(%{$self->{userImport}}))){
     my $q=$self->{userImport}->{$k}->getQuality($name,$useAs,$param);
     $p{$k}=$q;
   }

   @ret=sort({$p{$a}<=>$p{$b}} keys(%p));
   return(@ret);
}


sub ImportUser
{
   my $self=shift;
   my $maxCnt=31;
   my $success=0;
   my %param=(quiet=>1);

   my $importnames=Query->Param("importname");
   my @importname=split(/\s+/,trim($importnames));
   my @imported; # imported contacts

   my @idhelp=();
   my @importObjs=$self->getImportObjs(undef,undef,\%param);
   foreach my $k (@importObjs) {
      if ($self->{userImport}{$k}->can('getImportIDFieldHelp')) {
         push(@idhelp,$self->{userImport}{$k}->getImportIDFieldHelp());
      }
   }
   my $idhelp=' ';
   $idhelp=' ('.join(', ',@idhelp).') ' if ($#idhelp!=-1);

   if (Query->Param("DOIT")){
      my $i=0;

      while ($i<=$#importname && $i<$maxCnt) {
         my $name=$importname[$i];
         my $atCnt=($name=~tr/@//);

         my $useAs;
         $useAs='dsid'  if ($atCnt==0);
         $useAs='email' if ($atCnt==1);

         if (defined($useAs)) {
            my @res=$self->GetW5BaseUserID($name,$useAs,{quiet=>1});
            if (defined($res[0]) &&
                !in_array(\@imported,$res[1]->{fullname})) {
               push(@imported,$res[1]->{fullname});
               $success++;
            }
         }

         $i++;
      }

      if ($success && $success==$#importname+1) {
         if ($success==1) {
            $self->LastMsg(OK,"User successful imported");
         }
         else {
            $self->LastMsg(OK,"%d user successful imported",$success);
         }
      }
      else {
         $self->LastMsg(WARN,"%d from %d user successful imported",
                             $success,$#importname+1);
      }

      Query->Delete("importname");
      Query->Delete("DOIT");
   }

   my $names=join("<br>",sort(@imported));
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importnames},
                           body=>1,form=>1,
                           title=>"Contact Import");
   print $self->getParsedTemplate("tmpl/minitool.user.import",
                                  {static=>{idhelp=>$idhelp,
                                            imported=>$names}});
   print $self->HtmlBottom(body=>1,form=>1);
}



sub jsExploreFormatLabelMethod
{
   my $self=shift;
   return("newlabel=newlabel.replace(' (','\\n(');");
}


sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;

   my $label=$self->T("add organisational tree");
   $methods->{'m100addUserOrgParentTree'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m100addUserOrgParentTree on \",this);
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          var app=this.app;
          app.pushOpStack(new Promise(function(methodDone){
             app.network.setOptions({ 
                layout: {
                   hierarchical: {
                     direction: 'UD',
                     sortMethod: 'hubsize',
                     treeSpacing: 500,
                     edgeMinimization:true
                   }
                 }
             } );
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'base::user');
                var w5grp=getModuleObject(cfg,'base::grp');

                var orgFinder=function(curkey,parentid,nlevel){
                    w5grp.SetFilter({
                       grpid:parentid
                    });

                    w5grp.findRecord(\"grpid,parentid,fullname,name\",
                                function(data){
                       if (data[0]){
                          var nodelevel=(data[0].fullname.split(\".\").length)
                          var nexkey=app.toObjKey('base::grp',data[0].grpid);
                          app.addNode('base::grp',data[0].grpid,data[0].name,{
                             level:nodelevel*2
                          });
                          app.addEdge(curkey,nexkey);
                          if (!!data[0].parentid){
                             app.pushOpStack(
                                new Promise(function(res,rej){
                                   orgFinder(nexkey,data[0].parentid,nlevel+1);
                                   res(1);
                                })
                             );
                          }
                          else{
                             //console.log(\"end of orgFinder\",app._opStack);
                          }
                       }

                    });
                };


                w5obj.SetFilter({
                   userid:dataobjid
                });
                w5obj.findRecord(\"userid,orgunits\",function(data){
                   console.log(\"found:\",data);
                   for(recno=0;recno<data.length;recno++){
                      for(subno=0;subno<data[recno].orgunits.length;subno++){
                         w5grp.SetFilter({
                            fullname:data[recno].orgunits[subno]
                         });
                         w5grp.findRecord(\"grpid,parentid,name,fullname\",
                            function(data){
                            var level=2;
                            var nodelevel=(data[0].fullname.split(\".\").length)
                            var curkey=app.toObjKey(dataobj,dataobjid);
                            var nexkey=app.toObjKey('base::grp',data[0].grpid);
                            app.addNode('base::grp',data[0].grpid,data[0].name,{
                                level:nodelevel*2
                            });
                            app.addEdge(curkey,nexkey);
                            if (!!data[0].parentid){
                               orgFinder(nexkey,data[0].parentid,level+1);
                            }
                         });
                      }
                   }
                   app.networkFitRequest=true;
                });
                \$(document).ajaxStop(function () {
                   methodDone(\"load of orgArea done\");
                });
             });
          }));
       },
       postExec:function(resultOfOpStack){
          var app=this.app;
          var maxLevel=0;
          app.node.forEach(function(e){
             if (e.dataobj=='base::grp'){
                if (maxLevel<e.level){
                   maxLevel=e.level;
                }
             }
          });
          app.node.forEach(function(e){
             if (e.dataobj=='base::user'){
                app.node.update({id:e.id,level:maxLevel+1});
             }
          });
          console.log(\"Start Layout of scenario\",resultOfOpStack);
       }
   ";

}


sub generateContextMap
{
   my $self=shift;
   my $rec=shift;

   my $d={
      items=>[]
   };
   my %item;


   my $imageUrl=$self->getRecordImageUrl(undef);
   my $cursorItem;

   my $cursorItem="base::user::".$rec->{userid};
   if ($cursorItem){
      my $title=$rec->{fullname};
      my $description=$rec->{email};
      my $itemrec={
         id=>$cursorItem,
         dataobj=>'base::user',
         dataobjid=>$rec->{userid},
         templateName=>'contactTemplate'
      };
      $item{$cursorItem}=$itemrec;
      push(@{$d->{items}},$itemrec);
   }
   my %baseorg;
   foreach my $grprec (@{$rec->{groups}}){
      if ($grprec->{is_orggrp}){  # only organisational groups view
         my $roles=$grprec->{roles};
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         if (in_array($roles,[orgRoles()])){
            $baseorg{$grprec->{grpid}}++;
         } 
      }
   }
   my $grp=$self->getPersistentModuleObject("base::grp");
   if (keys(%baseorg)){
      $grp->SetFilter({grpid=>[keys(%baseorg)],cistatusid=>'4'});
      my @l=$grp->getHashList(qw(fullname name grpid users description
                                 urlofcurrentrec));
      foreach my $grec (@l){
         my $gid="base::grp::".$grec->{grpid};
         if (!exists($item{$gid})){
            my $itemrec={
               id=>$gid,
               title=>$grec->{name},
               dataobj=>'base::grp',
               dataobjid=>$grec->{grpid},
               description=>$grec->{description},
               templateName=>'ultraWideTemplate'
            };
            $item{$gid}=$itemrec;
            push(@{$d->{items}},$itemrec);
            
         }
         foreach my $urec (@{$grec->{users}}){
            my $roles=$urec->{roles};
            $roles=[$roles] if (ref($roles) ne "ARRAY");
            if (in_array($roles,[orgRoles()])){
               my $uid="base::user::".$urec->{userid};
               if (!exists($item{$uid})){
                  my $itemrec={
                     id=>$uid,
                     dataobj=>'base::user',
                     dataobjid=>$urec->{userid},
                     templateName=>'contactTemplate',
                     parents=>[]
                  };
                  $item{$uid}=$itemrec;
                  push(@{$d->{items}},$itemrec);
               }
               if (!in_array($item{$uid}->{parents},$gid)){
                  push(@{$item{$uid}->{parents}},$gid);
               }
            }
         }
      }
      # fillup recursiv all parent groups




      #
   }
   {
      my $opobj=$self;
      my %id;
      foreach my $k (keys(%item)){
         if ($item{$k}->{dataobj} eq "base::user"){
            $id{$item{$k}->{dataobjid}}++;
         }
      }
      if (keys(%id)){
         $opobj->ResetFilter();
         $opobj->SetFilter({userid=>[keys(%id)]});
         foreach my $chkrec ($opobj->getHashList(qw(ALL))){
            my $k=$opobj->Self()."::".$chkrec->{userid};
            my $imageUrl=$opobj->getRecordImageUrl($chkrec);
            $item{$k}->{titleurl}=$chkrec->{urlofcurrentrec};
            $item{$k}->{titleurl}=~s#/ById/#/Map/#;
            $item{$k}->{image}=$imageUrl;
            $item{$k}->{title}=$chkrec->{fullname};
            $item{$k}->{title}=~s/ \(.*$//;
         }
      }
   }
   {
      my $opobj=$grp;
      my %id;
      foreach my $k (keys(%item)){
         if ($item{$k}->{dataobj} eq "base::grp"){
            $id{$item{$k}->{dataobjid}}++;
         }
      }
      if (keys(%id)){
         do{
            $opobj->ResetFilter();
            $opobj->SetFilter({grpid=>[keys(%id)]});
            foreach my $chkrec ($opobj->getHashList(qw(ALL))){
               my $k=$opobj->Self()."::".$chkrec->{grpid};
               if (!exists($item{$k})){
                  my $itemrec={
                     id=>$k,
                     title=>$chkrec->{name},
                     dataobj=>'base::grp',
                     dataobjid=>$chkrec->{grpid},
                     description=>$chkrec->{description},
                     templateName=>'ultraWideTemplate'
                  };
                  $item{$k}=$itemrec;
                  push(@{$d->{items}},$itemrec);
               }
               my $imageUrl=$opobj->getRecordImageUrl($chkrec);
               $item{$k}->{titleurl}=$chkrec->{urlofcurrentrec};
               $item{$k}->{titleurl}=~s#/ById/#/Map/#;
               $item{$k}->{image}=$imageUrl;
               delete($id{$chkrec->{grpid}});
               if ($chkrec->{parentid} ne ""){
                  my $pkey="base::grp::".$chkrec->{parentid};
                  if (!exists($item{$k}->{parents})){
                     $item{$k}->{parents}=[];
                  }
                  if (!in_array($item{$k}->{parents},$pkey)){
                     push(@{$item{$k}->{parents}},$pkey);
                  }
                  if (!exists($item{$pkey})){
                     $id{$chkrec->{parentid}}++;
                  }
               }
            }
         }while(keys(%id)!=0);
      }
   }

   if ($cursorItem){
      $d->{cursorItem}=$cursorItem;
   }

   $d->{enableMatrixLayout}=1;
   $d->{minimumMatrixSize}=4;
   $d->{maximumColumnsInMatrix}=3;
   if ($#{$d->{items}}>8){
      $d->{initialZoomLevel}="5";
   }


   #print STDERR Dumper($d);
   return($d);
}

1;
