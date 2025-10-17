package base::event::sendmail;
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
use kernel::Event;
use kernel::mime;
use MIME::Base64;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;

   $self->RegisterEvent("sendmail","Sendmail");
  # $self->CreateIntervalEvent("MyTime",10);
   return(1);
}

sub createSplitHeader
{
   my $self=shift;
   my $wf=shift;
   my $rec=shift;
   my $from=shift;
   my $Emailto=shift;
   my $Emailcc=shift;
   my $Emailbcc=shift;
   my $emailsig=shift;

   my $mail="";

   my $to=join(",\n ",@$Emailto);
   if (defined($emailsig) && $emailsig->{fromaddress} ne ""){
      $mail.="From: $emailsig->{fromaddress}\n";
   }else{
      $mail.="From: $from\n";
   }
   $mail.="To: $to\n" if ($to ne "");
   if (defined($emailsig) && $emailsig->{replyto} ne ""){
      $mail.="Reply-To: $emailsig->{replyto}\n";
   }
   my $cc=join(",\n ",@$Emailcc);
   my $bcc=join(",\n ",@$Emailbcc);
   
   
   $mail.="Cc: $cc\n" if ($cc ne "");
   $mail.="bcc: $bcc\n" if ($bcc ne "");
   $mail.="Subject: ".mimeencode($rec->{name})."\n";
   $mail.="Date: ".
      $wf->ExpandTimeExpression($rec->{createdate},"RFC822","GMT","GMT").
      "\n";
   my $emailcategory=$rec->{emailcategory};
   $emailcategory=[$emailcategory] if (ref($emailcategory) ne "ARRAY");
   my $opmode=$self->Config->Param("W5BaseOperationMode");
   foreach my $cat (@$emailcategory){
      $cat=trim($cat);
      if ($cat ne ""){
         $mail.="X-W5Category: $cat :X-W5Category\n";
         $mail.="X-W5FullqualifiedCategory: ".      # use FullqualifiedCategory
                $opmode.".".$cat.                   # to filter opmode+cat to
                " :X-W5FullqualifiedCategory\n";    # bypass MS-Outlook filter
      }                                             # limitations (no AND)
   }

   return($mail);

}

