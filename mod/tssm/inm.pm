package tssm::inm;
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
use tssm::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tssm::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Id(
                name          =>'incidentnumber',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'Incident No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>SELpref.'probsummarym1.dh_number'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'probsummarym1.brief_description'),

      new kernel::Field::Link(
                name          =>'rawname',
                label         =>'Brief Description',
                dataobjattr   =>SELpref.'probsummarym1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>20,
                dataobjattr   =>SELpref.'probsummarym1.status'),

##      new kernel::Field::Text(
##                name          =>'softwareid',
##                label         =>'SoftwareID',
##                dataobjattr   =>'probsummarym1.tsi_main_ci_sw_name'),

      new kernel::Field::Text(
                name          =>'deviceid',
                label         =>'DeviceID',
                dataobjattr   =>SELpref.'probsummarym1.logical_name'),

     new kernel::Field::Text(
                name          =>'dstobj',
                group         =>'amdst',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'AMObj',
                dataobjattr   =>
                     tssm::lib::io::getAMObjDecode( SELpref."device2m1.type")),

      new kernel::Field::Text(
                name          =>'devicename',
                label         =>'Devicename',
                vjointo       =>'tssm::dev',
                vjoinon       =>['deviceid'=>'deviceid'],
                vjoindisp     =>'fullname',
                dataobjattr   =>SELpref.'probsummarym1.tsi_ci_name'),

      new kernel::Field::Text(
                name          =>'affectedserviceid',
                label         =>'AffectedServiceID',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>SELpref.'probsummarym1.tsi_as_logical_name'),

      new kernel::Field::Text(
                name          =>'servicename',
                label         =>'AffectedServiceName',
                vjointo       =>'tssm::dev',
                htmldetail    =>'NotEmpty',
                vjoinon       =>['affectedserviceid'=>'deviceid'],
                vjoindisp     =>'fullname',
                dataobjattr   =>SELpref.'probsummarym1.tsi_as_name'),

     new kernel::Field::MultiDst (
                name          =>'dstamname',
                group         =>'amdst',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'AMName',
                altnamestore  =>'dstraw',
                htmlwidth     =>'200',
                dst           =>[
                                 'tsacinv::system'=>'fullname',
                                 'tsacinv::appl'=>'fullname',
                                 'tsacinv::asset'=>'fullname',
                                ],
                dsttypfield   =>'dstobj',
                dstidfield    =>'dstid'),

     new kernel::Field::Link(
                name          =>'dstraw',
                group         =>'amdst',
                label         =>'AM Name',
                dataobjattr   =>SELpref."device2m1.title"),

     new kernel::Field::Text(
                name          =>'dstid',
                group         =>'amdst',
                label         =>'AMID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>SELpref."device2m1.id"),



##      new kernel::Field::Text(
##                name          =>'custapplication',
##                label         =>'Customer Application',
##                dataobjattr   =>'probsummarym1.dsc_service'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                label         =>'SysModTime',
                dataobjattr   =>SELpref.'probsummarym1.sysmodtime'),

#      new kernel::Field::Text(
#                name          =>'affservices',
#                sqlorder      =>"none",
#                htmldetail    =>0,
#                label         =>'affected services',
#                dataobjattr   =>SELpref.'probsummarym1.affected_services'),

      new kernel::Field::Date(
                name          =>'cdate',
                label         =>'Created',
                dataobjattr   =>SELpref.'probsummarym1.open_time'),

      new kernel::Field::Date(
                name          =>'downtimestart',
                label         =>'Downtime Start',
                dataobjattr   =>SELpref.'probsummarym1.downtime_start'),

      new kernel::Field::Date(
                name          =>'downtimeend',
                label         =>'Downtime End',
                dataobjattr   =>SELpref.'probsummarym1.downtime_end'),

      new kernel::Field::Text(
                name          =>'mandant',
                label         =>'ServiceManager Mandant',
                dataobjattr   =>SELpref.'probsummarym1.tsi_mandant_name'),

      new kernel::Field::Text(
                name          =>'mandantid',
                label         =>'ServiceManager Mandant ID',
                dataobjattr   =>SELpref.'probsummarym1.tsi_mandant'),

      new kernel::Field::Textarea(
                name          =>'action',
                label         =>'Description',
                dataobjattr   =>SELpref.'probsummarym1.action'),

      new kernel::Field::Textarea(
                name          =>'actionlog',
                label         =>'Actions',
                searchable    =>0,
                dataobjattr   =>SELpref.'probsummarym1.update_action'),

      new kernel::Field::Textarea(       
                name          =>'resolution',
                label         =>'Resolution',
                searchable    =>0,
                dataobjattr   =>SELpref.'probsummarym1.resolution'),

#      new kernel::Field::SubList(
#                name          =>'history',
#                label         =>'History',
#                vjointo       =>'tssm::inm_assignment',
#                vjoinon       =>['incidentnumber'=>'incidentnumber'],
#                vjoininhash   =>['assignment','status'],
#                vjoindisp     =>[qw(page assignment status sysmodtime)]),

#      new kernel::Field::SubList(
#                name          =>'relations',
#                label         =>'Relations',
#                group         =>'relations',
#                vjointo       =>'tssm::lnk',
#                vjoinon       =>['incidentnumber'=>'src'],
#                vjoininhash   =>['dst'],
#                vjoindisp     =>[qw(dst dstname)]),

      new kernel::Field::Text(
                name          =>'hassignment',
                group         =>'status',
                label         =>'Home Assignment',
                weblinkto     =>'tssm::group',
                weblinkon     =>['hassignment'=>'fullname'],
                dataobjattr   =>SELpref.'probsummarym1.open_group'),

##      new kernel::Field::Text(
##                name          =>'iassignment',
##                group         =>'status',
##                label         =>'Initial Assignment',
##                dataobjattr   =>'probsummarym1.initial_assignment'),

#      new kernel::Field::Text(
#                name          =>'rassignment',
#                searchable    =>0,
#                group         =>'status',
#                depend        =>["history"],
#                onRawValue    =>\&getResolvAssignment,
#                label         =>'Resolved Assignment'),

#      new kernel::Field::Text(
#                name          =>'involvedassignment',
#                searchable    =>0,
#                group         =>'status',
#                depend        =>["history"],
#                onRawValue    =>\&getInvolvedAssignment,
#                label         =>'Involved Assignment'),

      new kernel::Field::Text(
                name          =>'cassignment',
                group         =>'status',
                label         =>'Current Assignment',
                weblinkto     =>'tssm::group',
                weblinkon     =>['cassignment'=>'fullname'],
                dataobjattr   =>SELpref.'probsummarym1.assignment'),

      new kernel::Field::Text(
                name          =>'priority',
                group         =>'status',
                label         =>'Priority',
                dataobjattr   =>SELpref.'probsummarym1.priority_code'),

      new kernel::Field::Text(
                name          =>'impact',
                group         =>'status',
                label         =>'Business Impact',
                dataobjattr   =>SELpref.'probsummarym1.initial_impact'),
     
      new kernel::Field::Text(
                name          =>'causecode',
                group         =>'status',
                label         =>'Cause Code',
                dataobjattr   =>SELpref.'probsummarym1.cause_code'),

##      new kernel::Field::Text(
##                name          =>'reason',
##                group         =>'status',
##                label         =>'Reason',
##                dataobjattr   =>'probsummarym1.reason_type'),

##      new kernel::Field::Text(
##                name          =>'reasonby',
##                group         =>'status',
##                label         =>'Reason by',
##                dataobjattr   =>'probsummarym1.reason_causedby'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                label         =>'Create time',
                dataobjattr   =>SELpref.'probsummarym1.open_time'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                label         =>'Closing time',
                dataobjattr   =>SELpref.'probsummarym1.close_time'),

