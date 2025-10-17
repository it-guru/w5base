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
   
   $self->setWorktable("SYSTEMHARDENING");
   $self->setDefaultView(qw(linenumber 
                            applicationid
                            anwendungsname 
                            icto_id
                            systemname 
                            ip_adresse));
   return($self);
}

1;
