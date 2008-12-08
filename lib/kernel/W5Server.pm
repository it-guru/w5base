package kernel::W5Server;
use strict;
use kernel;
use kernel::Universal;
use vars(qw(@ISA));

@ISA=qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub Config
{
   return($_[0]->getParent->Config());
}

sub Init
{
   return(1);
}

sub start
{
   my $self=shift;
   printf STDERR ("W5Server start ($self)\n");
}

sub process
{
   my $self=shift;
   while(1){
      printf STDERR ("W5Server process ($self)\n");
      sleep(1);
   }
}

sub end
{
   my $self=shift;
   printf STDERR ("W5Server end ($self)\n");
}

sub reload
{
   my $self=shift;
   printf STDERR ("W5Server reload ($self)\n");
}



1;

