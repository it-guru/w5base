package AL_TCom::workflow::eventnotify;
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
use kernel::WfClass;
use itil::workflow::eventnotify;
use Text::Wrap qw($columns &wrap);

@ISA=qw(itil::workflow::eventnotify);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(
      $self->SUPER::getDynamicFields(@_),

      new kernel::Field::Text(
                name          =>'eventprmticket',
                xlswidth      =>'15',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'related problem ticket',
                container     =>'headref'),

      new kernel::Field::Text(
                name          =>'eventinmticket',
                xlswidth      =>'15',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                label         =>'related incident ticket',
                container     =>'headref'),


      new kernel::Field::Textarea(
                name          =>'eventscproblemsolution',
                translation   =>'AL_TCom::workflow::eventnotify',
                group         =>'eventnotifyinternal',
                depend        =>['eventprmticket'],
                readonly      =>1,
                htmldetail    =>\&isSCproblemSet,
                onRawValue    =>\&loadDataFromSC,
                label         =>'SC Problem soultion'),
      new kernel::Field::Textarea(
                name          =>'eventscproblemcause',
                translation   =>'AL_TCom::workflow::eventnotify',
                onRawValue    =>\&loadDataFromSC,
                group         =>'eventnotifyinternal',
                readonly      =>1,
                htmldetail    =>\&isSCproblemSet,
                depend        =>['eventprmticket'],
                label         =>'SC Problem cause'),
      ));
}

sub isSCproblemSet
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $current=$param{current};
   return(1) if ($current->{eventprmticket} ne "");
   return(0);
}



sub loadDataFromSC
{
   my $self=shift;
   my $current=shift;

   my $reffld=$self->getParent->getField("eventprmticket",$current);
   return(undef) if (!defined($reffld));
   my $prmid=$reffld->RawValue($current);
   return(undef) if (!defined($prmid) || $prmid eq "");
   my $scprm=getModuleObject($self->getParent->Config,"tssc::prm");
   if (defined($scprm)){
      $scprm->SetFilter({problemnumber=>\$prmid});
      my ($prmrec,$msg)=$scprm->getOnlyFirst(qw(cause solution));
      if (defined($prmrec)){ 
         if ($self->Name eq "eventscproblemcause"){
            return($prmrec->{cause});
         }
         if ($self->Name eq "eventscproblemsolution"){
            return($prmrec->{solution});
         }
      }
   }
   
   return(undef);

}


sub getNotifyDestinations
{
   my $self=shift;
   my $mode=shift;    # "custinfo" | "mgmtinfo"
   my $WfRec=shift;
   my $emailto=shift;

   if ($mode eq "rootcausei"){
      my $ia=getModuleObject($self->Config,"base::infoabo");
      if ($WfRec->{eventmode} eq "EVk.appl"){
         my $applid=$WfRec->{affectedapplicationid};
         $applid=[$applid] if (ref($applid) ne "ARRAY");
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>$applid});
         my %allcustgrp;
         foreach my $rec ($appl->getHashList(qw( customerid))){
            if ($rec->{customerid}!=0){
               $self->getParent->LoadGroups(\%allcustgrp,"up",
                                            $rec->{customerid});
            }
         }
         if (keys(%allcustgrp)){
            $ia->LoadTargets($emailto,'base::grp',\'rootcauseinfo',
                                      [keys(%allcustgrp)]);
         }
         $ia->LoadTargets($emailto,'*::appl *::custappl',\'rootcauseinfo',
                                   $applid);
      }
   }
   return($self->SUPER::getNotifyDestinations($mode,$WfRec,$emailto));
}

sub IsModuleSelectable
{
   my $self=shift;
   my $acl;

   $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          "base::workflow",
                          func=>'New',
                          param=>'WorkflowClass=AL_TCom::workflow::eventnotify');
   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(1) if ($self->getParent->IsMemberOf("admin"));
   return(0);
}

sub activateMailSend
{
   my $self=shift;
   my $WfRec=shift;
   my $wf=shift;
   my $id=shift;
   my $newmailrec=shift;
   my $action=shift;

   my %d=(step=>'base::workflow::mailsend::waitforspool',
          emailsignatur=>'EventNotification: AL T-Com');
   $self->linkMail($WfRec->{id},$id);
   if (my $r=$wf->Store($id,%d)){
      return(1);
   }
   return(0);
}

