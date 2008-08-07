package tssc::qrule::Change;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["tssc::chm"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my @qmsg;
   my $exitcode=0;
   if ($rec->{rawcustomer} =~m/^\s*$/){
      push(@qmsg,"no customer defined in change");
      $exitcode=3;
   }
   if ($rec->{impact} =~m/^\s*$/){
      push(@qmsg,"no impact defined in change");
      $exitcode=3;
   }
   my $desc={qmsg=>\@qmsg};
   return($exitcode,$desc);
}




1;
