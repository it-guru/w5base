package article::lnkelement;
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
                label         =>'ProductelementID',
                searchable    =>0,
                dataobjattr   =>'artdelivelement.id'),
                                                 
      new kernel::Field::Interface(
                name          =>'productid',
                label         =>'Delivery-ProductID',
                dataobjattr   =>'artproduct.id'),


      new kernel::Field::TextDrop(
                name          =>'delivelement',
                htmlwidth     =>'250px',
                label         =>'Productelement',
                vjointo       =>'article::delivelement',
                vjoinon       =>['id'=>'id'],
                vjoindisp     =>'fullname'),
   );
   $self->setDefaultView(qw(product delivelement cdate));
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkartelementprod.jpg?".$cgi->query_string());
#}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="artproduct ".
            "left outer join lnkartelementprod ".
            "on lnkartelementprod.artproduct=artproduct.id ".
            "left outer join lnkartprodprod ".
            "on lnkartprodprod.partproduct=artproduct.id ".
            "left outer join artproduct as subproduct ".
            "on lnkartprodprod.artproduct=subproduct.id  ".
            "left outer join lnkartelementprod as sublnkartelementprod ".
            "on sublnkartelementprod.artproduct=subproduct.id,".
            "artdelivelement";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="(artdelivelement.id=sublnkartelementprod.artdelivelement or ".
              "artdelivelement.id=lnkartelementprod.artdelivelement)";
   return($where);
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
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return("default");

   return(undef);
}





1;
