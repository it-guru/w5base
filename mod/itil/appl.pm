package itil::appl;
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
use kernel::App::Web::InterviewLink;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
use kernel::MandatorDataACL;
use itil::lib::Listedit;
use itil::lib::BorderChangeHandling;
use finance::costcenter;
use kernel::Scene;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
        kernel::App::Web::InterviewLink kernel::CIStatusTools
        kernel::MandatorDataACL itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   my $haveitsemexp="costcenter.itsem is not null ".
                    "or costcenter.itsemteam is not null ".
                    "or costcenter.itseminbox is not null ".
                    "or costcenter.itsem2 is not null";

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'appl.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                explore       =>110,
                htmleditwidth =>'40%',
                label         =>'CI-State',
                default       =>'3',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                label         =>'Customer Business Manager E-Mail',
                searchable    =>0,
                group         =>'finance',
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Text(
                name          =>'conumber',
                explore       =>500,
                htmleditwidth =>'150px',
                htmlwidth     =>'100px',
                label         =>'Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'appl.conumber'),

      new itil::appl::Link(
                name          =>'conumberexists',
                readonly      =>1,
                dataobjattr   =>"if (costcenter.id is null,0,1)"),

      new kernel::Field::Text(
                name          =>'conodenumber',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'Costcenter-Number',
                vjointo       =>'itil::costcenter',
                vjoinon       =>['conumber'=>'name'],
                vjoindisp     =>'conodenumber'),

      new kernel::Field::Text(
                name          =>'allconumbers',
                label         =>'all reference Costcenters',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>['conumber','systems'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my %co;
                   $co{$current->{conumber}}++;
                   my $fo=$self->getParent->getField("systems");
                   my $sl=$fo->RawValue($current);
                   $sl=[] if (ref($sl) ne "ARRAY");
                   my $s=getModuleObject($self->getParent->Config,
                                         "itil::system");
                   
                   my $fl={id=>[map({$_->{systemid}} @{$sl})]};
                   $s->SetFilter($fl);
                   foreach my $srec ($s->getHashList(qw(conumber))){
                      $co{$srec->{conumber}}++ if ($srec->{conumber} ne "");
                   }
                   return([sort(keys(%co))]);
                }),
       
                


                


      new kernel::Field::Text(
                name          =>'applid',
                explore       =>150,
                htmlwidth     =>'100px',
                htmleditwidth =>'150px',
                readonly     =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Application ID',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                allowcleanup  =>1,
                htmllimit     =>200,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system','systemsystemid',
                                 'reltyp','systemcistatus',
                                 'shortdesc'],
                vjoininhash   =>['system','systemsystemid','systemcistatus',
                                 'systemid','id','reltyp','shortdesc',
                                 'assetassetname','assetid',
                                 'srcsys','srcid','id','cistatusid']),
      new kernel::Field::Group(
                name          =>'itsemteam',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      if ($param{current}->{rawitseminboxid} eq ""){
                         return(1);
                      }
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                label         =>'IT Servicemanagement Team',
                translation   =>'finance::costcenter',
                vjoinon       =>'itsemteamid'),

      new kernel::Field::Link(
                name          =>'itsemteamid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsemteam'),

      new kernel::Field::TextDrop(
                name          =>'itseminbox',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      if ($param{current}->{rawitseminboxid} ne ""){
                         return(1);
                      }
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                translation   =>'finance::costcenter',
                label         =>'IT Servicemanagement Inbox',
                vjointo       =>'base::user',
                vjoinon       =>['itseminboxid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itseminboxid',
                group         =>'itsem',
                selectfix     =>1,
                dataobjattr   =>"if (costcenter.itseminbox is null,".
                                "costcenter.itsem,costcenter.itseminbox)"),

      new kernel::Field::Interface(
                name          =>'rawitseminboxid',
                group         =>'itsem',
                selectfix     =>1,
                dataobjattr   =>"costcenter.itseminbox"),

      new kernel::Field::TextDrop(
                name          =>'itsem',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      if ($param{current}->{rawitseminboxid} eq ""){
                         return(1);
                      }
                   }
                   return(0);
                },
                group         =>'itsem',
                label         =>'IT Servicemanager',
                translation   =>'finance::costcenter',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoinon       =>['itsemid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itsemid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem'),

      new kernel::Field::Interface(
                name          =>'conumber_delmgrid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.delmgr'),

      new kernel::Field::TextDrop(
                name          =>'itsem2',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      if ($param{current}->{rawitseminboxid} eq ""){
                         return(1);
                      }
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                translation   =>'finance::costcenter',
                label         =>'Deputy IT Servicemanager',
                vjointo       =>'base::user',
                vjoinon       =>['itsem2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itsem2id',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem2'),



      new kernel::Field::Group(
                name          =>'responseteam',
                group         =>'finance',
                label         =>'CBM Team',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                vjoinon       =>'responseteamid'),

      new itil::appl::Link(
                name          =>'responseteamid',
                wrdataobjattr =>'appl.responseteam',
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsemteam,appl.responseteam)"),

      new kernel::Field::Contact(
                name          =>'sem',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'finance',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Customer Business Manager',
                vjoinon       =>'semid'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                group         =>'finance',
                label         =>'Customer Business Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'sem2email',
                group         =>'finance',
                label         =>'Deputy Customer Business Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['sem2id'=>'userid'],
                vjoindisp     =>'email'),

      new itil::appl::Link(
                name          =>'semid',
                wrdataobjattr =>'appl.sem',
                dataobjattr   =>"if ($haveitsemexp,".
                                "if (costcenter.itseminbox is not null,".
                                    "costcenter.itseminbox,costcenter.itsem),".
                                "appl.sem)"),

      new kernel::Field::Group(
                name          =>'businessteam',
                explore       =>'200',
                group         =>'technical',
                label         =>'Business Team',
                vjoinon       =>'businessteamid'),

      new kernel::Field::TextDrop(
                name          =>'businessdepart',
                htmlwidth     =>'300px',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                group         =>'technical',
                label         =>'Business Department',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['businessdepartid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'businessdepartid',
                searchable    =>0,
                readonly      =>1,
                label         =>'Business Department ID',
                group         =>'technical',
                depend        =>['businessteamid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $businessteamid=$current->{businessteamid};
                   if ($businessteamid ne ""){
                      my $grp=getModuleObject($self->getParent->Config,
                                              "base::grp");
                      my $businessdepartid=
                         $grp->getParentGroupIdByType($businessteamid,"depart");
                      return($businessdepartid);
                   }
                   return(undef);
                }),

      new kernel::Field::Contact(
                name          =>'tsm',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                explore       =>'190',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "ROLEBASED"){
                      return(1);
                   }
                   return(0);
                },
                group         =>'technical',
                label         =>'Technical Solution Manager',
                vjoinon       =>'tsmid'),

      new kernel::Field::Contact(
                name          =>'techresponse',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                explore       =>190,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "FUNCBASED"){
                      return(1);
                   }
                   return(0);
                },
                group         =>'technical',
                label         =>'Technical Responsible',
                vjoinon       =>'tsmid'),

      new kernel::Field::Contact(
                name          =>'opm',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'opmgmt',
                explore       =>'195',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "ROLEBASED"){
                      return(1);
                   }
                   return(0);
                },
                AllowEmpty    =>1,
                label         =>'Operation Manager',
                vjoinon       =>'opmid'),

      new kernel::Field::Contact(
                name          =>'opresponse',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                explore       =>195,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "FUNCBASED"){
                      return(1);
                   }
                   return(0);
                },
                AllowEmpty    =>1,
                group         =>'opmgmt',
                label         =>'Operational Responsible',
                vjoinon       =>'opmid'),

      new kernel::Field::SubList(
                name          =>'directlicenses',
                label         =>'direct linked Licenses',
                group         =>'licenses',
                allowcleanup  =>1,
                vjointo       =>'itil::lnklicappl',
                vjoinbase     =>[{liccontractcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['liccontract','quantity','comments']),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                htmldetail    =>'NotEmpty',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['fullname','swnature','is_dbs','is_mw'],
                vjoininhash   =>['fullname','swnature','is_dbs',
                                 'is_mw','cistatusid','id',
                                 'systemid','itclustsid','srcsys','srcid']),

      new kernel::Field::Number(
                name          =>'swinstancecount',
                label         =>'Instance count',
                group         =>'swinstances',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['swinstances'],
                onRawValue    =>\&calculateInstanceCount),

      new kernel::Field::Number(
                name          =>'mwswinstancecount',
                label         =>'MW Instance count',
                group         =>'swinstances',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['swinstances'],
                onRawValue    =>\&calculateInstanceCount),

      new kernel::Field::Number(
                name          =>'dbsswinstancecount',
                label         =>'DBS Instance count',
                group         =>'swinstances',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['swinstances'],
                onRawValue    =>\&calculateInstanceCount),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Cluster services',
                group         =>'services',
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['itclustsvc']),

      new kernel::Field::SubList(
                name          =>'itcloudareas',
                label         =>'CloudAreas',
                group         =>'itcloudareas',
                htmldetail    =>'NotEmpty',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjointo       =>'itil::itcloudarea',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['fullname','cistatus'],
                vjoininhash   =>['fullname','cistatusid',
                                 'id','mdate','cdate','allowuncleanseq']),

      new kernel::Field::SubList(
                name          =>'businessservices',
                label         =>'provided Businessservices',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                vjoinbase     =>{cistatusid=>"<=5"},
                group         =>'businessservices',
                vjointo       =>'itil::businessservice',
                vjoinon       =>['id'=>'servicecompapplid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::SubList(
                name          =>'applurl',
                label         =>'Communication URLs',
                group         =>'applurl',
                vjointo       =>'itil::lnkapplurl',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['name'],
                vjoininhash   =>['name','id']),

      new kernel::Field::SubList(
                name          =>'addcis',
                label         =>'additional used Config-Items',
                group         =>'addcis',
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkadditionalci',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['name','ciusage']),

      new kernel::Field::SubList(
                name          =>'tags',
                label         =>'ItemTags',
                group         =>'tags',
                htmldetail    =>'NotEmpty',
                vjoinbase     =>{'internal'=>'0','ishidden'=>'0'},
                vjointo       =>'itil::tag_appl',
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['name','value']),

      new kernel::Field::SubList(
                name          =>'alltags',
                label         =>'all ItemTags',
                group         =>'tags',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'itil::tag_appl',
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['name','value'],
                vjoininhash   =>['name','value','id','mdate','cdate','uname']),

      new kernel::Field::Text(
                name          =>'businessteambossid',
                group         =>'technical',
                label         =>'Business Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0,
                depend        =>['businessteamid']),

      new kernel::Field::Text(
                name          =>'businessteamboss',
                group         =>'technical',
                label         =>'Business Team Boss',
                onRawValue    =>\&getTeamBoss,
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['businessteambossid']),

      new kernel::Field::Text(
                name          =>'businessteambossemail',
                searchable    =>0,
                group         =>'technical',
                label         =>'Business Team Boss EMail',
                onRawValue    =>\&getTeamBossEMail,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['businessteambossid']),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                group         =>'technical',
                label         =>'Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsmphone',
                group         =>'technical',
                label         =>'Technical Solution Manager Office-Phone',
                vjointo       =>'base::user',
                htmlwidth     =>'200px',
                nowrap        =>1,
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::TextDrop(
                name          =>'tsmmobile',
                group         =>'technical',
                label         =>'Technical Solution Manager Mobile-Phone',
                vjointo       =>'base::user',
                htmlwidth     =>'200px',
                htmldetail    =>0,
                nowrap        =>1,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_mobile'),

      new kernel::Field::TextDrop(
                name          =>'tsmposix',
                group         =>'technical',
                label         =>'Technical Solution Manager POSIX',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'posix'),

      new kernel::Field::Interface(
                name          =>'tsmid',
                group         =>'technical',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Interface(
                name          =>'opmid',
                group         =>'opmgmt',
                dataobjattr   =>'appl.opm'),


      new kernel::Field::TextDrop(
                name          =>'delmgr',
                group         =>'delmgmt',
                readonly      =>1,
                label         =>'Service Delivery Manager',
                translation   =>'finance::costcenter',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'delmgr2',
                group         =>'delmgmt',
                readonly      =>1,
                label         =>'Deputy Service Delivery Manager',
                translation   =>'finance::costcenter',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                vjointo       =>'base::user',
                vjoinon       =>['delmgr2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Group(
                name          =>'delmgrteam',
                group         =>'delmgmt',
                readonly      =>1,
                translation   =>'finance::costcenter',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Service Delivery-Management Team',
                vjoinon       =>'delmgrteamid'),


      new kernel::Field::Link(
                name          =>'delmgrteamid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsemteam,costcenter.delmgrteam)"),

      new kernel::Field::Link(
                name          =>'delmgrid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "if (costcenter.itseminbox is not null,".
                                    "costcenter.itseminbox,costcenter.itsem),".
                                "costcenter.delmgr)"),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "if (costcenter.itseminbox is not null,".
                                    "costcenter.itseminbox,costcenter.itsem2),".
                                "costcenter.delmgr2)"),

      new kernel::Field::Link(
                name          =>'haveitsem',
                readonly      =>1,
                selectfix     =>1,
                dataobjattr   =>"if ($haveitsemexp,1,0)"),

      new kernel::Field::Group(
                name          =>'customer',
                group         =>'customer',
                SoftValidate  =>1,
                label         =>'Customer',
                vjoinon       =>'customerid'),

      new kernel::Field::Link( 
                name          =>'customerid',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Contact(
                name          =>'sem2',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'finance',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Deputy Customer Business Manager',
                vjoinon       =>'sem2id'),

      new itil::appl::Link(
                name          =>'sem2id',
                dataobjattr   =>"if ($haveitsemexp,".
                                "if (costcenter.itseminbox is not null,".
                                    "costcenter.itseminbox,costcenter.itsem2),".
                                "appl.sem2)",
                wrdataobjattr =>'appl.sem2'),


      new kernel::Field::Contact(
                name          =>'tsm2',
                AllowEmpty    =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "ROLEBASED"){
                      return(1);
                   }
                   return(0);
                },
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager',
                vjoinon       =>'tsm2id'),

      new kernel::Field::Contact(
                name          =>'techresponse2',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "FUNCBASED"){
                      return(1);
                   }
                   return(0);
                },
                group         =>'technical',
                label         =>'Deputy Technical Responsible',
                vjoinon       =>'tsm2id'),

      new kernel::Field::Contact(
                name          =>'opm2',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "ROLEBASED"){
                      return(1);
                   }
                   return(0);
                },
                group         =>'opmgmt',
                label         =>'Deputy Operation Manager',
                vjoinon       =>'opm2id'),

      new kernel::Field::Contact(
                name          =>'opresponse2',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "FUNCBASED"){
                      return(1);
                   }
                   return(0);
                },
                AllowEmpty    =>1,
                group         =>'opmgmt',
                label         =>'Deputy Operational Responsible',
                vjoinon       =>'opm2id'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsm2posix',
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager POSIX',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'posix'),

      new kernel::Field::Interface(
                name          =>'tsm2id',
                group         =>'technical',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Interface(
                name          =>'opm2id',
                group         =>'opmgmt',
                dataobjattr   =>'appl.opm2'),

      new kernel::Field::Select(
                name          =>'customerprio',
                group         =>'customer',
                label         =>'Customers Application Prioritiy',
                value         =>['1','2','3'],
                default       =>'2',
                htmleditwidth =>'50px',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Select(
                name          =>'criticality',
                group         =>'customer',
                label         =>'Criticality',
                allowempty    =>1,
                value         =>['CRnone','CRlow','CRmedium','CRhigh',
                                 'CRcritical'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.criticality'),

      new kernel::Field::Text(
                name          =>'applgrp',
                label         =>'Applicationgroup',
                readonly      =>'1',
                htmldetail    =>'NotEmpty',
                group         =>'customer',
                weblinkto     =>'itil::applgrp',
                weblinkon     =>['applgrpid'=>'id'],
                dataobjattr   =>'applgrp.name'),

      new kernel::Field::Interface(
                name          =>'applgrpid',
                readonly      =>'1',
                group         =>'customer',
                dataobjattr   =>'lnkapplgrpappl.applgrp'),

      new kernel::Field::Group(
                name          =>'responseorg',
                readonly      =>'1',
                htmldetail    =>'NotEmpty',
                group         =>'customer',
                label         =>'responsible Organisation',
                vjoinon       =>'responseorgid'),

      new kernel::Field::Interface(
                name          =>'responseorgid',
                readonly      =>'1',
                group         =>'customer',
                dataobjattr   =>"applgrp.responseorg"),

      new kernel::Field::Text(
                name          =>'mgmtitemgroup',
                group         =>'customer',
                label         =>'central managed CI groups',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>1,
                htmldetail    =>1,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>['PCONTROL','CFGROUP'],
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Text(
                name          =>'reportinglabel',
                group         =>'customer',
                label         =>'Reporting Label',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'RLABEL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Contact(
                name          =>'applowner',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'customer',
                label         =>'Application Owner',
                vjoinon       =>'applownerid'),

      new kernel::Field::Link(
                name          =>'applownerid',
                group         =>'customer',
                dataobjattr   =>'appl.applowner'),

      new kernel::Field::Contact(
                name          =>'applmgr',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                explore       =>170,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "ROLEBASED"){
                      return(1);
                   }
                   return(0);
                },
                group         =>'functional',
                label         =>'Application Manager',
                vjoinon       =>'applmgrid'),

      new kernel::Field::Interface(
                name          =>'applmgrid',
                group         =>'customer',
                dataobjattr   =>'appl.applmgr'),

      new kernel::Field::Contact(
                name          =>'overallresponse',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                explore       =>170,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{rmethod} eq "FUNCBASED"){
                      return(1);
                   }
                   return(0);
                },
                group         =>'functional',
                label         =>'Overall Responsible',
                vjoinon       =>'applmgrid'),

      new kernel::Field::Text(
                name          =>'itnormodel',
                group         =>'customer',
                label         =>'NOR Model to use',
                readonly      =>1,
                searchable    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $UC=$self->getParent->Cache->{User}->{Cache};
                   if ($UC->{$ENV{REMOTE_USER}}->{rec}->{dateofvsnfd} ne ""){
                      return(1);
                   }
                   return(0);
                },
                vjoinon       =>['itnormodelid'=>'id'],
                vjointo       =>'itil::itnormodel',
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'itnormodelid',
                group         =>'customer',
                label         =>'NOR ModelID',
                dataobjattr   =>'if (appladv.itnormodel is null,'.
                                '0,appladv.itnormodel)'),


      new kernel::Field::Boolean(
                name          =>'processingpersdata',
                label         =>'processing of person related data',
                group         =>'customer',
                searchable    =>0,
                translation   =>'itil::appladv',
                htmldetail    =>0,
                vjointo       =>'itil::appladv',
                vjoinon       =>['appladvid'=>'id'],
                vjoindisp     =>'processingpersdata'),

      new kernel::Field::Link(
                name          =>'appladvid',
                group         =>'customer',
                label         =>'ApplAdvID',
                dataobjattr   =>'appladv.id'),

      new kernel::Field::Select(
                name          =>'avgusercount',
                group         =>'functional',
                label         =>'Average user count',
                allowempty    =>1,
                value         =>['0','10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.avgusercount'),

      new kernel::Field::Select(
                name          =>'namedusercount',
                group         =>'functional',
                label         =>'Administrated user count',
                allowempty    =>1,
                value         =>['0','10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.namedusercount'),

      new kernel::Field::Select(
                name          =>'secstate',
                group         =>'customer',
                label         =>'Security state',
                uivisible     =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(1);
                   }
                   return(0);
                },
                allowempty    =>1,
                value         =>['','vsnfd'],
                transprefix   =>'SECST.',
                dataobjattr   =>'appl.secstate'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                selectfix     =>1,
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Customer Contracts',
                group         =>'custcontracts',
                readonly      =>1,
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['custcontract','custcontractcistatus',
                                 'fraction'],
                vjoinbase     =>[{custcontractcistatusid=>'<=5'}],
                vjoininhash   =>['custcontractid','custcontractcistatusid',
                                 'modules',
                                 'custcontract','custcontractname']),

      new kernel::Field::SubList(
                name          =>'supcontracts',
                label         =>'Support/Maintenence Contracts',
                group         =>'supcontracts',
                readonly      =>1,
                vjointo       =>'itil::lnkapplsupcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['supcontract','supcontractcistatus',
                                 'fraction'],
                vjoinbase     =>[{supcontractcistatusid=>'<=5'}],
                vjoininhash   =>['supcontractid','supcontractcistatusid',
                                 'supcontract','supcontractname']),

      new kernel::Field::SubList(
                name          =>'interfaces',
                label         =>'Interfaces',
                group         =>'interfaces',
                forwardSearch =>1,
                htmllimit     =>200,
                subeditmsk    =>'subedit.appl',
                depend        =>['isnoifaceappl','interfacescount'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}{isnoifaceappl} &&
                       $param{current}{interfacescount}==0) {
                      return(0);
                   }
                   return(1);
                },
                vjointo       =>'itil::lnkapplappl',
                vjoinbase     =>[{toapplcistatus=>"<=5",cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'fromapplid'],
                vjoindisp     =>['toappl','ifrelcontype','conproto','conmode',
                                 'comments'],
                vjoindispminsw=>['0','0','0','0','800'],
                vjoininhash   =>['toappl','contype','conproto','conmode',
                                 'toapplid', 'comments','id','cistatusid',
                                 'gwapplid','fullname',
                                 'ifagreementdocsz','ifagreementneeded']),

      new kernel::Field::Number(
                name          =>'interfacescount',
                label         =>'Interfaces count',
                group         =>'interfaces',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['interfaces'],
                onRawValue    =>\&calculateInterfacesCount),

      new kernel::Field::SubList(
                name          =>'systemnames',
                label         =>'active systemnames',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system']),

      new kernel::Field::SubList(
                name          =>'systemids',
                label         =>'active systemids',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['systemsystemid']),

      new kernel::Field::Number(
                name          =>'systemcount',
                label         =>'system count',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['systems'],
                onRawValue    =>\&calculateSysCount),

      new kernel::Field::Number(
                name          =>'systemslogicalcpucount',
                label         =>'log cpucount',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>\&calculateLogicalCpuCount),

      new kernel::Field::Number(
                name          =>'systemsrelphyscpucount',
                label         =>'relative phys. cpucount',
                group         =>'systems',
                htmldetail    =>0,
                precision     =>2,
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>\&calculateRelPhysCpuCount),

      new kernel::Field::Select(
               name          =>'opmode',
                #group         =>'misc',
                label         =>'primary operation mode',
                transprefix   =>'opmode.',
                value         =>['',
                                 'prod',
                                 'test',
                                 'devel',
                                 'education',
                                 'approvtest',
                                 'reference',
                                 'cbreakdown'],  # see also opmode at system
                htmleditwidth =>'200px',
                dataobjattr   =>'appl.opmode'),

      new kernel::Field::Select(
                name          =>'rmethod',
                label         =>'Responsibility Model',
                selectfix     =>1,
                transprefix   =>'rmeth.',
                value         =>['ROLEBASED',
                                 'FUNCBASED'],
                htmleditwidth =>'200px',
                dataobjattr   =>'appl.respmethod'),


      new kernel::Field::Text(
                name          =>'assetassetids',
                label         =>'used AssetIDs',
                group         =>'systems',
                searchable    =>1,
                uploadable    =>0,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"},
                                 {assetassetname=>'!""'}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'assetassetname'),

      new kernel::Field::Link(
                name          =>'assetids',
                label         =>'used W5Base AssetIDs',
                group         =>'systems',
                searchable    =>0,
                uploadable    =>0,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'assetid'),


      new kernel::Field::Text(
                name          =>'itfarms',
                label         =>'used Serverfarms',
                group         =>'systems',
                searchable    =>0,  # funktioniert nicht wegen doppelt indirekt
                uploadable    =>0,
                htmldetail    =>0,
                vjointo       =>'itil::itfarm',
                vjoinon       =>['assetids'=>'assetids'],
                vjoindisp     =>'fullname'),


      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                dataobjattr   =>'appl.description'),

      new kernel::Field::Textarea(
                name          =>'currentvers',
                label         =>'Application Version',
                dataobjattr   =>'appl.currentvers'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'appl.allowifupdate'),

      new kernel::Field::Boolean(
                name          =>'isnosysappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no system or cloud components',
                dataobjattr   =>'appl.is_applwithnosys'),

      new kernel::Field::Boolean(
                name          =>'isnoifaceappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no interfaces',
                dataobjattr   =>'appl.is_applwithnoiface'),

      new kernel::Field::Boolean(
                name          =>'isnotarchrelevant',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is not architecture relevant',
                dataobjattr   =>'appl.isnotarchrelevant'),

      new kernel::Field::Boolean(
                name          =>'allowdevrequest',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow developer request workflows',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'allowbusinesreq',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow business request workflows',
                container     =>'additional'),

      #new kernel::Field::Select(
      #          name          =>'eventlang',
      #          group         =>'control',
      #          htmleditwidth =>'30%',
      #          value         =>['en','de','en-de','de-en'],
      #          label         =>'default language for eventinformations',
      #          dataobjattr   =>'appl.eventlang'),


      new kernel::Field::Boolean(
                name          =>'issoxappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is mangaged by rules of SOX or ICS',
                dataobjattr   =>'appl.is_soxcontroll'),

      new kernel::Field::Text(
                name          =>'mon1url',
                group         =>'control',
                htmldetail    =>0,
                label         =>'Monitoring URL1',
                dataobjattr   =>'appl.mon1url'),

      new kernel::Field::Text(
                name          =>'mon2url',
                group         =>'control',
                htmldetail    =>0,
                label         =>'Monitoring URL2',
                dataobjattr   =>'appl.mon2url'),

      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                label         =>'Service&Support Class',
                group         =>'monisla',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'appl.servicesupport'),


      new kernel::Field::Select(
                name          =>'slacontroltoolname',
                group         =>'monisla',
                label         =>'SLA control tool type',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::slacontroltool',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::slacontroltool',
                   cistatusid=>\'4'
                },
                vjoinon       =>['slacontroltool'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Link(
                name          =>'slacontroltool',
                group         =>'monisla',
                label         =>'raw SLA control tool type',
                dataobjattr   =>'appl.slacontroltool'),

      new kernel::Field::Number(
                name          =>'slacontravail',
                group         =>'monisla',
                htmlwidth     =>'100px',
                precision     =>5,
                unit          =>'%',
                searchable    =>0,
                label         =>'SLA availibility guaranted by contract',
                dataobjattr   =>'appl.slacontravail'),

      new kernel::Field::Select(
                name          =>'slacontrbase',
                group         =>'monisla',
                label         =>'SLA availibility calculation base',
                transprefix   =>'slabase.',
                searchable    =>0,
                value         =>['',
                                 'month',
                                 'year'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.slacontrbase'),

      new kernel::Field::Select(
                name          =>'applbasemoniname',
                group         =>'monisla',
                label         =>'Application base monitoring',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                   cistatusid=>\'4'
                },
                jsonchanged   =>"
                   var elements=document.forms[0].elements;
                   var moni=elements['Formated_applbasemoniname'];
                   var stat=elements['Formated_applbasemonistatus'];
                   if (moni && stat){
                      var v=moni.options[moni.selectedIndex].value;
                      if (v.match(/no monitoring/)){
                         stat.value='NOMONI';
                      }
                      else{
                         var s=stat.options[stat.selectedIndex].value;
                         if (s=='NOMONI'){
                            stat.value='';
                         }
                      }
                   }
                ",
                vjoinon       =>['applbasemoni'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Link(
                name          =>'applbasemoni',
                group         =>'monisla',
                label         =>'raw Application base monitoring',
                dataobjattr   =>'appl.applbasemoni'),


      new kernel::Field::Select(
                name          =>'applbasemonistatus',
                group         =>'monisla',
                label         =>'Application base monitoring status',
                transprefix   =>'monistatus.',
                value         =>['',
                                 'NOMONI',
                                 'MONISIMPLE',
                                 'MONIAUTOIN'],
                htmleditwidth =>'280px',
                jsonchanged   =>"
                   var elements=document.forms[0].elements;
                   var moni=elements['Formated_applbasemoniname'];
                   var stat=elements['Formated_applbasemonistatus'];
                   if (moni && stat){
                      var v=stat.options[stat.selectedIndex].value;
                      if (v.match(/NOMONI/)){
                         moni.value='-no monitoring-';
                      }
                      else{
                         var s=moni.options[moni.selectedIndex].value;
                         if (s=='-no monitoring-'){
                            moni.value='';
                         }
                      }
                   }
                ",
                dataobjattr   =>'appl.applbasemonistatus'),

      new kernel::Field::Group(
                name          =>'applbasemoniteam',
                group         =>'monisla',
                label         =>'Application base monitoring resonsible Team',
                AllowEmpty    =>1,
                vjoinon       =>'applbasemoniteamid'),

      new kernel::Field::Link(
                name          =>'applbasemoniteamid',
                group         =>'monisla',
                label         =>'Application base monitoring resonsible TeamID',
                dataobjattr   =>'appl.applbasemoniteam'),


      new kernel::Field::Text(
                name          =>'kwords',
                group         =>'misc',
                label         =>'Keywords',
                dataobjattr   =>'appl.kwords'),

      new kernel::Field::Text(
                name          =>'swdepot',
                group         =>'misc',
                label         =>'Software-Depot path',
                dataobjattr   =>'appl.swdepot'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                group         =>'mutimes',
                searchable    =>0, 
                label         =>'Maintenance Window',
                dataobjattr   =>'appl.maintwindow'),


      new kernel::Field::TimeSpans(
                name          =>'usetimes',
                htmlwidth     =>'150px',
                depend        =>['issupport'],
                tspantype     =>{'M'=>'main use time',
                                 'S'=>'sec. use time',
                                 'O'=>'offline time'},
                tspantypeproc =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $blk=shift;
                   $blk->[4]="transparent";
                   if ($blk->[2] eq "on" || $blk->[2] eq "legend"){
                      $blk->[4]="blue";
                      $blk->[4]="lightblue" if ($blk->[3] eq "S");
                      $blk->[4]="yellow" if ($blk->[3] eq "O");
                   }
                },
                tspantypemaper=>sub{
                   my $self=shift;
                   my $type=shift;
                   my $t=shift;
                   $type=uc($type);
                   #$type="M" if ($type eq "");
                   return($type);
                },
                tspanlegend   =>1,
                tspandaymap   =>[1,1,1,1,1,1,1,0],
                group         =>'mutimes',
                label         =>'use-times',
                dataobjattr   =>'appl.usetime'),

      new kernel::Field::Textarea(
                name          =>'tempexeptusetime',
                group         =>'mutimes',
                searchable    =>0, 
                label         =>'temporary exeptions in use times',
                htmlheight    =>40,
                dataobjattr   =>'appl.tempexeptusetime'),

      new kernel::Field::Email(
                name          =>'inmcontact',
                AllowEmpty    =>1,
                group         =>'inmchm',
                label         =>'Incident-Ticket contact email',
                dataobjattr   =>'appl.inmcontact'),

      new kernel::Field::Email(
                name          =>'chmcontact',
                AllowEmpty    =>1,
                group         =>'inmchm',
                label         =>'Change-Ticket contact email',
                dataobjattr   =>'appl.chmcontact'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                searchable    =>0, 
                dataobjattr   =>'appl.comments'),

      new kernel::Field::Textarea(
                name          =>'socomments',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'socomments',
                label         =>'comments to switch-over behaviour',
                searchable    =>0, 
                dataobjattr   =>'appl.socomments'),

      new kernel::Field::Select(
                name          =>'soslanumdrtests',
                label         =>'SLA number Disaster-Recovery test interval',
                group         =>'sodrgroup',
                htmleditwidth =>'220',
                transprefix   =>'DRTESTPERYEAR.',
                value         =>[
                                 '0.5',
                                 '0.3',
                                 '1',
                                 '2',
                                 '4',
                                 '12',
                                 '0'
                                ],
                default       =>'0.5',
                searchable    =>0,
                dataobjattr   =>'appl.soslanumdrtests'),

      new kernel::Field::Number(
                name          =>'soslanumdrtestinterval',
                label         =>'SLA number Disaster-Recovery tests per year',
                group         =>'sodrgroup',
                htmleditwidth =>'120',
                precision     =>2,
                htmldetail    =>'0',
                default       =>'0.5',
                searchable    =>0,
                dataobjattr   =>'appl.soslanumdrtests'),

      new kernel::Field::Number(
                name          =>'sosladrduration',
                label         =>'SLA planned Disaster-Recovery duration',
                group         =>'sodrgroup',
                unit          =>'min',
                searchable    =>0,
                dataobjattr   =>'appl.sosladrduration'),

#      new kernel::Field::WorkflowLink(
#                name          =>'olastdrtestwf',
#                AllowEmpty    =>1,
#                readonly      =>1,
#                htmldetail    =>0,
#                label         =>'last Disaster-Recovery test (CHM-WorkflowID)',
#                group         =>'sodrgroup',
#                vjoinon       =>'olastdrtestwfid'),
#
#      new kernel::Field::Link(
#                name          =>'olastdrtestwfid',
#                label         =>'last Disaster-Recovery test (CHM-WorkflowID)',
#                readonly      =>1,
#                htmldetail    =>0,
#                group         =>'sodrgroup',
#                searchable    =>0,
#                dataobjattr   =>'appl.solastdrtestwf'),
#
#      new kernel::Field::Date(
#                name          =>'solastdrdate',
#                label         =>'last Disaster-Recovery test (WorkflowEnd)',
#                readonly      =>1,
#                htmldetail    =>0,
#                dayonly       =>1,
#                group         =>'sodrgroup',
#                vjointo       =>'base::workflow',
#                vjoinon       =>['olastdrtestwfid'=>'id'],
#                vjoindisp     =>'eventend',
#                searchable    =>0),

      new kernel::Field::Select(
                name          =>'soslanumclusttests',
                label         =>'SLA number Cluster-Switch test interval',
                group         =>'soclustgroup',
                htmleditwidth =>'220',
                transprefix   =>'CLUSTTESTPERYEAR.',
                value         =>[
                                 '0.5',
                                 '0.3',
                                 '1',
                                 '2',
                                 '4',
                                 '0'],
                default       =>'0.5',
                searchable    =>0,
                dataobjattr   =>'appl.soslanumclusttests'),

      new kernel::Field::Number(
                name          =>'soslaclustduration',
                label         =>'SLA maximum cluster service '.
                                'take over duration',
                group         =>'soclustgroup',
                searchable    =>0,
                unit          =>'min',
                dataobjattr   =>'appl.soslaclustduration'),

#      new kernel::Field::WorkflowLink(
#                name          =>'solastclusttestwf',
#                label         =>'last Cluster-Service switch '.
#                                'test (CHM-WorkflowID)',
#                readonly      =>1,
#                htmldetail    =>0,
#                AllowEmpty    =>1,
#                group         =>'soclustgroup',
#                vjoinon       =>'solastclusttestwfid'),
#
#      new kernel::Field::Link(
#                name          =>'solastclusttestwfid',
#                htmleditwidth =>'120',
#                label         =>'last Cluster-Service switch test (WorkflowID)',
#                group         =>'soclustgroup',
#                htmldetail    =>0,
#                readonly      =>1,
#                searchable    =>0,
#                dataobjattr   =>'appl.solastclusttestwf'),

#      new kernel::Field::Date(
#                name          =>'solastclustswdate',
#                label         =>'last Cluster-Service switch test (WorkflowEnd)',
#                group         =>'soclustgroup',
#                vjointo       =>'base::workflow',
#                vjoinon       =>['solastclusttestwfid'=>'id'],
#                vjoindisp     =>'eventend',
#                dayonly       =>1,
#                readonly      =>1,
#                htmldetail    =>0,
#                searchable    =>0),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::appl',
                group         =>'attachments'),

      new kernel::Field::SubList(
                name          =>'individualAttr',
                label         =>'individual attributes',
                group         =>'individualAttr',
                allowcleanup  =>1,
                forwardSearch =>1,
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::grpindivappl',
                vjoinon       =>['id'=>'srcdataobjid'],
                vjoindisp     =>['fieldname','indivfieldvalue']),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                htmldetail    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'appl.additional'),


      new kernel::Field::Interface(
                name          =>'servicetrees',
                label         =>'service trees',
                readonly      =>1,
                searchable    =>0,
                group         =>'businessservices',
                depend        =>['id','name'],
                onRawValue    =>\&itil::lib::Listedit::calculateServiceTrees),

      new kernel::Field::Interface(
                name          =>'involvedbusinessprocessesids',
                label         =>'involved in businessprocessesIDs',
                readonly      =>1,
                searchable    =>0,
                group         =>'businessservices',
                depend        =>['name','id','servicetrees'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $stfld=$app->getField("servicetrees",$current);
                   my $st=$stfld->RawValue($current);

                   my @bpids=();
                   if (ref($st) eq "HASH" && exists($st->{obj})){
                      foreach my $obj (values(%{$st->{obj}})){
                         if ($obj->{dataobj}=~m/::businessprocess$/){
                            if (!in_array(\@bpids,$obj->{dataobjid})){
                               push(@bpids,$obj->{dataobjid});
                            }
                         }
                      } 
                   }
                   return(\@bpids);
                }),

      new kernel::Field::SubList(
                name          =>'involvedbusinessprocesses',
                label         =>'involved in businessprocesses',
                group         =>'businessservices',
                depend        =>['name','id','servicetrees',
                                 'involvedbusinessprocessesids'],
                htmldetail    =>'0',
                vjointo       =>'crm::businessprocess',
                vjoinbase     =>[{'cistatusid'=>\'4'}],
                vjoinon       =>['involvedbusinessprocessesids'=>'id'],
                vjoindisp     =>['fullname','customerprio','importance']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Text(
                name          =>'customerapplicationname',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'customer',
                label         =>'nameing of application by customer',
                dataobjattr   =>"if (itcrmappl.name is null or ".
                                "itcrmappl.name='',appl.name,itcrmappl.name)"),

      new kernel::Field::Text(
                name          =>'customerapplicationid',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'customer',
                label         =>'ID of application by customer',
                dataobjattr   =>"if (itcrmappl.custapplid is null or ".
                                "itcrmappl.custapplid='',appl.applid,".
                                "itcrmappl.custapplid)"),

      new kernel::Field::SubList(
                name          =>'oncallphones',
                searchable    =>0,
                htmldetail    =>0,
                uivisible     =>1,
                readonly      =>1,
                label         =>'oncall Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                vjointo       =>'base::phonenumber',
                vjoinon       =>['id'=>'refid'],
                vjoinbase     =>{'rawname'=>'phoneRB'},
                vjoindisp     =>['phonenumber','shortedcomments']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'appl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'appl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'appl.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"appl.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(appl.id,35,'0')"),

      new kernel::Field::SubList(
                name          =>'accountnumbers',
                label         =>'Account numbers',
                group         =>'accountnumbers',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkaccountingno',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['name','cdate','comments']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'appl.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'appl.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'appl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'appl.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'appl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'appl.realeditor'),

      new kernel::Field::Link(
                name          =>'secapplmgr2id',
                noselect      =>'1',
                dataobjattr   =>'lnkapplmgr2.targetid'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::XMLInterface(
                name          =>'itemsummary',
                label         =>'total Config-Item Summary',
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $parrent=$self->getParent();
                   my $summary={};
                   my $bk=0;
                   if ($parrent->can("ItemSummary")){
                      $bk=$parrent->ItemSummary($current,$summary);
                   }
                   if ($bk){
                      $summary->{xmlstate}="valid";
                      return({xmlroot=>$summary}); 
                   }
                   return({xmlroot=>{xmlstate=>"invalid"}});
                }),

      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'appl.lastqcheck'),
      new kernel::Field::QualityResponseArea(),
      new kernel::Field::EnrichLastDate(
                dataobjattr   =>'appl.lastqenrich'),

      new kernel::Field::Date(
                name          =>'lrecertreqdt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert request date',
                dataobjattr   =>'appl.lrecertreqdt'),

      new kernel::Field::Date(
                name          =>'lrecertreqnotify',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert request notification date',
                dataobjattr   =>'appl.lrecertreqnotify'),

      new kernel::Field::Date(
                name          =>'lrecertdt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert date',
                dataobjattr   =>'appl.lrecertdt'),

      new kernel::Field::Interface(
                name          =>'lrecertuser',
                group         =>'qc',
                label         =>'last recert userid',
                htmldetail    =>'0',
                dataobjattr   =>"appl.lrecertuser")


   );
   $self->AddGroup("external",translation=>'itil::appl');
   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };
   $self->{workflowlink}={ workflowkey=>[id=>'affectedapplicationid']
                         };
   $self->{use_distinct}=1;
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->setDefaultView(qw(name mandator cistatus mdate));
   $self->setWorktable("appl");
   $self->{individualAttr}={
      dataobj=>'itil::grpindivappl'
   };

   return($self);
}



