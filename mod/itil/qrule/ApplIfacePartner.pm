package itil::qrule::ApplIfacePartner;
#######################################################################
=pod

=head3 PURPOSE

If another application (fromappl) has documented an interface with
cistatus 'available/in project' or 'installed/activ' to an 
application (toappl), the toappl has to document the corresponding 
interface on its side too.
An error is caused, if the corresponding interface is missing,
except that in the interface definition the flag
'interface agreement necessary' is set to 'no'.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This quality rule checks, if interface definitions to this application
are existing, which are not yet documented here.
The check also keeps the data direction in mind, i.e. send/send and
receive/receive are not allowed.

Please document the corresponding interface, or contact the interface
partner, if you are of the´mind, that this is an incorrect entry.

In further questions please contact the Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001

[de:]

Dieses Qualitätsregel prüft, ob es Schnittstelleneinträge zu dieser
Anwendung gibt, die hier noch nicht dokumentiert sind.
Dabei wird auch die Datenflussrichtung berücksichtigt,
d.h. senden/senden und empfangen/empfangen sind nicht erlaubt.

Bitte legen Sie den korrespondierenden Schnittstelleintrag an,
oder kontaktieren Sie den Schnittstellenpartner, falls Sie der Meinung
sind, dass es sich um einen fehlerhaften Eintrag handelt.

Bei weiteren Fragen wenden Sie sich bitte an den Darwin-Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


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

   my $lnkobj=getModuleObject($self->getParent->Config,'itil::lnkapplappl');
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
         push(@msg,sprintf("%s (%s: %d)",$aa->{fromappl},
                                         $self->T('Interface ID'),
                                         $aa->{id}));
         push(@dataissue,"$aa->{fromappl} -> $aa->{urlofcurrentrec}");
      }
   }
   
   return(3,{qmsg=>\@msg,dataissue=>\@dataissue}) if ($#msg!=-1);
   return(0,undef);
}



1;
