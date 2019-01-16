package faq::forum;
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
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{maintabparam}="class=boardgroup cellspacing=1 border=0 ".
                         "cellpadding=0 width=95%";
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main addAttach Topic NativNewTopic NewTopic HandleInfoAboSubscribe
             HandleShowSubscribers));
}

sub Main
{
   my ($self)=@_;

   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','public/faq/load/forum.css'],
                           js=>['toolbox.js','subModal.js',
                                'TextTranslation.js'],
                           prefix=>$rootpath,
                           form=>1,
                           title=>$self->T($self->Self()));
   $rootpath.="/" if ($rootpath eq "..");
   my @param=split(/\//,$p);
   print $self->HtmlSubModalDiv(prefix=>$rootpath);
  
   $p=~s/\///g;
   $self->ShowBoards($rootpath) if ($p eq ""); 
   $self->ShowBoard($rootpath,$p) if ($p ne ""); 
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Topic
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','public/faq/load/forum.css'],
                           js=>['toolbox.js','subModal.js',
                                'TextTranslation.js'],
                           prefix=>$rootpath,
                           form=>1,
                           title=>$self->T($self->Self()));
   $rootpath.="/" if ($rootpath eq "..");
   print $self->HtmlSubModalDiv(prefix=>$rootpath);

   $p=~s/\///g;
   if ($p ne ""){
      $self->ShowTopic($rootpath,$p);
   }
   else{
      print("Exeption");
   }
   print $self->HtmlBottom(body=>1,form=>1);
}


sub NewTopic
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','public/faq/load/forum.css'],
                           js=>['toolbox.js','subModal.js',
                                'TextTranslation.js'],
                           form=>1,
                           title=>$self->T($self->Self()));
   print $self->HtmlSubModalDiv();
   my $board=Query->Param("board");
   if ($board ne ""){
      my $bo=$self->getPersistentModuleObject("faq::forumboard");
      $bo->SetFilter({id=>\$board});
      my ($borec,$msg)=$bo->getOnlyFirst(qw(name));
      my $t=$self->T("new topic");
      print $self->getAppTitleBar(title=>'Forum: '.
                    "<a href=\"Main\" class=toplink>Boards</a> &bull; ".
                    "<a href=\"Main/$board\" class=toplink>$borec->{name}</a>".
                    ' &bull; '.$t);
      $self->ShowNewTopic();
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub addAttach
{
   my $self=shift;
   return($self->kernel::App::Web::Listedit::addAttach());
}



sub ShowNewTopic
{
  my $self=shift;
  print("<br><center>".
        "<table $self->{maintabparam}>");
  if (Query->Param("DO") ne ""){
     my %rec=(name=>Query->Param("name"),
              comments=>Query->Param("comments"),
              forumboard=>Query->Param("board"));
     my $to=$self->getPersistentModuleObject("faq::forumtopic");
     $to->Context->{DataInputFromUserFrontend}=1;
     if (my $id=$to->ValidatedInsertRecord(\%rec)){
        my $t=$self->T("Topic successfull saved");
        print("<tr><td>${t}.</td></tr></table>");
        my $ref=Query->Param("HTTP_REFERER"); 
        if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
           $ref=~s/^http:/https/gi;
        }
        print("<script language=\"JavaScript\">".
              "window.setTimeout('document.location.href=\"$ref\";', 500);".
              "</script>");
        return();
     }
  }
  my $newtopic=$self->T("new topic");
  print("<tr><th class=boardgroup colspan=3>$newtopic</th></tr>");
  my $name=Query->Param("name");
  my $comments=Query->Param("comments");
  print("<tr><td width=1%>".$self->T("Topic","faq::forumtopic").":</td>".
        "<td colspan=2>".
        "<input name=name value=\"$name\" ".
        "type=text style=\"width:100%\"></td></tr>");
  print("<tr><td colspan=3>".
        "<textarea onkeydown=\"textareaKeyHandler(this,event);\" ".
        "name=comments id=comments ".
        "rows=10 cols=20 style=\"width:100%\">".
        "$comments</textarea></td></tr>"); 
  my $lastmsg=$self->findtemplvar({},"LASTMSG");
  my $send=$self->T("send");
  print(<<EOF);
<tr>
<td colspan=3>
<table border=0 cellspacing=0 cellpadding=0 width="100%">
<tr>
<td align=left>$lastmsg</td>
<td width=1% align=right>
<input type=button onClick="doSave();" value=" $send "></td></tr>
<input type=hidden name=DO value="1">
</table>
</td></tr>
</table></center>
<script language="JavaScript">
function doSave()
{
   document.forms[0].submit();
}
</script>
EOF
  print $self->HtmlPersistentVariables("board","HTTP_REFERER");
}


