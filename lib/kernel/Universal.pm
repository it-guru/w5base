package kernel::Universal;
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
use UNIVERSAL;
use kernel;
use Carp;
use Scalar::Util qw(weaken);
use vars qw($AUTOLOAD);
@ISA    = qw(UNIVERSAL);
#our $AUTOLOAD;

sub Context
{
   my $self=shift;
   my $s=sprintf("-%s-",$self);
   $W5V2::Context->{$s}={} if (!exists($W5V2::Context->{$s}));
   return($W5V2::Context->{$s});
}

sub Cache
{
   my $self=shift;
   my $config=$self->Config;
   croak("ERROR: no config defined in $self Universal::Cache") if (!defined($config));
   my $s=$config->getCurrentConfigName();
   $W5V2::Cache={}       if (!defined($W5V2::Cache));
   $W5V2::Cache->{$s}={} if (!exists($W5V2::Cache->{$s}));
   return($W5V2::Cache->{$s});
}

sub UserEnv
{
   my $self=shift;
   my $UserCache=$self->Cache->{User}->{Cache};
   return($UserCache->{$ENV{REMOTE_USER}});
}

sub FullContextReset
{
   my $self=shift;
   Query->Reset();
   $W5V2::Context={};
}



sub getParent
{
   return($_[0]->{Parent});
}

sub setParent
{
   if (!defined($_[1])){
      delete($_[0]->{Parent});
      return();
   }
   $_[0]->{Parent}=$_[1];
   weaken($_[0]->{Parent});   
   return($_[0]->{Parent});
}

sub Init
{
   return(1);
}

sub Self
{
   my ($self)=@_;
   $self=~s/=.*$//;
   return($self);
}

sub SelfAsParentObject
{
   my $self=shift;
   return($self->Self());
}


sub getObjectTree
{
   my $self=shift;
   my @objtree=($self->Self());

   my $o=$self;
   while(my $parent=$o->getParent()){
      unshift(@objtree,$parent->Self()); 
      $o=$parent;
   }
   return(@objtree);
}

sub AUTOLOAD {
   my $self=shift;
   my @param=@_;
   my $name = $AUTOLOAD;

   my $type=ref($self) or die("$self is not an object ".join(",",$name));

   $name =~ s/.*://;   # strip fully-qualified portion
   return() if ($name eq "DESTROY");
   return(Dumper($self)) if ($name eq "Dumper");
   unless(exists $self->{_permitted}->{$name}){
      msg(ERROR,"Can't access '$name' field in class $type");
      msg(ERROR,"access only for %s",
                join(",",sort(keys(%{$self->{_permitted}}))));
      msg(ERROR,"call from '%s'",join(",",caller()));
      exit(1);
   }

   return(&{$self->{$name}}($self,@param)) if (ref($self->{$name}) eq "CODE");
   return($self->{$name}) if (exists($self->{$name}));
   return();
}

sub DESTROY
{
   my $self=shift;
   my $s=sprintf("-%s-",$self);
   delete($W5V2::Context->{$s});

}





######################################################################
1;
