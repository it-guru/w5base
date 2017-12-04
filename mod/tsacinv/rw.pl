#!/usr/bin/perl
use strict;

my $F=$ARGV[0];

if (! -f $F){
   die(sprintf("ERROR: File '%s' does not exists\n",$F));
}


if (!open(IN,"<$F")){
   die(sprintf("ERROR: in file $F can not be open\n",$F));
}

if (-f "$F.bak" || !open(BAK,">$F.bak")){
   die(sprintf("ERROR: bak file for $F can not be create\n",$F));
}

while(my $line=<IN>){
   print BAK $line;
}
close(BAK);
close(IN);

if (!open(OUT,">$F")){
   die(sprintf("ERROR: out file $F can not be open\n",$F));
}

if (!open(BAK,"<$F.bak")){
   die(sprintf("ERROR: can not read bak file for $F\n",$F));
}

printf("start file '%s'\n",$F);

my $fldname;
my $in_new=0;

while(my $line=<BAK>){
   if ($line=~m/^sub new\s*$/){
      $in_new=1;
   }
   if ($in_new){
      if (my ($chkname)=$line=~m/^\s*name\s*=>['"]([0-9a-zA-Z_]+)['"]/){
         $fldname=$chkname;
      }
      if ($line=~m/^\s*dataobjattr\s*=>.*\),\s*$/){
         my $l=$line;
         $l=~s/=>(\s*)(.*)\)/=>$1'"$fldname"')/;
         printf("P:%s: %s",$fldname,$line);
         printf("P:%s: %s",$fldname,$l);
         printf("\n");
         $line=$l;
      }
   }
   if ($in_new && $line=~m/^}\s*$/){
      $in_new=0;
   }
   print OUT $line;
}



close(BAK);
close(OUT);





