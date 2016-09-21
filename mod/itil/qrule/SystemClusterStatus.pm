package itil::qrule::SystemClusterStatus;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This rule checks if "isclusternode"="true", if a valid cluster is assigned.
This rule also creates a DataIssue if the referenced Cluster is not in 
CI-State "installed/active" or "available/in project".

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

This rule checks if a valid cluster is assigned.

[de:]

Diese Regel prüft, ob ein gültiger Cluster eingetragen ist.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   my @failmsg;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);

   if ($rec->{isclusternode}){
      if ($rec->{itclust} eq ""){
         push(@failmsg,
              "on a cluster node, there must be a valid cluster specified");
      }
      else{
         my $itclustid=$rec->{itclustid};
         my $itclust=getModuleObject($self->getParent->Config,"itil::itclust");
         if (defined($itclust)){
            $itclust->SetFilter({id=>\$itclustid});
            my ($cl,$msg)=$itclust->getOnlyFirst(qw(cistatusid));
            if ($itclust->Ping()){
               if (!defined($cl)){
                  push(@failmsg,
                       "invalid cluster refernence - contact w5base admin");
               }
               else{
                  if ($cl->{cistatusid}!=3 && $cl->{cistatusid}!=4){
                     push(@failmsg,"invalid refernece to inactiv cluster");
                  }
               }
            }
            else{
               push(@failmsg,"ping to itclust failed");
            }
         }
         else{
            push(@failmsg,"cluster object not connectable");
         }
      }
   }

   if ($#failmsg!=-1){
      return(3,{qmsg=>[@failmsg],
                dataissue=>[@failmsg]});
   }

   return(0,undef);

}




1;
