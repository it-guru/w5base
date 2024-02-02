package W5Warehouse::W5USULICMGMT_SYSTEM;
use strict;
use vars qw(@ISA);
use kernel;
use W5Warehouse::lib::Listedit
@ISA=qw(W5Warehouse::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->setWorktable("W5USULICMGMT_SYSTEM");
   $self->setDefaultView(qw(systemname systemcistatus systemid w5baseid));
   return($self);
}


1;
