package tsdina::pslist;
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

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                searchable    =>0,
                dataobjattr   =>'w5map.servername'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                uppersearch   =>1,
                dataobjattr   =>'cfm.systemid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Command',
                dataobjattr   =>'ps.command_name'),

      new kernel::Field::Date(
                name          =>'scandate',
                timezone      =>'CET',
                label         =>'last Scandate',
                dataobjattr   =>'ps.last_monitor_date'),

      new kernel::Field::Text(
                name          =>'hostid',
                group         =>'source',
                label         =>'DinaHostID',
                dataobjattr   =>"cfm.host_id"),

      new kernel::Field::Text(
                name          =>'w5baseid',
                label         =>'W5BaseID',
                weblinkto     =>'itil::system',
                weblinkon     =>['w5baseid'=>'id'],
                dataobjattr   =>'w5map.w5baseid'),


   );

   $self->setDefaultView(qw(systemname name scandate));

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


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_scandate"))){
     Query->Param("search_scandate"=>">now-1d");
   }
}



sub getSqlFrom
{
   my $self=shift;
   my $from="d2dw_ps_comm_vw ps ".
            "join d2dw_system_config_vw cfm ".
            "on  cfm.host_id=ps.host_id ".
            "left outer join dina_darwin_map_vw w5map ".
            "on cfm.host_id = w5map.host_id ";
   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="current_date between cfm.valid_from and cfm.valid_to ".
             "and ps.last_monitor_date > current_date-7";
   return($where);
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
