package W5Warehouse::ExtOperationUser;
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
   
   $self->setWorktable("EXTOPERATIONUSER");
   $self->setDefaultView(qw(id dataobj itemid name email posix accesslevel));
   return($self);
}


1;
