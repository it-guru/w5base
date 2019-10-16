package FLEXERAsup::system;
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

# -- drop table "W5I_FLEXERAsup__system_of";

create table "W5I_FLEXERAsup__system_of" (
   refid               varchar2(80) not null,
   comments            varchar2(4000),
   rollout_package     varchar2(40),
   rollout_process     varchar2(40),
   rollout_instplanned date,
   rollout_hpoaavail   varchar2(40),
   rollout_hpsaavail   number(*,0),
   rollout_ipv6        number(*,0),
   rollout_issungzone  number(*,0),
   rollout_isitm6      number(*,0),
   rollout_isrcrel     number(*,0),
   rollout_oos_reason  varchar2(40),
   rollout_oos_cluster varchar2(40),
   modifyuser          number(*,0),
   modifydate          date,
   constraint "W5I_TAD4Dsup__system_of_pk" primary key (refid)
);

grant select,update,insert on "W5I_FLEXERAsup__system_of" to W5I;
grant select on "W5I_FLEXERAsup__system_of" to W5_BACKUP_D1;
grant select on "W5I_FLEXERAsup__system_of" to W5_BACKUP_W1;

create or replace synonym W5I.FLEXERAsup__system_of for "W5I_FLEXERAsup__system_of";



create or replace view "W5I_FLEXERAsup__system" as
select "W5I_system_universum".id,
       "W5I_system_universum".systemname,
       "W5I_system_universum".systemid,
       "W5I_system_universum".saphier,
       "W5I_system_universum".amcostelement costelement,
       "W5I_system_universum".w5costelement w5costelement,
       decode("mview_FLEXERA_system".FLEXERASYSTEMID,NULL,0,1) flexerafnd,
       "mview_FLEXERA_system".SYSTEMINVHOSTTYPE                systeminvhosttype,
       "mview_FLEXERA_system".ISVM                             isvm,
       "mview_FLEXERA_system".ISVMHOSTMISSING                  isvmhostmissing,
       "mview_FLEXERA_system".INVENTORYDATE                    inventorydate,
       "mview_FLEXERA_system".SERVICESINVENTORYDATE            servicesinventorydate,
       "mview_FLEXERA_system".HARDWAREINVENTORYDATE            hardwareinventorydate,
       "tsacinv::system".assetassetid            AM_assetid,
       "tsacinv::system".systemola               AM_systemola,
       decode("tsacinv::system".systemolaclass,
              10,'CLASSIC',
              20,'STANDARDIZED',
              25,'STANDARDIZED SLICE',
              30,'APPCOM','UNDEF')               AM_systemolaclass,
       "tsacinv::system".status                  AM_systemstatus,
       "tsacinv::system".securitymodel           AM_securitymodel,
       "tsacinv::system".assignmentgroup         AM_assignmentgroup,
       "tsacinv::asset".modelname                AM_modelname,
       "tsacinv::asset".cputype                  AM_assetcputype,
       "tsacinv::asset".cpucount                 AM_assetcpucount,
       "tsacinv::asset".corecount                AM_assetcorecount,
       "tsacinv::asset".systemsonasset           AM_systemsonasset,
       "tsacinv::asset".tsacinv_locationfullname AM_location,
       "itil::system".mandator                   W5_mandator,
       "itil::system".cistatusid                 W5_cistatus,
       "itil::system".location                   W5_location,
       "itil::system".osrelease                  W5_osrelease,
       "itil::system".osclass                    W5_osclass,
       "itil::system".isprod                     W5_isprod,
       "itil::system".istest                     W5_istest,
       "itil::system".isdevel                    W5_isdevel,
       "itil::system".iseducation                W5_iseducation,
       "itil::system".isapprovtest               W5_isapprovtest,
       "itil::system".isreference                W5_isreference,
       '0'                                       TAD4D_is,
       '0'                                       TAD4D_is_sub_cap,
       "W5I_FLEXERAsup__system_of".refid of_id,
       "W5I_FLEXERAsup__system_of".comments,
       "W5I_FLEXERAsup__system_of".rollout_package,
       "W5I_FLEXERAsup__system_of".rollout_process,
       "W5I_FLEXERAsup__system_of".rollout_instplanned,
       to_char("W5I_FLEXERAsup__system_of".rollout_instplanned,'iw') rollout_instplannedcw,
       "W5I_FLEXERAsup__system_of".rollout_hpoaavail,
       "W5I_FLEXERAsup__system_of".rollout_hpsaavail,
       "W5I_FLEXERAsup__system_of".rollout_ipv6,
       "W5I_FLEXERAsup__system_of".rollout_isitm6,
       "W5I_FLEXERAsup__system_of".rollout_isrcrel,
       "W5I_FLEXERAsup__system_of".rollout_issungzone,
       "W5I_FLEXERAsup__system_of".rollout_oos_reason,
       "W5I_FLEXERAsup__system_of".rollout_oos_cluster,

       "W5I_FLEXERAsup__system_of".modifyuser,
       "W5I_FLEXERAsup__system_of".modifydate
