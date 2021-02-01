package itil::lnkswinstancesystem;
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
   $param{MainSearchFieldLines}=5;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::TextDrop(
                name          =>'swinstance',
                htmlwidth     =>'250px',
                label         =>'Instance name',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'swinstance.fullname'),

      new kernel::Field::Select(
                name          =>'swinstancecistatus',
                group         =>'swinstanceinfo',
                readonly      =>1,
                label         =>'Instance CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['swinstancecistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name',
                dataobjattr   =>'system.name'),
                                                   
      new kernel::Field::Select(
                name          =>'systemcistatus',
                readonly      =>1,
                group         =>'systeminfo',
                label         =>'System CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['systemcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                readonly      =>1,
                label         =>'SystemID',
                group         =>'systeminfo',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::TextDrop(
                name          =>'swteam',
                label         =>'Instance guardian team',
                translation   =>'itil::swinstance',
                readonly      =>1,
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['swteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'swteamid',
                dataobjattr   =>'swinstance.swteam'),
                                                   
      new kernel::Field::Text(
                name          =>'shortdesc',
                readonly      =>1,
                label         =>'Short Description',
                group         =>'systeminfo',
                dataobjattr   =>'system.shortdesc'),

      new kernel::Field::Select(
                name          =>'osrelease',
                group         =>'systeminfo',
                translation   =>'itil::system',
                htmleditwidth =>'40%',
                readonly      =>1,
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Select(
                name          =>'isprod',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                readonly      =>1,
                htmleditwidth =>'30%',
                label         =>'Productionsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_prod'),

      new kernel::Field::Select(
                name          =>'istest',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                readonly      =>1,
                label         =>'Testsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_test'),

      new kernel::Field::Mandator(
                group         =>'swinstanceinfo',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'ApplMandatorID',
                group         =>'swinstanceinfo',
                dataobjattr   =>'swinstance.mandator'),

      new kernel::Field::Select(
                name          =>'swnature',
                group         =>'swinstanceinfo',
                readonly      =>1,
                translation   =>'itil::swinstance',
                label         =>'Instance type',
                dataobjattr   =>'swinstance.swnature'),

      new kernel::Field::Text(
                name          =>'swtype',
                group         =>'swinstanceinfo',
                readonly      =>1,
                translation   =>'itil::swinstance',
                label         =>'Instance operation type',
                dataobjattr   =>'swinstance.swtype'),
                                                  
      new kernel::Field::Link(
                name          =>'swinstancecistatusid',
                label         =>'SwInstanceCiStatusID',
                dataobjattr   =>'swinstance.cistatus'),

      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetID',
                dataobjattr   =>'system.asset'),

      new kernel::Field::Select(
                name          =>'isdevel',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                htmleditwidth =>'30%',
                readonly      =>1,
                label         =>'Developmentsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_devel'),

      new kernel::Field::Select(
                name          =>'iseducation',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                readonly      =>1,
                htmleditwidth =>'30%',
                label         =>'Educationsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_education'),

      new kernel::Field::Select(
                name          =>'isapprovtest',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                readonly      =>1,
                htmleditwidth =>'30%',
                label         =>'Approval Testsystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_approvtest'),

      new kernel::Field::Select(
                name          =>'isreference',
                group         =>'systeminfo',
                transprefix   =>'boolean.',
                readonly      =>1,
                htmleditwidth =>'30%',
                label         =>'Referencesystem',
                value         =>[0,1],
                dataobjattr   =>'system.is_reference'),

                                                   
      new kernel::Field::Link(
                name          =>'systemcistatusid',
                label         =>'SystemCiStatusID',
                dataobjattr   =>'system.cistatus'),
                                                   
      new kernel::Field::Link(
                name          =>'assetid',
                label         =>'AssetId',
                dataobjattr   =>'system.asset'),
                                                   
      new kernel::Field::Link(
                name          =>'swinstanceid',
                dataobjattr   =>'swinstance.id'),
                                                   
      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemId',
                dataobjattr   =>'system.id'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'swinstance.mandator'),
   );
   $self->setDefaultView(qw(swnature swinstance swtype system systemsystemid cdate));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/lnkswinstancesystem.jpg?".
          $cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="swinstance
      left outer join lnkitclustsvc
         on swinstance.itclusts=lnkitclustsvc.id
      left outer join itclust
         on lnkitclustsvc.itclust=itclust.id
      left outer join system as clnode
         on clnode.clusterid=itclust.id
      left outer join lnkitclustsvcsyspolicy
         on (lnkitclustsvc.id=lnkitclustsvcsyspolicy.itclustsvc and
            clnode.id=lnkitclustsvcsyspolicy.system)
      left outer join system
         on (swinstance.system=system.id or clnode.id=system.id)";
 
   return($from);
}


sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   my $where="((swinstance.runonclusts=0) or (
      ((lnkitclustsvc.id is not null and
        lnkitclustsvcsyspolicy.runpolicy is null and
        itclust.defrunpolicy<>'deny') or
       (lnkitclustsvc.id is not null and
        lnkitclustsvcsyspolicy.runpolicy is not null and
        lnkitclustsvcsyspolicy.runpolicy<>'deny'))
      ))";
   return($where);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.swinstance.read 
                              w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      push(@flt,[
                 {mandatorid=>\@mandators},
                ]);
   }
   return($self->SetFilter(@flt));
}






sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_swinstancecistatus"))){
     Query->Param("search_swinstancecistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_systemcistatus"))){
     Query->Param("search_systemcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

#   my $swinstanceid=effVal($oldrec,$newrec,"swinstanceid");
#
#   return("default") if (!defined($oldrec) && !defined($newrec));
#   return("default") if ($self->IsMemberOf("admin"));
#   return("default") if ($self->isWriteOnSwinstanceValid($swinstanceid,"systems"));
#   return("default") if (!$self->isDataInputFromUserFrontend() && 
#                         !defined($oldrec));

   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default misc swinstanceinfo systeminfo ));
}







1;
