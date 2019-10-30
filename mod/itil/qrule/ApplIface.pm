package itil::qrule::ApplIface;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every Application in in CI-Status "installed/active" or "available", needs
at least 1 interface, if the flag "application has no intefaces" is not 
true.
Loop interfaces from the current to the current application are not allowed.

=head3 IMPORTS

NONE

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
   if (!$rec->{isnoifaceappl}){
      if (ref($rec->{interfaces}) ne "ARRAY" || $#{$rec->{interfaces}}==-1){
         return(3,{qmsg=>['no interfaces defined'],
                   dataissue=>['no interfaces defined']});
      }
      if ($#{$rec->{interfaces}}!=-1){
         my $appl=$dataobj->Clone();
         my @msg;
         foreach my $ifrec (@{$rec->{interfaces}}){
            if ($ifrec->{'comments'}=~m/(^|\s)DataLoopInOutTechSpec(\s|$)/) {
               next;
            }
            if ($ifrec->{toapplid} eq $rec->{id}){
               my @msg=("loop interfaces to the current ".
                        "application are not allowed");
               return(3,{qmsg=>\@msg,dataissue=>\@msg});
            }
            my @acheck=();
            push(@acheck,$ifrec->{toapplid}) if ($ifrec->{toapplid} ne "");
            push(@acheck,$ifrec->{gwapplid}) if ($ifrec->{gwapplid} ne "");
            foreach my $applid (@acheck){
               $appl->ResetFilter();
               $appl->SetFilter({id=>\$applid,cistatusid=>"2 3 4 5"});
               my ($arec,$msg)=$appl->getOnlyFirst(qw(id));
               if (!defined($arec)){
                  push(@msg,"invalid application in interface: ".
                           $ifrec->{fullname});
               }
            }
         }
         if ($#msg!=-1){
            return(3,{qmsg=>\@msg,dataissue=>\@msg});
         }
      }
   }
   else{
      if (ref($rec->{interfaces}) eq "ARRAY" && $#{$rec->{interfaces}}!=-1){
         return(3,{qmsg=>['superfluous interfaces'],
                   dataissue=>['superfluous interfaces']});
      }
   }
   return(0,undef);

}



1;
