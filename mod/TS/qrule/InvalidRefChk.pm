package TS::qrule::InvalidRefChk;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if there are contact or group references in the current
record, whitch are marked as "disposed of waste".
This qrule can check fields with type ...
kernel::Field::ContactLnk
kernel::Field::Contact
kernel::Field::Group
kernel::Field::Databoss
The rule removes references to contact or group enties, where the
target record is in state "wasted".

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Prüft, ob der Datensatz veraltete Kontaktreferenzen enthält. 
Ungültige Kontakte oder Gruppen im aktuellen Datensatz erkennt man 
anhand einer Nummer in eckigen Klammern am Ende des Kontaktes. 
Ein DataIssue wird erzeugt, wenn ein Datensatz einen oder mehrere 
veraltete Kontakt/Gruppenreferenzen enthält. Um das DataIssue zu beheben, 
muss man veraltete Kontakte am Datensatz finden und entfernen oder 
bei Bedarf durch neue Kontakpersonen bzw. Gruppen mit entsprechenden 
Rollen ersetzen.

Die QualityRule entfernt Referenzen auf Kontakte oder Gruppen, bei denen
der Zieldatensatz im Status "entsorgt" steht.
Zusätzlich werden Referenzen auf Kontakte oder Gruppen entfernt, bei
denen der Kontakt länger als 4 Wochen im Status "veraltet/gelöscht"
steht. Werden Datenverantwortliche erkannt, die länger als 4 Wochen
nicht gültig sind, werden diese automatisch durch den letzten bekannten
Projekt-Vorgesetzten ersetzt. Wird kein letzter bekannter 
Projekt-Vorgesetzter gefunden, so wird der letzten bekannte Vorgesetzte
verwendet.

Alle Veränderungen der Kontakte werden an den Datenverantwortlichen
per E-Mail notifiziert.

Bei Fragen wenden Sie sich bitte an den DARWIN Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[en:]

Checks, if there are invalid contact references on the CI. 
Invalid contacts or groups can be identified 
by a number in square brackets at the end. 
A DataIssue is created when there are one or more invalid contacts on the CI. 
The DataIssue can be resolved by finding and deleting 
the invalid contact references. 
If necessary, new users or groups with the corresponding roles can be added.

In addition, references to contacts or groups are also removed when
in the status "disposed of waste" for more than 4 weeks.
If databosses are identified who have for more than 4 weeks
are not valid, they are automatically replaced by the last known
project-superiors. If no project-superiors is found, the last 
known superiors is used.

All changes of the contacts will be forwarded to the databoss as
by e-mail.

