#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

sub scanWord
{
   my $name=shift;
   my $word=1;
   my $ipos=0;
   my $char;
   my @letters;
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
   return(\@letters);
}

sub moveStart
{
   my $letters=shift;
   my $length=shift;
   my %acros;
   # move start position one step forward
   for (my $a=0;$a<$#{$letters}+2-$length;$a++){
      if ($a == $#{$letters}+1-$length){
         my $lastword;
         for (my $y=0;$y<$length;$y++){ 
            $lastword=$lastword.$letters->[$a+$y]->{'char'};
         }
         $acros{$lastword}=1;
         next;
      }
      my ($rstr,$rpos)=chglastchar($letters,$length,\%acros,"",$a);
      for (my $l=2;$l<$length;$l++){
         ($rstr)=chgchar($letters,$length,\%acros,$rstr,$rpos,$l);
      }   
   }
   return(\%acros);
}

sub chgchar
{
   # change characters after start position (first character in $str)
   my $letters=shift;
   my $length=shift;
   my $acros=shift;
   my $str=shift;
   my $pos=shift;
   my $level=shift;
   my $newstr=substr($str,0,length($str)-$level);
   my $posnew=$pos;
   while (length($newstr) < $length){
      if ($#{$letters} >= $posnew-$level+1){
         $newstr=$newstr.$letters->[$posnew-$level+1]->{'char'};
         $posnew++;
      }else{
         last;
      }
   }
   if ($pos < $#{$letters}){
      if ($level == 2){
         chgchar($letters,$length,$acros,
                 chglastchar($letters,$length,$acros,$newstr,$pos),
                 $level);
      }else{
         chgchar($letters,$length,$acros,
                 chgchar($letters,$length,$acros,$newstr,$pos,$level-1),
                 $level); 
      }
   }elsif($pos == $#{$letters}){
      if ($level == 2){
         chglastchar($letters,$length,$acros,$newstr,$pos);
      }else{
         chgchar($letters,$length,$acros,$newstr,$pos,$level-1);
      }
   }
   return($str,$pos+1);
}

sub chglastchar
{
   # change last character for all possibilities
   my $letters=shift;
   my $length=shift;
   my $acros=shift;
   my $str=shift;
   my $pos=shift;
   while (length($str) >= $length){
      $str=substr($str,0,length($str)-1);
   }
   for (my $c=$pos;$c<=$#{$letters};$c++){
      $str=$str.$letters->[$c]->{'char'};
      if($length == length($str)){
         $acros->{$str}=1;
         if ($#{$letters} != $letters->[$c]->{'pos'}){
            chglastchar($letters,$length,$acros,substr($str,0,$length-1),$letters->[$c]->{'pos'}+1);
            return($str,$letters->[$c]->{'pos'}+1);
         }
      }
   }   
   return($str,$pos+1);
}


sub initDBs
{
   my $db=shift;
   my @rdb;
   my $fnd="";
   foreach my $d (@$db){
      my %db;
      open(FH,'<'."../../lib/dict/$d") ||
          printf STDERR ("ERROR: can't open dictionary $d\n");
      my $fh=\*FH;
      $db{'tblname'}="$d";
      $db{'dbfp'}=$fh;
      while (my $w=<$fh>){
         if ($fnd ne substr($w,0,1)){
            $fnd=substr($w,0,1); 
            $db{'keypos'}->{$fnd}=tell($fh);
         }
      }
      push(@rdb,\%db);
   }
   return(\@rdb); 
}
sub closeDBs
{
   my $db=shift;
   foreach my $fh (@$db){
#      close($fh->{'dbfp'});
   }
}

sub seekWord
{
   my $acros=shift;
   my $dbs=shift;
   foreach my $key (keys(%$acros)){
      my $k=$key;
      foreach my $db (@$dbs){
         my $f=$db->{'dbfp'};
         seek($f,$db->{'keypos'}->{substr($key,0,1)},0);
         while(my $dict=<$f>){
            my $dict=chop($dict);
print "$dict\n";
            if (chomp($dict) eq $k){
               $acros->{$key}=3;
            } 
         }
      }
   }
   return($acros);
}


my $length=4;
my $name="operational framework";

my $letters=scanWord($name);
my $acros=moveStart($letters,$length);
printf ("fifi count=%s\n",my $a=keys(%$acros));
my $dbs=initDBs(['en']);
seekWord($acros,$dbs);
printf ("fifi founds=%s\n",$acros->{'oper'});
closeDBs($dbs);


