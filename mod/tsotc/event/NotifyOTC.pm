package tsotc::event::NotifyOTC;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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


   $self->RegisterEvent("NotifyOTC","NotifyOTC");
   return(1);
}

sub NotifyOTC
{
   my $self=shift;
   my %param=@_;

   my $url=$self->Config->Param("tsotcControllerURL");

   if (!ref($url) && $url ne ""){
      delete($ENV{HTTP_PROXY});
      delete($ENV{http_proxy});
     
      my $ua = new LWP::UserAgent();
      $url.="/" if (!($url=~m/\/$/));
      if ($param{mod} ne ""){
         $url.="$param{mod}/";
      }
      if ($param{op} ne ""){
         $url.="$param{op}/";
      }
      $url.="event";
      if ($param{id} ne ""){
         $url.="?id=".$param{id};
      }
      my $req= new HTTP::Request('GET',$url);
      #$req->authorization_basic($wsuser, $wspass);
      my $response=$ua->request($req);
     
     
      if ($response->is_success) {
         #msg(DEBUG,"result:\n".$response->content);
         $self->Log(INFO,"trigger","NotifyOTC: id:%d",$param{id});
         return({exitcode=>0,msg=>'ok'});
      }
      else {
         $self->Log(WARN,"trigger","NotifyOTC: id:%d :".$response->status_line,
                    $param{id});
         return({exitcode=>1,msg=>'fail:'.$response->status_line});
      }
   }
   return({exitcode=>0,msg=>'ok'});
}



1;
