#!/usr/bin/env perl 
use strict;
use lib qw(../lib ../../lib ../../../lib);
use Getopt::Long;
use W5Kernel;
use W5FastConfig;
use W5Base::API;
use vars qw( $opt_v $opt_v $opt_h $opt_c $appname);

#######################################################################
# INIT
#######################################################################
my @ARGV_bak=@ARGV;
$appname="w5orasync";
exit(1) if (!GetOptions('verbose'=>\$opt_v,
                        'debug'=>\$opt_v,
                        'help'=>\$opt_h,
                        'config=s'=>\$opt_c));
$W5V2::Debug=0; $W5V2::Debug=1 if ($opt_v);
if (defined($opt_h)){ help(); exit(1); }

$0=$main::appname;
my @argv=@ARGV;
@ARGV=@ARGV_bak;
my $configname=$opt_c;

my $cfg=new W5FastConfig('sysconfdir'=>'/etc');
if (!$cfg->readconfig($configname)){
   msg(ERROR,"can't read configfile '%s'",$configname);
   exit(1);
}
#######################################################################
print $cfg->Dumper();
#######################################################################
#######################################################################





#######################################################################
sub help
{
   printf STDERR ("Usage: $main::appname -c {config} [-v]\n");
}
#######################################################################
   
