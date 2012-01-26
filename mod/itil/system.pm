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
use kernel::App::Web::InterviewLink;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
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

      new kernel::Field::Link(
                name          =>'signedfiletransfername',
                label         =>'sigend file transfer name',
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

      new kernel::Field::Databoss(),

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
                vjoindisp     =>['appl','applcistatus','reltyp','fraction'],
                vjoininhash   =>['appl','applcistatusid','mandatorid',
                                 'applid']),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Text(
                name          =>'tsmemails',
                label         =>'Technical Solution Manager E-Mails',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['tsmemail']),


#      new kernel::Field::Text(
#                name          =>'applicationnamesline',
#                label         =>'Applicationnames line',
#                group         =>'applications',
#                htmldetail    =>0,
#                searchable    =>0,
#                vjointo       =>'itil::lnkapplsystem',
#                vjoinbase     =>[{applcistatusid=>"<=4"}],
#                vjoinon       =>['id'=>'systemid'],
#                vjoindisp     =>['appl']),

      new kernel::Field::Text(
                name          =>'customer',
                label         =>'all Customers',
                group         =>'customer',
                depend        =>['applications'],
                searchable    =>0,
                htmldetail    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fo=$self->getParent->getField("applications");
                   my $f=$fo->RawValue($current);
                   my @aid=();
                   my %customer;
                   if (ref($f) eq "ARRAY"){
                      foreach my $a (@{$f}){
                         push(@aid,$a->{applid});
                      }
                   }
                   if ($#aid!=-1){
                      my $appl=getModuleObject($self->getParent->Config,
                                               "itil::appl");
                      $appl->SetFilter({id=>\@aid,cistatusid=>"<5"});
                      foreach my $arec ($appl->getHashList(qw(customer))){
                         if ($arec->{customer} ne ""){
                            $customer{$arec->{customer}}++;
                         }
                      } 
                      my $cont=getModuleObject($self->getParent->Config,
                                               "itil::custcontract");
                      $cont->SetFilter({applicationids=>\@aid,
                                        cistatusid=>"<5"});
                      foreach my $arec ($cont->getHashList(qw(customer))){
                         if ($arec->{customer} ne ""){
                            $customer{$arec->{customer}}++;
                         }
                      } 
                   }
                   return([keys(%customer)]);
                }),

      new kernel::Field::SubList(
                name          =>'applcustomers',
                label         =>'Application Customers',
                htmlwidth     =>'200px',
                group         =>'customer',
                searchable    =>1,
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['applcustomer','appl']),

      new kernel::Field::Text(
                name          =>'custcontract',
                label         =>'Customer Contract',
                group         =>'customer',
                depend        =>['applications'],
                searchable    =>0,
                htmldetail    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fo=$self->getParent->getField("applications");
                   my $f=$fo->RawValue($current);
                   my @aid=();
                   my %customer;
                   if (ref($f) eq "ARRAY"){
                      foreach my $a (@{$f}){
                         push(@aid,$a->{applid});
                      }
                   }
                   if ($#aid!=-1){
                      my $cont=getModuleObject($self->getParent->Config,
                                               "itil::custcontract");
                      $cont->SetFilter({applicationids=>\@aid,
                                        cistatusid=>"<5"});
                      foreach my $arec ($cont->getHashList(qw(name))){
                         if ($arec->{name} ne ""){
                            $customer{$arec->{name}}++;
                         }
                      } 
                   }
                   return([keys(%customer)]);
                }),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                subeditmsk    =>'subedit.system',
                allowcleanup  =>1,
                forwardSearch =>1,
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['software','version','quantity','comments'],
                vjoininhash   =>['softwarecistatusid','liccontractcistatusid',
                                 'liccontractid',
                                 'software','version','quantity','softwareid']),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['fullname','swnature']),

      new kernel::Field::Text(
                name          =>'shortdesc',
                group         =>'misc',
                label         =>'Short Description',
                dataobjattr   =>'system.shortdesc'),

      new kernel::Field::Contact(
                name          =>'adm',
                group         =>'admin',
                label         =>'Administrator',
                vjoinon       =>['admid'=>'userid']),

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
                vjoineditbase =>{'cistatusid'=>"<=5"},
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

      new kernel::Field::Contact(
                name          =>'adm2',
                AllowEmpty    =>1,
                group         =>'admin',
                label         =>'Deputy Administrator',
                vjoinon       =>['adm2id'=>'userid']),

      new kernel::Field::Link(
                name          =>'adm2id',
                dataobjattr   =>'system.adm2'),

      new kernel::Field::TextDrop(
                name          =>'adm2email',
                group         =>'admin',
                label         =>'Deputy Administrator E-Mail',
                searchable    =>0,
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
                searchable    =>0,
                readonly      =>1,
                uivisible     =>0,
                depend        =>['adminteamid']),

      new kernel::Field::Text(
                name          =>'adminteamboss',
                group         =>'admin',
                label         =>'Admin Team Boss',
                onRawValue    =>\&getTeamBoss,
                searchable    =>0,
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

      new kernel::Field::Interface(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Select(
                name          =>'osclass',
                group         =>'logsys',
                label         =>'OS-Class',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'osclass'),

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

      new kernel::Field::Number(
                name          =>'cpucount',
                group         =>'logsys',
                label         =>'CPU-Count',
                dataobjattr   =>'system.cpucount'),

      new kernel::Field::Number(
                name          =>'relphysicalcpucount',
                searchable    =>0,
                precision     =>2,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['cpucount','assetid','hwcpucount'],
                group         =>'logsys',
                label         =>'relative phys. CPU-Count',
                onRawValue    =>\&calcPhyCpuCount),

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

      new kernel::Field::JoinUniqMerge(
                name          =>'issox',
                label         =>'mangaged by rules of SOX',
                group         =>'sec',
                searchable    =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>'systemissox'),

      new kernel::Field::Select(
                name          =>'nosoxinherit',
                group         =>'sec',
                label         =>'SOX state',
                searchable    =>0,
                transprefix   =>'ApplInherit.',
                htmleditwidth =>'180px',
                value         =>['0','1'],
                translation   =>'itil::appl',
                dataobjattr   =>'system.no_sox_inherit'),


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
                searchable    =>0,
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
                searchable    =>0,
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
                label         =>'phys. CPU-Count',
                dataobjattr   =>'asset.cpucount'),

      new kernel::Field::Number(
                name          =>'hwcorecount',
                readonly      =>1,
                group         =>'physys',
                label         =>'phys. Core-Count',
                dataobjattr   =>'asset.corecount'),

      new kernel::Field::Number(
                name          =>'hwmemory',
                readonly      =>1,
                group         =>'physys',
                label         =>'phys. Memory',
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

      new kernel::Field::Boolean(
                name          =>'isprod',
                group         =>'opmode',
                htmlhalfwidth =>1,
                label         =>'Productionsystem',
                dataobjattr   =>'system.is_prod'),

      new kernel::Field::Boolean(
                name          =>'istest',
                group         =>'opmode',
                htmlhalfwidth =>1,
                label         =>'Testsystem',
                dataobjattr   =>'system.is_test'),

      new kernel::Field::Boolean(
                name          =>'isdevel',
                group         =>'opmode',
                htmlhalfwidth =>1,
                label         =>'Developmentsystem',
                dataobjattr   =>'system.is_devel'),

      new kernel::Field::Boolean(
                name          =>'iseducation',
                group         =>'opmode',
                htmlhalfwidth =>1,
                label         =>'Educationsystem',
                dataobjattr   =>'system.is_education'),

      new kernel::Field::Boolean(
                name          =>'isapprovtest',
                group         =>'opmode',
                htmlhalfwidth =>1,
                label         =>'Approval Testsystem',
                dataobjattr   =>'system.is_approvtest'),

      new kernel::Field::Boolean(
                name          =>'isreference',
                group         =>'opmode',
                htmlhalfwidth =>1,
                label         =>'Referencesystem',
                dataobjattr   =>'system.is_reference'),

      new kernel::Field::Boolean(
                name          =>'isapplserver',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Server/Applicationserver',
                dataobjattr   =>'system.is_applserver'),

      new kernel::Field::Boolean(
                name          =>'isinfrastruct',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Infrastructursystem',
                dataobjattr   =>'system.is_infrastruct'),

      new kernel::Field::Boolean(
                name          =>'isworkstation',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Workstation',
                dataobjattr   =>'system.is_workstation'),

      new kernel::Field::Boolean(
                name          =>'isprinter',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Printer/Printserver',
                dataobjattr   =>'system.is_printer'),

      new kernel::Field::Boolean(
                name          =>'isbackupsrv',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Backupserver',
                dataobjattr   =>'system.is_backupsrv'),

      new kernel::Field::Boolean(
                name          =>'isdatabasesrv',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Databaseserver',
                dataobjattr   =>'system.is_databasesrv'),

      new kernel::Field::Boolean(
                name          =>'iswebserver',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'WEB-Server',
                dataobjattr   =>'system.is_webserver'),

      new kernel::Field::Boolean(
                name          =>'ismailserver',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Mail/Mailrelay-Server',
                dataobjattr   =>'system.is_mailserver'),

      new kernel::Field::Boolean(
                name          =>'isrouter',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Router/Networkrouter',
                dataobjattr   =>'system.is_router'),

      new kernel::Field::Boolean(
                name          =>'isnetswitch',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Switch/Networkswitch',
                dataobjattr   =>'system.is_netswitch'),

      new kernel::Field::Boolean(
                name          =>'isterminalsrv',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Terminalserver',
                dataobjattr   =>'system.is_terminalsrv'),

      new kernel::Field::Boolean(
                name          =>'isnas',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Network Attached Storage NAS',
                dataobjattr   =>'system.is_nas'),

      new kernel::Field::Boolean(
                name          =>'isloadbalacer',
                group         =>'systemclass',
                htmlhalfwidth =>1,
                label         =>'Loadbalancer',
                dataobjattr   =>'system.is_loadbalacer'),

#      new kernel::Field::Boolean(           # vorerst nicht, da die Information
#                name          =>'ishousing',# nicht "absolut" wäre!
#                group         =>'systemclass',
#                label         =>'Housing',
#                dataobjattr   =>'system.is_housing'),

      new kernel::Field::Boolean(
                name          =>'isclusternode',
                selectfix     =>1,
                group         =>'systemclass',
                label         =>'ClusterNode',
                dataobjattr   =>'system.is_clusternode'),

      new kernel::Field::TextDrop(
                name          =>'itclust',
                group         =>'cluster',
                label         =>'Cluster',
                vjointo       =>'itil::itclust',
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['itclustid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'itclustid',
                dataobjattr   =>'system.clusterid'),

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
                htmldetail    =>0,
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

      new kernel::Field::SubList(
                name          =>'applicationteams',
                label         =>'Application business teams',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['businessteam']),

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
                label         =>'JobServer Proxy Command',
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

      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
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

sub calcPhyCpuCount   #calculates the relative physical cpucount
{
   my $self=shift;
   my $current=shift;

   my $assetid=$current->{assetid};

   my $sys=getModuleObject($self->getParent->Config,"itil::system");
   $sys->SetFilter({assetid=>\$assetid,cistatusid=>[qw(3 4 5)]});
   my $syscount;
   my $syscpucount;
   foreach my $subsysrec ($sys->getHashList(qw(cpucount))){
      $syscount++;
      $syscpucount+=$subsysrec->{cpucount};
   }
   if ($syscount==1){
      return($current->{hwcpucount});
   }
   else{
      my $lcpucount=$current->{cpucount};
      if ($current->{hwcpucount}>0 && $syscpucount>0 && $lcpucount>0){
         return($current->{hwcpucount}/$syscpucount*$lcpucount); 
      }
      return(undef);
   }  
   return(undef);
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
               [orgRoles(),qw(RCFManager RCFManager RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {admid=>$userid},       {adm2id=>$userid},
                 {adminteamid=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
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
   if (length($name)<3 || haveSpecialChar($name) ||
       ($name=~m/^\d+$/)){  # only a number as system name ist not ok
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
   if (exists($newrec->{isclusternode})){
      if (effVal($oldrec,$newrec,"isclusternode")!=1){
         $newrec->{itclustid}=undef;
      }
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
      if (!$self->IsMemberOf("admin") &&
          (defined($newrec->{databossid}) &&
           $newrec->{databossid}!=$userid &&
           $newrec->{databossid}!=$oldrec->{databossid})){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   if ($oldrec->{cistatusid}!=6 &&
       $newrec->{cistatusid}==6){
      if (defined($oldrec->{ipaddresses}) && 
          ref($oldrec->{ipaddresses}) eq "ARRAY"){
         foreach my $iprec (@{$oldrec->{ipaddresses}}){
            if ($iprec->{cistatusid}!=6){
               $self->LastMsg(ERROR,
                          "there are still linked active ipaddresses on this system");
               return(undef);
            }
         }
      }
   }


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
   my @all=qw(header default swinstances 
              software admin logsys contacts misc opmode 
              physys ipaddresses phonenumbers sec applications
              location source customer history
              attachments control systemclass interview);
   if (defined($rec) && $rec->{'isclusternode'}){
      push(@all,"cluster");
   }
   if ($self->IsMemberOf("admin")){
      push(@all,"qc");
   }
   return(@all);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default software admin logsys contacts misc opmode 
                       physys ipaddresses phonenumbers sec cluster
                       attachments control systemclass interview);
   if (!defined($rec)){
      return("default","physys","admin","misc","cluster",
             "opmode","control","systemclass","sec");
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
   return(
          qw(header default admin phonenumbers logsys location 
             physys systemclass cluster
             opmode sec applications customer software 
             swinstances ipaddresses
             contacts misc attachments control source));
}


#############################################################################






1;
