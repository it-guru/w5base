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

   my $marker="";
   if ($current->{label} ne ""){
      $marker.="<b>".$current->{label}."</b>"."\n";
   }
   if ($current->{address1} ne ""){
      $marker.=$current->{address1}."\n";
   }
   if ($current->{zipcode} ne ""){
      if ($current->{country} ne ""){
         $marker.=uc($current->{country})."-";
      }
      $marker.=$current->{zipcode}." ";
   }
   if ($current->{location} ne ""){
      $marker.=$current->{location}."\n";
   }
#   $marker.="<hr>";
#   $marker.="<center>&nbsp; &bull; GoogleMap ";
#   $marker.="&bull; GC ";
#   $marker.="&bull; OpenStreetMap &bull; &nbsp; &nbsp;</center>";

   my $country=latin1($current->{country})->utf8();
   my $zipcode=latin1($current->{zipcode})->utf8();
   my $location=latin1($current->{location})->utf8();
   my $address1=latin1($current->{address1})->utf8();
   my $searchaddr="$address1,$location,$zipcode,$country";

   my $OPERATOREMAIL=$self->getParent->Config->Param("OPERATOREMAIL");
   my $q=kernel::cgi::Hash2QueryString({'q'=>,$searchaddr,
                                        'polygon'=>0,
                                        'email'=>$OPERATOREMAIL,
                                        'addressdetails'=>1,
                                        'format'=>'xml'});

   my $mapsize=400;

   if ($mode ne "HtmlDetail"){
      $mapsize=200;
      $mapsize=1;
   }
   if ($mode eq "edit"){
      return("<div id=\"OSMapLayer$id\" ".
             "style=\"width: 100%; height: ${mapsize}px\">".
             "edit not supported ...</div>");
   }

   $q="$current->{country} $current->{zipcode} ".
       "$current->{location} ; $current->{address1}";
   my $queryobj=new kernel::cgi({q=>latin1($q)->utf8()});
   $q=$queryobj->QueryString();
   my $gmaplink="<a href='http://maps.google.de?$q' target=_blank>";
   my $binglink="<a href='http://www.bing.com/maps/?$q' target=_blank>";
   my $forwardmsg=$self->getParent->T("forward address search",$self->Self);


   $marker=~s/\n/<br>/g;
   if ($mode=~m/^Html.*$/){
      $d.=<<EOF;
<script language=JavaScript xsrc="../../../public/base/load/firebug-lite.js"></script>
<!--
<script xsrc="http://www.openlayers.org/api/OpenLayers.js" type="text/javascript"></script>
<script xsrc="http://www.openstreetmap.org/openlayers/OpenStreetMap.js" type="text/javascript">
-->

</script>
<script language="JavaScript">

var OSMmarkers;
var OSMMessage;
var OSMMap$id;


// perform a synchron API request
//function requestApi(file, query, handler)
//{
//   if (typeof handler == 'undefined')
//      return OpenLayers.Request.GET({url: root+'api/'+file+'.php?'+query, async: false});
//   else
//      return OpenLayers.Request.GET({url: uery, async: false, success: handler});
//}




function OSMapSearch$id(){
  OSMMessage.contentDiv.innerHTML="Searching for $current->{name}";

  var lon="11";
  var lat="50";
  var wgspos=new OpenLayers.LonLat(lon,lat);

  var q="$q";

  var requrl="http://nominatim.openstreetmap.org/search?"+q;

  //console.log("url",requrl);
  var res=OpenLayers.Request.GET({ url:requrl, async:false });
  //console.log(res);
  //console.log(res.responseText);

  if (res.responseXML &&
      res.responseXML.firstChild.tagName=="searchresults"){
     //console.log("OK, found searchresult");

    for(pno=0;pno<res.responseXML.firstChild.childNodes.length;pno++){
       var p=res.responseXML.firstChild.childNodes[pno];
       if (p.attributes){
          lon=p.attributes['lon'].textContent;
          lat=p.attributes['lat'].textContent;
          OSMMessage.hide();
          var wgspos=new OpenLayers.LonLat(lon,lat);
          return(addPositionMarker(wgspos,"$marker"));
       }
    }
  }

  var sphpos=wgspos.clone().transform(
       new OpenLayers.Projection("EPSG:4326"),    // WGS84
       new OpenLayers.Projection("EPSG:900913")); // Sph. Mercator
  OSMMap$id.setCenter(sphpos,8);
  OSMMessage.contentDiv.innerHTML="$current->{name} NOT FOUND";
  OSMMessage.show();
}






function OSMapInit$id() {
  var lon="$current->{gpslongitude}";
  var lat="$current->{gpslatitude}";
  var zoom=16;

  if (lon=="" || lat==""){
     lon=0.1;
     lat=0.1;
     zoom=1
  }
 
  //  Center Position berechnen
  var wgspos=new OpenLayers.LonLat(lon,lat);

  var mode="$mode";

  if (mode=="HtmlDetail"){

     OSMMap$id = new OpenLayers.Map("OSMapLayer$id",{
            controls:[
               new OpenLayers.Control.Navigation({
                  'zoomWheelEnabled':false
               }),
               new OpenLayers.Control.PanZoomBar(),
               new OpenLayers.Control.LayerSwitcher(),
               new OpenLayers.Control.Attribution()
               ],
            units: 'm'
     });

     // Karte erzeugen
     var mapnik = new OpenLayers.Layer.OSM();
     OSMMap$id.addLayer(mapnik);
    
     var alt1 = new OpenLayers.Layer.OSM.Osmarender("Osmrender");
     OSMMap$id.addLayer(alt1);
  }
  else{
     OSMMap$id = new OpenLayers.Map("OSMapLayer$id",{
         controls:[]
     });
     var mapnik = new OpenLayers.Layer.OSM();
     OSMMap$id.addLayer(mapnik);
  }



  // Marker Layer hinzufügen
  OSMmarkers = new OpenLayers.Layer.Markers( "current Adress" );
  OSMMap$id.addLayer(OSMmarkers);


   var sphpos=wgspos.clone().transform(
               new OpenLayers.Projection("EPSG:4326"),    // WGS84
               new OpenLayers.Projection("EPSG:900913")); // Sph. Mercator

  // Karte Center Position setzen
  OSMMap$id.setCenter(sphpos,zoom);
  if (mode!="HtmlDetail"){
     return;
  }

  if (zoom>2){
     addPositionMarker(wgspos,"$marker");
  }
  OSMMessage=new OpenLayers.Popup("OSMMessage", 
                                  new OpenLayers.LonLat(10,10),
                                  new OpenLayers.Size(280,30),
                                  "Loading ...",
                                  false);
//  OSMMessage.setBorder("2px");
//  OSMMessage.padding=new OpenLayers.Bounds(10,10,10,10);;


  OSMMap$id.addPopup(OSMMessage);
  if (zoom>2){
     OSMMessage.hide();
  }
  else{
     OSMMessage.show();
     //window.setTimeout(OSMapSearch$id,1000);
     window.setTimeout(OSMapSearch$id,10);
  }
}

function addPositionMarker(wgspos,markerText){

   markerText+="<hr>";
   markerText+="<center>&nbsp;&nbsp;&bull;";

   // add GoogleMaps Link
   markerText+=" <a href='http://maps.google.de/?"+
               "ll="+wgspos.lat+","+wgspos.lon+
               "&q="+wgspos.lat+","+wgspos.lon+
               "' target=_blank>"+
               "GoogleMaps</a> &bull;";

   // add GeoCaching Link
   markerText+=" <a href='http://www.geocaching.com/seek/nearest.aspx?"+
               "origin_lat="+wgspos.lat+
               "&origin_long="+wgspos.lon+
               "&dist=10"+
               "' target=_blank>"+
               "GC</a> &bull;";

   // add Bing Link
   markerText+=" <a href='http://www.bing.com/maps/?"+
               "q="+wgspos.lat+","+wgspos.lon+
               "' target=_blank>"+
               "Bing</a> &bull;";

   // add OSM Link
   markerText+=" <a href='http://osm.org?"+
               "lat="+wgspos.lat+
               "&lon="+wgspos.lon+
               "&zoom=16"+
               "' target=_blank>"+
               "OSM</a> &bull;";

   markerText+="&nbsp;&nbsp;</center>";

   var sphpos=wgspos.clone().transform(
               new OpenLayers.Projection("EPSG:4326"),    // WGS84
               new OpenLayers.Projection("EPSG:900913")); // Sph. Mercator


   // OSMmarkers.addMarker(new OpenLayers.Marker(sphpos));  // to simple
   feature=new OpenLayers.Feature(OSMmarkers, sphpos);
   feature.closeBox = false;
   feature.popupClass =  OpenLayers.Class(OpenLayers.Popup.FramedCloud, {
          'autoSize': true,
          'minSize': new OpenLayers.Size(200,100),
          'maxSize': new OpenLayers.Size(300,200)
        });
   feature.data.popupContentHTML = markerText;
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
   OSMmarkers.addMarker(marker);

   feature.popup = feature.createPopup(feature.closeBox);
   feature.padding = new OpenLayers.Bounds(10,10,10,10);
   OSMMap$id.addPopup(feature.popup);
   feature.popup.show();
   OSMMap$id.setCenter(sphpos,16);
}

//addEvent(window, "load", OSMapInit$id);

(function() {

   var osl=document.createElement('script'); 
   osl.type='text/javascript'; 
   osl.async=true;
   osl.src='http://www.openlayers.org/api/OpenLayers.js';
   (document.getElementsByTagName('head')[0] || 
    document.getElementsByTagName('body')[0]).appendChild(osl);

   var osm=document.createElement('script'); 
   osm.type='text/javascript'; 
   osm.async=true;
   osm.src='http://www.openstreetmap.org/openlayers/OpenStreetMap.js';
   (document.getElementsByTagName('head')[0] || 
    document.getElementsByTagName('body')[0]).appendChild(osm);


    })();


</script>
<!--
<div id="OSMapLayer$id" style="width: 100%; height: ${mapsize}px;border-style:solid;border-color:gray;border-width:1px;margin-bottom:0px;border-bottom-style:none"></div>
<div id="OSMapSig$id" style="width: 100%; height: auto;border-style:solid;border-color:gray;border-width:1px;margin-bottom:2px;">&nbsp;
-->
<b>$forwardmsg:</b>
-&gt; ${gmaplink}GoogleMaps</a> &nbsp;&nbsp;
-&gt; ${binglink}Microsoft Bing</a> &nbsp;&nbsp;
</div>
EOF
   }
   else{
      $d="-only visible in HTML-";
   }
   return($d);
}








1;
