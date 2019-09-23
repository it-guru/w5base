package secscan::finding;
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
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

=head1

#
# Generierung der Support-Views in der pw5repo Kennung


create or replace view "W5I_secscan__findingbase" as
   select  'OpSha-' || "w5secscan_ShareData"."W5_id"          as id,
           "w5secscan_ShareData"."W5_isdel"                   as isdel,
           "w5secscan_ShareData"."W5_keyid"                   as keyid,
           "w5secscan_ShareData"."C01_SecToken"               as sectoken,
           "w5secscan_ShareData"."C05_SecItem"                as secitem,
           "w5secscan_ShareData"."C04_TreatRules"             as sectreadrules,
           TO_DATE("w5secscan_ShareData"."C02_ScanDate",
                   'YYYY-MM-DD HH24:MI:SS')                   as fndscandate,
           "w5secscan_ShareData"."W5_cdate"                   as fndcdate,
           "w5secscan_ShareData"."W5_mdate"                   as fndmdate,
           LOWER(REPLACE(REGEXP_SUBSTR(
                 "w5secscan_ShareData"."C03_HostName",
                 '^.*?\.'),'.',''))                           as hostname,
           "W5FTPGW1"."w5secscan_ShareData"."C03_HostName"    as fqdns,
           "w5secscan_ComputerIP"."C02_IPAddress"             as ipaddr,
           'Share=' || "w5secscan_ShareData"."C06_ShareName" || 
            chr(10) ||
           'Files=' || "w5secscan_ShareData"."C09_foundFiles" ||
            chr(10) ||
           'Items=' || "w5secscan_ShareData"."C08_foundItems" as detailspec,
           'w5sharescan'                                      as srcsys,
           "w5secscan_ShareData"."W5_id"                      as srcid
   from "W5FTPGW1"."w5secscan_ShareData"
      join "W5FTPGW1"."w5secscan_ComputerIP"
         on "w5secscan_ComputerIP"."C01_NetComputer"=
            "w5secscan_ShareData"."C03_HostName"
union
   select  'Once-' || "w5secscan_OneShot"."W5_id"             as id,
           "w5secscan_OneShot"."W5_isdel"                     as isdel,
           "w5secscan_OneShot"."W5_keyid"                     as keyid,
           "w5secscan_OneShot"."C01_SecToken"                 as sectoken,
           "w5secscan_OneShot"."C05_SecItem"                  as secitem,
           "w5secscan_OneShot"."C04_TreatRules"               as sectreadrules,
           TO_DATE("w5secscan_OneShot"."C02_ScanDate",
                   'YYYY-MM-DD HH24:MI:SS')                   as fndscandate,
           "w5secscan_OneShot"."W5_cdate"                     as fndcdate,
           "w5secscan_OneShot"."W5_mdate"                     as fndmdate,
           NULL                                               as hostname,
           NULL                                               as fqdns,
           "w5secscan_OneShot"."C03_IPAddress"                as ipaddr,
           "w5secscan_OneShot"."C07_SecDetailSpec"            as detailspec,
           'OneShot'                                          as srcsys,
           "w5secscan_OneShot"."W5_id"                        as srcid
   from "W5FTPGW1"."w5secscan_OneShot"
union
   select  'BK-' || "w5secscan_BlueKeepRDP"."W5_id"           as id,
           "w5secscan_BlueKeepRDP"."W5_isdel"                 as isdel,
           "w5secscan_BlueKeepRDP"."W5_keyid"                 as keyid,
           "w5secscan_BlueKeepRDP"."C01_SecToken"             as sectoken,
           "w5secscan_BlueKeepRDP"."C05_SecItem"              as secitem,
           "w5secscan_BlueKeepRDP"."C04_TreatRules"           as sectreadrules,
           TO_DATE("w5secscan_BlueKeepRDP"."C02_ScanDate",
                   'YYYY-MM-DD HH24:MI:SS')                   as fndscandate,
           "w5secscan_BlueKeepRDP"."W5_cdate"                 as fndcdate,
           "w5secscan_BlueKeepRDP"."W5_mdate"                 as fndmdate,
           NULL                                               as hostname,
           NULL                                               as fqdns,
           "w5secscan_BlueKeepRDP"."C03_IPAddress"            as ipaddr,
           'found on '||"w5secscan_BlueKeepRDP"."C03_IPAddress"
                                                              as detailspec,
           'BlueKeepRDP'                                      as srcsys,
           "w5secscan_BlueKeepRDP"."W5_id"                    as srcid
   from "W5FTPGW1"."w5secscan_BlueKeepRDP"
