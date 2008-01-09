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
use Data::Dumper;
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
   $d.=$app->HttpHeader();
   $d.=$app->HtmlHeader(style=>['default.css',
                                'work.css',
                                'Output.HtmlDetail.css',
                                'kernel.App.Web.css',
                                'Output.HtmlSubList.css',
                           #     'kernel.workflowrelation.css',
                                'kernel.filemgmt.css'],
                        onload=>'DetailInit()');
#   $d.="<html>";
#   $d.="<link rel=stylesheet ".
#       "href=\"../../base/load/default.css\"></link>";
#   $d.="<link rel=stylesheet ".
#       "href=\"../../base/load/work.css\"></link>";
#   $d.="<link rel=stylesheet ".
#       "href=\"../../base/load/Output.HtmlDetail.css\"></link>";
#   $d.="<link rel=stylesheet ".
#       "href=\"../../base/load/kernel.App.Web.css\"></link>";
#   $d.="<link rel=stylesheet ".
#       "href=\"../../base/load/Output.HtmlSubList.css\"></link>";
#   $d.="<link rel=stylesheet ".
#       "href=\"../../base/load/kernel.filemgmt.css\"></link>";
#   $d.="<body OnLoad=DetailInit()>";
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
   my ($self,$fh,$rec,$msg)=@_;
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
   $d.="<form method=post target=_self enctype=\"multipart/form-data\">";
   $d.="<style>";
   $d.=$self->getStyle($fh,$rec,$msg,\@view,$view);
   $d.="</style>\n";
   $d.="<script language=\"JavaScript\" ".
       "src=\"../../base/load/HtmlDetail.js\"></script>\n";
   $d.="<script language=\"JavaScript\" ".
       "src=\"../../base/load/toolbox.js\"></script>\n";
   $d.="<script language=\"JavaScript\" ".
       "src=\"../../base/load/TextTranslation.js\"></script>\n";
   $d.="<script language=\"JavaScript\">\n";
   if ($scrolly!=0){
      $d.=<<EOF;
function DetailInit()  // used from asyncron sub data to restore position in
{                      // page
   document.body.scrollTop=$scrolly;
   return;
}
EOF
   }
   else{
      $d.=<<EOF;
function DetailInit()  // used from asyncron sub data to restore position in
{                      // page
   return;
}
EOF
   }
   $d.=<<EOF;
function onNew()
{
   var t=document.getElementById("TabSelectorModeSelect");
   if (t){
      var e=document.getElementById("HtmlDetail");
      e.style.height=(t.offsetHeight-30)+"px";
   }
}
addEvent(window, "load",   onNew);

EOF
   $d.="</script>\n\n";
   $self->Context->{LINE}=0;
   $self->Context->{jsonchanged}=[];

   return($d);
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
   my $spec=$self->getParent->getParent->LoadSpec($rec);
   
   if ($self->getParent->{NewRecord}){
      $currentfieldgroup="default";
   #   $currentid="[new]";
   }
   my $d="";
   $currentfieldgroup=undef if ($currentfieldgroup eq "");
   my $field=$app->IdField();
   my $id=$field->RawValue($rec);
   if ($self->Context->{LINE}>0){
      $d.="<div style=\"height:2px;overflow:hidden;padding:0;maring:0\">".
          "&nbsp;</div>";
      $d.="<hr class=detailseperator>";
   }

   my $module=$app->Module();
   my $appname=$app->App();
   my @detaillist=$app->getSkinFile("$module/tmpl/$appname.detail.*");
   if ($#detaillist==-1){
      @detaillist=$app->getSkinFile("$module/tmpl/$appname.detail")
   }
   my %template=();
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
      my $headerval="";
      my $H="";
      if (my $f=$self->getParent->getParent->getField("fullname")){
         $headerval=quoteHtml($f->RawValue($rec));
      }
      elsif (my $f=$self->getParent->getParent->getField("name")){
         $headerval=quoteHtml($f->RawValue($rec));
      }
      else{
         $headerval='%objecttitle%';
      }
      my $s=$self->getParent->getParent->T($self->getParent->getParent->Self,
                                           $self->getParent->getParent->Self);
      my $recordimg=$self->getParent->getParent->getRecordImageUrl($rec);

      if ($self->getParent->getParent->can("getRecordHtmlDetailHeader")){
         $H=$self->getParent->getParent->getRecordHtmlDetailHeader($rec);
      }
      else{ 
         $H="<p class=detailtoplineobj>$s:</p>".
            "<p class=detailtoplinename>$headerval</p>";
      }
      if ($recordimg ne ""){
         $recordimg="<img class=toplineimage src=\"$recordimg\">";
      }
      my $ByIdLinkStart="";
      my $ByIdLinkEnd="";
      if (grep(/^ById$/,$self->getParent->getParent->getValidWebFunctions())){
         $ByIdLinkStart="<a target=_blank href=\"ById/$id\">";
         $ByIdLinkEnd="</a>";
      }
      my $sfocus;
      if ($currentfieldgroup ne ""){
         #$sfocus="setFocus(\"\");";
         $sfocus="setEnterSubmit(document.forms[0],DetailEditSave);";
      #   $sfocus="setFocus(\"\");".
      #           "setEnterSubmit(document.forms[0],DetailEditSave);";
      }
      $template{"header"}=<<EOF;
