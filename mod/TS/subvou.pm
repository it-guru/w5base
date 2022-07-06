package TS::subvou;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);



   $self->{useMenuFullnameAsACL}=$self->Self();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'subvou.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::TextDrop(
                name          =>'vou',
                htmlwidth     =>'100px',
                label         =>'parent virtual Org-Unit',
                htmlwidth     =>'160px',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (defined($rec)){
                      return(1);
                   }
                   return(0);
                },
                vjointo       =>'TS::vou',
                vjoinon       =>['vouid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'vouid',
                label         =>'VouID',
                dataobjattr   =>'subvou.vou'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                maxlength     =>'12',
                selectfix     =>1,
                dataobjattr   =>'subvou.name'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'subvou.description'),

      new kernel::Field::TextDrop(
                name          =>'reprgrp',
                readonly      =>1,
                htmldetail    =>'0',
                label         =>'representing group',
                vjointo       =>'base::grp',
                vjoinbase     =>{srcsys=>[$self->SelfAsParentObject()]},
                vjoinon       =>['id'=>'srcid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'subvou.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'subvou.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'subvou.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'subvou.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'subvou.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'subvou.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'subvou.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'subvou.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'subvou.realeditor'),
   );
   $self->setDefaultView(qw(name cdate mdate));
   $self->setWorktable("subvou");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default source));
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   if (!defined($oldrec)){
      my $vouid=$newrec->{vouid};
      if (!$self->isWriteOnVouValid($vouid,"subvous")){
         $self->LastMsg(ERROR,"no write access to selected virtual org unit");
         return(0);
      }
   }

   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   if (!defined($oldrec) || defined($newrec->{name})){
      my $newshortname=$newrec->{name};
      $newshortname=~s/\[\d+\]$//;
      if (length($newshortname)>12){
         $self->LastMsg(ERROR,"Name too long (max. 12 characters)");
         return(0);
      }
      if ($newshortname=~m/^\s*$/ || 
          !($newshortname=~m/^[a-z0-9_-]+$/i) ||
          ($newshortname=~m/^[0-9-]/i)) {
         $self->LastMsg(ERROR,"invalid Sub-Unit name (invalid characters)");
         return(0);
      }
   }
   if (effChanged($oldrec,$newrec,"name")){
      my $newname=effVal($oldrec,$newrec,"name");
      if ($newname=~m/^people$/i){
         $self->LastMsg(ERROR,"Sub-Unit name 'people' is not allowed");
         return(0);
      }
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("TS::subvou");
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orig=shift;

   my $parentobj="TS::vou";
   my $refid=effVal($oldrec,$newrec,"vouid");
   $self->UpdateParentMdate($parentobj,$refid);
   return($self->SUPER::FinishWrite($oldrec,$newrec,$orig));
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;


   my $parentobj="TS::vou";
   my $refid=$oldrec->{vouid};
   $self->UpdateParentMdate($parentobj,$refid);
   return($self->SUPER::FinishDelete($oldrec));
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @l;


   return("default") if (!defined($oldrec));


   my $vouid=effVal($oldrec,$newrec,"vouid");

   if ($self->isWriteOnVouValid($vouid,"subvous")){
      push(@l,"default");
   }

   return(@l);
}



sub isWriteOnVouValid
{
   my $self=shift;
   my $vouid=shift;
   my $group=shift;

   my $vou=$self->getPersistentModuleObject("TS::vou");
   $vou->SetFilter({id=>\$vouid});
   my ($arec,$msg)=$vou->getOnlyFirst(qw(ALL));
   my @g=$vou->isWriteValid($arec);
   if (grep(/^ALL$/,@g) || grep(/^$group$/,@g)){
      return(1);
   }
   return(0);
}







#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}



1;
