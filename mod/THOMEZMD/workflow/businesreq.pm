package THOMEZMD::workflow::businesreq;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::WfClass;
use AL_TCom::workflow::businesreq;
@ISA=qw(AL_TCom::workflow::businesreq);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();

   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Select(    name       =>'zmsarticleno',
                                         label      =>'ZMD Article number',
                                  htmleditwidth=>'80%',
                                  translation=>'THOMEZMD::workflow::businesreq',
                                         value      =>[

        "",
        "174524-0001; Operativer Change",
        "174524-0002; Incident",
        "174524-0003; Lizenz-Management",
        "175084-0001; Abschluss von Wartungsverträgen",
        "175084-0002; Abschluss von Supportverträgen",
        "175084-0003; Entwicklungsunterstützung",
        "175084-0004; Pilotierung",
        "175084-0005; Installation",
        "175084-0006; Erstkonfiguration",
        "175084-0007; Test der erfolgreichen Installation",
        "175084-0008; Dokumentation",
        "175084-0009; Einspielen von Fixes",
        "175084-0010; Einspielen von Updates (Minor Releases)",
        "175084-0011; Einspielen von Releaseänderungen (Major Releases)",
        "175084-0012; Einspielen von Versionen",
        "175084-0013; Fallback für Releasewechsel oder Migrationen",
        "175084-0014; Disaster-Recovery Test",
        "175084-0015; Deinstallation von Applikationen",
        "175084-0016; Ausführen von Batches/Scripten",
        "175084-0017; Ausführen von Daueraufträge",
        "175084-0018; Ändern Jobablauf",
        "175084-0019; Roll-Outs",
        "175084-0020; Ergebnisprüfung (z. B. für Datenabgabe)",
        "175084-0021; Offline Eingriffe (z.B Heli)",
        "175084-0022; Besondere Monitoring Anforderungen",
        "700700-0001; Neuaufbau durch Cloning",
        "700700-0002; Last und Performance Test",
        "700700-0003; Abnahmetest",
        "700700-0004; Installation",
        "700700-0005; Erstkonfiguration",
        "700700-0006; Test der erfolgreichen Installation",
        "700700-0007; Einspielen von Fixes",
        "700700-0008; Einspielen von Updates (Minor Releases)",
        "700700-0009; Einspielen von Releaseänderungen (Major Releases)",
        "700700-0010; Einspielen von Versionen",
        "700700-0011; Starten der Datenbanken (?) ",
        "700700-0012; Monitoring der Datenbanken",
        "700700-0013; Housekeeping",
        "700700-0014; Ressourcen Management",
        "700700-0015; Optimierungsanalyse Prüfung von Verbesserungspotenzialen",
        "700700-0016; Starten und Stoppen der Appl.",
        "700700-0017; Ausführen von Batchen",
        "700700-0018; Operational Changes",
        "700700-0019; Störungsbearbeitung  (Appl. und DB (?)",
        "700700-0020; Konfigurationen",
        "700700-0021; Parametrisierung",
        "700700-0022; Schnittstellen Mgmt",
        "700700-0023; Administration (Passwörter, Firewall, Benutzer)",
        "700700-0024; Testdaten einspielen",
        "700700-0025; Testumgebungen sichern und restoren",
        "701841-0001; Abrufleistung Reporting",
        "701841-0002; Sonstige Abrufleistungen",
        "701841-0003; Kümmerer E2E für Incidents nach Leistungsnachweis",
        "701842-0001; Analysen"


                                         ],
                                         default    =>'undef',
                                         group      =>'customerdata',
                                         container  =>'headref'),
   ));
}

sub getSpecificDataloadForm
{
   my $self=shift;

   my $templ=<<EOF;
<tr>
<td class=fname>%zmsarticleno(label)%:</td>
<td colspan=3 class=finput>%zmsarticleno(detail)%</td>
</tr>
EOF
   return($templ.$self->SUPER::getSpecificDataloadForm());
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec) &&
       $newrec->{zmsarticleno} eq ""){
      $self->LastMsg(ERROR,"no article number selected");
      return(undef);
   }


   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}




1;
