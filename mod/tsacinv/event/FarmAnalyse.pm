package tsacinv::event::FarmAnalyse;
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


sub FarmAnalyse
{
   my $self=shift;
   my $app=$self->getParent;

   my @msg;

   my %d;
   my $lnkfarm=getModuleObject($self->Config,"AL_TCom::lnkitfarmasset");
   my $vhost=getModuleObject($self->Config,"tsadopt::vhost");
   my $vsys=getModuleObject($self->Config,"tsadopt::vsys");
   my $amfarm=getModuleObject($self->Config,"tsacinv::itfarm");
   my $amsys=getModuleObject($self->Config,"tsacinv::system");

   $lnkfarm->SetFilter({
      assetcistatusid=>'4',
   #   itfarm=>'IT-Serverfarm_x86-TB001'
   });
   foreach my $rec ($lnkfarm->getHashList(qw(itfarm itfarmid asset))){
      push(@{$d{w5}->{itfarm}->{$rec->{itfarm}}->{assetid}},
           $rec->{asset});
      $d{anyassetid}->{$rec->{asset}}->{refcnt}++;
      $d{anyassetid}->{$rec->{asset}}->{w5farm}->{$rec->{itfarm}}++;
   }

   # check known names for farms in ADOP-T
   foreach my $itfarm (sort(keys(%{$d{w5}->{itfarm}}))){
      printf("analyse farm %s\n",$itfarm);
      my @assetid=@{$d{w5}->{itfarm}->{$itfarm}->{assetid}};
      $vhost->ResetFilter();
      $vhost->SetFilter({ assetid=>\@assetid });
      foreach my $rec ($vhost->getHashList(qw(vfarm))){
         $d{w5}->{itfarm}->{$itfarm}->{adoptvfarm}->{$rec->{vfarm}}++;
      }
   }
   $d{w5}->{itfarm}->{"NoSF"}->{adoptvfarm}->{"dcshi-mag01-s01-cl01"}++;
   # check farmnames in AssetManager
   my %adoptfarmnames;
   foreach my $itfarm (sort(keys(%{$d{w5}->{itfarm}}))){
      my $farmrec=$d{w5}->{itfarm}->{$itfarm};
      if (exists($farmrec->{adoptvfarm})){
         foreach my $adoptfarmname (keys(%{$farmrec->{adoptvfarm}})){
            $d{adopt}->{farm}->{$adoptfarmname}={};
            $amfarm->ResetFilter();
            $amfarm->SetFilter({name=>$adoptfarmname});
            foreach my $rec ($amfarm->getHashList(qw(name farmlocation farmassets))){
               $d{adopt}->{farm}->{$adoptfarmname}->{amfarmname}->{$rec->{name}}++;
               if ($rec->{farmlocation} eq ""){
                  push(@msg,"farm '$rec->{name}' has no location in AM");
               }
               my $loc=$rec->{farmlocation};
               $loc=[$loc] if (ref($loc) ne "ARRAY");
               my %chkname;
               foreach my $locname (@$loc){
                 my $chkname=$locname;
                 $chkname=~s#^(/.*?/).*$#$1#;
                 $chkname{$chkname}++;
               }
               if (keys(%chkname)>1){
                  push(@msg,"farm '$rec->{name}' has multiple locations in AM based on AssetID locations");
               }
               #print STDERR "fifi chkname".Dumper(\%chkname);
               #print Dumper($rec);
               $d{w5}->{itfarm}->{$itfarm}->{amfarm}->{$rec->{name}}++;
               foreach my $assetid (@{$rec->{farmassets}}){
                  $d{am}->{farm}->{$rec->{name}}->{assetid}->{$assetid}++;
                  $d{anyassetid}->{$assetid}->{refcnt}++;
                  $d{anyassetid}->{$assetid}->{amfarm}->{$rec->{name}}++;
               }
               $d{am}->{farm}->{$rec->{name}}->{adoptname}->{$adoptfarmname}++;
            }
         }
      }
   }
   foreach my $farmname (keys(%{$d{adopt}->{farm}})){
      $vhost->ResetFilter();
      $vhost->SetFilter({vfarm=>$farmname});
      foreach my $rec ($vhost->getHashList(qw(assetid))){
         $d{adopt}->{farm}->{$farmname}->{assetid}->{$rec->{assetid}}++;
         $d{anyassetid}->{$rec->{assetid}}->{refcnt}++;
         $d{anyassetid}->{$rec->{assetid}}->{adoptfarm}->{$farmname}++;
      }
   }




   # check assetid count between AM and ADOP-T
   foreach my $amfarmname (keys(%{$d{am}->{farm}})){
      if (exists($d{am}->{farm}->{$amfarmname}->{adoptname})){
         my @adoptfarmname=keys(%{$d{am}->{farm}->{$amfarmname}->{adoptname}});
         if ($#adoptfarmname!=0){
            push(@msg,"not unique farm nameing bettwen AM farm '$amfarmname' and ADOP-T");
         }
         else{
            my $adoptfarmname=$adoptfarmname[0];
            my @amcount=keys(%{$d{am}->{farm}->{$amfarmname}->{assetid}});
            my @adoptcnt=keys(%{$d{adopt}->{farm}->{$adoptfarmname}->{assetid}});
            if ($#amcount!=$#adoptcnt){
               push(@msg,"farm '$amfarmname' in AM has different Asset count against ADOP-T ".
                         ($#amcount+1)."/".($#adoptcnt+1));
            }
            foreach my $adoptid (sort(@adoptcnt)){
               if (!in_array(\@amcount,$adoptid)){
                  push(@msg,"AssetID '$adoptid' seems to be overly in farm '$amfarmname' in AM");
               }
            }
            foreach my $amid (sort(@amcount)){
               if (!in_array(\@adoptcnt,$amid)){
                  push(@msg,"AssetID '$amid' seems to be missing in farm '$amfarmname' in AM");
               }
            }
         }
      }
      else{
         push(@msg,"farm '$amfarmname' in AM can not be found in ADOP-T");
      }
   }
   

   my @assetid=keys(%{$d{anyassetid}});

   $amsys->ResetFilter();
   $amsys->SetFilter({assetassetid=>\@assetid,status=>\'in operation',deleted=>\'0'});
   my @l=$amsys->getHashList(qw(systemid assetassetid status itfarm));
   foreach my $rec (@l){
      print Dumper($rec);
      $d{anysys}->{$rec->{systemid}}->{amassetid}=$rec->{assetassetid};
      $d{anysys}->{$rec->{systemid}}->{amfarmname}=$rec->{itfarm};
   }


   my @systemid=keys(%{$d{anysys}});
   $vsys->ResetFilter();
   $vsys->SetFilter({systemid=>\@systemid});
   foreach my $rec ($vsys->getHashList(qw(systemid assetid vfarm))){
      $d{anysys}->{$rec->{systemid}}->{adoptassetid}=$rec->{assetid};
      $d{anysys}->{$rec->{systemid}}->{adoptfarmname}=$rec->{vfarm};
   }

   foreach my $systemid (sort(@systemid)){
      my $amfarmname=$d{anysys}->{$systemid}->{amfarmname};
      my $adoptfarmname=$d{anysys}->{$systemid}->{adoptfarmname};
      if (lc($amfarmname) ne lc($adoptfarmname)){
         $amfarmname="NixDrin" if ($amfarmname eq "");
         $adoptfarmname="NixDrin" if ($adoptfarmname eq "");
         push(@msg,"farm mismatch on systemid '$systemid' between AM and ADOP-T ($amfarmname - $adoptfarmname)");
      }
   }
   push(@msg,"result: analysed ".keys(%{$d{anysys}})." SystemIDs");
   push(@msg,"result: analysed ".keys(%{$d{anyassetid}})." AssetIDs");
   push(@msg,"result: analysed ".keys(%{$d{am}->{farm}})." IT-Farms in AM");
   push(@msg,"result: analysed ".keys(%{$d{adopt}->{farm}})." IT-Farms in ADOP-T");

   if (open(F,">FarmAnalyse.log.txt")){
      print F join("\r\n",@msg);
      close(F);
   }


printf("Messages:\n%s\n",join("\n",@msg));




   return({exicode=>0});
}



1;
