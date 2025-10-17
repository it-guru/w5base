package W5Warehouse::itil__system;
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
   
   $self->setWorktable("ITIL__SYSTEM");
   $self->setDefaultView(qw(id name d_w5repllastsucc d_w5repllasttry));
   return($self);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;   # if $rec is undefined, general access to app is checked
   my %param=@_;

   return("ALL");
}



1;
