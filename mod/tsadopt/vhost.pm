package tsadopt::vhost;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'vHostID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"abstract_compute_id"),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'200px',
                label         =>'virtualisation Host',
                dataobjattr   =>"system_name"),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Hardware Type',
                dataobjattr   =>"hardware_type"),

      new kernel::Field::TextDrop(
                name          =>'vfarm',
                label         =>'virtual Farm',
                vjointo       =>'tsadopt::vfarm',
                vjoinon       =>['vfarmid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>"ager"),

      new kernel::Field::Link(
                name          =>'vfarmid',
                label         =>'vfarm id',
                dataobjattr   =>"virtual_farm_id"),

   );
   $self->{use_distinct}=0;
   #$self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(name assetid type vfarm));
   $self->setWorktable("view_darwin_abstract_compute");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsadopt"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="virtual_farm_id is not null";
   return($where);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsadopt/load/vhost.jpg?".$cgi->query_string());
}



#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_operational"))){
#     Query->Param("search_operational"=>"\"".$self->T("yes")."\"");
#   }
#}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
