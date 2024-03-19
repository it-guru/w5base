package kernel::Field::Textarea;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{htmlheight}=1;
   $self->{_permitted}->{viewarea}=1;
   $self->{_permitted}->{editarea}=1;
   $self->{htmlheight}=""    if (!defined($self->{htmlheight}));
   $self->{valign}="top"     if (!defined($self->{valign}));
   $self->{cols}="70"        if (!defined($self->{cols}));
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   my $d=$self->RawValue($current,$mode);
   my $j="\n--\n";
   if (exists($self->{vjoinconcat})){
      $j=$self->{vjoinconcat};
   }
   $d=join($j,@{$d}) if (ref($d) eq "ARRAY");
   my $readonly=$self->readonly($current);
   if ($mode eq "HtmlDetail" || 
       (($mode eq "edit" || $mode eq "workflow") && $readonly)){
      $d=$self->callViewArea($current,$mode,$d);
   }
   if (($mode eq "edit" || $mode eq "workflow") && !$readonly){
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      $d=$self->callEditArea($current,$mode,$d);
   }
   return($d);
}

sub callEditArea
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=shift;
   $self->{editarea}=\&EditArea if (!defined($self->{editarea}));
   return(&{$self->{editarea}}($self,$current,$mode,$d));
}

sub EditArea    # for module defined edit areas (f.e. javascript areas)
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=shift;
   my $name=$self->Name();
   my $style1="";
   my $style2="resize:none";
   if ($self->{htmlheight} ne ""){
      if ($self->{htmlheight} eq "auto"){
         $style1=" style='height:208px'";
         $style2.=";height:200px";
      }
      else{
         $style1=" style='height:".($self->{htmlheight}+4)."px'";
         $style2.=";height:".($self->{htmlheight}-4)."px";
      }
   }

   my $arialable=$self->Label();
   $arialable=~s/"//g;

   $d="<div class=multilinetext$style1>".
      "<textarea aria-label=\"$arialable\" id=$name style='$style2' ".
      "onkeydown=\"if (window.textareaKeyHandler){".
      "textareaKeyHandler(this,event);}\" ".
      "cols=$self->{cols} name=Formated_$name ".
      "class=multilinetext>".quoteHtml($d)."</textarea></div>";
   $d.="<script language=JavaScript>";
   $d.=" var element_$name=document.forms[0].elements['Formated_$name'];";
   $d.=" function DragCancel_$name(e){";
   $d.="   if (e.preventDefault){";
   $d.="      e.preventDefault();";
   $d.="   }";
   $d.="   return(false);";
   $d.=" }";
   $d.=" function HandleDrop_$name(e){";
   $d.="   if (e.preventDefault){";
   $d.="      e.preventDefault();";
   $d.="   }";
   $d.="   this.value+=\"\\n\"+e.dataTransfer.getData('Text')+\"\\n\";";
   $d.="   return(false);";
   $d.=" }";
   $d.=" addEvent(element_$name,'drop',HandleDrop_$name);";
   $d.=" addEvent(element_$name,'dragover',DragCancel_$name);";
   $d.=" addEvent(element_$name,'dragenter',DragCancel_$name);";
   $d.="</script>";

   return($d);
}

sub callViewArea
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=shift;
   $self->{viewarea}=\&ViewArea if (!defined($self->{viewarea}));
   return(&{$self->{viewarea}}($self,$current,$mode,$d));
}

