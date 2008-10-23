package itil::system;
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
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'system.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'system.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'system.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::TextDrop(
                name          =>'databoss',
                label         =>'Databoss',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['databossid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'system.databoss'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                subeditmsk    =>'subedit.appl',
                allowcleanup  =>1,
                forwardSearch =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['appl','applcistatus','fraction'],
                vjoininhash   =>['appl','applcistatusid','mandatorid',
                                 'applid']),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                subeditmsk    =>'subedit.system',
                allowcleanup  =>1,
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinbase     =>[{softwarecistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['software','version','quantity','comments'],
                vjoininhash   =>['softwarecistatusid','liccontractcistatusid',
                                 'liccontractid',
                                 'software','version','quantity']),

      new kernel::Field::Text(
                name          =>'shortdesc',
                group         =>'misc',
                label         =>'Short Description',
                dataobjattr   =>'system.shortdesc'),

      new kernel::Field::TextDrop(
                name          =>'adm',
                group         =>'admin',
                label         =>'Administrator',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['admid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'admid',
                dataobjattr   =>'system.adm'),

      new kernel::Field::TextDrop(
                name          =>'admemail',
                group         =>'admin',
                label         =>'Administrator E-Mail',
                vjointo       =>'base::user',
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['admid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'asset',
                group         =>'physys',
                label         =>'Asset-Name',
                AllowEmpty    =>1,
                vjointo       =>'itil::asset',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'assetserialno',
                readonly      =>1,
                weblinkto     =>'none',
                translation   =>'itil::asset',
                label         =>'Serialnumber',
                group         =>'physys',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'serialno'),

      new kernel::Field::TextDrop(
                name          =>'location',
                depend        =>['assetid'],
                readonly      =>1,
                group         =>'location',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'assetroom',
                readonly      =>1,
                weblinkto     =>'none',
                label         =>'Room',
                group         =>'location',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'room'),

      new kernel::Field::Text(
                name          =>'assetplace',
                readonly      =>1,
                weblinkto     =>'none',
                label         =>'Place',
                group         =>'location',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'place'),

      new kernel::Field::Text(
                name          =>'assetrack',
                readonly      =>1,
                weblinkto     =>'none',
                label         =>'Rack',
                group         =>'location',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'rack'),

      new kernel::Field::TextDrop(
                name          =>'adm2',
                AllowEmpty    =>1,
                group         =>'admin',
                label         =>'Deputy Administrator',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['adm2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'adm2id',
                dataobjattr   =>'system.adm2'),

      new kernel::Field::TextDrop(
                name          =>'adm2email',
                group         =>'admin',
                label         =>'Deputy Administrator E-Mail',
                vjointo       =>'base::user',
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['adm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'adminteam',
                htmlwidth     =>'300px',
                group         =>'admin',
                label         =>'Administrationteam',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['adminteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'adminteamid',
                dataobjattr   =>'system.admteam'),

      new kernel::Field::Text(
                name          =>'adminteambossid',
                group         =>'admin',
                label         =>'Admin Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0,
                depend        =>['adminteamid']),

      new kernel::Field::Text(
                name          =>'adminteamboss',
                group         =>'admin',
                label         =>'Admin Team Boss',
                onRawValue    =>\&getTeamBoss,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['adminteambossid']),


      new kernel::Field::Select(
                name          =>'osrelease',
                group         =>'logsys',
                htmleditwidth =>'40%',
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'systemtype',
                group         =>'logsys',
                default       =>'standard',
                htmleditwidth =>'40%',
                label         =>'logical system type',
                value         =>['standard',
                                 'vmware',
                                 'Xen',
                                 'vPartition',
                                 'nPartition',
                                 'IntegrityVM',
                                 'gZone',                # solaris
                                 'lZone',                # solaris
                                 'LDomain',              # sun logische Domain
                                 'HDomain',              # sun hardware Domain
                                 'lpar',                 # z/os
                                 ],
                dataobjattr   =>'system.systemtype'),,

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Number(
                name          =>'cpucount',
                group         =>'logsys',
                label         =>'CPU-Count',
                dataobjattr   =>'system.cpucount'),

      new kernel::Field::Number(
                name          =>'memory',
                group         =>'logsys',
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>'system.memory'),

      new kernel::Field::Text(
                name          =>'hostid',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      my $osobj=$self->getParent->getField("osrelease");
                      my $os=$osobj->RawValue($param{current});
                      return(1) if ($os=~m/^solaris/i);
                   }
                   return(0);
                },
                depend        =>['osrelease','osreleaseid'],
                group         =>'logsys',
                label         =>'HostID',
                dataobjattr   =>'system.hostid'),

      new kernel::Field::Text(
                name          =>'consoleip',
                group         =>'logsys',
                label         =>'Console-IP[:Port]',
                dataobjattr   =>'system.consoleip'),

      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                AllowEmpty    =>1,
                group         =>'misc',
                label         =>'Service&Support Class',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'system.servicesupport'),


      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'system.comments'),

      new kernel::Field::Text(
                name          =>'conumber',
                group         =>'misc',
                htmlwidth     =>'100px',
                label         =>'CO-Number',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'system.conumber'),

      new kernel::Field::Text(
                name          =>'kwords',
                group         =>'misc',
                label         =>'Keywords',
                dataobjattr   =>'system.kwords'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::system',
                group         =>'attachments'),

      new kernel::Field::Link(
                name          =>'assetid',
                dataobjattr   =>'system.asset'),

      new kernel::Field::Link(
                name          =>'locationid',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'locationid'),

      new kernel::Field::TextDrop(
                name          =>'hwmodel',
                readonly      =>1,
                weblinkto     =>'none',
                group         =>'physys',
                label         =>'Hardwaremodel',
                vjointo       =>'itil::hwmodel',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['hwmodelid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'hwmodelid',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'hwmodelid'),

      new kernel::Field::TextDrop(
                name          =>'hwproducer',
                readonly      =>1,
                weblinkto     =>'none',
                group         =>'physys',
                label         =>'Producer',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'hwproducer'),

      new kernel::Field::Number(
                name          =>'hwcpucount',
                readonly      =>1,
                group         =>'physys',
                label         =>'CPU-Count',
                translation   =>'itil::asset',
                dataobjattr   =>'asset.cpucount'),

      new kernel::Field::Number(
                name          =>'hwcorecount',
                readonly      =>1,
                group         =>'physys',
                label         =>'Core-Count',
                translation   =>'itil::asset',
                dataobjattr   =>'asset.corecount'),

      new kernel::Field::Number(
                name          =>'hwmemory',
                readonly      =>1,
                group         =>'physys',
                label         =>'Memory',
                translation   =>'itil::asset',
                unit          =>'MB',
                dataobjattr   =>'asset.memory'),

      new kernel::Field::Text(
                name          =>'systemhandle',
                readonly      =>1,
                group         =>'physys',
                label         =>'Producer System-Handle',
                dataobjattr   =>'asset.systemhandle'),

      new kernel::Field::Text(
                name          =>'assetservicesupport',
                readonly      =>1,
                group         =>'physys',
                vjointo       =>'itil::servicesupport',
                vjoinon       =>['assetservicesupportid'=>'id'],
                vjoindisp     =>'name',
                label         =>'Producer Service&Support Class'),

      new kernel::Field::Link(
                name          =>'assetservicesupportid',
                dataobjattr   =>'asset.prodmaintlevel'),

      new kernel::Field::Link(
                name          =>'hwmodelid',
                vjointo       =>'itil::asset',
                vjoinon       =>['assetid'=>'id'],
                vjoindisp     =>'hwmodelid'),

      new kernel::Field::Select(
                name          =>'isprod',
                group         =>'opmode',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Productionsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_prod'),

      new kernel::Field::Select(
                name          =>'istest',
                group         =>'opmode',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Testsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_test'),

      new kernel::Field::Select(
                name          =>'isdevel',
                group         =>'opmode',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Developmentsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_devel'),

      new kernel::Field::Select(
                name          =>'iseducation',
                group         =>'opmode',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Educationsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_education'),

      new kernel::Field::Select(
                name          =>'isapprovtest',
                group         =>'opmode',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Approval Testsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_approvtest'),

      new kernel::Field::Select(
                name          =>'isreference',
                group         =>'opmode',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Referencesystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_reference'),

      new kernel::Field::Select(
                name          =>'isapplserver',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Server/Applicationserver',
                value         =>[0,1],
                dataobjattr   =>'system.is_applserver'),

      new kernel::Field::Select(
                name          =>'isworkstation',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Workstation',
                value         =>[0,1],
                dataobjattr   =>'system.is_workstation'),

      new kernel::Field::Select(
                name          =>'isprinter',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Printer/Printserver',
                value         =>[0,1],
                dataobjattr   =>'system.is_printer'),

      new kernel::Field::Select(
                name          =>'isbackupsrv',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Backupserver',
                value         =>[0,1],
                dataobjattr   =>'system.is_backupsrv'),

      new kernel::Field::Select(
                name          =>'isdatabasesrv',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Databaseserver',
                value         =>[0,1],
                dataobjattr   =>'system.is_databasesrv'),

      new kernel::Field::Select(
                name          =>'iswebserver',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'WEB-Server',
                value         =>[0,1],
                dataobjattr   =>'system.is_webserver'),

      new kernel::Field::Select(
                name          =>'ismailserver',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Mail/Mailrelay-Server',
                value         =>[0,1],
                dataobjattr   =>'system.is_mailserver'),

      new kernel::Field::Select(
                name          =>'isrouter',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Router/Networkrouter',
                value         =>[0,1],
                dataobjattr   =>'system.is_router'),

      new kernel::Field::Select(
                name          =>'isnetswitch',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Switch/Networkswitch',
                value         =>[0,1],
                dataobjattr   =>'system.is_netswitch'),

      new kernel::Field::Select(
                name          =>'isterminalsrv',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Terminalserver',
                value         =>[0,1],
                dataobjattr   =>'system.is_terminalsrv'),

      new kernel::Field::Select(
                name          =>'isnas',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'Network Attached Storage NAS',
                value         =>[0,1],
                dataobjattr   =>'system.is_nas'),

      new kernel::Field::Select(
                name          =>'isclusternode',
                group         =>'systemclass',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                label         =>'ClusterNode',
                value         =>[0,1],
                dataobjattr   =>'system.is_clusternode'),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                allowcleanup  =>1,
                forwardSearch =>1,
                subeditmsk    =>'subedit.system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['webaddresstyp','name','cistatus',
                                 'dnsname','shortcomments'],
                vjoininhash   =>['id','name','addresstyp',
                                 'cistatusid',
                                 'dnsname','comments']),

      new kernel::Field::SubList(
                name          =>'ipaddresseslist',
                label         =>'IP-Adresses list',
                group         =>'ipaddresses',
                htmldetail    =>0,
                subeditmsk    =>'subedit.system',
                vjoinbase     =>[{cistatusid=>\"4"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['name']),

      new kernel::Field::SubList(
                name          =>'dnsnamelist',
                label         =>'DNS-Name list',
                group         =>'ipaddresses',
                htmldetail    =>0,
                subeditmsk    =>'subedit.system',
                vjoinbase     =>[{cistatusid=>\"4"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['dnsname']),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'system.additional'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::system'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::system'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'system.allowifupdate'),

      new kernel::Field::Text(
                name          =>'ccproxy',
                group         =>'control',
                label         =>'ControlCenter Proxy',
                dataobjattr   =>'system.ccproxy'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'system.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'system.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'system.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'system.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'system.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'system.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'system.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'system.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'system.realeditor'),

      new kernel::Field::SubList(
                name          =>'customer',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'400px',
                label         =>'Customer',
                group         =>'applications',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['applcustomer','appl']),

      new kernel::Field::SubList(
                name          =>'customerprio',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'400px',
                translation   =>'itil::appl',
                label         =>'Customers Application Prioritiy',
                group         =>'applications',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['applcustomerprio','appl']),

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
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'system.lastqcheck'),

   );
   $self->{workflowlink}={ workflowkey=>[id=>'affectedsystemid']
                         };
   $self->{history}=[qw(insert modify delete)];
   $self->{use_distinct}=1;
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->AddGroup("control",translation=>'itil::system');
   $self->setDefaultView(qw(name location cistatus mdate));
   $self->setWorktable("system");
   return($self);
}

sub getTeamBossID
{
   my $self=shift;
   my $current=shift;
   my $teamfieldname=$self->{depend}->[0];
   my $teamfield=$self->getParent->getField($teamfieldname);
   my $teamid=$teamfield->RawValue($current);
   my @teambossid=();
   if ($teamid ne ""){
      my $lnk=getModuleObject($self->getParent->Config,
                              "base::lnkgrpuser");
      $lnk->SetFilter({grpid=>\$teamid,
                       nativroles=>'RBoss'});
      foreach my $rec ($lnk->getHashList("userid")){
         if ($rec->{userid} ne ""){
            push(@teambossid,$rec->{userid});
         }
      }
   }
   return(\@teambossid);
}

sub PhoneUsage
{
   my $self=shift;
   return('phoneRB',$self->T("phoneRB","itil::appl"));
}



sub getTeamBoss
{  
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("fullname")){
         if ($rec->{fullname} ne ""){
            push(@teamboss,$rec->{fullname});
         }
      }
   }
   return(\@teamboss);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.system.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["REmployee","RMember"],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {admid=>$userid},       {adm2id=>$userid},
                 {adminteamid=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if (length($name)<3 || haveSpecialChar($name)){
      $self->LastMsg(ERROR,"invalid system name '%s' specified",$name);
      return(0);
   }
   $newrec->{name}=lc($name) if (exists($newrec->{name}) &&
                                 $newrec->{name} ne lc($name));
   my $systemid=trim(effVal($oldrec,$newrec,"systemid"));
   if (exists($newrec->{systemid}) && $newrec->{systemid} ne $systemid){
      $newrec->{systemid}=$systemid;
   }
   $newrec->{systemid}=undef if (exists($newrec->{systemid}) &&
                                 $newrec->{systemid} eq "");
   if (defined($newrec->{asset}) && $newrec->{asset} eq ""){
      $newrec->{asset}=undef;
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          !($self->IsMemberOf("databossin")) &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::system' ".
          "and $worktable.id=lnkcontact.refid ".
          " left outer join asset on system.asset=asset.id";

   return($from);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $refobj=getModuleObject($self->Config,"itil::systemnfsnas");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'systemid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }


   return($bak);
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::system");
}








sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default software admin logsys contacts misc opmode 
                       physys ipaddresses phonenumbers
                       attachments control systemclass);
   if (!defined($rec)){
      return("default","admin","misc","opmode","control","systemclass");
   }
   else{
      if ($rec->{databossid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
            return(@databossedit) if (grep(/^write$/,@roles));
         }
      }
      if ($rec->{mandatorid}!=0 &&
         $self->IsMemberOf($rec->{mandatorid},"RCFManager","down")){
         return(@databossedit);
      }
      if ($rec->{adminteamid}!=0 &&
         $self->IsMemberOf($rec->{adminteamid},"RCFManager","down")){
         return(@databossedit);
      }
   }
   return(undef);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default admin phonenumbers logsys location physys systemclass 
             opmode applications software ipaddresses
             contacts misc attachments control source));
}

#############################################################################
#
#  ControlCenter implementation
#
sub getValidWebFunctions
{
   my ($self)=@_;

   return(qw(ControlCenter ControlCenterSelectJob ControlCenterRunJob 
             ChangeTiming
             ControlCenterActiveJobs ControlCenterPublicKey),
             $self->SUPER::getValidWebFunctions());
}

sub ControlCenterActiveJobs
{
   my $self=shift;
   my $id=Query->Param("id");

   Query->Param("FormatAs"=>"HtmlV01");
   Query->Param('$NOVIEWSELECT$'=>1);

   if ($id ne ""){
      my $wf=$self->getPersistentModuleObject("base::workflow");
      if (!$wf->{IsFrontendInitialized}){
         $wf->{IsFrontendInitialized}=$wf->FrontendInitialize();
      }
      $wf->ResetFilter();
      $wf->setDefaultView(qw(eventstart eventduration state name));
      $wf->SecureSetFilter([
                            {class=>\'itil::workflow::systemjob',
                            eventend=>'>now-1h',
                            affectedsystemid=>\$id,
                            stateid=>'>=20'},
                            {class=>\'itil::workflow::systemjob',
                            eventstart=>'>now-1h',
                            affectedsystemid=>\$id,
                            stateid=>'>=20'},
                            {class=>\'itil::workflow::systemjob',
                            eventstart=>'>now-24h',
                            affectedsystemid=>\$id,
                            stateid=>'<20'},
                           ]);
      $wf->SetCurrentOrder(qw(eventstartrev));
      return($wf->Result(ExternalFilter=>1));
   }
}
sub ControlCenterRunJob
{
   my $self=shift;
   my $id=Query->Param("id");
   my $jobid=Query->Param("jobid");

   my $userid=$self->getCurrentUserId();
   my $sys=$self->getPersistentModuleObject("itil::system");
   $sys->ResetFilter();
   $sys->SetFilter({id=>\$id});
   my ($system,$msg)=$sys->getOnlyFirst(qw(admid adm2id));
   my $jobo=$self->getPersistentModuleObject("itil::systemjob");
   $jobo->ResetFilter();
   $jobo->SetFilter($self->ControlCenterJobFilterByID($jobid));
   my ($job,$msg)=$jobo->getOnlyFirst(qw(name param));
   my $joballowed=0;
   $joballowed=1 if ($self->ControlCenterCheckJobAccess($sys,$jobo,
                                                        $system,$job));
   if (!$joballowed){
      my $lnko=$self->getPersistentModuleObject("itil::lnksystemjobsystem");
      $lnko->ResetFilter();
      $lnko->SetFilter({systemid=>\$id,jobid=>\$jobid});
      my ($lnkrec,$msg)=$lnko->getOnlyFirst(qw(id));
      $joballowed=1 if (defined($lnkrec));
   }

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1);
   if ($id eq ""){
      printf("ERROR: no systemid");
      return(undef);
   }
   if (Query->Param("DO")){
      my %param;
      foreach my $pline (split(/\n/,$job->{param})){
         my ($pname,$data)=$pline=~m/^\s*(.*)\s*=\s*(.*)\s*$/;
         $param{$pname}=Query->Param($pname);
      }
      if ($self->ControlCenterStartJob($id,$jobid,%param)){
         print("<script>parent.fRefreshJobList();".
               "parent.hidePopWin(false);</script>");
      }
      else{
         print("Fail: LastMsg");
      }
   }
   else{
      if (defined($job) && defined($system) && $joballowed){
       
         printf("<table width=100%% height=100%%>");
         printf("<tr height=1%%>".
                "<td width=1%% nowrap><b>Job name:</b></td>".
                "<td><u>%s</u></td></tr>",
                $job->{name});
         printf("<tr><td colspan=2>".
                "<div style=\"width:100%;height:130px;overflow:auto;".
                "border-style:solid;border-width:1px;border-color:black\">");
         printf("<table width=100%% style=\"border-width:1px;".
                "border-color:silver\">");
         printf("<tr><th width=1%%>Parameter</th>".
                "<th align=left>Eingabewert</th></tr>");
         foreach my $pline (split(/\n/,$job->{param})){
            my ($pname,$data)=$pline=~m/^\s*(.*)\s*=\s*(.*)\s*$/;
            if ($data=~m/\?/){
               $data=~s/\?//;
               $data=~s/"/&quot;/;
               $data=~s/</&lt;/;
               $data=~s/>/&gt;/;
               printf("<tr><td nowrap>%s</td><td><input type=text name=\"%s\" ".
                      "value=\"%s\"></td></tr>",$pname,$pname,$data); 
            }
            elsif($data=~m/\|/){
               printf("<tr><td nowrap>%s</td><td><select name=\"%s\"> ",
                      $pname,$pname); 
               foreach my $opt (split(/\|/,$data)){
                  printf("<option value=\"%s\">%s</option>",$opt,$opt); 
               }
               printf("</select></td></tr>"); 
            }
            else{
               $data=~s/"/&quot;/;
               $data=~s/</&lt;/;
               $data=~s/>/&gt;/;
               printf("<tr><td nowrap>%s</td><td><input type=text name=\"%s\" ".
                      "value=\"%s\" readonly ".
                      "style=\"background-color:silver\"></td></tr>",
                      $pname,$pname,$data); 
            }
         }
         printf("</table>");
         printf("</td></tr>");
         printf("<tr height=1%%><td colspan=2 align=center>".
                "<input class=RunJob  type=submit ".
                "name=DO value=\"Run\">".
                "</td></tr></table>");
      }
      else{
         print("ERROR: job not found or not allowed");
      }
   }
   print <<EOF;
<link rel=stylesheet type="text/css" 
      href="../../../public/itil/load/ControlCenter.css"></link>
<input type=hidden name=id value="$id\">
<input type=hidden name=jobid value="$jobid">
EOF
   print $self->HtmlBottom(body=>1,form=>1);
   return(1);
}

sub ControlCenterCheckJobAccess
{
   my $self=shift;
   my $sysobj=shift;
   my $jobobj=shift;
   my $sys=shift;
   my $job=shift;
   my $userid=$self->getCurrentUserId();
   my $joballowed=0;

   my $c=$self->Context;
   $c->{ControlCenterAcl}={} if (!defined($c->{ControlCenterAcl}));
   $c=$c->{ControlCenterAcl};
   if (!defined($c->{$sys->{id}})){
      $joballowed=1 if ($sys->{admid}==$userid || 
                        $sys->{adm2id}==$userid);
      if (!$joballowed){
         my @fg=$sysobj->isWriteValid($sys);
         $joballowed=1 if (grep(/^default$/,@fg) || grep(/^ALL$/,@fg));
      }
      if (!$joballowed){
         $joballowed=1 if ($self->IsMemberOf("admin"));
      }
      $c->{$sys->{id}}=$joballowed;
   }
   return($c->{$sys->{id}});
}


sub ControlCenterJobFilterByID
{
   my $self=shift;
   my $jobid=shift;

   my %flt;
   %flt=(id=>\$jobid) if ($jobid ne "");
   my @q=();
   my $userid=$self->getCurrentUserId();
   my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','both');
   push(@q,{%flt,owner=>\$userid});
   push(@q,{%flt,aclmode=>['write','run'],
                 acltarget=>\'base::user',
                 acltargetid=>[$userid]});
   push(@q,{%flt,aclmode=>['write','run'],
                 acltarget=>\'base::grp',
                 acltargetid=>[keys(%groups)]});
   return(\@q);
}

sub ControlCenterStartJob
{
   my $self=shift;
   my $id=shift;
   my $jobid=shift;
   my %param=@_;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $sysobj=$self->getPersistentModuleObject("itil::system");
   my $jobobj=$self->getPersistentModuleObject("itil::systemjob");
   my $lnkjob=$self->getPersistentModuleObject("itil::lnksystemjobsystem");
   $jobobj->ResetFilter();
   $jobobj->SetFilter($self->ControlCenterJobFilterByID($jobid));

   my ($job,$msg)=$jobobj->getOnlyFirst(qw(ALL));
   if (!defined($job)){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css'],
                              title=>'Job select',
                              body=>1,form=>1);
      printf("ERROR: Job not found");
      return(undef);
   }

   $sysobj->ResetFilter();
   $sysobj->SetFilter({id=>\$id});
   my ($system,$msg)=$sysobj->getOnlyFirst(qw(name admid adm2id));

   if (!defined($system)){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css'],
                              title=>'Job select',
                              body=>1,form=>1);
      printf("ERROR: System not found");
      return(undef);
   }

   my $userid=$self->getCurrentUserId();
   if (!$self->ControlCenterCheckJobAccess($sysobj,$jobobj,$system,$job)){
      $lnkjob->ResetFilter();
      $lnkjob->SetFilter({systemid=>\$id,jobid=>\$jobid});
      my ($lnkrec,$msg)=$sysobj->getOnlyFirst(qw(id));
      if (!defined($lnkrec)){
         print $self->HttpHeader("text/html");
         print $self->HtmlHeader(style=>['default.css','work.css'],
                                 title=>'Job select',
                                 body=>1,form=>1);
         printf("ERROR: Job not linked to system");
         return(undef);
      }
   }

   if (defined($job)){
      if ($id=$wf->Store(undef,{class  =>'itil::workflow::systemjob',
                                step   =>'itil::workflow::systemjob::dataload',
                                jobid  =>$jobid,
                                affectedsystemid=>$id,
                                affectedsystem=>$system->{name},
                                jobsystemname=>$system->{name},
                                additional=>\%param,
                                name   =>$job->{name}})){
         my %d=(step=>'itil::workflow::systemjob::pending');
         my $r=$wf->Store($id,\%d);
         return(1);
      }
   }
   return(undef);
}

sub ChangeTiming
{
   my $self=shift;
   my $id=Query->Param("id");
   my $jobid=Query->Param("jobid");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           title=>'Timing Control',
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   my $syso=$self->getPersistentModuleObject("itil::system");
   my $jobo=$self->getPersistentModuleObject("itil::systemjob");
   my $timo=$self->getPersistentModuleObject("itil::systemjobtiming");

   $syso->ResetFilter();
   $syso->SetFilter({id=>\$id});
   my ($system,$msg)=$syso->getOnlyFirst(qw(name admid adm2id));

   $jobo->ResetFilter();
   $jobo->SetFilter($self->ControlCenterJobFilterByID($jobid));
   my ($job,$msg)=$jobo->getOnlyFirst(qw(name param));

   my $timeofilter={jobid=>\$jobid,systemid=>\$id};
   $timo->ResetFilter();
   $timo->SetFilter($timeofilter);
   my ($jobt,$msg)=$timo->getOnlyFirst(qw(ALL));

   my $joballowed=0;
   $joballowed=1 if ($self->ControlCenterCheckJobAccess($syso,$jobo,
                                                        $system,$job));

   my @options=("0"=>"no timing",
                "2"=>"dayly",
                "3"=>"weekly",
                "4"=>"monthly");
   my @options=("0"=>"no timing",
                "1"=>"one time",
                "2"=>"start the job daily");

   my @days=qw(mon tue wed thu fri sat sun);

   if (Query->Param("SAVE")){
      if ($joballowed){
         my $newrec=$timo->getWriteRequestHash("web",$jobt);
         delete($newrec->{id});
         foreach my $day (qw(sun mon tue wed thu fri sat)){
            $newrec->{"plannedwd".$day}=0;
            if (Query->Param($day) eq "on"){
               $newrec->{"plannedwd".$day}=1;
            }
         }
         $newrec->{"plannedhour"}=undef if (!exists($newrec->{"plannedhour"}));
         $newrec->{"plannedmin"}=undef  if (!exists($newrec->{"plannedmin"}));
         $newrec->{"plannedday"}=undef  if (!exists($newrec->{"plannedday"}));
         $newrec->{"plannedmon"}=undef if (!exists($newrec->{"plannedmon"}));
         $newrec->{"plannedyear"}=undef if (!exists($newrec->{"plannedyear"}));
         $newrec->{"systemid"}=$id;
         $newrec->{"jobid"}=$jobid;

printf STDERR ("fifi write=%s\n",Dumper($newrec));
         $timo->ValidatedInsertOrUpdateRecord($newrec,$timeofilter);
         $timo->ResetFilter();
         $timo->SetFilter($timeofilter);
         ($jobt,$msg)=$timo->getOnlyFirst(qw(ALL));
      }
   }
   ######################################################################
   my $plannedyear=$jobt->{plannedyear};
   if (defined(Query->Param("Formated_plannedyear"))){
      $plannedyear=Query->Param("Formated_plannedyear");
   }
   my $pY="<select name=Formated_plannedyear id=plannedyear ".
         "style=\"width:70px;margin-left:2px\">";
   for(my $c=2007;$c<=2050;$c++){
      $pY.="<option value=\"$c\"";
      $pY.=" selected" if ($c eq $plannedyear);
      $pY.=">$c</option>";
   }
   $pY.="</select>";
   ######################################################################
   my $plannedmon=$jobt->{plannedmon};
   if (defined(Query->Param("Formated_plannedmon"))){
      $plannedmon=Query->Param("Formated_plannedmon");
   }
   my $pM="<select name=Formated_plannedmon id=plannedmon ".
         "style=\"width:40px;margin-left:2px\">";
   for(my $c=1;$c<=12;$c++){
      $pM.="<option value=\"$c\"";
      $pM.=" selected" if ($c eq $plannedmon);
      $pM.=">$c</option>";
   }
   $pM.="</select>";
   ######################################################################
   my $plannedday=$jobt->{plannedday};
   if (defined(Query->Param("Formated_plannedday"))){
      $plannedday=Query->Param("Formated_plannedday");
   }
   my $pD="<select name=Formated_plannedday id=plannedday ".
         "style=\"width:40px;margin-left:2px\">";
   for(my $c=1;$c<=31;$c++){
      $pD.="<option value=\"$c\"";
      $pD.=" selected" if ($c eq $plannedday);
      $pD.=">$c</option>";
   }
   $pD.="</select>";
   ######################################################################
   my $plannedmin=$jobt->{plannedmin};
   if (defined(Query->Param("Formated_plannedmin"))){
      $plannedmin=Query->Param("Formated_plannedmin");
   }
   my $pm="<select name=Formated_plannedmin id=plannedmin ".
         "style=\"width:40px;margin-left:2px\">";
   for(my $c=0;$c<=59;$c++){
      $pm.="<option value=\"$c\"";
      $pm.=" selected" if ($c eq $plannedmin);
      $pm.=">$c</option>";
   }
   $pm.="</select>";
   ######################################################################
   my $plannedhour=$jobt->{plannedhour};
   if (defined(Query->Param("Formated_plannedhour"))){
      $plannedhour=Query->Param("Formated_plannedhour");
   }
   my $ph="<select name=Formated_plannedhour id=plannedhour ".
         "style=\"width:40px;margin-left:2px\">";
   for(my $c=0;$c<=23;$c++){
      $ph.="<option value=\"$c\"";
      $ph.=" selected" if ($c eq $plannedhour);
      $ph.=">$c</option>";
   }
   $ph.="</select>";
   ######################################################################
   my $tinterval=$jobt->{tinterval};
   if (defined(Query->Param("Formated_tinterval"))){
      $tinterval=Query->Param("Formated_tinterval");
   }
   my $s="<select name=Formated_tinterval id=tinterval ".
         "style=\"width:100%;margin-left:2px\">";
   while(defined(my $k=shift(@options))){
      my $v=shift(@options);
      $s.="<option value=\"$k\"";
      $s.=" selected" if ($k eq $tinterval);
      $s.=">$v</option>";
   }
   $s.="</select>";
   ######################################################################
   my %daycb;
   foreach my $day (@days){
      my $oldval=0;
      $oldval=1 if (Query->Param("plannedwd".$day));
      $oldval=1 if ($jobt->{"plannedwd".$day});
      $daycb{$day}="<input type=checkbox name=$day";  
      $daycb{$day}.=" checked" if ($oldval);
      $daycb{$day}.=">";
   }
   ######################################################################

   print <<EOF;
$s
<style>
body{
  overflow:hidden;
}
div.timingbox{
   border-style:solid;
   border-width:1px;
   border-color:black;
   height:45px;
   margin-top:2px;
   margin-left:2px;
   margin-bottom:4px;
   display:none;
}
div.syncctrlbox{
   border-style:solid;
   border-width:1px;
   border-color:black;
   height:45;
   margin-top:2px;
   margin-left:2px;
   margin-bottom:4px;
}
div.state{
   border-style:solid;
   border-width:1px;
   border-color:black;
   height:45;
   margin-top:2px;
   margin-left:2px;
   margin-bottom:4px;
}
</style>
<div id=tinterval0 class=timingbox>
No timing
</div> 
<div id=tinterval1 class=timingbox>
 <table width=100% border=0 cellspacing=0 cellpadding=0>
 <tr>
 <td align=center>
  <table border=0 cellspacing=2 cellpadding=0>
  <tr><td>day:</td><td>$pD</td>
      <td>month:</td><td>$pM</td>
      <td>year:</td><td>$pY</td>
  </table>
 </td></tr>
 <tr>
 <td align=center>
  <table border=0 cellspacing=2 cellpadding=0>
  <tr><td>hour:</td><td>$ph</td><td>minute:</td><td>$pm</td>
      <td> in GMT</td></tr>
  </table>
 </td></tr>
 </table>
</div> 
<div id=tinterval2 class=timingbox>
<table width=100% border=0 cellspacing=0 cellpadding=0>
<tr>
<td colspan=7 align=center>
<table border=0 cellspacing=2 cellpadding=0>
<tr><td>hour:</td><td>$ph</td><td>minute:</td><td>$pm</td><td> in GMT</td></tr>
</table>
</td>
</tr>
<tr>
<td>$daycb{sun}Sun</td>
<td>$daycb{mon}Mon</td>
<td>$daycb{tue}Tue</td>
<td>$daycb{wed}Wed</td>
<td>$daycb{thu}Thu</td>
<td>$daycb{fri}Fri</td>
<td>$daycb{sat}Sat</td>
</tr>
</table>
</div> 
<div id=tinterval3 class=timingbox>
start job monthly
</div> 
<div id=tinterval4 class=timingbox>
start job monthly
</div> 
<div id=syncctrl class=syncctrlbox>
<table>
<tr>
<td valign=top width=1%><input type=checkbox name=synccontrol></td>
<td>start um maximal <select name=maxlatency><option value="1">1</option></select> Stunden verzögern, falls der
job bereits <select name=synccontrolmode><option value="1">auf mehr als n anderen Systemen</option></select> läuft.</td>
</tr>
</table>
</div> 
<div id=state class=state>
<table>
<tr>
<td nowrap valign=top width=1%>Lastrun:</td>
<td>xxx</td>
</tr>
<tr>
<td nowrap valign=top width=1%>Timer erstellt:</td>
<td>xxx</td>
</tr>

</table>
</div> 

<input type=hidden name=id value="$id">
<input type=hidden name=jobid value="$jobid">
<center><input type=submit name=SAVE value=" save "></center>


<script language="JavaScript">
function divSwitcher(sel,defval)
{
   var syncctrl=false;
   var tags=new Array("input","select");
   for(c=0;c<sel.options.length;c++){
      var ov=sel.options[c].value;
      var d=document.getElementById(sel.id+ov);
      var disa=true;
      if (sel.options[c].selected){
         d.style.display="block";
         disa=false;
         if (ov=="0"){
            syncctrl=true;
         }
      }
      else{
         d.style.display="none";
      }
      for(tn=0;tn<tags.length;tn++){
         var subs=d.getElementsByTagName(tags[tn]);
         for(cc=0;cc<subs.length;cc++){
            subs[cc].disabled=disa;
         }
      }
   }
   var d=document.getElementById("syncctrl");
   for(tn=0;tn<tags.length;tn++){
      var subs=d.getElementsByTagName(tags[tn]);
      for(cc=0;cc<subs.length;cc++){
         subs[cc].disabled=syncctrl;
      }
   }

   addEvent(sel,"change",function(){divSwitcher(sel);});
}
function InitDivs()
{
   var s=document.getElementById("tinterval");
   divSwitcher(s,"$tinterval");
}

InitDivs();

</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
   return(1);
}


sub ControlCenterSelectJob
{
   my $self=shift;
   my $id=Query->Param("id");
   my $jobid=Query->Param("jobid");
   return(undef) if ($id eq "");
   my $syso=$self->getPersistentModuleObject("itil::system");
   my $jobo=$self->getPersistentModuleObject("itil::systemjob");
   my $lnkjob=$self->getPersistentModuleObject("itil::lnksystemjobsystem");
   my $OP=Query->Param("OP");
   if ($OP ne ""){
      if ($OP eq "add" && $id ne "" && $jobid ne ""){
         $lnkjob->ResetFilter();
         $lnkjob->ValidatedInsertRecord({jobid=>$jobid,systemid=>$id});
      }
      if ($OP eq "del" && $id ne "" && $jobid ne ""){
         $lnkjob->ResetFilter();
         $lnkjob->SetFilter({jobid=>\$jobid,systemid=>\$id});
         $lnkjob->ForeachFilteredRecord(sub{
                            $lnkjob->ValidatedDeleteRecord($_);
                         });

      }
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           title=>'Job select',
                           body=>1,form=>1);
   $jobo->ResetFilter();
   $jobo->SetFilter($self->ControlCenterJobFilterByID());

   $syso->ResetFilter();
   $syso->SetFilter({id=>\$id});
   my ($system,$msg)=$syso->getOnlyFirst(qw(name admid adm2id));

   $lnkjob->ResetFilter();
   $lnkjob->SetFilter({systemid=>\$id});

   my @jl=map({$_->{jobid}} $lnkjob->getHashList(qw(jobid)));
   print("<table width=100% border=1 cellspacing=0 cellpadding=0>");
   foreach my $job ($jobo->getHashList(qw(ALL))){
      if ($self->ControlCenterCheckJobAccess($syso,$jobo,$system,$job)){
         printf("<tr><td>%s</td>",$job->{name});
         printf("<td width=1%%>".
                "<input type=button class=RunJob style=\"width:80px\" ".
                "onclick=RunJob($id,$job->{id}) ".
                "value=\"Run\"></td>");
         if (grep(/^$job->{id}$/,@jl)){
            printf("<td width=135><input style=\"width:110px\" ".
                   "onclick=doDel($job->{id}) ".
                   "type=button value=\"remove from server\">");
         }
         else{
            printf("<td width=135><input style=\"width:110px\" ".
                   "onclick=doAdd($job->{id}) ".
                   "type=button value=\"add to server\">");
         }
         printf("<input  type=button ".
                   "onclick=doChangeTiming($job->{id}) ".
                   "id=Timing value=\"\"></td>");

         printf("</tr>");
      }
   }
   print("</table>");
   print("<input type=hidden name=id value=\"$id\">");
   print("<input type=hidden name=jobid value=\"\">");
   print("<input type=hidden name=OP value=\"\">");
   print(<<EOF);
<script language="JavaScript">
function doChangeTiming(jobid)
{
   document.forms[0].elements['jobid'].value=jobid;
   document.forms[0].action="ChangeTiming";
   document.forms[0].submit();
}
function doAdd(jobid)
{
   document.forms[0].elements['jobid'].value=jobid;
   document.forms[0].elements['OP'].value="add";
   document.forms[0].submit();
}
function doDel(jobid)
{
   document.forms[0].elements['jobid'].value=jobid;
   document.forms[0].elements['OP'].value="del";
   document.forms[0].submit();
}
function RunJob(id,jobid)
{
   parent.hidePopWin(false);
   parent.RunJob(id,jobid);
}
</script>
<link rel=stylesheet type="text/css" 
      href="../../../public/itil/load/ControlCenter.css"></link>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
   return(1);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "ControlCenter"=>$self->T("ControlCenter"));
}