sub ItemSummary
{
   my $self=shift;
   my $current=shift;
   my $summary=shift;

   my $o=getModuleObject($self->Config,$self->Self);
   $o->SetFilter({id=>\$current->{id}});
   my ($rec,$msg)=$o->getOnlyFirst(qw(systems urlofcurrentrec));
   my $rec=ObjectRecordCodeResolver($rec);
   $summary->{systems}=$rec->{systems};
   $summary->{urlofcurrentrec}=$rec->{urlofcurrentrec};
   return(0) if (!$o->Ping());

   my $ids=$self->getRelatedWorkflows($current->{id},
             {timerange=>">now-56d"});  # 8 Wochen
   $summary->{workflow}=[values(%$ids)];
   return(0) if (!$self->Ping());

   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub getFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;

   my @l=$self->SUPER::getFieldObjsByView($view,%param);

   # 
   # hack to prevent display of "itnormodel" in outputs other then
   # Standard-Detail
   # 
   if (defined($param{current}) && exists($param{current}->{itnormodel})){
      if ($param{output} ne "kernel::Output::HtmlDetail"){
         if (!$self->IsMemberOf("admin") && 
             !$self->IsMemberOf("w5base.itil.appl.securityread")){
            @l=grep({$_->{name} ne "itnormodel"} @l);
         }
      }
   }
   return(@l);
}


