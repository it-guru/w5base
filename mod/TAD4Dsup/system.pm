package TAD4Dsup::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

=head1

#
# Generierung der Support-Views in der pw5repo Kennung
#

create table "W5I_TAD4Dsup__system_of" (
   systemid     varchar2(40) not null,
   denv         varchar2(20) not null,
   comments     varchar2(4000),
   modifyuser   number(*,0),
   modifydate   date,
   constraint "W5I_TAD4Dsup__system_of_pk" primary key (systemid)
);


create or replace view "W5I_TAD4Dsup__system" as
select "W5I_system_universum".id,
       "W5I_system_universum".systemname,
       "W5I_system_universum".systemid,
       "W5I_system_universum".saphier,
       "W5I_system_universum".amcostelement costelement,
       (case
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=1 then 'Both'
          when "W5I_system_universum".is_t4dp=1 then 'Production'
          when "W5I_system_universum".is_t4di=1 then 'Integration'
          else 'None'
       end) cenv ,
       
       decode((select count(*)
        from "mview_TAD4D_adm_agent"
        where agent_custom_data1="W5I_system_universum".systemid
              and agent_active=1
       ),'1',1,'0','1',0) agent_systemidunique,

       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_status
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_status
          else null
       end) agent_status ,
       
       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_version
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_version
          else null
       end) agent_version ,
       
       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_osname
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_osname
          else null
       end) agent_osname ,

       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_osversion
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_osversion
          else null
       end) agent_osversion ,

       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_active
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_active
          else null
       end) agent_active ,

       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_full_hwscan_time
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_full_hwscan_time
          else null
       end) agent_full_hwscan_time ,

       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_agent.agent_scan_time
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_agent.agent_scan_time
          else null
       end) agent_scan_time ,

       (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_computer.computer_model
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_computer.computer_model
          else null
       end) computer_model ,

      (case
          when "W5I_system_universum".is_t4di=0 and
               "W5I_system_universum".is_t4dp=1 then tad4dp_computer.sys_ser_num
          when "W5I_system_universum".is_t4di=1 and
               "W5I_system_universum".is_t4dp=0 then tad4di_computer.sys_ser_num
          else null
       end) computer_serialno ,
       "tsacinv::system".systemola     AM_systemola,
       decode("tsacinv::system".systemolaclass,
              10,'CLASSIC',
              20,'STANDARDIZED',
              25,'STANDARDIZED SLICE',
              30,'APPCOM','UNDEF')  AM_systemolaclass,
       "tsacinv::system".status        AM_systemstatus,
       "tsacinv::system".securitymodel AM_securitymodel,
       "tsacinv::asset".modelname      AM_modelname,
       "tsacinv::system".assetassetid  AM_assetid,
       "tsacinv::asset".cputype        AM_assetcputype,
       "tsacinv::asset".cpucount       AM_assetcpucount,
       "tsacinv::asset".corecount      AM_assetcorecount,
       "tsacinv::asset".systemsonasset AM_systemsonasset,
       "tsacinv::asset".tsacinv_locationfullname AM_location,

       "W5I_TAD4Dsup__system_of".systemid of_id,
       "W5I_TAD4Dsup__system_of".comments,
       "W5I_TAD4Dsup__system_of".denv,
       "W5I_TAD4Dsup__system_of".modifyuser,
       "W5I_TAD4Dsup__system_of".modifydate