sub ControlCenterPublicKey
{
   my $self=shift;
   my $key="not found";
   my $res;
   if (defined($res=$self->W5ServerCall("rpcGetSSHkey"))){
      if ($res->{exitcode}==0){
         $key=$res->{key};
      }
      else{
         $key=$res->{msg};
      }
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],form=>1,body=>1);
   print ("<table border=1 width=100% style=\"table-layout:fixed\">");
   print ("<tr>");
   print ("<td>Step1:");
   print ("</td>");
   print ("</tr>");
   print ("<tr>");
   print ("<td>SSH Public Key:<br><textarea style=\"width:100%\" rows=12 wrap=soft>");
   print ($key);
   print ("</textarea></td>");
   print ("</tr>");
   print ("</table>");
   print $self->HtmlBottom(body=>1,form=>1);

   return();
}

sub ControlCenter
{
   my $self=shift;
   my $page="";
   my $id=Query->Param("id");
   return(undef) if ($id eq "");
   my $sysobj=$self->getPersistentModuleObject("itil::system");
   $sysobj->ResetFilter();
   $sysobj->SetFilter({id=>\$id});
   my ($system,$msg)=$sysobj->getOnlyFirst(qw(name));
   return(undef) if (!defined($system));

   my $lnkjob=$self->getPersistentModuleObject("itil::lnksystemjobsystem");
   $lnkjob->ResetFilter();
   $lnkjob->SetFilter({systemid=>\$id});
   my @joblist=$lnkjob->getHashList(qw(jobname jobid));
   my $buttons="";

   my $job=$self->getPersistentModuleObject("itil::systemjob");
   my @jobrest;
   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','both');
      $job->SetFilter([{owner=>\$userid},
                       {aclmode=>['write','run'],
                        acltarget=>\'base::user',
                        acltargetid=>[$userid]},
                       {aclmode=>['write','run'],
                        acltarget=>\'base::grp',
                        acltargetid=>[keys(%groups)]}]);
      @jobrest=map({$_->{id}} $job->getHashList(qw(id)));
   }
   my $selectany="disabled";
   my @wgrp=$sysobj->isWriteValid($system);
   if (grep(/^ALL$/,@wgrp) || grep(/^default$/,@wgrp)){
      $selectany="";
   }
   

   foreach my $job (@joblist){
       if (!$self->IsMemberOf("admin")){
          next if (!grep(/^$job->{jobid}$/,@jobrest));
       }
       $buttons.="<input type=button ".
                 "class=RunJob ".
                 "value=\"$job->{jobname}\" ".
                 "onclick=RunJob($id,$job->{jobid})>";
   }
   $page.=<<EOF;
