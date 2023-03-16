package passx::mgr;
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
use kernel::App::Web::Listedit;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::MenuTree;
use kernel::TabSelector;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::TabSelector);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'passxpassword.passwordid'),
                                                  
      new kernel::Field::Link(
                name          =>'userid',
                sqlorder      =>'desc',
                label         =>'UserID',
                dataobjattr   =>'passxpassword.userid'),
                                                  
      new kernel::Field::Link(
                name          =>'entryid',
                sqlorder      =>'desc',
                label         =>'DistibutionID',
                dataobjattr   =>'passxpassword.entryid'),

      new kernel::Field::TextDrop(
                name          =>'user',
                label         =>'User',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'systemname',
                label         =>'Systemname',
                readonly      =>1,
                vjointo       =>'passx::entry',
                vjoinon       =>['entryid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'account',
                label         =>'Account',
                readonly      =>1,
                vjointo       =>'passx::entry',
                vjoinon       =>['entryid'=>'id'],
                vjoindisp     =>'account'),

      new kernel::Field::Textarea(
                name          =>'cryptdata',
                label         =>'CryptData',
                dataobjattr   =>'passxpassword.cryptdata'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'passxpassword.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'passxpassword.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'passxpassword.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'passxpassword.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'passxpassword.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'passxpassword.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'passxpassword.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'passxpassword.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'passxpassword.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'passxpassword.realeditor'),
   

   );
   $self->setDefaultView(qw(systemname account mdate user));
   return($self);
}

sub Initialize
{
   my $self=shift;

   $self->setWorktable("passxpassword");
   return($self->SUPER::Initialize());
}

