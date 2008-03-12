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
use Data::Dumper;
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

   if (!defined($newrec->{kh}->{mandator}) || 
       ref($newrec->{kh}->{mandator}) ne "ARRAY" ||
       !grep(/^AL T-Com$/,@{$newrec->{kh}->{mandator}})){
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
                    qw(EVt.iswtsi EVt.iswext EVt.wrkerr EVt.wrkerrito
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
   my $subjectlabel=shift;
   my $failclass=shift;
   my $ag=shift;
   my $subject;
   my $colon;
   $colon=":" if ($ag ne "");              
   $subject="$ag$colon Kundeninformation Anwendungsausfall/Störung";
   if ($WfRec->{eventmode} eq "EVk.net"){ 
      $subject="$ag$colon Kundeninformation Anwendungsausfall/Störung";
   }
   if ($WfRec->{eventmode} eq "EVk.infraloc"){ 
      $subject="$ag$colon Kundeninformation Anwendungsausfall/Störung";
   }
   $subject.=" HeadID ".$WfRec->{id};
   return($subject);
}

sub getSalutation
{
   my $self=shift;
   my $WfRec=shift;
   my $ag=shift;
   my $salutation;
   my $info;
   my $st;
 
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

die Beeinträchtigung im Umfeld der AG "$ag" wurde beseitigt.
EOF
   }elsif($WfRec->{eventmode} eq "EVk.appl"){
      $salutation=<<EOF;
Sehr geehrte Damen und Herren,

im Folgenden erhalten Sie den aktuellen Stand zum Ereignis
der Anwendung '$ag' vom $creationtime.
EOF
   }elsif ($WfRec->{eventmode} eq "EVk.net" && $eventstat==17){
      $salutation=<<EOF;
Sehr geehrte Kundin, sehr geehrter Kunde,

die Beeinträchtigung im Umfeld des TCP/IP-Netzes (HitNet) wurde beseitigt.
EOF
   }elsif($WfRec->{eventmode} eq "EVk.net"){   
      $salutation=<<EOF;
Sehr geehrte Damen und Herren,

folgende Informationen zum Ereignis im Bereich des 
TCP/IP-Netzes (HitNet) liegen derzeit vor:
$info
EOF
   }
   return($salutation);
}
 
sub getNotificationSkinbase
{
   my $self=shift;
   return('AL_TCom');
}

sub generateMailSet
{
   my $self=shift;
   my ($WfRec,$eventlang,$additional,$emailprefix,$emailpostfix,
       $emailtext,$emailsep,$emailsubheader,$emailsubtitle)=@_;
   my @emailprefix=();
   my @emailpostfix=();
   my @emailtext=();
   my @emailsep=();
   my @emailsubheader=();
   my @emailsubtitle=();

   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/auth/.*$##;
   }
   my @baseset=qw(wffields.eventstatclass wffields.eventstartofevent);
   my $fo=$self->getField("wffields.eventendofevent",$WfRec);
   if (defined($fo)){
      my $v=$fo->FormatedResult($WfRec,"HtmlMail");
      if (defined($v)){
         push(@baseset,"wffields.eventendofevent");
      }else{
         push(@baseset,"wffields.eventendexpected");
      }
   }
   # wffields.eventstatnature deleted w5baseid: 12039307490008 
   push(@baseset,qw(wffields.affectedregion));
   if ($WfRec->{eventmode} eq "EVk.appl"){
      push(@baseset,"affectedapplication");
      push(@baseset,"wffields.affectedcustomer");
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
   my $lang="de";
   my $line=0;
   my $mailsep=0;
   $mailsep="$lang:" if ($#emailsep!=-1); 
   $ENV{HTTP_FORCE_LANGUAGE}=$lang;

   my @fields=@{shift(@sets)};
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
            }elsif($field eq "wffields.shorteventelimination"){
                push(@emailsubtitle,"");    
                push(@emailprefix,"Kurzfristige Massnahme zur Servicewiederherstellung:");
            }else{
                push(@emailprefix,$fo->Label().":");
                push(@emailsubtitle,"");
            }
            $line++;
            $mailsep=0;
         }
     }
   }
   my $rel=$self->getField("relations",$WfRec);
   my $reldata=$rel->ListRel($WfRec->{id},"mail",{name=>\'consequenceof'});
   push(@emailprefix,$rel->Label().":");
   push(@emailtext,$reldata);
   push(@emailsubheader,0);
   push(@emailsep,0);
   push(@emailpostfix,"");
   delete($ENV{HTTP_FORCE_LANGUAGE});
   @$emailprefix=@emailprefix;
   @$emailpostfix=@emailpostfix;
   @$emailtext=@emailtext;
   @$emailsep=@emailsep;
   @$emailsubheader=@emailsubheader;
   @$emailsubtitle=@emailsubtitle;
}

1;
