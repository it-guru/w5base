package caiman::lib::Listedit;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"caiman"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   return(1) if (defined($self->{tsciam}));
   return(0);
}


sub Ping
{
   my $self=shift;
   my $errors;
   # Ping is for checking backend connect, without any error displaying ...
   {
      open local(*STDERR), '>', \$errors;
      $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   }
   # ... so STDERR outputs from this method are redirected to $errors
   if ($errors){
      foreach my $emsg (split(/[\n\r]+/,$errors)){
         $self->SilentLastMsg(ERROR,$emsg);
      }
   }
   else{
      my $chk=$self->Clone();
      return(1); # hab noch keine saubere Loesung fuer einen LDAP::Ping gefunden
      #printf STDERR ("do Ping $self\n");
      $chk->setLdapQueryPageSize(1);
      my $idField=$self->IdField();
      if (defined($idField)){
         my $idname=$idField->Name();
         open local(*STDERR), '>', \$errors;
         $chk->SetFilter({$idname=>'*'});
         my ($chkrec)=$chk->getOnlyFirst(qw(parentid));
         if ($errors && $errors ne ""){
            my @emsg=grep(/search execute failed/,split(/[\n\r]+/,$errors));
            @emsg=("wrong auth credentials or communication error");
            foreach my $emsg (@emsg){
               $self->SilentLastMsg(ERROR,$emsg);
            }
         }
         else{
            if (defined($chkrec)){
               return(1);
            }
            else{
               $self->SilentLastMsg(ERROR,"missing Ping check record");
            }
         }
         $self->SilentLastMsg(ERROR,"Ping check error");
         return(0);
      }
   }
   return($self->SUPER::Ping());
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


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



1;