from "W5I_system_universum"

     left outer join "W5I_TAD4Dsup__system_of"
        on "W5I_system_universum".systemid="W5I_TAD4Dsup__system_of".systemid
        
     left outer join "mview_TAD4D_adm_agent" tad4dp_agent
        on "W5I_system_universum".t4dpcomputer_sys_id=tad4dp_agent.agent_id
           and tad4dp_agent.agent_deleted_time is null
        
     left outer join "mview_TAD4D_adm_agent" tad4di_agent
        on "W5I_system_universum".t4dicomputer_sys_id=tad4di_agent.agent_id
           and tad4di_agent.agent_deleted_time is null
        
     left outer join "mview_TAD4D_adm_computer" tad4dp_computer
        on tad4dp_agent.agent_id=tad4dp_computer.computer_sys_id
        
     left outer join "mview_TAD4D_adm_computer" tad4di_computer
        on tad4di_agent.agent_id=tad4di_computer.computer_sys_id
        
     left outer join "tsacinv::system"
        on "W5I_system_universum".systemid="tsacinv::system".systemid
        
     left outer join "tsacinv::asset"
        on "tsacinv::system".assetassetid="tsacinv::asset".assetid;

grant select on "W5I_TAD4Dsup__system" to W5I;
grant update,insert on "W5I_TAD4Dsup__system_of" to W5I;
create or replace synonym W5I.TAD4Dsup__system for "W5I_TAD4Dsup__system";
create or replace synonym W5I.TAD4Dsup__system_of for "W5I_TAD4Dsup__system_of";

grant select on "W5I_TAD4Dsup__system_of" to W5_BACKUP_D1;
grant select on "W5I_TAD4Dsup__system_of" to W5_BACKUP_W1;


