package tssc::chm;
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
                dataobjattr   =>'cm3rm1_w5base.numberprgn'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'cm3rm1_w5base.brief_description'),

      new kernel::Field::Date(
                name          =>'cdate',
                timezone      =>'CET',
                label         =>'Created',
                dataobjattr   =>'cm3rm1_w5base.orig_date_entered'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                timezone      =>'CET',
                label         =>'Planed Start',
                dataobjattr   =>'cm3rm1_w5base.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                timezone      =>'CET',
                label         =>'Planed End',
                dataobjattr   =>'cm3rm1_w5base.planned_end'),

      new kernel::Field::Duration(
                name          =>'plannedduration',
                label         =>'Planed Duration',
                depend        =>[qw(plannedstart plannedend)]),

      new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                ignorecase    =>1,
                dataobjattr   =>'cm3rm1_w5base.change_shortname'), 

      new kernel::Field::Link(
                name          =>'rawlocation',
                label         =>'raw Location',
                dataobjattr   =>'cm3rm1_w5base.change_shortname'), # scheint nicht 
       #         dataobjattr   =>'cm3rm1_w5base.location_code'),

      new kernel::Field::Text(
                name          =>'srcid',
                label         =>'Extern Change ID',
                dataobjattr   =>'cm3rm1_w5base.ex_number'),

      new kernel::Field::Text(
                name          =>'project',
                label         =>'Project',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                dataobjattr   =>'cm3rm1_w5base.project'),

      new kernel::Field::Text(
                name          =>'deviceid',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'DeviceID (deprecated)',
                dataobjattr   =>'cm3rm1_w5base.logical_name'),

      new kernel::Field::Text(
                name          =>'softwareid',
                htmlwidth     =>'100px',
                ignorecase    =>1,
                htmldetail    =>0,
                searchable    =>0,
                label         =>'SoftwareID (deprecated)',
                dataobjattr   =>'cm3rm1_w5base.program_name'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software (deprecated)',
                group         =>'software',
                htmlwidth     =>'300px',
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'tssc::chm_software',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'device',
                label         =>'Device (deprecated)',
                group         =>'device',
                htmlwidth     =>'300px',
                nodetaillink  =>1,
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'tssc::chm_device',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      # geht nicht, da im scadm schema dsc_service nicht existiert
      #new kernel::Field::Text(
      #          name          =>'custapplication',
      #          label         =>'Customer Application',
      #          dataobjattr   =>'cm3rm1_w5base.dsc_service'),

      new kernel::Field::Text(
                name          =>'modelid',
                label         =>'Model ID',
                dataobjattr   =>'cm3rm1_w5base.model_ref'),

      new kernel::Field::SubList(
                name          =>'approvalsreq',
                label         =>'Approvals Required',
                group         =>'approvals',
                forwardSearch =>1,
                vjointo       =>'tssc::chm_approvereq',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(groupname groupmailbox)]),

      new kernel::Field::SubList(
                name          =>'approvallog',
                label         =>'Approval Log',
                group         =>'approvals',
                forwardSearch =>1,
                vjointo       =>'tssc::chm_approvallog',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(timestamp name action)]),

      new kernel::Field::SubList(
                name          =>'approved',   # wird noch für das NotifyInetwork
                label         =>'Approved Groups',  # verfahren gebraucht
                htmldetail    =>0,
                htmlwidth     =>'200px',
                group         =>'approvals',
                vjointo       =>'tssc::chm_approvedgrp',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>[qw(name)]),

      new kernel::Field::SubList(
                name          =>'tasks',
                label         =>'Tasks',
                htmlwidth     =>'300px',
                group         =>'tasks',
                forwardSearch =>1,
                vjointo       =>'tssc::chmtask',
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
                vjointo       =>'tssc::chm_description',
                vjoinconcat   =>"\n",
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoindisp     =>'description'),

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

