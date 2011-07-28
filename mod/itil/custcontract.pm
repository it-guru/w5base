package itil::custcontract;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
use finance::custcontract;
@ISA=qw(finance::custcontract);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::SubList(    name       =>'applications',
                                     label      =>'Applications',
                                     group      =>'applications',
                                     subeditmsk =>'subedit.custcontract',
                                     vjointo    =>'itil::lnkapplcustcontract',
                                     vjoinon    =>['id'=>'custcontractid'],
                                     vjoindisp  =>['appl','fraction'],
                                     vjoinbase  =>[{applcistatusid=>'<=4'}],
                                     vjoininhash=>['applid','applcistatusid',
                                                   'appl']),

      new kernel::Field::SubList(    name       =>'applicationids',
                                     label      =>'ApplicationIDs',
                                     group      =>'applications',
                                     uivisible  =>0,
                                     vjointo    =>'itil::lnkapplcustcontract',
                                     vjoinon    =>['id'=>'custcontractid'],
                                     vjoindisp  =>['applid'],
                                     vjoinbase  =>[{applcistatusid=>'<=4'}],
                                     vjoininhash=>['applid','applcistatusid',
                                                   'appl']),
   );
   return($self);
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
   my @res=$self->SUPER::isWriteValid(@_);
   push(@res,"applications") if (grep(/^default$/,@res) ||
                                 grep(/^ALL$/,@res));
   return(@res);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);
   
   my $refobj=getModuleObject($self->Config,"itil::lnkapplcustcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'custcontractid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   return($bak);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/contract.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default sem delmgmt modules
             applications contacts control misc attachments source));
}




1;
