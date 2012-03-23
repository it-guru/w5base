package base::interviewcat;
#  W5Base Framework
#  Copyright (C) 2009  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web::HierarchicalList;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                size          =>'10',
                dataobjattr   =>'interviewcat.id'),
                                  
      new kernel::Field::TextDrop(
                name          =>'parent',
                label         =>'Parentgroup',
                vjointo       =>'base::interviewcat',
                vjoinon       =>['parentid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                size          =>'20',
                dataobjattr   =>'interviewcat.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                htmlwidth     =>'300px',
                dataobjattr   =>'interviewcat.fullname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'interviewcat.comments'),

      new kernel::Field::SubList(
                name          =>'questions',
                label         =>'Questions',
                group         =>'questions',
                readonly      =>1,
                vjointo       =>'base::interview',
                vjoinon       =>['id'=>'interviewcatid'],
                vjoindisp     =>['name','cistatus']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'id',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'interviewcat.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'id',
                label         =>'Source-Id',
                dataobjattr   =>'interviewcat.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'id',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'interviewcat.srcload'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'id',
                label         =>'Modification-Date',
                dataobjattr   =>'interviewcat.modifydate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'id',
                label         =>'Creation-Date',
                dataobjattr   =>'interviewcat.createdate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'interviewcat.createuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'id',
                label         =>'Editor',
                dataobjattr   =>'interviewcat.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'id',
                label         =>'RealEditor',
                dataobjattr   =>'interviewcat.realeditor'),

      new kernel::Field::Link(
                name          =>'parentid',
                label         =>'ParentID',
                dataobjattr   =>'interviewcat.parentid'),
   );
   $self->{history}=[qw(insert modify delete)];
   $self->{locktables}="interviewcat write, history write, iomap write";
   $self->setDefaultView(qw(fullname interviewcatid editor comments));
   $self->setWorktable("interviewcat");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (defined($newrec->{name}) || !defined($oldrec)){
      trim(\$newrec->{name});
      if ($newrec->{name} eq "" ||
           !($newrec->{name}=~m/^[a-zäöüß0-9_-\s]+$/i)){
         $self->LastMsg(ERROR,"invalid groupname '%s' specified",
                        $newrec->{name});
         return(undef);
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}



sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $g=getModuleObject($self->Config,"base::interview");
   my $grpid=$rec->{id};
   $g->SetFilter({"interviewcatid"=>\$grpid});
   if ($g->CountRecords()>0){
      return(0);
   }
   return(0) if (!grep(/^default$/,$self->isWriteValid($rec)));
   return($self->SUPER::isDeleteValid($rec));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec)){
      return(qw(header default id history questions));
   }
   return(qw(header default));
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default questions id));
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return(qw(default)) if ($self->IsMemberOf("admin"));
   if (!defined($rec)){
      my $o=getModuleObject($self->Config,"base::interview");
      $o->SetFilter({contactid=>\$userid});
      my ($rec,$msg)=$o->getOnlyFirst(qw(id));
      if (defined($rec)){
         return("default");
      }
   }
   return(qw(default)) if ($rec->{creator} == $userid);

   return(undef);
}

1;
