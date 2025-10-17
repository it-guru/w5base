package AL_TCom::qrule::ApplAttachSystemOverview;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Check if IT application has a SystemOverview Attachment.

=head3 IMPORTS

NONE

=head3 HINTS

Darwin checks whether a system environment document (short graphical overview - 1-2 pages) eventually with relevant communication relations is uploaded for every application in production and its disaster recovery environment. 
In case of a data issue, please check the name of the recorded document.

Prescribed document format is: 
ICTO-xxxx_Application_name_SystemOverview_yyyymmdd.pdf

A DataIssue is created if:

-   No document is uploaded

-   The uploaded document does not have the prescribed format (pdf)

-   The name of the uploaded document does not correspond to the prescribed naming convention (see above)

If there is no System Overview document uploaded yet, please upload one in the above mentioned format.

Background: a system environment document with all communication relations is necessary to speed up and to reduce the incident handling process in our complex application landscape.

It is not allowed to mark the system overview as private. Marking the system overview as private generates a DataIssue.

Further information you can find on Disaster Recovery FAQ site at intranet:

https://yam-united.telekom.com/pages/problem-management-telekom-it/apps/wiki/dr-faq/list/view/435cc4fa-558c-4354-9d43-2cd19482000b

In case of any questions please contact our FMB:
DR_Disaster_Recovery_Test@telekom.de

[de:]

Bei jeder Produktionsanwendung (inklusive deren DR Umgebung) wird in Darwin geprüft, ob ein Dokument zur Systemumgebung (kurze grafische Übersicht - 1-2 Seiten) ggf. mit den relevanten Kommunikationsbeziehungen hinterlegt wurde.

Formatvorgabe: 
ICTO-xxxx_Applikationsname_SystemOverview_jjjjmmdd.pdf

Ein DataIssue wird erzeugt, wenn:

- Kein Dokument hinterlegt ist

- Das hinterlegte Dokument nicht das vorgegebene Format hat (pdf)

- Der Name des hinterlegten Dokuments nicht der o.g. Formatvorgabe entspricht


Falls Sie bisher keine SystemOverview hinterlegt hatten, ist dies im oben aufgezeigten Format nachzuholen.

Hintergrund: Bei der Incident-Bearbeitung in unserer komplexen Anwendungslandschaft ist eine dokumentierte Systemumgebung mit relevanten Kommunikationsbeziehungen ein wichtiges Arbeitsmittel um die Ursachensuche zu beschleunigen und damit mögliche Ausfallzeiten zu reduzieren.

Es ist nicht erlaubt, die SystemOverview Anlage als vertraulich zu markieren - dies generiert sonst ein DataIssue.

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
