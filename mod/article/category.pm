package article::category;
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
                group         =>'source',
                sqlorder      =>'none',
                dataobjattr   =>'artcategory.id'),

      new article::category::Field::Text(
                name          =>'fullname',
                label         =>'full Category',
                htmldetail    =>0,
                ignorecase    =>1,
                readonly      =>1),

      new kernel::Field::Text(
                name          =>'categorie',
                label         =>'Category',
                htmldetail    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artcategory.frontlabel'),

      new kernel::Field::Text(
                name          =>'multilangcatalog',
                label         =>'Catalog',
                uivisible     =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artcatalog.frontlabel'),

      new kernel::Field::Select(
                name          =>'catalog',
                htmleditwidth =>'40%',
                label         =>'Catalog',
                allowempty    =>1,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                jsonchanged   =>"
                    if (mode=='onchange'){
                       document.forms[0].submit();
                    }
                ",
                vjointo       =>'article::catalog',
                vjoinon       =>['catalogid'=>'id'],
                vjoineditbase =>{cistatusid=>"<=5"},
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'catalogid',
                label         =>'Catalog-ID',
                dataobjattr   =>'artcategory.artcatalog'),

      new kernel::Field::Select(
                name          =>'pcategory',
                htmleditwidth =>'40%',
                label         =>'parent Category',
                allowempty    =>1,
                vjointo       =>'article::category',
                vjoinon       =>['pcategoryid'=>'id'],
                vjoineditbase =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $flt={id=>undef};
                   my $i=Query->Param("Formated_catalog");
                   if ($i ne ""){
                      $flt={catalogid=>\$i};
                   }
                   else{
                      my $i=$current->{catalogid};
                      if ($i ne ""){
                         $flt={catalogid=>\$i,id=>"!".$current->{id}};
                      }
                   }
                   return($flt);
                },
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'pcategoryid',
                label         =>'pCategory-ID',
                dataobjattr   =>'artcategory.partcategory'),

      new kernel::Field::Link(
                name          =>'chkpcategoryid',
                label         =>'pCategory-ID',
                dataobjattr   =>'artcategory.chkpartcategory'),

      new kernel::Field::Text(
                name          =>'outlineno',
                label         =>'Outline Number',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'cast(if (p5.id is not null,"[LevelDepthError]",if (p1.id is null,artcategory.posno,'.
                                'if(p2.id is null,concat(p1.posno,".",'.
                                'artcategory.posno),if(p3.id is null,'.
                                'concat(p2.posno,".",p1.posno,".",'.
                                'artcategory.posno),if(p4.id is null,'.
                                'concat(p3.posno,".",p2.posno,".",p1.posno,"."'.
                                ',artcategory.posno),concat(p4.posno,".",'.
                                'p3.posno,".",p2.posno,".",p1.posno,".",'.
                                'artcategory.posno)))))) as char(20))'),

#      new kernel::Field::Text(
#                name          =>'outlineno2',
#                label         =>'Outline Number2',
#                htmldetail    =>0,
#                readonly      =>1,
#          dataobjattr   =>"concat(".
#          ")"),

      new kernel::Field::Number(
                name          =>'posno',
                label         =>'Position Number',
                searchable    =>0,
                precision     =>0,
                dataobjattr   =>'artcategory.posno'),

      new kernel::Field::Textarea(
                name          =>'frontlabel',
                label         =>'Category label',
                htmlheight    =>50,
                dataobjattr   =>'artcategory.frontlabel'),

      new kernel::Field::SubList(
                name          =>'products',
                label         =>'Products',
                group         =>'products',
                vjointo       =>'article::product',
                vjoinon       =>['id'=>'category1id'],
                vjoindisp     =>['fullname']),

      new kernel::Field::SubList(
                name          =>'subcategories',
                label         =>'Subcategories',
                group         =>'subcategories',
                vjointo       =>'article::category',
                vjoinon       =>['id'=>'pcategoryid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'artcategory.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'artcategory.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'artcategory.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'artcategory.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'artcategory.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artcategory.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artcategory.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artcategory.realeditor'),

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

   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(catalog fullname name cdate));
   $self->setWorktable("artcategory");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/article/load/category.jpg?".$cgi->query_string());
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


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","subcategories","products","source");
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift;
   return(0) if (!defined($rec));
   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();

   my $from="$worktable ".
      "left outer join artcategory as p1 on artcategory.partcategory=p1.id ".
      "left outer join artcategory as p2 on p1.partcategory=p2.id ".
      "left outer join artcategory as p3 on p2.partcategory=p3.id ".
      "left outer join artcategory as p4 on p3.partcategory=p4.id ".
      "left outer join artcategory as p5 on p4.partcategory=p5.id ".
      "left outer join artcatalog on artcategory.artcatalog=artcatalog.id ".
      "left outer join lnkcontact on lnkcontact.parentobj='article::catalog' ".
      "and artcategory.id=lnkcontact.refid";
   return($from);
}


sub initSqlOrder
{
   my $self=shift;
   return("artcategory.artcatalog,".
          "if (p5.id is not null,0,1)",
          "if (isnull(p4.posno),if (isnull(p3.posno),if (isnull(p2.posno),if (isnull(p1.posno),if (isnull(artcategory.posno),0,artcategory.posno),p1.posno),p2.posno),p3.posno),p4.posno),".
          "if (isnull(p4.posno),if (isnull(p3.posno),if (isnull(p2.posno),if (isnull(p1.posno),0,artcategory.posno),p1.posno),p2.posno),p3.posno),".
          "if (isnull(p4.posno),if (isnull(p3.posno),if (isnull(p2.posno),if (isnull(p1.posno),0,0),artcategory.posno),p1.posno),p2.posno),".
          "if (isnull(p4.posno),if (isnull(p3.posno),if (isnull(p2.posno),if (isnull(p1.posno),0,0),0),artcategory.posno),p1.posno),".
          "if (isnull(p4.posno),if (isnull(p3.posno),if (isnull(p2.posno),if (isnull(p1.posno),0,0),0),0),artcategory.posno)");
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $name=effVal($oldrec,$newrec,"frontlabel");
   if ($name eq ""){
      $self->LastMsg(ERROR,"invalid name '\%s' specified",
                     $name);
      return(undef);
   }
   if (exists($newrec->{pcategoryid})){
      if ($newrec->{pcategoryid} eq ""){
         $newrec->{pcategoryid}=undef;
         $newrec->{chkpcategoryid}=0;
      }
      else{
         $newrec->{chkpcategoryid}=$newrec->{pcategoryid};
      }
   }
   if (effVal($oldrec,$newrec,"posno") eq "0"){
      $self->LastMsg(ERROR,"position number 0 is not allowed");
      return(0);
   }
   if (defined($oldrec)){ # check write on old category
      my $cid=$oldrec->{catalogid};
      my $c=getModuleObject($self->Config,"article::catalog");
      if (!$c->isCatalogWriteValid($cid)){
         $self->LastMsg(ERROR,"you have no right to modify this category");
         return(0);
      }
   }
   if (defined($newrec)){ # check on modifikation of a record
      my $cid=effVal($oldrec,$newrec,"catalogid");
      my $c=getModuleObject($self->Config,"article::catalog");
      if ($cid eq "" || !$c->isCatalogWriteValid($cid)){
         $self->LastMsg(ERROR,"you have no right to write in given catalog");
         return(0);
      }
   }
   
   return(1);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));

   my $cid=$rec->{catalogid};
   my $c=getModuleObject($self->Config,"article::catalog");
   if ($c->isCatalogWriteValid($cid)){
      return("default");
   }
   
   return(undef);
}


package article::category::Field::Text;
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
      my $outlineno=$self->getParent->getField("outlineno");
      my $outlineno_attr=$outlineno->getBackendName($mode,$db);
      my $categorie=$self->getParent->getField("categorie");
      my $categorie_attr=$categorie->getBackendName($mode,$db);
      my $multilangcatalog=$self->getParent->getField("multilangcatalog");
      my $multilangcatalog_attr=$multilangcatalog->getBackendName($mode,$db);

      my $f="concat($multilangcatalog_attr,\": \",".
            "$outlineno_attr,\" \",$categorie_attr)";

      return($f);
   }
   return($self->SUPER::getBackendName($mode,$db));
}





1;
