package TS::ipaddress;
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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
use kernel::Field;
use itil::ipaddress;
@ISA=qw(itil::ipaddress);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getValidWebFunctions
{
   my $self=shift;

   my @l=$self->SUPER::getValidWebFunctions(@_);
   push(@l,"Analyse");
   return(@l);
}

sub Analyse
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            query=>{
               typ=>'STRING',
               path=>0,
               init=>'10.105.204.109'
            },
            ipaddr=>{
               typ=>'STRING',
            },
            networkid=>{
               typ=>'STRING'
            },
            network=>{
              typ=>'STRING'
            }
         },undef,\&doAnalyse,@_)
   );
}

sub doAnalyse
{
   my $self=shift;
   my $param=shift;

   my @indication;
   my $ipflt={};
   my %userid;
   my $userid;
   my @cadmin;
   my @tadmin;
   my %cadmin;
   my %tadmin;
   my @refurl;
   my $notes;
   my %networks;
   my $r={};

   if (exists($param->{query}) && $param->{query} ne ""){
      if (!exists($param->{ipaddr}) || $param->{ipaddr} eq ""){
         $param->{ipaddr}=$param->{query};
      }
      if (exists($param->{ipaddr}) && $param->{ipaddr} ne $param->{query}){
         $param->{ipaddr}="-1";
      }
   }

   $ipflt->{name}=[$param->{ipaddr}];
   $ipflt->{cistatusid}=\'4';


   if (exists($param->{networkid}) && $param->{networkid} ne ""){
      $ipflt->{networkid}=[$param->{networkid}];
   }
   else{
      if (exists($param->{network}) && $param->{network} ne ""){
         $ipflt->{network}=$param->{network};
      }
   }
   $self->ResetFilter();
   $self->SetFilter($ipflt);

   my @l=$self->getHashList(qw(id applications network networkid
                               dnsname name system itclustsvc
                               systemid systemsystemid itclustsvcid));

   my %applid;

   my %systemid;
   my @related;

   foreach my $iprec (@l){
      $networks{$iprec->{networkid}}={
         network=>$iprec->{network},
         networkid=>$iprec->{networkid}
      };
      if (ref($iprec->{applications}) eq "ARRAY"){   # this is slow !!!
         foreach my $applrec (@{$iprec->{applications}}){
            if ($applrec->{applid} ne ""){
               $applid{$applrec->{applid}}++;
            }
         }
      }
      if ($iprec->{system} ne ""){
         if (!in_array(\@indication,"system: ".$iprec->{system})){
            push(@indication,"system: ".$iprec->{system});
            $systemid{$iprec->{systemid}}++;
         }
         push(@related,{
            dataobj=>'itil::system',
            dataobjid=>$iprec->{systemid},
            data=>{
               name=>$iprec->{system},
               systemid=>$iprec->{systemsystemid}
            }
         });
      }
      if ($iprec->{itclustsvc} ne ""){
         if (!in_array(\@indication,"clusterservice: ".$iprec->{itclustsvc})){
            push(@indication,"clusterservice: ".$iprec->{itclustsvc});
         }
      }
   }
   if ((!keys(%applid)) && 
       keys(%systemid)){ # logical system without any applications
      my $sys=getModuleObject($self->Config,"itil::system");
      $sys->SetFilter({id=>[keys(%systemid)]});
      my @l=$sys->getHashList(qw(id databossid admid adm2id));
      foreach my $r (@l){
         if ($r->{databossid} ne ""){
            my $userid=$r->{databossid};
            $userid{$userid}++;
            if (!in_array(\@cadmin,$userid)){
               push(@cadmin,$userid);
            }
         }
         if ($r->{admid} ne ""){
            my $userid=$r->{admid};
            $userid{$userid}++;
            if (!in_array(\@tadmin,$userid) &&
                !in_array(\@cadmin,$userid)){
               push(@tadmin,$userid);
            }
         }
     #    if ($r->{adm2id} ne ""){
     #       my $userid=$r->{adm2id};
     #       $userid{$userid}++;
     #       if (!exists($tadmin{$userid})){
     #          $tadmin{$userid}++;
     #          push(@tadmin,$userid);
     #       }
     #    }
      }
   }

   if (!keys(%applid)){ 
      my $urlip=getModuleObject($self->Config,"itil::lnkapplurl");
      my $ipflt={};
      $ipflt->{lastipaddresses}=[$param->{ipaddr}];
      if (exists($param->{networkid}) && $param->{networkid} ne ""){
         $ipflt->{networkid}=[$param->{networkid}];
      }
#      if (exists($param->{network})){
#         $ipflt->{network}=$param->{network};
#      }
      $urlip->ResetFilter();
      $urlip->SetFilter($ipflt);
      my @l=$urlip->getHashList(qw(id name network networkid 
                                   applid urlofcurrentrec));
      foreach my $r (@l){
         $networks{$r->{networkid}}={
            network=>$r->{network},
            networkid=>$r->{networkid}
         };
         if (!in_array(@refurl,$r->{urlofcurrentrec})){
            push(@refurl,$r->{urlofcurrentrec});
         }
         if (!in_array(\@indication,"url: ".$r->{name})){
            push(@indication,"url: ".$r->{name});
         }
         $applid{$r->{applid}}++;
      }
   }




   if (!keys(%applid) && 
       $#cadmin==-1 && $#tadmin==-1 &&
       $param->{ipaddr} ne "-1"){  # Query NOAH - if IP is not in Darwin
      #msg(INFO,"start handling unknown ip adresses");
      my $newcomments="";
      my $ipflt=$param->{ipaddr};
      $ipflt=~s/\*//g;
      $ipflt=~s/\?//g;
      #msg(INFO,"try to query NOAH on ip $ipflt");
      if ($ipflt ne ""){
         $r->{query}->{ipaddr}=$ipflt;

         my $neo=getModuleObject($self->Config,"neo::ipaddressAnalyse");

         if (!defined($neo) || !$neo->Ping()){
            return({
               exitcode=>1,
               exitmsg=>'error while connect to NEO'
            });
         }
         $neo->SetFilter({cidr=>$ipflt,customer=>'CN-DTAG'});

         my @l=$neo->getHashList(qw(ALL));
         my @email;
         if ($#l!=-1){
            $newcomments.="NEO IP-Informations:\n".join("\n\n",map({
               my $str=$_->{component_dns}."\n".
               $_->{urlofcurrentrec}."\n".
               "VLAN Domain:".$_->{vlan_domain}."\n".
               "Network comment:".$_->{network_comment}."\n".
               $_->{component_servicenumb};
              foreach my $contactv (qw(network_contact
                                       network_contact2
                                       subnet_contact 
                                       subnet_contact2)){
                 if ($_->{$contactv} ne ""){
                    if (!in_array(\@email,$_->{$contactv})){
                       push(@email,$_->{$contactv});
                    }
                 }
              }
              $str;
            } @l));
         }

         if ($#email!=-1){
            foreach my $email (@email){
               my $flt={emails=>$email};
               $flt->{cistatusid}=[3,4,5];
               my $user=getModuleObject($self->Config,"base::user");
               $user->ResetFilter();
               $user->SetFilter($flt);
               my ($urec)=$user->getOnlyFirst(qw(userid));
               if (defined($urec)){
                  $userid=$urec->{userid};
                  $userid{$userid}++;
                  if (!in_array(\@cadmin,$userid)){
                     push(@cadmin,$userid);
                  }
               }
            }
         }
      }
      if ( trim($newcomments) ne ""){
         $notes.=$newcomments;
      }
   }

   my @criticality;
   my @ictono;
   my %opmode;

   $self->finalizeAnalysedContacts(
      [keys(%applid)],
      [keys(%systemid)],
      \%userid,
      \@indication,
      \@cadmin,
      \@tadmin,
      \@criticality,
      \@ictono,
      \@refurl,
      \%opmode,
      \@related
   );



   if ($#indication!=-1){
      $r->{indication}=\@indication;
   }
   if ($#cadmin!=-1){
      $r->{'Admin-C'}=\@cadmin;
   }
   if ($#tadmin!=-1){
      $r->{'Tech-C'}=\@tadmin;
   }
   if ($#refurl!=-1){
      $r->{refurl}=\@refurl;
   }
   if ($#ictono!=-1){
      $r->{ictono}=\@ictono;
   }
   if ($#criticality!=-1){
      $r->{criticality}=$criticality[0];
   }
   if (keys(%opmode)){
      $r->{opmode}=\%opmode;
   }

   if (keys(%networks)){
      $r->{networks}=[values(%networks)];
   }
   if ($#related!=-1){
      $r->{related}=\@related;
   }

   if ($notes ne ""){
      $r->{notes}=$notes;
   }


   
   return({
      result=>$r,
      exitcode=>0,
      exitmsg=>'OK'
   });
}

1;

