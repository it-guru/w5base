package AL_TCom::qrule::ApplAttachEmergencyPlan;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Check if a active application has a EmergencyPlan Attachment.

=head3 IMPORTS

NONE

=head3 HINTS
This rule checks whether a emergency plan document is present.

In case of a data issue, please check the name of the recorded document.

Document name format should be: 
SCM_Emergency_Plan_ICTO-xxxx_DARWIN-Applicationname_jjjjmmdd.pdf 

If there is no Emergency Plan  document uploaded yet, 
please upload one in the above mentioned format. 


[de:]
Diese QualityRule prüft, ob ein Notfallplan Dokument hinterlegt ist.

Falls Sie ein DataIssue haben bitten, wir Sie das Format zu überprüfen.

SCM_Notfallplan_ICTO-xxxx_DARWIN-Applikationsname_jjjjmmdd.pdf 

Falls Sie bisher keine SystemOverview hinterlegt hatten, bitten wir Sie dies 
im oben aufgezeigten Format nachzuholen.


=cut
#######################################################################
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
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);


   if ($rec->{ictoid} ne ""){
      my @nameexpr;
     
      my $ne=qr/^SCM_Emergency_Plan_$rec->{ictono}_.+_\d{8}\.pdf$/;
      push(@nameexpr,$ne);

      my $ne=qr/^SCM_Notfallplan_$rec->{ictono}_.+_\d{8}\.pdf$/;
      push(@nameexpr,$ne);

      my $found=0;

      if (exists($rec->{attachments}) &&
          ref($rec->{attachments}) eq "ARRAY"){
         foreach my $a (@{$rec->{attachments}}){
            foreach my $ne (@nameexpr){
               if ($a->{name}=~m/$ne/){
                  $found++;
               }
            }
         }
      }
      if (!($found)){
         $exitcode=3 if ($exitcode<3);
         push(@{$desc->{qmsg}},
              $self->T('there is no Emergency Plan attachment found'));
         push(@{$desc->{dataissue}},
              $self->T('there is no Emergency Plan attachment found'));
      }
   }
   else{
      return(undef);
   }


   return($exitcode,$desc);
}




1;
