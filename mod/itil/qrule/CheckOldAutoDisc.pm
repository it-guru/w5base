package itil::qrule::CheckOldAutoDisc;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if old, unprocessed AutoDiscovery Data exists on an logical
system (in CI-State "installed/active" or "available/in project").

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

New AutoDiscovery Data needs to be processed within 12 weeks.

[de:]

Neue AutoDiscovery Daten müssen innerhalb von 12 Wochen 
behandelt werden.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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


   my $ad=getModuleObject($self->getParent->Config,'itil::autodiscrec');
   $ad->SetFilter({disc_on_systemid=>\$rec->{id},
                   cdate=>'<now-14d',
                   state=>[1],
                   processable=>\'1'});
   if ($ad->CountRecords()>0){
      my $msg='found unprocessed autodiscovery data';
      return(3,{qmsg=>[$msg],dataissue=>[$msg]});
   }
   return(0,undef);

}




1;
