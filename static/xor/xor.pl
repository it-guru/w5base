#!/usr/bin/perl
use strict;
use POSIX;
use Math::BigInt;

my $code="Cryptkey";
my $ctxt="a7a02122c7ad1477c7e1b0b91ea46fbbb03054b87a00f0eead";

my $ptext = decrypt($code,$ctxt);
printf("text=%s\n",$ptext);
my $ctext =encrypt($code,$ptext);
printf("text=%s\n",$ctext);
printf("text=%s\n",decrypt($code,$ctext));

sub encrypt
{
   my $code=shift;
   my $text=shift;
   my $prand="";
   foreach my $c (split(//,$code)){ $prand.=ord($c);}
   my $sPos=int(length($prand)/5);
   my $mult=int(substr($prand,$sPos,1).
                substr($prand,$sPos*2,1).
                substr($prand,$sPos*3,1).
                substr($prand,$sPos*4,1).
                substr($prand,$sPos*5,1));
   my $incr=ceil(length($code)/2);
   my $modu=2**31-1;
   my $salt=sprintf("%.0f",(rand()*1000000000)%100000000);
   $prand.=$salt;
   while(length($prand)>10){
      my $a=Math::BigInt->new(substr($prand,0,10));
      my $b=Math::BigInt->new(substr($prand,10));
      $prand=($a+$b);
   }
   $prand=sprintf("%d",$prand);
   $prand=($mult*$prand+$incr)%$modu;
   my $enc_str="";
   foreach my $c (split(//,$text)){
      my $x = floor(($prand / $modu) * 255);
      my $enc_chr = int(ord($c)^$x);
      $enc_str .= sprintf("%02x", $enc_chr);
      $prand=($mult*$prand+$incr)%$modu;
   }
   $salt = sprintf("%08x",$salt);
   $enc_str.=$salt;
   return($enc_str);
}

sub decrypt
{
   my $code=shift;
   my $ctext=shift;
   my $prand="";
   foreach my $c (split(//,$code)){ $prand.=ord($c);}
   my $sPos=int(length($prand)/5);
   my $mult=int(substr($prand,$sPos,1).
                substr($prand,$sPos*2,1).
                substr($prand,$sPos*3,1).
                substr($prand,$sPos*4,1).
                substr($prand,$sPos*5,1));
   my $incr=ceil(length($code)/2);
   my $modu=2**31-1;
   my $salt=hex(substr($ctext,length($ctext)-8));
   my $str=substr($ctext,0,length($ctext)-8);
   $prand.=$salt;
   while(length($prand)>10){
      my $a=Math::BigInt->new(substr($prand,0,10));
      my $b=Math::BigInt->new(substr($prand,10));
      $prand=($a+$b);
   }
   $prand=sprintf("%d",$prand);
   $prand=($mult*$prand+$incr)%$modu;
   my $enc_str="";
   for(my $i=0;$i<length($str);$i+=2){
      my $h=substr($str,$i,2);
      my $d=hex($h);
      my $x = floor(($prand / $modu) * 255);
      $enc_str.=chr($d ^ $x);
      $prand=($mult*$prand+$incr)%$modu;
   }
   return($enc_str);
}

1;
