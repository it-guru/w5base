package AL_TCom::qrule::ApplAttachEmergencyPlan;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Check if a active application has a EmergencyPlan Attachment.

=head3 IMPORTS

NONE

=head3 HINTS

This rule checks whether an emergency plan document is uploaded.

Prescribed document format is: 

SCM_Emergency_Plan_ICTO-xxxx_Application_name_yyyymmdd.pdf


A DataIssue is created if:

-   No document is uploaded

-   The uploaded document does not have the prescribed format (pdf)

-   The name of the uploaded document does not correspond to the prescribed naming convention (see above)


If there is no Emergency Plan document uploaded yet, please upload one in the above mentioned format.

Further information you can find on Disaster Recovery FAQ site at intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b

In case of any questions please contact our FMB:
DR_Disaster_Recovery_Test@telekom.de


[de:]

Diese QualityRule prüft, ob ein Notfallplan Dokument hinterlegt ist.

Formatvorgabe: 

SCM_Notfallplan_ICTO-xxxx_Applikationsname_jjjjmmdd.pdf


Ein DataIssue wird erzeugt, wenn:

- Kein Dokument hinterlegt ist

- Das hinterlegte Dokument nicht das vorgegebene Format hat (pdf)

- Der Name des hinterlegten Dokuments nicht der o.g. Formatvorgabe entspricht


Falls Sie bisher keinen Notfallplan hinterlegt hatten, dies ist im oben aufgezeigten Format nachzuholen.

Weiterführende Informationen finden Sie auch auf unserer FAQ Seite im Intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b

Bei Fragen wenden Sie sich bitte an unsere FMB:
DR_Disaster_Recovery_Test@telekom.de


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
        $rec->{drclass} eq "6" || $rec->{drclass} eq "7" ||
        $rec->{drclass} eq "11" || $rec->{drclass} eq "14" ||
        $rec->{drclass} eq "18")){
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
