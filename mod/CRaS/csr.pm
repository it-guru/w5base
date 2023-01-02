package CRaS::csr;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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

use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use itil::lib::Listedit;
use Date::Parse;
use DateTime;
use Crypt::OpenSSL::X509 qw(FORMAT_PEM FORMAT_ASN1);
use Crypt::PKCS10;

use vars qw(@ISA);

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

# State-Flow:
#
# captured/erfasst  (1) = requestor has stored the PKCS10 request
#                         in this state, all tsm/opm and businessteam users
#                         can update the request.
#                         On store, a message will be send to applmgr.
# accepted/     
# angenommen        (2) = from csteam the request has been accepted 
#                       
# sign in progress/     
# signieren         (3) = from csteam the request has been trasferted to CA
#                       
# signed /signiert  (4) = cs team has stored the signresult from CA
#                       
# renewal requested (5) = requestor has requested a renewal (process from
#                         now is the same as on "accepted")
# disposed of wasted/   
# veraltet/gelöscht (6) = entry is deleted



sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'csr.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                readonly      =>1,
                group         =>'default',
                dataobjattr   =>'csr.name'),

      new kernel::Field::Select(
                name          =>'state',
                htmltablesort =>'Number',
                selectfix     =>1,
                htmlwidth     =>'80px',
                label         =>'Certificate state',
                htmleditwidth =>'50%',
                transprefix   =>'CSRSTATE.',
                getPostibleValues=>sub{
                   my $self=shift;
                   my $current=shift;
                   my $newrec=shift;
                   my $mode=shift;
                   my $app=$self->getParent();
                   my @states=qw(1 2 3 4 5 6);

                   my @r;
                   foreach my $st (@states){
                      if ($app->isDataInputFromUserFrontend()){
                         if (!defined($current)){
                          #  next if ($st ne "1");
                         }
                         else{ 
                            if ($current->{rawstate} eq "6"){
                               if (!in_array($st,[qw(6)])){
                                  next;
                               }
                            }
                            if ($current->{rawstate} eq "5"){
                               if (!in_array($st,[qw(5 6)])){
                                  next;
                               }
                            }
                            if ($current->{rawstate} eq "4"){
                               if ($current->{refno} ne "" &&
                                   ($current->{applid} ne "" &&
                                    $current->{applid} ne "0")){
                                  if (!in_array($st,[qw(4 5 6)])){
                                     next;
                                  }
                               }
                               else{  # verlaengerung nur mit refno moeglich
                                  if (!in_array($st,[qw(4 6)])){
                                     next;
                                  }
                               }
                            }
                            if ($current->{rawstate} eq "2"){
                               if (!in_array($st,[qw(3 2 6)])){
                                  next;
                               }
                            }
                            if ($current->{rawstate} eq "3"){
                               if (!in_array($st,[qw(4 3 6)])){
                                  next;
                               }
                            }
                            if ($current->{rawstate} eq "1"){
                               if ($app->IsMemberOf([$current->{csgrpid},
                                                     "admin"])){
                                  if (!in_array($st,[qw(1 2 3 6)])){
                                     next;
                                  }
                               }
                               else{
                                  if (!in_array($st,[qw(1 6)])){
                                     next;
                                  }
                               }
                            }
                         }
                      }
                      push(@r,$st,$app->T("CSRSTATE.".$st));
                   }
                   return(@r);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0);
                },
                dataobjattr   =>'csr.status'),

      new kernel::Field::Text(
                name          =>'rawstate',
                label         =>'Raw Certificate State',
                selectfix     =>1,
                htmldetail    =>0,
                dataobjattr   =>'csr.status'),

      new kernel::Field::Link(
                name          =>'applid',
                label         =>'Application ID',
                dataobjattr   =>'csr.applid'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'related application',
                vjointo       =>'itil::appl',
                group         =>['default','request'],
                vjoinon       =>['applid'=>'id'],
                htmldetail    =>'NotEmptyOrEdit',
                vjoineditbase =>{cistatusid=>">2 AND <5"},
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                vjoindisp     =>'name'),
                
      new kernel::Field::TextDrop(
                name          =>'csteam',
                label         =>'Certificate Service Team',
                group         =>'source',
                readonly      =>1,
                vjointo       =>'CRaS::csteam',
                vjoinon       =>['csteamid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'csteam.name'),
                
      new kernel::Field::Link(
                name          =>'csteamid',
                label         =>'CS Team ID',
                dataobjattr   =>'csr.csteam'),

      new kernel::Field::Link(
                name          =>'csteamgrpid',
                label         =>'CS Team Group ID',
                dataobjattr   =>'csteam.grp'),

      new kernel::Field::TextDrop(
                name          =>'csgroup',
                label         =>'Service Group',
                group         =>'source',
                readonly      =>1,
                vjointo       =>'base::grp',
                vjoinon       =>['csgrpid'=>'grpid'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'grp.fullname'),
                
      new kernel::Field::Link(
                name          =>'csgrpid',
                selectfix     =>1,
                label         =>'ServiceGroup ID',
                dataobjattr   =>'grp.grpid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                group         =>['default','request'],
                dataobjattr   =>'csr.comments'),

#      new kernel::Field::Text(
#                name          =>'sslcertdocname',
#                label         =>'SSL-Certificate-Document Name',
#                searchable    =>0,
#                uploadable    =>0,
#                readonly      =>1,
#                htmldetail    =>0,
#                dataobjattr   =>'csr.sslcertdocname'),

      new kernel::Field::Text(
                name          =>'sslcertcommon',
                label         =>'SSL-Certificate Common Name',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'csr.sslcertcommon'),

      new kernel::Field::Text(
                name          =>'sslaltnames',
                label         =>'SSL-Certificate alternate Names',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'csr.sslaltnames'),

      new kernel::Field::Text(
                name          =>'sslcertorg',
                label         =>'SSL-Certificate Organisation',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'csr.sslcertorg'),

      new kernel::Field::SubList(
                name          =>'followupcsr',
                label         =>'followup CSR',
                group         =>'followupcsr',
                htmldetail    =>'NotEmpty',
                vjointo       =>'CRaS::csr',
                vjoinon       =>['refno'=>'replacedrefno'],
                vjoindisp     =>['name','refno','state']),

      new kernel::Field::Text(
                name          =>'editrefno',
                label         =>'CA Reference No.',
                group         =>'caref',
                dataobjattr   =>'csr.refno'),

      new kernel::Field::Text(
                name          =>'refno',
                label         =>'CA Reference No.',
                htmldetail    =>'NotEmpty',
                htmlwidth     =>'60',
                group         =>'detail',
                selectfix     =>1,
                dataobjattr   =>'csr.refno'),

      new kernel::Field::Text(
                name          =>'replacedrefno',
                label         =>'CA replaced Ref. No.',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                weblinkto     =>'CRaS::csr',
                weblinkon     =>['replacedrefno'=>'refno'],
                dataobjattr   =>'csr.replacedrefno'),

      new kernel::Field::Text(
                name          =>'spassword',
                label         =>'CA Service-Password',
                group         =>'detail',
                history       =>0,
                searchable    =>0,
                prepRawValue  =>sub{
                   my $self=shift;
                   my $app=$self->getParent();
                   my $d=shift;
                   my $current=shift;
                   if (!$app->IsMemberOf([$current->{csgrpid},"admin"])){
                      $d=~s/./?/g;
                   }
                   return($d);
                },
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'csr.spassword'),

      new kernel::Field::Select(
                name          =>'expnotifyleaddays',
                htmleditwidth =>'280px',
                default       =>'56',
                htmldetail    =>0,
                label         =>'Expiration notify lead time',
                value         =>['14','21','28','56','70'],
                transprefix   =>'EXPNOTIFYLEAD.',
                translation   =>'itil::applwallet',
                dataobjattr   =>'csr.expnotifyleaddays'),

      new kernel::Field::Date(
                name          =>'sslexpnotify1',
                history       =>0,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'1.Notification of Certificate Expiration',
                dataobjattr   =>'csr.expnotify1'),

      new kernel::Field::Date(
                name          =>'sslexpnotify2',
                history       =>0,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'2.Notification of Certificate Expiration',
                dataobjattr   =>'csr.expnotify2'),

      new kernel::Field::Text(
                name          =>'ssslsubject',
                label         =>'SSL-Certificate Owner',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'csr.ssslsubject'),

      new kernel::Field::File(
                name          =>'sslcert',
                label         =>'certificate request',
                group         =>['detail','request'],
                maxsize       =>65533,
                readonly      =>1,
                searchable    =>0,
                uploadable    =>0,
                allowempty    =>0,
                allowdirect   =>1,
                dataobjattr   =>'csr.sslcert'),

      new kernel::Field::Text(
                name          =>'ssslissuerdn',
                label         =>'SSL-Certificate Issuer DN',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'csr.ssslissuer'),

      new kernel::Field::Text(
                name          =>'ssslserialno',
                label         =>'SSL-Certificate Serial No.',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'csr.ssslserialno'),

      new kernel::Field::Date(
                name          =>'ssslstartdate',
                label         =>'SSL-Certificate begin',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'csr.ssslstartdate'),

      new kernel::Field::Date(
                name          =>'ssslenddate',
                label         =>'SSL-Certificate end',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'csr.ssslenddate'),

      new kernel::Field::Link(
                name          =>'ssslcertfilename',
                label         =>'Download-Filename signed certificate',
                depend        =>['name'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my $fld=$self->getParent->getField("name");
                    my $name=lc($fld->RawValue($current));
                    $name=~s/\s*//g;
                    $name=~s/[^a-z0-9_.-]//gi;
                    $name="SingedCert" if ($name eq "");
                    return($name.".pem");
                }),
  

      new kernel::Field::File(
                name          =>'ssslcert',
                label         =>'signed certificate',
                group         =>['detail'],
                types         =>['pem'],
                filename      =>'ssslcertfilename',
                maxsize       =>65533,
                readonly      =>1,
                searchable    =>0,
                uploadable    =>0,
                allowempty    =>0,
                allowdirect   =>1,
                dataobjattr   =>'csr.ssslcert'),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'csr.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'csr.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'csr.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'csr.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'csr.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'csr.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'csr.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'csr.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'csr.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'csr.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'csr.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(csr.id,35,'0')"),

   );
   $self->setDefaultView(qw(state mdate sslcertcommon appl));
   $self->setWorktable('csr');
   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };

   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/certificate.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $worktable="csr";
   my $from="$worktable join csteam ".
            "on $worktable.csteam=csteam.id ".
            "left outer join grp on csteam.grp=grp.grpid ";

   return($from);
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin support w5base.itil.applcsr.read)])) {
      my @addflt;
      my $userid=$self->getCurrentUserId();
      my %grps=$self->getGroupsOf($userid,"RMember","up");
      my @grpids=keys(%grps);
      @grpids=qw(-99) if ($#grpids==-1);

      my $applobj=getModuleObject($self->Config,'itil::appl');
      $applobj->SetFilter([{sectarget=>\'base::user',
                            sectargetid=>\$userid,
                            secroles=>"*roles=?write?=roles* ".
                                      "*roles=?privread?=roles*"},
                           {sectarget=>\'base::grp',
                            sectargetid=>\@grpids,
                            secroles=>"*roles=?write?=roles* ".
                                      "*roles=?privread?=roles*"},
                           {databossid=>\$userid},
                           {applmgrid=>\$userid},
                           {tsmid=>\$userid},
                           {tsm2id=>\$userid},
                           {opmid=>\$userid},
                           {opm2id=>\$userid},
                           {semid=>\$userid},
                           {sem2id=>\$userid},
                           {delmgrid=>\$userid},
                           {delmgr2id=>\$userid}]);
      my @secappl=map($_->{id},$applobj->getHashList(qw(id)));

      push(@addflt,{applid=>\@secappl});
      push(@addflt,{csgrpid=>\@grpids});
      push(@flt,\@addflt);
   }

   return($self->SetFilter(@flt));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("request") if (!defined($rec));

   if ($self->IsMemberOf("admin")){
      return(qw(default caref));
   }
   if ($rec->{state}==1 || $rec->{state}==4){
      if ($self->itil::lib::Listedit::isWriteOnApplValid(
                                          $rec->{applid},"technical")) {
         return("default");
      }
   }
   my $userid=$self->getCurrentUserId();


   if ($rec->{state}==2){
      if ($rec->{owner}==$userid){
         my @l=("default","caref");
         return(@l);
      }
   }
   else{
      if ($self->IsMemberOf($rec->{csgrpid})){
         my @l=("default");
         if ($rec->{state}==1 || $rec->{state}==3){
            push(@l,"caref");
         }
         return(@l);
      }
   }
   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("request") if (!defined($rec));

   my @l=();

   if ($rec->{rawstate}>0){
      push(@l,qw(history default detail header source));
   }
   if ($rec->{rawstate}==1 || $rec->{rawstate}==2 ||
       $rec->{rawstate}==3){
      push(@l,qw(caref));
   }
   if ($rec->{rawstate}==5 || $rec->{rawstate}==6){
      push(@l,qw(followupcsr));
   }
   return(@l);
}