sub createSplitEmailHead
{
   my $self=shift;
   my $wf=shift;
   my $rec=shift;
   my $from=shift;
   my $FullEmailto=shift;
   my $FullEmailcc=shift;
   my $FullEmailbcc=shift;
   my $Emailto=shift;
   my $Emailcc=shift;
   my $Emailbcc=shift;
   my $emailsig=shift;
   my $splitnum=shift;
   my $mail="";

   @{$Emailto}=();
   @{$Emailcc}=();
   @{$Emailbcc}=();

   my $emailHead;

   my $headCheckCnt=0;

   my $rcpcnt=0;

   do{
      if ($#{$FullEmailto}!=-1){
         push(@{$Emailto},shift(@{$FullEmailto}));
         $rcpcnt++;
      }
      if ($#{$FullEmailcc}!=-1){
         push(@{$Emailcc},shift(@{$FullEmailcc}));
         $rcpcnt++;
      }
      if ($#{$FullEmailbcc}!=-1){
         push(@{$Emailbcc},shift(@{$FullEmailbcc}));
         $rcpcnt++;
      }
      $emailHead=$self->createSplitHeader(
         $wf, $rec, $from,
         $Emailto, $Emailcc, $Emailbcc,
         $emailsig
      );
      msg(DEBUG,"headcheck loop $headCheckCnt finished - l=".
                length($emailHead));
      $headCheckCnt++;
   }while((length($emailHead)<18000 || 
           $headCheckCnt<=1) &&     # 1st loop always have to work 
          $rcpcnt<1500 &&
          ($#{$FullEmailto}!=-1 ||  # if some idiot sends a 21k EMail Address
           $#{$FullEmailcc}!=-1 || 
           $#{$FullEmailbcc}!=-1));
   if ($$splitnum==0 && (        # processing first block, but there are
         $#{$FullEmailto}!=-1 || # some emails in todo List
         $#{$FullEmailcc}!=-1 ||
         $#{$FullEmailbcc}!=-1)){
      $$splitnum=1;  # now the upper routines know we are in splitmode
   }
   $mail=$emailHead;

   return($mail);
}

sub Sendmail
{
   my $self=shift;
   my $id=shift;
   my @processed=();
   my $app=$self->getParent();
   msg(DEBUG,"start Event Sendmail");

   my $baseurl=$self->Config->Param("EventJobBaseUrl");
   my $opmode=$self->Config->Param("W5BaseOperationMode");
   my @sendmailpath=qw(/usr/local/sbin/sendmail 
                       /sbin/sendmail 
                       /usr/sbin/sendmail 
                       /usr/lib/sendmail
                       /usr/lib/sbin/sendmail);
   my $sendmail=undef;
   foreach my $s (@sendmailpath){
      if (-x $s){
         $sendmail=$s;
         last;
      }
   }
   if (!defined($sendmail)){
      printf STDERR ("ERROR Handling fehlt\n");
      exit(1);
   }
   msg(DEBUG,"found sendmail at $sendmail");

   my $wf=getModuleObject($self->Config,"base::workflow");
   msg(DEBUG,"workflow DataObj loaded");
   if (defined($id)){
      msg(DEBUG,"Event($self):Sendmail wfheadid=$id");
      $wf->SetFilter({class=>'base::workflow::mailsend',state=>\'6',id=>\$id});
      $wf->SetFilter({class=>'base::workflow::mailsend',id=>\$id});

      $wf->SetCurrentView(qw(ALL));
      $wf->Limit(1);
   }
   else{
      msg(DEBUG,"Event($self):Sendmail cleanup");
      $wf->SetFilter([
                       {
                         class=>'base::workflow::mailsend',
                         state=>\'6',
                         isdeleted=>\'0',
                         mdate=>"<now-1h"
                       },
                       {
                         class=>'base::workflow::mailsend',
                         state=>\'1',
                         isdeleted=>\'0',
                         mdate=>"<now-48h"
                       },
                       {
                         class=>'base::workflow::mailsend',
                         state=>\'4',
                         isdeleted=>\'0',
                         mdate=>"<now-12h"
                       }
                     ]);
      $wf->SetCurrentView(qw(ALL));
      $wf->Limit(100);
   }
   my ($rec,$msg)=$wf->getFirst();
   if (defined($rec)){
      msg(DEBUG,"found record");
      my $smstext;
      $wf->Store($rec,{state=>4,step=>'base::workflow::mailsend::finish'});
      msg(DEBUG,"state of record id '%s' is set to 4",$rec->{id});
      do{
         my $blkcount=-1;
         my $emailsig;
         if ($rec->{emailsignatur} ne ""){
            my $ms=getModuleObject($self->Config,"base::mailsignatur");
            $ms->SetFilter({name=>\$rec->{emailsignatur},userid=>undef});
            my $msg;
            ($emailsig,$msg)=$ms->getOnlyFirst(qw(ALL));
         }
         $ENV{LANG}=$rec->{initiallang};
         msg(DEBUG,"loading mail informations");
         foreach my $d (qw(emailtext emailtstamp emailprefix emailpostfix 
                           emailhead emailsep emailsubheader emailsubtitle)){
            if (defined($rec->{$d})){
               if (ref($rec->{$d}) ne "ARRAY"){
                  $rec->{$d}=[$rec->{$d}];
               }
               if ($#{$rec->{$d}}>$blkcount){
                  $blkcount=$#{$rec->{$d}};
               }
            }
            else{
               $rec->{$d}=[];
            }
         }
         my @emaillang=split(/[,;\-.]/,$rec->{emaillang});
         my $e=$rec->{emaillang};
         @emaillang=@{$rec->{emaillang}} if (ref($rec->{emaillang}) eq "ARRAY");
         my $langcontrol;
         if ($#emaillang>0){
            foreach my $lang (@emaillang){
               $langcontrol.=" - " if ($langcontrol ne "");
               $langcontrol.="<a class=langcontrol href=\"#lang.$lang\">
                             $lang</a>";
            }
         }
         
         my $bound="d6f5".time()."af".time()."jhdfjasd";
         my $mixbound="d345".time()."af".time()."j34fjasd";
         my $from=$rec->{emailfrom};
         my $terminfrom=$rec->{emailfrom};
         if ($from eq ""){
            my $sitename=$self->Config->Param("SiteName");
            $sitename="W5Base" if ($sitename eq "");
            $from="\"$sitename\" <>";
            $terminfrom="CN=\"$sitename\":MAILTO:no_reply\@".
                        $rec->{initialsite}
         }
         else{
            if (my ($label,$email)=$rec->{emailfrom}=~m/^"(.*)" <(.*)>$/){
               $terminfrom="CN=\"$label\":MAILTO:$email";
            }
            else{
               $terminfrom="CN=\"Notifier\":MAILTO:$rec->{emailfrom}";
            }
         }
         my $template=$rec->{emailtemplate};
         $template="sendmail" if ($template eq "");
         my $skinbase=$rec->{skinbase};
         $skinbase="base" if ($skinbase eq "");
         if (my ($b,$t)=$template=~m/^(\S+)\/(\S+)$/){
            $skinbase=$b;
            $template=$t;
         }
         my @mailallow=split(/[,;]/,$self->Config->Param("W5BaseMailAllow"));
         msg(DEBUG,"sendmail:W5BaseOperationMode=$opmode");
         msg(DEBUG,"sendmail:W5BaseMailAllow=".join(" ",@mailallow));
         @mailallow=grep(!/^\s*$/,@mailallow);
         # TO Handling
         $rec->{emailto}=[$rec->{emailto}] if (ref($rec->{emailto}) ne "ARRAY");
         my @emailto=@{$rec->{emailto}};
         if ($#mailallow!=-1 || 
             $opmode eq "test" ||
             $opmode eq "dev"){
            @emailto=map({my $m=$_;
                          my $qm=quotemeta($m);
                          if (!grep(/^$qm$/i,@mailallow)){
                             $m=~s/\@.*$/\@trash.w5base.net/;
                          }
                          $m;
                         } @emailto);
         }
         # CC Handling
         $rec->{emailcc}=[$rec->{emailcc}] if (ref($rec->{emailcc}) ne "ARRAY");
         my @emailcc=@{$rec->{emailcc}};
         if ($#mailallow!=-1 || 
             $opmode eq "test" ||
             $opmode eq "dev"){
            @emailcc=map({my $m=$_;
                          my $qm=quotemeta($m);
                          if (!grep(/^$qm$/i,@mailallow)){
                             $m=~s/\@.*$/\@trash.w5base.net/;
                          }
                          $m;
                         } @emailcc);
         }
         # BCC Handling
         if (ref($rec->{emailbcc}) ne "ARRAY"){
            $rec->{emailbcc}=[$rec->{emailbcc}];
         }
         my @emailbcc=@{$rec->{emailbcc}};
         if ($#mailallow!=-1 || 
             $opmode eq "test" ||
             $opmode eq "dev"){
            @emailbcc=map({my $m=$_;
                          my $qm=quotemeta($m);
                          if (!grep(/^$qm$/i,@mailallow)){
                             $m=~s/\@.*$/\@trash.w5base.net/;
                          }
                          $m;
                         } @emailbcc);
         }


         my @FullEmailto=grep(!/^\s*$/,@emailto);
         my @FullEmailcc=grep(!/^\s*$/,@emailcc);
         my @FullEmailbcc=grep(!/^\s*$/,@emailbcc);

         my $splitnum=0;
         my $splitokcount=0;
         if ($#FullEmailto==-1 && $#FullEmailcc==-1 && $#FullEmailbcc==-1){
            $splitokcount=1;
         }
         do{   # split large Mails
            if ($#FullEmailto==-1 && $#FullEmailcc==-1 && $#FullEmailbcc==-1){
               next;
            }
            my $mail=$self->createSplitEmailHead(
               $wf, $rec, $from,
               \@FullEmailto, \@FullEmailcc, \@FullEmailbcc,
               \@emailto, \@emailcc, \@emailbcc,
               $emailsig,
               \$splitnum
            );
            my $MessageId=$rec->{id};
            if ($splitnum>=1){
               $MessageId.=".".$splitnum;
            }
          
            $mail.="Message-ID: <".$MessageId.'@'.$rec->{initialconfig}.'@'.
                   $rec->{initialsite}.'@'."W5Base>\n";
            if ($template ne ""){
               $mail.="X-W5MailTemplate: $template :X-W5MailTemplate\n";
            }
            if ($opmode ne ""){
               $mail.="X-W5OPMode: $opmode :X-W5OPMode\n";
            }
            $mail.="Mime-Version: 1.0\n";

            if ($splitnum>=1){
               sleep(1); # sendmail calls nicht zu schnell durchführen
               my $wfop=$wf->Clone();
               $wfop->Action->StoreRecord( $rec->{id},"note",
                    {translation=>'base::workflow::sendmail'},
                    "message splitmode pack $splitnum",undef,
                    {TopHeaderSize=>length($mail)}
               );
            }
            $mail.="Content-Type: multipart/mixed; boundary=\"$mixbound\"\n";
            $mail.="--$mixbound";
            $mail.="\n";
            $mail.="Content-Type: multipart/alternative; boundary=\"$bound\"\n";
            $mail.="--$bound";
            $mail.="\n";
            $mail.="Content-Type: text/plain; charset=\"iso-8859-1\"\n\n";
            #printf STDERR ("%s\n",$mail);       
            {
               my $plaintext;
               for(my $blk=0;$blk<=$blkcount;$blk++){
                  $plaintext.=$rec->{emailprefix}->[$blk];
                  $plaintext.="\n"; 
                  my $emailtext=$rec->{emailtext}->[$blk];
                  $emailtext=~s#<[a-z/].*?>##g;
                  $emailtext=~s#&nbsp;# #g;
                  $emailtext=~s#^\.\s*$# .\n#mg;  # prevent . finish of mail
                  $plaintext.=$emailtext;
                  $plaintext.="\n-\n"; 
               }
               if ($plaintext ne ""){
                  $mail.=$plaintext;
                  $smstext=$plaintext;
               }
            }
          
          
            $mail.="\n--$bound";
            $mail.="\n";
            my $relbound="Rel.$bound";
            $mail.="Content-Type: multipart/related; boundary=\"$relbound\"\n\n";
            $mail.="--$relbound";
            $mail.="\n";
            $mail.="Content-Type: text/html; charset=\"iso-8859-1\"\n\n";
            my $additional=$rec->{additional};
            my %additional=();
            foreach my $k (keys(%$additional)){
               if (ref($additional->{$k}) eq "ARRAY"){
                  $additional{$k}=join(", ",@{$additional->{$k}});
               }
               else{
                  $additional{$k}=$additional->{$k};
               }
            }
            #msg(DEBUG,"add=%s",Dumper(\%additional));
            my $currentlang=shift(@emaillang);
            my $formname="tmpl/$template.form.head";
            my $maildata="ERROR: critical application problem - ".
                         "mail template not found";
            #msg(DEBUG,"loading and parsing mail template");
            $app->setSkinBase($skinbase);
            my $sep=0;
            my %useadditional=%additional;
            foreach my $k (keys(%useadditional)){
               if ($k=~m/PAGE$sep$/){
                  my $knew=$k;
                  $knew=~s/PAGE\d+$//;
                  $useadditional{$knew}=$additional{$k};
               }
            }
          
          
            if ($app->getSkinFile($app->SkinBase()."/".$formname)){
               $maildata=$app->getParsedTemplate($formname,
                                        {static=>{
                                           %useadditional,
                                           currentlang =>$currentlang,
                                           langcontrol =>$langcontrol,
                                         }
                                        });
            }
            $mail.=$maildata;
            #msg(DEBUG,"adding $blkcount datablocks to mail body");
            $mail.="<a name=\"separation.$sep\"></a>";
            $mail.="<div class=\"separation\" id=\"separation.$sep\">";
            $mail.="<div class=\"separationbackground\">";
            for(my $blk=0;$blk<=$blkcount;$blk++){
               my $formname="tmpl/$template.form.line";
               my $maildata="ERROR: Mail template not found";
               if (my $skinfile=$app->getSkinFile($app->SkinBase()."/".$formname)){
   #               my $emailtext="<!-- skinfile=$skinfile -->\n".
                  my $emailtext=$rec->{emailtext}->[$blk];
                  if (!(($emailtext=~m/<a/) ||
                        ($emailtext=~m/<b>/) ||
                        ($emailtext=~m/<center>/) ||
                        ($emailtext=~m/<\/b>/) ||
                        ($emailtext=~m/<\/ul>/) ||
                        ($emailtext=~m/<i>/) ||
                        ($emailtext=~m/<div/))){
                     $emailtext=~s/</&lt;/g;
                     $emailtext=~s/>/&gt;/g;
                  }
                  $emailtext=FancyLinks($emailtext);
                  $emailtext=mkMailInlineAttachment($baseurl,$emailtext);
                  my $emailbottom=$rec->{emailbottom};
                  if (ref($rec->{emailbottom}) eq "ARRAY"){
                     $emailbottom=$rec->{emailbottom}->[$blk];
                  }
                  if (defined($emailbottom) && $emailbottom eq ""){
                     $emailbottom="<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>";
                  }
                  #msg(DEBUG,"try add blk $blk");
                  if ($rec->{emailsubheader}->[$blk] ne "" &&
                      $rec->{emailsubheader}->[$blk] ne "0"){
                     my $sh=$rec->{emailsubheader}->[$blk];
                     if ($sh eq "1"){
                        $sh="";
                     }
                     if ($sh eq " "){
                        $sh="&nbsp;";
                     }
                     $sh=~s/\n/<br>\n/g;
                     $mail.="<div class=subheader>".$sh."</div>";
                  }
                  my $prepemailpostfix=$rec->{emailpostfix}->[$blk];
                  if ($prepemailpostfix=~m/^\s*$/){
                     $prepemailpostfix="<font size=1>&nbsp;</font>";
                  }
                  $maildata=$app->getParsedTemplate($formname,{
                             static=>{
                                %useadditional,
                                emailtext   =>$emailtext,
                                emailhead   =>$rec->{emailhead}->[$blk],
                                emailbottom =>$emailbottom,
                                emailtstamp =>$rec->{emailtstamp}->[$blk],
                                emailprefix =>$rec->{emailprefix}->[$blk],
                                emailsubtitle =>$rec->{emailsubtitle}->[$blk],
                                emailpostfix=>$prepemailpostfix,
                                currentlang =>$currentlang,
                                langcontrol =>$langcontrol,
                                                     }
                              });
                  $maildata=~s#^\.\s*$# .\n#mg;  # prevent . finish of mail
                  if ($rec->{emailsep}->[$blk] ne "" &&
                      $rec->{emailsep}->[$blk] ne "0"){
                     $currentlang=shift(@emaillang);
                     my $septext=$rec->{emailsep}->[$blk];
                     if ($septext eq "1"){
                        $septext="";
                     }
                     $mail.="</div>";
                     $mail.="</div>";
                     $sep++;
                     %useadditional=%additional;
                     foreach my $k (keys(%useadditional)){
                        if ($k=~m/PAGE$sep$/){
                           my $knew=$k;
                           $knew=~s/PAGE\d+$//;
                           $useadditional{$knew}=$additional{$k};
                        }
                     }
                     my $formname="tmpl/$template.form.sep";
                     my $maildata="ERROR: Mail template not found";
                     if ($app->getSkinFile($app->SkinBase()."/".$formname)){
                        my $sep=$app->getParsedTemplate($formname,{
                                           static=>{
                                              %useadditional,
                                              currentlang=>$currentlang,
                                              separation=>$sep,
                                              septext=>$septext,
                                              langcontrol =>$langcontrol,
                                            }});
                        $mail.=$sep;
                   
                     }
                     $mail.="<a name=\"separation.$sep\"></a>";
                     $mail.="<div class=\"separation\" id=\"separation.$sep\">";
                     $mail.="<div class=\"separationbackground\">";
                  }
                  #msg(DEBUG,"add blk $blk ok");
               }
               $mail.=$maildata;
            }
            $mail.="</div>";
            $mail.="</div>";
            #msg(DEBUG,"adding mail bottom");
            my $formname="tmpl/$template.form.bottom";
            my $maildata="ERROR: Mail template not found";
            if ($app->getSkinFile($app->SkinBase()."/".$formname)){
               my $emailbottom=$rec->{emailbottom};
               if (ref($emailbottom) eq "ARRAY"){
                  $emailbottom=join("",@{$emailbottom});
               }
               my $mailsignature="";
               if (defined($emailsig) && $emailsig->{htmlsig} ne ""){
                  $mailsignature=$emailsig->{htmlsig};
               }
          
               $maildata=$app->getParsedTemplate($formname,{
                                              static=>{
                                                 %additional,
                                                 langcontrol =>$langcontrol,
                                                 emailbottom =>$emailbottom,
                                                 MAILSIGNATURE=>$mailsignature
                                              }});
            }
            $mail.=$maildata;
          
            $mail.="\n--$relbound";
            #msg(DEBUG,"adding pictures to mail body as multiplart content");
            for(my $c=1;$c<=9;$c++){
               my $imgname="$template.bild$c.jpg";
               my $qimgname=quotemeta($imgname);
               if (grep(/cid:$qimgname/,$mail)){
                  if (my $pic=$app->getSkinFile($app->SkinBase()."/img/".
                                                $imgname)){
                     if (open(IMG,"<$pic")){
                        my $imgbin=join("",<IMG>);
                        close(IMG);
                        $mail.="\nContent-ID: <$imgname>\n";
                        $mail.="Content-Type: image/jpg\n";
                        $mail.="Content-Name: $imgname\n";
                        $mail.="Content-Transfer-Encoding: base64\n\n";
                        $mail.=encode_base64($imgbin);
                        $mail.="\n--$relbound";
                     }
                  }
               }
            }
            $mail.="--\n";
            my $tstart=$rec->{terminstart};
            my $tend=$rec->{terminend};
            if ($tend ne "" && $tstart ne ""){
               $mail.="\n--$bound\n";
               $mail.="Content-Type: text/calendar\n";
               $mail.="\n";
               $mail.="BEGIN:VCALENDAR\n";
               $mail.="METHOD:PUBLISH\n";
               $mail.="PRODID:http://$rec->{initialsite}\n";
               $mail.="VERSION:2.0\n";
          
               $mail.="BEGIN:VTIMEZONE\n";
               $mail.="TZID:GMT\n";
               $mail.="BEGIN:STANDARD\n";
               $mail.="TZOFFSETTO:+0000\n";
               $mail.="END:STANDARD\n";
               $mail.="END:VTIMEZONE\n";
          
               $mail.="BEGIN:VEVENT\n";
               $mail.="SUMMARY:$rec->{name}\n";
               # aus absender
               $mail.="ORGANIZER;".$terminfrom."\n";
               # aus to
               foreach my $e (@emailto){
                  if ($e ne ""){
                     $mail.="ATTENDEE;ROLE=REQ-PARTICIPANT;".
                            "PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN=:".
                            "MAILTO:$e\n";
                  }
               }
               # aus cc
               foreach my $e (@emailcc){
                  if ($e ne ""){
                     $mail.="ATTENDEE;ROLE=OPT-PARTICIPANT;".
                            "PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN=:".
                            "MAILTO:$e\n";
                  }
               }
               
               $mail.="DTSTART;TZID=GMT:".
                      $app->ExpandTimeExpression($tstart,"ICS")."\n";
               $mail.="DTEND;TZID=GMT:".
                      $app->ExpandTimeExpression($tend,"ICS")."\n";
               my $uid;
               if ($rec->{directlnkid} ne ""){
                  $uid=$rec->{directlnkid};
                  $uid.='@'.$rec->{directlnkmode}.'@'.$rec->{directlnktype};
               }
               else{
                  $uid=$rec->{id};
               }
               $mail.="UID:$uid\@$rec->{initialsite}\n";  
               $mail.="CLASS:PUBLIC\n";
               $mail.="DTSTAMP:".
                      $app->ExpandTimeExpression($rec->{createdate},"ICS")."\n";
               $mail.="STATUS:REQUEST\n";
               if ($rec->{terminlocation} ne ""){
                  $mail.="LOCATION:".$rec->{terminlocation}."\n";
               }
               $mail."PRIORITY:".$rec->{prio}."\n";
               if ($rec->{terminnotify}>0){
                  $mail.="BEGIN:VALARM\n";
                  $mail.="ACTION:DISPLAY\n";
                  $mail.="DESCRIPTION:REMINDER\n";
                  $mail.="TRIGGER;RELATED=START:-PT".$rec->{terminnotify}."M\n";
                  $mail.="END:VALARM\n";
               }
          
               $mail.="END:VEVENT\n";
               $mail.="END:VCALENDAR\n";
            }
          
            $mail.="\n--$bound--\n";
            {
               my $wfa=getModuleObject($self->Config,"base::wfattach");
               $wfa->SetFilter({wfheadid=>\$rec->{id}});
               my ($attrec,$msg)=$wfa->getOnlyFirst(qw(ALL));
               $wfa->SetCurrentView(qw(contenttype name data));
               my ($attrec,$msg)=$wfa->getFirst(unbuffered=>1);
               if (defined($attrec)){
                  do{
                     $mail.="\n--$mixbound\n";
                     $mail.="Content-Type: $attrec->{contenttype}\n";
                     $mail.="Content-Name: $attrec->{name}\n";
                     $mail.="Content-Disposition: attachment; ".
                            "filename=$attrec->{name}\n";
                     $mail.="Content-Transfer-Encoding: base64\n\n";
                     $mail.=encode_base64($attrec->{data});
                     ($attrec,$msg)=$wfa->getNext();
                  }until(!defined($attrec));
               }
            }
            $mail.="\n--$mixbound--\n";
            ####################################################################
            # SMS Handling
            if ($rec->{allowsms}==1 &&
                $self->Config->Param("SMSInterfaceScript") ne ""){
               my $smsscript=$self->Config->Param("SMSInterfaceScript");
               #msg(DEBUG,"prepare to call $smsscript");
               my $user=getModuleObject($self->Config,"base::user");
               $user->SetFilter({email=>\@emailto});
               my @smsrec=$user->getHashList(qw(fullname sms 
                                                office_mobile private_mobile));
               $smstext=$rec->{smstext} if ($rec->{smstext} ne "");
               my @numlist;
               foreach my $smsrec (@smsrec){
                  my $number;
                  if ($smsrec->{sms} eq "officealways"){
                     $number=$smsrec->{office_mobile};
                  }
                  if ($smsrec->{sms} eq "homealways"){
                     $number=$smsrec->{private_mobile};
                  }
                  if (defined($number)){
                     $number=~s/[\s-\/\(\)]//g;
                     #msg(DEBUG,"sending sms to $smsrec->{fullname}");
                     push(@numlist,$number);
                     if (open(F,"|".$smsscript." \"-s\" -- \"$number\"")){
                        print F $smstext;
                        close(F);
                     }
                     else{
                        msg(ERROR,"cant initiate sms to $smsrec->{fullname}");
                     }
                  }
               }
               if ($#numlist!=-1){
                  if (open(F,"|".$smsscript." \"-m\" -- ".
                             join(" ",map({'"'.$_.'"'} @numlist)))){
                     print F $smstext;
                     close(F);
                  }
               }
            }
            ####################################################################
            #msg(DEBUG,"deliver maildata to $sendmail");
            my $bouncehandler=$self->Config->Param("MAILBOUNCEHANDLER");
            $bouncehandler='bounce@w5base.net' if ($bouncehandler eq "");
            if (open(F,"|".$sendmail." -f $bouncehandler -t")){
               print F $mail;
               close(F);
               push(@processed,$rec->{id});
               if (open(D,">/tmp/mail.dump${splitnum}.tmp")){
                  print D $mail;
               }
               $splitokcount++;
            }
            $splitnum++;
         }while($#FullEmailto!=-1 || $#FullEmailcc!=-1 || $#FullEmailbcc!=-1);
         if ($splitokcount>0){
            my $wfop=$wf->Clone();
            my $finerec={state=>21,
                         eventend=>NowStamp("en"),
                         closedate=>NowStamp("en"),
                         step=>'base::workflow::mailsend::finish'};
            $wfop->Store($rec,$finerec);
         }
         #msg(DEBUG,"try to load next record");
         ($rec,$msg)=$wf->getNext();
      }until(!defined($rec));
   }

   
   return({exitcode=>0,processed=>($#processed+1)});
}





1;
