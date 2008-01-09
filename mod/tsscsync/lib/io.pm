package tsscsync::lib::io;
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
use Data::Dumper;
use kernel;


sub loadCredentials
{
   my $self=shift;
   my $uri=$self->Config->Param('DATAOBJBASE');
   my $user=$self->Config->Param('DATAOBJUSER');
   my $pass=$self->Config->Param('DATAOBJPASS');
   $uri={} if (ref($uri) ne "HASH");
   $user={} if (ref($user) ne "HASH");
   $pass={} if (ref($pass) ne "HASH");
   $uri=$uri->{tsscfrontend};
   $user=$user->{tsscfrontend};
   $pass=$pass->{tsscfrontend};
   my $showpass=$pass;
   $showpass=~s/./*/g;
   msg(DEBUG,"SC Frontend user=$user");
   msg(DEBUG,"SC Frontend pass=$showpass");
   msg(DEBUG,"SC Frontend base=$uri");
   return($uri,$user,$pass);
}

sub ConnectSC
{
   my $self=shift;

   $self->{sc}=new SC::Customer::TSystems;
   my ($SCuri,$SCuser,$SCpass)=$self->loadCredentials();
   if ($SCuri eq "" || $SCuser eq "" || $SCpass eq ""){
      return({exitcode=>1,msg=>'ERROR: missing SC frontend account'});
   }
   if (!$self->{sc}->Connect($SCuri,$SCuser,$SCpass)){
      msg(DEBUG,"SC msg=%s",($self->{sc}->LastMessage())[1]);
      msg(ERROR,"fail with ($SCuri,$SCuser,$SCpass)");
      return({msg=>"ERROR: ServiceCenter connect failed",
              exitcode=>1001});
   }
   msg(DEBUG,"SC Connect OK");
   msg(DEBUG,"try Login");
   if (!$self->{sc}->Login()){
      msg(DEBUG,"SC msg=%s",($self->{sc}->LastMessage())[1]);
      msg(ERROR,"fail with ($SCuri,$SCuser,$SCpass)");
      return({msg=>"ERROR: ServiceCenter login failed",
              exitcode=>1002});
   }
   msg(DEBUG,"SC Login OK");

   return(undef);
}

sub DisconnectSC
{
   my $self=shift;

   msg(DEBUG,"try Logout");
   if (!$self->{sc}->Logout()){
      return({msg=>"ERROR: ServiceCenter logout failed",
              exitcode=>1003});
   }
   msg(DEBUG,"SC Logout OK");
   return(undef);
}

1;
