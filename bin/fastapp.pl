#!/usr/bin/perl
#  W5Base Framework Main-Programm
#  Copyright (C) 2002-2017  Hartmut Vogler (it@guru.de)
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

################################################################
package errHandler;
sub TIEHANDLE{ 
   my $class=shift;
   bless {stderr=>$_[0]}; 
}
sub PRINT { 
   my $self=shift;
   my $fh=$self->{stderr};
   foreach my $line (@_){
      foreach my $subline (split(/\n/,$line)){
         print $fh (sprintf("[%s] [w5base] [pid %d] %s\n",
                            (scalar(localtime())),$$,$subline));
      }
   }
}
sub PRINTF {
   my $self=shift;
   my $fmt=shift;
   $self->PRINT(sprintf($fmt, @_));
}

sub BINMODE{}
################################################################

package main;
my %SHELLENV;
BEGIN{
   %SHELLENV=(%ENV);
}
END {
   printf STDERR ("INFO: terminate fastappl.pl($$)\n");
}

use strict;
use FindBin ;
use CGI;
use FCGI;
use Scalar::Util;
eval('use Proc::ProcessTable;');  # try to load Proc::ProcessTabel if exists


*CORE::GLOBAL::die = sub {
   if (Scalar::Util::blessed($_[0])){
      CORE::die(@_); 
   }
   require Carp; Carp::confess 
};


#######################################################################
# ENV Init $W5V2::*
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
foreach my $path (map({$_."/mod",$_."/lib"} $W5V2::INSTDIR),
                  map({$_."/mod"} @w5instpath)){
   my $qpath=quotemeta($path);
   unshift(@INC,$path) if (!grep(/^$qpath$/,@INC));
}
#######################################################################



do "$W5V2::INSTDIR/lib/kernel/App/Web.pm";
print STDERR ("ERROR: $@\n") if ($@ ne "");
my $err = new IO::Handle;

my $request = FCGI::Request(\*STDIN,\*STDOUT,$err);
while($request->Accept()>=0){
   #######################################################################
   # Redirecting STDERR
   my $errlog=FileHandle->new(">&STDERR");
   $errlog->autoflush(1);
   tie(*STDERR=>'errHandler',$errlog);
   #######################################################################
   CGI::initialize_globals();
   my $fastreq;
   if ($ENV{'QUERY_STRING'} eq "MOD=base::interface&FUNC=SOAP"){
      # all operations in SOAP::Lite uses STDIN/STDOUT, so we need
      # to create a dummy CGI Object with minimal variables and leafing
      # IO Streams untouched.
      $fastreq=CGI->new({MOD=>'base::interface',FUNC=>'SOAP'});
   }
   else{
      $fastreq=CGI->new();
   }

   for my $ev (keys(%SHELLENV)){  # Restore Enviroment
       if (($ev=~m/^(CLASSPATH|JAVA_HOME|PATH|LD_LIBRARY_PATH)$/) ||
           ($ev=~m/^PERL/) ||
           ($ev=~m/^W5/) ||
           ($ev=~m/^(ORA|NLS|TNS)/) ||
           ($ev=~m/^DB2/)){
          $ENV{$ev}=$SHELLENV{$ev};
       }
   }
   $W5V2::OperationContext="WebFrontend";
   $W5V2::InvalidateGroupCache=0;
   $W5V2::HistoryComments=undef;
   $W5V2::CurrentFastCGIRequest=$fastreq;
   my ($configname)=$ENV{'SCRIPT_NAME'}=~m#/(.+)/(bin|auth|public|cookie)#;
   kernel::App::Web::RunWebApp($W5V2::INSTDIR,$configname);
   if (defined($Proc::ProcessTable::VERSION)){
      my $pt=new Proc::ProcessTable();
      my %info = map({$_->pid =>$_} @{$pt->table});
      my $rss=$info{$$}->rss;
      my $szlimit=800000000;
      if ($rss>$szlimit){ 
         printf STDERR ("cleanup perl process due size ".
                        "limitation %d (limit=%d)\n",$rss,$szlimit);
         $request->LastCall(); 
      }
   }
}


sub redirect_elog
{
    my ($file) = @_;
    local *LCSTDERR;
    open(LCSTDERR, ">>$file") or
        die "Can't open log file $file";
    open(STDERR, ">&LCSTDERR") or
        die "can't redirect standard error";

}
