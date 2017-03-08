package tsacinv::itfarmsystem;
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
                name          =>'lsysid',
                label         =>'ITFarmSystemID',
                dataobjattr   =>'sys.litemid'),

      new kernel::Field::Link(
                name          =>'lfarmid',
                label         =>'ITFarmID',
                dataobjattr   =>'clu.litemid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Systemname',
                ignorecase    =>1,
                htmlwidth     =>'250',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['systemid'=>'systemid'],
                dataobjattr   =>'sysportfolio.name'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                uppersearch   =>1,
                dataobjattr   =>'sys.assettag'),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                uppersearch   =>1,
                dataobjattr   =>'ass.assettag'),

      new kernel::Field::Text(
                name          =>'clusterid',
                label         =>'ClusterID',
                ignorecase    =>1,
                dataobjattr   =>'clu.assettag'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                ignorecase    =>1,
                dataobjattr   =>'sys.status'),

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
   $self->setDefaultView(qw(name systemid status));
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


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!out of operation\"");
   }
#   if (!defined(Query->Param("search_tenant"))){
#     Query->Param("search_tenant"=>"CS");
#   }
}

         

sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;
amcomputer con
   join amportfolio conportfolio
      on conportfolio.lportfolioitemid=con.litemid
   join amportfolio assportfolio
      on assportfolio.Lportfolioitemid=conportfolio.lparentid
   join amasset ass
      on assportfolio.assettag=ass.assettag
   join amcomputer clu
      on con.lparentid=clu.lcomputerid
   join amportfolio sysportfolio
      on assportfolio.Lportfolioitemid=sysportfolio.lparentid
   join amcomputer sys
      on sysportfolio.lportfolioitemid=sys.litemid
EOF
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=<<EOF;
conportfolio.usage like 'OSY-_: KONSOLSYSTEM %'
and sysportfolio.usage not like 'OSY-_: KONSOLSYSTEM %'
and clu.litemid<>'0'
EOF
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
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
