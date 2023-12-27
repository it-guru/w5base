package tssapp01::costcenter;
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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'"tssapp01::costcenter".w5id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                nowrap        =>1,
                label         =>'CostCenter',
                dataobjattr   =>'"tssapp01::costcenter".w5name'),

      new kernel::Field::Text(
                name          =>'accarea',
                label         =>'Accounting Area',
                dataobjattr   =>'"tssapp01::costcenter".w5accarea'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'"tssapp01::costcenter".w5description'),

      new kernel::Field::Link(
                name          =>'etype',
                label         =>'Type',
                dataobjattr   =>'"tssapp01::costcenter".w5etype'),

      new kernel::Field::TextDrop(
                name          =>'responsible',
                group         =>'contacts',
                label         =>'costcenter responsible EMail',
                vjointo       =>'tsciam::user',
                vjoinon       =>['responsiblewiw'=>'wiwid'],
                vjoindisp     =>'email'),

      new kernel::Field::Text(
                name          =>'responsiblewiw',
                group         =>'contacts',
                label         =>'costcenter responsible WIW ID',
                dataobjattr   =>'"tssapp01::costcenter".w5responsiblewiw'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP hierarchy',
                group         =>'saphier',
                ignorecase    =>1,
                dataobjattr   =>'saphier'),

      new kernel::Field::Text(
                name          =>'saphier1',
                label         =>'SAP hierarchy 1',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier1'),

      new kernel::Field::Text(
                name          =>'saphier2',
                label         =>'SAP hierarchy 2',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier2'),

      new kernel::Field::Text(
                name          =>'saphier3',
                label         =>'SAP hierarchy 3',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier3'),

      new kernel::Field::Text(
                name          =>'saphier1',
                label         =>'SAP hierarchy 4',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier4'),

      new kernel::Field::Text(
                name          =>'saphier5',
                label         =>'SAP hierarchy 5',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier5'),

      new kernel::Field::Text(
                name          =>'saphier6',
                label         =>'SAP hierarchy 6',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier6'),

      new kernel::Field::Text(
                name          =>'saphier7',
                label         =>'SAP hierarchy 7',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier7'),

      new kernel::Field::Text(
                name          =>'saphier8',
                label         =>'SAP hierarchy 8',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier8'),

      new kernel::Field::Text(
                name          =>'saphier9',
                label         =>'SAP hierarchy 9',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier9'),

      new kernel::Field::Text(
                name          =>'saphier10',
                label         =>'SAP hierarchy 10',
                group         =>'saphier',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"tssapp01::costcenter".saphier10'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'"tssapp01::costcenter".w5createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'"tssapp01::costcenter".w5modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"\"tssapp01::costcenter\".w5modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(\"tssapp01::costcenter\".w5id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"tssapp01::costcenter".w5srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"tssapp01::costcenter".w5srcid'),

   );
   $self->setDefaultView(qw(name description cdate mdate));
   $self->setWorktable("\"tssapp01::costcenter\"");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   return($self);
}

sub getSAPhierSQL
{
   my $tab=shift;
   $tab="\"tssapp01::costcenter\"" if ($tab eq "");
   my $saphierfield;
   for(my $c=1;$c<=10;$c++){
      $saphierfield.="||'.'||" if ($saphierfield ne "");
      $saphierfield.="decode(${tab}.saphier${c},NULL,'-',${tab}.saphier${c})";
   }
   $saphierfield="($saphierfield)";
   return($saphierfield);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

  # $newrec->{etype}='PSP';

   return(1);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default contacts saphier source));
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


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportCostCenter));
}


sub ImportCostCenter
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"costcenter has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"CostCenter Import");
   print $self->getParsedTemplate("tmpl/minitool.costcenter.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $import=$param->{importname};
   $import=trim($import);
   $import=~s/[\*\?]//g;  # prevent wildcards
   if ($import eq ""){
      $self->LastMsg(ERROR,"please specify a valid costcenter or PSP");
      return();
   }
   my @import=split(/[,;\s]+/,$import);
   if ($#import>3){
      $self->LastMsg(ERROR,"too many import elements specified");
      return();
   }
   my $co=getModuleObject($self->Config,"TS::costcenter");

   my $allok=1;
   foreach my $chk (@import){
      if (!$co->ValidateCONumber($self->Self,
           "conumber",undef,{conumber=>$chk})){
         $chk=limitlen($chk,15,1);
         $self->LastMsg(ERROR,
            "the element '%s' seems not to be acceptable for this database",
            $chk);
         $allok=0;
      }
   }
   return() if (!$allok);

   my @irec;
   my $allok=1;
   my $sappsp=getModuleObject($self->Config,"tssapp01::psp");
   my $sapcos=getModuleObject($self->Config,"tssapp01::costcenter");
   foreach my $chk (@import){
      next if ($chk eq "");
      $co->ResetFilter();
      $co->SetFilter({name=>$chk});
      my ($oldrec)=$co->getOnlyFirst(qw(id));
      if (defined($oldrec)){
         $self->LastMsg(WARN,"'%s' already exists - ignoring it",$chk);
      }
      else{
         $sappsp->ResetFilter();
         $sappsp->SetFilter({name=>$chk});
         my ($saprec)=$sappsp->getOnlyFirst(qw(ALL));
         if (defined($saprec)){
            my $newrec={name=>$saprec->{name},
                        costcentertype=>'pspelement',
                        cistatusid=>4,
                        srcsys=>$sappsp->Self,
                        srcid=>$saprec->{id}};
            if ($saprec->{accarea} ne ""){
               $newrec->{accarea}=$saprec->{accarea};
            }
            if ($saprec->{description} ne ""){
               $newrec->{shortdesc}=$saprec->{description};
            }
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
            $newrec->{allowifupdate}=1;
            push(@irec,$newrec);
         } 
         else{
            $sapcos->ResetFilter();
            my $altchk=sprintf("%d %010d",$chk,$chk);
            $sapcos->SetFilter({name=>$altchk});
            my ($saprec)=$sapcos->getOnlyFirst(qw(ALL));
            if (defined($saprec)){
               my $newrec={name=>$saprec->{name},
                           costcentertype=>'costcenter',
                           cistatusid=>4,
                           srcsys=>$sapcos->Self,
                           srcid=>$saprec->{id}};
               if ($saprec->{accarea} ne ""){
                  $newrec->{accarea}=$saprec->{accarea};
               }
               if ($saprec->{description} ne ""){
                  $newrec->{shortdesc}=$saprec->{description};
               }
               my $userid=$self->getCurrentUserId();
               $newrec->{databossid}=$userid;
               $newrec->{allowifupdate}=1;
               push(@irec,$newrec);
            }
            else{
               $self->LastMsg(ERROR,"can not find '%s' in SAP P01",$chk);
               $allok=0;
            }
         }
      }
   }
   return() if (!$allok);

   my @iid;
   foreach my $irec (@irec){
      my $identifyby=$co->ValidatedInsertRecord($irec);
      if (defined($identifyby) && $identifyby!=0){
         $co->ResetFilter();
         $co->SetFilter({'id'=>\$identifyby});
         my ($rec,$msg)=$co->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            my $qc=getModuleObject($self->Config,"base::qrule");
            $qc->setParent($co);
            $qc->nativQualityCheck($co->getQualityCheckCompat($rec),$rec);
            push(@iid,$identifyby);

            $self->LastMsg(INFO,"costcenter '%s' successfuly imported",
                                $rec->{name});
         }
      }
   }
   return(@iid);
}








1;
