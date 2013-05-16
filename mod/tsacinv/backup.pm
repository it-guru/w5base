package tsacinv::backup;
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
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'BackupID',
                htmldetail    =>0,
                align         =>'left',
                dataobjattr   =>'amtsibackup.lbackupid'),

      new kernel::Field::Text(
                name          =>'backupid',
                label         =>'BackupID',
                dataobjattr   =>'amtsibackup.code'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'amtsibackup.backupservice'),

      new kernel::Field::Text(
                name          =>'bgroup',
                label         =>'Group',
                dataobjattr   =>'amtsibackup.groupname'),

      new kernel::Field::Text(
                name          =>'hexpectedquantity',
                label         =>'expectedquantity',
                dataobjattr   =>"concat(amtsibackup.expectedquantity,".
                                "concat(' ',amtsibackup.quantityunit))"),

      new kernel::Field::Boolean(
                name          =>'isactive',
                label         =>'Active',
                dataobjattr   =>'amtsibackup.bactive'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'Computerid',
                dataobjattr   =>'amtsibackup.lcomputerid'),

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
   my $from="amtsibackup";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amtsibackup.bdelete=0 ";
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
