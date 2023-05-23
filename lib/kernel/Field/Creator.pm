package kernel::Field::Creator;
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
use kernel::Field::Owner;
@ISA    = qw(kernel::Field::Owner);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{history}=0 if (!defined($param{history}));
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $name=$self->Name();
   my $userid;

   if (!defined($oldrec)){
      if (!defined($newrec->{$name})){
         return({}) if ($W5V2::OperationContext eq "QualityCheck");
         my $userid=$self->getDefaultValue();
         return({}) if (!defined($userid));
         return({$name=>$userid});
      }
      return({$name=>$newrec->{$name}});
   }
   return({});
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if ($hflt->{$field} eq "*"){
      delete($hflt->{$field});
   }

   if (defined($hflt->{$field}) &&
       !ref($hflt->{$field}) && $hflt->{$field} ne ""){
      if (!($hflt->{$field} eq "[LEER]" || $hflt->{$field} eq "[EMPTY]" ||
            $hflt->{$field} eq "![LEER]" || $hflt->{$field} eq "![EMPTY]")){
         if (!($hflt->{$field}=~m/^\d+$/)){
            my $u=getModuleObject($self->getParent->Config,"base::user");
            $u->SetFilter({fullname=>$hflt->{$field}});
            $hflt->{$field}=[map({$_->{userid}} $u->getHashList(qw(userid)))];
            $changed++;
         }
      }
   }

   return($changed,$err);
}



sub getDefaultValue
{  
   my $self=shift;
   my $userid;

   my $UserCache=$self->getParent->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{tz})){
      $userid=$UserCache->{userid};
   }
   return($userid);
}

sub Unformat
{  
   my $self=shift;
   return({$self->Name()=>$self->getDefaultValue()});
}

sub Uploadable
{
   my $self=shift;

   return(0);
}




1;
