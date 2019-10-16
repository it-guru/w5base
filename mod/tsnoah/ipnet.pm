package tsnoah::ipnet;
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
                dataobjattr   =>"ipnet.subnetz_id"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Subnet label',
                dataobjattr   =>'ipnet.subnetzname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Subnet',
                dataobjattr   =>'ipnet.subnetz_von'),

      new kernel::Field::Text(
                name          =>'subnetmask',
                label         =>'Subnet mask',
                dataobjattr   =>'ipnet.subnetz_maske'),

      new kernel::Field::Link(
                name          =>'vlanid',
                label         =>'VLAN-ID',
                dataobjattr   =>'ipnet.vlan_id'),

      new kernel::Field::Link(
                name          =>'regionid',
                label         =>'RegionID',
                dataobjattr   =>'ipnet.region_id'),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                group         =>'ipaddresses',
                label         =>'IP-Adresses',
                htmldetail    =>0,
                vjointo       =>'tsnoah::ipaddress',
                vjoinon       =>['id'=>'subnetid'],
                vjoindisp     =>['name','systemname']),

      new kernel::Field::TextDrop(
                name          =>'systems',
                group         =>'systems',
                label         =>'Systems',
                weblinkto     =>'NONE',
                vjointo       =>'tsnoah::ipaddress',
                vjoinon       =>['id'=>'subnetid'],
                vjoindisp     =>'systemname'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'ipnet.timestamp'),

   );
   $self->setDefaultView(qw(fullname name subnetmask mdate));
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
   my $from="tsiimp.DARWIN_SUBNETZ ipnet";

   return($from);
}




sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","ipaddresses","systems","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ip_network.jpg?".$cgi->query_string());
}
         


1;
