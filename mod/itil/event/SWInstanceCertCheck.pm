package itil::event::SWInstanceCertCheck;
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
use IO::Socket::SSL;
use Net::SSLeay;
use Date::Parse;
use Carp;

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


   $self->RegisterEvent("SWInstanceCertCheck","SWInstanceCertCheck");
   return(1);
}

sub SWInstanceCertCheck
{
   my $self=shift;
   my %param=@_;

   my $sw=getModuleObject($self->Config,"itil::swinstance");
   my $swop=$sw->Clone();

   $sw->SetFilter({cistatusid=>"<6",sslurl=>'!""'});
   $sw->SetCurrentOrder(qw(NONE));
   $sw->SetCurrentView(qw(ALL));

   my ($swrec,$msg)=$sw->getFirst(unbuffered=>1);
   if (defined($swrec)){
      do{
         msg(DEBUG,"check %s",$swrec->{fullname});
         my ($msg,$begin,$end);
         if (my ($host)=$swrec->{sslurl}=~m#^https://([^/]+)$#){
            eval('($msg,$begin,$end)=$self->checkSSL($host,443);'); 
            if ($@ ne ""){
               $msg=$@;
            }
         }
         else{
            $msg="ERROR: unknown URL format";
         }

         if ($msg ne ""){
            my $now=NowStamp();
            my $newrec={sslcheck=>$now,sslstate=>$msg};
            if ($end ne ""){
               $newrec->{sslend}=$end;
            }
            else{
               $newrec->{sslend}=undef;
            }
            if ($begin ne ""){
               $newrec->{sslbegin}=$begin;
            }
            else{
               $newrec->{sslbegin}=undef;
            }
            $swop->ValidatedUpdateRecord($swrec,$newrec,{id=>\$swrec->{id}});
         }



         ($swrec,$msg)=$sw->getNext();
      }until(!defined($swrec));
   }



   return({exitcode=>0,msg=>'ok'});
}

sub checkSSL
{
   my $self=shift;
   my $host=shift;
   my $port=shift;

   my $sock = IO::Socket::SSL->new("$host:$port");
   return("ERROR: connect failed to $host:$port") if ! $sock;
   my $cert = $sock->peer_certificate();

   my $expire_date_asn1 = Net::SSLeay::X509_get_notAfter($cert);
   my $expire_date_str  = Net::SSLeay::P_ASN1_UTCTIME_put2string($expire_date_asn1);
   ### $expire_date_str
   my $begin_date_asn1  = Net::SSLeay::X509_get_notBefore($cert);
   my $begin_date_str   = Net::SSLeay::P_ASN1_UTCTIME_put2string($begin_date_asn1);
   ### $begin_date_str

   $sock->close;

   my $begin_date  = DateTime->from_epoch(epoch => str2time($begin_date_str));
   my $expire_date = DateTime->from_epoch(epoch => str2time($expire_date_str));


   printf STDERR ("fifi begin_date_str $begin_date\n");
   printf STDERR ("fifi expire_date_str $expire_date\n");

   return("check OK",$begin_date,$expire_date);
}





1;
