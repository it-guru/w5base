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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{htmlheight}=1;
   $self->{_permitted}->{viewarea}=1;
   $self->{_permitted}->{editarea}=1;
   $self->{htmlheight}="300" if (!defined($self->{htmlheight}));
   $self->{valign}="top"     if (!defined($self->{valign}));
   $self->{cols}="80"        if (!defined($self->{cols}));
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   my $d=$self->RawValue($current);
   $d=join("\n--\n",@{$d}) if (ref($d) eq "ARRAY");
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
   $d="<div class=multilinetext>".
      "<textarea onkeydown=\"if (window.textareaKeyHandler){".
      "textareaKeyHandler(this,event);}\" ".
      "cols=$self->{cols} name=Formated_$name ".
      "class=multilinetext>".quoteHtml($d)."</textarea></div>";

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
   $d="<table style=\"width:100%;table-layout:fixed;padding:0;margin:0\">".
      "<tr><td><img class=printspacer ".
      "src=\"../../../public/base/load/empty.gif\" width=1 height=100>".
      "<div class=multilinetext>".
      "<pre class=multilinetext>".mkInlineAttachment(FancyLinks($d)).
      "</pre></div></td></tr></table>";
   return($d);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   $d=join("\n--\n",@{$d}) if (ref($d) eq "ARRAY");
   if ($FormatAs eq "HtmlV01"){
      if (!$self->{AllowHtmlInput}){
         $d=~s/</&lt;/g;
         $d=~s/>/&gt;/g;
      }
      $d=~s/\n/<br>\n/g;
   }
   if ($FormatAs eq "SOAP"){
      return(quoteSOAP($d));
   }
   #printf STDERR ("fifi FormatAs=$FormatAs\n");
   return($d);
}

sub getSelectField
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
      if (!($$curPageHeadRef=~m/^<script id=TextTranslation /)){
         $$curPageHeadRef.=
              "<script id=TextTranslation language=\"JavaScript\" ".
              "src=\"../../base/load/TextTranslation.js\"></script>\n";
      }
   }
}












1;
