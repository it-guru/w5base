package itil::w5stat::base;
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
          'w5baseitil'=>{
                         opcode=>\&displayW5Base,
                         overview=>\&overviewW5Base,
                         group=>['Group','Application'],
                         prio=>500,
                      },
          'appl'=>{
                         opcode=>\&displayAppl,
                         overview=>\&overviewAppl,
                         group=>['Group'],
                         prio=>1000,
                      },
          'system'=>{
                         opcode=>\&displaySystem,
                         overview=>\&overviewSystem,
                         group=>['Group'],
                         prio=>1001,
                      },
          'asset'=>{
                         opcode=>\&displayAsset,
                         overview=>\&overviewAsset,
                         group=>['Group'],
                         prio=>1002,
                      },
          'swinstance'=>{
                         opcode=>\&displaySWInstance,
                         overview=>\&overviewSWInstance,
                         group=>['Group'],
                         prio=>1003,
                      },
          'itilchange'=>{
                         opcode=>\&displayChange,
                         prio=>1101,
                         group=>['Group'],
                      }
         );

}

sub overviewW5Base
{
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   if ($primrec->{sgroup} eq "Mandator"){
      my @flds=(
         "ITIL.Total.Application.Count"=>'W5Base total application count',
         "ITIL.Total.Asset.Count"      =>'W5Base total asset count',
         "ITIL.Total.System.Count"     =>'W5Base total system count',
         "ITIL.Total.SWInstance.Count" =>'W5Base total software-instance count',
         "ITIL.Total.Cloud.Count"      =>'W5Base total cloud count',
      );

      push(@l,[$app->T('Config-Items statistics'),undef]);

      my @statrec=($primrec);
      push(@statrec,$hist->{lastdstrange}) if (defined($hist->{lastdstrange}));

      my %kpaths=@flds; 
      my @kpaths=keys(%kpaths);
      foreach my $statrec ($primrec,$hist->{lastdstrange}){
         my $total=0; 
         if (ref($statrec->{stats}) eq "HASH"){
            foreach my $k (@kpaths){
               my $val=0;
               if (defined($statrec->{stats}->{$k})){
                  $val=$statrec->{stats}->{$k};
                  $val=$val->[0] if (ref($val) eq "ARRAY");
                  $statrec->{stats}->{$k}=$val;
                  $total+=$val;
               }
            }   
         }
         $statrec->{stats}->{'ITIL.Total.Count'}=$total;
      }

      while(my $k=shift(@flds)){
         my $label=shift(@flds);
         if (defined($primrec->{stats}->{$k})){
            my $val=$primrec->{stats}->{$k};
            my $color="black";
            my $delta=$app->calcPOffset($primrec,$hist,[$k]);
            push(@l,[$app->T($label),$val,$color,$delta]);
         }
      }

      my $total=$primrec->{stats}->{'ITIL.Total.Count'};
      my $delta=$app->calcPOffset($primrec,$hist,\@kpaths);


      push(@l,["<b>".
               $app->T("Total primary Config-Item count").
               "</b>",$total,"black",$delta]);

      my $total=$primrec->{stats}->{'ITIL.Total.Count'};
      my $dicnt=$primrec->{stats}->{'base.DataIssue.open'};
      if (ref($dicnt) eq "ARRAY"){
         $dicnt=$dicnt->[0];
      }

      my $dis56cnt=$primrec->{stats}->{'base.DataIssue.sleep56'};
      if (ref($dis56cnt) eq "ARRAY"){
         $dis56cnt=$dis56cnt->[0];
      }
      
      push(@l,["DataQuality",undef]);

      if ($total>0){  # prevent divsion by zero
         my $dipct=sprintf("%.2lf",100-($dicnt*100/$total));
         push(@l,[$app->T("DataIssue free primary Config-Items")
                  ,$dipct.'%',"black",""]);
      }

      if ($total>0){  # prevent divsion by zero
         my $dipct=sprintf("%.2lf",100-($dis56cnt*100/$total));
         push(@l,[$app->T("primary Config-Items without longtime DataIssue")
                  ,$dipct.'%',"black",""]);
      }

      my $totalRuleCount=$primrec->{stats}->{'ITIL.Total.QRuleCount'};
      if (ref($totalRuleCount) eq "ARRAY"){
         $totalRuleCount=$totalRuleCount->[0];
      }
      my $delta=$app->calcPOffset($primrec,$hist,"ITIL.Total.QRuleCount");
      push(@l,[$app->T("Total QRule count related to primary Config-Items")
               ,$totalRuleCount,"black",$delta]);


      my $totalRuleVio=$primrec->{stats}->{'base.DataIssue.open.rule.violated'};
      if (ref($totalRuleVio) eq "ARRAY"){
         $totalRuleVio=$totalRuleVio->[0];
      }
      if ($totalRuleCount>0){
         my $dipct=sprintf("%.2lf",100-($totalRuleVio*100/$totalRuleCount));
         push(@l,[
            $app->T("Proportion not violated QRules at primary Config-Items"),
                    $dipct.'%',"black",""]
         );
      }
      my $tRuleVioLt=
           $primrec->{stats}->{'base.DataIssue.sleep56.rule.violated'};
      if (ref($tRuleVioLt) eq "ARRAY"){
         $tRuleVioLt=$tRuleVioLt->[0];
      }
      if ($totalRuleCount>0){
         my $dipct=sprintf("%.2lf",100-($tRuleVioLt*100/$totalRuleCount));
         push(@l,[$app->T("Proportion not violated QRules by ".
                          "longtime DataIssues at primary Config-Items")
                  ,$dipct.'%',"black",""]);
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

   if ((!defined($primrec->{stats}->{'ITIL.Total.Application.Count'}))){
      return(undef);
   }


   my @flds=("ITIL.Total.Application.Count" =>'total Applications',
             "ITIL.Total.Asset.Count"       =>'total Assets',
             "ITIL.Total.System.Count"      =>'total Systems');
   
   while(my $k=shift(@flds)){ 
      my $label=shift(@flds);
      my $data=$app->extractYear($primrec,$hist,$k);
      my $v="Chart".$k;
      $v=~s/\./_/g;
      my $chart=$app->buildChart($v,$data,
                      width=>450,height=>200,
                      label=>$app->T($label));
      $d.=$chart;

   }   
   return($d);
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

   my @grpids=keys(%groups);




   if ($#grpids==-1){
      @grpids=(-99);
   }

   my $appl=getModuleObject($app->Config,"itil::appl");

   my @flt=(
      {
         cistatusid=>'3 4 5',
         databossid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         applmgrid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         tsmid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         opmid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         tsm2id=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         opm2id=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         itsemid=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         itsem2id=>\$userid
      },
      {
         cistatusid=>'3 4 5',
         secapplmgr2id=>\$userid
      }
   );


   $appl->SetFilter(\@flt);
   my @l=$appl->getHashList(qw(id name));
   my @applname;
   my @applid;
   foreach my $r (@l){
      push(@applid,$r->{id});
      push(@applname,$r->{name});
      if (!exists($selbox->{'Application:'.$r->{name}})){
         $selbox->{'Application:'.$r->{name}}={
            prio=>'9000'
         };   
      }
   }

   $app->ResetFilter();
   $app->SetFilter([
                           {dstrange=>\$dstrange,sgroup=>\'Application',
                            fullname=>\@applname,statstream=>\'default'},
                           {dstrange=>\$dstrange,sgroup=>\'Application',
                            nameid=>\@applid,statstream=>\'default'},
                          ]);
   my @statnamelst=$app->getHashList(qw(fullname id));

   if ($#statnamelst==-1){   # seems to be the first day in month
      $app->ResetFilter();
      $app->SecureSetFilter([
                              {dstrange=>\$altdstrange,sgroup=>\'Application',
                               fullname=>\@applname},
                              {dstrange=>\$altdstrange,sgroup=>\'Application',
                               nameid=>\@applid},
                             ]);
      @statnamelst=$app->getHashList(qw(fullname id));
   }
   my $c=0;
   foreach my $r (sort({$a->{fullname} cmp $b->{fullname}} @statnamelst)){
      $c++;
      if (exists($selbox->{'Application:'.$r->{fullname}})){
         $selbox->{'Application:'.$r->{fullname}}->{fullname}=$r->{fullname};
         $selbox->{'Application:'.$r->{fullname}}->{id}=$r->{id};
         $selbox->{'Application:'.$r->{fullname}}->{prio}+=$c;
      }
   }
}




sub overviewAppl
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   if ($primrec->{sgroup} eq "Application"){
      my $keyname='ITIL.Change.Finish.Count';
      my $n=0;
      if (defined($primrec->{stats}->{$keyname})){
         $n=$primrec->{stats}->{$keyname}->[0];
      }
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('finished Changes'),
                  $n,$color,$delta]);
   }
   if ($primrec->{sgroup} eq "Application"){
      my $keyname='ITIL.Incident.Finish.Count';
      my $n=0;
      if (defined($primrec->{stats}->{$keyname})){
         $n=$primrec->{stats}->{$keyname}->[0];
      }
      my $color="black";
      my $delta=$app->calcPOffset($primrec,$hist,$keyname);
      push(@l,[$app->T('finished Incidents'),
                  $n,$color,$delta]);
   }

   #if (defined($primrec->{stats}->{$keyname})){
   #   my $color="black";
   #   my $delta=$app->calcPOffset($primrec,$hist,$keyname);
   #   push(@l,[$app->T('Count of Application Config-Items'),
   #            $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   #}

   return(@l);
}

