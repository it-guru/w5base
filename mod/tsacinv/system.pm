package tsacinv::system;
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
use tsacinv::lib::tools;
use tsacinv::costcenter;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                label         =>'Name',
                uivisible     =>0,
                dataobjattr   =>"concat(concat(concat(amportfolio.name,' ('".
                                "),amportfolio.assettag),')')"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'amportfolio.name'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemId',
                size          =>'13',
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'lower(amcomputer.status)'),

      new kernel::Field::Text(
                name          =>'tenant',
                label         =>'Tenant',
                group         =>'source',
                dataobjattr   =>'amtenant.code'),

      new kernel::Field::Interface(
                name          =>'tenantid',
                label         =>'Tenant ID',
                group         =>'source',
                dataobjattr   =>'amtenant.ltenantid'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostcenterid'=>'id'],
                dataobjattr   =>'amcostcenter.trimmedtitle'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>"location",
                fields        =>[qw(fullname location)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'none',
              #  weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"location",
                fields        =>[qw(room place)]),

      new kernel::Field::Text(
                name          =>'customerlink',
                label         =>'Customer (link)',
                htmldetail    =>0,
                dataobjattr   =>'amcostcenter.customerlink'),

      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'amcostcenter.lcostid'),

      new kernel::Field::Text(
                name          =>'cocustomeroffice',
                searchable    =>0,
                label         =>'Customer Office',
                size          =>'20',
                dataobjattr   =>'amcostcenter.customeroffice'),

      new kernel::Field::Text(
                name          =>'bc',
                label         =>'Business Center',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP costcenter hierarchy',
                group         =>'saphier',
                htmldetail    =>0,
                ignorecase    =>1,
                dataobjattr   =>tsacinv::costcenter::getSAPhierSQL()),

      new kernel::Field::TextDrop(
                name          =>'supervisor',
                label         =>'Supervisor',
                searchable    =>0,
                vjointo       =>'tsacinv::user',
                vjoinon       =>['supervid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'supervid',
                label         =>'Supervisor ID',
                dataobjattr   =>'amportfolio.lsupervid'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisor',
                label         =>'Assignment Group Supervisor',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisor'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisoremail',
                label         =>'Assignment Group Supervisor E-Mail',
                htmldetail    =>0,
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisoremail'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'amportfolio.lassignmentid'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AC-Incident-AssignmentID',
                dataobjattr   =>'amportfolio.lincidentagid'),

      new kernel::Field::Text(
                name          =>'controlcenter',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter'=>'name'],
                label         =>'System ControlCenter',
                dataobjattr   =>'amportfolio.controlcenter'),

      new kernel::Field::Text(
                name          =>'controlcenter2',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter2'=>'name'],
                label         =>'Application ControlCenter',
                dataobjattr   =>'amportfolio.controlcenter2'),

      new kernel::Field::Text(
                name          =>'usage',
                group         =>'form',
                label         =>'Usage',
                dataobjattr   =>'amportfolio.usage'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Type',
                group         =>'form',
                dataobjattr   =>'amcomputer.computertype'),

      new kernel::Field::Text(
                name          =>'model',
                label         =>'Model',
                group         =>'form',
                dataobjattr   =>'ammodel.name'),

      new kernel::Field::Text(
                name          =>'nature',
                label         =>'Nature',
                group         =>'form',
                dataobjattr   =>'amnature.name'),

      new kernel::Field::Boolean(
                name          =>'soxrelevant',
                label         =>'SOX relevant',
                group         =>'form',
                dataobjattr   =>"decode(amportfolio.soxrelevant,'YES',1,0)"),

      new kernel::Field::Text(
                name          =>'securitymodel',
                label         =>'security flag',
                searchable    =>sub{
                   my $self=shift; 
                   my $current=shift; 
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                group         =>'form',
                dataobjattr   =>"decode(amcomputer.addsysname,".
                                "'+VS+','VS',".
                                "'+VS++','VS',".
                                "'+GS+','GS',".
                                "'+GS++','GS'".
                                ",'NONE')"),

      new kernel::Field::Text(
                name          =>'altname',
                label         =>'second name',
                group         =>'form',
                dataobjattr   =>"amcomputer.addsysname"),

      new kernel::Field::Text(
                name          =>'securityset',
                label         =>'security set',
                ignorecase    =>1,
                group         =>'form',
                dataobjattr   =>"amportfolio.securityset"),

      new kernel::Field::Float(
                name          =>'systemcpucount',
                label         =>'System CPU count',
                unit          =>'CPU',
                precision     =>0,
                dataobjattr   =>'amcomputer.itotalnumberofcores'),

      new kernel::Field::Float(  # temp. da es keine phys. cpu anzahl beim
                name          =>'systeminvoicecpucount',  # logischen system
                label         =>'invoice relevant cpu count', # geben kann
                unit          =>'CPU',                   # grund: TMO 
                htmldetail    =>0,                       # abrechnungsprozess
                precision     =>1,
                dataobjattr   =>'amcomputer.fcpunumber'),

      new kernel::Field::Float(
                name          =>'systemcpuspeed',
                label         =>'System CPU speed',
                unit          =>'MHz',
                precision     =>0,
                dataobjattr   =>'amcomputer.lcpuspeedmhz'),

      new kernel::Field::Text(
                name          =>'systemcputype',
                label         =>'System CPU type',
                unit          =>'MHz',
                dataobjattr   =>'amcomputer.cputype'),

      new kernel::Field::Text(
                name          =>'systemtpmc',
                label         =>'System tpmC',
                unit          =>'tpmC',
                dataobjattr   =>'amcomputer.lProcCalcSpeed'),

      new kernel::Field::Float(
                name          =>'systemmemory',
                label         =>'System Memory',
                unit          =>'MB',
                precision     =>0,
                dataobjattr   =>'amcomputer.lmemorysizemb'),

      new kernel::Field::Text(
                name          =>'virtualization',
                htmldetail    =>0,
                label         =>'Virualization Status',
                dataobjattr   =>'amcomputer.virtualization'),

      new kernel::Field::Text(
                name          =>'systemos',
                label         =>'System OS',
                dataobjattr   =>'trim(amcomputer.operatingsystem)'),

      new kernel::Field::Text(
                name          =>'systemospatchlevel',
                label         =>'System OS patchlevel',
                dataobjattr   =>"amcomputer.osservicelevel"),

      new kernel::Field::Text(
                name          =>'systemos',
                label         =>'System OS',
                dataobjattr   =>'trim(amcomputer.operatingsystem)'),

      new kernel::Field::Float(
                name          =>'partofasset',
                label         =>'System Part of Asset',
                unit          =>'%',
                depend        =>['lassetid','status'],
                prepRawValue  =>\&SystemPartOfCorrection,
                dataobjattr   =>'amcomputer.psystempartofasset'),

      new kernel::Field::Float(
                name          =>'nativepartofasset',
                label      =>'System Part of Asset (native from AssetManager)',
                htmldetail    =>0,
                unit          =>'%',
                dataobjattr   =>'amcomputer.psystempartofasset*100'),

#      new kernel::Field::Text(
#                name          =>'costallocactive',
#                label         =>'Cost allocation active',
#                dataobjattr   =>'amcomputer.bcostallocactive'),

      new kernel::Field::Text(
                name          =>'systemola',
                label         =>'System OLA',
                dataobjattr   =>'amcomputer.olaclasssystem'),

      new kernel::Field::Select(
                name          =>'systemolaclass',
                label         =>'System OLA Service Class',
                value         =>['0','4','10','20','25','30','38'], 
                transprefix   =>'SYSCLASS.',
                dataobjattr   =>'amcomputer.seappcom'),

      new kernel::Field::Text(
                name          =>'rawsystemolaclass',
                label         =>'raw System OLA Service Class',
                dataobjattr   =>"decode(amcomputer.seappcom,".
                                "'0','UNDEFINED',".
                                "'4','UNIVERSAL',".
                                "'10','CLASSIC',".
                                "'20','STANDARDIZED',".
                                "'25','STANDARDIZED SLICE',".
                                "'30','APPCOM',".
                                "'33','DCS',".
                                "amcomputer.seappcom||'???')"),

      new kernel::Field::Text(
                name          =>'priority',
                label         =>'Priority of system',
                dataobjattr   =>'amportfolio.priority'),

      new kernel::Field::Date(
                name          =>'installdate',
                label         =>'installation date',
                dataobjattr   =>'decode(amportfolio.dtinvent,NULL,'.
                              'assetportfolio.dtinvent,amportfolio.dtinvent)'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'tsacinv::asset',
                weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetdata",
                fields        =>[qw(assetid serialno inventoryno modelname 
                                    powerinput cpucount cputype cpuspeed 
                                    corecount
                                    systemsonasset maitcond maintlevel)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetfinanz",
                fields        =>[qw( mdepr mmaint)]),

      new kernel::Field::Date(
                name          =>'compdeprstart',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'compdeprstart',
                htmldetail    =>0,
                group         =>"assetfinanz",
                label         =>'Asset complete deprecation start'),

      new kernel::Field::Date(
                name          =>'compdeprend',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'compdeprend',
                htmldetail    =>0,
                group         =>"assetfinanz",
                label         =>'Asset complete deprecation end'),

      new kernel::Field::Link(
                name          =>'partofassetdec',
                label         =>'System Part of Asset',
                dataobjattr   =>'amcomputer.psystempartofasset'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'amcomputer.lcomputerid'),

      new kernel::Field::Link(
                name          =>'lassetid',
                label         =>'AC-AssetID',
                dataobjattr   =>'amportfolio.lparentid'),

      new kernel::Field::Interface(
                name          =>'lclusterid',
                label         =>'AC-lClusterID',
                dataobjattr   =>'amcomputer.lparentid'),

      new kernel::Field::Link(
                name          =>'lportfolioitemid',
                label         =>'PortfolioID',
                dataobjattr   =>'amportfolio.lportfolioitemid'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'AC-LocationID',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'locationid'),

      new kernel::Field::Link(
                name          =>'altbc',
                label         =>'Alternate BC',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::SubList(
                name          =>'orderedservices',
                label         =>'ordered Services',
                group         =>'orderedservices',
                vjointo       =>'tsacinv::service',
                vjoinbase     =>[{'isdelivered'=>\'0'}],
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(name type ammount unit)],
                vjoininhash   =>['name','type','ammount']),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'delivered Services',
                group         =>'services',
                vjointo       =>'tsacinv::service',
                vjoinbase     =>[{'isdelivered'=>\'1'}],
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(name type ammount unit)],
                vjoininhash   =>['name','type','ammount']),


      new kernel::Field::Boolean(
                name          =>'tbsm_ordered',
                group         =>'orderedservices',
                htmldetail    =>0,
                label         =>'is TBSM ordered',
                dataobjattr   =>"decode(tbsm.ordered,'XMBSM',1,0)"),


      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                searchable    =>0,
                group         =>'ipaddresses',
                vjointo       =>'tsacinv::ipaddress',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(fullname description type)],
                vjoininhash   =>[qw(ipaddress ipv4address ipv6address 
                                    description dnsname)]),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(parent applid)],
                vjoininhash   =>['parent','applid','usage','comments']),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                group         =>'applications',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(parent)]),

      new kernel::Field::SubList(
                name          =>'applicationids',
                htmldetail    =>0,
                label         =>'ApplicationIDs',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(applid)]),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                vjointo       =>'tsacinv::lnksystemsoftware',
                vjoinon       =>['lportfolioitemid'=>'lparentid'],
                vjoindisp     =>[qw(id name version quantity)]),

      new kernel::Field::SubList(
                name          =>'usedsharedstorage',
                label         =>'direct connected Shared-Storage Servers',
                group         =>'usedsharedcomp',
                vjointo       =>'tsacinv::sharedstoragemnt',
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoindisp     =>[qw(storagename name)]),

      new kernel::Field::Text(
                name          =>'usedsharednetcomp',
                group         =>'usedsharedcomp',
                label         =>'direct connected Shared-Network Components',
                vjointo       =>'tsacinv::lnksharednet',
                weblinkto     =>'NONE',
                htmldetail    =>0,
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoindisp     =>'netname'),

      new kernel::Field::SubList(
                name          =>'backups',
                label         =>'ordered backup jobs',
                group         =>'backups',
                forwardSearch =>1,
                vjointo       =>'tsacinv::backup',
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoindisp     =>[qw(backupid name stype bgroup tfrom tto isactive 
                                    hexpectedquantity)]),


      new kernel::Field::Dynamic(
                name          =>'dynservices',
                searchable    =>0,
                depend        =>[qw(systemid)],
                group         =>'services',
                label         =>'Services Columns',
                fields        =>\&AddDeliveredServices),

      new kernel::Field::Dynamic(
                name          =>'dynorderedservices',
                searchable    =>0,
                depend        =>[qw(systemid)],
                group         =>'orderedservices',
                label         =>'ordered Services Columns',
                fields        =>\&AddOrderedServices),

      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                label         =>'W5Base Application',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_sem',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base SeM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_tsm',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base TSM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_businessteam',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base Businessteam',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'acmdbcontract',
                group         =>'acmdb',
                selectfix     =>1,
                label         =>'ACMDB contract',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{$self->{name}} ne "");
                   }
                   return(0);
                },
                dataobjattr   =>'amcomputer.servicename'),

      new kernel::Field::Text(
                name          =>'acmdbcontractnumber',
                group         =>'acmdb',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{$self->{name}} ne "");
                   }
                   return(0);
                },
                label         =>'ACMDB contractnumber',
                dataobjattr   =>'amcomputer.slanumber'),

      new kernel::Field::Date(
                name          =>'instdate',
                group         =>'source',
                label         =>'system installation date',
                dataobjattr   =>'amportfolio.dtinvent'),

      new kernel::Field::Textarea(
                name          =>'merged_use_description',
                label         =>'merged description of application usage',
                depend        =>['applications'],
                searchable    =>'0',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $fo=$app->getField("applications",$current);
                   my $d=$fo->RawValue($current);
                   $d=[$d] if (ref($d) ne "ARRAY");
                   my $out="";
                   foreach my $rec (sort({$a->{parent}<=>$b->{parent}} @$d)){
                      my $l="'$rec->{parent}' as $rec->{usage} system";
                      $l.="\n$rec->{comments}" if ($rec->{comments} ne "");
                      $out.="\n---\n"  if ($out ne "" && $l ne "");
                      $out.=$l;
                   }
                   return($out);
                }),

      new kernel::Field::Textarea(                 # Attention: NCLOB field!
                name          =>'tcomments',       # makes distinct not posible!
                label         =>'technical comments',
                searchable    =>'0',
                #dataobjattr   =>"unistr(amcomment.memcomment)"),
                # unistr could not be used becouse invalid backslash sequenses
                # in assetmanager
                dataobjattr   =>"amcomment.memcomment"),

      new kernel::Field::Text(
                name          =>'autodiscent',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                weblinkto     =>'tsacinv::autodiscsystem',
                weblinkon     =>['systemid'=>'systemid'],
                label         =>'AutoDiscovery Entry',
                dataobjattr   =>"decode(amtsiautodiscovery.name,NULL,'',".
                                "amtsiautodiscovery.name || ".
                                "' ('||amtsiautodiscovery.assettag||') - '||".
                                "amtsiautodiscovery.source)"),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'amportfolio.dtcreation'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'amportfolio.dtlastmodif'),

