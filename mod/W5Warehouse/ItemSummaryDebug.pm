package W5Warehouse::ItemSummaryDebug;
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
   
   $self->setWorktable("ITEMSUMMARYDEBUG");
   $self->setDefaultView(qw(linenumber 
                            name 
                            cistatus 
                            mgmtitemgroup
                            dataissuecicount
                            dataissuefailcount
                            ));
   return($self);
}

1;
