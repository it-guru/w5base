package tsAPR::w5stat::base;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::date;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);

   $self->{Colors}=[
      red=>'not acceptable',
      yellow=>'problmeatic or soon problematic',
      blue=>'risk acceptance exists',
      green=>'alright',
      gray=>'unidentifiable'
   ];
   return($self);
}

sub getPresenter
{
   my $self=shift;

   my @l=(
          'APR'=>{
                         opcode=>\&displayAPR,
                         overview=>undef,
                         group=>['Application','Group'],
                         prio=>5100,
                      }
         );

}


sub processDataInit
{
   my $self=shift;
   my $datastream=shift;
   my $dstrangestamp=shift;
   my %param=@_;
   my $app=$self->getParent;


  my $o=getModuleObject($app->Config,"itil::softwareset");
   $o->SetFilter({name=>'"TEL-IT Patchmanagement*"',
                  cistatusid=>\'4'});
   my @nativeroadmapname=$o->getHashList(qw(id name));
   my @roadmapname;
   my @mroadmaps;     # Roadmaps on month base
   foreach my $r (@nativeroadmapname){
      if (my ($year,$month)=$r->{name}
          =~m/^TEL-IT Patchmanagement\s*([0-9]{4})[\/-]([0-9]{2})$/){
         push(@mroadmaps,{
            id=>$r->{id},
            name=>$r->{name},
            month=>$month,
            year=>$year,
            k=>sprintf("%04d%02d",$year,$month),
         });
      }
   }
   my ($cy,$cm)=Today_and_Now("GMT");
   my $ckey=sprintf("%04d%02d",$cy,$cm);
   if ($#mroadmaps!=-1){
      @mroadmaps=grep({$_->{k} le $ckey} sort({$a->{k}<=>$b->{k}} @mroadmaps));
      if ($#mroadmaps!=-1){
         @mroadmaps=($mroadmaps[-1]);
      }
   }
   if ($#mroadmaps==-1){
      @roadmapname=grep({$_->{name} eq "TEL-IT Patchmanagement"}
                        @nativeroadmapname);
   }
   else{
      @roadmapname=@mroadmaps;
   }
   #print Dumper(\@roadmapname);
   $self->{Roadmap}=\@roadmapname;
}
























sub SignImg
{
   my $name=shift;

   $name="gray" if ($name eq "");

   return("<img width=13 height=13 src=\"../../base/load/sign_$name.gif\">");
}

sub Legend
{
   my $self=shift;
   my @colors=@{$self->{Colors}};

   my $d="";
   $d.="<table class=statTab style=\"width:auto\">";
   while(my $color=shift(@colors)){
      my $legend=shift(@colors);
      $d.="<tr><td class=fixColor>".SignImg($color)."</td>";
      $d.="<td class=fixColor>".$self->getParent->T($legend)."</td></tr>";
   }
   $d.="</table>";

   return($d);
}


sub mkSegBar
{
   my $self=shift;
   my $name=shift;
   my $data=shift;

   my $d="<div id=\"$name\"></div>";
   $d.="<script language=JavaScript>\n";
   $d.='$(document).ready(function(){';
   $d.="\$(\"#$name\").segbar([\n";
   $d.='{';
   $d.=" data:[\n";
   for(my $c=0;$c<=$#{$data};$c++){
      $d.="," if ($c>0);
      $d.="{title:'".$data->[$c]->{value}."',";
      $d.="value:".$data->[$c]->{value}.",";
      $d.="color:'".$data->[$c]->{color}."'}";
   }
   $d.="],\n";
   $d.=' height:"40px"';
   $d.='}';
   $d.=']);';
   $d.='});';
   $d.='</script>';


   return($d);

}

