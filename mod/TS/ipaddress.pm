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
            ipaddr=>{
               typ=>'STRING',
               mandatory=>1,
               path=>0,
               init=>'10.105.204.109'
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
   my @applcadminfields=qw(applmgrid);
   my @appltadminfields=qw(tsmid tsm2id opmid opm2id);
   my $notes;
   my %networks;


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
                               dnsname name system itclustsvc));

   my %applid;

   foreach my $iprec (@l){
      $networks{$iprec->{networkid}}={
         network=>$iprec->{network},
         networkid=>$iprec->{networkid}
      };
      if (ref($iprec->{applications}) eq "ARRAY"){
         foreach my $applrec (@{$iprec->{applications}}){
            if ($applrec->{applid} ne ""){
               $applid{$applrec->{applid}}++;
            }
         }
      }
      if ($iprec->{system} ne ""){
         if (!in_array(\@indication,"system: ".$iprec->{system})){
            push(@indication,"system: ".$iprec->{system});
         }
      }
      if ($iprec->{itclustsvc} ne ""){
         if (!in_array(\@indication,"clusterservice: ".$iprec->{itclustsvc})){
            push(@indication,"clusterservice: ".$iprec->{itclustsvc});
         }
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
   if (!keys(%applid)){  # Query NOAH - if IP is not in Darwin
      #msg(INFO,"start handling unknown ip adresses");
      my $newcomments="";
      my $ipflt=$param->{ipaddr};
      $ipflt=~s/\*//g;
      $ipflt=~s/\?//g;
      #msg(INFO,"try to query NOAH on ip $ipflt");
      if ($ipflt ne ""){
         my $noa=getModuleObject($self->Config,"tsnoah::ipaddress");
         if (!defined($noa) || !$noa->Ping()){
            return({
               exitcode=>1,
               exitmsg=>'error while connect to NOAH'
            });
         }
         $noa->SetFilter({name=>$ipflt});
         my @l=$noa->getHashList(qw(name systemname urlofcurrentrec));
         if ($#l!=-1){
            $newcomments.="NOAH IP-Informations:\n".join("\n\n",map({
               $_->{systemname}."\n".$_->{urlofcurrentrec};
            } @l));
         }
         if (1){
            # now we try to find the correct networks
            my @netmask=qw(0 0 0 0);
            my @network=qw(0 0 0 0);
            my @ipnetflt;
            my @netareaflt;
            foreach my $ipaddr (split(/[\s;]+/,$ipflt)){
                my @okt=split(/\./,$ipaddr);
                for(my $o=0;$o<=3;$o++){
                   my $bitmask=128;
                   for(my $bit=0;$bit<8;$bit++){
                      $bitmask=(128>>$bit)|$bitmask;
                      $netmask[$o]=$bitmask;
                      my $netmask=join(".",@netmask);
                      for(my $n=0;$n<4;$n++){
                         $network[$n]=$okt[$n]&$netmask[$n];
                      }
                      my $network=join(".",@network);
                      push(@ipnetflt,{
                         name=>\$network,
                         subnetmask=>\$netmask 
                      });
                      push(@netareaflt,{
                         netaddr=>\$network,
                         netmask=>\$netmask 
                      });
                   }
                }
            }
            if ($#ipnetflt!=-1){
               my $noa=getModuleObject($self->Config,"tsnoah::ipnet");
               $noa->SetFilter(\@ipnetflt);
               my @l=$noa->getHashList(qw(fullname name subnetmask
                                          urlofcurrentrec email));
               my $email;
               if ($#l!=-1){
                  foreach my $noahnet (@l){
                     if ($email eq "" && $noahnet->{email} ne ""){
                        $email=$noahnet->{email};
                     }
                  }
                  if ($newcomments ne ""){
                     $newcomments.="\n\n";
                  }
                  $newcomments.="NOAH IP-Networks:\n".join("\n\n",map({
                     $_->{fullname}."\n".$_->{name}." ".
                     "(".$_->{subnetmask}.")\n".
                     $_->{urlofcurrentrec};
                  } @l));
               }
               else{
                  my $narea=getModuleObject($self->Config,"tsnoah::netrange");


                  $narea->SetFilter(\@netareaflt);
                  my @l=$narea->getHashList(qw(name name netmask netaddr
                                             urlofcurrentrec email));
                  if ($#l!=-1){
                     foreach my $noahnet (@l){
                        if ($email eq "" && $noahnet->{email} ne ""){
                           $email=$noahnet->{email};
                        }
                     }
                     if ($newcomments ne ""){
                        $newcomments.="\n\n";
                     }
                     $newcomments.="NOAH IP-Netarea:\n".join("\n\n",map({
                        $_->{name}."\n".$_->{netaddr}." ".
                        "(".$_->{subnetmask}.")\n".
                        $_->{urlofcurrentrec};
                     } @l));
                  }
               }
               if ($email ne ""){
                  my $flt={emails=>\$email};
                  $flt->{cistatusid}=[3,4,5];
                  my $user=getModuleObject($self->Config,"base::user");
                  $user->ResetFilter();
                  $user->SetFilter($flt);
                  my ($urec)=$user->getOnlyFirst(qw(userid));
                  if (defined($urec)){
                     $userid{$urec->{userid}}={};
                  }
               }
            }
         }
      }
      if ( trim($newcomments) ne ""){
         $notes.=$newcomments;
      }
   }

   # now all applications are detected
   my @applrec;

   if (keys(%applid)){
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->ResetFilter();
      $appl->SetFilter({
         cistatusid=>"<6", 
         id=>[keys(%applid)]
      });
      my @appls=$appl->getHashList(qw(+cdate name urlofcurrentrec),
                                @applcadminfields,@appltadminfields);
      foreach my $a (@appls){
         push(@applrec,{
            name=>$a->{name},
            urlofcurrentrec=>$a->{urlofcurrentrec},
            tsmid=>$a->{tsmid},
            opmid=>$a->{opmid},
            tsm2id=>$a->{tsm2id},
            opm2id=>$a->{opm2id},
            applmgrid=>$a->{applmgrid}
         });
         foreach my $fld (@applcadminfields,@appltadminfields){
            $userid{$a->{$fld}}++;
         }
      }
   }
   if (keys(%userid)){
      my @userid=grep(!/^\s*$/,keys(%userid));
      my $flt={};
      $flt->{cistatusid}=[3,4,5];
      $flt->{userid}=\@userid;
      my $user=getModuleObject($self->Config,"base::user");
      $user->ResetFilter();
      $user->SetFilter($flt);
      $user->SetCurrentView(qw(fullname posix dsid email userid));
      $userid=$user->getHashIndexed(qw(userid));
   }
   # create prio list of cadmin tadmin
   if ($#applrec!=-1){
      foreach my $arec (@applrec){
         my $cadminset=0;
         foreach my $fld (@applcadminfields){
            if (exists($userid->{userid}->{$arec->{$fld}}) &&
                !exists($cadmin{$arec->{$fld}})){
               $cadmin{$arec->{$fld}}++;
               push(@cadmin,$userid->{userid}->{$arec->{$fld}});
               $cadminset++;
            }
         }
         foreach my $fld (@appltadminfields){
            if (exists($userid->{userid}->{$arec->{$fld}}) &&
                !exists($tadmin{$arec->{$fld}})){
               $tadmin{$arec->{$fld}}++;
               push(@tadmin,$userid->{userid}->{$arec->{$fld}});
            }
         }
         if ($cadminset){
            if (!in_array(\@indication,"application: ".$arec->{name})){
               unshift(@indication,"application: ".$arec->{name});
            }
            if (!in_array(@refurl,$arec->{urlofcurrentrec})){
               unshift(@refurl,$arec->{urlofcurrentrec});
            }
         }
         else{
            if (!in_array(@refurl,$arec->{urlofcurrentrec})){
               push(@refurl,$arec->{urlofcurrentrec});
            }
         }
      }
   }
   else{
      # admin-c resolved by NOAH
      my @userids=sort(keys(%userid));
      if (exists($userid->{userid}->{$userids[0]}) &&
          !exists($cadmin{$userids[0]})){
         push(@cadmin,$userid->{userid}->{$userids[0]});
      }



      
   }


   my $r={};
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
   if (keys(%networks)){
      $r->{networks}=[values(%networks)];
   }
   if (keys(%applid)){
      $r->{related}=[
        map({{dataobj=>'itil::appl',dataobjid=>$_}} keys(%applid))
      ];
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

