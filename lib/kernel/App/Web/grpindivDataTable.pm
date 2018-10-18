package kernel::App::Web::grpindivDataTable;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->setDefaultView(qw(fieldname dataobjname indivfieldvalue mdate));
   return($self);
}

sub AddStandardFields
{
   my $self=shift;

   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'indiv attribute value - W5BaseID',
                size          =>'10',
                group         =>'source',
                wrdataobjattr =>"id",
                dataobjattr   =>"concat(".$self->{grpindivLinkSQLIdField}.
                                ",'_',grpindivfld.id)"),
                                  
      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'OverflowID',
                readonly      =>1,
                size          =>'10',
                dataobjattr   =>$worktable.'.id'),
                                  
      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                dataobjattr   =>"concat(grpindivfld.name,': ',".
                                 $worktable.".fldval)"),
                                  
      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                dataobjattr   =>"concat(grpindivfld.name,': ',".
                                 $worktable.".fldval)"),

      # control field behavior
      new kernel::Field::Link(             
                name          =>'readonly',
                selectfix     =>1,
                dataobjattr   =>'grpindivfld.rdonly'),

      new kernel::Field::Link(
                name          =>'behavior',
                selectfix     =>1,
                dataobjattr   =>'grpindivfld.fldbehavior'),

      new kernel::Field::Link(
                name          =>'extra',
                selectfix     =>1,
                dataobjattr   =>'grpindivfld.fldextra'),
      ###################################################
                                  
      new kernel::Field::Link(
                name          =>'fieldidatvaluerec',
                label         =>'indiv attribute - value id',
                readonly      =>1,
                size          =>'10',
                dataobjattr   =>$worktable.'.grpindivfld'),
                                  
      new kernel::Field::Link(
                name          =>'indivfieldid',
                label         =>'Fieldid',
                size          =>'10',
                dataobjattr   =>'grpindivfld.id'),
                                  
      new kernel::Field::TextDrop(
                name          =>'fieldname',
                label         =>'attribute',
                weblinkto     =>'base::grpindivfld',
                weblinkon     =>['indivfieldid'=>'id'],
                readonly      =>1,
                size          =>'10',
                dataobjattr   =>'grpindivfld.name'),

      new kernel::Field::Interface(
                name          =>'grpidview',
                dataobjattr   =>'grpindivfld.grpview'),

      new kernel::Field::Interface(
                name          =>'grpidwrite',
                dataobjattr   =>'grpindivfld.grpwrite'),

      new kernel::Field::Link(
                name          =>'srcdataobjid',
                label         =>'attribute value DataObjID',
                readonly      =>1,
                size          =>'10',
                dataobjattr   =>$self->{grpindivLinkSQLIdField}),
                                  
      new kernel::Field::Link(
                name          =>'dataobjid',
                label         =>'Fieldvalue DataObjID',
                readonly      =>1,
                size          =>'10',
                dataobjattr   =>$worktable.'.dataobjid'),
                                  
      new kernel::Field::IndividualAttr(
                name          =>'indivfieldvalue',
                label         =>'value',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if ($rec->{readonly});
                   return(0);
                },
                dataobjattr   =>$worktable.'.fldval'),

      new kernel::Field::Text(
                name          =>'internalname',
                group         =>'source',
                label         =>'Internal field name',
                readonly      =>1,
                dataobjattr   =>
                           "concat('individualattribute_',grpindivfld.id)"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>$worktable.'.modifydate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>$worktable.'.createdate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>$worktable.'.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>$worktable.'.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>$worktable.'.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>$worktable.'.realeditor'),
   );

   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };
}



sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{id}};
   if (!defined($oldrec->{ofid})){     
      my %newrec=%{$newrec};
      $newrec{fieldidatvaluerec}=$oldrec->{indivfieldid}; 
      $newrec{dataobjid}=$oldrec->{id};  
      $newrec{id}=$oldrec->{srcdataobjid}."_".$oldrec->{indivfieldid}; # ID gen
      return($self->SUPER::ValidatedInsertRecord(\%newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $fieldidatvaluerec=effVal($oldrec,$newrec,"fieldidatvaluerec");
   my $g=$self->getPersistentModuleObject("indivGrp","base::grpindivfld");
   $g->SetFilter({id=>\$fieldidatvaluerec});
   my ($giFld,$msg)=$g->getOnlyFirst(qw(id readonly behavior extra));

   if (!defined($giFld)){
      $self->LastMsg("ERROR","invalid field id write request");
      return(undef);
   }

   if ($giFld->{readonly}){
      $self->LastMsg("ERROR","attribute is marked as archived");
      return(undef);
   }
   if ($giFld->{behavior} eq "singleline"){
      if (exists($newrec->{indivfieldvalue})){
         $newrec->{indivfieldvalue}=~s/[\r\n].*$//gs;
      }
   }
   if ($giFld->{behavior} eq "select"){
      my @valids=map({trim($_)} split(/\|/,$giFld->{extra}));
      if (exists($newrec->{indivfieldvalue})){
         my $newval=trim($newrec->{indivfieldvalue});
         if ($newval ne $newrec->{indivfieldvalue}){
            $newrec->{indivfieldvalue}=$newval;
         }
         if (!in_array(\@valids,$newval)){
            $self->LastMsg("ERROR","invalid value in select field",
                           'kernel::App::Web::grpindivDataTable');
            return(undef);
         }
      }
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));

   my $grpid=$rec->{grpidview};
   if ($self->IsMemberOf($grpid,["RMember","RBoss","RBoss2"],"up")){
      return("default");
   }
   if ($self->IsMemberOf("admin")){
      return("default");
   }

   return(undef);
}



1;
