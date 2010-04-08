package AL_TCom::event::NotifyDina;
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
use LWP::UserAgent;
use HTTP::Request;
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


   $self->RegisterEvent("NotifyDina","NotifyDina");
   return(1);
}

sub NotifyDina
{
   my $self=shift;
   my %param=@_;

   delete($ENV{HTTP_PROXY});
   delete($ENV{http_proxy});

   msg(DEBUG,"NotifyDina: start of NotifyDina");
   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
   my $wspass=$self->Config->Param("WEBSERVICEPASS");
   $wsproxy=$wsproxy->{dina} if (ref($wsproxy) eq "HASH");
   $wsuser=$wsuser->{dina} if (ref($wsuser) eq "HASH");
   $wspass=$wspass->{dina} if (ref($wspass) eq "HASH");
   return({exitcode=>0,msg=>'ok - no interface defined'}) if ($wsproxy eq "");
   return({exitcode=>0,msg=>'ok - only upd send'}) if ($param{'op'} ne "upd");

   my $ua = new LWP::UserAgent();
   $wsproxy.="?" if (!($wsproxy=~m/\?/));
   if ($param{id} ne ""){
      $wsproxy.="&id=".$param{id};
   }
   my $req= new HTTP::Request('GET',$wsproxy);
   $req->authorization_basic($wsuser, $wspass);
   my $response=$ua->request($req);


   if ($response->is_success) {
      #msg(DEBUG,"result:\n".$response->content);
      $self->Log(INFO,"trigger","Dina: WF:%d",$param{id});
      return({exitcode=>0,msg=>'ok'});
   }
   else {
      $self->Log(WARN,"trigger","Dina: WF:%d :".$response->status_line,
                 $param{id});
      return({exitcode=>1,msg=>'fail:'.$response->status_line});
   }
   return({exitcode=>0,msg=>'ok'});
}





1;
