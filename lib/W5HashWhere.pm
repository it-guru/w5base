#!/bin/perl
use Text::ParseWords;
use Data::Dumper;
my @l=(
        {surname=>'Vogler',      givenname=>'Hartmut', location=>'Bamberg'},
        {surname=>'Wieschollek', givenname=>'Andreas', location=>'Bamberg'},
        {surname=>'Vogler',      givenname=>'Klaus',   location=>'Schöndorf'},
      );


my $t="mandator='AL T-Com' AND ((customer like 'DTAG.%' OR customer='xx')";

#
# parse words
#
my @w;
foreach my $w (quotewords('\s+',1,$t)){
   if ($w=~m/^\(/i){
      my @stack;
      while($w=~s/^\(//){
         push(@stack,"(");
      }
      push(@w,@stack);
   }
   if ($w=~m/^[a-z0-9]+=/i){
      push(@w,($w=~m/^([a-z0-9]+)(=)(.*)$/i));
   }
   else{
      push(@w,$w);
   }
   if ($w[$#w]=~m/\)$/i){
      my @stack;
      while($w[$#w]=~s/\)$//){
         push(@stack,")");
      }
      push(@w,@stack);
   }
}
#
# classify element list
#
my @e;
my @COM=qw(like and or =);
foreach my $w (@w){
   my $qw=quotemeta($w);
   if (grep(/^${qw}$/i,@COM)){
      push(@e,{type=>'COM',name=>$w});
   }
   elsif (grep(/^${qw}$/i,"(",")")){
      push(@e,{type=>'BRACKET',name=>$w});
   }
   elsif ($w=~m/^".*"$/){
      push(@e,{type=>'VALUE',val=>$w});
   }
   elsif ($w=~m/^'.*'$/){
      push(@e,{type=>'CONST',val=>$w});
   }
   else{
      push(@e,{type=>'VARNAME',name=>$w});
   }
}

#
# syntax and structur check
#

#
# build perl eval code
#
my $cmd="sub{my \$H=shift;return(";
while(my $e=shift(@e)){
   if ($e->{type} eq "VARNAME"){
      $cmd.="\$H->{'$e->{name}'}";
   }
   if ($e->{type} eq "CONST"){
      $cmd.="$e->{val}";
   }
   if ($e->{type} eq "BRACKET"){
      $cmd.="$e->{name}";
   }
   if ($e->{type} eq "COM" && $e->{name} eq "="){
      $cmd.=" eq ";
   }
   if ($e->{type} eq "COM" && lc($e->{name}) eq "and"){
      $cmd.=" and ";
   }
   if ($e->{type} eq "COM" && lc($e->{name}) eq "or"){
      $cmd.=" and ";
   }
   if ($e->{type} eq "COM" && lc($e->{name}) eq "like"){
      $cmd.=" = ";
   }
}
$cmd.=")};";

my $match=eval($cmd);

printf("res=%s\n",$@);
printf("match=%s\n",$match);







printf("source=>%s<\n\n",$t);

printf("result=%s\n",Dumper(\@e));
printf("cmd=>%s<\n\n",$cmd);




