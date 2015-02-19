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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                uivisible     =>0,
                dataobjattr   =>"(SYSTEM_ID||'-'||SYSTEM_NAME)"),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"SYSTEM_ID"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                ignorecase    =>1,
                dataobjattr   =>'SYSTEM_NAME'),

      new kernel::Field::Text(
                name          =>'productline',
                label         =>'Productline',
                ignorecase    =>1,
                dataobjattr   =>'PRODUCTLINE'),


      #######################################################################
      # Cluster Software ####################################################
      new kernel::Field::Text(
                name          =>'ha_base_setup',
                label         =>'Cluster Software',
                ignorecase    =>1,
                group         =>['ha'],
                htmldetail    =>0,
                depend        =>['ha_base_setup_color'],
                background    =>\&getTCCbackground,
                dataobjattr   =>'HA_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'ha_base_setup_check',
                group         =>['ha'],
                htmldetail    =>0,
                label         =>'Cluster Software: CheckID',
                dataobjattr   =>'CHECK_HA'),

      new kernel::Field::Text(
                name          =>'ha_base_setup_state',
                group         =>['ha'],
                htmldetail    =>0,
                label         =>'Cluster Software: State',
                dataobjattr   =>getTCCStateSQL('CHECK_HA')),

      new kernel::Field::Text(
                name          =>'ha_base_setup_color',
                group         =>['default','ha'],
                htmldetail    =>0,
                label         =>'Cluster Software: Color',
                dataobjattr   =>getTCCColorSQL('CHECK_HA')),
      #######################################################################

      #######################################################################
      # Betriebssystem   ####################################################
      new kernel::Field::Text(
                name          =>'os_name',
                label         =>'Operationsystem',
                ignorecase    =>1,
                group         =>['os'],
                dataobjattr   =>'OS_NAME'),

      new kernel::Field::Text(
                name          =>'os_base_setup',
                label         =>'OS Base-Setup',
                group         =>['os'],
                depend        =>['os_base_setup_color'],
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                dataobjattr   =>'OS_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'os_base_setup_check',
                label         =>'OS Base-Setup: CheckID',
                group         =>['os'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_OS'),

      new kernel::Field::Text(
                name          =>'os_base_setup_state',
                label         =>'OS Base-Setup: State',
                group         =>['os'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_OS')),

      new kernel::Field::Text(
                name          =>'os_base_setup_color',
                label         =>'OS Base-Setup: Color',
                group         =>['os'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_OS')),

      #######################################################################


      #######################################################################
      # HW base-setups ######################################################
      new kernel::Field::Text(
                name          =>'hw_base_setup',
                label         =>'Hardware Base-Setup ?',
                depend        =>['hw_base_setup_color'],
                background    =>\&getTCCbackground,
                ignorecase    =>1,
                group         =>['hw'],
                dataobjattr   =>'HW_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'hw_base_setup_check',
                label         =>'Hardware Base-Setup: CheckID',
                group         =>['hw'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_HW'),

      new kernel::Field::Text(
                name          =>'hw_base_setup_state',
                label         =>'Hardware Base-Setup: State',
                group         =>['hw'],
                htmldetail    =>0,
                dataobjattr   =>getTCCStateSQL('CHECK_HW')),

      new kernel::Field::Text(
                name          =>'hw_base_setup_color',
                label         =>'Hardware Base-Setup: Color',
                group         =>['hw'],
                htmldetail    =>0,
                dataobjattr   =>getTCCColorSQL('CHECK_HW')),

      #######################################################################

      #######################################################################
      # other base-setups ###################################################
      new kernel::Field::Text(
                name          =>'other_base_setups',
                label         =>'Other Base-Setups',
                ignorecase    =>1,
                htmldetail    =>0,
                group         =>['other'],
                dataobjattr   =>'OTHER_BASE_SETUPS'),

      new kernel::Field::Text(
                name          =>'other_base_setups_check',
                label         =>'Other Base-Setups: CheckID',
                group         =>['other'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_OTHER'),

      #######################################################################

      #######################################################################
      # Roadmap #############################################################
      new kernel::Field::Text(
                name          =>'filesets',
                label         =>'Filesets for Roadmap',
                group         =>['roadmap'],
                depend        =>['filesets_color'],
#                background    =>\&getTCCbackground,
                htmldetail    =>0,
                ignorecase    =>1,
                dataobjattr   =>'FILESETS_AVAILABLE'),

#      new kernel::Field::Text(
#                name          =>'filesets_check',
#                label         =>'Filesets for Roadmap: CheckID',
#                group         =>['roadmap'],
#                htmldetail    =>0,
#                ignorecase    =>1,
#                dataobjattr   =>'CHECK_FILESETS'),
#
#
#      new kernel::Field::Text(
#                name          =>'filesets_state',
#                label         =>'Filesets for Roadmap: State',
#                group         =>['roadmap'],
#                htmldetail    =>0,
#                dataobjattr   =>getTCCStateSQL('CHECK_FILESETS')),
#
#      new kernel::Field::Text(
#                name          =>'filesets_color',
#                label         =>'Filesets for Roadmap: Color',
#                group         =>['roadmap'],
#                htmldetail    =>0,
#                dataobjattr   =>getTCCColorSQL('CHECK_FILESETS')),

      new kernel::Field::Text(
                name          =>'sv_versions',
                label         =>'Software-Discovery Script Version',
                ignorecase    =>1,
                htmldetail    =>0,
                group         =>['roadmap'],
                dataobjattr   =>'SV_VERSIONS'),


      new kernel::Field::Text(
                name          =>'os_name_check',
                label         =>'Roadmap: CheckID',
                group         =>['roadmap'],
                htmldetail    =>0,
                dataobjattr   =>'CHECK_ROADMAP'),


      new kernel::Field::Date(
                name          =>'version_info_date',
                label         =>'Software-Discovery: Importdate',
                group         =>['roadmap'],
                ignorecase    =>1,
                dataobjattr   =>'VERSION_INFO_DATE'),

      #######################################################################

      #######################################################################
      # Multipath ###########################################################
      new kernel::Field::Text(
                name          =>'disk',
                label         =>'Disk Settings',
                group         =>'dsk',
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>'DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'disk_check',
                label         =>'Disk Settings: CheckID',
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_DISK'),

      new kernel::Field::Text(
                name          =>'multipath_access',
                label         =>'Multipath Access',
                ignorecase    =>1,
                htmldetail    =>0,
                group         =>['dsk'],
                dataobjattr   =>'DISK_MULTIPATH_ACCESS'),

      new kernel::Field::Text(
                name          =>'multipath_access_check',
                label         =>'Multipath Access: CheckID',
                htmldetail    =>0,
                group         =>['mp'],
                dataobjattr   =>'CHECK_MULTIPATH'),

      new kernel::Field::Text(
                name          =>'fc_settings',
                label         =>'Fibrechannel Settings',
                group         =>'dsk',
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>'FC_SETTINGS'),

      new kernel::Field::Text(
                name          =>'fc_settings_check',
                group         =>'dsk',
                label         =>'Fibrechannel Settings: CheckID',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_FC'),

      new kernel::Field::Text(
                name          =>'vscsi',
                label         =>'VSCSI Settings',
                ignorecase    =>1,
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'VSCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'vscsi_check',
                label         =>'VSCSI Settings: CheckID',
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'CHECK_VSCSI'),

      new kernel::Field::Text(
                name          =>'iscsi',
                label         =>'ISCSI Settings',
                ignorecase    =>1,
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'ISCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'iscsi_check',
                label         =>'ISCSI Settings: CheckID',
                htmldetail    =>0,
                group         =>'dsk',
                dataobjattr   =>'CHECK_ISCSI'),

      new kernel::Field::Text(
                name          =>'storage',
                label         =>'Storage-Discovery Script-Version',
                ignorecase    =>1,
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'SV_STORAGE'),

      new kernel::Field::Text(
                name          =>'storage_check',
                label         =>'CHECK_STORAGE ?',
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'CHECK_STORAGE'),

      new kernel::Field::Date(
                name          =>'storage_date',
                label         =>'Storage-Data Import Date',
                ignorecase    =>1,
                group         =>'dsk',
                htmldetail    =>0,
                dataobjattr   =>'STORAGE_DATE'),

      #######################################################################

      #######################################################################
      # Monitoring ##########################################################
      new kernel::Field::Text(
                name          =>'mon',
                label         =>'Monitoring Filter',
                group         =>'mon',
                htmldetail    =>0,
                ignorecase    =>1,
                dataobjattr   =>'MON_FILTER'),

      new kernel::Field::Text(
                name          =>'mon_check',
                label         =>'Monitoring Filter: CheckID',
                group         =>'mon',
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>'CHECK_MON'),

      #######################################################################

#      new kernel::Field::Text(
#                name          =>'check_status',
#                label         =>'CHECK_STATUS ?',
#                ignorecase    =>1,
#                dataobjattr   =>'CHECK_STATUS'),
#
#      new kernel::Field::Text(
#                name          =>'check_release',
#                label         =>'CHECK_RELEASE ?',
#                ignorecase    =>1,
#                dataobjattr   =>'CHECK_RELEASE'),

      #######################################################################
      new kernel::Field::Text(
                name          =>'srcsys',
                label         =>'AutoDiscovery Sourcesystem',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'AD_SOURCE'),

      new kernel::Field::Text(
                name          =>'ad_filter',
                label         =>'Autodiscovery Filter',
                ignorecase    =>1,
                htmldetail    =>0,
                group         =>'source',
                dataobjattr   =>'AD_FILTER'),

      new kernel::Field::Text(
                name          =>'check_ad',
                label         =>'Autodiscovery: CheckID',
                htmldetail    =>0,
                group         =>'source',
                dataobjattr   =>'CHECK_AD'),

      new kernel::Field::Date(
                name          =>'report_date',
                searchable    =>0,
                label         =>'Report-Date',
                group         =>'source',
                dataobjattr   =>'REPORT_DATE'),

   );
   $self->setWorktable("tcc_report");
   $self->setDefaultView(qw(systemid systemname));
   return($self);
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



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default os ha roadmap hw dsk mon other source));
}




sub getTCCbackground{
   my ($self,$FormatAs,$current)=@_;

   my $name=$self->Name();

   my $f=$self->getParent->getField($name."_color");

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
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_saphier"))){
#     Query->Param("search_saphier"=>
#                  "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
#   }
#}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}




1;
