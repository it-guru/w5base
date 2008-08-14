#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

my $length=2;
my $name="operational framework";
my (@letters,$char,$acros);
my $word=1;
my $ipos=0;



# scan given word 
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

# move start position one step forward
for (my $a=0;$a<$#letters+2-$length;$a++){
   if ($a == $#letters+1-$length){
      my $lastword;
      for (my $y=0;$y<$length;$y++){ 
         $lastword=$lastword.$letters[$a+$y]->{'char'};
      }
      push(@$acros,{$lastword=>''}); 
      next;
   }
   my ($rstr,$rpos)=chglastchar("",$a);
   for (my $l=2;$l<$length;$l++){
      ($rstr)=chgchar($rstr,$rpos,$l);
   }   
}

printf ("fifi dump=%s\n",Dumper($acros));
# change characters after start position (first character in $str)
sub chgchar
{
   my $str=shift;
   my $pos=shift;
   my $level=shift;
   my $newstr=substr($str,0,length($str)-$level);
   my $posnew=$pos;
   while (length($newstr) < $length){
      if ($#letters >= $posnew-$level+1){
         $newstr=$newstr.$letters[$posnew-$level+1]->{'char'};
         $posnew++;
      }else{
         last;
      }
   }
   if ($pos < $#letters){
      if ($level == 2){
         chgchar(chglastchar($newstr,$pos),$level);
      }else{
         chgchar(chgchar($newstr,$pos,$level-1),$level); 
      }
   }elsif($pos == $#letters){
      if ($level == 2){
         chglastchar($newstr,$pos);
      }else{
         chgchar($newstr,$pos,$level-1);
      }
   }
   return($str,$pos+1);
}

# change last character for all possibilities
sub chglastchar
{
   my $str=shift;
   my $pos=shift;
   while (length($str) >= $length){
      $str=substr($str,0,length($str)-1);
   }
   for (my $c=$pos;$c<=$#letters;$c++){
      $str=$str.$letters[$c]->{'char'};
      if($length == length($str)){
         push(@$acros,{$str=>''});
         if ($#letters != $letters[$c]->{'pos'}){
            chglastchar(substr($str,0,$length-1),$letters[$c]->{'pos'}+1);
            return($str,$letters[$c]->{'pos'}+1);
         }
      }
   }   
   return($str,$pos+1);
}

