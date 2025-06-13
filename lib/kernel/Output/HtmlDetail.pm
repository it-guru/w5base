package kernel::Output::HtmlDetail;
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
use kernel::TemplateParsing;
use base::load;
use kernel::TabSelector;
use kernel::Field::Date;
@ISA    = qw(kernel::Formater kernel::TemplateParsing);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->HttpHeader("text/html");
   $d.=$app->HtmlHeader(style=>['default.css',
                                'work.css',
                                'Output.HtmlDetail.css',
                                'kernel.App.Web.css',
                                'Output.HtmlSubList.css',
                                'kernel.filemgmt.css'],
                        title=>'Detail loading ...',
                        body=>1,
                        onload=>'DetailInit()');
   return($d);
}

sub getViewLine
{
   my ($self,$fh,$rec,$msg,$viewlist,$curview)=@_;
   my $d="";
   return($d);
}

sub getStyle
{
   my ($self,$fh,$rec,$msg,$viewlist,$curview)=@_;
   my $app=$self->getParent->getParent();
   my $d="\n";
#   $d.=$app->getTemplate("css/default.css","base");
#   $d.=$app->getTemplate("css/kernel.App.Web.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlSubList.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlDetail.css","base");
#   $d.=$app->getTemplate("css/kernel.filemgmt.css","base");
   return($d);
}


sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $scrolly=Query->Param("ScrollY");
   $scrolly=0 if (!defined($scrolly));
   my $newstyle="";
   if ($self->getParent->{NewRecord}){
      $newstyle="overflow:auto;height:300px";
   }
   my $d="";
   $d.="<div id=HtmlDetail style=\"$newstyle\"><div style=\"padding:5px\">";
   $d.="<div class='printbacktotop'>".
       "<div class='backtotop' id=BackToTop>".
       "<a href='#index' tabindex=-1 title=\"Jumpt to top\">".
       "<img border=0 src='../../base/load/backtotop.gif' width=20 height=20>".
       "</a></div></div>";
   $d.=$self->{fieldsPageHeader};
   $d.="<form method=post target=_self enctype=\"multipart/form-data\">";
   $d.="<style>";
   $d.=$self->getStyle($fh,$rec,$msg,\@view,$view);
   $d.="</style>\n";
   $d.="<script type=\"text/javascript\" language=\"JavaScript\">\n";
   if ($scrolly!=0){
      $d.=<<EOF;
function DetailInit()  // used from asyncron sub data to restore position in
{                      // page
   setFocusOnForm();
   document.body.scrollTop=$scrolly;
   startFixBackToTop();
   return;
}
EOF
   }
   else{
      $d.=<<EOF;
function DetailInit()  // used from asyncron sub data to restore position in
{                      // page
   setFocusOnForm();
   startFixBackToTop();
   return;
}
EOF
   }
   $d.=<<EOF;

function userCountTimer(){
   window.setTimeout("userCountTimer()", 310000);
   var tnow=new Date().getTime();
   \$jsonp.send('../../base/userlogon/userCount?t='+tnow, {
       callbackName: '_JSONP',
       onSuccess: function(json){
       },
       onTimeout: function(){
          // connection to Server seems to broken
          console.log("timeout userCount - serverconnection broken");
          //window.top.close();
          //window.close();
       },
       timeout: 60
   });
}

function onNew()
{
   var t=document.getElementById("TabSelectorModeSelect");
   if (t){
      var e=document.getElementById("HtmlDetail");
      e.style.height=(t.offsetHeight-30)+"px";
   }
   window.setTimeout("userCountTimer()", 100);
}
function startFixBackToTop(){
   setTimeout(function(){
      setInterval(fixBackToTop,10);
   },1000);
}
function fixBackToTop(){
   var e=document.getElementById("BackToTop");
   if (e){
      if (document.body.scrollTop<20){
         e.style.visibility="hidden";
         e.style.display="none";
      }
      else{
         e.style.visibility="visible";
         e.style.display="block";
         h=document.body.clientHeight;
         var newtop=h+document.body.scrollTop-24;
         var offset=newtop-e.offsetTop;
         if (offset<h){
            if (offset>1 && offset<h/2){
               offset=offset/3;
               newtop=e.offsetTop+offset;
            }
         }
         else{
            newtop=e.offsetTop+offset;
         }
         e.style.top=newtop+"px";
      }
   }
}
function onResize()
{
   var t=document.getElementById("TabSelectorModeSelect");
   if (t){
      var e=document.getElementById("HtmlDetail");
      e.style.height="10px";
   }
   window.setTimeout(onNew,1);

}

function setFocusOnForm()
{
   if (document.forms && document.forms[0].elements){
      for (var i=0;i<document.forms[0].elements.length;i++){
          var e=document.forms[0].elements[i];
          if (e.id!="save"){
             e.focus();
             break;
          }
      }
   }
}
addEvent(window, "load",   onNew);
addEvent(window, "resize", onResize);
addEvent(window, "load",   add_clipIconFunc);


EOF
   $d.="</script>\n\n";
   $self->Context->{LINE}=0;
   $self->Context->{jsonchanged}=[];

   return($d);
}


