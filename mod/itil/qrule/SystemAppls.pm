package itil::qrule::SystemAppls;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every System in the CI-State "installed/active" or "available/in project" 
has to be linked to at least one (1) application. If no applications 
are assigned, a DataIssue is generated. In this case the databoss of the 
logical system has to contact the databoss of the application the system 
belongs to, to assign the system to the application. This rule is inactive 
if the system is a workstation and not a server/applicationserver. 
This rule is also inactive if the system is an infrastructure system and 
a sufficient description is documented in the comments.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

An active system has to be linked to an active application. 
The link between a system and an application is established on the 
application side. Therefore it might be necessary for you to contact 
the person responsible for maintaining the data of the application 
and ask them to enter the system there.

[de:]

Ein aktives System muss mit einer aktiven Anwendung verknüpft sein. 
Die Verbindung zwischen einem System und einer Anwendung wird an dem 
Anwendungsdatensatz vorgenommen. Deshalb ist es möglich, dass Sie eine 
für die Anwendung verantwortliche Person kontaktieren müssen, 
um den Eintrag des Systems an der Anwendung durchzuführen.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
   return(["itil::system"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   return(0,undef) if (!($rec->{isapplserver}) && ($rec->{isworkstation}));
   return(undef,undef) if ($rec->{relationmodel} ne "APPL");

   if ($rec->{isinfrastruct}) {
      if (ref($rec->{applications}) ne "ARRAY" || $#{$rec->{applications}}==-1){
         my $wcnt=split(/\s+/,$rec->{comments});
        
         if ($wcnt<10) {
            my $msg='description in field comments '.
                    'not available resp. insufficient';
            return(3,{qmsg=>[$msg],dataissue=>[$msg]});
         }
      }
      return(0,undef);
   }

   if ($rec->{itfarm} ne "" && $rec->{cistatusid} eq "3" ){
      # logical systems provided by an itfarm in state 
      # "available/in project" does not need to have application relations
      return(0,undef);
   }


   if (ref($rec->{applications}) ne "ARRAY" || $#{$rec->{applications}}==-1){
      return(3,{qmsg=>['no application relations'],
                dataissue=>['no application relations']});
   }
   return(0,undef);
}



1;