sub ValidateCreate
{
   my $self=shift;
   my $newrec=shift;

  #
  # laut Tino soll nun auch Extern zugelassen werden
  #
   if (!defined($newrec->{mandator}) ||    
       ref($newrec->{mandator}) ne "ARRAY" ||
       !grep(/^(Extern|AL T-Com)$/,@{$newrec->{mandator}})){
      $self->LastMsg(ERROR,"no AL T-Com mandator included");
      return(0);
   }
        
   return(1);
}

sub getPosibleEventStatType
{
   my $self=shift;
   my @l;
   
   foreach my $int ('',
                    qw(EVt.iswtsi EVt.iswext EVt.wrkerr 
                       EVt.wrkerrito EVt.wrkerr3ito EVt.wrkerr3thome
                       EVt.dqual EVt.stdswbug EVt.stdswold 
                       EVt.hwfail EVt.busoverflow EVt.tecoverflow
                       EVt.parammod EVt.rzinfra EVt.hitnet EVt.inanalyse
                       EVt.unknown)){
      push(@l,$int,$self->getParent->T($int));
   }
   
   return(@l);
}

sub getNotificationSubject 
{
   my $self=shift;
   my $WfRec=shift;
   if ($WfRec->{eventlang} ne "de"){
      return($self->SUPER::getNotificationSubject($WfRec,@_));
   }
   my $action=shift;
   my $subjectlabel=shift;
   my $failclass=shift;
   my $ag=shift;
   my $state;
   my $id=$WfRec->{id};
   $self->getParent->Action->ResetFilter();
   $self->getParent->Action->SetFilter({wfheadid=>\$id});
   my @l=$self->getParent->Action->getHashList(qw(cdate name));
   my $sendcustinfocount=1;
   foreach my $arec (@l){
      $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
   }

#print STDERR ("fifi %s\n",Dumper($WfRec));
   if ($WfRec->{stateid} == 17){
     $state=$self->getParent->T("finish info","itil::workflow::eventnotify");
   }elsif ($sendcustinfocount > 1){
     $state=$self->getParent->T("follow info","itil::workflow::eventnotify");
   }else{
     $state=$self->getParent->T("first information","itil::workflow::eventnotify");
   }
   my $afcust=$WfRec->{affectedcustomer}->[0]; # only first customer will be displayed
   my $subject="EK ".$WfRec->{eventstatclass};
   my $subject2=" / $ag / $state Incident / ".$afcust." / Applikation / ";
   if ($WfRec->{eventmode} eq "EVk.net"){ 
      $subject2=" / $state Incident / $afcust / Netz / ";
   }
   if ($WfRec->{eventmode} eq "EVk.infraloc"){ 
      $subject2=" / $state Incident / Infrastruktur / ";
   }
   if ($action eq "rootcausei"){
      $subject2=" / $ag / Ursachenanalyse / $afcust / Applikation /";
   }
   $subject.=$subject2;
   $subject.=" HeadID ".$WfRec->{id};
   return($subject);
}

sub getSalutation
{
   my $self=shift;
   my $WfRec=shift;
   my $action=shift;
   my $ag=shift;
   my $salutation;
   my $info;
   my $st;
   $ag="\"$ag\"";
   if (length($ag) > 16){
       $ag="<br>$ag";
   }
   my $eventstat=$WfRec->{stateid};
   my $eventstart=$WfRec->{eventstartofevent};
   my $utz=$self->getParent->UserTimezone();
   my $creationtime=$self->getParent->ExpandTimeExpression($eventstart,"de","UTC",$utz);
   if ($WfRec->{eventmode} eq "EVk.infraloc" && $eventstat==17){
      $salutation=<<EOF;
Sehr geehrte Kundin, sehr geehrter Kunde,

die Beeinträchtigung der Infrastruktur wurde beseitigt.
EOF
   }elsif($WfRec->{eventmode} eq "EVk.infraloc"){
      $salutation=<<EOF;
Sehr geehrte Damen und Herren,

folgende Informationen zum Ereignis im Bereich
der Rechenzentrums-Infrastruktur liegen derzeit vor:
$info
EOF
   }elsif ($WfRec->{eventmode} eq "EVk.appl" && $eventstat==17){
      $salutation=<<EOF;
Sehr geehrte Kundin, sehr geehrter Kunde,

die Beeinträchtigung im Umfeld der AG $ag wurde beseitigt.
EOF
   }elsif($WfRec->{eventmode} eq "EVk.appl"){
      $salutation=<<EOF;
Sehr geehrte Damen und Herren,

im Folgenden erhalten Sie den aktuellen Stand zum Ereignis
der Anwendung $ag vom $creationtime.
EOF
   }elsif ($WfRec->{eventmode} eq "EVk.net" && $eventstat==17){
      $salutation=<<EOF;
Sehr geehrte Kundin, sehr geehrter Kunde,

die Beeinträchtigung im Umfeld des
TCP/IP-Netzes (HitNet) wurde beseitigt.
EOF
   }elsif($WfRec->{eventmode} eq "EVk.net"){   
      $salutation=<<EOF;
Sehr geehrte Damen und Herren,

folgende Informationen zum Ereignis im Bereich des 
TCP/IP-Netzes (HitNet) liegen derzeit vor:
$info
EOF
   }
   if ($action eq "rootcausei"){
      $salutation=<<EOF;
Sehr geehrte Damen und Herren,

wir informieren Sie über das Ergebnis der
Ursachenanalyse und über die eingeleiteten Maßnahmen.
EOF
   }
   return($salutation);
}
 
