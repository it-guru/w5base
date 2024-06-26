package W5Warehouse::SWInstanceExtOperationUser;
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
   
   $self->setWorktable("SWINSTANCEEXTOPERATIONUSER");
   $self->setDefaultView(qw(id swinstanceid name email posix accesslevel));
   return($self);
}


1;
