package tssm::chmtask;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'changenumber',
                label         =>'Change No.',
                align         =>'left',
                weblinkto     =>'tssm::chm',
                weblinkon     =>['changenumber'=>'changenumber'],
                dataobjattr   =>SELpref.'cm3tm1.parent_change'),

      new kernel::Field::Id(
                name          =>'tasknumber',
                label         =>'Task No.',
                searchable    =>1,
                align         =>'left',
                htmlwidth     =>'200px',
                dataobjattr   =>SELpref.'cm3tm1.dh_number'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Task Brief Description',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'cm3tm1.brief_desc'),

      new kernel::Field::Text(
                name          =>'status',
                group         =>'status',
                label         =>'Status',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'cm3tm1.tsi_status'),

      new kernel::Field::Text(
                name          =>'approvalstatus',
                label         =>'approval status',
                group         =>'status',
                ignorecase    =>1,
                dataobjattr   =>SELpref.'cm3tm1.approval_status'),

      new kernel::Field::Date(
                name          =>'plannedstart',
                label         =>'Planned Start',
                dataobjattr   =>SELpref.'cm3tm1.planned_start'),

      new kernel::Field::Date(
                name          =>'plannedend',
                label         =>'Planned End',
                dataobjattr   =>SELpref.'cm3tm1.planned_end'),

      new kernel::Field::Boolean(          
                name          =>'cidown',  
                label         =>'PSO-Flag',  
                dataobjattr   =>"decode(".SELpref."cm3tm1.ci_down,".
                                "'t','1','0')"),

##      new kernel::Field::Date(
##                name          =>'downstart',
##                group         =>'downtime',
##                label         =>'Down Start',
##                dataobjattr   =>'cm3tm1.down_start'),
##
##      new kernel::Field::Date(
##                name          =>'downend',
##                group         =>'downtime',
##                label         =>'Down End',
##                dataobjattr   =>'cm3tm1.down_end'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                searchable    =>0,
                htmlwidth     =>300,
                sqlorder      =>'NONE',
                dataobjattr   =>SELpref.'cm3tm1.description'),

      new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Relations',
                group         =>'relations',
                vjointo       =>'tssm::lnk',
                vjoinon       =>['tasknumber'=>'src'],
                vjoininhash   =>['dstname','dstobj'],
                vjoindisp     =>[qw(dst dstname)]),

      new kernel::Field::Date(
                name          =>'workstart',
                label         =>'Work Start',
                dataobjattr   =>SELpref.'cm3tm1.actualstart'),

      new kernel::Field::Date(
                name          =>'workend',
                label         =>'Work End',
                dataobjattr   =>SELpref.'cm3tm1.actualend'),

      new kernel::Field::Text(
                name          =>'assignedto',
                label         =>'Assigned to',
                group         =>'contact',
                ignorecase    =>1,
                weblinkto     =>'tssm::group',
                weblinkon     =>['assignedto'=>'fullname'],
                dataobjattr   =>SELpref.'cm3tm1.assign_dept'),

      new kernel::Field::Text(
                name          =>'implementer',
                label         =>'Implementer',
                group         =>'contact',
                ignorecase    =>1,
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['implementer'=>'loginname'],
                dataobjattr   =>SELpref.'cm3tm1.assigned_to'),

      new kernel::Field::Text(
                name          =>'editor',
                group         =>'status',
                label         =>'Editor Account',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['implementer'=>'loginname'],
                dataobjattr   =>SELpref.'cm3tm1.sysmoduser'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                label         =>'SysModTime',
                dataobjattr   =>SELpref.'cm3tm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                group         =>'status',
                label         =>'Create time',
                dataobjattr   =>SELpref.'cm3tm1.orig_date_entered'),

   );

   $self->{use_distinct}=0;
   $self->setDefaultView(qw(linenumber changenumber tasknumber 
                            name description));
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
   my $nowlabel=$self->T("now","kernel::App");

   if (!defined(Query->Param("search_plannedstart"))){
     Query->Param("search_plannedstart"=>">$nowlabel AND <$nowlabel+1d");
   }
}


sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."cm3tm1 ".SELpref."cm3tm1";
  #,scadm1.cm3tm1 downtab";
  # my $from="cm3tm1";
   return($from);
}

#sub initSqlWhere
#{
#   my $self=shift;
#   my $where="cm3tm1.numberprgn=downtab.numberprgn";
#   return($where);
#}

sub isQualityCheckValid
{
   return(0);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=qw(header default relations contact status);
   if ($rec->{cidown}){
      push(@l,"downtime");
   }
   
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default downtime relations contact status));
}




1;
