package kernel::EventController;
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
use vars qw(@ISA);
use strict;
use kernel;
use kernel::App;
use Data::Dumper;

@ISA=qw(kernel::App);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub LoadEventHandler
{
   my $self=shift;

   $self->LoadSubObjs("event");
}

sub ipcStore
{
   my $self=shift;
   my $p=$self->getParent();

   if (defined($p)){
      if ($p->can("ipcStore")){
         return($p->ipcStore(@_));
      }
   }
   return(undef);
}

sub getEventMethods
{
   my $self=shift;
   my $name=shift;

   if ($self->isEvent($name)){
      my @l=();
      foreach my $ev (@{$self->{Events}->{$name}}){
         push(@l,$ev->{method}); 
      }
      return(@l);
   }
   return();
}

sub getMaxEventTimeout
{
   my $self=shift;
   my $name=shift;

   if ($self->isEvent($name)){
      my $timeout=0;
      foreach my $ev (@{$self->{Events}->{$name}}){
         $timeout=$ev->{timeout} if ($timeout<$ev->{timeout});
      }
      return($timeout);
   }
   return(undef);
}

sub ProcessEvent
{
   my $self=shift;
   my $name=shift;
   my $param=shift;
   my $requestedmethod=shift;
   my @res=();

   if ($self->isEvent($name)){
      msg(DEBUG,"start ProcessEvent '$name'(%s)",join(@{$param->{param}}));
      $W5V2::EventContext=$name if (!defined($W5V2::EventContext));
      my $subindexstr="";
      if (defined($requestedmethod)){
         $subindexstr=" requested $requestedmethod";
      }
      msg(DEBUG,"in event '$name'%s",$subindexstr);
      foreach my $ev (@{$self->{Events}->{$name}}){
         $SIG{'USR1'}=sub{
          #  msg(WARN,"recive USR1 Signal at $name");
            $ev->{obj}->{ServerGoesDown}++;
         };
         if (!defined($requestedmethod) || $ev->{method} eq $requestedmethod){
            msg(DEBUG,"try to call '$ev->{method}'");
            my $res;
            {
               no strict 'refs';
               $res=&{$ev->{method}}($ev->{obj},@{$param->{param}});
            }
            $res={result=>$res} if (ref($res) ne "HASH");
            $res->{method}=$ev->{method} if (!defined($res->{method}));
            push(@res,$res);
         }
      }
   }
   else{
      msg(DEBUG,"ProcessEvent '$name' - this is no event");
   }
   msg(DEBUG,"end   ProcessEvent '$name'");
   $W5V2::EventContext=undef;
   return(@res);
}

sub setSkinBase
{
   my $self=shift;
   $self->{SkinBase}=$_[0];
}

sub SkinBase
{
   my $self=shift;
   return($self->{SkinBase});
}



sub ProcessTimer
{
   my $self=shift;

   msg(DEBUG,"ProcessTimer %s in pid=%d ppid=%d",time(),$$,getppid());
}

sub isEvent
{
   my $self=shift;
   my $name=shift;

   return(1) if (defined($self->{Events}->{$name}));
   return(0);
}


1;

