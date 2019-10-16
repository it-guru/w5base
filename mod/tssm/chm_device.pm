package tssm::chm_device;
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
                label         =>'No.'),

      new kernel::Field::Id(        
                name          =>'lnkid',
                label         =>'LnkID',
                htmldetail    =>0,
                dataobjattr   =>SELpref."cm3ra10.dh_number || '-' || ".
                                SELpref."cm3ra10.record_number"),

      new kernel::Field::Link(        
                name          =>'src',
                label         =>'Change No.',
                align         =>'left',
                dataobjattr   =>SELpref.'cm3ra10.dh_number'),

      new kernel::Field::Text(        
                name          =>'changenumber',
                label         =>'Change No.',
                weblinkto     =>'tssm::chm',
                weblinkon     =>['changenumber'=>'changenumber'],
                align         =>'left',
                dataobjattr   =>SELpref.'cm3ra10.dh_number'),

      new kernel::Field::Link(
                name          =>'fullname',
                group         =>'dst',
                label         =>'Name',
                uppersearch   =>1,
                dataobjattr   =>"(".SELpref.'cm3ra10.dh_number'."||'-'||".
                                  SELpref."device2m1.ci_name)"),

      new kernel::Field::Text(
                name          =>'descname',
                group         =>'dst',
                label         =>'Name',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'cm3ra10.tsi_ci_name'),

      new kernel::Field::Boolean(
                name          =>'civalid',
                group         =>'dst',
                label         =>'Valid',
                translation   =>'tssm::lnk',
                nowrap        =>1,
                dataobjattr   =>
                  "decode(".SELpref."device2m1.ci_name,NULL,0,1)"
                ),

     new kernel::Field::Text(
                name          =>'dstsmid',
                group         =>'dst',
                label         =>'Destination-SMID',
                dataobjattr   =>SELpref."device2m1.logical_name"),

     new kernel::Field::Text(
                name          =>'dstcriticality',
                group         =>'dst',
                label         =>'Criticality',
                dataobjattr   =>"lower(".SELpref.
                                "device2m1.tsi_business_criticality)"),

     new kernel::Field::Text(
                name          =>'dststatus',
                group         =>'dst',
                label         =>'Status',
                nowrap        =>1,
                dataobjattr   =>"lower(".SELpref.
                                "device2m1.istatus)"),

     new kernel::Field::Text(
                name          =>'dstmodel',
                group         =>'dst',
                label         =>'Destination-Model',
                dataobjattr   =>SELpref."device2m1.type"),

     new kernel::Field::Text(
                name          =>'dstname',
                group         =>'amdst',
                label         =>'Destination Name',
                dataobjattr   =>SELpref."device2m1.title"),

     new kernel::Field::Text(
                name          =>'dstobj',
                group         =>'amdst',
                label         =>'Destination-AMObj',
                dataobjattr   =>getAMObjDecode( SELpref."device2m1.type")),

     new kernel::Field::MultiDst (
                name          =>'dstamname',
                group         =>'amdst',
                label         =>'Destination-AMName',
                altnamestore  =>'dstraw',
                htmlwidth     =>'200',
                dst           =>[
                                 'tsacinv::system'=>'fullname',
                                 'tsacinv::appl'=>'fullname',
                                 'tsacinv::asset'=>'fullname',
                                ],
                dsttypfield   =>'dstobj',
                dstidfield    =>'dstid'),

     new kernel::Field::Link(
                name          =>'dstraw',
                group         =>'amdst',
                label         =>'Destination-AM Name',
                dataobjattr   =>SELpref."device2m1.title"),

     new kernel::Field::Text(
                name          =>'dstid',
                group         =>'amdst',
                label         =>'Destination-AMID',
                dataobjattr   =>SELpref."device2m1.id"),


      new kernel::Field::MDate(
                name         =>'mdate',
                label        =>'Modification-Date',
                uppersearch  =>1,
                dataobjattr  =>SELpref.'cm3ra10.sysmodtime'),
   );
   $self->{use_distinct}=0;


   $self->setDefaultView(qw(linenumber changenumber name civalid 
                            dstmodel dstobj mdate));
   return($self);
}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default dst amdst source));
}


sub isQualityCheckValid
{
   return(0);
}


sub getAMObjDecode
{
   my $depend=shift;

   return(
          "decode($depend,".
               "'application','tsacinv::appl',".
               "'computer','tsacinv::system',".
               "'networkcomponents','tsacinv::system',".
               "'generic','tsacinv::asset',".
               "'runningsoftware','tsacinv::swinstance',".
               "NULL)"
       );
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."cm3ra10 ".SELpref."cm3ra10 ".
         "left outer join ".TABpref."device2m1 ".SELpref."device2m1 ".
         "on ".SELpref."cm3ra10.tsi_ci_name=".SELpref."device2m1.ci_name";
   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="not ".SELpref."cm3ra10.tsi_ci_name is null";
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