sub getNotificationSkinbase
{
   my $self=shift;
   my $WfRec=shift;
   if ($WfRec->{eventlang} ne "de"){
      return($self->SUPER::getNotificationSkinbase($WfRec));
   }
   return('AL_TCom');
}

sub generateMailSet
{
   my $self=shift;
   my $WfRec=shift;
   if ($WfRec->{eventlang} ne "de"){
      return($self->SUPER::generateMailSet($WfRec,@_));
   }
   my ($action,$eventlang,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,$emailsubheader,$emailsubtitle,
       $subject,$allowsms,$smstext)=@_;
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();

   $$allowsms=0;
   $$smstext="\n";



   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/auth/.*$##;
   }
   my @baseset=qw(wffields.eventstartofevent wffields.eventstatclass );
   my $fo=$self->getField("wffields.eventendofevent",$WfRec);
   if (defined($fo)){
      my $v=$fo->FormatedResult($WfRec,"HtmlMail");
      if (defined($v)){
         push(@baseset,"wffields.eventendofevent");
      }else{
         push(@baseset,"wffields.eventendexpected");
      }
   }
   if ($action eq "rootcausei"){
      @baseset=qw(wffields.eventstartofevent
                  wffields.eventendofevent wffields.eventstatclass);
   }
   # wffields.eventstatnature deleted w5baseid: 12039307490008 
   push(@baseset,qw(wffields.affectedregion));
   if ($WfRec->{eventmode} eq "EVk.appl"){
      push(@baseset,"affectedapplication");
      push(@baseset,"wffields.affectedcustomer");
      # wffields.eventstatreason entfernt lt. Request ID:12077277280002  
      #push(@baseset,"wffields.eventstatreason");
   }
   if ($WfRec->{eventmode} ne "EVk.appl"){
      my $fo=$self->getField("wffields.eventmode",$WfRec);
      if (defined($fo)){
         my $v=$fo->FormatedResult($WfRec,"HtmlMail");
         if ($v ne ""){
            $$smstext.=$v."\n";
         }
      }
   }

   my @sets=([@baseset,qw(
                          wffields.eventimpact
                          wffields.eventreason
                          wffields.shorteventelimination
                         )],
             [@baseset,qw(
                          wffields.eventaltimpact
                          wffields.eventaltreason 
                          wffields.altshorteventelimination
                         )]);
   if ($action eq "rootcausei"){
      @sets=([@baseset,qw(wffields.eventimpact wffields.eventscproblemcause)],
             [@baseset,qw(wffields.eventimpact wffields.eventscproblemcause)]);
   }
   my $lang="de";
   my $line=0;
   my $mailsep=0;
   $mailsep="$lang:" if ($#emailsep!=-1); 
   $ENV{HTTP_FORCE_LANGUAGE}=$lang;

   my @fields=@{shift(@sets)};
 
   foreach my $field (qw(wffields.affectedcustomer
                         affectedapplication
                         wffields.eventstatclass
                         wffields.eventstartofevent 
                         wffields.eventendofevent id)){
      my $fo=$self->getField($field,$WfRec);

      my $vv=$fo->FormatedResult($WfRec,"ShortMsg");
      if ($vv ne ""){
         if ($field=~m/(eventstartofevent)/){
            $$smstext.="Start:".$vv."\n";
         }
         elsif ($field=~m/(eventendofevent)/){
            $$smstext.="Ende:".$vv."\n";
         }
         elsif ($field=~m/(affectedapplication)/){
            $$smstext.="AG:".$vv."\n";
         }
         elsif ($field=~m/(eventstatnature)/){
            $$smstext.=$vv."\n";
         }
         elsif ($field=~m/(affectedcustomer)/){
            $vv=~s/^([^\.]+\.[^\.]+).*$/$1/;
            $$smstext.=$vv."\n";
         }
         elsif ($field=~m/^id$/){
            $$smstext.="HeadID:".$vv."\n";
         }
         else{
            $$smstext.=$fo->Label().":".$vv."\n";
         }
      }
   }
   foreach my $field (@fields){
      my $fo=$self->getField($field,$WfRec);
      my $sh=0;
      $sh=" " if ($field eq "wffields.eventaltdesciption" ||
                  $field eq "wffields.eventdesciption");
      if (defined($fo)){
         my $v=$fo->FormatedResult($WfRec,"HtmlMail");
         if($field eq "wffields.eventendexpected" && $v eq ""){
            $v=" ";
         }
         if ($v ne ""){
            if ($field eq "wffields.eventstatclass" &&
               ( $v eq "1" || $v eq "2") && $action ne "rootcausei"){
               $$allowsms=1
            }
                           
            if ($baseurl ne "" && $line==0){
               my $ilang="?HTTP_ACCEPT_LANGUAGE=$lang";
               my $imgtitle=$self->getParent->T("current state of workflow",
                                                "base::workflow");
               push(@emailpostfix,
                    "<img title=\"$imgtitle\" class=status border=0 ".
                    "src=\"$baseurl/public/base/workflow/".
                    "ShowState/$WfRec->{id}$ilang\">");
            }
            else{
               push(@emailpostfix,"");
            }
            my $data=$v;
            $data=~s/</&lt;/g;
            $data=~s/>/&gt;/g;
            #$columns="50";
            #$data=wrap("","",$data);

            push(@emailtext,$data);
            push(@emailsubheader,$sh);
            push(@emailsep,$mailsep);
            if ($line==0){ 
                push(@emailprefix,$fo->Label().":");
                push(@emailsubtitle,"Problemdetails");
            }elsif($field eq "wffields.affectedcustomer"){
                push(@emailsubtitle,"");    
                push(@emailprefix,"betroffener Kunde:");
            }elsif($field eq "wffields.eventimpact"){
                push(@emailsubtitle,"");    
                push(@emailprefix,"Auswirkungen für den Kunden:");
            }elsif($field eq "wffields.eventreason"){
                push(@emailsubtitle,"");    
                push(@emailprefix,"Beschreibung der Ursache:");
            }elsif($field eq "wffields.eventscproblemcause"){
                push(@emailsubtitle,"");    
                push(@emailprefix,"Ursachen-Cluster/ ".
                                  "Beschreibung der Ursache:");
            }elsif($field eq "wffields.shorteventelimination"){
                push(@emailsubtitle,"");    
                push(@emailprefix,"Kurzfristige Massnahme zur ".
                                  "Servicewiederherstellung:");
            }else{
                push(@emailprefix,$fo->Label().":");
                push(@emailsubtitle,"");
            }
            $line++;
            $mailsep=0;
         }
     }
   }
   if ($action ne "rootcausei"){
      my $rel=$self->getField("relations",$WfRec);
      my $reldata=$rel->ListRel($WfRec->{id},"mail",{name=>\'consequenceof'});
      push(@emailprefix,$rel->Label().":");
      push(@emailtext,$reldata);
      push(@emailsubheader,0);
      push(@emailsep,0);
      push(@emailpostfix,"");
   }
   if ($action eq "rootcausei"){
      my $wf=$self->getParent();
      my $prmfld=$wf->getField("wffields.eventscproblemsolution",$WfRec);
      my $prmticket=$prmfld->RawValue($WfRec);
      if ($prmticket ne ""){
         push(@emailprefix,"Umzusetzende Maßnahmen:");
         push(@emailtext,$prmfld->FormatedResult($WfRec,"HtmlMail"));
         push(@emailsubheader,0);
         push(@emailsep,0);
         push(@emailpostfix,"");
      }
   }
   my $wf=$self->getParent();
   my $ssfld=$wf->getField("wffields.eventstaticmailsubject",$WfRec);
   if (defined($ssfld)){
      my $sstext=$ssfld->RawValue($WfRec);
      if ($sstext ne ""){
         $$subject=$sstext;
      }
   }

   delete($ENV{HTTP_FORCE_LANGUAGE});
   @$emailprefix=@emailprefix;
   @$emailpostfix=@emailpostfix;
   @$emailtext=@emailtext;
   @$emailsep=@emailsep;
   @$emailsubheader=@emailsubheader;
   @$emailsubtitle=@emailsubtitle;
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return("AL_TCom::workflow::eventnotify"=>'relprobtick',
          $self->SUPER::getPosibleRelations($WfRec));
}

