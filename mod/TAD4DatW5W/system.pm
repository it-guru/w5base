package TAD4DatW5W::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   $self->{use_distinct}=0;

   
   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'TAD4DatW5W Computer scanid',
                dataobjattr   =>'computer_sys_id'),

      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Systemname',
                uivisible     =>0,
                dataobjattr   =>'computer_alias'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                ignorecase    =>1,
                dataobjattr   =>'computer_alias'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                dataobjattr   =>'custom_data1'),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release',
                ignorecase    =>1,
                dataobjattr   =>'os_name'),

      new kernel::Field::Text(
                name          =>'hwmodel',
                label         =>'Hardwaremodel',
                ignorecase    =>1,
                dataobjattr   =>'computer_model'),

      new kernel::Field::Text(
                name          =>'serialno',
                label         =>'Serialnumber',
                dataobjattr   =>'sys_ser_num'),

      new kernel::Field::Text(
                name          =>'agentversion',
                group         =>'agent',
                label         =>'Version',
                dataobjattr   =>'agent_version'),

      new kernel::Field::Text(
                name          =>'agentip',
                group         =>'agent',
                label         =>'IP-Address',
                dataobjattr   =>'agent_ip_address'),

      new kernel::Field::Text(
                name          =>'hostname',
                group         =>'agent',
                label         =>'Hostname',
                dataobjattr   =>'agent_hostname'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                forwardSearch =>1,
                vjointo       =>'TAD4DatW5W::software',
                vjoinon       =>['agentid'=>'agentid'],
                vjoinbase     =>{endtime=>\undef},
                vjoindisp     =>['software','version','isremote',
                                 'isfreeofcharge'],
                vjoininhash   =>['software','version','isremote',
                                 'isfreeofcharge','scope']),

      new kernel::Field::SubList(
                name          =>'nativesoftware',
                label         =>'native Software',
                group         =>'software',
                htmldetail    =>0,
                vjointo       =>'TAD4DatW5W::nativesoftware',
                vjoinon       =>['agentid'=>'agentid'],
                vjoindisp     =>['software','version']),

      new kernel::Field::Text(
                name          =>'nodeid',
                group         =>'source',
                label         =>'Node ID',
                dataobjattr   =>'agent_node_id'),

      new kernel::Field::Text(
                name          =>'agentid',
                group         =>'source',
                label         =>'Agent ID',
                dataobjattr   =>'agent_id'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'create_time'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'update_time'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Scan-Date',
                dataobjattr   =>'scan_time'),

      new kernel::Field::Text(
                name          =>'env',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Enviroment',
                dataobjattr   =>'enviroment'),

   );
   $self->setWorktable("TAD4D_system");
   $self->setDefaultView(qw(systemname osrelease hwmodel agentversion 
                            scandate env));
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


#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_status"))){
#     Query->Param("search_status"=>"\"!out of operation\"");
#   }
#   if (!defined(Query->Param("search_tenant"))){
#     Query->Param("search_tenant"=>"CS");
#   }
#
#}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub extractAutoDiscData      # SetFilter Call ist Job des Aufrufers
{
   my $self=shift;
   my @res=();

   $self->SetCurrentView(qw(systemid systemname osrelease agentip software));

   my ($rec,$msg)=$self->getFirst();
   if (defined($rec)){
      do{
#         my %e=(
#            section=>'SYSTEMNAME',
#            scanname=>$rec->{systemname},
#            quality=>0     # neutral verlässlich
#         );
#         push(@res,\%e);
#         my %e=(
#            section=>'IP',
#            scanname=>$rec->{agentip},
#            quality=>0     # neutral verlässlich
#         );
#         push(@res,\%e);
         foreach my $sw (@{$rec->{software}}){
            my %e=(
               section=>'SOFTWARE',
               scanname=>$sw->{software}, 
               scanextra1=>$sw->{scope},
               scanextra2=>$sw->{version},
               quality=>-10     # relativ schlecht verlässlich
            );
            push(@res,\%e);
         }
         ($rec,$msg)=$self->getNext();
      } until(!defined($rec));
   }
   return(@res);
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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default agent software 
             source));
}  

1;
