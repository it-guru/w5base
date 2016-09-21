package tssm::qrule::Change;
=pod

=encoding latin1

=head3 PURPOSE

B<Checks the compliance with change quality rules>

This check performs an automatic test of compliance with the mandatory data in a change, based on the specifications from Changemanagement process.

This test can be a precheck only.
The final quality-check is a task of the Changemanager.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

All hints refer on fields in Change/Task in ServiceCenter COSIMA.

* no customer defined in change * 
Fill field Customer under General - Additional Info

* requested from empty * 
Fill field Requested from under General - Additional Info

* requested from extern, but extern change id missing *
Changes initiated by delivery have to be marked as intern under General - Requested from.
All others, e.g. Telekom IT as extern.

* extern change id existing, but requested from intern * 
For delivery-initiated Changes can not exist an extern RfC.

* coordinator missing * 
Before a change will be confirmed, a contact has to be recorded under Personel - Change Coordinator/ChangeMgr - Assignment Information. 

* changemanager missing * 
To fill this field is exclusively a task from Changemanagement!
Otherwise it could occur a time-delay from CHM.
The change has to be confirmed before.

* check backout method *
Fill Description - Back-out Method.

* check validation *
Fill Description - Validation. 

* check Risk of Omission * 
Fill Description - Risk - Risk of Omission.
What would be the consequence, if the change does not occour. 

* check Risk of Implementation * 
Fill Description - Risk - Risk of Implementation.
Negative effects, if occurs something unplanned.

* check Impact Description * 
Fill Description - Impact Description.
The planned effects on the service. 

* check Target of Change * 
Fill Description - Cause/Target - Target of Change.

* approver groups missing * 
Check if really no approver have to be involved.
Changes concerning Telekom IT, have at least to contain the approver-group of the Changemanagement-Team.
Exception: Change Type standard.

* no valid config item in change * 
Change has at least to contain one valide Config Item. 

* no valid application in change * 
Check if really no application is concerned.

* emergency-change without relation to inm-ticket prio 1 or 2 * 
Emergency-Changes have to be related with an Incident-Ticket Prio 1 or 2.
Make the relation over Relations - Incidents - Associate.

* no tasks * 
All activities in a change takes place in tasks.
Add tasks. 

+++ Check of the tasks +++ 

* no QS-Task found * 
No QS-Task could be identified.
QS-Tasks will be found with help of the term QS or QA in the brief description.

* not yet all tasks confirmed * 
Change is confirmed, but not all tasks. Confirm tasks. 

* PSO-flag not set *
The brief description contains the term PSO or Auszeit or Downtime, but the PSO-Flag in the task is not set.
Set PSO-Flag or adjust the brief description.

* PSO-flag probably wrong set * 
The PSO-Flag in the task is set, but no reference on it were found (PSO, Auszeit or Downtime).
Unset PSO-Flag or adjust the brief description.

* implementer missing * 
Befor a task will be confirmed, a contact has to be registered under Personel - General - Assignment Information.

* no valid config item in task *
Fill in valid Config Item(s) under Configuration Item - Associate

* no valid application in PSO-Task * 
PSO refers on the service. Therefore a PSO-Task has to contain a valid application.

[de:]

Alle Hinweise zur Fehlebeseitigung beziehen sich auf die angegebenen Felder im Change/Task in ServiceCenter COSIMA.


* kein Kunde (Customer) eingetragen *

Feld Customer unter General - Additional Info füllen


* Requested from nicht befüllt *

Feld Requested from unter General - Additional Info füllen


* Requested from extern, aber extern Change ID leer *

Changes, die durch die Delivery initiiert werden, sind unter General - Requested from als intern zu markieren. Alles andere, z.B. Telekom It, als extern.
Bei externen Changes ist unter General - Extern Change ID die Referenz auf den RfC einzutragen, falls dieser über ein externes Tool beuaftragt wurde.


* Extern Change ID eingetragen, aber Requested from intern *

Bei Delivery initiierten Changes kann es keinen externen RfC geben


* kein Koordinator eingetragen *

Bevor ein Change confirmed wird, muss unter Personel - Change Coordinator/ChangeMgr - Assignment Information ein Kontakt eingetragen werden.


* noch kein Change Manager eingetragen *

Dieser Eintrag darf ausschließlich vom Changemanagement gemacht werden!
Ansonsten könnte es zu Zeitverzögerungen durch das CHM kommen.
Vorher muss der Change confirmed sein.


