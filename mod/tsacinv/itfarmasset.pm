package tsacinv::itfarmasset;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Id(
                name          =>'lconsid',
                label         =>'ITFarmAssetID',
                dataobjattr   =>'assportfolio.lportfolioitemid'),

      new kernel::Field::Link(
                name          =>'lfarmid',
                label         =>'ITFarmID',
                dataobjattr   =>'clu.litemid'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'LocationID',
                dataobjattr   =>'assportfolio.llocaid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'ITFarmAsset-AssetID',
                weblinkto     =>'tsacinv::asset',
                weblinkon     =>['name'=>'assetid'],
                ignorecase    =>1,
                dataobjattr   =>'ass.assettag'),

      new kernel::Field::Import( $self,
                weblinkto     =>'tsacinv::location',
                weblinkon     =>['locationid'=>'locationid'],
                vjointo       =>'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>'location',
                fields        =>['fullname','location']),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                ignorecase    =>1,
                dataobjattr   =>'ass.status'),

#      new kernel::Field::Interface(
#                name          =>'replkeypri',
#                group         =>'source',
#                label         =>'primary sync key',
#                dataobjattr   =>"assetmodel.dtlastmodif"),
#
#      new kernel::Field::Interface(
#                name          =>'replkeysec',
#                group         =>'source',
#                label         =>'secondary sync key',
#                dataobjattr   =>"lpad(assetmodel.lmodelid,35,'0')"),
#
#      new kernel::Field::Date(
#                name          =>'mdate',
#                group         =>'source',
#                label         =>'Modification-Date',
#                dataobjattr   =>'assetmodel.dtlastmodif'),
#

   );
   $self->setDefaultView(qw(name status));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;
amcomputer sys
   join amportfolio sysportfolio
      on sysportfolio.lportfolioitemid=sys.litemid
   join amportfolio assportfolio
      on assportfolio.Lportfolioitemid=sysportfolio.lparentid
   join amasset ass
      on assportfolio.assettag=ass.assettag
   join amcomputer clu
      on sys.lparentid=clu.lcomputerid
EOF
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=<<EOF;
sysportfolio.usage like 'OSY-_: KONSOLSYSTEM %'
and sys.status<>'out of operation'
and clu.litemid<>'0'
EOF
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
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
   my $rec=shift;
   return(undef);
}


1;
