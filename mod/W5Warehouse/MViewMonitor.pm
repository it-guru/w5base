package W5Warehouse::MViewMonitor;
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
   
   $self->setWorktable("MVIEWMON");
   $self->setDefaultView(qw( 
                            d_last_refresh_date
                            name
                            d_last_refresh_type
                            d_next_refresh_date
                            failcount
                            is_broken));
   return($self);
}

1;
