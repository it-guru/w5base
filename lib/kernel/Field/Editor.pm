package kernel::Field::Editor;
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
   if (!defined($self->{weblinkto})){
      $self->{weblinkto}="base::user";
   }
   if (!defined($self->{weblinkon})){
      $self->{weblinkon}=[$self->Name()=>'accounts'];
   }
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);

   $d=$self->addWebLinkToFacility($d,$current) if ($mode eq "HtmlDetail" &&
                                                   !($d=~m/^system\//) &&
                                                   !($d=~m/^service\//));

   return($d);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $editor=$newrec->{$self->Name()};
   return({}) if ($W5V2::OperationContext eq "Kernel");
   if ($W5V2::OperationContext eq "QualityCheck"){
      if (defined($oldrec)){
         return({});
      }
      else{
         return({$self->Name()=>"service/QualityCheck"});
      }
   }
   if ($W5V2::OperationContext eq "Enrichment"){
      if (defined($oldrec)){
         return({});
      }
      else{
         return({$self->Name()=>"service/QualityEnrichment"});
      }
   }
   $editor=$ENV{REMOTE_USER}    if ($editor eq "");
   $editor="system/".$ENV{USER} if ($editor eq "" && $ENV{USER} ne "");
   $editor="system/unknown"     if ($editor eq "");

   return({$self->Name()=>$editor});
}

sub Unformat
{
   my $self=shift;
   my $editor;
   $editor=$ENV{REMOTE_USER};

   return({$self->Name()=>$editor});
}



sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   return(undef);
}

sub Uploadable
{
   my $self=shift;

   return(0);
}







1;
