package tsacinv::itfarm;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=1;
   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'lfarmid',
                label         =>'ITFarmID',
                group         =>'source',
                dataobjattr   =>'"lfarmid"'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'350px',
                label         =>'ITFarm-Name',
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'clusterid',
                label         =>'ClusterID',
                ignorecase    =>1,
                dataobjattr   =>'"clusterid"'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                ignorecase    =>1,
                dataobjattr   =>'"status"'),

      new kernel::Field::Text(
                name          =>'farmassets',
                label         =>'ITFarmAssetIDs',
                ignorecase    =>1,
                vjointo       =>'tsacinv::itfarmasset',
                vjoinon       =>['lfarmid'=>'lfarmid'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'farmlocation',
                label         =>'ITFarmLocation',
                ignorecase    =>1,
                vjointo       =>'tsacinv::itfarmasset',
                vjoinon       =>['lfarmid'=>'lfarmid'],
                vjoindisp     =>'tsacinv_locationfullname'),

      new kernel::Field::SubList(
                name          =>'farmsystems',
                label         =>'ITFarm Systemnames',
                ignorecase    =>1,
                forwardSearch =>1,
                htmllimit     =>200,
                group         =>'systems',
                vjointo       =>'tsacinv::itfarmsystem',
                vjoinon       =>['lfarmid'=>'lfarmid'],
                vjoinbase     =>{status=>'!"out of operation"'},
                vjoindisp     =>[qw(name systemid status)]),
   
      new kernel::Field::SubList(
                name          =>'farmsystemids',
                label         =>'ITFarm SystemIDs',
                uppersearch   =>1,
                forwardSearch =>1,
                htmldetail    =>0,
                group         =>'systems',
                vjointo       =>'tsacinv::itfarmsystem',
                vjoinon       =>['lfarmid'=>'lfarmid'],
                vjoinbase     =>{status=>'!"out of operation"'},
                vjoindisp     =>[qw(systemid name status)]),
   

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
   $self->setWorktable("itfarm");
   $self->setDefaultView(qw(name clusterid status));
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default systems source));
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!out of operation\"");
   }
}

         
sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getRecordImageUrl
{  
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/itfarm.jpg?".$cgi->query_string());
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
