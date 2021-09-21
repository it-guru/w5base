package itil::lnkipnetipnet;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>"concat(ipnet.id,'-',ipnet.id)"),


      new kernel::Field::Text(
                name          =>'ipnetid',
                label         =>'Child IP-Net ID',
                group         =>'ipaddress',
                dataobjattr   =>'ipnet.id'),

      new kernel::Field::Text(
                name          =>'ipnet',
                label         =>'IP-Net',
                translation   =>'itil::ipnet',
                weblinkto     =>'itil::ipnet',
                weblinkon     =>['ipnetid'=>'id'],
                group         =>'ipaddress',
                dataobjattr   =>'ipnet.name'),

      new kernel::Field::Select(
                name          =>'pipnetcistatus',
                htmleditwidth =>'60%',
                label         =>'parent IP-Net CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['pipnetcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'pipnetcistatusid',
                label         =>'parent IP-Net CI-StateID',
                dataobjattr   =>'pipnet.cistatus'),

                                                 
      new kernel::Field::Text(
                name          =>'pipnetid',
                label         =>'Parent IP-Network ID',
                group         =>'ipnet',
                dataobjattr   =>'pipnet.id'),

      new kernel::Field::TextDrop(
                name          =>'pipnet',
                label         =>'parent IP-Network',
                htmlwidth     =>'100px',
                vjointo       =>'itil::ipnet',
                vjoinon       =>['pipnetid'=>'id'],
                dataobjattr   =>'pipnet.name'),

      new kernel::Field::TextDrop(
                name          =>'pipnetname',
                htmlwidth     =>'350',
                label         =>'parent IP-Network Name',
                vjointo       =>'itil::ipnet',
                vjoinon       =>['pipnetid'=>'id'],
                dataobjattr   =>'pipnet.label'),

      new kernel::Field::Number(
                name          =>'phostbitcount',
                label         =>'Host bit count',
                group         =>'status',
                dataobjattr   =>"length(".
                                 "replace(".
                                  "replace(pipnet.binnamekey,'1',''),'0',''))"),

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
   $self->setDefaultView(qw(ipnet pipnet networkname));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $from="ipnet join ipnet as pipnet ".
            "on ipnet.binnamekey like pipnet.binnamekey and ".
                "ipnet.network=pipnet.network and ".
                "ipnet.id<>pipnet.id ".
            "join network on ".
            "ipnet.network=network.id ";
   return($from);
}


sub initSqlOrder
{
   return("length(replace(replace(pipnet.binnamekey,'1',''),'0',''))");
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
   return(qw(header default source));
}







1;
