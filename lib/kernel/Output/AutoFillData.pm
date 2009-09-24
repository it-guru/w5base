package kernel::Output::AutoFillData;
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
use base::load;
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   return(0);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_csv.gif");
}
sub Label
{
   return("Output to CSV");
}
sub Description
{
   return("Writes the data for AutoFill functions.");
}

sub MimeType
{
   return("text/plain");
}

sub getEmpty
{
   my $self=shift;
   my %param=@_;
   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   return($d);
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".csv");
}

sub getHttpHeader
{  
   my $self=shift;
   my $d="";
   $d.="Content-type:".$self->MimeType()."\n\n";
   return($d);
}

sub quoteData
{
   my $d=shift;

   $d=~s/;/\\;/g;
   $d=~s/\r\n/\\n/g;
   $d=~s/\n/\\n/g;
   return($d); 
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;

   for(my $recno=0;$recno<=$#{$self->{recordlist}};$recno++){
      for(my $fieldno=0;$fieldno<=$#{$self->{recordlist}->[$recno]};$fieldno++){
         $d.=";" if ($fieldno>0);
         $d.=quoteData($self->{recordlist}->[$recno]->[$fieldno]);
      }
      $d.="\r\n";
   }
   return($d);
}

1;
