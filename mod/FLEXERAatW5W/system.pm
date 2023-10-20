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
use FLEXERAatW5W::lib::Listedit;
use kernel::Field;
@ISA=qw(FLEXERAatW5W::lib::Listedit);

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

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Systemname',
                uivisible     =>0,
                dataobjattr   =>'FLEXERA_system.systemname'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                ignorecase    =>1,
                dataobjattr   =>'FLEXERA_system.systemname'),

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
                vjoindisp     =>['software','version','classification'],
                vjoininhash   =>['software','version','classification',
                                 'id','scandate','fullversion']),

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

      new kernel::Field::Text(
                name          =>'instancecloudid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'InstanceCloudId',
                dataobjattr   =>'instancecloudid'),

      new kernel::Field::Text(
                name          =>'w5systemid',
                group         =>'w5basedata',
                label         =>'W5BaseID',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'UFLEXERA_system2w5system.w5baseid'),

      new kernel::Field::Text(
                name          =>'w5systemname',
                label         =>'W5Base/logical System',
                group         =>'w5basedata',
                searchable    =>0,
                vjointo       =>\'AL_TCom::system',
                vjoinon       =>['w5systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'W5Base/Applications',
                group         =>'w5basedata',
                readonly      =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['w5systemid'=>'systemid'],
                vjoindisp     =>'appl'),

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
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_systemdevicestatus"))){
     Query->Param("search_systemdevicestatus"=>"ACTIVE");
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



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="$worktable  ".
          "left outer join (".
             "select distinct FLEXERADEVICEID,W5BASEID ".
             "from FLEXERA_system2w5system) UFLEXERA_system2w5system ".
          "on $worktable.FLEXERASYSTEMID=".
          "UFLEXERA_system2w5system.FLEXERADEVICEID ";

   return($from);
}




sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software vm w5basedata source));
}  



sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(systemname systemid instpkgsoftware));

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{

         #####################################################################
         #my %e=(
         #   section=>'SYSTEMNAME',
         #   scanname=>$rec->{systemname}, 
         #   quality=>-50,    # relativ schlecht verlässlich
         #   processable=>1,
         #   forcesysteminst=>1  # MUSS System zugeordnet sein
         #);
         #push(@res,\%e);
         #####################################################################




         foreach my $s (@{$rec->{instpkgsoftware}}){
            # at this point, there can be nativ scandata be patched to correct
            # scan informations!  
            my $version=$s->{fullversion};
            $version=~s/-.*$//;  # remove package version
            my %e=(
               section=>'SOFTWARE',
               scanname=>$s->{software},
               scanextra2=>$version,
               quality=>2,    # schlechter als AM
               processable=>1,
               backendload=>$s->{scandate},
               autodischint=>$self->Self.": ".$rec->{id}.
                             ": ".$rec->{systemid}.
                             ": ".$rec->{name}.":SOFTWARE :".$s->{id}.": ".
                             $s->{software}
            );
            # Flexera Agent ist immer Hostbasiert installiert.
            if ($s->{software}=~m/^FlexNet Inventory Agent/i){
               $e{forcesysteminst}=1;
               $e{allowautoremove}=1;
               $e{quality}=100;  #flexera weiss am besten über flexera bescheid
            }
            push(@res,\%e);
         }
#         foreach my $s (@{$rec->{ipaddresses}}){
#            my %e=(
#               section=>'IPADDR',
#               scanname=>$s->{address},
#               scanextra2=>$s->{physicaladdress},
#               quality=>10,    # relativ verlässlich
#               processable=>0  # nicht verwendbar - da AM Master!
#            );
#            push(@res,\%e);
#         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
}


1;
