package AL_TCom::event::NotifyINetwork;
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
#use SOAP::Lite +trace=>'all';
use SOAP::Lite;
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


   $self->RegisterEvent("NotifyINetwork","NotifyINetwork");
   return(1);
}

sub NotifyINetwork
{
   my $self=shift;
   my %param=@_;

   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
   my $wspass=$self->Config->Param("WEBSERVICEPASS");
   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   $wsuser=$wsuser->{inetwork} if (ref($wsuser) eq "HASH");
   $wspass=$wspass->{inetwork} if (ref($wspass) eq "HASH");
   $wsproxy=$wsproxy->{inetwork} if (ref($wsproxy) eq "HASH");

   return({exitcode=>0,msg=>'ok'}) if ($wsuser eq "");
   sub SOAP::Transport::HTTP::Client::get_basic_credentials { 
       return $wsuser => $wspass;
   }
   my $inetwxmlns="http://tempuri.org";

   my $header = SOAP::Header->name(AuthentifizierungsHeader => { 
     userName => $wsuser,
     password => $wspass
   })->uri($inetwxmlns)->prefix(''); 


   my $method = SOAP::Data->name('TriggerINetwork')->attr({xmlns=>$inetwxmlns});

   my @params=(
# $header,
                SOAP::Data->name('Module')->type("")->value('myMod'),
                SOAP::Data->name('Submodule')->type("")->value('MySub'),
                SOAP::Data->name('Operation')->type("")->value('MyOp'),
                SOAP::Data->name('IdentifyBy')->type("")->value('MyId')  );

   my $res=SOAP::Lite->uri($inetwxmlns)->proxy($wsproxy)
                     ->on_action(sub{'"'.join('/',$inetwxmlns,$_[1]).'"'})
                     ->call($method=>@params);


#printf STDERR ("fifi d=%s\n",Dumper($res));


   if (open(F,">>/tmp/event.log")){
      printf F ("Event=%s\n",time());
      printf F ("Data=%s\n",Dumper(\%param));
      close(F);
   }



   return({exitcode=>0,msg=>'ok'});
}





1;
