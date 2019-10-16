package tsdina::swinstance;
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'instanceid',
                label         =>'Instance ID',
                htmldetail    =>0,
                uivisible     =>0,
                dataobjattr   =>"concat(dina_inst_id,".
                                 "concat('-',systemid))"),

      new kernel::Field::Text(
                name          =>'dinainstanceid',
                label         =>'DINA Instance ID',
                htmldetail    =>0,
                dataobjattr   =>'dina_inst_id'),

      new kernel::Field::Text(
                name          =>'dinainstancename',
                label         =>'Instance Name',
                htmlwidth     =>'200px',
                ignorecase    =>1,
                dataobjattr   =>'instance_name'),

      new kernel::Field::Link(
                name          =>'dinadbid',
                label         =>'Dina DB ID',
                htmldetail    =>0,
                dataobjattr   =>'dina_db_id'),

      new kernel::Field::Link(
                name          =>'name',
                htmldetail    =>0,
                dataobjattr   =>"concat(instance_name,".
                                 "concat(' - ',host_name))"),

      new kernel::Field::Date(
                name          =>'monitordate',
                label         =>'Monitor Date',
                dataobjattr   =>'monitor_date'),

      new kernel::Field::Text(
                name          =>'dbname',
                label         =>'DB Name',
                ignorecase    =>1,
                group         =>'oracle',
                dataobjattr   =>'db_name'),

      new kernel::Field::Text(
                name          =>'edition',
                label         =>'Edition',
                ignorecase    =>1,
                group         =>'oracle',
                dataobjattr   =>'edition'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                group         =>'oracle',
                dataobjattr   =>'version'),

      new kernel::Field::SubList(
                name          =>'orafeatures',
                label         =>'Features',
                group         =>'features',
                forwardSearch =>1,
                searchable    =>0,
                vjointo       =>'tsdina::lnkorafeature',
                vjoinon       =>['dinadbid'=>'dinadbid'],
                vjoindisp     =>[qw(featurename usageinfo)]),      

      new kernel::Field::SubList(
                name          =>'oraoptions',
                label         =>'Options',
                group         =>'options',
                forwardSearch =>1,
                searchable    =>0,
                vjointo       =>'tsdina::lnkoraoption',
                vjoinon       =>['dinainstanceid'=>'dinainstanceid'],
                vjoindisp     =>[qw(optionname installed)]),      

      new kernel::Field::Text(
                name          =>'systemname',
                group         =>'system',
                label         =>'Systemname',
                vjointo       =>'tsdina::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>['name']),

      new kernel::Field::Text(
                name          =>'systemid',
                group         =>'system',
                label         =>'SystemID',
                dataobjattr   =>'systemid'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'monitor_date'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(dina_inst_id,35,'0')"),

   );

   $self->setDefaultView(qw(dinainstancename systemname monitordate));

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsdina"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="darwin_ora_license_info_vw";
   return($from);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","oracle","features","options","system");
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
   return("../../../public/itil/load/swinstance.jpg?".$cgi->query_string());
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isUploadValid
{
   return(0);
}



1;
