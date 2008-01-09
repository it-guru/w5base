package tsacinv::event::testprog;
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
use Data::Dumper;
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("testco","TestCoNumbers");
   return(1);
}

sub TestCoNumbers
{
   my $self=shift;

   my $co=getModuleObject($self->Config,"tsacinv::costcenter");
   $co->SetFilter({});
   my @l=$co->getHashList(qw(name));
   my %u=();
   my $colision=0;
   foreach my $rec (@l){
     my $striped=$rec->{name};
     $striped=~s/^0+//g;
     if (!defined($u{$striped})){
        $u{$striped}=$rec->{name};
     }
     else{
        if ($striped ne $rec->{name}){
           msg(ERROR,"CO collision bettween %15s and %15s",
                  "'".$striped."'","'".$u{$striped}."'");
           $colision++;
        }
     }
   }
   printf STDERR ("CO-Count:%s  collisions:%d\n",$#l+1,$colision);
  # printf ("%s\n",join(",",map({$_->{name}} @l)));

   return({}); 
}





1;
