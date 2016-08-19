package AL_TCom::qrule::ApplAttachSystemOverview;
#######################################################################
=pod

=head3 PURPOSE

Check if a prio1 application has a SystemOverview Attachment.

=head3 IMPORTS

NONE

=head3 HINTS
This rule checks whether a system environment document with relevant 
communication relations is present on a top application (priority 1).

In case of a data issue, please check the name of the recorded document.

Document name format should be: 
ICTO-xxxx_Applikationsnamexxxx_SystemOverview_jjjjmmdd.pdf 

If there is no System Overview document uploaded yet, 
please upload one in the above mentioned format. 

Background: 
To speed up and to reduce the incident handling process in our complex 
application landscape, a system environment document with all 
communication relations is necessary.
 
Requested by TelekomIT Service Management on 08/16 
(https://darwin.telekom.de/darwin/auth/base/user/ById/13559244960000)


[de:]

Bei jeder TOP-Anwendung (Priorität 1) in W5Base/Darwin wird geprüft, 
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


   if ($rec->{customerprio}==1){
      if ($rec->{ictoid} ne ""){
         my $nameexpr=$rec->{ictono}."_xxxxx_SystemOverview_jjjjmmtt.pdf";
         my $ne=qr/^$rec->{ictono}_.+_SystemOverview_\d{8}\.pdf$/;
         my $found=0;

         if (exists($rec->{attachments}) &&
             ref($rec->{attachments}) eq "ARRAY"){
            foreach my $a (@{$rec->{attachments}}){
               if ($a->{name}=~m/$ne/){
                  $found++;
               }
            }
         }
         if (!($found)){
            $exitcode=3 if ($exitcode<3);
            push(@{$desc->{qmsg}},
                 $self->T('there is no SystemOverview attachment found'));
            push(@{$desc->{qmsg}},
                 $self->T('requested SystemOverview name').": ".$nameexpr);
            push(@{$desc->{dataissue}},
                 $self->T('there is no SystemOverview attachment found'));
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
