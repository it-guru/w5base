package outdoor::GCopti;
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
use kernel::App::Web;
use kernel::TemplateParsing;
@ISA=qw(kernel::App::Web kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Main
{
   my $self=shift;

   my $C=$self->Cache();
   my $apikey;
   my $site=$ENV{SCRIPT_URI};

   $site=~s/([^\/])\/[^\/].*$/$1\//;
   if (!exists($C->{GoogleMapKeys}->{$site})){
      my $gk=getModuleObject($self->Config,"base::googlekeys");
      $gk->SetFilter({name=>\$site});
      my ($gkrec,$msg)=$gk->getOnlyFirst(qw(apikey));
      if (defined($gkrec)){
         $C->{GoogleMapKeys}->{$site}=$gkrec->{apikey};
      }
   }
   $apikey=$C->{GoogleMapKeys}->{$site};

   my @jsl=();
   push(@jsl,"http://maps.google.com/maps?file=api&amp;v=2.x&amp;key=$apikey",
             'toolbox.js','tsp.js');
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           title=>"GeoCaching optimizer",
                           js=>\@jsl);
   print(<<EOF);
<style>
/* Center block equations */
div.eq {
    text-align: center;
} 

/* Align inline equations with parents content area */
span.eq img {
    vertical-align: text-bottom;
} 

body {
    font-size: 62.5%; /* Resets 1em to 10px */
    text-align: center;
    background: #e7e7e7;
    border: none;
    color: #333;
    font-family: 'Lucida Grande', Verdana, Arial, Sans-Serif;
}

h1, h2, h3 {
    font-family: 'Trebuchet MS', 'Lucida Grande', Verdana, Arial, Sans-Serif;
    font-weight: bold;
    text-align: center;
}

p {
    text-align: center;
}

h1 {
    font-size: 2.0em;
    color: #0000a0;
}

h2 {
    font-size: 1.6em;
    color: #0000a0;
}

h3 {
    font-size: 1.3em;
}

p a:visited {
    color: #0000a0;
}

a {
    color: #0000ff;
    text-decoration: none;
}

a:hover {
    color: #0000ff;
    text-decoration: underline;
}

h1 {
    padding-top: 70px;
    margin: 0;
}

h2 {
    margin: 5px 0 15px 0;
}

table.round {
    margin-left: auto;
    margin-right: auto;    
    border: thin none black;
    border-collapse: collapse;
    border-spacing: 0;
}

div.my_textual_div {
    width: 700px;
    margin-left: auto;
    margin-right: auto;
}

div.myMap {
    width: 600px;
    height: 380px;
    margin-left: auto;
    margin-right: auto;
}

div.myButton {
    width: 200px;
    height: 40px;
    margin-left: auto;
    margin-right: auto;
    text-align: center;
}

div.pathData {
    margin-left: auto;
    margin-right: auto;
    text-align: center;
}

table.gebddir {
    text-align: left;
    width: 600px;
    margin-left: auto;
    margin-right: auto;    
    border: thin none black;
    border-collapse: collapse;
    border-spacing: 0;
}

table.gebddir td {
    padding: 0;
}

table.gebddir tr.heading {
    height: 40px;
}

table.gebddir tr.text {
    height: 30px;
}

table.gebddir td.heading {
    background: #a7a7a7;
    margin-left: 10px;
}

table.gebddir td.even {
    background: #fff;
}

table.gebddir td.odd {
    background: #e7e7e7;
}

div.centered-directions {
    text-align: center;
    margin-left: auto;
    margin-right: auto;
    background: #a7a7a7;
}

div.left-shift {
    margin-right: 40px;
    margin-top: auto;
    text-align: right;
}

div.right-shift {
    margin-left: 40px;
}

span.red {
    color: #ca0000;
}
</style>
<body onload='loadAtStart(37.4419,-122.1419,true)' onunload='GUnload()'>
<table class="round">
  <tr class="roundborder">

    <td class="ul"></td>
    <td class="u"></td>
    <td class="ur"></td>
  </tr>
  <tr>
    <td class="l"></td>
    <td class="m">
      <h2>Google Maps Fastest Roundtrip Solver</h2>

    <div id="map" class="myMap"></div><br><br>
    <div align="center"><form name="listOfLocations" onSubmit="clickedAddList(); return false;">
      <textarea name="inputList" rows="5" cols="40" style="width:100%" value=""></textarea><br>
      <input type="button" value="Add list of locations" onClick="clickedAddList()">
    </form></div>
    <div id="clickme" class="myButton"><input id="button1" type="button" value="Calculate Fastest Roundtrip" onClick="directions()"></div>
</td>
    <td class="r"></td>
  </tr>

  <tr class="roundborder">
    <td class="ll"></td>
    <td class="lower"></td>
    <td class="lr"></td>
  </tr>
</table>
<p>&nbsp;</p>
<table class="round">
  <tr class="roundborder">
    <td class="ul"></td>

    <td class="u"></td>
    <td class="ur"></td>
  </tr>
  <tr>
    <td class="l"></td>
    <td class="m"><center>
      <h2>Computed Data:</h2>
    <!--<div id="message"></div>-->

    <div id="path" class="pathdata"></div>
    <p>Order of visits:</p>
    <div id="exportData" class="pathdata"></div>
    <div id="my_textual_div"></div>
    </center>
    </td>
    <td class="r"></td>
  </tr>

  <tr class="roundborder">
    <td class="ll"></td>
    <td class="lower"></td>
    <td class="lr"></td>
  </tr>
</table>
<p>&nbsp;</p>
<table class="round">
  <tr class="roundborder">
    <td class="ul"></td>

    <td class="u"></td>
    <td class="ur"></td>
  </tr>
  <tr>
    <td class="l"></td>
    <td class="m">
      <h2>Instructions</h2>
      <p>Locations are added to the textarea under the map in the following
      format:<br>

      latitude, longitude<br>
      latitude, longitude<br>
      It's important that each latitude, longitude pair appears on a line of its own.</p>
    </td>
    <td class="r"></td>
  </tr>
  <tr class="roundborder">

    <td class="ll"></td>
    <td class="lower"></td>
    <td class="lr"></td>
  </tr>
</table>
<p>&nbsp;</p>
<table class="round">
  <tr class="roundborder">
    <td class="ul"></td>
    <td class="u"></td>

    <td class="ur"></td>
  </tr>
  <tr>
    <td class="l"></td>
    <td class="m">
      <h2>Thanks</h2>
      <p><a href="http://www.google.com">Google</a> - for providing an awesome map <a href="http://www.google.com/apis/maps/documentation/">API</a><br>

      <a href="http://brennan.offwhite.net/blog/2005/07/23/new-google-maps-icons-free/">Brennan</a> - for providing a set of free map icons</p>
    </td>
    <td class="r"></td>
  </tr>
  <tr class="roundborder">
    <td class="ll"></td>
    <td class="lower"></td>

    <td class="lr"></td>
  </tr>
</table>

EOF
   print $self->HtmlBottom();
   return(0);
}



1;