* Fallback-Beschreibung (Back-out Method) prüfen *
Description - Back-out Method befüllen.


* Validation prüfen *
Description - Validation befüllen.


* Risk of Omission prüfen *

Description - Risk - Risk of Omission befüllen.
Was wären die Folgen, wenn der Change nicht stattfindet.


* Risk of Implementation prüfen *

Description - Risk - Risk of Implementation befüllen. Negative Auswirkungen, wenn etwas ungeplantes passiert. 


* Impact Description prüfen *

Description - Impact Description befüllen. Geplante Auswirkungen auf den Service.


* Target of Change prüfen *

Description - Cause/Target - Target of Change befüllen. Was soll mit dem Change erreicht werden?


* keine Approver-Gruppen eingetragen *

Prüfen, ob wirklich keine Approver eingebunden werden müssen. Changes, die Telekom IT betreffen, benötigen mindestens die Approver-Gruppe des Changemanagent-Teams. Ausnahme: Change Typ standard.


* kein valides Configuration Item im Change *

Change muss mindestens ein valides Config Item enthalten.


* keine valide Anwendung im Change *

Prüfen, ob wirklich keine Applikation betroffen ist.


* emergency-Change ohne Verknüpfung mit INM-Ticket Prio 1 oder 2 *

Emergency-Changes müssen mit einem Incident-Ticket Prio 1 oder 2 verknüpft sein.
Über Relations - Incidents - Associate Verknüpfung herstellen.


* Change enthält keine Tasks *

Sämtliche Aktivitäten eines Changes werden in Tasks abgebildet. Tasks hinzufügen.


+++ Prüfung der Tasks +++


* keinen QS-Task gefunden *

Es konnte kein QS-Task identifiziert werden.
QS-Tasks werden anhand des Begriffs QS oder QA in der Brief Description erkannt.


* noch nicht alle Tasks confirmed *

Change ist confirmed, aber noch nicht alle Tasks. Tasks confirmen.


* PSO-Flag nicht gesetzt *

Es wurde einer der Begriffe PSO oder Auszeit oder Downtime in der Brief Description gefunden, aber das PSO-Flag in der Task ist nicht gesetzt. PSO-Flag setzen oder Brief Description anpassen.


* PSO-Flag möglicherweise falsch gesetzt *

Das PSO-Flag in der Task ist gesetzt, es wurde aber kein Hinweis darauf in der Brief Description gefunden (PSO, Auszeit oder Downtime). PSO-Flag löschen oder Brief Description anpassen


* kein Implementer eingetragen *

Bevor ein Task confirmed wird, muss unter Personel - General - Assignment Information ein Kontakt eingetragen werden.


* kein gültiges Config Item im Task *

Unter Configuration Item - Associate valide Config Item(s) eintragen.


* keine gültige Anwendung im PSO-Task *

PSO bezieht sich auf den Service. Eine PSO-Task muss demnach eine valide Applikation enthalten.

