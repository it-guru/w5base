package itil::qrule::AssetCPUCount;
#######################################################################
=pod

=head3 PURPOSE

Every asset has to have at least one (1) CPU to work. A DataIssue is 
generated, if there is either no or 0 CPU-count defined on a logical system 
in CI-State "installed/active" or "available/in project". A DataIssue is also 
generated, if the Core-Count is lower than the CPU-Count. A core count of more 
than 4096 and a CPU-count of more than 1024 is considered not realistic.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Please enter a non-zero CPU count in the field 'CPU-Count' under 'Assetdata'.
If the field 'allow automatic updates by interfaces' on the CI is set to 
'yes', the data is automatically imported from Asset Manager. If the DataIssue 
persists despite this, please contact the assignment group of the CI, 
so the data can be changed in Asset Manager.

[de:]

Bitte tragen Sie einen CPU-Wert der ungleich Null ist in das Feld 
'CPU-Anzahl' im Block 'Hardwaredaten' ein. Wenn am Datensatz das Feld 
'automatisierte Updates durch Schnittstellen zulassen' auf 'ja' steht, 
werden diese Angaben aus Asset Manager übertragen. Wenn dennoch DataIssues 
erzeugt werden, wenden Sie sich bitte an die Assignment Gruppe des CI-s, 
damit die Pflege in Asset Manager erfolgt.


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
   return(["itil::asset"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if ($rec->{cistatusid}!=4 && $rec->{cistatusid}!=3);
   my @msg;
   if ($rec->{cpucount}<=0){
      my $msg='no cpu count defined';
      push(@msg,$msg);
   }
   if ($rec->{cpucount}>1024){
      my $msg='cpu count is not realistic';
      push(@msg,$msg);
   }
   if ($rec->{corecount}>1024){
      my $msg='core count is not realistic';
      push(@msg,$msg);
   }
   if ($rec->{corecount}<$rec->{cpucount}){
      my $msg='core count is less then cpu count';
      push(@msg,$msg);
   }
   if ($#msg>=0){
      return(3,{qmsg=>\@msg,dataissue=>\@msg});
   }
   return(0,undef);

}




1;
