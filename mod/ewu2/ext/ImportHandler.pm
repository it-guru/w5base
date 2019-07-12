package ewu2::ext::ImportHandler;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getPriority
{
   my $self=shift;
   my $dataobj=shift;
   my $name=shift;
   if ($name eq "itil::system"){
      return(3000);

   }
   return(undef);
}

sub getSelector
{
   my $self=shift;
   my $dataobj=shift;
   my $name=shift;
   return("DevLab EWU2");
}

sub getImportToolPath
{
   my $self=shift;
   my $dataobj=shift;
   my $name=shift;
   return("ewu2/system/ImportSystem");
}



1;
