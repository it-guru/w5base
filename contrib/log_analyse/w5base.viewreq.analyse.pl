#!/usr/bin/perl
use strict;
use Data::Dumper;

my %pid;
my %u;
my $startstamp;
my $endstamp;
my %s;
while(my $l=<>){
   $l=~s/\s*$//;
   #printf ("%s\n::\n",$l);
   if (my @p=$l=~m/^(\d{14})\s\[(\d+)\]\s\S+\s+(\S+)\s+(\S+)\s+(.*)$/x){
      my $i=0;
      my $tstamp=$p[$i++];
      my $pid=$p[$i++];
      my $user=$p[$i++];
      my $dataobj=$p[$i++];
      my $view=$p[$i++];
      my @view=split(/,/,$view);
      my ($day)=$tstamp=~/^([0-9]{8})/;

      $s{day}->{$day}->{viewcount}->{total}++;
      $s{day}->{$day}->{viewcount}->{total}++;
      $s{day}->{$day}->{viewcount}->{dataobj}->{$dataobj}++;
      $s{day}->{$day}->{viewcount}->{user}->{$user}++;
      $s{avg}->{dataobj}->{$dataobj}=0;
      $s{sum}->{dataobj}->{$dataobj}={};
      foreach my $fld (@view){
         $s{day}->{$day}->{dataobj}->{$dataobj}->{$fld}++;
      }
   }
}

#######################################################################
# Verdichtung

my @days=sort(keys(%{$s{day}}));
#print Dumper(\@days);
shift(@days);
pop(@days);
#print Dumper(\@days);
foreach my $dataobj (keys(%{$s{avg}->{dataobj}})){
   my $sum=0;
   foreach my $day (@days){
      $sum+=$s{day}->{$day}->{viewcount}->{dataobj}->{$dataobj};
      foreach my $fld (keys(%{$s{day}->{$day}->{dataobj}->{$dataobj}})){
         $s{sum}->{dataobj}->{$dataobj}->{fld}->{$fld}+=
            $s{day}->{$day}->{dataobj}->{$dataobj}->{$fld};
      }
   }
   $s{avg}->{dataobj}->{$dataobj}=$sum/($#days+1);
}


#######################################################################
#print Dumper($s{avg});

my $LIM=20;

printf("Request Range %s-%s\n",$days[0],$days[-1]);
printf("%s\n",'-' x 40);
foreach my $day (@days){
   printf("%s: %6d total views\n",$day,$s{day}->{$day}->{viewcount}->{total});
}
printf("\nAveranged Views per Day (total objects=%d)\n",0+keys(%{$s{avg}->{dataobj}}));
printf("%s\n",'-' x 40);
my @dataobj=keys(%{$s{avg}->{dataobj}});
@dataobj=sort({
   $s{avg}->{dataobj}->{$b}<=>$s{avg}->{dataobj}->{$a};
} @dataobj);
my ($rank,$subrank);
for($rank=0;$rank<$LIM;$rank++){
   if (defined($dataobj[$rank])){
      printf("%02d %-35s : %8.2lf views per day\n",$rank+1,$dataobj[$rank],
             $s{avg}->{dataobj}->{$dataobj[$rank]});
   }
}
if (defined($dataobj[$rank])){
   printf("...\n");
}
printf("\nField view stats\n");
printf("%s\n",'-' x 40);
for($rank=0;$rank<$LIM;$rank++){
   if (defined($dataobj[$rank])){
      my @fields=keys(%{$s{sum}->{dataobj}->{$dataobj[$rank]}->{fld}});
      @fields=sort({
         $s{sum}->{dataobj}->{$dataobj[$rank]}->{fld}->{$b}<=>
         $s{sum}->{dataobj}->{$dataobj[$rank]}->{fld}->{$a};
      } @fields);
      printf("%s:\n",$dataobj[$rank]);
      for($subrank=0;$subrank<$LIM;$subrank++){
         if (defined($fields[$subrank])){
            printf("  %02d %-33s : %5.0lf total use count\n",$subrank+1,$fields[$subrank],
                   $s{sum}->{dataobj}->{$dataobj[$rank]}->{fld}->{$fields[$subrank]});
         }
      }
      if (defined($fields[$subrank+1])){
         printf("  ...\n");
      }
      printf("\n");
   }
}





#print Dumper(\%s);
