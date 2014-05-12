package tshpsa::lnksystemsysgrp;
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
                name          =>'sysgrpid',
                label         =>'system group id',
                dataobjattr   =>'srcid'),

      new kernel::Field::Text(
                name          =>'sysgrpname',
                label         =>'system group name',
                htmlwith      =>'300',
                nowrap        =>1,
                dataobjattr   =>'srcname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'systemid',
                dataobjattr   =>'dstid'),
   );
   $self->setDefaultView(qw(srcid dstid mdate));
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

(

select memb.item_id,
       memb.item_source_id srcid,
       memb.server_item_id dstid,
       grp.group_name      srcname,
       memb.latest_flag is_latest
from (select DATE_DIMENSION.FULL_DATE_LOCAL curdate 
      from DATE_DIMENSION 
      where DATE_DIMENSION.FULL_DATE_LOCAL between SYSDATE-1 AND SYSDATE)  ddim
      join SAS_SERVER_GROUP_MEMBERS memb 
          on ddim.curdate between memb.begin_date and memb.end_date
      join SAS_SERVER_GROUPS grp 
          on ddim.curdate between grp.begin_date and grp.end_date
             and memb.item_source_id=grp.item_id
) lnksystemsysgrp

EOF

   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="lnksystemsysgrp.is_latest=1";
   return($where);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","w5baselocation");
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
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
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
