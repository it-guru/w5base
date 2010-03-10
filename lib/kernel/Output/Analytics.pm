package kernel::Output::Analytics;
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
use kernel::Output::JSON;
@ISA    = qw(kernel::Output::JSON);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   return(1) if ($self->getParent->getParent->IsMemberOf("admin"));
   return(0);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xml.gif");
}
sub Label
{
   return("Output to W5Analytics");
}
sub Description
{
   return("Format as W5Analytics");
}

sub MimeType
{
   return("text/html");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".html");
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:".$self->MimeType()."; charset=UTF-8\n\n";
   return($d);
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
#   my $h=$self->SUPER::ProcessHead($fh,$rec,$msg);
   my $d;
#   $d.="<html>";
#   $d.="<head>";
#   $d.='<meta http-equiv="content-type" content="text/html; charset=UTF8">';
#   if (1){
#      $d.="<script type='text/javascript' ";
#      $d.="src='http://getfirebug.com/releases/lite/1.2/".
#          "firebug-lite-compressed.js'>";
#      $d.="</script>";
#   }
#   my @load="jquery.js";
#   foreach my $js (@load){
#      my $instdir=$self->getParent->getParent->Config->Param("INSTDIR");
#      my $filename=$instdir."/lib/javascript/".$js;
#      if (open(F,"<$filename")){
#         $d.="<script language=\"JavaScript\">\n";
#         $d.=join("",<F>);;
#         $d.="</script>\n";
#         close(F);
#      }
#   }
#   my @load=("default.css","work.css");
#   foreach my $css (@load){
#      my $filename=$self->getParent->getParent->getSkinFile(
#                   $self->getParent->getParent->Module."/css/".$css);
#      if (open(F,"<$filename")){
#         $d.="<style>\n";
#         $d.=join("",<F>);;
#         $d.="</style>\n";
#         close(F);
#      }
#   }
#
#
   $d.="<script language=\"JavaScript\">\n";
   my $app=$self->getParent->getParent();
   my $dataname=$app->Self();
   if (exists($self->{'AnalyticsDataName'})){
      $dataname=$self->{'AnalyticsDataName'};
   }
   $dataname=~s/::/_/g;
   $d.="$dataname={\n";
   return($d); 
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d="\n};\n";
   $d.="</script>\n";
#   $d.="<script language=\"JavaScript\">";
#   $d.=<<EOF;
#var res=document.W5Base.LastResult();
#
#// Pre Prozessor
#var u=new Array();
#for (i in res){
#  if (typeof(u[res[i].parentname])=="undefined"){
#     u[res[i].parentname]=0;
#  }
#  if (res[i].relevant!=null){
#     u[res[i].parentname]++;
#  }
#}
#
#// Output Prozessor
#var d="";
#d+="<table border=1>";
#for (i in u){
#  var col1="";
#  var col2="";
#  if (u[i]==0){
#     col1="<font color=red>";
#     col2="</font>";
#  }
#  d+="<tr><td>"+i+"</td><td>"+col1+u[i]+" Antworten"+col2+"</tr>";
#}
#d+="</table>";
#document.write(d);
#
#EOF
#   $d.="</script>";
#   $d.="</head>";
#   $d.="<body>";
#   $d.="</body>";
#   $d.="</html>";
   return($d);
}




1;
