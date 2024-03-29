package base::ObjectEventHandler::BaseUser;
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

sub HandleEvent
{
   my $self=shift;
   my $event=shift;
   my $object=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ($object eq "base::user" && $event eq "UpdateRecord"){
      my $oldcistatusid=$oldrec->{cistatusid};
      my $newcistatusid=$newrec->{cistatusid};
      if (defined($newcistatusid) && $newcistatusid==6 &&
          $oldcistatusid!=6){ # delete infoabos if user is set disposed of wast
         my $idobj=$self->getParent->IdField();
         my $id=$idobj->RawValue($oldrec);
         my $infoabo=getModuleObject($self->getParent->Config,"base::infoabo");
         if (defined($infoabo)){
            $infoabo->SetFilter({'userid'=>\$id});
            my $nr=$infoabo->DeleteAllFilteredRecords("ValidatedDeleteRecord");
         }
      }
   }
   if ($object eq "base::user" && $event eq "DeleteRecord"){
      my $idobj=$self->getParent->IdField();
      my $id=$idobj->RawValue($oldrec);
      my $infoabo=getModuleObject($self->getParent->Config,"base::infoabo");
      if (defined($infoabo)){
         $infoabo->SetFilter({'userid'=>\$id});
         my $nres=$infoabo->DeleteAllFilteredRecords("ValidatedDeleteRecord");
      }
   }

   return(undef);
}


1;
