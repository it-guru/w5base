package kernel::MenuTree;
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
use vars qw(@ISA @EXPORT);
use UNIVERSAL;
use kernel;
use Exporter;
use XML::Smart;
@EXPORT=qw(&BuildHtmlTree);


sub BuildHtmlTree
{
   my %control=@_;
   # $control->{tree}     =Datenstruktur des Trees
   # $control->{rootpath} =rootpath/prefix vor den img tags
   # $control->{rootimg}  =name of the top image
   # $control->{showcomm} =if equals to 1, comments will be displayed
   #
   # tree->{prio}         = sortierreihenfolge
   # tree->{href}         = href link für den link
   # tree->{label}        = dargestellter text
   # tree->{target}       = target window
   # tree->{tree}         = array pointer auf untermenu

   $control{imgparam}=""             if (!defined($control{imgparam}));
   $control{rootpath}="../"          if (!defined($control{rootpath}));
   $control{rootimg}="miniglobe.gif" if (!defined($control{rootimg}));
   my $d="<div>";
   $d.=_ProcessTreeLayer(\%control,[$#{$control{tree}}+1],$control{tree});
   $d.="</div>"; # ent of id=MenuTree
   $d.="</div>";
  # $d.="<script language=JavaScript>tt_Init();</script>\n";
   return($d);
}



sub _TreeLine
{
   my $control=shift;
   my $indent=shift;
   my $id=shift;
   my $ment=shift;
   my $href;
   my $text;
   my $desc;
   my $comm = undef;
   my $d;

   if (defined($ment)){
      $href=$ment->{href};
      $text=$ment->{label};
      $desc=$ment->{description};
      $comm=$ment->{comments} if $control->{'showcomm'} == 1;
   }
   my $rootpath=$control->{rootpath};
   if ($id==0){
      if (defined($control->{rootlink})){
         $d.="<a href=$control->{rootlink}>";
      }
      my $onclick="";
      if (defined($control->{rootclick})){
         $onclick=" onClick=\"$control->{rootclick}\" ".
                  "style=\"cursor:pointer\" ";
      }
      $d.="<img border=0 id=rootimg alt=\"root\" $onclick".
          "src=\"${rootpath}../../base/load/$control->{rootimg}".
          "$control->{imgparam}\">";
      if (defined($control->{rootlink})){
         $d.="</a>";
      }
      $d.="<div id=MenuTree>";
   }
   else{
      my $markActive="";
      if ($ment->{active}){
         $markActive="id=\"activeMenuTree\" ";
      }
      $d.="<div ${markActive}style=\"border-style:none;border-width:1px;".
            "padding:0;margin:0;vertical-align:middle\">";
      $d.="<table width=\"100%\" border=0 cellspacing=0 cellpadding=0>";
      $d.="<tr><td valign=center width=1% nowrap>";
      for(my $c=1;$c<=$#{$indent};$c++){
         my $l=4;
         $l=1 if ($indent->[$c-1]>0);
         $d.="<img border=0 alt=\"+\" ".
             "src=\"${rootpath}../../base/load/menu_bar_$l.gif".
             "$control->{imgparam}\">";
      }
      my $imgname="menu_bar_${id}.gif";
      $d.="<img border=0 alt=\"+\" ".
          "src=\"${rootpath}../../base/load/$imgname".
          "$control->{imgparam}\">";
      $d.="</td><td valign=center>";
      my $hrefclass;
      if (defined($control->{hrefclass})){
         $hrefclass="$control->{hrefclass}";
      }
      if ($ment->{active}){
         $hrefclass.=" " if ($hrefclass ne "");
         $hrefclass.="activeMenuTreeEntry";
      }
      if ($hrefclass ne ""){
         $hrefclass=" class=\"$hrefclass\" ";
      }


      $d.=$ment->{labelprefix}  if (defined($ment->{labelprefix}));
      my $usehref="href=\"$href\"";
      $usehref="href=$href" if ($href=~m/^javascript:/i);

      my $contextM;
      if (defined($ment->{contextMenu})){
         $contextM=" cont=\"contextMenu_M$ment->{menuid}\" ";
      }
      my $target;
      if (defined($ment->{hreftarget}) && $ment->{hreftarget} ne ""){
         $target="target=\"$ment->{hreftarget}\"";
      }
      $d.="<div style=\"position:relative\">";
      if (defined($href)){
         $d.="<a $target $hrefclass $contextM title=\"$desc\n\" $usehref>";
      }
      $d.=$text  if (defined($text));
      $d.="</a>" if (defined($href));
      if (exists($control->{clipicon})){
         my $labelpath=$ment->{labelpath};
         $labelpath=~s/['"]//g;
         $d.="<div onclick=".
         "\"ClickOn_".$control->{clipicon}."(this,'$href','$labelpath');\" ".
         "class=\"".$control->{clipicon}."\"></div>\n";
      }
      $d.= ' ('.CGI::escapeHTML(limitlen($comm,30,1)).')' if ($comm ne '');

      $d.="</div>";

      $d.="</td></tr></table>";
      $d.="</div>\n";
      if (defined($ment->{contextMenu}) && 
          ref($ment->{contextMenu}) eq "ARRAY"){
         $d.=getHtmlContextMenu("M".$ment->{menuid},
                                @{$ment->{contextMenu}});
      }

   }
   return($d);
}

sub getHtmlContextMenu
{
   my $name=shift;
   my @contextMenu=@_;

   my $contextMenu;
   if ($#contextMenu!=-1){
      $contextMenu="<div id=\"contextMenu_$name\" "
                   ."class=\"context_menu\">";
      $contextMenu.="<table cellspacing=\"1\" cellpadding=\"2\" ".
                    "border=\"0\">";
      while(my $label=shift(@contextMenu)){
         my $link=shift(@contextMenu);
         $contextMenu.="\n<tr>";
         $contextMenu.="<td class=\"std\" ".
                       "onMouseOver=\"this.className='active';\" ".
                       "onMouseOut=\"this.className='std';\">";
         $contextMenu.="<div onMouseUp=\"$link\">$label</div>";
         $contextMenu.="</td></tr>";
      }
      $contextMenu.="\n</table>";
      $contextMenu.="</div>";
   }
   return($contextMenu);
}






sub _ProcessTreeLayer
{
   my $control=shift;
   my $layer=shift;
   my $menu=shift;
   my $d="";
   $d.=_TreeLine($control,$layer,0,undef) if ($#{$layer}==0);
   my @mlist=@{$menu};
   if (!exists($control->{treesort}) || $control->{treesort}==1){ 
      @mlist=sort({
                     my $bk;
                     if ($a->{prio}==$b->{prio}){
                        $bk=$a->{menuid}<=>$b->{menuid};
                     }
                     else{
                        $bk=$a->{prio}<=>$b->{prio};
                     }
                     $bk;
                  } @{$menu});
   }
   for(my $c=0;$c<=$#mlist;$c++){
      my $m=$mlist[$c];
      my $modid=2;
      if ($c==$#mlist){
         $modid=3;
         $layer->[$#{$layer}]=0;
      }
      $modid=6 if ($m->{active} && $modid==3);
      $modid=5 if ($m->{active} && $modid==2);
      my $mLine=_TreeLine($control,$layer,$modid,$m);
      $d.=$mLine;
      if (defined($m->{tree}) && $#{$m->{tree}}!=-1){
         $d.=_ProcessTreeLayer($control,[@$layer,$#{$m->{tree}}+1],
                               $m->{tree});
      }
   }
   return($d);
}

#####################################################################
#####################################################################
#####################################################################


######################################################################
1;