sub InitRequest
{
   my $self=shift;
   my $bk=$self->SUPER::InitRequest(@_);

   if ($ENV{REMOTE_USER} eq "" || $ENV{REMOTE_USER} eq "anonymous"){
      print($self->noAccess());
      return(undef);
   }
   return($bk);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   return("ALL") if ($userid==$rec->{userid});
  
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub getValidWebFunctions
{
   my $self=shift;
   return("UserFrontend",
          "Workspace","CryptoOut","KeyStore","helptmpl",
          "Connector",
          $self->SUPER::getValidWebFunctions());
}

sub GetDestPublicKeys
{
   my $self=shift;
   my $erec=shift;
   my %destu=($erec->{ownerid}=>1);
   my $pk=$self->getPersistentModuleObject("passx::key");
   if (ref($erec->{acls}) eq "ARRAY"){
      foreach my $arec (@{$erec->{acls}}){
         if ($arec->{acltarget} eq "base::grp"){
            map({$destu{$_}=$_} $self->getMembersOf($arec->{acltargetid},
                                                    "RMember","direct"));
         } 
         if ($arec->{acltarget} eq "base::user"){
            $destu{$arec->{acltargetid}}=$arec->{acltargetid};
         } 
      }
   }
   $pk->ResetFilter();
   $pk->SetFilter({userid=>[keys(%destu)]});
   my @dest=$pk->getHashList(qw(n e userid user)); 
}

sub StoreCryptData
{
   my $self=shift;
   my $id=shift;
   my $cryptdata=shift;
   my $dest=shift;

   my %name=();
   map({$name{$_->{userid}}=$_->{user}} @$dest);
   my $comments="";
   $comments.="Crypted for users:\n";
   foreach my $l (split(/\n/,$cryptdata)){
      my ($uid,$d)=$l=~m/^\s*(\d+)\s*,\s*(\S+)\s*$/;
      my $rec={userid=>$uid,entryid=>$id,cryptdata=>$d};
      my @passwordid=$self->ValidatedInsertOrUpdateRecord($rec,
                                    {userid=>\$uid,entryid=>\$id});
      $comments.="$name{$uid}\n";
   }
   if ($ENV{REMOTE_USER} eq "anonymous"){
      $comments.="\n\nchanged from ".getClientAddrIdString();
   }
   $self->SetFilter({entryid=>\$id});
   $self->ForeachFilteredRecord(sub{
                $self->ValidatedUpdateRecord($_,
                        {comments=>$comments},{id=>\$_->{id}});
             });
}

sub CryptoOut
{
   my $self=shift;
   my $id=Query->Param("id");
   my $userid=$self->getCurrentUserId();
   my $pk=$self->getPersistentModuleObject("passx::key");
   my $ent=$self->getPersistentModuleObject("passx::entry");
   $pk->SetFilter({userid=>\$userid});
   my $cryptdata=Query->Param("cryptdata");
   my $passxlog=$self->getPersistentModuleObject("passx::log");


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css',
                                   'public/passx/load/passx.css'],
                           js=>[qw( crypto_dessrc.js 
                                    crypto_desextra.js 
                                    crypto_jsbn.js     
                                    crypto_jsbn2.js     
                                    crypto_prng4.js     
                                    crypto_rng.js     
                                    crypto_rsa.js     
                                    crypto_rsa2.js
                                    PasswordGenerator.js
                                    passx.js
                                    toolbox.js )],
                           body=>1,form=>1);
   my $userid=$self->getCurrentUserId();
   my $pk=$self->getPersistentModuleObject("passx::key");
   $pk->SetFilter({userid=>\$userid});
   my ($krec,$msg)=$pk->getOnlyFirst(qw(ALL));
   my $canunencrypt="true";
   if ($id ne ""){
      $ent->SetFilter({id=>\$id});
      my ($erec,$msg)=$ent->getOnlyFirst(qw(ALL));
      if (defined($erec)){
         my $saveok=0;
         if (grep(/^default$/,$ent->isWriteValid($erec))){
            $saveok=1;
         }
         my @dest=$self->GetDestPublicKeys($erec);
         my $destu=join(",",map({"'".$_->{userid}."'"} @dest));
         my $destn=join(",",map({"'".$_->{n}."'"} @dest));
         my $deste=join(",",map({"'".$_->{e}."'"} @dest));
         $destn=~s/\s//gm;

         # 
         #  Process write operaion
         # 
         #printf STDERR ("%s\n",Dumper(scalar(Query->MultiVars())));

         if ($cryptdata ne "" && $id ne ""){
            if ($saveok){
               $self->StoreCryptData($id,$cryptdata,\@dest);
            }
            else{
               $self->LastMsg(ERROR,"no write access for ".
                                    "$erec->{name}:$erec->{account}");
            }
         }
         # ################################################################


         $self->ResetFilter();
         $self->SetFilter({userid=>\$userid,entryid=>\$id});
         my ($rec,$msg)=$self->getOnlyFirst(qw(realeditor cryptdata 
                                               mdate comments ));
         my $LastUpdate=$self->T("Last Update");
         $passxlog->ValidatedInsertRecord({name=>'password of '.
                                                 $erec->{account}.'@'.
                                                 $erec->{name}.' read',
                                           entryid=>$id});
         print("<div class=passxinfo>");
         print("<table width=\"100%\" border=0>");
         my $fld=$ent->getField("shortedcomments");
         my $comments=$fld->RawValue($erec);
         $comments=" ($comments)" if (!($comments=~m/^\s*$/));
         print("<tr><td nowrap width=1% valign=top>Systemname:</td>".
               "<td>$erec->{name}$comments</td></tr>");
         my $detailx=$ent->DetailX();
         my $detaily=$ent->DetailY();
         print("<tr><td nowrap valign=top>Account:</td><td>".
               "<a class=entrylink ".
               "href=JavaScript:openwin(\"../entry/Detail?id=$id\",".
               "\"_blank\",\"height=$detaily,width=$detailx,toolbar=no,".
               "status=no,"."resizable=yes,scrollbars=auto\")>".
               "$erec->{account}</a></td></tr>");
         my $df=new kernel::Field::Date();
         $df->setParent($self);
         my ($fdate)=$df->getFrontendTimeString("HtmlDetail", $rec->{mdate});
         my $u=$rec->{realeditor}; 
         $u=" ; $u" if ($u ne "");
         print("<tr><td nowrap>$LastUpdate:</td><td>$fdate$u</td></tr>");
         print("</table>");
         print("</div>");
         my $cryptdata="<center>- No crypted informations stored -</center>";
         if (defined($rec)){
            $cryptdata=join("<br>",grep(!/^\s*$/,
                            split(/(.{0,55})/,$rec->{cryptdata})));
            $canunencrypt="false";
         }
         print("<div id=cryptdata class=cryptdata>$cryptdata</div>");
         printf("<input type=hidden name=cryptdata value=\"%s\">",
                $rec->{cryptdata});
         print("<div class=passxaction>");
         my $NewPass=$self->T("generate a new password");
         my $UnEncrypt=$self->T("unencrypt");
         my $Save=$self->T("save");
         #print("<input disabled type=button class=passxaction name=unencrypt ".
         #      "style=\"width:20%\" ".
         #      "value=\" $UnEncrypt \" onClick=\"rsaunecrypt()\">");
         print("<input disabled type=button class=passxaction name=genpass ".
               "style=\"width:50%\" ".
               "value=\" $NewPass \" onClick=\"do_GeneratePassword()\">");
         print("<input type=button disabled ".
               "style=\"width:20%\" ".
               "onClick=\"do_save();\" class=passxaction ".
               "name=save value=\" $Save \">");
         print("</div>");
         print("<div class=unencryptdata>");
         print("<input type=text name=unencryptdata ".
               "class=unencryptdata value=\"\">");
         print("</div>");
         my $lastmsg=join("\n",$self->LastMsg());
         $lastmsg="<font color=red>$lastmsg</font>";
         printf("<div class=distinfo><pre>%s%s</pre></div>",
                $lastmsg,$rec->{shortedcomments});
         printf("<input type=hidden name=userid value=\"$userid\">");
         foreach my $v (qw(p q n e dmp1 dmq1 verify coeff d)){
            my $mode="disabled";
            my $rawval=$krec->{$v};
            if ($v eq "n" || $v eq "e"){
               $mode="";
            }
            printf("<input $mode type=hidden value=\"%s\" name=\"%s\">\n",
                   $rawval,$v);
            printf("<input disabled type=hidden value=\"\" ".
                   "name=\"plain_%s\">\n",$v);
         }
         printf("<input type=hidden name=id value=\"$id\">");
         my $nopassword=$self->T("No password specified - continue?");
         print(<<EOF);
<script language="JavaScript">
function do_GeneratePassword()
{
   parent.parent.document.forms[0].activity.value=getClockTime();
   document.forms[0].unencryptdata.value=
          getPassword(8,"",true,true,false,false,true,true,true,true);
}

function do_unecryptkeys(key)
{
   parent.parent.document.forms[0].activity.value=getClockTime();
   unecryptkeys(key);
   if ($saveok){
      document.forms[0].save.disabled=false;
      document.forms[0].genpass.disabled=false;
   }
   rsaunecrypt();
   
}
function rsaunecrypt()
{
  if (document.forms[0].cryptdata.value!=""){
     document.forms[0].unencryptdata.value = "*** unencrypt start ... ***";
     window.setTimeout("Background_rsaunecrypt()", 10);
  }
}

function Background_rsaunecrypt()
{
  var rsa = new RSAKey();
  var dr = document.forms[0];
  rsa.setPrivateEx(dr.n.value, dr.e.value, dr.plain_d.value, dr.plain_p.value, 
                   dr.plain_q.value, dr.plain_dmp1.value, dr.plain_dmq1.value, 
                   dr.plain_coeff.value);
  var res = rsa.decrypt(document.forms[0].cryptdata.value);
  if(res == null) {
    document.forms[0].unencryptdata.value = "*** Invalid Ciphertext ***";
  }
  else {
    document.forms[0].unencryptdata.value = res;
  }
}

function do_save()
{
   var enc="";
   var destu=new Array($destu);
   var deste=new Array($deste);
   var destn=new Array($destn);
   if (document.forms[0].unencryptdata.value==""){
      if (!confirm("$nopassword")){
         return;
      }
   }
   for(c=0;c<destu.length;c++){
      var rsa = new RSAKey();
      rsa.setPublic(destn[c], deste[c]);
      var res = rsa.encrypt(document.forms[0].unencryptdata.value);
      if(res && res!="") {
         enc=enc+destu[c]+","+res+"\\n";
      }
      else{
         return;
      }
   }
   document.forms[0].unencryptdata.value="";
   document.forms[0].cryptdata.value=enc;
   document.forms[0].submit();
}
window.setTimeout("do_unecryptkeys(parent.parent.document.forms[0].rsaphrase.value);", 500);
parent.parent.document.forms[0].activity.value=getClockTime();

</script>
EOF
      }
   }
   print $self->HtmlBottom(body=>1,form=>1);
}
sub Workspace
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   my $pk=$self->getPersistentModuleObject("passx::key");
   $pk->SetFilter({userid=>\$userid});
   my ($pkrec,$msg)=$pk->getOnlyFirst(qw(ALL));

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css'],
                           js=>[qw( crypto_dessrc.js 
                                    crypto_desextra.js 
                                    crypto_jsbn.js     
                                    crypto_jsbn2.js     
                                    crypto_prng4.js     
                                    crypto_rng.js     
                                    crypto_rsa.js     
                                    crypto_rsa2.js
                                    asn1.js    
                                    passx.js )],
                           body=>1,form=>1);
   print $self->HtmlSubModalDiv();
