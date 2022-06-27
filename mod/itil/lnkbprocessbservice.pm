package itil::lnkbprocessbservice;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'lnkbprocessbusinessservice.id'),

      new kernel::Field::RecordUrl(),
                                                 
      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'fullqualified relation name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fullname;

                   my $fo=$self->getParent->getField("businessprocess");
                   my $f=$fo->RawValue($current);

                   $fullname.=$f;

                   $fullname.=" -> ";

                   my $fo=$self->getParent->getField("businessservice");
                   my $f=$fo->RawValue($current);

                   $fullname.=$f;
                   return($fullname);
                }),

      new kernel::Field::TextDrop(
                name          =>'businessprocess',
                htmlwidth     =>'250px',
                label         =>'Business process',
                vjointo       =>'itil::businessprocess',
                vjoinon       =>['bprocessid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'businessservice',
                label         =>'Businessservice',
                vjointo       =>'itil::businessservice',
                vjoinon       =>['businessserviceid'=>'id'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Select(
                name          =>'bprocesscistatus',
                group         =>'bprocessinfo',
                label         =>'Business Process CI-State',
                vjointo       =>'base::cistatus',
                readonly      =>1,
                vjoinon       =>['bprocesscistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'bservicecistatus',
                group         =>'bserviceinfo',
                label         =>'BusinessService CI-State',
                vjointo       =>'base::cistatus',
                readonly      =>1,
                vjoinon       =>['bservicecistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkbprocessbusinessservice.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbprocessbusinessservice.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkbprocessbusinessservice.modifyuser'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkbprocessbusinessservice.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkbprocessbusinessservice.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbprocessbusinessservice.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbprocessbusinessservice.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkbprocessbusinessservice.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbprocessbusinessservice.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbprocessbusinessservice.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkbprocessbusinessservice.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkbprocessbusinessservice.realeditor'),

      new kernel::Field::Mandator(
                group         =>'bprocessinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'BusinessProcessMandatorID',
                group         =>'bprocessinfo',
                dataobjattr   =>'businessprocess.mandator'),

      new kernel::Field::Link(
                name          =>'bsmandatorid',
                label         =>'BusinessServiceMandatorID',
                group         =>'bprocessinfo',
                dataobjattr   =>'businessservice.mandator'),

      new kernel::Field::Link(
                name          =>'bprocessbprocessid',
                label         =>'BusinessprocessID',
                group         =>'bprocessinfo',
                dataobjattr   =>'businessprocess.id'),

      new kernel::Field::TextDrop(
                name          =>'customer',
                label         =>'Organisation/Customer',
                readonly      =>1,
                group         =>'bprocessinfo',
                translation   =>'crm::businessprocess',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['customerid'=>'grpid'],
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Link(
                name          =>'bprocesscistatusid',
                label         =>'BusinessProcessStatusID',
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::Link(
                name          =>'bservicecistatusid',
                label         =>'BusinessServiceStatusID',
                dataobjattr   =>'businessprocess.cistatus'),

      new kernel::Field::Link(
                name          =>'customerid',
                readonly      =>1,
                label         =>'CustomerID',
                dataobjattr   =>'businessprocess.customer'),

                                                   
      new kernel::Field::Link(
                name          =>'bprocessid',
                label         =>'BusinessprocessID',
                dataobjattr   =>'lnkbprocessbusinessservice.bprocess'),
                                                   
      new kernel::Field::Link(
                name          =>'businessserviceid',
                label         =>'BusinessServiceID',
                dataobjattr   =>'lnkbprocessbusinessservice.businessservice'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'businessprocess.mandator'),
   );
   $self->setDefaultView(qw(businessprocess businessservice cdate));
   $self->setWorktable("lnkbprocessbusinessservice");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkbprocessbusinessservice left outer join businessprocess ".
            "on lnkbprocessbusinessservice.bprocess=businessprocess.id ".
            "left outer join businessservice ".
            "on lnkbprocessbusinessservice.businessservice=businessservice.id ";
   return($from);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.bprocess.read 
                              w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                ]);
   }
   return($self->SetFilter(@flt));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if ((!defined($oldrec) && !defined($newrec->{bprocessid})) ||
       (defined($newrec->{bprocessid}) && $newrec->{bprocessid}==0)){
      $self->LastMsg(ERROR,"invalid business process specified");
      return(undef);
   }
   if ((!defined($oldrec) && !defined($newrec->{businessserviceid})) ||
       (defined($newrec->{businessserviceid}) && $newrec->{businessserviceid}==0)){
      $self->LastMsg(ERROR,"invalid application specified");
      return(undef);
   }
   my $bprocessid=effVal($oldrec,$newrec,"bprocessid");

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnBProcessValid($bprocessid,"businessservices")){
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
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bprocessid=effVal($oldrec,$newrec,"bprocessid");
   my @rw=qw(default);

   return(@rw) if (!defined($oldrec) && !defined($newrec));
   return(@rw) if ($self->IsMemberOf("admin"));
   return(@rw) if ($self->isWriteOnBProcessValid($bprocessid,
                                                       "businessservices"));
   return(@rw) if (!$self->isDataInputFromUserFrontend() &&
                         !defined($oldrec));

   return();
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default eventnotification misc bprocessinfo 
             bserviceinfo applinfo source ));
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_bprocesscistatus"))){
     Query->Param("search_bprocesscistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_bservicecistatus"))){
     Query->Param("search_bservicecistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}









1;