If you have any questions please contact the Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use vars qw(@ISA);
use kernel;
use base::qrule::InvalidRefChk;
@ISA=qw(base::qrule::InvalidRefChk);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub setReferencesToNull
{
   my $self=shift;
   my $dataobj=shift;
   my $reason=shift;
   my $ref=shift;
   my $rec=shift;
   my $contactrec=shift;

   my $ReferenceIsStillInvalid=1;

   my $idfield=$dataobj->IdField();

   if ((!defined($contactrec) || $contactrec->{cistatusid}==7) ||
       (defined($contactrec) && $contactrec->{cistatusid}==6)){
      my $contact_old_enought=1;
      my $contact_age_days;
      if (defined($contactrec) && exists($contactrec->{mdate}) &&
          $contactrec->{mdate} ne "" &&
          $contactrec->{cistatusid}==6){   # only cistatusid==6 gets a check
         my $now=NowStamp("en");           # on old enought
         my $d=CalcDateDuration($contactrec->{mdate},$now,"GMT");
         my $max=7*4;  # check only if application record is older than 4 weeks
         if (!defined($d) || $d->{days}<$max){
            $contact_old_enought=0;
            $contact_age_days=$d->{days};
            #msg(INFO,"contact is bad but not old enouth");
         }
      }
      if (defined($idfield)){
         my $idname=$idfield->Name();
         if ($ref->{type} ne "ContactLnk"){
            if ($ref->{type} ne "Databoss" ||
                (exists($rec->{cistatusid}) &&  # if record is marked as 
                 $rec->{cistatusid}>5)){        # delete, databoss can
                                                # be set to NULL
               if (!defined($contactrec) || 
                   $contactrec->{cistatusid}==7 
                  # || ($contactrec->{cistatusid}==6 &&  # cleanup if chkrec
                  #  exists($rec->{cistatusid}) &&       # self is already
                  #  $rec->{cistatusid}>5)               # marked as delete
                   ){
                  # nur entsorgte Rollen sollen geNULLt werden
                  # https://darwin.telekom.de/darwin/auth/base/workflow/ById/15053783010001
                  if ($dataobj->UpdateRecord({$ref->{rawfield}=>undef},
                                         {$idname=>\$rec->{$idname}})){
                     $dataobj->StoreUpdateDelta("update",
                        {$ref->{rawfield}=>$rec->{$ref->{rawfield}},
                         $idname=>$rec->{$idname}},
                        {$ref->{rawfield}=>undef,
                         $idname=>$rec->{$idname}},
                         $self->Self().
                         "\nContact cistatus=$contactrec->{cistatusid}");
                     $self->NotifyContactDataModification("roledel",
                                                   $dataobj,$reason,$ref,
                                                   $rec,$contactrec);
                     $ReferenceIsStillInvalid=0;
                  }
               }
            }
            else{
               # set lastknownbossid as new databoss
               my @lastknownboss;
               if ($contactrec->{lastknownpbossid} ne ""){
                  push(@lastknownboss,sort(split(/\s+/,
                                          $contactrec->{lastknownpbossid})));
               }
               if ($contactrec->{lastknownbossid} ne ""){
                  push(@lastknownboss,sort(split(/\s+/,
                                           $contactrec->{lastknownbossid})));
               }
               BLOOP: foreach my $lastbossid (@lastknownboss){
                  my $o=getModuleObject($dataobj->Config,"base::user");
                  $o->SetFilter({userid=>\$lastbossid});
                  my ($newbossrec,$msg)=$o->getOnlyFirst(qw(usertyp 
                                                            cistatusid
                                                            groups)); 
                  my $is_currently_boss=0;
                  if (ref($newbossrec) eq "HASH" &&
                      ref($newbossrec->{groups}) eq "ARRAY"){
                     foreach my $grprec (@{$newbossrec->{groups}}){
                        if (ref($grprec->{roles}) eq "ARRAY" &&
                            grep(/^RBoss$/,@{$grprec->{roles}})){
                           $is_currently_boss++;
                        }
                     }
                  }
                  if (defined($newbossrec) &&
                      $is_currently_boss>0 &&
                      $newbossrec->{cistatusid} eq "4" &&
                      $newbossrec->{usertyp} eq "user"){
                     if ($contact_old_enought){
                        my $bk=$dataobj->UpdateRecord({
                              $ref->{rawfield}=>$lastbossid
                           },{$idname=>\$rec->{$idname}});
                        if ($bk){
                           $dataobj->StoreUpdateDelta("update",
                              {$ref->{rawfield}=>$rec->{$ref->{rawfield}},
                               $idname=>$rec->{$idname}},
                              {$ref->{rawfield}=>$lastbossid,
                               $idname=>$rec->{$idname}},
                              $self->Self().
                              "\nDataboss replace by lastknownbossid");
                           $self->NotifyContactDataModification(
                                                      "databosschange",
                                                      $dataobj,$reason,$ref,
                                                      $rec,$contactrec,
                                                      $lastbossid);
                           $ReferenceIsStillInvalid=0;
                           last BLOOP;
                        }
                     }
                     elsif ($contact_age_days>14){
                        $self->NotifyContactDataModification(
                                                   "lastbossnotify",
                                                   $dataobj,$reason,$ref,
                                                   $rec,$contactrec,
                                                   $lastbossid);
                        last BLOOP;
                     }
                  }
               }
            }
         }
         else{
            if ($contact_old_enought){
               my $o=getModuleObject($dataobj->Config(),"base::lnkcontact");
               $o->SetFilter({id=>\$ref->{rawrecid}});
               my ($oldrec,$msg)=$o->getOnlyFirst(qw(ALL)); 
               if (defined($oldrec)){ 
                  $o->DeleteRecord({id=>\$ref->{rawrecid}});
                  $o->StoreUpdateDelta("delete", $oldrec, undef,
                      $self->Self().
                      "\nContact cistatus=$contactrec->{cistatusid}");
                  $self->NotifyContactDataModification("contactdel",
                                                $dataobj,$reason,$ref,
                                                $rec,$contactrec);
               }
               $ReferenceIsStillInvalid=0;
            }
         }
      }
      else{
         Stacktrace();
      }
   }
   return($ReferenceIsStillInvalid);
}

1;
