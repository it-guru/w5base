package kernel::Field::GoogleMap;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{marker}=1;
   $self->{_permitted}->{address}=1;
   $self->{searchable}=0;
   $self->{uploadable}=0;
   
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   my $C=$self->getParent->Cache();
   my $d=$self->RawValue($current);
   my $lang=$self->getParent->Lang();
   my $address;
   my $marker;
   my $apikey;
   my $site=$ENV{SCRIPT_URI};
   my $idname=$self->getParent->IdField->Name();
   my $id=$current->{$idname};

   $site=~s/([^\/])\/[^\/].*$/$1\//;
   if (!exists($C->{GoogleMapKeys}->{$site})){
      my $gk=getModuleObject($self->getParent->Config,"base::googlekeys");
      $gk->SetFilter({name=>\$site});
      my ($gkrec,$msg)=$gk->getOnlyFirst(qw(apikey));
      if (defined($gkrec)){
         $C->{GoogleMapKeys}->{$site}=$gkrec->{apikey};
      }
   }
   $apikey=$C->{GoogleMapKeys}->{$site};
   foreach my $v (@{$self->{depend}}){
      $address.=" " if ($address ne "");
      $marker.="<br>" if ($marker ne "");
      $address.=$current->{$v};
      $marker.=$current->{$v};
   }
   $address=$self->address($current) if (exists($self->{address}));
   $marker=$self->marker($current) if (exists($self->{marker}));
   if ($mode=~m/^Html.*$/){
      $d.=<<EOF;
<script src="http://maps.google.com/maps?file=api&amp;v=2.x&amp;key=$apikey" 
        type="text/javascript">
</script>
<script language="JavaScript">

var map$id = null;
var geocoder$id = null;

function showAddress$id(address) {
  if (geocoder$id) {
    geocoder$id.getLatLng(
      address,
      function(point) {
        if (!point) {
           map$id.setCenter(new GLatLng(51.0, 10.0), 5);
        } else {
           map$id.setCenter(point, 13);
           var marker = new GMarker(point);
           map$id.addOverlay(marker);
           marker.openInfoWindowHtml("$marker");
           if ("$mode"=="HtmlDetail"){
              map$id.addControl(new GLargeMapControl());
              map$id.addControl(new GMapTypeControl());
           }
        }
      }
    );
  }
}

function load() {
  if (window.GBrowserIsCompatible){
     if (GBrowserIsCompatible()) {
       map$id = new GMap2(document.getElementById("googlemap$id"));
       geocoder$id = new GClientGeocoder();
       window.setTimeout("showAddress$id(\\"$address\\");",200);
       addEvent(window, "unload",GUnload);
     }
  }
  else{
    e = document.getElementById("googlemap$id");
    if (e){
       e.innerHTML="<table width='100%' height='100%'><tr><td align=center valign=center>No access to http://maps.google.com/</td></tr></table>";
    }
  }
}

addEvent(window, "load", load);
</script>
<div id="googlemap$id" style="width: 100%; height: 400px"></div>
EOF
   }
   else{
      $d="-only visible in HTML-";
   }
   return($d);
}








1;
