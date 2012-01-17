package kernel::Field::OSMap;
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
   foreach my $v (@{$self->{depend}}){
      $marker.="<br>" if ($marker ne "");
      $marker.=$current->{$v};
   }
   if ($mode=~m/^Html.*$/){
      $d.=<<EOF;
<script src="http://www.openlayers.org/api/OpenLayers.js" type="text/javascript">
</script>
<script language="JavaScript">

function OSMapInit$id() {


  var lon="$current->{gpslongitude}";
  var lat="$current->{gpslatitude}";


 
  //  Center Position berechnen
  var wgspos=new OpenLayers.LonLat(lon,lat);
  var sphpos=wgspos.transform(
               new OpenLayers.Projection("EPSG:4326"),    // WGS84
               new OpenLayers.Projection("EPSG:900913")); // Sph. Mercator

  // Karte erzeugen
  map = new OpenLayers.Map("OSMapLayer$id");
  var mapnik = new OpenLayers.Layer.OSM();
  map.addLayer(mapnik);

  // Karte Center Position setzen
  map.setCenter(sphpos,17);

  // Marker hinzufügen
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  // markers.addMarker(new OpenLayers.Marker(sphpos));  // to simple


  feature=new OpenLayers.Feature(markers, sphpos);
  feature.closeBox = false;
  feature.popupClass =  OpenLayers.Class(OpenLayers.Popup.FramedCloud, {
         'autoSize': true,
         'maxSize': new OpenLayers.Size(300,200)
       });
  feature.data.popupContentHTML = "$marker";
  feature.data.overflow = "auto";
       
  marker = feature.createMarker();

  markerClick = function (evt) {
       if (this.popup == null) {
         this.popup = this.createPopup(this.closeBox);
         map.addPopup(this.popup);
         this.popup.show();
       } else {
         this.popup.toggle();
       }
       currentPopup = this.popup;
       OpenLayers.Event.stop(evt);
    };
  marker.events.register("mousedown", feature, markerClick);
  markers.addMarker(marker);

  map.setCenter(new OpenLayers.LonLat(lon, lat).transform(projLonLat,projMercator), zoom);

  feature.popup = feature.createPopup(feature.closeBox);
  feature.popup.show();
  map.addPopup(feature.popup);

}



addEvent(window, "load", OSMapInit$id);
</script>
<div id="OSMapLayer$id" style="width: 100%; height: 400px"></div>
EOF
   }
   else{
      $d="-only visible in HTML-";
   }
   return($d);
}








1;
