package base::ext::w5stat;
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
use Data::Dumper;
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
          'overview'=>{
                         opcode=>\&displayOverview,
                         prio=>1,
                      },
          'dataissue'=>{
                         overview=>\&overviewDataIssue,
                         opcode=>\&displayDataIssue,
                         prio=>2,
                      },
          'org'=>{
                         opcode=>\&displayOrg,
                         prio=>99999,
                      }
         );

}


sub processOverviewRecords
{
   my $self=shift;
   my $ovdata=shift;
   my $P=shift;
   my $primrec=shift;
   my $hist=shift;

   foreach my $p (sort({$P->{$a}->{prio} <=> $P->{$b}->{prio}} keys(%{$P}))){
      my $prec=$P->{$p};
      if (defined($prec) && defined($prec->{overview})){
         if (my @ov=&{$prec->{overview}}($prec->{obj},$primrec,$hist)){
            push(@{$ovdata},@ov);
         }
      }
   }
}

sub displayOverview
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my $d="";

   my @ovdata;


   my @Presenter;
   foreach my $obj (values(%{$app->{w5stat}})){
      if ($obj->can("getPresenter")){
         my %P=$obj->getPresenter();
         foreach my $p (values(%P)){
            $p->{module}=$obj->Self();
            $p->{obj}=$obj;
         }
         push(@Presenter,%P);
      }
   }
   my $P={@Presenter};
   $self->processOverviewRecords(\@ovdata,$P,$primrec,$hist);
   if (defined($primrec->{nameid}) && $primrec->{nameid} ne "" 
       && $primrec->{sgroup} eq "Group"){
      my $month=$primrec->{month};
      my $grp=getModuleObject($app->Config,"base::grp");
      $grp->SetFilter({parentid=>\$primrec->{nameid}});
      my @l=$grp->getHashList(qw(fullname grpid));
      if ($#l!=-1){
         foreach my $grprec (@l){
            my ($primrec,$hist)=$app->LoadStatSet(grpid=>$grprec->{grpid},
                                                   $month);
            if (defined($primrec)){
               push(@ovdata,[$primrec->{fullname}]);
               $self->processOverviewRecords(\@ovdata,$P,$primrec,$hist);

            }
         }
      }
   }
   $d.="\n<div class=overview>";
   $d.="<table width=100% height=70%>";
   my $class="unitdata";
   foreach my $rec (@ovdata){
      if ($#{$rec}!=0){
         my $color="black";
         if (defined($rec->[2])){
            $color=$rec->[2];
         }
         $d.="\n<tr height=1%>";
         $d.="<td><div class=\"$class\">".$rec->[0]."</div></td>";
         $d.="<td align=right width=50><font color=\"$color\"><b>".
             $rec->[1]."</b></font></td>";
         $d.="<td align=right width=50>".$rec->[3]."</td>";
         $d.="</tr>";
      }
      else{
         if ($class eq "unitdata"){
            $d.="\n<tr height=1%><td colspan=3>&nbsp;</td></tr>";
            $class="subunitdata";
         }
         $d.="\n<tr height=1%>";
         $d.="<td colspan=3><div class=subunit>".$app->T("Subunit").": ".
              $rec->[0]."</div></td>";
         $d.="</tr>";
      }
   }
   $d.="\n<tr><td colspan=3></td></tr>";
   $d.="</table>";
   $d.="</div>\n";
   return($d,\@ovdata);
}


sub overviewDataIssue
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;
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
   push(@l,[$app->T('unprocessed DataIssue Workflows'),
            $dataissues,$color,$delta]);
   return(@l);
}