##      new kernel::Field::Date(
##                name          =>'workstart',
##                depend        =>['status'],
##                group         =>'close',
##                label         =>'Work Start',
##                dataobjattr   =>'probsummarym1.work_start'),

##      new kernel::Field::Date(
##                name          =>'workend',
##                depend        =>['status'],
##                group         =>'close',
##                label         =>'Work End',
##                dataobjattr   =>'probsummarym1.work_end'),

      new kernel::Field::Text(
                name          =>'reportedby',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Reported by',
                dataobjattr   =>SELpref.'probsummarym1.alternate_contact'),

      new kernel::Field::Text(
                name          =>'openedby',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Opened by',
                dataobjattr   =>SELpref.'probsummarym1.opened_by'),

      new kernel::Field::Text(
                name          =>'editor',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Editor Account',
                dataobjattr   =>SELpref.'probsummarym1.sysmoduser'),

##      new kernel::Field::Text(
##                name          =>'contactlastname',
##                ignorecase    =>1,
##                group         =>'contact',
##                label         =>'Contact Lastname',
##                dataobjattr   =>'probsummarym1.contact_lastname'),

      new kernel::Field::Text(
                name          =>'contactname',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Contact Name',
                dataobjattr   =>SELpref.'probsummarym1.contact_name'),

      new kernel::Field::Text(
                name          =>'assigneename',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Assignee Name',
                dataobjattr   =>SELpref.'probsummarym1.assignee_name'),

      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'W5Base Application',
                onRawValue    =>\&AddW5BaseData,
                depend        =>[qw(devicename dstobj dstid)]),

      new kernel::Field::Text(
                name          =>'w5base_tsmposix',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'w5basedata',
                label         =>'W5Base TSM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>[qw(devicename dstobj dstid)]),

      new kernel::Field::Text(
                name          =>'w5base_tsm2posix',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'w5basedata',
                label         =>'W5Base TSM deputy',
                onRawValue    =>\&AddW5BaseData,
                depend        =>[qw(devicename dstobj dstid)]),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>SELpref.
                                'probsummarym1.tsi_ext_backbone_creator_sys'),
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-ID',
                depend        =>[qw(srcsys)],
                dataobjattr   =>SELpref.
                                'probsummarym1.tsi_ext_related_ids'),

   );
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(linenumber incidentnumber 
                            downtimestart downtimeend status name));
   return($self);
}


