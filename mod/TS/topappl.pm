package TS::topappl;
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
use kernel::Field;
use itil::appl;
@ISA=qw(itil::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->setDefaultView(qw(name criticality));
   return($self);
}


sub isWriteValid
{
   my $self=shift;
   return(undef);
}

sub arrangeSearchData
{
   my $self=shift;
   my $searchframe=shift;
   my $extframe=shift;
   my $defaultsearch=shift;
   my %param=@_;
   my $d;
   my @customer=(
                 {
                  name=>'tcom',
                  label=>'T-Com/T-Home',
                  customer=>'DTAG.T-Home DTAG.T-Home.*'
                 },
                 {
                  name=>'activebilling',
                  label=>'ActiveBilling',
                  customer=>'DTAG.ACTIVEBILLING DTAG.ACTIVEBILLING.*'
                 },
                 {
                  name=>'rci',
                  label=>'RCI',
                  customer=>'DTAG.GHS.RCI DTAG.GHS.RCI.*'
                 },
                 {
                  name=>'tpg',
                  label=>'T-Punkte Gesellschaft',
                  customer=>'DTAG.TPG DTAG.TPG.*'
                 },
                 {
                  name=>'tsi',
                  label=>'T-Systems',
                  customer=>'DTAG.TSI DTAG.TSI.*'
                 },
                );
 
   $d.="<input type=hidden name=search_customer value=\"NONE\">";
   $d.="<input type=hidden name=search_cistatusid value=\"4\">";
   $d.="<input type=hidden name=search_customerprio value=\"1\">";
   $d.="<table width=100%><tr><td align=center>";
   foreach my $rec (@customer){
      $d.="<input style=\"margin-right:2px;margin-left:2px;width:120px\" ".
          "type=button ".
          "onclick=topSearch(\"$rec->{name}\") value=\"$rec->{label}\">";
   }
   $d.="<td></tr></table>";
   $d.=<<EOF;
<script language="JavaScript">
function topSearch(l)
{
   var customer=document.forms[0].elements['search_customer'];
   document.forms[0].elements['UseLimit'].value='1000';
EOF
   foreach my $rec (@customer){
      $d.="if (l==\"$rec->{name}\"){customer.value=\"$rec->{customer}\";}\n";
   }


   $d.=<<EOF;
   nativeDoSearch();
}
</script>
EOF
   return($d);
}






1;
