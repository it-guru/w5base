#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Resolv IP DNS Names from IP-Adresses.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The Qrule try to resolv DNS name from IP-Address. This will only work,
if the Network-Area is correct specified and for the given Network-Area
a working W5ProbeIP URL is existing.



=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
package itil::qrule::IPdnsresolv;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::QRule;
use itil::lib::Listedit;
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
   return(["itil::ipaddress"]);
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



   return(undef,undef) if ($rec->{'cistatusid'}!=4 && $rec->{'cistatusid'}!=3);
   my $networkid=$rec->{networkid};


   my $url="ip://".$rec->{name};
   my $res=itil::lib::Listedit::probeUrl(
     $dataobj,$url,[qw(DNSRESOLV REVDNS)],$networkid
   );
   if (ref($res) eq "HASH"){
      if ($res->{exitcode} eq "0"){
         if (ref($res->{revdns}) eq "HASH" && 
             ref($res->{revdns}->{names}) eq "ARRAY" &&
             $#{$res->{revdns}->{names}} !=-1){
            my @names=sort(@{$res->{revdns}->{names}});
            my $name=$names[0];
            $name=~s/\.$//;
            if (lc($rec->{dnsname}) ne lc($name)){
               $forcedupd->{dnsname}=$name;
            }
         }
      }
   }
   if ($rec->{dnsname} ne ""){
      if ($rec->{system} ne ""){
         my $dnshostpart=$rec->{dnsname};
         $dnshostpart=~s/\..*$//;
         if (lc($dnshostpart) eq lc($rec->{system})){
            if ($rec->{addresstyp} ne "0"){ # should be prim - but we check 
                                            # if there others already primary
               my $sys=getModuleObject($dataobj->Config,"itil::system");
               $sys->SetFilter({id=>\$rec->{systemid}});
               my ($sysrec,$msg)=$sys->getOnlyFirst(qw(ipaddresses)); 
               my $foundprim=0;
               if (defined($sysrec) && exists($sysrec->{ipaddresses})){
                  foreach my $iprec (@{$sysrec->{ipaddresses}}){
                    if ($iprec->{addresstyp} eq "0"){
                       $foundprim=1;
                       last;
                    }
                  }
                  if (!$foundprim){
                     $forcedupd->{addresstyp}="0";
                  }
               }
            }
         }
      }
   }
   if (keys(%$forcedupd) && exists($forcedupd->{dnsname})){
      $forcedupd->{mdate}=$rec->{mdate};
      $forcedupd->{editor}=$rec->{editor};
      $forcedupd->{owner}=$rec->{owner};
      my $swop=$dataobj->Clone();
      $swop->SetFilter({id=>\$rec->{id}}); 
      my ($oldrec,$msg)=$swop->getOnlyFirst(qw(ALL)); 
      if ($swop->ValidatedUpdateRecord($oldrec,$forcedupd,{id=>\$rec->{id}})){
         push(@qmsg,"DNS Name updated to: ".$forcedupd->{dnsname});
      }
      $forcedupd={};
   }
   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);


   return(0,undef);
}


1;