sub InterviewPartners
{
   my $self=shift;
   my $rec=shift;


   return(''=>$self->T("Databoss"),
          'INTERVApplicationMgr'   =>'ApplicationManager',
          'INTERVSystemTechContact'=>'TechnicalContact') if (!defined($rec));
   my %g=();
   $g{''}=[$rec->{'databossid'}] if (exists($rec->{'databossid'}) &&
                                     $rec->{'databossid'} ne "");
   my @amgr=();
   push(@amgr,$rec->{applmgrid}) if ($rec->{applmgrid} ne "");
   $g{'INTERVApplicationMgr'}=\@amgr if ($#amgr!=-1);

   my @tsm=();
   push(@tsm,$rec->{tsmid}) if ($rec->{tsmid} ne "");
   push(@tsm,$rec->{tsm2id}) if ($rec->{tsm2id} ne "");
   $g{'INTERVSystemTechContact'}=\@tsm if ($#tsm!=-1);

   return(%g);
}


# 
#  Sub: getTeamBossID
#
#  Calculates the userid of the business team boss.
#
#  Parameters:
#
#     rec        - current record
#
#  Returns:
#
#     array refernce - the list of  userids of team bosses.
#
sub getTeamBossID
{
   my $self=shift;
   my $current=shift;
   my $teamfieldname=$self->{depend}->[0];
   my $teamfield=$self->getParent->getField($teamfieldname);
   my $teamid=$teamfield->RawValue($current);
   my @teambossid=();
   if ($teamid ne ""){
      my $lnk=getModuleObject($self->getParent->Config,
                              "base::lnkgrpuser");
      $lnk->SetFilter({grpid=>\$teamid,
                       rawnativroles=>'RBoss'});
      foreach my $rec ($lnk->getHashList("userid")){
         if ($rec->{userid} ne ""){
            push(@teambossid,$rec->{userid});
         }
      }
   }
   return(\@teambossid);
}


sub getTeamBoss
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("fullname")){
         if ($rec->{fullname} ne ""){
            push(@teamboss,$rec->{fullname});
         }
      }
   }
   return(\@teamboss);
}

