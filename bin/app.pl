#!/usr/bin/perl
#  W5Base Framework Main-Programm
#  Copyright (C) 2002-2008  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use FindBin ;
use Scalar::Util;


*CORE::GLOBAL::die = sub {
   if (Scalar::Util::blessed($_[0])){
      CORE::die(@_);
   }
   require Carp; Carp::confess
};

$W5V2::OperationContext="WebFrontend";
$W5V2::InvalidateGroupCache=0;
$W5V2::HistoryComments=undef;
if (!defined($W5V2::INSTDIR)){
   if (defined(&{FindBin::again})){
      FindBin::again();
      $W5V2::INSTDIR="$FindBin::Bin/..";
   }
}
$W5V2::INSTDIR="/opt/w5base" if (!defined($W5V2::INSTDIR));

my @w5instpath;
if ($ENV{W5BASEINSTDIR} ne ""){
   @w5instpath=split(/:/,$ENV{W5BASEINSTDIR});
   $W5V2::INSTDIR=shift(@w5instpath);
   $W5V2::INSTPATH=\@w5instpath;
}

foreach my $path (map({$_."/mod",$_."/lib"} $W5V2::INSTDIR,@w5instpath)){
   my $qpath=quotemeta($path);
   unshift(@INC,$path) if (!grep(/^$qpath$/,@INC));
}
do "$W5V2::INSTDIR/lib/kernel/App/Web.pm";
print STDERR ("ERROR: $@\n") if ($@ ne "");
my ($configname)=$ENV{'SCRIPT_NAME'}=~m#/(.+)/(bin|auth|public|cookie)#;
kernel::App::Web::RunWebApp($W5V2::INSTDIR,$configname);
