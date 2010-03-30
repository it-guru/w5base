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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit 
        kernel::DataObj::DB 
        kernel::App::Web::InterviewLink
        kernel::CIStatusTools);



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

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'280',
                group         =>'name',
                readonly =>
                   sub{
                      my $self=shift;
                      return(1);
                    #  return(1) if (!$self->getParent->IsMemberOf("admin"));
                    #  return(0);
                   },
                prepRawValue   =>
                   sub{
                      my $self=shift;
                      my $d=shift;
                      my $current=shift;
                      my $secstate=$self->getParent->getCurrentSecState();
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
                      return($d);
                   },
                label         =>'Fullname',
                dataobjattr   =>'contact.fullname'),

      new kernel::Field::Text(
                name          =>'phonename',
                htmlwidth     =>'280',
                group         =>'name',
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


      new kernel::Field::Select(
                name          =>'usertyp',
                label         =>'Usertyp',
                htmleditwidth =>'100px',
                default       =>'extern',
                value         =>[qw(extern service user function)],
                dataobjattr   =>'contact.usertyp'),

      new kernel::Field::Link(
                name          =>'usertypid',
                label         =>'nativ Usertyp',
                dataobjattr   =>'contact.usertyp'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                group         =>['name','default'],
                readonly      =>
                   sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if ($self->getParent->IsMemberOf("admin"));
                      return(1) if (defined($rec) && 
                                    $rec->{cistatusid}>2 &&
                                    !$self->getParent->IsMemberOf("admin"));
                      return(0);
                   },
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>">0"},
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'name',
                label         =>'CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Id(
                name          =>'userid',
                label         =>'W5BaseID',
                size          =>'10',
                group         =>'userro',
                dataobjattr   =>'contact.userid'),
                                  
      new kernel::Field::Text(
                name          =>'givenname',
                readonly      =>sub{
                                   my $self=shift;
                                   my $current=shift;
                                   if ($current->{usertyp} ne "service"){
                                      return(0);
                                   }
                                   return(1);
                                },
                group         =>'name',
                label         =>'Givenname',
                dataobjattr   =>'contact.givenname'),
                                  
      new kernel::Field::Text(
                name          =>'surname',
                group         =>'name',
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
                dataobjattr   =>'contact.surname'),

      new kernel::Field::Text(
                name          =>'posix',
                label         =>'POSIX-Identifier',
                group         =>'userro',
                dataobjattr   =>'contact.posix_identifier'),

      new kernel::Field::Select(
                name          =>'secstate',
                label         =>'security state',
                value         =>['1','2','3','4'],
                transprefix   =>'SECSTATE.',
                group         =>'userro',
                dataobjattr   =>'contact.secstate'),

      new kernel::Field::Link(
                name          =>'secstateid',
                label         =>'Sec-StateID',
                dataobjattr   =>'contact.secstate'),

      new kernel::Field::SubList(
                name          =>'accounts',
                label         =>'Accounts',
                allowcleanup  =>1,
                readonly      =>1,
                group         =>'userro',
                vjointo       =>'base::useraccount',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['account','cdate'],
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
                label         =>'Room number',
                dataobjattr   =>'contact.office_room'),

      new kernel::Field::Phonenumber(
                name          =>'office_facsimile',
                group         =>['office','nativcontact'],
                label         =>'FAX-Number',
                dataobjattr   =>'contact.office_facsimile'),

      new kernel::Field::Text(
                name          =>'office_elecfacsimile',
                group         =>'office',
                label         =>'electronical FAX-Number',
                dataobjattr   =>'contact.office_elecfacsimile'),

      new kernel::Field::Number(
                name          =>'office_persnum',
                group         =>'officeacc',
                label         =>'Personal-Number',
                dataobjattr   =>'contact.office_persnum'),

      new kernel::Field::Number(
                name          =>'office_costcenter',
                group         =>'officeacc',
                weblinkto     =>'finance::costcenter',
                weblinkon     =>['costcenterid'=>'id'],
                label         =>'CostCenter',
                dataobjattr   =>'contact.office_costcenter'),

      new kernel::Field::Number(
                name          =>'office_accarea',
                group         =>'officeacc',
                label         =>'Accounting Area',
                dataobjattr   =>'contact.office_accarea'),

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
                label         =>'privat Street',
                dataobjattr   =>'contact.private_street'),

      new kernel::Field::Text(
                name          =>'private_zipcode',
                group         =>'private',
                label         =>'privat ZIP-Code',
                dataobjattr   =>'contact.private_zipcode'),

      new kernel::Field::Text(
                name          =>'private_location',
                group         =>'private',
                label         =>'privat Location',
                dataobjattr   =>'contact.private_location'),

      new kernel::Field::Phonenumber(
                name          =>'private_facsimile',
                group         =>'private',
                label         =>'privat FAX-Number',
                dataobjattr   =>'contact.private_facsimile'),

      new kernel::Field::Phonenumber(
                name          =>'private_elecfacsimile',
                group         =>'private',
                label         =>'privat electronical FAX-Number',
                dataobjattr   =>'contact.private_elecfacsimile'),

      new kernel::Field::Phonenumber(
                name          =>'private_mobile',
                group         =>'private',
                label         =>'privat Mobile-Phonenumber',
                dataobjattr   =>'contact.private_mobile'),

      new kernel::Field::Phonenumber(
                name          =>'private_phone',
                group         =>'private',
                label         =>'privat Phonenumber',
                dataobjattr   =>'contact.private_phone'),

      new kernel::Field::Select(
                name          =>'tz',
                label         =>'Timezone',
                group         =>'userparam',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'contact.timezone'),

      new kernel::Field::Select(
                name          =>'lang',
                label         =>'Language',
                htmleditwidth =>'50%',
                group         =>'userparam',
                value         =>['',LangTable()],
                dataobjattr   =>'contact.lang'),

      new kernel::Field::Select(
                name          =>'pagelimit',
                label         =>'Pagelimit',
                unit          =>'Entrys',
                htmleditwidth =>'50px',
                group         =>'userparam',
                value         =>[qw(10 15 20 30 40 50 100)],
                default       =>'20',
                dataobjattr   =>'contact.pagelimit'),

      new kernel::Field::Select(
                name          =>'dialermode',
                label         =>'PC Phone Dialer Mode',
                htmleditwidth =>'50%',
                group         =>'userparam',
                value         =>['',"Cisco WebDialer V1"],
                dataobjattr   =>'contact.dialermode'),

      new kernel::Field::Text(
                name          =>'dialeripref',
                group         =>'userparam',
                label         =>'PC Phone own country code',
                dataobjattr   =>'contact.dialeripref'),

      new kernel::Field::Text(
                name          =>'dialerurl',
                group         =>'userparam',
                label         =>'PC Phone Dialer URL',
                dataobjattr   =>'contact.dialerurl'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                prepRawValue   =>
                   sub{
                      my $self=shift;
                      my $d=shift;
                      my $current=shift;
                      my $secstate=$self->getParent->getCurrentSecState();
                      if ($secstate<2){
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

      new kernel::Field::Select(
                name          =>'winsize',
                label         =>'Window-Size',
                htmleditwidth =>'50%',
                htmldetail    =>0,           # die Sache ist noch nicht opti
                group         =>'userparam',
                value         =>['','normal','large'],
                container     =>'options'),

      new kernel::Field::Select(
                name          =>'sms',
                label         =>'SMS Notification',
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

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'contact.allowifupdate'),

      new kernel::Field::Textarea(
                name          =>'ssh1publickey',
                label         =>'SSH1 Public Key',
                group         =>'control',
                htmldetail    =>0,
                dataobjattr   =>'contact.ssh1publickey'),

      new kernel::Field::Textarea(
                name          =>'ssh2publickey',
                label         =>'SSH2 Public Key',
                group         =>'control',
                htmldetail    =>0,
                dataobjattr   =>'contact.ssh2publickey'),

      new kernel::Field::Textarea(
                name          =>'similarcontacts',
                htmldetail    =>0,
                label         =>'simialr contacts',
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
                searchable    =>0,
                group         =>'picture',
                dataobjattr   =>'contact.picture'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'userro',
                label         =>'Creator',
                dataobjattr   =>'contact.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'userro',
                label         =>'Owner',
                dataobjattr   =>'contact.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'userro',
                label         =>'Editor',
                dataobjattr   =>'contact.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'userro',
                label         =>'RealEditor',
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

      new kernel::Field::Date(
                name          =>'lastlogon',
                readonly      =>1,
                group         =>'userro',
                searchable    =>0,
                depend        =>["accounts"],
                onRawValue    =>\&getLastLogon,
                label         =>'Last-Logon'),

      new kernel::Field::Text(
                name          =>'lastlang',
                readonly      =>1,
                group         =>'userro',
                depend        =>["accounts"],
                onRawValue    =>\&getLastLogon,
                searchable    =>0,
                label         =>'Last-Lang'),

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
                vjoininhash   =>['group','grpid','roles','cdate']),

      new kernel::Field::Text(
                name          =>'groupnames',
                label         =>'Groupnames',
                group         =>'groups',
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
                vjointo       =>'base::lnkgrpuser',
                vjoinbase     =>['lineroles'=>[orgRoles()]],
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>['group']),

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
                vjoindisp     =>['dstaccount','active','cdate']),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments', 
                label         =>'Comments',
                dataobjattr   =>'contact.comments'),

      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'contact.lastqcheck'),

   );
   $self->{CI_Handling}={uniquename=>"fullname",
                         uniquesize=>255};
   $self->setWorktable("contact");
   $self->LoadSubObjs("user");
   $self->setDefaultView(qw(fullname cistatus usertyp));
   return($self);
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
                      logonbrowser=>'!SOAP::*'}); # exclude SOAP logons
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
   my $wrgroups=shift;

   my $usertyp=effVal($oldrec,$newrec,"usertyp");
   if (!$self->IsMemberOf("admin")){
      if (!defined($oldrec)){
         if ($usertyp eq "" || $usertyp eq "user"){
            $self->LastMsg(ERROR,"you are not autorized to create these ".
                                 "usertyp");
            return(0);
         }
      }
      delete($newrec->{secstate});
   }
   my $userid=$self->getCurrentUserId();
   if (defined($oldrec) && $oldrec->{userid}==$userid){
      delete($newrec->{cistatusid});
   }
   else{
      if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
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
   if (!defined($oldrec)){
      $newrec->{secstate}=$self->Config->Param("DefaultUserSecState");
   }
   my $usertyp=effVal($oldrec,$newrec,"usertyp");
   $newrec->{surname}="FMB" if ($usertyp eq "function");
   if ($usertyp eq "service"){
      $newrec->{givenname}="";
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
               if ($sshkey=~m/^ssh-dss\s+\S{100,600}/){
                  $k{$sshkey}=1;
               }
               else{
                  $fail++;
               }
            }
         }
         if ($fail){
            $self->LastMsg(ERROR,"invalid ssh-dss SSH2 key format");
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
   if ($usertyp eq "service"){
      my $email=effVal($oldrec,$newrec,"email");
      $newrec->{fullname}="service: ".$newrec->{fullname};
   }
   my $fullname=effVal($oldrec,$newrec,"fullname");
   msg(INFO,"fullname=$fullname");
   if ($fullname eq "" || ($fullname=~m/;/)){
      $self->LastMsg(ERROR,"invalid given or resulted fullname");
      return(0);
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
   if (defined($newrec->{email})){
      $newrec->{email}=undef if ($newrec->{email} eq "");
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   if (exists($newrec->{picture})){
      if ($newrec->{picture} ne ""){
         no strict;
         my $f=$newrec->{picture};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>10240){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{picture}=$pic;
      }
      else{
         $newrec->{picture}=undef;
      }
   }


   return(1);
}

sub FinishWrite
{  
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   $self->InvalidateCache($oldrec) if (defined($oldrec));
   $self->ValidateUserCache();
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   $self->NotifyAddOrRemoveObject($oldrec,$newrec,"fullname",
                                  "STEVuserchanged",110000001);

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


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   my @pic;
   my $userid=$self->getCurrentUserId();
   my @gl;
   #if ($userid eq $rec->{userid} || $self->IsMemberOf("admin")){
   #   push(@pic,"picture");
   #}
   if ($self->IsMemberOf("admin")){
      push(@pic,"picture","roles","interview","qc");
   }
   if ($rec->{usertyp} eq "extern"){
      @gl=qw(header name default comments groups userro control 
                office private);
   }  
   elsif ($rec->{usertyp} eq "function"){
      if ($self->IsMemberOf("admin")){
         @gl=qw(header name default nativcontact comments 
                   control userro);
      }
      else{
         @gl=qw(header name default nativcontact comments userro);
      }
   }  
   elsif ($rec->{usertyp} eq "service"){
      @gl=qw(header name default comments groups usersubst userro 
                control userparam);
   }  
   else{
      @gl=(@pic,
             qw(default name office officeacc private userparam groups 
                userro control usersubst header qc interview));
   }
   my $secstate=$self->getCurrentSecState();
   if ($rec->{userid}!=$userid){
      if ($secstate<2){
         @gl=grep(/^(name|header)$/,@gl);
      }
      elsif ($secstate<3){
         @gl=grep(/^(name|header|office|default|groups|comments|nativcontact|qc)$/,@gl);
      }
      elsif ($secstate<4){
         @gl=grep(/^(name|header|office|officeacc|private|default|groups|comments|nativcontact|qc)$/,@gl);
      }
   }
   if ($userid==$rec->{userid}){
      push(@gl,"personrelated","interview");
   }
   else{
      # check if the user has a direct boss
      my $g=$self->getField("groups")->RawValue($rec);
      if (ref($g) eq "ARRAY"){
         foreach my $grp (@$g){
            if (ref($grp->{roles}) eq "ARRAY"){
               foreach my $orole ($self->orgRoles()){
                  if (grep(/^$orole$/,@{$grp->{roles}})){
                     if ($self->IsMemberOf($grp->{grpid},["RBoss"],"direct")){
                        push(@gl,"personrelated","private","interview");
                     }
                  }
               }
            }
         }
      }
      if (!grep(/^personrelated$/,@gl)){
         if ($self->IsMemberOf("admin")){ 
            push(@gl,"personrelated","private","interview");
         }
      }
   }
 

   return(@gl);
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


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","name") if (!defined($rec));
   return(undef) if (!defined($rec));
   if ($self->IsMemberOf("admin")){
      return(qw(default name office private userparam groups usersubst control
                comments header picture nativcontact userro
                interview));
   }
   my $userid=$self->getCurrentUserId();
   if ($userid eq $rec->{userid} ||
       ($rec->{creator}==$userid && $rec->{cistatusid}<3)){
      return("name","userparam","office","officeacc","private","nativcontact",
             "usersubst","control","officeacc","interview");
   }
   # check if the user has a direct boss
   my $g=$self->getField("groups")->RawValue($rec);
   if (ref($g) eq "ARRAY"){
      foreach my $grp (@$g){
         if (ref($grp->{roles}) eq "ARRAY"){
            foreach my $orole ($self->orgRoles()){
               if (grep(/^$orole$/,@{$grp->{roles}})){
                  if ($self->IsMemberOf($grp->{grpid},["RBoss"],"direct")){
                     return("personrelated","interview");
                     last;
                  }
               }
            }
         }
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
          AddrBook)); 
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
   return(qw(header name picture default comments nativcontact office 
             officeacc private userparam control groups usersubst));
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   my @f;
   if ($self->getCurrentSecState()>1){ 
      @f=($self->T("SSH Public Key")=>'SSHPublicKey');
   }
   if (!defined($rec) || ($rec->{ssh1publickey} eq "" && 
                          $rec->{ssh2publickey} eq "" &&
       !($self->IsMemberOf("admin")) && !($userid==$rec->{userid}))){
      return($self->SUPER::getDetailFunctions($rec));
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
function FinishSSHPublicKey()
{
}

EOF
   return($d.$self->SUPER::getDetailFunctionsCode($rec));
}




#sub isQualityCheckValid
#{
#   return(1);
#}





1;
