package AL_TCom::aegmgmt;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
   $self->{Worktable}="AL_TCom_appl_aegmgmt";
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->{history}=[qw(insert modify delete)];
   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"appl.id"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                uploadable    =>1,
                label         =>'Application',
                weblinkto     =>'itil::appl',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'appl.name'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                readonly      =>1,
                uploadable    =>0,
                htmleditwidth =>'40%',
                label         =>'Application CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Boolean(
                name          =>'managed',
                selectfix     =>1,
                label         =>'is managed AEG',
                dataobjattr   =>"$worktable.managed"),

      new kernel::Field::Databoss(
                readonly      =>1),

      new kernel::Field::Link(
                readonly      =>1,
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),


                                                  
      new kernel::Field::Link(
                name          =>'applcistatusid',
                readonly      =>1,
                uploadable    =>0,
                label         =>'Application CI-StateID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Select(
                name          =>'aegsolution',
                value         =>['Customer Solutions',
                                 'Market & Corporate Solutions',
                                 'Technologiy Solutions',
                                 'EU Solutions'],
                label         =>'Solution',
                dataobjattr   =>"$worktable.aegsolution"),


      new kernel::Field::Select(
                name          =>'meetinginterval',
                group         =>'meetings',
                value         =>['none',
                                 'weekly',
                                 'monthly'],
                label         =>'meeting interval',
                dataobjattr   =>"$worktable.meetinginterval"),
                                                  
      new kernel::Field::Date(
                name          =>'meetingstart',
                group         =>'meetings',
                label         =>'meetings startet at',
                dataobjattr   =>"$worktable.meetingstart"),
                                                  
      new kernel::Field::Textarea(
                name          =>'meetingcomments',
                group         =>'meetings',
                label         =>'meetings - comments',
                dataobjattr   =>"$worktable.meetingcomments"),
                                                  

      new kernel::Field::Boolean(
                name          =>'processcheckdone',
                group         =>'processcheck',
                label         =>'process check done',
                dataobjattr   =>"$worktable.processcheckdone"),
                                                  
      new kernel::Field::Date(
                name          =>'processcheckuntil',
                group         =>'processcheck',
                label         =>'process check finished at',
                dataobjattr   =>"$worktable.processcheckuntil"),
                                                  
      new kernel::Field::Textarea(
                name          =>'processcheckcomments',
                group         =>'processcheck',
                label         =>'process check - comments',
                dataobjattr   =>"$worktable.processcheckcomments"),
                                                  

      new kernel::Field::Boolean(
                name          =>'checklistdone',
                group         =>'checklist',
                label         =>'checklists created',
                dataobjattr   =>"$worktable.checklistdone"),
                                                  
      new kernel::Field::Date(
                name          =>'checklistuntil',
                group         =>'checklist',
                label         =>'checklist createfinished at',
                dataobjattr   =>"$worktable.checklistuntil"),
                                                  
      new kernel::Field::Textarea(
                name          =>'checklistcomments',
                group         =>'checklist',
                label         =>'checklist - comments',
                dataobjattr   =>"$worktable.checklistcomments"),

      new kernel::Field::Htmlarea(
                name          =>'applicationexpertgroup',
                readonly      =>1,
                group         =>'aeg',
                searchable    =>0,
                label         =>'Application Expert Group',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my $o=getModuleObject($self->getParent->Config,"TS::appl");
                   $o->SetFilter({id=>\$id});
                   my ($arec,$msg)=$o->getOnlyFirst($self->Name);
                   return($arec->{$self->Name});
                }),

      new kernel::Field::MDate(
                name          =>'mdate',
                readonly      =>1,
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Owner(
                name          =>'owner',
                readonly      =>1,
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                readonly      =>1,
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                readonly      =>1,
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>"$worktable.realeditor"),




   );
   $self->setDefaultView(qw(name applcistatus managed aegsolution));
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_managed"))){
     Query->Param("search_managed"=>$self->T("yes"));
   }
}






sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
      my $o=$self->Clone();
      $o->BackendSessionName("preProcessReadedRecord");
      my ($id)=$o->ValidatedInsertRecord({id=>$rec->{parentid}});
      $rec->{id}=$id;
   }
   return(undef);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="appl left outer join $worktable on appl.id=$worktable.id";

   return($from);
}

#sub initSqlWhere
#{
#   my $self=shift;
#   my $mode=shift;
#   my $where="(asset.cpucount is not null AND asset.cpucount>0)";
#   return($where);
#}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
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
   my @l=$self->SUPER::isWriteValid($rec);
   return("default","meetings","processcheck","checklist") if (in_array(\@l,"ALL"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default aeg meetings processcheck checklist source));
}




1;
