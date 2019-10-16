package tsdina::lnkorafeature;
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
                dataobjattr   =>"concat(features.dina_db_id,".
                                 "concat('-',features.fid))"),

      new kernel::Field::Link(
                name          =>'dinadbid',
                label         =>'Dina DB ID',
                htmldetail    =>0,
                dataobjattr   =>'features.dina_db_id'),

      new kernel::Field::Link(
                name          =>'name',
                label         =>'Link name',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['featurename','dbname'],
                onRawValue    =>sub{
                   my $self   =shift;
                   my $current=shift;
                   my $lnkname=$current->{featurename}.' - '.
                               $self->getParent->getVal('dbname');
                   return($lnkname);
                }),

      new kernel::Field::Number(
                name          =>'featureid',
                label         =>'Feature ID',
                searchable    =>0,
                dataobjattr   =>'features.fid'),

      new kernel::Field::Text(
                name          =>'featurename',
                label         =>'Feature',
                ignorecase    =>1,
                htmlwidth     =>'200px',
                dataobjattr   =>'name.feature_name'),

      new kernel::Field::Boolean(
                name          =>'used',
                label         =>'Feature used',
                htmldetail    =>0,
                dataobjattr   =>"decode(features.usage_info,'--',0,1 )"),

      new kernel::Field::Text(
                name          =>'dbname',
                label         =>'DB Name',
                weblinkto     =>'none',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['dinadbid'=>'dinadbid'],
                vjoindisp     =>['dbname']),

      new kernel::Field::Text(
                name          =>'instance',
                label         =>'Instance',
                htmldetail    =>0,
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['dinadbid'=>'dinadbid'],
                vjoindisp     =>['name']),

      new kernel::Field::Text(
                name          =>'usageinfo',
                label         =>'last usage info',
                ignorecase    =>1,
                dataobjattr   =>'features.usage_info'),
   );

   $self->setDefaultView(qw(linenumber featurename dbname usageinfo));

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
   my $from="dina_db2oracle_features_vw features,".
            "oracle_db_features_vw name";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="features.fid=name.fid(+)";
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
