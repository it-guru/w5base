#!/usr/bin/perl
use strict;
use Data::Dumper;

my %pid;
my %u;
my $startstamp;
my $endstamp;
while(my $l=<>){
   $l=~s/\s*$//;
   if (my @p=$l=~m/^(\d{14})\s\[(\d+)\]\s(\S+)\s+findRecord:\s
                    \[(\S+)\]\s\((.*)\)\s*$/x){
      my $i=0;
      my $tstamp=$p[$i++];
      my $pid=$p[$i++];
      my $prio=$p[$i++];
      my $dataobj=$p[$i++];
      my $view=$p[$i++];
      my @view=split(/,/,$view);
      $startstamp=$tstamp if (!defined($startstamp));
      $endstamp=$tstamp;
      my $user="UNKNOWN";
      if (defined($pid{$pid})){
         $user=$pid{$pid}->{user};
      }
      foreach my $fld (@view){
         $u{$user}->{obj}->{$dataobj}->{'findRecord'}->{$fld}++;
      }
      #printf("l=%s\n",$l);
      #printf("user=$user pid=$pid dataobj=$dataobj view=$view\n");
   }
   elsif (my @p=$l=~m/^(\d{14})\s\[(\d+)\]\s(\S+)\s+request:\s+
                    user='(\S+)'\sdone.*$/x){
      my $i=0;
      my $tstamp=$p[$i++];
      my $pid=$p[$i++];
      my $prio=$p[$i++];
      my $user=$p[$i++];
      delete($pid{$pid});
   }
   elsif (my @p=$l=~m/^(\d{14})\s\[(\d+)\]\s(\S+)\s+request:\s+
                    user='(\S+)'\sip='(\S+)'.*$/x){
      my $i=0;
      my $tstamp=$p[$i++];
      my $pid=$p[$i++];
      my $prio=$p[$i++];
      my $user=$p[$i++];
      my $ip=$p[$i++];
      $pid{$pid}={user=>$user};
      $u{$user}->{ip}->{$ip}++;
   }
   elsif (my @p=$l=~m/^(\d{14})\s\[(\d+)\]\s(\S+)\s+findRecord:\s+
                    return\s+(\d+)\s+records - exitcode:(\d+)$/x){
   }
}
printf("Analyse: %s - %s\n\n",$startstamp,$endstamp);
my @user=sort(keys(%u));
for(my $usercnt=0;$usercnt<=$#user;$usercnt++){
   my $user=$user[$usercnt];
   printf("Interface: $user (%s)\n",join(",",sort(keys(%{$u{$user}->{ip}}))));
   my @obj=sort(keys(%{$u{$user}->{obj}}));
   for(my $objcnt=0;$objcnt<=$#obj;$objcnt++){
      my $p1="|";
      my $obj=$obj[$objcnt];
      printf(" %s- $obj\n",$p1);
      $p1=" " if ($objcnt==$#obj);
      my @view=sort(keys(%{$u{$user}->{obj}->{$obj}->{'findRecord'}}));
      my $line="";
      while((my $fld=shift(@view)) ne ""){
         $line.="," if (length($line));
         $line.=$fld;
         if (length($line)>40){
            printf(" %s    %s\n",$p1,$line);
            $line="";
         }
      }
      if ($line ne ""){
         printf(" %s    %s\n",$p1,$line);
         $line="";
      }
      printf(" %s\n",$p1);
   }
   print("\n");
}
