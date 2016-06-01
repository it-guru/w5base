package itcrm::custsystem;
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
use kernel::DataObj::DB;
use kernel::App::Web::Listedit;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'system.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'TS Systemname',
                dataobjattr   =>'system.name'),

      new kernel::Field::Text(
                name          =>'systemid',
                readonly      =>1,
                label         =>'AssetManager SystemID',
                dataobjattr   =>'system.systemid'),

      new kernel::Field::Select(  
                name          =>'cistatus',
                readonly      =>1,
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',   # function is needed to 
                label         =>'CI-StatusID',  # show undefined state
                dataobjattr   =>'system.cistatus'),


      new kernel::Field::Select(
                name          =>'osrelease',
                label         =>'OS-Release',
                vjointo       =>'itil::osrelease',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::system',
                vjoinon       =>['id'=>'id'],
                group         =>'default',
                dontrename    =>1,
                fields        =>[qw(cpucount memory locationid location)]),



      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OSReleaseID',
                dataobjattr   =>'system.osrelease'),

      new kernel::Field::Link(       
                name          =>'customerid',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Link(       
                name          =>'semid',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::Link(       
                name          =>'sem2id',
                dataobjattr   =>'appl.sem2'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                nodetaillink  =>1,
                vjoindisp     =>['appl','applcistatus','applcustomer',
                                 'applid']),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                nodetaillink  =>1,
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinbase     =>[{softwarecistatusid=>"<=4"}],
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['software','version','quantity','comments']),




#
#      new kernel::Field::SubList(
#                name          =>'systems',
#                label         =>'Systems',
#                group         =>'systems',
#                nodetaillink  =>1,
#                vjointo       =>'itil::lnkapplsystem',
#                vjoinbase     =>[{systemcistatusid=>"<=5"}],
#                vjoinon       =>['id'=>'applid'],
#                vjoindisp     =>['system','systemsystemid',
#                                 'systemcistatus',
#                                 'shortdesc'],
#                vjoindispXMLV01=>['system','systemsystemid',
#                                 'systemcistatus',
#                                 'systemcistatusid',
#                                 'isprod', 'isdevel', 'iseducation',
#                                 'isapprovtest', 'isreference',
#                                 'isapplserver','isbackupsrv',
#                                 'isdatabasesrv','iswebserver',
#                                 'osrelease',
#                                 'shortdesc']),
   );

   $self->setDefaultView(qw(name cistatus));
   $self->setWorktable("system");
   return($self);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf(["admin","w5base.itcrm.custsystem.read"])){
      my $userid=$self->getCurrentUserId();
      my %grp=$self->getGroupsOf($ENV{REMOTE_USER},
                                [qw(RMember RBoss RBoss2 RQManager
                                    RCFManager RCFManager2
                                    RCFOperator)],"both");
      my @grpids=keys(%grp);
      @grpids=(qw(NONE)) if ($#grpids==-1);

      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {customerid=>\@grpids},
                 {semid=>\$userid},
                 {sem2id=>\$userid}
                ]);
   }

   return($self->SetFilter(@flt));
}







sub getSqlFrom
{
   my $self=shift;
   my @from=("appl left outer join lnkapplsystem ".
             "on appl.id=lnkapplsystem.appl ".
             "left outer join system on lnkapplsystem.system=system.id");

   return(@from);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}  



sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::system");
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



















1;
