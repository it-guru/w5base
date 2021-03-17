package base::w5stat::base;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub getPresenter
{
   my $self=shift;

   my @l=(
          'w5basestat'=>{
                         opcode=>\&displayW5Base,
                         overview=>\&overviewW5Base,
                         prio=>500,
                      },
          'dataissue'=>{
                         overview=>\&overviewDataIssue,
                         opcode=>\&displayDataIssue,
                         prio=>2,
                         group=>['Group']
                      },
          'wfact'=>{
                         opcode=>\&displayWorkflowActivity,
                         prio=>3,
                         group=>['Group']
                      },
          'org'=>{
                         opcode=>\&displayOrg,
                         prio=>99999,
                         group=>['Group']
                      }
         );

}


sub getStatSelectionBox
{
   my $self=shift;
   my $selbox=shift;
   my $dstrange=shift;
   my $altdstrange=shift;
   my $app=$self->getParent();



   my $userid=$app->getCurrentUserId();
   my %groups=$app->getGroupsOf($userid,['REmployee','RBoss'],'direct');
   foreach my $grpid (keys(%groups)){
      if (!exists($selbox->{'Group:'.$groups{$grpid}->{fullname}})){
         $selbox->{'Group:'.$groups{$grpid}->{fullname}}={
            prio=>'1000'
         };   
      }
   }

   my $lnkrole=getModuleObject($app->Config,"base::lnkgrpuserrole");


   $lnkrole->SetFilter({userid=>\$userid,
                        nativrole=>['REmployee','RBoss','RBoss2',
                                    'RReportReceive','RQManager']});
   my %grpids;
   map({$grpids{$_->{grpid}}++} $lnkrole->getHashList("grpid"));
   my $grp=getModuleObject($app->Config,"base::grp");
   $grp->SetFilter([{grpid=>[keys(%grpids)]},
                    {parentid=>[keys(%grpids)]}]);
   map({$grpids{$_->{grpid}}++;
        $grpids{$_->{parentid}}++;} $grp->getHashList("grpid","parentid"));
   my @grpids=grep(!/^\s*$/,keys(%grpids));
   $grp->ResetFilter();
   $grp->SetFilter({grpid=>\@grpids});
   my @grps=$grp->getHashList("fullname","grpid");
                    

   my @grpnames;
   my @grpids;
   foreach my $r (@grps){
      push(@grpids,$r->{grpid});
      push(@grpnames,$r->{fullname});
      if (!exists($selbox->{'Group:'.$r->{fullname}})){
         $selbox->{'Group:'.$r->{fullname}}={
            prio=>'2000'
         };   
      }
   }

   $app->ResetFilter();
   $app->SecureSetFilter([
                           {dstrange=>\$dstrange,sgroup=>\'Group',
                            fullname=>\@grpnames,statstream=>\'default'},
                           {dstrange=>\$dstrange,sgroup=>\'Group',
                            nameid=>\@grpids,statstream=>\'default'},
                          ]);
   my @statnamelst=$app->getHashList(qw(fullname id));

   if ($#statnamelst==-1){   # seems to be the first day in month
      $app->ResetFilter();
      $app->SecureSetFilter([
                              {dstrange=>\$altdstrange,sgroup=>\'Group',
                               fullname=>\@grpnames},
                              {dstrange=>\$altdstrange,sgroup=>\'Group',
                               nameid=>\@grpids},
                             ]);
      @statnamelst=$app->getHashList(qw(fullname id));
   }
   my $c=0;
   foreach my $r (sort({$a->{fullname} cmp $b->{fullname}} @statnamelst)){
      $c++;
      if (exists($selbox->{'Group:'.$r->{fullname}})){
         $selbox->{'Group:'.$r->{fullname}}->{fullname}=$r->{fullname};
         $selbox->{'Group:'.$r->{fullname}}->{id}=$r->{id};
         $selbox->{'Group:'.$r->{fullname}}->{prio}+=$c;
      }
   }

   my %grp=$app->getGroupsOf($ENV{REMOTE_USER},
           ['RCFManager','RCFManager2'],"down");
   if (keys(%grp)){
      my $m=getModuleObject($app->Config,"base::mandator");
      $m->SetFilter({grpid=>[keys(%grp)],
                     cistatusid=>"<6"});


      my @idl=();
      foreach my $mrec ($m->getHashList(qw(name grpid))){
         push(@idl,$mrec->{grpid});
      }
      my @statnamelst;
      if ($#idl!=-1){
         $app->ResetFilter();
         $app->SecureSetFilter([
                                 {dstrange=>\$dstrange,sgroup=>\'Mandator',
                                  nameid=>\@idl},
                                ]);
         @statnamelst=$app->getHashList(qw(fullname id));
         if ($#statnamelst==-1){   # seems to be the first day in month
            msg(INFO,"w5stat/base: seems to be the first day in month");
            $app->ResetFilter();
            $app->SecureSetFilter([
                                    {dstrange=>\$altdstrange,sgroup=>\'Group',
                                     nameid=>\@idl},
                                   ]);
            @statnamelst=$app->getHashList(qw(fullname id));
         }
         foreach my $r (sort({$a->{fullname} cmp $b->{fullname}} @statnamelst)){
             if (!exists($selbox->{'Group:'.$r->{fullname}})){
                $selbox->{'Mandator:'.$r->{fullname}}={
                   id=>$r->{id},
                   fullname=>$r->{fullname},
                   prio=>'3000'
                };   
             }
         }
      }
   }






}


