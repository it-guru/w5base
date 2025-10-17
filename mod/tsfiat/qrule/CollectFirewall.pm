package tsfiat::qrule::CollectFirewall;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Every System in the CI-State >2 and <6 gets firewall lists from
FIAT as additional configitems.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

Collect additional config items from FIAT as firewalls.

[de:]

Abfrage der firewalls aus FIAT als zusätzlich verwendete
Config-Items.


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
   my $desc={qmsg=>[],solvtip=>[]};
   my $errorlevel=0;
   my $exitcode=0;

   my $fiatfw=$dataobj->getPersistentModuleObject("tsfiat::firewall");

   return({}) if ($fiatfw->isSuspended());
   # if ping failed ...
   # ??? - is ping on fiat implemented?
   #if (!$fiatfw->Ping()){
   #   # check if there are lastmsgs
   #   # if there, send a message to interface partners
   #   my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
   #   return({}) if ($infoObj->NotifyInterfaceContacts($fiatfw));
   #   msg(ERROR,"no ping posible to ".$fiatfw->Self());
   #   return({});
   #}


   if (ref($rec->{ipaddresses}) ne "ARRAY" || $#{$rec->{ipaddresses}}==-1){
      my $msg="missing ip addresses";
      return(undef,{qmsg=>$msg});
   }
   my @ip;
   foreach my $iprec (@{$rec->{ipaddresses}}){
      if ($iprec->{name}=~m/^10\./ && 
          $iprec->{cistatusid}==4 ){
         if (!($iprec->{name}=~m/^10\.250\./)){ # keine Consolen (laut Holger W.)
            push(@ip,$iprec->{name}); 
         }
      }
   }

   my %fwlist;

   foreach my $ip (@ip){
      my $fw=$fiatfw->getFirewallByIp($ip);
      foreach my $fwrec (@$fw){
         if (!exists($fwlist{$fwrec->{id}})){
            $fwlist{$fwrec->{id}}={
               id=>$fwrec->{id},
               ifname=>{}
            };
         }
         $fwlist{$fwrec->{id}}->{ifname}->{$fwrec->{name}}++;
      }
   }
   if (keys(%fwlist)){
      $fiatfw->SetFilter({id=>[keys(%fwlist)]});
      $fiatfw->SetCurrentView(qw(id name fullname isexcluded));
      my $d=$fiatfw->getHashIndexed("id");
 
      foreach my $fwid (keys(%fwlist)){
         my $fullname;
         my $isexcluded;
         if (exists($d->{id}->{$fwid})){
            $fwlist{$fwid}->{name}=$d->{id}->{$fwid}->{name};
            $fwlist{$fwid}->{ciusage}="FIREWALL";
            $fwlist{$fwid}->{isexcluded}=$d->{id}->{$fwid}->{isexcluded};
            if (!$fwlist{$fwid}->{isexcluded}){
               $fullname=$d->{id}->{$fwid}->{fullname};
            }
         }
         $fwlist{$fwid}->{comments}="Interfaces:\n".join("\n",
                sort(keys(%{$fwlist{$fwid}->{ifname}})));
         if ($fullname ne ""){
            $fwlist{$fullname}={
               name=>$fullname,
               ciusage=>"FIREWALL-VDOM",
               comments=>''
            };
         }
      }
      foreach my $fullname (keys(%fwlist)){
         #print STDERR "$fullname: = ".Dumper($fwlist{$fullname});
         if ($fwlist{$fullname}->{isexcluded}){
            push(@{$desc->{qmsg}},"firewall id '$fullname' is excluded");
            delete($fwlist{$fullname});
         }
         else{
            if ($fwlist{$fullname}->{name} eq ""){
               push(@{$desc->{qmsg}},"error - firewall id '$fullname' can ".
                                     "not be resolved from firewall cache");
               delete($fwlist{$fullname});
            }
         }
      }

      my @soll=sort({$a->{name} cmp $b->{name}} values(%fwlist));
      
      my $acis=getModuleObject($dataobj->Config,"itil::lnkadditionalci");
      $acis->SetFilter({systemid=>\$rec->{id}});
      my @acis=$acis->getHashList(qw(ALL));

      my @opList;

      my $srcsys=$fiatfw->Self();

      my $res=OpAnalyse(
         sub{  # comperator 
            my ($a,$b)=@_;   # a=lnkadditionalci b=aus AM
            my $eq;
            if ($a->{srcsys} eq $srcsys &&
                $a->{name} eq $b->{name}){
               $eq=0;
               # eq=0 = Satz gefunden und es wird ein Update gemacht
               if ($a->{comments} eq $b->{comments} &&
                   $a->{ciusage} eq $b->{ciusage}){
                  $eq=1;
                  # eq=1 = alles super - kein Update notwendig
               }
            }
            return($eq);
         },
         sub{  # oprec generator
            my ($mode,$oldrec,$newrec,%p)=@_;
            if ($mode eq "insert" || $mode eq "update"){
               my $oprec={
                  OP=>$mode,
                  MSG=>"$mode  $newrec->{systemname} ".
                       "in W5Base",
                  DATAOBJ=>'itil::lnkadditionalci',
                  DATA=>{
                     name      =>$newrec->{name},
                     ciusage   =>$newrec->{ciusage},
                     srcload   =>NowStamp("en"),
                     srcsys    =>$srcsys,
                     systemid  =>$rec->{id}
                  }
               };
               if ($mode eq "update"){
                  $oprec->{IDENTIFYBY}=$oldrec->{id};
               }
               if ($mode eq "insert"){
                  $checksession->{EssentialsChangedCnt}++;
                  push(@{$desc->{qmsg}},"add: ".$oprec->{DATA}->{name});
               }
               return($oprec);
            }
            elsif ($mode eq "delete"){
               my $id=$oldrec->{id};
               push(@{$desc->{qmsg}},"remove: ".$oldrec->{name});
               $checksession->{EssentialsChangedCnt}++;
               return({OP=>$mode,
                       MSG=>"delete ip $oldrec->{name} ".
                            "from W5Base",
                       DATAOBJ=>'itil::lnkadditionalci',
                       IDENTIFYBY=>$oldrec->{id},
                       });
            }
            return(undef);
         },
         \@acis,\@soll,\@opList,
         refid=>$rec->{id}
      );
      if (!$res){
         my $opres=ProcessOpList($self->getParent,\@opList);
      }
   }


   return($exitcode,$desc);









   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);
}





1;
