package itil::grpindivappl;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
   $self->setWorktable("grpindivappl");
   $self->{grpindivLinkSQLIdField}='appl.id';
   $self->AddStandardFields();
   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'dataobjname',
                label         =>'Application',
                weblinkto     =>'itil::appl',
                weblinkon     =>['dataobjid'=>'id'],
                readonly      =>1,
                dataobjattr   =>'appl.name'),
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
   my $from.="appl ".
          "join grpindivfld ".
          "on grpindivfld.dataobject='itil::appl' and ".
          "((grpindivfld.grpview in ($ids) and grpindivfld.directonly='0') or ".
          "(grpindivfld.grpview in ($dids) and grpindivfld.directonly='1')) ".
          "left outer join grpindivappl ".
          "on (appl.id=grpindivappl.dataobjid ".
          " and grpindivappl.grpindivfld=grpindivfld.id)";

   return($from);
}


1;
