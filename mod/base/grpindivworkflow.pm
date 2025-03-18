package base::grpindivworkflow;
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
   $self->setWorktable("grpindivwfhead");
   $self->{grpindivLinkSQLIdField}='wfhead.wfheadid';
   $self->AddStandardFields();
   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'dataobjname',
                label         =>'Workflow',
                weblinkto     =>'base::workflow',
                weblinkon     =>['dataobjid'=>'id'],
                readonly      =>1,
                dataobjattr   =>'wfhead.shortdescription'),
   );

   $self->setDefaultView(qw(fieldname dataobjname indivfieldvalue mdate));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my $from="wfhead ".
         "join grpindivfld ".
         "on grpindivfld.dataobject='base::workflow' ".
         "left outer join grpindivwfhead ".
         "on (wfhead.wfheadid=grpindivwfhead.dataobjid ".
         " and grpindivwfhead.grpindivfld=grpindivfld.id)";
   if ($W5V2::OperationContext ne "W5Server"){
      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','up');
     
     
      my $ids=join(",",keys(%groups));
      my $dids=join(",",map({$_->{grpid}} 
                        grep({$_->{distance} eq "0"} 
                        values(%groups))));
     
      if ($ids eq ""){
         $ids="-99";
      }
      if ($dids eq ""){
         $dids="-99";
      }
     
      $from="wfhead ".
         "join grpindivfld ".
         "on grpindivfld.dataobject='base::workflow' and ".
         "((grpindivfld.grpview in ($ids) and grpindivfld.directonly='0') or ".
         "(grpindivfld.grpview in ($dids) and grpindivfld.directonly='1')) ".
         "left outer join grpindivwfhead ".
         "on (wfhead.wfheadid=grpindivwfhead.dataobjid ".
         " and grpindivwfhead.grpindivfld=grpindivfld.id)";
   }

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;
   my $where="";

   # due preformance problems with join of wfhead table, it is
   # need to add a where on wfhead.wfheadid on direct record access

   if ($mode eq "select"){
      foreach my $subf (@filter){
         my @fl=($subf);
         if (ref($subf) eq "ARRAY"){
            @fl=@$subf;
         }
         foreach my $f (@fl){
            if (ref($f) eq "HASH"){
               if (exists($f->{id}) && $f->{id}=~m/^\d+_\d+$$/){
                  $f->{id}=[$f->{id}];
               }
               if (exists($f->{id}) && ref($f->{id}) eq "SCALAR"){
                  $f->{id}=[${$f->{id}}];
               }
               if (exists($f->{id}) && ref($f->{id}) eq "ARRAY"){
                  my @wfheadid=map({
                     my ($wfheadid)=$_=~m/^(\d+)_/;
                     $wfheadid;
                  } @{$f->{id}});
                  if ($where ne ""){
                     $where.=" or ";
                  }
                  $where.="wfhead.wfheadid in (".join(",",@wfheadid).")";
               }
            }
         }
      }
   }
   return($where);
}

1;