sub overviewW5Base
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my @flds=(
      "Base.Total.User.Count"               =>'W5Base total user count',
      "Base.Total.Group.Count"              =>'W5Base total group count',
      "Base.Total.Contact.Count"            =>'W5Base total contact count',
      "Base.Total.Workflow.Active.Count"    =>'W5Base total active workflows',
      "Base.Total.Workflow.Count"           =>'W5Base total workflows',
      "Base.Total.WorkflowAction.Count"     =>'W5Base total workflow actions',
      "Base.Total.UserLogon.Count"          =>'W5Base User Logon Entrys',
      "Base.Total.JobLog.Count"             =>'W5Base Job-Log Entrys',
   );

   while(my $k=shift(@flds)){
      my $label=shift(@flds);
      my $val=0;
      if (defined($primrec->{stats}->{$k})){
         $val=$primrec->{stats}->{$k}->[0];
         my $color="black";
         push(@l,[$app->T($label),$val,$color,undef]);
      }
   }   
   return(@l);
}

sub displayW5Base
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my $d;
   if ((!defined($primrec->{stats}->{'Base.Total.User.Count'}))&&
       (!defined($primrec->{stats}->{'Base.Total.Workflow.Count'}))){
      return(undef);
   }

   my @flds=("Base.Total.User.Count"     =>'Users',
             "Base.Total.Group.Count"    =>'Groups',
             "Base.Total.Contact.Count"  =>'Contacts',
             "Base.Total.Workflow.Active.Count"=>'active Workflows',
             "Base.Total.Workflow.Count"  
                                         =>'W5Base total workflows',
             "Base.Total.WorkflowAction.Count"  
                                         =>'W5Base total workflow actions',
             "Base.Total.UserLogon.Count"  
                                         =>'W5Base User Logon Entrys',
             "Base.Total.JobLog.Count"  
                                         =>'W5Base Job-Log Entrys',
             );

   while(my $k=shift(@flds)){
      my $label=shift(@flds);
      my $data=$app->extractYear($primrec,$hist,$k);
      my $v="Chart".$k;
      $v=~s/\./_/g;
      my $chart=$app->buildChart($v,$data,
                      width=>450,height=>200, label=>$app->T($label));
      $d.=$chart;

   }   
   return($d);
}