<table width=100% height=100% border=0 style=\"table-layout:fixed\">
<tr height=1%>
<td align=center><hr>
<input onclick=fControlCenterSelectJob() id=ControlCenterSelectJob 
       type=button $selectany value="Select any desired job">
<input onclick=fRefreshJobList() id=RefreshJobList
       type=button value="RefreshJobList">
<input onclick=fShowKey() id=ShowKey
       type=button value="show W5Base Public Key"><hr></td>
<tr>
<td valign=top><div class=Actions>$buttons</div></td>
</tr>
<tr height=1%>
<td>All active jobs (a job can't run longer then 24h!):</td>
</tr>
<tr height=1%>
<td align=center><iframe id=ControlCenterActiveJobs style=\"width:99%;height:230px\" src="ControlCenterActiveJobs?id=$id"></iframe></td>
</tr>
</table>
<script language="JavaScript">
function RestartApp(returnVal,isbreak)
{
   parent.document.forms[0].submit();
}
function fShowKey()
{
   var e=document.getElementById("ControlCenterActiveJobs");
   e.src="ControlCenterPublicKey?id=$id";
}
function fRefreshJobList()
{
   var e=document.getElementById("ControlCenterActiveJobs");
   e.src="ControlCenterActiveJobs?id=$id";
}
function RunJob(id,jobid)
{
   showPopWin('ControlCenterRunJob?id='+id+'&jobid='+jobid,
              500,200,RestartApp);
}
function fControlCenterSelectJob()
{
   showPopWin('ControlCenterSelectJob?id=$id',
              500,200,RestartApp);
}
function setTitle()
{
   var t="ControlCenter: $system->{name}";
   window.document.getElementById("WindowTitle");
   parent.document.title=t;
   return(true);
}
function refresher()
{
   var e=document.getElementById("ControlCenterActiveJobs");
   if (!e.src.match("ControlCenterRunJob")){
      e.src=e.src;
   }
   window.setTimeout("refresher();",10000);
}
refresher();
addEvent(window, "load", setTitle);

</script>
<input type=hidden name=id value="$id">
<input type=hidden name=jobid value="">
<link rel=stylesheet type="text/css" href="../../../public/itil/load/ControlCenter.css"></link>
EOF
   return($page);
}




sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   my $page="";
   if ($p eq "ControlCenter"){
      my $idname=$self->IdField->Name();
      my $idval=$rec->{$idname};
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      $page=$self->ControlCenter();
      return($page);
   }

   return($page.$self->SUPER::getHtmlDetailPageContent($p,$rec));
}


#############################################################################






1;