sub AddW5BaseData
{
   my $self=shift;
   my $current=shift;
   my $dstobj=$current->{dstobj};
   my $dstid=$current->{dstid};
   my $cachekey=$current->{devicename};

   my $app=$self->getParent();
   my $c=$self->getParent->Context();
   return(undef) if (!defined($cachekey) || $cachekey eq "");
   if (!defined($c->{W5BaseRel}->{$cachekey})){
      my $w5sys=$app->getPersistentModuleObject("W5BaseSys","itil::system");
      my $w5appl=$app->getPersistentModuleObject("W5BaseAppl","itil::appl");
      my @applid;
      my @applapplid;
      if ($dstobj eq "tsacinv::appl" && $dstid ne ""){
         push(@applapplid,$dstid);
      }
      my @systemid;
      if ($dstobj eq "tsacinv::system" && $dstid ne ""){
         push(@systemid,$dstid);
      }
      my ($applapplidfromkey)=$cachekey=~m/\((A\d+)\)$/;
      if (($#applapplid==-1) && $applapplidfromkey ne ""){
         push(@applapplid,$applapplidfromkey);
      }
      my ($systemidfromkey)=$cachekey=~m/\((S\d+)\)$/;
      if (($#systemid==-1) && $systemidfromkey ne ""){
         push(@systemid,$systemidfromkey);
      }
      if ($#systemid!=-1){
         $w5sys->ResetFilter();
         $w5sys->SetFilter({systemid=>\@systemid});
         my ($rec,$msg)=$w5sys->getOnlyFirst(qw(applications));
         my %l=();
         if (defined($rec)){
            if (defined($rec->{applications}) &&
                ref($rec->{applications}) eq "ARRAY"){
               foreach my $app (@{$rec->{applications}}){
                  push(@applid,$app->{applid}) if ($app->{applid} ne "");
               }
            }
         }
      }
      my @flt;
      if ($#applid!=-1){
         push(@flt,{id=>\@applid});
      }
      if ($#applapplid!=-1){
         push(@flt,{applid=>\@applapplid});
      }
      my %appl;
      my %tsmposix;
      my %tsm2posix;
      if ($#flt!=-1){
         $w5appl->ResetFilter();
         $w5appl->SetFilter(\@flt);
         my @l=$w5appl->getHashList(qw(name tsmposix tsm2posix));
         foreach my $arec (@l){
            $appl{$arec->{name}}++ if ($arec->{name} ne "");
            $tsmposix{$arec->{tsmposix}}++ if ($arec->{tsmposix} ne "");
            $tsm2posix{$arec->{tsm2posix}}++ if ($arec->{tsm2posix} ne "");

         }
      }
      my %l;
      $l{w5base_appl}=[sort(keys(%appl))];
      $l{w5base_tsmposix}=[sort(keys(%tsmposix))];
      $l{w5base_tsm2posix}=[sort(keys(%tsm2posix))];
      $c->{W5BaseRel}->{$cachekey}=\%l;
   }
   return($c->{W5BaseRel}->{$cachekey}->{$self->Name});

}



sub getResolvAssignment
{
   my $self=shift;
   my $current=shift;
   my $fo=$self->getParent->getField("history");
   my $l=$fo->RawValue($current);
   my $a;
   foreach my $rec (@$l){
      $a=$rec->{assignment} if ($rec->{status} eq "closed");
   }
   return($a); 
}

sub SetFilterForQualityCheck
{
   my $self=shift;
   my $stateparam=shift;
   my @view=@_;
   return(undef);
}

sub allowFurtherOutput
{
   my $self=shift;
#   return(1) if ($self->isMemberOf("admin"));
   return(0);
}

sub isUploadValid
{
   my $self=shift;

   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/inm.jpg?".$cgi->query_string());
}

sub getInvolvedAssignment
{
   my $self=shift;
   my $current=shift;
   my $fo=$self->getParent->getField("history");
   my $l=$fo->RawValue($current);
   my %a;
   foreach my $rec (@$l){
      $a{$rec->{assignment}}=1;
   }
   return([sort(keys(%a))]); 
}

sub initSearchQuery
{
   my $self=shift;
   my $nowlabel=$self->T("now","kernel::App");

   if (!defined(Query->Param("search_sysmodtime"))){
     Query->Param("search_sysmodtime"=>">now-1h");
   }

}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default status relations contact close amdst
             w5basedata source));
}



sub getSqlFrom
{
   my $self=shift;

   my $from=TABpref."probsummarym1 ".SELpref."probsummarym1 ".
         "left outer join ".TABpref."device2m1 ".SELpref."device2m1 ".
         "on ".SELpref."probsummarym1.tsi_ci_name=".SELpref."device2m1.ci_name".
         " and ".SELpref."device2m1.ci_name<>'N/A'";
   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where;
   if ($ENV{REMOTE_USER} ne "dummy/admin"){
      $where=SELpref."probsummarym1.tsi_mandant in (".
         join(",",map({"'".$_."'"} MandantenRestriction())).")";
   }
   return($where);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $st;
   if (defined($rec)){
      $st=$rec->{status};
   }
   my @l=qw(header default status relations contact close w5basedata 
            amdst source);

   if ($rec->{srcsys} ne ""){
      push(@l,"source");
   }
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getValidWebFunctions
{
   my $self=shift;
   return("Manager",
          "inmFinish","inmResolv","inmClose","inmAddNote","inmReopen",
          "Process",
          $self->SUPER::getValidWebFunctions());
}


1;
