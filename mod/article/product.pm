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
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
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
                searchable    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artproduct.frontlabel'),

      new kernel::Field::Textarea(
                name          =>'frontlabel',
                label         =>'Product designation',
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
                name          =>'pdetaillevel',
                label         =>'Product detail level',
                selectfix     =>1,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                htmleditwidth =>'100px',
                value         =>['max'],
                selectfix     =>1,
                dataobjattr   =>'artproduct.detaillevel'),

      new kernel::Field::Text(
                name          =>'pvariant',
                label         =>'Product variant',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1);
                   }
                   return(0);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current) && 
                                 $current->{pvariant} eq "standard");
                   return(0);
                },
                selectfix     =>1,
                dataobjattr   =>'artproduct.variant'),

      new kernel::Field::TextDrop(
                name          =>'variantof',
                label         =>'variant of',
                depend        =>['variantofid'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      if (defined($param{current}->{variantofid})){
                         return(1);
                      }
                   }
                   return(0);
                },
                vjointo       =>'article::product',
                vjoinon       =>['variantofid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'variantofid',
                label         =>'VariantOf-Id',
                dataobjattr   =>'artproduct.variantof'),

      new kernel::Field::TextDrop(
                name          =>'catalog',
                label         =>'Catalog',
                readonly      =>1,
                vjointo       =>'article::catalog',
                vjoinon       =>['catalogid'=>'id'],
                vjoineditbase =>{cistatusid=>"<=5"},
                vjoindisp     =>'fullname'),


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
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      if (defined($param{current}->{variantofid})){
                         if ($param{current}->{variantofid} ne 
                             $param{current}->{id}){
                            return(0);
                         }
                      }
                   }
                   return(1);
                },
                searchable    =>0,
                htmleditwidth =>'40px',
                precision     =>0,
                dataobjattr   =>'artproduct.posno1'),

      new kernel::Field::Select(
                name          =>'category2',
                label         =>'alt Category',
                allowempty    =>1,
                vjointo       =>'article::category',
                vjoinon       =>['category2id'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'category2id',
                label         =>'alt CategoryID',
                dataobjattr   =>'artproduct.artcategory2'),

      new kernel::Field::TextDrop(
                name          =>'delivprovider',
                label         =>'Provider',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjointo       =>'article::delivprovider',
                vjoinon       =>['delivproviderid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'delivproviderid',
                dataobjattr   =>'artproduct.delivprovider'),

      new kernel::Field::Textarea(
                name          =>'description',
                group         =>'desc',
                htmlheight    =>350,
                label         =>'Description',
                dataobjattr   =>'artproduct.description'),

      new kernel::Field::Textarea(
                name          =>'variantdescription',
                group         =>'variantspecials',
                label         =>'variant specials',
                dataobjattr   =>'artproduct.variantdesc'),

      new kernel::Field::Textarea(
                name          =>'custoblig',
                group         =>'custoblig',
                label         =>'Customer obligations',
                dataobjattr   =>'artproduct.custoblig'),

      new kernel::Field::Textarea(
                name          =>'premises',
                group         =>'custoblig',
                label         =>'Premises',
                dataobjattr   =>'artproduct.premises'),

      new kernel::Field::Textarea(
                name          =>'rest',
                group         =>'custoblig',
                label         =>'Restrictions',
                dataobjattr   =>'artproduct.rest'),

      new kernel::Field::Textarea(
                name          =>'exclusions',
                group         =>'custoblig',
                label         =>'Exclusions',
                dataobjattr   =>'artproduct.exclusions'),

      new kernel::Field::Textarea(
                name          =>'pod',
                group         =>'pod',
                label         =>'Point of delivery',
                dataobjattr   =>'artproduct.pod'),

      new kernel::Field::Textarea(
                name          =>'specialarr',
                group         =>'specialarr',
                label         =>'Specific agreements',
                dataobjattr   =>'artproduct.specialarr'),

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

      new kernel::Field::TextDrop(
                name          =>'delivprovidergroup',
                label         =>'Provider groupname',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'base::grp',
                vjoinon       =>['delivprovidergrpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'delivprovidergrpid',
                group         =>'mgmt',
                readonly      =>1,
                dataobjattr   =>'artdelivprovider.grpid'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                group         =>'mgmt',
                default       =>'4',
                vjoineditbase =>{id=>[qw(1 4 5 6)]},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'mgmt',
                label         =>'CI-StateID',
                dataobjattr   =>'artproduct.pstatus'),

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

      new kernel::Field::File(
                name          =>'logo_small',
                label         =>'logo_small',
                content       =>'image/jpg',
                searchable    =>0,
                group         =>'mgmtlogosmall',
                uploadable    =>0,
                dataobjattr   =>'artproduct.logo_small'),

      new kernel::Field::File(
                name          =>'logo_large',
                label         =>'logo_large',
                content       =>'image/jpg',
                searchable    =>0,
                group         =>'mgmtlogolarge',
                uploadable    =>0,
                dataobjattr   =>'artproduct.logo_large'),



      new kernel::Field::Textarea(
                name          =>'pricerulesmodals',
                group         =>'price',
                label         =>'Commercial Rules/Modalities',
                dataobjattr   =>'artproduct.price_rulesmodals'),

      new kernel::Field::Currency(
                name          =>'priceonce',
                label         =>'price once',
                depend        =>['pricecurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{pricecurrency} ne ""){
                      return($current->{pricecurrency});
                   }
                   return();
                },
                precision     =>4,
                minprecision  =>2,
                width         =>'50',
                group         =>'price',
                dataobjattr   =>'artproduct.price_once'),

      new kernel::Field::Currency(
                name          =>'priceday',
                label         =>'price day',
                depend        =>['pricecurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{pricecurrency} ne ""){
                      return($current->{pricecurrency});
                   }
                   return();
                },
                precision     =>4,
                minprecision  =>2,
                width         =>'50',
                group         =>'price',
                dataobjattr   =>'artproduct.price_day'),

      new kernel::Field::Currency(
                name          =>'pricemonth',
                label         =>'price month',
                depend        =>['pricecurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{pricecurrency} ne ""){
                      return($current->{pricecurrency});
                   }
                   return();
                },
                precision     =>4,
                minprecision  =>2,
                width         =>'50',
                group         =>'price',
                dataobjattr   =>'artproduct.price_month'),

      new kernel::Field::Currency(
                name          =>'priceyear',
                width         =>'50',
                precision     =>4,
                minprecision  =>2,
                label         =>'price year',
                depend        =>['pricecurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{pricecurrency} ne ""){
                      return($current->{pricecurrency});
                   }
                   return();
                },
                group         =>'price',
                dataobjattr   =>'artproduct.price_year'),

      new kernel::Field::Currency(
                name          =>'priceperuse',
                label         =>'price peruse',
                depend        =>['pricecurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{pricecurrency} ne ""){
                      return($current->{pricecurrency});
                   }
                   return();
                },
                precision     =>4,
                minprecision  =>2,
                width         =>'50',
                group         =>'price',
                dataobjattr   =>'artproduct.price_peruse'),

      new kernel::Field::Select(
                name          =>'pricecurrencysel',
                label         =>'currency label',
                vjointo       =>'base::isocurrency',
                vjoinon       =>['pricecurrency'=>'token'],
                vjoindisp     =>'fullname',
                group         =>'price'),

      new kernel::Field::Text(
                name          =>'pricecurrency',
                htmldetail    =>0,
                uploadable    =>0,
                default       =>'EUR',
                label         =>'currency',
                group         =>'price',
                dataobjattr   =>'artproduct.price_currency'),

      new kernel::Field::Text(
                name          =>'priceprodunit',
                label         =>'unit of quantity',
                group         =>'price',
                dataobjattr   =>'artproduct.price_produnit'),

      new kernel::Field::Select(
                name          =>'pricebillinterval',
                label         =>'Invoicing frequency',
                value         =>['PERMONTH','PERYEAR'],
                group         =>'price',
                dataobjattr   =>'artproduct.price_billinterval'),

      new kernel::Field::Textarea(
                name          =>'pricestepping',
                group         =>'price',
                label         =>'Step pricing',
                dataobjattr   =>'artproduct.price_stepping'),


      new kernel::Field::Textarea(
                name          =>'pricerulesmodals',
                group         =>'price',
                label         =>'Commercial Rules/Modalities',
                dataobjattr   =>'artproduct.price_rulesmodals'),



      new kernel::Field::Currency(
                name          =>'costonce',
                label         =>'cost once',
                precision     =>4,
                minprecision  =>2,
                depend        =>['pricecurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{costcurrency} ne ""){
                      return($current->{costcurrency});
                   }
                   return();
                },
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_once'),

      new kernel::Field::Currency(
                name          =>'costday',
                label         =>'cost day',
                precision     =>4,
                minprecision  =>2,
                depend        =>['costcurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{costcurrency} ne ""){
                      return($current->{costcurrency});
                   }
                   return();
                },
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_day'),

      new kernel::Field::Currency(
                name          =>'costmonth',
                label         =>'cost month',
                precision     =>4,
                minprecision  =>2,
                depend        =>['costcurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{costcurrency} ne ""){
                      return($current->{costcurrency});
                   }
                   return();
                },
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_month'),

      new kernel::Field::Currency(
                name          =>'costyear',
                depend        =>['costcurrency'],
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{costcurrency} ne ""){
                      return($current->{costcurrency});
                   }
                   return();
                },
                width         =>'50',
                label         =>'cost year',
                precision     =>4,
                minprecision  =>2,
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_year'),

      new kernel::Field::Currency(
                name          =>'costperuse',
                label         =>'cost peruse',
                depend        =>['costcurrency'],
                precision     =>4,
                minprecision  =>2,
                unit          =>'',
                unit          =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $current=shift;
                   if ($current->{costcurrency} ne ""){
                      return($current->{costcurrency});
                   }
                   return();
                },
                width         =>'50',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_peruse'),

      new kernel::Field::Select(
                name          =>'costcurrencysel',
                label         =>'currency label (cost)',
                vjointo       =>'base::isocurrency',
                vjoinon       =>['costcurrency'=>'token'],
                vjoindisp     =>'fullname',
                group         =>'cost'),

      new kernel::Field::Text(
                name          =>'costcurrency',
                htmldetail    =>0,
                uploadable    =>0,
                default       =>'EUR',
                label         =>'currency (cost)',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_currency'),

      new kernel::Field::Text(
                name          =>'costprodunit',
                label         =>'unit of quantity (cost)',
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_produnit'),

      new kernel::Field::Select(
                name          =>'costbillinterval',
                label         =>'Invoicing frequency (cost)',
                value         =>['PERMONTH','PERYEAR'],
                group         =>'cost',
                dataobjattr   =>'artproduct.cost_billinterval'),

      new kernel::Field::Textarea(
                name          =>'coststepping',
                group         =>'cost',
                label         =>'Step pricing (cost)',
                dataobjattr   =>'artproduct.cost_stepping'),

      new kernel::Field::Link(
                name          =>'subparentid',
                label         =>'id for all sub elements/products',
                readonly      =>1,
                dataobjattr   =>'if (artproduct.variantof is null,'.
                                'artproduct.id,artproduct.variantof)'),

      new kernel::Field::SubList(
                name          =>'subproducts',
                label         =>'Subproducts',
                group         =>'subproducts',
                vjointo       =>'article::lnkprodprod',
                vjoinon       =>['subparentid'=>'pproductid'],
                vjoindisp     =>['product']),

      new kernel::Field::SubList(
                name          =>'response',
                label         =>'Responsibility-Matrix',
                group         =>'response',
                vjointo       =>'article::productoptresponse',
                vjoinon       =>['subparentid'=>'parentproductid'],
                vjoindisp     =>['name','description','response','frequency']),

      new kernel::Field::SubList(
                name          =>'variants',
                label         =>'Variants',
                group         =>'variants',
                vjointo       =>'article::product',
                vjoinon       =>['id'=>'variantofid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::SubList(
                name          =>'slaqualities',
                label         =>'SLA/Qualities',
                group         =>'slaqualities',
                vjointo       =>'article::productoptkpi',
                vjoinon       =>['id'=>'productid'],
                vjoindisp     =>['slaquality','description']),

      new kernel::Field::SubList(
                name          =>'modalities',
                label         =>'Modalities',
                group         =>'modalities',
                vjointo       =>'article::productoptmodal',
                vjoinon       =>['id'=>'productid'],
                vjoindisp     =>['modality','description']),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'mgmt',
                label         =>'Comments',
                dataobjattr   =>'artproduct.comments'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'article::product',
                group         =>'attachments'),

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

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'databossid',
                noselect      =>'1',
                dataobjattr   =>'artcatalog.databoss'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                noselect      =>'1',
                dataobjattr   =>'artcatalog.mandator'),
                                  
      new kernel::Field::Link(
                name          =>'catalogid',
                dataobjattr   =>'artcatalog.id')
                                  
   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(category1  
                            fullname description cdate));
   $self->setWorktable("artproduct");
   return($self);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.article.admin)],"RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RODManager RODManager2 
                                         RODOperator
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles* *roles=?order?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles* *roles=?order?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
            {mandatorid=>\@mandators},
            {databossid=>\$userid}
         );
      }
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/article/load/product.jpg?".$cgi->query_string());
}


