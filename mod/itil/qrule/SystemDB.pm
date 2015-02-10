package itil::qrule::SystemDB;
#######################################################################
=pod

=head3 PURPOSE

A system containing a software instance based on a DBMS must flagged
with systemclass databaseserver.
Inconsistent entries between systemclass and software instances will
produce an error.

=head3 IMPORTS

NONE

=head3 HINTS

If there is a system marked as databaseserver (in systemclassification)
there is need to have at least one software instance linked to the 
locical system (or cluster complex) with a software installation based
on a database software.
In reverse if "is database server" is set to false, it is not allowed
to have database instances on the logical system.

[de:]

Wenn ein logisches System in der Systemklassifizierung als Datenbankserver
markiert ist, dann muß min. eine Software-Instanz mit dem logischen
System (oder Cluster Komplex) verbunden sein, die auf einer 
Datenbanksoftware basiert.
Umgekehrt ist muß darf falls ein System mit  "ist Datenbankserver"=nein
markiert ist, auch keine Datenbank-Software-Instanz mit dem System
verknüpft sein.


=cut
#######################################################################
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
   return(["itil::system"]);
}

sub qcheckRecord
{  
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3); 

   my $dbInstalled=0;
   my @instances;

   if ($rec->{isclusternode}) {
      my $csobj=getModuleObject($self->getParent->Config,
                                'itil::lnkitclustsvc');
      $csobj->SetFilter({clustid=>$rec->{itclustid},
                         itclustcistatusid=>[qw(3 4 5)]});
      foreach my $inst ($csobj->getHashList('swinstances')) {
         push(@instances,@{$inst->{swinstances}});
      }
   } else {
      @instances=@{$rec->{swinstances}};
   }

   foreach my $instance (@instances) {
      my $instobj=getModuleObject($self->getParent->Config,
                                  'itil::swinstance');
      $instobj->SetFilter({fullname=>$instance->{fullname}});
      my ($d,$msg)=$instobj->getOnlyFirst('is_dbs');
      if ($d->{is_dbs}) {
         $dbInstalled=1;
         last;
      }
   }

   if ($dbInstalled!=$rec->{isdatabasesrv}) {
      return(3,{qmsg     =>['inconsistent entries '.
                            'in databaseserver and software instances'],
                dataissue=>['inconsistent entries '.
                            'in databaseserver and software instances']});
   }

   return(0,undef);
}



1;
