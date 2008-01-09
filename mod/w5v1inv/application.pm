package w5v1inv::application;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(         name          =>'id',
                                     label         =>'W5BaseID',
                                     dataobjattr   =>'bcapp.id'),
      new kernel::Field::Text(       name          =>'name',
                                     label         =>'Applicationname',
                                     dataobjattr   =>'bcapp.name'),
      new kernel::Field::Text(       name          =>'databoss',
                                     label         =>'Databoss',
                                     vjointo       =>'base::useraccount',
                                     vjoinon       =>['databossac'=>'account'],
                                     vjoindisp     =>'contactfullname'),
      new kernel::Field::Text(       name          =>'tsm',
                                     label         =>'TSM',
                                     vjointo       =>'base::useraccount',
                                     vjoinon       =>['tsmaccount'=>'account'],
                                     vjoindisp     =>'contactfullname'),
      new kernel::Field::Text(       name          =>'sem',
                                     label         =>'Service Manager',
                                     vjointo       =>'base::useraccount',
                                     vjoinon       =>['semaccount'=>'account'],
                                     vjoindisp     =>'contactfullname'),
      new kernel::Field::Text(       name          =>'tsm2',
                                     label         =>'TSM debuty',
                                     vjointo       =>'base::useraccount',
                                     vjoinon       =>['tsm2account'=>'account'],
                                     vjoindisp     =>'contactfullname'),
      new kernel::Field::Text(       name          =>'sem2',
                                     label         =>'debuty Service Manager',
                                     vjointo       =>'base::useraccount',
                                     vjoinon       =>['sem2account'=>'account'],
                                     vjoindisp     =>'contactfullname'),
      new kernel::Field::Text(       name          =>'costcenter',
                                     label         =>'CostCenter',
                                     dataobjattr   =>'bcapp.conummer'),
      new kernel::Field::Select(     name          =>'cistatus',
                                     label         =>'CI-State',
                                     vjointo       =>'base::cistatus',
                                     vjoinon       =>['cistatusid'=>'id'],
                                     vjoindisp     =>'name'),
      new kernel::Field::Text(       name          =>'customerarea',
                                     label         =>'Customer Area',
                                     vjointo       =>'base::grp',
                                     vjoinon       =>['kndorgarea'=>'grpid'],
                                     vjoindisp     =>'fullname'),
      new kernel::Field::Text(       name          =>'bteam',
                                     label         =>'Buissnes Team',
                                     vjointo       =>'base::grp',
                                     vjoinon       =>['bcteam'=>'grpid'],
                                     vjoindisp     =>'fullname'),
      new kernel::Field::Text(       name          =>'semteam',
                                     label         =>'Service Management Team',
                                     vjointo       =>'base::grp',
                                     vjoinon       =>['bcbereich'=>'grpid'],
                                     vjoindisp     =>'fullname'),
      new kernel::Field::Text(       name          =>'vieworgarea',
                                     label         =>'View Area',
                                     vjointo       =>'base::grp',
                                     vjoinon       =>['bcbereich'=>'grpid'],
                                     vjoindisp     =>'fullname'),
      new kernel::Field::Textarea(   name          =>'description',
                                     label         =>'Description',
                                     dataobjattr   =>'bcapp.appdoku'),
      new kernel::Field::Textarea(   name          =>'release',
                                     label         =>'Release',
                                     dataobjattr   =>'bcapp.wirkvers'),
      new kernel::Field::Link(       name          =>'cistatusid',
                                     label         =>'CI-StateID',
                                     dataobjattr   =>'bcapp.cistatus'),
      new kernel::Field::Link(       name          =>'databossac',
                                     dataobjattr   =>'databoss.account'),
      new kernel::Field::Link(       name          =>'tsmaccount',
                                     dataobjattr   =>'tsm.account'),
      new kernel::Field::Link(       name          =>'tsm2account',
                                     dataobjattr   =>'tsm2.account'),
      new kernel::Field::Link(       name          =>'semaccount',
                                     dataobjattr   =>'sem.account'),
      new kernel::Field::Link(       name          =>'sem2account',
                                     dataobjattr   =>'sem2.account'),
      new kernel::Field::Link(       name          =>'bcteam',
                                     dataobjattr   =>'bcapp.teamorgarea'),
      new kernel::Field::Link(       name          =>'vieworgarea',
                                     dataobjattr   =>'bcapp.vieworgarea'),
      new kernel::Field::Link(       name          =>'bcbereich',
                                     dataobjattr   =>'bcapp.bcbereich'),
      new kernel::Field::Link(       name          =>'kndorgarea',
                                     dataobjattr   =>'bcapp.kndorgarea'),
   );
   $self->setDefaultView(qw(id name cistatus cistatusid));
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   return("bcapp ".
          "left outer join user as databoss  on bcapp.databoss=databoss.id ".
          "left outer join user as tsm  on bcapp.tsm=tsm.id ".
          "left outer join user as tsm2 on bcapp.tsm2=tsm2.id ".
          "left outer join user as sem  on bcapp.sem=sem.id ".
          "left outer join user as sem2 on bcapp.sem2=sem2.id ");
}


sub Initialize
{  
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("bcapp");
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
   return(undef);
}









1;
