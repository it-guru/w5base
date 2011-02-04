package AL_TCom::event::ImportINetworkContacts;
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


   $self->RegisterEvent("ImportINetworkContacts",
                        "ImportINetworkContacts",timeout=>30);
   return(1);
}

sub ImportINetworkContacts
{
   my $self=shift;
   my %param=@_;

   my $wsuser=$self->Config->Param("WEBSERVICEUSER");
   my $wspass=$self->Config->Param("WEBSERVICEPASS");
   my $wsproxy=$self->Config->Param("WEBSERVICEPROXY");
   $wsuser=$wsuser->{inetwork} if (ref($wsuser) eq "HASH");
   $wspass=$wspass->{inetwork} if (ref($wspass) eq "HASH");
   $wsproxy=$wsproxy->{inetwork} if (ref($wsproxy) eq "HASH");

   if ($wsuser eq ""){
      return({exitcode=>0,msg=>'ok - no web service account data'});
   }
   my %state;





   my $appl=getModuleObject($self->getParent->Config(),"itil::appl");
   $appl->SetNamedFilter("DBASE",{name=>"Flex* EKI* IT-Base*"});
   $appl->SetFilter({customer=>"DTAG DTAG.*",cistatusid=>"<=5"});
   my @idl=$appl->getHashList(qw(id name));

   eval('
   sub SOAP::Transport::HTTP::Client::get_basic_credentials { 
       return $wsuser => $wspass;
   }
   ');

   my @msglist;


   my $n=0;
   foreach my $arec (@idl){
      $n++;
      msg(INFO,"check applid $arec->{name}");

      my $inetwxmlns="http://tempuri.org/";

      my $method = SOAP::Data->name('GetSMforApplication')->prefix('ns');

      my @SOAPparam;
      push(@SOAPparam,SOAP::Data->name("QueryName")
           ->type("")->prefix('ns')->value("w5baseid"));
      push(@SOAPparam,SOAP::Data->name("QueryValue")
           ->type("")->prefix('ns')->value($arec->{id}));



      my $soap=SOAP::Lite->uri($inetwxmlns)->proxy($wsproxy)
                         ->on_action(sub{'"'.$inetwxmlns.$_[1].'"'});
      $soap->serializer->register_ns($inetwxmlns,'ns');

      my $res;
      eval('$res=$soap->call($method=>@SOAPparam);'); 
      if (!defined($res) || ($@=~m/Connection refused/)){
         msg(ERROR,"can not connect to ".$wsproxy);
         return({exitcode=>10,
                 msg=>'can not connect to INetwork - Connection refused'});
      }

      if ($res->fault){
         $self->Log(ERROR,"trigger","INetwork: ".$res->fault->{faultstring});
         return({exitcode=>2,msg=>$res->fault->{faultstring}});
      }
      my $indata=$res->result();
      if (ref($indata) eq "HASH" && exists($indata->{SMAppData})){
         my ($errorcode,$msg)=$self->processRecord($indata->{SMAppData});
         if ($errorcode){
            push(@msglist,$msg);
         }
        
      }
      else{
         push(@{$state{notfound}},
         sprintf("'%s' (W5BaseID=%s)",$arec->{name},$arec->{id}));
      }
   #   $self->Log(INFO,"trigger","INetwork: ".$res->result());
   }
   printf("Applications not found in I-Network:\n%s\n",
          join("\n",@{$state{notfound}}));

   printf("Messages:\n%s",join("\n",@msglist));
   return({exitcode=>0,msg=>"ok - checked $n records"});
}

sub processRecord
{
   my $self=shift;
   my $d=shift;

   if (!($d->{'smEmail'}=~m/^\S+\@\S+$/)){
      return(1,"invalid smEmail '$d->{'smEmail'}'");
   }

   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({email=>$d->{'smEmail'}});
   my ($urec,$msg)=$user->getOnlyFirst(qw(userid));
   if (!defined($urec)){
      return(2,"user '$d->{'smEmail'}' does not exists");
   }

   my $userid=$urec->{userid};
   my $w5baseid=$d->{'w5baseId'};
   my $w5basename=$d->{'w5baseAppname'};
   my $inname=$d->{'inetworkAppname'};
   my $inid=$d->{'inetworkId'};

   print Dumper($d);

#
   my $appl=getModuleObject($self->Config,"TCOM::custappl");

   $appl->SetFilter({id=>\$w5baseid});
   my ($arec,$msg)=$appl->getOnlyFirst(qw(id name wbvid 
                                          custname custnameid));

   if (!defined($arec)){
      return(3,"application '$w5basename' ($w5baseid) not found in w5base");
   }

   if (lc($arec->{name}) ne lc($w5basename)){
      return(4,"W5base appname I-Network ($w5basename) does not ".
               "match $arec->{name}");
   }

   if (!$appl->ValidatedUpdateRecord($arec,{
          wbvid=>$userid,
          custname=>$inname,
          custnameid=>"IN:$inid"
      },{id=>\$w5baseid})){
      return(5,"fail to update");
   }


   return(0,"OK");
}




1;