sub ViewArea    # for module defined view areas (f.e. javascript areas)
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=shift;


   if (!$self->{AllowHtmlInput}){
      $d=~s/&/&amp;/g;
      $d=~s/</&lt;/g;
      $d=~s/>/&gt;/g;
   }
   my $style1="";
   my $style2="";
   if ($self->{htmlheight} ne ""){
      if ($self->{htmlheight} eq "auto"){
         $style1=" style='min-height:200px;height:".($self->{htmlheight})."'";
         $style2=" style='min-height:200px;height:".($self->{htmlheight})."'";
      }
      else{
         $style1=" style='height:".($self->{htmlheight}+4)."px'";
         $style2=" style='height:".($self->{htmlheight}-4)."px'";
      }
   }
   
   my $expandcode="var p=this.parentNode;p.style.height='auto';".
                  "var c=this.parentNode.childNodes;".
                  "for(var i=0; i<c.length; i++) {".
                  "if (c[i].nodeName.toLowerCase()=='div' ||".
                  "c[i].nodeName.toLowerCase()=='pre') {".
                  "c[i].style.height='auto';".
                  "}".
                  "}".
                  "this.style.display='none';";
   my $multilinetextexpand="<img onclick=\"$expandcode\" ".
                           "class=\"multilinetextexpand\" ".
                           "src='../../../public/base/load/vexpand.gif'>";
   {
      my @l=split(/\n/,$d);
      if ($#l<5 && length($d)<250){
         $multilinetextexpand="";
      }
   }
   if ($self->{htmlheight} eq "auto"){
      $multilinetextexpand="";
   }

   $d="<table cellspacing=0 cellpadding=0 border=0 ".
      "style=\"width:100%;table-layout:fixed;padding:0;margin:0\">".
      "<tr><td width=1><img class=printspacer style=\"padding:0;margin:0\" ".
      "src=\"../../../public/base/load/empty.gif\" width=0 height=100>".
      "</td><td><div class=multilinetext$style1>".
      $multilinetextexpand.
      "<pre class=multilinetext$style2>".
      mkInlineAttachment(
         ExpandW5BaseDataLinks($self->getParent,"HtmlDetail",
            FancyLinks($d))).
      "</pre></div></td></tr></table>";
   return($d);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current,$FormatAs);
   my $j="\n--\n";
   if (exists($self->{vjoinconcat})){
      $j=$self->{vjoinconcat};
   }
   $d=join($j,@{$d}) if (ref($d) eq "ARRAY");

   if ($FormatAs eq "HtmlV01" || 
       $FormatAs eq "HtmlWfActionlog" ||
       $FormatAs eq "HtmlSubList"){
      if (!ref($d)){
         my $lang=$self->getParent->Lang();
         $d=extractLangEntry($d,$lang,65535,65535);  # 64k lines and bytes
      }
      if (!$self->{AllowHtmlInput}){
         $d=quoteHtml($d);
        # $d=~s/</&lt;/g;
        # $d=~s/>/&gt;/g;
      }
      else{
         $d=quoteHtml($d);
      }
      if ($FormatAs eq "HtmlV01"){
         my @lines=split(/\n/,$d);
         if (length($d)>80 || $#lines>3){
            $d="<p class=heightLimitedText>".$d."</p>";
         }
      }
      if ($FormatAs eq "HtmlV01" || $FormatAs eq "HtmlExplore" || 
          $FormatAs eq "HtmlSubList"){
         # target ist kein pre-Formated HTML Element
         $d=~s/\n/<br>\n/gs;
      }
   }
   if ($FormatAs eq "SOAP"){
      return(quoteSOAP($d));
   }
   $d=ExpandW5BaseDataLinks($self->getParent,$FormatAs,$d);
   
   #printf STDERR ("fifi FormatAs=$FormatAs d=$d\n");
   return($d);
}

sub getBackendName
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   return(undef) if ($mode eq "order");
   return(undef) if (!defined($self->{dataobjattr}));
   return($self->{dataobjattr});
}

sub FormatedStoredWorkspace
{
   my $self=shift;
   my $name=$self->{name};
   my $d="";

   my @curval=Query->Param("Formated_".$name);
   my $disp="";
   foreach my $var (@curval){
      $disp.=$self->FormatedDetail({$name=>$var},"HtmlDetail");
      $var=quoteHtml($var);
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   return($d);
}

sub extendPageHeader
{
   my $self=shift;
   my $mode=shift;
   my $current=shift;
   my $curPageHeadRef=shift;

   if ($mode eq "Detail" || ($mode=~m/^html/i)){
      if (!($$curPageHeadRef=~m/<script id=TextTranslation /)){
         $$curPageHeadRef.=
              "<script id=TextTranslation language=\"JavaScript\" ".
              "src=\"../../base/load/TextTranslation.js\"></script>\n";
      }
   }
}












1;