print<<EOF;
<style>
html,body{
   overflow:hidden;
}
</style>
EOF
   print "<script language=\"JavaScript\" src=\"../../base/load/toolbox.js\">";
   print "</script>\n";
   print "<script language=\"JavaScript\" src=\"../../base/load/subModal.js\">";
   print "</script>\n";

   print("<script language=\"JavaScript\">");
   print("function setEditMode(m)");
   print("{");
   print("   this.SubFrameEditMode=m;");
   print("}");
   print("function TabChangeCheck()");
   print("{");
   print("if (this.SubFrameEditMode==1){return(DataLoseWarn());}");
   print("return(true);");
   print("}");
   print("</script>");

   my $p=Query->Param("ModeSelectCurrentMode");
   $p="pstore" if (!defined($p));
   my $pages=[pstore=>'Password Store',
              keymgmt=>'Key Management',
              keydist=>'Distribution Management',
              connector=>'Connector',
              help=>'Help'];
   if (!defined($pkrec)){
      $p="keymgmt" if ($p eq "pstore" || $p eq "");
      $pages=[keymgmt=>'Key Management',help=>'Help'];
   }
   my $page="none";
   $page=$self->pstore()    if ($p eq "pstore");
   $page=$self->keymgmt()   if ($p eq "keymgmt");
   $page=$self->keydist()   if ($p eq "keydist");
   $page=$self->connector() if ($p eq "connector");
   $page=$self->help()      if ($p eq "help");


   my $directopenid=Query->Param("directopenid");
   if ($directopenid eq ""){
      my @WfFunctions=();
      my %param=(functions   =>\@WfFunctions,
                 pages       =>$pages,
                 activpage  =>$p,
                 tabwidth    =>"18%",
                 page        =>$page,
                );
      print TabSelectorTool("ModeSelect",%param);
   }
   else{
      print("<div id=TabSelectorModeSelect>".$self->directOpen()."</div>");
   }
   print(<<EOF);
