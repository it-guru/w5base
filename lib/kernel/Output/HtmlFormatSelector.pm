package kernel::Output::HtmlFormatSelector;
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

sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d=$app->HttpHeader();
   $d.=$app->HtmlHeader();
   $d.="<title>".$app->T("Further Functions",$app->Self())."</title>";
   $d.="<body>";
   return($d);
}


sub getHttpHeader
{
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->HttpHeader("text/html");
   $d.=$app->HtmlHeader(style=>['default.css',
                                'Output.HtmlViewLine.css',
                                'Output.HtmlFormatSelector.css'],
                        title=>$app->T("Further Functions",$app->Self()),
                        body=>1,
                        );
   return($d);
}


sub getStyle
{
   my ($self,$fh)=@_;
   my $d="";
   return($d);
}

sub isRecordHandler
{
   return(0);
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;

   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $dest=$app->Self();
   $dest=~s/::/\//g;
   $dest="../../$dest/Result";

   my $d="";
   $d.="<form method=post><style>";
   $d.=$self->getStyle($fh);
   $d.="</style>\n\n";
   $d.="<script language=JavaScript ".
         "src=\"../../../public/base/load/toolbox.js\"></script>\n";
   $d.="<script language=JavaScript ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n";
   $d.="<table id=viewline class=maintable>\n";
   $d.=$self->getHtmlViewLine($fh,$dest);

   $d.="<tr><td class=mainblock>";
   $d.="<table  class=datatable width=\"100%\">\n".
       "<tr class=headline>";
   $d.="<th colspan=2 class=headfield height=1%>".
       $self->getParent->getParent->T("Select method to use on selected data").
       " ...</th></tr>\n";
   $d.="</table>";
   $d.="</table>";
   return($d);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $outputhandler=$self->getParent();
   my $d="<div style=\"padding:2px;padding-bottom:0px\"><div id=FormatSelector ".
         "style=\"overflow:auto;height:100px;".
         "border-style:solid;border-width:1px\">";
   if (!defined($self->Cache->{OutputHandlerCache})){
      $self->Cache->{OutputHandlerCache}={};
      my $instdir=$app->Config->Param("INSTDIR");
      my $handlerdir=$instdir."/lib/kernel/Output";
      if (opendir(DH,$handlerdir)){
         my @mods=grep({ -f "$handlerdir/$_" &&
                         $_=~m/\.pm$/ &&
                         !($_=~m/^\./) } readdir(DH));
         @mods=map({$_=~s/\.pm$//;$_} @mods);
         
         foreach my $f (@mods){
            my $o;
            eval("use kernel::Output::$f;".
                 "\$o=new kernel::Output::$f(\$outputhandler,{});");
            if ($@ ne ""){
               msg(ERROR,"can't use module '%s'","kernel::Output::".$f);
               printf STDERR ("%s\n",$@);
               next;
            }
            if (!defined($o)){
               msg(ERROR,"can't $o create object of '%s'","kernel::Output::".$f);
               next;
            }
            $o->setParent($self->getParent());
            my %env=(mode=>'Init');
            if ($o->IsModuleSelectable(%env)){
               $self->Cache->{OutputHandlerCache}->{$f}=$o;
            }
         }
         closedir(DH);
      }
   }
   my %env=(mode=>'Output');
   if (exists($self->{currentFrontendFilter})){
      $env{'currentFrontendFilter'}=$self->{currentFrontendFilter};
   }
   if (exists($self->{currentFrontendOrder})){
      $env{'currentFrontendOrder'}=$self->{currentFrontendOrder};
   }
   my @operator=();
   foreach my $o ($self->getParent->getParent->getOperator()){
      $o->setParent($self->getParent());
      if ($o->IsModuleSelectable(%env)){
         my %rec=();
         $rec{download}=0;
         $rec{function}="InitWorkflow";
         $rec{name}=$o->Name();
         $rec{prio}=$o->FormaterOrderPrio();
         $rec{icon}=$o->getRecordImageUrl();
         $rec{mimetype}=$o->MimeType();
         $rec{label}=$self->getParent->getParent->T($o->Label(),$o->Self());
         $rec{description}=$self->getParent->getParent->T($o->Description(),
                                                          $o->Self());
         push(@operator,\%rec);
      }
   }
   my %workoutput=();
   foreach my $f (keys(%{$self->Cache->{OutputHandlerCache}})){
      my $o=$self->Cache->{OutputHandlerCache}->{$f};
      $o->setParent($self->getParent());
      if ($o->IsModuleSelectable(%env)){
         my %rec=();
         $rec{download}=$o->IsModuleDownloadable(%env);
         $rec{prio}=$o->FormaterOrderPrio();
         $rec{directlink}=$o->IsDirectLink();
         if ($o->forceDownloadAsAttachment()){
            $rec{function}="DirectDownload";
         }
         else{
            $rec{function}="doDirectView";
         }
         $rec{name}=$f;
         $rec{icon}=$o->getRecordImageUrl();
         $rec{mimetype}=$o->MimeType();
         $rec{label}=$self->getParent->getParent->T($o->Label(),$o->Self());
         $rec{description}=$self->getParent->getParent->T($o->Description(),
                                                          $o->Self());
         $workoutput{$f}=\%rec;
      }
   }

   my @formaterList=(values(%workoutput),@operator);

   @formaterList=sort({
      my $bk=$a->{prio} <=> $b->{prio};
      if ($bk eq "0"){
         $bk=$a->{name} cmp $b->{name};
      }
      return($bk);
   } @formaterList);



   foreach my $frec (@formaterList){
      my $t1=$app->T("show the selected data in browser (if it is posible)");
      my $lstart="";
      my $lend="";

      if ($frec->{directlink}){
         $lstart="<a href=JavaScript:".
                 "$frec->{function}(this,\"$frec->{name}\") ".
                 "title=\"$t1\">";
         $lstart="<a onclick='".
                 "$frec->{function}(this,\"$frec->{name}\")' ".
                 "title=\"$t1\"  style='cursor:pointer'>";
         $lend="</a>";
      }
      $d.=<<EOF;
<div style="padding:4px;
            margin:5px;
            width:230px;
            height:70px;
            border-style:solid;
            float:left;
            border-width:1px;">
<table width="100%" cellspacing=0 cellpadding=0 border=0>
<tr>
<td width=1% valign=top>${lstart}
<img alt="format icon $frec->{name}" 
     src="$frec->{icon}" border=0 style="margin-right:5px;">${lend}
</td>
<td valign=top>

<table width="100%" border=0 cellspacing=0 cellpadding=0>
<tr>

<td><b><u>$frec->{label}</u></b></td>
<td width=1% nowrap>
EOF
    #$d.=<<EOF if ($frec->{download});



    if ($frec->{download}){
       my $t1=$app->T("create a direct access url for the current data").': '.
              $frec->{label};
       my $t2=$app->T("download the selected data as offline file").': '.
              $frec->{label};
       my $directDownload="<a onclick='DirectDownload(this,\"$frec->{name}\",".
                  "\"DirectView\")' style='cursor:pointer' ".
                  "title=\"$t2\">".
                  "<img border=0 alt=\"download\" ".
                  "src=\"../../../public/base/load/download_mini.gif\"></a>";
       if (!$frec->{directlink}){
          $directDownload="";
       }
       $d.=<<EOF;
<a style='cursor:pointer' onclick='ShowUrl("$frec->{name}")' title="$t1"><img border=0 alt="anker" src="../../../public/base/load/anker.gif"></a>&nbsp;
$directDownload
EOF
    }
    else{
       $d.=<<EOF;
<img border=0 alt="spacer" src="../../../public/base/load/empty.gif" 
     width=16 height=16>
EOF
    }
    $d.=<<EOF
</td>
</tr>
<tr>
<td colspan=2><div style="height:45px;overflow:auto;">$frec->{description}</div></td>
</tr>
</table>

</td>
</tr>
</table>
</div>
EOF
   }
   $d.="</div></div>";
#$d.="<xmp>".Dumper(\%ENV)."</xmp>";
#   $d.="</td>";
   return($d);
}
sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $title=$app->T("DirectView");
#   $d.="<td valign=center align=left style=\"padding:5px\">";
   my $d.=<<EOF;
<div style=\"padding:2px;padding-bottom:0px;padding-top:0px\">
<div id=DirectViewFrame style="border-style:solid;height:20px;
                               visibility:hidden;display:block;
                               margin:0px;padding:0px;border-width:1px">
   <div id=DirectViewTitleBar class=TitleBar>$title</div>
   <div class=DirectViewDiv 
        id=DirectViewDiv style="border-style:solid;
                                margin:0px;padding:0px;
                                border-width:0px;">
      <iframe id=DirectView src="../../base/load/empty" scrolling="auto" 
              frameborder="0" allowtransparency="true" xid="popupFrame" 
              name="DirectView" 
              style="height:100%;width:100%;
              background-color:transparent;
              margin:0px;
              padding:0px" scrolling="auto">
      </iframe>
   </div>
</div>
</div>
EOF

  # solte eingentlich nicht mehr notwendig sein, da die Query immer
  # auf dem Parent ausgeführt wird.
  # Query->Param("UseLimit"=>0);
  # $d.=$self->HtmlStoreQuery();
  # $d.="<input type=hidden id=WorkflowName name=WorkflowName value=\"\">";
   $d.="</form>";

   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $d="";
   $d.="</body>";
$d.=<<EOF;
<script language="JavaScript">
var directvisible=0;
function setViewFrame(flag)
{
   directvisible=flag;
   var DirectViewFrame=document.getElementById("DirectViewFrame");
   if (directvisible){
      DirectViewFrame.style.visibility="visible";
      DirectViewFrame.style.display="block";
   }
   else{
      DirectViewFrame.style.visibility="hidden";
      DirectViewFrame.style.display="none";
   }
   FormaterResize();
}
function FormaterResize()
{
   var h=getViewportHeight();
   var viewline=document.getElementById("viewline");
   var fo=document.getElementById("FormatSelector");
   var DirectViewFrame=document.getElementById("DirectViewFrame");
   var DirectView=document.getElementById("DirectView");
   var DirectViewTitleBar=document.getElementById("DirectViewTitleBar");
   h=h-viewline.offsetHeight-20;
   if (directvisible==1){
      fo.style.height=h/3;
      DirectViewFrame.style.height=h/3*2;
      DirectView.style.height=(h/3*2)-DirectViewTitleBar.offsetHeight-5;
      DirectView.style.width=DirectViewTitleBar.offsetWidth-4;
      fo.style.width=DirectViewTitleBar.offsetWidth;
   }
   else{
      fo.style.height=h;
      DirectViewFrame.style.visibility="hidden";
      DirectViewFrame.style.display="none";
   }
}
function FormaterInit()
{
   FormaterResize();
}
addEvent(window, "resize", FormaterResize);
addEvent(window, "load",   FormaterInit);
</script>
EOF
   $d.="</html>";
   return($d);
}



1;
