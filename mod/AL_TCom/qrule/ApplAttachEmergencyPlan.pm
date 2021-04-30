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

Document name format: 
SCM_Emergency_Plan_ICTO-xxxx_DARWIN-Applicationname_jjjjmmdd.pdf 

If there is no Emergency Plan  document uploaded yet, 
please upload one in the above mentioned format. 

For further informations please contact Mr. Arlt ...

https://darwin.telekom.de/darwin/auth/base/user/ById/12651851320005

[de:]

Diese QualityRule prüft, ob ein Notfallplan Dokument hinterlegt ist.

Falls Sie ein DataIssue haben, bitten wir Sie das Format zu überprüfen.

Format:
SCM_Notfallplan_ICTO-xxxx_DARWIN-Applikationsname_jjjjmmdd.pdf 

Falls Sie bisher keinen Notfallplan hinterlegt hatten, bitten wir Sie dies 
im oben aufgezeigten Format nachzuholen.

Für nähere Informationen kontaktieren Sie bitte Hr. Arlt ...

https://darwin.telekom.de/darwin/auth/base/user/ById/12651851320005

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


   if ($rec->{ictoid} ne "" &&
       ($rec->{drclass} eq "4" || $rec->{drclass} eq "5" ||
        $rec->{drclass} eq "6" || $rec->{drclass} eq "7")){
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
         my $msg='no Emergency Plan attachment found / '.
                 'no valid naming for Emergency Plan attachment';
         push(@{$desc->{qmsg}},$msg);
         if (lc($rec->{businessteam}) eq "extern"){
            $exitcode=2 if ($exitcode<2);
         }
         else{
            $exitcode=3 if ($exitcode<3);
            push(@{$desc->{dataissue}},$msg);
         }
      }
   }
   else{
      return(undef);
   }


   return($exitcode,$desc);
}




1;
