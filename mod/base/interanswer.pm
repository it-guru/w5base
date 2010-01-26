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
                label         =>'AnswerID',
                dataobjattr   =>'interanswer.id'),

      new kernel::Field::TextDrop(
                name          =>'name',
                label         =>'question',
                readonly      =>1,
                vjointo       =>'base::interview',
                vjoinon       =>['interviewid'=>'id'],
                vjoindisp     =>'name',
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
                uploadable    =>0,
                label         =>'parent Ojbect',
                dataobjattr   =>'interanswer.parentobj'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'relation',
                uploadable    =>0,
                label         =>'parent ID',
                dataobjattr   =>'interanswer.parentid'),

      new kernel::Field::Text(
                name          =>'interviewid',
                group         =>'relation',
                uploadable    =>0,
                label         =>'Interview ID',
                dataobjattr   =>'interanswer.interviewid'),

      new kernel::Field::TextDrop(
                name          =>'qtag',
                label         =>'unique query tag',
                translation   =>'base::interview',
                group         =>'relation',
                vjointo       =>'base::interview',
                vjoinon       =>['interviewid'=>'id'],
                vjoindisp     =>'qtag',
                dataobjattr   =>'interview.qtag'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'interanswer.comments'),

      new kernel::Field::Text(
                name          =>'archiv',
                group         =>'archiv',
                htmldetail    =>0,
                uploadable    =>0,
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
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(mdate parentobj parentid name relevant answer));
   $self->setWorktable("interanswer");
   return($self);
}

sub prepUploadRecord
{
   my $self=shift;
   my $newrec=shift;

   if (!exists($newrec->{id}) || $newrec->{id} eq ""){
      if (exists($newrec->{qtag}) && $newrec->{qtag} ne "" &&
          exists($newrec->{parentname}) && $newrec->{parentname} ne ""){
         my $fobj=$self->getField("parentname");
         if (defined($fobj)){
            my $i=$self->Clone();
            $i->SetFilter({qtag=>\$newrec->{qtag},
                           parentname=>\$newrec->{parentname}});
            my ($rec,$msg)=$i->getOnlyFirst(qw(id));
            if (defined($rec)){
               $newrec->{id}=$rec->{id};
               delete($newrec->{qtag});
               delete($newrec->{parentname});
            }
         }
      }
   }

   return(1);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("base::interanswer");
}




sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $i=getModuleObject($self->Config,"base::interview");

   my $fobj=$self->getField("parentname");
   if (defined($fobj)){
      my $rec={};
      my $comprec={};
      my $rawWrRequest=$fobj->Validate($oldrec,$newrec,$rec,$comprec);
      if (defined($rawWrRequest)){
         foreach my $k (keys(%{$rawWrRequest})){
            $newrec->{$k}=$rawWrRequest->{$k};
         }
         delete($newrec->{parentname});
      }
   }
   my $qid=effVal($oldrec,$newrec,"interviewid");
   if ($qid eq ""){
      my $qtag=effVal($oldrec,$newrec,"qtag");
      if ($qtag ne ""){
         $i->SetFilter({qtag=>\$qtag});
         my ($irec,$msg)=$i->getOnlyFirst(qw(id)); 
         if (defined($irec)){
            delete($newrec->{qtag});
            $newrec->{interviewid}=$irec->{id};
         }
      }
   }

   if (defined($oldrec)){
      foreach my $k (keys(%{$newrec})){
         next if ($k eq "comments" ||
                  $k eq "answer"   ||
                  $k eq "relevant");
         delete($newrec->{$k});
      }
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $parentid=effVal($oldrec,$newrec,"parentid");
   my $qid=effVal($oldrec,$newrec,"interviewid");
   if ($parentid eq ""){
      $self->LastMsg(ERROR,"invalid parentid"); 
      return(0);
   }
   if ($qid eq ""){
      $self->LastMsg(ERROR,"invalid question id"); 
      return(0);
   }
   my ($write,$irec)=$self->getAnswerWriteState($i,$qid,$parentid,$parentobj);
   #printf STDERR ("parentobj=$parentobj parentid=$parentid qid=$qid SecureValidate=%s\n",Dumper($newrec));
   if (!$write){
      $self->LastMsg(ERROR,"insuficient rights to answer this question"); 
      return(0);
   }
   if (!defined($oldrec)){
      if ($newrec->{parentobj} eq ""){ 
         $newrec->{parentobj}=$irec->{parentobj};
      }
      if ($irec->{parentobj} ne $newrec->{parentobj}){
         $self->LastMsg(ERROR,"parentobj doesn't macht question parentobj"); 
         return(0); 
      }
   }

   return(1);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where;
   if ($self->{secparentobj} ne ""){
      $where="interanswer.parentobj='$self->{secparentobj}'";
   }
   return($where);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) && !defined($newrec->{archiv})){
      $newrec->{archiv}="";
   }
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
   if (defined($rec)){
      my $parentobj=$rec->{parentobj};
      my $parentid=$rec->{parentid};
      my $qid=$rec->{interviewid};
      my $i=getModuleObject($self->Config,"base::interview");
      my ($write,$irec,$oldans)=
                       $self->getAnswerWriteState($i,$qid,$parentid,$parentobj);

      return("default") if ($write);
      return("default") if ($self->IsMemberOf("admin"));
      return(undef);
   }
   return("default","relation");
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(), qw(Store));
}

sub getAnswerWriteState
{
   my $self=shift;
   my $i=shift;
   my $qid=shift;
   my $parentid=shift;
   my $parentobj=shift;

   $i->ResetFilter();
   $i->SetFilter({id=>\$qid});
   my ($irec,$msg)=$i->getOnlyFirst(qw(ALL));
   if ($parentobj eq ""){
      $parentobj=$irec->{parentobj};
   }

   $self->ResetFilter();
   $self->SetFilter({interviewid=>\$qid,
                     parentobj=>\$parentobj,
                     parentid=>\$parentid});
   my ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));

   my $p=getModuleObject($self->Config,$parentobj);
   return(0,$irec,$oldrec,undef) if (!defined($p));
   $p->SetFilter({id=>\$parentid});
   my ($rec,$msg)=$p->getOnlyFirst(qw(ALL));

   my $pwrite=$i->checkParentWrite($p,$rec);
   return($i->checkAnserWrite($pwrite,$irec,$p,$rec),$irec,$oldrec,$rec);
}

sub Store
{
   my $self=shift;
   my $parentid=Query->Param("parentid");
   my $parentobj=Query->Param("parentobj");
   my $qid=Query->Param("qid");
   my $vname=Query->Param("vname");
   my $vval=Query->Param("vval");

   my $i=getModuleObject($self->Config,"base::interview");
   printf STDERR ("\n\nAjaxStore: qid=$qid parentid=$parentid ".
                  "parentobj=$parentobj vname=$vname\nval=$vval\n\n");

   my ($write,$irec,$oldrec)=$self->getAnswerWriteState($i,$qid,
                                                        $parentid,$parentobj);
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
         $i->getHtmlEditElements($write,$irec,$newrec);

   $newrec->{HTMLanswer}=$HTMLanswer;
   $newrec->{HTMLrelevant}=$HTMLrelevant;
   $newrec->{HTMLcomments}=$HTMLcomments;
   
   print $self->HttpHeader("text/xml");
   my $res=hash2xml({document=>{result=>'ok',interanswer=>$newrec,exitcode=>0}},{header=>1});
   print $res;
   #print STDERR $res;
}






1;
