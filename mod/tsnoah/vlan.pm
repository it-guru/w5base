package tsnoah::vlan;
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
                group         =>'source',
                label         =>'ID',
                dataobjattr   =>"vlan.vlan_id"),

      new kernel::Field::Text(
                name          =>'vlanid',
                label         =>'VLAN-ID',
                dataobjattr   =>"vlan.vlan_id"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'VLAN label',
                dataobjattr   =>'vlan.vlan_name'),

      new kernel::Field::Text(
                name          =>'contactemail',
                label         =>'Contact email',
                dataobjattr   =>'vlan.ansprechpartner'),

      new kernel::Field::TextDrop(
                name          =>'contact',
                label         =>'Contact',
                vjointo       =>'base::user',
                vjoinon       =>['contactemail'=>'email'],
                vjoindisp     =>'fullname'),

      new kernel::Field::SubList(
                name          =>'ipnets',
                group         =>'ipnets',
                label         =>'IP-Networks',
                vjointo       =>'tsnoah::ipnet',
                vjoinon       =>['id'=>'vlanid'],
                vjoindisp     =>['name','fullname']),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'timestamp'),

   );
   $self->setDefaultView(qw(name vlanid mdate));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsinet"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="tsiimp.DARWIN_VLAN vlan ";

   return($from);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","ipnets","source");
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/ip_network.jpg?".$cgi->query_string());
#}
         


1;
