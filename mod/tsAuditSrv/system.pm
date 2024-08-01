package tsAuditSrv::system;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>"(DARWIN_TBL_ASSET_DATA.SYSTEM_NAME||".
                                "' ('||DARWIN_TBL_ASSET_DATA.SYSTEM_ID||')')"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'DARWIN_TBL_ASSET_DATA.SYSTEM_NAME'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'default',
                htmllabelwidth=>'250',
                searchable    =>1,
                uppersearch   =>1,
                dataobjattr   =>"DARWIN_TBL_ASSET_DATA.SYSTEM_ID"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                htmllabelwidth=>'250',
                ignorecase    =>1,
                dataobjattr   =>'DARWIN_TBL_ASSET_DATA.ASSET_ID'),


      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'DARWIN_TBL_ASSET_DATA.SYSTEM_STATUS'),

      new kernel::Field::Boolean(
                name          =>'registered',
                selectfix     =>1,
                label         =>'Auditserver registered',
                dataobjattr   =>"decode(AUDITSERVER_REGISTRATED,'YES',1,0)"),

      new kernel::Field::Text(
                name          =>'w5applications',
                label         =>'W5Base/Application',
                group         =>'w5basedata',
                vjointo       =>\'itil::lnkapplsystem',
                vjoinslimit   =>'1000',
                vjoinon       =>['w5systemid'=>'systemid'],
                weblinkto     =>'none',
                vjoindisp     =>'appl'),

      new kernel::Field::SubList(
                name          =>'urgentauditmsgs',
                label         =>'urgent audit messages',
                group         =>'auditmsgs',
                vjointo       =>'tsAuditSrv::auditmsg',
                htmllimit     =>30,
                searchable    =>0,
                forwardSearch =>1,
                vjoinbase     =>{'excluded'=>'0',severity=>'>0'},
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>['severity','firstoccur',
                                 'messagetext','resultreturnedshorted']),

      new kernel::Field::SubList(
                name          =>'auditmsgs',
                label         =>'Audit messages',
                group         =>'auditmsgs',
                vjointo       =>'tsAuditSrv::auditmsg',
                htmldetail    =>0,
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>['severity','firstoccur',
                                 'messagetext','resultreturnedshorted']),

      new kernel::Field::SubList(
                name          =>'inventmsgs',
                label         =>'Inventory messages',
                group         =>'inventmsgs',
                vjointo       =>'tsAuditSrv::inventmsg',
                htmldetail    =>0,
                htmllimit     =>30,
                vjoinon       =>['nodeid'=>'nodeid'],
                vjoindisp     =>['messagetext','resultreturned']),

      new kernel::Field::SubList(
                name          =>'files',
                label         =>'Audit Files',
                group         =>'auditfiles',
                vjointo       =>\'tsAuditSrv::auditfile',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>['filename','mdate']),

      new kernel::Field::Text(
                name          =>'patchstatus',
                label         =>'Patch Status',
                group         =>'audit',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.PATCH_STATUS'),

      new kernel::Field::Text(
                name          =>'days_not_patched',
                label         =>'Missing Patch released x days ago',
                htmldetail    =>'NotEmpty',
                group         =>'audit',
                searchable    =>0,
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.DAYS_NOT_PATCHED'),

      new kernel::Field::Text(
                name          =>'cstatus',
                label         =>'Compliance Status',
                group         =>'audit',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.COMPLIANCE_STATUS'),

      new kernel::Field::Text(
                name          =>'red_alert',
                label         =>'Red Alert',
                group         =>'audit',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.red_alert'),

      new kernel::Field::Text(
                name          =>'reactionlevel',
                label         =>'Reaction Level',
                group         =>'audit',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.reaction_level'),

      new kernel::Field::Text(
                name          =>'osversion',
                label         =>'OS version',
                group         =>'autodiscdata',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"(select result_returned from ".
                                "darwin_inventory_data where ".
                                "darwin_inventory_data.node_id=".
                                "darwin_system_status.node_id and ".
                                "darwin_inventory_data.message_text_en=".
                                "'OS version' and ".
                                "ROWNUM=1)"),

      new kernel::Field::Text(
                name          =>'operatingsystem',
                label         =>'operating system',
                group         =>'autodiscdata',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"(select result_returned from ".
                                "darwin_inventory_data where ".
                                "darwin_inventory_data.node_id=".
                                "darwin_system_status.node_id and ".
                                "darwin_inventory_data.message_text_en=".
                                "'operating system' and ".
                                "ROWNUM=1)"),


      new kernel::Field::Text(
                name          =>'nodeid',
                label         =>'NodeID',
                selectfix     =>1,
                group         =>'source',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.NODE_ID'),


      new kernel::Field::Text(
                name          =>'psource',
                label         =>'Patch Source',
                group         =>'source',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.patch_source'),

      new kernel::Field::Date(
                name          =>'pcalcdate',
                label         =>'Patch Calculation Date',
                timezone      =>'CET', 
                group         =>'source',
                dataobjattr   =>'DARWIN_SYSTEM_STATUS.patch_calculation_dat'),


      new kernel::Field::Link(
                name          =>'w5systemid',
                label         =>'W5BaseID of relevant System',
                group         =>'w5basedata',
                vjointo       =>\'itil::system',
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



   );
   $self->setWorktable("DARWIN_TBL_ASSET_DATA");
   $self->setDefaultView(qw(systemid systemname status 
                            registered patchstatus cstatus psource));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="DARWIN_TBL_ASSET_DATA ".
            "LEFT OUTER JOIN DARWIN_SYSTEM_STATUS on ".
            "DARWIN_TBL_ASSET_DATA.SYSTEM_ID=DARWIN_SYSTEM_STATUS.SYSTEM_ID";

   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="";

   my $userid=$self->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->IsMemberOf([qw(admin 
                                 w5base.tsAuditSrv.read
                              )],
          "RMember")){
         my @systemid=$self->getSecurityRestrictedAllowedSystemIDs(20);
         if ($#systemid>-1){
            my @secsystemid;
            #needed to fix ora "in" limits
            while (my @sid=splice(@systemid,0,500)){
               push(@secsystemid,"DARWIN_TBL_ASSET_DATA.SYSTEM_ID in (".
                                 join(",",map({"'".$_."'"} @sid)).")");
            }
            $where="(".join(" OR ",@secsystemid).")";
         }
         else{
            $where="(1=0)";
         }
      }
      if ($self->IsMemberOf([qw(w5base.tsAuditSrv.read)])){
         $where.=" AND " if ($where ne "");
         $where.=" (CUSTOMER like 'DTAG.%' ".
                 "or CUSTOMER like 'Deutsche Telekom%')";
      }
   }

   return($where);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!out of operation\"");
   }
   if (!defined(Query->Param("search_registered"))){
     Query->Param("search_registered"=>$self->T("yes"));
   }
}




sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   my @l=qw(default);

   if ($rec->{registered}){
      push(@l,"audit","auditmsgs","inventmsgs","autodiscdata",
              "auditfiles","w5basedata","source");
   }

   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   return(undef);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default autodiscdata 
             inventmsgs auditmsgs audit auditfiles w5basedata source));
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsAuditSrv"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}




1;
