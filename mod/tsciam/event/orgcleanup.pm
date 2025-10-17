package tsciam::event::orgcleanup;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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

   $self->RegisterEvent("CIAMOrgareaRefresh",\&UpdateOrgareaStructure,
                         timeout=>14400);
   return(1);
}

sub UpdateOrgareaStructure
{
   my $self=shift;
   my $app=$self->getParent();
   $self->{SRCSYS}="CIAM";

   my $Config=$self->getParent->Config();
   my $grpuser=getModuleObject($Config,"base::lnkgrpuser");
   $grpuser->SetFilter(srcsys=>\$self->{SRCSYS},      
                       srcload=>"<now-7d");           # übergang = 7 Tage
   $grpuser->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$grpuser->getFirst();
   if (defined($rec)){
      do{
         if ($rec->{expiration} eq ""){
            my $exp="now+28d";  # damit sinnvolle Beanchrichtigungen raus gehen
            $exp=$app->ExpandTimeExpression($exp,"en","GMT","GMT");
            $grpuser->ValidatedUpdateRecord($rec,{expiration=>$exp,
                                                  roles=>$rec->{roles}},
              {userid=>\$rec->{userid},lnkgrpuserid=>\$rec->{lnkgrpuserid}});
         }
         ($rec,$msg)=$grpuser->getNext();
      }until(!defined($rec));
   }
   else{
      if (defined($msg)){
         msg(ERROR,"LDAP cleanup problem:%s",$msg);
      }
   }



   $grpuser->SetFilter(srcsys=>\$self->{SRCSYS},       # (4 Wochen)
                       srcload=>"<now-42d");           # übergang = 42 Tage
   $grpuser->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$grpuser->getFirst();
   if (defined($rec)){
      do{
         $grpuser->ValidatedDeleteRecord($rec);
         ($rec,$msg)=$grpuser->getNext();
      }until(!defined($rec));
   }
   else{
      if (defined($msg)){
         msg(ERROR,"LDAP cleanup problem:%s",$msg);
      }
   }

   return({msg=>'OK',exitcode=>0});
}
1;