sub overviewDataIssue
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $keyname='base.DataIssue.open';
   my $users=0;
   if (defined($primrec->{stats}->{User})){
      $users=$primrec->{stats}->{User}->[0];
   }
   my $dataissues=0;
   if (defined($primrec->{stats}->{$keyname})){
      $dataissues=$primrec->{stats}->{$keyname}->[0];
   }
   my $color="goldenrod";
   if ($dataissues==0){
      $color="black";
   }
   my $delta=$app->calcPOffset($primrec,$hist,$keyname);
   if ($dataissues>($users*0.4) && $dataissues>5){
      $color="red";
   }
   if ($primrec->{sgroup} eq "Group"){
      push(@l,[$app->T('unprocessed DataIssue Workflows'),
               $dataissues,$color,$delta]);
   }

   my $keyname1='base.DataIssue.sleep56';
   my $dataissues=0;
   if (defined($primrec->{stats}->{$keyname1})){
      $dataissues=$primrec->{stats}->{$keyname1}->[0];
   }
   my $keyname2='base.DataIssue.dead';
   if (defined($primrec->{stats}->{$keyname2})){
      $dataissues+=$primrec->{stats}->{$keyname2}->[0];
   }

  
   my $color="goldenrod";
   if ($dataissues==0){
      $color="black";
   }
   my $delta=$app->calcPOffset($primrec,$hist,[$keyname1,$keyname2]);
   if ($dataissues>($users*0.4) && $dataissues>5){
      $color="red";
   }
   if ($dataissues>0){
      push(@l,[$app->T('untreaded DataIssues longer then 8 weeks'),
               $dataissues,$color,$delta]);
   }

   if ($#l!=-1){
      unshift(@l,[$app->T('DataIssue Workflows'),undef]);
   }

   my @wf;

   my $keyname1='base.Workflow.sleep56';
   my $wfcount=0;
   if (defined($primrec->{stats}->{$keyname1})){
      $wfcount=$primrec->{stats}->{$keyname1}->[0];
   }
   my $keyname2='base.Workflow.dead';
   if (defined($primrec->{stats}->{$keyname2})){
      $wfcount+=$primrec->{stats}->{$keyname2}->[0];
   }

   my $color="goldenrod";
   if ($wfcount==0){
      $color="black";
   }
   my $delta=$app->calcPOffset($primrec,$hist,[$keyname1,$keyname2]);
   if ($wfcount>($users*0.4) && $wfcount>5){
      $color="red";
   }

   if ($wfcount>0 && $wfcount!=$dataissues){
      push(@wf,[$app->T('workflows untreaded longer then 8 weeks'),
               $wfcount,$color,$delta]);
   }

   my $keyname='base.Workflow.dead';
   my $wfcount=0;
   if (defined($primrec->{stats}->{$keyname})){
      $wfcount=$primrec->{stats}->{$keyname}->[0];
   }

   my $color="red";
   if ($wfcount==0){
      $color="black";
   }
   my $delta=$app->calcPOffset($primrec,$hist,$keyname);
   if ($wfcount>0){
      push(@wf,[$app->T('count of consequent ignored workflow'),
               $wfcount,$color,$delta]);
   }

   if ($#wf!=-1){
      unshift(@wf,[$app->T('generally Workflow view'),undef]);
      push(@l,@wf);
   }

   return(@l);
}

