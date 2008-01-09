package base::userpic;
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
use kernel::App::Web;
use base::load;
use kernel::TemplateParsing;
@ISA=qw(base::load);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Run
{
   my $self=shift;
   my $img=Query->Param("FUNC");
   if (my ($userid)=$img=~m/^(\d+)\.jpg$/){
      my $u=$self->getPersistentModuleObject("u","base::user");
      $u->ResetFilter();
      $u->SetFilter({userid=>\$userid});
      my ($rec,$msg)=$u->getOnlyFirst(qw(picture));
      if (defined($rec) && $rec->{picture} ne ""){
         print $self->HttpHeader("image/jpg",cache=>0);
         print $rec->{picture};
         return(1);
      }
   }
   Query->Param("FUNC"=>"user.jpg");
   return($self->SUPER::Run(@_));
}


1;
