package article::product;
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
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                sqlorder      =>'none',
                group         =>'source',
                dataobjattr   =>'artproduct.id'),

      new article::product::Field::Text(
                name          =>'fullname',
                label         =>'full Productname',
                htmldetail    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Productname',
                htmldetail    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Textarea(
                name          =>'frontlabel',
                label         =>'Product label',
                htmlheight    =>50,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Select(
                name          =>'pclass',
                label         =>'Product class',
                selectfix     =>1,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                htmleditwidth =>'100px',
                value         =>['simple','bundle'],
                dataobjattr   =>'artproduct.pclass'),

      new kernel::Field::Select(
                name          =>'pvariant',
                label         =>'Product variant',
                selectfix     =>1,
                htmleditwidth =>'100px',
                value         =>['standard','high','medium','low'],
                dataobjattr   =>'artproduct.variant'),

      new kernel::Field::Select(
                name          =>'category1',
                label         =>'Category',
                vjointo       =>'article::category',
                vjoinon       =>['category1id'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'category1id',
                label         =>'CategoryID',
                dataobjattr   =>'artproduct.artcategory1'),

      new kernel::Field::Number(
                name          =>'posno1',
                label         =>'Position Number',
                width         =>'1%',
                searchable    =>0,
                htmleditwidth =>'40px',
                precision     =>0,
                dataobjattr   =>'artproduct.posno1'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'artproduct.description'),

      new kernel::Field::Contact(
                name          =>'productmgr',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'mgmt',
                label         =>'Product Manager',
                vjoinon       =>'productmgrid'),

      new kernel::Field::Link(
                name          =>'productmgrid',
                group         =>'mgmt',
                dataobjattr   =>'artproduct.productmgr'),

      new kernel::Field::Date(
                name          =>'orderable_from',
                group         =>'mgmt',
                label         =>'orderable from',
                dataobjattr   =>'artproduct.orderable_from'),

      new kernel::Field::Date(
                name          =>'orderable_to',
                label         =>'orderable to',
                group         =>'mgmt',
                dataobjattr   =>'artproduct.orderable_to'),

      new kernel::Field::Number(
                name          =>'costonce',
                label         =>'cost once',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_once'),

      new kernel::Field::Number(
                name          =>'costday',
                label         =>'cost day',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_day'),

      new kernel::Field::Number(
                name          =>'costmonth',
                label         =>'cost month',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_month'),

      new kernel::Field::Number(
                name          =>'costyear',
                precision     =>2,
                width         =>'50',
                label         =>'cost year',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_year'),

      new kernel::Field::Number(
                name          =>'costperuse',
                label         =>'cost peruse',
                precision     =>2,
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_peruse'),

      new kernel::Field::Text(
                name          =>'produnit',
                label         =>'product unit',
                group         =>'cost',
                dataobjattr   =>'artproduct.produnit'),

      new kernel::Field::Select(
                name          =>'billinterval',
                label         =>'bill interval',
                value         =>['PERMONTH','PERYEAR'],
                group         =>'cost',
                dataobjattr   =>'artproduct.billinterval'),

      new kernel::Field::SubList(
                name          =>'directproductelements',
                label         =>'direct Productelements',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{pclass} eq "simple");
                   }
                   return(0);
                },
                group         =>'productelements',
                vjointo       =>'article::lnkelementprod',
                vjoinon       =>['id'=>'productid'],
                vjoindisp     =>['delivelement']),

      new kernel::Field::SubList(
                name          =>'allproductelements',
                label         =>'all Productelements',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1) if ($param{current}->{pclass} eq "bundle");
                   }
                   return(0);
                },
                group         =>'productelements',
                vjointo       =>'article::lnkelement',
                vjoinon       =>['id'=>'productid'],
                vjoindisp     =>['delivelement']),

      new kernel::Field::SubList(
                name          =>'subproducts',
                label         =>'Subproducts',
                group         =>'subproducts',
                vjointo       =>'article::lnkprodprod',
                vjoinon       =>['id'=>'pproductid'],
                vjoindisp     =>['product']),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'mgmt',
                label         =>'Comments',
                dataobjattr   =>'artproduct.comments'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'artproduct.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'artproduct.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'artproduct.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'artproduct.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'artproduct.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artproduct.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artproduct.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artproduct.realeditor'),


                                  
   );
   $self->setDefaultView(qw(category1  
                            fullname description cdate));
   $self->setWorktable("artproduct");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","cost","mgmt","subproducts",
          "productelements","source");
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;
   return(0) if (!defined($rec));
   return(1);
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=effVal($oldrec,$newrec,"frontlabel");
   if ($name=~m/^\s$/){
      $self->LastMsg(ERROR,"invalid name '\%s' specified",
                     $name);
      return(undef);
   }
   return(1);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","mgmt") if (!defined($rec));
   my @l=("header","default","mgmt","productelements","source");
   push(@l,"subproducts") if ($rec->{pclass} eq "bundle");
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgroups=qw(default mgmt);

   push(@wrgroups,"cost") if (defined($rec));

   return(@wrgroups) if ($self->IsMemberOf(["admin"]));
   return(undef);
}


package article::product::Field::Text;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::Field;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   return($self);
}

sub getBackendName
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   if (($mode=~m/^where/) || $mode eq "select"){
      my $name=$self->getParent->getField("name");
      my $name_attr=$name->getBackendName($mode,$db);
      my $pclass=$self->getParent->getField("pclass");
      my $pclass_attr=$pclass->getBackendName($mode,$db);
      my $pvariant=$self->getParent->getField("pvariant");
      my $pvariant_attr=$pvariant->getBackendName($mode,$db);

      my $f="concat($pclass_attr,\" - \",$name_attr,\": \",$pvariant_attr)";

      return($f);
   }
   return($self->SUPER::getBackendName($mode,$db));
}







1;