<div style="height:4px;border-width:0;overflow:hidden">&nbsp;</div>
<div class=detailtopline>
   <table width=100% cellspacing=0 cellpadding=0>
      <tr>
<td rowspan=2 width=1%>$ByIdLinkStart$recordimg$ByIdLinkEnd</a></td>
      <td class=detailtopline align=left>
<table border=0 width=100% style="table-layout:fixed;overflow:hidden"><tr>
<td class=detailtopline align=left>$H
<div style="display:none;visibility:hidden;" id=WindowTitle>$s: $headerval</div>
</td></tr></table>
</td>
      </tr><tr>
      <td class=detailtopline align=right></td>
      </tr>
   </table>
</div>

<script language="JavaScript">
function setTitle()
{
   var t=window.document.getElementById("WindowTitle");
   parent.document.title=t.innerHTML;
   return(true);
}
addEvent(window, "load", setTitle);
$sfocus
</script>
EOF
      my @grouplist;
      my %grouplabel;
      my @fieldlist=@$recordview;
      my @uivisibleof=();

      for(my $c=0;$c<=$#fieldlist;$c++){
         my $name=$fieldlist[$c]->Name();
         $fieldbase->{$name}=$fieldlist[$c];
         $uivisibleof[$c]=$fieldlist[$c]->UiVisible("HtmlDetail",current=>$rec);
         next if (!($uivisibleof[$c]));
         next if (!($fieldlist[$c]->htmldetail("HtmlDetail",current=>$rec)));
         if (!grep(/^$fieldlist[$c]->{group}$/,@grouplist)){
            push(@grouplist,$fieldlist[$c]->{group});
            $grouplabel{$fieldlist[$c]->{group}}=0;
         }
         my $grouplabel=$fieldlist[$c]->grouplabel($rec);
         $grouplabel{$fieldlist[$c]->{group}}=1 if ($grouplabel);
      }
      foreach my $group (@grouplist){
         my $subfunctions="topedit,editend";
         my $subblock="";
         my $grpentry=$app->getGroup($group,current=>$rec);
         for(my $c=0;$c<=$#fieldlist;$c++){
            my $name=$fieldlist[$c]->Name();
            next if (!($uivisibleof[$c]));
            next if (!($fieldlist[$c]->htmldetail("HtmlDetail",current=>$rec)));
            if ($fieldlist[$c]->{group} eq $group){
               my $valign=$fieldlist[$c]->valign();
               $valign=" valign=$valign";
               $valign=" valign=top" if ($fieldlist[$c]->can("EditProcessor"));
               if (!($fieldlist[$c]->can("EditProcessor"))){ $subfunctions="edit,cancel,save";
               }
               my $fieldspec="";
               my $fieldspecfunc="";
               if (defined($spec->{$name})){
                  $fieldspec="<div id=\"fieldspec_$name\" ".
                             "class=detailfieldspec>".
                             "<table width=100% style=\"table-layout:fixed\">".
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
               if ($fieldlist[$c]->Type() eq "Textarea" ||
                   $fieldlist[$c]->Type() eq "Container" ||
                   $fieldlist[$c]->Type() eq "Htmlarea"){
                  $subblock.=<<EOF;
      <tr class=fline>
         <td class=fname$valign colspan=2>
<span $fieldspecfunc>$prefix\%$name(label)%:</span><br>$fieldspec
\%$name(detail)\%
</td>
      </tr>
EOF
               }
               elsif (
                   $fieldlist[$c]->Type() eq "TimeSpans" 
                   ){
                  $subblock.=<<EOF;
      <tr class=fline>
         <td class=fname$valign colspan=2>
\%$name(detail)\%
</td>
      </tr>
EOF
               }
               elsif ($fieldlist[$c]->can("EditProcessor")){
                  $subblock.=<<EOF;
      <tr class=fline>
         <td class=fname$valign colspan=2 $fieldspecfunc>$fieldspec
\%$name(detail)\%
</td>
      </tr>
EOF

               }
               elsif ($fieldlist[$c]->Type() eq "Message" ||
                      $fieldlist[$c]->Type() eq "GoogleMap"){
                  $subblock.=<<EOF;
      <tr class=fline>
         <td class=finput$valign colspan=2>
\%$name(detail)\%
</td>
      </tr>
EOF

               }
               else{
                  $subblock.=<<EOF;
      <tr class=fline>
         <td class=fname$valign style="width:20%;">$fieldspec<span $fieldspecfunc>$prefix\%$name(label)%:</span></td>
         <td class=finput>
<table border=0 cellspacing=0 cellpadding=0 width=100% style="table-layout:fixed;overflow:hidden"><tr>
<td>
<div style="width=100%;overflow:hidden">
                          \%$name(detail)\%</div>
</td></tr></table>
</td>

      </tr>
EOF
               }
            }
         }
         my $grouplabel="fieldgroup.".$group;
         my $groupspec="";
         if (defined($spec->{$grouplabel})){
            $groupspec="<div class=detailgroupspec>".
                       $spec->{$grouplabel}."</div>";
         }
         if (defined($grpentry) && defined($grpentry->{translation})){
            my $tr=$grpentry->{translation};
            $tr=[$tr] if (ref($tr) ne "ARRAY");
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
         $template{$group}.=<<EOF;
<div class=detailframe>
EOF
         if ($grouplabel{$group}){
            $template{$group}.=<<EOF;
 <div class=detailheadline>
 <table width=100% cellspacing=0 cellpadding=0>
 <tr>
 <td class=detailheadline align=left>$grouplabel</td>
 <td class=detailheadline align=right>%DETAILGROUPFUNCTIONS($subfunctions)%</td>
 </tr>
 </table>
 </div>
 $groupspec
EOF
         }
         $template{$group}.=<<EOF;
 <table class=detailframe border=1>$subblock
 </table>
</div>
EOF
      }
   }
   my $c=0;
   my @blocks=$self->getParent->getParent->sortDetailBlocks([keys(%template)],
                                                            current=>$rec,
                                                            mode=>'HtmlDetail');
   $self->{WindowMode}="HtmlDetailEdit" if ($currentfieldgroup ne "");
   foreach my $template (@blocks){
      my $dtemp=$template{$template};
      my $fieldgroup=$template;
      if (grep(/^ALL$/,@{$viewgroups}) || 
          grep(/^$fieldgroup$/,@{$viewgroups})){
         my %param=(id               =>$id,
                    current          =>$rec,
                    currentid        =>$currentid,
                    fieldbase        =>$fieldbase,
                    fieldgroup       =>$fieldgroup,
                    editgroups       =>$editgroups,
                    viewgroups       =>$viewgroups,
                    WindowMode       =>$self->{WindowMode},
                    currentfieldgroup=>$currentfieldgroup);
         $self->ParseTemplateVars(\$dtemp,\%param);
         $d.="<a name=$id.$fieldgroup></a>";
         if ($c>0 || $#detaillist==0){
            my @msglist;
            if ($fieldgroup eq $currentfieldgroup){
               @msglist=$self->getParent->getParent->LastMsg();
            }
            $d.="<div class=lastmsg>".
                join("<br>\n",map({
                                    if ($_=~m/^ERROR/){
                                       $_="<font style=\"color:red;\">".$_.
                                          "</font>";
                                    }
                                    $_;
                                  } @msglist))."</div>";
         }
         $d.=$dtemp;
      }
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
               ScrollY AllowClose CurrentDetailMode);
   my $idname=$app->IdField->Name();
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

   $d.="<div style=\"width:100%;padding:0px;margin:0px\">";
   if (!($self->getParent->{NewRecord})){
       $d.="<div class=detailbottomline>".
           "$label $str $ut - $user</div></div>";
   }
   $d.="</div>";
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
      $d.="<script language=JavaScript>".                # IE Hack to restore
          "window.document.body.scrollTop=$scrolly;".# Scroll Position
          "</script>";
   }
   if ($#{$self->Context->{jsonchanged}}!=-1){
      $d.="\n<script language=JavaScript>\n";
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

sub MkFunc
{
   my $self=shift;
   my $class=shift;
   my $js=shift;
   my $name=shift;

   return("<a class=$class href=JavaScript:$js>".
     $self->getParent->getParent->T($name,"kernel::Output::HtmlDetail")."</a>");
}

sub DetailFunctions
{
   if ($#_!=-1){
      return("<div class=detailfunctions>&bull; ".join(" &bull; ",@_).
             " &bull;</div>");
   }
   return("&nbsp;");
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
                   grep(/^ALL$/,@{$editgroups})){
                  push(@func,$self->MkFunc("detailfunctions","DetailEditSave()","save")); 
               }
            }
            if (grep(/^cancel$/,@param)){
               if ($opt->{id} ne ""){
                  push(@func,$self->MkFunc("detailfunctions","DetailEditBreak()","cancel")); 
               }
            }
            if (grep(/^editend$/,@param)){
               push(@func,$self->MkFunc("detailfunctions","DetailTopEditBreak()","finish edit")); 
            }
         }
         else{
            @func=();
         }
      }
      else{
         if (grep(/^edit$/,@param)){
            if (grep(/^$opt->{fieldgroup}$/,@{$editgroups}) ||
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
               push(@func,$self->MkFunc("detailfunctions","DetailTopEdit(\"$opt->{fieldgroup}\",".
                                 "\"$opt->{id}\")","edit")); 
            }
         }
      }
      return(DetailFunctions(@func));
   }

   return($self->SUPER::findtemplvar(@_));   
}



1;
