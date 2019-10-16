package tsacinv::ipaddress;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                label         =>'NetworkCardID',
                align         =>'left',
                dataobjattr   =>'"id"'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'IP-Address',
                uivisible     =>0,
                depend        =>['ipaddress'],
                onRawValue    =>sub{   # compress IPV6 Adresses
                   my $self=shift;
                   my $current=shift;
                   my $d=$current->{ipaddress};
                      $d=~s/0000:/0:/g;
                      $d=~s/:0000/:0/g;
                      $d=~s/(:)0+?([a-f1-9])/$1$2/gi;
                      $d=~s/^0+?([a-f1-9])/$1$2/gi;
                      $d=~s/:0:/::/gi;
                      $d=~s/:0:/::/gi;
                      $d=~s/:::::/:0:0:0:0:/gi;
                      $d=~s/::::/:0:0:0:/gi;
                      $d=~s/:::/:0:0:/gi;
                   return($d);
                }),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP-Address',
                searchable    =>0,
                dataobjattr   =>'"ipaddress"'),

      new kernel::Field::Text(
                name          =>'ipv4address',
                label         =>'IP-V4-Address',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'"ipv4address"'),

      new kernel::Field::Text(
                name          =>'ipv6address',
                label         =>'IP-V6-Address',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'"ipv6address"'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemId',
                weblinkto     =>'tsacinv::system',
                weblinkon     =>['systemid'=>'systemid'],
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'"systemid"'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'"systemname"'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'"status"'),

      new kernel::Field::Boolean(
                name          =>'deleted',
                readonly      =>1,
                label         =>'marked as delete',
                dataobjattr   =>'"bdelete"'),


      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                dataobjattr   =>'"code"'),

      new kernel::Field::Text(
                name          =>'netmask',
                label         =>'Netmask',
                dataobjattr   =>'"netmask"'),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS-Name',
                dataobjattr   =>'"dnsname"'),

      new kernel::Field::Text(
                name          =>'dnsalias',
                label         =>'DNS-Alias',
                dataobjattr   =>'"dnsalias"'),

      new kernel::Field::Text(
                name          =>'accountno',
                label         =>'Account Number',
                group         =>'finance',
                vjointo       =>'tsacinv::accountno',
                vjoinon       =>['laccountnoid'=>'id'],
                vjoindisp     =>'name',
                uppersearch   =>1),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Type',
                ignorecase    =>1,
                dataobjattr   =>'"type"'),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'"description"'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'Computerid',
                dataobjattr   =>'"lcomputerid"'),

      new kernel::Field::Link(
                name          =>'laccountnoid',
                label         =>'AccountNoID',
                dataobjattr   =>'"laccountnoid"'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'"replkeypri"'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>'"replkeysec"')
   );
   $self->setWorktable("ipaddress");
   $self->setDefaultView(qw(linenumber systemid 
                            systemname ipaddress status description));
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

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!unconfigured\"");
   }
   if (!defined(Query->Param("search_deleted"))){
      Query->Param("search_deleted"=>$self->T("no"));
   }

}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/ipaddress.jpg?".$cgi->query_string());
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


1;
