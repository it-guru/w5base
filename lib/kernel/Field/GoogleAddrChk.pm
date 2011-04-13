package kernel::Field::GoogleAddrChk;
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

@ISA    = qw(kernel::Field);


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
      my $country=$current->{country};
      my $zipcode=$current->{zipcode};
      my $location=$current->{location};
      my $address1=$current->{address1};
      my $addr="";
      $addr.=$country if ($country ne "");
      if ($location ne ""){
         $addr.="; "         if ($addr ne "");
         $addr.=$zipcode." " if ($zipcode ne "");
         $addr.=$location    if ($location ne "");
      }
      if ($address1 ne ""){
         $addr.="; "         if ($addr ne "");
         $addr.=$address1;
      }
      #printf STDERR ("addr=%s\n",$addr);
      # offenes Problem UTF8 !!!!
    #  my $q=kernel::cgi::Hash2QueryString({'address'=>,latin1($addr)->utf8(),
    #                                       'sensor'=>'false'});
      my $q=kernel::cgi::Hash2QueryString({'address'=>,$addr,
                                           'sensor'=>'false'});
      
      sleep(1); 
      my $url="http://maps.google.com/maps/api/geocode/xml?$q";
      msg(INFO,"Google geocode request $url");
      my $response=$ua->request(GET($url,
                       'Content_Type'=>'text/html; charset=utf-8',
                       'Accept-Charset'=>'utf-8',
                       'Accept'=>'text/xml,application/xml,application/xhtml'.
                                 '+xml,text/html;q=0.9,text/plain;q=0.8'));
      if ($response->code ne "200"){
         return("ERROR: Google geocode unavailable");
      }
      if ($response->is_success) {
         my $xmlcontent = $response->content;
         my $gloc=undef;
         my $acomp=undef;
         {
            $parser->setHandlers (
            Start=>sub{
                my ($p, $element, %attrs) = @_;
                $p->{xmlpath}=[] if (!defined($p->{xmlpath}));
                push(@{$p->{xmlpath}},$element);
                $gloc={} if (!defined($gloc));
                if ($element eq "address_component"){
                   $acomp={};
                }
            },
            End=>sub{
                my ($p, $element, %attrs) = @_;
                pop(@{$p->{xmlpath}});
                if ($element eq "address_component"){
               #    printf STDERR ("acomp=%s\n",Dumper($acomp));
                   my %g=%{$acomp};
                   $gloc->{address_component}->{$acomp->{type}}=\%g;
                   $acomp=undef;
                }
            },
            Char=>sub{
                my($p, $data) = @_;
                my $element=$p->{xmlpath}->[$#{$p->{xmlpath}}];

                $data =~ s/{amp}/&/;
                if ($data ne "" && 
                    ($element eq "lng" || $element eq "lat" ||
                     $element eq "formatted_address" || 
                     $element eq "status")){
                   $gloc->{join(".",@{$p->{xmlpath}})}.=UTF8toLatin1($data);
                }
                if (defined($acomp) && $element ne 'address_component'){
                   if ($element eq "type" && $data eq "political"){
                      $data="";
                   }
                   $acomp->{$element}.=UTF8toLatin1($data);
                }
                
               # printf STDERR ("t(%s)=%s\n",join(".",@{$p->{xmlpath}}),$data);
            });

            eval('$parser->parsestring($xmlcontent);');
           # print STDERR Dumper($gloc);
           # printf STDERR ("d=%s\n",UTF8toLatin1($xmlcontent));
            if (defined($gloc)){
               if ($gloc->{'GeocodeResponse.status'} eq "OK"){
                  my @msg;
                  my $gstreet=$gloc->{address_component}->{route}->{long_name}.
                   " ".$gloc->{address_component}->{street_number}->{long_name};
                  if ($gstreet ne substr($address1,0,length($gstreet))){
                     push(@msg,"Correct Street to: $gstreet");
                  }
                  my $gloca=$gloc->{address_component}->{sublocality}->{long_name};
                  if (trim($gloca) ne trim($location)){
                     push(@msg,"Correct Location to: $gloca");
                  }
 


                  if ($#msg==-1){
                     return("OK: ".UTF8toLatin1(
                         $gloc->{'GeocodeResponse.result.formatted_address'}));
                  }
                  return(join("\n",@msg));
               }
               else{
                  return($gloc->{'GeocodeResponse.status'});
                  return("invalid location address");
               }
            }
            else{
               return("ERROR: invalid Google geocode response");
            }
         }


         return($xmlcontent);
      }





      return("fifi c=$country z=$zipcode l=$location a=$address1");
   }
   return(undef);
}



#sub FormatedDetail
#{
#   my $self=shift;
#   my $current=shift;
#   my $mode=shift;
#   my $name=$self->Name();
#   my $C=$self->getParent->Cache();
#   my $d=$self->RawValue($current);
#   my $lang=$self->getParent->Lang();
#   my $address;
#   my $apikey;
#   my $site=$ENV{SCRIPT_URI};
#   my $idname=$self->getParent->IdField->Name();
#   my $id=$current->{$idname};

#   $site=~s/([^\/])\/[^\/].*$/$1\//;
#   if (!exists($C->{GoogleMapKeys}->{$site})){
#      my $gk=getModuleObject($self->getParent->Config,"base::googlekeys");
#      $gk->SetFilter({name=>\$site});
#      my ($gkrec,$msg)=$gk->getOnlyFirst(qw(apikey));
#      if (defined($gkrec)){
#         $C->{GoogleMapKeys}->{$site}=$gkrec->{apikey};
#      }
#   }
#   $apikey=$C->{GoogleMapKeys}->{$site};
#   foreach my $v (@{$self->{depend}}){
#      $address.=" " if ($address ne "");
#      $address.=$current->{$v};
#   }
#printf STDERR ("fifi k=%s\n",$apikey);
#   $address=$self->address($current) if (exists($self->{address}));
#   if ($mode=~m/^Html.*$/){
#      $d.=<<EOF;
#<script src="http://maps.google.com/maps?file=api&amp;v=2.x&amp;key=$apikey" 
#        type="text/javascript">
#</script>
#<script language="JavaScript">
#
#var map$id = null;
#var geocoder$id = null;
#
#function showAddress$id(address) {
#  if (geocoder$id) {
#    geocoder$id.getLatLng(
#      address,
#      function(point) {
#        res = document.getElementById("googlechk$id");
#        if (!point) {
#           res.innerHTML="fail";
#        } else {
#           res.innerHTML="ok";
#        }
#      }
#    );
#  }
#}
#
#function load() {
#  if (window.GBrowserIsCompatible){
#     if (GBrowserIsCompatible()) {
#       map$id = new GMap2(document.getElementById("googleaddrchk$id"));
#       geocoder$id = new GClientGeocoder();
#       window.setTimeout("showAddress$id(\\"$address\\");",100);
#       addEvent(window, "unload",GUnload);
#     }
#  }
#  else{
#    e = document.getElementById("googlechk$id");
#    if (e){
#       e.innerHTML="no access to http://maps.google.com";
#    }
#  }
#}
#
#addEvent(window, "load", load);
#</script>
#<div id="googleaddrchk$id" style="display:none;visibility:hidden;width:50px;height:50px"></div><div id="googlechk$id">searching ...</div>
#EOF
#   }
#   else{
#      $d="-only visible in HTML-";
#   }
#   return($d);
#}








1;
