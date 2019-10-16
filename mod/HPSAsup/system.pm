package HPSAsup::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                dataobjattr   =>"id",
                wrdataobjattr =>"systemid"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                lowersearch   =>1,
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Select(
                name          =>'dscope',
                label         =>'Scope State',
                value         =>['IN','OUT - no MW','OUT - SAP excl','OUT - other'],
                dataobjattr   =>'dscope'),

      new kernel::Field::Text(
                name          =>'chm',
                label         =>'Change triggered',
                weblinkto     =>'tssm::chm',
                weblinkon     =>['chm'=>'changenumber'],
                dataobjattr   =>'chm'),

      new kernel::Field::Boolean(
                name          =>'hpsafound',
                label         =>'HPSA found',
                readonly      =>1,
                dataobjattr   =>'hpsafnd'),

      new kernel::Field::Boolean(
                name          =>'scannerfound',
                label         =>'MW_Scanner found',
                readonly      =>1,
                dataobjattr   =>'scannerfnd'),

      new kernel::Field::Text(
                name          =>'w5osclass',
                readonly      =>1,
                ignorecase    =>1,
                translation   =>'itil::system',
                label         =>'OS-Class',
                dataobjattr   =>'osclass'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Text(
                name          =>'applications',
                group         =>'source',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4",applcistatusid=>"4"}],
                vjoindisp     =>'appl', 
                vjoinon       =>['systemid'=>'systemsystemid'],
                label         =>'Applications'),

     new kernel::Field::Text(
                name          =>'scopemode',
                searchable    =>1,
                htmldetail    =>0,
                group         =>'source',
                selectsearch  =>sub{
                   my $self=shift;
                   my @l=("11/2018-","2017-","-2016");
                   return(@l);
                },

                label         =>'Scope-Mode',
                dataobjattr   =>'scopemode'),

     new kernel::Field::Text(
                name          =>'applcustomerprio',
                searchable    =>1,
                htmldetail    =>0,
                label         =>'lowest application customerprio',
                dataobjattr   =>'applcustomerprio'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser')
   );
   $self->setWorktable("HPSAsup__system_of");
   $self->setDefaultView(qw(systemname systemid w5osclass 
                            hpsafound scannerfound comments));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="HPSAsup__system";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default tad4d w5basedata am source));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $effdscope=effVal($oldrec,$newrec,"dscope");
   if ($effdscope=~m/^OUT /){
      if (length(effVal($oldrec,$newrec,"comments"))<10){
         $self->LastMsg(ERROR,"setting out of scope needs meaningfu comments"); 
         return(undef);
      }
      if (effVal($oldrec,$newrec,"chm") ne ""){
         $newrec->{chm}=undef;
      }
   }
   if (effChanged($oldrec,$newrec,"chm") &&
       effVal($oldrec,$newrec,"chm") ne ""){
      if ((effVal($oldrec,$newrec,"scannerfound")==1)){
         $self->LastMsg(ERROR,"change number makes no sense - scanner exists"); 
         return(undef);
      }
      if (!(effVal($oldrec,$newrec,"chm")=~m/^C\d{5,15}/)){
         $self->LastMsg(ERROR,"change number seems not to be correct"); 
         return(undef);
      }
   }

   return(1);
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{systemid}};
   $newrec->{id}=$oldrec->{systemid};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_scannerfound"))){
     Query->Param("search_scannerfound"=>"\"".$self->T("boolean.false")."\"");
   }
   if (!defined(Query->Param("search_dscope"))){
     Query->Param("search_dscope"=>"IN");
   }
   if (!defined(Query->Param("search_applcustomerprio"))){
     Query->Param("search_applcustomerprio"=>"1");
   }
}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($self->isDirectFilter(@flt)){
      if (!exists($flt[0]->{scopemode})){
         $flt[0]->{scopemode}=\"11/2018-";
      }
   }
   return($self->SUPER::SetFilter(@flt));
}



#sub isViewValid
#{
#   my $self=shift;
#   my $rec=shift;
#
#   my @l=$self->SUPER::isViewValid($rec);
#
#   if (in_array(\@l,"ALL")){
#      if ($rec->{cenv} eq "Both"){
#         return(qw(header source am default));
#      }
#   }
#   return(@l);
#}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/));
   my @l=$self->SUPER::isWriteValid($rec,@_);

   return("default") if ($#l!=-1);
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