sub displayDataIssue
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
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
      my $wf=getModuleObject($app->Config,"base::workflow");
      if (defined($wf)){
         $wf->SetFilter({id=>\@usewfid});
         my @wfl=$wf->getHashList(qw(name id state stateid));
         if ($#wfl!=-1){
            $wfidtmpl.="<table border=0 cellspacing=0 cellpadding=0>";
            $wfidtmpl.="<tr>"; 
            $wfidtmpl.="<td colspan=2><b>".
                        $app->T("The related Worflow list").":</td>"; 
            $wfidtmpl.="</tr>"; 
            foreach my $WfRec (@wfl){
               my $statename=$wf->findtemplvar({current=>$WfRec},
                                               "state","formated");

               my $dest="../../base/workflow/Detail?id=$WfRec->{id}";
               my $detailx=$wf->DetailX();
               my $detaily=$wf->DetailY();
               my $onclick="openwin(\"$dest\",\"_blank\",".
                   "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                   "resizable=yes,scrollbars=no\")";

               $wfidtmpl.="<tr>"; 
               $wfidtmpl.="<td><a href=JavaScript:$onclick>".
                          $WfRec->{name}."</a></td>"; 
               $wfidtmpl.="<td width=10%>".$statename."</td>"; 
               $wfidtmpl.="</tr>"; 
            }
            if ($#wfid>$#wfl){
               my $num=$#wfid-$#usewfid;
               $wfidtmpl.="<tr>"; 
               $wfidtmpl.="<td colspan=2>... ($num)</td>"; 
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
   return($d);
}


sub displayOrg
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
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
   my $monthstamp=shift;
   my $currentmonth=shift;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;
   my $count;


   msg(INFO,"starting collect of base::grp");
   my $grp=getModuleObject($self->getParent->Config,"base::grp");
   $grp->SetFilter({cistatusid=>\"4"});
   $grp->SetCurrentView(qw(ALL));
   msg(INFO,"getFirst of base::grp");$count=0;
   my ($rec,$msg)=$grp->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::grp',$monthstamp,$rec);
         $count++;
         ($rec,$msg)=$grp->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::grp $count records");


   my @wfstat=qw(id eventstart class step eventend stateid
                          fwdtarget fwdtargetid responsiblegrp);


   my $wf=getModuleObject($self->getParent->Config,"base::workflow");

   msg(INFO,"starting collect of base::workflow set1.1");
   $wf->SetFilter({eventend=>">=$month/$year AND <$month/$year+1M"});
   # not posible because sequential search
   #               {eventstart=>">=$month/$year AND <$month/$year+1M"}]);
   #               {eventstart=>"<$month/$year",eventend=>">$month/$year+1M"}]);
   $wf->SetCurrentView(@wfstat);
   $wf->SetCurrentOrder("NONE");
   my $c=0;

   msg(INFO,"getFirst of base::workflow set1.1");$count=0;
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::workflow::active',
                                         $monthstamp,$rec);
         $count++;
         $c++;
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::workflow set1.1 $count records");

   msg(INFO,"starting collect of base::workflow set1.2");
   $wf->SetFilter({eventend=>"[EMPTY]"});
   $wf->SetCurrentView(@wfstat);
   $wf->SetCurrentOrder("NONE");
   my $c=0;

   msg(INFO,"getFirst of base::workflow set1.2");$count=0;
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::workflow::active',
                                         $monthstamp,$rec);
         $count++;
         $c++;
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::workflow set1.2 $count records");

   msg(INFO,"starting collect of base::workflow set2");
   $wf->ResetFilter();
   $wf->SetFilter([{stateid=>"<20",fwdtarget=>'![EMPTY]'}]);
   $wf->SetCurrentView(@wfstat);
   $wf->SetCurrentOrder("NONE");
   my $c=0;

   msg(INFO,"getFirst of base::workflow set2");$count=0;
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord('base::workflow::notfinished',
                                         $monthstamp,$rec);
         $c++;
         $count++;
         ($rec,$msg)=$wf->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of base::workflow set2 $count records");


}

sub processRecord
{
   my $self=shift;
   my $module=shift;
   my $month=shift;
   my $rec=shift;

   if ($module eq "base::grp"){
      my $name=$rec->{fullname};
      my $users=$rec->{users};
      $users=[] if (ref($users) ne "ARRAY");
      my $subunits=$rec->{subunits};
      $subunits=[] if (ref($subunits) ne "ARRAY");

      my $subunitcount=$#{$subunits}+1;
      my $userscount=$#{$users}+1;


      $self->getParent->storeStatVar("Group",$name,{nameid=>$rec->{grpid}},
                                     "Groups",1);
      $self->getParent->storeStatVar("Group",$name,{maxlevel=>0},
                                     "SubGroups",$subunitcount);

      $self->getParent->storeStatVar("Group",$name,{},"User",$userscount);
      $self->getParent->storeStatVar("Group",$name,{maxlevel=>0},
                                     "User.Direct",$userscount);
   }
   elsif ($module eq "base::workflow::notfinished"){
      if ($rec->{class} eq "base::workflow::DataIssue"){
         if (ref($rec->{responsiblegrp}) eq "ARRAY"){
            foreach my $resp (@{$rec->{responsiblegrp}}){
               $self->getParent->storeStatVar("Group",$resp,{},
                                              "base.DataIssue.open",1);
               $self->getParent->storeStatVar("Group",$resp,
                                 {maxlevel=>1,method=>'concat'},
                                 "base.DataIssue.IdList.open",$rec->{id});
            }
         }
         msg(DEBUG,"response %s\n",Dumper($rec->{responsiblegrp}));
      }
   }
}


1;