#      new kernel::Field::Textarea(
#                name          =>'fallback',
#                label         =>'Fallback',
#                searchable    =>0,
#                vjointo       =>'tssc::chm_fallback',
#                vjoinconcat   =>"\n",
#                vjoinon       =>['changenumber'=>'changenumber'],
#                vjoindisp     =>'fallback'),

      new kernel::Field::Textarea(
                name          =>'fallback',
                label         =>'Fallback',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.backout_method'),

      new kernel::Field::Textarea(
                name          =>'cause',
                label         =>'Cause',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.cause'),

      new kernel::Field::Textarea(
                name          =>'chmtarget',
                label         =>'Target of change',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.target_of_change'),

      new kernel::Field::Textarea(
                name          =>'riskomission',
                label         =>'Risk of omission',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.risk_of_mission'),

      new kernel::Field::Textarea(
                name          =>'riskimplementation',
                label         =>'Risk of implementation',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.risk_of_implementation'),

      new kernel::Field::Textarea(
                name          =>'impactdesc',
                label         =>'Impact description',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.impact_description'),

      new kernel::Field::Textarea(
                name          =>'cause',
                label         =>'Cause',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.cause'),

      new kernel::Field::Textarea(
                name          =>'validation',
                label         =>'Validation',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.justification'),

      new kernel::Field::Textarea(
                name          =>'serviceinfo',
                label         =>'Service Info',
                searchable    =>0,
                dataobjattr   =>'cm3rm1_w5base.service_info_comments'),

      new kernel::Field::Textarea(
                name          =>'resources',
                label         =>'Resources',
                htmldetail    =>0,
                searchable    =>0,
                dataobjattr   =>'cm3ra43.resources'),

      new kernel::Field::Text(
                name          =>'priority',
                htmldetail    =>0,
                group         =>'status',
                label         =>'Pritority',
                dataobjattr   =>'cm3rm1_w5base.priority'),

      new kernel::Field::Text(
                name          =>'status',
                group         =>'status',
                label         =>'Current Status',
                dataobjattr   =>'cm3rm1_w5base.status'),

      new kernel::Field::Text(
                name          =>'approvalstatus',
                group         =>'status',
                label         =>'Approval Status',
                dataobjattr   =>'cm3rm1_w5base.approval_status'),

      new kernel::Field::Text(
                name          =>'impact',
                group         =>'status',
                label         =>'Business Impact',
                dataobjattr   =>'cm3rm1_w5base.impact'),

      new kernel::Field::Text(
                name          =>'requestedfrom',
                group         =>'status',
                label         =>'Requested from',
                dataobjattr   =>'cm3rm1_w5base.misc3'),

      new kernel::Field::Text(
                name          =>'urgency',
                group         =>'status',
                label         =>'Urgency',
                dataobjattr   =>'cm3rm1_w5base.urgency'),

      new kernel::Field::Text(
                name          =>'reason',
                group         =>'status',
                htmldetail    =>0,
                label         =>'Reason',
                dataobjattr   =>'cm3rm1_w5base.reason'),
             
      new kernel::Field::Text(
                name          =>'category',
                group         =>'status',
                htmldetail    =>0,
                label         =>'Category',
                dataobjattr   =>'cm3rm1_w5base.category'),

      new kernel::Field::Text(
                name          =>'risk',
                group         =>'status',
                label         =>'Risk',
                dataobjattr   =>'cm3rm1_w5base.risk_assessment'),

      new kernel::Field::Text(
                name          =>'type',
                group         =>'status',
                label         =>'Type',
                htmldetail    =>0,
                dataobjattr   =>'cm3rm1_w5base.class_field'),

      new kernel::Field::Text(
                name          =>'typecalc',
                group         =>'status',
                label         =>'Type calculated',
                htmldetail    =>0,
                dataobjattr   =>'cm3rm1_w5base.dsc_change_type_calculated'),

      new kernel::Field::Text(
                name          =>'types',
                group         =>'status',
                label         =>'Type',
                searchable    =>0,
                depend        =>[qw(type typecalc)],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   return "$current->{type} (calc. $current->{typecalc})";
                }),

      new kernel::Field::Text(
                name          =>'criticality',
                group         =>'status',
                label         =>'Criticality',
                htmldetail    =>0,
                dataobjattr   =>'cm3rm1_w5base.criticality'),

      new kernel::Field::Text(
                name          =>'criticalitycalc',
                group         =>'status',
                label         =>'Criticality calculated',
                htmldetail    =>0,
                dataobjattr   =>'cm3rm1_w5base.criticality_total'),

      new kernel::Field::Text(
                name          =>'criticalities',
                group         =>'status',
                label         =>'Criticality',
                searchable    =>0,
                depend        =>[qw(criticality criticalitycalc)],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $txt=$current->{criticality};
                   if ($current->{criticalitycalc}=~m/\S*/){
                      $txt.=" (calc. $current->{criticalitycalc})";
                   }
                   return $txt;
                }),

      new kernel::Field::Text(
                name          =>'complexity',
                group         =>'status',
                label         =>'Complexity',
                dataobjattr   =>'cm3rm1_w5base.complexity'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'cm3rm1_w5base.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'cm3rm1_w5base.orig_date_entered'),

      new kernel::Field::Text(
                name          =>'closedby',
                group         =>'close',
                label         =>'Closed by',
                dataobjattr   =>'cm3rm1_w5base.closed_by'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Closeing time',
                dataobjattr   =>'cm3rm1_w5base.close_time'),

      new kernel::Field::Text(
                name          =>'closecode',
                group         =>'close',
                label         =>'Close Code',
                dataobjattr   =>'cm3rm1_w5base.close_code_accept'),

      new kernel::Field::Text(
                name          =>'resolvedby',
                group         =>'close',
                label         =>'Resolved by',
                dataobjattr   =>'cm3rm1_w5base.resolved_by'),

      new kernel::Field::Date(
                name          =>'resolvetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Resolve time',
                dataobjattr   =>'cm3rm1_w5base.resolve_time'),

      new kernel::Field::Date(
                name          =>'workstart',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work Start',
                dataobjattr   =>'cm3rm1_w5base.work_start'),

      new kernel::Field::Date(
                name          =>'workend',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work End',
                dataobjattr   =>'cm3rm1_w5base.work_end'),

      new kernel::Field::Text(
                name          =>'workduration',
                depend        =>['status'],
                group         =>'close',
                label         =>'Work Duration',
                dataobjattr   =>'cm3rm1_w5base.work_duration'),

      new kernel::Field::Import($self,
                vjointo       =>'tssc::chm_closingcomments',
                vjoinon       =>['changenumber'=>'changenumber'],
                vjoinconcat   =>"\n",
                group         =>"close",
                depend        =>['status'],
                fields        =>['closingcomments']),

      new kernel::Field::Text(
                name          =>'assignarea',
                group         =>'contact',
                htmldetail    =>0,
                ignorecase    =>1,
                label         =>'Assign Area',
                dataobjattr   =>'cm3rm1_w5base.assigned_area'),

      new kernel::Field::Link(
                name          =>'rawassignarea',
                label         =>'raw Assign Area',
                htmldetail    =>0,
                dataobjattr   =>'cm3rm1_w5base.assigned_area'),

      new kernel::Field::Text(
                name          =>'customer',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Customer',
                dataobjattr   =>'cm3rm1_w5base.misc4'),

      new kernel::Field::Link(
                name          =>'rawcustomer',
                group         =>'contact',
                label         =>'raw Customer',
                dataobjattr   =>'cm3rm1_w5base.misc4'),

      new kernel::Field::Text(
                name          =>'requestedby',
                group         =>'contact',
                htmldetail    =>0,
                label         =>'Requested By',
                dataobjattr   =>'cm3rm1_w5base.requested_by'),

      new kernel::Field::Text(
                name          =>'assignedto',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Assigned To',
                dataobjattr   =>'cm3rm1_w5base.assigned_to'),

      new kernel::Field::Text(
                name          =>'implementor',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Coordinator',
                dataobjattr   =>'cm3rm1_w5base.assign_firstname'),

      new kernel::Field::Text(
                name          =>'coordinator',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Changemanager group',
                dataobjattr   =>'cm3rm1_w5base.coordinator'),

      new kernel::Field::Text(
                name          =>'coordinatorposix',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Changemanager',
                dataobjattr   =>'cm3rm1_w5base.coord_firstname'),

      new kernel::Field::Text(
                name          =>'coordinatorname',
                uppersearch   =>1,
                htmldetail    =>0,
                group         =>'contact',
                label         =>'Change-Manager fullname',
                dataobjattr   =>'cm3rm1_w5base.coord_shortname'),

       new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Relations',
                uivisible     =>0,
                group         =>'relations',
                vjointo       =>'tssc::lnk',
                vjoinon       =>['changenumber'=>'src'],
                vjoininhash   =>['dst','dstobj','primary'],
                vjoindisp     =>[qw(dst dstname primary)]),


      new kernel::Field::SubList(
                name          =>'configitems',
                label         =>'Configuration Items',
                group         =>'configitems',
                forwardSearch =>1,
                vjointo       =>'tssc::lnkci',
                vjoinon       =>['changenumber'=>'src'],
                vjoindisp     =>[qw(dstmodel dstname dstcriticality civalid
                                    dststatus 
                                    furtherciinfo)]),
                              #      opmode mandator

      new kernel::Field::SubList(
                name          =>'tickets',
                label         =>'Related Tickets',
                group         =>'tickets',
                forwardSearch =>1,
                vjointo       =>'tssc::lnkticket',
                vjoinon       =>['changenumber'=>'src'],
                vjoindisp     =>[qw(dstid priority status)]),

      new kernel::Field::Text(
                name          =>'editor',
                group         =>'contact',
                label         =>'Editor',
                dataobjattr   =>'cm3rm1_w5base.sysmoduser'),

      new kernel::Field::Text(  # notwendig, solange noch das NotifyINetwork
                name          =>'addgrp', # verfahren verwendet wird.
                sqlorder      =>"none",
                group         =>'contact',
                htmldetail    =>0,
                label         =>'Additional Groups',
                dataobjattr   =>'cm3rm1_w5base.additional_groups'),

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
                                 ['RCHManager','RCHManager2']);
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
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
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



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;
  
   my @chmfilter; 
   if (!$self->IsMemberOf("admin")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"direct");
      my $MandatorCache=$self->Cache->{Mandator}->{Cache};
      foreach my $grpid (@mandators){
         if (defined($MandatorCache->{grpid}->{$grpid})){
            my $mc=$MandatorCache->{grpid}->{$grpid};
            if (defined($mc->{additional}) &&
                ref($mc->{additional}->{tsscchmfilter}) eq "ARRAY"){
               push(@chmfilter,@{$mc->{additional}->{tsscchmfilter}});
            }
         }
      }
      @chmfilter=grep(!/^\s*$/,@chmfilter);
      my $chmfilter=join(" or ",@chmfilter);
      @chmfilter=();
      if (!(@chmfilter=$self->StringToFilter($chmfilter))){
         $self->LastMsg(ERROR,"none or invalid mandator base filter '\%s'",
                        $chmfilter);
         return(undef);
      }
      my $userid=$self->getCurrentUserId();
      my $user=getModuleObject($self->Config,"base::user");
      $user->SetFilter({userid=>\$userid});
      my ($urec,$msg)=$user->getOnlyFirst(qw(posix));
      if (defined($urec) && $urec->{posix} ne ""){
         my $usr=uc($urec->{posix});
         push(@chmfilter,{requestedby=>\$usr});
         push(@chmfilter,{implementor=>\$usr});
         push(@chmfilter,{coordinator=>\$usr});
         push(@chmfilter,{editor=>\$usr});
      }
      # ensure, that undefined mandators results to empty result
      @chmfilter=("rawlocation"=>\'InvalidMandator') if ($#chmfilter==-1);
      #msg(INFO,"chm mandator filter=%s\n",Dumper(\@chmfilter));
      $self->SetNamedFilter("MandatorFilter",\@chmfilter);
   }
   return($self->SUPER::SecureSetFilter(@flt));
}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(status configitems tickets relations approvals tasks contact));
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
   my $from="cm3rm1_w5base,cm3rm1,cm3ra43";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="cm3rm1_w5base.numberprgn=cm3rm1.numberprgn and ".
             "(cm3rm1_w5base.lastprgn='t' or cm3rm1_w5base.lastprgn is null) ".
             "and cm3rm1_w5base.numberprgn=cm3ra43.numberprgn(+)";
   return($where);
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
            $chnr=$pref.'CHM'.'0'x(8-length($chnum)).$chnum;       
         }
         push @chnrs,$chnr;
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
   if ($st ne "closed" && $st ne "rejected" && $st ne "resolved"){
      return(qw(contact default tickets configitems relations qc
                status header software device tasks approvals));
   }
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec));
   # VisualView ausgeblendet; muss angepasst werden
   #
   #return($self->SUPER::getHtmlDetailPages($p,$rec),
   #       "VisualView"=>$self->T("Visual-View"));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "VisualView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};
   
   if ($p eq "VisualView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"VisualView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"VisualView");
}