<style>
#TabSelectorModeSelect{
   visibility:hidden;
}
</style>
<div id=RunInfo style="position:absolute;left:50px;top:50px;
                       border-style:outset;
                       padding:10px;
                       visibility:hidden;
                       width:380px;height:100px">
<img style="float:right" src="../../../public/passx/load/schloss.gif">
Bitte geben Sie Ihr persönliches Passwort<br>(min. 5 Zeichen) ein.<br>
Falls Sie PassX das erste mal starten, so wählen Sie bitte
ihr persönliches Passwort, dass Sie zukünftig verwenden möchten.
</div>
<script language="JavaScript">
function CheckPasswordState()
{
   var work=document.getElementById("TabSelectorModeSelect");
   var info=document.getElementById("RunInfo");
   //console.log("fifi re=",parent.returnpressed);
   //console.log("fifi pass=",parent.document.forms[0].rsaphrase.value);
   if (parent.document.forms[0].rsaphrase.value.length<5 ||
       parent.returnpressed==false){
      work.style.visibility="hidden";
      info.style.visibility="visible";
   }
   else{
      work.style.visibility="visible";
      info.style.visibility="hidden";
      var e=parent.document.getElementById("manEnterBtn");
      if (e){
         e.style.display="none";
      }
      if ("$directopenid"!=""){
         var newurl="CryptoOut?id=$directopenid";
         var oldurl=window.frames['CryptoOut'].document.location.href;
         var oldsub=oldurl.substring(oldurl.length-newurl.length);
         if (oldsub!=newurl){
            window.frames['CryptoOut'].document.location.href=newurl;
         }
      }
   }
   window.setTimeout("CheckPasswordState();", 1000);
}
CheckPasswordState();
var oldact="*";
function CheckActivityState()
{
   var a=parent.document.getElementById("activity");
   var curact=a.value;
   if (curact==oldact){
      parent.document.forms[0].rsaphrase.value="";
      parent.returnpressed=false;
      if (window.frames['CryptoOut']){
         window.frames['CryptoOut'].document.location.href="CryptoOut";
      }
   }
   a.value=getClockTime();
   curact=a.value;
   oldact=curact;
   window.setTimeout("CheckActivityState();",600000);
}
CheckActivityState();


