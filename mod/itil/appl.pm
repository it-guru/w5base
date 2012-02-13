package itil::appl;
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
use kernel::CIStatusTools;
use kernel::MandatorDataACL;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
        kernel::App::Web::InterviewLink kernel::CIStatusTools
        kernel::MandatorDataACL);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
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
                dataobjattr   =>'appl.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'appl.mandator'),

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
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                label         =>'Customer Business Manager E-Mail',
                searchable    =>0,
                group         =>'finance',
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'appl.servicesupport'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmleditwidth =>'150px',
                htmlwidth     =>'100px',
                label         =>'CO-Number',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::Text(
                name          =>'applid',
                htmlwidth     =>'100px',
                htmleditwidth =>'150px',
                label         =>'Application ID',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::Group(
                name          =>'responseteam',
                group         =>'finance',
                label         =>'CBM Team',
                vjoinon       =>'responseteamid'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'appl.responseteam'),


      new kernel::Field::Contact(
                name          =>'sem',
                group         =>'finance',
                label         =>'Customer Business Manager',
                vjoinon       =>'semid'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                group         =>'finance',
                label         =>'Customer Business Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'sem2email',
                group         =>'finance',
                label         =>'Deputy Customer Business Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['sem2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'semid',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::Group(
                name          =>'businessteam',
                group         =>'technical',
                label         =>'Business Team',
                vjoinon       =>'businessteamid'),

      new kernel::Field::TextDrop(
                name          =>'businessdepart',
                htmlwidth     =>'300px',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                group         =>'technical',
                label         =>'Business Department',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['businessdepartid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'businessdepartid',
                searchable    =>0,
                readonly      =>1,
                label         =>'Business Department ID',
                group         =>'technical',
                depend        =>['businessteamid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $businessteamid=$current->{businessteamid};
                   if ($businessteamid ne ""){
                      my $grp=getModuleObject($self->getParent->Config,
                                              "base::grp");
                      my $businessdepartid=
                         $grp->getParentGroupIdByType($businessteamid,"depart");
                      return($businessdepartid);
                   }
                   return(undef);
                }),

      new kernel::Field::Contact(
                name          =>'tsm',
                group         =>'technical',
                label         =>'Technical Solution Manager',
                vjoinon       =>'tsmid'),

      new kernel::Field::Contact(
                name          =>'opm',
                group         =>'opmgmt',
                label         =>'Operation Manager',
                vjoinon       =>'opmid'),

      new kernel::Field::SubList(
                name          =>'directlicenses',
                label         =>'direct linked Licenses',
                group         =>'licenses',
                allowcleanup  =>1,
                vjointo       =>'itil::lnklicappl',
                vjoinbase     =>[{liccontractcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['liccontract','quantity','comments']),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['fullname','swnature']),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Cluster services',
                group         =>'services',
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['itclustsvc']),

      new kernel::Field::Text(
                name          =>'businessteambossid',
                group         =>'technical',
                label         =>'Business Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0,
                depend        =>['businessteamid']),

      new kernel::Field::Text(
                name          =>'businessteamboss',
                group         =>'technical',
                label         =>'Business Team Boss',
                onRawValue    =>\&getTeamBoss,
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['businessteambossid']),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                group         =>'technical',
                label         =>'Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsmphone',
                group         =>'technical',
                label         =>'Technical Solution Manager Office-Phone',
                vjointo       =>'base::user',
                htmlwidth     =>'200px',
                nowrap        =>1,
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::TextDrop(
                name          =>'tsmmobile',
                group         =>'technical',
                label         =>'Technical Solution Manager Mobile-Phone',
                vjointo       =>'base::user',
                htmlwidth     =>'200px',
                htmldetail    =>0,
                nowrap        =>1,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_mobile'),

      new kernel::Field::TextDrop(
                name          =>'tsmposix',
                group         =>'technical',
                label         =>'Technical Solution Manager POSIX',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'posix'),

      new kernel::Field::Link(
                name          =>'tsmid',
                group         =>'technical',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'opmid',
                group         =>'opmgmt',
                dataobjattr   =>'appl.opm'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::costcenter',
                vjoinon       =>['conumber'=>'name'],
                dontrename    =>1,
                uploadable    =>0,
                group         =>'delmgmt',
                fields        =>[qw(delmgr   delmgr2
                                    delmgrid delmgr2id
                                    delmgrteam
                                    delmgrteamid)]),

      new kernel::Field::TextDrop(
                name          =>'customer',
                group         =>'customer',
                SoftValidate  =>1,
                label         =>'Customer',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link( 
                name          =>'customerid',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Contact(
                name          =>'sem2',
                AllowEmpty    =>1,
                group         =>'finance',
                label         =>'Deputy Customer Business Manager',
                vjoinon       =>'sem2id'),

      new kernel::Field::Link(
                name          =>'sem2id',
                dataobjattr   =>'appl.sem2'),


      new kernel::Field::Contact(
                name          =>'tsm2',
                AllowEmpty    =>1,
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager',
                vjoinon       =>'tsm2id'),

      new kernel::Field::Contact(
                name          =>'opm2',
                AllowEmpty    =>1,
                group         =>'opmgmt',
                label         =>'Deputy Operation Manager',
                vjoinon       =>'opm2id'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                group         =>'technical',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Link(
                name          =>'opm2id',
                group         =>'opmgmt',
                dataobjattr   =>'appl.opm2'),

      new kernel::Field::Select(
                name          =>'customerprio',
                group         =>'customer',
                label         =>'Customers Application Prioritiy',
                value         =>['1','2','3'],
                default       =>'2',
                htmleditwidth =>'50px',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Select(
                name          =>'criticality',
                group         =>'customer',
                label         =>'Criticality',
                allowempty    =>1,
                value         =>['CRnone','CRlow','CRmedium','CRhigh',
                                 'CRcritical'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.criticality'),

      new kernel::Field::Select(
                name          =>'avgusercount',
                group         =>'customer',
                label         =>'average user count',
                allowempty    =>1,
                value         =>['10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.avgusercount'),

      new kernel::Field::Select(
                name          =>'namedusercount',
                group         =>'customer',
                label         =>'named user count',
                allowempty    =>1,
                value         =>['10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.namedusercount'),

      new kernel::Field::Select(
                name          =>'secstate',
                group         =>'customer',
                label         =>'Security state',
                uivisible     =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(1);
                   }
                   return(0);
                },
                allowempty    =>1,
                value         =>['','vsnfd'],
                transprefix   =>'SECST.',
                dataobjattr   =>'appl.secstate'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Customer Contracts',
                group         =>'custcontracts',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['custcontract','fraction'],
                vjoinbase     =>[{custcontractcistatusid=>'<=5'}],
                vjoininhash   =>['custcontractid','custcontractcistatusid',
                                 'modules',
                                 'custcontract','custcontractname']),

      new kernel::Field::SubList(
                name          =>'interfaces',
                label         =>'Interfaces',
                group         =>'interfaces',
                forwardSearch =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplappl',
                vjoinbase     =>[{toapplcistatus=>"<=5"}],
                vjoinon       =>['id'=>'fromapplid'],
                vjoindisp     =>['toappl','contype','conproto','conmode'],
                vjoininhash   =>['toappl','contype','conproto','conmode',
                                 'toapplid']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system','systemsystemid',
                                 'reltyp','systemcistatus',
                                 'shortdesc'],
                vjoininhash   =>['system','systemsystemid','systemcistatus',
                                 'systemid','id']),

      new kernel::Field::SubList(
                name          =>'systemnames',
                label         =>'active systemnames',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system']),

      new kernel::Field::SubList(
                name          =>'systemids',
                label         =>'active systemids',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['systemsystemid']),

      new kernel::Field::Number(
                name          =>'systemcount',
                label         =>'system count',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['systems'],
                onRawValue    =>\&calculateSysCount),

      new kernel::Field::Number(
                name          =>'systemslogicalcpucount',
                label         =>'log cpucount',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>\&calculateLogicalCpuCount),

      new kernel::Field::Number(
                name          =>'systemsrelphyscpucount',
                label         =>'relative phys. cpucount',
                group         =>'systems',
                htmldetail    =>0,
                precision     =>2,
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>\&calculateRelPhysCpuCount),

      new kernel::Field::Text(
                name          =>'applgroup',
                label         =>'Application Group',
                dataobjattr   =>'appl.applgroup'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                dataobjattr   =>'appl.description'),

      new kernel::Field::Textarea(
                name          =>'currentvers',
                label         =>'Application Version',
                dataobjattr   =>'appl.currentvers'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'appl.allowifupdate'),

      new kernel::Field::Boolean(
                name          =>'sodefinition',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application switch-over behaviour defined',
                dataobjattr   =>'appl.sodefinition'),

      new kernel::Field::Boolean(
                name          =>'isnosysappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no system components',
                dataobjattr   =>'appl.is_applwithnosys'),

      new kernel::Field::Boolean(
                name          =>'isnoifaceappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no interfaces',
                dataobjattr   =>'appl.is_applwithnoiface'),

      new kernel::Field::Boolean(
                name          =>'allowdevrequest',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow developer request workflows',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'allowbusinesreq',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow business request workflows',
                container     =>'additional'),

      new kernel::Field::Select(
                name          =>'eventlang',
                group         =>'control',
                htmleditwidth =>'30%',
                value         =>['en','de','en-de','de-en'],
                label         =>'default language for eventinformations',
                dataobjattr   =>'appl.eventlang'),


      new kernel::Field::Boolean(
                name          =>'issoxappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is mangaged by rules of SOX',
                dataobjattr   =>'appl.is_soxcontroll'),

      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                label         =>'Service&Support Class',
                group         =>'monisla',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'opmode',
                group         =>'misc',
                label         =>'primary operation mode',
                transprefix   =>'opmode.',
                value         =>['',
                                 'prod',
                                 'pilot',
                                 'test',
                                 'devel',
                                 'education',
                                 'approvtest',
                                 'reference',
                                 'license',
                                 'cbreakdown'],  # see also opmode at system
                htmleditwidth =>'200px',
                dataobjattr   =>'appl.opmode'),

      new kernel::Field::Select(
                name          =>'applbasemoni',
                group         =>'monisla',
                label         =>'Application base monitoring',
                value         =>['',
                                 'BigBrother',
                                 'HP OpenView',
                                 'OpenNMS',
                                 'Nagios',
                                 'Relfex',
                                 'Tivoli 5',
                                 'Tivoli 6',
                                 'TV-CC',
                                 'SAP-Reporter',
                                 'no monitoring'],
                htmleditwidth =>'200px',
                dataobjattr   =>'appl.applbasemoni'),

      new kernel::Field::Select(
                name          =>'slacontroltool',
                group         =>'monisla',
                label         =>'SLA control tool type',
                value         =>['',
                                 'BigBrother',
                                 'OpenNMS',
                                 'Nagios',
                                 'Relfex',
                                 'Tivoli 5',
                                 'Tivoli 6',
                                 'TV-CC',
                                 'SAP-Reporter',
                                 'no SLA control'],
                htmleditwidth =>'200px',
                dataobjattr   =>'appl.slacontroltool'),

      new kernel::Field::Number(
                name          =>'slacontravail',
                group         =>'monisla',
                htmlwidth     =>'100px',
                precision     =>5,
                unit          =>'%',
                searchable    =>0,
                label         =>'SLA availibility guaranted by contract',
                dataobjattr   =>'appl.slacontravail'),

      new kernel::Field::Select(
                name          =>'slacontrbase',
                group         =>'monisla',
                label         =>'SLA availibility calculation base',
                transprefix   =>'slabase.',
                searchable    =>0,
                value         =>['',
                                 'month',
                                 'year'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.slacontrbase'),

      new kernel::Field::Text(
                name          =>'kwords',
                group         =>'misc',
                label         =>'Keywords',
                dataobjattr   =>'appl.kwords'),

      new kernel::Field::Text(
                name          =>'swdepot',
                group         =>'misc',
                label         =>'Software-Depot path',
                dataobjattr   =>'appl.swdepot'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                group         =>'misc',
                searchable    =>0, 
                label         =>'Maintenance Window',
                dataobjattr   =>'appl.maintwindow'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                searchable    =>0, 
                dataobjattr   =>'appl.comments'),

      new kernel::Field::Textarea(
                name          =>'socomments',
                group         =>'socomments',
                label         =>'comments to switch-over behaviour',
                searchable    =>0, 
                dataobjattr   =>'appl.socomments'),

      new kernel::Field::Number(
                name          =>'soslanumdrtests',
                label         =>'SLA number Desaster-Recovery tests per year',
                group         =>'sodrgroup',
                htmleditwidth =>'120',
                searchable    =>0,
                dataobjattr   =>'appl.soslanumdrtests'),

      new kernel::Field::Number(
                name          =>'sosladrduration',
                label         =>'SLA planned Desaster-Recovery duration',
                group         =>'sodrgroup',
                unit          =>'min',
                searchable    =>0,
                dataobjattr   =>'appl.sosladrduration'),

      new kernel::Field::WorkflowLink(
                name          =>'olastdrtestwf',
                AllowEmpty    =>1,
                label         =>'last Desaster-Recovery test (CHM-WorkflowID)',
                group         =>'sodrgroup',
                vjoinon       =>'olastdrtestwfid'),

      new kernel::Field::Link(
                name          =>'olastdrtestwfid',
                label         =>'last Desaster-Recovery test (CHM-WorkflowID)',
                group         =>'sodrgroup',
                searchable    =>0,
                dataobjattr   =>'appl.solastdrtestwf'),

      new kernel::Field::Date(
                name          =>'solastdrdate',
                label         =>'last Desaster-Recovery test (WorkflowEnd)',
                readonly      =>1,
                dayonly       =>1,
                group         =>'sodrgroup',
                vjointo       =>'base::workflow',
                vjoinon       =>['olastdrtestwfid'=>'id'],
                vjoindisp     =>'eventend',
                searchable    =>0),

      new kernel::Field::Date(
                name          =>'temp_solastdrdate',
                label         =>'last Desaster-Recovery test date (temp)',
                group         =>'sodrgroup',
                searchable    =>0,
                dayonly       =>1,
                dataobjattr   =>'appl.solastdrdate'),

      new kernel::Field::Number(
                name          =>'soslaclustduration',
                label         =>'SLA maximum cluster service take over duration',
                group         =>'soclustgroup',
                searchable    =>0,
                unit          =>'min',
                dataobjattr   =>'appl.soslaclustduration'),

      new kernel::Field::WorkflowLink(
                name          =>'solastclusttestwf',
                label         =>'last Cluster-Service switch test (CHM-WorkflowID)',
                AllowEmpty    =>1,
                group         =>'soclustgroup',
                vjoinon       =>'solastclusttestwfid'),

      new kernel::Field::Link(
                name          =>'solastclusttestwfid',
                htmleditwidth =>'120',
                label         =>'last Cluster-Service switch test (WorkflowID)',
                group         =>'soclustgroup',
                searchable    =>0,
                dataobjattr   =>'appl.solastclusttestwf'),

      new kernel::Field::Date(
                name          =>'solastclustswdate',
                label         =>'last Cluster-Service switch test (WorkflowEnd)',
                group         =>'soclustgroup',
                vjointo       =>'base::workflow',
                vjoinon       =>['solastclusttestwfid'=>'id'],
                vjoindisp     =>'eventend',
                dayonly       =>1,
                readonly      =>1,
                searchable    =>0),

      new kernel::Field::Date(
                name          =>'temp_solastclustswdate',
                label         =>'last Cluster-Service switch date (temp)',
                group         =>'soclustgroup',
                searchable    =>0,
                dayonly       =>1,
                dataobjattr   =>'appl.solastclustswdate'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::appl',
                group         =>'attachments'),

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
                dataobjattr   =>'appl.additional'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoininhash   =>['mdate','targetid','target', 'roles','id'],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::SubList(
                name          =>'oncallphones',
                searchable    =>0,
                htmldetail    =>0,
                uivisible     =>1,
                readonly      =>1,
                label         =>'oncall Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                vjointo       =>'base::phonenumber',
                vjoinon       =>['id'=>'refid'],
                vjoinbase     =>{'rawname'=>'phoneRB'},
                vjoindisp     =>['phonenumber','shortedcomments']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'appl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'appl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'appl.srcload'),

      new kernel::Field::SubList(
                name          =>'accountnumbers',
                label         =>'Account numbers',
                group         =>'accountnumbers',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkaccountingno',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['name','cdate','comments']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'appl.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'appl.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'appl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'appl.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'appl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'appl.realeditor'),

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

      new kernel::Field::Email(
                name          =>'wfdataeventnotifytargets',
                label         =>'WF:event notification customer info targets',
                htmldetail    =>0,
                searchable    =>0,
                uploadable    =>0,
                group         =>'workflowbasedata',
                onRawValue    =>\&getWfEventNotifyTargets),
 

      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'appl.lastqcheck'),
      new kernel::Field::QualityResponseArea()
   );
   $self->{history}=[qw(insert modify delete)];
   $self->{workflowlink}={ workflowkey=>[id=>'affectedapplicationid']
                         };
   $self->{use_distinct}=1;
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->setDefaultView(qw(name mandator cistatus mdate));
   $self->setWorktable("appl");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub InterviewPartners
{
   my $self=shift;
   my $rec=shift;


   return(''=>$self->T("Databoss"),
          'INTERVSystemTechContact'=>'SystemTechContact',
          'INTERVInfraClimaContact'=>'InfraClimaContact',
          'INTERVInfraPowerContact'=>'InfraPowerContact',
          'INTERVInfraIPNetContact'=>'InfraIPNetContact',
          'INTERVInfrastrucContact'=>'InfrastrucContact') if (!defined($rec));
   return(''=>[$rec->{'databossid'}]) if (exists($rec->{'databossid'}));
   return(''=>[]);
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

sub calculateLogicalCpuCount
{
   my $self=shift;
   my $current=shift;
   my $applid=$current->{id};

   my $l=getModuleObject($self->getParent->Config(),"itil::lnkapplsystem");
   $l->SetFilter({applid=>\$applid,systemcistatusid=>[qw(3 4 5)]});

   my $cpucount;
   foreach my $lrec ($l->getHashList(qw(logicalcpucount))){
      $cpucount+=$lrec->{logicalcpucount};
   }
   return($cpucount);
}

sub calculateRelPhysCpuCount
{
   my $self=shift;
   my $current=shift;
   my $applid=$current->{id};

   my $l=getModuleObject($self->getParent->Config(),"itil::lnkapplsystem");
   $l->SetFilter({applid=>\$applid,systemcistatusid=>[qw(3 4 5)]});

   my $cpucount;
   foreach my $lrec ($l->getHashList(qw(relphysicalcpucount))){
      $cpucount+=$lrec->{relphysicalcpucount};
   }
   return($cpucount);
}

sub calculateSysCount
{
   my $self=shift;
   my $current=shift;
   my $sysfld=$self->getParent->getField("systems");
   my $s=$sysfld->RawValue($current);
   return(0) if (!ref($s) eq "ARRAY");
   return($#{$s}+1);
}



sub getWfEventNotifyTargets     # calculates the target email addresses
{                               # for an customer information in
   my $self=shift;              # itil::workflow::eventnotify
   my $current=shift;
   my $emailto={};

   my $applid=$current->{id};
   my $ia=getModuleObject($self->getParent->Config,"base::infoabo");
   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter({id=>\$applid});


   my @byfunc;
   my @byorg;
   my @team;
   my %allcustgrp;
   foreach my $rec ($appl->getHashList(qw(semid sem2id tsmid tsm2id delmgrid
                                          opmid 
                                          responseteamid customerid 
                                          businessteamid))){
      foreach my $v (qw(semid sem2id tsmid tsm2id delmgrid opmid)){
         my $fo=$appl->getField($v);
         my $userid=$appl->getField($v)->RawValue($rec);
         push(@byfunc,$userid) if ($userid ne "" && $userid>0);
      }
      foreach my $v (qw(responseteamid businessteamid)){
         my $grpid=$rec->{$v};
         push(@team,$grpid) if ($grpid>0);
      }
      if ($rec->{customerid}!=0){
         $self->getParent->LoadGroups(\%allcustgrp,"up",
                                      $rec->{customerid});
         
      }
   }
   if (keys(%allcustgrp)){
      $ia->LoadTargets($emailto,'base::grp',\'eventnotify',
                                [keys(%allcustgrp)]);
   }
   $ia->LoadTargets($emailto,'*::appl *::custappl',\'eventnotify',
                             $applid);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'eventnotify',
                             '100000002',\@byfunc,default=>1);

   my $grp=getModuleObject($self->getParent->Config,"base::grp");
   for(my $level=0;$level<=100;$level++){
      my @nextlevel=();
      $grp->ResetFilter();
      $grp->SetFilter({grpid=>\@team});
      foreach my $rec ($grp->getHashList(qw(users parentid))){ 
         push(@nextlevel,$rec->{parentid}) if ($rec->{parentid}>0);
         if (ref($rec->{users}) eq "ARRAY"){
            foreach my $user (@{$rec->{users}}){
               if (ref($user->{roles}) eq "ARRAY" &&
                   (grep(/^RBoss$/,@{$user->{roles}}) ||
                    grep(/^RBoss2$/,@{$user->{roles}}))){
                  push(@byorg,$user->{userid});
               }
            }
         }
  #       print STDERR Dumper($rec);
      }
      if ($#nextlevel!=-1){
         @team=@nextlevel;
      }
      else{
         last;
      }
   }
  # print STDERR "byorg=".Dumper(\@byorg);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'eventnotify',
                             '100000001',\@byorg,default=>1);



   return([sort(keys(%$emailto))]);
}


sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneRB phoneMVD phoneMISC phoneDEV);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);

}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}

#sub getRecordWatermarkUrl
#{
#   my $self=shift;
#   my $rec=shift;
#   if ($rec->{secstate} eq "vsnfd"){
#      my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#      return("../../../public/itil/load/HtmlDetail.watermark.vsnfd.jpg?".
#             $cgi->query_string());
#   }
#   return(undef);
#}




sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj='$selfasparent' ".
            "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (
      #!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RCFManager RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>\$userid},
                 {semid=>\$userid},       {sem2id=>\$userid},
                 {tsmid=>\$userid},       {tsm2id=>\$userid},
                 {opmid=>\$userid},       {opm2id=>\$userid},
                 {businessteamid=>\@grpids},
                 {responseteamid=>\@grpids},
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

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appl");
}
         

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   
   if (length($name)<3 || haveSpecialChar($name) ||
       ($name=~m/^\d+$/)){   # only numbers as application name is not ok!
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid application name '%s' specified"),$name));
      return(0);
   }
   if (exists($newrec->{name}) && $newrec->{name} ne $name){
      $newrec->{name}=$name;
   }
   if ((my $swdepot=effVal($oldrec,$newrec,"swdepot")) ne ""){
      if (!($swdepot=~m#^(https|http)://[a-z0-9A-Z_/.:]/[a-z0-9A-Z_/.]*$#) &&
          !($swdepot=~m#^[a-z0-9A-Z_/.]+:/[a-z0-9A-Z_/.]*$#)){
         $self->LastMsg(ERROR,"invalid swdepot path spec");
         return(0);
      }
   }

   if (defined($newrec->{slacontravail})){
      if ($newrec->{slacontravail}>100 || $newrec->{slacontravail}<0){
         my $fo=$self->getField("slacontravail");
         my $msg=sprintf($self->T("value of '%s' is not allowed"),$fo->Label());
         $self->LastMsg(ERROR,$msg);
         return(0);
      }
   }
   if (exists($newrec->{conumber})){
      my $conumber=trim(effVal($oldrec,$newrec,"conumber"));
      if ($conumber ne ""){
         $conumber=~s/^0+//g;
         if (!($conumber=~m/^\d{5,13}$/)){
            my $fo=$self->getField("conumber");
            my $msg=sprintf($self->T("value of '%s' is not correct ".
                                     "numeric"),$fo->Label());
            $self->LastMsg(ERROR,$msg);
            return(0);
         }
         $newrec->{conumber}=$conumber;
      }
   }
   foreach my $v (qw(avgusercount namedusercount)){
      $newrec->{$v}=undef if (exists($newrec->{$v}) && $newrec->{$v} eq "");
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   if (defined($newrec->{applid})){
      $newrec->{applid}=trim($newrec->{applid});
   }
   if (effVal($oldrec,$newrec,"applid")=~m/^\s*$/){
      $newrec->{applid}=undef;
   }
   ########################################################################
   if (!defined($oldrec) && !exists($newrec->{eventlang})){
      $newrec->{eventlang}=$self->Lang(); 
   }

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   $self->NotifyAddOrRemoveObject($oldrec,$newrec,"name",
                                  "STEVapplchanged",100000003);
   return($bak);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my @all=qw(accountnumbers history default applapplgroup applgroup
              attachments contacts control custcontracts customer delmgmt
              finance interfaces licenses monisla qc
              misc opmgmt phonenumbers services
              soclustgroup socomments sodrgroup source swinstances systems
              technical workflowbasedata header inmchm interview efforts);
   if (!$rec->{sodefinition}){
      @all=grep(!/^(socomments|soclustgroup|sodrgroup)$/,@all);
   }

   return(@all);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default interfaces finance opmgmt technical contacts misc
                       systems attachments accountnumbers interview
                       customer control phonenumbers monisla
                       sodrgroup soclustgroup socomments);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if ($rec->{databossid}==$userid){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
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
            if (grep(/^write$/,@roles)){
               return($self->expandByDataACL($rec->{mandatorid},@databossedit));
            }
         }
      }
      if ($rec->{mandatorid}!=0 && 
         $self->IsMemberOf($rec->{mandatorid},"RCFManager","down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if ($rec->{businessteamid}!=0 && 
         $self->IsMemberOf($rec->{businessteamid},"RCFManager","down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if ($rec->{responseteamid}!=0 && 
         $self->IsMemberOf($rec->{responseteamid},"RCFManager","down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
   }
   return($self->expandByDataACL($rec->{mandatorid}));
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $refobj=getModuleObject($self->Config,"itil::lnkapplcustcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'appl'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'fromapplid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   $self->NotifyAddOrRemoveObject($oldrec,undef,"name",
                                  "STEVapplchanged",100000003);
   return($bak);
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $refobj->SetFilter({'toapplid'=>\$id});
      $lock++ if ($refobj->CountRecords()>0);
   }
   if ($lock>0 ||
       $#{$rec->{systems}}!=-1 ||
       $#{$rec->{services}}!=-1 ||
       $#{$rec->{swinstances}}!=-1 ||
       $#{$rec->{custcontracts}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no system, ".
          "software instance and contract relations");
      return(0);
   }

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default finance technical opmgmt delmgmt 
             customer custcontracts 
             contacts phonenumbers 
             interfaces systems swinstances services monisla
             misc attachments control 
             sodrgroup soclustgroup socomments accountnumbers licenses source));
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}


sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   my @l=$self->SUPER::getHtmlDetailPages($p,$rec);
   if (defined($rec)){
      push(@l,"OPInfo"=>$self->T("OperatorInfo"));
   }
   return(@l);
}


sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;

   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "OPInfo");

   if ($p eq "OPInfo"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page.="<iframe class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"OPInfo?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"OPInfo");
}


