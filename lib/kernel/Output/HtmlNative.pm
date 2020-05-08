package kernel::Output::HtmlNative;
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
use base::load;
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   return($self);
}

sub IsModuleSelectable
{
   return(1);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_htmltab.gif");
}
sub Label
{
   return("Output to native HTML");
}
sub Description
{
   return("Use this format, to get native HTML Lists without any includes");
}





sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->HttpHeader("text/html");
   $d.=$app->HtmlHeader();
   $d.=<<EOF;
<style>
body,th,td,li,p{
   font-family:Arial,Adobe Helvetica,Helvetica;
   font-size:12px;
}
th{
   text-align:left;
}
</style>

EOF


#   $d.="Content-type:text/html\n\n";
#   $d.="<html>";
#   $d.="<body>";
   return($d);
}

#sub Init
#{
#   my ($self,$fh)=@_;
#   my $app=$self->getParent->getParent();
#   $self->{fieldobjects}=[];
#   $self->{fieldkeys}={};
#   my @view=$app->getFieldObjsByView([$app->getCurrentView()]);
#   for(my $c=0;$c<=$#view;$c++){
#      my $field=$view[$c];
#      my $name=$field->Name();
#      push(@{$self->{fieldobjects}},$field);
#      $self->{fieldkeys}->{$name}=$#{$self->{fieldobjects}};
#   }
#   return();
#}





sub ProcessHead
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=();
   @view=@{$self->{fieldobjects}} if (defined($self->{fieldobjects}));
   my $d="";
   my $dest=$app->Self();
   $dest=~s/::/\//g;
   $dest="../../$dest/Result";
   $d.="<table border=1>\n<tr>";
   if ($#view!=-1){
      foreach my $field (@view){
         my $nowrap="";
         my $displayname=$field->Name();
         if (defined($field)){
            $displayname=$field->Label();
         }
         if (defined($field->{unit})){
            $displayname.="<br>($field->{unit})";
         }
         if ($field->{htmlnowrap} eq "all" || $field->{htmlnowrap} eq "head"){
            $nowrap=" nowrap";
         }
         my $style="";
         if (defined($field->{htmlwidth})){
            $style="width:$field->{htmlwidth};";
         }
         $d.="<th class=headfield valign=top style=\"$style\"$nowrap>".
             $displayname."</th>";
      }
   }
   else{
      $d.="<th>No-Fields</th>";
   }
   $d.="</tr>\n";
   return($d);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=@{$recordview};
   my $fieldbase={};
   map({$fieldbase->{$_->Name()}=$_} @view);
   my $d="";
   my $lineclass="subline";
   my $lineonclick;
   my $idfield=$app->IdField();
   my $idfieldname=undef;
   my $id=undef;
   if (defined($idfield)){
      $idfieldname=$idfield->Name() if (defined($idfield));
      $id=$idfield->RawValue($rec);
   }
   $id=$id->[0] if (ref($id) eq "ARRAY");
   my $ResultLineClickHandler=$app->{ResultLineClickHandler};
   $ResultLineClickHandler="Detail" if (!defined($ResultLineClickHandler));
   if (grep(/^$ResultLineClickHandler$/,$app->getValidWebFunctions())){
      if ($idfield){
         my $dest=$app->Self();
         $dest=~s/::/\//g;
         my $lq=new kernel::cgi({});
         $lq->Param($idfieldname=>$id);
         $lq->Param(AllowClose=>1);
         my $urlparam=$lq->QueryString();
         $dest="../../$dest/$ResultLineClickHandler?$urlparam";
         my $detailx=$app->DetailX();
         my $detaily=$app->DetailY();
         my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         my $winsize="";
         if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
            $winsize=$UserCache->{winsize};
         }
         if ($winsize eq ""){
            $lineonclick="openwin(\"$dest\",\"_blank\",".
                "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                "resizable=yes,scrollbars=auto\")";
         }
         else{
            $lineonclick="custopenwin(\"$dest\",\"$winsize\",$detailx)";
         }
      }
   }
   $d.="<tr class=$lineclass>";
   my @l=();
   for(my $c=0;$c<=$#view;$c++){
      my $nowrap="";
      my $fieldname=$view[$c]->Name();
      my $field=$view[$c];
      my $data="undefined";
      if (!defined($self->{fieldkeys}->{$fieldname})){
         push(@{$self->{fieldobjects}},$field);
         $self->{fieldkeys}->{$fieldname}=$#{$self->{fieldobjects}};
      }
      my $fclick=undef;
      if (defined($field)){
         if ($field->UiVisible("HtmlList",current=>$rec)){
            $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      current=>$rec,
                                      WindowMode=>$self->{WindowMode},
                                      fieldbase=>$fieldbase
                                     },$fieldname,
                                        "formated");
            #if ($self->getParent->getParent->Config->Param("UseUTF8")){
            #   $data=utf8($data);
            #   $data=$data->latin1();
            #}
         }
         else{
            $data="-";
         }
        # my $data=$field->FormatedResult("html");
         $fclick=undef if ($field->can("getSubListData"));
      
         if ($self->{SubListEdit}==1){
            $fclick="SubListEdit('$id')";
         }
      }
      my $style;
      my $align;
      if (defined($field->{align})){
         $align=" align=$field->{align}";
      }
      if (defined($field->{htmlwidth})){
         $style.="width:$field->{htmlwidth};";
      }
      else{
         $style.="width:auto;";
      }
      if (defined($field->{nowrap}) && $field->{nowrap}==1){
         $style.="white-space:nowrap;";
         $nowrap=" nowrap";
      }
      $l[$self->{fieldkeys}->{$fieldname}]={data=>$data,
                                            align=>$align,
                                            nowrap=>$nowrap,
                                            style=>$style};
   }
   foreach my $rec (@l){
      if (!defined($rec) || $rec->{data}=~m/^\s*$/){
         $d.="<td>&nbsp;</td>";
      }
      else{
         $d.="<td valign=top align=$rec->{align}";
         $d.=" style=\"$rec->{style}\"$rec->{nowrap}>".
             $rec->{data}.
             "</td>\n";
      }
   }
   $d.="</tr>\n";
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="</table>";

   my $limitreached=0;
   if (defined($msg)){
      if (!$self->{DisableMsg}){
         if ($msg eq "Limit reached"){
            $limitreached=1;
         }
         else{
            $d.="<hr>unexpected error = $msg<br>";
         }
      }
   }


   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $d="";
   $d.="</body>";
   $d.="</html>";
   return($d);
}





sub getStyle
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->getTemplate("css/default.css","base");
   $d.=$app->getTemplate("css/Output.HtmlSubList.css","base");
   $d.=$app->getTemplate("css/Output.HtmlV01.css","base");
   return($d);
}




1;
