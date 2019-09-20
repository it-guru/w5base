package tssm::chm;
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
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'changenumber',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'Change No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>SELpref.'cm3rm1.dh_number'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Title',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'cm3rm1.brief_description'),

      new kernel::Field::Date(
                name          =>'cdate',
                label         =>'Created',
                dataobjattr   =>SELpref.'cm3rm1.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                label         =>'Planed Start',
                dataobjattr   =>SELpref.'cm3rm1.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                label         =>'Planed End',
                dataobjattr   =>SELpref.'cm3rm1.planned_end'),

      new kernel::Field::Duration(
                name          =>'plannedduration',
                label         =>'Planed Duration',
                depend        =>[qw(plannedstart plannedend)]),

      new kernel::Field::Text(
                name          =>'exsrcid',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'Extern Change ID',
                dataobjattr   =>"decode(".SELpref."cm3rm1.tsi_external_id,
                                        'null',NULL,".
                                         SELpref."cm3rm1.tsi_external_id)"),


      new kernel::Field::Text(
                name          =>'modelid',
                label         =>'Model ID',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current={};
                   my %param=@_;
                   $current=$param{current} if (exists($param{current}));
                   return(1) if ($current->{$self->{name}} ne "");
                   return(0);
                },
                dataobjattr   =>SELpref.'cm3rm1.tsi_referenced_model'),

      new kernel::Field::Text(
                name          =>'mandant',
                label         =>'ServiceManager Mandant',
                dataobjattr   =>SELpref.'cm3rm1.tsi_mandant_name'),

      new kernel::Field::Text(
                name          =>'mandantid',
                label         =>'ServiceManager Mandant ID',
                dataobjattr   =>SELpref.'cm3rm1.tsi_mandant'),

      new kernel::Field::SubList(
                name          =>'approvalsreq',
                label         =>'Approvals Required',
                group         =>'approvals',
                forwardSearch =>1,
                vjointo       =>'tssm::chm_approvereq',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(groupname groupmailbox)]),

      new kernel::Field::SubList(
                name          =>'approvallog',
                label         =>'Approval Log',
                group         =>'approvals',
                forwardSearch =>1,
                vjointo       =>'tssm::chm_approvallog',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(timestamp name action)]),

      new kernel::Field::SubList(
                name          =>'tasks',
                label         =>'Tasks',
                htmlwidth     =>'300px',
                group         =>'tasks',
                forwardSearch =>1,
                vjointo       =>'tssm::chmtask',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoininhash   =>['plannedstart','plannedend',
                                 'tasknumber','name','cidown',
                                 'status','relations','implementer'],
                vjoindisp     =>[qw(plannedstart plannedend tasknumber status
                                    cidown name implementer)]),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (!($param{current}->{phase}=~m/^70 /) &&
                       $param{current}->{phase}=~m/RFC/i){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>SELpref.'cm3rm1.plan_clob'),

      new kernel::Field::Textarea(
                name          =>'rfcdescription',
                label         =>'RFC Description',
                depend        =>['description','phase'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (!($param{current}->{phase}=~m/^70 /) &&
                       $param{current}->{phase}=~m/RFC/i){
                      return(1);
                   }
                   return(0) if ($param{current}->{$self->Name()} eq "");
                   my $l=length($param{current}->{$self->Name()});
                   if (trim(substr($param{current}->{description},0,$l)) eq 
                       trim($param{current}->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.description'),

      new kernel::Field::Number(
                name          =>'descriptionlength',
                label         =>'Description length',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['description'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fo=$self->getParent->getField("description",$current);
                   my $d=$fo->RawValue($current);
                   return(length($d));
                }),

      new kernel::Field::Textarea(
                name          =>'fallback',
                label         =>'Fallback',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.backout_method'),

      new kernel::Field::Textarea(
                name          =>'chmtarget',
                label         =>'Target of change',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.tsi_target'),

      new kernel::Field::Textarea(
                name          =>'riskomission',
                label         =>'Risk of omission',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.tsi_risk_omission'),

      new kernel::Field::Textarea(
                name          =>'riskimplementation',
                label         =>'Risk of implementation',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.tsi_risk_impl'),

      new kernel::Field::Textarea(
                name          =>'impactdesc',
                label         =>'Impact description',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.tsi_impact_desc'),

      new kernel::Field::Textarea(
                name          =>'validation',
                label         =>'Validation',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.tsi_validation'),

      new kernel::Field::JoinUniqMerge(
                name          =>'pso',
                label         =>'PSO',
                group         =>'downtimesum',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'tssm::chmtask',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>'cidown'),

      new kernel::Field::SubList(
                name          =>'downtimesum',
                label         =>'Downtime summary',
                group         =>'downtimesum',
                depend        =>'pso',
                htmldetail    =>1,
                searchable    =>0,
                forwardSearch =>1,
                vjointo       =>'tssm::chm_pso',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoinbase     =>[{plannedstart=>''}],
                vjoindisp     =>[qw(plannedstart plannedend applname)]),

      new kernel::Field::Text(
                name          =>'priority',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'status',
                label         =>'Pritority',
                dataobjattr   =>SELpref.'cm3rm1.priority_code'),

      new kernel::Field::Text(
                name          =>'status',
                group         =>'status',
                selectfix     =>1,
                label         =>'Current Status',
                dataobjattr   =>SELpref.'cm3rm1.tsi_status'),

      new kernel::Field::Text(
                name          =>'taskstatus',
                group         =>'status',
                selectfix     =>1,
                label         =>'Task Status',
                dataobjattr   =>SELpref.'cm3rm1.tsi_tasks_status'),

      new kernel::Field::Text(
                name          =>'phase',
                selectfix     =>1,
                group         =>'status',
                label         =>'Current Phase',
                dataobjattr   =>SELpref.'cm3rm1.current_phase'),

      new kernel::Field::Text(
                name          =>'approvalstatus',
                group         =>'status',
                label         =>'Approval Status',
                dataobjattr   =>SELpref.'cm3rm1.tsi_approval_status'),

      new kernel::Field::Text(
                name          =>'impact',
                group         =>'status',
                label         =>'Business Impact',
                dataobjattr   =>SELpref.'cm3rm1.tsi_restriction'),

      new kernel::Field::Text(
                name          =>'requestedfrom',
                group         =>'status',
                label         =>'Requested from',
                dataobjattr   =>SELpref.'cm3rm1.tsi_requested_from'),

      new kernel::Field::Text(
                name          =>'urgency',
                group         =>'status',
                label         =>'Urgency',
                dataobjattr   =>"decode(".SELpref."cm3rm1.emergency,'t',".
                                "'emergency','normal')"),

      new kernel::Field::Text(
                name          =>'reason',
                group         =>'status',
                htmldetail    =>0,
                label         =>'Reason',
                dataobjattr   =>SELpref.'cm3rm1.reason'),
             
      new kernel::Field::Text(
                name          =>'category',
                group         =>'status',
                htmldetail    =>0,
                label         =>'Category',
                dataobjattr   =>SELpref.'cm3rm1.category'),

      new kernel::Field::Text(
                name          =>'risk',
                group         =>'status',
                label         =>'Risk',
                dataobjattr   =>SELpref.'cm3rm1.tsi_risk_type'),

      new kernel::Field::Text(
                name          =>'type',
                group         =>'status',
                label         =>'Change Type (CBI)',
                dataobjattr   =>SELpref.'cm3rm1.initial_impact'),

      new kernel::Field::Text(
                name          =>'criticality',
                group         =>'status',
                label         =>'Criticality',
                dataobjattr   =>SELpref.'cm3rm1.severity'),

      new kernel::Field::Text(
                name          =>'complexity',
                group         =>'status',
                label         =>'Complexity',
                dataobjattr   =>SELpref.'cm3rm1.tsi_complexity'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                label         =>'SysModTime',
                dataobjattr   =>SELpref.'cm3rm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                label         =>'Create time',
                dataobjattr   =>SELpref.'cm3rm1.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                label         =>'Closing time',
                dataobjattr   =>SELpref.'cm3rm1.close_time'),

      new kernel::Field::Text(
                name          =>'resolutioncode',
                group         =>'close',
                label         =>'Resolution Code',
                dataobjattr   =>SELpref.'cm3rm1.tsi_resolution_code'),

      new kernel::Field::Text(
                name          =>'closecode',
                group         =>'close',
                label         =>'Close Code',
                dataobjattr   =>SELpref.'cm3rm1.tsi_close_code'),

      new kernel::Field::Textarea(
                name          =>'closurecomments',
                label         =>'Closure Comments',
                group         =>'close',
                searchable    =>0,
                dataobjattr   =>SELpref.'cm3rm1.closurecomments_clob'),

      new kernel::Field::Date(
                name          =>'workstart',
                depend        =>['status'],
                group         =>'close',
                label         =>'Work Start',
                dataobjattr   =>SELpref.'cm3rm1.tsi_kpi_work_start'),

      new kernel::Field::Date(
                name          =>'workend',
                depend        =>['status'],
                group         =>'close',
                label         =>'Work End',
                dataobjattr   =>SELpref.'cm3rm1.tsi_kpi_work_end'),

      new kernel::Field::Text(
                name          =>'assignarea',
                group         =>'contact',
                htmldetail    =>0,
                ignorecase    =>1,
                label         =>'Assign Area',
                dataobjattr   =>SELpref.'cm3rm1.tsi_assignarea'),

      new kernel::Field::Link(
                name          =>'rawassignarea',
                label         =>'raw Assign Area',
                htmldetail    =>0,
                dataobjattr   =>SELpref.'cm3rm1.tsi_assignarea'),

      new kernel::Field::Text(
                name          =>'chmmgrgrp',
                uppersearch   =>1,
                group         =>'chmcontact',
                label         =>'Changemanager group',
                weblinkto     =>'tssm::group',
                weblinkon     =>['chmmgrgrp'=>'fullname'],
                dataobjattr   =>SELpref.'cm3rm1.tsi_manager_group'),

      new kernel::Field::Text(
                name          =>'chmmgroper',
                uppersearch   =>1,
                group         =>'chmcontact',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['chmmgroper'=>'loginname'],
                label         =>'Changemanager',
                dataobjattr   =>SELpref.'cm3rm1.tsi_manager_operator'),

      new kernel::Field::Text(
                name          =>'coordinatorgrp',
                uppersearch   =>1,
                group         =>'contact',
                weblinkto     =>'tssm::group',
                weblinkon     =>['coordinatorgrp'=>'fullname'],
                label         =>'Change Coordinator Group',
                dataobjattr   =>SELpref.'cm3rm1.assign_dept'),

      new kernel::Field::Text(
                name          =>'coordinatoroper',
                uppersearch   =>1,
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['coordinatoroper'=>'loginname'],
                group         =>'contact',
                label         =>'Change Coordinator',
                dataobjattr   =>SELpref.'cm3rm1.coordinator'),

      new kernel::Field::Text(
                name          =>'requestedby',
                group         =>'contact',
                weblinkto     =>'tssm::user',
                weblinkon     =>['requestedby'=>'userid'],
                label         =>'Change Requestor',
                dataobjattr   =>SELpref.'cm3rm1.requested_by'),

       new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Relations',
                uivisible     =>0,
                searchable    =>0,
                group         =>'relations',
                vjointo       =>'tssm::chm_device',
                vjoinon       =>['changenumber'=>'src'],
                vjoininhash   =>[qw(dstid dstobj dstname)],
                vjoindisp     =>[qw(dstname)]),

      new kernel::Field::SubList(
                name          =>'configitems',
                label         =>'Configuration Items',
                group         =>'configitems',
                forwardSearch =>1,
                vjointo       =>'tssm::chm_device',
                vjoinon       =>['changenumber'=>'src'],
                vjoininhash   =>[qw(descname dstmodel dstcriticality
                                    civalid dststatus dstid)],
                vjoindisp     =>[qw(descname dstmodel dstcriticality
                                    civalid dststatus)]),

      new kernel::Field::SubList(
                name          =>'tickets',
                label         =>'Related Tickets',
                group         =>'tickets',
                forwardSearch =>1,
                vjointo       =>'tssm::lnkticket',
                vjoinon       =>['changenumber'=>'src'],
                vjoindisp     =>[qw(dstname)],
                vjoininhash   =>[qw(dstsmid dstsmobj dstname)]),

      new kernel::Field::Text(
                name          =>'editor',
                group         =>'contact',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['editor'=>'loginname'],
                label         =>'Editor Account',
                dataobjattr   =>SELpref.'cm3rm1.sysmoduser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>SELpref.
                                'cm3rm1.tsi_external_main_id'),
      new kernel::Field::Text(
                name          =>'srcid',
                depend        =>[qw(srcsys)],
                group         =>'source',
                label         =>'Source-ID',
                dataobjattr   =>SELpref.
                                'cm3rm1.tsi_external_number'),

      new kernel::Field::QualityOk(
                uivisible     =>\&showQualityFields),

      new kernel::Field::QualityText(
                uivisible     =>\&showQualityFields),
   );

   $self->setDefaultView(qw(linenumber changenumber 
                            plannedstart plannedend 
                            status name));

   return($self);
}

sub showQualityFields {
   my $self=shift;
   my %grps=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                                 ['RCHManager','RCHManager2','RCHOperator']);
   return(1) if (keys(%grps));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   my $nowlabel=$self->T("now","kernel::App");

   if (!defined(Query->Param("search_plannedend"))){
     Query->Param("search_plannedend"=>">$nowlabel-1d AND <$nowlabel+14d");
   }

#   if (!defined(Query->Param("search_changenumber"))){
#     Query->Param("search_changenumber"=>"C000191883 C000146354 C000002274 ".
#                                         "C000222842 C000188772");
#   }

}

sub allowFurtherOutput
{
   my $self=shift;
   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}


sub isUploadValid
{
   my $self=shift;

   return(0);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
}

sub SetFilterForQualityCheck
{
   my $self=shift;
   my $stateparam=shift;
   my @view=@_;
   return(undef);
}



#sub SecureSetFilter
#{
#   my $self=shift;
#   my @flt=@_;
#  
#   my @chmfilter; 
#   if (!$self->IsMemberOf("admin")){
#      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"direct");
#      my $MandatorCache=$self->Cache->{Mandator}->{Cache};
#      foreach my $grpid (@mandators){
#         if (defined($MandatorCache->{grpid}->{$grpid})){
#            my $mc=$MandatorCache->{grpid}->{$grpid};
#            if (defined($mc->{additional}) &&
#                ref($mc->{additional}->{tssmchmfilter}) eq "ARRAY"){
#               push(@chmfilter,@{$mc->{additional}->{tssmchmfilter}});
#            }
#         }
#      }
#      @chmfilter=grep(!/^\s*$/,@chmfilter);
#      my $chmfilter=join(" or ",@chmfilter);
#      @chmfilter=();
#      if (!(@chmfilter=$self->StringToFilter($chmfilter))){
#         $self->LastMsg(ERROR,"none or invalid mandator base filter '\%s'",
#                        $chmfilter);
#         return(undef);
#      }
#      my $userid=$self->getCurrentUserId();
#      my $user=getModuleObject($self->Config,"base::user");
#      $user->SetFilter({userid=>\$userid});
#      my ($urec,$msg)=$user->getOnlyFirst(qw(posix));
#      if (defined($urec) && $urec->{posix} ne ""){
#         my $usr=uc($urec->{posix});
#         push(@chmfilter,{requestedby=>\$usr});
#         push(@chmfilter,{implementor=>\$usr});
#         push(@chmfilter,{coordinator=>\$usr});
#         push(@chmfilter,{editor=>\$usr});
#      }
#      # ensure, that undefined mandators results to empty result
#      @chmfilter=("rawlocation"=>\'InvalidMandator') if ($#chmfilter==-1);
#      #msg(INFO,"chm mandator filter=%s\n",Dumper(\@chmfilter));
#      $self->SetNamedFilter("MandatorFilter",\@chmfilter);
#   }
#   return($self->SUPER::SecureSetFilter(@flt));
#}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default status close configitems tickets relations approvals
             tasks downtimesum chmcontact contact source));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/chm.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."cm3rm1 ".SELpref."cm3rm1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where;
   my $SELpref=SELpref;

   if ($ENV{REMOTE_USER} ne "dummy/admin"){
      my $mlist=join(",",map({"'".$_."'"} MandantenRestriction()));

$where=<<EOF;
         (${SELpref}CM3RM1.TSI_MANDANT in ($mlist) or
         ${SELpref}CM3RM1.dh_number in (
            SELECT B."DH_NUMBER"
            FROM SMREP1.DH_CM3RM1 B
            WHERE B.TSI_MANDANT like '40004787.%'
         union
           SELECT CN."DH_NUMBER"
           FROM SMREP1.DH_DEVICE2M1 D 
           join SMREP1.DH_CM3RA10 CN on CN.TSI_CI_NAME = D.CI_NAME
           WHERE D.TSI_MANDANT like '40004787.%'
         union
           SELECT M."DH_NUMBER"
           FROM SMREP1.DH_CM3RA8 M,SMREP1.DH_COMPANYM1 CO
           WHERE M.TSI_MULTI_CUST_LIST = CO.COMPANY AND
             CO.TSI_MANDANT like '40004787.%'
         union
           SELECT AA."DH_NUMBER"
           FROM SMREP1.DH_CM3RA6 AA
           WHERE AA.TSI_APPROVAL_LOG_GROUP like 'TIT.%'
         union
            SELECT CP."DH_NUMBER"
            FROM SMREP1.DH_CM3RA7 CP
            WHERE CP.TSI_APPROVALS_MANUAL like 'TIT.%'
         ))
EOF
   }

   my @states=$self->getStateFilter();
   if ($#states!=-1){
      $where.=" AND " if ($where ne "");
      $where.=SELpref."cm3rm1.state in ".join(",",map({"'".$_."'"} @states));
   }
   return($where);
}

sub getStateFilter
{
   my $self=shift;

   return(qw(tsi.cm.view));

}

sub SetFilter
{
   my $self=shift;

   my $flt=$_[0];

   if (ref($flt) eq "HASH" && exists($flt->{changenumber}) &&
       !ref($flt->{changenumber})) {

      my @chnrs;
      foreach my $chnr (split /[\s,;]+/,$flt->{changenumber}) {
         if (my ($pref,$chnum)=$chnr=~m/^([><]{0,1})(\d{1,8})$/) {
            push(@chnrs,$pref.'C'.'0'x(9-length($chnum)).$chnum);       
            push(@chnrs,$pref.'SMCT-C'.'0'x(9-length($chnum)).$chnum);       
         }
         else{
            push(@chnrs,$chnr);
         }
      }

      $_[0]->{changenumber}=join(' ',@chnrs);
   }

   return($self->SUPER::SetFilter(@_));
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $st;
   if (defined($rec)){
      $st=$rec->{status};
   }
   $st=lc($st);
   my @l=qw(header default status configitems tickets relations approvals
             tasks downtimesum chmcontact contact close);

   if (defined($rec) &&
       lc($rec->{status}) ne "closed" && 
       lc($rec->{status}) ne "rejected" && 
       lc($rec->{status}) ne "resolved" &&
       !($rec->{phase}=~m/^60 /) &&
       !($rec->{phase}=~m/^70 /)){
      @l=grep(!/^close$/,@l);   # "close" would be also used as flag, to
   }                            # handle workstart/end als eventstart/end
   if ($rec->{srcsys} ne ""){   # in w5base workflow engine !
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





1;