from "W5I_system_universum"
     left outer join "W5I_FLEXERAsup__system_of"
        on "W5I_system_universum".id=
           "W5I_FLEXERAsup__system_of".refid
     left outer join "W5I_FLEXERA__systemidmap_of"
        on "W5I_system_universum".systemid=
           "W5I_FLEXERA__systemidmap_of".systemid
     left outer join "mview_FLEXERA_system"
        on "W5I_FLEXERA__systemidmap_of".flexerasystemid=
           "mview_FLEXERA_system".flexerasystemid
     left outer join "itil::system"
        on "W5I_system_universum".systemid=
           "itil::system".systemid
     left outer join "tsacinv::system"
        on "W5I_system_universum".systemid=
           "tsacinv::system".systemid
     left outer join "tsacinv::asset"
        on "tsacinv::system".assetassetid=
           "tsacinv::asset".assetid;

grant select on "W5I_FLEXERAsup__system" to W5I;
create or replace synonym W5I.FLEXERAsup__system for "W5I_FLEXERAsup__system";



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
                history       =>0,
                dataobjattr   =>"id",
                wrdataobjattr =>"refid"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                lowersearch   =>1,
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'systemname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                readonly      =>1,
                dataobjattr   =>'w5_cistatus'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                selectfix     =>1,
                readonly      =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'mandator',
                label         =>'Mandator',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'W5_mandator'),

      new kernel::Field::Boolean(
                name          =>'inflexera',
                readonly      =>1,
                group         =>'flexera',
                selectfix     =>1,
                label         =>'in Flexera known',
                dataobjattr   =>"flexerafnd"),

      new kernel::Field::Text(
                name          =>'flexerainvhosttype',
                readonly      =>1,
                group         =>'flexera',
                label         =>'Flexera InvHostType',
                dataobjattr   =>"systeminvhosttype"),

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
                label         =>'AM costelement',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'costelement'),

      new kernel::Field::Text(
                name          =>'w5costelement',
                label         =>'W5Base costelement',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'costelement'),

      new kernel::Field::Import( $self,
                vjointo       =>'FLEXERAatW5W::system',
                dontrename    =>1,
                readonly      =>1,
                group         =>'flexera',
                uploadable    =>0,
                fields        =>[qw(is_vm is_vmhostmissing scandate svscandate hwscandate)]),

      new kernel::Field::Text(
                name          =>'am_systemid',
                group         =>'am',
                readonly      =>1,
                label         =>'SystemID',
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'am_sysassignment',
                group         =>'am',
                readonly      =>1,
                label         =>'Assignmentgroup',
                dataobjattr   =>'AM_assignmentgroup'),

      new kernel::Field::Text(
                name          =>'am_systemola',
                group         =>'am',
                readonly      =>1,
                label         =>'SystemOLA',
                dataobjattr   =>'am_systemola'),

      new kernel::Field::Text(
                name          =>'am_systemolaclass',
                group         =>'am',
                readonly      =>1,
                label         =>'SystemOLA Service Class',
                dataobjattr   =>'am_systemolaclass'),

      new kernel::Field::Text(
                name          =>'am_systemstatus',
                group         =>'am',
                readonly      =>1,
                label         =>'System Status',
                dataobjattr   =>'am_systemstatus'),

      new kernel::Field::Text(
                name          =>'am_securitymodel',
                group         =>'am',
                readonly      =>1,
                translation   =>'tsacinv::system',
                label         =>'security flag',
                dataobjattr   =>'am_securitymodel'),

      new kernel::Field::Text(
                name          =>'am_assetid',
                group         =>'am',
                readonly      =>1,
                label         =>'AssetID',
                dataobjattr   =>'am_assetid'),

      new kernel::Field::Text(
                name          =>'am_modelname',
                group         =>'am',
                readonly      =>1,
                label         =>'Model',
                dataobjattr   =>'am_modelname'),

      new kernel::Field::Text(
                name          =>'am_location',
                group         =>'am',
                readonly      =>1,
                label         =>'AMLocation',
                dataobjattr   =>'am_location'),

      new kernel::Field::Number(
                name          =>'am_cpucount',
                group         =>'am',
                readonly      =>1,
                translation   =>'tsacinv::asset',
                label         =>'Asset CPU count',
                dataobjattr   =>'am_assetcpucount'),

      new kernel::Field::Text(
                name          =>'am_assetcputype',
                group         =>'am',
                readonly      =>1,
                translation   =>'tsacinv::asset',
                label         =>'Asset CPU Typ',
                dataobjattr   =>'am_assetcputype'),

      new kernel::Field::Number(
                name          =>'am_corecount',
                group         =>'am',
                readonly      =>1,
                translation   =>'tsacinv::asset',
                label         =>'Asset Core count',
                dataobjattr   =>'am_assetcorecount'),

      new kernel::Field::Number(
                name          =>'am_systemsonasset',
                group         =>'am',
                readonly      =>1,
                translation   =>'tsacinv::asset',
                label         =>'Systems on Asset',
                dataobjattr   =>'am_systemsonasset'),

      new kernel::Field::SubList(
                name          =>'am_adminlanip',
                label         =>'Admin-LAN IP',
                group         =>'am',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'tsacinv::ipaddress',
                vjoinon       =>['systemid'=>'systemid'],
                vjoinbase     =>{type=>"*ADMIN*FIRST*"},
                vjoindisp     =>[qw(fullname description type)],
                vjoininhash   =>[qw(ipaddress ipv4address ipv6address 
                                    description dnsname status)]),

      new kernel::Field::Boolean(
                name          =>'am_haveadminlan',
                group         =>'am',
                readonly      =>1,
                label         =>'have adminlan connect',
                depend        =>[qw(am_adminlanip)],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $ipl=$current->{am_adminlanip};
                   my $fld=$self->getParent->getField("am_adminlanip");
                   my $d=$fld->RawValue($current);
                   if (defined($d) && ref($d) eq "ARRAY" && $#{$d}!=-1){
                      return(1);
                   }
                   return(0);
                }),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Select(
                name          =>'ro_process',
                group         =>'rollout',
                value         =>['AUTOMATIC',
                                 'MANUEL',
                                 'OUT OF SCOPE'],
                label         =>'Rollout process',
                htmldetail    =>\&is_rolloutVisible,
                uppersearch   =>1,
                wrdataobjattr =>'rollout_process',
                dataobjattr   =>"decode(rollout_process,NULL,'AUTOMATIC',".
                                "rollout_process)"),

      new kernel::Field::Text(
                name          =>'ro_package',
                group         =>'rollout',
                label         =>'package',
                htmldetail    =>\&is_rolloutVisible,
                dataobjattr   =>'rollout_package'),

      new kernel::Field::Date(
                name          =>'ro_instplanned',
                dayonly       =>1,
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                label         =>'planned install date',
                dataobjattr   =>'rollout_instplanned'),

      new kernel::Field::Number(
                name          =>'ro_instplannedcw',
                unit          =>sub{
                   my $self=shift;
                   return($self->getParent->T("CW",$self->getParent->Self()));
                },
                group         =>'rollout',
                htmldeltail   =>'NotEmpty',
                readonly      =>1,
                label         =>'planned install CW',
                dataobjattr   =>'rollout_instplannedcw'),

      new kernel::Field::Boolean(
                name          =>'ro_ipv6',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                allowempty    =>1,
                label         =>'IPv6',
                dataobjattr   =>'rollout_ipv6'),

      new kernel::Field::Select(
                name          =>'ro_hpoaavail',
                group         =>'rollout',
                value         =>['online',
                                 'offline',
                                 'not_controlled'
                                 ],
                label         =>'HPOA available',
                useNullEmpty  =>1,
                allowempty    =>1,
                htmldetail    =>\&is_rolloutVisible,
                dataobjattr   =>"rollout_hpoaavail"),

      new kernel::Field::Boolean(
                name          =>'ro_itm6',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                allowempty    =>1,
                label         =>'ITM6 available',
                dataobjattr   =>'rollout_isitm6'),

      new kernel::Field::Boolean(
                name          =>'ro_hpsaavail',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                allowempty    =>1,
                label         =>'HPSA available',
                dataobjattr   =>'rollout_hpsaavail'),

      new kernel::Field::Boolean(
                name          =>'ro_tad4d',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                readonly      =>1,
                label         =>'TAD4D available',
                dataobjattr   =>'tad4d_is'),

      new kernel::Field::Boolean(
                name          =>'ro_tad4dsubcap',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                readonly      =>1,
                label         =>'TAD4D SubCapacity',
                dataobjattr   =>'tad4d_is_sub_cap'),

      new kernel::Field::Boolean(
                name          =>'ro_issungzone',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                allowempty    =>1,
                label         =>'is SUN global Zone',
                dataobjattr   =>'rollout_issungzone'),

      new kernel::Field::Boolean(
                name          =>'ro_rcrel',
                group         =>'rollout',
                htmldetail    =>\&is_rolloutVisible,
                allowempty    =>1,
                label         =>'Release-Container-Relevant',
                dataobjattr   =>'rollout_isrcrel'),


      new kernel::Field::Select(
                name          =>'ro_outofscope_reason',
                group         =>'rollout',
                value         =>['CHASSI',
                                 'CRYPTO',
                                 'GS',
                                 'STORAGE',
                                 'NETWORK',
                                 'OUTOFOP',
                                 'RETIERED',
                                 'ADS',
                                 'VDS',
                                 'TSG',
                                 'MAINFRAME',
                                 'MISC'
                                 ],
                label         =>'Out of Scope: reason',
                transprefix   =>'REASON.',
                useNullEmpty  =>1,
                allowempty    =>1,
                htmldetail    =>\&is_rolloutVisible,
                dataobjattr   =>"rollout_oos_reason"),


      new kernel::Field::Select(
                name          =>'ro_outofscope_ecluster',
                group         =>'rollout',
                value         =>['CONNECT',
                                 'ACCESS',
                                 'OFFLINE',
                                 'NOROUTE',
                                 'INANAL',
                                 'OUTOFOP',
                                 'COMPAT'
                                 ],
                label         =>'error cluster',
                transprefix   =>'ERRCLUST.',
                useNullEmpty  =>1,
                allowempty    =>1,
                htmldetail    =>\&is_rolloutVisible,
                dataobjattr   =>"rollout_oos_cluster"),



      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                readonly      =>1,
                label         =>'W5Base Application',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_applcustomerprio',
                group         =>'w5basedata',
                searchable    =>0,
                readonly      =>1,
                label         =>'W5Base Application Prio',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_applmgr',
                searchable    =>0,
                readonly      =>1,
                group         =>'w5basedata',
                label         =>'W5Base ApplicationManager',
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

      new kernel::Field::Text(
                name          =>'w5base_businessteam',
                searchable    =>0,
                readonly      =>1,
                group         =>'w5basedata',
                label         =>'W5Base Team',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_location',
                readonly      =>1,
                group         =>'w5basedata',
                translation   =>'itil::asset',
                label         =>'Location',
                dataobjattr   =>'w5_location'),

      new kernel::Field::Text(
                name          =>'w5base_osrelease',
                readonly      =>1,
                group         =>'w5basedata',
                translation   =>'itil::system',
                label         =>'OS-Release',
                dataobjattr   =>'w5_osrelease'),

      new kernel::Field::Text(
                name          =>'w5base_osclass',
                readonly      =>1,
                group         =>'w5basedata',
                translation   =>'itil::system',
                label         =>'OS-Class',
                dataobjattr   =>'w5_osclass'),


      new kernel::Field::Boolean(
                name          =>'isprod',
                group         =>'opmode',
                readonly      =>1,
                translation   =>'itil::system',
                htmlhalfwidth =>1,
                label         =>'Productionsystem',
                dataobjattr   =>'w5_isprod'),

      new kernel::Field::Boolean(
                name          =>'istest',
                group         =>'opmode',
                readonly      =>1,
                translation   =>'itil::system',
                htmlhalfwidth =>1,
                label         =>'Testsystem',
                dataobjattr   =>'w5_istest'),

      new kernel::Field::Boolean(
                name          =>'isdevel',
                group         =>'opmode',
                readonly      =>1,
                translation   =>'itil::system',
                htmlhalfwidth =>1,
                label         =>'Developmentsystem',
                dataobjattr   =>'w5_isdevel'),

      new kernel::Field::Boolean(
                name          =>'iseducation',
                group         =>'opmode',
                readonly      =>1,
                translation   =>'itil::system',
                htmlhalfwidth =>1,
                label         =>'Educationsystem',
                dataobjattr   =>'w5_iseducation'),

      new kernel::Field::Boolean(
                name          =>'isapprovtest',
                group         =>'opmode',
                readonly      =>1,
                translation   =>'itil::system',
                htmlhalfwidth =>1,
                label         =>'Approval/Integration System',
                dataobjattr   =>'w5_isapprovtest'),

      new kernel::Field::Boolean(
                name          =>'isreference',
                group         =>'opmode',
                readonly      =>1,
                translation   =>'itil::system',
                htmlhalfwidth =>1,
                label         =>'Referencesystem',
                dataobjattr   =>'w5_isreference'),


      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                history       =>0,
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser')
   );
   $self->{history}={
      update=>[
         'local'
      ],
      insert=>[
         'local'
      ]
   };

   $self->setWorktable("FLEXERAsup__system_of");
   $self->setDefaultView(qw(systemname systemid inflexera comments));
   return($self);
}