sub getShowTopicDetailFunctions
{
   my $self=shift;
   my $rootpath=shift;
   my $mode=shift;
   my $id=shift;
   my $d="";
   $d.=<<EOF;
<a href=\"javascript:DetailHandleInfoAboSubscribe()\" class=detailfunctions>InfoAbo</a>
<script language="JavaScript">
function DetailHandleInfoAboSubscribe()
{
   showPopWin('${rootpath}HandleInfoAboSubscribe?CurrentIdToEdit=$id,$mode',585,300,
              FinishHandleInfoAboSubscribe);
}
function FinishHandleInfoAboSubscribe(returnVal,isbreak)
{
   if (!isbreak){
      document.location.href=document.location.href;
   }
}
</script>
EOF
   my $to=$self->getPersistentModuleObject("faq::forumtopic");
   $to->SetFilter({id=>\$id});
   my ($torec,$msg)=$to->getOnlyFirst(qw(ALL));
   my @wr=$to->isWriteValid($torec);
   if ($#wr!=-1 && grep(/^default$/,@wr)){
         my $detailx=$to->DetailX();
         my $detaily=$to->DetailY();
         my $onclick="openwin('../../forumtopic/ById/$id',".
                     "'_blank',".
                     "'height=$detaily,width=$detailx,toolbar=no,status=no,".
                     "resizable=yes,scrollbars=no');";
      $d.=" &bull; <span class=detailfunctions onclick=$onclick>".
          $self->T("edit","kernel::Output::HtmlDetail")."</span>";

   }


   return($d);
}

