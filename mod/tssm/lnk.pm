package tssm::lnk;
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
use tssm::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'lnkid',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'LinkID',
                dataobjattr   =>'screlationm1.ROWID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'relation name',
                uppersearch   =>1,
                dataobjattr   =>"concat(screlationm1.source,".
                                "concat('-',screlationm1.depend))"),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'relation type',
                uppersearch   =>1,
                dataobjattr   =>"screlationm1.type"),

      new kernel::Field::MultiDst (
                name          =>'srcname',
                group         =>'src',
                label         =>'Source name',
                htmlwidth     =>'200',
                htmleditwidth =>'400',
                dst           =>['tssm::chm' =>'name',
                                 'tssm::inm'=>'name',
                                 'tsacinv::system'=>'systemname',
                                 'tsacinv::appl'=>'name',
                                 'tssm::prm'=>'name'],
                dsttypfield   =>'srcobj',
                dstidfield    =>'src'),

      new kernel::Field::Text(
                name          =>'src',
                group         =>'src',
                label         =>'Source-ID',
                uppersearch   =>1,
                dataobjattr   =>'screlationm1.source'),

      new kernel::Field::Text(
                name          =>'srcfilename',
                group         =>'src',
                label         =>'Source-filename',
                dataobjattr   =>'screlationm1.source_filename'),

      new kernel::Field::Text(
                name          =>'srcobj',
                group         =>'src',
                label         =>'Source-obj',
                dataobjattr   =>getObjDecode("screlationm1.source_filename")),

##      new kernel::Field::MultiDst (
##                name          =>'dstname',
##                group         =>'dst',
##                label         =>'Destination name',
##                htmlwidth     =>'200',
##                htmleditwidth =>'400',
##                dst           =>['tssm::chm' =>'name',
##                                 'tssm::inm'=>'name',
##                                 'tsacinv::system'=>'systemname',
##                                 'tsacinv::appl'=>'name',
##                                 'tssm::prm'=>'name'],
##                dsttypfield   =>'dstobj',
##                dstidfield    =>'dst'),

      new kernel::Field::Text(
                name          =>'dst',
                group         =>'dst',
                label         =>'Destination-ID',
                uppersearch   =>1,
                sqlorder      =>'NONE',
                dataobjattr   =>
                   "decode(substr(dbms_lob.substr(dh_desc,255,1),1,8),'org=TSI|',".
                   "reverse(".
                      "substr(substr(reverse(".
                         "dbms_lob.substr(screlationm1.dh_desc,255,1)".
                      "),2,20),1,".
                   "instr(substr(reverse(".
                      "dbms_lob.substr(screlationm1.dh_desc,255,1)".
                   "),2,20),'(')-1))  ".
                   ",screlationm1.depend)"),

      new kernel::Field::Text(
                name          =>'dstfilename',
                group         =>'dst',
                label         =>'Destination-filename',
                dataobjattr   =>'screlationm1.depend_filename'),

      new kernel::Field::Text(
                name          =>'dstobj',
                group         =>'dst',
                label         =>'Destination-obj',
                dataobjattr   =>getObjDecode("screlationm1.depend_filename")),

      new kernel::Field::Text(
                name          =>'dstmodel',
                group         =>'dst',
                selectfix     =>1,
                label         =>'Destination-Model',
                dataobjattr   =>'device2m1dstdev.model'),

##      new kernel::Field::Boolean(
##                name          =>'primary',
##                label         =>'Primary',
##                markempty     =>1,
##                dataobjattr   =>"decode(screlationm1.primary_ci,".
##                                "'true',1,'false',0,NULL)"),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'Modification-Date',
                dataobjattr   =>'screlationm1.sysmodtime'),

      new kernel::Field::Textarea(
                name          =>'rawdepend',
                label         =>'raw Depend',
                dataobjattr   =>'screlationm1.depend'),

      new kernel::Field::Textarea(
                name          =>'rawtype',
                label         =>'raw type',
                dataobjattr   =>'screlationm1.type'),

      new kernel::Field::Textarea(
                name          =>'rawdstmodel',
                label         =>'raw dstmodel',
                dataobjattr   =>'device2m1dstdev.model'),

#      new kernel::Field::Textarea(
#                name          =>'description',
#                label         =>'Description',
#                dataobjattr   =>'screlationm1.descprgn'),
   );
   
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(linenumber src dst sysmodtime));
   return($self);
}



sub getObjDecode
{
   my $varname=shift;
   return("decode($varname,".
      "'cm3r','tssm::chm',".
      "'problem','tssm::prm',".
      "'incidents','tssm::inm',".
      "'device',".
       "decode(device2m1dstdev.model,'APPLICATION','tsacinv::appl',".
       "decode(device2m1dstdev.model,'LOGICAL SYSTEM','tsacinv::system',".
       "decode(substr(depend,0,4),'APPL','tsacinv::appl',".
       "decode(substr(depend,0,3),'GER','tsacinv::appl',".
       "decode(substr(depend,0,1),'A','tsacinv::asset',".
       "decode(substr(depend,0,1),'S','tsacinv::system',".
         "decode(instr(depend,'|cit=amTsiCustAppl|'),0,".
         "decode(instr(depend,'|cit=amPortfolio|'),0,NULL,".
         "'tsacinv::system'),'tsacinv::appl')".
       ")))))))");
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(src dst status));
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


sub getSqlFrom
{
   my $self=shift;
   my $from="dh_screlationm1 screlationm1,dh_device2m1 device2m1dstdev";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="screlationm1.depend=device2m1dstdev.id(+)";
   return($where);
}


1;
