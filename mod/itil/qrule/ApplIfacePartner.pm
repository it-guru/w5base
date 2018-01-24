package itil::qrule::ApplIfacePartner;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

If another application (fromappl) has documented an interface with
cistatus 'available/in project' or 'installed/active' to an 
application (toappl), the toappl has to document the corresponding 
interface on its side too.
An error is caused, if the corresponding interface is missing,
except that in the interface definition the flag
'interface agreement necessary' is set to 'no'.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The documentation of interfaces requires these relations 
to be documented from both sides.

This QualityRule checks whether the specification has been adhered to. 
It also checks the data flow direction.
Data flows send/send and/or receive/receive are not allowed.

For clarification please contact the Databoss of the respective application(s).

[de:]

Die Dokumentation von Schnittstellen an Anwendungen erfordert,
dass diese auf beiden Seiten dokumentiert werden.

Diese Qualitätsregel prüft, ob diese Vorgabe eingehalten wurde.
Bei dieser Prüfung wird auch die Datenflussrichtung geprüft.
Senden/senden und empfangen/empfangen wird als nicht zulässig bewertet.

Zur Klärung kontaktieren Sie bitte den Datenverantwortlichen 
der aufgelisteten Anwendungen.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2016 Hartmut Vogler (it@guru.de)
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
   return(["itil::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   # key = contype of fromappl
   # val = possible contypes of toappl
   my %contypeMap=(0=>[0..5],1=>[0,2,3,5],2=>[0,1,3,4],
                   3=>[0..5],4=>[0,2,3,5],5=>[0,1,3,4]);
   my @msg;
   my @dataissue;
   my @issuedappl;

   my $lnkobj=getModuleObject($self->getParent->Config,'itil::lnkapplappl');
   my $appl=getModuleObject($self->getParent->Config,'itil::appl');
   $lnkobj->SetFilter({toapplid=>\$rec->{id},
                       cistatusid=>[3,4],fromapplcistatus=>[3,4],
                       ifagreementneeded=>1});

   foreach my $aa ($lnkobj->getHashList(qw(id fromapplid fromappl
                                           rawcontype conproto
                                           urlofcurrentrec))) {
      my @ifok=grep { $_->{toapplid} == $aa->{fromapplid} &&
                      #$_->{conproto} eq $aa->{conproto}   &&
                      in_array($contypeMap{$aa->{rawcontype}},$_->{contype})
                    } @{$rec->{interfaces}};
      if ($#ifok==-1) {
         $appl->ResetFilter();
         $appl->SetFilter({id=>\$aa->{fromapplid}});
         my ($fromapplrec,$msg)=$appl->getOnlyFirst(qw(mandator));
         if ($fromapplrec->{mandator} ne "Extern"){
            push(@issuedappl,$aa->{fromappl});
         }
      }
   }

   if ($#issuedappl!=-1) {
      my $appl=join(', ',@issuedappl);
      push(@msg,'MSG01');
      push(@msg,$appl);

      push(@dataissue,'MSG02');
      push(@dataissue,$appl);

      return(3,{qmsg=>\@msg,dataissue=>\@dataissue});
   }
   
   return(0,undef);
}



1;