sub OPInfo
{
   my $self=shift;
   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"OP Info comming sone!",
                           js=>['toolbox.js'],
                           style=>['default.css',
                                'work.css',
                                'Output.HtmlDetail.css',
                                'kernel.App.Web.css']);

   print ("This is IT!");


}

sub HtmlPublicDetail   # for display record in QuickFinder or with no access
{
   my $self=shift;
   my $rec=shift;
   my $header=shift;   # create a header with fullname or name

   my $htmlresult="";
   if ($header){
      $htmlresult.="<table style='margin:5px'>\n";
      $htmlresult.="<tr><td colspan=2 align=center><h2>";
      $htmlresult.=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      "name","formated");
      $htmlresult.="</h2></td></tr>";
   }
   else{
      $htmlresult.="<table>\n";
   }
   my @l=qw(sem sem2 delmgr delmgr2 tsm tsm2 databoss businessteam);
   foreach my $v (@l){
      if ($rec->{$v} ne ""){
         my $name=$self->getField($v)->Label();
         my $data=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      $v,"formated");
         $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                      "<td valign=top>$data</td></tr>\n";
      }
   }

   if (my $pn=$self->getField("phonenumbers")){
      $htmlresult.=$pn->FormatForHtmlPublicDetail($rec,["phoneRB"]);
   }
   $htmlresult.="</table>\n";
   if ($rec->{description} ne ""){
      my $desclabel=$self->getField("description")->Label();
      my $desc=$rec->{description};
      $desc=~s/\n/<br>\n/g;

      $htmlresult.="<table><tr><td>".
                   "<div style=\"height:60px;overflow:auto;color:gray\">".
                   "\n<font color=black>$desclabel:</font><div>\n$desc".
                   "</div></div>\n</td></tr></table>";
   }
   return($htmlresult);

}









1;
