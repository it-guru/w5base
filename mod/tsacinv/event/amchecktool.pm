package tsacinv::event::amchecktool;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("amfarmcheck","amfarmcheck");
   $self->RegisterEvent("amchecktool","amchecktool");
   $self->RegisterEvent("amVerifyGroupParents","amVerifyGroupParents");
   $self->RegisterEvent("ChkAppToW5Base","ChkAppToW5Base");
   return(1);
}



sub amfarmcheck
{
   my $self=shift;
   msg(INFO,"ok start");

   my $name="dcs*";
   my %farmlist;

   my $amfarm=getModuleObject($self->Config,"tsacinv::itfarm");
   my $ecfarm=getModuleObject($self->Config,"tsadopt::vfarm");

   $amfarm->SetFilter({status=>'!"out of operation"',
                       name=>$name});
   foreach my $frec ($amfarm->getHashList(qw(name))){
      $farmlist{uc($frec->{name})}->{amcds}++;
   }

   $ecfarm->SetFilter({state=>'"in operation"',
                       name=>$name});
   foreach my $frec ($ecfarm->getHashList(qw(name))){
      $farmlist{uc($frec->{name})}->{ecmdb}++;
   }

   

   print Dumper(\%farmlist);

}


sub amchecktool
{
   my $self=shift;
   my $app=$self->getParent;

   my $acappl=getModuleObject($self->Config,"tsacinv::appl");
   $acappl->SetCurrentView(qw(name));
   my %c;

   my ($rec,$msg)=$acappl->getFirst();
   if (defined($rec)){
      do{
         $c{$rec->{name}}++;
         ($rec,$msg)=$acappl->getNext();
      } until(!defined($rec));
   }
   my $cn;
   my $ct;
   foreach my $name (sort(keys(%c))){
      if ($c{$name}>2){
         $cn++;
         printf("%-30s;%d entries\n",$name,$c{$name});
         $ct+=$c{$name}-1;
      }
   }
   printf("%d dublicate enties\n",$cn);
   printf("%d total appl to kill\n",$ct);
   return({exicode=>0});
}


