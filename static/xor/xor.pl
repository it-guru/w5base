#!/usr/bin/perl
use strict;
use Math::Round qw/round/;
use Math::BigInt;

my $code="Cryptkey";
my $ctxt="9b81c57692d8d0f1f7ba73ff2eb1eda6e0b3d7061b042b1f17";


printf("text=%s\n",decrypt($code,$ctxt));

sub decrypt
{
   my $code=shift;
   my $ctext=shift;
   printf("fifi: ctext=$ctext\n");
   my $prand="";
   foreach my $c (split(//,$code)){ $prand.=ord($c);}
   printf("fifi: prand=$prand\n");

   my $sPos=int(length($prand)/5);

   printf("fifi: sPos=$sPos\n");

   my $mult=int(substr($prand,$sPos,1).
                substr($prand,$sPos*2,1).
                substr($prand,$sPos*3,1).
                substr($prand,$sPos*4,1).
                substr($prand,$sPos*5,1));

   printf("fifi: mutl=$mult\n");

   my $incr=round(length($code)/2);

   printf("fifi: incr=$incr\n");

   my $modu=2**31-1;
   printf("fifi: modu=$modu\n");
   

   my $salt=hex(substr($ctext,length($ctext)-8));

   printf("fifi: salt=$salt\n");

   my $str=substr($ctext,0,length($ctext)-8);
   printf("fifi: str=$str\n");

   $prand.=$salt;
   printf("prand pre while %s\n" ,$prand);
   while(length($prand)>10){
      printf("1prand:".$prand."\n");
      my $a=Math::BigInt->new(substr($prand,0,10));
      my $b=Math::BigInt->new(substr($prand,10));

      print("s1:".$a."\n");
      print("s2:".$b."\n");
      $prand=$a+$b;
      print($prand,"\n--\n"); 
      printf("2prand:".$prand."\n");
   }
   $prand=($mult*$prand+$incr)%$modu;
   printf("fifi: prand=$prand\n");


   my $enc_str="";

   for(my $i=0;$i<length($str);$i+=2){
      my $h=substr($str,$i,2);
      my $d=hex($h);
      printf("fifi h=$h d=$d\n");
      my $enc_chr=int(hex(substr($str,$i,2))^int(($prand/$modu)*255));
      $enc_str.=chr($enc_chr);
   }
   printf("fifi enc_str=$enc_str\n");


}





1;
