package itil::lnkapplurl;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use itil::appl;
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit itil::lib::Listedit kernel::DataObj::DB);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{history}={
      insert=>[
         {dataobj=>'itil::appl', id=>'applid',
          field=>'name',as=>'applurl'}
      ],
      update=>[
         'local',
         {dataobj=>'itil::appl', id=>'applid',
          field=>'name',as=>'applurl'}
      ],
      delete=>[
         {dataobj=>'itil::appl', id=>'applid',
          field=>'name',as=>'applurl'}
      ]
   };

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'URL ID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'accessurl.id'),
      new kernel::Field::RecordUrl(),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'URL fullname',
                dataobjattr   =>"concat(appl.name,': ',accessurl.fullname)"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'URL',
                dataobjattr   =>'accessurl.fullname'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'250px',
                label         =>'provided by Application',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'appl.name'),
                                                   
      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'network',
                htmleditwidth =>'280px',
                label         =>'Network',
                vjointo       =>'itil::network',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['networkid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'networkid',
                label         =>'NetworkID',
                dataobjattr   =>'accessurl.network'),

      new kernel::Field::TextDrop(
                name          =>'itcloudarea',
                group         =>'default',
                label         =>'CloudArea',
                htmldetail    =>'NotEmpty',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                vjointo       =>'itil::itcloudarea',
                vjoinon       =>['itcloudareaid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itcloudareaid',
                label         =>'CloudAreaID',
                selectfix     =>1,
                group         =>'default',
                dataobjattr   =>'accessurl.itcloudarea'),


                                                  
      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'accessurl.comments'),

      new kernel::Field::Boolean(
                name          =>'is_userfrontend',
                group         =>'class',
                label         =>'Accessed by endusers (Application Frontend)',
                dataobjattr   =>'accessurl.is_userfrontend'),

      new kernel::Field::Boolean(
                name          =>'is_interface',
                group         =>'class',
                label         =>'Accessed by interface applications',
                dataobjattr   =>'accessurl.is_interface'),

      new kernel::Field::Boolean(
                name          =>'is_internal',
                group         =>'class',
                label         =>'only for internal communication in application',
                dataobjattr   =>'accessurl.is_internal'),

      new kernel::Field::Boolean(
                name          =>'is_onshproxy',
                group         =>'class',
                label         =>'URL is hosted on Shared-Reverse Proxy',
                dataobjattr   =>'accessurl.isonsharedproxy'),

      new kernel::Field::Boolean(
                name          =>'is_derivatedfromif',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'derivated from interface',
                dataobjattr   =>'if (accessurl.lnkapplappl is null,0,1)'),


      new kernel::Field::Boolean(
                name          =>'do_sslcertcheck',
                group         =>'sslclass',
                jsonchanged   =>\&getOnChangedClassScript,
                jsoninit      =>\&getOnChangedClassScript,
                selectfix     =>1,
                label         =>'perform cyclic SSL certificate checks',
                dataobjattr   =>'accessurl.do_ssl_cert_check'),

      new kernel::Field::Select(
                name          =>'ssl_expnotifyleaddays',
                htmleditwidth =>'180px',
                group         =>'sslclass',
                default       =>'56',
                label         =>'SSL Expiration notify lead time',
                value         =>['14','21','28','56','70'],
                transprefix   =>'EXPNOTIFYLEAD.',
                translation   =>'itil::applwallet',
                dataobjattr   =>'accessurl.ssl_expnotifyleaddays'),

      new kernel::Field::TextDrop(
                name          =>'lnkapplappl',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'derivated from interface application',
                vjointo       =>'itil::lnkapplappl',
                vjoinon       =>['lnkapplapplid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'lnkapplapplid',
                selectfix     =>1,
                label         =>'InterfaceID',
                dataobjattr   =>'accessurl.lnkapplappl'),

      new kernel::Field::Text(
                name          =>'scheme',
                group         =>'urlinfo',
                readonly      =>1,
                label         =>'Scheme',
                dataobjattr   =>'accessurl.scheme'),
                                                   
      new kernel::Field::Text(
                name          =>'hostname',
                group         =>'urlinfo',
                readonly      =>1,
                label         =>'Hostname',
                dataobjattr   =>'accessurl.hostname'),

      new kernel::Field::Number(
                name          =>'ipport',
                group         =>'urlinfo',
                readonly      =>1,
                label         =>'IP-Port',
                dataobjattr   =>'accessurl.ipport'),
                                                   
      new kernel::Field::SubList(
                name          =>'lastipaddresses',
                label         =>'last known IP-Adresses',
                group         =>'lastipaddresses',
                vjointo       =>'itil::lnkapplurlip',
                vjoinon       =>['id'=>'lnkapplurlid'],
                vjoindisp     =>['name','srcload']),



      new kernel::Field::Date(
                name          =>'sslbegin',
                history       =>0,
                group         =>'ssl',
                depend        =>['sslurl'],
                label         =>'SSL Certificate Begin',
                dataobjattr   =>'accessurl.ssl_cert_begin'),

      new kernel::Field::Date(
                name          =>'sslend',
                history       =>0,
                group         =>'ssl',
                depend        =>['sslurl'],
                label         =>'SSL Certificate End',
                dataobjattr   =>'accessurl.ssl_cert_end'),

      new kernel::Field::Date(
                name          =>'sslcheck',
                history       =>0,
                readonly      =>1,
                group         =>'ssl',
                label         =>'SSL last Certificate check',
                dataobjattr   =>'accessurl.ssl_cert_check'),

      new kernel::Field::Text(
                name          =>'sslstate',
                readonly      =>1,
                group         =>'ssl',
                label         =>'SSL State',
                dataobjattr   =>'accessurl.ssl_state'),

      new kernel::Field::Text(
                name          =>'ssl_cipher',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Cipher',
                dataobjattr   =>'accessurl.ssl_cipher'),

      new kernel::Field::Text(
                name          =>'ssl_version',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Version',
                dataobjattr   =>'accessurl.ssl_version'),

      new kernel::Field::Text(
                name          =>'ssl_certdump',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Certificate',
                dataobjattr   =>'accessurl.ssl_certdump'),

      new kernel::Field::Text(
                name          =>'ssl_cert_serialno',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Certificate Serial',
                dataobjattr   =>'accessurl.ssl_certserial'),

      new kernel::Field::Text(
                name          =>'ssl_cert_issuerdn',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Issuer DN',
                dataobjattr   =>'accessurl.ssl_certissuerdn'),

      new kernel::Field::Text(
                name          =>'ssl_cert_signature_algo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Certificate signature algo',
                dataobjattr   =>'accessurl.ssl_certsighash'),

      new kernel::Field::Date(
                name          =>'sslexpnotify1',
                history       =>0,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'ssl',
                label         =>'Notification of Certificate Expiration',
                dataobjattr   =>'accessurl.ssl_cert_exp_notify1'),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'accessurl.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'accessurl.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'accessurl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'accessurl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'accessurl.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"accessurl.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(accessurl.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'accessurl.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'accessurl.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'accessurl.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'accessurl.realeditor'),

      new kernel::Field::Mandator(
                group         =>'applinfo',
                htmldetail    =>0,
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'ApplMandatorID',
                group         =>'applinfo',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::appl',
                dontrename    =>1,
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                uploadable    =>0,
                fields        =>[qw(databoss databossid applmgr applmgrid
                                    tsmid tsm2id 
                                    opmid opm2id 
                                    businessteamid )]),

      new kernel::Field::Link(
                name          =>'databossid',
                label         =>'DatabossID',
                group         =>'applinfo',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Text(
                name          =>'applapplid',
                label         =>'ApplicationID',
                readonly      =>1,
                uploadable    =>0,
                htmldetail    =>0,
                group         =>'applinfo',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Customer',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'applinfo',
                translation   =>'itil::appl',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'applcustomerprio',
                label         =>'Customers Application Prioritiy',
                readonly      =>1,
                htmldetail    =>0,
                translation   =>'itil::appl',
                group         =>'applinfo',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'customerid',
                label         =>'CustomerID',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::SubList(
                name          =>'addcis',
                label         =>'additional used Config-Items',
                group         =>'addcis',
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkadditionalci',
                vjoinon       =>['id'=>'accessurlid'],
                vjoindisp     =>['name','ciusage']),


      new kernel::Field::Number(
                name          =>'sharedlevel',
                label         =>'SharedLevel',
                readonly      =>1,
                uploadable    =>0,
                htmldetail    =>0,
                group         =>'lastipaddresses',
                dataobjattr   =>"(select count(*) from accessurllastip ".
                                "join accessurllastip altip ".
                                "on accessurllastip.name=altip.name ".
                                "join accessurl alturl ".
                                "on altip.accessurl=alturl.id ".
                                "join accessurl cururl ".
                                "on accessurllastip.accessurl=cururl.id ".
                                "join appl curappl ".
                                "on cururl.appl=curappl.id ".
                                "join appl altappl ".
                                "on alturl.appl=altappl.id ".
                                "left outer join lnkapplgrpappl curapplgrp ".
                                "on curappl.id=curapplgrp.appl ".
                                "left outer join lnkapplgrpappl altapplgrp ".
                                "on altappl.id=altapplgrp.appl ".
                                "where ".
                                "accessurllastip.accessurl=accessurl.id and ".
                                "cururl.network=alturl.network and ".
                                "cururl.appl!=alturl.appl and ".
                                "curapplgrp.applgrp!=altapplgrp.applgrp)"),

      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplID',
                wrdataobjattr =>'accessurl.appl',
                dataobjattr   =>"if (accessurl.appl is not null,accessurl.appl,".
                                "lnkapplappl.fromappl)"),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'accessurl.expiration'),

      new kernel::Field::Link(
                name          =>'secapplmgr2id',
                noselect      =>'1',
                dataobjattr   =>'lnkapplmgr2.targetid'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),



      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'accessurl.lastqcheck'),
      new kernel::Field::QualityResponseArea(),

   );
   $self->setDefaultView(qw(name network appl applcistatus cdate));
   $self->setWorktable("accessurl");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="accessurl ".
            "left outer join lnkcontact ".
            "on lnkcontact.parentobj='itil::appl' ".
            "   and accessurl.appl=lnkcontact.refid ".
            "left outer join lnkcontact as lnkapplmgr2 ".
            "on (lnkapplmgr2.parentobj='itil::appl' ".
            "and accessurl.appl=lnkapplmgr2.refid ".
            "and lnkapplmgr2.croles like '%roles=_applmgr2_=roles%' ".
            "and lnkapplmgr2.target='base::user') ".
            "left outer join lnkapplappl ".
            "on accessurl.lnkapplappl=lnkapplappl.id ".
            "left outer join appl ".
            "on appl.id=if (accessurl.appl is not null,".
            "accessurl.appl,lnkapplappl.fromappl) ".
            "join (select min(id) ugroupedid ".
                  "from accessurl ".
                  "where (appl is not null or target_is_fromappl=1) ".
                  "group by fullname,network,appl) ugrouped ".
            "on accessurl.id=ugrouped.ugroupedid";
   return($from);
}

