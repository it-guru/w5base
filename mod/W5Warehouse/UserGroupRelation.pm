package W5Warehouse::UserGroupRelation;
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
   
   $self->setWorktable("USERGROUPRELATION");
   $self->setDefaultView(qw(linenumber 
                            kontaktname
                            gruppenname
                            rollen));
   return($self);
}

1;