union
   select  'OP-' || "w5secscan_OpenProxy"."W5_id"           as id,
           "w5secscan_OpenProxy"."W5_isdel"                 as isdel,
           "w5secscan_OpenProxy"."W5_keyid"                 as keyid,
           "w5secscan_OpenProxy"."C01_SecToken"             as sectoken,
           "w5secscan_OpenProxy"."C05_SecItem"              as secitem,
           "w5secscan_OpenProxy"."C04_TreatRules"           as sectreadrules,
           TO_DATE("w5secscan_OpenProxy"."C02_ScanDate",
                   'YYYY-MM-DD HH24:MI:SS')                 as fndscandate,
           "w5secscan_OpenProxy"."W5_cdate"                 as fndcdate,
           "w5secscan_OpenProxy"."W5_mdate"                 as fndmdate,
           NULL                                             as hostname,
           NULL                                             as fqdns,
           "w5secscan_OpenProxy"."C03_IPAddress"            as ipaddr,
           'Port='||"w5secscan_OpenProxy"."C07_ProxyPort"||
           chr(10) ||
           'GatewayIP='||
           "w5secscan_OpenProxy"."C08_GatewayIP"            as detailspec,
           'OpenProxy'                                      as srcsys,
           "w5secscan_OpenProxy"."W5_id"                    as srcid
   from "W5FTPGW1"."w5secscan_OpenProxy";


create table "W5I_secscan__finding_of" (
   refid               varchar2(80) not null,
   comments            varchar2(4000),
   wfhandeled          number(*,0) default '0',
   wfref               varchar2(256),
   wfheadid            varchar2(20),
   hstate              varchar2(20) default 'AUTOANALYSED',
   respemail           varchar2(128),
   modifyuser          number(*,0),
   modifydate          date,
   constraint "W5I_secscan_finding_of_pk" primary key (refid)
);

grant select,update,insert,delete on "W5I_secscan__finding_of" to W5I;
create or replace synonym W5I.secscan__finding_of for "W5I_secscan__finding_of";


create or replace view "W5I_secscan__finding" as
select "W5I_secscan__findingbase".id,
       "W5I_secscan__findingbase".keyid,
       "W5I_secscan__findingbase".isdel,
       "W5I_secscan__findingbase".sectoken,
       "W5I_secscan__findingbase".secitem,
       "W5I_secscan__findingbase".sectreadrules,
       "W5I_secscan__findingbase".fndscandate,
       "W5I_secscan__findingbase".fndcdate,
       "W5I_secscan__findingbase".fndmdate,
       "W5I_secscan__findingbase".hostname,
       "W5I_secscan__findingbase".fqdns,
       "W5I_secscan__findingbase".ipaddr,
       "W5I_secscan__findingbase".detailspec,
       "W5I_secscan__findingbase".srcsys,
       "W5I_secscan__findingbase".srcid,
       "W5I_secscan__finding_of".refid of_id,
       "W5I_secscan__finding_of".comments,
       decode("W5I_secscan__finding_of".wfhandeled,
              NULL,'0',"W5I_secscan__finding_of".wfhandeled) wfhandeled,
       "W5I_secscan__finding_of".wfref,
       "W5I_secscan__finding_of".hstate,
       "W5I_secscan__finding_of".wfheadid,
       "W5I_secscan__finding_of".respemail,
       "W5I_secscan__finding_of".modifyuser,
       "W5I_secscan__finding_of".modifydate
from "W5I_secscan__findingbase"
     left outer join "W5I_secscan__finding_of"
        on "W5I_secscan__findingbase".keyid=
           "W5I_secscan__finding_of".refid;


grant select on "W5I_secscan__finding" to W5I;
create or replace synonym W5I.secscan__finding for "W5I_secscan__finding";


