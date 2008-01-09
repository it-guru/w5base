package base::event::checkdouble;
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
use Data::Dumper;
use kernel;
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("checkdouble","CheckDouble");
   return(1);
}

sub CheckDouble
{
   my $self=shift;
   my $email=shift;
   my $surname=shift;
   my $givenname=shift;

   my $chk=getModuleObject($self->Config,"base::user");
   my @fl=qw(usertyp userid surname givenname email);

   if ($email ne ""){
      my $cemail=$email;
      $cemail=~s/\@.*$//;
      $chk->ResetFilter();
      $chk->SetFilter({email=>"$cemail\@*"});
      my @l=$chk->getHashList(@fl);
      my @e=map({$_->{email}} @l);
      printf("%s;",$email); 
      if ($#e==-1){
         printf("not found");
      }
      else{
         printf("%s",join(",",@e));
      }
      printf("\n");
      return({exitcode=>0});
   }
   else{
      my $user=getModuleObject($self->Config,"base::user");
    
      $user->ResetFilter();
      $user->SetCurrentView(@fl);
      my ($rec,$msg)=$user->getFirst();
      if (defined($rec)){
         do{
            my $email=$rec->{email};
            $email=~s/\@.*$/\@/g;
            if ($email ne "" && $email ne '@'){
               $email.="*";
               $chk->ResetFilter();
               $chk->SetFilter({email=>$email});
               my @l=$chk->getHashList(@fl);
               if ($#l!=0){
                  if ($#l>0){
                     my @e=map({$_->{email}} @l);
                     msg(ERROR,"double: %s\n",join(" ",@e));
                  }
               }
            }
            else{
               if ($rec->{usertyp} ne "service"){
                  msg(ERROR,"buggi: %s\n",$rec->{userid});
               }
            }
    
    
    
    
            ($rec,$msg)=$user->getNext();
         }until(!defined($rec));
      }
   }
   return({exitcode=>0});
}



1;
