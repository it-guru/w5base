package AL_TCom::ext::distlist;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub expandDynamicDistibutionList
{
   my $self=shift;
   my $infoabo=shift;
   my $dlname=shift;
   my @cc;
   my @to;
   my @bcc;

   my $appl=getModuleObject($infoabo->Config,"itil::appl");
   if (lc($dlname) eq "al_tsm"){
      $appl->SetFilter({cistatusid=>\'4'});
      foreach my $arec ($appl->getHashList(qw(tsmid tsm2id))){
         push(@to,$arec->{tsmid});
         push(@cc,$arec->{tsm2id});
      }
   }
   return(\@to,\@cc,\@bcc);
}