#      new kernel::Field::Date(
#                name          =>'lastqcheck',
#                group         =>'source',
#                label         =>'Quality Check last date',
#                dataobjattr   =>'amportfolio.dqualitycheck'),

      new kernel::Field::Date(
                name          =>'mdaterev',
                group         =>'source',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'Modification-Date reverse',
                dataobjattr   =>'amportfolio.dtlastmodif'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amportfolio.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amportfolio.externalid'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
 
      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'amportfolio.dtlastmodif'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(amportfolio.assettag,35,'0')")

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(systemname status tsacinv_locationfullname 
                            systemid assetassetid));
   return($self);
}

sub AddW5BaseData
{
   my $self=shift;
   my $current=shift;
   my $systemid=$current->{systemid};
   my $app=$self->getParent();
   my $c=$self->getParent->Context();
   return(undef) if (!defined($systemid) || $systemid eq "");
   if (!defined($c->{W5BaseSys}->{$systemid})){
      my $w5sys=$app->getPersistentModuleObject("W5BaseSys","itil::system");
      my $w5appl=$app->getPersistentModuleObject("W5BaseAppl","itil::appl");
      $w5sys->ResetFilter();
      $w5sys->SetFilter({systemid=>\$systemid});
      my ($rec,$msg)=$w5sys->getOnlyFirst(qw(applications));
      my %l=();
      if (defined($rec)){
         my %appl=();
         my %sem=();
         my %tsm=();
         my %businessteam=();
         if (defined($rec->{applications}) && 
             ref($rec->{applications}) eq "ARRAY"){
            foreach my $app (@{$rec->{applications}}){
               $appl{$app->{applid}}=$app->{appl};
               $w5appl->ResetFilter();
               $w5appl->SetFilter({id=>\$app->{applid}});
               my ($arec,$msg)=$w5appl->getOnlyFirst(qw(sem businessteam 
                                                        semid tsm tsmid));
               if (defined($arec)){
                  $sem{$arec->{semid}}=$arec->{sem};
                  $tsm{$arec->{tsmid}}=$arec->{tsm};
                  $businessteam{$arec->{businessteam}}=$arec->{businessteam};
               }
            }
         }
         $l{w5base_appl}=[sort(values(%appl))];
         $l{w5base_sem}=[sort(values(%sem))];
         $l{w5base_tsm}=[sort(values(%tsm))];
         $l{w5base_businessteam}=[sort(values(%businessteam))];
      }
      $c->{W5BaseSys}->{$systemid}=\%l;
   }
   return($c->{W5BaseSys}->{$systemid}->{$self->Name});
   
}