sub getAdditionalMainButtons
{
   my $self=shift;
   my $WfRec=shift;
   my $actions=shift;
   my $d="";

   my @buttons=('rootcausei'=>$self->T("Send Root-Cause Info"),
                'startwarum'=>$self->T("Start a WARUM analaysis"));

   while(my $name=shift(@buttons)){
      my $label=shift(@buttons);
      my $dis="";
      $dis="disabled" if (!$self->ValidActionCheck(0,$actions,$name));
      $d.="<input type=submit $dis ".
          "class=workflowbutton name=$name value=\"$label\"><br>";
   }
   return($d);
}

sub getPosibleActions
{
   my $self=shift;
   my $WfRec=shift;
   my $app=$self->getParent;
   my $userid=$self->getParent->getCurrentUserId();
   my @l;

   if ($WfRec->{stateid}==17){
      if ($self->IsIncidentManager($WfRec) || 
          $self->getParent->IsMemberOf(["admin","admin.workflow"])){
         push(@l,"rootcausei");
      }
   }
   return(@l,$self->SUPER::getPosibleActions($WfRec));
}

sub AdditionalMainProcess
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if (!defined($action) && Query->Param("rootcausei")){
      return(-1) if (!$self->ValidActionCheck(1,$actions,"rootcausei"));
      my $prmfld=$self->getField("wffields.eventprmticket",$WfRec);
      my $prmticket=$prmfld->RawValue($WfRec);
      if (!($prmticket=~m/^PRM\d+$/)){
         $self->LastMsg(ERROR,"invalid problemticket registered");
         return(0);
      }
      my @WorkflowStep=Query->Param("WorkflowStep");
      push(@WorkflowStep,"AL_TCom::workflow::eventnotify::sendrootcausei");
      Query->Param("WorkflowStep"=>\@WorkflowStep);
      return(0);
   }
   return(-1);
}


