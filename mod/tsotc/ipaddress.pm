package tsotc::ipaddress;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'name',
                label         =>'IP-Address',
                dataobjattr   =>"ip_address"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                dataobjattr   =>"otc4darwin_server_vw.server_name"),

      new kernel::Field::Text(
                name          =>'hwaddr',
                label         =>'MAC address',
                dataobjattr   =>"mac_address"),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'OTC-SystemID',
                dataobjattr   =>"otc4darwin_server_ips_vw.server_uuid"),

   );
   $self->setDefaultView(qw(systemname name hwaddr systemid));
   $self->setWorktable("otc4darwin_server_ips_vw");
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsotc"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable ".
       "join otc4darwin_server_vw ".
       "on $worktable.server_uuid=otc4darwin_server_vw.server_uuid";

   return($from);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/location.jpg?".$cgi->query_string());
#}

#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
#}

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

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


1;