=cut

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
   return(["tssm::chm"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my @qmsg;
   my $exitcode=0;
   # Customer?
   if ($rec->{rawcustomer} =~m/^\s*$/){
      push(@qmsg,"no customer defined in change");
      $exitcode=3;
   }
   # Requested from
   if ($rec->{requestedfrom} =~m/^\s*$/){
      push(@qmsg,"requested from empty");
      $exitcode=3;
   }
   # Requested from extern and extern Change ID missing
   if ($rec->{requestedfrom} eq 'extern' && $rec->{srcid}=~m/^\s*$/){
      push(@qmsg,"requested from extern, but extern change id missing");
      $exitcode=3;
   }
   # Requested from intern but extern Change existing
   if ($rec->{requestedfrom} eq 'intern' && $rec->{srcid}=~m/\S+/){
      push(@qmsg,"extern change id existing, but requested from intern");
      $exitcode=3;
   }
   # assigned worker in change (Coordinator)
   if ($rec->{coordinator}=~m/^\s*$/){
      push(@qmsg,"coordinator missing");
      $exitcode=3;
   }
   # changemanager userid
   if ($rec->{type} ne 'standard' && $rec->{coordinatorposix}=~m/^\s*$/){
      push(@qmsg,"changemanager missing");
      $exitcode=3;
   }
   # backout method
   if (length($rec->{fallback})<10){
      push(@qmsg,"check backout method");
      $exitcode=3;
   }
   # validation
   if (length($rec->{validation})<10){
      push(@qmsg,"check validation");
      $exitcode=3;
   }
   # risk of omission
   if (length($rec->{riskomission})<10){
      push(@qmsg,"check risk of omission");
      $exitcode=3;
   }
   # risk of implementation
   if (length($rec->{riskimplementation})<10){
      push(@qmsg,"check risk of implementation");
      $exitcode=3;
   }
   # impact description
   if (length($rec->{impactdesc})<10){
      push(@qmsg,"check impact description");
      $exitcode=3;
   }
   # target of change
   if (length($rec->{chmtarget})<10){
      push(@qmsg,"check target of change");
      $exitcode=3;
   }
   # approver groups
   if ($rec->{type} ne 'standard' && $rec->{addgrp}=~m/^\s*$/){
      push(@qmsg,"approver groups missing");
      $exitcode=3;
   }
   # config items
   {
      my ($validCi, $validAppl);

      foreach my $ci (@{$rec->{configitems}}) {
         if ($ci->{civalid}) {
            $validCi = 1;
            if ($ci->{dstmodel} eq 'APPLICATION') {
               $validAppl = 1;
               last;
            }
         }
      }

      if (!$validCi) {
         push(@qmsg,"no valid config item in change");
         $exitcode=3;
      } elsif (!$validAppl) {
         push(@qmsg,"no valid application in change");
         $exitcode=3;
      }
   }
   # related INM-Ticket if emergency
   if ($rec->{urgency} eq 'emergency') {
      my $hasTicket;
      foreach my $ticket (@{$rec->{tickets}}) {
         next if $ticket->{dstobj} ne 'tssm::inm';
         if ($ticket->{priority} <= 2) {
            $hasTicket = 1;
            last;
         }
      }
      unless ($hasTicket) {
         push(@qmsg,"emergency-change without relation to inm-ticket prio 1 or 2");
         $exitcode=3;
      }
   }
   # tasks
   unless (@{$rec->{tasks}}) {
      push(@qmsg,"no tasks");
      $exitcode=3;
   }

   {
      my $psoInBriefDesc = qr/PSO|Auszeit|[Dd]owntime/;
      my $qsInBriefDesc  = qr/QS|QA/;
      my $hasQsTask;
      my $notAllConfirmed;

      foreach my $task (@{$rec->{tasks}}) {
         my $validCi;
         my $validApp;
         my $isPso;

         # QS-Task
         $hasQsTask = 1 if ($task->{name}=~m/$qsInBriefDesc/); 

         # not all tasks confirmed
         if ($rec->{status}  ne 'planning' &&
             $task->{status} eq 'planning') {
            $notAllConfirmed = 1;
         }

         # PSO-Flag not set
         if ($task->{name}=~m/$psoInBriefDesc/) {
            if ($task->{cidown}) {
               $isPso = 1;
            } else {
               push(@qmsg,"PSO-flag not set: ".$task->{tasknumber});
               $exitcode=3;
            }
         }
         # PSO-Flag wrongly set
         if (!($task->{name}=~m/$psoInBriefDesc/) && $task->{cidown}) {
            push(@qmsg,"PSO-flag probably wrong set: ".$task->{tasknumber});
            $exitcode=3;
         }
         # Implementer
         if ($task->{implementer}=~m/^\s*$/) {
            push(@qmsg,"implementer missing: ".$task->{tasknumber});
            $exitcode=3;
         }
         # valid CI
         foreach (@{$task->{relations}}) {
            $validCi  = 1 if ($_->{dstmodel});
            $validApp = 1 if ($_->{dstmodel} eq 'APPLICATION'); 
         }
         if (!$validCi) { # valid CI in normal task
            push(@qmsg,"no valid config item in task: ".$task->{tasknumber});
            $exitcode=3;
         }
         if ($isPso && !$validApp) { # valid application in PSO-Task
            push(@qmsg,"no valid application in PSO-Task: ".$task->{tasknumber});
            $exitcode=3;
         }
      }
      unless ($hasQsTask) {
         push(@qmsg,"no QS-Task found");
         $exitcode=3;
      }
      if ($notAllConfirmed) {
         push(@qmsg,"not yet all tasks confirmed");
         $exitcode=3;
      }
   }

   my $desc={qmsg=>\@qmsg};
   return($exitcode,$desc);
}



1;
