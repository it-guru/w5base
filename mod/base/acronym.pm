#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $length=6;
my $name="operational framework";
my (@letters,$char,$acros);
my $word=1;
my $ipos=0;
for (my $s=0;$s<length($name);$s++){
   my $tmpchr=substr($name,$s,1);
   if ($tmpchr=~m/ /){
      $word++;
   }else{
      my $rest=substr($name,$s+1,length($name)-$s);
      $char={'char'=>$tmpchr,
             'word'=>$word,
             'rest'=>$rest,
             'pos'=>$ipos};
      push(@letters,$char);
      $ipos++; 
   }
}
for (my $a=0;$a<$#letters+2-$length;$a++){
printf ("fifi hauptschleife_1 a=$a letter=$#letters length=$length le=%s\n",$#letters-2-$length);
   if ($a == $#letters+1-$length){
      my $lastword;
      for (my $y=0;$y<$length;$y++){ 
         $lastword=$lastword.$letters[$a+$y]->{'char'};
      }
printf ("fifi hauptschleife if a=$a lastword=$lastword\n");
      push(@$acros,{$lastword=>''}); 
      next;
   }
   my ($rstr,$rpos)=calcstr1("",$a);
#   printf ("FIFI rstr=$rstr rpos=$rpos\n");
#  my ($rstr2,$rpos2)=calcstr2($rstr,$rpos);
#   printf ("FIFI aufruf calc3 rstr=$rstr2 rpos=%s\n",$rpos2);
#   my ($rstr3,$rpos3)=calcstr3($rstr2,$rpos2-1);
   for (my $l=2;$l<$length;$l++){
printf ("fifi schleife funktionsaufruf level=$l rstr=$rstr rpos=$rpos letters=$#letters\n");
#$rpos=4 if ($l==3);
      ($rstr)=calcstr($rstr,$rpos,$l);
printf ("fifi schleife returncode level=$l rstr=$rstr rpos=$rpos letters=$#letters\n");
   }   
}

printf ("FIFI data=%s\n",Dumper($acros));
printf ("FIFI countarray=%s\n",$#{$acros});

sub calcstr
{
   my $str=shift;
   my $pos=shift;
   my $level=shift;
#printf ("fifi calcstr level=$level str=$str pos=$pos\n");
   my $newstr=substr($str,0,length($str)-$level);
printf ("fifi calcstr eingangsparameter str=$str newstr=$newstr pos=$pos level=$level\n");
   my $posnew=$pos;
printf ("fifi calcstr pos=%s level=$level\n",$posnew-$level+1);
   while (length($newstr) < $length){
      if ($#letters >= $posnew-$level+1){
         $newstr=$newstr.$letters[$posnew-$level+1]->{'char'};
         $posnew++;
      }else{
         last;
      }
   }
#   $newstr=substr($newstr,0,$length);
printf ("fifi calcstr newstr=$newstr level=$level\n");
#printf ("fifi calcstr3 funktionsaufruf newstr=$newstr pos=$pos str=$str\n");
   if ($pos < $#letters){
      if ($level == 2){
         calcstr(calcstr1($newstr,$pos),$level);
      }else{
#printf ("fifi calcstr level3 newstr=$newstr, pos=$pos, level=$level\n");
#printf ("FIFI data=%s\n",Dumper($acros));
         calcstr(calcstr($newstr,$pos,$level-1),$level); 
      }
   }elsif($pos == $#letters){
      if ($level == 2){
         calcstr1($newstr,$pos);
      }else{
printf ("fifi calcstr newstr=$newstr pos=$pos level=%s\n",$level-1);
         calcstr($newstr,$pos,$level-1);
      }
   }
   return($str,$pos+1);
}

sub calcstr3
{
   my $str=shift;
   my $pos=shift;
   my $newstr=substr($str,0,length($str)-3);
#printf ("fifi calc3 eingangsparameter str=$str newstr=$newstr pos=$pos\n");
   my $posnew=$pos;
   while (length($newstr) < $length){
      if ($letters[$posnew-2]->{'char'}){
         $newstr=$newstr.$letters[$posnew-2]->{'char'};
         $posnew++;
      }
   }
   $newstr=substr($newstr,0,$length);
#printf ("fifi calcstr3 funktionsaufruf newstr=$newstr pos=$pos str=$str\n");
   if ($pos < $#letters){
      calcstr3(calcstr2($newstr,$pos)); 
   }elsif($pos == $#letters){
      calcstr2($newstr,$pos);
   }
   return($str,$pos+1);
}

sub calcstr2
{
   my $str=shift;
   my $pos=shift;
#printf ("fifi calc2 eingangsparameter str=$str pos=$pos\n");
   my $newstr=substr($str,0,length($str)-2);
   my $posnew=$pos;
   # calcstr1 expect $lenght characters in $str
   while (length($newstr) < $length){
      if ($letters[$posnew-1]->{'char'}){
         $newstr=$newstr.$letters[$posnew-1]->{'char'};
         $posnew++;
      }
   }
   $newstr=substr($newstr,0,$length);
   if ($pos < $#letters){
#printf ("fifi calc2 funktionsaufruf newstr=$newstr pos=$pos\n");
      calcstr2(calcstr1($newstr,$pos));
   }elsif($pos == $#letters){
      calcstr1($newstr,$pos);
   }
   return($str,$pos+1);
}

sub calcstr1
{
   my $str=shift;
   my $pos=shift;
   # calcstr1 expect $lenght-1 characters in $str
   while (length($str) >= $length){
      $str=substr($str,0,length($str)-1);
   }
   for (my $c=$pos;$c<=$#letters;$c++){
      $str=$str.$letters[$c]->{'char'};
      if($length == length($str)){
         push(@$acros,{$str=>''});
         if ($#letters != $letters[$c]->{'pos'}){
            calcstr1(substr($str,0,$length-1),$letters[$c]->{'pos'}+1);
            return($str,$letters[$c]->{'pos'}+1);
         }
      }
   }   
   return($str,$pos+1);
}

