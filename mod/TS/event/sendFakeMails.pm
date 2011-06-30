package TS::event::sendFakeMails;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::date;
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


   $self->RegisterEvent("sendFakeMails","sendFakeMails");
   return(1);
}

sub sendFakeMails
{
   my $self=shift;
   my $user=getModuleObject($self->Config,"base::user");


   $user->SetFilter({userid=>['12144878980001','11634955470001']});

   foreach my $urec ($user->getHashList(qw(surname givenname email 
                                           office_phone office_mobile))){
      $self->doNotify($urec);
   }

   return({exitcode=>0});
}


sub doNotify
{
   my $self=shift;
   my $urec=shift;

   my $msg=
      "Sehr geehrte Damen und Herren,\n".
      "\n".
      "das Lösungswort für das Gewinnspiel lautet:\n\n".
      "                 <b><font size=+1>PagePlace</font></b>\n\n".
      "Im Falle eines Gewinnes erreichen Sie mich\nunter ".
      "der Telefonnummer ".$urec->{office_phone}." .\n".
      "Meine E-Mail Adresse lautet ".$urec->{email}."\n\n\n".
      "Mit freundlichen Grüssen\n\n".
      $urec->{surname}." ".$urec->{givenname};
   my $wfa=getModuleObject($self->Config,"base::workflowaction");
#   $wfa->Notify("","Gewinnspiel Motorola Xoom",$msg,
#                emailfrom=>$urec->{email},
#                emailtemplate=>'sendmailnativ',
#                emailto=>'online.redaktion@telekom.de',
#                emailbcc=>[11634953080001,$urec->{userid}]);
}
1;
