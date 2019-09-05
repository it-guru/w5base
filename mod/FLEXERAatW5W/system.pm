package FLEXERAatW5W::system;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;

   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'Flexera ComputerID',
                dataobjattr   =>'flexerasystemid'),

      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Systemname',
                uivisible     =>0,
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                ignorecase    =>1,
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Text(
                name          =>'systemdevicestatus',
                label         =>'System Device Status',
                uppersearch   =>1,
                dataobjattr   =>'devicestatus'),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release',
                ignorecase    =>1,
                dataobjattr   =>'SYSTEMOS'),

      new kernel::Field::Text(
                name          =>'ospatchlevel',
                label         =>'OS-PatchLevel',
                ignorecase    =>1,
                dataobjattr   =>'SYSTEMOSPATCHLEVEL'),

      new kernel::Field::Number(
                name          =>'cpucount',
                label         =>'CPU-Count',
                precision     =>0,
                dataobjattr   =>'SYSTEMCPUCOUNT'),

      new kernel::Field::Number(
                name          =>'corecount',
                label         =>'CORE-Count',
                precision     =>0,
                dataobjattr   =>'SYSTEMCORECOUNT'),

      new kernel::Field::Text(
                name          =>'hwmodel',
                label         =>'Hardwaremodel',
                ignorecase    =>1,
                dataobjattr   =>'ASSETMODLEL'),

      new kernel::Field::Text(
                name          =>'serialno',
                label         =>'Serialnumber',
                dataobjattr   =>'ASSETSERIALNO'),

      new kernel::Field::Text(
                name          =>'iplist',
                label         =>'IP-Addresses',
                dataobjattr   =>'IPADDRLIST'),

#      new kernel::Field::SubList(
#                name          =>'software',
#                label         =>'Software',
#                group         =>'software',
#                forwardSearch =>1,
#                vjointo       =>'FLEXERAatW5W::software',
#                vjoinon       =>['agentid'=>'agentid'],
#                vjoinbase     =>{endtime=>\undef},
#                vjoindisp     =>['software','version','isremote',
#                                 'isfreeofcharge'],
#                vjoininhash   =>['software','version','isremote',
#                                 'isfreeofcharge','scope']),
#
      new kernel::Field::SubList(
                name          =>'instpkgsoftware',
                label         =>'installed Packaged-Software',
                group         =>'software',
                htmldetail    =>0,
                vjointo       =>'FLEXERAatW5W::instpkgsoftware',
                vjoinon       =>['id'=>'flexerasystemid'],
                vjoindisp     =>['software','version','classification']),

     new kernel::Field::Boolean(
                name          =>'is_vm',
                group         =>'vm',
                label         =>'is virtualized system',
                htmldetail    =>\&checkIfVM, 
                selectfix     =>1,
                dataobjattr   =>'ISVM'),

     new kernel::Field::Boolean(
                name          =>'is_vmhostmissing',
                group         =>'vm',
                htmldetail    =>\&checkIfVM, 
                label         =>'is virtualization host missing',
                dataobjattr   =>'ISVMHOSTMISSING'),


      new kernel::Field::Text(
                name          =>'beaconid',
                group         =>'source',
                label         =>'BeaconID',
                dataobjattr   =>'BEACONID'),

      new kernel::Field::Text(
                name          =>'uuid',
                group         =>'source',
                label         =>'UUID',
                dataobjattr   =>'UUID'),

      new kernel::Field::CDate(
                name          =>'crdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'cdate'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Inventory-Date',
                dataobjattr   =>'INVENTORYDATE'),

      new kernel::Field::Date(
                name          =>'svscandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Services-Inventory-Date',
                dataobjattr   =>'SERVICESINVENTORYDATE'),

      new kernel::Field::Date(
                name          =>'hwscandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Hardware-Inventory-Date',
                dataobjattr   =>'HARDWAREINVENTORYDATE'),

   );
   $self->setWorktable("FLEXERA_system");
   $self->setDefaultView(qw(systemname systemid systemdevicestatus osrelease hwmodel 
                            beaconid scandate));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemdevicestatus"))){
     Query->Param("search_systemdevicestatus"=>"!IGNORED");
   }
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}



sub checkIfVM
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $current=$param{current};

   return(0) if (!defined($current));
   return(1) if ($current->{is_vm});
   return(0);
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub initSqlWhere
{
   my $self=shift;
   my $where="";

   my $userid=$self->getCurrentUserId();
   $userid=-1 if (!defined($userid) || $userid==0);

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->IsMemberOf([qw(admin
                                 w5base.tsflexera.read
                              )],
          "RMember") &&
          !$self->IsMemberOf([qw(
                                 DTAG.GHQ.VTI.DTIT.E-DTO.E-DTOPL
                              )],
          "RMember","up") ){
         $where="(BEACONID is null ".
                "or BEACONID='DEU0360DEVLAB' ".
                "or BEACONID='DEU0360WSICTS')";
      }
   }

   return($where);
}




#sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
#{
#   my $self=shift;
#   my @res=();
#
#   $self->SetCurrentView(qw(systemid systemname osrelease agentip software));
#
#   my ($rec,$msg)=$self->getFirst();
#   if (defined($rec)){
#      do{
##         my %e=(
##            section=>'SYSTEMNAME',
##            scanname=>$rec->{systemname},
##            quality=>0     # neutral verlässlich
##         );
##         push(@res,\%e);
##         my %e=(
##            section=>'IP',
##            scanname=>$rec->{agentip},
##            quality=>0     # neutral verlässlich
##         );
##         push(@res,\%e);
#         foreach my $sw (@{$rec->{software}}){
#            my %e=(
#               section=>'SOFTWARE',
#               scanname=>$sw->{software}, 
#               scanextra1=>$sw->{scope},
#               scanextra2=>$sw->{version},
#               quality=>-10     # relativ schlecht verlässlich
#            );
#            push(@res,\%e);
#         }
#         ($rec,$msg)=$self->getNext();
#      } until(!defined($rec));
#   }
#   return(@res);
#}
         


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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software vm source));
}  

1;
