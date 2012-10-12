package itil::custcontractcrono;
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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'custcontrcrono.id'),

      new kernel::Field::Text(
                name          =>'name',
                weblinkto     =>'itil::custcontract',
                weblinkon     =>['custcontractid'=>'id'],
                label         =>'Contructnumber',
                dataobjattr   =>'custcontrcrono.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Contract Name',
                dataobjattr   =>'custcontrcrono.fullname'),

      new kernel::Field::Text(
                name          =>'month',
                label         =>'Month',
                dataobjattr   =>'custcontrcrono.month'),

      new kernel::Field::Text(
                name          =>'applications',
                label         =>'active Applications',
                dataobjattr   =>'custcontrcrono.applications'),

      new kernel::Field::Link(
                name          =>'custcontractid',
                label         =>'CustomerContractID',
                dataobjattr   =>'custcontrcrono.custcontract'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Reporting Data',
                htmldetail    =>1,
                uivisible     =>1,
                dataobjattr   =>'custcontrcrono.additional'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'custcontrcrono.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'custcontrcrono.modifydate'),


   );

   $self->setDefaultView(qw(name month fullname mdate));
   $self->setWorktable("custcontrcrono");


   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_mdate"))){
     Query->Param("search_mdate"=>"currentmonth");
   }
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

   return();
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/contract.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default sem delmgmt modules
             applications contacts control misc attachments source));
}




1;
