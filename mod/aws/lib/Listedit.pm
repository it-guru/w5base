package aws::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::DataObj::Static;
use kernel::Field;

use Paws;
use Paws::Credential;
use Paws::Credential::Explicit;
use Paws::Credential::AssumeRole;
use Paws::Net::LWPCaller;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub genericSimpleFilterCheck4AWS
{
   my $self=shift;
   my $filterset=shift;

   if (!ref($filterset) eq "HASH" ||
       keys(%{$filterset})!=1 ||
       !exists($filterset->{FILTER}) ||
       ref($filterset->{FILTER}) ne "ARRAY" ||
       $#{$filterset->{FILTER}}!=0){
      $self->LastMsg(ERROR,"requested filter not supported by REST backend");
      print STDERR Dumper($filterset);
      return(undef);
   }
   return(1);
}

sub checkMinimalFilter4AWS
{
   my $self=shift;
   my $filter=shift;
   my @fields=@_;   # at now only 1 field works

   my $field=$fields[0];

   if (!exists($filter->{$field}) ||
       !($filter->{$field}=~m/^\S{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary filter not specifed");
      print STDERR Dumper($filter);
      return(undef);
   }
   return(1);
}


sub decodeFilter2Query4AWS
{
   my $self=shift;
   my $filter=shift;

   my $query={};

   foreach my $fn (keys(%$filter)){
      $query->{$fn}=$filter->{$fn};
      $query->{$fn}=${$query->{$fn}} if (ref($query->{$fn}) eq "SCALAR");
      $query->{$fn}=join(" ",@$query->{$fn}) if (ref($query->{$fn}) eq "ARRAY");
   }
   return($query);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



1;
