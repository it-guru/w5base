package tssm::chm_approvereq;
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
use tssm::lib::io;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name       =>'linenumber',
                label      =>'No.'),

      new kernel::Field::Text(        
                name       =>'changenumber',
                label      =>'Change No.',
                align      =>'left',
                dataobjattr=>SELpref.'cm3ra7.dh_number'),

      new kernel::Field::Text(      
                name       =>'name',
                ignorecase =>1,
                label      =>'Pending',
                htmldetail =>0,
                dataobjattr=>SELpref.'cm3ra7.tsi_approvals_manual'),

      new kernel::Field::Text(      
                name       =>'groupname',
                label      =>'Pending',
                htmlwidth  =>'200px',
                searchable =>0,
                vjointo    =>'tssm::group',
                vjoinon    =>['name'=>'name'],
                vjoindisp  =>['name']),

      new kernel::Field::Text(      
                name       =>'groupmailbox',
                label      =>'Group Email Address',
                vjointo    =>'tssm::group',
                vjoinon    =>['name'=>'name'],
                vjoindisp  =>['groupmailbox']),

      new kernel::Field::Text(
                name          =>'chmmgrgrp',
                uppersearch   =>1,
                label         =>'Changemanager group',
                dataobjattr   =>SELpref.'cm3rm1.tsi_manager_group'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Change Type (CBI)',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'cm3rm1.initial_impact'),

      new kernel::Field::Text(
                name          =>'phase',
                selectfix     =>1,
                label         =>'Current Phase',
                dataobjattr   =>SELpref.'cm3rm1.current_phase'),
   );

   $self->setDefaultView(qw(linenumber changenumber groupname groupmailbox));
   $self->{use_distinct}=0;

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_phase"))){
     Query->Param("search_phase"=>'"40 Change Approval"');
   }
}


sub initSqlWhere
{
   my $self=shift;
   my $where=SELpref."cm3ra7.tsi_approvals_manual is not null";
   return($where);
}


sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."cm3ra7 ".SELpref."cm3ra7 ".
            "join ".TABpref."cm3rm1 ".SELpref."cm3rm1 ".
              "on (".SELpref."cm3rm1.dh_number=".SELpref."cm3ra7.dh_number )";
   return($from);
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
   return(undef);
}


1;
