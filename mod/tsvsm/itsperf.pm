package tsvsm::itsperf;
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
   $param{MainSearchFieldLines}=4;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                dataobjattr   =>"logid"),

      new kernel::Field::Link(
                name          =>'businessserviceid',
                label         =>'BusinessServiceID',
                dataobjattr   =>"businessserviceid"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'IT-Service HashTag',
                dataobjattr   =>'hashtag'),

      new kernel::Field::Text(
                name          =>'businessservice',
                label         =>'Business Service',
                vjointo       =>'AL_TCom::businessservice',
                vjoinon       =>['businessserviceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Date(
                name          =>'mperiod_from',
                label         =>'measure period from',
                timezone      =>'CET',
                sqlorder      =>'NONE',
                dataobjattr   =>'mfrom'),

      new kernel::Field::Date(
                name          =>'mperiod_to',
                label         =>'measure period to',
                timezone      =>'CET',
                sqlorder      =>'NONE',
                dataobjattr   =>'mto'),

      new kernel::Field::Text(
                name          =>'mperiod',
                htmldetail    =>0,
                label         =>'measure period',
                sqlorder      =>'NONE',
                dataobjattr   =>"to_char(mfrom,'DD.MM.YYYY HH24:MI')||' - '|| ".
                                "to_char(mto,'DD.MM.YYYY HH24:MI') || ' CET'"),

      new kernel::Field::Select(
                name          =>'logtyp',
                label         =>'Log-Typ',
                value         =>[qw(day week)],
                dataobjattr   =>'logtyp'),

      new kernel::Field::Boolean(
                name          =>'islatest',
                group         =>'source',
                label         =>'is latest',
                dataobjattr   =>'decode(islatest,NULL,0,islatest)'),

      new kernel::Field::Link(
                name          =>'rawislatest',
                group         =>'source',
                label         =>'is latest',
                dataobjattr   =>'islatest'),

      new kernel::Field::Number(
                name          =>'avail',
                precision     =>2,
                unit          =>'%',
                label         =>'availability',
                dataobjattr   =>'avail'),

      new kernel::Field::Number(
                name          =>'perf',
                precision     =>2,
                unit          =>'%',
                label         =>'performance',
                dataobjattr   =>'performance'),

      new kernel::Field::Number(
                name          =>'quality',
                precision     =>2,
                unit          =>'%',
                label         =>'quality',
                dataobjattr   =>'quality'),

      new kernel::Field::Number(
                name          =>'resptime',
                precision     =>2,
                unit          =>'ms',
                label         =>'response time',
                dataobjattr   =>'resptime'),

      new kernel::Field::Number(
                name          =>'trend',
                precision     =>0,
                label         =>'Trend',
                dataobjattr   =>'trend'),

      new kernel::Field::MDate(
                name          =>'moddate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'mdate')
   );
   $self->setWorktable("measurementlog");

   $self->setDefaultView(qw(name logtyp mperiod_from 
                            avail perf quality));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsvsm"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_validto"))){
#     Query->Param("search_validto"=>
#                  ">now OR [EMPTY]");
#   }
#}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/w5stat.jpg?".$cgi->query_string());
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