sub displayWorkflowActivity
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   return() if ($primrec->{dstrange}=~m/KW/);
   my $showall=Query->Param("FullWorkflowList");
   #my $data=$app->extractYear($primrec,$hist,"base.DataIssue.IdList.open");
   my $data1=$app->extractYear($primrec,$hist,"base.Workflow.open",
                              setUndefZero=>1);
   my $data2=$app->extractYear($primrec,$hist,"base.Workflow.sleep28",
                              setUndefZero=>1);
   my $data3=$app->extractYear($primrec,$hist,"base.Workflow.sleep56",
                              setUndefZero=>1);
   my $data4=$app->extractYear($primrec,$hist,"base.Workflow.dead",
                              setUndefZero=>1);
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data1));
   my $chart1=$app->buildChart("ofcOpenWorkflows",$data1,
                   employees=>$user, 
                   label=>$app->T('open Workflows'),
                   legend=>$app->T('count of open Workflows'));

   my $chart2=$app->buildChart("ofcSleep28Workflows",$data2,
                   width=>400,height=>200,
                   label=>$app->T('Workflows untreaded longer then 4 weeks'),
                   legend=>$app->T('count of Workflows'));

   my $chart3=$app->buildChart("ofcSleep56Workflows",$data3,
                   width=>400,height=>200,
                   label=>$app->T('Workflows untreaded longer then 8 weeks'),
                   legend=>$app->T('count of Workflows'));

   my $chart4=$app->buildChart("ofcDeadWorkflows",$data4,
                   width=>400,height=>200,
                   label=>$app->T('Workflows untreaded longer then a half year'),
                   legend=>$app->T('count of Workflows'));

   my $wf_or=$primrec->{stats}->{'base.Workflow.sleep56.id'}->[0];
   my $wf_rd=$primrec->{stats}->{'base.Workflow.dead.id'}->[0];

   my @wfid=sort({$a<=>$b} grep(!/^\s*$/,split(/\s*,\s*/,$wf_rd.",".$wf_or)));


   my $wfidtmpl;
   if ($#wfid!=-1){
      my @usewfid=@wfid[0..20];
      if ($showall eq "1"){
         @usewfid=@wfid;
      }
      my $wf=getModuleObject($app->Config,"base::workflow");
      if (defined($wf)){
         $wf->SetFilter({id=>\@usewfid});
         my @wfl=$wf->getHashList(qw(name id state stateid fwdtargetname));
         if ($#wfl!=-1){
            $wfidtmpl.="<table border=0 cellspacing=2 cellpadding=0>";
            $wfidtmpl.="<tr>"; 
            $wfidtmpl.="<td colspan=2><b>".
                        $app->T("The related Worflow list").":</td>"; 
            $wfidtmpl.="</tr>"; 
            foreach my $WfRec (@wfl){
               my $statename=$wf->findtemplvar({current=>$WfRec},
                                               "state","formated");

               my $dest="../../base/workflow/ById/$WfRec->{id}";
               my $detailx=$wf->DetailX();
               my $detaily=$wf->DetailY();
               my $onclick="openwin(\"$dest\",\"_blank\",".
                   "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                   "resizable=yes,scrollbars=no\")";

               $wfidtmpl.="<tr>"; 
               $wfidtmpl.="<td valign=top><a class=exlink ".
                          "href=JavaScript:$onclick>".
                          $WfRec->{name}."</a>";
               if ($showall eq "1"){
                  $wfidtmpl.="<br>".$WfRec->{fwdtargetname};
               }
               $wfidtmpl.="</td>"; 
               $wfidtmpl.="<td width=10% valign=top nowrap>".
                          $statename."</td>"; 
               $wfidtmpl.="</tr>"; 
            }
            if ($#wfid>$#wfl){
               my $num=$#wfid-$#usewfid;
               $wfidtmpl.="<tr>"; 
               $wfidtmpl.="<td colspan=2><br><br>".
                          "<a class=exlink ".
                          "href=javascript:showFullDataIssue(this) ".
                          "title=\"".
                  $self->getParent->T("click to see full list","base::w5stat").
                          "\">... ($num ".
                          $self->getParent->T("more","base::w5stat").
                          ")</a></td>"; 
               $wfidtmpl.="</tr>"; 
            }
            $wfidtmpl.="</table>";
         }
      }
   }

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.WorkflowActivity",
                                 {current=>$primrec,
                                  static=>{
                                       statname=>$primrec->{fullname},
                                       chart1=>$chart1,
                                       chart2=>$chart2,
                                       chart3=>$chart3,
                                       chart4=>$chart4,
                                       detaillist=>$wfidtmpl
                                          },
                                  skinbase=>"base"});

   $d.=<<EOF;
<input type=hidden name=FullWorkflowList value="$showall">
<script language="JavaScript">
function showFullDataIssue()
{
   document.forms[0].elements['FullWorkflowList'].value='1'; 
   document.forms[0].submit();
}
</script>
EOF
   return($d);
}


