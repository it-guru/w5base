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
                name          =>'ha_base_setup',
                label         =>'HA_BASE_SETUP',
                ignorecase    =>1,
                dataobjattr   =>'HA_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'check_ha',
                label         =>'CHECK_HA',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_HA'),

      new kernel::Field::Text(
                name          =>'other_base_setups',
                label         =>'OTHER_BASE_SETUPS',
                ignorecase    =>1,
                dataobjattr   =>'OTHER_BASE_SETUPS'),

      new kernel::Field::Text(
                name          =>'check_other',
                label         =>'CHECK_OTHER',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_OTHER'),

      new kernel::Field::Text(
                name          =>'sv_versions',
                label         =>'SV_VERSIONS',
                ignorecase    =>1,
                dataobjattr   =>'SV_VERSIONS'),

      new kernel::Field::Text(
                name          =>'version_info_date',
                label         =>'VERSION_INFO_DATE',
                ignorecase    =>1,
                dataobjattr   =>'VERSION_INFO_DATE'),

      new kernel::Field::Text(
                name          =>'check_storage',
                label         =>'CHECK_STORAGE',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_STORAGE'),

      new kernel::Field::Text(
                name          =>'filesets_available',
                label         =>'FILESETS_AVAILABLE',
                ignorecase    =>1,
                dataobjattr   =>'FILESETS_AVAILABLE'),

      new kernel::Field::Text(
                name          =>'check_filesets',
                label         =>'CHECK_FILESETS',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_FILESETS'),

      new kernel::Field::Text(
                name          =>'disk_multipath_access',
                label         =>'DISK_MULTIPATH_ACCESS',
                ignorecase    =>1,
                dataobjattr   =>'DISK_MULTIPATH_ACCESS'),

      new kernel::Field::Text(
                name          =>'check_multipath',
                label         =>'CHECK_MULTIPATH',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_MULTIPATH'),

      new kernel::Field::Text(
                name          =>'disk_settings',
                label         =>'DISK_SETTINGS',
                ignorecase    =>1,
                dataobjattr   =>'DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'check_disk',
                label         =>'CHECK_DISK',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_DISK'),

      new kernel::Field::Text(
                name          =>'fc_settings',
                label         =>'FC_SETTINGS',
                ignorecase    =>1,
                dataobjattr   =>'FC_SETTINGS'),

      new kernel::Field::Text(
                name          =>'check_fc',
                label         =>'CHECK_FC',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_FC'),

      new kernel::Field::Text(
                name          =>'vscsi_disk_settings',
                label         =>'VSCSI_DISK_SETTINGS',
                ignorecase    =>1,
                dataobjattr   =>'VSCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'check_vscsi',
                label         =>'CHECK_VSCSI',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_VSCSI'),

      new kernel::Field::Text(
                name          =>'iscsi_disk_settings',
                label         =>'ISCSI_DISK_SETTINGS',
                ignorecase    =>1,
                dataobjattr   =>'ISCSI_DISK_SETTINGS'),

      new kernel::Field::Text(
                name          =>'sv_storage',
                label         =>'SV_STORAGE',
                ignorecase    =>1,
                dataobjattr   =>'SV_STORAGE'),

      new kernel::Field::Text(
                name          =>'storage_date',
                label         =>'STORAGE_DATE',
                ignorecase    =>1,
                dataobjattr   =>'STORAGE_DATE'),

      new kernel::Field::Text(
                name          =>'ad_filter',
                label         =>'AD_FILTER',
                ignorecase    =>1,
                dataobjattr   =>'AD_FILTER'),

      new kernel::Field::Text(
                name          =>'check_ad',
                label         =>'CHECK_AD',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_AD'),

      new kernel::Field::Text(
                name          =>'mon_filter',
                label         =>'MON_FILTER',
                ignorecase    =>1,
                dataobjattr   =>'MON_FILTER'),

      new kernel::Field::Text(
                name          =>'check_mon',
                label         =>'CHECK_MON',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_MON'),

      new kernel::Field::Text(
                name          =>'ad_source',
                label         =>'AD_SOURCE',
                ignorecase    =>1,
                dataobjattr   =>'AD_SOURCE'),

      new kernel::Field::Text(
                name          =>'report_date',
                label         =>'REPORT_DATE',
                ignorecase    =>1,
                dataobjattr   =>'REPORT_DATE'),

      new kernel::Field::Text(
                name          =>'check_status',
                label         =>'CHECK_STATUS',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_STATUS'),

      new kernel::Field::Text(
                name          =>'productline',
                label         =>'PRODUCTLINE',
                ignorecase    =>1,
                dataobjattr   =>'PRODUCTLINE'),

      new kernel::Field::Text(
                name          =>'os_name',
                label         =>'OS_NAME',
                ignorecase    =>1,
                dataobjattr   =>'OS_NAME'),

      new kernel::Field::Text(
                name          =>'check_roadmap',
                label         =>'CHECK_ROADMAP',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_ROADMAP'),

      new kernel::Field::Text(
                name          =>'check_release',
                label         =>'CHECK_RELEASE',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_RELEASE'),

      new kernel::Field::Text(
                name          =>'os_base_setup',
                label         =>'OS_BASE_SETUP',
                ignorecase    =>1,
                dataobjattr   =>'OS_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'check_os',
                label         =>'CHECK_OS',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_OS'),

      new kernel::Field::Text(
                name          =>'hw_base_setup',
                label         =>'HW_BASE_SETUP',
                ignorecase    =>1,
                dataobjattr   =>'HW_BASE_SETUP'),

      new kernel::Field::Text(
                name          =>'check_hw',
                label         =>'CHECK_HW',
                ignorecase    =>1,
                dataobjattr   =>'CHECK_HW'),

   );
   $self->setWorktable("tcc_report");
   $self->setDefaultView(qw(systemid systemname));
   return($self);
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
