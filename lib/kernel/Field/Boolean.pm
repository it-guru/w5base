package kernel::Field::Boolean;
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
use kernel::Field::Select;

@ISA    = qw(kernel::Field::Select);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{value}=[0,1]            if (!defined($self->{value}));
   # Boolean unterstützt auch andere Werte für 0,1 wenn diese
   # bei der initialisierung als value mitgegeben werden. Erstes
   # value=false, zweites value=true (zumindest ist es so geplant)
   $self->{transprefix}="boolean." if (!defined($self->{transprefix}));
   $self->{allowempty}=0           if (!defined($self->{allowempty}));
   if (!defined($self->{default})){
      $self->{default}=$self->{allowempty} ? "": "0";
   }
   $self->{htmleditwidth}="60px"   if (!defined($self->{htmleditwidth}));
   $self->{WSDLfieldType}="xsd:boolean" if (!defined($self->{WSDLfieldType}));
   if ($self->{markempty}){
      $self->{default}=undef;
   }
  # if ($self->{allowempty} && !grep(/^$/,@{$self->{value}})){
  #    unshift(@{$self->{value}},"");
  # }
   return($self);
}


sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;


   my $d=$self->RawValue($current);
   if ($mode eq "SOAP"){
      return("true") if ($d);
      return("false");
   }
   if ($mode eq "JSON"){
      return(undef) if (!defined($d));
      return(\'1') if ($d);
      return(\'0');
   }
   if ($mode=~m/Html/i){
      return("?") if ($d eq "" && $self->{'markempty'});
   }

   return($d) if ($mode eq "XMLV01");
   return($self->SUPER::FormatedResult($current,$mode));
}


1;