sub  calcHtmlDetailViewMatrix
{
   my ($self,$rec,$vMatrix,$fieldbase,$fieldlist,$viewgroups,
       $currentfieldgroup)=@_;

   for(my $c=0;$c<=$#{$fieldlist};$c++){
      my $name=$fieldlist->[$c]->Name();
      $fieldbase->{$name}=$fieldlist->[$c];

      $vMatrix->{uivisibleof}->[$c]=
         $fieldlist->[$c]->UiVisible("HtmlDetail",current=>$rec);


      if ($fieldlist->[$c]->Type() eq "MatrixHeader"){
         $vMatrix->{uivisibleof}->[$c]=1;
      }
      if ($fieldlist->[$c]->{htmldetail} eq "NotEmpty" ||
          $fieldlist->[$c]->{htmldetail} eq "NotEmptyOrEdit"){
         if (defined($rec)){
            my $v=$fieldlist->[$c]->RawValue($rec);
            if ($v ne ""){
               if (ref($v) eq "ARRAY"){
                  if ($#{$v}==-1){
                     $vMatrix->{htmldetailof}->[$c]=0;
                  }
                  else{
                     $vMatrix->{htmldetailof}->[$c]=1;
                  }
               }
               else{
                  $vMatrix->{htmldetailof}->[$c]=1;
               }
               my $fldro=$fieldlist->[$c]->readonly();
               if ($fldro){  # readonly fields are making no sense in edit mode
                  if ($currentfieldgroup ne ""){
                     my $fldgroups=$fieldlist->[$c]->{group};
                     $fldgroups=[$fldgroups] if (ref($fldgroups) ne "ARRAY");
                     if (in_array($fldgroups,$currentfieldgroup)){
                        $vMatrix->{htmldetailof}->[$c]=0;
                     }
                  }
               }
            }
            else{
               $vMatrix->{htmldetailof}->[$c]=0;
            }
         }
         else{
            if ($fieldlist->[$c]->{htmldetail} eq "NotEmptyOrEdit" &&
                !defined($rec)){
               $vMatrix->{htmldetailof}->[$c]=1;
            }
            else{
               $vMatrix->{htmldetailof}->[$c]=0;
            }
         }
      }
      elsif ($fieldlist->[$c]->{htmldetail} eq "Admin"){
         if ($self->getParent->getParent->IsMemberOf("admin") 
             && defined($rec)){
            $vMatrix->{htmldetailof}->[$c]=1;
         }
      }
      elsif ($fieldlist->[$c]->{htmldetail} eq "AdminOrSupport" ){
         if (($self->getParent->getParent->IsMemberOf("admin") ||
              $self->getParent->getParent->IsMemberOf("support")) 
             && defined($rec)){
            $vMatrix->{htmldetailof}->[$c]=1;
         }
      }
      else{ 
         $vMatrix->{htmldetailof}->[$c]=
            $fieldlist->[$c]->htmldetail("HtmlDetail",
                                         current=>$rec,
                                         currentfieldgroup=>$currentfieldgroup
         );
      }
      next if (!($vMatrix->{uivisibleof}->[$c]));
      next if (!($vMatrix->{htmldetailof}->[$c]) &&
                $fieldlist->[$c]->{htmldetail} ne "NotEmptyOrEdit");
       
      my @fieldgrouplist=($fieldlist->[$c]->{group});
      if (ref($fieldlist->[$c]->{group}) eq "ARRAY"){
         @fieldgrouplist=@{$fieldlist->[$c]->{group}};
      }
      $vMatrix->{fieldgrouplist}->[$c]=\@fieldgrouplist;
      next if (!in_array($viewgroups,"ALL") &&
               !in_array($viewgroups,$vMatrix->{fieldgrouplist}->[$c]));
      # next code is only running, if current field is in edit mode
      if ($fieldlist->[$c]->{htmldetail} eq "NotEmptyOrEdit" &&
          defined($currentfieldgroup) &&
          in_array($currentfieldgroup,$vMatrix->{fieldgrouplist}->[$c])){
         $vMatrix->{htmldetailof}->[$c]=1;
      }
      next if (!($vMatrix->{htmldetailof}->[$c]));
              
      $fieldlist->[$c]->extendFieldHeader($self->{WindowMode},$rec,
                                          \$self->{fieldHeaders}->{$name});
      $fieldlist->[$c]->extendPageHeader($self->{WindowMode},$rec,
                                          \$self->{fieldsPageHeader});

      my $grouplabel=$fieldlist->[$c]->grouplabel($rec);
      $vMatrix->{fieldhalfwidth}->{$name}=$fieldlist->[$c]->htmlhalfwidth();
      foreach my $fieldgroup (@fieldgrouplist){
         if ((in_array($viewgroups,$fieldgroup) ||
              in_array($viewgroups,"ALL") ) && 
             (!grep(/^$fieldgroup$/,@{$vMatrix->{grouplist}}))){
            push(@{$vMatrix->{grouplist}},$fieldgroup);
            $vMatrix->{grouplabel}->{$fieldgroup}=0;
         }
         $vMatrix->{grouplabel}->{$fieldgroup}=1 if ($grouplabel);
         if ($vMatrix->{fieldhalfwidth}->{$name}){
            $vMatrix->{grouphavehalfwidth}->{$fieldgroup}++;
         }
      }
   }
}



sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $fieldbase={};
   my $editgroups=[$app->isWriteValid($rec)];
   my $currentfieldgroup=Query->Param("CurrentFieldGroupToEdit"); 
   my $currentid=Query->Param("CurrentIdToEdit"); 
   my $FilterViewGroups=Query->Param("FilterViewGroups");
   if ($self->{WindowEnviroment} eq "modal" && $FilterViewGroups eq ""){
      $FilterViewGroups="header,source";
      Query->Param("FilterViewGroups"=>$FilterViewGroups);
   }

   if (defined($rec) && exists($rec->{cistatusid}) && $rec->{cistatusid}==7){
      $editgroups=[];
   }
   $self->{fieldHeaders}={} if (!exists($self->{fieldHeaders}));
   if (!exists($self->{fieldsPageHeader})){
      $self->{fieldsPageHeader}=
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/OutputHtml.js\"></script>\n".
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/HtmlDetail.js\"></script>\n".
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/toolbox.js\"></script>\n".
           "<script language=\"JavaScript\" ".
           "src=\"../../base/load/ContextMenu.js\"></script>\n";
   }
   
   
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $editgroups=[];
   }

   if ($self->getParent->{NewRecord}){
      $currentfieldgroup="default";
   #   $currentid="[new]";
   }
   if ($currentfieldgroup eq "default" && 
       !in_array($viewgroups,["default","ALL"])){
      my @candidats=sort(grep(!/^header$/,@$viewgroups));
      $currentfieldgroup=$candidats[0];
   }
   
   my $d="";
   $currentfieldgroup=undef if ($currentfieldgroup eq "");
   my $field=$app->IdField();
   my $id;
   if (defined($field)){
      $id=$field->RawValue($rec);
   }
   if ($self->Context->{LINE}>0){
      $d.="<div style=\"height:2px;overflow:hidden;padding:0;maring:0\">".
          "&nbsp;</div>";
      $d.="<hr class=detailseperator>";
   }
   my $watermark=$app->getRecordWatermarkUrl($rec);
   if ($watermark ne ""){
      $d.=<<EOF
<script language="JavaScript">
function setBG(){
   var e=document.getElementById("HtmlDetail");
   if (e){
      e.style.backgroundPosition="top left";
      e.style.backgroundImage="url($watermark)";
      e.style.backgroundRepeat="repeat";
   }
}
addEvent(window, "load", setBG);
</script>
EOF
   }

   {
      # add translated button text for historycommented save
      my $t=$self->getParent->getParent->T("continue save with comments");
      $d.="<script language=\"JavaScript\">\n";
      $d.="document.HistoryCommentedSaveButtonText='$t';\n";
      $d.="</script>\n";
   }
   


   my $module=$app->Module();
   my $appname=$app->App();
   my @detaillist=$app->getSkinFile("$module/tmpl/$appname.detail.*");
   if ($#detaillist==-1){
      @detaillist=$app->getSkinFile("$module/tmpl/$appname.detail")
   }
   my %template=();
   my %grouplabel;
   my @indexdataaddon;
   if ($#detaillist!=-1){
      for(my $c=0;$c<=$#detaillist;$c++){
         my $template=$detaillist[$c];
         my $dtemp;
         if (open(F,"<$template")){
            sysread(F,$dtemp,65535);
            close(F);
         }
         $template{$template}=$dtemp; 
      }
   }
   else{
      my $headerval;
      my $urlofcurrentrec;
      if ($self->getParent->getParent->can("getField")){
         if (my $o=$self->getParent->getParent->getField("urlofcurrentrec")){
            $urlofcurrentrec=$o->RawValue($rec);
            if ($urlofcurrentrec ne ""){
               $urlofcurrentrec.="<br>";
            }
         }
      }
      if ($self->getParent->getParent->can("getRecordHeader")){
         $headerval=$self->getParent->getParent->getRecordHeader($rec);

      }
      my $H="";
      my $s=$self->getParent->getParent->T($self->getParent->getParent->Self,
                                           $self->getParent->getParent->Self);
      my $recordimg=$self->getParent->getParent->getRecordImageUrl($rec);
      my $subheader="&nbsp;";

      if ($self->getParent->getParent->can("getRecordHtmlDetailHeader")){
         $H=$self->getParent->getParent->getRecordHtmlDetailHeader($rec);
      }
      else{ 
         $headerval=~s/%/\\%/g;   # quote percent chars
         $s=~s/%/\\%/g;
         $H="<h1 class=detailtoplineobj>$s:</h1>".
            "<h2 class=detailtoplinename>$headerval</h2>";
         $recordimg=$self->getParent->getParent->getRecordImageUrl($rec);
         $subheader=$self->getParent->getParent->getRecordSubHeader($rec);
      }
      if ($recordimg ne ""){
         $recordimg="<img class=toplineimage src=\"$recordimg\">";
      }
      my $ByIdLinkStart="";
      my $ByIdLinkEnd="";
      my $dragname="";
      if ($id ne ""){
         if (grep(/^ById$/,$app->getValidWebFunctions())){
            my $targeturl="ById/$id";
            if ($app->can("getAbsolutByIdUrl")){
               $targeturl=$app->getAbsolutByIdUrl($id,{});
            }
            if ($self->getParent->getParent->can("allowAnonymousByIdAccess")){
               if ($self->getParent->getParent->allowAnonymousByIdAccess()){
               #   my $s=$self->getParent->getParent->Self();
               #   $s=~s/::/\//g;
               #   $targeturl="../../../public/$s/ById/$id";
                   $targeturl=~s/\/auth\//\/public\//;
               }
            }


            # Attion: The spaces around the href prevent from rewriten
            #         the address in T-SSO Logon Mode. This is not beautiful,
            #         but it works.
            $ByIdLinkStart="<a tabindex=-1 ".
                           "id=toplineimage target=_blank title=\"".
            $self->getParent->getParent->T("use this link to reference this ".
            "record (f.e. in mail)")."\" href=\" $targeturl \">";
            $ByIdLinkEnd="</a>";
            #if ($targeturl ne ""){
            #   $targeturl=~s#^.*//[^/]+/#/#;
            #   $d.="\n\n<script language=\"JavaScript\">\n";
            #   $d.="window.setTimeout(function(){".
            #       "var curl=parent.document.location.href;\n".
            #       "curl=curl.replace(/\\/(auth|public)\\/.*\$/,'/\$1/');\n".
            #       "var tarl='$targeturl';\n".
            #       "tarl=tarl.replace(/^.*\\/(auth|public)\\//,'');\n".
            #       "tarl=curl+tarl;\n".
            #       "parent.history.pushState({},'Id',tarl);\n".
            #       "},100);\n";
            #   $d.="</script>\n\n";
            #}
         }
         if ($self->getParent->getParent->can("getRecordHeaderField")){
            my $fobj=$self->getParent->getParent->getRecordHeaderField($rec);
            if (defined($fobj)){
               $dragname=$self->getParent->getParent->Self;
               $dragname="w5base://".$dragname."/Show/".$id."/".$fobj->Name(); 
            }
         }
      }
      my $sfocus;
      if ($currentfieldgroup ne ""){
         #$sfocus="setFocus(\"\");";
         $sfocus="setEnterSubmit(document.forms[0],DetailEditSave);";
      #   $sfocus="setFocus(\"\");".
      #           "setEnterSubmit(document.forms[0],DetailEditSave);";
      }
      my $titlestring="$headerval - $s";
      $titlestring=~s/[<>"']//g;
      $titlestring=~s/(&gt;|&lt;)//g;
      $template{"HEADER"}=<<EOF;
<div id="context_menu" class="context_menu">
 <table cellspacing="1" cellpadding="2" border="0">

  <tr>
   <td class="std" onMouseOver="this.className='active';" 
       onMouseOut="this.className='std';">ContextMenu Test</td>
  </tr>

 </table>
</div>
<script language="JavaScript">
var shiftKey=0;

if (parent && parent.globalKeyHandling){
   addEvent(document,'keydown',function(e){
      e=e || window.event;
      parent.globalKeyHandling(document,e);
   });
}

function setTitle()
{
   var t=window.document.getElementById("WindowTitle");
   if (t){
      var query = parent.location.search.substring(1)
      if (query.length){
         if (parent.history != undefined && 
             parent.history.pushState != undefined) {
            var newpath=parent.location.pathname;
            //newpath=newpath.replace(/\\/Detail/,'/ById/${id}'); // not works 
                                                                  // in IE
            
            //parent.history.pushState({},document.title, newpath); // makes 
                                                                    // Strg+R
                                                                    // not work
         }
      } 
      var unquotedTitle=t.innerHTML;                        // unquote amberand
      unquotedTitle=unquotedTitle.replaceAll(/&amp;/g,'&'); // for title tag
      parent.document.title=unquotedTitle;
      document.title=unquotedTitle;
   }
   if ("$dragname"!=""){
      var toplineimage=document.getElementById("toplineimage");
      if (toplineimage){
         addEvent(toplineimage, 'dragstart', function (event) {
            if (event.dataTransfer) {
               event.dataTransfer.clearData(); 
               event.dataTransfer.setData('Text', "$dragname");
            }
         });
      }
   }
   return(true);
}
addEvent(window, "load", setTitle);
addEvent(window, "keydown",function(e){
  if (e.key=="Shift"){
     shiftKey=1;
  }
});
addEvent(window, "keyup",function(e){
  if (e.key=="Shift"){
     shiftKey=0;
  }
});
$sfocus
</script>
<div style="display:none;visibility:hidden;" id=WindowTitle>$titlestring</div>
EOF

      #######################################################################
      # PlugCode Implementation
      my $PlugCode;
      my $userid=$self->getParent->getParent->getCurrentUserId();
      my $po=$self->getParent->getParent->
             getPersistentModuleObject("base::lnkuserw5plug");
      my @parent=($self->getParent->getParent->Self(),
                  $self->getParent->getParent->SelfAsParentObject());

      $po->SetFilter({userid=>\$userid,parentobj=>\@parent});

      foreach my $prec ($po->getHashList(qw(plugname plugcode))){
         $PlugCode.="function W5Plug_".$prec->{plugname}."(){\n";
         $PlugCode.=$prec->{plugcode};
         $PlugCode.="\n}\n";
         $PlugCode.="addEvent(window,'load',W5Plug_".$prec->{plugname}.");\n";
      }
      if ($PlugCode ne ""){
         $PlugCode="<div id=PlugCode><br></div>".
                   "<script language=\"JavaScript\">".$PlugCode."</script>";
      }
      #######################################################################
      my $copyToClipboardStart="";
      my $copyToClipboardEnd="";
      if ($urlofcurrentrec ne ""){ # allow one click to clipboard only on
                                   # records with urlofcurrentrec field
         $copyToClipboardStart="<div style=\"cursor:pointer\" ".
                               "onclick=\"".
                               "copyToClipboard('detailtoplinecliptext');".
                               "\">";
         $copyToClipboardEnd="</div>";
      }

      $template{"header"}=<<EOF;
<a name="index"></a>
<div style="height:4px;border-width:0;overflow:hidden">&nbsp;</div>
<div id=detailtopline class=detailtopline>
   <table aria-hidden="true" width="100%" cellspacing=0 cellpadding=0>
      <tr>
<td rowspan=2 width=1%>$ByIdLinkStart$recordimg$ByIdLinkEnd</a></td>
      <td class=detailtopline>
<table border=0 aria-hidden="true" cellspacing=0 width="100%" style="table-layout:fixed;overflow:hidden"><tr>
<td class=detailtopline align=left>
<div style="display:none;visibility:hidden" id=detailtoplinecliptext><font face="Courier;Courier New"><font color="black">$headerval</font><br>
$urlofcurrentrec</font></div>
$copyToClipboardStart
${H}
$copyToClipboardEnd
</td>
</tr>
<tr><td>${PlugCode}</td></tr>
</table>
</td>
      </tr><tr>
      <td class=detailtopline align=right>$subheader</td>
      </tr>
   </table>
</div>
EOF

      my @fieldlist=@$recordview;
      my $vMatrix={
         grouplist=>[],         # the list of groups, needs to be displayed
         grouplabel=>{},        # the group labels
         grouphavehalfwidth=>{},# the group have min. 1 halfwidth entry
         uivisibleof=>[],       # field is uivisible
         htmldetailof=>[],      # field ist in htmldetail
         fieldhalfwidth=>{},    # field have half width entry
         fieldgrouplist=>[]     # resolved groups of a field
      };
                      
      $self->calcHtmlDetailViewMatrix(
                $rec,$vMatrix,$fieldbase,\@fieldlist,$viewgroups,
                $currentfieldgroup
      );

      my $spec=$self->getParent->getParent->LoadSpec($rec);
      foreach my $group (@{$vMatrix->{grouplist}}){
         my $subfunctions="topedit,editend";
         my $subblock="";
         my $grpentry=$app->getGroup($group,current=>$rec);
         my $col=0;
         my $MaxMatrixCol=0;
         my $CurMatrixCol=0; 
         for(my $c=0;$c<=$#fieldlist;$c++){
            my $name=$fieldlist[$c]->Name();
            next if (!($vMatrix->{uivisibleof}->[$c]));
            next if (!($vMatrix->{htmldetailof}->[$c]));

            if (in_array($vMatrix->{fieldgrouplist}->[$c],$group)){
               if ($fieldlist[$c]->Type() eq "WebLink"){ # WebLink special
                  push(@indexdataaddon,{                 # handling
                     href=>$fieldlist[$c]->RawValue($rec),
                     target=>'_blank',
                     label=>$fieldlist[$c]->Label()});
                  next;
               }
               my $valign=$fieldlist[$c]->valign();
               $valign=" valign=$valign";
               $valign=" valign=top" if ($fieldlist[$c]->can("EditProcessor"));
               if (!($fieldlist[$c]->can("EditProcessor"))){ 
                  $subfunctions="edit,cancel,save";
               }
               my $fieldspec="";
               my $fieldspecfunc="";
               if (defined($spec->{$name})){
                  $fieldspec="<div id=\"fieldspec_$name\" ".
                             "class=detailfieldspec>".
                             "<table aria-hidden=\"true\" width=\"100%\" ".
                             "style=\"table-layout:fixed\">".
                             "<tr><td><span class=detailfieldspec>".
                             $spec->{$name}."</span></td></tr></table></div>";
                  $fieldspecfunc="OnMouseOver=
                                  \"displaySpec(this,'fieldspec_$name');\"";
               }
               my $prefix=$fieldlist[$c]->dlabelpref(current=>$rec);
               if (defined($fieldlist[$c]->{jsonchanged})){
                  my $n="jsonchanged_".$name;
                  if (!grep(/^$n$/,@{$self->Context->{jsonchanged}})){
                     push(@{$self->Context->{jsonchanged}},$n);
                  }
               }
               my $halfwidth=$vMatrix->{fieldhalfwidth}->{$name};
               my $htmllabelwidth=$fieldlist[$c]->htmllabelwidth();
               my $labelwidth="";
               if (defined($htmllabelwidth)){
                  $labelwidth=" width=\"$htmllabelwidth\" "; 
               }
               $subblock.="<tr class=fline>" if ($col==0);
               if ($fieldlist[$c]->Type() eq "Textarea" ||
                   $fieldlist[$c]->Type() eq "Container" ||
                   $fieldlist[$c]->Type() eq "IndividualAttr" ||
                   $fieldlist[$c]->Type() eq "TimeSpans" ||
                   $fieldlist[$c]->Type() eq "Htmlarea"){
                  my $datacolspan=2;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=fname$valign colspan=$datacolspan><span $fieldspecfunc>$prefix\%$name(label)%:</span>$self->{'fieldHeaders'}->{$name}<br>$fieldspec \%$name(detail)\%</td>
EOF
               }
               elsif ($fieldlist[$c]->Type() eq "TimeSpans"){
                  my $datacolspan=1;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=fname$valign colspan=$datacolspan>$self->{'fieldHeaders'}->{$name}\%$name(detail)\%</td>
EOF
               }
               elsif ($fieldlist[$c]->can("EditProcessor")){
                  my $datacolspan=2;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=fname$valign colspan=$datacolspan $fieldspecfunc>$self->{'fieldHeaders'}->{$name}$fieldspec\%$name(detail)\%</td>
EOF

               }
               elsif ($fieldlist[$c]->Type() eq "Message" ||
                      $fieldlist[$c]->Type() eq "OSMap" ||
                      $fieldlist[$c]->Type() eq "GoogleMap"){
                  my $datacolspan=2;
                  $datacolspan=4 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=2 if ($halfwidth);
                  $subblock.=<<EOF;
<td class=finput$valign colspan=$datacolspan>$self->{'fieldHeaders'}->{$name}\%$name(detail)\%</td>
EOF

               }
               elsif ($fieldlist[$c]->Type() eq "MatrixHeader"){
                  my $label=$fieldlist[$c]->Label();
                  $MaxMatrixCol=$#{$label};
                  $subblock.=join("\n",
                                map({
                                   "<td class=finput$valign colspan=1 ".
                                   "align=center><b>".
                                   $_.
                                   "</b></td>";
                                } @$label));
               }
               else{
                  my $align=$fieldlist[$c]->align("Detail");
                  $align="left" if ($align eq "");
                  my $datacolspan=1;
                  $datacolspan=3 if ($vMatrix->{grouphavehalfwidth}->{$group});
                  $datacolspan=1 if ($halfwidth);
                  if ($labelwidth eq ""){
                     $labelwidth="style=\"width:20%;\"";
                  }
                  if ($MaxMatrixCol){
                     if ($CurMatrixCol==0){
                        $subblock.="<td class=fname$valign $labelwidth>$fieldspec<span $fieldspecfunc>$prefix\%$name(label)%:</span>$self->{'fieldHeaders'}->{$name}</td>";
                     }
                     $subblock.=<<EOF;
<td class=finput colspan=$datacolspan>
<table border=0 cellspacing=0 cellpadding=0 width="100%" aria-hidden="true" style="table-layout:fixed;overflow:hidden"><tr>
<td>
<div style="text-align:$align;width:100%;overflow:hidden">
                          \%$name(detail)\%</div>
</td></tr></table>
<div class=clipicon><img title="copy" src="../../base/load/edit_copy.gif"></div>
</td>
EOF
                     $CurMatrixCol++;
                     if ($CurMatrixCol>=$MaxMatrixCol){
                        $CurMatrixCol=0;
                     }
                  }
                  else{
                     $subblock.=<<EOF;
         <td class=fname$valign $labelwidth>$fieldspec<span $fieldspecfunc>$prefix\%$name(label)%:</span>$self->{'fieldHeaders'}->{$name}</td>
         <td class=finput colspan=$datacolspan>
<table aria-hidden="true" border=0 cellspacing=0 cellpadding=0 width="100%" style="table-layout:fixed;overflow:hidden"><tr>
<td>
<div style="width:100%;overflow:hidden">
                          \%$name(detail)\%</div>
</td></tr></table>
<div class=clipicon><img title="copy" src="../../base/load/edit_copy.gif"></div>
</td>
EOF
                  }
               }
               if ($fieldlist[$c]->Type() ne "WebLink"){
                  $col++;
                  if ($CurMatrixCol==0){
                     if ($halfwidth){
                        if ($col>=2){
                           $col=0;
                        } 
                     }
                     else{
                        if ($col>=1){
                           $col=0;
                        } 
                     }
                     $subblock.="</tr>" if ($col==0);
                  }
               }
            }
         }
         my $grouplabel="fieldgroup.".$group;
         my $groupspeclabel=$grouplabel;
         if ($self->getParent->{NewRecord}){
            $groupspeclabel="New.".$groupspeclabel;
         }
         my $groupspec="";
         if (defined($spec->{$groupspeclabel})){
            $groupspec="<div class=detailgroupspec>".
                       $spec->{$groupspeclabel}."</div>";
         }
         if (defined($grpentry) && defined($grpentry->{translation})){
            my $tr=$grpentry->{translation};
            $tr=[$tr] if (ref($tr) ne "ARRAY");
            unshift(@$tr,$self->getParent->getParent->Self());
            $grouplabel=$self->getParent->getParent->T($grouplabel,@$tr);
         }
         else{
            $grouplabel=$self->getParent->getParent->T($grouplabel,
                            $self->getParent->getParent->Self());
         }
         if ($grouplabel eq "fieldgroup.default"){
            $grouplabel=$self->getParent->getParent->T(
                        $self->getParent->getParent->Self(),
                        $self->getParent->getParent->Self());
         }
         if ($group=~m/^privacy_/){
            my $privacy=$self->getParent->getParent->T(
                        "privacy information - ".
                        "only readable with rule write or privacy read");
            $grouplabel.="&nbsp;<a title=\"$privacy\">".
                         "<font color=red>!</font></a>";
         }
         my $detaiframeclassname="detailframe";
         if ($currentfieldgroup ne ""){
            $detaiframeclassname="detailframeread";
         }
         if ($currentfieldgroup eq $group || 
             $self->{WindowEnviroment} eq "modal" ||
             $self->getParent->{NewRecord}){
            $detaiframeclassname="detailframeedit";
         }

         $template{$group}.=<<EOF;
<div class="$detaiframeclassname">
EOF
         if ($vMatrix->{grouplabel}->{$group}){
            $grouplabel{$group}=$grouplabel;
            $grouplabel=~s/#//g;
            $template{$group}.=<<EOF;
 <div class=detailheadline>
 <table aria-hidden="true" width="100%" cellspacing=0 cellpadding=0>
 <tr>
 <td class=detailheadline align=left>
 <h3 class="grouplabel">$grouplabel</h3>
 </td>
 <td class=detailheadline align=right>%DETAILGROUPFUNCTIONS($subfunctions)%</td>
 </tr>
 </table>
 </div>
 $groupspec
EOF
            $grouplabel{$group}=~s/#.*//g;
         }
         $template{$group}.=<<EOF;
 <table aria-hidden="true" class=detailframe border=1>$subblock
 </table>
</div>
EOF
      }
   }


   my $c=0;
   my @blocks=$self->getParent->getParent->sortDetailBlocks([keys(%template)],
                                                            current=>$rec,
                                                            mode=>'HtmlDetail');
   @blocks=("HEADER",grep(!/^HEADER$/,@blocks));
   
   my @indexdata=$app->getRecordHtmlIndex($rec,$id,$viewgroups,
                                          \@blocks,\%grouplabel);
   if ($#indexdataaddon!=-1){
      push(@indexdata,@indexdataaddon);
   }
   if ($#indexdata!=-1){
      my @set;
      my $setno=0;
      my $indexcols=2; 
      for(my $c=0;$c<=$#indexdata;$c++){
         my $chklabel=$indexdata[$c]->{label};
         $chklabel=~s/\<.*?\>//g; # remove html sequences from check
         if (length($chklabel)>40){
            $indexcols=1;last;
         }
      }
      for(my $c=0;$c<=$#indexdata;$c++){
         if ($indexcols==2){
            $setno++ if ($setno==0 && $c>($#indexdata/2));
         }
         if (defined($indexdata[$c])){
            my $link="<a class=HtmlDetailIndex ".
                     "href=\"$indexdata[$c]->{href}\"";
            if (exists($indexdata[$c]->{target})){
               $link.=" target='$indexdata[$c]->{target}'";
            }
            $link.=">";
            $link=~s/\%/\\%/g;
            $set[$setno].="<li>$link$indexdata[$c]->{label}</a></li>";
         }
      }
      for(my $icolnum=0;$icolnum<$indexcols;$icolnum++){
         $set[$icolnum]="<ul class=HtmlDetailIndex>".$set[$icolnum]."</ul>";
      }
      my $indexcoldata=""; # long group names special handling
      for(my $icolnum=0;$icolnum<$indexcols;$icolnum++){
         $indexcoldata.='<td width=40% valign=top>'.
                        '<table style="table-layout:fixed;width:100%" '.
                        'aria-hidden="true" '.
                        'cellspacing=0 cellpadding=0 border=0>'.
                        '<tr><td style="overflow:hidden">'.
                        $set[$icolnum].
                        '</td></tr></table>'.
                        '</td>';
      }

      $template{"header"}.=<<EOF;
<center><div class=HtmlDetailIndex style="text-align:center;width:95%">
<hr>
<table aria-hidden="true" style="xtable-layout:fixed;width:98%" border=0 cellspacing=0 cellpadding=0>
<tr>$indexcoldata</tr>
</table>

<hr>
</div></center>
EOF
   }
     


   $self->{WindowMode}="HtmlDetailEdit" if ($currentfieldgroup ne "");
   my $latelastmsg=0;
   if ($currentfieldgroup eq "" && $self->getParent->getParent->LastMsg()){
      $latelastmsg++;
   }
   if ($app->can("UserReCertHandling")){
      $app->UserReCertHandling($rec,$editgroups);
   }

   foreach my $template (@blocks){
      next if ($self->{WindowEnviroment} eq "modal" &&
               in_array([split(/,/,$FilterViewGroups)],$template));
      my $dtemp=$template{$template};
      my $fieldgroup=$template;
      my %param=(id               =>$id,
                 current          =>$rec,
                 currentid        =>$currentid,
                 fieldbase        =>$fieldbase,
                 fieldgroup       =>$fieldgroup,
                 editgroups       =>$editgroups,
                 viewgroups       =>$viewgroups,
                 WindowEnviroment =>$self->{WindowEnviroment},
                 WindowMode       =>$self->{WindowMode},
                 currentfieldgroup=>$currentfieldgroup);
      $self->ParseTemplateVars(\$dtemp,\%param);
      $d.="\n\n<a name=\"fieldgroup_$fieldgroup\"></a>";
      $d.="\n<a name=\"I.$id.$fieldgroup\"></a>\n";
      if ($c>0 || $#detaillist==0){
         my @msglist;
         if ( $fieldgroup eq $currentfieldgroup || 
             ($fieldgroup eq "default" && $latelastmsg)){
            @msglist=$self->getParent->getParent->LastMsg();
         }
         @msglist=map({quoteHtml($_)} @msglist);
         $d.="<div class=lastmsg>".join("<br>\n",map({
           if ($_=~m/^ERROR/){
              $_="<font style=\"color:red;\">".$_."</font>";
           }
           if ($_=~m/^WARN/){
              $_="<font style=\"color:brown;\">".$_."</font>";
           }
           $_;
         } @msglist))."</div>";
      }
      $d.=$dtemp;
      $c++;
   }
   $self->Context->{LINE}+=1;
   return($d);
}





sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my @pers=qw(CurrentFieldGroupToEdit isCopyFromId CurrentIdToEdit OP
               ScrollY AllowClose FilterViewGroups CurrentDetailMode);
   my $idname;
   my $idfieldobj=$app->IdField();
   if (defined($idfieldobj)){
      $idname=$idfieldobj->Name();
   }
   if (defined($idname) && defined(Query->Param($idname))){
      push(@pers,$idname);
   }
   if (defined($idname) && defined(Query->Param("search_".$idname))){
      Query->Param($idname=>Query->Param("search_".$idname));
      push(@pers,$idname);
   }
   my $d=$app->HtmlPersistentVariables(@pers);
   #$d.="<div style=\"height:".$app->DetailY."px\"></div>";
   $d.="</div>";
   
   my $date=new kernel::Field::Date();
   $date->setParent($self->getParent->getParent());
   my ($str,$ut,$dayoffset)=$date->getFrontendTimeString("HtmlDetail",
                                                         NowStamp("en"));
   my $str2=NowStamp("en");
   my $label=$self->getParent->getParent->T("Condition to:");
   my $user=$ENV{REMOTE_USER};

   my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{fullname})){
      $user.=" - ".$UserCache->{fullname};
   }
   $d.="<br><br>";
   $d.="<div style=\"width:100%;padding:0px;margin:0px\">";
   if (!($self->getParent->{NewRecord})){
       $d.="<div class=detailbottomline>".
           "$label $str $ut - $user</div></div>";
   }
   $d.="</div>";

   if ($#{$self->Context->{jsonchanged}}!=-1){
      $d.="\n<script type=\"text/javascript\" language=JavaScript>\n";
      foreach my $f (@{$self->Context->{jsonchanged}}){
         $d.="if (typeof($f)!=\"undefined\"){\n   $f('init');\n}\n";
      }
      $d.="</script>\n";
   }
   $d.="\n<script language=JavaScript>\n";
   if (Query->Param("CurrentIdToEdit") ne ""){
      $d.="if (parent.setEditMode){parent.setEditMode(1);}";
   }
   else{
      $d.="if (parent.setEditMode){parent.setEditMode(0);}";
   }
   $d.="</script>\n";

   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $scrolly=Query->Param("ScrollY");
   $scrolly=0 if (!defined($scrolly));
   my $d="</form></div></body>";
   $d.="</html>";
   if ($scrolly!=0){
      $d.="<script type=\"text/javascript\" language=JavaScript>".
           # IE Hack to restore
          "window.document.body.scrollTop=$scrolly;".# Scroll Position
          "</script>";
   }
   return($d);
}

