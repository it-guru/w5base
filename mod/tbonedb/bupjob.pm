package tbonedb::bupjob;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use tbonedb::lib::Listedit;
@ISA=qw(tbonedb::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'bupid',
                label         =>'BUP',
                weblinkto     =>\'tbonedb::bupjob',
                weblinkon     =>['bupid'=>'bupid'],
                uppersearch   =>1,
                dataobjattr   =>'BUP'),

      new kernel::Field::Text(
                name          =>'systemid',
                uppersearch   =>1,
                label         =>'SystemID',
                dataobjattr   =>'SYSTEMID'),

      new kernel::Field::Text(
                name          =>'systemname',
                uppersearch   =>1,
                label         =>'Systemname',
                dataobjattr   =>'(select HOSTNAME from v_bupdetails_31d '.
                                'where ROWNUM<2 AND '.
                                'v_bupdetails_31d.POSCHECK_BUPID=BUP)'),

      new kernel::Field::Text(
                name          =>'service',
                label         =>'Service',
                caseignore    =>1,
                dataobjattr   =>'SERVICE'),

      new kernel::Field::Text(
                name          =>'retention',
                label         =>'Retention',
                caseignore    =>1,
                dataobjattr   =>'RETENTION'),

      new kernel::Field::Number(
                name          =>'quantity',
                label         =>'Quantity',
                caseignore    =>1,
                unit          =>'GB',
                dataobjattr   =>'QUANTITY'),


      new kernel::Field::Boolean(
                name          =>'isactive',
                label         =>'Active',
                dataobjattr   =>'ACTIVE'),

      new kernel::Field::Boolean(
                name          =>'isdeleted',
                label         =>'is deleted',
                dataobjattr   =>'DELETED'),

      new kernel::Field::Text(
                name          =>'policy',
                label         =>'Policy',
                dataobjattr   =>'POLICY'),

      new kernel::Field::Text(
                name          =>'retention',
                label         =>'Retention',
                dataobjattr   =>'RETENTION'),

      new kernel::Field::Text(
                name          =>'dbtype',
                label         =>'DB-Type',
                dataobjattr   =>'DBTYPE'),

      new kernel::Field::SubList(
                name          =>'lastjobs',
                label         =>'Last-Jobs',
                group         =>'lastjobs',
                htmllimit     =>15,
                vjointo       =>\'tbonedb::bupstat',
                vjoinon       =>['bupid'=>'bupid'],
                vjoindisp     =>['bupid','checkdate','exitstate','exittext']),


      new kernel::Field::Text(
                name          =>'w5applications',
                label         =>'W5Base/Application',
                group         =>'w5basedata',
                vjointo       =>\'itil::lnkapplsystem',
                vjoinslimit   =>'1000',
                vjoinon       =>['systemid'=>'systemsystemid'],
                weblinkto     =>'none',
                vjoindisp     =>'appl'),
   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(bupid systemid systemname service 
                            retention quantity isactive));
   $self->setWorktable("BUPJOB");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tbone"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_isdeleted"))){
     Query->Param("search_isdeleted"=>$self->T("no"));
   }
   if (!defined(Query->Param("search_isactive"))){
     Query->Param("search_isactive"=>$self->T("yes"));
   }
}




sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="V_IBR_AM_BACKUPS BUPJOB " ;


   return($from);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
