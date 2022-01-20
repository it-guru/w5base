package itil::lnkapplappltag;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
  
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'InterfaceTagID',
                dataobjattr   =>'lnkapplappltag.id'),

      new kernel::Field::Link(
                name          =>'lnkapplappl',
                label         =>'Interface ID',
                dataobjattr   =>'lnkapplappltag.lnkapplappl'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'lnkapplappltag.name'),

      new kernel::Field::Text(
                name          =>'value',
                label         =>'Value',
                dataobjattr   =>'lnkapplappltag.value'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplappltag.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplappltag.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplappltag.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplappltag.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkapplappltag.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplappltag.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplappltag.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplappltag.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplappltag.realeditor'),
   );
   $self->setDefaultView(qw(id fromappl toappl cdate editor));
   $self->setWorktable("lnkapplappltag");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!$self->checkWriteValid($oldrec,$newrec)){
      $self->LastMsg(ERROR,"no access");
      return(0);
   }

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   #return(undef);
   return("default") if (!defined($rec));
   return("default") if ($self->checkWriteValid($rec));
   return(undef);
}

sub checkWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $lnkapplappl=effVal($oldrec,$newrec,"lnkapplappl");

   return(undef) if ($lnkapplappl eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$lnkapplappl);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL)); 
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^interfacetag$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(1);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
