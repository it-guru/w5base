package tssm::inmDumper;
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
                label         =>'Incident No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'probsummarym1.dh_number'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'probsummarym1.brief_description'),


      new kernel::Field::DataDump(
                name          =>'fulldump',
                depend        =>['id'],
                label         =>'DataDump',
                sqldepend     =>[
                   'dh_probsummarym1'=>{
                       dbname=>'tssm',
                       joinon=>['id'=>'dh_number'] 
                   },
                ]),
   );

   $self->setDefaultView(qw(linenumber id 
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
   my $from="dh_probsummarym1 probsummarym1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="(probsummarym1.last='t' or probsummarym1.last is null)";
   my $where="";
   return($where);
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