sub getSqlFrom
{
   my $self=shift;
   my $from="artproduct ".
      "left outer join artcategory on artproduct.artcategory1=artcategory.id ".
      "left outer join artcatalog on artcategory.artcatalog=artcatalog.id ".
      "left outer join artdelivprovider on ".
      "artproduct.delivprovider=artdelivprovider.id ".
      "left outer join lnkcontact on lnkcontact.parentobj='article::catalog' ".
      "and artcategory.id=lnkcontact.refid";
   return($from);
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","desc","response","variants","variantspecials",
          "custoblig","pod","price","modalities","cost","specialarr","mgmt",
          "subproducts","slaqualities",
          "mgmtlogosmall","mgmtlogolarge","attachments","source");
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;
   return(0) if (!defined($rec));
   if ($rec->{variantofid} ne ""){
      return(0);
   }
   if ($rec->{pclass} ne "bundle"){
      return(0);
   }
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   if (!$bak){
      my $id=effVal($oldrec,$newrec,"id");
      my $p=$self;
      $self->ResetFilter();
      $p->SetFilter({variantofid=>\$id});
      my @l=$p->getHashList(qw(ALL));
      if ($#l!=-1){
         $p->ResetFilter();
         foreach my $subrec (@l){
            my $id=$subrec->{id};
            $p->ValidatedUpdateRecordTransactionless(
                   $subrec,{mdate=>NowStamp("en")},{id=>\$id});
         }
      }
   }
   return($bak);
}








sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec) && $newrec->{pvariant} eq ""){
      $newrec->{pvariant}="standard";
   }

   my $productmgrid=effVal($oldrec,$newrec,"productmgrid");
   if ($productmgrid eq "" || $productmgrid==0){
      my $userid=$self->getCurrentUserId();
      $newrec->{productmgrid}=$userid;
   }




   my $pvariant=effVal($oldrec,$newrec,"pvariant");
   if ($pvariant ne "" &&
       !($pvariant=~m/^[A-Z0-9_]+$/i)){
      $self->LastMsg(ERROR,"invalid characters in variant name");
      return(undef);
   }
   my $variantofid=effVal($oldrec,$newrec,"variantofid");
   if ($variantofid ne ""){
      if (effVal($oldrec,$newrec,"pvariant") eq "standard"){
         $self->LastMsg(ERROR,"variant standard is not allowed if ".
                              "product is a variant of an other ones");
         return(undef);
      }
      my $p=getModuleObject($self->Config,"article::product");
      $p->SetFilter({id=>\$variantofid});
      my ($prec,$msg)=$p->getOnlyFirst(qw(ALL));
      # Werte die immer vom "Parent" übernommen werden
      foreach my $pfld (qw(category1id frontlabel pclass description
                           delivproviderid pdetaillevel specialarr
                           custoblig premises rest exclusions pod)){
         if (!defined($oldrec) ||
             $oldrec->{$pfld} ne $prec->{$pfld}){
            $newrec->{$pfld}=$prec->{$pfld};
         }
      }
      if (!defined($oldrec)){
         # Werte die nur Initial vom Parent übernommen werden
         foreach my $pfld (qw(productmgrid)){
            if (!defined($oldrec) ||
                $oldrec->{$pfld} ne $prec->{$pfld}){
               $newrec->{$pfld}=$prec->{$pfld};
            }
         }
      }
   }
   else{
      if (defined($oldrec->{variantofid})){
         $newrec->{variantofid}=undef;
      }
      my $posno1=effVal($oldrec,$newrec,"posno1");
      if ($posno1 eq ""){
         my $category1id=effVal($oldrec,$newrec,"category1id");
         my $o=getModuleObject($self->Config,"article::product");
         $o->SetFilter({category1id=>\$category1id});
         my %i;
         foreach my $rec ($o->getHashList(qw(id posno1))){
            $i{$rec->{posno1}}=$rec->{id};
         } 
         my $nextfree=0;
         while(defined($i{++$nextfree})){}
         $newrec->{posno1}=$nextfree;
      }
   }

   my $delivproviderid=effVal($oldrec,$newrec,"delivproviderid");
   if ($delivproviderid eq "" || $delivproviderid==0){
      $self->LastMsg(ERROR,"no provider specified");
      return(undef);
   }

   my $orderable_to=effVal($oldrec,$newrec,"orderable_to");
   my $orderable_from=effVal($oldrec,$newrec,"orderable_from");
   if ($orderable_to ne "" && $orderable_from ne ""){
      my $duration=CalcDateDuration($orderable_from,$orderable_to);
      if ($duration->{totalseconds}<0){
         $self->LastMsg(ERROR,
                        "orderable to can not be sooner as orderable from");
         my $srcid=effVal($oldrec,$newrec,"srcid");
         msg(ERROR,"totalseconds=$duration->{totalseconds} ".
                   "start=$orderable_from end=$orderable_to srcid=$srcid");
         return(0);
      }
   }

   my %checkcategories;
   if (!defined($oldrec)){
      if (!defined($newrec->{productmgrid}) ||
          $newrec->{productmgrid} eq ""){
         my $userid=$self->getCurrentUserId();
         $newrec->{productmgrid}=$userid;
      }
      if ($newrec->{category1id} eq ""){
         $self->LastMsg(ERROR,"missing primary category");
         return(0);
      }
      else{
         $checkcategories{$newrec->{category1id}}++;
      }
   }
   my $category1id=effVal($oldrec,$newrec,"category1id");
   $checkcategories{$category1id}++ if ($category1id ne "");

   my $cat=getModuleObject($self->Config,"article::category");
   my $c=getModuleObject($self->Config,"article::catalog");
   my @checkcategories=keys(%checkcategories);
   if ($#checkcategories==-1){
      $self->LastMsg(ERROR,"missing categories");
      return(0);
   }
   my $wrok=$#checkcategories;
   foreach my $categoryid (@checkcategories){
      $cat->ResetFilter();
      $cat->SetFilter({id=>\$categoryid});
      my $catalogid=$cat->getVal("catalogid");
      if ($catalogid ne ""){
         if (!$c->isCatalogWriteValid($catalogid)){
            $wrok--;
         }
      }
   }
   if ($wrok!=0){
      $self->LastMsg(ERROR,"no nesassary write access to category");
      return(0);
   }






   if (exists($newrec->{logo_small})){   # laden des small Logos
      if ($newrec->{logo_small} ne ""){
         no strict;
         my $f=$newrec->{logo_small};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>100240){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{logo_small}=$pic;
      }
      else{
         $newrec->{logo_small}=undef;
      }
   }

   if (exists($newrec->{logo_large})){   # laden des small Logos
      if ($newrec->{logo_large} ne ""){
         no strict;
         my $f=$newrec->{logo_large};
         seek($f,0,SEEK_SET);
         my $pic;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $pic.=$buffer;
            $size+=$bytesread;
            if ($size>100240){
               $self->LastMsg(ERROR,"picure to large");
               return(0);
            }
         }
         $newrec->{logo_large}=$pic;
      }
      else{
         $newrec->{logo_large}=undef;
      }
   }


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
   return("default","desc","custoblig","pod","mgmt") if (!defined($rec));
   my @l=("header","default","history","mgmt","desc","custoblig","pod",
          "mgmtlogosmall","mgmtlogolarge","attachments","slaqualities",
          "modalities","response","specialarr",
          "cost","price","source");
   if ($rec->{pvariant} eq "standard"){
      push(@l,"variants");
   }
   else{
      push(@l,"variantspecials");
   }
   push(@l,"subproducts") if ($rec->{pclass} eq "bundle");
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default","desc","custoblig","pod","mgmt") if (!defined($rec));

   my @wrgroups=qw(default desc custoblig pod mgmt mgmtlogosmall 
                   mgmtlogolarge attachments slaqualities response
                   modalities specialarr);

   if (defined($rec) && $rec->{variantofid}){
      @wrgroups=grep(!/^(default|desc|custoblig|specialarr|pod|response)$/,@wrgroups);
   }

   push(@wrgroups,"cost","price") if (defined($rec));

   if (defined($rec) && $rec->{pvariant} eq "standard"){
      push(@wrgroups,"variants");
   }
   else{
      push(@wrgroups,"variantspecials");
   }
   push(@wrgroups,"subproducts") if ($rec->{pclass} eq "bundle" &&
                                     $rec->{pvariant} eq "standard");

   return(@wrgroups) if (!defined($rec));

   my $catalogid=$rec->{catalogid};
   if ($catalogid ne ""){
      my $c=getModuleObject($self->Config,"article::catalog");
      if ($c->isCatalogWriteValid($catalogid)){
         return(@wrgroups);
      }
   }




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
      my $id=$self->getParent->getField("id");
      my $id_attr=$id->getBackendName($mode,$db);
      my $name=$self->getParent->getField("name");
      my $name_attr=$name->getBackendName($mode,$db);
      my $pclass=$self->getParent->getField("pclass");
      my $pclass_attr=$pclass->getBackendName($mode,$db);
      my $pvariant=$self->getParent->getField("pvariant");
      my $pvariant_attr=$pvariant->getBackendName($mode,$db);

      my $f="concat(trim(cast($id_attr as char(20))),\": \"".
            ",$pclass_attr,\" - \",".
            "$name_attr,\": \",$pvariant_attr)";

      return($f);
   }
   return($self->SUPER::getBackendName($mode,$db));
}







1;
