package kernel::Output::HtmlGraphics;
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
use kernel::Formater;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   return($self);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_html.gif");
}


sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;
 
   return(1) if ($param{mode} eq "Init");
   return(1) if ($self->getParent()->getParent->can("HtmlGraphics"));
   return(0);
}



sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.="Content-type:text/html\n\n";
   $d.="<html>";
   $d.="<body><div id=HtmlDetail><form>";
   return($d);
}

sub Init
{
   my ($self,$fh)=@_;
   $self->{OutputCount}=0;
   return();
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".html");
}







sub ProcessHead
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my $d="";
   if ($self->{OutputCount}){
      my @load=qw(toolbox.js wz_jsgraphics.js);
	      my @cssload=qw(default.css work.css Output.HtmlDetail.css 
                             kernel.App.Web.css);
      if ($self->{WindowMode} eq "Detail"){
         foreach my $js (@load){
            $d.="<script language=JavaScript ".
                "src=\"../../../public/base/load/$js\"></script>";
         }
         foreach my $css (@cssload){
            $d.="<link rel=stylesheet type=\"text/css\" ".
                "href=\"../../../public/base/load/$css\">".
                "</link>\n";
         }
      }
      else{
         foreach my $js (@load){
            my $instdir=$self->getParent->getParent->Config->Param("INSTDIR");
            my $filename=$instdir."/lib/javascript/".$js;
            if (open(F,"<$filename")){
               $d.="<script language=\"JavaScript\">\n";
               $d.=join("",<F>);;
               $d.="</script>\n";
               close(F);
            }
         }
      }
   }
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
   $self->{lineclass}=1 if (!exists($self->{lineclass}));
   my $d="";
   my $lineclass="line".$self->{lineclass};
   my $lineonclick;
   my $idfield=$app->IdField();
   my $idfieldname=undef;
   my $id=undef;
   if (defined($idfield)){
      $idfieldname=$idfield->Name() if (defined($idfield));
      $id=$idfield->RawValue($rec);
   }
   if (defined($idfieldname) && $id ne ""){
      my $jid="GraphicsContext$id";
      my ($x,$y,$js)=$self->getParent->getParent->HtmlGraphics($rec,$jid,
                                                            $viewgroups,
                                                            $fieldbase,
                                                            $self->{WindowMode},
                                                            $lineno);
      if ($js ne ""){
         my $tstyle="";
         $tstyle="page-break-before:always;" if ($self->{OutputCount});
         $tstyle.="width:100%;";
         $tstyle.="height:100%;" if ($self->{WindowMode} eq "Detail");
         if ($self->{WindowMode} ne "Detail"){
            $tstyle.="border-style:solid;border-width:1px;";
         }
         $d="<table style=\"$tstyle\"><tr>".
            "<td valign=center align=center>".
            "<div id=\"$jid\" style=\"position:relative;width:${x}px;".
            "height:${y}px;\">$js</div>".
            "</td></tr></table>";
         $self->{OutputCount}++;
      }
   }
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="";
   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $d="";
   $d.="</form>";
   $d.="</div>";
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
