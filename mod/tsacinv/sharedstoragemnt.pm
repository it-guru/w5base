package tsacinv::sharedstoragemnt;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'MountPointID',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'"id"'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Mountpoint',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Path',
                dataobjattr   =>'"name"'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'"lcomputerid"'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                group         =>'system',
                dataobjattr   =>'"systemname"'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                group         =>'system',
                dataobjattr   =>'"systemid"'),

      new kernel::Field::Text(
                name          =>'systemstatus',
                label         =>'System Status',
                group         =>'system',
                dataobjattr   =>'"systemstatus"'),

      new kernel::Field::Text(
                name          =>'storageassetid',
                label         =>'Storage-AssetId',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                group         =>'storage',
                align         =>'left',
                dataobjattr   =>'"storageassetid"'),

      new kernel::Field::Text(
                name          =>'storagefullname',
                htmldetail    =>0,
                searchable    =>0,
                group         =>'storage',
                label         =>'storage full name',
                dataobjattr   =>'"storagefullname"'),

      new kernel::Field::Text(
                name          =>'storagename',
                group         =>'storage',
                label         =>'Storage-Name',
                dataobjattr   =>'"storagename"'),

      new kernel::Field::Link(
                name          =>'sharedstorageid',
                sqlorder      =>'NONE',
                dataobjattr   =>'"sharedstorageid"'),

   );
   $self->setWorktable("sharedstoragemnt"); 
   $self->setDefaultView(qw(assetid stoid exportname location place));
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


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!out of operation\"");
   }
   if (!defined(Query->Param("search_tenant"))){
     Query->Param("search_tenant"=>"CS");
   }

}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/storage.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default system source));
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