sub MkFunc
{
   my $self=shift;
   my $class=shift;
   my $js=shift;
   my $name=shift;

   my $label=$self->getParent->getParent->T($name,"kernel::Output::HtmlDetail");
   $label=~s/"/&quote;/g;
   $label=~s/'/&quote;/g;

   my $id=$name;
   $id=~s/[^a-z]//ig;

   return("<button id=\"$id\" type=button class=$class onclick=$js>".
          $label."</button>");
}

sub DetailFunctions
{
   my $self=shift;

   my $back="&nbsp;";
   if ($#_!=-1){
      $back="&bull; ".join(" &bull; ",@_)." &bull;";
   }
   my $label=$self->getParent->getParent->T("jump to top",
             "kernel::Output::HtmlDetail");
   $back="<div class=detailfunctions>".
         "<span style=\"\">".
         "<a class=HtmlDetailIndex tabindex=-1 style=\"cursor:n-resize\" ".
         " title=\"$label\" href=\"#index\">".
         "&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;</a></span>".
         $back."</div>";
   return($back);
}


sub findtemplvar
{
   my $self=shift;
   my ($opt,$vari,@param)=@_;
   my $fieldgroup="default";
   $fieldgroup=$opt->{fieldgroup} if (defined($opt->{fieldgroup}));

   if ($vari eq "DETAILGROUPFUNCTIONS"){
      my @func;
      my $editgroups=$opt->{editgroups};
      $editgroups=[] if (!ref($editgroups) eq "ARRAY");
      if (defined($opt->{currentfieldgroup})){
         if ($opt->{currentfieldgroup} eq $opt->{fieldgroup} &&
             $opt->{currentid} eq $opt->{id}){
            if (grep(/^save$/,@param)){
               if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
                   grep(/^$opt->{fieldgroup}\..+$/,@{$editgroups}) ||
                   grep(/^ALL$/,@{$editgroups})){
                  push(@func,$self->MkFunc("detailfunctions",
                                           "DetailEditSave()","save")); 
               }
            }
            if (grep(/^cancel$/,@param)){
               if ($opt->{id} ne ""){
                  push(@func,$self->MkFunc("detailfunctions",
                                           "DetailEditBreak()","cancel")); 
               }
            }
            if (grep(/^editend$/,@param)){
               push(@func,$self->MkFunc("detailfunctions",
                                        "DetailTopEditBreak()","finish edit")); 
            }
         }
         else{
            @func=();
         }
      }
      else{
         if (grep(/^edit$/,@param)){
            if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
                grep(/^$opt->{fieldgroup}\..+$/,@{$editgroups}) ||
                grep(/^ALL$/,@{$editgroups})){
               my $qid=$opt->{id};
               $qid=~s/"/\\"/g;
               push(@func,$self->MkFunc("detailfunctions",
                                 "DetailEdit(\"$opt->{fieldgroup}\",".
                                 "\"$qid\")","edit")); 
            }
         }
         if (grep(/^topedit$/,@param)){
            if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
                grep(/^ALL$/,@{$editgroups})){
               push(@func,$self->MkFunc("detailfunctions",
                                        "DetailTopEdit(\"$opt->{fieldgroup}\",".
                                        "\"$opt->{id}\")","edit")); 
            }
         }
      }
      return($self->DetailFunctions(@func));
   }

   return($self->SUPER::findtemplvar(@_));   
}


sub getErrorDocument
{
   my $self=shift;
   my (%param)=@_;
   my $d="";

   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   if ($self->getParent->getParent->can("getParsedTemplate")){
      $d.=$self->getParent->getParent->getParsedTemplate("tmpl/DataObjOffline",
          {skinbase=>"base"});
   }
   else{
      my $LastMsg=join("\n",map({rmNonLatin1($_)}
                  $self->getParent->getParent->LastMsg()));
      $d.=join("\n",map({rmNonLatin1($_)}
                        $self->getParent->getParent->LastMsg()));
   }
   return($d);
}




1;