=cut

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>"id",
                wrdataobjattr =>"systemid"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                lowersearch   =>1,
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP Hier',
                uppersearch   =>1,
                readonly      =>1,
                align         =>'left',
                dataobjattr   =>'saphier'),

      new kernel::Field::Text(
                name          =>'costelement',
                label         =>'costelement',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'costelement'),

      new kernel::Field::Select(
                name          =>'cenv',
                label         =>'current Env',
                readonly      =>1,
                selectfix     =>1,
                transprefix   =>'ENV.',
                value         =>['Production','Integration','Both','None'],
                dataobjattr   =>'cenv'),

      new kernel::Field::Select(
                name          =>'denv',
                label         =>'destination Env',
                transprefix   =>'ENV.',
                value         =>['Production','Integration','Shared',
                                 'CHK','DEFERRED','REJECTED','OUT',''],
                dataobjattr   =>'denv'),

      new kernel::Field::Boolean(
                name          =>'agent_active',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Agent Active',
                dataobjattr   =>'agent_active'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Textarea(
                name          =>'todo',
                label         =>'ToDo',
                readonly      =>1,
                dataobjattr   =>
                   "(case".
                   "   when systemid like 'TAD4D%MISS'  then ".
                       "'* set systemid on system agent\n'".
                   "   else ''".
                   "end) ||".
                   "(case".
                   "   when cenv<>denv  ".
                   "        AND denv<>'CHK' ".
                   "        AND denv<>'DEFERRED' ".
                   "        AND denv<>'OUT' ".
                   "        AND denv<>'Shared' ".
                   "        then '* move system to '||denv||'\n'".
                   "   else ''".
                   "end) ||".
                   "(case".
                   "   when cenv='Both' then '* remove system ".
                                             "from one enviroment\n'".
                   "   else ''".
                   "end) ||".
                   "(case".
                   "   when denv is null and saphier like '9TS_ES.9DTIT.%' ".
                                         "then '* set destination ".
                                               "enviroment\n'".
                   "   else ''".
                   "end)"),

      new kernel::Field::Text(
                name          =>'agent_version',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Agent Version',
                dataobjattr   =>'agent_version'),

      new kernel::Field::Boolean(
                name          =>'agent_systemidunique',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Agent SystemID Unique',
                dataobjattr   =>'agent_systemidunique'),

      new kernel::Field::Text(
                name          =>'agent_status',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Agent Status',
                dataobjattr   =>'agent_status'),

      new kernel::Field::Text(
                name          =>'agent_osname',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Agent OS Name',
                dataobjattr   =>'agent_osname'),

      new kernel::Field::Text(
                name          =>'agent_osversion',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Agent OS Version',
                dataobjattr   =>'agent_osversion'),

      new kernel::Field::Date(
                name          =>'hwscan_time',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Hardware-Scan-Date',
                dataobjattr   =>'agent_full_hwscan_time'),

      new kernel::Field::Date(
                name          =>'scan_time',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Software-Scan-Date',
                dataobjattr   =>'agent_scan_time'),

      new kernel::Field::Text(
                name          =>'computer_model',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Computer Model',
                dataobjattr   =>'computer_model'),

      new kernel::Field::Text(
                name          =>'computer_serialno',
                group         =>'tad4d',
                readonly      =>1,
                label         =>'Computer Serialno.',
                dataobjattr   =>'computer_serialno'),

      new kernel::Field::Text(
                name          =>'am_systemid',
                group         =>'am',
                label         =>'SystemID',
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'am_systemola',
                group         =>'am',
                label         =>'SystemOLA',
                dataobjattr   =>'am_systemola'),

      new kernel::Field::Text(
                name          =>'am_systemolaclass',
                group         =>'am',
                label         =>'SystemOLA Service Class',
                dataobjattr   =>'am_systemolaclass'),

      new kernel::Field::Text(
                name          =>'am_systemstatus',
                group         =>'am',
                label         =>'System Status',
                dataobjattr   =>'am_systemstatus'),

      new kernel::Field::Text(
                name          =>'am_securitymodel',
                group         =>'am',
                translation   =>'tsacinv::system',
                label         =>'security flag',
                dataobjattr   =>'am_securitymodel'),

      new kernel::Field::Text(
                name          =>'am_assetid',
                group         =>'am',
                label         =>'AssetID',
                dataobjattr   =>'am_assetid'),

      new kernel::Field::Text(
                name          =>'am_modelname',
                group         =>'am',
                label         =>'Model',
                dataobjattr   =>'am_modelname'),

      new kernel::Field::Text(
                name          =>'am_location',
                group         =>'am',
                label         =>'AMLocation',
                dataobjattr   =>'am_location'),

      new kernel::Field::Number(
                name          =>'am_cpucount',
                group         =>'am',
                translation   =>'tsacinv::asset',
                label         =>'Asset CPU count',
                dataobjattr   =>'am_assetcpucount'),

      new kernel::Field::Text(
                name          =>'am_assetcputype',
                group         =>'am',
                translation   =>'tsacinv::asset',
                label         =>'Asset CPU Typ',
                dataobjattr   =>'am_assetcputype'),

      new kernel::Field::Number(
                name          =>'am_corecount',
                group         =>'am',
                translation   =>'tsacinv::asset',
                label         =>'Asset Core count',
                dataobjattr   =>'am_assetcorecount'),

      new kernel::Field::Number(
                name          =>'am_systemsonasset',
                group         =>'am',
                translation   =>'tsacinv::asset',
                label         =>'Systems on Asset',
                dataobjattr   =>'am_systemsonasset'),

      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                readonly      =>1,
                label         =>'W5Base Application',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_tsm',
                searchable    =>0,
                readonly      =>1,
                group         =>'w5basedata',
                label         =>'W5Base TSM',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser')
   );
   $self->setWorktable("TAD4Dsup__system_of");
   $self->setDefaultView(qw(systemname systemid cenv denv todo));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="TAD4Dsup__system";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default tad4d w5basedata am source));
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{systemid}};
   $newrec->{id}=$oldrec->{systemid};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_saphier"))){
     Query->Param("search_saphier"=>
                  "\"K001YT5ATS_ES\" \"K001YT5ATS_ES.*\" ".
                  "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
   }
   if (!defined(Query->Param("search_denv"))){
     Query->Param("search_denv"=>
                  "\"!out of scope\"");
   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

   if (in_array(\@l,"ALL")){
      if ($rec->{cenv} eq "Both"){
         return(qw(header source am default));
      }
   }
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/) &&
                     !($rec->{systemid}=~m/^\d{14,20}$/));
   my @l=$self->SUPER::isWriteValid($rec,@_);


   return("default") if ($#l!=-1);
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