</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);

}

sub help
{
   my $self=shift;

   my $d=<<EOF;
<iframe frameborder=0 style="border-style:none;padding:0px;
                            margin:0px;width:100%;height:100%" 
                            src="helptmpl">
</iframe>
EOF
}

sub connector
{
   my $self=shift;

   my $d=<<EOF;
<iframe frameborder=0 style="border-style:none;padding:0px;
                            margin:0px;width:100%;height:100%" 
                            src="Connector">
</iframe>
EOF
}

sub Connector
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css'],
                           title=>'PassX Connector',
                           js=>[qw( toolbox.js ContextMenu.js)],
                           body=>1,form=>1);
   my $flt=Query->Param("filter");
   my $curpath=Query->Param("curpath");
   my $search=$self->T("search");

   my $d=<<EOF;
<div id="context_menu" class="context_menu"></div>
<input type=hidden name=curpath>
<link rel=stylesheet type="text/css" href="../../../public/passx/load/passx.css"></link>
<link rel=stylesheet type="text/css" href="../../../public/base/load/menu.css"></link>
<script language="JavaScript">
function setCurPath(p)
{
   e=document.forms[0].elements['curpath'];
   if (e){
      e.value=p;
      document.forms[0].submit();
   }

}
function resizeDiv()
{
   var h=getViewportHeight();
   var sl=document.getElementById("sl");
   sl.style.height=h-60;
}
addEvent(window,"load",resizeDiv);
addEvent(window,"resize",resizeDiv);

</script>
<table width="100%" border=0>
<tr>
<td width=1% nowrap>&nbsp;<b>PassX Connector: &nbsp;</b></td><td><input type=text name=filter value="$flt" size=10 style="width:100%"></td><td width="100"><input type=submit name=go value="$search" style="width:100%"></td></tr></table>
<div id=sl style="width:100%;height:3px;overflow:auto;border-width:1px;border-style:solid">
EOF
   my $userid=$self->getCurrentUserId();
   my $ent=$self->getPersistentModuleObject("passx::entry");
   $d.=$ent->generateMenuTree("connector",$userid,$flt,$curpath);
   $d.=<<EOF;
</div>
<center>&bull; <a class=sublink href=javascript:openwin("Connector","_blank","height=300,width=450,toolbar=no,status=no,resizable=yes,scrollbars=auto")>new window</a> &bull;</center>
</table>
EOF
   print $d;
   print $self->HtmlBottom(body=>1,form=>1);
}

sub helptmpl
{
   my $self=shift;
   print $self->HttpHeader("text/html");

   print $self->getParsedTemplate("tmpl/help.html",{});
}

sub keydist
{
   my $self=shift;

   my $d=<<EOF;
<iframe frameborder=0 style="border-style:none;padding:0px;
                            margin:10px;width:97%;height:95%" 
                            src="../entry/NativMain">
</iframe>
EOF
}


