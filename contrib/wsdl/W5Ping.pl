#!/usr/bin/env perl
use strict;
use lib 'lib/';
use lib '../lib';
use Data::Dumper;
#use SOAP::Lite +trace=>'all';
use File::Basename qw(dirname);
use File::Spec;
my $path = File::Spec->rel2abs( dirname __FILE__);

# SOAP::WSDL variant
use SOAP::WSDL;
my $soap = SOAP::WSDL->new(no_dispatch=>0);
my $som = $soap->wsdl("file:///$path/W5Ping.wsdl");

#$som->outputxml(1);

my $body=$som->call('Ping', Ping =>
    { lang => 'de' }
);
print Dumper($body->result());


sub SOAP::Transport::HTTP::Client::get_basic_credentials {
    return ("dummy/admin", "acache");
 };


#die "Error" if $som->fault();
#print $som->result();

# SOAP::Lite variant:
# Note that you have to look both the proxy and the xmlns attribute 
# set on the GetWeather SOAP::Data object from the WSDL.

#use SOAP::Lite +trace;
#$soap = SOAP::Lite->new()->on_action( sub { join'/', @_ } )
#  ->proxy("http://www.webservicex.net/globalweather.asmx");     # from WSDL
#$som = $soap->call(
#    SOAP::Data->name('GetWeather')
#        ->attr({ xmlns => 'http://www.webserviceX.NET' }),      # from WSDL
#    SOAP::Data->name('CountryName')->value('Germany'),
#    SOAP::Data->name('CityName')->value('Munich')
#);
#die "Error" if $som->fault();
#print $som->result();
