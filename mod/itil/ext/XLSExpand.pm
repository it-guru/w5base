package itil::ext::XLSExpand;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::XLSExpand;
use Data::Dumper;
@ISA=qw(kernel::XLSExpand);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}


sub GetKeyCriterion
{
   my $self=shift;
   my $d={in=>{'itil::system::name'       =>{label=>'Systemname',
                                             out=>['itil::appl::name']},
               'itil::appl::name'         =>{label=>'Application',
                                             out=>['itil::appl::name']},
               'itil::system::systemid'   =>{label=>'SystemID',
                                             out=>['itil::appl::name']},
               'itil::asset::name'        =>{label=>'AssetID',
                                             out=>['itil::appl::name']},
               'itil::system::ipaddress::name'  =>{label=>'IP-Address',
                                             out=>['itil::appl::name']}
              },
          out=>{'itil::appl::name'          =>{label=>'IT-Inventar: Application',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::sememail'      =>{label=>'IT-Inventar: Application: CBM E-Mail',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::tsmemail'      =>{label=>'IT-Inventar: Application: TSM E-Mail',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::tsm2email'     =>{label=>'IT-Inventar: Application: Vetreter TSM E-Mail',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::sem'           =>{label=>'IT-Inventar: Application: CBM',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::tsm'           =>{label=>'IT-Inventar: Application: TSM',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::tsm2'          =>{label=>'IT-Inventar: Application: Vetreter TSM',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::businessteam'  =>{label=>'IT-Inventar: Application: Betriebsteam',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::businessteamboss'=>{label=>'IT-Inventar: Application: Betriebsteamleiter',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::applid'        =>{label=>'IT-Inventar: Application: ApplicationID',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::customer'      =>{label=>'IT-Inventar: Application: Kunde',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::customerprio'  =>{label=>'IT-Inventar: Application: Kundenprio',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::appl::criticality'  =>{label=>'IT-Inventar: Application: Kritikalität',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::system::ipaddress::name'   =>{label=>'IT-Inventar: System: IP-Address',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::system::name'        =>{label=>'IT-Inventar: System: Systemname',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::system::osrelease'   =>{label=>'IT-Inventar: System: OS-Release',
                                               in=>[qw(itil::appl::name
                                                       itil::system::systemid
                                                       itil::asset::name
                                                       itil::system::ipaddress::name
                                                       itil::system::name)]},
                'itil::system::location'   =>{
                   label=>'IT-Inventar: System: Location'
                }
              }
         };
   return($d);
}

sub ProcessLine
{
   my $self=shift;
   my $line=shift;
   my $in=shift;
   my $out=shift;
   my $loopcount=shift;

   if (defined($in->{'itil::system::ipaddress::name'})){
      my $ip=$self->getParent->getPersistentModuleObject('itil::ipaddress');
      $ip->SetFilter({name=>\$in->{'itil::system::ipaddress::name'},cistatusid=>'4'});
      foreach my $iprec ($ip->getHashList(qw(systemid))){
         $in->{'itil::system::id'}->{$iprec->{systemid}}=1;
      }
   }
   if (defined($in->{'finance::costcenter::name'})){
      my $o=$self->getParent->getPersistentModuleObject('itil::appl');
      if (ref($in->{'finance::costcenter::name'}) eq "HASH"){
         $o->SetFilter({conumber=>[keys(%{$in->{'finance::costcenter::name'}})],
                        cistatusid=>'4'});
      }
      else{
         $o->SetFilter({conumber=>\$in->{'finance::costcenter::name'},cistatusid=>'4'});
      }
      foreach my $orec ($o->getHashList(qw(id))){
         $in->{'itil::appl::id'}->{$orec->{id}}++;
      }
   }

   if (defined($in->{'itil::appl::name'})){
      my $appl=$self->getParent->getPersistentModuleObject('itil::appl');
      if (ref($in->{'itil::appl::name'}) eq "HASH"){
         $appl->SetFilter({name=>[keys(%{$in->{'itil::appl::name'}})],
                           cistatusid=>'4'});
      }
      else{
         $appl->SetFilter({name=>\$in->{'itil::appl::name'},cistatusid=>'4'});
      }
      foreach my $applrec ($appl->getHashList(qw(id conumber systems))){
         $in->{'itil::appl::id'}->{$applrec->{id}}++;
         if ($applrec->{conumber} ne ""){
            if (!exists($in->{'finance::costcenter::name'}) ||
                ref($in->{'finance::costcenter::name'}) eq "HASH"){
               $in->{'finance::costcenter::name'}->{$applrec->{conumber}}++;
            }
         }
         if (grep(/^itil::system::.*$/,keys(%{$out}))){
            if (defined($applrec->{systems}) && 
                ref($applrec->{systems}) eq "ARRAY"){
               foreach my $sysrec (@{$applrec->{systems}}){
                  $in->{'itil::system::id'}->{$sysrec->{systemid}}++;
               }
            }
         }
      }
   }
   if (defined($in->{'itil::system::systemid'})) {
      my $sys=$self->getParent->getPersistentModuleObject('itil::system');
      $sys->SetFilter({systemid=>\$in->{'itil::system::systemid'},cistatusid=>'4'});
      foreach my $sysrec ($sys->getHashList(qw(id))){
         $in->{'itil::system::id'}->{$sysrec->{id}}++;
      }
   } 
   if (defined($in->{'itil::asset::name'})){
      printf STDERR ("process in by assetid\n");
      my $ass=$self->getParent->getPersistentModuleObject('itil::asset');
      my @flt=();
      if (defined($in->{'itil::asset::name'})){
         push(@flt,{name=>$in->{'itil::asset::name'}});
      }
      map({$_->{cistatusid}=\'4'} @flt);
      $ass->SetFilter(\@flt);
      if (grep(/^.*::appl::.*$/,keys(%{$out}))||
          grep(/^.*::system::.*$/,keys(%{$out}))){
         $in->{'itil::appl::id'}=undef if (!exists($in->{'itil::appl::id'}));
         foreach my $rec ($ass->getHashList(qw(id systems applications))){
            $in->{'itil::asset::id'}->{$rec->{'id'}}++;

            if (grep(/^.*::appl::.*$/,keys(%{$out}))){
               if (ref($rec->{applications}) eq "ARRAY"){
                  foreach my $app (@{$rec->{applications}}){
                     if (exists($out->{'itil::appl::name'})){
                        $out->{'itil::appl::name'}->{$app->{'appl'}}++;
                     }
                     $in->{'itil::appl::id'}->{$app->{'applid'}}++;
                  }
               }
            }

            if (grep(/^.*::system::.*$/,keys(%{$out}))){
               if (ref($rec->{systems}) eq "ARRAY"){
                  foreach my $sys (@{$rec->{systems}}){
                     if (exists($out->{'itil::system::name'})){
                        $out->{'itil::system::name'}->{$sys->{'name'}}++;
                     }
                     $in->{'itil::system::id'}->{$sys->{'id'}}++;
                  }
               }
            }

         }
      }


   }
   if (defined($in->{'itil::system::name'}) || 
       defined($in->{'itil::system::id'})){
      printf STDERR ("process in by systemname\n");
      my $sys=$self->getParent->getPersistentModuleObject('itil::system');
      my @flt=();
      if (defined($in->{'itil::system::name'})){
         push(@flt,{name=>$in->{'itil::system::name'}});
      }
      if (defined($in->{'itil::system::id'})){
         push(@flt,{id=>[keys(%{$in->{'itil::system::id'}})]});
      }
      map({$_->{cistatusid}=\'4'} @flt);
      $sys->SetFilter(\@flt);
      if (grep(/^.*::appl::.*$/,keys(%{$out}))||
          grep(/^.*::system::.*$/,keys(%{$out}))){
         $in->{'itil::appl::id'}=undef if (!exists($in->{'itil::appl::id'}));
         foreach my $rec ($sys->getHashList(qw(id applications))){
            $in->{'itil::system::id'}->{$rec->{'id'}}++;
            if (grep(/^.*::appl::.*$/,keys(%{$out}))){
               if (ref($rec->{applications}) eq "ARRAY"){
                  foreach my $app (@{$rec->{applications}}){
                     if (exists($out->{'itil::appl::name'})){
                        $out->{'itil::appl::name'}->{$app->{'appl'}}++;
                     }
                     $in->{'itil::appl::id'}->{$app->{'applid'}}++;
                  }
               }
            }
         }
      }
   }

 
   # output
   foreach my $appsekvar (qw(sem tsm tsm2 tsm2email name
                             sememail tsmemail businessteam businessteamboss applid
                             customerprio criticality customer)){
      if (defined($in->{'itil::appl::id'}) && 
          exists($out->{'itil::appl::'.$appsekvar})){
         my $appl=$self->getParent->getPersistentModuleObject('itil::appl');
         my $id=[keys(%{$in->{'itil::appl::id'}})];
         $appl->SetFilter({id=>$id});
         foreach my $rec ($appl->getHashList($appsekvar)){
            if (defined($rec->{$appsekvar})){
               if (ref($rec->{$appsekvar}) ne "ARRAY"){
                  $rec->{$appsekvar}=[$rec->{$appsekvar}]; 
               }
               foreach my $v (@{$rec->{$appsekvar}}){
                   if ($v ne ""){
                      $out->{'itil::appl::'.$appsekvar}->{$v}++;
                   }
               }
            } 
         }
      }
   }
   foreach my $syssekvar (qw(osrelease name location)){
      if (exists($out->{'itil::system::'.$syssekvar}) &&
          defined($in->{'itil::system::id'})){
         my $sys=$self->getParent->getPersistentModuleObject('itil::system');
         my $id=[keys(%{$in->{'itil::system::id'}})];
         $sys->SetFilter({id=>$id});
         foreach my $rec ($sys->getHashList($syssekvar)){
            if ($rec->{$syssekvar} ne ""){
                $out->{'itil::system::'.$syssekvar}->{$rec->{$syssekvar}}++;
            } 
        }
      }
   }

   if (exists($out->{'itil::system::ipaddress::name'})){
     my $ipa=$self->getParent->getPersistentModuleObject('itil::ipaddress');
     my $id=[keys(%{$in->{'itil::system::id'}})];
      $ipa->SetFilter({systemid=>$id});
      foreach my $rec ($ipa->getHashList('name')){
         $out->{'itil::system::ipaddress::name'}->{$rec->{'name'}}++;
     }
   }

   return(1);
}





1;