sub pstore
{
   my $self=shift;
   my $PasswordFolders=$self->T("Password folders");
   my $flt=Query->Param("filter");
   my $curpath=Query->Param("curpath");
   my $search=$self->T("search");

   my $d=<<EOF;
<input type=hidden name=curpath>
<link rel=stylesheet type="text/css" href="../../../public/passx/load/passx.css"></link>
<link rel=stylesheet type="text/css" href="../../../public/base/load/menu.css"></link>
<table width="100%" height="100%" 
       cellspacing=0 cellpadding=5 border=0 style="table-layout:fixed">
<tr>
<td width=30% valign=bottom>
<table width="100%" border=0>
<tr>
<td><b>$PasswordFolders:</b></td><td><input type=text name=filter value="$flt" size=10></td><td><input type=submit name=go value="$search"></td></tr></table>
<div id=sl style="width:100%;height:220px;overflow:auto;border-width:1px;border-style:solid">
EOF
   my $userid=$self->getCurrentUserId();
   my $ent=$self->getPersistentModuleObject("passx::entry");
   $d.=$ent->generateMenuTree("web",$userid,$flt,$curpath);

   my $detailx=$ent->DetailX();
   my $detaily=$ent->DetailY();
   my $newlabel=$self->T("Create new Distribution entry");

   my $starturl="CryptoOut";
   if (my $id=Query->Param("id")){
      $starturl.="?id=$id";
   }

   $d.=<<EOF;
</div>
</td>
<td align=center>
<div class=storewin>
<table border=0 width="100%">
<tr>
<td>
<a href=JavaScript:openwin("../entry/New","_blank","height=$detaily,width=$detailx,toolbar=no,status=no,resizable=yes,scrollbars=auto")>
<img style="float:right" border=0 title="$newlabel"
     src="../../../public/passx/load/schloss.gif"></a>
<font size=+2><b>PassX Evolution II</b></font><br>
High secure password super store<br>
<br>
<img style="float:left;padding-left:2px" src="../../../public/passx/load/rsa.gif">
<img style="float:left;padding-top:8px;padding-left:12px" src="../../../public/passx/load/ssl.gif">
</td>
</tr>
<tr>
<td>
<iframe name=CryptoOut src="$starturl" style="width:99%;height:250px"></iframe>
</td>
</tr>
</table>
</div>
</td>
</table>
<script language="JavaScript">
var h=getViewportHeight();
var sl=document.getElementById("sl");
sl.style.height=h-60;
function showCryptoOut(id)
{
   window.frames['CryptoOut'].document.location.href="CryptoOut?id="+id;
}
function setCurPath(p)
{
   e=document.forms[0].elements['curpath'];
   if (e){
      e.value=p;
      document.forms[0].submit();
   }

}

</script>
EOF
}


sub directOpen
{
   my $self=shift;
   my $PasswordFolders=$self->T("Password folders");
   my $flt=Query->Param("filter");
   my $curpath=Query->Param("curpath");
   my $search=$self->T("search");

   my $d=<<EOF;
</td>
<td align=center>
<div class=storewin>
<iframe name=CryptoOut src="CryptoOut" style="width:99%;height:280px"></iframe>
</div>
EOF
}


sub KeyStore
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css'],
                           js=>[qw( toolbox.js)],
                           body=>1,form=>1);
   print <<EOF;
<style>
body{
  margin:10px;
}
</style>

EOF
   my $pk=$self->getPersistentModuleObject("passx::key");
   Query->Delete("ModeSelectCurrentMode");
   my $write=scalar(Query->MultiVars());
   $write->{userid}=$userid;
   $pk->ValidatedInsertOrUpdateRecord($write,{userid=>\$userid});
   my $msg=$self->T("OK: keys are saved - now you can restart PassX");
   print $msg;
   print $self->HtmlBottom(body=>1,form=>1);
}

sub keymgmt
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   my $pk=$self->getPersistentModuleObject("passx::key");
   $pk->SetFilter({userid=>\$userid});
   my ($rec,$msg)=$pk->getOnlyFirst(qw(ALL));
   my $oldval=$rec->{keylen};
   $oldval="512" if (!defined($oldval) || $oldval eq "");
   my $kselect="<select name=keylen>";
   foreach my $kl (qw(256 512 1024)){
      $kselect.="<option value=\"$kl\" ";
      $kselect.=" selected" if ($oldval eq $kl);
      $kselect.=">$kl Bit";
      $kselect.=" keycreate takes ca. ";
      $kselect.="2 sec" if ($kl==256);
      $kselect.="10 sec" if ($kl==512);
      $kselect.="60 sec" if ($kl==1024);
      $kselect.="</option>";
   }
   $kselect.="</select>";
   my $geninfo=$self->T("This process may take long time. If you get ".
                        "questions from your browser to break this process ".
                        "you should not do a break!");

   my $d=<<EOF;

