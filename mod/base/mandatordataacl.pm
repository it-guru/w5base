package base::mandatordataacl;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
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
                dataobjattr   =>'mandatordataacl.id'),

      new kernel::Field::Select(              # Attention: Mandator field type 
                name          =>'mandator',   # is not useable at this point
                label         =>'Mandator',
                vjointo       =>'base::mandator',
                vjoinon       =>['mid'=>'id'],
                useNullEmpty  =>1,
                allowempty    =>1,
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'mid',
                label         =>'MandatorMID',
                dataobjattr   =>'mandatordataacl.mandator'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                readonly      =>1,
                sqlorder      =>'NONE',
                label         =>'MandatorID',
                dataobjattr   =>'mandator.grpid'),

      new kernel::Field::Text(
                name          =>'parentobj',
                label         =>'Parent-Object',
                dataobjattr   =>'mandatordataacl.parentobj'),

      new kernel::Field::Text(
                name          =>'dataname',
                label         =>'Dataname',
                dataobjattr   =>'mandatordataacl.dataname'),

      new kernel::Field::MultiDst (
                name          =>'targetname',
                htmlwidth     =>'200',
                htmleditwidth =>'400',
                label         =>'Target-Name',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                vjoineditbase =>[{'cistatusid'=>[3,4]},
                                 {'cistatusid'=>4,
                                  'usertyp'=>['user']},
                                ],
                dsttypfield   =>'target',
                dstidfield    =>'targetid'),

      new kernel::Field::Link(
                name          =>'target',
                sqlorder      =>'NONE',
                label         =>'Target-Typ',
                dataobjattr   =>'target'),

      new kernel::Field::Link(
                name          =>'targetid',
                sqlorder      =>'NONE',
                dataobjattr   =>'targetid'),

      new kernel::Field::Number(
                name          =>'prio',
                htmlwidth     =>'30px',
                label         =>'Prio',
                dataobjattr   =>'prio'),

      new kernel::Field::Select(
                name          =>'aclmode',
                htmleditwidth =>'80px',
                htmlwidth     =>'40px',
                label         =>'Mode',
                value         =>[qw(allow deny)],
                dataobjattr   =>'aclmode'),

      new kernel::Field::Text(
                name          =>'comments',
                sqlorder      =>'NONE',
                htmlwidth     =>'150',
                label         =>'Comments',
                dataobjattr   =>'mandatordataacl.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Creator',
                dataobjattr   =>'mandatordataacl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'last Editor',
                dataobjattr   =>'mandatordataacl.modifyuser'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'mandatordataacl.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'mandatordataacl.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Editor Account',
                dataobjattr   =>'mandatordataacl.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'real Editor Account',
                dataobjattr   =>'mandatordataacl.realeditor')
   );
   $self->setDefaultView(qw(parentobj mandator dataname prio targetname aclmode));
   $self->setWorktable("mandatordataacl");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join mandator ".
          "on $worktable.mandator=mandator.id ");
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $targetid=effVal($oldrec,$newrec,"targetid");
   my $target=effVal($oldrec,$newrec,"target");
   if ($target eq "" || $targetid eq ""){
      $self->LastMsg(ERROR,"no contact specified");
      return(0);
   }
   if (!defined($oldrec) && $target eq "base::grp" && $targetid==-1){
      if (!defined($newrec->{prio})){
         $newrec->{prio}=9999;
      }
   }
   if (!defined($oldrec) && $target eq "base::grp" && $targetid==-2){
      if (!defined($newrec->{prio})){
         $newrec->{prio}=1000;
      }
   }
   if (exists($newrec->{dataname})){
      if (!($newrec->{dataname}=~m/^[a-z0-9\._]+$/i)){
         $self->LastMsg(ERROR,"invalid dataname");
         return(0);
      }
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
#   if (!defined($parentobj) && defined($self->{secparentobj})){
#      $parentobj=$self->{secparentobj};
#      $newrec->{parentobj}=$parentobj;
#   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return;
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;
   return(0) if (!defined($rec));
   return(1);
}





1;