sub VisualView
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));

   print $self->HttpHeader();
   print $self->HtmlHeader(
                           style=>['default.css',
                             'work.css',
                             '../../../public/tssc/load/visual-view.css']);
#
   print("<body class=fullview><form>");
   print $self->BuildVisualView($rec);
   print("</form></body></html>");
}

sub BuildVisualView
{
   my $self=shift;
   my $rec=shift;
   my $d;

   my $label="CR# ";



   if ($rec->{changenumber} ne ""){
      $label.=$rec->{changenumber};
      $label.=" - ";
   }


   if ($rec->{risk} ne ""){
      $label.=$rec->{risk};
   }
   else{
      $label.="<font color=red>MISSING RISK</font>";
   }
   $label.=" - ";


   if ($rec->{impact} ne ""){
      $label.=$rec->{impact};
   }
   else{
      $label.="<font color=red>MISSING IMPACT</font>";
   }
   $label.=" - ";


   if ($rec->{type} ne ""){
      $label.=$rec->{type};
   }
   else{
      $label.="<font color=red>MISSING TYPE</font>";
   }
   $label.=" - ";

   if ($rec->{reason} ne ""){
      $label.=$rec->{reason};
   }
   else{
      $label.="<font color=red>MISSING REASON</font>";
   }
   $label.=" - ";
   my $templparam={WindowMode=>"HtmlDetail",current=>$rec};

   my $qcok=$self->findtemplvar($templparam,"qcok");
   my $starttime=$self->findtemplvar($templparam,"plannedstart","detail");
   my $endtime=$self->findtemplvar($templparam,"plannedend","detail");
   my $requestedby=$self->findtemplvar($templparam,"requestedby","detail");
   my $description=$self->findtemplvar($templparam,"description","detail");
   $description=~s/(\S{40,60})([,:;])/$1$2 /g; # break long lines

   my $gr="#75D194";
   my $rd="#F28C8C";
   my $bl="#B9C5F5";

   my $aprcol="";
   my $crscol="";
   my $bg="bgcolor";
   $aprcol="$bg=\"$gr\"" if (lc($rec->{approvalstatus}) eq "approved");
   $crscol="$bg=\"$bl\"" if (lc($rec->{currentstatus}) eq "work in progress");
   my $qcflag="";
   if (!$qcok){
      $qcflag="<td rowspan=2 align=center>".
              "<img src=\"../../base/load/alarm.gif\">".
              "</td>";
   }
   


   $d=<<EOF;
<div class=label>$label</div>
<table style="border-bottom-style:none;min-width:500px;width:auto;width:100%">
<tr>
<td width=80>Start:</td>
<td>$starttime</td>$qcflag</tr>
<tr>
<td width=80>End:</td>
<td>$endtime</td>
</tr>
</table>

<table style="border-bottom-style:none;min-width:500px;width:auto;width:100%">
<tr>
<td width=80><u>Originator:</u><br>&nbsp;</td>
<td width=107 $crscol>CR-Status:<br>
<b>$rec->{currentstatus}</b></td>
<td width=100 $aprcol>Approval:<br>
<b>$rec->{approvalstatus}</b></td>
<td>Owner:<br>
<b>$requestedby</b></td>
<td width=200>Assigned Group:<br>
<b>$rec->{assignedto}</b></td>
</tr>
</table>

<table style="min-width:500px;width:auto;width:100%"><tr>
<td width=80><u>Change-Mgr:</u><br>&nbsp;</td>
<td>Group:<br>
<b>$rec->{coordinator}</b></td>
<td>Released by:<br>
<b>??</b></td>
<td>Completion Code:</td>
</tr>
</table>

<table style="margin-top:10px;min-width:500px;width:auto;width:100%">
<tr>
<td>
  <table class=noborder>
    <tr>
     <td class=noborder align=right width=20%><b>Customer:</b></td>
     <td class=noborder>$rec->{customer}</td>
     <td class=noborder align=right width=20%><b>Ext. Change ID:</b></td>
     <td class=noborder>$rec->{srcid}</td>
    </tr>
    <tr>
     <td class=noborder align=right width=20%><b>Reason:</b></td>
     <td class=noborder>$rec->{reason}</td>
     <td class=noborder align=right width=20%><b>Project:</b></td>
     <td class=noborder>??</td>
    </tr>
    <tr>
     <td class=noborder align=right width=20%><b>Risk:</b></td>
     <td class=noborder>$rec->{risk}</td>
     <td class=noborder align=right width=20%><b>Int. Order:</b></td>
     <td class=noborder>??</td>
    </tr>
    <tr>
     <td class=noborder align=right width=20%><b>Req. Customer:</b></td>
     <td class=noborder>??</td>
     <td class=noborder align=right width=20%><b>&nbsp;</b></td>
     <td class=noborder>&nbsp;</td>
    </tr>
  </table>
</td>
</tr><tr>
<tr>
<td>Brief-Description:<br>
<b>$rec->{name}</b>
</td>
</tr>
<tr>
<td><b><u>Description:</b></u><br>
<table style=\"width:100%;overflow:hidden;table-layout:fixed;padding:0;margin:0\">
<tr><td style="min-height:80px;height:auto;height:80px">
<pre class=multilinetext>$description</pre>
</td></tr></table>
</td>
</tr>
<tr>
<td><b><u>Backout Method:</b></u><br>
<table style=\"width:100%;overflow:hidden;table-layout:fixed;padding:0;margin:0\">
<tr><td style="min-height:80px;height:auto;height:80px">
<pre class=multilinetext>$rec->{fallback}</pre>
</td></tr></table>
</td>
</tr>
</table>

EOF
   return($d);
}







1;
