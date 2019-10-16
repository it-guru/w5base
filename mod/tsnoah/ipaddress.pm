package tsnoah::ipaddress;
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
                sqlorder      =>'desc',
                label         =>'ID',
                dataobjattr   =>"ipaddress.ip_id"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'ifname',
                label         =>'Interface Name',
                htmlwidth     =>'200',
                nowrap        =>1,
                dataobjattr   =>'interface.interface_name'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'IP-Address',
                dataobjattr   =>'ipaddress.ip_adresse'),

      new kernel::Field::Boolean(
                name          =>'isprimary',
                label         =>'is primary',
                dataobjattr   =>"decode(interface.primary_interface,".
                                "'ja',1,'nein',0)"),

      new kernel::Field::TextDrop(
                name          =>'subnet',
                label         =>'Subnet',
                vjointo       =>'tsnoah::ipnet',
                vjoinon       =>['subnetid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'subnetid',
                label         =>'SubNetID',
                dataobjattr   =>'interface.subnetz_id'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                vjointo       =>'tsnoah::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                uppersearch   =>1,
                dataobjattr   =>'device.devicename'),

      new kernel::Field::Link(
                name          =>'systemid',
                dataobjattr   =>'ipaddress.device_id'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'ipaddress.timestamp'),

   );
   $self->setDefaultView(qw(name systemname mdate));
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
   my $from="tsiimp.DARWIN_IP ipaddress ".
         "join tsiimp.DARWIN_INTERFACE interface ".
         "on ipaddress.interfacezuordnung_id=interface.interfacezuordnung_id ".
         "left outer join tsiimp.DARWIN_DEVICE device ".
         "on interface.device_id=device.device_id";

   return($from);
}




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
   return("../../../public/itil/load/ip_adress.jpg?".$cgi->query_string());
}
         


1;
