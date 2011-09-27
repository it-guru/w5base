package kernel::TabSelector;
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
use vars qw(@EXPORT @ISA);
use kernel;
use Data::Dumper;
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&TabSelectorTool 
             );


sub TabSelectorTool
{
   my $name=shift;
   my %param=@_;
   my $d=<<EOF;
<script language="JavaScript">
function ${name}Set(v)
{ 
  if (this.TabChangeCheck){
     if (!TabChangeCheck()){
        return;
     }
  }

  document.forms[0].elements['${name}CurrentMode'].value=v;
  document.forms[0].submit(); }
</script>
EOF
   $d.="<div id=TabSelector$name class=TabSelector$name>";
   $d.="<table width=100% height=100% border=0 cellspacing=0 cellpadding=0>";
   my @ml;
   my %pages=@{$param{pages}};
   my @plist=@{$param{pages}};
   my @pklist;
   foreach my $p (@{$param{pages}}){
      push(@pklist,shift(@plist));
      shift(@plist);
   }
   my $CurMode=$param{activpage};
   foreach my $f (@pklist){
      if (grep(/^$f$/,keys(%pages))){
         $CurMode=$f if (!defined($param{activpage}) || 
                         $param{activpage} eq "");
         my $state="Inactiv";
         $state="Activ" if ($CurMode eq $f);
         my $flink="<span class=${name}$state ".
                   "onclick=${name}Set(\"$f\")>".
                   "$pages{${f}}&nbsp;&nbsp;&nbsp;</span>";
         my $width=" width=1% nowrap";
         if (defined($param{tabwidth})){
            $width=" width=$param{tabwidth}";
         }
         push(@ml,"<td class=${name}$state$width>$flink</td>");
      }
   }
   my $ml="<td class=${name}Sep>&nbsp;</td>".
          join("<td class=${name}Sep>&nbsp;</td>",@ml);
   $ml.="<td class=${name}Fillup>&nbsp;</td>";
   $ml="<table id=$name class=${name} cellspacing=0 cellpadding=0 border=0>".
       "<tr>$ml</tr></table>";
   my $ht="<table id=$name width=100% border=0 cellspacing=0 cellpadding=0>";
   if (defined($param{topline})){
      $ht.=sprintf("<tr><td height=1%%>%s</td></tr>",$param{topline});
   }
   my $actionbox="";
   if (defined($param{actionbox})){
      $actionbox=$param{actionbox};
   }
   if (defined($param{functions})){
      my %functions={};
      my @labels=();
      my @f=@{$param{functions}};
      for(my $c=0;$c<=$#{$param{functions}}/2;$c++){
         my $l=shift(@f);
         my $f=shift(@f);
         $functions{$l}=$f;
         push(@labels,$l);
      }
      my $fl=join(" &bull; ",map({
         my $f="<a class=${name}FunctionLink href=JavaScript:$functions{$_}()>".
               $_."</a>";
         $f;
      } @labels));
      $ht.=sprintf("<tr><td align=left valign=top>".
                   "<div class=TabActionBox>%s</div>".
                   "</td><td height=1%% valign=top align=right>".
                   "%s &nbsp;</td></tr>",$actionbox,$fl);
   }

   $ht.="<tr><td colspan=2 height=1%%>".$ml."</td></tr>";
   $ht.="</table>"; 
   $d.="<tr><td height=1%%>".$ht."</td></tr>";
   $d.="<tr><td align=center valign=top class=${name}PageArea>".$param{page}.
       "</td></tr></table>";
   $d.="<input type=hidden name=${name}CurrentMode value=\"$CurMode\">";
   $d.="</div>";
   return($d);
}






