package AL_TCom::event::migIntGroupRoles;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub migIntGroupRoles
{
   my $self=shift;
   my $grp=getModuleObject($self->Config,"base::grp");
   my $ur=getModuleObject($self->Config,"base::lnkgrpuser");

   $grp->SetFilter({fullname=>"*.SK *.HU *.RU *.BR *.CZ *.MY *.PL",
                    srcsys=>"[EMPTY]"});
   $grp->SetCurrentView(qw(grpid fullname name srcsys srcid));

   my ($rec,$msg)=$grp->getFirst();
   if (defined($rec)){
      do{
         if (!($rec->{fullname}=~m/^(w5base|membergroup)\./)){
            msg(INFO,"process group: $rec->{fullname}");
            $ur->ResetFilter();
            $ur->SetFilter({grpid=>\$rec->{grpid}});
            my @l=$ur->getHashList(qw(ALL));
            foreach my $urec (@l){
               my $rolesChanged=0;
               my @roles=@{$urec->{roles}};
               if (in_array(\@roles,"REmployee")){
                  @roles=grep(!/^REmployee$/,@roles);
                  push(@roles,"RFreelancer");
                  $rolesChanged++;
               }
               if ($#roles==0 && $roles[0] eq "RMember"){
                  push(@roles,"RFreelancer");
                  $rolesChanged++;
               }
               if ($rolesChanged){
                  $ur->ValidatedUpdateRecord(
                     $urec,
                     {roles=>\@roles},
                     {lnkgrpuserid=>\$urec->{lnkgrpuserid}}
                  ); 
               }
            }
         }
         ($rec,$msg)=$grp->getNext();
      } until(!defined($rec));
   }


   return({exitcode=>0});
}
1;
