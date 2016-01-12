package TS::qrule::AccessUrlResolver;
#######################################################################
=pod

=head3 PURPOSE

This rule checks the DNS resolv posibility of the hostname part
in the URL. Urls at the networkarea "internet" will be resolved
by http://restdns.net/

=head3 IMPORTS

NONE

=head3 HINTS

no english hints avalilable

[de:]

keine Hinweise vorhanden - einfach die richtige URL eintragen!

=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
use itil::lib::Listedit;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["itil::lnkapplurl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   my $exitcode=0;
   my $desc={qmsg=>[],solvtip=>[]};
   my @ipl;
   my $host=$rec->{hostname};

   if ($rec->{network} eq "Telekom Product and Inovation Net"){
      $desc->{qmsg}=['ignoring Telekom Product and Inovation Net'];
      return($exitcode,$desc);
   }
   if ($host eq ""){
      my $msg="can not identify hostname in:".$rec->{fullname};
      push(@{$desc->{qmsg}},$msg);
      push(@{$desc->{dataissue}},$msg);
   }elsif ($host=~m/^\d+\.\d+\.\d+\.\d+$/){ # url redirects already to an ip
      push(@ipl,$host);
   }
   else{
      if (lc($rec->{network}) eq "internet"){
         my $ua;
         eval('
            use LWP::UserAgent;
            use HTTP::Request::Common;
           
            $ua=new LWP::UserAgent(env_proxy=>0);
            $ua->timeout(60);
         ');
         if ($@ ne ""){
            msg(ERROR,$@);
            return(undef);
         }
         else{
            my $proxy=$self->getParent->Config->Param("http_proxy");
            if ($proxy ne ""){
               msg(INFO,"set proxy to $proxy");
               $ua->proxy(['http', 'ftp'],$proxy);
            }
            my $url="http://restdns.net/".$host;
            my $response=$ua->request(GET($url));
            if ($response->code ne "200"){
               msg(ERROR,"$self URL request $url failed");
            }
            else{
               my $res=$response->content;
               my @resipl=grep(!/^\s*$/,split(/\s+/,$res));
               my $msg;
               my $ipfail=0;
               foreach my $ip (@resipl){
                  last if ($ipfail);
                  if (!$self->itil::lib::Listedit::IPValidate($ip,\$msg)){
                     $ipfail++;
                  }
               }
               if ($ipfail){
                  msg(ERROR,"restdns result invalid for $url");
               }
               else{
                  push(@ipl,@resipl);
               }
            }
         }
      }
      else{
         my $res;
         eval('
            use Net::DNS;
            $res=Net::DNS::Resolver->new();
         ');
         if ($@ ne ""){
            msg(ERROR,$@);
            return(undef);
         }
         else{
            my $query=$res->search($host);
            if ($query){
               foreach my $rr ($query->answer) {
                  next unless($rr->type eq "A");
                  push(@ipl,$rr->address);
               }
               if ($#ipl==-1){
                  my $msg="can not find any ip for: ".$host;
                  push(@{$desc->{qmsg}},$msg);
                  push(@{$desc->{dataissue}},$msg);
               }
            }
            elsif ($res->errorstring eq "NXDOMAIN" ||
                   $res->errorstring eq "NOERROR"){
               my $msg="can not resolv hostname: ".$host;
               push(@{$desc->{qmsg}},$msg);
               push(@{$desc->{dataissue}},$msg);
            }
            else{
               msg(ERROR,$self->Self()." query failed: ".$res->errorstring.
                         " for ".$host);
               return(undef);
            }
         }
      }
   }
   my $lastip=getModuleObject($self->getParent->Config,"itil::lnkapplurlip");
   my $srcload=NowStamp("en");
   foreach my $ip (@ipl){
      $lastip->ValidatedInsertOrUpdateRecord({
         name=>$ip,
         srcload=>$srcload,
         lnkapplurlid=>$rec->{id}
      },{name=>\$ip,lnkapplurlid=>\$rec->{id}});
   }
   $lastip->BulkDeleteRecord({'srcload'=>"<'$srcload-7d GMT' OR [EMPTY]",
                              lnkapplurlid=>\$rec->{id}});

   $lastip->ResetFilter();
   $lastip->SetFilter({lnkapplurlid=>\$rec->{id}});
   my @l=$lastip->getHashList(qw(id));

   if ($#l==-1){
      $exitcode=3 if ($exitcode<3);
      my $msg="unable to resolv hostname part of url in DNS";
      push(@{$desc->{qmsg}},$msg);
      push(@{$desc->{dataissue}},$msg);
   }
   return($exitcode,$desc);
}




1;