sub ShowTopic
{
   my $self=shift;
   my $rootpath=shift;
   my $id=shift;

   my $allowclose=Query->Param("AllowClose");
   my $en=$self->getPersistentModuleObject("faq::forumentry");
   my $to=$self->getPersistentModuleObject("faq::forumtopic");
   $to->SecureSetFilter({id=>\$id});
   my ($torec,$msg)=$to->getOnlyFirst(qw(ALL));
   if (!defined($torec)){
      print("no access or topic not found");
      return();
   }

   if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
      $to->ValidatedUpdateRecord($torec,{viewcount=>$torec->{viewcount}+1,
                                         mdate=>$torec->{mdate},
                                         owner=>$torec->{owner},
                                         editor=>$torec->{editor},
                                         realeditor=>$torec->{realeditor}},
                                {id=>\$torec->{id}});
   }

   my $bo=$self->getPersistentModuleObject("faq::forumboard");
   $bo->SetFilter({id=>$torec->{forumboard}});
   my ($borec,$msg)=$bo->getOnlyFirst(qw(ALL));
   if (defined($borec) && defined($torec)){
      my $comments=Query->Param("comments");
      if ($comments ne ""){
         $en->Context->{DataInputFromUserFrontend}=1;
         $en->ValidatedInsertRecord({comments=>$comments,
                                     forumtopic=>$torec->{id}});
      }
   }
   print $to->extendHtmlDetailPageContent("../../..",140,$torec);

   $en->ResetFilter();
   $en->SetFilter({forumtopic=>\$torec->{id}});

   if (!$allowclose){
      print $self->getAppTitleBar(prefix=>$rootpath,
                                  title=>'Forum: '.
                                         "<a class=toplink ".
                                         "href=\"../Main\">Boards</a> &bull;".
                                         "<a class=toplink ".
                                         "href=\"../Main/$borec->{id}\">".
                                         "$borec->{name}</a>");
      print("<br>");
   }
   else{
      print("<table width=\"100%\" cellspacing=0 cellpadding=0 border=0>");
      print("<tr><td align=right><div class=OnlyInBrowser>");
      print("<a class=FunctionLink href=JavaScript:DetailPrint()>".
            $self->T("DetailPrint","kernel::App::Web::Listedit")."</a> &bull;");
      print("<a class=FunctionLink href=JavaScript:DetailClose()>".
            $self->T("DetailClose","kernel::App::Web::Listedit")."</a>");
      print("&nbsp; </div></td><tr></table>");

   }
   my $grp="0"; 
   print("<center><div id=mainarea style=\"overflow:auto\"> ".
         "<table $self->{maintabparam}>");
   my $Q="";
   $Q="&AllowClose=1" if ($allowclose);
   if ($allowclose){
      printf("<tr><td colspan=3 class=topiclabel>".
             "<table width=\"100%%\" cellspacing=0 cellpadding=0 border=0>".
             "<tr><td><b>".
             $self->T("Board","faq::forumboard").":</b> ".
             "$borec->{name}".
             "</td></tr></table></td></tr>");
   }
   printf("<tr><td colspan=3 class=topiclabel>".
          "<table width=\"100%%\" cellspacing=0 cellpadding=0 border=0>".
          "<tr><td><b>".
          $self->T("Topic","faq::forumtopic").":</b> <a class=topiclink ".
          "href=\"./$torec->{id}$Q\">$torec->{name}</a>".
          "</td><td width=1%% valign=top nowrap>".
          "<div class=OnlyInBrowser>%s</div></td></tr></table></td></tr>",
          $self->getShowTopicDetailFunctions($rootpath,"topic",$id));
   my $label=$self->T("topic answers")." ($torec->{entrycount})";
   if ($torec->{entrycount}==0){
      my $label=$self->T("topic entry");
   }
   print("<tr>".
         "<th class=boardgroup width=200>".
         $self->T("autor","faq::forum")."</th>".
         "<th class=boardgroup>$label</th></tr>");
   my @l=$en->getHashList(qw(cdate mdate comments creator id));
   my $l=1;
   my $line=0;
   my $creatorfld=$en->getField("creator");
   my $cdatefld=$en->getField("cdate");
   foreach my $rec ($torec,@l){
      my $linelabel="";
      $linelabel="<a href=\"?go=$rec->{id}\" class=ForumDirectLink ".
                 "name=\"E$rec->{id}\">#$line</a>" if ($line>0);
      print("<tr class=l$l id=\"E$rec->{id}\">");
      my $creator=$creatorfld->FormatedDetail($rec,"HtmlForum");
      $creator=~s/\s\(/<br>(/;
      my $cdate=$cdatefld->FormatedDetail($rec,"HtmlDetail");
      $cdate=~s/\s\(/<br>(/;
    #  print("<td valign=top width=200>$creator".
    #        "<br>$cdate<br>Beiträge: 123<br>EMail, Home".
    #        "</td>");
     # print("<td width=1><img height=120 width=1 ".
     #       "src=\"${rootpath}../../base/load/empty.gif\"></td>");
      my $comments=$rec->{comments};
      $comments=~s/</&lt;/g;
      $comments=~s/>/&gt;/g;
      $comments=mkInlineAttachment(FancyLinks($comments),$rootpath);

      print <<EOF;
<td valign=top width=200 class=authorlabel>$creator<br>$cdate<br>
<table width="100%">
<tr><td><!-- Beitragscount des users --></td><td align=right><!-- profile link -->
</td></tr></table></td><td width=70% valign=top>
<table style="table-layout:fixed" width="100%" cellspacing=0 cellpadding=0>
<tr><td><pre class=wraped style="overflow:hidden">$comments</pre></td>
<td width=25 valign=top>$linelabel</td></tr></table>
</td></tr>
EOF
      $l++;
      $l=1 if ($l>2);
      $line++; 
   }
   print(<<EOF);
</table>
<a name="end"></a>
</div>
<div class=OnlyInBrowser>
<center>
<table $self->{maintabparam}>
EOF
   my $answerok=0;
   my @acl=$bo->getCurrentAclModes($ENV{REMOTE_USER},$borec->{acls});
   if ($self->IsMemberOf("admin") ||
       grep(/^write$/,@acl) ||
       grep(/^moderate$/,@acl) ||
       grep(/^answer$/,@acl)){
      $answerok=1;
   }
   my $answer=$self->T("answer");
   my $send=$self->T("send");
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $answerok=0;
   }
   print(<<EOF) if ($answerok);
<tr>
<th class=boardgroup colspan=3>$answer:</th></tr>
<tr>
<td colspan=3>
<input type="hidden" value="last" name="go">
<textarea onkeydown=\"textareaKeyHandler(this,event);\" 
          name=comments id=comments rows=5 cols=5 style="width:100%">
</textarea></td></tr>
<tr>
<td colspan=3 align=right>
<input type=submit value=" $send "></td></tr>
EOF
   my $go=Query->Param("go");
   print(<<EOF);
</table></center></div>
<script language="JavaScript">
function modMainTab()
{
   var d=document.getElementById("mainarea");
   var comments=document.getElementById("comments");
   d.style.height="1px";
   var h=getViewportHeight();
   if (comments){
      h=h-180;
   }
   else{
      h=h-40;
   }
   d.style.height=h+"px";
   if ("$go"=="last"){
      d.scrollTop=d.scrollHeight;
   }
   else{
      if ("$go"!=""){
         var y=document.getElementById("E$go");
         if (y){
            y=y.offsetTop;
            d.scrollTop=y;
         }
      }
   }
   
}
function DetailClose()
{
   window.close();
}
function DetailPrint()
{
   var d=document.getElementById("mainarea");
   d.style.height="auto";
   window.print();
   window.setTimeout("modMainTab();",2000);
}
addEvent(window,"load",modMainTab);
addEvent(window,"resize",modMainTab);
</script>
<style>
\@media print {
   div.OnlyInBrowser{
      display:none;
      visibility:hidden;
   }
   #mainarea{
      height:auto;
      overflow:auto;
   }
}
div.OnlyInBrowser{
   margin:0;
   padding:0;
}
</style>
EOF
  print $self->HtmlPersistentVariables("AllowClose");
  my $forumtopicread=$self->getPersistentModuleObject("faq::forumtopicread");
  my $now=$self->ExpandTimeExpression('now');
  if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
     $forumtopicread->InsertRecord({forumtopicid=>$torec->{id},
                                    cdate=>$now,
                                    clientipaddr=>getClientAddrIdString(),
                                    creatorid=>$self->getCurrentUserId()});
  }
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my ($id,$mode)=split(/,/,Query->Param("CurrentIdToEdit"));
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
#      $self->ResetFilter();
#      $self->SetFilter({id=>\$id});
#      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      $mode="board" if ($mode eq "");
      my @modes;
      if ($mode eq "board"){
         my $bo=$self->getPersistentModuleObject("faq::forumboard");
         $bo->SetFilter({id=>\$id});
         my ($borec,$msg)=$bo->getOnlyFirst(qw(ALL));
         if (defined($borec)){
            unshift(@modes,"faq::forumboard",$id,$borec->{name});
         }
      }
      if ($mode eq "topic"){
         my $to=$self->getPersistentModuleObject("faq::forumtopic");
         $to->SetFilter({id=>\$id});
         my ($torec,$msg)=$to->getOnlyFirst(qw(ALL));
         if (defined($torec)){
            unshift(@modes,"faq::forumboard",
                           $torec->{forumboard},$torec->{forumboardname});
            unshift(@modes,"faq::forumtopic",$id,$torec->{name});
         }
      }
      print($ia->WinHandleInfoAboSubscribe({},@modes,
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }

}

sub HandleShowSubscribers
{
   my $self=shift;
   my ($id,$mode)=split(/,/,Query->Param("CurrentIdToEdit"));
   my ($borec,$msg);
   my $ismoderator=0;
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      my $bo=$self->getPersistentModuleObject("faq::forumboard");
      $bo->SetFilter({id=>\$id});
      ($borec,$msg)=$bo->getOnlyFirst(qw(ALL));
      my @acl=$bo->getCurrentAclModes($ENV{REMOTE_USER},$borec->{acls});
      if ($self->IsMemberOf("admin") ||
          grep(/^moderate$/,@acl)){
         $ismoderator=1;
      }
   }
   if (defined($borec)){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css'],
                              form=>1,body=>1,
                              title=>$self->T("subscribers"));
      my $d;
      if ($ismoderator){
         my $subjectprefix=$self->T("moderator info");
         my $sitename=$self->Config->Param("SITENAME");
         if ($sitename ne ""){
            $subjectprefix="$sitename: ".$subjectprefix;
         }
         my $user=$self->getPersistentModuleObject("base::user");
         my $msg=$self->T("remove user from list");
         $d.=<<EOF;
<script language="JavaScript">
function removeUser(userid)
{
   if (confirm("$msg ?")){
      var e=document.getElementById("ruserid");
      e.value=userid;
      document.forms[0].submit();
   }
}
</script>
EOF
         my $ruserid=Query->Param("ruserid");
         if ($ruserid=~m/^\d+$/){
            $user->SetFilter({userid=>\$ruserid});
            my ($urec,$msg)=$user->getOnlyFirst(qw(email));
            if (defined($urec)){
               foreach my $mode (qw(foaddtopic foboardansw)){
                  $ia->ValidatedInsertOrUpdateRecord(
                       {refid=>$id,mode=>$mode,active=>'0',
                        userid=>$ruserid,
                        parentobj=>'faq::forumboard'},
                       {refid=>\$id,mode=>\$mode,userid=>\$ruserid,
                        parentobj=>\'faq::forumboard'});
               }
               my $wf=getModuleObject($self->Config,"base::workflow");
               my %notiy;
               $notiy{name}="$subjectprefix: ".$borec->{name};
               $notiy{emailto}=$urec->{email};
               $notiy{emailtext}=sprintf($self->T(
                                 "The Board manager has removed ".
                                 "you from board \"%s\"."),
                                 $borec->{name});
               $notiy{class}='base::workflow::mailsend';
               $notiy{step}='base::workflow::mailsend::dataload';
               if (my $id=$wf->Store(undef,\%notiy)){
                  my %d=(step=>'base::workflow::mailsend::waitforspool');
                  my $r=$wf->Store($id,%d);
               }
            }
         }
         ####################################################################
         # for add operations
         ####################################################################
         my $oldval=Query->Param("Formated_addcon");
         my ($n,$userfullname,$edt,
             $keylist,$vallist,$list)=$user->getHtmlTextDrop("addcon",$oldval,
                                             vjoindisp=>'fullname',
                                             fields=>['userid','email'],
                                             vjoineditbase=>{cistatusid=>\'4'});
         if (defined($n) && $n==1 && $list->[0]->{userid}=~m/^\d+$/){
            my $adduserid=$list->[0]->{userid};
            my $email=$list->[0]->{email};
            foreach my $mode (qw(foaddtopic foboardansw)){
               $ia->ValidatedInsertOrUpdateRecord(
                    {refid=>$id,mode=>$mode,active=>'1',
                     userid=>$adduserid,
                     parentobj=>'faq::forumboard'},
                    {refid=>\$id,mode=>\$mode,userid=>\$adduserid,
                     parentobj=>\'faq::forumboard'});
            }
            Query->Param("Formated_addcon"=>'');
            $oldval="";
            ($n,$userfullname,$edt,
             $keylist,$vallist)=$user->getHtmlTextDrop("addcon",$oldval,
                                             vjoindisp=>'fullname',
                                             fields=>['userid','email'],
                                             vjoineditbase=>{cistatusid=>'4'});


            my $wf=getModuleObject($self->Config,"base::workflow");
            my $accessurl=$ENV{SCRIPT_URI};
            $accessurl=~s/HandleShowSubscribers/Main\/$id/;
            my %notiy;
            $notiy{name}="$subjectprefix: ".$borec->{name};
            $notiy{emailto}=$email;
            $notiy{emailtext}=sprintf($self->T("The Board manager has add ".
                              "you to board \"%s\"."),$borec->{name}).
                              "\n\n".$accessurl;
                             
            $notiy{class}='base::workflow::mailsend';
            $notiy{step}='base::workflow::mailsend::dataload';
            if (my $id=$wf->Store(undef,\%notiy)){
               my %d=(step=>'base::workflow::mailsend::waitforspool');
               my $r=$wf->Store($id,%d);
            }



         }
         ####################################################################
         $d.="<table width=\"100%\">";
         $d.="<tr>";
         $d.="<td>$edt</td>"; 
         $d.="<td width=1%><input type=submit value=\"".
             $self->T("add")."\"></td>"; 
         $d.="</tr>";
         $d.="</table>";
      }
      $ia->SetFilter({refid=>\$id,
                      mode=>\'foaddtopic',
                      active=>\'1',
                      parentobj=>\'faq::forumboard'});
      my @l=$ia->getHashList(qw(user userid));
      $d.="<div style=\"padding:5px;\">".
          "<div style=\"margin-bottom:2px\">".
          "<b><u>".$self->T("current active subscribers").":</u></b></div>";
      foreach my $rec (sort({$a->{user} cmp $b->{user}} @l)){
         if ($ismoderator){
            $d.="<table cellspacing=0 cellpadding=0>".
                "<tr><td valign=center width=1%>".
                "<img onclick=removeUser($rec->{userid}) ".
                "style=\"cursor:pointer;cursor:hand\" ".
                "src=\"../../base/load/minidelete.gif\"></td>".
                "<td valign=center>".$rec->{user}."</td></tr></table>";
         }
         else{
            $d.=$rec->{user}."<br>";
         }
      }
      $d.="</div>";
      $d.="<input type=hidden name=CurrentIdToEdit value=\"$id\">";
      $d.="<input type=hidden id=ruserid name=ruserid value=\"\">";
      print $d;
      print $self->HtmlBottom(body=>1,form=>1);
   }
   else{
      print($self->noAccess());
   }
}

