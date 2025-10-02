package kernel::Input::CsvV01;

use vars qw(@ISA);
use strict;
use kernel;
use kernel::Universal;
use Data::Dumper;

@ISA=qw(kernel::Universal);
   
sub new
{  
   my $type=shift;
   my $parent=shift;
   my $self=bless({},$type);

   $self->setParent($parent);

   return($self);
}

sub getIconName
{
   my $self=shift;
   return("icon_csv");
}





sub SetInput
{
   my $self=shift;
   my $file=shift;


   return(undef);
}
   
sub getNext
{
   my $self=shift;


   return(undef);
}
   