=cut

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();
   $self->{use_distinct}=0;

   
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
                name          =>'name',
                label         =>'Security Token',
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'sectoken'),

      new kernel::Field::Text(
                name          =>'hstate',
                label         =>'handling state',
                default       =>'Waiting for analyse...',
                nowrap        =>1,
                readonly      =>1,
                selectfix     =>1,
                dataobjattr   =>'hstate'),

      new kernel::Field::Number(
                name          =>'recuperation',
                label         =>'Security Token Recuperation Count',
                readonly      =>1,
                sqlorder      =>'NONE',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"decode(isdel,'0',".
                                "(select decode(count(*),'0',NULL,count(*)) ".
                                " from secscan__finding s ".
                                " where ".
                                " secscan__finding.sectoken=s.sectoken and ".
                                " isdel='1')".
                                ",NULL)" 
                ),

      new kernel::Field::Boolean(
                name          =>'isdel',
                group         =>'source',
                label         =>'marked as deleted',
                dataobjattr   =>'isdel'),

      new kernel::Field::Text(
                name          =>'secitem',
                label         =>'SecurityItem',
                group         =>'source',
                selectfix     =>1,
                readonly      =>1,
                dataobjattr   =>'secitem'),

      new kernel::Field::Text(
                name          =>'sectreadrules',
                label         =>'TreadRules',
                group         =>'source',
                selectfix     =>1,
                readonly      =>1,
                dataobjattr   =>'sectreadrules'),

      new kernel::Field::Date(
                name          =>'findscandate',
                sqlorder      =>'desc',
                label         =>'Scan-Date',
                dataobjattr   =>'fndscandate'),

      new kernel::Field::Date(
                name          =>'findcdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Create-Date',
                dataobjattr   =>'fndcdate'),

      new kernel::Field::Text(
                name          =>'hostname',
                label         =>'Systemname',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'hostname'),

      new kernel::Field::Text(
                name          =>'fqdns',
                label         =>'fullqualified DNS',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'fqdns'),

      new kernel::Field::Text(
                name          =>'ipaddr',
                label         =>'IP-Address',
                dataobjattr   =>'ipaddr'),


      new kernel::Field::Textarea(
                name          =>'itemrawdesc',
                label         =>'Security Finding Item Desc',
                readonly      =>1,
                uivisible     =>0,
                vjointo       =>\'secscan::item',
                vjoinon      =>['secitem'=>'name'],
                vjoindisp     =>'description'),


      new kernel::Field::Textarea(
                name          =>'spec',
                readonly      =>1,
                label         =>'Specification',
                searchable    =>0,
                depend        =>[qw(itemrawdesc secitem detailspec)],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent;
                   my $i=$self->getParent->getField(
                         "itemrawdesc");
                   my $dsc=$i->RawValue($current);
                   my $lang=$self->getParent->Lang();
                   $dsc=extractLangEntry($dsc,
                                         $lang,65535,65535);
                   my $d=$self->getParent->getField(
                         "detailspec");
                   my $detaildescription=
                         $d->RawValue($current);
                   return($dsc.
                          "\n".
                          $detaildescription);
                }),

      new kernel::Field::Textarea(
                name          =>'detailspec',
                htmldetail    =>0,
                readonly      =>1,
                selectfix     =>1,
                label         =>'Detail-Spec',
                dataobjattr   =>'detailspec'),

      new kernel::Field::Date(
                name          =>'findmdate',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'fndmdate'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Select(
                name          =>'mhstate',
                group         =>'handling',
                label         =>'handling state',
                searchable    =>0,
                value         =>[qw(NOTAUTOHANDLED 
                                    MANUELRESPCONT
                                    GOTMANUELOK)],
                dataobjattr   =>'hstate'),

      new kernel::Field::Email(
                name          =>'respemail',
                group         =>'handling',
                label         =>'desired E-Mail responsible',
                dataobjattr   =>'respemail'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'handling',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Boolean(
                name          =>'wfhandeled',
                group         =>'wfhandling',
                readonly      =>1,
                label         =>'Workflow in process',
                dataobjattr   =>'wfhandeled'),
                #
                # wfhandeled gibt an, ob das finding mit einem Workflow in
                # Darwin "gekoppelt" ist. Wenn ein finding gelöscht markiert
                # wurde, kann es bis zu 14 Tage dauern, bis es "entkoppelt"
                # wird. Die wfref bleibt beim Entkoppeln aber vorhanden.
                #

      new kernel::Field::TextURL(
                name          =>'wfref',
                group         =>'wfhandling',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Workflow',
                dataobjattr   =>'wfref'),

      new kernel::Field::Text(
                name          =>'wfheadid',
                group         =>'wfhandling',
                readonly      =>1,
                htmldetail    =>'0',
                selectfix     =>1,
                label         =>'WfHeadID',
                dataobjattr   =>'wfheadid'),

      new kernel::Field::Import($self,
                vjointo       =>\'base::workflow',
                vjoinon       =>['wfheadid'=>'id'],
                group         =>"wfhandling",
                htmldetail    =>'NotEmpty',
                weblinkto     =>"NONE",
                fields        =>[qw(name state)]),

      new kernel::Field::Text(
                name          =>'findingstatus',
                group         =>'wfhandling',
                readonly      =>1,
                label         =>'current Workflow result',
                onRawValue    =>\&getFindingState),

#      new kernel::Field::Text(
#                name          =>'wfname',
#                group         =>'wfhandling',
#                vjointo       =>'base::workflow',
#                vjoinon       =>['wfheadid'=>'id'],
#                vjoindisp     =>'name',
#                weblinkto     =>"NONE",
#                readonly      =>1,
#                htmldetail    =>'NotEmpty',
#                label         =>'Workflow Name'),
#
#      new kernel::Field::Text(
#                name          =>'wfstate',
#                group         =>'wfhandling',
#                vjointo       =>'base::workflow',
#                vjoinon       =>['wfheadid'=>'id'],
#                vjoindisp     =>'state',
#                weblinkto     =>"NONE",
#                readonly      =>1,
#                htmldetail    =>'NotEmpty',
#                label         =>'Workflow State'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'handlingsource',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::SubList(
                name          =>'recuphist',
                label         =>'Recuperation History',
                group         =>'recup',
                depend        =>['recuperation'],
                htmldetail    =>sub{
                                  my $self=shift;
                                   my $mode=shift;
                                   my %param=@_;
                                   if (defined($param{current})){
                                      my $d=$param{current}->{recuperation};
                                      return(1) if ($d ne "" && $d>0);
                                   }
                                   return(0);
                                },
                searchable    =>0,
                vjointo       =>'secscan::finding',
                vjoinon       =>['name'=>'name'],
                vjoinbase     =>{isdel=>'1'},
                vjoindisp     =>['startdate','enddate'],
                vjoininhash   =>['id','startdate','enddate']),


      new kernel::Field::Owner(
                name          =>'owner',
                history       =>0,
                group         =>'handlingsource',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser'),

      new kernel::Field::Date(
                name          =>'startdate',
                sqlorder      =>'desc',
                group         =>'source',
                htmldetail    =>'0',
                label         =>'Start-Date',
                dataobjattr   =>'fndcdate'),

      new kernel::Field::Date(
                name          =>'enddate',
                group         =>'handlingsource',
                htmldetail    =>'0',
                sqlorder      =>'desc',
                label         =>'End-Date',
                dataobjattr   =>'fndmdate'),


      new kernel::Field::Text(
                name          =>'sectokenid',
                label         =>'Security Token ID',
                size          =>'16',
                group         =>'source',
                readonly      =>1,
                dataobjattr   =>'keyid'),

      new kernel::Field::Text(
                name          =>'srcsys',
                selectfix     =>1,
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'srcid')
   );
   $self->{history}={
      update=>[
         'local'
      ],
      insert=>[
         'local'
      ]
   };

   $self->setWorktable("secscan__finding_of");
   $self->setDefaultView(qw(findcdate name hstate secitem comments));
   return($self);
}


