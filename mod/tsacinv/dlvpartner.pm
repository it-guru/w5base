package tsacinv::dlvpartner;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                sqlorder      =>'desc',
                label         =>'ID',
                dataobjattr   =>'amtsidlvpartner.ldeliverypartnerid'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'CostCenter-No.',
                translation   =>'tsacinv::costcenter',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['name'=>'name'],
                dataobjattr   =>'amcostcenter.trimmedtitle'),

      new kernel::Field::TextDrop(
                name          =>'deliverymanagement',
                label         =>'Delivery Management',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['ldeliverymanagementid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'ldeliverymanagementid',
                dataobjattr   =>'amtsidlvpartner.ldeliverymanagementid'),

      new kernel::Field::Text(
                name          =>'description',
                htmlwidth     =>'150px',
                label         =>'Description',
                ignorecase    =>1,
                dataobjattr   =>'amtsidlvpartner.description'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                label         =>'Operational Delivery Manager',
                htmlwidth     =>'150px',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['delmgrid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgrid',
                dataobjattr   =>'amtsidlvpartner.ldeliverymanagerid'),

      new kernel::Field::TextDrop(
                name          =>'delmgr2',
                label         =>'Deputy Operational Delivery Manager',
                vjointo       =>'tsacinv::user',
                vjoinon       =>['delmgr2id'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                dataobjattr   =>'amtsidlvpartner.ldeputydeliverymanagerid'),


      new kernel::Field::Link(
                name          =>'lcommentid',
                dataobjattr   =>'amtsidlvpartner.lcommentid'),
      
      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                vjointo       =>'tsacinv::comment', 
                vjoinon       =>['lcommentid'=>'lcommentid'],
                vjoindisp     =>'comments'),

      new kernel::Field::Date(
                name          =>'mdate',
                sqlorder      =>'NONE',
                label         =>'Modification-Date',
                dataobjattr   =>'amtsidlvpartner.dtlastmodif')
   );
   $self->setDefaultView(qw(linenumber name description mdate));
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

sub getSqlFrom
{
   my $self=shift;
   my $from="amtsidlvpartner,amcostcenter";
   return($from);
}  

sub initSqlWhere
{
   my $self=shift;
   my $where="amtsidlvpartner.lcostcenterid=amcostcenter.lcostid and ".
             "amcostcenter.bdelete=0 and amtsidlvpartner.bdelete=0";
   return($where);
}







sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if (!defined($rec));
   return(undef);
}





1;
