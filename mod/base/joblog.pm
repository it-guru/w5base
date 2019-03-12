package base::joblog;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseJobID',
                dataobjattr   =>'joblog.id'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Method',
                dataobjattr   =>'joblog.method'),

      new kernel::Field::Text(
                name          =>'pid',
                label         =>'ProcessID',
                dataobjattr   =>'joblog.pid'),

      new kernel::Field::Text(
                name          =>'event',
                label         =>'Event',
                dataobjattr   =>'joblog.event'),

      new kernel::Field::Text(
                name          =>'exitcode',
                group         =>'result',
                htmlwidth     =>'1%',
                label         =>'Exitcode',
                dataobjattr   =>'joblog.exitcode'),

      new kernel::Field::Text(
                name          =>'exitstate',
                htmlwidth     =>'1%',
                group         =>'result',
                label         =>'Exitstate',
                dataobjattr   =>'joblog.exitstate'),

      new kernel::Field::Text(
                name          =>'exitmsg',
                group         =>'result',
                htmlwidth     =>'200px',
                label         =>'Exit message',
                dataobjattr   =>'joblog.msg'),

      new kernel::Field::CDate(
                name          =>'cdate',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'joblog.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'joblog.modifydate'),

      new kernel::Field::Duration(
                name          =>'duration',
                htmlwidth     =>'30px',
                label         =>'Duration',
                visual        =>'auto',
                depend        =>['cdate','mdate']),

      new kernel::Field::Text(
                name          =>'srcsys',
                label         =>'Source-System',
                htmldetail    =>0,
                dataobjattr   =>'joblog.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                label         =>'Source-Id',
                htmldetail    =>0,
                dataobjattr   =>'joblog.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                label         =>'Last-Load',
                htmldetail    =>0,
                dataobjattr   =>'joblog.srcload'),



    #  new kernel::Field::Duration(  name        =>'durationraw',
    #                                label       =>'Duration Raw',
    #                                visual      =>'min',
    #                                depend      =>['cdate','mdate']),
   );
   $self->{dontSendRemoteEvent}=1;
   $self->setDefaultView(qw(id event method exitstate exitcode 
                            duration cdate mdate));
   $self->setWorktable("joblog");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","result","source");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

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

sub isDeleteValid
{
   my $self=shift;
   return(0) if (!$self->IsMemberOf("admin"));
   if (($self->Config->Param("W5BaseOperationMode") eq "dev") ||
       ($self->Config->Param("W5BaseOperationMode") eq "test")){
      return(1);
   }
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/env.jpg?".$cgi->query_string());
}

1;
