package base::event::NotifyByScript;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("NotifyByScript","NotifyByScript",timeout=>120);
   return(1);
}

sub NotifyByScript
{
   my $self=shift;
   my %param=@_;

   my $mod=$param{mod};

   return({exitcode=>1,msg=>'no mod specified'}) if ($mod eq "");

   my $NotifyByScript=$self->Config->Param("NotifyByScript");
   $NotifyByScript=$NotifyByScript->{$mod} if (ref($NotifyByScript) eq "HASH");
   return({exitcode=>0,msg=>'no script specified'}) if ($NotifyByScript eq "");

   system("$NotifyByScript '$param{mod}' '$param{id}' '$param{op}'");
   if ($?!=0){
      return({exitcode=>$?,msg=>'$NotifyByScript exitcode was not zero'});
   }

   return({exitcode=>0,msg=>'ok'});
}





1;
