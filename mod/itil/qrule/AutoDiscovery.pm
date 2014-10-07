package itil::qrule::AutoDiscovery;
#######################################################################
=pod

=head3 PURPOSE

Every Application in in CI-Status "installed/active" or "available", needs
to set a valid primary operation mode.

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
   return(['itil::system','itil::swinstance']);
}


sub qenrichRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $dataobjname=$dataobj->SelfAsParentObject();

   my $add=getModuleObject($dataobj->Config,"itil::autodiscdata");
   my $ade=getModuleObject($dataobj->Config,"itil::autodiscengine");
   if (defined($add) && defined($ade)){ # itil:: seems to be installed
      $ade->SetFilter({localdataobj=>\$dataobjname});
      foreach my $engine ($ade->getHashList(qw(ALL))){
         my $rk;
         $rk="systemid"     if ($dataobjname eq "itil::system");
         $rk="swinstanceid" if ($dataobjname eq "itil::swinstance");
         $add->SetFilter({$rk=>\$rec->{id},engine=>\$engine->{name}});
         my ($oldadrec)=$add->getOnlyFirst(qw(ALL));
         # check age of oldadrec - if newer then 24h - use old one
            # todo

         my $ado=getModuleObject($dataobj->Config,$engine->{addataobj});
         if (!exists($rec->{$engine->{localkey}})){
            # autodisc key data does not exists in local object
            msg(ERROR,"preQualityCheckRecord failed for $dataobjname ".
                      "local key $engine->{localkey} does not exists");
            next;
         }
         if (defined($ado)){  # check if autodisc object name is OK
            my $adokey=$ado->getField($engine->{adkey});
            if (defined($adokey)){ # check if autodisc key is OK
               my $adfield=$add->getField("data");
               $ado->SetFilter({
                  $engine->{adkey}=>\$rec->{$engine->{localkey}}
               });
               my ($adrec)=$ado->getOnlyFirst(qw(ALL));
               if (defined($adrec)){
                  if ($ado->Ping()){
                     $adrec->{xmlstate}="OK";
                     my $adxml=hash2xml({xmlroot=>$adrec});
                     if (!defined($oldadrec)){
                        $add->ValidatedInsertRecord({engine=>$engine->{name},
                                                     $rk=>$rec->{id},
                                                     data=>$adxml});
                     }
                     else{
                        my $upd={data=>$adxml};
                        my $chk=$adfield->RawValue($oldadrec);
                        if (trim($upd->{data}) eq trim($chk)){  # wird verm.
                           delete($upd->{data});    # sein, da XML im Aufbau
                           $upd->{mdate}=$oldadrec->{mdate}; # dynamisch ist
                        }
                        $add->ValidatedUpdateRecord($oldadrec,$upd,{
                           engine=>\$engine->{name},
                           $rk=>\$rec->{id}
                        });
                     }
                  }
               }
            }
            $ado->{DB}->Disconnect();
         }
         else{
            msg(ERROR,"preQualityCheckRecord failed for $dataobjname ".
                      "while load AutoDisc($engine->{name}) object ".
                       $engine->{addataobj});
         }
         sleep(1); # reduce process load
      }
   }
   return(0);

}




1;