<!--
RSA from http://www-cs-students.stanford.edu/~tjw/jsbn/rsa2.html
DES from http://www.tero.co.uk/des/test.php
-->
<style>
textarea.keyinput{
   height:35px;
}
</style>
<br>
<table width=80% border=1>

   <tr>
    <td>
     Modulus:
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_n" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=n value="$rec->{n}">
    </td>
   </tr>

   <tr>
    <td nowrap>
     Key Lenght:
    </td>
    <td>$kselect</td>
   </tr>

   <tr>
    <td nowrap>
     Public exponent:
    </td>
    <td>
     <input disabled type=text name="plain_e" value="">
     <input type=hidden name=e value="$rec->{e}">
    </td>
   </tr>

   <tr>
    <td nowrap>
     Private exponent(hex):
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_d" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=d value="$rec->{d}">
    </td>
   </tr>

   <tr>
    <td>
     P (hex):
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_p" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=p value="$rec->{p}">
    </td>
   </tr>

   <tr>
    <td>
     Q (hex):
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_q" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=q value="$rec->{q}">
    </td>
   </tr>

   <tr>
    <td>
     D mod (P-1) (hex):
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_dmp1" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=dmp1 value="$rec->{dmp1}">
    </td>
   </tr>

   <tr>
    <td>
     D mod (Q-1) (hex):
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_dmq1" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=dmq1 value="$rec->{dmq1}">
    </td>
   </tr>

   <tr>
    <td>
     1/Q mod P (hex):
    </td>
    <td>
     <textarea disabled class=keyinput name="plain_coeff" type="text" rows=2 cols=70></textarea>
     <input type=hidden name=coeff value="$rec->{coeff}">
    </td>
   </tr>

</table>
<input disabled type=hidden name=plain_verify value="KeyIsOK">
<input type=hidden name=verify value="$rec->{verify}">
<input type=button id=genrsa value="Generate" onClick="do_genrsa()">
<input type=button disabled name=do_store value="Store" onClick="do_save()">
<br>
<iframe style="width:90%;height:40px" src="Welcome" name=KeyStore id=KeyStore></iframe>
<script language="JavaScript">
function check_do_store()
{
  if (parent.document.forms[0].rsaphrase.value!='' &&
      document.forms[0].plain_n.value!=''){
     document.forms[0].do_store.disabled=false;
  }
  window.setTimeout("check_do_store();", 1000);
}
//function trim(s) {
//  while (s.substring(0,1) == ' ') {
//    s = s.substring(1,s.length);
//  }
//  while (s.substring(s.length-1,s.length) == ' ') {
//    s = s.substring(0,s.length-1);
//  }
//  return s;
//}

