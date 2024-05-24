#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks the ssl expiration on swinstances in cistate "installed/active"
or "available". If the expiration of the sslcheck url comes closer then
2 week, a dataissue will be generated.

=head3 IMPORTS

NONE

=head3 HINTS

[en:]

The Qrule checks on Software Instances in status "installed/active" or 
"available/ in project" if the certificate is available via the filled out URL.
It is important to ensure that the specified URL is accessible from the 
W5Base environment. Appropriate firewall permissions must be in place for 
this purpose.

[de:]

Die Qrule prüft an den Software-Instanzen im Status "installiert/aktiv" 
oder "verfügbar/in Projektierung" ob das Zertifikat über die angegebene URL 
abrufbar ist.
Dabei ist darauf zu achten, dass die angegebene URL netzmäßig von der 
W5Base-Umgebung aus erreichbar ist. Evtl. sind dafür entsprechende 
Firewall-Freischaltungen zu beauftragen.


=cut
#######################################################################
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
package itil::qrule::SWInstanceCertCheck;
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
   return(["itil::swinstance"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;


   my $sslend;
   my $sslstate="ERROR: unspecific check failure";

   return(undef,undef) if ($rec->{'cistatusid'}!=4 && 
                       $rec->{'cistatusid'}!=3);
   if ($rec->{'sslurl'} ne "" &&  # Eckige Klammern verhindern den autoscan
       !($rec->{'sslurl'}=~m/^\[.+\]$/)){
      if ($rec->{ssl_networkid} eq ""){
         my $msg="Invalid SSL Check Network specified";
         push(@qmsg,$msg);
         push(@dataissue,$msg);
      }
      my $url=$rec->{'sslurl'};
      my $networkid=$rec->{ssl_networkid};
      my $now=NowStamp("en");
      my $res=itil::lib::Listedit::probeUrl($dataobj,$url,[],$networkid);
      $forcedupd->{sslcheck}=$now;
      if (ref($res) eq "HASH"){
         if ($res->{exitcode} eq "0"){
            $sslstate="Check OK";
            if (ref($res->{sslcert}) eq "HASH" && 
                $res->{sslcert}->{exitcode} eq "0"){
               if ($res->{sslcert}->{ssl_cert_begin} eq "" ||
                   $res->{sslcert}->{ssl_cert_end} eq ""){
                  printf STDERR ("ERROR: missing SSL start/end data ".
                                 "in $url\n%s\n",Dumper($res));
               }
               else{
                  if (ref($res->{sslcert}->{ssl_cert_type}) eq "ARRAY" &&
                      in_array($res->{sslcert}->{ssl_cert_type},"EVP_PK_RSA")){
                     msg(INFO,"found RSA private key");
                     my $bits=$res->{sslcert}->{ssl_cert_bits};
                     if ($bits<3000){
                        my $msg=$dataobj->T("WARN: ".
                                "RSA private keys with less than 3000 bit ".
                                "are considered insecure");
                        push(@qmsg,$msg);
                     }
                  }
                  $forcedupd->{sslbegin}=$self->getParent->ExpandTimeExpression(
                     $res->{sslcert}->{ssl_cert_begin},'en','GMT');
                  $forcedupd->{sslend}=$self->getParent->ExpandTimeExpression(
                     $res->{sslcert}->{ssl_cert_end},'en','GMT');
                  $sslend=$forcedupd->{sslend};
                  $forcedupd->{ssl_cipher}=
                     $res->{sslcert}->{ssl_cipher};
                  $forcedupd->{ssl_version}=
                     $res->{sslcert}->{ssl_version};
                  $forcedupd->{ssl_cert_serialno}=
                     $res->{sslcert}->{ssl_cert_serialno};
                  $forcedupd->{ssl_cert_issuerdn}=
                     $res->{sslcert}->{ssl_cert_issuerdn};
                  $forcedupd->{ssl_certdump}=
                     $res->{sslcert}->{certtree}->[
                         $#{$res->{sslcert}->{certtree}}]->{name};
                  if ($res->{networkid} ne "" &&
                      $res->{networkid} ne $networkid &&
                      ($rec->{ssl_networkid} eq "" ||
                       $rec->{ssl_networkid} eq "0")){
                     # no networkarea was defined, and we found one, so we set
                     # it fix
                     my $swop=$dataobj->Clone();
                     $swop->SetFilter({id=>\$rec->{id}}); 
                     my ($oldrec,$msg)=$swop->getOnlyFirst(qw(ALL)); 
                     $swop->ValidatedUpdateRecord($oldrec,{
                        ssl_networkid=>$res->{networkid}
                     },{id=>\$rec->{id}});
                  }
               }
            }
         }
         elsif ($res->{exitcode} eq "101"){
            $sslstate="DNS query error";
         }
         elsif ($res->{exitcode} eq "102"){
            $sslstate="invalid DNS name or unkonwn host";
         }
         elsif ($res->{exitcode} eq "201"){
            $sslstate="unable to create ssl connection to host";
         }
         elsif ($res->{exitcode} eq "51"){
            $sslstate="tcp connect error";
         }
         elsif ($res->{exitcode} eq "999"){
            $sslstate="selected network area is not available for ssl checks";
         }
         elsif ($res->{exitcode} eq "9999"){
            $sslstate="unable to find network area for ssl checks";
         }
         elsif ($res->{exitcode} eq "1201"){
            $sslstate="unable to communicate with ssl url";
         }
         elsif ($res->{exitcode} eq "1101"){
            $sslstate="unable to communicate with ssl url".
                      " - ".
                      "possibly a firewall problem";
         }
         elsif ($res->{exitcode} eq "199"){
            $sslstate=$res->{exitmsg};
            $sslstate="generel problem while ProbeIP" if ($sslstate eq "");
         }
         else{
            my $msg="unknown problem (exitcode=$res->{exitcode}) ".
                    "while itil::lib::Listedit::probeUrl";
            msg(ERROR,$msg." while check $url");
            return(undef,{ qmsg=>$msg });
         }
      }
      else{
         return(undef,{
            qmsg=>"ERROR: internal itil::lib::Listedit::probeUrl problem"
         });
      }
      $forcedupd->{sslstate}=$sslstate;
      
      $forcedupd->{mdate}=$rec->{mdate};
      $forcedupd->{editor}=$rec->{editor};
      my $swop=$dataobj->Clone();
      $swop->SetFilter({id=>\$rec->{id}}); 
      my ($oldrec,$msg)=$swop->getOnlyFirst(qw(ALL)); 
      $swop->ValidatedUpdateRecord($oldrec,$forcedupd,{id=>\$rec->{id}});
      $forcedupd={};


      if ($sslstate=~m/OK/){
         if (!defined($oldrec->{sslend}) || $oldrec->{sslend} eq ""){
            my $m="SSL check: invalid or undefined sslend returend";
            return(3,{qmsg=>[$m],dataissue=>[$m]});
         }

         my $ok=$self->itil::lib::Listedit::handleCertExpiration(
                                     $dataobj,$oldrec,undef,undef,
                                     \@qmsg,\@dataissue,\$errorlevel,
                                     {
            expnotifyfld=>'sslexpnotify1',
            expnotifyleaddays=>$rec->{ssl_expnotifyleaddays},
            expdatefld=>'sslend'
         });
         if (!$ok) {
            msg(ERROR,sprintf("QualityCheck of '%s' (%d) failed",
                              $dataobj->Self(),$rec->{id}));
         }
      }
      else{
         push(@qmsg,"SSL check:".$sslstate);
         push(@dataissue,"SSL check:".$sslstate);
         $errorlevel=3 if ($errorlevel<3);
      }










#         if ($#qmsg!=-1) {
#            return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
#         }
   }
   my @result=$self->HandleQRuleResults("None",
                 $dataobj,$rec,$checksession,
                 \@qmsg,\@dataissue,\$errorlevel,$wfrequest,$forcedupd);
   return(@result);


   return(0,undef);
}


1;