sub parseCertDate
{
   my $self=shift;
   my $certdate=shift;

   my $timestamp=(str2time($certdate)); # convert to Unix timestamp
   return(undef) if(!defined($timestamp));

   my $dt=DateTime->from_epoch(epoch=>$timestamp);
   return($dt->ymd.' '.$dt->hms); # valid mySQL datetime format
}


sub formatedMultiline
{
   my $self=shift;
   my $entryobjs=shift;
   my %elements;
   my $multiline='';

   foreach my $entry (@$entryobjs) {
      my ($key,$val)=split(/=/,$entry->as_string(1));
      $elements{$key}=$val;
   }

   my @keylen=sort({$b<=>$a} map({length} keys(%elements)));

   foreach my $l (sort(keys(%elements))) {
      $multiline.=sprintf("%-*s = %s\n",$keylen[0],$l,$elements{$l});
   }

   return($multiline);
}


sub getCSTeamIDbyApplid
{
   my $self=shift;
   my $applid=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $csteamid;
   my $csteamaccess=0;

   my $appl=getModuleObject($self->Config,"itil::appl");
   $appl->SetFilter({id=>\$applid});
   my ($arec)=$appl->getOnlyFirst(qw(ALL));
   my @org;
   if (defined($arec)){
      my @grp;

      my $team=$arec->{businessteam};
      if ($team ne ""){
         my @team=split(/\./,$team);
         for(my $c=0;$c<=$#team;$c++){
            push(@org,join(".",@team[0..$c])); 
         }
      }

      my $responseorg=$arec->{responseorg};
      if ($responseorg ne ""){
         my @responseorg=split(/\./,$responseorg);
         for(my $c=0;$c<=$#responseorg;$c++){
            push(@org,join(".",@responseorg[0..$c])); 
         }
      }
      @org="-1" if ($#org==-1);
   }
   my $csteam=getModuleObject($self->Config,"CRaS::csteam");
   if ($self->isDataInputFromUserFrontend()){
      $csteam->SetFilter({orgarea=>\@org});
   }
   else{
      $csteam->SetFilter({});   # allow all on Server-Jobs
   }
   my @l=$csteam->getHashList(qw(orgarea grpid id));
   if ($#l>=0){
      $csteamid=$l[0]->{id}; 
      if ($l[0]->{grpid} ne ""){
         if ($self->IsMemberOf([$l[0]->{grpid}])){
            $csteamaccess++;
         }
      }
   }
   return($csteamid,$csteamaccess);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

#   if ($self->isDataInputFromUserFrontend() && !defined($oldrec)){
#      if ($newrec->{sslcert} eq ""){
#$newrec->{sslcert}=<<EOF;
#-----BEGIN CERTIFICATE REQUEST-----
#MIIE9DCCAtwCAQAwga4xCzAJBgNVBAYTAkRFMQwwCgYDVQQIDANOUlcxDTALBgNV
#BAcMBEJvbm4xITAfBgNVBAoMGERldXRzY2hlIFRlbGVrb20gSVQgR21iSDEXMBUG
#A1UECwwOVGVsZWtvbS1JVCBQVkcxHjAcBgNVBAMMFXNob3BwbGFuZXIudGVsZWtv
#bS5kZTEmMCQGCSqGSIb3DQEJARYXamFuLmthbmRhQHQtc3lzdGVtcy5jb20wggIi
#MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDBXfpSunBMPInekJ1tfVOq0shs
#WHIjXEN+HhjSEgmYmER9h+Piy7nZ0FNlBR2Ii2bqwc64NTNarxUjHEc4751QEtFr
#FZ89MNQpv0iQmtbvIEx0UYdzG/+m6HoHpPjFputw7Jh9iDe2r4FNjR5+rck66Dv2
#noCtthhz/r+S4Rvj7DtK2igxflLHaujkivV70GF5bsP4HXqpo5r7DC22KsaBKqpF
#6TI28O4VpZUTYXktaECJmaoLYzUr4dwZXTX2OufDJALu0azk6ZVFxhrJsXJAeJ8K
#gqIcbkS+1+vtVg4/H5cfCQWNfw0M7eYl/tsk+L5CiRA1lXsb7J2+/5EZmgTnDhrL
#Z++WsfhsFW8T+n1hI0TAlTfYCJ/TvYjHFhiM9EfaqMw9dC3id50K2W8OeDMaqy3G
#P4iolbVhBaH8HYXRphpTObD5HEh4fRrNmjTHsSwOeJd/GrWY3m5okjtMhxy4Mp4a
#9lyxBCHUMRoL4ycH69djIayMO5VUnwtxm2iZvNV/Iwct7odHyHhDDolbKinK5Zry
#ZJGzib9HjiXcY2vU1Wc/YCGKTOyYtTgs7KG1MyQ8VAK1ge7trRw4EfgTVLZqXzZ6
#NNqlcCHuZb6uKfWbbFFeUZjhabCrbogx+bSwzkRVCthP4WeKwlIJ1l2D3+eIDQ2k
#k61yx/wZVmLJmNamMQIDAQABoAAwDQYJKoZIhvcNAQELBQADggIBAAkH6nr064K+
#k1zekqu1c14poD5MJ3ObizY8RxsAcjpVFbXqPQxfU9vRbqMJRpgSc9DOtXyWxS+c
#wNQlHgLiEIgyQ9W8LN+glg+g5t5QwuAbdd/qXXGQCyle8fkvXrkfV/GrDBKoC5Pi
#BplZZdBAW0wwZKmyDpko0d5HjqMdxXGSZlECCoSeTh0v+82FbPca221f28jYJMSp
#A12QugNO+TAm25+xAXU8ZkSl8AZL2Z8SYNTUgSQSYRc9pOr4w9xSCTH3jXBLYh64
#OblTH+8GDl7+4tcTn+86Dm99iJV71/jddZslQM2mw6gWsvbGQn/djD1Dj35yM/Fn
#q3asPXwmwZ33/AOCWrTsejfh6lO5Ujo28RtynqhLdw3WSrTc41bBIDiAL7gxW8yY
#zP+Qs3xlphOqGlPHxuaeAKTXTHC2axa4GMSA15f+qSnVBhaBsfGew/SOqodbUCj5
#teblY+jsRAPBrxO4cxQ/6aM5morEPNkeh4N86y6XIJBwH6Gn0ote92kk7X0331t0
#sjE8ipHjZeA4R+4G/FuQotrxkge/KRjb5Q/mXW3/oKN/ZPI1zp+PHu6wSue8GIjF
#7MOb5z/4YrkCfgfayYN9PVfuZfsg5gmESJil5SP/lfqz6mE9mvOTRc+IL4jSHdEh
#m2U/7Rd5u0FxEoIjT84/wX1GIBmp0+sW
#-----END CERTIFICATE REQUEST-----
#EOF
#      }
#   }
   #if (effVal($oldrec,$newrec,'shortdesc') eq '') {
   #   $self->LastMsg(ERROR,"No brief description specified");
   #   return(0);
   #}

   my $csteamaccess=0;
   if (!defined($oldrec)){
      if (!exists($newrec->{state}) && !exists($newrec->{rawstate})){
         $newrec->{state}=1;
      }
      my $applid=effVal($oldrec,$newrec,"applid"); 
      my $csteamid;
      ($csteamid,$csteamaccess)=$self->getCSTeamIDbyApplid($applid,
                                                           $oldrec,$newrec);
      if (defined($csteamid)){
         $newrec->{csteamid}=$csteamid;
      }
   }
   if (!defined($oldrec) && !defined($newrec->{csteamid})){
      $self->LastMsg(ERROR,
        "unable to find Certificate-Service Team for selected application");
      return(0);
   }



   if (!exists($newrec->{state}) && $newrec->{editrefno} ne "" &&
       in_array(effVal($oldrec,$newrec,"state"),[qw(1 2)])){
      $newrec->{state}="3";
   }

   if ($self->isDataInputFromUserFrontend()){
      if (effVal($oldrec,$newrec,'applid') eq '') {
         $self->LastMsg(ERROR,"No application specified");
         return(0);
      }
      my $applid=effVal($oldrec,$newrec,"applid"); 
      my ($csteamid,$csteamaccess);
      if (effChanged($oldrec,$newrec,"state")){
         ($csteamid,$csteamaccess)=$self->getCSTeamIDbyApplid(
                                   $applid, $oldrec,$newrec);
      }
      if (effChanged($oldrec,$newrec,"state") && 
          $newrec->{state} eq "5"){
         if (!defined($csteamid)){
            $self->LastMsg(ERROR,
                 "new record would be out of a serviceteam scope");
            return(0);
         }
      }
      if (!$self->itil::lib::Listedit::isWriteOnApplValid($applid,"technical")){
         if (!$csteamaccess && !$self->IsMemberOf($oldrec->{csgrpid})){
            $self->LastMsg(ERROR,"no write access on specified application");
            return(0);
         }
      }
   }

   if ($self->isDataInputFromUserFrontend()){
      if (!defined($oldrec) && effVal($oldrec,$newrec,'sslcert') eq '') {
         # Wenn kein sslcert angegeben, dann MUSS alterativ 
         # name, replacedrefno und spassword vorhanden sein. In diesem
         # Fall wäre es dann eine Erneuerung eines Certs aus der XLS
         if ($newrec->{name} eq "" ||
             $newrec->{replacedrefno} eq "" ||
             $newrec->{spassword} eq ""){
            $self->LastMsg(ERROR,"no csr file specified");
            return(0);
         }
      }
   }
   if (effChanged($oldrec,$newrec,"state") && $newrec->{state} eq "4"){
      if ($self->isDataInputFromUserFrontend()){
         if (effVal($oldrec,$newrec,"ssslcert") eq ""){
            $self->LastMsg(ERROR,
                   "sigend state only allowed with singed cert file");
            return(0);
         }
      }
      $newrec->{sslexpnotify1}=undef;
      $newrec->{sslexpnotify2}=undef;
   }

   if (effChanged($oldrec,$newrec,"expnotifyleaddays")){
      $newrec->{sslexpnotify1}=undef;
      $newrec->{sslexpnotify2}=undef;
   }


   if (effChangedVal($oldrec,$newrec,'sslcert')) {
      my $sslcertfile=effVal($oldrec,$newrec,"sslcert");

      Crypt::PKCS10->setAPIversion(0);
      my $pkcs;
      # try multiple file formats
      eval('$pkcs=Crypt::PKCS10->new($sslcertfile);');
      if ($@ ne "") {
         $self->LastMsg(ERROR,"Unknown file format - PKCS10 required");
         return(0);      
      }
   
      # Subject
      $newrec->{ssslsubject}=$pkcs->subject();

      # Name
      $newrec->{name}=$pkcs->commonName();
      $newrec->{sslcertcommon}=$pkcs->commonName();
      $newrec->{sslcertorg}=$pkcs->organizationName();

      my @altnames;

      if ($pkcs->can("extensionValue")){
         my @names = $pkcs->extensionValue('subjectAltName' );
         if ($#names==0 && ref($names[0]) eq "ARRAY"){
            @names=@{$names[0]};
         }
         
         foreach my $nrec (@names){
            if ($nrec->{dNSName} ne ""){
               push(@altnames,$nrec->{dNSName});
            }
         }
      }
      if ($#altnames!=-1){
         $newrec->{sslaltnames}=join("; ",sort(@altnames));
      }
   }
   if (exists($newrec->{'ssslcert'})) {
      my $x509=$self->readPEM(effVal($oldrec,$newrec,'ssslcert'));
      if (!defined($x509)){
         $self->LastMsg(ERROR,"signed cert in invalid format");
         return(0);      
      }
      else{
         $newrec->{ssslstartdate}=$x509->{startdate};
         $newrec->{ssslstartdate}=$x509->{startdate};
         $newrec->{ssslenddate}=$x509->{enddate};
         $newrec->{ssslissuerdn}=$x509->{ssslissuerdn};
         $newrec->{ssslserialno}=$x509->{ssslserialno};
         $newrec->{ssslissuerdn}=$x509->{ssslissuerdn};
      }
   }


   #
   # getCSTeamIDbyApplid muss vermutlich hier rein (da zukünftig
   # die Ermittlung des ServiceTeams von den CSR Daten (Erkennen,
   # ob es sich um ein Client-Cert handelt) abhängt - das
   # wird dann aber erst noch gebaut (und im jetzigen Schritt noch
   # nicht umgesetzt)
   #

   return(1);
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orig=shift;

   if (effChanged($oldrec,$newrec,"state") && $newrec->{state} eq "5"){
      my %newrec=();
      #
      # derive a new csr in state captured from the current record
      #
      $newrec{applid}=$oldrec->{applid};
      $newrec{name}=$oldrec->{name};
      $newrec{sslcert}=$oldrec->{sslcert} if ($oldrec->{sslcert} ne "");
      $newrec{ssslcert}=$oldrec->{ssslcert};
      $newrec{sslcertcommon}=$oldrec->{sslcertcommon};
      $newrec{sslcertorg}=$oldrec->{sslcertorg};
      $newrec{replacedrefno}=$oldrec->{refno};
      $newrec{spassword}=$oldrec->{spassword};

      $newrec{csteamid}=$oldrec->{csteamid};
      if (1){
         my ($csteamid,$csteamaccess)=
            $self->getCSTeamIDbyApplid($newrec{applid},undef,$newrec);
         if (defined($csteamid)){  # neues Team ist nun für 
                                   # die AG zusändig
            $newrec{csteamid}=$csteamid;
         }
      }

      $newrec{state}="1";
      $self->ValidatedInsertRecord(\%newrec);
   }
   if (effChanged($oldrec,$newrec,"state") && $newrec->{state} eq "4"){
     my $replacedrefno=effVal($oldrec,$newrec,"replacedrefno");
     if ($replacedrefno ne ""){
        $self->ResetFilter();
        $self->SetFilter({state=>'5',refno=>\$replacedrefno});
        my $op=$self->Clone();
        foreach my $oldrec ($self->getHashList(qw(ALL))){
           $op->UpdateRecord({state=>6},{id=>\$oldrec->{id}});
        }
      }
   }

   if ($self->isDataInputFromUserFrontend()){
      if (effChanged($oldrec,$newrec,"state") && $newrec->{state} eq "4"){
         # notify requestor about new signed cert
         my $csrid=effVal($oldrec,$newrec,"id");
         $self->doNotify($csrid,"CERTSIGNED");
      }
     
      if ((!defined($oldrec) || effChanged($oldrec,$newrec,"state")) && 
          $newrec->{state} eq "1"){
         # notify service team abount new request
         my $csrid=effVal($oldrec,$newrec,"id");
         $self->doNotify($csrid,"NEWCERT");
      }
   }


   return($self->SUPER::FinishWrite($oldrec,$newrec,$orig));
}


sub doNotify
{
   my $self=shift;
   my $csrid=shift;
   my $mode=shift;    # NEWCERT | CERTSIGNED | CERTEXPIRE1 | CERTEXPIRE2

   my $obj=$self->Clone();

   $obj->ResetFilter();
   $obj->SetFilter({id=>\$csrid});
   my ($rec)=$obj->getOnlyFirst(qw(ALL));
   if (defined($rec)){
      my $arec;
      if ($rec->{applid} ne ""){
         my $aobj=$self->getPersistentModuleObject("appl","itil::appl");
         $aobj->SetFilter({id=>\$rec->{applid}});
         ($arec)=$aobj->getOnlyFirst(qw(tsmid tsm2id contacts 
                                       opmid opm2id applmgrid));
      }
      #printf STDERR ("fifi02 arec=%s\n",Dumper($arec));

      #######################################################################
      ## E-Mail generation                                                 ##
      #######################################################################

      my $grp=$self->getPersistentModuleObject("grp","base::grp");
      my %touid;
      my %ccuid;

      if ($mode eq "NEWCERT" || $mode eq "CERTEXPIRE2"){
         my @csteam;
         if ($rec->{csteamgrpid} ne ""){
            @csteam=$obj->getMembersOf($rec->{csteamgrpid},
               "RMember",
               "direct"
            );
         }
         if ($mode eq "NEWCERT"){
            foreach my $uid (@csteam){
               $touid{$uid}++;
            }
         }
         if ($mode eq "CERTEXPIRE2"){
            foreach my $uid (@csteam){
               $touid{$uid}++;
            }
         }
      }

      if ($mode eq "CERTSIGNED"){
         if (defined($rec) && $rec->{creatorid} ne ""){
            $ccuid{$rec->{creatorid}}++;
         }
      }
      if ($mode eq "CERTSIGNED" || $mode eq "CERTEXPIRE1" || 
                                   $mode eq "CERTEXPIRE2"){ 
         if (defined($arec)){
            $touid{$arec->{tsmid}}++;
            $ccuid{$arec->{tsm2id}}++;
            $touid{$arec->{opmid}}++;
            $ccuid{$arec->{opm2id}}++;
            $ccuid{$arec->{applmgrid}}++;
            foreach my $crec (@{$arec->{contacts}}){
               my $roles=$crec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if ($crec->{target} eq "base::user" &&
                   in_array($roles,"applmgr2")){
                  $ccuid{$crec->{targetid}}++;
               }
            }
         }
      }

      # printf STDERR ("fifi CERTEXPIRE1 to=%s\n",Dumper(\%touid));
      # printf STDERR ("fifi CERTEXPIRE1 cc=%s\n",Dumper(\%ccuid));
     
     
      my @targetuids=(keys(%touid),keys(%ccuid)); #now we got all target userids
     
      my %nrec;
     
      my $user=$self->getPersistentModuleObject("user","base::user");
      my $wfa=$self->getPersistentModuleObject("wfa","base::workflowaction");

      $user->ResetFilter(); 
      $user->SetFilter({userid=>\@targetuids});
      foreach my $urec ($user->getHashList(qw(fullname userid lastlang lang))){
         my $lang=$urec->{lastlang};
         $lang=$urec->{lang} if ($lang eq "");
         $lang="en" if ($lang eq "");
         $nrec{$lang}->{$urec->{userid}}++;
      }
      my $lastlang;
      if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
         $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
      }
      foreach my $lang (keys(%nrec)){
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;
         my @emailto;
         my @emailcc;
         foreach my $uid (keys(%touid)){
            if (exists($nrec{$lang}->{$uid})){
               push(@emailto,$uid);
            }
         }
         foreach my $uid (keys(%ccuid)){
            if (!exists($touid{$uid})){
               if (exists($nrec{$lang}->{$uid})){
                  push(@emailcc,$uid);
               }
            }
         }
         if ($#emailto!=-1 || $#emailcc!=-1){
            my $subject=$self->T(
               "CRaS certificate service",
               $obj->Self).": ".$rec->{sslcertcommon};

            my $csrlink="";
            my $sigcert="";

            if ($rec->{sslcert} ne ""){
               my $fo=$self->getField("sslcert",$rec);
               my $url=$fo->getDownloadUrl($rec,1);
               $csrlink="\nCSR:\n".$url."\n";
            }

            if ($rec->{ssslcert} ne ""){
               my $fo=$self->getField("ssslcert",$rec);
               my $url=$fo->getDownloadUrl($rec,1);
               $sigcert="\nSigned Cert:\n".$url."\n";
            }
           
            my $tmpl=$self->getParsedTemplate("tmpl/CRaS_Notify_$mode",{
               static=>{
                  CSRLINK=>$csrlink,
                  SIGCERT=>$sigcert,
               }
            });

            if (1){
               $tmpl.="\n\nDirectLink:\n";
               my $baseurl=$ENV{SCRIPT_URI};
               $baseurl=~s/\/(auth|public)\/.*$//;
               my $jobbaseurl=$self->Config->Param("EventJobBaseUrl");
               if ($jobbaseurl ne ""){
                  $jobbaseurl=~s#/$##;
                  $baseurl=$jobbaseurl;
               }
               my $url=$baseurl;
               if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
                  $url=~s/^http:/https:/i;
               }
               my $p=$self->Self();
               $p=~s/::/\//g;
               $url.="/auth/$p/ById/".$rec->{id};
               $tmpl.=$url;
               $tmpl.="\n\n";
            }


            my $level="INFO";
            if ($mode eq "NEWCERT"){
               $subject=$self->T(
                  "CRaS new CSR to process",
                  $obj->Self).": ".$rec->{sslcertcommon};
            }
            if ($mode eq "CERTSIGNED"){
               $subject=$self->T(
                  "CRaS certificate signed",
                  $obj->Self).": ".$rec->{sslcertcommon};
            }
            if ($mode eq "CERTEXPIRE1"){
               $level="WARN";
               $subject=$self->T(
                  "CRaS check for renew",
                  $obj->Self).": ".$rec->{sslcertcommon};
            }
            if ($mode eq "CERTEXPIRE2"){
               $level="ERROR";
               $subject=$self->T(
                  "CRaS expiration extrem near",
                  $obj->Self).": ".$rec->{sslcertcommon};
            }
 
            $wfa->Notify($level,$subject,$tmpl, 
               emailto=>\@emailto, 
               emailcc=>\@emailcc, 
               emailbcc=>[
                  11634953080001,   # HV
               ],
               emailcategory =>['CRaS']
            );
         }
      }
      if ($lastlang ne ""){
         $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
      }
      else{
         delete($ENV{HTTP_FORCE_LANGUAGE});
      }
      #######################################################################
   }


   #printf STDERR ("Notify(%s)=%s\n",$mode,Dumper($rec));

   return(1);
}






sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default followupcsr caref detail source));
}


sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{state}<6);

   return($self->SUPER::isDeleteValid($rec));
}



sub isUploadValid
{
   return(0);
}


sub isQualityCheckValid
{
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_state"))){
     Query->Param("search_state"=>
                  "\"!".$self->T("CSRSTATE.6")."\"");
   }
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"CAresponseHandler");
}

sub readPEM
{
   my $self=shift;
   my $pem=shift;
   my %oprec=();
   my $x509;

   # try multiple file formats
   eval('$x509=Crypt::OpenSSL::X509->new_from_string($pem,FORMAT_PEM);');
   if ($@ ne "") {
      eval('$x509=Crypt::OpenSSL::X509->new_from_string($pem,FORMAT_ASN1);');
   }
   if ($@ ne "") {
      return(undef);
   }
   else{
      # SerialNr. (hex format)
      $oprec{ssslserialno}=$x509->serial();

      # Issuer
      my $iobjs=$x509->issuer_name->entries();
      $oprec{ssslissuer}=$self->formatedMultiline($iobjs);
      $oprec{ssslissuerdn}=$x509->issuer();

      # Name
      my ($cn)=grep({$_->type() eq 'CN'} @$iobjs);
      if (defined($cn)){
         $oprec{ssslcertcommon}=$cn->value();
      }
      # Startdate / Enddate
      my $startdate=$x509->notBefore();
      $oprec{startdate}=$self->parseCertDate($startdate);

      my $enddate=$x509->notAfter();
      $oprec{enddate}=$self->parseCertDate($enddate);

   }
   return(\%oprec);


}

