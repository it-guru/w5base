package ewu2::system;
#  W5Base Framework
#  Copyright (C) 118  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>1,
                group         =>'source',
                label         =>"DevLabSystemID",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"COMPUTER_SYSTEM_ID\""),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>"full systemname",
                ignorecase    =>1,
                htmldetail    =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UNAME\" || ' (' || ".
                                "\"COMPUTER_SYSTEMS\".\"COMPUTER_SYSTEM_ID\" ".
                                "||')'"),

      new kernel::Field::Text(
                name          =>'typedfullname',
                label         =>"full systemname",
                nowrap        =>1,
                uivisible     =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UNAME\" || ' (' || ".
                                "\"COMPUTER_SYSTEMS\".\"COMPUTER_SYSTEM_ID\" ".
                                "||') ' || \"COMPUTER_SYSTEMS\".\"TYPE\""),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>"Systemname",
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UNAME\""),

      new kernel::Field::Text(
                name          =>'status',
                label         =>"Status",
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"STATUS\""),

      new kernel::Field::Text(
                name          =>'type',
                label         =>"system type",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"TYPE\""),

      new kernel::Field::Boolean(
                name          =>'deleted',
                label         =>"marked as delete",
                htmldetail    =>0,
                dataobjattr   =>"decode(\"COMPUTER_SYSTEMS\".".
                                "\"DELETED_AT\",NULL,0,1)"),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                vjointo       =>'ewu2::ipaddress',
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(name dnsname dnsdomain)]),

      new kernel::Field::SubList(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts',
                vjointo       =>'ewu2::lnksystemcontact',
                searchable    =>0,
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(contactfullname comments)]),

      new kernel::Field::SubList(
                name          =>'contracts',
                label         =>'Contracts',
                group         =>'contracts',
                vjointo       =>'ewu2::lnksystemcontract',
                searchable    =>0,
                vjoinon       =>['id'=>'devlabsystemid'],
                vjoindisp     =>[qw(contractname projectname)]),

      new kernel::Field::Text(
                name          =>'description',
                label         =>"Description",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"DESCRIPTION\""),

      new kernel::Field::Textarea(
                name          =>'notes',
                label         =>"Notes",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"NOTES\""),

      new kernel::Field::Link(
                name          =>'physicalelementid',
                label         =>"Physical Element Id",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"PHYSICAL_ELEMENT_ID\""),

      new kernel::Field::Link(
                name          =>'clustercsid',
                label         =>"Cluster Cs Id",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CLUSTER_CS_ID\""),

      new kernel::Field::TextDrop(
                name          =>'vhostname',
                label         =>"virtualisation Host",
                group         =>'virtualisation',
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::system',
                vjoinon       =>['hostingcsid'=>'id'],
                vjoindisp     =>'typedfullname'),

      new kernel::Field::Link(
                name          =>'hostingcsid',
                label         =>"Hosting Cs Id",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"HOSTING_CS_ID\""),

      new kernel::Field::Text(
                name          =>'vmvirtualisationtype',
                label         =>"Virtualisation Type",
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".".
                                "\"VM_VIRTUALISATION_TYPE\""),

      new kernel::Field::SubList(
                name          =>'vsystems',
                label         =>'virtual systems',
                group         =>'virtualisation',
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::system',
                vjoinon       =>['id'=>'hostingcsid'],
                vjoindisp     =>[qw(typedfullname status osrelease)]),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>"OS-Release",
                group         =>'sysdata',
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"OS\""),

      new kernel::Field::Text(
                name          =>'platform',
                label         =>"Platform",
                group         =>'sysdata',
                ignorecase    =>1,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"PLATFORM\""),

      new kernel::Field::Text(
                name          =>'cputype',
                group         =>'sysdata',
                label         =>"CPU-Type",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_TYPE\""),

      new kernel::Field::Text(
                name          =>'cpuspeed',
                group         =>'sysdata',
                label         =>"CPU-Speed",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_SPEED\""),

      new kernel::Field::Text(
                name          =>'cpucount',
                group         =>'sysdata',
                label         =>"CPU-Count",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_COUNT\""),

      new kernel::Field::Text(
                name          =>'cpucorestotal',
                group         =>'sysdata',
                label         =>"CPU Cores Total",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CPU_CORES_TOTAL\""),

      new kernel::Field::Text(   # Feld ist nicht verwendbar, da der Inhalt
                name          =>'memory',  # manchmal MB und manchmal GB sind
                uivisible     =>0,  
                group         =>'sysdata',
                label         =>"Memory",
                unit          =>'MB',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"RAM_MB\""),

      new kernel::Field::Text(
                name          =>'hostid',
                label         =>"Host-ID",
                group         =>'sysdata',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"HOSTID\""),

      new kernel::Field::TextDrop(
                name          =>'asset',
                label         =>"Asset",
                group         =>'asset',
                htmldetail    =>'NotEmpty',
                vjointo       =>'ewu2::asset',
                vjoinon       =>['physicalelementid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'operatedby',
                label         =>"Operated By",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"OPERATED_BY\""),

      new kernel::Field::Text(
                name          =>'servicelevel',
                label         =>"Service Level",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"SERVICE_LEVEL\""),

      new kernel::Field::Text(
                name          =>'lockversion',
                uivisible     =>0,
                label         =>"Lock Version",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"LOCK_VERSION\""),

      new kernel::Field::Text(
                name          =>'survey',
                label         =>"Survey",
                uivisible     =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"SURVEY\""),

      new kernel::Field::Text(
                name          =>'backupsystem',
                group         =>'backup',
                label         =>"Backup System",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"BACKUP_SYSTEM\""),

      new kernel::Field::Text(
                name          =>'backupserver',
                group         =>'backup',
                label         =>"Backup Server",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"BACKUP_SERVER\""),

      new kernel::Field::Text(
                name          =>'managementaccess',
                uivisible     =>0,
                label         =>"Management Access",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"MANAGEMENT_ACCESS\""),

      new kernel::Field::Text(
                name          =>'domain',
                label         =>"Domain",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"DOMAIN\""),

      new kernel::Field::Text(
                name          =>'puppet',
                label         =>"Puppet",
                uivisible     =>0,
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"PUPPET\""),

      new kernel::Field::Text(
                name          =>'sger',
                uivisible     =>0,
                label         =>"Sger",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"SGER\""),

      new kernel::Field::Date(
                name          =>'dlicensedate',
                label         =>"License Date",
                uivisible     =>0,
                timezone      =>'CET',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"LICENSE_DATE\""),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                timezone      =>'CET',
                label         =>"Creation-Date",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"CREATED_AT\""),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                timezone      =>'CET',
                label         =>"Modification-Date",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"UPDATED_AT\""),

      new kernel::Field::Date(
                name          =>'ddate',
                group         =>'source',
                timezone      =>'CET',
                uivisible     =>0,
                label         =>"Deletion-Date",
                dataobjattr   =>"\"COMPUTER_SYSTEMS\".\"DELETED_AT\""),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(systemname type status osrelease 
                            vhostname asset));
   $self->setWorktable("\"COMPUTER_SYSTEMS\"");
   return($self);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"ewu2"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","sysdata","virtualisation",
          "asset","ipaddresses","contacts",
          "backup","contracts","source");
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
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }

}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL");
}


1;

