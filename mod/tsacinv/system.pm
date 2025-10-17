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
                label         =>'full CI-Name',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'system."fullname"'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'"systemname"'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemId',
                size          =>'13',
                explore       =>100,
                searchable    =>1,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'system."systemid"'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'itfarm',
                vjointo       =>\'tsacinv::itfarm',
                vjoinon       =>['assetassetid'=>'farmassets'],
                vjoindisp     =>'name',
                uivisible     =>0,
                label         =>'IT-Farm'),

      new kernel::Field::Text(
                name          =>'status',
                explore       =>200,
                label         =>'Status',
                dataobjattr   =>'system."status"'),

      new kernel::Field::Boolean(
                name          =>'deleted',
                readonly      =>1,
                label         =>'marked as delete',
                dataobjattr   =>'system."deleted"'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostcenterid'=>'id'],
                dataobjattr   =>'system."conumber"'),

      new kernel::Field::Import($self,
                vjointo       =>\'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>"location",
                fields        =>[qw(fullname location)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'none',
              #  weblinkon     =>['lassetid'=>'lassetid'],
                htmldetail    =>0,
                prefix        =>"asset",
                group         =>"location",
                fields        =>[qw(room place)]),

      new kernel::Field::Text(
                name          =>'customerlink',
                label         =>'Customer (link)',
                htmldetail    =>0,
                dataobjattr   =>'system."customerlink"'),

      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'system."lcostcenterid"'),

      new kernel::Field::Text(
                name          =>'cocustomeroffice',
                searchable    =>0,
                label         =>'Customer Office',
                size          =>'20',
                dataobjattr   =>'"cocustomeroffice"'),

      new kernel::Field::Text(
                name          =>'bc',
                label         =>'Business Center',
                dataobjattr   =>'"bc"'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP costcenter hierarchy',
                group         =>'saphier',
                htmldetail    =>0,
                ignorecase    =>1,
                dataobjattr   =>'"saphier"'),

      new kernel::Field::TextDrop(
                name          =>'supervisor',
                label         =>'Supervisor',
                searchable    =>0,
                vjointo       =>\'tsacinv::user',
                vjoinon       =>['supervid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'supervid',
                label         =>'Supervisor ID',
                dataobjattr   =>'system."supervid"'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                explore       =>300,
                label         =>'Assignment Group',
                vjointo       =>\'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name',
                dataobjattr   =>"cfmassignment.\"name\""),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisor',
                label         =>'Assignment Group Supervisor',
                htmldetail    =>0,
                vjointo       =>\'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisor'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroupsupervisoremail',
                label         =>'Assignment Group Supervisor E-Mail',
                htmldetail    =>0,
                vjointo       =>\'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'supervisoremail'),

      new kernel::Field::TextDrop(
                name          =>'iassignmentgroup',
                label         =>'Incident Assignment Group',
                vjointo       =>\'tsacinv::group',
                vjoinon       =>['lincidentagid'=>'lgroupid'],
                vjoindisp     =>'name',
                dataobjattr   =>"inmassignment.\"name\""),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'system."lassignmentid"'),

      new kernel::Field::Link(
                name          =>'lincidentagid',
                label         =>'AC-Incident-AssignmentID',
                dataobjattr   =>'system."lincidentagid"'),

      new kernel::Field::Text(
                name          =>'controlcenter',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter'=>'name'],
                label         =>'System ControlCenter',
                dataobjattr   =>'"controlcenter"'),

      new kernel::Field::Text(
                name          =>'controlcenter2',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter2'=>'name'],
                label         =>'Application ControlCenter',
                dataobjattr   =>'"controlcenter2"'),

      new kernel::Field::Text(
                name          =>'usage',
                group         =>'form',
                label         =>'Usage',
                dataobjattr   =>"
                   (case 
                     when (system.\"usage\" like 'HOUSING' or 
                           system.\"usage\" like 'OSY-I: HOUSING' ) and
                          system.\"srcsys\" is null and
                          system.\"srcid\" is null and
                          system.\"systemola\" like '%-ONLY' and 
                          system.\"systemname\" like '%_HW' and 
                          (cfmassignment.\"name\"='MIS' or 
                           cfmassignment.\"name\" like 'MIS.%') and
                          (inmassignment.\"name\"='TI' or 
                           inmassignment.\"name\" like 'TI.%' or
                           inmassignment.\"name\"='DT' or 
                           inmassignment.\"name\" like 'DT.%' or
                           inmassignment.\"name\"='TIT' or 
                           inmassignment.\"name\" like 'TIT.%') 
                          then n'INVOICE_ONLY'
                     when (system.\"usage\" like 'HOUSING' or
                           system.\"usage\" like 'OSY-I: HOUSING' ) and
                          system.\"srcsys\" is null and
                          system.\"srcid\" is null and
                          system.\"systemola\" like '%-ONLY' and 
                          (cfmassignment.\"name\"='MIS' or 
                           cfmassignment.\"name\" like 'MIS.%') and
                          (inmassignment.\"name\"='TI' or 
                           inmassignment.\"name\" like 'TI.%' or
                           inmassignment.\"name\"='DT' or 
                           inmassignment.\"name\" like 'DT.%' or
                           inmassignment.\"name\"='TIT' or 
                           inmassignment.\"name\" like 'TIT.%') 
                          then n'INVOICE_ONLY?'
                     else system.\"usage\"
                    end)
                "),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Type',
                group         =>'form',
                dataobjattr   =>'system."type"'),

      new kernel::Field::Text(
                name          =>'model',
                label         =>'Model',
                group         =>'form',
                dataobjattr   =>'system."model"'),

      new kernel::Field::Text(
                name          =>'nature',
                label         =>'Nature',
                group         =>'form',
                dataobjattr   =>'system."nature"'),

      new kernel::Field::Boolean(
                name          =>'isprotnetdev',
                label         =>'is protected network device',
                group         =>'form',
                dataobjattr   =>'"isProtectedNetworkDevice"'),

      new kernel::Field::Boolean(
                name          =>'isapplreldisallowed',
                label         =>'is application relation disallowed',
                group         =>'form',
                dataobjattr   =>'"isApplRelDisallowed"'),

      new kernel::Field::Boolean(
                name          =>'soxrelevant',
                label         =>'SOX relevant',
                group         =>'form',
                dataobjattr   =>'"soxrelevant"'),

      new kernel::Field::Boolean(
                name          =>'sas70relevant',
                label         =>'SAS70 relevant',
                group         =>'form',
                dataobjattr   =>"decode(\"sas70relevant\",'YES',1,0)"),

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
                dataobjattr   =>'system."securitymodel"'),

      new kernel::Field::Text(
                name          =>'altname',
                label         =>'second name',
                group         =>'form',
                dataobjattr   =>'"altname"'),

      new kernel::Field::Text(
                name          =>'norsolutionclass',
                label         =>'NORSolutionClass',
                group         =>'form',
                dataobjattr   =>'"norsolutionclass"'),

      new kernel::Field::Text(
                name          =>'securityset',
                label         =>'security set',
                ignorecase    =>1,
                group         =>'form',
                dataobjattr   =>'system."securityset"'),

      new kernel::Field::Float(
                name          =>'systemcpucount',
                label         =>'System CPU count',
                unit          =>'CPU',
                precision     =>0,
                dataobjattr   =>'system."systemcpucount"'),

      new kernel::Field::Float(  # temp. da es keine phys. cpu anzahl beim
                name          =>'systeminvoicecpucount',  # logischen system
                label         =>'invoice relevant cpu count', # geben kann
                unit          =>'CPU',                   # grund: TMO 
                htmldetail    =>0,                       # abrechnungsprozess
                precision     =>1,
                dataobjattr   =>'system."systeminvoicecpucount"'),

      new kernel::Field::Float(
                name          =>'systemcpuspeed',
                label         =>'System CPU speed',
                unit          =>'MHz',
                precision     =>0,
                dataobjattr   =>'system."systemcpuspeed"'),

      new kernel::Field::Text(
                name          =>'systemcputype',
                label         =>'System CPU type',
                unit          =>'MHz',
                dataobjattr   =>'system."systemcputype"'),

      new kernel::Field::Text(
                name          =>'systemtpmc',
                label         =>'System tpmC',
                unit          =>'tpmC',
                dataobjattr   =>'system."systemtpmc"'),

      new kernel::Field::Float(
                name          =>'systemmemory',
                label         =>'System Memory',
                unit          =>'MB',
                precision     =>0,
                dataobjattr   =>'system."systemmemory"'),

      new kernel::Field::Text(
                name          =>'virtualization',
                htmldetail    =>0,
                label         =>'Virualization Status',
                dataobjattr   =>'"virtualization"'),

      new kernel::Field::Text(
                name          =>'systemos',
                vjointo       =>\'tsacinv::osrelease',
                vjoinon       =>['systemos'=>'name'],
                weblinkto     =>'none',
                label         =>'System OS',
                dataobjattr   =>'"systemos"'),

      new kernel::Field::Text(
                name          =>'systemospatchlevel',
                label         =>'System OS patchlevel',
                dataobjattr   =>'"systemospatchlevel"'),

      new kernel::Field::Text(
                name          =>'systemos',
                label         =>'System OS',
                dataobjattr   =>'"systemos"'),

      new kernel::Field::Float(
                name          =>'partofasset',
                label         =>'System Part of Asset',
                unit          =>'%',
                htmldetail    =>0,
                depend        =>['lassetid','status'],
                prepRawValue  =>\&SystemPartOfCorrection,
                dataobjattr   =>'"partofasset"'),

      new kernel::Field::Float(
                name          =>'nativepartofasset',
                label      =>'System Part of Asset (native from AssetManager)',
                htmldetail    =>0,
                unit          =>'%',
                dataobjattr   =>'system."nativepartofasset"'),

#      new kernel::Field::Text(
#                name          =>'costallocactive',
#                label         =>'Cost allocation active',
#                dataobjattr   =>'amcomputer.bcostallocactive'),

      new kernel::Field::Text(
                name          =>'systemola',
                label         =>'System OLA',
                dataobjattr   =>'system."systemola"'),

      new kernel::Field::Select(
                name          =>'systemolaclass',
                label         =>'System OLA Service Class',
                value         =>['0','4','10','20','25','30','38'], 
                transprefix   =>'SYSCLASS.',
                dataobjattr   =>'"systemolaclass"'),

      new kernel::Field::Text(
                name          =>'rawsystemolaclass',
                htmldetail    =>0,
                label         =>'raw System OLA Service Class',
                dataobjattr   =>'system."rawsystemolaclass"'),

      new kernel::Field::Text(
                name          =>'operationcategory',
                label         =>'Operation Category',
                dataobjattr   =>'system."opcategory"'),

      new kernel::Field::Text(
                name          =>'priority',
                label         =>'Priority of system',
                dataobjattr   =>'system."priority"'),

      new kernel::Field::Date(
                name          =>'installdate',
                label         =>'installation date',
                dataobjattr   =>'system."installdate"'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'tsacinv::asset',
                weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetdata",
                fields        =>[qw(assetid)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'tsacinv::asset',
                weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                htmldetail    =>0,
                group         =>"assetdata",
                fields        =>[qw(serialno inventoryno modelname 
                                    powerinput cpucount cputype cpuspeed 
                                    corecount
                                    systemsonasset maitcond maintlevel)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                htmldetail    =>0,
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
                dataobjattr   =>'"partofassetdec"'),

      new kernel::Field::Interface(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'system."lcomputerid"'),

      new kernel::Field::Link(
                name          =>'lassetid',
                label         =>'AC-AssetID',
                selectfix     =>1,
                dataobjattr   =>'system."lassetid"'),

      new kernel::Field::Interface(
                name          =>'lclusterid',
                label         =>'AC-lClusterID',
                dataobjattr   =>'system."lclusterid"'),

      new kernel::Field::Link(
                name          =>'lportfolioitemid',
                label         =>'PortfolioID',
                dataobjattr   =>'system."lportfolioitemid"'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'AC-LocationID',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'locationid'),

      new kernel::Field::Link(
                name          =>'altbc',
                label         =>'Alternate BC',
                dataobjattr   =>'system."altbc"'),

      new kernel::Field::SubList(
                name          =>'orderedservices',
                label         =>'ordered Services',
                group         =>'orderedservices',
                vjointo       =>'tsacinv::service',
                vjoinbase     =>[{'isdelivered'=>\'0'}],
                forwardSearch =>1,
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoindisp     =>[qw(longname type ammount unit)],
                vjoininhash   =>['name','type','longname','ammount',
                                 'bmonthly']),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'delivered Services',
                group         =>'services',
                forwardSearch =>1,
                vjointo       =>'tsacinv::service',
                vjoinbase     =>[{'isdelivered'=>\'1'}],
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoindisp     =>[qw(longname type ammount unit)],
                vjoininhash   =>['name','type','longname','ammount',
                                 'bmonthly']),


      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                searchable    =>0,
                group         =>'ipaddresses',
                vjointo       =>'tsacinv::ipaddress',
                vjoinon       =>['lcomputerid'=>'lcomputerid'],
                vjoinbase     =>{deleted=>'0'},
                vjoindisp     =>[qw(fullname status description type)],
                vjoininhash   =>[qw(ipaddress ipv4address ipv6address 
                                    description dnsname status type)]),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinbase     =>{deleted=>'0'},
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
                vjoinbase     =>{deleted=>'0'},
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(parent)]),

      new kernel::Field::SubList(
                name          =>'applicationids',
                htmldetail    =>0,
                label         =>'ApplicationIDs',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinbase     =>{deleted=>'0'},
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
                htmldetail    =>0,
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
                preferArray   =>1,
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
                dataobjattr   =>'"acmdbcontract"'),

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
                dataobjattr   =>'"acmdbcontractnumber"'),

      new kernel::Field::Date(
                name          =>'instdate',
                group         =>'source',
                label         =>'system installation date',
                dataobjattr   =>'system."instdate"'),

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
                dataobjattr   =>'system."tcomments"'),

      new kernel::Field::Text(
                name          =>'autodiscent',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                weblinkto     =>'tsacinv::autodiscsystem',
                weblinkon     =>['systemid'=>'systemid'],
                label         =>'AutoDiscovery Entry',
                dataobjattr   =>'system."autodiscent"'),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'system."cdate"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'system."mdate"'),

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
                dataobjattr   =>'system."mdaterev"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'system."srcsys"'),

      new kernel::Field::Text(                 
                name          =>'srcid',       
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'system."srcid"'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
 
      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'system."replkeypri"'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>'system."replkeysec"'),

   );
   $self->{use_distinct}=0;
   $self->setWorktable("system");


   # Performance Hacks
   $self->getField("assetassetid")->{dataobjattr}=
      '"assetid"';

   $self->getField("locationid")->{dataobjattr}=
      '"locationid"';

   $self->getField("tsacinv_locationfullname")->{dataobjattr}=
      '"locationfullname"';

   $self->getField("tsacinv_locationlocation")->{dataobjattr}=
      '"locationlocation"';

 
   $self->setDefaultView(qw(systemname status tsacinv_locationfullname 
                            systemid assetassetid));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;

   # Performance Hack
   my $from="system ".
            "left outer join grp inmassignment ".
            "on system.\"lincidentagid\"=inmassignment.\"lgroupid\" ".
            "left outer join grp cfmassignment ".
            "on system.\"lassignmentid\"=cfmassignment.\"lgroupid\" ";
   return($from);
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
         my %applmgr=();
         my %sem=();
         my %tsm=();
         my %businessteam=();
         my %customerprio=();
         if (defined($rec->{applications}) && 
             ref($rec->{applications}) eq "ARRAY"){
            foreach my $app (@{$rec->{applications}}){
               $appl{$app->{applid}}=$app->{appl};
               $w5appl->ResetFilter();
               $w5appl->SetFilter({id=>\$app->{applid}});
               my ($arec,$msg)=$w5appl->getOnlyFirst(qw(sem businessteam 
                                                        semid tsm tsmid
                                                        customerprio
                                                        applmgr applmgrid));
               if (defined($arec)){
                  $sem{$arec->{semid}}=$arec->{sem};
                  $tsm{$arec->{tsmid}}=$arec->{tsm};
                  $customerprio{$arec->{customerprio}}=$arec->{customerprio};
                  $applmgr{$arec->{applmgrid}}=$arec->{applmgr};
                  $businessteam{$arec->{businessteam}}=$arec->{businessteam};
               }
            }
         }
         $l{w5base_appl}=[sort(values(%appl))];
         $l{w5base_sem}=[sort(values(%sem))];
         $l{w5base_tsm}=[sort(values(%tsm))];
         $l{w5base_applmgr}=[sort(values(%applmgr))];
         $l{w5base_applcustomerprio}=[sort(values(%customerprio))];
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
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!out of operation\"");
   }
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }
}