sub amVerifyGroupParents
{
   my $self=shift;
   my $app=$self->getParent;


   my $checked=0;
   my @erram;
   my @errlo;


   if (1){ # location check
      my $location=getModuleObject($self->Config,"tsacinv::location");
      my %sould=(zipcode=>'60528',
                 country=>'de',
                 location=>'Frankfurt am Main',
                 address1=>'Hahnstrasse 43'); 
      $location->SetFilter({fullname=>"*frankfurt*hahnstr*43*"});
      foreach my $loc ($location->getHashList(
                qw(fullname country address1 zipcode location  
                   locationtype locationid))){
         $checked++;
         my @setam;
         if ($loc->{zipcode} ne $sould{zipcode}){
            push(@setam,"- ZIPCODE: the zipcode of the location must be ".
                      "'$sould{zipcode}'. The current value '$loc->{zipcode}' ".
                      "is wrong.");
         } 
         if ($loc->{address1} ne $sould{address1}){
            push(@setam,"- ADDRESS: the address must be ".
                      "'$sould{address1}'. The current ".
                      "address '$loc->{address1}' is wrong.");
         } 
         if ($loc->{location} ne $sould{location}){
            push(@setam,"- LOCATION: the name of the location ".
                      "'$sould{location}'. The current ".
                      "location name '$loc->{location}' is wrong.");
         } 
         if ($#setam!=-1 && lc($loc->{country}) ne lc($sould{country})){
            push(@setam,"- COUNTRY: the country of the location ".
                      "sould be set to '$sould{country}.");
         } 
         if ($#setam!=-1){
            push(@erram,
                 join("\n","LOCATION:".$loc->{fullname}." (".($#erram+2)."):",
                 @setam));
         }
      }
   }






   if (1){ # group strucutre check
      my $grp=getModuleObject($self->Config,"base::grp");
      my $agrp=getModuleObject($self->Config,"tsacinv::group");
      $agrp->SetCurrentView(qw(name supervisorldapid parent));
      $agrp->SetFilter({name=>"CSS.AO.DTAG CSS.AO.DTAG.*"});
      my ($rec,$msg)=$agrp->getFirst();
      if (defined($rec)){
         do{
            msg(INFO,"check group '%s'",$rec->{name});
            msg(INFO," - supervisor posix : %s",$rec->{supervisorldapid});
            msg(INFO," - parent           : %s",$rec->{parent});
            $checked++;
    
            my $chkname="DTAG.TSI.Prod.".uc($rec->{name});
            $grp->ResetFilter();
            $grp->SetFilter({fullname=>\$chkname});
            my ($w5rec)=$grp->getOnlyFirst(qw(fullname));
            my @setam;
            my @setlo;
            {
               if (!defined($w5rec)){
                  push(@setlo,"- MISSW5GROUP: the assetmanager group ".
                            "'".$rec->{name}."' could not be found or exists ".
                            " by an other name in W5Base group list!");
               }
               else{
                  my @boss;
                  foreach my $u (@{$w5rec->{users}}){
                     if (grep(/^(RBoss2|RBoss)$/,@{$u->{roles}})){
                        push(@boss,$u->{posix});
                     }
                  }
                  if ($#boss!=-1){
                     if (!in_array(\@boss,[$rec->{supervisorldapid}])){
                       # push(@setam,"- WRONGSUPERV: the supervisor of group ".
                       #           "'".$rec->{name}."' is not '".
                       #           $rec->{supervisorldapid}."'! Candidates are ".
                       #           join(", ",map({"'".$_."'"} @boss)).".");
                     }
                  }
               }
               if ($#setlo!=-1){
                  push(@errlo,
                       join("\n",$rec->{name}." (".($#errlo+2)."):",@setlo));
               }
            }
            {
               my $shouldparent=$rec->{name};
               $shouldparent=~s/\.[^\.]+$//;
               if ($shouldparent ne $rec->{parent}){
                  push(@setam,"- AMPARENTGRP: parent group of '".$rec->{name}.
                            "' must be changed to '".
                            $shouldparent."'! The current entry '".
                            $rec->{parent}."' is wrong.");
               }
               if ($#setam!=-1){
                  push(@erram,
                       join("\n","GROUP:".$rec->{name}." (".($#erram+2)."):",
                            @setam));
               }
            }
            ($rec,$msg)=$agrp->getNext();
         } until(!defined($rec));
      }
   }
   my $d="";
   @errlo=();
   if ($#erram!=-1){
      $d.="Hello dear Config-Manager,\n\n".
          "there are some problems found in AssetManager data structures. ".
          "Feal free to press ahead the solution of this issues.\n\n\n";
      $d.=sprintf("AssetManager problems:\n");
      $d.=sprintf("======================\n");
      $d.=sprintf("%s",join("\n\n",@erram));
      if ($#errlo!=-1){
         $d.=sprintf("\n\n");
         $d.=sprintf("----------------------------------------------------\n");
         $d.=sprintf("\n\n");
      }
   }
   if ($#errlo!=-1){
      $d.=sprintf("posible W5Base problems:\n");
      $d.=sprintf("========================\n");
      $d.=sprintf(join("\n\n",@errlo));
   }
   if ($#errlo!=-1 || $#erram!=-1){
      $d.=sprintf("\n\n");
      $d.=sprintf("* %d of %d checks ".
                  "found issues in AssetManager.\n",
                  $#erram+1,$checked);
      if ($#errlo!=-1){
         $d.=sprintf("* %d of %d ".
                     "checks found posible issues in W5Base.\n",
                     $#errlo+1,$checked);
      }
   }
   if ($d ne ""){
      my $act=getModuleObject($self->Config,"base::workflowaction");
    
      $act->Notify("","Problem Report AssetManager (".($#erram+1)." issues)",$d,
                   emailfrom=>'"AssetManager verification" <>',
                  # emailto=>['11756437640004'], # Moebius
                   emailto=>['11634955470001'], # Merx
                   adminbcc=>1);
      print $d;
   }
}

1;
