package article::productoptkpi;
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
   $self->{use_distinct}=0;
   $self->{UseSqlReplace}=1,

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                group         =>'source',
                searchable    =>0,
                readonly      =>1,
                wrdataobjattr =>'artprodoptkpi.id',
                dataobjattr   =>"if (artprodoptkpi.id is null,".
                                "concat(artproduct.id,'-',".
                                "artprodopttoken.token),artprodoptkpi.id)"),
                                                 
      new kernel::Field::TextDrop(
                name          =>'product',
                htmlwidth     =>'250px',
                label         =>'Product',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                vjointo       =>'article::product',
                vjoinon       =>['productid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'parentproduct',
                htmlwidth     =>'250px',
                readonly      =>1,
                label         =>'relevant standard Product',
                vjoineditbase =>{pvariant=>\'standard'},
                vjointo       =>'article::product',
                vjoinon       =>['parentproductid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'productid',
                readonly      =>1,
                label         =>'Delivery-ProductID',
                wrdataobjattr =>'artprodoptkpi.artproduct',
                dataobjattr   =>"artproduct.id"),

      new kernel::Field::Link(
                name          =>'parentproductid',
                readonly      =>1,
                label         =>'Delivery-ProductID',
                dataobjattr   =>'artprodopttoken.partproduct'),

      new kernel::Field::Text(
                name          =>'variant',
                readonly      =>1,
                label         =>'Variant',
                dataobjattr   =>'artproduct.variant'),

      new kernel::Field::Select(
                name          =>'slaquality',
                label         =>'SLA Quality',
                weblinkto     =>"none",
                vjointo       =>'article::kernkpi',
                vjoineditbase =>{
                   cistatusid=>\'4'
                },
                vjoinon       =>['token'=>'name'],
                vjoindisp     =>'displaylabel',
                htmlwidth     =>'150px',
                htmleditwidth =>'200px'),
      

      new kernel::Field::Link(
                name          =>'token',
                label         =>'SLA Quality token',
                dataobjattr   =>'artprodopttoken.token'),


      new kernel::Field::Interface(
                name          =>'kpiartproduct',
                searchable    =>0,
                label         =>'KPI token',
                dataobjattr   =>'artprodoptkpi.artproduct'),

      new kernel::Field::Interface(
                name          =>'kpipartproduct',
                searchable    =>0,
                label         =>'KPI pareent',
                dataobjattr   =>'artprodoptkpi.partproduct'),

      new kernel::Field::Interface(
                name          =>'kpitoken',
                searchable    =>0,
                label         =>'KPI token',
                dataobjattr   =>'artprodoptkpi.token'),

      new kernel::Field::Textarea(
                name          =>'description',
                searchable    =>0,
                label         =>'Description',
                dataobjattr   =>'artprodoptkpi.description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'artprodoptkpi.comments'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artprodoptkpi.modifyuser'),
                                   
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'artprodoptkpi.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artprodoptkpi.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artprodoptkpi.realeditor'),

   );
   $self->setDefaultView(qw(product delivelement cdate));
   $self->setWorktable("artprodoptkpi");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/artprodopttoken.jpg?".$cgi->query_string());
#}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="artproduct join ".
            "(select distinct partproduct,token ".
            " from artprodoptkpi) artprodopttoken ".
            "on (artproduct.variantof=artprodopttoken.partproduct or ".
            "    artproduct.id=artprodopttoken.partproduct) ".
            "left outer join artprodoptkpi on ".
            "artprodoptkpi.token=artprodopttoken.token and ".
            "artproduct.id=artprodoptkpi.artproduct";
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

   if (!defined($oldrec)){
      my $token=effVal($oldrec,$newrec,"token");
      if (!($token=~m/^[a-zA-Z0-9_]+$/)){
         $self->LastMsg(ERROR,"invalid token in itemizedlist");
         return(0);
      }
      my $productid=effVal($oldrec,$newrec,"productid");
      my $o=getModuleObject($self->Config,"article::product");
      $o->SetFilter({id=>\$productid});
      my ($prec,$msg)=$o->getOnlyFirst(qw(subparentid));
      if (defined($prec)){
         delete($newrec->{productid});
         $newrec->{kpipartproduct}=$prec->{subparentid};
         $newrec->{kpiartproduct}=$productid;
         $newrec->{kpitoken}=$token;
         $newrec->{id}=$productid."-".$token;
      }
   }
   else{
      my $id=effVal($oldrec,$newrec,"id");
      my ($productid,$token)=$id=~m/^(\d+)-(\S+)$/;
      if (exists($newrec->{token}) && $newrec->{token} ne $token){
         $self->LastMsg(ERROR,"token change not supported");
         return(0);
      }
      if (effVal($oldrec,$newrec,"kpitoken") eq ""){
         $newrec->{productid}=$productid;
         $newrec->{token}=$token;
         my $o=getModuleObject($self->Config,"article::product");
         $o->SetFilter({id=>\$productid});
         my ($prec,$msg)=$o->getOnlyFirst(qw(subparentid));
         if (defined($prec)){
            delete($newrec->{productid});
            $newrec->{kpipartproduct}=$prec->{subparentid};
            $newrec->{kpiartproduct}=$productid;
            $newrec->{kpitoken}=$token;
            $newrec->{id}=$productid."-".$token;
         }
      }
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   return("default");

}





1;