sub is_rolloutVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   return(1); # rollout soll doch IMMER sichtbar sein
   return(0) if (ref($param{current}) eq "HASH" && 
                 $param{current}->{inflexera});
   return(1);


}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="FLEXERAsup__system";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default rollout flexera am w5basedata opmode source));
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{id}};
   if (!defined($oldrec->{ofid})){     # flexerasystemid verwenden
      $newrec->{id}=$oldrec->{id};  # als Referenz in der Overflow die 
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;


   if (effVal($oldrec,$newrec,"ro_process") eq "" &&
       effVal($oldrec,$newrec,"comments") eq ""){
      $self->LastMsg(ERROR,"rollout process or comments needs to be specified");
      return(undef);
   }

   if (effChanged($oldrec,$newrec,"ro_process") &&
       $newrec->{ro_process} eq "OUT OF SCOPE"){
      if (effVal($oldrec,$newrec,"ro_outofscope_reason") eq ""){
         $self->LastMsg(ERROR,"no out of scope reason spezified");
         return(undef);
      }
   }
   if (effChanged($oldrec,$newrec,"ro_process") &&
       $newrec->{ro_process} ne "OUT OF SCOPE"){
      if (effVal($oldrec,$newrec,"ro_outofscope_reason") ne ""){
         $self->LastMsg(ERROR,
                     "out of scope reason not allowed in this rollout process");
         return(undef);
      }
   }
   if (effChanged($oldrec,$newrec,"ro_process") &&
       $oldrec->{ro_process} eq "AUTOMATIC" &&
       $newrec->{ro_process} eq "MANUEL"){
      if ($oldrec->{ro_outofscope_ecluster} ne ""){
         foreach my $var (qw(ro_instplanned 
                             ro_outofscope_ecluster 
                             ro_package)){
            if (!effChanged($oldrec,$newrec,$var)){
               $newrec->{$var}=undef;
            }
         }
      }
   }

   return(1);
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_saphier"))){
     Query->Param("search_saphier"=>
           "\"K001YT5ATS_ES.K001YT5A_DTIT\" \"K001YT5ATS_ES.K001YT5A_DTIT.*\" ".
           "\"YT5ATS_ES.YT5A_DTIT\" \"YT5ATS_ES.YT5A_DTIT.*\" ".
           "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
   }
#   if (!defined(Query->Param("search_inflexera"))){
#      Query->Param("search_inflexera"=>$self->T("no"));
#   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);


#   if (in_array(\@l,["ALL","default"])){
#      my $sys=$self->getPersistentModuleObject("w5sys","itil::system");
#      if (defined($sys) && $rec->{systemid} ne ""){
#         $sys->SecureSetFilter({systemid=>\$rec->{systemid}});
#         my ($rec,$msg)=$sys->getOnlyFirst(qw(id)); 
#         if (defined($rec)){
#            return(@l);
#         }
#      }
#
#      return(qw(header default source));
#   }
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


   #return("default","rollout") if ($#l!=-1 && defined($rec) && $rec->{inflexera} ne "1");
   return("default","rollout") if ($#l!=-1);
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
