package tssmartcube::tcc;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use kernel::Field::DataMaintContacts;
use itil::lib::Listedit;
use itil::lib::SecurityRestrictor;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB
        itil::lib::SecurityRestrictor);

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
                label         =>'Fullname',
                uivisible     =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"(SYSTEM_NAME||' ('||SYSTEM_ID||')')"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'SYSTEM_NAME'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                htmllabelwidth=>'250',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"SYSTEM_ID"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'ASSET_ID'),

      new kernel::Field::Text(
                name          =>'w5applications',
                label         =>'W5Base/Application',
                group         =>'w5basedata',
                vjointo       =>\'itil::lnkapplsystem',
                vjoinslimit   =>'1000',
                vjoinon       =>['w5systemid'=>'systemid'],
                weblinkto     =>'none',
                vjoindisp     =>'appl'),

      new kernel::Field::Text(
                name          =>'productline',
                label         =>'Productline of TSI',
                htmllabelwidth=>'150',
                ignorecase    =>1,
                dataobjattr   =>'PRODUCTLINE'),

      new kernel::Field::Text(
                name          =>'operationcategory',
                label         =>'Operation Category',
                searchable    =>0,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'OPERATIONCATEGORY'),

      new kernel::Field::Text(
                name          =>'assignment_group',
                label         =>'Assignment Group',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'ASSIGNMENT_GROUP'),

      new kernel::Field::Text(
                name          =>'customerlink_identifier',
                label         =>'Kunde',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'CUSTOMERLINK_IDENTIFIER'),

      new kernel::Field::Text(
                name          =>'criticality',
                label         =>'Criticality',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'CRITICALITY'),

      new kernel::Field::Text(
                name          =>'autodiscoverystatus',
                label         =>'Autodiscovery Status',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'AUTODISCOVERYSTATUS'),

      new kernel::Field::Text(
                name          =>'appcom_techbase',
                label         =>'AppCom Location',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'APPCOM_TECHBASE'),

      new kernel::Field::Text(
                name          =>'virtualization',
                label         =>'Virtualization',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'VIRTUALIZATION'),

      new kernel::Field::Date(
                name          =>'opcatchangedate',
                label         =>'Operation Category Change Date',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'OPCAT_CHANGE_DATE'),

      new kernel::Field::Number(
                name          =>'check_status',
                label         =>'TCC total state: CheckID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'CHECK_STATUS'),

      new kernel::Field::Date(
                name          =>'tcc_report_date',
                searchable    =>0,
                htmllabelwidth=>'250',
                label         =>'Report-Date',
                dataobjattr   =>'REPORT_DATE'),

      new kernel::Field::Text(
                name          =>'check_status_color',
                htmllabelwidth=>'250',
                depend        =>['check_status_color'],
                background    =>\&getTCCbackground,
                label         =>'TCC total state',
                dataobjattr   =>getTCCColorSQL('CHECK_STATUS')),


      #######################################################################

      new kernel::Field::Text(
                name          =>'os_base_setup',
                label         =>'OS Base-Setup',
                htmllabelwidth=>'250',
                group         =>['patch'],
                depend        =>['os_base_setup_color'],
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                sqlorder      =>'NONE',
                dataobjattr   =>"(case ".
                    "when lower(OS_NAME) like '%windows%' then OS_NAME ".
                    "else OS_BASE_SETUP ".
                    "end)"),


      #######################################################################
      # Roadmap Compliance ##################################################

      new kernel::Field::Text(
                name          =>'roadmap',
                label         =>'Operating System',
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['roadmap_color'],
                group         =>['roadmap'],
                sqlorder      =>'NONE',
                dataobjattr   =>"(case ".
                    "when lower(OS_NAME) like '%windows%' then 'Windows' ".
                    "else OS_NAME ".
                    "end)"),

      new kernel::Field::Text(
                name          =>'roadmap_check',
                label         =>'Roadmap Compliance: CheckID',
                htmllabelwidth=>'250',
                group         =>['roadmap'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_ROADMAP'),

      new kernel::Field::Text(
                name          =>'roadmap_state',
                label         =>'Roadmap Compliance: State',
                htmllabelwidth=>'250',
                group         =>['roadmap'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_ROADMAP')),

      new kernel::Field::Text(
                name          =>'roadmap_color',
                label         =>'Roadmap Compliance: Color',
                htmllabelwidth=>'250',
                htmldetail    =>0,
                group         =>['roadmap'],
                dataobjattr   =>getTCCColorSQL('CHECK_ROADMAP')),

      #######################################################################

      new kernel::Field::Select(
                name          =>'denyupselect',
                label         =>'it is posible to update/upgrade OS',
                group         =>'upd',
                vjointo       =>'itil::upddeny',
                vjoinon       =>['denyupd'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'denyupd',
                group         =>'upd',
                default       =>'0',
                label         =>'UpdDenyID',
                dataobjattr   =>'denyupd'),

      new kernel::Field::Textarea(
                name          =>'denyupdcomments',
                group         =>'upd',
                label         =>'comments to Update/Refresh posibilities',
                dataobjattr   =>'denyupdcomments'),

     new kernel::Field::Date(
                name          =>'denyupdvalidto',
                group         =>'upd',
                htmldetail    =>sub{
                                   my $self=shift;
                                   my $mode=shift;
                                   my %param=@_;
                                   if (defined($param{current})){
                                      my $d=$param{current}->{$self->{name}};
                                      return(1) if ($d ne "");
                                   }
                                   return(0);
                                },
                label         =>'Update/Upgrade reject valid to',
                dataobjattr   =>'ddenyupdvalidto'),

      new kernel::Field::Text(
                name          =>'osroadmapstate',
                label         =>'OS Roadmap State',
                group         =>'upd',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['os_base_setup_state',
                                 'denyupdvalidto','denyupd',
                                 'denyupdcomments'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;


                   my $st="OK";
                   if ($current->{os_base_setup_state} eq "warning"){
                      $st="WARN";
                   }
                   if ($current->{os_base_setup_state} eq "critical"){
                      $st="FAIL";
                   }

                   my $failpost="";
                   if ($current->{denyupd}==0){
                      return($st);
                   }
                   elsif ($current->{denyupd}<100){
                      # check if "but OK| but not OK"
                      if ($st eq "WARN" || $st eq "FAIL"){
                         if ($current->{denyupdvalidto} ne ""){
                             my $d=CalcDateDuration(
                                   NowStamp("en"),$current->{denyupdvalidto});
                             if ($d->{totalminutes}<0){
                                $failpost=" and not OK";
                             }
                             else{
                                $failpost=" but OK";
                             }
                         }
                         if (length($current->{denyupdcomments})<10 &&
                             $failpost eq " but OK"){
                            $failpost=" and not OK";
                         }
                      }
                   }
                   else{
                      if ($st eq "WARN" || $st eq "FAIL"){
                         $failpost=" and not OK";
                      }
                   }

                   return($st.$failpost);
                }),

      new kernel::Field::Text(
                name          =>'days_not_patched',
                label         =>'Missing Patch released x days ago',
                htmldetail    =>'NotEmpty',
                background    =>\&getTCCbackground,
                group         =>'auditserver',
                searchable    =>0,
                dataobjattr   =>'DAYS_NOT_PATCHED'),

      new kernel::Field::Text(
                name          =>'days_not_patched_color',
                label         =>'Missing Patch: Color',
                htmldetail    =>'0',
                group         =>'auditserver',
                sqlorder      =>'NONE',
                dataobjattr   =>"CASE  ".
                                "WHEN lower(OPERATIONCATEGORY)='downtime optimized' THEN ".
                                      "(case ".
                                      "when DAYS_NOT_PATCHED=0 THEN NULL ".
                                      "when DAYS_NOT_PATCHED is null THEN NULL ".
                                      "when DAYS_NOT_PATCHED<180 THEN 'green' ".
                                      "when DAYS_NOT_PATCHED>365 THEN 'red' ".
                                      "else 'yellow' end) ".
                                "WHEN lower(OPERATIONCATEGORY)='up to date' THEN ".
                                      "(case ".
                                      "when DAYS_NOT_PATCHED=0 THEN NULL ".
                                      "when DAYS_NOT_PATCHED is null THEN NULL ".
                                      "when DAYS_NOT_PATCHED<90 THEN 'green' ".
                                      "when DAYS_NOT_PATCHED>120 THEN 'red' ".
                                      "else 'yellow' end) ".
                                "ELSE NULL ".
                                "END"),

      new kernel::Field::Text(
                name          =>'red_alert',
                label         =>'Red Alert',
                htmldetail    =>'NotEmpty',
                background    =>\&getTCCbackground,
                group         =>'auditserver',
                searchable    =>1,
                ignorecase    =>1,
                dataobjattr   =>'RED_ALERT'),

      new kernel::Field::Text(
                name          =>'red_alert_color',
                label         =>'Red Alert: Color',
                htmldetail    =>'0',
                searchable    =>1,
                group         =>'auditserver',
                dataobjattr   =>"decode(RED_ALERT,NULL,'','red')"),

      #######################################################################
      # Release-/Patchmanagement Compliancy #################################

      new kernel::Field::Text(
                name          =>'os_base_setup_check',
                label         =>'OS Base-Setup: CheckID',
                group         =>['patch'],
                htmldetail    =>0,
                sqlorder      =>'NONE',
                dataobjattr   =>"(case ".
                    "when lower(OS_NAME) like '%windows%' then CHECK_ROADMAP ".
                    "else CHECK_OS ".
                    "end)"),

      new kernel::Field::Text(
                name          =>'os_base_setup_state',
                label         =>'OS Base-Setup: State',
                group         =>['patch'],
                htmldetail    =>0,
                sqlorder      =>'NONE',
                dataobjattr   =>getTCCStateSQL("(case ".
                    "when lower(OS_NAME) like '%windows%' then CHECK_ROADMAP ".
                    "else CHECK_OS ".
                    "end)")),

      new kernel::Field::Text(
                name          =>'os_base_setup_color',
                label         =>'OS Base-Setup: Color',
                group         =>['patch'],
                htmldetail    =>0,
                sqlorder      =>'NONE',
                dataobjattr   =>getTCCColorSQL("(case ".
                    "when lower(OS_NAME) like '%windows%' then CHECK_ROADMAP ".
                    "else CHECK_OS ".
                    "end)")),


      new kernel::Field::Text(
                name          =>'other_base_setups',
                label         =>'Other Base-Setups',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['other_base_setups_color'],
                background    =>\&getTCCbackground,
                group         =>['patch'],
                dataobjattr   =>'OTHER_BASE_SETUPS'),

      new kernel::Field::Text(
                name          =>'other_base_setups_check',
                label         =>'Other Base-Setups: CheckID',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_OTHER'),

      new kernel::Field::Text(
                name          =>'other_base_setups_state',
                label         =>'Other Base-Setups: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_OTHER')),

      new kernel::Field::Text(
                name          =>'other_base_setups_color',
                label         =>'Other Base-Setups: Color',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_OTHER')),


      new kernel::Field::Text(
                name          =>'ha_base_setup',
                label         =>'Cluster Software',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['patch'],
                htmldetail    =>1,
                depend        =>['ha_base_setup_color'],
                background    =>\&getTCCbackground,
                dataobjattr   =>'HA_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'ha_base_setup_check',
                group         =>['patch'],
                htmldetail    =>0,
                label         =>'Cluster Software: CheckID',
                dataobjattr   =>'CHECK_HA'),

      new kernel::Field::Text(
                name          =>'ha_base_setup_state',
                group         =>['patch'],
                htmldetail    =>0,
                label         =>'Cluster Software: State',
                dataobjattr   =>getTCCStateSQL('CHECK_HA')),

      new kernel::Field::Text(
                name          =>'ha_base_setup_color',
                group         =>['patch'],
                htmldetail    =>0,
                label         =>'Cluster Software: Color',
                dataobjattr   =>getTCCColorSQL('CHECK_HA')),


      new kernel::Field::Text(
                name          =>'hw_base_setup',
                label         =>'Hardware Base-Setup',
                depend        =>['patch'],
                background    =>\&getTCCbackground,
                htmllabelwidth=>'250',
                ignorecase    =>1,
                group         =>['patch'],
                dataobjattr   =>'HW_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'hw_base_setup_check',
                label         =>'Hardware Base-Setup: CheckID',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_HW'),

      new kernel::Field::Text(
                name          =>'hw_base_setup_state',
                label         =>'Hardware Base-Setup: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_HW')),

      new kernel::Field::Text(
                name          =>'hw_base_setup_color',
                label         =>'Hardware Base-Setup: Color',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_HW')),

      new kernel::Field::Text(
                name          =>'sv_versions',
                label         =>'Software-Discovery Script Version',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['patch'],
                dataobjattr   =>'SV_VERSIONS'),

      new kernel::Field::Date(
                name          =>'tcc_version_info_date',
                label         =>'Software-Discovery: Importdate',
                group         =>['patch'],
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'VERSION_INFO_DATE'),

      new kernel::Field::Text(
                name          =>'check_release',
                label         =>'Release-/Patchmanagement Compliancy: CheckID',
                group         =>['patch'],
                htmllabelwidth=>'250',
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>'CHECK_RELEASE'),

      new kernel::Field::Text(
                name          =>'check_release_state',
                label         =>'Release-/Patchmanagement Compliancy: State',
                group         =>['patch'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_RELEASE')),

      new kernel::Field::Text(
                name          =>'check_release_color',
                label         =>'Release-/Patchmanagement Compliancy',
                htmllabelwidth=>'250',
                background    =>\&getTCCbackground,
                group         =>['patch'],
                dataobjattr   =>getTCCColorSQL('CHECK_RELEASE')),



      #######################################################################
      # Storage Connectivity Compliancy #####################################

      new kernel::Field::Text(
                name          =>'multipath_access',
                label         =>'SAN Multipath Access',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                group         =>['dsk'],
                depend        =>['multipath_access_color'],
                background    =>\&getTCCbackground,
                dataobjattr   =>'DISK_MULTIPATH_ACCESS'),

      new kernel::Field::Text(
                name          =>'multipath_access_check',
                label         =>'SAN Multipath Access: CheckID',
                htmldetail    =>0,
                group         =>['dsk'],
                dataobjattr   =>'CHECK_MULTIPATH'),

      new kernel::Field::Text(
                name          =>'multipath_access_color',
                label         =>'SAN Multipath Access: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_MULTIPATH')),

      new kernel::Field::Text(
                name          =>'disk',
                label         =>'SAN Disk Settings',
                group         =>'dsk',
                depend        =>['disk_color'],
                background    =>\&getTCCbackground,
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'disk_check',
                label         =>'SAN Disk Settings: CheckID',
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_DISK'),

      new kernel::Field::Text(
                name          =>'disk_state',
                label         =>'SAN Disk Settings: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_DISK')),

      new kernel::Field::Text(
                name          =>'disk_color',
                label         =>'SAN Disk Settings: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_DISK')),


      new kernel::Field::Text(
                name          =>'fc_settings',
                label         =>'Fibrechannel Settings',
                depend        =>['fc_settings_color'],
                htmllabelwidth=>'250',
                background    =>\&getTCCbackground,
                group         =>'dsk',
                ignorecase    =>1,
                dataobjattr   =>'FC_SETTINGS'),

      new kernel::Field::Text(
                name          =>'fc_settings_check',
                group         =>'dsk',
                label         =>'Fibrechannel Settings: CheckID',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_FC'),

      new kernel::Field::Text(
                name          =>'fc_settings_state',
                label         =>'SAN Filesets: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_FC')),

      new kernel::Field::Text(
                name          =>'fc_settings_color',
                label         =>'SAN Filesets: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_FC')),

      new kernel::Field::Text(
                name          =>'filesets',
                label         =>'SAN Filesets',
                group         =>['dsk'],
                htmllabelwidth=>'250',
                depend        =>['filesets_color'],
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                dataobjattr   =>'FILESETS_AVAILABLE'),

      new kernel::Field::Text(
                name          =>'filesets_check',
                label         =>'SAN Filesets: CheckID',
                group         =>['dsk'],
                htmldetail    =>0,
                ignorecase    =>1,
                dataobjattr   =>'CHECK_FILESETS'),


      new kernel::Field::Text(
                name          =>'filesets_state',
                label         =>'SAN Filesets: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_FILESETS')),

      new kernel::Field::Text(
                name          =>'filesets_color',
                label         =>'SAN Filesets: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_FILESETS')),


      new kernel::Field::Text(
                name          =>'vscsi',
                label         =>'VSCSI Settings',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['vscsi_color'],
                background    =>\&getTCCbackground,
                group         =>'dsk',
                dataobjattr   =>'VSCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'vscsi_check',
                label         =>'VSCSI Settings: CheckID',
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'CHECK_VSCSI'),

      new kernel::Field::Text(
                name          =>'vscsi_state',
                label         =>'VSCSI Settings: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_VSCSI')),

      new kernel::Field::Text(
                name          =>'vscsi_color',
                label         =>'VSCSI Settings: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_VSCSI')),


      new kernel::Field::Text(
                name          =>'iscsi',
                label         =>'ISCSI Settings',
                ignorecase    =>1,
                htmllabelwidth=>'250',
                depend        =>['iscsi_color'],
                background    =>\&getTCCbackground,
                group         =>'dsk',
                dataobjattr   =>'ISCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'iscsi_check',
                label         =>'ISCSI Settings: CheckID',
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'CHECK_ISCSI'),

      new kernel::Field::Text(
                name          =>'iscsi_state',
                label         =>'VSCSI Settings: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_VSCSI')),

      new kernel::Field::Text(
                name          =>'iscsi_color',
                label         =>'VSCSI Settings: Color',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_VSCSI')),

      new kernel::Field::Text(
                name          =>'storage',
                label         =>'Storage-Discovery Script-Version',
                ignorecase    =>1,
                htmldetail    =>0,
                htmllabelwidth=>'250',
                group         =>'dsk',
                dataobjattr   =>'SV_STORAGE'),

      new kernel::Field::Date(
                name          =>'tcc_storage_date',
                label         =>'Storage-Discovery Importdate',
                group         =>['dsk'],
                htmldetail    =>0,
                htmllabelwidth=>'250',
                dataobjattr   =>'STORAGE_DATE'),

      new kernel::Field::Text(
                name          =>'storage_check',
                label         =>'Storage Connectivity Compliancy: CheckID',
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_STORAGE'),

      new kernel::Field::Text(
                name          =>'iscsi_state',
                label         =>'Storage Connectivity Compliancy: State',
                group         =>['dsk'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_STORAGE')),

      new kernel::Field::Text(
                name          =>'storage_color',
                label         =>'Storage Connectivity Compliancy',
                group         =>['dsk'],
                htmllabelwidth=>'250',
                background    =>\&getTCCbackground,
                dataobjattr   =>getTCCColorSQL('CHECK_STORAGE')),



      #######################################################################


      new kernel::Field::Link(
                name          =>'w5systemid',
                label         =>'W5BaseID of relevant System',
                group         =>'w5basedata',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'id'),

      new kernel::Field::Text(
                name          =>'w5systemname',
                label         =>'W5Base/logical System',
                group         =>'w5basedata',
                searchable    =>0,
                vjointo       =>\'AL_TCom::system',
                vjoinon       =>['w5systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::DataMaintContacts(
                vjointo       =>'itil::system',
                vjoinon       =>['w5systemid'=>'id'],
                group         =>'w5basedata'),
               

      #######################################################################
      new kernel::Field::Text(
                name          =>'srcsys',
                label         =>'AutoDiscovery Sourcesystem',
                searchable    =>0,
                htmllabelwidth=>'250',
                group         =>'source',
                dataobjattr   =>'AD_SOURCE'),

      new kernel::Field::MDate(
                name          =>'mdate', 
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'dmodifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser')
   );
   $self->setWorktable("smartcube_tcc_report_of");
   $self->setDefaultView(qw(systemid systemname roadmap check_status_color));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="smartcube_tcc_report";

   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="";

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->IsMemberOf([qw(admin 
                                 w5base.tssmartcube.tcc.read
                                 w5base.tssmartcube.tcc.read.itsem
                              )],
          "RMember")){
         my @systemid=$self->getSecurityRestrictedAllowedSystemIDs(10);
         if ($#systemid>-1){
            my @secsystemid;
            #needed to fix ora "in" limits
            while (my @sid=splice(@systemid,0,500)){ 
               push(@secsystemid,"SYSTEM_ID in (".
                                 join(",",map({"'".$_."'"} @sid)).")");
            }
            $where="(".join(" OR ",@secsystemid).")";
         }
         else{
            $where="(1=0)";
         }
      }
   }

   return($where);
}



#SYSTEM_ID               = SystemID des logischen Systems (aus AssetManager)

#OS_ROADMAP              = aktuelle Betriebssystemversion
#CHECK_ROADMAP           = Farbcodierung für das Feld OS_ROADMAP

#OS_BASE_SETUP           = OS Base Setup (aus Versionsscript)
#CHECK_OS                = Farbcodierung
#HA_BASE_SETUP           = HA Base Setup (aus Versionsscript)
#OTHER_BASE_SETUPS       = Other Base Setup (aus Versionsscript)
#CHECK_OTHER             = Farbcodierung
#MONITOR                 = Monitoring Status
#PRODUCTLINE             = Production Line (Appcom, STS, Classic); aus der OLA Klasse im AssetManager ermittelt
#CHECK_FILESETS          = Farbcodierung
#DISK_MULTIPATH_ACCESS   = SAN Disc Multipath Access (aus Storagescript)
#CHECK_MULTIPATH         = Farbcodierung
#CHECK_DISK              = Farbcodierung
#FC_SETTINGS             = SAN FC Settings (aus Storagescript)
#CHECK_FC                = Farbcodierung
#VERSION_INFO_DATE       = Zeitpunkt an dem die Versionsdaten in die Datenbank geladen wurden
#DESCRIPTION             = Kommentar, den TCC Server Administratoren eingeben können; Kommt nicht aus Asset Manager
#TMR                     = Source von den Autodiscoverydaten
#STORAGE_DATE            = Zeitpunkt an dem die Storage Daten in die Datenbank geladen wurden
#VSCSI_DISK_SETTINGS     = vSCSI Settings (aus Storagescript)
#CHECK_VSCSI             = Farbcodierung
#ISCSI_DISK_SETTINGS     = iSCSI Settings (aus Storagescript)
#CHECK_ISCSI             = Farbcodierung
#SV_VERSIONS             = Version des Scripts, das die Versionsdaten liefert
#SV_STORAGE              = Version des Scripts, das die Storage Daten liefert
#CHECK_VERSIONS          = Farbcodierung
#CHECK_STORAGE           = Farbcodierung
#LAST_UPDATE             = Letzter Ausführungszeitpunkt des Scripts, das die Versionsdaten liefert
#LAST_UPDATE_ST          = Letzter Ausführungszeitpunkt des Scripts, das die Storage Daten liefert


sub getTCCStateSQL
{
   my $fld=shift;

   # 
   #  based on Mail from Wiebe, Helene <Helene.Wiebe@t-systems.com>
   #  from 04.12.2014
   # 

   my $d="decode($fld,0,'ok',".
                     "1,'warning',".
                     "2,'critical',".
                     "3,'undefined',".
                     "4,'never touch',".
                     "5,'pending customer',NULL)";
   return($d);
}

sub getTCCColorSQL
{
   my $fld=shift;

   # 
   #  based on Mail from Wiebe, Helene <Helene.Wiebe@t-systems.com>
   #  from 04.12.2014
   # 

   my $d="decode($fld,0,'green',".
                     "1,'yellow',".
                     "2,'red',".
                     "3,NULL,".
                     "4,'blue',".
                     "5,'blue',NULL)";
   return($d);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={systemid=>\$oldrec->{systemid}};
   $newrec->{systemid}=$oldrec->{systemid};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/));

   my $sys=getModuleObject($self->Config,"itil::system");
   $sys->SetFilter({systemid=>\$rec->{systemid}});
   my ($sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   my @l=$sys->isWriteValid($sysrec);

   if (in_array(\@l,[qw(upd ALL)]) || $self->IsMemberOf("admin")){
      return("upd");
   }
   return(undef);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->itil::lib::Listedit::updateDenyHandling($oldrec,$newrec)){
      return(0);
   }
   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default auditserver roadmap upd patch dsk ha  hw mon other w5basedata source));
}


sub getTCCbackground{
   my ($self,$FormatAs,$current)=@_;

   my $name=$self->Name();

   my $colorfield=$name;

   if (!($self->Name()=~m/_color$/)){
      $colorfield.="_color";
   }

   my $f=$self->getParent->getField($colorfield);

   my $col;

   if (defined($f)){
      $col=$f->RawValue($current);
   }

   return($col);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tssmartcube/load/bgtccicon.jpg?".$cgi->query_string());
}




1;
