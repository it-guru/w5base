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
                name          =>'lsysid',
                label         =>'ITFarmSystemID',
                dataobjattr   =>'"lsysid"'),

      new kernel::Field::Link(
                name          =>'lfarmid',
                label         =>'ITFarmID',
                dataobjattr   =>'"lfarmid"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Systemname',
                ignorecase    =>1,
                htmlwidth     =>'250',
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'systemname',
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                uppersearch   =>1,
                dataobjattr   =>'"systemid"'),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                uppersearch   =>1,
                dataobjattr   =>'"assetid"'),

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

   );
   $self->setWorktable("itfarmsystem"); 
   $self->setDefaultView(qw(name systemid status));
   return($self);
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
