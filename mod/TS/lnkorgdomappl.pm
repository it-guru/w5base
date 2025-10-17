package TS::lnkorgdomappl;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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

   $self->{use_distinct}=1; 

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'orgdom',
                htmlwidth     =>'360px',
                label         =>'OrgDomain Object',
                vjointo       =>'TS::orgdom',
                vjoinon       =>['orgdomid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'orgdom.name'),
                                                   
      new kernel::Field::Interface(
                name          =>'orgdomid',
                label         =>'OrgDomainID',
                dataobjattr   =>'lnkorgdom.orgdomid'),

      new kernel::Field::Text(
                name          =>'orgdomorgdomid',
                label         =>'OrgDomain OrgDomainID',
                htmlwidth     =>'180px',
                dataobjattr   =>'orgdom.orgdomid'),

      new kernel::Field::Text(
                name          =>'ictono',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'ICTO-ID',
                dataobjattr   =>'lnkorgdom.ictono'),

      new kernel::Field::Text(
                name          =>'ictoid',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'ICTO internal ID',
                dataobjattr   =>'lnkorgdom.ictoid'),

      new kernel::Field::Text(
                name          =>'appl',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Application',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Interface(
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'appl.id'),

      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                searchable    =>0,
                default       =>'100',
                htmlwidth     =>'60px',
                dataobjattr   =>'lnkorgdom.fraction'),

      new kernel::Field::TextDrop(
                name          =>'vou',
                htmlwidth     =>'100px',
                label         =>'virtual Org-Unit',
                htmlwidth     =>'160px',
                vjointo       =>'TS::vou',
                vjoinon       =>['vouid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>"concat(".
                                "vou.shortname,".
                                "if (vou.name<>'','-',''),".
                                "vou.name".
                                ")"),
                                                   
      new kernel::Field::TextDrop(
                name          =>'voushort',
                htmlwidth     =>'100px',
                label         =>'virtual Org-Unit Short',
                htmlwidth     =>'160px',
                vjointo       =>'TS::vou',
                vjoinon       =>['vouid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'vou.shortname'),
                                                   
      new kernel::Field::Text(
                name          =>'vougrpname',
                label         =>'virtual Org-Unit Group',
                dataobjattr   =>'grp.fullname'),
                                                   
      new kernel::Field::Interface(
                name          =>'vougrpid',
                label         =>'virtual Org-Unit GroupID',
                dataobjattr   =>'grp.grpid'),
                                                   
      new kernel::Field::Interface(
                name          =>'vouid',
                label         =>'VouID',
                dataobjattr   =>'lnkorgdom.vouid'),

      new kernel::Field::Text(
                name          =>'orgdomorgdomid',
                label         =>'OrgDomainID',
                dataobjattr   =>'orgdom.orgdomid')
   );
   $self->setDefaultView(qw(orgdomorgdomid orgdom fraction 
                            ictono vou voushort vougrpname appl));
   $self->setWorktable("lnkorgdom");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="appl ".
            "left outer join lnkorgdom ".
            "on lnkorgdom.ictono=appl.ictono ".
            "left outer join vou ".
            "on lnkorgdom.vouid=vou.id ".
            "left outer join grp ".
            "on grp.srcid=vou.id and grp.srcsys='TS::vou' ".
            "left outer join orgdom ".
            "on lnkorgdom.orgdomid=orgdom.id ";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="appl.cistatus in (3,4)";
   return($where);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
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
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default source ));
}



1;