sub mkSegBarDSet
{
   my $self=shift;
   my $appkpi=shift;
   my $namespace=shift;
   my @ds;

   my @colors=@{$self->{Colors}};
   while(my $color=shift(@colors)){
      my $legend=shift(@colors);
      my $v=$appkpi->{$namespace.".".$color};
      if ($v>0){
         my $rec={
            value=>$v,
            color=>$color
         };
         push(@ds,$rec);
      }
   }
   push(@ds,{value=>'0',color=>'black'}) if ($#ds==0);
   return(\@ds);
}

sub DIsplit
{
   my $DIstr=shift;

   if ($DIstr eq ""){
      return(undef,"green");
   }
   my $DIcolor="red";
   my $DIid=$DIstr;
   my @di=split(/,/,$DIstr);
   if ($di[1] ne ""){
      $DIcolor=$di[1];      
      $DIid=$di[0];      
   }
   return($DIid,$DIcolor);
}

sub displayAPR
{  
   my $self=shift;
   my ($primrec,$hist)=@_;


   my $rmostat;
   foreach my $substatstream (@{$primrec->{statstreams}}){
      if ($substatstream->{statstream} eq "APR"){
         $rmostat=$substatstream;
      }
   }
   return() if (!defined($rmostat));


   my $app=$self->getParent();
   #my $user=$app->extractYear($primrec,$hist,"User",
   #                           setUndefZero=>1);

   my $d="";
   my $applcnt=0;
   if (exists($rmostat->{stats}->{'APR.Appl.Count'})){
      $applcnt=$rmostat->{stats}->{'APR.Appl.Count'}->[0];
   }


   my @s;
   my @a;
   my @appl;
   my %a;
   my @i;
   my @swinst;
   my %DIid;
   if (exists($rmostat->{stats}->{'APR.Appl.List'})){
      @appl=map({
         my @fld=split(/;/,$_);
         my $pos=0; 
         my $rec={id=>$fld[$pos++]};
         $rec->{name}=$fld[$pos++];
         $rec->{index}=$fld[$pos++];
         $rec;
      } @{$rmostat->{stats}->{'APR.Appl.List'}});
   }

   my $applById;
   if (1){
      my $o=$app->getPersistentModuleObject("itil::appl");
      my @ids=map({$_->{id}} @appl);
      if ($primrec->{sgroup} eq "Application" &&
          $primrec->{nameid} ne ""){
         push(@ids,$primrec->{nameid});
      }
      $o->SetFilter({id=>\@ids});
      $applById=$o->getHashIndexed(qw(id));
   }



   if ($rmostat->{sgroup} eq "Application"){
      my $applname=$primrec->{fullname};
      if ($primrec->{nameid} ne "" &&
          exists($applById->{id}->{$primrec->{nameid}})){
         $applname=$app->OpenByIdWindow("itil::appl",
                                        $primrec->{nameid},$applname);
      }
      if ($applcnt){
         $d.=sprintf($app->T("APPISRELEVANT"),$applname);
      }
      else{
         $d.=sprintf($app->T("APPISNOTRELEVANT"),$applname);
      }
      if (exists($rmostat->{stats}->{'APR.System'})){
         @s=map({
            my @fld=splitCsvLine($_);
            my $pos=0; 
            my $rec={id=>$fld[$pos++]};
            $rec->{name}=$fld[$pos++];
            $rec->{systemid}=$fld[$pos++];
            $rec->{check_status_color}=$fld[$pos++];
            $rec->{days_not_patched}=$fld[$pos++];
            $rec->{red_alert}=$fld[$pos++];
            $rec->{roadmap}=$fld[$pos++];
            $rec->{os_base_setup}=$fld[$pos++];
            $rec->{os_base_setup_color}=$fld[$pos++];
            $rec->{roadmap_color}=$fld[$pos++];
            $rec->{roadmap_state}=$fld[$pos++];
            $rec;
         } @{$rmostat->{stats}->{'APR.System'}});
      }
      if (exists($rmostat->{stats}->{'APR.SoftwareInst'})){
         @swinst=map({
            my @fld=split(/;/,$_);
            my $pos=0; 
            my $rec={id=>$fld[$pos++]};
            $rec->{dataobj}=$fld[$pos++];
            $rec->{refid}=$fld[$pos++];
            $rec->{fullname}=$fld[$pos++];
            $rec->{instrating}=$fld[$pos++];
            $rec->{ratingmsg}=$fld[$pos++];
            $rec;
         } @{$rmostat->{stats}->{'APR.SoftwareInst'}});
          
      }


   }

   my $appkpi;
   my $showLegend=0;

   my %colors=@{$self->{Colors}};
   foreach my $color (keys(%colors)){
      foreach my $prefix (qw(APR.SoftwareInst.Rating 
                             APR.System.TCC.check_status
                             APR.System.TCC.os_base_setup
                             APR.System.TCC.roadmap)){
         $appkpi->{$prefix.".".$color}=0;
      }
   }
   #if ($rmostat->{sgroup} eq "Application"){
   #   foreach my $rec (@swinst){
   #      my $color=$rec->{instrating};
   #      $appkpi->{'APR.SoftwareInst.Rating.'.$color}++;
   #   }
   #}
   if ($rmostat->{sgroup} eq "Group" ||
       $rmostat->{sgroup} eq "Application"){
      foreach my $color (keys(%colors)){
         foreach my $prefix (qw(
                                APR.SoftwareInst.Rating
                                APR.System.TCC.check_status
                                APR.System.TCC.os_base_setup
                                APR.System.TCC.roadmap
                                )){
            if (exists($rmostat->{stats}->{$prefix.".".$color})){
               $appkpi->{$prefix.".".$color}=
                  $rmostat->{stats}->{$prefix.".".$color}->[0];
            }
         }
      }
   }
   foreach my $color (keys(%colors)){
      foreach my $prefix (qw(APR.System.TCC.os 
                             APR.SoftwareInst.Rating
                             APR.Asset.age 
                             APR.DataIssue)){
         if ($appkpi->{$prefix.".".$color}==0){
            delete($appkpi->{$prefix.".".$color});
         }
         else{
            $showLegend++;
         }
      }
   }

   if ($rmostat->{sgroup} eq "Group"){
      $d.="<table class=statTab style=\"width:70%\">";
      $d.=sprintf("<tr><td>APR relevante Anwendungen:</td>".
                  "<td>%d</td></tr>",$applcnt);
      if (exists($rmostat->{stats}->{'APR.System.Count'})){
         $d.=sprintf("<tr><td nowrap>von APR relevanten Anwendungen ".
                     "verwendete logische Systeme:</td><td>%d</td></tr>",
                     $rmostat->{stats}->{'APR.System.Count'}->[0]);
      }
      if (exists($rmostat->{stats}->{'APR.SoftwareInst.Count'})){
         $d.=sprintf("<tr><td nowrap>Software-Installationen die ".
                     "von APR relevanten ".
                     "Anwendungen genutzt werden:</td><td>%d</td></tr>",
                     $rmostat->{stats}->{'APR.SoftwareInst.Count'}->[0]);
      }
      $d.="</table>";
      $d.="Die Kennzahlen werden immer bezogen auf eine Anwendung ermittelt ".
          "und dann bezogen auf Betriebsteam/Betriebsbereich und Mandant ".
          "auf alle darüberliegenden Organisationsebenen agregiert. ".
          "Dies bedeutet, dass wenn z.B. einen Hardware von mehreren ".
          "Anwendungen verwendet wird, kann es zu Mehrfachzählungen kommen.";
   }



   $d.="<hr>";
   if (grep(/^APR.SoftwareInst.Rating/,keys(%{$appkpi}))){
      $d.="<h3>Software-Installationen (TelekomIT Roadmap bewertet):</h3>";
      $d.="Software:";
      $d.=$self->mkSegBar("swinstrating",$self->mkSegBarDSet($appkpi,
                          "APR.SoftwareInst.Rating"));
      $d.="<hr>";
   }
   if (grep(/^APR.System.TCC.check_status/,keys(%{$appkpi}))){
      $d.="<h3>TCC Gesamtstatus:</h3>";
      $d.=":";
      $d.=$self->mkSegBar("tcctotal",$self->mkSegBarDSet($appkpi,
                          "APR.System.TCC.check_status"));
      $d.="<hr>";
   }
   if (grep(/^APR.System.TCC.os_base_setup/,keys(%{$appkpi}))){
      $d.="<h3>TCC BaseSetup:</h3>";
      $d.=":";
      $d.=$self->mkSegBar("tccbase",$self->mkSegBarDSet($appkpi,
                          "APR.System.TCC.os_base_setup"));
      $d.="<hr>";
   }
   if (grep(/^APR.System.TCC.roadmap/,keys(%{$appkpi}))){
      $d.="<h3>TCC Betriebssystem:</h3>";
      $d.=":";
      $d.=$self->mkSegBar("tccroadmap",$self->mkSegBarDSet($appkpi,
                          "APR.System.TCC.roadmap"));
      $d.="<hr>";
   }
   if ($rmostat->{sgroup} eq "Application"){
      my $sById;
      my $swinstById;
      my $aById;
      my $tccById;
      my $DIById;
      $d.="<br><br>";
      if ($#s!=-1){
         my $o=$app->getPersistentModuleObject("itil::system");
         $o->SetFilter({id=>[map({$_->{id}} @s)]});
         $sById=$o->getHashIndexed(qw(id));
         my @systemid=grep(!/^\s*$/,map({$_->{systemid}} @s));
         if ($#systemid!=-1){
            my $o=$app->getPersistentModuleObject("tssmartcube::tcc");
            $o->SetFilter({systemid=>\@systemid});
            $tccById=$o->getHashIndexed(qw(systemid));
         }
      }
      if ($#a!=-1){
         my $o=$app->getPersistentModuleObject("itil::asset");
         $o->SetFilter({id=>[map({$_->{id}} @a)]});
         $aById=$o->getHashIndexed(qw(id));
      }
      if ($#swinst!=-1){
         my $o=$app->getPersistentModuleObject("itil::lnksoftware");
         $o->SetFilter({id=>[map({$_->{id}} @swinst)]});
         $swinstById=$o->getHashIndexed(qw(id));
      }
      if (keys(%DIid)){
         my $o=$app->getPersistentModuleObject("base::workflow");
         $o->SetFilter({id=>[keys(%DIid)]});
         $DIById=$o->getHashIndexed(qw(id));
      }
      
      { # Systems
         for(my $i=0;$i<=$#s;$i++){
            if ($i==0){
               $d.="<table class=\"statTab sortableTable\">";
               $d.="<thead><tr><th width=1%>System</th>".
                       "<th width=20%>SystemID</th>".
                       "<th width=1%>TCC Gesamtstatus</th>".
                       "<th width=1%>Fehlender Patch, freigegeben vor x Tagen</th>".
                       "<th width=10%>Red Alert</th>".
                       "<th width=20%>Betriebssystem</th>".
                       "<th width=20%>OS BaseSetup</th>".
                       "<th width=20>OS Roadmap State</th>".
                       "</tr></thead>";
            }
            $d.="<tr>";
            $d.="<td nowrap>";
            if (exists($sById->{id}->{$s[$i]->{id}})){
               $d.=$app->OpenByIdWindow("itil::system",
                                        $s[$i]->{id},$s[$i]->{name});
            }
            else{
               $d.=$s[$i]->{name};
            }
            $d.="</td>";
            $d.="<td>".$s[$i]->{systemid}."</td>";

            $d.="<td align=center>";
            $d.=SignImg($s[$i]->{check_status_color});
            $d.="</td>";

            $d.="<td align=center>";
            $d.=$s[$i]->{days_not_patched};
            $d.="</td>";

            $d.="<td>";
            $d.=$s[$i]->{red_alert};
            $d.="</td>";

            $d.="<td>";
            $d.=$s[$i]->{roadmap}."&nbsp;";
            if ($s[$i]->{systemid} ne "" && 
               exists($tccById->{systemid}->{$s[$i]->{systemid}})){
              $d.=$app->OpenByIdWindow("tssmartcube::tcc",
                                        $s[$i]->{systemid},
                                        SignImg($s[$i]->{roadmap_color}));
            }
            else{
              $d.=SignImg($s[$i]->{roadmap_color});
            }
            $d.="</td>";

            $d.="<td>";
            $d.=$s[$i]->{os_base_setup}."&nbsp;".SignImg($s[$i]->{os_base_setup_color});
            $d.="</td>";

            $d.="<td align=center>";
            $d.=$s[$i]->{roadmap_state};
            $d.="</td>";
            $d.="</tr>";
         }
         $d.="</table>" if ($#s!=-1);
      }
      { # Software Installations
         @swinst=sort({$a->{fullname} cmp $b->{fullname}} @swinst);
         for(my $i=0;$i<=$#swinst;$i++){
            if ($i==0){
               $d.="<table class=\"statTab sortableTable\">";
               $d.="<thead><tr><th>Software-Installation</th>".
                   "<th width=10>Patch/Release Rating</th>".
                   "<th width=1%></th>".
                   "</tr></thead>";
            }
            $d.="<tr>";
            $d.="<td valign=top>";
            my $fullname=$swinst[$i]->{fullname};
            $d.=$fullname;
            $d.="</td>";
            $d.="<td align=center valign=top>".
                SignImg($swinst[$i]->{instrating}).
                "</td>";
            my $ratingmsg=$swinst[$i]->{ratingmsg};
            if ($swinst[$i]->{instrating} eq "blue"){
               $ratingmsg="";
            }
            $d.="<td width=2%>".$ratingmsg."</td>";
            $d.="</tr>";
         }
         $d.="</table>" if ($#i!=-1);
      }
   }



#print STDERR (Dumper($rmostat->{stats}));
#print STDERR (Dumper($rmostat));


   if ($showLegend){
      $d.=$self->Legend();
      $d.="<hr>";
   }


   my $condition=$app->T("condition",'base::w5stat');
   my $load=$app->findtemplvar({current=>$rmostat,
                              mode=>"HtmlV01"},"mdate","formated");
   $d.=sprintf("<div class=condition>APR $condition: $load</div>");


   if ($app->IsMemberOf("admin")){
      $d.="<br><br><br>Debug-Data:<br>";
      
      $d.="w5stat w5baseid=".
          $app->OpenByIdWindow("base::w5stat",$primrec->{id},$primrec->{id}).
          "<br>";
      $d.="w5stat APR w5baseid=".
          $app->OpenByIdWindow("base::w5stat",$rmostat->{id},$rmostat->{id}).
          "<br>";
      $d.="w5stat APR Stand=$rmostat->{mdate}<br>";
      $d.="<hr>";
   }
   return($d);
}

sub OpenByIdWindow
{
   my $self=shift;
   my $dataobj=shift;
   my $id=shift;

}



sub processData
{
   my $self=shift;
   my $statstream=shift;
   my $dstrange=shift;
   my %param=@_;
   my ($year,$month)=$dstrange=~m/^(\d{4})(\d{2})$/;
   my $count=0;

   return() if ($statstream ne "APR");

   my $appl=getModuleObject($self->getParent->Config,"TS::appl");
   $appl->SetCurrentView(qw(
      name cistatusid mandatorid systems 
      businessteam 
      mgmtitemgroup 
   ));
   if ($appl->Config->Param("W5BaseOperationMode") eq "dev"){
      $appl->SetFilter({cistatusid=>'<=4',
                        name=>'W5* Dina* TSG_VIRTUELLE_T-SERVER* NGSS*Perfo*'});
      $appl->SetFilter({cistatusid=>'<=4',
                        name=>'W5Base/Darwin'});
   }
   else{
      $appl->SetFilter({cistatusid=>'4'});
   }
   $appl->SetCurrentOrder("NONE");
   msg(INFO,"starting collect of APR Applications");
   my ($rec,$msg)=$appl->getFirst();
   if (defined($rec)){
      do{
         $self->getParent->processRecord($statstream,'tsAPR::appl',
                                         $dstrange,$rec,%param);
         ($rec,$msg)=$appl->getNext();
         $count++;
      } until(!defined($rec));
   }
   msg(INFO,"FINE of tsAPR::appl  $count records");

}


sub processRecord
{
   my $self=shift;
   my $statstream=shift;
   my $module=shift;
   my $monthstamp=shift;
   my $rec=shift;
   my %colors=@{$self->{Colors}};
   my $app=$self->getParent();
   my %param=@_;
   my ($year,$month)=$monthstamp=~m/^(\d{4})(\d{2})$/;

   return() if ($statstream ne "APR");

   if ($module eq "tsAPR::appl"){
      msg(INFO,"APR Processs $rec->{name}");
      print STDERR Dumper($rec);
      my %systemid=();
      my @systemid=();
      my @w5sysid=();
      my $isAPRrelevant=0;
      my @tccsys=();
      my %swinst;
      foreach my $sysrec (@{$rec->{systems}}){
         if ($sysrec->{systemsystemid} ne ""){
            $systemid{uc($sysrec->{systemsystemid})}=$sysrec->{systemid};
         }
      }
      @systemid=sort(keys(%systemid));
      if ($#systemid!=-1){
         my $tcc=$app->getPersistentModuleObject("tssmartcube::tcc");
         $tcc->SetFilter({systemid=>\@systemid});
         my @l=$tcc->getHashList(qw(
            systemname
            systemid 

            check_status_color
            days_not_patched
            red_alert
            roadmap

            os_base_setup 
            os_base_setup_color

            roadmap_color
            roadmap_state
            w5systemid

         ));
         print STDERR Dumper(\@l);
         foreach my $tccrec (@l){
            if (exists($systemid{uc($tccrec->{systemid})})){
               push(@w5sysid,$systemid{uc($tccrec->{systemid})});
            }
         }
         @tccsys=@l;
      }
      my $mgmtitemgroup=$rec->{mgmtitemgroup};
      $mgmtitemgroup=[$mgmtitemgroup] if (ref($mgmtitemgroup) ne "ARRAY");
      if (grep(/^TOP.*Telekom.*$/i,@$mgmtitemgroup)){
         $isAPRrelevant=1;
      }
      if ($app->Config->Param("W5BaseOperationMode") eq "dev"){
         if (($rec->{name}=~m/\(P\)$/) || ($rec->{name}=~m/^W5B/)){
            $isAPRrelevant=1;
         }
      }

      # @systemid= systemids die zu beruecksichtigen sind
      # @w5sysid = w5baseid der Systeme, die zu beruecksichtigen sind
      # $isAPRrelevant = APR relevant (im Management(Org) Reporting ja/nein

      if ($#{$self->{Roadmap}}>=0){
         foreach my $swinstdataobj (qw( itil::lnksoftwaresystem 
                                        itil::lnksoftwareitclustsvc)){
            my $o=$app->getPersistentModuleObject($swinstdataobj);
            if ($swinstdataobj eq "itil::lnksoftwaresystem"){
               if ($#systemid!=-1){
                  $o->SetFilter({
                     systemsystemid =>\@systemid,
                     softwareset=>$self->{Roadmap}->[0]->{name}
                  });
               }
               else{
                  next;
               }
            }
            else{
               $o->SetFilter({
                  applications    =>\$rec->{name},
                  softwareset=>$self->{Roadmap}->[0]->{name}
               });
            }
            foreach my $swirec ($o->getHashList(qw(id fullname 
                                                   softwareinstrelstate
                                                   softwareinstrelmsg))){
               #print Dumper($swirec);
               my $instrating="";
               if ($swirec->{softwareinstrelstate}=~m/^FAIL/){
                  $instrating="red";
               }
               if ($swirec->{softwareinstrelstate}=~m/^WARN/){
                  $instrating="yellow";
               }
               if ($swirec->{softwareinstrelstate}=~m/^OK$/){
                  $instrating="green";
               }
               if ($swirec->{softwareinstrelstate}=~m/^OK unrestricted/){
                  $instrating="";
               }
               my $softwareinstrelmsg=$swirec->{softwareinstrelmsg};
               $softwareinstrelmsg=~s/;/ /g;
               $softwareinstrelmsg=~s/\n/ /g;
               my $refid;
               if ($swirec->{itclustsvcid} ne ""){
                  $refid=$swirec->{itclustsvcid};
               }
               if ($swirec->{systemid} ne ""){
                  $refid=$swirec->{systemid};
               }
               $swinst{$swirec->{id}}={
                   id=>$swirec->{id},
                   dataobj=>$swinstdataobj,
                   refid=>$refid,
                   instrating=>$instrating,
                   fullname=>$swirec->{fullname},
                   ratingmsg=>$softwareinstrelmsg
               };
            }
         }
      }

      printf STDERR ("fifi swinst=%s\n",Dumper(\%swinst));

      printf STDERR ("fifi w5sysid=%s\n",join(",",@w5sysid));

      my $appkpi={};
      my $name=$rec->{name};

      my $grp=$app->getPersistentModuleObject("base::grp");
      my @repOrg;
      if ($rec->{businessteam} ne ""){
         push(@repOrg,$rec->{businessteam});
      }
      if ($rec->{mandatorid} ne ""){
         $grp->SetFilter({grpid=>\$rec->{mandatorid},cistatusid=>'4'});
         my ($grec)=$grp->getOnlyFirst(qw(fullname));
         if (defined($grec)){
            push(@repOrg,$grec->{fullname});
         }
      }


      my %colors=@{$self->{Colors}};
      foreach my $color (keys(%colors)){
         foreach my $prefix (qw(
               APR.System.TCC.check_status
               APR.System.TCC.red_alert
               APR.System.TCC.os_base_setup
               APR.System.TCC.roadmap
               APR.SoftwareInst.Rating
            )){
            $appkpi->{$prefix.".".$color}=0;
         }
      }


      # ---- start analytics and store of statvars ----

      foreach my $tccrec (@tccsys){
         $appkpi->{'APR.System.Count'}++;
         my $l=joinCsvLine(
               $tccrec->{w5systemid},
               $tccrec->{systemname},
               $tccrec->{systemid},
               $tccrec->{check_status_color},
               $tccrec->{days_not_patched},
               $tccrec->{red_alert},
               $tccrec->{roadmap},
               $tccrec->{os_base_setup},
               $tccrec->{os_base_setup_color},
               $tccrec->{roadmap_color},
               $tccrec->{roadmap_state}
         )."\n";

         { 
            if (in_array([keys(%colors)],$tccrec->{check_status_color})){
               $appkpi->{'APR.System.TCC.check_status.'.
                  $tccrec->{check_status_color}}++;
            }
            else{
               $appkpi->{'APR.System.TCC.check_status.gray'}++;
            }
         }


         { 
            #if (in_array([keys(%colors)],$tccrec->{red_alert})){
            if ($tccrec->{red_alert} ne ""){
               $appkpi->{'APR.System.TCC.red_alert.red'}++;
            }
            else{
               $appkpi->{'APR.System.TCC.red_alert.green'}++;
            }
         }

         { 
            if (in_array([keys(%colors)],$tccrec->{os_base_setup_color})){
               $appkpi->{'APR.System.TCC.os_base_setup.'.
                          $tccrec->{os_base_setup_color}}++;
            }
            else{
               $appkpi->{'APR.System.TCC.os_base_setup.gray'}++;
            }
         }

         { 
            if (in_array([keys(%colors)],$tccrec->{roadmap_color})){
               $appkpi->{'APR.System.TCC.roadmap.'.
                          $tccrec->{roadmap_color}}++;
            }
            else{
               $appkpi->{'APR.System.TCC.roadmap.gray'}++;
            }
         }

         $self->getParent->storeStatVar("Application",
                                        [$rec->{name}],
                                        {nosplit=>1,
                                         nameid=>$rec->{id},
                                         method=>'add'},
                                        "APR.System",$l);
      }
      foreach my $swiid (sort(keys(%swinst))){
         $appkpi->{'APR.SoftwareInst.Count'}++;
         my $l="";
         $l.=$swinst{$swiid}->{id}.";";
         $l.=$swinst{$swiid}->{dataobj}.";";
         $l.=$swinst{$swiid}->{refid}.";";
         $l.=$swinst{$swiid}->{fullname}.";";
         my $ratingcolor=$swinst{$swiid}->{instrating};
         $l.=$ratingcolor.";";
         { 
            if (in_array([keys(%colors)],$ratingcolor)){
               $appkpi->{'APR.SoftwareInst.Rating.'.$ratingcolor}++;
            }
            else{
               $appkpi->{'APR.SoftwareInst.Rating.gray'}++;
            }
         }
         $l.=$swinst{$swiid}->{ratingmsg}.";";
         $l.="\n";
         $self->getParent->storeStatVar("Application",
                                        [$rec->{name}],
                                        {nosplit=>1,
                                         nameid=>$rec->{id},
                                         method=>'add'},
                                        "APR.SoftwareInst",$l);
      }

      foreach my $k (keys(%$appkpi)){
         $self->getParent->storeStatVar("Application",
            [$rec->{name}],{
               nosplit=>1,nameid=>$rec->{id}
            },
            $k,$appkpi->{$k}
         );
      }
      if ($isAPRrelevant){
       #  $self->getParent->storeStatVar("Group",\@repOrg,{
       #      nosplit=>1,method=>'add'},
       #      "APR.Appl.List",$ApplIndexLine);
       #  $self->getParent->storeStatVar("Group",\@repOrg,{
       #      method=>'avg'},
       #      "APR.Appl.Index",$redPercent);

         $self->getParent->storeStatVar("Group",\@repOrg,{},"APR.Appl.Count",1);
         $self->getParent->storeStatVar("Application",
            [$rec->{name}],{
               nosplit=>1,nameid=>$rec->{id}
            },
            "APR.Appl.Count",1
         );
         foreach my $k (keys(%$appkpi)){
            $self->getParent->storeStatVar("Group",\@repOrg,{},
                                           $k,$appkpi->{$k});
         }
      }
   }
}


1;
