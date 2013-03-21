package kernel::Field::TimeSpans;
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
   my $self={@_};
   $self->{valign}="top"     if (!defined($self->{valign}));
   my $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $name=$self->Name();
   my $app=$self->getParent();
   return({}) if (!exists($newrec->{$name}));

   my $newval=$newrec->{$name};
   if (!ref($newval) && 
       ($newval=~m/^0\(.*1\(.*2\(.*3\(.*4\(.*5\(.*6\(.*7\(.*\)$/)){
      my @deparse=();
      while(my ($t,$v)=$newval=~m/^\+{0,1}(\d)\(([^\)]*?)\)/){
         if ($t>=0 && $t<=7){
            $deparse[$t]=$v;
         }
         $newval=~s/^\+{0,1}\d\([^\)]*?\)//;
      }
      $newval=\@deparse;

   }
   $newval=[$newval] if (ref($newval) ne "ARRAY");
   my $newstring="";
   for(my $day=0;$day<=$#{$newval};$day++){
      $newval->[$day]=~s/[\(\)\s\+]//g;
      my @times;
      my @chk;
      foreach my $t (split(/[,;]/,$newval->[$day])){
         if ($t ne ""){
            my ($h1,$m1,$h2,$m2)=$t=~m/^(\d+):(\d+)-(\d+):(\d+)$/;
            if (!defined($h1) || !defined($m2)){
               my $msg=sprintf($app->T("invalid timespan format '%s' - ".
                          "use f.e. 10:00-11:00, 15:00-18:30"),$t);
               $self->getParent->LastMsg(ERROR,$msg);
               return(undef);
            }
            if (($h1*60+$m1>=$h2*60+$m2) ||
                ($h1<0) || ($h1>23) || ($m1<0) || ($m1>59) ||
                ($h2<0) || ($h2>23) || ($m2<0) || ($m2>59)){
               my $msg=sprintf($app->T("range missmismatch '%s'"),$t);
               $self->getParent->LastMsg(ERROR,$msg);
               return(undef);
            }
            foreach my $c (@chk){
               if (($c->[0]<$h1*60+$m1 && $c->[1]>$h1*60+$m1) ||
                   ($c->[0]<$h2*60+$m2 && $c->[1]>$h2*60+$m2)){
                  my $msg=sprintf($app->T("overlap range '%s'"),$t);
                  $self->getParent->LastMsg(ERROR,$msg);
                  return(undef);
               }
            }
            push(@chk,[$h1*60+$m1,$h2*60+$m2]);
            push(@times,sprintf("%02d:%02d-%02d:%02d",$h1,$m1,$h2,$m2));
         }
      }
      $newval->[$day]=join(", ",sort(@times));
      $newstring.="+" if ($newstring ne "");
      $newstring.="$day($newval->[$day])";
   }

   return({$name=>$newstring});
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

#   if (($mode eq "edit" || $mode eq "workflow") && !defined($self->{vjointo})){
#      $d=join($self->{vjoinconcat},@$d) if (ref($d) eq "ARRAY");
#      my $readonly=0;
#      if ($self->{readonly}==1){
#         $readonly=1;
#      }
#      if ($self->{frontreadonly}==1){
#         $readonly=1;
#      }
#      my $fromquery=Query->Param("Formated_$name");
#      if (defined($fromquery)){
#         $d=$fromquery;
#      }
#      return($self->getSimpleInputField($d,$readonly));
#   }
#   $d=[$d] if (ref($d) ne "ARRAY");
#   if ($mode eq "HtmlDetail"){
#      $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} @{$d})];
#   }
#   if ($mode eq "HtmlV01"){
#      $d=[map({quoteHtml($_)} @{$d})];
#   }
#   my $vjoinconcat=$self->{vjoinconcat};
#   $vjoinconcat="; " if (!defined($vjoinconcat));
#   $d=join($vjoinconcat,@$d);
#   $d.=" ".$self->{unit} if ($d ne "" && $mode eq "HtmlDetail");
   if ($mode eq "HtmlDetail" || $mode eq "edit"){
      my $tab="<table border=1 width=100% height=100%>";
      $tab.="<tr><td>&nbsp;</td><td width=200>";
      $tab.="<table width=100% border=0 cellspacing=0 cellpadding=0><tr>";
      $tab.="<td align=left width=10%>0h</td>";
      $tab.="<td align=center width=25%>6h</td>";
      $tab.="<td align=center width=25%>12h</td>";
      $tab.="<td align=center width=25%>18h</td>";
      $tab.="<td align=right>24h</td>";
      $tab.="</tr></table></td>";
      $tab.="<td>&nbsp;</td></tr>";
      my @days=qw(sun mon tue wed thu fri sat HOL);
      my @blocks=split(/\+/,$d);
      my @fval;
      foreach my $blk (@blocks){
         if (my ($n,$d)=$blk=~m/^(\d+)\((.*)\)$/){
            $fval[$n]=$d;
         }
      }
      
      for(my $dayno=0;$dayno<=$#days;$dayno++){
         my $day=$self->getParent->T($days[$dayno],$self->Self());
         if ($dayno!=7){
            $day="<b>$day</b>";
         }
         $tab.="<tr><td width=1%>$day</td><td with=200>";
         if ($mode ne "edit"){
            my @blks=();
            foreach my $b (split(/,/,$fval[$dayno])){
               if (my ($starth,$startm,$endh,$endm)=$b=~
                       m/^\s*(\d+):(\d+)-(\d+):(\d+)\s*$/){
                  my $sp=(($starth*60)+$startm)*100/1440;
                  my $ep=(($endh*60)+$endm)*100/1440;
                  push(@blks,[$sp,$ep]);
               }
            }
            @blks=sort({$a->[0]<=>$b->[0]} @blks);
            map({$_->[0]=int($_->[0]);$_->[1]=int($_->[1]);
                 $_->[2]="on";} @blks);
            my @blanks;
            for(my $blk=1;$blk<=$#blks;$blk++){
               if ($blks[$blk-1]->[1]!=$blks[$blk]->[0]){
                  push(@blanks,[$blks[$blk-1]->[1],$blks[$blk]->[0],"off"]);
               }
            }
            if ($#blks>=0){
               if ($blks[0]->[0]!=0){
                  push(@blanks,[0,$blks[0]->[0],"off"]);
               }
               if ($blks[$#blks]->[1]!=100){
                  push(@blanks,[$blks[$#blks]->[1],100,"off"]);
               }
            }
            else{
               push(@blanks,[0,100,"off"]);
            }
            push(@blks,@blanks);
            @blks=sort({$a->[0]<=>$b->[0]} @blks);
            my $seg=0;
            foreach my $blk (@blks){
               my $w=$blk->[1]-$blk->[0];
               my $color="transparent";
               $color="blue" if ($blk->[2] eq "on");
               $tab.="<div id=\"$name.$dayno.$seg\" style=\"background:$color;".
                     "width:$w\%;height:18px;float:left;".
                     "border-style:none;padding:0px;margin:0px\">";
               if ($color ne "transparent"){
                  $tab.="<div style=\"border-style:solid;border-width:1px;".
                        "height:16px;padding:0px;margin:0px;".
                        "border-color:$color\">\n</div>";
               }
               else{
                  $tab.="&nbsp;";
               }
               $tab.="</div>";
               $seg++;
            }
         }
         else{
            $tab.="&nbsp;";
         }
         my $dis="";
         $dis=" disabled " if ($mode ne "edit");
         my $val=$fval[$dayno];
         my @fromquery=Query->Param($name);
         if ($mode eq "edit" && defined($fromquery[$dayno])){
            $val=$fromquery[$dayno];
         }
         $tab.="</td>".
               "<td><input name=$name $dis type=text value=\"$val\" ".
               "style=\"width:100%\"></td></tr>";
      }
      $tab.="</table><br>";
      $d=$tab;
   }
   return($d);
}





1;
