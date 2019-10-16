package tssm::devDumper;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::Field::DataDump;
use tssm::lib::io;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'DeviceID',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'device2m1.logical_name'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'CI Name',
                ignorecase    =>1,
                dataobjattr   =>'device2m1.ci_name'),


      new kernel::Field::DataDump(
                name          =>'fulldump',
                depend        =>['changenumber'],
                label         =>'DataDump',
                sqldepend     =>[
                   'dh_device2m1'=>{
                       dbname=>'tssm',
                       joinon=>['id'=>'logical_name'] 
                   },
                ]),
   );

   $self->setDefaultView(qw(linenumber changenumber 
                            fulldump));
   return($self);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");

   $self->{use_distinct}=0;
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/chm.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $from="dh_device2m1 device2m1";
   return($from);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return if (!$self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}







1;
