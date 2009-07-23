package kernel::InterviewField;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use kernel;

sub getTotalActiveQuestions
{
   my $self=shift;
   my $parentobj=shift;
   my $idname=shift;
   my $id=shift;
   my $p=getModuleObject($self->getParent->Config,$parentobj);
   $p->SetFilter({$idname=>\$id});
   my ($rec,$msg)=$p->getOnlyFirst(qw(ALL));

   my $i=getModuleObject($self->getParent->Config,"base::interview");
   $i->SetFilter({parentobj=>\$parentobj});
   my @l;
   foreach my $irec ($i->getHashList(qw(id name qname prio
                                        questtyp questclust))){
      push(@l,$irec);
   }
   return(\@l);
}

sub getAnsweredQuestions
{
   my $self=shift;
   my $parentobj=shift;
   my $idname=shift;
   my $id=shift;

   return([]);
}

1;
