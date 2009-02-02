package kernel::Output::HtmlSubList;
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
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
  # my $config=$self->getParent->getParent->Config();
   #$self->{SkinLoad}=getModuleObject($config,"base::load");

   return($self);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_html.gif");
}
sub Label
{
   return("Output to Html List");
}
sub Description
{
   return("A simple Html List");
}

sub MimeType
{
   return("text/html");
}




sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType()."\n\n";
   $d.="<html>";
   $d.="<body>";
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
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $d="";
  # $d.=$app->getTemplate("css/Output.HtmlV00.css","base");
   return($d);
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="";

   my $tableid;
   my $tableidstr;
   if (defined($self->{parentfield})){
      $tableid=$self->{parentfield};
   }
   else{
      $tableid=$self->Self;
      $tableid=~s/[^a-z]/_/gi;
   }
   $tableidstr="id=\"$tableid\""; 
   my @sortnames;
   foreach my $fname (@view){
      push(@sortnames,"String");
   }
   my $sortline=join(",",map({'"'.$_.'"'} @sortnames));

   if ($param->{ParentMode} ne "HtmlV01" &&
       $param->{ParentMode} ne "HtmlNative"){
      $d.="<table width=100% style=\"table-layout:fixed\">".
          "<tr><td><div style=\"overflow:hidden\">\n";
   }
   $d.=<<EOF if ($param->{ParentMode} eq "HtmlDetail");
<script language="JavaScript">
var SortTable$tableid;
function addClassName$tableid(el, sClassName) {
	var s = el.className;
	var p = s.split(" ");
	var l = p.length;
	for (var i = 0; i < l; i++) {
		if (p[i] == sClassName)
			return;
	}
	p[p.length] = sClassName;
	el.className = p.join(" ").replace( /(^\s+)|(\s+\$)/g, "" );
}

function removeClassName$tableid(el) {
	var s = el.className;
	var p = s.split(" ");
	var np = [];
	var l = p.length;
	var j = 0;
	el.className = "";
}


