package kernel::Output::PngV01;
#  W5Base Framework
#  Copyright (C) 2007  Holm Basedow (holm@blauwaerme.de)
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
use kernel::Output::JpgV01;
@ISA    = qw(kernel::Output::JpgV01);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_png.gif");
}
sub Label
{
   return("Output to Png");
}
sub Description
{
   return("Writes the data to a Png Image.");
}

sub MimeType
{
   return("application/zip");
}

sub getDownloadFilename
{
   my $self=shift;
   return($self->SUPER::getDownloadFilename().".zip");
}

sub IsModuleSelectable
{
   my $self=shift;

   eval("use DTP::png;");
   if ($@ ne ""){
      return(0);
   }
   return(1);
}

sub Init
{
   my $self=shift;
   my ($fh)=@_;
   $|=1;
   my ($id,$res);
   binmode($$fh);
   my ($dtp,$zip);
   eval('use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
         $zip=new Archive::Zip();');
   if ($@ eq ""){
      $self->{zip}=$zip;
   }else{
      printf STDERR ("ERROR: $@\n");
   }
   eval('use DTP::png;$dtp=new DTP::png();');
   if ($@ eq ""){
      $self->{dtp}=$dtp;
   }else{
      printf STDERR ("ERROR: $@\n");
   }
   if (defined($res=$self->getParent->getParent->W5ServerCall("rpcGetUniqueId")) &&
      $res->{exitcode}==0){
      $id=$res->{id};
   }
   $self->{dtp}->{_Layout}->{dir}="/tmp/tmp.$id.png";
   mkdir($self->{dtp}->{_Layout}->{dir});
   $self->{dtp}->{_Layout}->{tempfile}=$self->{dtp}->{_Layout}->{dir}."/doc%04d";
}

1;