sub getShowBoardDetailFunctions
{
   my $self=shift;
   my $rootpath=shift;
   my $mode=shift;
   my $id=shift;
   my $d="";
   my $label=$self->T("subscribers");


   my $oldsearch=Query->Param("search");
   my $qoldsearch=quoteHtml($oldsearch);
   $d.="<div>".
       $self->T("Search").": ".
       "<input type=text name=search ".
       "onchange=\"document.forms[0].elements['UseLimitStart'].value='0';\" ".
       "value=\"".$qoldsearch."\">".
       " &bull; ";

   $d.=<<EOF;
<a href=\"javascript:DetailHandleShowSubscribers()\" class=detailfunctions>$label</a> &bull; 
<script language="JavaScript">
function DetailHandleShowSubscribers()
{
   showPopWin('${rootpath}HandleShowSubscribers?CurrentIdToEdit=$id,$mode',450,250,
              null);
}
</script>
EOF

   $d.=<<EOF;
<a href=\"javascript:DetailHandleInfoAboSubscribe()\" class=detailfunctions>InfoAbo</a>
<script language="JavaScript">
function DetailHandleInfoAboSubscribe()
{
   showPopWin('${rootpath}HandleInfoAboSubscribe?CurrentIdToEdit=$id,$mode',585,300,
              FinishHandleInfoAboSubscribe);
}
function FinishHandleInfoAboSubscribe(returnVal,isbreak)
{
   if (!isbreak){
      document.location.href=document.location.href;
   }
}
</script>

<script language="JavaScript">
function DetailHandleDirectInfoAboSubscribe()
{
   alert("subscribe");
   document.forms[0].submit();
}
function DetailHandleDirectInfoAboUnSubscribe()
{
   alert("unsubscribe");
   document.forms[0].submit();
}
</script>
   </div>
EOF
   return($d);
   # todo = direct subscript on one click
   if (1){
      $d.=" &bull; ".
          "<a href=\"javascript:DetailHandleDirectInfoAboSubscribe()\" ".
          "class=detailfunctions>".
          $self->T("Subscribe new messages")."</a>";
   }
   else{
      $d.=" &bull; ".
          "<a href=\"javascript:DetailHandleDirectInfoAboUnSubscribe()\" ".
          "class=detailfunctions>".
          $self->T("unSubscribe all new messages")."</a>";
   }


   return($d);
}

