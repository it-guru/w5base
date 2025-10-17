package tsadsEMEA1::lnkaduseradgroup;
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
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(    name     =>'userObjectID',
                                  label    =>'UserObjectID'),

      new kernel::Field::Text(    name     =>'groupObjectID',
                                  label    =>'GroupObjectID'),

      new kernel::Field::Text(    name     =>'group',
                                  weblinkto=>sub{
                                     my $self=shift;
                                     my $d=shift;
                                     my $current=shift;
                                     my $targetObject;
                                     my $mod=$self->getParent->Module();
                                     if ($current->{groupObjectID}
                                         =~m/,dc=emea1,/i){
                                        return(\'tsadsEMEA1::adgroup',
                                               ['groupObjectID'
                                                =>'distinguishedName']);
                                     }
                                     if ($current->{groupObjectID}
                                         =~m/,dc=emea2,/i){
                                        return(\'tsadsEMEA2::adgroup',
                                               ['groupObjectID'
                                                =>'distinguishedName']);
                                     }
                                     return("none",undef);
                                  },
                                  label    =>'group'),

      new kernel::Field::Text(    name     =>'user',
                                  weblinkto=>sub{
                                     my $self=shift;
                                     my $d=shift;
                                     my $current=shift;
                                     my $targetObject;
                                     if ($current->{userObjectID}
                                         =~m/,dc=emea1,/i){
                                        return(\'tsadsEMEA1::aduser',
                                               ['userObjectID'
                                                =>'distinguishedName']);
                                     }
                                     if ($current->{userObjectID}
                                         =~m/,dc=emea2,/i){
                                        return(\'tsadsEMEA2::aduser',
                                               ['userObjectID'
                                                =>'distinguishedName']);
                                     }
                                     return("none",undef);
                                  },
                                  label    =>'user'),

   );

   $self->{'data'}=\&queryRelations;
   $self->setDefaultView(qw(user userObjectID group groupObjectID));
   return($self);
}


sub queryRelations
{
   my $self=shift;
   my $filterset=shift;
   my %data;
   if (ref($filterset) eq "HASH" &&
       ref($filterset->{FILTER}) eq "ARRAY" &&
       ref($filterset->{FILTER}->[0]) eq "HASH"){
      my $flt=$filterset->{FILTER}->[0];
      my $module=$self->Module();

      if (exists($flt->{userObjectID})){  
         my $user=$self->getPersistentModuleObject($module."::aduser");
         $user->SetFilter({distinguishedName=>$flt->{userObjectID}});
         foreach my $arec ($user->getHashList(qw(distinguishedName memberOf))){
            my $qid=$flt->{userObjectID};
            $qid=~s/^["'](.*)["']$/$1/;
            foreach my $cnid (@{$arec->{memberOf}}){
               my $k=$qid."::".$cnid;
               if (!exists($data{$k})){
                  $data{$k}={
                      groupObjectID=>$cnid,
                      group=>$cnid, 
                      userObjectID=>$qid 
                  };
               }
            }
         }
      }

      if (exists($flt->{groupObjectID})){  
         my $group=$self->getPersistentModuleObject($module."::adgroup");
         $group->SetFilter({distinguishedName=>$flt->{groupObjectID}});
         foreach my $arec ($group->getHashList(qw(distinguishedName member))){
            my $qid=$flt->{groupObjectID};
            $qid=~s/^["'](.*)["']$/$1/;
            foreach my $cnid (@{$arec->{member}}){
               my $k=$qid."::".$cnid;
               if (!exists($data{$k})){
                  $data{$k}={
                      userObjectID=>$cnid,
                      user=>$cnid, 
                      groupObjectID=>$qid 
                  };
               }
            }
         }
      }

#
#
#      if (exists($flt->{userObjectID})){   # Abfrage von der User-Seite
#         my $group=$self->getPersistentModuleObject($module."::adgroup");
#         my @qid=$flt->{userObjectID};
#         @qid=@{$qid[0]}  if (ref($qid[0]) eq "ARRAY");
#         @qid=(${$qid[0]}) if (ref($qid[0]) eq "SCALAR");
#         $group->SetFilter({member=>\@qid});
#         foreach my $arec ($group->getHashList(qw(id fullname))){
#            next if ($arec->{fullname} eq "");
#            foreach my $qid (@qid){
#               my $k=$qid."::".$arec->{id};
#               if (!exists($data{$k})){
#                  $data{$k}={
#                      groupObjectID=>$arec->{id}, 
#                      group=>$arec->{id}, 
#                      userObjectID=>$qid 
#                  };
#               }
#            }
#         }
#      }
#      if (exists($flt->{groupObjectID})){   # Abfrage von der Gruppen-Seite
#         my $user=$self->getPersistentModuleObject($module."::aduser");
#         my @qid=($flt->{groupObjectID});
#         my $fltstring=$flt->{groupObjectID};
#         if (!($fltstring=~m/^["'].*["']$/)){
#            $fltstring='"'.$fltstring.'"';
#         }
#         $user->SetFilter({memberOf=>$fltstring});
#         foreach my $arec ($user->getHashList(qw(id fullname))){
#            next if ($arec->{fullname} eq "");
#            foreach my $qid (@qid){
#               $qid=~s/^["'](.*)["']$/$1/;
#               my $k=$qid."::".$arec->{id};
#               if (!exists($data{$k})){
#                  $data{$k}={
#                      userObjectID=>$arec->{id}, 
#                      user=>$arec->{id}, 
#                      groupObjectID=>$qid 
#                  };
#               }
#            }
#         }
#      }


   }
   return([values(%data)]);
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
