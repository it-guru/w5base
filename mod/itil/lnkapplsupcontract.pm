package itil::lnkapplsupcontract;
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
use kernel::Field;
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>'lnkapplsupcontract.id'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'relation fullname',
                dataobjattr   =>'concat(appl.name," - ",'.
                                'supcontract.name," (ID:",'.
                                'lnkapplsupcontract.id,")")'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                htmlwidth     =>'300px',
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'applcistatus',
                htmleditwidth =>'40%',
                readonly      =>1,
                group         =>'relation',
                label         =>'Application CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['applcistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::TextDrop(
                name          =>'supcontract',
                htmlwidth     =>'130px',
                label         =>'Support Contract',
                vjointo       =>'itil::supcontract',
                vjoinon       =>['supcontractid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'supcontractcistatus',
                htmleditwidth =>'40%',
                htmlwidth     =>'160px',
                readonly      =>1,
                group         =>'relation',
                label         =>'Support Contract CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['supcontractcistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                dataobjattr   =>'lnkapplsupcontract.fraction'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplsupcontract.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplsupcontract.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplsupcontract.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplsupcontract.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkapplsupcontract.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplsupcontract.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplsupcontract.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplsupcontract.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplsupcontract.realeditor'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'supcontractcistatusid',
                label         =>'CustContractCiStatusID',
                dataobjattr   =>'supcontract.cistatus'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Text(
                name          =>'applcustomer',
                label         =>'Application Support',
                readonly      =>1,
                group         =>'relation',
                dataobjattr   =>'applcustgrp.fullname'),

      new kernel::Field::Link(
                name          =>'supcontractname',
                label         =>'CustContractName',
                dataobjattr   =>'supcontract.fullname'),

      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'lnkapplsupcontract.appl'),

      new kernel::Field::Interface(
                name          =>'supcontractid',
                htmlwidth     =>'150px',
                label         =>'Support ContractId',
                dataobjattr   =>'lnkapplsupcontract.supcontract'),
   );
   $self->setDefaultView(qw(id appl supcontract cdate editor));
   $self->setWorktable("lnkapplsupcontract");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_supcontractcistatus"))){
     Query->Param("search_supcontractcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub getSqlFrom
{
   my $self=shift;
   my $from="lnkapplsupcontract left outer join appl ".
            "on lnkapplsupcontract.appl=appl.id ".
            "left outer join supcontract ".
            "on lnkapplsupcontract.supcontract=supcontract.id ".
            "left outer join grp as applcustgrp on ".
            "appl.customer=applcustgrp.grpid ";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplsupcontract.jpg?".
          $cgi->query_string());
}
         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{applid})) ||
       (defined($newrec->{applid}) && $newrec->{applid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{supcontractid})) ||
       (defined($newrec->{supcontractid}) && $newrec->{supcontractid}==0)){
      $self->LastMsg(ERROR,"invalid contract specified");
      return(undef);
   }
   my $fraction=effVal($oldrec,$newrec,"fraction");
   if ($fraction=~m/^\s*$/){
      $newrec->{fraction}=100;
   }
   if ($fraction>100){
      $self->LastMsg(ERROR,"a fraction greater 100 is not allowed");
      return(undef);
   }
   if (!defined($oldrec) || effChanged($oldrec,$newrec,"fraction")){
      my $cobj=$self->Clone();
      my $supid=effVal($oldrec,$newrec,"supcontractid");
      my $flt={supcontractid=>\$supid};
      my $id=effVal($oldrec,$newrec,"id");
      if ($id ne ""){
         $flt->{id}="!\"$id\"";
      }
      $cobj->SetFilter($flt);
      my $s=effVal($oldrec,$newrec,"fraction");
      foreach my $chkrec ($cobj->getHashList(qw(fraction))){
         $s+=$chkrec->{fraction};
      }
      if ($s>100){
         $self->LastMsg(ERROR,"a fraction greater 100 is not allowed");
         return(undef);
      }
   }

   if ($self->isDataInputFromUserFrontend()){
      my $contractid=effVal($oldrec,$newrec,"supcontractid");
      if (!defined($contractid) ||
          !$self->isWriteOnCustContractValid($contractid,"applications")){
         $self->LastMsg(ERROR,"no access");
         return(undef);
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
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL") if ($self->IsMemberOf("admin"));
   return("default");
}





1;
