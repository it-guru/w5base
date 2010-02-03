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
   my $lnk=getModuleObject($self->Config,"base::lnkcontact");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $org="DTAG.T-HOME";
   my $start=NowStamp("en");

   $grp->SetFilter({fullname=>\$org});
   my ($grprec,$msg)=$grp->getOnlyFirst(qw(id fullname name));
   if (!defined($grprec)){
      return({exitcode=>2,msg=>"can not find organisation $org"});
   }

   my %thloc;

   $tsiloc->SetCurrentView(qw(ALL));
   #$tsiloc->SetFilter({location=>"Bamberg"});
   my ($rec,$msg)=$tsiloc->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(DEBUG,"process streetser $rec->{id}:$rec->{location};".
                   " $rec->{address1}");
         foreach my $w5id (@{$rec->{w5locid}}){
            msg(DEBUG,"w5locid=%s",$w5id);
            $loc->SetFilter({id=>\$w5id});
            my ($w5loc)=$loc->getOnlyFirst(qw(ALL));
            #printf STDERR ("d=%s\n",Dumper($w5loc));
            my $found;
            foreach my $crec (@{$w5loc->{contacts}}){
                my $roles=$crec->{roles};
                $roles=[$roles] if (ref($roles) ne "ARRAY");
                if ($crec->{target} eq "base::grp" &&
                    $crec->{targetid} eq $grprec->{grpid}){
                   $found=$crec->{id};
                }
            }
            if (!defined($found)){
               my $lnkid=$lnk->ValidatedInsertRecord({
                  target=>'base::grp',
                  targetid=>$grprec->{grpid},
                  srcsys=>"TSINET",
                  srcload=>NowStamp("en"),
                  parentobj=>"base::location",
                  refid=>$w5loc->{id}
               });
               $found=$lnkid if ($lnkid);
            }
            if ($found){
               $lnk->SetFilter({id=>\$found});
               my ($lnkrec)=$lnk->getOnlyFirst(qw(ALL));
               my $roles=$lnkrec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if (!grep(/^staffloc$/,@$roles)){
                  push(@$roles,"staffloc");
               }
               @$roles=grep(!/^\s*$/,@$roles);
               
               $lnk->ValidatedUpdateRecord($lnkrec,{comments=>
                                                       'Prio'.$rec->{prio},
                                                    srcsys=>'TSINET',
                                                    srcload=>$start,
                                                    roles=>$roles},
                                           {id=>\$found});
            }
            $thloc{$w5loc->{id}}++;
         }

         ($rec,$msg)=$tsiloc->getNext();
      } until(!defined($rec));
   }
   if (!$tsiloc->Ping()){
      return({msg=>'ping failed to dataobject '.$tsiloc->Self(),exitcode=>1});
   }


   $lnk->ResetFilter();
   $lnk->SetFilter({srcsys=>\'TSINET',srcload=>"\"<$start\""});
   $lnk->DeleteAllFilteredRecords("ValidatedDeleteRecord");

   return({exitcode=>0}); 
}

1;
