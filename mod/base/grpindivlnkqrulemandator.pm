package base::grpindivlnkqrulemandator;
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
use kernel::App::Web::grpindivDataTable;
@ISA=qw(kernel::App::Web::grpindivDataTable);

sub new
{
   my $type=shift;
   my %param=@_;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->setWorktable("grpindivlnkqrulemandator");
   $self->{grpindivLinkSQLIdField}='lnkqrulemandator.lnkqrulemandatorid';
   $self->AddStandardFields();
   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'dataobjname',
                label         =>'QRule Activation',
                weblinkto     =>'base::lnkqrulemandator',
                weblinkon     =>['dataobjid'=>'id'],
                readonly      =>1,
                dataobjattr   =>"concat(lnkqrulemandator.qrule,'-',".
                         "lnkqrulemandator.dataobj,'-',".
                         "if (lnkqrulemandator.mandator is null ".
                         "or lnkqrulemandator.mandator='0','ANY',".
                         "if (mandator.name is null,'INVALID',mandator.name)))")
   );

   $self->setDefaultView(qw(fieldname dataobjname indivfieldvalue mdate));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;

   my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','up');

   my $ids=join(",",keys(%groups));
   my $dids=join(",",map({$_->{grpid}} 
                     grep({$_->{distance} eq "0"} 
                     values(%groups))));
   if ($dids eq ""){
      $dids="-99";
   }
   if ($ids eq ""){
      $ids="-99";
   }
   my $from.="lnkqrulemandator ".
          "left outer join mandator ".
          " on lnkqrulemandator.mandator=mandator.grpid ".
          "join grpindivfld ".
          "on grpindivfld.dataobject='base::lnkqrulemandator' and ".
          "((grpindivfld.grpview in ($ids) and grpindivfld.directonly='0') or ".
          "(grpindivfld.grpview in ($dids) and grpindivfld.directonly='1')) ".
          "left outer join grpindivlnkqrulemandator ".
          "on (lnkqrulemandator.lnkqrulemandatorid=".
               "grpindivlnkqrulemandator.dataobjid ".
          " and grpindivlnkqrulemandator.grpindivfld=grpindivfld.id)";

   return($from);
}


1;
