package base::workflowrelation;
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
use Data::Dumper;
use base::workflow;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'RelationID',
                dataobjattr   =>'wfrelation.wfrelationid'),

      new kernel::Field::TextDrop(
                name          =>'srcwf',
                label         =>'Source Workflow',
                vjointo       =>'base::workflow',
                vjoinon       =>['srcwfid'=>'id'],
                vjoindisp     =>'id'),
                                  
      new kernel::Field::Link(
                name          =>'srcwfid',
                label         =>'Source Workflow ID',
                dataobjattr   =>'wfrelation.srcwfid'),

      new kernel::Field::TextDrop(
                name          =>'dstwf',
                label         =>'Destination Workflow',
                vjointo       =>'base::workflow',
                vjoinon       =>['dstwfid'=>'id'],
                vjoindisp     =>'id'),
                                  
      new kernel::Field::TextDrop(
                name          =>'srcwfname',
                group         =>'src',
                label         =>'Source Workflow name',
                vjointo       =>'base::workflow',
                vjoinon       =>['srcwfid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'srcwfhead.shortdescription'),

      new base::workflow::Field::state(
                name          =>'srcstate',
                htmldetail    =>0,
                selectfix     =>1,
                label         =>'Source Workflow-State',
                transprefix   =>'wfstate.',
                translation   =>'base::workflow',
                readonly      =>1,
                dataobjattr   =>'srcwfhead.wfstate'),
                                  
      new kernel::Field::Container(
                name          =>'srcwfadditional',
                group         =>'src',
                label         =>'Source Workflow additional',
                dataobjattr   =>'srcwfhead.additional'),
                                  
      new kernel::Field::Text(
                name          =>'srcwfclass',
                group         =>'src',
                label         =>'Source Workflow class',
                dataobjattr   =>'srcwfhead.wfclass'),
                                  
      new kernel::Field::Container(
                name          =>'srcwfheadref',
                group         =>'src',
                label         =>'Source Workflow headref',
                dataobjattr   =>'srcwfhead.headref'),
                                  
      new kernel::Field::TextDrop(
                name          =>'srcwfsrcid',
                group         =>'src',
                label         =>'Source Workflow Source-Id',
                vjointo       =>'base::workflow',
                vjoinon       =>['srcwfid'=>'id'],
                vjoindisp     =>'srcid'),
                                  
      new kernel::Field::TextDrop(
                name          =>'dstwfname',
                group         =>'dst',
                label         =>'Destination Workflow name',
                vjointo       =>'base::workflow',
                vjoinon       =>['dstwfid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'dstwfhead.shortdescription'),
                                  
      new base::workflow::Field::state(
                name          =>'dststate',
                htmldetail    =>0,
                selectfix     =>1,
                label         =>'Destination Workflow-State',
                transprefix   =>'wfstate.',
                translation   =>'base::workflow',
                readonly      =>1,
                dataobjattr   =>'dstwfhead.wfstate'),
                                  
      new kernel::Field::Container(
                name          =>'dstwfadditional',
                group         =>'dst',
                label         =>'Source Workflow additional',
                dataobjattr   =>'dstwfhead.additional'),
                                  
      new kernel::Field::Text(
                name          =>'dstwfclass',
                group         =>'dst',
                label         =>'Source Workflow class',
                dataobjattr   =>'dstwfhead.wfclass'),
                                  
      new kernel::Field::Container(
                name          =>'dstwfheadref',
                group         =>'dst',
                label         =>'Source Workflow headref',
                dataobjattr   =>'dstwfhead.headref'),
                                  
      new kernel::Field::TextDrop(
                name          =>'dstwfsrcid',
                group         =>'dst',
                label         =>'Destination Workflow Source-Id',
                vjointo       =>'base::workflow',
                vjoinon       =>['dstwfid'=>'id'],
                vjoindisp     =>'srcid'),
                                  
      new kernel::Field::Link(
                name          =>'dstwfid',
                label         =>'Destination Workflow ID',
                dataobjattr   =>'wfrelation.dstwfid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Relation Mode',
                dataobjattr   =>'wfrelation.name'),

      new kernel::Field::Text(
                name          =>'translation',
                label         =>'Translation Base',
                dataobjattr   =>'wfrelation.translation'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments',
                label         =>'Comments',
                dataobjattr   =>'wfrelation.comments'),

      new kernel::Field::Container(
                name        =>'additional',  # public 
                group       =>'additional',
                label       =>'Additional',  # informations
                uivisible   =>0,
                dataobjattr =>'wfrelation.additional'),

     # new kernel::Field::Container(
     #           name        =>'relationref',   # secure
     #           group       =>'additional',
     #           label       =>'Action Ref',  # informations
     #           uivisible   =>sub{
     #              my $self=shift;
     #              my $mode=shift;
     #              my %param=@_;
     #              return(1) if ($self->getParent->IsMemberOf("admin"));
     #              return(0);
     #           },
     #           dataobjattr =>'wfrelation.relationref'),

      new kernel::Field::Text(
                name        =>'srcsys',
                group       =>'source',
                label       =>'Source-System',
                dataobjattr =>'wfrelation.srcsys'),
                                  
      new kernel::Field::Text(
                name        =>'srcid',
                group       =>'source',
                label       =>'Source-Id',
                dataobjattr =>'wfrelation.srcid'),
                                  
      new kernel::Field::Date(
                name        =>'srcload',
                group       =>'source',
                label       =>'Last-Load',
                dataobjattr =>'wfrelation.srcload'),

      new kernel::Field::Creator(
                name        =>'creator',
                group       =>'source',
                label       =>'Creator',
                dataobjattr =>'wfrelation.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                label         =>'CreatorID',
                dataobjattr   =>'wfrelation.createuser'),

      new kernel::Field::Owner(
                name        =>'owner',
                group       =>'source',
                label       =>'last Editor',
                dataobjattr =>'wfrelation.modifyuser'),

      new kernel::Field::MDate( 
                name        =>'mdate',
                group       =>'source',
                label       =>'Modification-Date',
                dataobjattr =>'wfrelation.modifydate'),
                                  
      new kernel::Field::CDate(
                name        =>'cdate',
                group       =>'source',
                label       =>'Creation-Date',
                dataobjattr =>'wfrelation.createdate'),
                                  
      new kernel::Field::Editor(
                name        =>'editor',
                group       =>'source',
                label       =>'Editor Account',
                dataobjattr =>'wfrelation.editor'),

      new kernel::Field::RealEditor(
                name        =>'realeditor',
                group       =>'source',
                label       =>'real Editor Account',
                dataobjattr =>'wfrelation.realeditor'),
   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(id name editor comments));
   $self->setWorktable("wfrelation");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;

   Query->Param("search_cdate"=>'>now-60m');
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   $name="info" if ($name eq "");
   if ($name eq ""){
      $self->LastMsg(ERROR,"invalid relation '%s' specified",$name);
      return(0);
   }
   my $owner=trim(effVal($oldrec,$newrec,"owner"));
   if ($owner!=0){
      $newrec->{owner}=$owner;
   }
   $newrec->{name}=$name;
   my $srcwfid=trim(effVal($oldrec,$newrec,"srcwfid"));
   if ($srcwfid eq ""){
      $self->LastMsg(ERROR,"invalid srcwfid '%s' specified",$srcwfid);
      return(0);
   }
   my $dstwfid=trim(effVal($oldrec,$newrec,"dstwfid"));
   if ($dstwfid eq ""){
      $self->LastMsg(ERROR,"invalid dstwfid '%s' specified",$dstwfid);
      return(0);
   }
   if ($dstwfid eq $srcwfid){
      $self->LastMsg(ERROR,"relation loops are not good");
      msg(ERROR,"loop reqeust on $srcwfid");
      return(0);
   }
   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join wfhead as srcwfhead ".
            "on $worktable.srcwfid=srcwfhead.wfheadid ".
            "left outer join wfhead as dstwfhead ".
            "on $worktable.dstwfid=dstwfhead.wfheadid ";

   return($from);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   my $userid=$self->getCurrentUserId();

   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["admin",
                                        "workflow.manager",
                                        "workflow.admin"]));
   return("ALL") if ($rec->{creator}==$userid);
   return(undef) if ($param{resultname} eq "HistoryResult" &&
                     $rec->{privatestate}>=1);
   return("header","default");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;
   return("default","comments") if ($self->IsMemberOf(["admin",
                                        "workflow.admin"]));
   if (defined($rec) && $rec->{wfheadid}>0){
      my $wf=$self->getPersistentModuleObject("wf","base::workflow");
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$rec->{wfheadid}});
      my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));

      if (defined($WfRec)){
         return(undef) if ($WfRec->{stateid}>=20);
         my $userid=$self->getCurrentUserId();
         return("actiondata") if (defined($rec) && 
                                  $userid == $rec->{creatorid});
         my @grps=$wf->isWriteValid($WfRec,%param);
         return("actiondata") if (grep(/^ALL$/,@grps) ||
                           grep(/^actions$/,@grps) ||
                           grep(/^flow$/,@grps));
      }
   }
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(1) if ($self->IsMemberOf(["admin","workflow.admin"]));
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","src","dst","comments","state");
}





1;