sub displayAppl
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.Application.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcAppl",$data,
                   employees=>$user,
                   label=>$app->T('Applications'),
                   legend=>$app->T('count of applications'));
   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.appl",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub overviewSystem
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   if ($primrec->{sgroup} eq "Application"){
      my $keyname='ITIL.System.Count';
      if (defined($primrec->{stats}->{$keyname})){
         my $color="black";
         my $delta=$app->calcPOffset($primrec,$hist,$keyname);
         push(@l,[$app->T('Count of System Config-Items'),
                  $primrec->{stats}->{$keyname}->[0],$color,$delta]);
      }
   }
   return(@l);
}

sub displaySystem
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data1=$app->extractYear($primrec,$hist,"ITIL.System.Count");
   my $data2=$app->extractYear($primrec,$hist,"ITIL.Operation.System.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data1) && !defined($data2));

   my $d="";

   if (defined($data1)){
      my $chart1=$app->buildChart("ofcSystem",$data1,
                      employees=>$user,
                      label=>$app->T('logical systems'),
                      legend=>$app->T('administrated logical systems'));
      $d.=$app->getParsedTemplate("tmpl/ext.w5stat.system",
                                 {current=>$primrec,
                                  static=>{
                                       statname=>$primrec->{fullname},
                                       chart1=>$chart1
                                          },
                                  skinbase=>'itil'
                                 });
   }
   if (defined($data2) && scalar(grep({defined($_)} @$data2))>0){
      $d.="<br><br><br>" if ($d ne "");
      my $chart2=$app->buildChart("ofcSystem2",$data2,
                      employees=>$user,
                      label=>$app->T('logical systems'),
                      legend=>$app->T('operated logical systems'));
      $d.=$app->getParsedTemplate("tmpl/ext.w5stat.system2",
                                 {current=>$primrec,
                                  static=>{
                                       statname=>$primrec->{fullname},
                                       chart2=>$chart2
                                          },
                                  skinbase=>'itil'
                                 });
   }
   return($d);
}


