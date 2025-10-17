package tsacinv::sharedstorage;
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
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetId',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'"assetid"'),

      new kernel::Field::Text(
                name          =>'nature',
                htmldetail    =>0,
                label         =>'Nature',
                dataobjattr   =>'"nature"'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'full name',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'"name"'),

      new kernel::Field::Id(
                name          =>'storagecode',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'StorageCode',
                dataobjattr   =>'"storagecode"'),

      new kernel::Field::Link(
                name          =>'storageid',
                sqlorder      =>'NONE',
                label         =>'StorageID',
                dataobjattr   =>'"storageid"'),

     new kernel::Field::Text(
                name          =>'exportname',
                label         =>'Export Name',
                ignorecase    =>1,
                dataobjattr   =>'"exportname"'),

     new kernel::Field::Text(
                name          =>'location',
                label         =>'Location',
                ignorecase    =>1,
                weblinkto     =>'tsacinv::location',
                weblinkon     =>['locationid'=>'locationid'],
                group         =>"location",
                dataobjattr   =>'"location"'),

      new kernel::Field::Text(
                name          =>'systemnames',
                label         =>'Systemnames',
                group         =>'clientsystems',
                weblinkto     =>'NONE',
                forwardSearch =>1,
                htmldetail    =>0,
                vjointo       =>'tsacinv::lnksharedstorage',
                vjoinon       =>['storageid'=>'storageid'],
                vjoindisp     =>'systemname'),

      new kernel::Field::Text(
                name          =>'applnames',
                label         =>'Applications',
                group         =>'clientsystems',
                weblinkto     =>'NONE',
                htmldetail    =>0,
                forwardSearch =>1,
                vjointo       =>'tsacinv::lnksharedstorage',
                vjoinon       =>['storageid'=>'storageid'],
                vjoindisp     =>'applname'),

      new kernel::Field::SubList(
                name          =>'mountpoints',
                label         =>'Mountpoints',
                group         =>'mountpoints',
                forwardSearch =>1,
                vjointo       =>'tsacinv::sharedstoragemnt',
                vjoinon       =>['storageid'=>'sharedstorageid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Text(
                name          =>'systemids',
                label         =>'SystemIDs',
                weblinkto     =>'NONE',
                htmldetail    =>0,
                group         =>'clientsystems',
                forwardSearch =>1,
                vjointo       =>'tsacinv::lnksharedstorage',
                vjoinon       =>['storageid'=>'storageid'],
                vjoindisp     =>'systemsystemid'),

      new kernel::Field::Text(
                name          =>'applids',
                label         =>'ApplicationIDs',
                group         =>'clientsystems',
                htmldetail    =>0,
                weblinkto     =>'NONE',
                forwardSearch =>1,
                vjointo       =>'tsacinv::lnksharedstorage',
                vjoinon       =>['storageid'=>'storageid'],
                vjoindisp     =>'applid'),


      new kernel::Field::Text(
                name          =>'place',
                label         =>'Place',
                group         =>"location",
                dataobjattr   =>'"place"'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'LocationID',
                dataobjattr   =>'"locationid"'),

      new kernel::Field::Link(
                name          =>'lassetid',
                dataobjattr   =>'"lassetid"'),

   );
   $self->setWorktable("sharedstorage");
   $self->setDefaultView(qw(fullname location place));
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
   return(qw(header default location mountpoints
             source));
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