sub displayDataIssue
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   return() if ($primrec->{dstrange}=~m/KW/);
   my $showall=Query->Param("FullDataIssueList");
   #my $data=$app->extractYear($primrec,$hist,"base.DataIssue.IdList.open");
   my $data=$app->extractYear($primrec,$hist,"base.DataIssue.open",
                              setUndefZero=>1);
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcDataIssue",$data,
                   employees=>$user, 
                   label=>$app->T('automaticly detected Data-Problems'),
                   legend=>$app->T('count of DataIssue Workflows'));

   my $wfid=$primrec->{stats}->{'base.DataIssue.IdList.open'}->[0];
   my @wfid=sort({$a<=>$b} grep(!/^\s*$/,split(/\s*,\s*/,$wfid)));
   my $wfidtmpl;
   if ($#wfid!=-1){
      my @usewfid=@wfid[0..20];
      if ($showall eq "1"){
         @usewfid=@wfid;
      }
      my $wf=getModuleObject($app->Config,"base::workflow");
      if (defined($wf)){
         $wf->SetFilter({id=>\@usewfid});
         my @wfl=$wf->getHashList(qw(name id state stateid fwdtargetname));
         if ($#wfl!=-1){
            $wfidtmpl.="<table border=0 cellspacing=2 cellpadding=0>";
            $wfidtmpl.="<tr>"; 
            $wfidtmpl.="<td colspan=2><b>".
                        $app->T("The related Worflow list").":</td>"; 
            $wfidtmpl.="</tr>"; 
            foreach my $WfRec (@wfl){
               my $statename=$wf->findtemplvar({current=>$WfRec},
                                               "state","formated");

               my $dest="../../base/workflow/ById/$WfRec->{id}";
               my $detailx=$wf->DetailX();
               my $detaily=$wf->DetailY();
               my $onclick="openwin(\"$dest\",\"_blank\",".
                   "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                   "resizable=yes,scrollbars=no\")";

               $wfidtmpl.="<tr>"; 
               $wfidtmpl.="<td valign=top><a class=exlink ".
                          "href=JavaScript:$onclick>".
                          $WfRec->{name}."</a>";
               if ($showall eq "1"){
                  $wfidtmpl.="<br>".$WfRec->{fwdtargetname};
               }
               $wfidtmpl.="</td>"; 
               $wfidtmpl.="<td width=10% valign=top nowrap>".
                          $statename."</td>"; 
               $wfidtmpl.="</tr>"; 
            }
            if ($#wfid>$#wfl){
               my $num=$#wfid-$#usewfid;
               $wfidtmpl.="<tr>"; 
               $wfidtmpl.="<td colspan=2><br><br>".
                          "<a class=exlink ".
                          "href=javascript:showFullDataIssue(this) ".
                          "title=\"".
                  $self->getParent->T("click to see full list","base::w5stat").
                          "\">... ($num ".
                          $self->getParent->T("more","base::w5stat").
                          ")</a></td>"; 
               $wfidtmpl.="</tr>"; 
            }
            $wfidtmpl.="</table>";
         }
      }
   }

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.DataIssue",
                                 {current=>$primrec,
                                  static=>{
                                       statname=>$primrec->{fullname},
                                       chart1=>$chart,
                                       detaillist=>$wfidtmpl
                                          },
                                  skinbase=>"base"});
   $d.=<<EOF;
<input type=hidden name=FullDataIssueList value="$showall">
<script language="JavaScript">
function showFullDataIssue()
{
   document.forms[0].elements['FullDataIssueList'].value='1'; 
   document.forms[0].submit();
}
</script>
EOF
   return($d);
}


sub displayOrg
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   return() if ($primrec->{dstrange}=~m/KW/);
   #my $data=$app->extractYear($primrec,$hist,"base.DataIssue.IdList.open");
   my $data=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   my $chart1=$app->buildChart("ofcUser",$data,
                   width=>400,height=>200,
                   label=>$app->T('total Users'));
   my $data=$app->extractYear($primrec,$hist,"User.Direct",
                              setUndefZero=>1);
   my $chart2=$app->buildChart("ofcUserDirect",$data,
                   width=>400,height=>200,
                   label=>$app->T('direct Users'));
   my $data=$app->extractYear($primrec,$hist,"SubGroups",
                              setUndefZero=>1);
   my $chart3=$app->buildChart("ofcSubGroups",$data,
                   width=>400,height=>200,
                   label=>$app->T('SubGroups'));
   return(undef) if (!defined($data));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.org",
                                 {current=>$primrec,
                                  static=>{
                                       statname=>$primrec->{fullname},
                                       chart1=>$chart1,
                                       chart2=>$chart2,
                                       chart3=>$chart3,
                                          },
                                  skinbase=>"base"});
   return($d);
}


sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my $count;

   return() if ($statstream ne "default");

     
   foreach my $objname (qw(base::workflow
                           base::workflowaction
                           base::userlogon
                           base::joblog
                           )){
      msg(INFO,"starting count of $objname");
      my $o=getModuleObject($self->getParent->Config,$objname);
      my $n=$o->CountRecords();
      msg(INFO,"result of $objname is $n");
      $self->getParent->processRecord($statstream,'objectcount',$dstrange,
                                      {objectname=>$objname,count=>$n});
   }

   msg(INFO,"starting collect of base::grp");
   my $grp=getModuleObject($self->getParent->Config,"base::grp");
   $grp->SetFilter({cistatusid=>\"4"});
   $grp->SetCurrentView(qw(ALL));
   msg(INFO,"getFirst of base::grp");$count=0;
   my ($rec,$msg)=$grp->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'base::grp',$dstrange,$rec);
         $count++;
         ($rec,$msg)=$grp->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::grp $count records");

   msg(INFO,"starting collect of base::user");
   my $user=getModuleObject($self->getParent->Config,"base::user");
   $user->SetFilter({cistatusid=>\"4"});
   $user->SetCurrentView(qw(ALL));
   msg(INFO,"getFirst of base::user");$count=0;
   my ($rec,$msg)=$user->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'base::user',$dstrange,$rec,%param);
         $count++;
         ($rec,$msg)=$user->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::user $count records");


   if (my ($year,$month)=$dstrange=~m/^(\d{4})(\d{2})$/){
      my @wfstat=qw(id eventstart class step eventend stateid mandatorid
                             fwdtarget fwdtargetid responsiblegrp mdate);
     
     
      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
     
      msg(INFO,"starting collect of base::workflow set1.1");
      $wf->SetFilter({eventend=>">=$month/$year AND <$month/$year+1M",
                      isdeleted=>\'0'});
      # not posible because sequential search
      #            {eventstart=>">=$month/$year AND <$month/$year+1M"}]);
      #            {eventstart=>"<$month/$year",eventend=>">$month/$year+1M"}]);
      $wf->SetCurrentView(@wfstat);
      $wf->SetCurrentOrder("NONE");
      my $c=0;
     
      msg(INFO,"getFirst of base::workflow set1.1");$count=0;
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            $self->getParent->processRecord($statstream,'base::workflow::active',
                                            $dstrange,$rec,%param);
            $count++;
            $c++;
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
      msg(INFO,"FINE of base::workflow set1.1 $count records");
     
      msg(INFO,"starting collect of base::workflow set1.2");
      $wf->ResetFilter();
      $wf->SetFilter({eventend=>"[EMPTY]",
                      isdeleted=>\'0'});
      $wf->SetCurrentView(@wfstat);
      $wf->SetCurrentOrder("NONE");
      my $c=0;
     
      msg(INFO,"getFirst of base::workflow set1.2");$count=0;
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            $self->getParent->processRecord($statstream,'base::workflow::active',
                                            $dstrange,$rec,%param);
            $count++;
            $c++;
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
      msg(INFO,"FINE of base::workflow set1.2 $count records");
     
      msg(INFO,"starting collect of base::workflow set2");
      $wf->ResetFilter();
      $wf->SetFilter([{stateid=>"<20",fwdtarget=>'![EMPTY]',
                       isdeleted=>\'0'}]);
      $wf->SetCurrentView(@wfstat);
      $wf->SetCurrentOrder("NONE");
      my $c=0;
     
      msg(INFO,"getFirst of base::workflow set2");$count=0;
      my ($rec,$msg)=$wf->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            if ($rec->{fwdtargetid} ne "15632883160001"){ # temp Hack for 
                                                          # secfinding wf test
               $self->getParent->processRecord($statstream,
                                               'base::workflow::notfinished',
                                               $dstrange,$rec,%param);
               $c++;
               $count++;
            }
            ($rec,$msg)=$wf->getNext();
         } until(!defined($rec));
      }
      msg(INFO,"FINE of base::workflow set2 $count records");
   }
}

sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;
   my %param=@_;

   return() if ($statstream ne "default");


   if ($module eq "objectcount"){
      if ($rec->{objectname} eq "base::workflow"){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "Base.Total.Workflow.Count",
                                        $rec->{count});
      }
      elsif ($rec->{objectname} eq "base::workflowaction"){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "Base.Total.WorkflowAction.Count",
                                        $rec->{count});
      }
      elsif ($rec->{objectname} eq "base::userlogon"){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "Base.Total.UserLogon.Count",
                                        $rec->{count});
      }
      elsif ($rec->{objectname} eq "base::joblog"){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "Base.Total.JobLog.Count",
                                        $rec->{count});
      }
   }
   elsif ($module eq "base::user"){
      $self->getParent->storeStatVar("Group",["admin"],{},
                                     "Base.Total.Contact.Count",1);
      if ($rec->{usertyp} eq "user"){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "Base.Total.User.Count",1);
      }
      my %grpnames;
      foreach my $grp (@{$rec->{groups}}){
         my $roles=$grp->{roles};
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         if (in_array($roles,[orgRoles(),"RMember"])){
            $grpnames{$grp->{group}}++;
         }
      }
      $self->getParent->storeStatVar("Group",[keys(%grpnames)],{},"User",1);
   }
   elsif ($module eq "base::grp"){
      my $name=$rec->{fullname};
      my $allusers=$rec->{users};
      $allusers=[] if (ref($allusers) ne "ARRAY");
      my $users=[];
      foreach my $user (@$allusers){
         push(@$users,$user) if ($user->{usertyp} ne "service");
      }
      my $subunits=$rec->{subunits};
      $subunits=[] if (ref($subunits) ne "ARRAY");

      my $subunitcount=$#{$subunits}+1;
      my $userscount=$#{$users}+1;


      $self->getParent->storeStatVar("Group",$name,{nameid=>$rec->{grpid}},
                                     "Groups",1);
      $self->getParent->storeStatVar("Group",$name,{maxlevel=>0},
                                     "SubGroups",$subunitcount);

      $self->getParent->storeStatVar("Group",$name,{maxlevel=>0},
                                     "User.Direct",$userscount);

      $self->getParent->storeStatVar("Group",["admin"],{},
                                     "Base.Total.Group.Count",1);
   }
   elsif ($module eq "base::workflow::notfinished"){
      my $mdate=$rec->{mdate};
      my $age=0;
      if ($mdate ne ""){
         my $d=CalcDateDuration($mdate,NowStamp("en"));
         $age=$d->{totalminutes};
      }
      if ($rec->{class} eq "base::workflow::DataIssue"){
         if ($rec->{stateid}!=5 && defined($rec->{responsiblegrp})){

            foreach my $resp (@{$rec->{responsiblegrp}}){
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.DataIssue.open",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "base.DataIssue.IdList.open",$rec->{id});
            }
         }
         my $mandatorids=$rec->{mandatorid};
         $mandatorids=[$mandatorids] if (ref($mandatorids) ne "ARRAY");
         if ($#{$mandatorids}!=-1){
            my $MandatorCache=$self->getParent->Cache->{Mandator}->{Cache};
            foreach my $mandatorid (@{$mandatorids}){
               my $mn=$MandatorCache->{grpid}->{$mandatorid}->{name};
               $self->getParent->storeStatVar("Mandator",$mn,{
                                                 nameid=>$mandatorid
                                              },"base.DataIssue.open",1);
               if ($rec->{stateid}!=5 && 
                   $rec->{class} eq "base::workflow::DataIssue"){ 
                  if ($age>259200){ # 1/2 Jahr
                     $self->getParent->storeStatVar("Mandator",$mn,{
                                                       nameid=>$mandatorid
                                                    },
                                                    "base.DataIssue.dead",1);
                  }
                  elsif ($age>80640){ # 8 Wochen
                     $self->getParent->storeStatVar("Mandator",$mn,{
                                                       nameid=>$mandatorid
                                                    },
                                                    "base.DataIssue.sleep56",1);
                  }
                  elsif ($age>40320){ # 4 Wochen
                     $self->getParent->storeStatVar("Mandator",$mn,{
                                                       nameid=>$mandatorid
                                                    },
                                                    "base.DataIssue.sleep28",1);
                  }
               }
            }
         }
      }
      if ($rec->{stateid}!=5){
         my @responsiblegrp;
         if (ref($rec->{responsiblegrp}) eq "ARRAY"){
            @responsiblegrp=@{$rec->{responsiblegrp}};
         }
         elsif ($rec->{fwdtarget} eq "base::grp"){
            @responsiblegrp=($rec->{fwdtargetname});
         }
         elsif ($rec->{fwdtarget} eq "base::user"){
            @responsiblegrp=("user");
         }
         else{
            @responsiblegrp=("admin");
         }
         
         if ($rec->{stateid}!=5 && 
             $rec->{class} eq "base::workflow::DataIssue"){ # 8 Wochen
            my $acc=$rec->{involvedcostcenter};
            if ($age>80640){
               if ($acc ne ""){
                  if ($rec->{involvedaccarea} ne ""){
                     $acc.='@'.$rec->{involvedaccarea};
                  }
                  $acc=~s/\./_/g;
                  $self->getParent->storeStatVar("Costcenter",$acc,{},
                                                 "base.DataIssue.sleep56",1);
                  $self->getParent->storeStatVar("Costcenter",$acc,
                                    {maxlevel=>1,method=>'concat'},
                                    "base.DataIssue.sleep56.id",$rec->{id});
               }
            }



            #if ($age>259200){
            #   if ($rec->{mandator} ne "" && $rec->{mandatorid} ne ""){
            #      $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
            #                                     {nameid=>$rec->{mandatorid},
            #                                      nosplit=>1},
            #                                     "base.DataIssue.dead",1);
            #   }
            #}
         }


         foreach my $resp (@responsiblegrp){
            if ($rec->{stateid}!=5 && 
                $rec->{class} eq "base::workflow::DataIssue"){ 
               if ($age>259200){ # 1/2 Jahr
                  $self->getParent->storeStatVar("Group",$resp,{},
                                                 "base.DataIssue.dead",1);
               }
               elsif ($age>80640){ # 8 Wochen
                  $self->getParent->storeStatVar("Group",$resp,{},
                                                 "base.DataIssue.sleep56",1);
               }
               elsif ($age>40320){ # 4 Wochen
                  $self->getParent->storeStatVar("Group",$resp,{},
                                                 "base.DataIssue.sleep28",1);
               }
            }
            $self->getParent->storeStatVar("Group",$resp,{},
                                           "base.Workflow.open",1);
            if ($age>259200){ # 1/2 Jahr
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.Workflow.dead",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "base.Workflow.dead.id",$rec->{id});

            }
            elsif ($age>80640){ # 8 Wochen
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.Workflow.sleep56",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "base.Workflow.sleep56.id",$rec->{id});

            }
            elsif ($age>40320){ # 4 Wochen
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.Workflow.sleep28",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "base.Workflow.sleep28.id",$rec->{id});
            }
            elsif ($age>20160){ # 2 Wochen
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.Workflow.sleep14",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "base.Workflow.sleep14.id",$rec->{id});
            }
            $self->getParent->storeStatVar("Group",$resp,
                              {maxlevel=>1,method=>'concat'},
                              "base.Workflow.IdList.open",$rec->{id});
            
         }
      }
      $self->getParent->storeStatVar("Group",["admin"],{},
                                     "Base.Total.Workflow.Active.Count",1);
   }
}


1;
