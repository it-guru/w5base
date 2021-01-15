package tsacinv::autodiscsystem;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'systemdiscoveryid',
                group         =>'source',
                label         =>'DiscoveryID',
                dataobjattr   =>'"systemdiscoveryid"'),

      new kernel::Field::Text(
                name          =>'systemname',
                ignorecase    =>1,
                label         =>'Systemname',
                dataobjattr   =>'"systemname"'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'Systemname',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'"systemid"'),

      new kernel::Field::Text(
                name          =>'model',
                label         =>'Model',
                dataobjattr   =>'"model"'),

      new kernel::Field::Text(
                name          =>'usage',
                label         =>'Usage',
                dataobjattr   =>'"usage"'),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release',
                dataobjattr   =>'"osrelease"'),

      new kernel::Field::Text(
                name          =>'memory',
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>'"memory"'),

      new kernel::Field::Text(
                name          =>'physcpucount',
                label         =>'phys CPU-Count',
                dataobjattr   =>'"physcpucount"'),

      new kernel::Field::Text(
                name          =>'cputype',
                label         =>'CPU-Type',
                dataobjattr   =>'"cputype"'),

      new kernel::Field::Text(
                name          =>'cpuspeed',
                label         =>'CPU-Speed',
                unit          =>'MHz',
                dataobjattr   =>'"cpuspeed"'),

      new kernel::Field::Text(
                name          =>'independcpucount',
                label         =>'indipendent CPU-Count',
                dataobjattr   =>'"independcpucount"'),

      new kernel::Field::Text(
                name          =>'cpucount',
                label         =>'CPU-Count',
                dataobjattr   =>'"cpucount"'),

      new kernel::Field::Text(
                name          =>'serialno',
                label         =>'Serialnumber',
                dataobjattr   =>'"serialno"'),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Addresses',
                group         =>'ipaddresses',
                vjointo       =>'tsacinv::autodiscipaddress',
                vjoinon       =>['systemdiscoveryid'=>'systemautodiscid'],
                vjoindisp     =>['address','physicaladdress'],
               # vjoinbase     =>{scandate=>">now-7d"}
                ),

      new kernel::Field::SubList(
                name          =>'softwareinstallations',
                label         =>'Software Installations',
                group         =>'softwareinstallations',
                vjointo       =>'tsacinv::autodiscsoftware',
                vjoinon       =>['systemdiscoveryid'=>'systemautodiscid'],
                vjoindisp     =>['software','version','producer'],
                vjoininhash   =>['software','path','version','producer',
                                 'scandate','id'],
                vjoinbase     =>{scandate=>">now-14d"}),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                label         =>'Scandate',
                dataobjattr   =>'"scandate"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),


   );
   $self->{use_distinct}=0;
    $self->setWorktable("autodiscsystem");
   $self->setDefaultView(qw(name systemid model scandate));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}


sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(name systemid softwareinstallations
                            ipaddresses srcsys systemdiscoveryid));

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
#         my %e=(
#            section=>'SYSTEMNAME',
#            scanname=>$rec->{name}, 
#            quality=>-50     # relativ schlecht verlässlich
#         );
#         push(@res,\%e);
         foreach my $s (@{$rec->{softwareinstallations}}){
            my $path=$s->{path};
            # at this point, there can be nativ scandata be patched to correct
            # scan informations!  
            if ($s->{software}=~m/Oracle Database/){
               # remove inventory subtree from oracle install path
               $path=~s#([0-9]+\.[0-9]\.[0-9]+[\\/][^\\/]+)[\\/].*$#$1#;
            }
            my %e=(
               section=>'SOFTWARE',
               scanname=>$s->{software},
               scanextra1=>$path,
               scanextra2=>$s->{version},
               quality=>3,    # relativ schlecht (keine gute Version)
               processable=>1,
               backendload=>$s->{scandate},
               autodischint=>$rec->{srcsys}.": ".$rec->{systemdiscoveryid}.
                             ": ".$rec->{systemid}.
                             ": ".$rec->{name}.":SOFTWARE :".$s->{id}.": ".
                             $s->{software}
                             
            );
            push(@res,\%e);
         }
         foreach my $s (@{$rec->{ipaddresses}}){
            my %e=(
               section=>'IPADDR',
               scanname=>$s->{address},
               scanextra2=>$s->{physicaladdress},
               quality=>10,    # relativ verlässlich
               processable=>0  # nicht verwendbar - da AM Master!
            );
            push(@res,\%e);
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_scandate"))){
     Query->Param("search_scandate"=>">now-14d");
   }
}


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default ipaddresses softwareinstallations source));
}  


1;
