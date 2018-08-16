package base::ext::lnkcontact;
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

sub getPosibleRoles
{
   my $self=shift;
   my $field=shift;
   my $parentobj=shift;
   my $current=shift;
   my $newrec=shift;

   if ($parentobj eq "base::mandator" ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self() eq "base::mandator")){
      return("read"            =>$self->getParent->T("read",$self->Self),
             "write"           =>$self->getParent->T("write",$self->Self)
             );
   }
   if ($parentobj eq "base::user" ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self() eq "base::user")){
      return("useasfrom"        =>$self->getParent->T("UseAsFrom",$self->Self),
             );
   }
   if ($parentobj=~m/^.+::projectroom$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::projectroom$/)){
      return(
             "read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
             "SVNread"         =>$self->getParent->T("SVNread",
                                                     $self->Self),
             "SVNwrite"        =>$self->getParent->T("SVNwrite",
                                                     $self->Self),
             "privread"        =>$self->getParent->T("privacy read",
                                                     $self->Self),
             "PMember"         =>$self->getParent->T("project member",
                                                     $self->Self),
             "PManager"        =>$self->getParent->T("project manager",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::campus$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::campus$/)){
      return(
             "read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self));
   }
   if ($parentobj eq "base::location" ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self() eq "base::location")){
      return(
         "infrastruct"     =>$self->getParent->T("infrastruct",
                                                 $self->Self),
         "itnetwork"       =>$self->getParent->T("itnetwork",
                                                 $self->Self),
         "staffloc"        =>$self->getParent->T("staffloc",
                                                 $self->Self),
         "facmgr"          =>$self->getParent->T("facility manager",
                                                 $self->Self),
         "infocontact"     =>$self->getParent->T("Information contact",
                                                 $self->Self),
         "evinfocontact"   =>$self->getParent->T("Event information contact",
                                                 $self->Self),
         "write"           =>$self->getParent->T("write",
                                                 $self->Self)
         );
   }
   return();
}




1;
