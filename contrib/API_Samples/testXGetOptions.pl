#!/usr/bin/env perl
use lib qw(../../lib);
use strict;
use warnings;
use diagnostics;

use Data::Dumper ;

use W5Base::API;

my (    $help,$verbose,
        $drw_user,$drw_pass,
        $base,$lang
        );

my ($Config) ;

$verbose = 6;
$help = 0 ;

my %P = (
   "help"       => \$help,
   "verbose+"   => \$verbose,
   "base=s"     => \$base,
   "lang=s"     => \$lang,
#
   "webuser=s"  => \$drw_user,
   "webpass=s"  => \$drw_pass,
#
);
my $optresult = XGetOptions(\%P,\&Help,undef,undef,".W5Base.Interface");

print "Do something ...\n" ;
exit ;

sub Help
{
 print "Help procedure was called.\n" ;
}
