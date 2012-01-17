package kernel::Field::OSMAdrChk;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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

@ISA    = qw(kernel::Field::Textarea);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{address}=1;
   $self->{searchable}=0;
   
   return($self);
}

sub RawValue
{
   my $self=shift;
   my $current=shift;

   return("only for admins!") if (!$self->getParent->IsMemberOf("admin"));

   my $ua;
   my $html;
   my $parser;
   eval('
use XML::Parser;
use HTTP::Request::Common;
use LWP::UserAgent;
use HTTP::Status;

$ua=new LWP::UserAgent(env_proxy=>0);
$ua->timeout(20);
$ua->agent("Mozilla/5.0 (X11; U; Linux i686; de-AT; rv:1.8.1.4) Gecko/20070509 SeaMonkey/1.1.2");
$parser=new XML::Parser(Style=>"Stream");
');
   if ($@ ne ""){
      return($@);
   }
   if (defined($ua)){
      my $proxy=$self->getParent->Config->Param("http_proxy");
      if ($proxy ne ""){
        # msg(INFO,"set proxy to $proxy");
         $ua->proxy(['http', 'ftp'],$proxy);
      }
   }


   if (defined($current)){
      my $country=latin1($current->{country})->utf8();
      my $zipcode=latin1($current->{zipcode})->utf8();
      my $location=latin1($current->{location})->utf8();
      my $address1=latin1($current->{address1})->utf8();
      my $addr="$address1,$location,$zipcode,$country";
      #printf STDERR ("addr=%s\n",$addr);
      # offenes Problem UTF8 !!!!
    #  my $q=kernel::cgi::Hash2QueryString({'address'=>,latin1($addr)->utf8(),
    #                                       'sensor'=>'false'});
      my $OPERATOREMAIL=$self->getParent->Config->Param("OPERATOREMAIL");
      my $q=kernel::cgi::Hash2QueryString({'q'=>,$addr,
                                           'polygon'=>0,
                                           'email'=>$OPERATOREMAIL,
                                           'addressdetails'=>1,
                                           'format'=>'xml'});
      
      sleep(1); 
      my $url="http://nominatim.openstreetmap.org/search?$q";
      #msg(INFO,"OSM Nominazion geocode request $url");
      my $response=$ua->request(GET($url,
                       'Content_Type'=>'text/html; charset=utf-8',
                       'Accept-Charset'=>'utf-8',
                       'Accept'=>'text/xml,application/xml,application/xhtml'.
                                 '+xml,text/html;q=0.9,text/plain;q=0.8'));
      if ($response->code ne "200"){
         return("ERROR: OSM Nomination service unavailable");
      }
      if ($response->is_success) {
         my $xmlcontent = $response->content;
         my $osmloc=undef;
         my %place=();
         my $housefound=0;
         #return($xmlcontent);
         {
            $parser->setHandlers (
            Start=>sub{
                my ($p, $element, %attrs) = @_;
                if ($element eq "place"){
                   $osmloc={
                              type=>$attrs{type},
                              lat=>$attrs{lat},
                              lon=>$attrs{lon},
                           };
                   $housefound=1 if ($attrs{type} eq "house");
                }
            },
            End=>sub{
                my ($p, $element, %attrs) = @_;
                pop(@{$p->{xmlpath}});
                if ($element eq "place"){
                   if (defined($osmloc)){
                      my $key=$osmloc->{road}." ".$osmloc->{house_number}."\n".
                           uc($osmloc->{country_code})."-".$osmloc->{postcode}.
                           " ".$osmloc->{county};
                      $osmloc->{address}=$key;
                      $place{$key}=$osmloc;
                      $osmloc=undef;
                   }
                }
            },
            Char=>sub{
                my($p, $data) = @_;
                my @context=$p->context();
                my $n=$context[$#context];
                $osmloc->{$n}.=$data;
            });

            eval('$parser->parsestring($xmlcontent);');
            if (keys(%place)==0){
               return("ERROR: location not found");
            }
            my @kl=sort(keys(%place));
            if ($housefound){
               foreach my $k (@kl){
                  if ($place{$k}->{type} eq "house"){
                     @kl=($k);last;
                  }
               }
            }


            my $d;
            foreach my $p (@kl){
               $d.="\n\n" if ($d ne "");
               $d.=UTF8toLatin1($place{$p}->{address});
            }
            $d.="\n\nWARN: not unique result!" if ($#kl>0);


            if ($#kl==0){
               if ( $place{$kl[0]}->{lon} ne "" &&
                    $place{$kl[0]}->{lat} ne ""){
                  if ($current->{gpslongitude} eq "" 
                      && $current->{gpslatitude} eq ""){
                     my $loc=$self->getParent->Clone();
                     if (defined($loc) &&
                         defined($loc->getField("gpslongitude")) && 
                         defined($loc->getField("gpslatitude")) &&
                         ($place{$kl[0]}->{lon}=~m/^-{0,1}\d+\.\d+$/) &&
                         ($place{$kl[0]}->{lat}=~m/^-{0,1}\d+\.\d+$/)){
                        $loc->UpdateRecord({gpslongitude=>$place{$kl[0]}->{lon},
                                            gpslatitude=>$place{$kl[0]}->{lat}},
                                                    {id=>\$current->{id}});
                 
                     }
                  }
                  if ($current->{gpslongitude} ne ""
                      && $current->{gpslatitude} ne ""){
                     if ($current->{gpslongitude}!=$place{$kl[0]}->{lon} ||
                         $current->{gpslatitude}!=$place{$kl[0]}->{lat}){
                        $d.="\n\nWARN: coordinates seems to be wrong!";
                     }
                  }
               }
            }
            return($d);
         }


         return($xmlcontent);
      }
   }
   return(undef);
}



sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   my $d=$self->RawValue($current);

   return($self->SUPER::FormatedDetail($current,$mode,$name));
}








1;
