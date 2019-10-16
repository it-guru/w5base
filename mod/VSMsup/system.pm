package VSMsup::system;
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

# -- drop table "W5I_VSMsup__system_of";

create table "W5I_VSMsup__system_of" (
   refid               varchar2(128) not null,
   networkarea         varchar2(80),
   networkclass        varchar2(80),
   networktype         varchar2(80),
   networkcomment      varchar2(4000),
   vsmlink             varchar2(4000),
   vsmpartition        varchar2(80),
   deviceip            varchar2(45),
   deviceplattform     varchar2(80),
   devicetype          varchar2(80),
   modifyuser          number(*,0),
   modifydate          date,
   constraint "W5I_VSMsup__system_of_pk" primary key (refid)
);

grant select,update,insert on "W5I_VSMsup__system_of" to W5I;
grant select on "W5I_VSMsup__system_of" to W5_BACKUP_D1;
grant select on "W5I_VSMsup__system_of" to W5_BACKUP_W1;

create or replace synonym W5I.VSMsup__system_of for "W5I_VSMsup__system_of";

create table "W5I_VSMsup__locmap_of" (
   "am_standort"       varchar2(128) not null,
   "vsm_standort"      varchar2(128),
   constraint "W5I_VSMsup__locmap_of_pk" primary key ("am_standort")
);
grant select,update,insert,delete on "W5I_VSMsup__locmap_of" to W5I;
grant select on "W5I_VSMsup__locmap_of" to W5_BACKUP_D1;
grant select on "W5I_VSMsup__locmap_of" to W5_BACKUP_W1;
create or replace synonym W5I.VSMsup__locmap_of for "W5I_VSMsup__locmap_of";


create or replace view "W5I_VSMsup__system" as
with schain as (
select 'SCHAIN-'|| "tsacinv::schain".schainid ||'-'||
                   "tsacinv::lnkschain".itemid entryid,
       "tsacinv::schain".fullname servicegroup,
       "tsacinv::lnkschain".itemid systemid
from "tsacinv::schain"
   join "tsacinv::lnkschain"
      on "tsacinv::schain".schainid="tsacinv::lnkschain".lsspid
where "tsacinv::schain".fullname like 'TEL-IT_%'
   and "tsacinv::lnkschain".class='LOGICAL SYSTEM'
order by "tsacinv::schain".fullname,"tsacinv::lnkschain".itemid)

select schain.entryid                                id,
       schain.servicegroup                           servicegroup,
       lower("tsacinv::system".systemname)           vsm_devicename,
       decode(
          "W5I_VSMsup__locmap_of"."vsm_standort",
          NULL,'???',
          "W5I_VSMsup__locmap_of"."vsm_standort")    vsm_location,
       schain.systemid                               systemid,
       "tsacinv::location".fullname                  am_asset_location,
       "tsacinv::system".status                      am_status,
       "tsacinv::system".systemname                  am_systemname,
       "tsacinv::system".customerlink                am_customerlink,
       "tsacinv::system".usage                       am_usage,
       regexp_substr(
          "tsacinv::location".fullname,
          '([^/]+)/',1,1,NULL,1)                     am_location,
       regexp_substr(
          "tsacinv::location".fullname,
          '([^/]+)/',1,2,NULL,1)                     am_facility,
       regexp_substr(
          "tsacinv::location".fullname,
          '([^/]+)/',1,3,NULL,1)                     am_floor,
       regexp_substr(
          "tsacinv::location".fullname,
          '([^/]+)/',1,4,NULL,1)                     am_chassis,
       "tsacinv::asset".modelname                    am_model,
       "tsacinv::model".vendor                       am_vendor,
       "tsacinv::asset".serialno                     am_serialno,
       "tsacinv::asset".assetid                      am_assetid,
       "W5I_VSMsup__system_of".refid                 of_id,
       decode("W5I_VSMsup__system_of".networkarea,
              NULL,'LAN',
              "W5I_VSMsup__system_of".networkarea)   networkarea,
       decode("W5I_VSMsup__system_of".networkclass,
              NULL,'NET',
              "W5I_VSMsup__system_of".networkclass)  networkclass,
       "W5I_VSMsup__system_of".networktype           networktype,
       "W5I_VSMsup__system_of".networkcomment        networkcomment,
       "W5I_VSMsup__system_of".vsmlink               vsmlink,
       "W5I_VSMsup__system_of".vsmpartition          vsmpartition,
       "W5I_VSMsup__system_of".deviceip              deviceip,
       "W5I_VSMsup__system_of".deviceplattform       deviceplattform,
       "W5I_VSMsup__system_of".devicetype            devicetype,
       "W5I_VSMsup__system_of".modifydate            modifydate,
       "W5I_VSMsup__system_of".modifyuser            modifyuser
from schain
   join "tsacinv::system"
      on schain.systemid="tsacinv::system".systemid
   join "tsacinv::asset"
      on "tsacinv::system".assetassetid="tsacinv::asset".assetid
   join "tsacinv::location"
      on "tsacinv::asset".locationid="tsacinv::location".locationid
   join "tsacinv::asset"
       on "tsacinv::system".assetassetid="tsacinv::asset".assetid
   join "tsacinv::model"
       on "tsacinv::asset".lmodelid="tsacinv::model".lmodelid
   left outer join "W5I_VSMsup__locmap_of"
      on regexp_substr("tsacinv::location".fullname,'([^/]+)/',1,1,NULL,1)=
         "W5I_VSMsup__locmap_of"."am_standort"
   left outer join "W5I_VSMsup__system_of"
      on schain.entryid="W5I_VSMsup__system_of".refid;


