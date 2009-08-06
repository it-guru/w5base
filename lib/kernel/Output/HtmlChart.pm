package kernel::Output::HtmlChart;
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

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_chart.gif");
}



sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;
 
   return(1) if ($param{mode} eq "Init"); 
   my $app=$self->getParent()->getParent;
   my @l=$app->getCurrentView();
   if ($#l>0){
      return(1);
   }
   return(0);
}
sub Label
{
   return("HtmlChart");
}
sub Description
{
   return("Creates a simple chart from selected data");
}

sub MimeType
{
   return("text/html");
}

sub getEmpty
{
   my $self=shift;
   my %param=@_;
   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   return($d);
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".html");
}

sub getHttpHeader
{  
   my $self=shift;
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=iso-8859-1\n\n";
   return($d);
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $d;
   my @cell=();
   foreach my $fo (@{$recordview}){
      my $name=$fo->Name();
      my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   fieldbase=>$fieldbase,
                                   current=>$rec,
                                   mode=>$self->modeName(),
                                  },$name,"formated");
      $cell[$self->{fieldkeys}->{$name}]=$data;
   }
   push(@{$self->{recordlist}},$rec);
   return(undef);
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $instdir=$app->Config->Param("INSTDIR");
   my @view;
   if (ref($self->{fieldobjects}) eq "ARRAY"){
      @view=@{$self->{fieldobjects}};
   }
   my $d="";
   my $lev1=shift(@view);
   my $labels="";
   my $labelAlign="";
   my @labels;
   my $values="";
   my @values;
   my $legend="";
   my @legend;
   
   my @js=("$instdir/lib/javascript/HtmlGraph.js");
   if (!(-r $js[0])){
      return("no HtmlGraph.js installed");
   }
   $d.="<script>";

   foreach my $js (@js){
      if (open(F,"<$js")){
         $d.=join("",<F>);
         close(F);
      }
   }
   $d.="</script>";
   foreach my $fobj (@view){
      my $v=$fobj->Label();
      $labelAlign=$fobj->{align};
      push(@legend,$v);
   }
   for(my $recno=0;$recno<=$#{$self->{recordlist}};$recno++){
      my $rec=$self->{recordlist}->[$recno];
      my $v=$lev1->FormatedResult($rec,"HtmlChart");
      push(@labels,$v);
      my @subvalue;
      foreach my $fobj (@view){
         my $v=$fobj->FormatedResult($rec,"HtmlChart");
         push(@subvalue,$v);
      }
      push(@values,join(";",@subvalue));
   }
   $labels=join(",",@labels);
   $values=join(",",@values);
   $legend=join(",",@legend);


   $d.=<<EOF;
<style>
div.button{
   background:silver;
   cursor: pointer;
   cursor: hand;
   border-color:gray;
   border-width:3px;
   border-style:outset;
   padding:2px;
   margin:4px;
   width:100px;
   text-align:center;
   font-family:Arial,Adobe Helvetica,Helvetica;
   font-size:12px;
   text-decoration:none;
}
div.graphDiv{
   margin:3px;
}
\@media print{
   div.HtmlChartMenu{
      display:none;
      visiblity:hidden;
   }
}
</style>
<script language="JavaScript">

function mkBar(o)
{
   var graph;
   var graphDiv=document.getElementById("graphDiv");

   if (o=="hBar"){
      graph = new BAR_GRAPH("hBar");
   }
   else{
      if (o.id=="vBarButton"){
         graph = new BAR_GRAPH("vBar");
      }
      if (o.id=="hBarButton"){
         graph = new BAR_GRAPH("hBar");
      }
   }
   graph.labels = "$labels";
   graph.labelAlign = "$labelAlign";
   graph.values = "$values";
   graph.legend = "$legend";
   graph.showValues = 2;
   graphDiv.innerHTML=graph.create();
   
}
function doPrint(o)
{
   window.focus();
   window.print();
}
window.setTimeout("mkBar('hBar');",10);
</script>
<div class="HtmlChartMenu" id=Menu>
<table border=0 cellspacing=0 cellpadding=0>
<tr>
<td><div class=button id=vBarButton onclick=mkBar(this)>verticalBar</div></td>
<td><div class=button id=hBarButton onclick=mkBar(this)>horizontalBar</div></td>
<td><div class=button id=Print onclick=doPrint(this)>Print</div></td>
</tr>
</table>
</div>
<div class=graphDiv id=graphDiv></div>
EOF
   return($d);
}

1;
