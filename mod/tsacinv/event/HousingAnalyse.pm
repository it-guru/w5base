package tsacinv::event::HousingAnalyse;
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
use kernel::Event;
use kernel::database;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub HousingAnalyse
{
   my $self=shift;
   my $app=$self->getParent;

   my @msg;

   my $amsys=getModuleObject($self->Config,"tsacinv::system");
   my $amass=getModuleObject($self->Config,"tsacinv::asset");

   open(F,">HousingAnalyse.log.csv");
   my $form="%s;%s;%s;%s\r\n";

   printf F ($form,"ToDoTag","AM ID Ref","Standort","Bemerkung");

   my %loc;
   my @notsirz=(
      'DE_FRANKFURT-AM-MAIN_KRUPPSTRASSE_121-127',
      'DE_FRANKFURT_AM_MAIN_ESCHBORNER_LANDSTRASSE_100',
      'DE_MUENCHEN_DACHAUER-STRASSE_665',
      'DE_BONN_LANDGRABENWEG_151',
      'TSI-CSM-MAGDEBURG-LÜBE',
      'DE_BERLIN_HOLZHAUSER_STRASSE_4-8',
      'DE_MUENCHEN_ELISABETH-SELBERT-STRASSE_1'
   );

   my %assetid;




   $amsys->ResetFilter();
   $amsys->SetFilter({
      usage=>\'INVOICE_ONLY?',
      deleted=>\'0',
      status=>'"!out of operation"'
   });
   foreach my $amsysrec ($amsys->getHashList(
                         qw(systemname systemid
                            assetassetid
                            tsacinv_locationfullname))){
      my @l=split(/\//,$amsysrec->{tsacinv_locationfullname});
      next if (in_array(\@notsirz,$l[1]));

      $loc{$l[1]}++;
      $assetid{$amsysrec->{assetassetid}}++;
      printf F ($form,"CreateSysInW5","",$l[1],
                "Es muss in Darwin ein neues System mit dem Namen  ".
                lc($amsysrec->{systemname})." erzeugt werden, das auf die ".
                "AssetID $amsysrec->{assetassetid} verweist.");
    
      printf F ($form,"RenameSysInAM",$amsysrec->{systemid},$l[1],
                "Das System mit der SystemID $amsysrec->{systemid} muss ".
                "von $amsysrec->{systemname} auf $amsysrec->{systemid}_HW ".
                "umbenannt werden.");
    
      #print Dumper($amsysrec);
      #print Dumper(\@l);

   }

   $amass->ResetFilter();
   $amass->SetFilter({
      status=>'"!wasted"',
      deleted=>\'0',
      srcsys=>\'W5Base',
   });
   foreach my $amassrec ($amass->getHashList(
                         qw(assetid tsacinv_locationfullname))){
      my @l=split(/\//,$amassrec->{tsacinv_locationfullname});
      next if (in_array(\@notsirz,$l[1]));
      printf F ($form,"TransfAssetAuthD2A",$amassrec->{assetid},$l[1],
                "Das Asset $amassrec->{assetid} muss von ExternalSystem=W5Base".
                "auf ExternalSystem=NULL umgestellt werden, da es in einem ".
                "TSI RZ steht. Unklar, wer die Assignmentgroup in AM bekommen ".
                "soll.");
      #print Dumper($amassrec);
   }

   $amass->ResetFilter();
   $amass->SetFilter({
      status=>'"!wasted"',
      deleted=>\'0',
      assetid=>[keys(%assetid)]    # load assetids from posible INVOICE_ONLY?
   });
   foreach my $amassrec ($amass->getHashList(
                         qw(assetid tsacinv_locationfullname))){
      my @l=split(/\//,$amassrec->{tsacinv_locationfullname});
    #  next if (in_array(\@notsirz,$l[1]));
    #  printf F ($form,"TransfAssetAuthD2A",$amassrec->{assetid},$l[1],
    #            "Das Asset $amassrec->{assetid} muss von ExternalSystem=W5Base".
    #            "auf ExternalSystem=NULL umgestellt werden, da es in einem ".
    #            "TSI RZ steht. Unklar, wer die Assignmentgroup in AM bekommen ".
    #            "soll.");
      print Dumper($amassrec);
   }



   return({exicode=>0});
}



1;
