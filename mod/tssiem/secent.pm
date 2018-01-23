package tssiem::secent;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use tssiem::secscan;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'ictono',
                group         =>'scan',
                label         =>'ICTO-ID',
                dataobjattr   =>"('ICTO-'||W5SIEM_secscan.ictoid)"),

      new kernel::Field::Date(
                name          =>'sdate',
                label         =>'Scan date',
                dataobjattr   =>'W5SIEM_secscan.launch_datetime'),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP',
                dataobjattr   =>"W5SIEM_secent.ipaddress"),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'possible W5Base System',
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=4"}],
                vjoinon       =>['ipaddress'=>'ipaddresses'],
                vjoindisp     =>['name','applications']),

      new kernel::Field::Text(
                name          =>'tracking_method',
                label         =>'Tracking Meth',
                dataobjattr   =>"W5SIEM_secent.tracking_method"),

      new kernel::Field::Text(
                name          =>'os',
                label         =>'OS',
                htmlwidth     =>'200',
                dataobjattr   =>"W5SIEM_secent.osname"),

      new kernel::Field::Text(
                name          =>'ipstatus',
                label         =>'IP Status',
                sqlorder      =>'NONE',
                dataobjattr   =>"W5SIEM_secent.ipstatus"),

      new kernel::Field::Text(
                name          =>'qid',
                label         =>'QID',
                dataobjattr   =>"W5SIEM_secent.qid"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Title',
                dataobjattr   =>"W5SIEM_secent.title"),

      new kernel::Field::Text(
                name          =>'vuln_status',
                label         =>'Vuln Status',
                dataobjattr   =>"W5SIEM_secent.vuln_status"),

      new kernel::Field::Text(
                name          =>'ent_type',
                label         =>'Type',
                dataobjattr   =>"W5SIEM_secent.ent_type"),

      new kernel::Field::Text(
                name          =>'severity',
                label         =>'Severity',
                dataobjattr   =>"W5SIEM_secent.severity"),

      new kernel::Field::Text(
                name          =>'port',
                label         =>'Port',
                dataobjattr   =>"W5SIEM_secent.port"),

      new kernel::Field::Text(
                name          =>'ssl',
                label         =>'SSL',
                dataobjattr   =>"W5SIEM_secent.ssl"),

      new kernel::Field::Date(
                name          =>'firstdetect',
                label         =>'First Detect',
                dataobjattr   =>'W5SIEM_secent.first_detect'),

      new kernel::Field::Date(
                name          =>'lastdetect',
                label         =>'Last Detect',
                dataobjattr   =>'W5SIEM_secent.last_detect'),

      new kernel::Field::Textarea(
                name          =>'vendor_reference',
                label         =>'Vendor Reference',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.vendor_reference'),

      new kernel::Field::Textarea(
                name          =>'impact',
                label         =>'Impact',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.impact'),

      new kernel::Field::Textarea(
                name          =>'exploitability',
                label         =>'Exploitability',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.exploitability'),

      new kernel::Field::Textarea(
                name          =>'associated_malware',
                label         =>'Associated Malware',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.associated_malware'),

      new kernel::Field::Text(
                name          =>'pci_vuln',
                label         =>'PCI Vuln',
                dataobjattr   =>"W5SIEM_secent.pci_vuln"),

      new kernel::Field::Text(
                name          =>'category',
                label         =>'Category',
                dataobjattr   =>"W5SIEM_secent.category"),

      new kernel::Field::Text(
                name          =>'scanname',
                label         =>'Scan Title',
                sqlorder      =>'NONE',
                group         =>'scan',
                dataobjattr   =>"W5SIEM_secscan.title"),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>"'Qualys'"),

      new kernel::Field::Id(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'W5SIEM_secent.ROWID'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'W5SIEM_secscan.importdate'),

      new kernel::Field::Link(
                name          =>'qref',
                group         =>'source',
                label         =>'Scan-Ref',
                dataobjattr   =>'W5SIEM_secent.ref'),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(ictono 
        sdate ipaddress tracking_method os qid name vuln_status ent_type
       severity port ssl firstdetect lastdetect vendor_reference impact
       exploitability));
   $self->setWorktable("W5SIEM_secent");
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


sub getSqlFrom
{
   my $self=shift;
   my $from="W5SIEM_secent join W5SIEM_secscan ".
            "on W5SIEM_secent.ref=W5SIEM_secscan.ref";
   return($from);
}



#sub initSearchQuery
#{
#   my $self=shift;
#   if (!defined(Query->Param("search_operational"))){
#     Query->Param("search_operational"=>"\"".$self->T("yes")."\"");
#   }
#}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.tssiem.secent.read)],
                          "RMember")){
      my @addflt;
      $self->tssiem::secscan::addICTOSecureFilter(\@addflt);
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","scan","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tssiem/load/qualys_secent.jpg?".$cgi->query_string());
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;