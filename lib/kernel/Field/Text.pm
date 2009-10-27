package kernel::Field::Text;
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
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   $d=$self->FormatedDetailDereferncer($current,$FormatAs,$d);

   if ($FormatAs ne "edit" && defined($self->{expandvar})){
      $d=~s/\%([a-zA-Z][^\%]+?)\%/&{$self->{expandvar}}($self,$1,$current)/ge;
   }

   if (($FormatAs eq "edit" || $FormatAs eq "workflow") && 
       !defined($self->{vjointo})){
      $d=join($self->{vjoinconcat},@$d) if (ref($d) eq "ARRAY");
      my $readonly=0;
      if ($self->readonly($current)){
         $readonly=1;
      }
      if ($self->frontreadonly($current)){
         $readonly=1;
      }
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      return($self->getSimpleInputField($d,$readonly));
   }
   $d=[$d] if (ref($d) ne "ARRAY");
   if ($FormatAs eq "HtmlDetail"){
      $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} @{$d})];
   }
   if ($FormatAs eq "SOAP"){
      $d=[map({quoteSOAP($_)} @{$d})];
   }
   if ($FormatAs eq "HtmlV01"){
      $d=[map({quoteHtml($_)} @{$d})];
   }
   if ($FormatAs ne "XMLV01"){
      my $vjoinconcat=$self->{vjoinconcat};
      $vjoinconcat="; " if (!defined($vjoinconcat));
      $d=join($vjoinconcat,@$d);
   }
   
   if ($FormatAs eq "HtmlV01"){
      $d=~s/\n/<br>\n/g;
      if ($self->{htmlnowrap}){
         $d=~s/[ \t]/&nbsp;/g;
         $d=~s/-/&minus;/g;
      }
   }
   $d.=" ".$self->{unit} if ($d ne "" && $FormatAs eq "HtmlDetail");
   return($d);
}





1;