sub getOnChangedClassScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var d=document.forms[0].elements['Formated_do_sslcertcheck'];
var r=document.forms[0].elements['Formated_ssl_expnotifyleaddays'];

if (d && r){
   var v=d.options[d.selectedIndex].value;
   if (v!="" && v!="0"){
      r.disabled=false;
   }
   else{
      r.disabled=true;
   }
}
EOF
   return($d);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @addflt;
      $self->itil::appl::addApplicationSecureFilter([''],\@addflt);
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $name=effVal($oldrec,$newrec,"name");

   my $uri=$self->URLValidate($name);
   if ($uri->{name} ne $name){
      $newrec->{name}=$uri->{name};
      $name=$uri->{name};
   }
   if ($uri->{error}) {
      $self->LastMsg(ERROR,$uri->{error});
      printf STDERR ("DEBUG: itil::lnkapplurl::Validate\nnew=%s\n",
                     Dumper($newrec));
      printf STDERR ("DEBUG: itil::lnkapplurl::Validate\nold=%s\n",
                     Dumper($oldrec));
      return(undef);
   }
   if (effVal($oldrec,$newrec,"hostname") ne $uri->{host}){
         $newrec->{hostname}=$uri->{host};
      }
   if (effVal($oldrec,$newrec,"ipport") ne $uri->{port}){
         $newrec->{ipport}=$uri->{port};
   }

   my $itcloudareaid=effVal($oldrec,$newrec,"itcloudareaid");

   my $itcloudareaaccess=0;

   if ((!defined($oldrec) && exists($newrec->{itcloudareaid})) || 
       effChanged($oldrec,$newrec,"itcloudareaid")){
      my $itca=$self->getPersistentModuleObject("itil::itcloudarea");
      $itca->SetFilter({id=>\$itcloudareaid});
      my ($carec,$msg)=$itca->getOnlyFirst(qw(ALL));
      if (!defined($carec)){
         $self->LastMsg(ERROR,"invalid CloudAreaID specified");
         return(undef);
      }
      else{
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>\$carec->{applid}});
         my ($applrec,$msg)=$appl->getOnlyFirst(qw(ALL));
         if (!defined($applrec)){
            $self->LastMsg(ERROR,"invalid application referenced");
            return(undef);
         }

         my $itc=$self->getPersistentModuleObject("itil::itcloud");
         $itc->SetFilter({id=>\$carec->{cloudid}});
         my ($clrec,$msg)=$itc->getOnlyFirst(qw(ALL));
         if (!defined($clrec)){
            $self->LastMsg(ERROR,"no valid cloud referenced");
            return(undef);
         }
         else{
            if (!$itca->validateCloudAreaImportState("URL: ".$name,
                                            $clrec,$carec,$applrec)){
               if ($self->LastMsg()==0){
                  $self->LastMsg(ERROR,"invalid CloudArea State");
               }
               return(undef);
            }
            if ($self->isDataInputFromUserFrontend()){
               my @l=$itc->isWriteValid($clrec);
               if (!in_array(\@l,[qw(default ALL)])){
                  $self->LastMsg(ERROR,"no write access to cloud");
                  return(undef);
               }
               else{
                  $itcloudareaaccess=1;
               }
            }
            else{
               $itcloudareaaccess=1;
            }
            my $applid=effVal($oldrec,$newrec,"applid");
            if ($applid ne $carec->{applid}){
               $newrec->{applid}=$carec->{applid};
            }
         }
      }
   }






   my $applid=effVal($oldrec,$newrec,"applid");
   if ($applid eq ""){
      $self->LastMsg(ERROR,"no valid application specifed");
      return(undef);
   }
   my $networkid=effVal($oldrec,$newrec,"networkid");
   if ($networkid eq ""){
      $self->LastMsg(ERROR,"no valid ip network specified");
      return(undef);
   }


   if (!$itcloudareaaccess && $self->isDataInputFromUserFrontend()){
      if (!$self->isWriteToApplValid($applid)){
         $self->LastMsg(ERROR,"no write access to requested application");
         return(undef);
      }
   }
   if ((!defined($oldrec) ||
        exists($newrec->{is_userfrontend}) ||
        exists($newrec->{is_interface}) ||
        exists($newrec->{is_internal}))){
       if (effVal($oldrec,$newrec,"is_userfrontend")==0 &&
           effVal($oldrec,$newrec,"is_interface")==0 &&
           effVal($oldrec,$newrec,"is_internal")==0 ){
          $self->LastMsg(ERROR,"no classification specified");
          return(undef);
       }
   }

   if (effVal($oldrec,$newrec,"name") ne $name){
      $newrec->{name}=$name;
   }
   if (effVal($oldrec,$newrec,"scheme") ne $uri->{scheme}){
      $newrec->{scheme}=$uri->{scheme};
   }

   my $scheme=effVal($oldrec,$newrec,"scheme");
   my $do_sslcertcheck=effVal($oldrec,$newrec,"do_sslcertcheck");
   if ($do_sslcertcheck){
      if ($scheme ne "https"){
         $self->LastMsg(ERROR,"certificate checks only posible on https urls");
         return(undef);
      }
   }

   # 
   # Es wurde festgestellt, dass auch ReverseProxys durchaus auf 
   # unterschiedlichen DNS Namen mit der gleichen IP-Adresse arbeiten
   # können (Beispiel wäre die CaaS Plattform) - damit wird es 
   # dann notwendig, dass auch / Paths auf ReverseProxys
   # liegen duerfen.
   # 
   #my $is_onshproxy=effVal($oldrec,$newrec,"is_onshproxy");
   #
   #if ($is_onshproxy){
   #   if ($uri->{path} eq "/" || $uri->{path} eq ""){
   #      $self->LastMsg(ERROR,
   #               "on Shared-Reverse-Proxy URLs a path in URL is needed");
   #      return(undef);
   #   }
   #}

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default class sslclass applinfo urlinfo ssl 
             lastipaddresses addcis source));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","class","sslclass") if (!defined($rec));

   my @l=qw(header default history class sslclass applinfo urlinfo 
            source history addcis);

   if ($rec->{do_sslcertcheck}){
      push(@l,"ssl");
   }

   if ($#{$rec->{lastipaddresses}}!=-1){
      push(@l,"lastipaddresses");
   }

   if ($self->IsMemberOf("admin")){
      push(@l,"qc");
   }
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(undef) if ($rec->{lnkapplapplid} ne "");

   my $applid=defined($rec) ? $rec->{applid} : undef;

   my $wrok=$self->isWriteToApplValid($applid);

   return("default","class","sslclass" ) if ($wrok);
   return(undef);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/urlci.jpg?".$cgi->query_string());
}



sub isWriteToApplValid
{
   my $self=shift;
   my $applid=shift;

   my $userid=$self->getCurrentUserId();
   my $wrok=0;
   $wrok=1 if (!defined($applid));
  # $wrok=1 if ($self->IsMemberOf("admin"));
   if ($self->itil::lib::Listedit::isWriteOnApplValid($applid,"default")){
      $wrok=1;
   }
   return($wrok);
}











1;
