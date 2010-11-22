package base::Session;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use kernel::TemplateParsing;
use Net::OpenID::Consumer;
use LWP::UserAgent;
use CGI;
use CGI::Carp 'fatalsToBrowser';


@ISA=qw(kernel::App::Web kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Login Logout OpenIDResponse));
}

sub getCSR
{
   my $self=shift;
   my %csrinit=@_;

   my $ua=LWP::UserAgent->new();
   if (defined($ua)){
      my $proxy=$self->Config->Param("http_proxy");
      if ($proxy ne ""){
         $ua->proxy(['http', 'ftp'],$proxy);  # this combination is needed
         $ENV{HTTPS_PROXY}=$proxy;            # if https query over proxy
      }                                       # should be done
   }
   my %csrparam=%csrinit;
   $csrparam{ua}=$ua;
   $csrparam{required_root}="http://w8n00378.bmbg01.telekom.de/";
   $csrparam{consumer_secret}="sd4f6as5d";
   
   my $csr=Net::OpenID::Consumer->new(%csrparam);
   return($csr);
}


sub Login
{
   my $self=shift;

   if (Query->Param("LoginType") eq "openid"){

      my $openid=Query->Param("openid");

      my $csr=$self->getCSR();
      my $claimed_id=$csr->claimed_identity($openid);
#      printf("fifi: claimed_id='%s'<br><hr>",$claimed_id);
      if ($claimed_id) {
         my $check_url=$claimed_id->check_url(
           return_to=>'http://w8n00378.bmbg01.telekom.de/w5base2/public/base/Session/OpenIDResponse',
           trust_root=>'http://w8n00378.bmbg01.telekom.de/'
         );
printf STDERR ("URL=%s\n",$check_url);
         print("Location: ".$check_url."\n\n");
         print $self->HttpHeader("text/html"); 
         print("<h1>Connecting to OpenID Provider...</h1>");
         return();
      }
      else{
         $self->LoginFail("claimed_identity for '$openid' failed", 
                          $csr->errcode());
      }
   
      

   }

   print $self->HttpHeader("text/html"); 
   print $self->getParsedTemplate("tmpl/base.session.login",{});

}


sub OpenIDResponse
{
   my $self=shift;


   my %args=Query->MultiVars();
   print $self->HttpHeader("text/html"); 
   print "<hr>";
   delete($args{MOD});
   delete($args{FUNC});
   print STDERR "Query=".Dumper(\%args);
#   $args{user_setup_url}='http://www.google.de';
   print "<hr>";
   my $csr=$self->getCSR(args=>\%args);

   $csr->handle_server_response(
       not_openid => sub {
           die "Not an OpenID message";
       },
       setup_required => sub {
           my $setup_url = shift;
           # Redirect the user to $setup_url
           printf STDERR ("fifi setup_required to $setup_url\n");
       },
       cancelled => sub {
           # Do something appropriate when the user hits "cancel" at the OP
           printf STDERR ("fifi cancelled\n");
       },
       verified => sub {
           my $vident = shift;
           # Do something with the VerifiedIdentity object $vident
           printf ("fifi verified to <xmp>%s</xmp>\n",$vident->{identity});
       },
       error => sub {
           my $err = shift;
           print("<xmp>ERROR:$err</xmp>");
       },
   );






}

sub LoginFail
{
   my $self=shift;

   my ($message, $errcode) = @_;
   print $self->HttpHeader("text/html"); 
   print "<h1>There was a problem</h1>\n";
   print "<p><b>$message</b></p>\n";
   if ($errcode) {
        print "<p>The error code was <code>$errcode</code></p>\n";
        if ($errcode == "no_identity_server") {
            # This has happened many times!
            print <<EOF;
<p>An OpenID is a URL which identifies you uniquely. I could not find
an identity web server . Is it a valid URL? Is the URL
your unique identity?</p>
EOF
        }
    }
   print("<hr>");
}






1;
