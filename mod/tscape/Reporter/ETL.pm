package tscape::Reporter::ETL;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA);
use kernel;
use kernel::Reporter;
@ISA=qw(kernel::Reporter);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{name}="ETL Job from CapeTS to Darwin v_darwin_export";
   return($self);
}

sub getDefaultIntervalMinutes
{
   my $self=shift;
   return(3600);    
}


sub Process             # will be run as a spereate Process (PID)
{
   my $self=shift;

   my $srcdb=new kernel::database($self,"tscape");
   my $dstdb=new kernel::database($self,"w5base");

   return(0);

   $srcdb->Connect();
   $dstdb->Connect();
   $srcdb->{DB}=$srcdb;
   $dstdb->{DB}=$dstdb;

   my $srctable="V_DARWIN_EXPORT";
   my $dsttable="interface_tscape_v_darwin_export";

   $dstdb->{DB}->{db}->{AutoCommit}=0;
   $dstdb->do("begin");
   $dstdb->do("delete from ${dsttable}");

   $srcdb->execute("select * from $srctable");
   my $n=0;

   if (my ($rec)=$srcdb->fetchrow()){
      my @f=sort(keys(%$rec));
      my $inscmd="insert into ${dsttable} ".
                 "(".join(",",@f).") ".
                 "values (".join(",",map({"?"} @f)).")";
      while(1){
          $n++;
          my @d=map({$rec->{$_}} @f);
          $dstdb->do($inscmd,@d);
          ($rec)=$srcdb->fetchrow();
          last if (!defined($rec));
      }
   }
   print("Loaded $n records\n");
   $dstdb->do("commit");
   return(0);
}




1;
