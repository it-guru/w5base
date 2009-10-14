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
   my $locop=getModuleObject($self->Config,"base::location");
   my $grp=getModuleObject($self->Config,"base::grp");
   my $org="DTAG.T-HOME";

   $grp->SetFilter({fullname=>\$org});
   my ($grprec,$msg)=$grp->getOnlyFirst(qw(id fullname name));
   if (!defined($grprec)){
      return({exitcode=>2,msg=>"can not find organisation $org"});
   }

   my %thloc;

   $tsiloc->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$tsiloc->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         msg(DEBUG,"process streetser $rec->{id}:$rec->{location};".
                   " $rec->{address1}");
         foreach my $w5id (@{$rec->{w5locid}}){
            msg(DEBUG,"w5locid=%s",$w5id);
            $loc->SetFilter({id=>\$w5id});
            my ($w5loc)=$loc->getOnlyFirst(qw(ALL));
            my $newrec={};
            if ($w5loc->{orggrpid} ne $grprec->{grpid}){
               $newrec->{orggrpid}=$grprec->{grpid};
            }
            if ($w5loc->{orgprio} ne $rec->{prio}){
               $newrec->{orgprio}=$rec->{prio};
            }
            if (keys(%$newrec)){
               msg(DEBUG,"write=%s",Dumper($newrec));
               $loc->ValidatedUpdateRecord($w5loc,$newrec,{id=>\$w5loc->{id}});
            }
            $thloc{$w5loc->{id}}++;
         }

         ($rec,$msg)=$tsiloc->getNext();
      } until(!defined($rec));
   }
   if (!$tsiloc->Ping()){
      return({msg=>'ping failed to dataobject '.$tsiloc->Self(),exitcode=>1});
   }


   $loc->ResetFilter();
   $loc->SetFilter({orggrpid=>\$grprec->{grpid}});
   $loc->SetCurrentView(qw(ALL));

   my ($rec,$msg)=$loc->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         if (!exists($thloc{$rec->{id}})){
            $locop->ValidatedUpdateRecord($rec,{orgprio=>'2',orggrpid=>undef},
                                          {id=>\$rec->{id}});
         }
         ($rec,$msg)=$loc->getNext();
      } until(!defined($rec));
   }






   return({exitcode=>0}); 
}

1;