#######################################################################
package AL_TCom::workflow::eventnotify::sendrootcausei;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my @email=@{$self->Context->{CurrentTarget}};
   my $emaillang=();
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();
   my %additional=();
   my $smsallow;
   my $smstext;
   my $subject;
   $self->getParent->generateMailSet($WfRec,"rootcausei",
                    \$emaillang,\%additional,
                    \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                    \@emailsubheader,\@emailsubtitle,
                    \$subject,\$smsallow,\$smstext);
   return($self->generateNotificationPreview(emailtext=>\@emailtext,
                                             emailprefix=>\@emailprefix,
                                             emailsep=>\@emailsep,
                                             emailsubheader=>\@emailsubheader,
                                             emailsubtitle=>\@emailsubtitle,
                                             to=>\@email));
}

sub getPosibleButtons
{  
   my $self=shift;
   my $WfRec=shift;
   my %b=$self->SUPER::getPosibleButtons($WfRec);
   my %em=();
   $self->getParent->getNotifyDestinations("rootcausei",$WfRec,\%em);
   my @email=sort(keys(%em));
   $self->Context->{CurrentTarget}=\@email;
   delete($b{NextStep}) if ($#email==-1);
   delete($b{BreakWorkflow});

   return(%b);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      return(undef) if (!$self->ValidActionCheck(1,$actions,"rootcausei"));
      my %em=();
      $self->getParent->getNotifyDestinations("rootcausei",$WfRec,\%em);
      my @emailto=sort(keys(%em));
      my $id=$WfRec->{id};
      $self->getParent->getParent->Action->ResetFilter();
      $self->getParent->getParent->Action->SetFilter({wfheadid=>\$id});
      my @l=$self->getParent->getParent->Action->getHashList(qw(cdate name));
      my $sendcustinfocount=1;
      foreach my $arec (@l){
         $sendcustinfocount++ if ($arec->{name} eq "sendcustinfo");
      }
      my $wf=getModuleObject($self->Config,"base::workflow");
      my $eventlang;
      my @emailprefix=();
      my @emailpostfix=();
      my @emailtext=();
      my @emailsep=();
      my @emailsubheader=();
      my @emailsubtitle=();
      my $smsallow;
      my $smstext;

      my $eventlango=$self->getField("wffields.eventlang",$WfRec);
      $eventlang=$eventlango->RawValue($WfRec) if (defined($eventlango));
      $ENV{HTTP_FORCE_LANGUAGE}=$eventlang;
      $ENV{HTTP_FORCE_LANGUAGE}=~s/-.*$//;

      my $subjectlabel="Ergebnis der Ursachenanalyse";
      my $headtext="Ergebnis der Ursachenanalyse";
      if ($WfRec->{eventlang}=~m/^en/){
         $subjectlabel="result of root cause analyse";
         $headtext="result of root cause analyse";
      }
      delete($ENV{HTTP_FORCE_LANGUAGE});
      my $ag="";
      if ($WfRec->{eventmode} eq "EVk.appl"){ 
         foreach my $appl (@{$WfRec->{affectedapplication}}){
            $ag.="; " if ($ag ne "");
            $ag.=$appl;
         }
      }

      my $failclass=$WfRec->{eventstatclass};
      my $subject=$self->getParent->getNotificationSubject($WfRec,"rootcausei",
                                    $subjectlabel,$failclass,$ag);
      my $salutation=$self->getParent->getSalutation($WfRec,"rootcausei",$ag);

      my $eventstat=$WfRec->{stateid};
      my $failcolor="#6699FF";
      my $utz=$self->getParent->getParent->UserTimezone();
      my $creationtime=$self->getParent->getParent->ExpandTimeExpression('now',
                                                                "de",$utz,$utz);
      my %additional=(headcolor=>$failcolor,eventtype=>'Event',    
                      headtext=>$headtext,headid=>$id,salutation=>$salutation,
                      creationtime=>$creationtime);
      $self->getParent->generateMailSet($WfRec,"rootcausei",
                       \$eventlang,\%additional,
                       \@emailprefix,\@emailpostfix,\@emailtext,\@emailsep,
                       \@emailsubheader,\@emailsubtitle,\$subject,
                       \$smsallow,\$smstext);
      #
      # calc from address
      #
      my $emailfrom="unknown\@w5base.net";
      my @emailcc=();
      my $uobj=$self->getParent->getPersistentModuleObject("base::user");
      my $userid=$self->getParent->getParent->getCurrentUserId(); 
      $uobj->SetFilter({userid=>\$userid});
      my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
      if (defined($userrec) && $userrec->{email} ne ""){
         $emailfrom=$userrec->{email};
         my $qemailfrom=quotemeta($emailfrom);
         if (!grep(/^$qemailfrom$/,@emailto)){
            push(@emailcc,$emailfrom);
         }
      }
      
      #
      # load crator in cc
      #
      if ($WfRec->{openuser} ne ""){
         $uobj->SetFilter({userid=>\$WfRec->{openuser}});
         my ($userrec,$msg)=$uobj->getOnlyFirst(qw(email));
         if (defined($userrec) && $userrec->{email} ne ""){
            my $e=$userrec->{email};
            my $qemailfrom=quotemeta($e);
            if (!grep(/^$qemailfrom$/,@emailto) &&
                !grep(/^$qemailfrom$/,@emailcc)){
               push(@emailcc,$e);
            }
         }
      }
      my $newmailrec={
             class    =>'base::workflow::mailsend',
             step     =>'base::workflow::mailsend::dataload',
             name     =>$subject,
             emailtemplate  =>'eventnotification',
             skinbase       =>$self->getParent->getNotificationSkinbase($WfRec),
             emailfrom      =>$emailfrom,
             emailto        =>\@emailto,
             emailcc        =>\@emailcc,
             allowsms       =>$smsallow,
             emaillang      =>$eventlang,
             emailprefix    =>\@emailprefix,
             emailpostfix   =>\@emailpostfix,
             emailtext      =>\@emailtext,
             emailsep       =>\@emailsep,
             emailsubheader =>\@emailsubheader,
             emailsubtitle  =>\@emailsubtitle,
             additional     =>\%additional
            };
      if (my $id=$wf->Store(undef,$newmailrec)){
         if ($self->getParent->activateMailSend($WfRec,$wf,
                                                $id,$newmailrec,$action)){
            if ($wf->Action->StoreRecord(
                $WfRec->{id},"rootcausi",
                {translation=>'AL_TCom::workflow::eventnotify'},
                undef,undef)){
               Query->Delete("WorkflowStep");
               return(1);
            }
         }
      }
      else{
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec));
}



1;