sub overviewAsset
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='ITIL.Asset.Count';
   #if (defined($primrec->{stats}->{$keyname})){
   #   my $color="black";
   #   my $delta=$app->calcPOffset($primrec,$hist,$keyname);
   #   push(@l,[$app->T('Count of Asset Config-Items'),
   #            $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   #}
   return(@l);
}

sub displayAsset
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.Asset.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcAsset",$data,
                   employees=>$user,
                   label=>$app->T('assets'),
                   legend=>$app->T('count of physical systems'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.asset",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub displayChange
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.Change.Finish.Count");
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcChange",$data,
                   label=>$app->T('changes'),
                   legend=>$app->T('count of changes by businessteam'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.changes",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}


sub overviewSWInstance
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   my $app=$self->getParent();
   my @l;

   my $keyname='ITIL.SWInstance.Count';
   #if (defined($primrec->{stats}->{$keyname})){
   #   my $color="black";
   #   my $delta=$app->calcPOffset($primrec,$hist,$keyname);
   #   push(@l,[$app->T('Count of Instance Config-Items'),
   #            $primrec->{stats}->{$keyname}->[0],$color,$delta]);
   #}
   return(@l);
}

sub displaySWInstance
{  
   my $self=shift;
   my ($primrec,$hist)=@_;
   return() if ($primrec->{dstrange}=~m/KW/);
   my $app=$self->getParent();
   my $data=$app->extractYear($primrec,$hist,"ITIL.SWInstance.Count");
   my $user=$app->extractYear($primrec,$hist,"User",
                              setUndefZero=>1);
   return(undef) if (!defined($data));
   my $chart=$app->buildChart("ofcSWInstance",$data,
                   employees=>$user,
                   label=>$app->T('swinstance'),
                   legend=>$app->T('count of software instances'));

   my $d=$app->getParsedTemplate("tmpl/ext.w5stat.swinstance",
                              {current=>$primrec,
                               static=>{
                                    statname=>$primrec->{fullname},
                                    chart1=>$chart
                                       },
                               skinbase=>'itil'
                              });
   return($d);
}




sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my ($year,$month)=$dstrange=~m/^(\d{4})(\d{2})$/;
   my $count;

   return() if ($statstream ne "default");


   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetCurrentView(qw(ALL));
   $appl->SetFilter({cistatusid=>'<=4'});
   $appl->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::appl");$count=0;
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'itil::appl',
                                         $dstrange,$rec,%param);
         ($rec,$msg)=$appl->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::appl  $count records");

   my $swinstance=getModuleObject($self->getParent->Config,"itil::swinstance");
   $swinstance->SetCurrentView(qw(ALL));
   $swinstance->SetFilter({cistatusid=>'<=4'});
   $swinstance->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::swinstance");$count=0;
   my ($rec,$msg)=$swinstance->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'itil::swinstance',
                                         $dstrange,$rec, %param);
         ($rec,$msg)=$swinstance->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::swinstance  $count records");



   my $system=getModuleObject($self->getParent->Config,"itil::system");
   $system->SetFilter({cistatusid=>'<=4'});
   $system->SetCurrentView(qw(ALL));
   $system->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::system");$count=0;
   my ($rec,$msg)=$system->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'itil::system',$dstrange,$rec,%param);
         $count++;
         ($rec,$msg)=$system->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::system  $count records");


   my $asset=getModuleObject($self->getParent->Config,"itil::asset");
   $asset->SetFilter({cistatusid=>'<=4'});
   $asset->SetCurrentView(qw(ALL));
   $asset->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::asset");$count=0;
   my ($rec,$msg)=$asset->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'itil::asset',
                                         $dstrange,$rec,%param);
         $count++;
         ($rec,$msg)=$asset->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::asset  $count records");


   my $itcloud=getModuleObject($self->getParent->Config,"itil::itcloud");
   $itcloud->SetFilter({cistatusid=>'<=4'});
   $itcloud->SetCurrentView(qw(ALL));
   $itcloud->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of itil::itcloud");$count=0;
   my ($rec,$msg)=$itcloud->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'itil::itcloud',
                                         $dstrange,$rec,%param);
         $count++;
         ($rec,$msg)=$itcloud->getNext();
      } until(!defined($rec));
   }
   msg(INFO,"FINE of itil::itcloud  $count records");



}


sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my %param=@_;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   return() if ($statstream ne "default");

   my $qruleact=$self->getParent->getPersistentModuleObject("lnkqrule",
                                                     "base::lnkqrulemandator");

   if ($module eq "itil::appl"){
      my $name=$rec->{name};
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{businessteam},
                                                 $rec->{responseteam}],{},
                                        "ITIL.Application.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Application.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.Application.Count",1);
         my $systemcount=$#{$rec->{systems}}+1;
         $self->getParent->storeStatVar("Application",[$rec->{name}],
                                        {nameid=>$rec->{id},
                                         nosplit=>1},
                                        "ITIL.System.Count",$systemcount);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.Application.Count",1);
         ######################################################################
         # QRule count for ::appl
         $qruleact->SetFilter([{
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::appl',
            expiration=>'>now'
         },
         {
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::appl',
            expiration=>undef
         }]);
         $qruleact->SetCurrentView(qw(id));
         my $nrule=$qruleact->SoftCountRecords();
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.Application.QRuleCount",
                                        $nrule);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.QRuleCount",
                                        $nrule);
         ######################################################################
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         method=>'ucount',
                                         nosplit=>1},
                                        "base.Databoss.Count",
                                        $rec->{databossid});
      }
   }
   if ($module eq "itil::system"){
      if ($rec->{cistatusid}==4){
         my %businessteam;
         foreach my $appl (@{$rec->{applications}}){
            if ($appl->{businessteam} ne ""){
               $businessteam{$appl->{businessteam}}++;
            }
         }
         if (keys(%businessteam)){
            $self->getParent->storeStatVar("Group",[keys(%businessteam)],{},
                                           "ITIL.Operation.System.Count",1);
         }

         $self->getParent->storeStatVar("Group",[$rec->{adminteam}],{},
                                        "ITIL.System.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.System.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.System.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.System.Count",1);
         ######################################################################
         # QRule count for ::system
         $qruleact->SetFilter([{
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::system',
            expiration=>'>now'
         },
         {
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::system',
            expiration=>undef
         }]);
         $qruleact->SetCurrentView(qw(id));
         my $nrule=$qruleact->SoftCountRecords();
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.System.QRuleCount",
                                        $nrule);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.QRuleCount",
                                        $nrule);
         ######################################################################
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         method=>'ucount',
                                         nosplit=>1},
                                        "base.Databoss.Count",
                                        $rec->{databossid});
      }
   }
   if ($module eq "itil::swinstance"){
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{swteam}],{},
                                        "ITIL.SWInstance.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.SWInstance.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.SWInstance.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.SWInstance.Count",1);
         ######################################################################
         # QRule count for ::swinstance
         $qruleact->SetFilter([{
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::swinstance',
            expiration=>'>now'
         },
         {
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::swinstance',
            expiration=>undef
         }]);
         $qruleact->SetCurrentView(qw(id));
         my $nrule=$qruleact->SoftCountRecords();
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.SWInstance.QRuleCount",
                                        $nrule);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.QRuleCount",
                                        $nrule);
         ######################################################################
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         method=>'ucount',
                                         nosplit=>1},
                                        "base.Databoss.Count",
                                        $rec->{databossid});
      }
   }
   if ($module eq "itil::asset"){
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{guardianteam}],{},
                                        "ITIL.Asset.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Asset.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.Asset.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.Asset.Count",1);
         ######################################################################
         # QRule count for ::asset
         $qruleact->SetFilter([{
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::asset',
            expiration=>'>now'
         },
         {
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::asset',
            expiration=>undef
         }]);
         $qruleact->SetCurrentView(qw(id));
         my $nrule=$qruleact->SoftCountRecords();
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.Asset.QRuleCount",
                                        $nrule);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.QRuleCount",
                                        $nrule);
         ######################################################################
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         method=>'ucount',
                                         nosplit=>1},
                                        "base.Databoss.Count",
                                        $rec->{databossid});
      }
   }
   if ($module eq "itil::itcloud"){
      if ($rec->{cistatusid}==4){
         $self->getParent->storeStatVar("Group",[$rec->{swteam}],{},
                                        "ITIL.Cloud.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Cloud.Count",1);
      }
      if ($rec->{cistatusid}<=5){
         $self->getParent->storeStatVar("Group",["admin"],{},
                                        "ITIL.Total.Cloud.Count",1);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.Cloud.Count",1);
         ######################################################################
         # QRule count for ::itcloud
         $qruleact->SetFilter([{
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::itcloud',
            expiration=>'>now'
         },
         {
            mandatorid=>\$rec->{mandatorid},
            cistatusid=>\'4',
            dataobj=>'*::itcloud',
            expiration=>undef
         }]);
         $qruleact->SetCurrentView(qw(id));
         my $nrule=$qruleact->SoftCountRecords();
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.Cloud.QRuleCount",
                                        $nrule);
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         nosplit=>1},
                                        "ITIL.Total.QRuleCount",
                                        $nrule);
         ######################################################################
         $self->getParent->storeStatVar("Mandator",[$rec->{mandator}],
                                        {nameid=>$rec->{mandatorid},
                                         method=>'ucount',
                                         nosplit=>1},
                                        "base.Databoss.Count",
                                        $rec->{databossid});
      }
   }
   if ($module eq "base::workflow::active"){
      my $countvar;
      $countvar="ITIL.Change.Finish.Count" if ($rec->{class}=~m/::change$/);
      $countvar="ITIL.Incident.Finish.Count" if ($rec->{class}=~m/::incident$/);
      $countvar="ITIL.Problem.Finish.Count" if ($rec->{class}=~m/::problem$/);
      $countvar="ITIL.Devrequest.Finish.Count" if ($rec->{class}=~m/::devrequest$/);
      my @affectedapplication=$rec->{affectedapplication};
      if (ref($rec->{affectedapplication}) eq "ARRAY"){
         @affectedapplication=@{$rec->{affectedapplication}};
      }
      my @affectedapplicationid=$rec->{affectedapplicationid};
      if (ref($rec->{affectedapplicationid}) eq "ARRAY"){
         @affectedapplicationid=@{$rec->{affectedapplicationid}};
      }
      my @affectedcontract=$rec->{affectedcontract};
      if (ref($rec->{affectedcontract}) eq "ARRAY"){
         @affectedcontract=@{$rec->{affectedcontract}};
      }
      my $eend=0;
      if ($rec->{eventend} ne ""){
         my ($eyear,$emonth)=$rec->{eventend}=~m/^(\d{4})-(\d{2})-.*$/;
         $eend=1 if ($eyear==$year && $emonth==$month);
      }
      if ($countvar ne ""){
         foreach my $contract (@affectedcontract){
            $self->getParent->storeStatVar("Contract",$contract,
                                           {nosplit=>1},
                                           $countvar,1) if ($eend);
            if ($rec->{class}=~m/::incident$/){
               $self->getParent->storeStatVar("Contract",$contract,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Incident",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
         }
         foreach my $appl (@affectedapplication){
            $self->getParent->storeStatVar("Application",$appl,{nosplit=>1},
                                           $countvar,1) if ($eend);
            if ($rec->{class}=~m/::incident$/){
               $self->getParent->storeStatVar("Application",$appl,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Incident",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
            elsif ($rec->{class}=~m/::change$/){
               $self->getParent->storeStatVar("Application",$appl,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Change",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
            elsif ($rec->{class}=~m/::problem$/){
               $self->getParent->storeStatVar("Application",$appl,
                                              {nosplit=>1,
                                               method=>'tspan.union'},
                                              "ITIL.Problem",
                                              $rec->{eventstart},
                                              $rec->{eventend});
            }
         }
         my $involvedresponseteam=$rec->{involvedresponseteam};
         my $involvedbusinessteam=$rec->{involvedbusinessteam};
         if (!ref($involvedresponseteam)){
            $involvedresponseteam=[$involvedresponseteam];
         }
         if (!ref($involvedbusinessteam)){
            $involvedbusinessteam=[$involvedbusinessteam];
         }
         my @groups=();
         push(@groups,@$involvedresponseteam);
         push(@groups,@$involvedbusinessteam);
         $self->getParent->storeStatVar("Group",
                         \@groups,{},$countvar,1) if ($eend);
         if ($rec->{class}=~m/::incident$/){
            $self->getParent->storeStatVar("Group",\@groups,
                      {method=>'tspan.union'},
                     "ITIL.Incident",
                     $rec->{eventstart},$rec->{eventend});
         }
      }
   }
}


1;