sub ShowBoard
{
   my $self=shift;
   my $rootpath=shift;
   my $id=shift;

   my $bo=$self->getPersistentModuleObject("faq::forumboard");
   $bo->SetFilter({id=>\$id});
   my ($borec,$msg)=$bo->getOnlyFirst(qw(ALL));


   print $self->getAppTitleBar(prefix=>$rootpath,
                               title=>'Forum: '.
                                      "<a class=toplink ".
                                      "href=\"../Main\">Boards</a> &bull;".
                                      "<a class=toplink ".
                                      "href=\"./$id\">$borec->{name}</a>");
   my $to=$self->getPersistentModuleObject("faq::forumtopic");


   # calculate search filter
   my $s=Query->Param("search");
   my @fl;
   my %flt=(forumboard=>\$id);
   if ($s ne ""){
      if (!($s=~m/[\*\?\s]/)){
         $s="*$s*";
      }
      $flt{name}=$s;
      my $fe=$self->getPersistentModuleObject("faq::forumentry");
      $fe->SetFilter({comments=>$s});
      my @forumtopic=$fe->getVal("forumtopic");
      if ($#forumtopic!=-1){
         push(@fl,{forumboard=>\$id,id=>\@forumtopic});
      }
   }
   push(@fl,\%flt);


   # calculate pagelimit
   my $pagelimit=10;
   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{pagelimit}) && $UserCache->{pagelimit} ne ""){
      $pagelimit=$UserCache->{pagelimit};
   }

   my $uselimitstart=int(Query->Param("UseLimitStart"));
   $uselimitstart=0 if ($uselimitstart eq "");
   print("<input type=hidden name=UseLimitStart value=\"$uselimitstart\">");

   my $uselimit=Query->Param("UseLimit");
   $uselimit=$pagelimit if ($uselimit eq "");
   print("<input type=hidden name=UseLimit value=\"$uselimit\">");

   $to->SetFilter(\@fl);
   $to->SetCurrentOrder(qw(cdate));
   my $boardheader=$borec->{boardheader};
   my $class="class=boardgroup valign=top";

   print("<br><center>".
         "<div id=mainarea style=\"overflow:auto\">".
         "<table $self->{maintabparam}>");
   if ($boardheader ne ""){
      printf("<tr><td colspan=6 align=left valign=top>".
             "<iframe src=\"${rootpath}../forumboard/BoardHeader?id=%s\" ".
             "width=\"100%\" height=\"80\"></iframe>".
             "</td></tr>",$borec->{id});
   }
   printf("<tr><td colspan=6 align=right valign=top>%s</td></tr>",
          $self->getShowBoardDetailFunctions($rootpath,"board",$id));
   print("<tr><th $class>&nbsp;</th><th $class>".
         $self->T("Topic","faq::forumtopic")."</th><th $class>".
         $self->T("Creator surname","faq::forumtopic")."</th>".
         "<th $class style=\"width:1%;text-align=center\">".
         $self->T("Answers","faq::forumtopic")."</th>".
         "<th $class style=\"width:1%;text-align=center\">".
         $self->T("Views","faq::forumtopic")."</th>".
         "<th $class>".
         $self->T("last answer")."</th></tr>");
   print("<tr class=boardspacer><td colspan=6></td></tr>");
   my $l=1;
   my $line=0;

   $to->SetCurrentView(qw(lastentrymdate cdate name creatorshort 
                                        entrycount viewcount lastworkershort
                                        forcetopicicon
                                        topicicon));
   $to->Limit($uselimit,$uselimitstart,1) if ($uselimit>0);
   my ($rec,$msg)=$to->getFirst();
   if (defined($rec)){
      do{
         print("<tr class=l$l>");
         my $iconobj=$to->getField("topicicon");
         my $icon=$iconobj->FormatedDetail($rec,"HtmlDetail");
         $icon=~s/..\/faq\/load/$rootpath\/..\/load/;
         print("<td width=15 align=center>$icon</td>");
         my $name=$rec->{name};
         $name=~s/</&lt;/g;
         $name=~s/>/&gt;/g;
         $name="<b>$name</b>" if ($rec->{entrycount}==0);
         $name="<font color=darkred>$name</font>" if ($rec->{forcetopicicon}==2);
         print("<td width=200><a class=listlink href=\"../Topic/$rec->{id}\">".
               "$name</a></td>");
         print("<td width=1% style=\"padding-left:2px;padding-right:2px\">".
               "$rec->{creatorshort}</td>");
         print("<td align=center>$rec->{entrycount}</td>");
         print("<td align=center>$rec->{viewcount}</td>");
         print("<td width=120>$rec->{lastworkershort}</td>");
         print("</tr>");
         $l++;
         $line++;
         $l=1 if ($l>2);
         ($rec,$msg)=$to->getNext();
      }until(!defined($rec));
   }
   my $limitreached=$msg eq "Limit reached" ? 1 : 0;
   my $rows=$to->Rows();
   my $pagecontrol=$to->getHtmlPagingLine("FORM",$uselimit,
                               $line,$rows,$limitreached,$uselimitstart);
   my $disnew="disabled";


   my @acl=$bo->getCurrentAclModes($ENV{REMOTE_USER},$borec->{acls});
   if ($self->IsMemberOf("admin") ||
       grep(/^write$/,@acl) ||
       grep(/^moderate$/,@acl)){
      $disnew="";
   }
   my $HTTP_REFERER=$ENV{SCRIPT_URI};
   my $q=kernel::cgi::Hash2QueryString({HTTP_REFERER=>$ENV{SCRIPT_URI},
                                        board=>$id});
   my $newtopic=$self->T("new topic");
   print(<<EOF);