sub doCAresponseHandler
{
   my $self=shift;
   my $q=shift;
   my %result;

   $result{exitmsg}="OK";
   $result{exitcode}=0;

   my %oprec;

   my $mailtext=$q->{mailtext};
   $mailtext=~s/\r\n/\n/gs;
   my @mailtext=split(/\n/,$mailtext);


   # interpret mailtext
   my $incert=0;
   my @cert;
   foreach my $l (@mailtext){
      if ($l=~m/[-]+-BEGIN CERTIFICATE-[-]+$/){
         $incert++;
      }
      if ($incert){
         push(@cert,$l);
      }
      else{
         if (!exists($oprec{refno}) && 
             (my ($refno)=$l=~m/^\s*Referenznummer\s*:\s*([0-9.]+)\s*$/)){
            $oprec{refno}=$refno;
         }
         if (!exists($oprec{validto}) && 
             (my ($validto)=$l=~m/^\s*G.*ltig bis\s*:\s*([0-9.]+)\s*$/)){
            $oprec{validto}=$validto;
         }
         if (!exists($oprec{ssslserialno}) && 
             (my ($ssslserialno)=$l=~m/^\s*Serienn.*:\s*([0-9a-f]+)\s*$/i)){
            $oprec{ssslserialno}=$ssslserialno;
         }
         if (!exists($oprec{spassword}) && 
             (my ($spassword)=$l=~m/^\s*Service.*Pass.*:\s*(\S+)\s*$/i)){
            $oprec{spassword}=$spassword;
         }
         if (!exists($oprec{force}) && 
             (my ($force)=$l=~m/^force:\s*([0-9])\s*$/)){
            $oprec{force}=$force;
         }
         if (!exists($oprec{sslcertcommon}) && 
             (my ($common)=$l=~m/^\s*CommonName.*:\s*([\S]+)\s*$/i)){
            $oprec{sslcertcommon}=$common;
         }
      }
      if ($l=~m/[-]+-END CERTIFICATE-[-]+$/){
         $incert=0;
      }
   }
   if ($#cert!=-1){
      $oprec{cert}=join("\n",@cert)."\n";
   }
   if (exists($q->{certfile})){
      if (exists($oprec{cert})){
         $result{msg}="using cert from file - not from mailtext";
      }
      $oprec{cert}=$q->{certfile};
   }
   if ($result{exitcode}==0 && !exists($oprec{cert})){
      $result{exitcode}=100;
      $result{exitmsg}="no cert file in response";
   }

   if ($result{exitcode}==0 && exists($oprec{cert})){
      my $x509=$self->readPEM($oprec{cert});
      if (!defined($x509)){
         $result{exitcode}=200;
         $result{exitmsg}="unexpected cert file format";
      }
      else{
         foreach my $k (%{$x509}){
            $oprec{$k}=$x509->{$k};
         }
      }
   }
   if ($result{exitcode}==0 && exists($oprec{refno})){
      $self->ResetFilter();
      $self->SetFilter({refno=>\$oprec{refno}});
      my @l=$self->getHashList(qw(ALL));
      if ($#l==0){
         $oprec{csrrec}=$l[0];
      }
      else{
         $result{exitcode}=300;
         $result{exitmsg}="unable to find csr by refno";
      }
   }
   if ($result{exitcode}==0 && exists($oprec{ssslcertcommon}) &&
       !exists($oprec{csrrec})){
      $self->ResetFilter();
      $self->SetFilter({state=>3,sslcertcommon=>\$oprec{ssslcertcommon}});
      my @l=$self->getHashList(qw(ALL));
      if ($#l==0){
         $oprec{csrrec}=$l[0];
      }
      else{
         $result{exitcode}=301;
         $result{exitmsg}="unable to find csr by CommonName";
      }
   }
   if (!$oprec{force}){
      if ($result{exitcode}==0  && exists($oprec{csrrec})){
         if ($oprec{csrrec}->{state} eq "4"){
            $result{exitcode}=501;
            $result{exitmsg}="csr record is already singed";
         }
      }
   }


   if (!$oprec{force}){
      if ($result{exitcode}==0 && exists($oprec{sslcertcommon}) &&
          exists($oprec{csrrec})){
         if ($oprec{csrrec}->{sslcertcommon} ne $oprec{sslcertcommon}){
            $result{exitcode}=501;
            $result{exitmsg}="CommonName does not match csr record";
         }
      }
   }


   if ($result{exitcode}==0 && exists($oprec{csrrec})){
      #printf STDERR ("fifi try to ValidatedUpdateRecord %s\n",
      #               $oprec{csrrec}->{id});
      my $updrec={
         state=>4,
         ssslcert=>$oprec{cert}
      };
      if ($oprec{spassword} ne ""){
         $updrec->{spassword}=$oprec{spassword};
      }
      my $id=$oprec{csrrec}->{id};
      $self->ValidatedUpdateRecord($oprec{csrrec},$updrec,{id=>\$id});
   }













   $result{oprec}=\%oprec;

   return(\%result);
}


sub CAresponseHandler
{
   my $self=shift;
   my $qfields=shift;
   my $authorize=shift;
   my $f=shift;
   my @param=@_;


   my @accept=split(/\s*,\s*/,lc($ENV{HTTP_ACCEPT}));
   if (in_array(\@accept,["application/json","application/xml",
                          "text/javascript"])){
      my $q=Query->MultiVars();
      $self->_simpleRESTCallHandler_SendResult(0,
                   $self->doCAresponseHandler($q));
   }
   else{
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(
                        body=>1,
                        style=>['default.css','mainwork.css',
                                'kernel.App.Web.css'],
                        js=>['jquery.js','toolbox.js'],
                        title=>"CA Response Handler");
      print $self->getAppTitleBar();
      print $self->getParsedTemplate(
            "tmpl/CAresponseHandlerForm",
            { 
               static=>{
               }
            }
          );

      printf("</body>");
      printf("</html>");
   }
}






1;