sub getFindingState
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   if (defined($current) &&
       $current->{wfheadid} ne ""){
      my $wf=$app->getPersistentModuleObject("wf","base::workflow");
      $wf->SetFilter({id=>\$current->{wfheadid}});
      my ($WfRec)=$wf->getOnlyFirst(qw(ALL));
      if (defined($WfRec)){
         my $fld=$wf->getField("wffields.secfindingstate",$WfRec);
         if (defined($fld)){
            my $d=$fld->FormatedResult($WfRec,"HtmlV01");
            return($d);
         }
      }
   }
   return(undef);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="secscan__finding";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default recup wfhandling handling handlingsource source));
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   if ($newrec->{mhstate} eq "NOTAUTOHANDLED" &&
       $newrec->{respemail} ne ""){
      $newrec->{mhstate}="MANUELRESPCONT";
   }


   $filter[0]={id=>\$oldrec->{sectokenid}};
   if (!defined($oldrec->{ofid})){ 
      $newrec->{id}=$oldrec->{sectokenid}; 
      if ($newrec->{hstate} ne "AUTOANALYSED" &&
          $newrec->{hstate} ne "MANUELRESPCONT" &&
          $newrec->{hstate} ne "NOTAUTOHANDLED"){
         $newrec->{hstate}="TOUCHED";
      }
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
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_isdel"))){
     Query->Param("search_isdel"=>"\"".$self->T("no")."\"");
   }

#   if (!defined(Query->Param("search_findcdate"))){
#     Query->Param("search_findcdate"=>">now-14d");
#   }

}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->IsMemberOf(["admin",
                          "w5base.secscan.read",
                          "w5base.secscan.write"])){
      my @l=qw(source handlingsource default header recup);
      if ($rec->{wfheadid} ne ""){
         push(@l,"wfhandling");
      }
      else{
         if ($rec->{hstate} ne ""){
            push(@l,"handling");
         }
      }
      
      return(@l);
   }
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   if ($self->IsMemberOf(["admin",
                          "w5base.secscan.write"])){
      return("handling");
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->IsMemberOf("admin")){
      return(1);
   }
   return(0);
}


sub getDeleteRecordFilter
{
   my $self=shift;
   my $oldrec=shift;

   my $idname=$self->IdField->Name();
   my $dropid=$oldrec->{$idname};
   if (!defined($dropid)){
      $self->LastMsg(ERROR,"can't delete record without unique id in $idname");
      return;
   }
   my $sectokenid=$oldrec->{sectokenid};
   if (!defined($sectokenid)){
      $self->LastMsg(ERROR,"can't delete record without sectokenid in $idname");
      return;
   }

   my @flt=({$self->IdField->Name()=>$sectokenid});
   return(@flt);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
