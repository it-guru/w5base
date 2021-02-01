package itil::lnkapplcustcontract;
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
                dataobjattr   =>'lnkapplcustcontract.id'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'relation fullname',
                dataobjattr   =>'concat(appl.name," - ",'.
                                'custcontract.name," (ID:",'.
                                'lnkapplcustcontract.id,")")'),

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
                name          =>'custcontract',
                htmlwidth     =>'130px',
                label         =>'Customer Contract',
                vjointo       =>'itil::custcontract',
                vjoinon       =>['custcontractid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'custcontractcistatus',
                htmleditwidth =>'40%',
                htmlwidth     =>'160px',
                readonly      =>1,
                group         =>'relation',
                label         =>'Customer Contract CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['custcontractcistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Percent(
                name          =>'fraction',
                label         =>'Fraction',
                dataobjattr   =>'lnkapplcustcontract.fraction'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkapplcustcontract.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkapplcustcontract.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkapplcustcontract.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkapplcustcontract.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkapplcustcontract.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkapplcustcontract.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkapplcustcontract.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkapplcustcontract.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkapplcustcontract.realeditor'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Link(
                name          =>'custcontractcistatusid',
                label         =>'CustContractCiStatusID',
                dataobjattr   =>'custcontract.cistatus'),

      new kernel::Field::Link(
                name          =>'applcistatusid',
                label         =>'ApplCiStatusID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Text(
                name          =>'applcustomer',
                label         =>'Application Customer',
                readonly      =>1,
                group         =>'relation',
                dataobjattr   =>'applcustgrp.fullname'),

      new kernel::Field::Text(
                name          =>'contractcustomer',
                label         =>'Customer Contract Customer',
                readonly      =>1,
                group         =>'relation',
                dataobjattr   =>'contractcustgrp.fullname'),

      new kernel::Field::Link(
                name          =>'custcontractname',
                label         =>'CustContractName',
                dataobjattr   =>'custcontract.fullname'),

      new kernel::Field::Link(
                name          =>'applid',
                label         =>'ApplID',
                dataobjattr   =>'lnkapplcustcontract.appl'),

      new kernel::Field::Interface(
                name          =>'custcontractid',
                htmlwidth     =>'150px',
                label         =>'Customer ContractId',
                dataobjattr   =>'lnkapplcustcontract.custcontract'),
   );
   $self->setDefaultView(qw(id appl custcontract cdate editor));
   $self->setWorktable("lnkapplcustcontract");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_custcontractcistatus"))){
     Query->Param("search_custcontractcistatus"=>
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
   my $from="lnkapplcustcontract left outer join appl ".
            "on lnkapplcustcontract.appl=appl.id ".
            "left outer join custcontract ".
            "on lnkapplcustcontract.custcontract=custcontract.id ".
            "left outer join grp as contractcustgrp on ".
            "custcontract.customer=contractcustgrp.grpid ".
            "left outer join grp as applcustgrp on ".
            "appl.customer=applcustgrp.grpid ";
   return($from);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkapplcustcontract.jpg?".
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
   if ((!defined($oldrec) && !defined($newrec->{custcontractid})) ||
       (defined($newrec->{custcontractid}) && $newrec->{custcontractid}==0)){
      $self->LastMsg(ERROR,"invalid contract specified");
      return(undef);
   }
   my $fraction=effVal($oldrec,$newrec,"fraction");
   if ($fraction=~m/^\s*$/){
      $newrec->{fraction}=100;
   }

   if ($self->isDataInputFromUserFrontend()){
      my $contractid=effVal($oldrec,$newrec,"custcontractid");
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
