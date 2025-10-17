package AL_TCom::qrule::ApplDesc;
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
   return(["AL_TCom::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   if ($rec->{description}=~m/^\s*$/){
      $exitcode=3 if ($exitcode<3);
      push(@{$desc->{qmsg}},
           $self->T('there is no description defined'));
      push(@{$desc->{dataissue}},
           $self->T('there is no description defined'));
      push(@{$desc->{solvtip}},
           $self->T('descripe the application'));
   }

   if ($rec->{maintwindow}=~m/^\s*$/){
      $exitcode=1 if ($exitcode<1);
      push(@{$desc->{qmsg}},
           $self->T('there is no maintenence window defined'));
      push(@{$desc->{solvtip}},
           $self->T('define a maintenence window for the application'));
   }

   if ($rec->{currentvers}=~m/^\s*$/){
      $exitcode=1 if ($exitcode<1);
      push(@{$desc->{qmsg}},
           $self->T('there is no application version entered'));
      push(@{$desc->{solvtip}},
           $self->T('documentated the application version'));
   }
   return($exitcode,$desc);
}




1;
