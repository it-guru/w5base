# This is W5BB

package w5bb;
use strict;
use vars qw(@ISA);
@ISA=qw(W5Module);

sub new
{  
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

