package tsgrpmgmt::lnkmetagrp;
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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
use kernel::App::Web;
use kernel::DataObj::DB;
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'lnkmetagrp.id'),

      new kernel::Field::Text(
                name          =>'parentobj',
                frontreadonly =>1,
                label         =>'Parent object',
                dataobjattr   =>'lnkmetagrp.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                frontreadonly =>1,
                label         =>'RefID',
                dataobjattr   =>'lnkmetagrp.refid'),

      new kernel::Field::TextDrop(
                name          =>'group',
                label         =>'Group',
                htmlwidth     =>'60%',
                vjointo       =>'tsgrpmgmt::grp',
                vjoinon       =>['targetid'=>'id'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Link(
                name          =>'targetid',
                dataobjattr   =>'lnkmetagrp.targetid'),

      new kernel::Field::Select(
                name          =>'responsibility',
                default       =>'',
                htmleditwidth =>'40%',
                label         =>'Responsibility',
                value         =>['technical',
                                 'functional',
                                 'customer',
                                ],
                dataobjattr   =>'lnkmetagrp.responsibility'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkmetagrp.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkmetagrp.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkmetagrp.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkmetagrp.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkmetagrp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkmetagrp.realeditor'),

      new kernel::Field::Link(
                name          =>'secparentobj',
                label         =>'Security Parent-Object',
                sqlorder      =>'NONE',
                dataobjattr   =>'lnkmetagrp.parentobj'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkmetagrp.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkmetagrp.id,35,'0')"),
      );


   $self->setDefaultView(qw(group parentobj refid responsibility));
   $self->setWorktable('lnkmetagrp');

   return($self);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (defined($self->{secparentobj})){
      push(@flt,[{secparentobj=>\$self->{secparentobj}}]);
   }
   return($self->SetFilter(@flt));
}


sub isWriteOnParentValid
{
   my $self=shift;
   my $rec=shift;
   my $parent_fldgrp=shift;

   return(0) if (!defined($rec->{refid}));

   my $pobj=$self->getPersistentModuleObject('parentobj',$rec->{parentobj});

   return(0) if (!defined($pobj));
   my $idname=$pobj->IdField->Name();
   $pobj->SetFilter($idname=>$rec->{refid});
   my ($prec,$msg)=$pobj->getOnlyFirst('ALL');
   return(0) if (!defined($prec));
   return(1) if (!$self->isDataInputFromUserFrontend());

   my @l=$pobj->isWriteValid($prec);

   return(1) if (in_array(\@l,['ALL',$parent_fldgrp]));
   return(0);
}


sub getParentFieldGroup
{
   my $self=shift;

   return(undef);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $targetid=effVal($oldrec,$newrec,'targetid');
   my $parentobj=effVal($oldrec,$newrec,'parentobj');
   my $refid=effVal($oldrec,$newrec,'refid');

   if (!defined($targetid)) {
      $self->LastMsg(ERROR,"No group specified");
      return(0);
   }
   if ($parentobj eq '') {
      $self->LastMsg(ERROR,"No parent object specified");
      return(0);
   }

   my $pobj=$self->getPersistentModuleObject('parentobj',$parentobj);

   if (!defined($pobj)) {
      $self->LastMsg(ERROR,"Invalid dataobject '%s'",$parentobj);
      return(0);
   }
   if (!defined($oldrec) && $refid eq '') {
      $self->LastMsg(ERROR,"No RefID specified");
      return(0);
   }

   my $idfld=$pobj->IdField->Name();
   $pobj->SetFilter({$idfld=>$refid});
   my ($d,$msg)=$pobj->getOnlyFirst('ALL');

   if (!defined($d)) {
      $self->LastMsg(ERROR,"Invalid object ID '%d'",$refid);
      return(0);
   }

   my $parent_fldgrp=$self->getParentFieldGroup();
   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnParentValid({parentobj=>$parentobj,
                                        refid=>$refid},
                                       $parent_fldgrp)) {
        $self->LastMsg(ERROR,"You have no write access ".
                             "on the given parent object");
        return(0);
      }
   }

   return(1);
}


sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->isWriteOnParentValid($rec,$self->getParentFieldGroup())) {
      return(1);
   }

   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub getSqlFrom
{
   my $self=shift;

   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable join metagrpmgmt ".
            "on $worktable.targetid=metagrpmgmt.id";

   return($from);
}



1;
