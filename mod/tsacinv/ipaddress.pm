package tsacinv::ipaddress;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'NetworkCardID',
                align         =>'left',
                dataobjattr   =>'amnetworkcard.lnetworkcardid'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'IP-Address',
                uivisible     =>0,
                depend        =>['ipaddress'],
                onRawValue    =>sub{   # compress IPV6 Adresses
                   my $self=shift;
                   my $current=shift;
                   my $d=$current->{ipaddress};
                      $d=~s/0000:/0:/g;
                      $d=~s/:0000/:0/g;
                      $d=~s/(:)0+?([a-f1-9])/$1$2/gi;
                      $d=~s/^0+?([a-f1-9])/$1$2/gi;
                      $d=~s/:0:/::/gi;
                      $d=~s/:0:/::/gi;
                      $d=~s/:::::/:0:0:0:0:/gi;
                      $d=~s/::::/:0:0:0:/gi;
                      $d=~s/:::/:0:0:/gi;
                   return($d);
                }),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP-Address',
                searchable    =>0,
                dataobjattr   =>"amnetworkcard.tcpipaddress|| ".
                                "decode(amnetworkcard.tcpipaddress,NULL,'',".
                                "decode(amnetworkcard.ipv6address,NULL,'',".
                                "', ')) ||amnetworkcard.ipv6address"),

      new kernel::Field::Text(
                name          =>'ipv4address',
                label         =>'IP-V4-Address',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'amnetworkcard.tcpipaddress'),

      new kernel::Field::Text(
                name          =>'ipv6address',
                label         =>'IP-V6-Address',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'amnetworkcard.ipv6address'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemId',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['systemid'=>'systemid'],
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'amportfolio.name'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'amnetworkcard.status'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                dataobjattr   =>'amnetworkcard.code'),

      new kernel::Field::Text(
                name          =>'netmask',
                label         =>'Netmask',
                dataobjattr   =>'amnetworkcard.subnetmask'),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS-Name',
                dataobjattr   =>'amnetworkcard.dnsname'),

      new kernel::Field::Text(
                name          =>'dnsalias',
                label         =>'DNS-Alias',
                dataobjattr   =>'amnetworkcard.dnsalias'),

      new kernel::Field::Text(
                name          =>'accountno',
                label         =>'Account Number',
                group         =>'finance',
                vjointo       =>'tsacinv::accountno',
                vjoinon       =>['laccountnoid'=>'id'],
                vjoindisp     =>'name',
                uppersearch   =>1),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Type',
                ignorecase    =>1,
                dataobjattr   =>'amnetworkcard.type'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'amnetworkcard.description'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'Computerid',
                dataobjattr   =>'amnetworkcard.lcompid'),

      new kernel::Field::Link(
                name          =>'laccountnoid',
                label         =>'AccountNoID',
                dataobjattr   =>'amnetworkcard.laccountnoid'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'amnetworkcard.dtlastmodif'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(amnetworkcard.lnetworkcardid,35,'0')")
   );
   $self->setDefaultView(qw(linenumber systemid 
                            systemname ipaddress status description));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/service.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="amnetworkcard,amcomputer,".
            "(select amportfolio.* from amportfolio ".
            " where amportfolio.bdelete=0) amportfolio";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amcomputer.lcomputerid=amnetworkcard.lcompid ".
       "and amportfolio.lportfolioitemid=amcomputer.litemid ".
       "and amnetworkcard.bdelete=0 ".
       "and amnetworkcard.status<>'out of service' ";
   return($where);
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
