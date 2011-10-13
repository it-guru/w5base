package TCOM::custappl;
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

# Migration:
# ==========
# delete from itcrmappl;
# insert into itcrmappl (id,name,origname,customerprio,customer,
#                        custapplid,description,comments,
#                        createdate,modifydate,createuser,modifyuser,
#                        editor,realeditor,srcsys,srcid,srcload,
#                        additional)
#  select id,name,origname,customerprio,customer,custapplid,
#         description,comments,createdate,modifydate,
#         createuser,modifyuser,editor,realeditor,srcsys,srcid,srcload,
#         concat(concat("wbvid='",ifnull(wbv,''),"'=wbvid\n"),
#                concat("itvid='",ifnull(itv,''),"'=itvid\n"),
#                concat("inmid='",ifnull(inm,''),"'=inmid\n"),
#                concat("ipplid='",ifnull(ippl,''),"'=ipplid\n")) as additional
# from TCOM_appl;
#

use strict;
use vars qw(@ISA);
use kernel;
use kernel::Field;
use itcrm::custappl;
@ISA=qw(itcrm::custappl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'wbv',
                searchable    =>0,
                group         =>'tcomcontact',
                label         =>'System Manager (WBV)',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['wbvid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'wbvid',
                group         =>'tcomcontact',
                dataobjattr   =>'itcrmappl.itmanager'),

      new kernel::Field::TextDrop(
                name          =>'ev',
                searchable    =>0,
                group         =>'tcomcontact',
                label         =>'EV Einführungsverantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['evid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'evid',
                group         =>'tcomcontact',
                container     =>'custadditional'),

      new kernel::Field::TextDrop(
                name          =>'itv',
                searchable    =>0,
                group         =>'tcomcontact',
                label         =>'ITV IT-Verantwortlicher',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['itvid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'itvid',
                group         =>'tcomcontact',
                container     =>'custadditional'),

      new kernel::Field::TextDrop(
                name          =>'inm',
                searchable    =>0,
                group         =>'tcomcontact',
                label         =>'INM Intergrationsmanager',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['inmid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'inmid',
                group         =>'tcomcontact',
                container     =>'custadditional'),

      new kernel::Field::TextDrop(
                name          =>'ippl',
                searchable    =>0,
                group         =>'tcomcontact',
                label         =>'IPPL IP Projektleiter',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['ipplid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(      
                name          =>'ipplid',
                group         =>'tcomcontact',
                container     =>'custadditional'),

   );
   $self->getField("itmanager")->{htmldetail}=0;
   $self->getField("itmanager")->{searchable}=0;
   $self->getField("businessowner")->{htmldetail}=0;
   $self->getField("businessowner")->{searchable}=0;

   return($self);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default custapplnameing 
          tcomcontact tscontact custcontracts));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isWriteValid($rec);
   if (grep(/^custapplnameing$/,@l)){
      push(@l,"tcomcontact");
   }
   return(@l);
}




















1;
