package ewu2::ipaddress;
#  W5Base Framework
#  Copyright (C) 118  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'ipaddressid',
                label         =>"Ip Address Id",
                dataobjattr   =>"\"IP_ADDRESSES\".\"IP_ADDRESS_ID\""),

      new kernel::Field::Text(
                name          =>'name',
                nowrap        =>1,
                label         =>"IP-Address",
                dataobjattr   =>"\"IP_ADDRESSES\".\"ADDRESS\""),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>"DNS Name",
                dataobjattr   =>"\"IP_ADDRESSES\".\"DNS_NAME\""),

      new kernel::Field::Text(
                name          =>'dnsdomain',
                label         =>"DNS Domain",
                dataobjattr   =>"\"IP_ADDRESSES\".\"DNS_DOMAIN\""),

      new kernel::Field::Text(
                name          =>'system',
                label         =>'System',
                vjointo       =>\'ewu2::system',
                vjoinon       =>['devlabsystemid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'dnscname',
                label         =>"DNS Cname",
                dataobjattr   =>"\"IP_ADDRESSES\".\"DNS_CNAME\""),

      new kernel::Field::Link(
                name          =>'ptrnameid',
                label         =>"PTR Name Id",
                dataobjattr   =>"\"IP_ADDRESSES\".\"PTR_NAME_ID\""),

      new kernel::Field::Text(
                name          =>'devlabsystemid',
                htmldetail    =>0,
                label         =>"DevLabSystemId",
                dataobjattr   =>"\"IP_ADDRESSES\".\"COMPUTER_SYSTEM_ID\""),

   );
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(linenumber name dnsname));
   $self->setWorktable("\"IP_ADDRESSES\"");
   return($self);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"ewu2"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/ipaddress.jpg?".$cgi->query_string());
#}



sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  ""!".$self->T("CI-Status(6)","base::cistatus").""");
#   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}






sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}


1;

