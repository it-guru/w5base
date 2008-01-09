package AL_TCom::MyW5Base::myP800hists;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::MyW5Base;
use AL_TCom::MyW5Base::myP800hist;
@ISA=qw(AL_TCom::MyW5Base::myP800hist);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub FinalDataFilter
{
   my $self=shift;
   my $mainq1=shift;

   $mainq1->{class}=[grep(/^.*::P800special$/,keys(%{$self->{DataObj}->{SubDataObj}}))];

   $self->{DataObj}->ResetFilter();
   $self->{DataObj}->SecureSetFilter([$mainq1]);
   $self->{DataObj}->setDefaultView(qw(linenumber affectedcontract
                                                  affectedapplication
                                       wffields.p800_reportmonth
                                       wffields.p800_app_speicalwt));
   my %param=(ExternalFilter=>1);
   return($self->{DataObj}->Result(%param));
}

1;