sub AddDeliveredServices
{
   my $self=shift;
   my %param=@_;
   my @dyn=();
   my $c=$self->Context();
   if (!defined($c->{db})){
      $c->{db}=getModuleObject($self->getParent->Config,"tsacinv::service");
   }
   if (defined($param{current})){
      my $systemid=$param{current}->{systemid};
      $c->{db}->SetFilter({systemid=>\$systemid,isdelivered=>\'1'});
      my @l=$c->{db}->getHashList(qw(name ammount));
      my %sumrec=();
      foreach my $rec (@l){
         $sumrec{$rec->{name}}+=$rec->{ammount};
      }
      foreach my $ola (keys(%sumrec)){
         push(@dyn,$self->getParent->InitFields(
              new kernel::Field::Float(   name       =>'delola'.$ola,
                                          label      =>$ola,
                                          group      =>'services',
                                          htmldetail =>0,
                                          onRawValue =>sub {
                                                          return($sumrec{$ola});
                                                       },
                                          dataobjattr=>'amcomputer.name'
                                      )
             ));
      }
   }
   return(@dyn);
}

sub AddOrderedServices
{
   my $self=shift;
   my %param=@_;
   my @dyn=();
   my $c=$self->Context();
   if (!defined($c->{db})){
      $c->{db}=getModuleObject($self->getParent->Config,"tsacinv::service");
   }
   if (defined($param{current})){
      my $systemid=$param{current}->{systemid};
      $c->{db}->SetFilter({systemid=>\$systemid,isdelivered=>\'0'});
      my @l=$c->{db}->getHashList(qw(name ammount));
      my %sumrec=();
      foreach my $rec (@l){
         $sumrec{$rec->{name}}+=$rec->{ammount};
      }
      foreach my $ola (keys(%sumrec)){
         push(@dyn,$self->getParent->InitFields(
              new kernel::Field::Float(   name       =>'ordola'.$ola,
                                          label      =>$ola,
                                          group      =>'services',
                                          htmldetail =>0,
                                          onRawValue =>sub {
                                                          return($sumrec{$ola});
                                                       },
                                          dataobjattr=>'amcomputer.name'
                                      )
             ));
      }
   }
   return(@dyn);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!out of operation\"");
   }
   if (!defined(Query->Param("search_tenant"))){
     Query->Param("search_tenant"=>"CS");
   }

}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($W5V2::OperationContext eq "W5Replicate"){
      if ($#flt!=0 || ref($flt[0]) ne "HASH"){
         $self->LastMsg("ERROR","invalid Filter request on $self");
         return(undef);
      }

      my %f1=(%{$flt[0]});
      $f1{status}='!"out of operation"';

#      my %f2=(%{$flt[0]});
#      $f2{status}='"out of operation"';
#      $f2{mdate}='>now-7d';
#
#      @flt=([\%f1,\%f2]);
      @flt=([\%f1]);
   }
   return($self->SUPER::SetFilter(@flt));
}






sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}
         

sub SystemPartOfCorrection
{
   my $self=shift;
   my $val=shift;
   my $current=shift;
   my $context=$self->Context();

   if (!defined($context->{SystemPartOfobj})){
      $context->{SystemPartOfobj}=getModuleObject($self->getParent->Config,
                                                  "tsacinv::system");
   }
   if (lc($current->{status}) eq "out of operation"){
      return(0);
   }
   my $sys=$context->{SystemPartOfobj};

   if (defined($val) && $val==0){             # recalculate "SystemPartOf" if
      my $lassetid=$current->{lassetid};      # value is 0 and not the complete
      if ($lassetid ne ""){                   # asset is distributed to systems
         $sys->SetFilter({lassetid=>\$lassetid,
                          status=>"\"!out of operation\""});
         my @l=$sys->getHashList(qw(partofassetdec));
         my $nullsys=0;
         my $sumok=0;
         foreach my $rec (@l){
            $sumok+=$rec->{partofassetdec} if ($rec->{partofassetdec}>0);
            $nullsys++ if ($rec->{partofassetdec}==0);
         }
         if ($nullsys>0){
            $val=(1-$sumok)/$nullsys;
         }
      }
   }
   if (defined($val) && $val>0){
      $val=100*$val;
   }
   return($val);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "amcomputer,amportfolio,ammodel,amnature,amcomment,".
      "(select amcostcenter.*,amtsiaccsecunit.identifier as customerlink ".
      " from amcostcenter left outer ".
      " join amtsiaccsecunit on ".
      "amcostcenter.lcustomerlinkid=amtsiaccsecunit.lunitid ".
      " where amcostcenter.bdelete=0) amcostcenter, ".
      "amportfolio assetportfolio, ".
      "(select distinct ".
      "        amtsiservicetype.identifier ordered,amtsiservice.lportfolioid ".
      " from amtsiservice,amtsiservicetype ".
      " where amtsiservice.lservicetypeid=amtsiservicetype.ltsiservicetypeid ".
      "       and amtsiservicetype.identifier='XMBSM'".
      "       and amtsiservice.bdelete=0".
      ") tbsm,".
#      "(select amitemlistval.* from amitemlistval,amitemizedlist ".
#      " where amitemlistval.litemlistid=amitemlistval.litemlistid ".
#      " and amitemizedlist.identifier='amPortfolioSecuritySet')  ".
#      "securitysetval,".
      "amtenant,amtsiautodiscovery";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "amportfolio.bdelete=0 ".
      "and amcomputer.bgroup=0 ".
      "and assetportfolio.bdelete!=1 ".
      "and amportfolio.lparentid=assetportfolio.lportfolioitemid(+) ".
      "and amportfolio.lportfolioitemid=amcomputer.litemid ".
      "and amportfolio.lmodelid=ammodel.lmodelid ".
      "and ammodel.lnatureid=amnature.lnatureid ".
      "and amportfolio.ltenantid=amtenant.ltenantid ".
      "and amportfolio.lcostid=amcostcenter.lcostid(+) ".
      "and amportfolio.lportfolioitemid=tbsm.lportfolioid(+) ".
      "and ammodel.name='LOGICAL SYSTEM' ".
      "and amcomputer.lcommentid=amcomment.lcommentid(+) ".
      "and amportfolio.assettag=amtsiautodiscovery.assettag(+) ";
#      "and amportfolio.securityset=securitysetval.litemlistvalid(+) ";
   return($where);
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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default location form applications ipaddresses software 
             usedsharedcomp
             orderedservices services backups 
             assetdata assetfinanz saphier acmdb
             w5basedata source));
}  


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportSystem));
}  

