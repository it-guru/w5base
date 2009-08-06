package base::interanswer;
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
use kernel::InterviewField;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::InterviewField);

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
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'QuestionID',
                dataobjattr   =>'interanswer.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'question',
                dataobjattr   =>'interview.name'),

      new kernel::Field::Boolean(
                name          =>'relevant',
                label         =>'Relevant',
                dataobjattr   =>'interanswer.relevant'),

      new kernel::Field::Text(
                name          =>'answer',
                label         =>'answer',
                dataobjattr   =>'interanswer.answer'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'relation',
                label         =>'parent Ojbect',
                dataobjattr   =>'interanswer.parentobj'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'relation',
                label         =>'parent ID',
                dataobjattr   =>'interanswer.parentid'),

      new kernel::Field::Text(
                name          =>'interviewid',
                group         =>'relation',
                label         =>'Interview ID',
                dataobjattr   =>'interanswer.interviewid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'interanswer.comments'),

      new kernel::Field::Text(
                name          =>'archiv',
                group         =>'archiv',
                htmldetail    =>0,
                label         =>'Archiv',
                dataobjattr   =>'interanswer.archiv'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'interanswer.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'interanswer.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'interanswer.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'interanswer.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'interanswer.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'interanswer.realeditor'),

   );
   $self->setDefaultView(qw(mdate parentobj parentid name relevant answer));
   $self->setWorktable("interanswer");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

#   my $name=trim(effVal($oldrec,$newrec,"name"));
#   if ($name=~m/^\s*$/i){
#      $self->LastMsg(ERROR,"invalid question specified"); 
#      return(undef);
#   }
#   my $questclust=trim(effVal($oldrec,$newrec,"questclust"));
#   if ($questclust=~m/^\s*$/i){
#      $self->LastMsg(ERROR,"invalid question group specified"); 
#      return(undef);
#   }
   my $archiv=trim(effVal($oldrec,$newrec,"archiv"));
   if ($archiv eq ""){
      $newrec->{archiv}=undef;
   }
   return(1);
}

sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join interview ".
          "on $worktable.interviewid=interview.id ");
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
   return("default","relation") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(Store));
}

sub Store
{
   my $self=shift;
   my $parentid=Query->Param("parentid");
   my $parentobj=Query->Param("parentobj");
   my $qid=Query->Param("qid");
   my $vname=Query->Param("vname");
   my $vval=Query->Param("vval");

   printf STDERR ("AjaxStore: qid=$qid parentid=$parentid parentobj=$parentobj vname=$vname\nval=$vval\n\n");
   $self->ResetFilter();
   $self->SetFilter({interviewid=>\$qid,
                     parentobj=>\$parentobj,
                     parentid=>\$parentid});
   my ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));

   my $i=getModuleObject($self->Config,"base::interview");
   $i->SetFilter({id=>\$qid});
   my ($irec,$msg)=$i->getOnlyFirst(qw(ALL));

   my $p=getModuleObject($self->Config,$parentobj);
   $p->SetFilter({id=>\$parentid});
   my ($rec,$msg)=$p->getOnlyFirst(qw(ALL));

   my $pwrite=$i->checkParentWrite($p,$rec);
   my $write=$i->checkAnserWrite($pwrite,$irec,$p,$rec);

   if ($vname eq "comments" || $vname eq "answer" || $vname eq "relevant"){

      if ($write){
         if (!defined($oldrec)){
            $self->ValidatedInsertRecord({$vname=>$vval,
                                          parentobj=>$parentobj,
                                          parentid=>$parentid,
                                          interviewid=>$qid});
         }
         else{
            $self->ValidatedUpdateRecord($oldrec,{$vname=>$vval},
                                         {id=>\$oldrec->{id}});
         }
      }
   }
   $self->SetFilter({interviewid=>\$qid,
                     parentobj=>\$parentobj,
                     parentid=>\$parentid});
   my ($newrec,$msg)=$self->getOnlyFirst(qw(answer comments relevant));

   my ($HTMLanswer,$HTMLrelevant,$HTMLcomments)=
         $i->getHtmlEditElements($write,$irec,$newrec,$p,$rec);

   $newrec->{HTMLanswer}=$HTMLanswer;
   $newrec->{HTMLrelevant}=$HTMLrelevant;
   $newrec->{HTMLcomments}=$HTMLcomments;
   
   print $self->HttpHeader("text/xml");
   my $res=hash2xml({document=>{result=>'ok',interanswer=>$newrec,exitcode=>0}},{header=>1});
   print $res;
   print STDERR $res;
}






1;
