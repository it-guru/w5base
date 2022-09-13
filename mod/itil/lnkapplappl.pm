package itil::lnkapplappl;
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
use itil::lib::Listedit;
use itil::appl;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                group         =>'source',
                dataobjattr   =>'lnkapplappl.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Select(
                name          =>'ifrel',
                label         =>'Interface Relation',
                value         =>[qw(DIRECT INDIRECT)],
                default       =>'DIRECT',
                htmleditwidth =>'100px',
                jsonchanged   =>\&getifrelHandlingScript,
                jsoninit      =>\&getifrelHandlingScript,
                dataobjattr   =>'lnkapplappl.ifrelation'),

      new kernel::Field::TextDrop(
                name          =>'fromappl',
                htmlwidth     =>'250px',
                label         =>'from Application',
                vjointo       =>'itil::appl',
                vjoineditbase =>{cistatusid=>[2,3,4,5]},
                SoftValidate  =>1,
                vjoinon       =>['fromapplid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'fromappl.name'),

      new kernel::Field::TextDrop(
                name          =>'gwappl',
                htmlwidth     =>'250px',
                label         =>'Gateway Application',
                htmldetail    =>'NotEmptyOrEdit',
                vjoineditbase =>{cistatusid=>[2,3,4,5]},
                SoftValidate  =>1,
                AllowEmpty    =>1,
                vjointo       =>'itil::appl',
                vjoinon       =>['gwapplid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'gwappl.name'),

      new kernel::Field::TextDrop(
                name          =>'gwappl2',
                htmlwidth     =>'250px',
                label         =>'further Gateway Application',
                htmldetail    =>'NotEmptyOrEdit',
                vjoineditbase =>{cistatusid=>[2,3,4,5]},
                SoftValidate  =>1,
                AllowEmpty    =>1,
                vjointo       =>'itil::appl',
                vjoinon       =>['gwappl2id'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'gwappl2.name'),

      new kernel::Field::TextDrop(
                name          =>'toappl',
                htmlwidth     =>'150px',
                label         =>'to Application',
                vjointo       =>'itil::appl',
                vjoineditbase =>{cistatusid=>[2,3,4,5]},
                SoftValidate  =>1,
                vjoinon       =>['toapplid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'toappl.name'),


      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'Interface-State',
                vjointo       =>'base::cistatus',
                vjoineditbase =>{id=>[3,4,5,6]},
                default       =>'4',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Interface fullname',
                selectfix     =>1,
                dataobjattr   =>"concat(fromappl.name,':',".
                                "if (gwappl.id is not null,".
                                "concat('-',gwappl.name,'-:'),".
                                "''),".
                                "if (gwappl2.id is not null,".
                                "concat('-',gwappl2.name,'-:'),".
                                "''),".
                                "toappl.name,':',lnkapplappl.conprotocol)"),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'lnkapplappl.cistatus'),

      new kernel::Field::Select(
                name          =>'contype',
                label         =>'Interfacetype',
                htmlwidth     =>'250px',
                transprefix   =>'contype.',
                value         =>[qw(0 1 2 3 4 5)],
                default       =>'0',
                htmleditwidth =>'350px',
                dataobjattr   =>'lnkapplappl.contype'),

      new kernel::Field::Select(
                name          =>'ifrelcontype',
                label         =>'Interfacetype with relation',
                htmlwidth     =>'250px',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                transprefix   =>'contype.',
                dataobjattr   =>"concat(".
                                "if (lnkapplappl.ifrelation=".
                                "'INDIRECT',".
                                "if (gwappl2.name is null,'I','II'),''),".
                                "lnkapplappl.contype)"),

      new kernel::Field::Interface(
                name          =>'rawcontype',
                label         =>'raw Interfacetype',
                uploadable    =>0,
                dataobjattr   =>'lnkapplappl.contype'),

      new kernel::Field::Select(
                name          =>'conmode',
                label         =>'Interfacemode',
                value         =>[qw(online batch manuell)],
                default       =>'online',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conmode'),

      new kernel::Field::Select(
                name          =>'conproto',
                label         =>'Interfaceprotocol',
                value         =>[qw( unknown 
                     BCV CAPI CIFS Corba DB-Connection DB-Link dce DCOM DSO 
                     EFB
                     ftp html http https IMAP IMAPS IMAP4 
                     jdbc ldap ldaps LDIF MAPI 
                     MFT MQSeries Netegrity NFS ODBC OSI openFT
                     papier pkix-cmp POP3 POP3S 
                     rcp rfc RMI RPC rsh sftp sldap SMB SMB-AuthOnly
                     smtp snmp SPML
                     ssh tuxedo TCP UC4 UCP/SMS utm X.31 XAPI xml
                     OTHER)],
                default       =>'online',
                selectfix     =>'1',
                htmlwidth     =>'50px',
                htmleditwidth =>'150px',
                dataobjattr   =>'lnkapplappl.conprotocol'),


      new kernel::Field::Htmlarea(
                name          =>'htmldescription',
                searchable    =>0,
                group         =>'desc',
                label         =>'Interface description',
                dataobjattr   =>'lnkapplappl.description'),

      new kernel::Field::Htmlarea(
                name          =>'htmlagreements',
                searchable    =>0,
                group         =>'agreement',
                label         =>'Agreements',
                dataobjattr   =>'lnkapplappl.agreements'),

      new kernel::Field::Select(
                name          =>'fromapplicationcistatus',
                label         =>'from Application CI-State',
                readonly      =>1,
                htmldetail    =>0,
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['fromapplcistatus'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'fromapplcistatus',
                label         =>'from Appl CI-Status',
                dataobjattr   =>'fromappl.cistatus'),

      new kernel::Field::Select(
                name          =>'toapplicationcistatus',
                label         =>'to Application CI-State',
                readonly      =>1,
                htmldetail    =>0,
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['toapplcistatus'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'toapplcistatus',
                label         =>'to Appl CI-Status',
                dataobjattr   =>'toappl.cistatus'),


      new kernel::Field::SubList(
                name          =>'interfacescomp',
                label         =>'Interface components',
                group         =>'interfacescomp',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplapplcomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'lnkapplappl'],
                vjoindisp     =>['name','namealt1','namealt2',"comments"],
                vjoininhash   =>['objtype','obj1id','obj2id','obj3id',
                                 'name','namealt1','namealt2','comments']),

      new kernel::Field::SubList(
                name          =>'tags',
                label         =>'Interface Tags',
                group         =>'tags',
                subeditmsk    =>'subedit.iftag',
                vjointo       =>'itil::lnkapplappltag',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'lnkapplappl'],
                vjoindisp     =>['name','value']),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkapplappl.comments'),

      new kernel::Field::Boolean(
                name          =>'ifagreementneeded',
                jsonchanged   =>\&getifagreementHandlingScript,
                jsoninit      =>\&getifagreementHandlingScript,
                group         =>'ifagreement',
                label         =>'interface agreement necessary',
                dataobjattr   =>'lnkapplappl.ifagreementneeded'),

      new kernel::Field::Select(
                name          =>'ifagreementlang',
                label         =>'interface agreement language',
                group         =>'ifagreement',
                htmleditwidth =>'200px',
                value         =>['',LangTable()],
                dataobjattr   =>'lnkapplappl.ifagreementlang'),

      new kernel::Field::File(
                name          =>'ifagreementdoc',
                label         =>'Interface-Agreement-Document',
                searchable    =>0,
                uploadable    =>0,
                types         =>['pdf','xlsx','docx','pptx'],
                mimetype      =>'ifagreementdoctype',
                filename      =>'ifagreementdocname',
                uploaddate    =>'ifagreementdocdate',
                maxsize       =>'10485760',
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdoc'),

      new kernel::Field::Text(
                name          =>'ifagreementdocname',
                label         =>'Interface-Agreement-Document Name',
                searchable    =>0,
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdocname'),

      new kernel::Field::Number(
                name          =>'ifagreementdocsz',
                label         =>'Interface-Agreement-Document Size',
                searchable    =>0,
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'length(lnkapplappl.ifagreementdoc)'),

      new kernel::Field::Select(
                name          =>'ifagreementstate',
                label         =>'Interface-Agreement state',
                uploadable    =>1,
                htmleditwidth =>'200px',
                htmldetail    =>"NotEmpty",
                transprefix   =>'IFSTATE.',
                allowempty    =>1,
                value         =>['CURRENT','NEEDMAINTENANCE'],
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementstate'),

      new kernel::Field::Date(
                name          =>'ifagreementdocdate',
                label         =>'Interface-Agreement-Document Date',
                uploadable    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdocdate'),

      new kernel::Field::Text(
                name          =>'ifagreementdoctype',
                label         =>'Interface-Agreement-Document Type',
                searchable    =>0,
                uploadable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                group         =>'ifagreement',
                dataobjattr   =>'lnkapplappl.ifagreementdoctype'),

     new kernel::Field::Textarea(
                name          =>'ifagreementexclreason',
                group         =>'ifagreement',
                searchable    =>0,
                htmldetail    =>'NotEmptyOrEdit',
                depend        =>['ifagreementneeded'],
                label         =>'reason on not needed interface agreement',
                dataobjattr   =>'lnkapplappl.ifagreementexclreason'),

      new kernel::Field::Text(
                name          =>'fromurl',
                htmldetail    =>0,
                uivisible     =>0,
                group         =>'comdetails',
                label         =>'from URL',
                dataobjattr   =>'lnkapplappl.fromurl'),

      new kernel::Field::Text(
                name          =>'fromservice',
                htmldetail    =>0,
                uivisible     =>0,
                group         =>'comdetails',
                label         =>'from Servicename',
                dataobjattr   =>'lnkapplappl.fromservice'),

      new kernel::Field::Text(
                name          =>'tourl',
                htmldetail    =>0,
                uivisible     =>0,
                group         =>'comdetails',
                label         =>'to URL',
                dataobjattr   =>'lnkapplappl.tourl'),

      new kernel::Field::Text(
                name          =>'toservice',
                htmldetail    =>0,
                uivisible     =>0,
                group         =>'comdetails',
                label         =>'to Servicename',
                dataobjattr   =>'lnkapplappl.toservice'),

      new kernel::Field::SubList(
                name          =>'comlinks',
                label         =>'Communicationslinks',
                group         =>'comdetails',
                forwardSearch =>1,
                allowcleanup  =>1,
                subeditmsk    =>'subedit.lnkapplappl',
                vjointo       =>'itil::lnkapplapplurl',
                vjoinon       =>['id'=>'lnkapplapplid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Select(
                name          =>'monitor',
                group         =>'classi',
                label         =>'Interface Monitoring',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::lnkapplappl::monitor',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::lnkapplappl::monitor',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitor'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitor',
                group         =>'classi',
                label         =>'raw Interface Monitoring',
                uploadable    =>0,
                dataobjattr   =>'lnkapplappl.monitor'),

      new kernel::Field::Select(
                name          =>'monitortool',
                group         =>'classi',
                label         =>'Interface Monitoring Tool',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitortool'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitortool',
                group         =>'classi',
                uploadable    =>0,
                label         =>'raw Interface Monitoring Tool',
                dataobjattr   =>'lnkapplappl.monitortool'),

      new kernel::Field::Select(
                name          =>'monitorinterval',
                group         =>'classi',
                label         =>'Interface Monitoring Interval',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::lnkapplappl::monitorinterval',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::lnkapplappl::monitorinterval',
                   cistatusid=>\'4'
                },
                vjoinon       =>['rawmonitorinterval'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Interface(
                name          =>'rawmonitorinterval',
                group         =>'classi',
                label         =>'raw Interface Monitoring Interval',
                dataobjattr   =>'lnkapplappl.monitorinterval'),


      new kernel::Field::Select(
                name          =>'persrelated',
                group         =>'classi',
                label         =>'transfer of person related informations',
                default       =>'0',
                transprefix   =>'PERS.',
                value         =>[0,1,2],
                htmleditwidth =>'200px',
                dataobjattr   =>'lnkapplappl.exch_personal_data'),

      new kernel::Field::Select(
                name          =>'iscrypted',
                group         =>'classi',
                label         =>'encrypted communication',
                default       =>'0',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if ($rec->{iscrypted} eq "1");
                   return(0);
                },
                transprefix   =>'CRYPT.',
                value         =>[0,10,20,30],
                htmleditwidth =>'200px',
                wrdataobjattr =>'iscrypted',
                dataobjattr   =>"if (lnkapplappl.conprotocol='https' or ".
                                "lnkapplappl.conprotocol='ldaps' or ".
                                "lnkapplappl.conprotocol='POP3S' or ".
                                "lnkapplappl.conprotocol='sftp' or ".
                                "lnkapplappl.conprotocol='sldap' or ".
                                "lnkapplappl.conprotocol='ssh','1',".
                                "lnkapplappl.iscrypted)"),

      new kernel::Field::Boolean(
                name          =>'handleconfidential',
                selectfix     =>1,
                group         =>'classi',
                label         =>'handle interface documentation confidential',
                dataobjattr   =>'lnkapplappl.handleconfidential'),


      new kernel::Field::Text(
                name          =>'implapplversion',
                group         =>'impl',
                label         =>'implemented since "from"-application release',
                dataobjattr   =>'lnkapplappl.implapplversion'),

      new kernel::Field::Text(
                name          =>'implproject',
                group         =>'impl',
                label         =>'implementation project name',
                dataobjattr   =>'lnkapplappl.implproject'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplappl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplappl.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplappl.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplappl.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplappl.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkapplappl.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkapplappl.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplappl.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplappl.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplappl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplappl.realeditor'),

      new kernel::Field::Interface(
                name          =>'fromapplid',
                label         =>'from ApplID',
                dataobjattr   =>'lnkapplappl.fromappl'),

      new kernel::Field::Interface(
                name          =>'gwapplid',
                label         =>'gateway ApplID',
                dataobjattr   =>'lnkapplappl.gwappl'),

      new kernel::Field::Interface(
                name          =>'gwappl2id',
                label         =>'further gateway ApplID',
                dataobjattr   =>'lnkapplappl.gwappl2'),

      new kernel::Field::Interface(
               name          =>'fromapplopmode',
               label         =>'from Appl primary operation mode',
               dataobjattr   =>'fromappl.opmode'),

      new kernel::Field::Link(
                name          =>'lnktoapplid',
                label         =>'to ApplicationID',
                dataobjattr   =>'toappl.applid'),

      new kernel::Field::Interface(
                name          =>'toapplid',
                label         =>'to ApplID',
                dataobjattr   =>'lnkapplappl.toappl'),






      new kernel::Field::Link(
                name          =>'secfromapplsectarget',
                noselect      =>'1',
                dataobjattr   =>'fromappllnkcontact.target'),

      new kernel::Field::Link(
                name          =>'secfromapplsectargetid',
                noselect      =>'1',
                dataobjattr   =>'fromappllnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secfromapplsecroles',
                noselect      =>'1',
                dataobjattr   =>'fromappllnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'secfromapplmandatorid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.mandator'),

      new kernel::Field::Link(
                name          =>'secfromapplbusinessteamid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.businessteam'),

      new kernel::Field::Link(
                name          =>'secfromappltsmid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.tsm'),

      new kernel::Field::Link(
                name          =>'secfromappltsm2id',
                noselect      =>'1',
                dataobjattr   =>'fromappl.tsm2'),

      new kernel::Field::Link(
                name          =>'secfromapplopmid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.opm'),

      new kernel::Field::Link(
                name          =>'secfromapplopm2id',
                noselect      =>'1',
                dataobjattr   =>'fromappl.opm2'),



      new kernel::Field::Link(
                name          =>'sectoapplsectarget',
                noselect      =>'1',
                dataobjattr   =>'toappllnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectoapplsectargetid',
                noselect      =>'1',
                dataobjattr   =>'toappllnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'sectoapplsecroles',
                noselect      =>'1',
                dataobjattr   =>'toappllnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'sectoapplmandatorid',
                noselect      =>'1',
                dataobjattr   =>'toappl.mandator'),

      new kernel::Field::Link(
                name          =>'sectoapplbusinessteamid',
                noselect      =>'1',
                dataobjattr   =>'toappl.businessteam'),


      new kernel::Field::Contact(
                name          =>'toappldataboss',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'toapplcontacts',
                label         =>'Databoss',
                translation   =>'itil::appl',
                vjoinon       =>'sectoappldatabossid'),

      new kernel::Field::Contact(
                name          =>'toapplapplmgr',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'toapplcontacts',
                label         =>'Application Manager',
                translation   =>'itil::appl',
                vjoinon       =>'sectoapplapplmgrid'),

      new kernel::Field::Contact(
                name          =>'toappltsm',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'toapplcontacts',
                label         =>'Technical Solution Manager',
                translation   =>'itil::appl',
                vjoinon       =>'sectoappltsmid'),

      new kernel::Field::Contact(
                name          =>'toappltsm2',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'toapplcontacts',
                label         =>'Deputy Technical Solution Manager',
                translation   =>'itil::appl',
                vjoinon       =>'sectoappltsm2id'),

      new kernel::Field::Contact(
                name          =>'toapplopm',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'toapplcontacts',
                label         =>'Operation Manager',
                translation   =>'itil::appl',
                vjoinon       =>'sectoapplopmid'),

      new kernel::Field::Contact(
                name          =>'toapplopm2',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'toapplcontacts',
                label         =>'Deputy Operation Manager',
                translation   =>'itil::appl',
                vjoinon       =>'sectoapplopm2id'),


      new kernel::Field::Link(
                name          =>'sectoappldatabossid',
                dataobjattr   =>'toappl.databoss'),

      new kernel::Field::Link(
                name          =>'sectoapplapplmgrid',
                dataobjattr   =>'toappl.applmgr'),

      new kernel::Field::Link(
                name          =>'sectoappltsmid',
                dataobjattr   =>'toappl.tsm'),

      new kernel::Field::Link(
                name          =>'sectoappltsm2id',
                dataobjattr   =>'toappl.tsm2'),

      new kernel::Field::Link(
                name          =>'sectoapplopmid',
                dataobjattr   =>'toappl.opm'),

      new kernel::Field::Link(
                name          =>'sectoapplopm2id',
                dataobjattr   =>'toappl.opm2'),


   );
   $self->{history}={
      insert=>[
         'local',
         {dataobj=>'itil::appl', id=>'fromapplid',
          field=>'toapplid',as=>'interfaces'}
      ],
      update=>[
         'local'
      ],
      delete=>[
         {dataobj=>'itil::appl', id=>'fromapplid',
          field=>'fullname',as=>'interfaces'}
      ]
   };


   $self->setDefaultView(qw(fromappl ifrel toappl cistatus cdate editor));
   $self->setWorktable("lnkapplappl");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_fromapplicationcistatus"))){
     Query->Param("search_fromapplicationcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_toapplicationcistatus"))){
     Query->Param("search_toapplicationcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub orderSearchMaskFields
{
   my $self=shift;
   my $searchfields=shift;
   my @searchfields=$self->SUPER::orderSearchMaskFields($searchfields);

   foreach my $fname (qw(gwappl2 ifrel gwappl)){
      if (in_array(\@searchfields,$fname)){
         @searchfields=grep({$_ ne $fname} @searchfields);
         splice(@searchfields,
                first_index("toapplicationcistatus",@searchfields)+1,0,$fname);
      }
   }
   return(@searchfields); 
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnkapplappl");
}



sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplappl ".
            "left outer join appl as toappl ".
            "on lnkapplappl.toappl=toappl.id ".
            "left outer join appl as fromappl ".
            "on lnkapplappl.fromappl=fromappl.id ".
            "left outer join appl as gwappl ".
            "on lnkapplappl.gwappl=gwappl.id ".
            "left outer join appl as gwappl2 ".
            "on lnkapplappl.gwappl2=gwappl2.id ".

            "left outer join lnkcontact toappllnkcontact ".
            "on toappllnkcontact.parentobj='itil::appl' ".
            "and toappl.id=toappllnkcontact.refid ".
            "left outer join lnkcontact fromappllnkcontact ".
            "on fromappllnkcontact.parentobj='itil::appl' ".
            "and fromappl.id=fromappllnkcontact.refid ".

            "left outer join costcenter toapplcostcenter ".
            "on toappl.conumber=toapplcostcenter.name ".
            "left outer join costcenter fromapplcostcenter ".
            "on fromappl.conumber=fromapplcostcenter.name ";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string());
}


sub getifrelHandlingScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var d=document.forms[0].elements['Formated_ifrel'];
var c=document.forms[0].elements['Formated_gwappl'];
var c2=document.forms[0].elements['Formated_gwappl2'];

if (d){
   var v=d.options[d.selectedIndex].value;
   if (v!="" && v!="DIRECT"){
      if (c){
         c.disabled=false;
      }
      if (c2){
         c2.disabled=false;
      }
   }
   else{
      if (c){
         c.disabled=true;
      }
      if (c2){
         c2.disabled=true;
      }
   }
}

EOF
   return($d);
}


sub getifagreementHandlingScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var d=document.forms[0].elements['Formated_ifagreementneeded'];
var c=document.forms[0].elements['Formated_ifagreementexclreason'];

if (d){
   var v=d.options[d.selectedIndex].value;
   if (v!="" && v!="0"){
      if (c){
         c.disabled=true;
         //addClass(c,"disabledClass");
      }
   }
   else{
      if (c){
         c.disabled=false;
         //removeClass(c,"disabledClass");
      }
   }
}

EOF
   return($d);
}




sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   my $userid=$self->getCurrentUserId();
   my $mode;
   my ($applrec,$msg);

   my $toapplChanged=0;
   if (defined($oldrec) && effChanged($oldrec,$newrec,'toapplid')) {
      $toapplChanged=1;
   }

   my $applobj=getModuleObject($self->Config,'itil::appl');

   if (exists($newrec->{toapplid}) && 
       (!defined($oldrec) || $toapplChanged)) {
      $mode='InterfaceNew';
   }
   elsif (effChanged($oldrec,$newrec,'cistatusid')) {
      $mode='InterfaceUpdate';
      $newrec->{id}=$oldrec->{id} if (!defined($newrec->{id}));
   }

   if ($mode ne "") {
      $applobj->SetFilter({id=>\$newrec->{fromapplid}});
      ($applrec,$msg)=$applobj->getOnlyFirst(qw(name));
      $newrec->{fromappl}=$applrec->{name};

      $applobj->ResetFilter();
      $applobj->SetFilter({id=>\$newrec->{toapplid}});
      ($applrec,$msg)=$applobj->getOnlyFirst(qw(databossid contacts name));
      $newrec->{toappl}=$applrec->{name};

      $self->SetFilter({id=>$newrec->{id}});
      my ($lnk,$msg)=$self->getOnlyFirst(qw(cistatus));
      $newrec->{cistatus}=$lnk->{cistatus};
      $applobj->NotifyWriteAuthorizedContacts($applrec,undef,
                   {emailfrom=>$userid},{rec=>$newrec,mode=>$mode},
                   \&NotifyIfPartner);
   }

   if ($toapplChanged) {
      $applobj->ResetFilter();
      $applobj->SetFilter({id=>\$oldrec->{toapplid}});
      ($applrec,$msg)=$applobj->getOnlyFirst(qw(databossid contacts));
      
      $applobj->NotifyWriteAuthorizedContacts($applrec,undef,
                   {emailfrom=>$userid},{rec=>$oldrec,mode=>'InterfaceDeleted'},
                   \&NotifyIfPartner); 
   }

   return($bak);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $userid=$self->getCurrentUserId();
   my $appl=getModuleObject($self->Config,'itil::appl');
   $appl->SetFilter({id=>\$oldrec->{toapplid}});
   my ($toappl,$msg)=$appl->getOnlyFirst(qw(databossid contacts));
   $appl->NotifyWriteAuthorizedContacts($toappl,undef,
             {emailfrom=>$userid},{rec=>$oldrec,mode=>'InterfaceDeleted'},
             \&NotifyIfPartner);

   return($bak);
}
 

sub NotifyIfPartner
{
   my $self=shift;
   my $notifyparam=shift;
   my $notifycontrol=shift;
   my $subject;
   my $text;

   return(undef) if (ref($notifycontrol->{rec}) ne 'HASH');
   my %rec=%{$notifycontrol->{rec}};

   my $lnkobj=getModuleObject($self->Config,'itil::lnkapplappl');

   $lnkobj->SetFilter({id=>$rec{id}});
   my ($ifurl,$msg)=$lnkobj->getOnlyFirst('urlofcurrentrec');

   # key = contype of fromappl
   # val = possible contypes of toappl
   my %contypeMap=(0=>[0,3],1=>[2,5],2=>[1,4],
                   3=>[3,0],4=>[2,5],5=>[1,4]);

   my %flt=(fromapplid=>\$rec{toapplid},
            fromapplcistatus=>[3,4,5],
            toapplid=>\$rec{fromapplid},
            conproto=>\$rec{conproto},
            contype=>$contypeMap{$rec{contype}},
            cistatusid=>\'<6');

   my $ifparam=$self->T('Interfacetype').': ';
   $ifparam.=$self->T('contype.'.$rec{contype})."\n";
   $ifparam.=$self->T('Interfaceprotocol').': ';
   $ifparam.=$rec{conproto}."\n";
   $ifparam.=$self->T('Interfacemode').': ';
   $ifparam.=$rec{conmode}."\n";
   $ifparam.=$self->T('Interface-State').': ';
   $ifparam.=$rec{cistatus}."\n\n";
   $ifparam.="Details:\n";
   $ifparam.=$ifurl->{urlofcurrentrec};

   my $todomsg=sprintf($self->T("If necessary, please perform any ".
                                "needed modifications of the ".
                                "interface documentation ".
                                "on the application '%s'."),
                       $rec{toappl});
   $text=$self->T("Dear Databoss").",\n\n";
   if ($notifycontrol->{mode} eq 'InterfaceNew') {
      $lnkobj->ResetFilter();
      $lnkobj->SetFilter(\%flt);
      return(undef) if ($lnkobj->CountRecords()!=0);

      $subject=sprintf($self->T("New Application interface to %s"),
                       $rec{toappl});
      $text.=sprintf($self->T("from the side of application '%s' ".
                              "has been documented a new interface ".
                              "to your application '%s'."),
                     $rec{fromappl},$rec{toappl});
      $text.="\n\n";
      $text.=$ifparam;
      $text.="\n\n";
      $text.=$todomsg;
   }

   if ($notifycontrol->{mode} eq 'InterfaceUpdate') {
      $lnkobj->ResetFilter();
      $lnkobj->SetFilter(\%flt);
      return(undef) if ($lnkobj->CountRecords()<1);
     
      $subject=sprintf($self->T("The status of Application interface ".
                                "to %s has been changed"),
                       $rec{toappl});
      $text.=sprintf($self->T("the application '%s' has changed the status ".
                              "of an application interface to '%s'."),
                     $rec{fromappl},$rec{toappl});
      $text.="\n\n";
      $text.=$ifparam;
      $text.="\n\n";
      $text.=$todomsg;
   }

   if ($notifycontrol->{mode} eq 'InterfaceDeleted') {
      $lnkobj->ResetFilter();
      $lnkobj->SetFilter(\%flt);
      return(undef) if ($lnkobj->CountRecords()<1);

      $subject=sprintf($self->T("An application interface ".
                                "to %s has been deleted"),
                       $rec{toappl});
      $text.=sprintf($self->T("from the side of application '%s' ".
                              "has been deleted an existing interface ".
                              "to your application '%s'."),
                     $rec{fromappl},$rec{toappl});
      $text.="\n\n";
      $text.=$ifparam;
      $text.="\n\n";
      $text.=$todomsg;
   }
   return(($subject,$text));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $ifrel=effVal($oldrec,$newrec,"ifrel");
   $ifrel="DIRECT" if ($ifrel eq "");

   my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
   my $toapplid=effVal($oldrec,$newrec,"toapplid");
   my $gwappl2id=effVal($oldrec,$newrec,"gwappl2id");
   my $gwapplid=effVal($oldrec,$newrec,"gwapplid");

   if ($fromapplid ne "" && 
       ($fromapplid eq $gwapplid || $fromapplid eq $gwappl2id)){
      $self->LastMsg(ERROR,
                     "from application not allowed as gateway application");
      return(0);
   }

   if ($toapplid ne "" && 
       ($toapplid eq $gwapplid || $toapplid eq $gwappl2id)){
      $self->LastMsg(ERROR,
                     "to application not allowed as gateway application");
      return(0);
   }



   my $gwappl2id=effVal($oldrec,$newrec,"gwappl2id");
   my $gwapplid=effVal($oldrec,$newrec,"gwapplid");
   if ($gwapplid eq "" && $gwappl2id ne ""){
      $newrec->{gwapplid}=$gwappl2id;
      $newrec->{gwappl2id}=undef;
   }
   my $gwappl2id=effVal($oldrec,$newrec,"gwappl2id");
   my $gwapplid=effVal($oldrec,$newrec,"gwapplid");
   if ($gwapplid eq "" && $gwappl2id ne "" && $gwapplid eq $gwappl2id){
      $newrec->{gwapplid}=$gwappl2id;
      $newrec->{gwappl2id}=undef;
   }

   my $gwappl2id=effVal($oldrec,$newrec,"gwappl2id");
   my $gwapplid=effVal($oldrec,$newrec,"gwapplid");

   if ($ifrel eq "DIRECT"){    # indirekt auf direkt
      if (!exists($newrec->{ifrel})){
         if (exists($newrec->{gwapplid}) && $newrec->{gwapplid} ne ""){
            $newrec->{ifrel}="INDIRECT";
         }
      }
      else{
         if (!exists($newrec->{gwapplid}) && !exists($newrec->{gwappl2id})){
            if ($gwapplid ne ""){
               $newrec->{gwapplid}=undef;
            }
            if ($gwappl2id ne ""){
               $newrec->{gwappl2id}=undef;
            }
         }
         else{
            if ($gwapplid ne "" || $gwappl2id ne ""){
               $self->LastMsg(ERROR,"gateway application not allowed");
               return(0);
            }
         }
      }
   }
   else{
      if (!exists($newrec->{ifrel})){
         if (exists($newrec->{gwapplid}) && $newrec->{gwapplid} eq ""){
            $newrec->{ifrel}="DIRECT";
         }
      }
      else{
         if ($gwapplid eq ""){
            $self->LastMsg(ERROR,"no valid gateway application specified");
            return(0);
         }
      }
   }

   my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
   if ($fromapplid==0){
      $self->LastMsg(ERROR,"invalid from application");
      return(0);
   }
   my $toapplid=effVal($oldrec,$newrec,"toapplid");
   if ($toapplid==0){
      $self->LastMsg(ERROR,"invalid to application");
      return(0);
   }
   my $fromservice=effVal($oldrec,$newrec,"fromservice");
   if ($fromservice ne "" &&
       ($fromservice=~m/[^a-z0-9_]/i)){
      $self->LastMsg(ERROR,"invalid characters in from service name");
      return(0);
   }

   my $toservice=effVal($oldrec,$newrec,"toservice");
   if ($toservice ne "" &&
       ($toservice=~m/[^a-z0-9_]/i)){
      $self->LastMsg(ERROR,"invalid characters in to service name");
      return(0);
   }
   my $fromurl=effVal($oldrec,$newrec,"fromurl");
   if ($fromurl ne ""){
      my $uri=$self->URLValidate($fromurl);
      if ($uri->{error}) {
         $self->LastMsg(ERROR,$uri->{error});
         return(0);
      }
   }
   my $tourl=effVal($oldrec,$newrec,"tourl");
   if ($tourl ne ""){
      my $uri=$self->URLValidate($tourl);
      if ($uri->{error}) {
         $self->LastMsg(ERROR,$uri->{error});
         return(0);
      }
   }
   if (exists($newrec->{ifagreementstate}) && $newrec->{ifagreementstate} eq ""){
      $newrec->{ifagreementstate}="CURRENT";
   }
   if (exists($newrec->{ifagreementdoc})){
      if ($newrec->{ifagreementdoc} eq ""){
         $newrec->{ifagreementstate}=undef;
      }
      else{
         $newrec->{ifagreementstate}="CURRENT";
      }
   }


   if (effVal($oldrec,$newrec,"cistatusid")<5) {
      # check against flag 'isnoifaceappl' in fromappl
      my $fromapplid=effVal($oldrec,$newrec,"fromapplid");
      my $applobj=getModuleObject($self->Config,"itil::appl");
      $applobj->SetFilter({id=>\$fromapplid});
      my ($applrec,$msg)=$applobj->getOnlyFirst(qw(name isnoifaceappl));
      if ($applrec->{isnoifaceappl}) {
         my $msg=sprintf($self->T("Preset of '%s' is: ".
                                  "'Application has no interfaces'"),
                         $applrec->{name});
         $self->LastMsg(ERROR,$msg);
         return(0);
      }
   }

   if (!defined($oldrec)) {
      if (!exists($newrec->{htmlagreements})) {
         $newrec->{htmlagreements}=
            "<h4>Ziel/Zweck der Schnittstelle - ".
            "Purpose of the Interface</h4>".
            "(nothing documented)".
            "<h4>Aufbau/Testphase - ".
            "Setup/Testing Phase</h4>".
            "(nothing documented)".
            "<h4>Regelverarbeitungen und Wartungen - ".
            "Rule Processing and Maintenance</h4>".
            "(nothing documented)".
            "<h4>Verhalten bei Datenfehlern (Ansp.) - ".
            "Behaviour in case of Data Errors (Contact)</h4>".
            "(nothing documented)".
            "<h4>Verhalten bei technischen Fehlern (Ansp.) - ".
            "Behaviour in case of Technical Errors (Contact)</h4>".
            "(nothing documented)".
            "<h4>Evtl. Regressanspruchsregelungen - ".
            "Possible Regulations for Recourse Rights</h4>".
            "(nothing documented)";
      }
      if (!exists($newrec->{htmldescription})){
         $newrec->{htmldescription}=
            "<h4>Technische Realisation (log. System, IP, usw.) - ".
            "Technical Realisation (log. system, IP, etc.)</h4>".
            "(nothing documented)".
            "<h4>Übertragungsvolumen/Datenmenge - ".
            "Transfer Volumes</h4>".
            "(nothing documented)".
            "<h4>Lieferzeiten/Lieferungs-Intervall - ".
            "Delivery Times/Delivery Intervals</h4>".
            "(nothing documented)".
            "<h4>Beschreibung des Monitorings - ".
            "Detailed Description of Monitoring</h4>".
            "(nothing documented)".
            "<h4>Inhalt/Felder - ".
            "Content/Fields</h4>".
            "(nothing documented)";
      }
   }


   if (exists($newrec->{toapplid}) && 
       (!defined($oldrec) || $oldrec->{toapplid}!=$toapplid)){
      my $applobj=getModuleObject($self->Config,"itil::appl");
      $applobj->SetFilter({id=>\$newrec->{toapplid}});
      my ($applrec,$msg)=$applobj->getOnlyFirst(qw(cistatusid));
      if (!defined($applrec) || 
          $applrec->{cistatusid}>4 || $applrec->{cistatusid}==0){
         $self->LastMsg(ERROR,"selected application is currently unuseable");
         return(0);
      }
   }

   my $applid=effVal($oldrec,$newrec,"fromapplid");

   if (exists($newrec->{ifagreementneeded}) && $newrec->{ifagreementneeded}){
      $newrec->{ifagreementexclreason}='';
   }

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplValid($applid,"interfaces")){
         $self->LastMsg(ERROR,"no write access");
         return(0);
      }
   }


   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ifagreement agreement comdetails impl
             interfacescomp tags desc classi source));
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my @l=qw(header default ifagreement agreement comdetails impl
             interfacescomp tags 
             desc classi source history toapplcontacts);
   if (defined($rec) && exists($rec->{ifagreementneeded}) &&
       !$rec->{ifagreementneeded}){
      @l=grep(!/^agreement$/,@l);
   }
   if (defined($rec) && $rec->{handleconfidential}){
      my $foundprivread=0;
      foreach my $appid ($rec->{fromapplid},$rec->{toapplid}){
         my $acl=$self->loadPrivacyAcl('itil::appl',$appid);
         if ($acl->{ro}){
            $foundprivread++;
            last;
         }
      }
      if (!$foundprivread){
         @l=grep(/^(default|source)$/,@l);
      }
   }


   return(@l);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @addflt;
      $self->itil::appl::addApplicationSecureFilter(['secfromappl','sectoappl'],\@addflt);
      push(@flt,\@addflt);
   }

   return($self->SetFilter(@flt));
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $applid=effVal($oldrec,$newrec,"fromapplid");
   my @editgroup=("default","interfacescomp","tags","desc","agreement",
                  "ifagreement",
                  "comdetails","impl","classi");

   return(@editgroup) if (!defined($oldrec) && !defined($newrec));
   return(@editgroup) if ($self->IsMemberOf("admin"));
   return(@editgroup) if ($self->isWriteOnApplValid($applid,"interfaces"));
   return(@editgroup) if (!$self->isDataInputFromUserFrontend());

   return(undef);
}

sub getRecordHtmlIndex
{
   my $self=shift;
   my $rec=shift;
   my $id=shift;
   my $viewgroups=shift;
   my $grouplist=shift;
   my $grouplabel=shift;
   my @indexlist=$self->SUPER::getRecordHtmlIndex($rec,$id,$viewgroups,
                                                  $grouplist,$grouplabel);
   push(@indexlist,{label=>$self->T('Interface agreement template'),
           href=>"InterfaceAgreement?id=$id",
           target=>"_blank"
          });

   return(@indexlist);
}

sub InterfaceAgreement
{
   my $self=shift;
   
   my $id=Query->Param("id");
   $self->ResetFilter();
   $self->SetFilter({id=>\$id,cistatusid=>"<=5"});
   my ($masterrec,$msg)=$self->getOnlyFirst(qw(fromapplid toapplid
                                               ifagreementlang));
   if (defined($masterrec)){
      my $oldlang;
      my $lang=$self->Lang();
      if (defined($ENV{HTTP_FORCE_LANGUAGE})) {
         $oldlang=$ENV{HTTP_FORCE_LANGUAGE};
      }
      if ($masterrec->{ifagreementlang} ne '') {
         $lang=$masterrec->{ifagreementlang};
         $ENV{HTTP_FORCE_LANGUAGE}=$lang;
      }

      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$masterrec->{fromapplid}});
      my ($ag1,$msg)=$appl->getOnlyFirst(qw(name id tsm applmgr description));
      $appl->ResetFilter();
      $appl->SetFilter({id=>\$masterrec->{toapplid}});
      my ($ag2,$msg)=$appl->getOnlyFirst(qw(name id tsm applmgr description));
      my @l=($ag1,$ag2);
      @l=sort({$a->{name} cmp $b->{name}} @l);

      $l[0]->{targetid}=$l[1]->{id};
      $l[1]->{targetid}=$l[0]->{id};
      $l[0]->{targetname}=$l[1]->{name};
      $l[1]->{targetname}=$l[0]->{name};
      $self->ResetFilter();
      $self->SetFilter([{fromapplid=>\$l[0]->{id},
                         toapplid=>\$l[0]->{targetid},
                         cistatusid=>"<=5"},
                        {fromapplid=>\$l[1]->{id},
                         toapplid=>\$l[1]->{targetid},
                         cistatusid=>"<=5"}]);
      my @iflist=$self->getHashList(qw(cdate mdate 
                                       fromapplid toapplid contype 
                                       conmode conproto
                                       htmlagreements htmldescription comments
                                       fromurl fromservice
                                       tourl toservice
                                       monitor monitortool
                                       monitorinterval persrelated));
      my %com=();
      foreach my $ifrec (@iflist){
         $ifrec->{key}=$ifrec->{fromapplid}."_".$ifrec->{toapplid}.
                       "_".$ifrec->{conmode}."_".$ifrec->{conproto};
         $ifrec->{revkey}=$ifrec->{toapplid}."_".$ifrec->{fromapplid}.
                       "_".$ifrec->{conmode}."_".$ifrec->{conproto};
         $com{$ifrec->{key}}++;
      }
      foreach my $ifrec (@iflist){
         $ifrec->{partnerok}=0;
         if (exists($com{$ifrec->{revkey}})){
            $ifrec->{partnerok}=1;
         }
      }
      foreach my $ctrl (@l){
         $ctrl->{interface}=[];
         foreach my $ifrec (@iflist){
            if ($ifrec->{fromapplid} eq $ctrl->{id}){
               push(@{$ctrl->{interface}},$ifrec);
            }
         }
      }

      my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
      my $n="../../../public/itil/load/lnkapplappl.jpg?".$cgi->query_string();
      my $html=$self->HttpHeader("text/html");

      my $skinbase='itil';
      my $formname='head';
      $html.=$self->getParsedTemplate("tmpl/ifagreement.form.$formname",
                                      {skinbase=>$skinbase,
                                       static  =>{LANG=>$lang,
                                                  LOGO=>$n,
                                                  APPLA=>$l[0]->{name},
                                                  APPLB=>$l[1]->{name}}});

      foreach my $ctrl (@l) {
         my $details="<p class=\"attention\">".
               sprintf($self->T("The interface agreement is described ".
                                "from the point of view of application '%s'."),
                                $ag1->{name}).
                     "</p>";
         (my $desc=$ctrl->{description})=~s{\n}{<br />}g;

         if ($#{$ctrl->{interface}}!=-1) {
            $details=$self->getParsedTemplate(
                               "tmpl/ifagreement.detail.head",
                               {skinbase=>$skinbase,
                                static=>{TARGET=>$ctrl->{targetname}}
                               });
            foreach my $ifrec (@{$ctrl->{interface}}){
               my %templvar=(CONMODE =>$ifrec->{conmode},
                             CONPROTO=>$ifrec->{conproto},
                             TARGET  =>$ctrl->{targetname});

               if ($ifrec->{comments} ne ""){
                  $templvar{COMMENTS}=$ifrec->{comments};
               }

               my @ifparam=qw(contype fromurl fromservice tourl toservice
                              monitor monitortool monitorinterval
                              persrelated);
               foreach my $param (@ifparam) {
                  if ($ifrec->{$param} ne "") {
                     my $label=$self->getField($param)->Label;
                     my $value;

                     if ($param eq 'contype') {
                        $value=$self->T("contype.$ifrec->{contype}");
                     }
                     elsif ($param eq 'persrelated') {
                        $value=$self->T("PERS.$ifrec->{persrelated}");
                     }
                     else {
                        $value=$ifrec->{$param};
                     }

                     $templvar{PARAM}.=$self->getParsedTemplate(
                                                 "tmpl/ext.ifagreement.param",
                                                 {skinbase=>$skinbase,
                                                  static=>{
                                                     LABEL=>$label,
                                                     PARAM=>$value
                                                 }});
                  }
               }

               foreach my $desc (qw(htmlagreements htmldescription)) {
                  if ($ifrec->{$desc} ne "") {
                     my $label=$self->getField($desc)->Label;

                     $templvar{DESCRIPTION}.=$self->getParsedTemplate(
                                   "tmpl/ext.ifagreement.description",
                                    {skinbase=>$skinbase,
                                     static=>{
                                        LABEL      =>$label,
                                        DESCRIPTION=>$ifrec->{$desc}
                                    }});
                  }
               }

               $details.=$self->getParsedTemplate(
                                   "tmpl/ifagreement.detail.line",
                                    {skinbase=>$skinbase,
                                     static=>\%templvar});
            }

            $details.=$self->getParsedTemplate(
                                "tmpl/ifagreement.detail.bottom",
                                {skinbase=>$skinbase});
         }

         $formname='line';
         $html.=$self->getParsedTemplate("tmpl/ifagreement.form.$formname",
                                         {skinbase=>$skinbase,
                                          static=>{
                                             APPL       =>$ctrl->{name},
                                             DESCRIPTION=>$desc,
                                             AM         =>$ctrl->{applmgr},
                                             TSM        =>$ctrl->{tsm},
                                             DETAILS    =>$details
                                         }});
      }

      my $dateobj=new kernel::Field::Date();
      $dateobj->setParent($self);
      my ($date,$tz)=$dateobj->getFrontendTimeString("HtmlDetail",
                                                     NowStamp("en"));
      my $formname='bottom';
      $html.=$self->getParsedTemplate("tmpl/ifagreement.form.$formname",
                                      {skinbase=>$skinbase,
                                       static  =>{NOW=>"$date $tz",
                                                  APPLA=>$l[0]->{name},
                                                  APPLB=>$l[1]->{name}}});
      print $html;
      
      if (defined($oldlang)) {
         $ENV{HTTP_FORCE_LANGUAGE}=$oldlang;
      }
      else {
         delete($ENV{HTTP_FORCE_LANGUAGE});
      }
   }
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(InterfaceAgreement));
}








1;
