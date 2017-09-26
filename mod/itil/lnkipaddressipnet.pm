package itil::lnkipaddressipnet;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
                name          =>'id',
                label         =>'RelID',
                searchable    =>0,
                dataobjattr   =>"concat(ipaddress.id,'-',ipnet.id)"),


      new kernel::Field::Text(
                name          =>'ipaddressid',
                label         =>'IP-Address ID',
                group         =>'ipaddress',
                dataobjattr   =>'ipaddress.id'),

      new kernel::Field::Text(
                name          =>'ipaddressname',
                label         =>'IP-Address',
                translation   =>'itil::ipaddress',
                weblinkto     =>'itil::ipaddress',
                weblinkon     =>['ipaddressid'=>'id'],
                group         =>'ipaddress',
                dataobjattr   =>'ipaddress.name'),

      new kernel::Field::Select(
                name          =>'ipaddresscistatus',
                htmleditwidth =>'60%',
                label         =>'IP-Address CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['ipaddresscistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'ipaddresscistatusid',
                label         =>'IP-Address CI-StateID',
                dataobjattr   =>'ipaddress.cistatus'),

                                                 
      new kernel::Field::Text(
                name          =>'ipnetid',
                label         =>'IP-Network ID',
                group         =>'ipnet',
                dataobjattr   =>'ipnet.id'),

      new kernel::Field::TextDrop(
                name          =>'ipnet',
                label         =>'IP-Network',
                vjointo       =>'itil::ipnet',
                vjoinon       =>['ipnetid'=>'id'],
                dataobjattr   =>'ipnet.name'),

      new kernel::Field::TextDrop(
                name          =>'ipnetname',
                htmlwidth     =>'350',
                label         =>'IP-Network Name',
                vjointo       =>'itil::ipnet',
                vjoinon       =>['ipnetid'=>'id'],
                dataobjattr   =>'ipnet.label'),

      new kernel::Field::Select(
                name          =>'ipnetcistatus',
                htmleditwidth =>'60%',
                label         =>'IP-Network CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['ipnetcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'ipnetcistatusid',
                label         =>'IP-Network CI-StateID',
                dataobjattr   =>'ipnet.cistatus'),

      new kernel::Field::Number(
                name          =>'activesubipnets',
                label         =>'active Sub-IP-Nets',
                translation   =>'itil::ipnet',
                readonly      =>1,
                uploadable    =>0,
                dataobjattr   =>"(select count(*) from ipnet subipnet ".
                                "where ipnet.network=subipnet.network ".
                                "and subipnet.binnamekey like ".
                                "ipnet.binnamekey ".
                                "and subipnet.cistatus=4 ".
                                "and ipnet.id<>subipnet.id)"),
      new kernel::Field::Text(
                name          =>'networkid',
                label         =>'Networkarea ID',
                group         =>'networkarea',
                dataobjattr   =>'network.id'),

      new kernel::Field::Text(
                name          =>'networkname',
                label         =>'Networkarea Name',
                group         =>'networkarea',
                weblinkto     =>'itil::network',
                weblinkon     =>['networkid'=>'id'],
                dataobjattr   =>'network.name'),

   );
   $self->setDefaultView(qw(ipaddressname ipnetname networkname));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="ipaddress join ipnet ".
            "on ipaddress.binnamekey like ipnet.binnamekey and ".
                "ipnet.network=ipaddress.network ".
            "join network on ".
            "ipaddress.network=network.id ";
   return($from);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_ipaddresscistatus"))){
     Query->Param("search_ipaddresscistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_ipnetcistatus"))){
     Query->Param("search_ipnetcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default misc softwareinstallation link source));
}







1;
