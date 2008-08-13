#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $length=4;
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
   if ($a == $#letters+1-$length){
      my $lastword;
      for (my $y=0;$y<$length;$y++){ 
         $lastword=$lastword.$letters[$a+$y]->{'char'};
      }
      push(@$acros,{$lastword=>''}); 
      next;
   }
   my ($rstr,$rpos)=calcstr1("",$a);
  # printf ("FIFI rstr=$rstr rpos=$rpos\n");
   my ($rstr2,$rpos2)=calcstr2($rstr,$rpos);
 #  printf ("FIFI aufruf calc3 rstr=$rstr2 rpos=%s\n",$rpos2-1);
   my ($rstr3,$rpos3)=calcstr3($rstr2,$rpos2-1);
}


#printf ("FIFI data=%s\n",Dumper($acros));
printf ("FIFI countarray=%s\n",$#{$acros});

sub calcstr3
{
   my $str=shift;
   my $pos=shift;
   my $newstr=substr($str,0,length($str)-3);
#printf ("fifi calc3 eingangsparameter str=$str newstr=$newstr pos=$pos\n");
   my $posnew=$pos;
   while (length($newstr) < $length){
      if ($letters[$posnew-2]->{'char'} ne ""){
         $newstr=$newstr.$letters[$posnew-2]->{'char'};
         $posnew++;
      }
   }
   $newstr=substr($newstr,0,1).
           substr($newstr,length($newstr)-3,length($newstr));
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
      my ($nstr,$npos)=calcstr2(calcstr1($newstr,$pos));
   }elsif($pos == $#letters){
      my ($nstr,$npos)=calcstr1($newstr,$pos);
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