sub getTeamBossEMail
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("email")){
         if ($rec->{email} ne ""){
            push(@teamboss,$rec->{email});
         }
      }
   }
   return(\@teamboss);
}



sub calculateLogicalCpuCount
{
   my $self=shift;
   my $current=shift;
   my $applid=$current->{id};

   my $l=getModuleObject($self->getParent->Config(),"itil::lnkapplsystem");
   $l->SetFilter({applid=>\$applid,systemcistatusid=>[qw(3 4 5)]});

   my $cpucount;
   foreach my $lrec ($l->getHashList(qw(logicalcpucount))){
      $cpucount+=$lrec->{logicalcpucount};
   }
   return($cpucount);
}

sub calculateRelPhysCpuCount
{
   my $self=shift;
   my $current=shift;
   my $applid=$current->{id};

   my $l=getModuleObject($self->getParent->Config(),"itil::lnkapplsystem");
   $l->SetFilter({applid=>\$applid,systemcistatusid=>[qw(3 4 5)]});

   my $cpucount;
   foreach my $lrec ($l->getHashList(qw(relphysicalcpucount))){
      $cpucount+=$lrec->{relphysicalcpucount};
   }
   return($cpucount);
}

sub calculateSysCount
{
   my $self=shift;
   my $current=shift;
   my $sysfld=$self->getParent->getField("systems");
   my $s=$sysfld->RawValue($current);
   return(0) if (!ref($s) eq "ARRAY");
   return($#{$s}+1);
}

sub calculateInterfacesCount
{
   my $self=shift;
   my $current=shift;
   my $sysfld=$self->getParent->getField("interfaces");
   my $s=$sysfld->RawValue($current);
   return(0) if (!ref($s) eq "ARRAY");

   my $c=0;
   foreach my $irec (@$s){
      if (lc($irec->{conproto}) ne "unknown" &&
          ($irec->{cistatusid}>2 && $irec->{cistatusid}<6) &&
          ($irec->{ifagreementneeded} eq "1")){
         $c++;
      }
   }
   return($c);
}

sub calculateInstanceCount
{
   my $self=shift;
   my $current=shift;
   my $sysfld=$self->getParent->getField("swinstances");
   my $s=$sysfld->RawValue($current);
   return(0) if (!ref($s) eq "ARRAY");
   if ($self->{name} eq "mwswinstancecount"){
      my $c=0;
      foreach my $swrec (@{$s}){
         $c++ if ($swrec->{is_mw});
      }
      return($c);
   }
   elsif ($self->{name} eq "dbsswinstancecount"){
      my $c=0;
      foreach my $swrec (@{$s}){
         $c++ if ($swrec->{is_dbs});
      }
      return($c);

   }
   return($#{$s}+1);
}



sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneRB phoneMVD phoneMISC phoneDEV phoneSUP);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);

}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $worktable="appl";
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj='$selfasparent' ".
            "and $worktable.id=lnkcontact.refid ".
            "left outer join lnkcontact as lnkapplmgr2 ".
            "on (lnkapplmgr2.parentobj='$selfasparent' ".
            "and $worktable.id=lnkapplmgr2.refid ".
            "and lnkapplmgr2.croles like '%roles=_applmgr2_=roles%' ".
            "and lnkapplmgr2.target='base::user') ".
            "left outer join appladv on (appl.id=appladv.appl and ".
            "appladv.isactive=1) ".
            "left outer join itcrmappl on appl.id=itcrmappl.id ".
            "left outer join costcenter on (appl.conumber=costcenter.name and ".
                                           "costcenter.cistatus>1 and ".
                                           "costcenter.cistatus<6) ".
            "left outer join lnkapplgrpappl on lnkapplgrpappl.appl=".
            "(select s.appl from lnkapplgrpappl s".
            " where appl.id=s.appl ".
            " order by s.id ".
            " limit 1) ".
            "left outer join applgrp on lnkapplgrpappl.applgrp=applgrp.id";

   return($from);
}


