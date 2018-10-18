package itil::qrule::SystemDBsw;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

A system containing a software installation based on a DB-Software
must be marked with the systemclass "databaseserver". Inconsistent 
entries of systemclass and software installations generate a DataIssue.

=head3 IMPORTS

NONE

=head3 HINTS

If a system is marked as a database server (in the block "Systemclassification")
it is necessary to have at least one software installation
with database software.
If a system is NOT marked as a database server 
(the option "databaseserver" in "systemclassification" is set to "no"), 
it is not allowed to have a database installations on that logical system.

[de:]

Wenn ein logisches System in der Systemklassifizierung als Datenbankserver
markiert ist, dann muss min. eine Software-Installation mit dem logischen
System (oder Cluster Komplex) verbunden sein, die auf einer 
Datenbanksoftware basiert.
Falls ein System KEIN Datenbank-Server ist ("ist Datenbankserver: nein"),
darf auch keine Datenbank-Software-Installation mit dem System verknüpft sein.


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
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3); 

   # no autocorrection is allowed - see request 
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/15192854880001
   $autocorrect=0;

   my @inst;
   my @cinst;

   if (ref($rec->{software}) eq "ARRAY"){
      foreach my $swrec (@{$rec->{software}}){
          push(@inst,$swrec->{id});
      }
   }


   if ($rec->{isclusternode}) {
      my $csobj=getModuleObject($self->getParent->Config,
                                'itil::lnkitclustsvc');
      $csobj->SetFilter({clustid=>$rec->{itclustid},
                         itclustcistatusid=>[qw(3 4 5)]});
      foreach my $swinst ($csobj->getHashList('software')) {
          foreach my $swi (@{$swinst->{software}}){
             push(@cinst,$swi->{id});
          }
      }
   }


   my $lnksw=getModuleObject($self->getParent->Config,
                             'itil::lnksoftware');

   $lnksw->SetFilter({id=>[@cinst,@inst]});
   $lnksw->SetCurrentView(qw(id softwareid));
   my $swi=$lnksw->getHashIndexed("id");

   my %allsw;

   map({$allsw{$_->{softwareid}}++} values(%{$swi->{id}}));

   my $sw=getModuleObject($self->getParent->Config,"itil::software");
   $sw->SetFilter({id=>[keys(%allsw)]});
   $sw->SetCurrentView(qw(id is_dbs));
   my $swprod=$sw->getHashIndexed("id");

   # now we have all we need
   my $founddbinst=0;
   if ($rec->{isdatabasesrv}){
      foreach my $iid (@inst,@cinst){
         my $swinstsoftwareid=$swi->{id}->{$iid}->{softwareid};
         if ($swprod->{id}->{$swinstsoftwareid}->{is_dbs}){
            $founddbinst++;
         }
      }
      if ($founddbinst==0){ # nicht gut
         if ($autocorrect){
            $forcedupd->{isdatabasesrv}=0;
         }      
         else{
            my $msg="system classification db server is set without ".
                    "db software installations";
            push(@dataissue,$msg);
            push(@qmsg,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }
   else{
      foreach my $iid (@inst){
         my $swinstsoftwareid=$swi->{id}->{$iid}->{softwareid};
         if ($swprod->{id}->{$swinstsoftwareid}->{is_dbs}){
            $founddbinst++;
         }
      }
      if ($founddbinst>0){ # nicht gut
         if ($autocorrect){
            $forcedupd->{isdatabasesrv}=1;
         }      
         else{
            my $msg="system classification db server is not set, ".
                    "but db software installations found";
            push(@dataissue,$msg);
            push(@qmsg,$msg);
            $errorlevel=3 if ($errorlevel<3);
         }
      }
   }

   my @result=$self->HandleQRuleResults($self->Self,
                  $dataobj,$rec,$checksession,
                  \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}



1;