grant select on "W5I_VSMsup__system" to W5I;
create or replace synonym W5I.VSMsup__system for "W5I_VSMsup__system";



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
                name          =>'devicename',
                label         =>'Devicename',
                lowersearch   =>1,
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'vsm_devicename'),

      new kernel::Field::Text(
                name          =>'servicegroup',
                label         =>'Service-Group',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'servicegroup'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                selectfix     =>1,
                readonly      =>1,
                dataobjattr   =>'systemid'),


      new kernel::Field::Text(
                name          =>'vsmlocation',
                label         =>'VSM Location',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'vsm_location'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Select(
                name          =>'vsmnetworkarea',
                label         =>'Network Area',
                value         =>[qw(LAN WAN Storage)],
                dataobjattr   =>'networkarea'),

      new kernel::Field::Select(
                name          =>'vsmnetworkclass',
                label         =>'Network Class',
                value         =>["NET","Application","Central Services",
                                 "FW","LB","NAS","SAN"],
                dataobjattr   =>'networkclass'),

      new kernel::Field::Text(
                name          =>'vsmnetworktype',
                label         =>'Network Type',
                dataobjattr   =>'networktype'),

      new kernel::Field::Text(
                name          =>'vsm_link',
                label         =>'VSM Link',
                dataobjattr   =>'vsmlink'),

      new kernel::Field::Text(
                name          =>'vsm_partition',
                label         =>'VSM Partition',
                dataobjattr   =>'vsmpartition'),

      new kernel::Field::Text(
                name          =>'vsmdeviceip',
                label         =>'VSM Device IP',
                dataobjattr   =>'deviceip'),

      new kernel::Field::Text(
                name          =>'vsmdeviceplattform',
                label         =>'VSM Device Plattform',
                dataobjattr   =>'deviceplattform'),

      new kernel::Field::Text(
                name          =>'vsmdeviceplattform',
                label         =>'VSM Device Plattform',
                dataobjattr   =>'deviceplattform'),

      new kernel::Field::Text(
                name          =>'vsmdevicetype',
                label         =>'VSM Device Type',
                dataobjattr   =>'devicetype'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Network Comments',
                dataobjattr   =>'networkcomment'),

      new kernel::Field::Text(
                name          =>'amsystemid',
                label         =>'SystemID',
                group         =>'am',
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'amstatus',
                label         =>'Status',
                group         =>'am',
                dataobjattr   =>'am_status'),

      new kernel::Field::Text(
                name          =>'amassetid',
                label         =>'AssetID',
                group         =>'am',
                dataobjattr   =>'am_assetid'),

      new kernel::Field::Text(
                name          =>'amassetlocation',
                label         =>'Asset Location',
                group         =>'am',
                dataobjattr   =>'am_asset_location'),

      new kernel::Field::Text(
                name          =>'amserialno',
                label         =>'SerialNo',
                group         =>'am',
                dataobjattr   =>'am_serialno'),

      new kernel::Field::Text(
                name          =>'ammodel',
                label         =>'Model',
                group         =>'am',
                dataobjattr   =>'am_model'),

      new kernel::Field::Text(
                name          =>'amvendor',
                label         =>'Vendor',
                group         =>'am',
                dataobjattr   =>'am_vendor'),

      new kernel::Field::Text(
                name          =>'amcustomerlink',
                label         =>'CustomerLink',
                group         =>'am',
                dataobjattr   =>'am_customerlink'),

      new kernel::Field::Text(
                name          =>'amusage',
                label         =>'Usage',
                group         =>'am',
                dataobjattr   =>'am_usage'),

      new kernel::Field::Text(
                name          =>'amlocation',
                label         =>'Location',
                group         =>'amlocation',
                dataobjattr   =>'am_location'),

      new kernel::Field::Text(
                name          =>'amfacility',
                label         =>'Facility',
                group         =>'amlocation',
                dataobjattr   =>'am_facility'),

      new kernel::Field::Text(
                name          =>'amfloor',
                label         =>'Floor',
                group         =>'amlocation',
                dataobjattr   =>'am_floor'),

      new kernel::Field::Text(
                name          =>'amchassis',
                label         =>'Chassis',
                group         =>'amlocation',
                dataobjattr   =>'am_chassis'),


      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                readonly      =>1,
                label         =>'W5Base Application',
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

   $self->setWorktable("VSMsup__system_of");
   $self->setDefaultView(qw(servicegroup devicename systemid vsmlocation comments));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="VSMsup__system";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default am amlocation w5basedata source));
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


#sub initSearchQuery
#{
#   my $self=shift;
##   if (!defined(Query->Param("search_inflexera"))){
##      Query->Param("search_inflexera"=>$self->T("no"));
##   }
#}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return(undef) if (!$self->IsMemberOf("admin") &&
                     !$self->IsMemberOf("membergroup.VSM-Support-Tool.read") &&
                     !$self->IsMemberOf("membergroup.VSM-Support-Tool.write"));

   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/) &&
                     !($rec->{systemid}=~m/^\d{14,20}$/));


   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->IsMemberOf("membergroup.VSM-Support-Tool.write"));

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
