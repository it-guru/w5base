package W5Warehouse::Systemhardening;
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
   
   $self->setWorktable("Systemhardening");
   $self->setDefaultView(qw(linenumber 
                            anwendungsname 
                            systemname ));
   return($self);
}

1;
