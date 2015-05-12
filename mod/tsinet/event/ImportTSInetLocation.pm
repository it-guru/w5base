package tsinet::event::ImportTSInetLocation;
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
use kernel::Event;
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

   $self->RegisterEvent("ImportTSInetLocation","ImportTSInetLocation");
   return(1);
}

sub ImportTSInetLocation
{
   my $self=shift;

   my $tsiloc=getModuleObject($self->Config,"tsinet::location");
   my $loc=getModuleObject($self->Config,"base::location");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $rel=getModuleObject($self->Config,"base::lnklocationgrp");
   my $start=NowStamp("en");

   my @problems;


   my %thloc;

   $tsiloc->SetCurrentView(qw(ALL));
   #$tsiloc->SetCurrentOrder("NONE");
   #$tsiloc->SetFilter({location=>"Bamberg"});
   #$tsiloc->SetFilter({location=>"Berlin"});
   my ($rec,$msg)=$tsiloc->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(DEBUG,"process streetser $rec->{id}:$rec->{location}");
         msg(DEBUG," - address1: $rec->{address1}");
         msg(DEBUG," - customer: $rec->{customer}");
         msg(DEBUG," - prio    : $rec->{prio}");
         msg(DEBUG," - validto : $rec->{validto}");
         my $locvalid=1;
         if ($rec->{validto} ne ""){
            my $duration=CalcDateDuration(NowStamp("en"),$rec->{validto});
            if ($duration->{totalseconds}<0){
               $locvalid=0;
            }
         }
         if ($locvalid){ 
            my $org=$rec->{customer};
            $org=~s/^DTAG\.TDE/DTAG.TDG/;
            $org=~s/^DTAG\.TSG/DTAG.TDG.TSG/;
            $grp->ResetFilter();
            $grp->SetFilter({fullname=>\$org});
            my ($grprec,$msg)=$grp->getOnlyFirst(qw(id fullname name));
            if (!defined($grprec)){
               return({exitcode=>2,msg=>"can not find organisation $org"});
            }
            if ($#{$rec->{w5locid}}==-1){
               push(@problems," - no w5bloc for ".
                  "streetser $rec->{streetser} ".
                  "($rec->{prio};$rec->{location};$rec->{address1})");
            }
            else{
               foreach my $w5id (@{$rec->{w5locid}}){
                  msg(DEBUG,"w5locid=%s",$w5id);
                  $loc->SetFilter({id=>\$w5id});
                  my ($w5loc)=$loc->getOnlyFirst(qw(name grprelations));
                  my $found;
                  foreach my $crec (@{$w5loc->{grprelations}}){
                      if ($grprec->{grpid} eq $crec->{grpid}){
                         $found=$crec->{id};
                      }
                  }
                  if (!defined($found)){
                     my $lnkid=$rel->ValidatedInsertRecord({
                        grpid=>$grprec->{grpid},
                        srcsys=>"TSINET",
                        srcload=>NowStamp("en"),
                        locationid=>$w5loc->{id},
                        relmode=>'RMbusinesrel3'
                     });
                     $found=$lnkid if ($lnkid);
                  }
                  if ($found){
                     $rel->ResetFilter();
                     $rel->SetFilter({id=>\$found});
                     my ($lnkrec)=$rel->getOnlyFirst(qw(ALL));
                     my $relmode;
                     my $newrec={srcsys=>'TSINET',srcload=>$start};
                     if ($rec->{prio}==1){
                        $relmode="RMbusinesrel1";
                     }
                     elsif ($rec->{prio}==2){
                        $relmode="RMbusinesrel2";
                     }
                     elsif ($rec->{prio}==3){
                        $relmode="RMbusinesrel3";
                     }
                     else{
                        push(@problems," - unknown prio $rec->{prio} for ".
                                       "streetser $rec->{streetser} ".
                                       "($rec->{location};$rec->{address1})");
                     }
                     if (defined($relmode)){
                        $newrec->{relmode}=$relmode;
                        $rel->ValidatedUpdateRecord($lnkrec,$newrec,
                                                    {id=>\$found,
                                                    srcsys=>\'TSINET'});
                     }
                  }
                  $thloc{$w5loc->{id}}++;
               }
            }
         }

         ($rec,$msg)=$tsiloc->getNext();
      } until(!defined($rec));
   }
   if (!$tsiloc->Ping()){
      return({msg=>'ping failed to dataobject '.$tsiloc->Self(),exitcode=>1});
   }

   # cleanup contact links -> old style
   my $lnk=getModuleObject($self->Config,"base::lnkcontact");
   $lnk->ResetFilter();
   $lnk->SetFilter({srcsys=>\'TSINET',srcload=>"\"<$start-4d\""});
   $lnk->DeleteAllFilteredRecords("ValidatedDeleteRecord");

   $rel->ResetFilter();
   $rel->SetFilter({srcsys=>\'TSINET',srcload=>"\"<$start-4d\""});
   $rel->DeleteAllFilteredRecords("ValidatedDeleteRecord");


   if ($#problems!=-1){
      my $act=getModuleObject($self->Config,"base::workflowaction");
      $act->Notify(ERROR,"problems while tsinet to W5BaseDarwin sync",
                   "Found <b>".(($#problems)+1)." problems</b> ".
                   "while TSINET->W5Base locations syncronisation!\n\n".
                   join("\n",@problems),
                   emailfrom=>'"TSINET to W5BaseDarwin" <no_reply@w5base.net>',
                   emailto=>['12023045810001'], # Fritscher
                   emailcc=>['12480761360002'], # Steiger.
                   emailbcc=>['11634955570001'], # Junghans.
                  );
   }

   return({exitcode=>0}); 
}

1;