function InitTab$tableid()
{
  SortTable$tableid = new SortableTable(document.getElementById("$tableid"),
                                        [$sortline]);
  SortTable$tableid.onsort=function () {
        var rows = SortTable$tableid.tBody.rows;
        var l = rows.length;
        for (var i = 0; i < l; i++) {
                removeClassName$tableid(rows[i]);
                addClassName$tableid(rows[i], i % 2 ? "subline2":"subline1");
        }
  };
  SortTable$tableid.sort(0,false);
}
addEvent(window,"load",InitTab$tableid);
</script>
EOF
   if ($param->{ParentMode} eq "HtmlNative"){
      $d.="<table width=100%>\n";
   }
   else{
      $d.="<table class=maintable>\n";
   }
   $d.=$self->getViewLine($fh);

   $d.="<tr><td class=mainblock>";

   if ($param->{ParentMode} eq "HtmlNative"){
      $d.="<table $tableidstr border=1 width=100%>\n";
   }
   else{
      $d.="<table $tableidstr class=subdatatable width=100%>\n";
   }

   $d.="<thead><tr class=subheadline>";
   foreach my $fieldname (@view){
      my $field=$app->getField($fieldname);
      my $displayname=$fieldname;
      if (defined($field)){
         $displayname=$field->Label();
      }
      my $style;
      if (defined($field->{htmlwidth})){
         $style.="width:$field->{htmlwidth};";
      }
      $displayname="&nbsp;" if ($displayname eq "");
      $d.="<th class=subheadfield style=\"$style\">".$displayname."</th>";
   }
   $d.="</tr></thead>\n<tbody>\n";
   return($d);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   $self->{lineclass}=1 if (!exists($self->{lineclass}));
   my $d="";
   my $lineclass="subline".$self->{lineclass};
   my $lineonclick;
   my $idfield=$app->IdField();
   my $idfieldname=$idfield->Name();
   my $id=$idfield->RawValue($rec);
   $id=$id->[0] if (ref($id) eq "ARRAY");
   if (grep(/^Detail$/,$app->getValidWebFunctions())){
      if ($idfield){
         my $dest=$app->Self();
         $dest=~s/::/\//g;
         $dest="../../$dest/Detail?$idfieldname=$id&AllowClose=1";
         my $detailx=$app->DetailX();
         my $detaily=$app->DetailY();
         $lineonclick="openwin(\"$dest\",\"_blank\",".
             "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
             "resizable=yes,scrollbars=no\")";
      }
   }
   $d.="<tr class=$lineclass ";
   if (!($self->{nodetaillink})){
      $d.="onMouseOver=\"this.oldclassName=this.className;this.className='linehighlight';\" ".
          "onMouseOut=\"this.className=this.oldclassName\">\n";
   }
   for(my $c=0;$c<=$#view;$c++){
      my $fieldname=$view[$c];
      my $field=$app->getField($fieldname);
      my $data="undefined";
      my $fclick=$lineonclick;
      my $weblinkname=$app->Self();
      if (defined($field)){
         $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   mode=>'HtmlSubList',
                                      current=>$rec
                                     },$fieldname,
                                     "formated");
        # my $data=$field->FormatedResult("html");
         if (ref($field->{onClick}) eq "CODE"){
            my $fc=&{$field->{onClick}}($self,$app);
            $fclick=$fc if ($fc ne "");
         }
         elsif (defined($field->{weblinkto}) && $field->{weblinkto} ne "none"){
            my $weblinkon=$field->{weblinkon};
            my $weblinkto=$field->{weblinkto};
            if (ref($weblinkto) eq "CODE"){
               ($weblinkto,$weblinkon)=&{$weblinkto}($field,$data,$rec);
            }

            if (defined($weblinkto) && 
                defined($weblinkon) && $weblinkto ne "none"){
               $weblinkname=$weblinkto;
               my $target=$weblinkto;
               $target=~s/::/\//g;
               $target="../../$target/Detail";
               my $targetid=$weblinkon->[1];
               my $targetval;
               if (!defined($targetid)){
                  $targetid=$weblinkon->[0];
                  $targetval=$d;
               }
               else{
                  my $linkfield=$self->getParent->getParent->
                                       getField($weblinkon->[0]);
                  if (!defined($linkfield)){
                     msg(ERROR,"can't find field '%s' in '%s'",$weblinkon->[0],
                         $self->getParent);
                     return($d);
                  }
                  $targetval=$linkfield->RawValue($rec);
               }
               if (defined($targetval) && $targetval ne ""){
                  my $detailx=$self->getParent->getParent->DetailX();
                  my $detaily=$self->getParent->getParent->DetailY();
                  $targetval=$targetval->[0] if (ref($targetval) eq "ARRAY");
                  $fclick="openwin(\"$target?".
                      "AllowClose=1&search_$targetid=$targetval\",".
                      "\"_blank\",".
                      "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                      "resizable=yes,scrollbars=no\")";
               }
            }
         }
         $fclick=undef if ($field->Type() eq "SubList");
         $fclick=undef if ($field->Type() eq "DynWebIcon");
         $fclick=undef if ($self->{nodetaillink});
         if (defined($fclick)){
            my $p=$self->getParent->getParent;
            $weblinkname=sprintf($p->T('klick to view &lt;%s&gt;'),
                         $p->T($weblinkname,$weblinkname));
         }
         else{
            $weblinkname="";
         }
      
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
      my $nowrap="";
      if (defined($field->{nowrap}) && $field->{nowrap}==1){
         $style.="white-space:nowrap;";
         $nowrap=" nowrap";
      }

      $style.="width:auto;" if ($c==$#view && !defined($field->{htmlwidth}));
      $d.="<td class=subdatafield valign=top $align";
      $d.=" onClick=$fclick" if ($fclick ne "");
      $data="&nbsp;" if ($data=~m/^\s*$/);
      $d.=" style=\"$style\"";
      $d.=" title=\"$weblinkname\"";
      $d.="$nowrap>".$data."</td>\n";
   }
   $d.="</tr>\n";
   $self->{lineclass}++;
   $self->{lineclass}=1 if ($self->{lineclass}>2);
   return($d);
}
sub ProcessBottom
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="</tbody></table></td></tr>\n\n\n";
   $d.="</table>\n";
   if ($self->{SubListEdit}==1){
      $d.=<<EOF;
<script language=JavaScript>
function SubListEdit(setid)
{
   var id=document.getElementById('CurrentIdToEdit');
   var nr=document.getElementById('NewRecSelected');
   if (id){
      id.value=setid;
      nr.value="1";
      document.forms[0].submit();
   }
}
</script>
EOF
   }
   if (defined($msg)){
      if (!$self->{DisableMsg}){
         $d.="<hr>msg=$msg<br>";
      }
   }
   $d.=$self->StoreQuery();
   if ($param->{ParentMode} ne "HtmlV01" && 
       $param->{ParentMode} ne "HtmlNative"){
      $d.="</div></td></tr></table>";
   }

   return($d);
}

sub StoreQuery
{
   my $self=shift;
   my $d="";
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



1;
