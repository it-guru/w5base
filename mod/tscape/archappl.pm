package tscape::archappl;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'CapeID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"Internal_Key"),

      new kernel::Field::Text(
                name          =>'archapplid',
                label         =>'ICTO-ID',
                dataobjattr   =>'ICTO_Nummer'),

      new kernel::Field::Text(
                name          =>'fullname',
                searchable    =>0,
                sqlorder      =>'NONE',
                label         =>'fullname',
                dataobjattr   =>"ICTO_Nummer+': '+Name"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'Name'),

      new kernel::Field::Text(
                name          =>'shortname',
                label         =>'Shortname',
                dataobjattr   =>'Kurzbezeichnung'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'Status'),

      new kernel::Field::Text(
                name          =>'organisation',
                label         =>'Organisation',
                dataobjattr   =>'Organisation'),

      new kernel::Field::Group(
                name          =>'orgarea',
                readonly      =>1,
                label         =>'mapped W5Base-OrgArea',
                vjoinon       =>'orgareaid'),

      new kernel::Field::Link(
                name          =>'orgareaid',
                label         =>'OrgAreaID',
                depend        =>['organisation'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $grp=getModuleObject($self->getParent->Config,
                                               "base::grp");
                   my $newrec={};
                   my $d;
                   $newrec->{fullname}=$current->{organisation};
                   my @grpid=$grp->getIdByHashIOMapped(
                                $self->getParent->Self,
                                $newrec,DEBUG=>\$d);
                   if ($#grpid>=0){
                      return($grpid[0]);
                   }
                   return();
                }),


      new kernel::Field::Text(
                name          =>'respvorg',
                depend        =>['organisation'],
                label         =>'planned DigitalHub/ServiceHub',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;

                   if ($mode eq "ViewEditor"){
                      return(1);
                   }
                   if (defined($param{current})){
                      my $rec=$param{current};
                      if ($rec->{respvorg} ne "" &&
                          $rec->{respvorg} ne $rec->{organisation}){
                         return(1);
                      }
                   }
                   return(0);
                },
                dataobjattr   =>'HUB'),


      new kernel::Field::Text(
                name          =>'orgdomain',
                label         =>'Organisation Domain',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'Org_Domain'),

      new kernel::Field::Text(
                name          =>'lorgdomainseg',
                label         =>'Lead OrgDomain Segment',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"CASE ".
                                "WHEN charindex('/D',Org_Domain)>0 THEN ".
                                "trim(substring(Org_Domain,0,".
                                "charindex('/',Org_Domain))) ".
                                "ELSE '' ".
                                "END"),

      new kernel::Field::Text(
                name          =>'orgdomainid',
                label         =>'OrgDomainID',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"CASE ".
                                "WHEN charindex('/D',Org_Domain)>0 AND ".
                                "     charindex('- ',Org_Domain)>0 THEN ".
                                "trim(substring(Org_Domain,".
                                "charindex('/',Org_Domain)+1,".
                                "charindex('-',Org_Domain)-".
                                "charindex('/',Org_Domain)-2))".
                                "ELSE ''".
                                "END"),

      new kernel::Field::Text(
                name          =>'orgdomainname',
                label         =>'OrgDomainName',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"CASE ".
                                "WHEN charindex('/',Org_Domain)>0 THEN ".
                                "trim(right(Org_Domain,len(Org_Domain)-".
                                "charindex('-',Org_Domain))) ".
                                "ELSE '' ".
                                "END"),

      new kernel::Field::Contact(
                name          =>'applmgr',
                label         =>'Application Manager',
                searchable    =>0,
                vjoinon       =>['applmgremail'=>'allemails']),

      new kernel::Field::Text(
                name          =>'applmgremail',
                label         =>'Application Manager E-Mail',
                dataobjattr   =>
                  "(select TOP 1 lower(Mail) from V_DARWIN_EXPORT_AEG ".
                  "where V_DARWIN_EXPORT_AEG.ICTO_Nummer=".
                         "V_DARWIN_EXPORT.ICTO_Nummer and ".
                         "V_DARWIN_EXPORT_AEG.Role='Application Manager' ".
                  "order by V_DARWIN_EXPORT_AEG.Mail)"),

      new kernel::Field::SubList(
                name          =>'w5appl',
                label         =>'W5Base Application',
                group         =>'appl',
                vjointo       =>'TS::appl',          
                vjoinon       =>['id'=>'ictoid'],
                vjoinbase     =>{'cistatusid'=>"<=5"},
                vjoindisp     =>['name','opmode','cistatus']),

      new kernel::Field::SubList(
                name          =>'applvers',
                label         =>'Applicationversions',
                group         =>'applvers',
                vjointo       =>'tscape::applver',          
                vjoinon       =>['archapplid'=>'ictoid'],
                vjoindisp     =>['fullname','status','planed_activation']),

      new kernel::Field::SubList(
                name          =>'roles',
                label         =>'Roles',
                group         =>'roles',
                vjointo       =>'tscape::archapplrole',          
                vjoinon       =>['archapplid'=>'ictoid'],
                vjoindisp     =>['role','email']),

      new kernel::Field::Text(
                name          =>'allconumbers',
                label         =>'all reference Costcenters',
                group         =>'appl',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>['archapplid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my %co;
                   if ($current->{archapplid} ne ""){
                      my $a=getModuleObject($self->getParent->Config,
                                            "TS::appl");
                      $a->SetFilter({ictono=>[$current->{archapplid}],
                                     cistatusid=>"<=5"});
                      foreach my $arec ($a->getHashList(qw(allconumbers))){
                         my $l=$arec->{allconumbers};
                         $l=[$l] if (ref($l) ne "ARRAY");
                         map({$co{$_}++} @$l);
                      }
                   }
                   return([sort(keys(%co))]);
                }),

      new kernel::Field::Textarea(       
                name          =>'description',
                label         =>'description',
                dataobjattr   =>'Beschreibung'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"Last_Update"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"right(replicate('0',35)+Internal_Key,35)"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'none',    # in MSSQL zwingend!
                timezone      =>'CET',
                label         =>'Modification-Date',
                dataobjattr   =>"convert(VARCHAR,Last_Update,20)"),
   );
   $self->{use_distinct}=0;
   $self->{use_CountRecordPing}=1;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(archapplid name  shortname status w5appl));
   $self->setWorktable("V_DARWIN_EXPORT");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tscape"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!Retired\"");
   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","applvers","roles","appl","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}



1;
