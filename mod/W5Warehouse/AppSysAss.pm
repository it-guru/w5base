package W5Warehouse::AppSysAss;
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
   
   $self->setWorktable("APPSYSASS");
   $self->setDefaultView(qw(linenumber 
                            w5_app_name 
                            w5_sys_systemname 
                            w5_ass_assetid));
   return($self);
}

1;
