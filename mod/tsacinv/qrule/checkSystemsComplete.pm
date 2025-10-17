package tsacinv::qrule::checkSystemsComplete;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if all systems on a specifice costobject are documented in
it-inventory.

All systems in AM are defined as ...

state="!out of operation"

systemola=!*ONLY

... as requested in ...

https://darwin.telekom.de/darwin/auth/base/workflow/ById/14087131770001

... and as an additional restriction, the customer link in AssetManager
must point to DTAG.* 


=head3 IMPORTS

NONE

=head3 HINTS

Es müssen alle Systeme die im AssetManager dem aktuellen Kontierungsobjekt 
zugeordnet sind, auch in W5Base/Darwin unter IT-Inventar->System erfasst sein! 

Achtung: Sollte es sich um Infrastruktursysteme handeln, so müssen diese 
auch als solche in Darwin gekennzeichnet werden (Systemklassifizierung). 

Die Datenerfassung von logischen Systemen in Darwin erfolgt i.d.R. durch 
den TSM der betreffenden Anwendung. Der Datenverantwortliche des 
Kontierungsobjektes hat die Verantwortung den TSM zu informieren dass 
die über ihn beauftragten Systeme nun zur Erfassung bereitstehen. 

Sollte dies nicht passieren kann dies über den Prozess SACM eskaliert werden.
Alternativ kann der Datenverantwortliche des Kontierungsobjektes die 
betreffenden logischen Systeme selbst erfassen (somit die Datenverantwortung 
übernehmen) und in Darwin pflegen! 

[en:] 

All Systems assigned to an up to date cost center in Asset Manager have to be 
created in W5Base/Darwin under IT-Inventory > System. 

Attention: In case of an infrastructure system, the system has to be marked 
as infrastructure system in Darwin as well (Systemclass). 
Creation of logical systems in Darwin is generally done by TSM of the 
specific application. It is in the responsibility of the databoss of the 
cost center to inform the TSM, which then will create the logical systems. 

If this does not happen, it can be escalated through the SACM process. 
Alternatively the databoss of a corresponding cost center has to create 
logical systems on his own and also maintain them in Darwin.


=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   return(["finance::costcenter"]);
}


sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   my $o=getModuleObject($self->getParent->Config,"tsacinv::system");


   my $co=$rec->{name};

   $o->SetFilter({
      status=>'"in operation"',
      systemola=>'!*ONLY',
      conumber=>\$co,
      deleted=>\'0',
      customerlink=>'DTAG.* DTAG'
   });
   my @soll=$o->getHashList(qw(systemname systemid));

   my %sollsystemid;

   foreach my $r (@soll){
      if ($r->{systemid} ne ""){
         $sollsystemid{uc($r->{systemid})}=$r->{systemname};
      }
   }
   if (keys(%sollsystemid)){
      my $o=getModuleObject($self->getParent->Config,"itil::system");
      $o->SetFilter({
         systemid=>[keys(%sollsystemid)]
      });
      my @ist=$o->getHashList(qw(name systemid));
      my %istsystemid;
      foreach my $r (@ist){
         if ($r->{systemid} ne ""){
            $istsystemid{uc($r->{systemid})}++;
         }
      }

      my @miss;
      foreach my $r (sort(keys(%sollsystemid))){
         if (!exists($istsystemid{$r})){
            push(@miss,$sollsystemid{$r}." ($r)");
         }
      }
      if ($#miss!=-1){
         $errorlevel=3;
         foreach my $s (@miss){
            my $msg="missing logical system in it-inventory: ".$s;
            push(@qmsg,$msg);
            push(@dataissue,$msg);
         }
      }
   }
   my @result=$self->HandleQRuleResults("AssetManagerCDS",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);

   return(@result);
}



1;
