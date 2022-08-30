package tsadsEMEA1::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::LDAP;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub Initialize
{
   my $self=shift;

   my $module=$self->Module();

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,$module));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{tsadsEMEA1}));
   return(0);
}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;
   if (exists($self->{objectClass})){
      foreach my $fltsub (@flt){
         my @fltsub=$fltsub;
         if (ref($fltsub[0]) eq "ARRAY"){
            @fltsub=@$fltsub;
         }
         foreach my $fltsubhash (@fltsub){
            if (ref($fltsubhash) eq "HASH"){
               if (!exists($fltsubhash->{id})){
                  $fltsubhash->{objectClass}=$self->{objectClass};
               }
            }
         }
      }
   }
   return($self->SUPER::SetFilter(@flt));
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}



1;