sub addApplicationSecureFilter
{
   my $self=shift;
   my $namespace=shift;
   my $addflt=shift;


   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
   my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                       [orgRoles(),qw(RMember RCFManager RCFManager2 
                                      RAuditor RMonitor)],"both");
   my @grpids=keys(%grps);
   my $userid=$self->getCurrentUserId();

   foreach my $ns (@$namespace){ 
      if ($self->getField($ns.'sectargetid')){
         push(@$addflt,{$ns.'sectargetid'=>\$userid,
            $ns.'sectarget'=>\'base::user',
            $ns.'secroles'=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                      "*roles=?read?=roles*"}
         );
      }
      if ($self->getField($ns.'sectargetid')){
         push(@$addflt,{$ns.'sectargetid'=>\@grpids,
            $ns.'sectarget'=>\'base::grp',
            $ns.'secroles'=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                      "*roles=?read?=roles*"}
         );
      }
      if ($ENV{REMOTE_USER} ne "anonymous"){
         if ($self->getField($ns.'mandatorid')){
            push(@$addflt,{$ns.'mandatorid'=>\@mandators});
         }
         foreach my $fld (qw(databossid semid sem2id tsmid tsm2id 
                             opmid opm2id delmgrid delmgr2id)){
            if ($self->getField($ns.$fld)){
               push(@$addflt,{$ns.$fld=>\$userid});
            }
         }
         foreach my $fld (qw(businessteamid responseteamid responseorgid)){
            if ($self->getField($ns.$fld)){
               push(@$addflt,{$ns.$fld=>\@grpids});
            }
         }
      }
   }
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @addflt;
      $self->addApplicationSecureFilter([''],\@addflt);
      push(@flt,\@addflt);
   }
   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}


sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}



sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appl");
}
         

sub prepareToWasted
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{applid}=undef;
   $newrec->{srcsys}=undef;
   $newrec->{srcid}=undef;
   $newrec->{srcload}=undef;
   my $id=effVal($oldrec,$newrec,"id");

   my $o=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($o)){
      $o->BulkDeleteRecord({toapplid=>\$id});
      $o->BulkDeleteRecord({fromapplid=>\$id});
   }
   my $o=getModuleObject($self->Config,"itil::lnkapplsystem");
   if (defined($o)){
      $o->BulkDeleteRecord({applid=>\$id});
   }

   return(1);   # if undef, no wasted Transfer is allowed
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effChangedVal($oldrec,$newrec,"cistatusid")==7){
      return(1);
   }
   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $purename=$name;
   $purename=~s/\[[0-9]+\]\s*$//;
   
   if (length($name)<3 ||length($purename)>40|| haveSpecialChar($name) ||
       ($name=~m/^\d+$/)){   # only numbers as application name is not ok!
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid application name '%s' specified"),$name));
      return(0);
   }
   if (exists($newrec->{name}) && $newrec->{name} ne $name){
      $newrec->{name}=$name;
   }
   if ((my $swdepot=effVal($oldrec,$newrec,"swdepot")) ne ""){
      if (!($swdepot=~m#^(https|http)://[a-z0-9A-Z_/.:]/[a-z0-9A-Z_/.]*$#) &&
          !($swdepot=~m#^[a-z0-9A-Z_/.]+:/[a-z0-9A-Z_/.]*$#)){
         $self->LastMsg(ERROR,"invalid swdepot path spec");
         return(0);
      }
   }

   if (effChanged($oldrec,$newrec,"cistatusid")){
      if (defined($oldrec)){
         my $oldcistatusid=$oldrec->{cistatusid};
         if (defined($newrec) && exists($newrec->{cistatusid})){
            if ($oldcistatusid>=3 && $oldcistatusid<=5){
               if ($self->isDataInputFromUserFrontend() &&
                   !$self->IsMemberOf("admin") ){
                  if ($newrec->{cistatusid}>5){
                     if ($#{$oldrec->{itcloudareas}}!=-1){
                        $self->LastMsg(ERROR,"this CI-Status change is only ".
                                       "allowed without existing CloudAreas");
                        return(0);
                     }
                     if ($#{$oldrec->{systems}}!=-1){
                        $self->LastMsg(ERROR,"this CI-Status change is only ".
                                  "allowed without existing logical systems");
                        return(0);
                     }
                     if ($#{$oldrec->{swinstances}}!=-1){
                        $self->LastMsg(ERROR,"this CI-Status change is only ".
                               "allowed without existing software instances");
                        return(0);
                     }
                  }
               }
            }
         }
      }
   }

   if (defined($newrec->{slacontravail})){
      if ($newrec->{slacontravail}>100 || $newrec->{slacontravail}<0){
         my $fo=$self->getField("slacontravail");
         my $msg=sprintf($self->T("value of '%s' is not allowed"),$fo->Label());
         $self->LastMsg(ERROR,$msg);
         return(0);
      }
   }
   if (exists($newrec->{applbasemonistatus}) ||
       exists($newrec->{applbasemoni})){
      if (((effVal($oldrec,$newrec,"applbasemonistatus") eq "NOMONI" &&
           effVal($oldrec,$newrec,"applbasemoni") ne "-no monitoring-")) ||
          ((effVal($oldrec,$newrec,"applbasemonistatus") ne "NOMONI" &&
            effVal($oldrec,$newrec,"applbasemoni") eq "-no monitoring-"))){
         $self->LastMsg(ERROR,"invalid basemonitoring status combination");
         return(0);
      }
   }


   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      if (!$self->finance::costcenter::ValidateCONumber(
          $self->SelfAsParentObject,"conumber", $oldrec,$newrec)){
         $self->LastMsg(ERROR,
             $self->T("invalid number format '\%s' specified",
                      "finance::costcenter"),$newrec->{conumber});
         return(0);
      }
   }
   if ($newrec->{isnoifaceappl}) {
      my $ifcnt=$self->getField('interfacescount')->RawValue($oldrec);
      if ($ifcnt>0) {
         $self->LastMsg(ERROR,$self->T("supernumerary interfaces existing"));
         return(0);
      }
   }
   foreach my $v (qw(avgusercount namedusercount)){
      $newrec->{$v}=undef if (exists($newrec->{$v}) && $newrec->{$v} eq "");
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   if (defined($newrec->{applid})){
      $newrec->{applid}=trim($newrec->{applid});
   }
   if (effVal($oldrec,$newrec,"applid")=~m/^\s*$/){
      $newrec->{applid}=undef;
   }
   ########################################################################
   if (!defined($oldrec) && !exists($newrec->{eventlang})){
      $newrec->{eventlang}=$self->Lang(); 
   }

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   my $newlnkapplsystemcist;
   if (effChanged($oldrec,$newrec,"cistatusid") &&
       defined($oldrec) && $oldrec->{cistatusid}<6 &&
       defined($newrec) && $newrec->{cistatusid}>=6){
      $newlnkapplsystemcist=6;
   }
   if (effChanged($oldrec,$newrec,"cistatusid") &&
       defined($oldrec) && $oldrec->{cistatusid}>=6 &&
       defined($newrec) && $newrec->{cistatusid}<6){
      $newlnkapplsystemcist=4;
   }
   if (defined($newlnkapplsystemcist)){
      $self->itil::lib::Listedit::updateLnkapplsystem(
             $newlnkapplsystemcist,$oldrec->{systems});
   }


   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   $self->NotifyAddOrRemoveObject($oldrec,$newrec,"name",
                                  "STEVapplchanged",100000003);
   $self->itil::lib::BorderChangeHandling::BorderChangeHandling(
      $oldrec,
      $newrec
   ); 

   return($bak);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return(qw(header default)) if (defined($rec) && $rec->{cistatusid}==7);
   my @all=qw(accountnumbers history default applapplgroup applgroup
              attachments contacts control supcontracts custcontracts 
              customer delmgmt itcloudareas
              finance interfaces licenses monisla sodrgroup qc external itsem
              mutimes   individualAttr
              misc opmgmt phonenumbers services businessservices 
              soclustgroup socomments source swinstances systems applurl 
              addcis tags
              technical workflowbasedata header inmchm inm chm interview efforts
              functional);

   if (lc($rec->{businessteam}) ne "extern"){
      if (in_array(\@all,"inmchm")){
         @all=grep(!/^inmchm$/,@all);
         push(@all,"chm","inm");
      }
   }
   else{
      @all=grep(!/^(inm|chm)$/,@all);
      push(@all,"inmchm");
   }
   return(@all);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default interfaces finance opmgmt technical contacts misc
                       systems applurl attachments accountnumbers interview
                       customer control phonenumbers monisla mutimes
                       sodrgroup soclustgroup socomments functional);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
      if ($rec->{haveitsem}){
         @databossedit=grep(!/^finance$/,@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if ($rec->{databossid}==$userid){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
            if (grep(/^write$/,@roles)){
               return($self->expandByDataACL($rec->{mandatorid},@databossedit));
            }
         }
      }
      if ($rec->{mandatorid}!=0 && 
         $self->IsMemberOf($rec->{mandatorid},["RDataAdmin",
                                               "RCFManager",
                                               "RCFManager2"],
                           "down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if ($rec->{businessteamid}!=0 && 
         $self->IsMemberOf($rec->{businessteamid},["RCFManager",
                                                   "RCFManager2"],
                           "down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if ($rec->{responseteamid}!=0 && 
         $self->IsMemberOf($rec->{responseteamid},["RCFManager",
                                                   "RCFManager2"],
                           "down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
   }
   return($self->expandByDataACL($rec->{mandatorid}));
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $refobj=getModuleObject($self->Config,"itil::lnkapplcustcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'applid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   my $refobj=getModuleObject($self->Config,"itil::lnkapplsupcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'applid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'fromapplid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   $self->NotifyAddOrRemoveObject($oldrec,undef,"name",
                                  "STEVapplchanged",100000003);
   return($bak);
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $refobj->SetFilter({'toapplid'=>\$id});
      $lock++ if ($refobj->CountRecords()>0);
   }
   my $refobj=getModuleObject($self->Config,"itil::lnkbscomp");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $refobj->SetFilter([{objtype=>\'itil::appl',obj1id=>\$id},
                          {objtype=>\'itil::appl',obj2id=>\$id},
                          {objtype=>\'itil::appl',obj3id=>\$id}]);
      $lock++ if ($refobj->CountRecords()>0);
   }
   my $refobj=getModuleObject($self->Config,"itil::businessservice");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $refobj->SetFilter([{applid=>\$id,cistatusid=>"<6"}]);
      if ($refobj->CountRecords()>0){
         $self->LastMsg(ERROR,
             "delete only posible, if there are existing generic ".
             "businessservices which are not disposed of wasted");
         return(0);
      }
   }

   if ($lock>0 ||
       $#{$rec->{systems}}!=-1 ||
       $#{$rec->{services}}!=-1 ||
       $#{$rec->{applurl}}!=-1 ||
       $#{$rec->{itcloudareas}}!=-1 ||
       $#{$rec->{swinstances}}!=-1 ||
       $#{$rec->{supcontracts}}!=-1 ||
       $#{$rec->{custcontracts}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no system, ".
          "software instance, urls, cluster service, interfaces, ".
          "service components ".
          "and contract relations");
      return(0);
   }

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default functional itsem finance technical 
             inmchm inm chm
             opmgmt delmgmt 
             customer custcontracts supcontracts
             contacts phonenumbers 
             interfaces systems itcloudareas 
             swinstances services businessservices applurl addcis tags
             monisla 
             mutimes misc attachments individualAttr control 
             sodrgroup soclustgroup socomments accountnumbers licenses 
             external source));
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}


sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"Scene");
}


sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;

   my $label=$self->T("add application interfaces");
   $methods->{'m500addApplicationInterfaces'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call addApplicationInterfaces on \",this);
          \$(\".spinner\").show();
          var app=this.app;
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'itil::appl');
                w5obj.SetFilter({
                   id:dataobjid
                });
                w5obj.findRecord(\"id,interfaces\",function(data){
                   for(recno=0;recno<data.length;recno++){
                      for(ifno=0;ifno<data[recno].interfaces.length;ifno++){
                         var ifrec=data[recno].interfaces[ifno];
                         app.addNode(dataobj,ifrec.toapplid,ifrec.toappl);
                         app.addEdge(app.toObjKey(dataobj,dataobjid),
                                     app.toObjKey(dataobj,ifrec.toapplid));
                      }
                   }
                   methodDone(\"end of addApplicationInterfaces\");
                });
             });
          }));
       }
   ";

   my $label=$self->T("add systems");
   $methods->{'m501addApplicationSystems'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m501addApplicationSystems on \",this);
          \$(\".spinner\").show();
          var app=this.app;
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'itil::appl');
                w5obj.SetFilter({
                   id:dataobjid
                });
                w5obj.findRecord(\"id,systems\",function(data){
                   for(recno=0;recno<data.length;recno++){
                      for(subno=0;subno<data[recno].systems.length;subno++){
                         var subrec=data[recno].systems[subno];
                         app.addNode('itil::system',subrec.systemid,
                                     subrec.system);
                         app.addEdge(app.toObjKey(dataobj,dataobjid),
                                     app.toObjKey('itil::system',
                                     subrec.systemid),
                                     {noAcross:true});
                      }
                   }
                   methodDone(\"end of m501addApplicationSystems\");
                });
             });
          }));
       }
   ";

   my $label=$self->T("add software instances");
   $methods->{'m501addApplicationInstances'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m501addApplicationInstances on \",this);
          \$(\".spinner\").show();
          var app=this.app;
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'itil::appl');
                w5obj.SetFilter({
                   id:dataobjid
                });
                w5obj.findRecord(\"id,swinstances\",function(data){
                   for(recno=0;recno<data.length;recno++){
                      for(subno=0;subno<data[recno].swinstances.length;subno++){
                         var subrec=data[recno].swinstances[subno];
                         app.addNode('itil::swinstance',subrec.id,
                                     subrec.fullname);
                         app.addEdge(app.toObjKey(dataobj,dataobjid),
                                     app.toObjKey('itil::swinstance',
                                     subrec.id),
                                     {noAcross:true});
                         if (subrec.systemid){
                            app.addEdge(app.toObjKey('itil::swinstance',
                                        subrec.id),
                                        app.toObjKey('itil::system',
                                        subrec.systemid),
                                        {noAcross:true});
                         }
                      }
                   }
                   methodDone(\"end of m501addApplicationInstances\");
                });
             });
          }));
       }
   ";

   my $label=$self->T("set item visual focus");
   $methods->{'m000setApplVisualFocus'}="
       label:\"$label\",
       cssicon:\"arrow_in\",
       isPosible:function(nodeobj,activeApplet,selectedNodes){
          if (selectedNodes.length!=1){
             return(false);
          }
          return(true);
       },
       exec:function(){
          console.log(\"call setApplVisualFocus on \",this);
          \$(\".spinner\").show();
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          var runpath=[dataobj,dataobjid];
          this.app.runApplet('itil::Explore::appl',runpath);
       }
   ";

}






sub SceneHeader
{
   my $self=shift;
   my @js;
   foreach my $l (qw(lib/raphael.js lib/jquery-1.8.1.min.js 
                     lib/jquery-ui-1.8.23.custom.min.js 
                     lib/jquery.layout.js lib/jquery.autoresize.js 
                     lib/jquery-touch_punch.js lib/jquery.contextmenu.js 
                     lib/rgbcolor.js lib/canvg.js lib/Class.js 
                     lib/json2.js src/draw2d.js)){
      push(@js,"../../../../../static/draw2d/".$l);

   }

}


sub Scene
{
   my $self=shift;

   print $self->HttpHeader();
   print $self->HtmlHeader(title=>"Scene",
      style=>['../../../../../static/draw2d/css/contextmenu.css',
             ]);

   #######################################################################
   my $path;
   if (defined(Query->Param("FunctionPath"))){
      $path=Query->Param("FunctionPath");
   }
   $path=~s/\///;
   my ($id,$scene)=split(/\//,$path);
   my $dataobj=$self->Self();
   #######################################################################


   my $s=new kernel::Scene("gfx_holder");
   print $s->htmlBootstrap();
   print $s->htmlContainer();

   $s->addShape("defid","draw2d.shape.node.Start",50,50);
   $s->addShape("defid","draw2d.shape.node.End",150,150);
   $s->addShape("defid","draw2d.shape.basic.Rectangle",250,150);

   print $s->renderedScene();
   print $self->HtmlBottom(body=>1);
}

sub HtmlPublicDetail   # for display record in QuickFinder or with no access
{
   my $self=shift;
   my $rec=shift;
   my $header=shift;   # create a header with fullname or name

   my $htmlresult="";
   if ($header){
      $htmlresult.="<table style='margin:5px'>\n";
      $htmlresult.="<tr><td colspan=2 align=center><h1>";
      $htmlresult.=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      "name","formated");
      $htmlresult.="</h1></td></tr>";
   }
   else{
      $htmlresult.="<table>\n";
   }
   my @l=qw(mandator applmgr 
            itsem itsem2
            sem sem2 delmgr delmgr2 tsm tsm2 databoss 
            businessteam systemnames);
   if ($ENV{REMOTE_USER} eq "anonymous"){
      @l=qw(mandator applmgr);
   }
   foreach my $v (@l){
      if ($v eq "systemnames"){
         my $name=$self->getField($v)->Label();
         my $data;
         if (ref($rec->{$v}) eq "ARRAY"){
            $data=join("; ",sort(map({$_->{system}} @{$rec->{$v}})));
            if ($data ne ""){
               $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                            "<td valign=top>$data</td></tr>\n";
            }
         }
      }
      elsif ($rec->{$v} ne ""){
         my $show=1;
         if (in_array([qw(itsem itsem2 sem sem2 delmgr delmgr2)],$v)){
            if ($rec->{haveitsem}){
               if ($v eq "itsem" || $v eq "itsem2"){
                  $show=1;
               }
               else{ 
                  $show=0;
               }
            }
         }
         if ($show){
            my $name=$self->getField($v)->Label();
            my $data=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                         $v,"formated");
            $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                         "<td valign=top>$data</td></tr>\n";
         }
      }
   }

   if ($ENV{REMOTE_USER} ne "anonymous"){
      if (my $pn=$self->getField("phonenumbers")){
         $htmlresult.=$pn->FormatForHtmlPublicDetail($rec);
      }
   }
   $htmlresult.="</table>\n";
   if ($ENV{REMOTE_USER} ne "anonymous"){
      if ($rec->{description} ne ""){
         my $desclabel=$self->getField("description")->Label();
         my $desc=$rec->{description};
         $desc=~s/\n/<br>\n/g;

         $htmlresult.="<table><tr><td>".
                      "<div style=\"height:60px;overflow:auto;color:gray\">".
                      "\n<font color=black>$desclabel:</font><div>\n$desc".
                      "</div></div>\n</td></tr></table>";
      }
   }
   return($htmlresult);

}