window.setTimeout("ProcessKeyUnencrypt()", 1000);
document.getElementsByTagName('body')[0].style.cursor='wait';
function ProcessKeyUnencrypt()
{
   if (document.forms[0].verify.value!=""){
      unecryptkeys(parent.document.forms[0].rsaphrase.value);
   }
   document.getElementsByTagName('body')[0].style.cursor='default';
   document.getElementById('genrsa').disabled=false;
}
check_do_store();
window.genrsa=false;
function GenRSA(){
   var rsa = new RSAKey();
   var dr = document.forms[0];
   dr.plain_e.value="10001";
   var keylen=parseInt(dr.keylen.value);
   rsa.generate(keylen,dr.plain_e.value);
   dr.plain_n.value = linebrk(rsa.n.toString(16),64);
   dr.plain_d.value = linebrk(rsa.d.toString(16),64);
   dr.plain_p.value = linebrk(rsa.p.toString(16),64);
   dr.plain_q.value = linebrk(rsa.q.toString(16),64);
   dr.plain_dmp1.value = linebrk(rsa.dmp1.toString(16),64);
   dr.plain_dmq1.value = linebrk(rsa.dmq1.toString(16),64);
   dr.plain_coeff.value = linebrk(rsa.coeff.toString(16),64);
   check_do_store();
   document.getElementsByTagName('body')[0].style.cursor='default';
   document.getElementById('genrsa').disabled=false;
}
function do_genrsa() {
   alert("$geninfo");
   document.getElementById('genrsa').disabled=true;
   document.getElementsByTagName('body')[0].style.cursor='wait';
   window.setTimeout("GenRSA()", 1000);
}
function do_save()
{
  var f=document.forms[0];
  var oldaction=f.action;
  var oldtarget=f.target;
  f.action="KeyStore";
  f.target="KeyStore";

  var key=parent.document.forms[0].rsaphrase.value;

  var l=new Array('p','q','d','dmp1','dmq1','coeff','verify');
  for(c=0;c<l.length;c++){
     var plain=f.elements['plain_'+l[c]].value;
     var cdata=stringToHex(des(key, plain, 1, 0,false));
     f.elements[l[c]].value=cdata;
  }
  var l=new Array('n','e');
  for(c=0;c<l.length;c++){
     var plain=f.elements['plain_'+l[c]].value;
     f.elements[l[c]].value=plain;
  }
  
  f.submit();
  f.action=oldaction;
  f.target=oldtarget;
}
</script>
EOF
}

sub UserFrontend
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   my $directopenid=Query->Param("id");
   my $pk=$self->getPersistentModuleObject("passx::key");
   $pk->SetFilter({userid=>\$userid});

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','public/passx/load/passx.css'],
                           form=>1,body=>1,
                           title=>$self->T($self->Self()));
   my $PersonalPassword=$self->T("personal password");
   my $RestartApplication=$self->T("restart PassX");
   my $directopenparam="";
   if ($directopenid ne ""){
      $directopenparam="?directopenid=$directopenid";
   }
   print <<EOF;
<style>
html,body{
   overflow:hidden;
}
</style>
<script language="JavaScript">

window.returnpressed=false;
function keyhandler(ev)
{
   if (ev && ev.keyCode==13){
      window.returnpressed=true;
      return(false);
   }
   return(true);
}

function testForEnter() 
{    
   if (typeof(event)!="undefined"){
      if (event.keyCode == 13){        
         event.cancelBubble = true;
         event.returnValue = false;
         window.returnpressed=true;
      }
   }
} 

document.onkeypress=keyhandler;   //mozilla Variante
function inputkeyhandler()        //IE Variante
{
   if (window.event && window.event.keyCode==13){
      window.returnpressed=true;
      return(false);
   }
   return(true);
}

function manEnter()
{
   var e=document.getElementById("manEnterBtn");
   if (e){
      e.style.display="none";
   }
   window.returnpressed=true;
}

function RestartWorkspace()
{
   window.returnpressed=true;
   window.frames['CryptoWorkspace'].document.location.href="Workspace$directopenparam";
   
   if (window.frames['CryptoOut']){
      window.frames['CryptoOut'].document.location.href="CryptoOut";
   }
}
window.onload=function(){
   window.document.forms[0].rsaphrase.focus();

}
</script>
<table width="100%" height="100%" border=0>
<tr height="1%"><td width="10%" nowrap>$PersonalPassword</td><td>
<input name=rsaphrase autocomplete="off" autofill="off" onkeydown="testForEnter();" onkeypress="inputkeyhandler();" type=password><input id=manEnterBtn type=button value="&rarr;" onclick="manEnter();">
<input id=activity disabled name=activity type=hidden value="">
</td><td align=right>
<input type=button name=restart value=" $RestartApplication " onClick="RestartWorkspace()"></td></tr>
<tr>
<td colspan=3>
<iframe name=CryptoWorkspace style="width:100%;height:100%;padding:0;margin:0;border-width:0" frameborder=0 src="Workspace$directopenparam"></iframe>
</td>
</tr>
</table>

EOF

   print $self->HtmlBottom(body=>1,form=>1);

}




1;
