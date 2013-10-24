package article::lnkelementprod;
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
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkartelementprod.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'product',
                htmlwidth     =>'250px',
                label         =>'Product',
                vjointo       =>'article::product',
                vjoinon       =>['productid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'productid',
                label         =>'Delivery-ProductID',
                dataobjattr   =>'lnkartelementprod.artproduct'),


      new kernel::Field::TextDrop(
                name          =>'delivelement',
                htmlwidth     =>'250px',
                label         =>'Productelement',
                vjointo       =>'article::delivelement',
                vjoinon       =>['delivelementid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'delivelementid',
                label         =>'Delivery-ElementID',
                dataobjattr   =>'lnkartelementprod.artdelivelement'),


      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkartelementprod.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkartelementprod.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'lnkartelementprod.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkartelementprod.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkartelementprod.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkartelementprod.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkartelementprod.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkartelementprod.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'lnkartelementprod.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnkartelementprod.realeditor'),

   );
   $self->setDefaultView(qw(product delivelement cdate));
   $self->setWorktable("lnkartelementprod");
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
   my $from="lnkartelementprod ";
   return($from);
}

sub getDetailBlockPriority
{  
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default liccontractinfo source));
}







sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   return(1);
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


   return("default") if (!defined($oldrec));

   return(undef);
}





1;
