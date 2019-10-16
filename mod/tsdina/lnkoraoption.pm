package tsdina::lnkoraoption;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'lnkid',
                label         =>'LinkID',
                htmldetail    =>0,
                uivisible     =>0,
                dataobjattr   =>'opt.ROWID'),

      new kernel::Field::Link(
                name          =>'dinainstanceid',
                label         =>'Instance ID',
                htmldetail    =>0,
                dataobjattr   =>'opt.dina_inst_id'),

      new kernel::Field::Link(
                name          =>'name',
                label         =>'Link name',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['optionname','instance'],
                onRawValue    =>sub{
                   my $self   =shift;
                   my $current=shift;
                   my $lnkname=$current->{optionname}.' - '.
                               $self->getParent->getVal('instancename');
                   return($lnkname);
                }),

      new kernel::Field::Number(
                name          =>'optionid',
                label         =>'Option ID',
                searchable    =>0,
                dataobjattr   =>'opt.optid'),

      new kernel::Field::Text(
                name          =>'optionname',
                label         =>'Option',
                ignorecase    =>1,
                htmlwidth     =>'200px',
                dataobjattr   =>'name.option_name'),

      new kernel::Field::Boolean(
                name          =>'installed',
                label         =>'installed',
                dataobjattr   =>'opt.installed'),

      new kernel::Field::Text(
                name          =>'instancename',
                label         =>'Instance',
                htmldetail    =>0,
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['dinainstanceid'=>'dinainstanceid'],
                vjoindisp     =>['dinainstancename']),

      new kernel::Field::SubList(
                name          =>'instances',
                label         =>'Instances',
                group         =>'instances',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['dinainstanceid'=>'dinainstanceid'],
                vjoindisp     =>[qw(dinainstancename systemname)]),

      new kernel::Field::Text(
                name          =>'dbname',
                label         =>'DB Name',
                htmldetail    =>0,
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['dinainstanceid'=>'dinainstanceid'],
                vjoindisp     =>['dbname']),
   );

   $self->setDefaultView(qw(linenumber instancename optionname installed));

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsdina"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="dina_inst2oracle_options_vw opt,".
            "oracle_db_options_vw name";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="opt.optid=name.optid(+)";
   return($where);
}

sub isQualityCheckValid
{
   return(0);
}

sub isUploadValid
{
   return(0);
}



1;
