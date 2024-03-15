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
   $d.="<table width=\"100%\" height=\"100%\" border=0 ".
       "cellspacing=0 cellpadding=0>";
   my @ml;
   my %pages=@{$param{pages}};
   my @plist=@{$param{pages}};
   my @pklist;
   foreach my $p (@{$param{pages}}){
      push(@pklist,shift(@plist));
      shift(@plist);
   }
   my %keyFuncs=();
   my $CurMode=$param{activpage};
   my $c=0;
   foreach my $f (@pklist){
      $c++;
      if (grep(/^$f$/,keys(%pages))){
         $CurMode=$f if (!defined($param{activpage}) || 
                         $param{activpage} eq "");
         my $state="Inactiv";
         $state="Activ" if ($CurMode eq $f);
         $keyFuncs{"${c}"}=$f;
         my $flabel=$pages{${f}};
         my $c1st=substr($flabel,0,1);
         my $lower1st=lc($c1st);
         if (!exists($keyFuncs{$lower1st})){
            $keyFuncs{"${lower1st}"}=$f;
            $flabel=~s#${c1st}#<u>${c1st}</u>#;
         }
         my $flink="<span ".
                   " class=${name}$state ".
                   "onclick=${name}Set(\"$f\")>".
                   "${flabel}".
                   "<span aria-hidden=\"true\">&nbsp;&nbsp;&nbsp;".
                   "</span></span>";
         my $width=" width=1% nowrap";
         if (defined($param{tabwidth})){
            $width=" width=$param{tabwidth}";
         }
         my $tabClass="${name}$state";
         if ($state ne "Activ" ||$c>1){
            $tabClass.=" hideOnMobile";
         }
         push(@ml,"<td class=\"$tabClass\"$width>$flink ".
                  "<span class=aria-only>".
                  "shortcut:<br>Alt plus $c1st<br></span></td>");
      }
   }
   my $ml="<td class=${name}Sep>".
          "<span aria-hidden=\"true\">&nbsp;</span></td>".
          join("<td class=${name}Sep>".
               "<span aria-hidden=\"true\">&nbsp;</span></td>",@ml);
   $ml.="<td class=${name}Fillup>".
        "<span aria-hidden=\"true\">&nbsp;</span></td>";
   $ml="<table id=$name class=${name} cellspacing=0 cellpadding=0 border=0>".
       "<tr>$ml</tr></table>";
   my $ht="<table id=$name width=\"100%\" border=0 ".
          "cellspacing=0 cellpadding=0>";
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
      my $c=0;
      my $fl=join(" <span class=hideOnMobile>&bull;</span> ",map({
         my $fclass="${name}FunctionLink";
         if ($c!=$#labels){
            $fclass.=" hideOnMobile";
         }
         $c++;
         my $f="<a class=\"$fclass\" href=JavaScript:$functions{$_}()>".
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
   if (keys(%keyFuncs)){
      $d.="\n<script language=\"JavaScript\">\n";
      $d.="function directTabKeyHandling(doc,e){\n";
      $d.="var key=e.keyCode;\n";
      $d.="key=(96 <= key && key <= 105)? key-48 : key;\n";
      foreach my $k (sort(keys(%keyFuncs))){
         $d.="if (e.altKey && ".
             "String.fromCharCode(key).toLowerCase()==\"$k\"){\n";
            $d.="${name}Set(\"$keyFuncs{$k}\");\n";
         $d.="}\n";
      } 
      $d.="}\n";
      $d.="\n</script>\n";

   }
   return($d);
}