sub ImportSystem
{
   my $self=shift;

   my $importname=trim(Query->Param("importname"));
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"AssetManager System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


   

sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   if ($param->{importname} ne ""){
      $flt={systemid=>[$param->{importname}]};
   }
   else{
      return(undef);
   }
   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(systemid systemname lassignmentid assetid));
   if ($#l==-1){
      $self->LastMsg(ERROR,"SystemID not found in AssetManager");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"SystemID not unique in AssetManager");
      return(undef);
   }

   my $sysrec=$l[0];
   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter($flt);
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5sysrec)){
      if ($w5sysrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"SystemID already exists in W5Base");
         return(undef);
      }
      $identifyby=$sys->ValidatedUpdateRecord($w5sysrec,{cistatusid=>4},
                                              {id=>\$w5sysrec->{id}});
   }
   else{
      # check 1: Assigmenen Group registered
      if ($sysrec->{lassignmentid} eq ""){
         $self->LastMsg(ERROR,"SystemID has no Assignment Group");
         return(undef);
      }
      #printf STDERR Dumper($sysrec);
      # check 2: Assingment Group active
      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      $acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisorldapid));
      if (!defined($acgrouprec)){
         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
         return(undef);
      }
      # check 3: Supervisor registered
      if ($acgrouprec->{supervisorldapid} eq "" &&
          $acgrouprec->{supervisoremail} eq ""){
         $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
         return(undef);
      }
      my $importname=$acgrouprec->{supervisorldapid};
      $importname=$acgrouprec->{supervisoremail} if ($importname eq "");
      # check 4: load Supervisor ID in W5Base
      my $tswiw=getModuleObject($self->Config,"tswiw::user");
      my $admid=$tswiw->GetW5BaseUserID($importname);
      if (!defined($admid)){
         $self->LastMsg(WARN,"Can't import Supervisor as Admin");
      }
      # check 5: find id of mandator "extern"
      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->SetFilter({name=>"extern"});
      my ($mandrec,$msg)=$mand->getOnlyFirst(qw(grpid));
      if (!defined($mandrec)){
         $self->LastMsg(ERROR,"Can't find mandator extern");
         return(undef);
      }
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write","direct");
      my $mandatorid=$mandrec->{grpid};
      if (in_array(\@mandators,200)){
         $mandatorid=200;
      }
      else{
         $mandatorid=$mandators[0];
      }
      if ($mandatorid eq ""){
         $self->LastMsg(ERROR,"Can't find any mandator");
         return(undef);
      }

      # final: do the insert operation
      my $newrec={name=>$sysrec->{systemname},
                  systemid=>$sysrec->{systemid},
                  allowifupdate=>1,
                  mandatorid=>$mandatorid,
                  cistatusid=>4};
      if (defined($admid)){
         $newrec->{admid}=$admid;
      }

      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $sys->ResetFilter();
      $sys->SetFilter({'id'=>\$identifyby});
      my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
      if (defined($rec)){
         my $qc=getModuleObject($self->Config,"base::qrule");
         $qc->setParent($sys);
         $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec);
      }
   }
   return($identifyby);
}





1;
