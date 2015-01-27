package tshpsa::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'ItemID',
                dataobjattr   =>"item_id"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Hostname',
                dataobjattr   =>'hostname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'primaryip',
                label         =>'primary IP',
                dataobjattr   =>'pip'),

      new kernel::Field::SubList(
                name          =>'sysgrps',
                label         =>'Groups',
                group         =>'sysgrps',
                vjointo       =>'tshpsa::lnksystemsysgrp',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>[qw(sysgrpname sysgrpid)]),

      new kernel::Field::SubList(
                name          =>'swis',
                label         =>'Software-Installations',
                group         =>'swis',
                vjointo       =>'tshpsa::lnkswi',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>[qw(class version iname)]),

      new kernel::Field::Text(
                name          =>'w5appl',
                label         =>'W5Base Applications',
                group         =>'w5basedata',
                searchable    =>0,
                weblinkto     =>'none',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>['applicationnames']),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'curdate'),

      new kernel::Field::Textarea(
                name          =>'rawscan',
                group         =>'source',
                label         =>'raw Scan-Data',
                dataobjattr   =>"
   (select ATTRIBUTE_SHORT_VALUE from SAS_SERVER_CUST_ATTRIBUTES 
   where SAS_SERVER_CUST_ATTRIBUTES.item_id=locicalsystem.item_id 
      and SAS_SERVER_CUST_ATTRIBUTES.ATTRIBUTE_NAME='TI.CSO_ao_mw_scanner'
      and (select DATE_DIMENSION.FULL_DATE_LOCAL curdate 
           from DATE_DIMENSION 
           where DATE_DIMENSION.FULL_DATE_LOCAL between SYSDATE-1 AND SYSDATE) 
        between SAS_SERVER_CUST_ATTRIBUTES.begin_date 
           and SAS_SERVER_CUST_ATTRIBUTES.end_date
      and ROWNUM<2)")

   );
   $self->setDefaultView(qw(name systemid primaryip mdate));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tshpsa"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;

(select system.item_id,
       ddim.curdate,
       lower(system.host_name) hostname,
       lower(system.display_name) name,
       system.primary_ip pip,
       attr_systemid.ATTRIBUTE_SHORT_VALUE systemid

from (select CMDB_DATA.DATE_DIMENSION.FULL_DATE_LOCAL curdate 
      from CMDB_DATA.DATE_DIMENSION 
      where CMDB_DATA.DATE_DIMENSION.FULL_DATE_LOCAL 
            between SYSDATE-1 AND SYSDATE)  ddim
     join CMDB_DATA.SAS_SERVERS system
          on ddim.curdate between system.begin_date and system.end_date
     join SAS_SERVER_CUST_ATTRIBUTES attr_systemid
          on ddim.curdate 
             between attr_systemid.begin_date and attr_systemid.end_date
             and system.item_id=attr_systemid.item_id
             and attr_systemid.ATTRIBUTE_NAME='ITM_Service_ID'
     join SAS_SERVERS_BASE base
          on system.item_id=base.item_id
     join SAS_SERVER_AGENT agent
          on system.item_id=agent.item_id
) locicalsystem
EOF

   return($from);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","swis","sysgrps","w5basedata","source");
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
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
