package itil::lnkbscomp;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
  
   my $dst           =[
                       'itil::appl'=>'name',
                       'itil::system' =>'name',
                       'itil::systemmonipoint' =>'fullname',
                      ];

   my $vjoineditbase =[{'cistatusid'=>"<5"},
                       {'cistatusid'=>"<5"},
                       {'systemcistatusid'=>'<5'}];

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'InterfaceComponentID',
                dataobjattr   =>'lnkbscomp.id'),

      new kernel::Field::Link(
                name          =>'businessserviceid',
                label         =>'Businessservice ID',
                dataobjattr   =>'lnkbscomp.businessservice'),

      new kernel::Field::Link(
                name          =>'sortkey',
                label         =>'SortKey',
                dataobjattr   =>'lnkbscomp.sortkey'),

      new kernel::Field::Select(
                name          =>'objtype',
                label         =>'Component type',
                getPostibleValues=>sub{
                   my $self=shift;
                   my @l;
                   my @dslist=@$dst;
                   while(my $obj=shift(@dslist)){
                       shift(@dslist);
                       push(@l,$obj,$self->getParent->T($obj,$obj));
                   }
                   return(@l);
                },
                dataobjattr   =>'lnkbscomp.objtype'),

      new kernel::Field::MultiDst (
                name          =>'name',
                htmlwidth     =>'200',
                htmleditwidth =>'200',
                selectivetyp  =>1,
                dst           =>$dst,
                vjoineditbase =>$vjoineditbase,
                label         =>'Component',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj1id'),

      new kernel::Field::Link(
                name          =>'obj1id',
                label         =>'Object1 ID',
                dataobjattr   =>'lnkbscomp.obj1id'),

      new kernel::Field::MultiDst (
                name          =>'namealt1',
                htmlwidth     =>'200',
                htmleditwidth =>'200',
                selectivetyp  =>1,
                dst           =>$dst,
                vjoineditbase =>$vjoineditbase,
                label         =>'Redundance 1',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj2id'),

      new kernel::Field::Link(
                name          =>'obj2id',
                label         =>'Object2 ID',
                dataobjattr   =>'lnkbscomp.obj2id'),

      new kernel::Field::MultiDst (
                name          =>'namealt2',
                htmlwidth     =>'200',
                htmleditwidth =>'200',
                selectivetyp  =>1,
                dst           =>$dst,
                vjoineditbase =>$vjoineditbase,
                label         =>'Redundance 2',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj3id'),

      new kernel::Field::Link(
                name          =>'obj3id',
                label         =>'Object3 ID',
                dataobjattr   =>'lnkbscomp.obj3id'),


      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkbscomp.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbscomp.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkbscomp.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbscomp.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbscomp.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkbscomp.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbscomp.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbscomp.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkbscomp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkbscomp.realeditor'),
   );
   $self->setDefaultView(qw(id fromappl toappl cdate editor));
   $self->setWorktable("lnkbscomp");
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

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

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

   my $bsid=effVal($oldrec,$newrec,"businessserviceid");

   return(undef) if ($bsid eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::businessservice");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$bsid);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL)); 
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^servicecomp$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(0);
}






1;
