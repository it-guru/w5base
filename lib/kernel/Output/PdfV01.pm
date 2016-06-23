package kernel::Output::PdfV01;
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
@ISA=qw(kernel::Output::JpgV01);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_pdf.gif");
}
sub Label
{
   return("Output to PDF");
}
sub Description
{
   return("Writes the data in PDF Format.");
}

sub MimeType
{
   return("application/pdf");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->kernel::Formater::getDownloadFilename().".pdf");
}

sub IsModuleSelectable
{  
   my $self=shift;

   eval("use DTP::pdf;");
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
   binmode($$fh);
   my $dtp;
   eval('use DTP::pdf;$dtp=new DTP::pdf();');
   if ($@ eq ""){
      $self->{dtp}=$dtp;
   }
   return(undef);
}

sub Finish
{
   my $self=shift;
   my $fh=shift;

   $self->{filename}="/tmp/tmp.$$.pdf";
   $self->{dtp}->GetDocument($self->{filename});
   if (open(F,"<$self->{filename}")){
      my $buf;
      while(sysread(F,$buf,8192)){
         syswrite($$fh,$buf);
      }
      close(F);
  }
  else{
      printf STDERR ("ERROR: can't open $self->{filename}\n");
  }
   unlink($self->{filename});
   return();
}

1;