sub fltRulesOrderingAuthorized
{
   my $self=shift;
   my $applid=shift;
   my $param=shift;
   my $userid=shift;

   my $directUserid=[qw(applmgrid itsemid itsem2id)];
   my $directGroupid=[];  # noch nicht implementiert
   my $roles=[qw(write orderingauth)];

   return($directUserid,$directGroupid,$roles);
}

sub validateOrderingAuthorized
{
   my $self=shift;
   my $applid=shift;
   my $param=shift;

   my %userid;
   if ($param->{email} ne "" && ($param->{email}=~m/\@/)){
      my $emailfilter=$param->{email};
      $emailfilter=~s/[\s"'\*\?]//;
      my $user=getModuleObject($self->Config,"base::user");
      $user->SetFilter({emails=>$emailfilter,cistatusid=>[4,5]});
      my @l=$user->getHashList(qw(userid fullname));
      if ($#l==0){
         $userid{$l[0]->{userid}}=$l[0]->{fullname}; 
      }
   }
   if ($param->{posix} ne "" && !($param->{posix}=~m/\@/)){
      my $emailfilter=$param->{posix};
      $emailfilter=~s/[\s"'\*\?]//;
      my $user=getModuleObject($self->Config,"base::user");
      $user->SetFilter({posix=>\$emailfilter,cistatusid=>[4,5]});
      my @l=$user->getHashList(qw(userid fullname));
      if ($#l==0){
         $userid{$l[0]->{userid}}=$l[0]->{fullname}; 
      }
   }
   if ($param->{userid} ne "" && !($param->{userid}=~m/\@/)){
      my $userid=$param->{userid};
      $userid=~s/[\s"'\*\?]//;
      my $user=getModuleObject($self->Config,"base::user");
      $user->SetFilter({userid=>\$userid,cistatusid=>[4,5]});
      my @l=$user->getHashList(qw(userid fullname));
      if ($#l==0){
         $userid{$l[0]->{userid}}=$l[0]->{fullname}; 
      }
   }
   if ($param->{dsid} ne "" && !($param->{dsid}=~m/\@/)){
      my @flt=();
      my $dsidfilter=$param->{dsid};
      $dsidfilter=~s/[\s"'\*\?]//;
      if (length($dsidfilter)>3){
         push(@flt,{dsid=>\$dsidfilter,cistatusid=>[4,5]});
      }
      if ($#flt!=-1){
         my $user=getModuleObject($self->Config,"base::user");
         $user->SetFilter(\@flt);
         my @l=$user->getHashList(qw(userid fullname));
         if ($#l==0){
            $userid{$l[0]->{userid}}=$l[0]->{fullname}; 
         }
      }
   }

   my ($directUserid,$directGroupid,$Croles)=$self->fltRulesOrderingAuthorized(
      $applid,$param,\%userid
   );
   my $orderAllowed=0;
   my @userid=keys(%userid);
   my $op=$self->Clone();
   $op->ResetFilter();
   $op->SetFilter({id=>\$applid});


   my ($rec,$msg)=$op->getOnlyFirst(qw(id name contacts ),@$directUserid);
   if (defined($rec)){
      if (keys(%userid)){
         my @grpid;
         foreach my $userid (@userid){
            my %grps=$self->getGroupsOf($userid,["RMember"],"up");
            push(@grpid,keys(%grps));
         }
         if (!$orderAllowed){
            foreach my $fldname (@$directUserid){
               if ($rec->{$fldname} ne "" && 
                   in_array(\@userid,$rec->{$fldname})){
                  $orderAllowed=1;
               }
            }
         }
         # due perf the check of grp and user is splited
         if (!$orderAllowed){   # direct base::user check
            UCHK: foreach my $crec (@{$rec->{contacts}}){
               my $roles=$crec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if ($crec->{target} eq "base::user"){
                  if (in_array($roles,$Croles) &&
                      in_array(\@userid,$crec->{targetid})){
                     $orderAllowed=1;
                     last UCHK;
                  }
               }
            }
         }
         if (!$orderAllowed){   # direct base::grp check
            GCHK: foreach my $crec (@{$rec->{contacts}}){
               my $roles=$crec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if ($crec->{target} eq "base::grp"){
                  if (in_array($roles,$Croles) &&
                      in_array(\@grpid,$crec->{targetid})){
                     $orderAllowed=1;
                     last GCHK;
                  }
               }
            }
         }
      }
   }

   return(\%userid,$orderAllowed); 
}


sub generateContextMap
{
   my $self=shift;
   my $rec=shift;

   my $d={
      items=>{add=>[]}
   };

   my $imageUrl=$self->getRecordImageUrl(undef);
   my $cursorItem;

   my $cursorItem="itil::appl::".$rec->{id};

   if (Query->Param("OP") eq "expand"){
      foreach my $id (keys(%{$rec->{servicetrees}->{obj}})){
         my $obj=$rec->{servicetrees}->{obj}->{$id};
     
         my $itemrec={id=>$id,title=>$obj->{label},image=>$imageUrl};
     
         if ($obj->{dataobj} ne ""){
            my $o=getModuleObject($self->Config,$obj->{dataobj});
            if ($o){
               $itemrec->{image}=$o->getRecordImageUrl(undef);
            }
            if ($obj->{dataobj} eq $self->Self() ||
                $obj->{dataobj} eq $self->SelfAsParentObject()){
               if ($obj->{dataobjid} eq $rec->{id}){
                  $cursorItem=$id; 
               }
            }
         }
     
         my $titleurl=$obj->{urlofcurrentrec};
         if (($obj->{dataobj}=~m/::businessservice$/)){  # nur da get ContextMap
           #  ($obj->{dataobj}=~m/::businessprocess$/)){
            $titleurl=~s#/ById/#/Map/#;
         }
         $itemrec->{titleurl}=$titleurl;
     
         my $title=$itemrec->{title};
         if (($title=~m/:.*:/) || 
              ($title=~m/^[^:]{5,20}:/) ||
              ($title=~m/^[^:]{2,10}:[^:]{20}/) ){
            my @l=split(/:/,$title);
            my $description=pop(@l);
            $title=join(":",@l);
            $itemrec->{title}=$title;
            $itemrec->{description}=$description;
            $itemrec->{description}=~s/\@/\@ /g;
         }
         if (exists($obj->{directParent})){
            $itemrec->{parents}=$obj->{directParent};
         }
         $itemrec->{labelPlacement}=3;
         push(@{$d->{items}->{add}},$itemrec);
      }
      $d->{items}->{del}=["itil::applgrp::".$rec->{applgrpid}];
       
      
      return($d);
   }

   my $applgrpid;
   if ($cursorItem && $rec->{applgrp} ne ""){
      $applgrpid="itil::applgrp::".$rec->{applgrpid};
      my $itemrec={
         id=>$applgrpid,
         title=>$rec->{applgrp},
         image=>$imageUrl,
         dataobj=>'itil::applgrp',
         dataobjid=>$rec->{applgrpid}
      };
      my $o=getModuleObject($self->Config,"itil::applgrp");
      if ($o){
         $itemrec->{image}=$o->getRecordImageUrl(undef);
      }
      push(@{$d->{items}->{add}},$itemrec);
   }
   if ($cursorItem){
      my $itemrec={
         id=>$cursorItem,
         title=>$rec->{name},
         image=>$imageUrl,
         expandBaseLocation=>1
      };
      my $titleurl=$rec->{urlofcurrentrec};
      $titleurl=~s#/ById/#/Map/#;
      $itemrec->{titleurl}=$titleurl;

      if ($applgrpid){
         $itemrec->{parents}=[$applgrpid];
      }
      push(@{$d->{items}->{add}},$itemrec);
   }




   if ($cursorItem){
      my %assetid;
      foreach my $sysrec (@{$rec->{systems}}){
         my $id="itil::system::".$sysrec->{systemid};
         my $itemrec={
            id=>$id,
            title=>$sysrec->{system},
            dataobj=>'itil::appl',
            dataobjid=>$rec->{id},
            description=>$sysrec->{shortdesc}
         };
         my $o=getModuleObject($self->Config,"itil::system");
         if ($o){
            $itemrec->{image}=$o->getRecordImageUrl(undef);
         }
         # assetassetname
         # assetid
         $itemrec->{parents}=[$cursorItem];
         push(@{$d->{items}->{add}},$itemrec);
 
         if ($sysrec->{assetassetname} ne ""){
            my $assetk="itil::asset::".$sysrec->{assetid}; 
            if (!exists($assetid{$assetk})){
               my $itemrec={
                  id=>$assetk,
                  title=>$sysrec->{assetassetname},
                  parents=>[$id]
               };
               my $o=getModuleObject($self->Config,"itil::asset");
               if ($o){
                  $itemrec->{image}=$o->getRecordImageUrl(undef);
               }
               $assetid{$assetk}=$itemrec;
            }
            else{
               push(@{$assetid{$assetk}->{parents}},$id);
            }
         }
      }
      if (keys(%assetid)){
         push(@{$d->{items}->{add}},values(%assetid));
      }
   }


   foreach my $itemrec (@{$d->{items}->{add}}){
      $itemrec->{templateName}="wideTemplate";
   }

   if ($cursorItem){
      $d->{cursorItem}=$cursorItem;
   }
   $d->{enableMatrixLayout}=1;
   $d->{minimumMatrixSize}=2;
   $d->{maximumColumnsInMatrix}=3;
   if ($#{$d->{items}->{add}}>10){
      $d->{maximumColumnsInMatrix}=4;
      $d->{initialZoomLevel}="5";
   }

   #print STDERR Dumper($d);
   return($d);
}







#############################################################################

package itil::appl::Link;

use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Link);


sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}

sub getBackendName     # returns the name/function to place in select
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   return($self->{wrdataobjattr}) if ($mode eq "update" || $mode eq "insert");

   return($self->SUPER::getBackendName($mode,$db));
}







1;