sub getFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;

   my @l=$self->SUPER::getFieldObjsByView($view,%param);

   #
   # hack to prevent display of "norsolutionclass" in outputs other then
   # Standard-Detail
   #
   if (defined($param{current}) && exists($param{current}->{norsolutionclass})){
      if ($param{output} ne "kernel::Output::HtmlDetail"){
         if (!$self->IsMemberOf("admin") &&
             !$self->IsMemberOf("w5base.tsacinv.system.securityread")){
            @l=grep({$_->{name} ne "norsolutionclass"} @l);
         }
      }
   }
   return(@l);
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
      if ((!exists($flt[0]->{systemid})) ||
          !ref($flt[0]->{systemid})){   # exakt record references are not
         my %f1=(%{$flt[0]});           # time filtered
         $f1{status}='!"out of operation"';

         my %f2=(%{$flt[0]});
         $f2{status}='"out of operation"';
         $f2{mdate}='>now-7d';

         @flt=([\%f1,\%f2]);
      }
   }
   #print STDERR Dumper(\@flt);
   #Stacktrace(1);
   #sleep(10);
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
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem AutoDiscoveryView));
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
   my @l=$self->getHashList(qw(systemid systemname lassignmentid status usage
                               assetid srcsys));
   if ($#l==-1){
      $self->LastMsg(ERROR,"SystemID not found in AssetManager");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"SystemID not unique in AssetManager");
      return(undef);
   }
   my $sysrec=$l[0];

   if ($sysrec->{status} eq "out of operation"){
      $self->LastMsg(ERROR,"SystemID is out of operation");
      return(undef);
   }





   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter($flt);
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my $identifyby;
   if (defined($w5sysrec)){
      if ($w5sysrec->{cistatusid}==4){
         $self->LastMsg(ERROR,"SystemID already exists in W5Base");
         return(undef);
      }

      my %newrec=(cistatusid=>4);
      my $userid;

      if ($self->isDataInputFromUserFrontend() &&
          !$self->IsMemberOf("admin")) {
         $userid=$self->getCurrentUserId();
         $newrec{databossid}=$userid;
      }

      if ($sys->ValidatedUpdateRecord($w5sysrec,\%newrec,
                                      {id=>\$w5sysrec->{id}})) {
         $identifyby=$w5sysrec->{id};
      }
   }
   else{
      # check 0: usage
      if ($sysrec->{usage}=~m/^INVOICE_ONLY/){
         $self->LastMsg(ERROR,"invoice systems are not allowed to import");
         return(undef);
      }
      # check 0.1: srcsys
      if ($sysrec->{srcsys}=~m/MCOS_FCI/){
         $self->LastMsg(ERROR,"MCOS FCI systems are not allowed to import");
         return(undef);
      }
    
      # check 1: Assigmenen Group registered
      if ($sysrec->{lassignmentid} eq ""){
         $self->LastMsg(ERROR,"SystemID has no Assignment Group");
         return(undef);
      }
      # check 2: Assignment Group active
      my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      $acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
      my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisoremail));
      if (!defined($acgrouprec)){
         $self->LastMsg(ERROR,"Can't find Assignment Group of system");
         return(undef);
      }
      # check 3: Supervisor registered
      #if ($acgrouprec->{supervisoremail} eq ""){
      #   $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
      #   return(undef);
      #}
      my $importname=$acgrouprec->{supervisoremail};
      # check 4: load Supervisor ID in W5Base
      my $user=getModuleObject($self->Config,"base::user");
      my $admid;
      if ($importname ne ""){
         $admid=$user->GetW5BaseUserID($importname,"email");
      }
      #if (!defined($admid)){
      #   $self->LastMsg(WARN,"Can't import Supervisor as Admin");
      #}
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
                  srcid=>$sysrec->{systemid},
                  srcsys=>'AssetManager',
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

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   my $systemid=$rec->{systemid};
   my $o=getModuleObject($self->Config,"tsacinv::autodiscsystem");
   $o->SetFilter({systemid=>\$systemid});
   my ($chkrec)=$o->getOnlyFirst(qw(systemid));
   if (!defined($chkrec)){
      return($self->SUPER::getHtmlDetailPages($p,$rec));
   }
   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "AutoDiscoveryView"=>$self->T("AutoDiscovery"));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;

   if ($p ne "AutoDiscoveryView"){
      return($self->SUPER::getHtmlDetailPageContent($p,$rec));
   }
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{systemid};

   if ($p eq "AutoDiscoveryView"){
      Query->Param("systemid"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("search_systemid"=>$idval);
      my $urlparam=$q->QueryString();
      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"../autodiscsystem/HtmlDetail?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}










1;
