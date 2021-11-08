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
                            if ($current->{rawstate} eq "5"){
                               if (!in_array($st,[qw(2 5 3)])){
                                  next;
                               }
                            }
                            if ($current->{rawstate} eq "4"){
                               if (!in_array($st,[qw(4 5 6)])){
                                  next;
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
                name          =>'sslcertorg',
                label         =>'SSL-Certificate Organisation',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'csr.sslcertorg'),

      new kernel::Field::Text(
                name          =>'refno',
                label         =>'CA Reference No.',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
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
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'csr.spassword'),

#      new kernel::Field::Select(
#                name          =>'expnotifyleaddays',
#                htmleditwidth =>'280px',
#                default       =>'56',
#                label         =>'Expiration notify lead time',
#                value         =>['14','21','28','56','70'],
#                transprefix   =>'EXPNOTIFYLEAD.',
#                translation   =>'itil::applcsr',
#                dataobjattr   =>'csr.expnotifyleaddays'),

#      new kernel::Field::Date(
#                name          =>'sslexpnotify1',
#                history       =>0,
#                htmldetail    =>0,
#                searchable    =>0,
#                label         =>'Notification of Certificate Expiration',
#                dataobjattr   =>'csr.exp_notify1'),

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

      new kernel::Field::Text(
                name          =>'ssslsubject',
                label         =>'SSL-Certificate Owner',
                group         =>'detail',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'csr.ssslsubject'),

      new kernel::Field::Text(
                name          =>'ssslissuer',
                label         =>'SSL-Certificate Issuer',
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

   if ($rec->{state}==1 || $rec->{state}==4){
      if ($self->itil::lib::Listedit::isWriteOnApplValid(
                                          $rec->{applid},"technical")) {
         return("default");
      }
   }
   my $userid=$self->getCurrentUserId();


   if ($rec->{state}==2){
      return("default") if ($rec->{owner}==$userid);
   }
   else{
      return("default") if ($self->IsMemberOf($rec->{csgrpid}));
   }
   return(undef);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("request") if (!defined($rec));

   if ($rec->{rawstate}>0){
      return(qw(history default detail header source));
   }

   return(qw(ALL));
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


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ($self->isDataInputFromUserFrontend() && !defined($oldrec)){
      if ($newrec->{sslcert} eq ""){
$newrec->{sslcert}=<<EOF;
-----BEGIN CERTIFICATE REQUEST-----
MIIE9DCCAtwCAQAwga4xCzAJBgNVBAYTAkRFMQwwCgYDVQQIDANOUlcxDTALBgNV
BAcMBEJvbm4xITAfBgNVBAoMGERldXRzY2hlIFRlbGVrb20gSVQgR21iSDEXMBUG
A1UECwwOVGVsZWtvbS1JVCBQVkcxHjAcBgNVBAMMFXNob3BwbGFuZXIudGVsZWtv
bS5kZTEmMCQGCSqGSIb3DQEJARYXamFuLmthbmRhQHQtc3lzdGVtcy5jb20wggIi
MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDBXfpSunBMPInekJ1tfVOq0shs
WHIjXEN+HhjSEgmYmER9h+Piy7nZ0FNlBR2Ii2bqwc64NTNarxUjHEc4751QEtFr
FZ89MNQpv0iQmtbvIEx0UYdzG/+m6HoHpPjFputw7Jh9iDe2r4FNjR5+rck66Dv2
noCtthhz/r+S4Rvj7DtK2igxflLHaujkivV70GF5bsP4HXqpo5r7DC22KsaBKqpF
6TI28O4VpZUTYXktaECJmaoLYzUr4dwZXTX2OufDJALu0azk6ZVFxhrJsXJAeJ8K
gqIcbkS+1+vtVg4/H5cfCQWNfw0M7eYl/tsk+L5CiRA1lXsb7J2+/5EZmgTnDhrL
Z++WsfhsFW8T+n1hI0TAlTfYCJ/TvYjHFhiM9EfaqMw9dC3id50K2W8OeDMaqy3G
P4iolbVhBaH8HYXRphpTObD5HEh4fRrNmjTHsSwOeJd/GrWY3m5okjtMhxy4Mp4a
9lyxBCHUMRoL4ycH69djIayMO5VUnwtxm2iZvNV/Iwct7odHyHhDDolbKinK5Zry
ZJGzib9HjiXcY2vU1Wc/YCGKTOyYtTgs7KG1MyQ8VAK1ge7trRw4EfgTVLZqXzZ6
NNqlcCHuZb6uKfWbbFFeUZjhabCrbogx+bSwzkRVCthP4WeKwlIJ1l2D3+eIDQ2k
k61yx/wZVmLJmNamMQIDAQABoAAwDQYJKoZIhvcNAQELBQADggIBAAkH6nr064K+
k1zekqu1c14poD5MJ3ObizY8RxsAcjpVFbXqPQxfU9vRbqMJRpgSc9DOtXyWxS+c
wNQlHgLiEIgyQ9W8LN+glg+g5t5QwuAbdd/qXXGQCyle8fkvXrkfV/GrDBKoC5Pi
BplZZdBAW0wwZKmyDpko0d5HjqMdxXGSZlECCoSeTh0v+82FbPca221f28jYJMSp
A12QugNO+TAm25+xAXU8ZkSl8AZL2Z8SYNTUgSQSYRc9pOr4w9xSCTH3jXBLYh64
OblTH+8GDl7+4tcTn+86Dm99iJV71/jddZslQM2mw6gWsvbGQn/djD1Dj35yM/Fn
q3asPXwmwZ33/AOCWrTsejfh6lO5Ujo28RtynqhLdw3WSrTc41bBIDiAL7gxW8yY
zP+Qs3xlphOqGlPHxuaeAKTXTHC2axa4GMSA15f+qSnVBhaBsfGew/SOqodbUCj5
teblY+jsRAPBrxO4cxQ/6aM5morEPNkeh4N86y6XIJBwH6Gn0ote92kk7X0331t0
sjE8ipHjZeA4R+4G/FuQotrxkge/KRjb5Q/mXW3/oKN/ZPI1zp+PHu6wSue8GIjF
7MOb5z/4YrkCfgfayYN9PVfuZfsg5gmESJil5SP/lfqz6mE9mvOTRc+IL4jSHdEh
m2U/7Rd5u0FxEoIjT84/wX1GIBmp0+sW
-----END CERTIFICATE REQUEST-----
EOF
      }
   }
   #if (effVal($oldrec,$newrec,'shortdesc') eq '') {
   #   $self->LastMsg(ERROR,"No brief description specified");
   #   return(0);
   #}

   if (!defined($oldrec)){
      if (!exists($newrec->{state}) && !exists($newrec->{rawstate})){
         $newrec->{state}=1;
      }
      my $applid=effVal($oldrec,$newrec,"applid"); 
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({id=>\$applid});
      my ($arec)=$appl->getOnlyFirst(qw(ALL));
      
      my $csteam=getModuleObject($self->Config,"CRaS::csteam");
      $csteam->SetFilter({});
      my ($csteamrec)=$csteam->getOnlyFirst(qw(ALL));

      $newrec->{csteamid}=$csteamrec->{id}; 
   }

   if ($self->isDataInputFromUserFrontend()){
      if (effVal($oldrec,$newrec,'applid') eq '') {
         $self->LastMsg(ERROR,"No application specified");
         return(0);
      }
      if (!$self->itil::lib::Listedit::isWriteOnApplValid(
                                          $newrec->{applid},"technical")) {
         $self->LastMsg(ERROR,"No write access on specified application");
         return(0);
      }
   }

   if ($self->isDataInputFromUserFrontend()){
      if (!defined($oldrec) && effVal($oldrec,$newrec,'sslcert') eq '') {
         $self->LastMsg(ERROR,"No certificate file selected");
         return(0);
      }
   }

   if (effChanged($oldrec,$newrec,"expnotifyleaddays")){
      $newrec->{sslexpnotify1}=undef;
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

#      # Issuer
#      my $iobjs=$pkcs->issuer_name->entries();
#      $newrec->{issuer}=$self->formatedMultiline($iobjs);
#
#      $newrec->{issuerdn}=$pkcs->issuer();
#
#      # SerialNr. (hex format)
#      $newrec->{serialno}=$pkcs->serial();


      # Name
      $newrec->{name}=$pkcs->commonName();
      $newrec->{sslcertcommon}=$pkcs->commonName();
      $newrec->{sslcertorg}=$pkcs->organizationName();
   }

   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default detail source));
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

sub doCAresponseHandler
{
   my $self=shift;
   my $q=shift;


   return({
    exitmsg=>'OK',
    mailtext=>$q->{mailtext},
    exitcode=>0
   });
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