</table>
$pagecontrol

</div>
<table $self->{maintabparam}>
<tr><td colspan=6 class=boardgroup>&nbsp;</td></tr>
<tr><td colspan=6 align=right>
<input type=button onClick="openNew();" $disnew value=" $newtopic "></td></tr>
</table></center>

<script language="JavaScript">
function openNew()
{
   document.location.href="../NewTopic?$q";
}
function modMainTab()
{
   var d=document.getElementById("mainarea");
   d.style.height="1px";
   var h=getViewportHeight();
   h=h-100;

   d.style.height=h+"px";
}
addEvent(window,"load",modMainTab);
</script>
EOF
   
}

sub ShowBoards
{
   my $self=shift;
   my $rootpath=shift;

   my $bo=$self->getPersistentModuleObject("faq::forumboardnativ");
   my $boacl=$self->getPersistentModuleObject("faq::forumboardacl");
   print $self->getAppTitleBar(prefix=>$rootpath,
                               title=>'Forum:'.
                                    ' <a class=toplink href="Main">Boards</a>');
   print "<br>";  
   my $grp; 
   my $class="class=boardgroup";
   print("<center><table $self->{maintabparam}>");

   print("<tr><td colspan=5 align=right>&nbsp;</td></tr>");
   my $t=$self->T("moderator");
   print("<tr><th $class>Board</th><th $class style=\"text-align:center\">".
         $self->T("topics")."</th><th $class style=\"text-align:center\">".
         $self->T("entrys")."</th><th $class>".
         $self->T("last posting by")."</th><th $class>${t}</th></tr>");
   my $l=1;
   $bo->SecureSetFilter();
   foreach my $rec ($bo->getHashList(qw(boardgroup name id 
                                        topiccount entrycount comments
                                        lastworkershort))){
      if ($grp ne $rec->{boardgroup}){
         print("<tr class=boardspacer><td colspan=5></td></tr>");
         if ($rec->{boardgroup} ne ""){
            print("<tr><td colspan=5 class=boardgroup>".
                  "&bull; ".$rec->{boardgroup}."</td></tr>");
         }
         $grp=$rec->{boardgroup};
         $l=1;
      }
      my $comments=$rec->{comments};
      if (!($comments=~m/^\s*$/)){
         $comments="<br><div class=boardcomments>".$comments."</div>";
      }
      $boacl->ResetFilter();
      $boacl->SetFilter({aclparentobj=>\'faq::forumboard',
                         refid=>\$rec->{id},aclmode=>\'moderate'});
      my @mod=$boacl->getHashList(qw(acltargetname));
      my $admin="admin";
      if ($#mod!=-1){
         $admin=join(", ",map({my $n=$_->{acltargetname};
                               if ($n=~m/\(.*\@.*\)$/){
                                  $n=~s/,\s.*$//;
                               }
                               $n;} @mod));
      }
      print("<tr class=l$l>".
            "<td valign=top><a class=listlink href=\"Main/$rec->{id}\">".
            "$rec->{name}</a>$comments</td>");
      print("<td width=20 align=center valign=top>$rec->{topiccount}</td>");
      print("<td width=20 align=center valign=top>$rec->{entrycount}</td>");
      print("<td width=120 valign=top>$rec->{lastworkershort}</td>");
      print("<td width=120 valign=top>$admin</td>");
      print("</tr>");
      $l++;
      $l=1 if ($l>2);
   }
   print("</table></center>");
}



1;
