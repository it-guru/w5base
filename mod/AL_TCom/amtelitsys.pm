package AL_TCom::amtelitsys;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use tsacinv::system;
@ISA=qw(tsacinv::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   my $saphier=$self->getField("saphier");
   if (!defined($saphier)){
      return(undef);
   }
   $saphier->{searchable}=0;
   delete($saphier->{ignorecase});
   $saphier->{uppersearch}=1;

   my $status=$self->getField("status");
   if (!defined($status)){
      return(undef);
   }
   $status->{searchable}=0;

   $self->AddFields(
      new kernel::Field::Boolean(
                name          =>'w5found',
                searchable    =>0,
                label         =>'System found in IT-Inventar',
                depend        =>['systemid'],
                onRawValue=>sub{
                   my $self=shift;
                   my $current=shift;
                   my $p=$self->getParent();
                   my $sys=$p->getPersistentModuleObject("invsys",
                                                         "itil::system");
                   $sys->SetFilter({systemid=>\$current->{systemid}});
                   my ($rec,$msg)=$sys->getOnlyFirst(qw(id));
                   return(1) if (defined($rec));
                   return(0);
                }),
      insertafter=>['applid']
   );


   $self->setDefaultView(qw(systemname systemid tsacinv_locationfullname
                            w5found));


   return($self);
}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   foreach my $flt (@flt){
      if (ref($flt) eq "HASH"){
         $flt->{saphier}="YT5AGH.* YT5A_DTIT.*";
         $flt->{status}='"in operation" "hibernate"';
      }
   }

   return($self->SUPER::SetFilter(@flt));
}






1;
