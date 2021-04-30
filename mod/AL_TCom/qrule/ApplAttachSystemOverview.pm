package AL_TCom::qrule::ApplAttachSystemOverview;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Check if a prio1 application has a SystemOverview Attachment.

=head3 IMPORTS

NONE

=head3 HINTS
This rule checks whether a system environment document with relevant 
communication relations is present on a production or desaster recovery application.

In case of a data issue, please check the name of the recorded document.

Document name format should be: 
ICTO-xxxx_Applikationsnamexxxx_SystemOverview_jjjjmmdd.pdf 

If there is no System Overview document uploaded yet, 
please upload one in the above mentioned format. 

Background: 
To speed up and to reduce the incident handling process in our complex 
application landscape, a system environment document with all 
communication relations is necessary.

It is not allowed to mark the system overview as private. Marking the system overview as private generates a dataissue.
 
Requested by TelekomIT Service Management on 08/16 
(https://darwin.telekom.de/darwin/auth/base/user/ById/13559244960000)


[de:]

Bei jeder Produktions- und Katastrophenfall-Anwendung in W5Base/Darwin wird geprüft, 
ob ein Dokument zur Systemumgebung mit den relevanten 
Kommunikationsbeziehungen hinterlegt wurde.

Falls Sie ein DataIssue haben bitten, wir Sie das Format zu überprüfen.

Formatvorgabe:  ICTO-xxxx_Applikationsnamexxxx_SystemOverview_jjjjmmdd.pdf 

Falls Sie bisher keine SystemOverview hinterlegt hatten, bitten wir Sie dies 
im oben aufgezeigten Format nachzuholen.

Hintergrund:
Bei der Incident-Bearbeitung in unserer komplexen Anwendungslandschaft ist 
eine dokumentierte Systemumgebung mit relevanten Kommunikationsbeziehungen 
ein wichtiges Arbeitsmittel um die Ursachensuche zu beschleunigen und damit 
mögliche Ausfallzeiten zu reduzieren. 

Es ist nicht erlaubt, die SystemOverview Anlage als vertraulich zu markieren  dies generiert sonst ein DataIssue.

Anforderungsrequest 08/16:
Anforderung durch 'TelekomIT Service Management'
(https://darwin.telekom.de/darwin/auth/base/user/ById/13559244960000)


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
   return(["TS::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   return($exitcode,$desc) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);


   if ($rec->{opmode} eq "prod" || $rec->{opmode} eq "cbreakdown"){
      if ($rec->{ictoid} ne ""){
         my $nameexpr=$rec->{ictono}."_xxxxx_SystemOverview_jjjjmmtt.pdf";
         my $ne=qr/^$rec->{ictono}_.+_SystemOverview_\d{8}\.pdf$/;
         my $found=0;
         my $foundasprivate=0;

         if (exists($rec->{attachments}) &&
             ref($rec->{attachments}) eq "ARRAY"){
            foreach my $a (@{$rec->{attachments}}){
               if ($a->{name}=~m/$ne/){
                  if ($a->{isprivate}){
                     $foundasprivate++;
                  }
                  $found++;
               }
            }
         }
         if (!($found)){
            my @msg=('no SystemOverview attachment found / '.
                     'no valid naming for SystemOverview attachment',
                     'requested SystemOverview name'.": ".$nameexpr);
            push(@{$desc->{qmsg}},@msg);
            if (lc($rec->{businessteam}) eq "extern"){
               $exitcode=2 if ($exitcode<2);
            }
            else{
               $exitcode=3 if ($exitcode<3);
               push(@{$desc->{dataissue}},$msg[0]);
            }
         }
         if ($foundasprivate){
            $exitcode=3 if ($exitcode<3);
            my $m='it is not allowed to mark SystemOverview '.
                  'attachment as privacy';
            push(@{$desc->{qmsg}},$m);
            push(@{$desc->{dataissue}},$m);
         }
      }
      else{
         return(undef);
      }
   }
   else{
      return(undef);
   }
   return($exitcode,$desc);
}




1;
