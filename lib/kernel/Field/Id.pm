package kernel::Field::Id;
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
   my %self=@_;
   $self{selectfix}=1                   if (!defined($self{selectfix}));
   $self{autogen}=1                     if (!defined($self{autogen}));
   $self{readonly}=1                    if (!defined($self{readonly}));
   $self{htmlwidth}="1%"                if (!exists($self{htmlwidth}));
   $self{xlswidth}="16"                 if (!exists($self{xlswidth}));
   $self{searchable}=0                  if (!exists($self{searchable}));
   $self{align}="right"                 if (!defined($self{align}));
   $self{WSDLfieldType}="xsd:integer"   if (!defined($self{WSDLfieldType}));
   my $self=bless($type->SUPER::new(%self),$type);
   $self->{_permitted}->{thoupoint}=1;
   $self->{_permitted}->{autogen}=1;
   $self->{_permitted}->{format}=1;
   return($self);
}

#sub prepareToSearch
#{
#   my $self=shift;
#   if (defined($self->thoupoint)){
#      my $t=$self->thoupoint;
#      my $qt=quotemeta($t);
#      @_=map({
#              s/$qt//g;
#              $_;
#             } @_);
#   }
#   return(@_);
#}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   if ($mode eq "edit" && !defined($current)){
      my $readonly=0;
      if ($self->{readonly}==1){
         $readonly=1;
      }
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      return($self->getSimpleInputField($d,$readonly));
   }
   $d=[$d] if (ref($d) ne "ARRAY");
   if ($mode eq "HtmlDetail" || $mode eq "HtmlV01"){
      if (defined($self->thoupoint)){
         my $t=$self->thoupoint;
         my $qt=quotemeta($t);
         $d=[map({
                    my $d=$_;
                    $d=~s/(.+)(\d\d\d)$/$1$t$2/;
                    while($d=~m/\d\d\d\d/){
                       $d=~s/(\d)(\d\d\d$qt)/$1$t$2/;
                    }
                    $d;
                 } @{$d})];
      }
      if ($mode eq "HtmlDetail"){
         $d=[map({$self->addWebLinkToFacility(quoteHtml($_),$current)} @{$d})];
      }
   }
   $d=join("; ",@$d);
   return($d);
}

sub Uploadable
{
   my $self=shift;

   return(1);
}

sub getXLSformatname
{
   my $self=shift;
   my $data=shift;
   return("longint");
}

sub WSDLfieldType
{
   my $self=shift;
   my $ns=shift;
   my $mode=shift;
   return("xsd:integer");
}











1;
