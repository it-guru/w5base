package itil::swinstance;
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
use kernel::CIStatusTools;
use itil::appl;
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools 
        itil::lib::Listedit);

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
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'swinstance.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmlwidth     =>'300px',
                readonly      =>'1',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1);
                   }
                   return(0);
                },
                dataobjattr   =>'swinstance.fullname'),

      new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'swinstance.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                explore       =>100,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'swinstance.databoss'),

      new kernel::Field::Select(
                name          =>'swnature',
                htmleditwidth =>'40%',
                group         =>'env',
                selectfix     =>1,
                label         =>'Instance type',
                onPreProcessFilter=>sub{
                   return(0,undef);
                },
                getPostibleValues=>sub{
                   my $self=shift;
                   my $current=shift;
                   return($self->getParent->getPosibleInstanceTypes(
                             $current->{posibleinstanceidentify}
                          )
                   );
                },
                dataobjattr   =>'swinstance.swnature'),
     
      new kernel::Field::Interface(
                name          =>'rawswnature',
                group         =>'env',
                explore       =>200,
                uploadable    =>0,
                label         =>'raw Instance type',
                dataobjattr   =>'swinstance.swnature'),

      new kernel::Field::TextDrop(
                name       =>'appl',
                htmlwidth  =>'150px',
                label      =>'Application',
                vjointo    =>'itil::appl',
                SoftValidate  =>1,          # check only - if changed
                vjoineditbase =>{cistatusid=>">1 AND <6"},
                vjoinon    =>['applid'=>'id'],
                vjoindisp  =>'name'),

      new kernel::Field::Interface(
                name          =>'applid',
                uploadable    =>0,
                label         =>'ApplicationID',
                dataobjattr   =>'swinstance.appl'),

      new kernel::Field::Text(
                name          =>'applconumber',
                htmlwidth     =>'100px',
                label         =>'Application Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['applconumber'=>'name'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1);
                   }
                   return(0);
                },
                readonly      =>'1',
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Instance-Name',
                dataobjattr   =>'swinstance.name'),

      new kernel::Field::Text(
                name          =>'addname',
                htmlwidth     =>'250px',
                label         =>'Additional-Tag',
                dataobjattr   =>'swinstance.addname'),

      new kernel::Field::Select(
                name          =>'swtype',
                htmleditwidth =>'40%',
                label         =>'Instance operation type',
                value         =>['primary',
                                 'secondary',
                                 'standby'],
                dataobjattr   =>'swinstance.swtype'),


      new kernel::Field::Number(
                name          =>'swport',
                label         =>'TCP/IP-Port',
                dataobjattr   =>'swinstance.swport'),

      new kernel::Field::Text(
                name          =>'swinstanceid',
                htmlwidth     =>'100px',
                explore       =>150,
                label         =>'Instance ID',
                dataobjattr   =>'swinstance.swinstanceid'),

      new kernel::Field::Interface(
                name          =>'swteamid',
                dataobjattr   =>'swinstance.swteam'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'swinstance.cistatus'),

      new kernel::Field::Contact(
                name          =>'adm',
                label         =>'Instance Administrator',
                group         =>'adm',
                vjoinon       =>['admid'=>'userid']),

      new kernel::Field::Interface(
                name          =>'admid',
                group         =>'adm',
                dataobjattr   =>'swinstance.adm'),

      new kernel::Field::Contact(
                name          =>'adm2',
                label         =>'Deputy Instance Administrator',
                group         =>'adm',
                vjoinon       =>['adm2id'=>'userid']),

      new kernel::Field::Interface(
                name          =>'adm2id',
                group         =>'adm',
                dataobjattr   =>'swinstance.adm2'),

      new kernel::Field::TextDrop(
                name          =>'swteam',
                label         =>'Instance guardian team',
                vjointo       =>'base::grp',
                explore       =>300,
                group         =>'adm',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['swteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Textarea(
                name          =>'admcomments',
                group         =>'adm',
                label         =>'comments for admin and connect',
                dataobjattr   =>'swinstance.admcomments'),

      new kernel::Field::Select(
                name          =>'lnksoftwaresystem',
                htmleditwidth =>'80%',
                label         =>'Software-Installation',
                group         =>'softwareinst',
                allowempty    =>1,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   my $d=$rec->{runon};
                   return(1) if ($mode eq "ViewEditor"); # damit upload geht
                   return(1) if ($d eq "0");
                   return(1) if ($d eq "1");
                   return(0);
                },
                vjoineditbase     =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($current->{systemid} ne ""){
                      return({systemid=>\$current->{systemid}});
                   }
                   if ($current->{itclustsid} ne ""){
                      my $p=$self->getParent();
                      my $o=getModuleObject($p->Config,"itil::lnkitclustsvc");
                      $o->SetFilter({id=>\$current->{itclustsid}});
                      my ($itclrec)=$o->getOnlyFirst(qw(
                         clustid 
                         posiblesystems
                      )); 
                      if (defined($itclrec) && 
                          exists($itclrec->{posiblesystems})){
                         my @sysflt;
                         foreach my $sys (@{$itclrec->{posiblesystems}}){
                            push(@sysflt,$sys->{syssystemid});
                         }
                         @sysflt=(-1) if ($#sysflt==-1);
                         my $o=getModuleObject($p->Config,
                               "itil::lnksoftware");
                         $o->SetFilter([
                               {itclustsvcid=>\$current->{itclustsid}},
                               {systemid=>\@sysflt}]);
                         my @swinstid=$o->getVal("id");
                         if ($#swinstid!=-1){
                            return({id=>\@swinstid});
                         }
                      }
                      return({itclustsvcid=>\$current->{itclustsid}});
                   }
                   return({id=>\'NONE'});
                },
                vjointo       =>'itil::lnksoftware',
                vjoinon       =>['lnksoftwaresystemid'=>'id'],
                vjoindisp     =>'fullname'),
                #dataobjattr   =>$self->SoftwareInstFullnameSql()),


      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   my $d=$rec->{runon};
                   return(1) if ($d eq "2");
                   return(0);
                },
                label         =>'Software',
                group         =>'softwareinst',
                vjoineditbase =>{pclass=>\'MAIN',cistatusid=>[3,4]},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'swinstance.software'),

      new kernel::Field::Text(
                name          =>'version',
                htmlwidth     =>'50px',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   my $d=$rec->{runon};
                   return(1) if ($d eq "2");
                   return(0);
                },
                group         =>'softwareinst',
                label         =>'Version',
                dataobjattr   =>'swinstance.version'),


      new kernel::Field::Boolean(
                name          =>'lnksoftwaresystemvalid',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'softwareinst',
                label         =>'is Software-Installation valid',
                dataobjattr   =>'if (lnksoftwaresystem.id is not null,1,0)'),

      new kernel::Field::Text(
                name          =>'optionlist',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'installed Optionlist',
                group         =>'softwareinst',
                vjointo       =>'itil::lnksoftwareoption',
                vjoinon       =>['lnksoftwaresystemid'=>'parentid'],
                vjoindisp     =>['software']),

      new kernel::Field::Text(
                name          =>'softwareinstproducer',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Producer of installed software',
                group         =>'softwareinst',
                dataobjattr   =>'producer.name'),

      new kernel::Field::Text(
                name          =>'softwareinstname',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Name of installed software',
                group         =>'softwareinst',
                dataobjattr   =>'software.name'),

      new kernel::Field::Link(
                name          =>'posibleinstanceidentify',
                htmldetail    =>0,
                selectfix     =>1,
                readonly      =>1,
                label         =>'posible instance identify',
                group         =>'softwareinst',
                dataobjattr   =>'software.instanceidentify'),

      new kernel::Field::Boolean(
                name          =>'is_dbs',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'softwareinst',
                label         =>'is DBS (Databasesystem) instance',
                dataobjattr   =>'software.is_dbs'),

      new kernel::Field::Boolean(
                name          =>'is_mw',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'softwareinst',
                label         =>'is MW (Middleware) instance',
                dataobjattr   =>'software.is_mw'),

      new kernel::Field::Text(
                name          =>'softwareinstversion',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'Version of installed software',
                group         =>'softwareinst',
                dataobjattr   =>'if (swinstance.runonclusts=2,'.
                                'swinstance.version,'.
                                'lnksoftwaresystem.version)'),

      new kernel::Field::Interface(
                name          =>'lnksoftwaresystemid',
                label         =>'W5BaseID of software installation',
                group         =>'softwareinst',
                dataobjattr   =>'swinstance.lnksoftwaresystem'),

      new kernel::Field::Textarea(
                name          =>'techrelstring',
                group         =>'softwareinst',
                htmldetail    =>0,
                #htmldetail    =>sub{
                #   my $self=shift;
                #   my $mode=shift;
                #   my %param=@_;
                #   if (defined($param{current})){
                #      if ($self->getParent->IsMemberOf("admin")){
                #         return(1);
                #      }
                #   }
                #   return(0);
                #},
                label         =>'technical release string from instance (AutoDisc)',
                dataobjattr   =>'swinstance.techrelstring'),

      new kernel::Field::Textarea(
                name          =>'techproductstring',
                group         =>'softwareinst',
                htmldetail    =>0,
                #htmldetail    =>sub{
                #   my $self=shift;
                #   my $mode=shift;
                #   my %param=@_;
                #   if (defined($param{current})){
                #      if ($self->getParent->IsMemberOf("admin")){
                #         return(1);
                #      }
                #   }
                #   return(0);
                #},
                label         =>'technical product string from instance (AutoDisc)',
                dataobjattr   =>'swinstance.techprodstring'),

      new kernel::Field::Date(
                name          =>'techdataupdate',
                group         =>'softwareinst',
                history       =>0,
                htmldetail    =>0,
                #htmldetail    =>sub{
                #   my $self=shift;
                #   my $mode=shift;
                #   my %param=@_;
                #   if (defined($param{current})){
                #      if ($self->getParent->IsMemberOf("admin")){
                #         return(1);
                #      }
                #   }
                #   return(0);
                #},
                label         =>'technical date last update (AutoDisc)',
                dataobjattr   =>'swinstance.techdataupd'),

      new kernel::Field::SubList(
                name          =>'relations',
                label         =>'Instance-Relations',
                group         =>'relations',
                htmldetail    =>'NotEmptyOrEdit',
                subeditmsk    =>'subedit.swinstance',
                vjointo       =>'itil::lnkswinstanceswinstance',
                vjoineditbase =>{'cistatusid'=>"<=5"},
                vjoinon       =>['id'=>'fromswi'],
                vjoindisp     =>['toswinstance','conmode']),

      new kernel::Field::SubList(
                name          =>'references',
                label         =>'refered by software instances',
                group         =>'relations',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkswinstanceswinstance',
                vjoineditbase =>{'cistatusid'=>"<=5"},
                vjoinon       =>['id'=>'toswi'],
                vjoindisp     =>['fromswinstance']),

      new kernel::Field::Text(                 # this field only exists for
                name          =>'referedat',   # downward compatibility. The
                label         =>'refered by',  # successor is "references"
                group         =>'relations',   # and should be used in the
                readonly      =>1,             # future
                htmldetail    =>0,
                vjointo       =>'itil::lnkswinstanceswinstance',
                vjoineditbase =>{'cistatusid'=>"<=5"},
                vjoinon       =>['id'=>'toswi'],
                vjoindisp     =>['fromswinstance']),

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
                group         =>'monisla',
                dataobjattr   =>'swinstance.servicesupport'),

      new kernel::Field::TextDrop(
                name          =>'servicesupportsapservicename',
                label         =>'Service&Support Class - SAP Service name',
                group         =>'monisla',
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'sapservicename'),


      new kernel::Field::Select(
                name          =>'monistatus',
                group         =>'monisla',
                label         =>'monitoring status',
                transprefix   =>'monistatus.',
                value         =>['',
                                 'NOMONI',
                                 'MONISIMPLE',
                                 'MONIAUTOIN'],
                htmleditwidth =>'280px',
                dataobjattr   =>'swinstance.monistatus'),

      new kernel::Field::Group(
                name          =>'moniteam',
                group         =>'monisla',
                label         =>'monitoring resonsible Team',
                vjoinon       =>'moniteamid'),

      new kernel::Field::Link(
                name          =>'moniteamid',
                group         =>'monisla',
                label         =>'monitoring resonsible TeamID',
                dataobjattr   =>'swinstance.moniteam'),



      new kernel::Field::Boolean(
                name          =>'issox',
                readonly      =>1,
                group         =>'sec',
                htmleditwidth =>'30%',
                label         =>'mangaged by rules of SOX',
                dataobjattr   =>
                'if (swinstance.no_sox_inherit,0,appl.is_soxcontroll)'),

      new kernel::Field::Select(
                name          =>'nosoxinherit',
                group         =>'sec',
                label         =>'SOX state',
                searchable    =>0,
                transprefix   =>'ApplInherit.',
                htmleditwidth =>'180px',
                value         =>['0','1'],
                translation   =>'itil::appl',
                dataobjattr   =>'swinstance.no_sox_inherit'),


      new kernel::Field::Boolean(
                name          =>'custcostalloc',
                label         =>'Customer cost allocation',
                group         =>'misc',
                dataobjattr   =>'swinstance.custcostalloc'),
      
      new kernel::Field::Interface(  # down compat 0=system 1=clusterservice
                name          =>'runonclusts',
                selectfix     =>1,
                readonly      =>1,
                label         =>'run on Cluster Service',
                group         =>'runon',
                dataobjattr   =>'if (swinstance.runonclusts=1,1,0)'),

      new kernel::Field::Select(  # down compat 0=system 1=clusterservice
                name          =>'runon',
                selectfix     =>1,
                jsonchanged   =>\&getRunOnOnChangedScript,
                jsoninit      =>\&getRunOnOnChangedScript,
                label         =>'run on',
                transprefix   =>'RUNON.',
                default       =>'0',
                value         =>['0',
                                 '1',
                                 '2'],
                group         =>'runon',
                dataobjattr   =>'swinstance.runonclusts'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'System',
                #group         =>'systems',
                group         =>'runon',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if (exists($param{currentfieldgroup}) &&
                                 $param{currentfieldgroup} eq "runon");
                   if (defined($param{current})){
                      my $d=$param{current}->{runon};
                      return(0) if ($d ne "0");
                   }
                   return(1);
                },
                explore       =>500,
                vjointo       =>'itil::system',
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'systemid',
                selectfix     =>1,
                group         =>'runon',
                dataobjattr   =>'swinstance.system'),

      new kernel::Field::Boolean(
                name          =>'isembedded',
                selectfix     =>1,
                htmldetail    =>0,
                label         =>'is embedded instance',
                group         =>'env',
                dataobjattr   =>'system.is_embedded'),

      new kernel::Field::Text(
                name          =>'autoname',
                group         =>'env',
                label         =>'Automationsname/IP-Address',
                dataobjattr   =>'swinstance.autompartner'),

      new kernel::Field::Select(
                name          =>'issslinstance',
                label         =>'Instance uses SSL technologie',
                transprefix   =>'SSL.',
                group         =>'env',
                value         =>['UNKNOWN','YES','NO'],
                dataobjattr   =>'swinstance.issslinstance'),

      new kernel::Field::Text(
                name          =>'runtimeusername',
                label         =>'runtime username',
                group         =>'env',
                dataobjattr   =>'swinstance.runtimeusername'),

      new kernel::Field::Text(
                name          =>'intallusername',
                label         =>'install username',
                group         =>'env',
                dataobjattr   =>'swinstance.installusername'),

      new kernel::Field::Text(
                name          =>'configdirpath',
                label         =>'config directory path',
                group         =>'env',
                dataobjattr   =>'swinstance.configdirpath'),

      new kernel::Field::TextDrop(
                name          =>'itclusts',
                group         =>'runon',
                label         =>'Cluster Service',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if (exists($param{currentfieldgroup}) &&
                                 $param{currentfieldgroup} eq "runon");
                   if (defined($param{current})){
                      my $d=$param{current}->{runon};
                      return(0) if ($d ne "1");
                   }
                   return(1);
                },
                explore       =>500,
                vjointo       =>'itil::lnkitclustsvc',
                vjoineditbase =>{'itclustcistatusid'=>[2,3,4]},
                vjoinon       =>['itclustsid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itclustsid',
                selectfix     =>1,
                group         =>'runon',
                dataobjattr   =>'swinstance.itclusts'),

      new kernel::Field::TextDrop(
                name          =>'itcloudarea',
                group         =>'runon',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   return(1) if (exists($param{currentfieldgroup}) &&
                                 $param{currentfieldgroup} eq "runon");
                   if (defined($param{current})){
                      my $d=$param{current}->{runon};
                      return(0) if ($d ne "2");
                   }
                   return(1);
                },
                label         =>'CloudArea',
                vjointo       =>'itil::itcloudarea',
                vjoineditbase =>{'cistatusid'=>[4]},
                vjoinon       =>['itcloudareaid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itcloudareaid',
                selectfix     =>1,
                group         =>'runon',
                dataobjattr   =>'swinstance.itcloudarea'),

      new kernel::Field::SubList(
                name          =>'swinstancerunnodes',
                label         =>'posible instance run nodes/systems',
                group         =>'swinstancerunnodes',
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkswinstancesystem',
                vjoinbase     =>{'systemcistatusid'=>"<=5"},
                vjoinon       =>['id'=>'swinstanceid'],
                vjoininhash   =>['system','systemid','systemsystemid',
                                 'systemcistatusid'],
                vjoindisp     =>['system','systemsystemid','systemcistatus']),

      new kernel::Field::Text(
                name          =>'sslurl',
                group         =>'ssl',
                label         =>'SSL Check URL',
                dataobjattr   =>'swinstance.ssl_url'),

      new kernel::Field::Select(
                name          =>'ssl_network',
                htmleditwidth =>'280px',
                group         =>'ssl',
                allowempty    =>1,
                label         =>'SSL Check Network',
                vjointo       =>'itil::network',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['ssl_networkid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'ssl_expnotifyleaddays',
                htmleditwidth =>'280px',
                group         =>'ssl',
                default       =>'56',
                label         =>'SSL Expiration notify lead time',
                value         =>['14','21','28','56','70'],
                transprefix   =>'EXPNOTIFYLEAD.',
                translation   =>'itil::applwallet',
                dataobjattr   =>'swinstance.ssl_expnotifyleaddays'),

      new kernel::Field::Link(
                name          =>'ssl_networkid',
                label         =>'NetworkID',
                history       =>0,
                dataobjattr   =>'swinstance.ssl_network'),

      new kernel::Field::Date(
                name          =>'sslbegin',
                history       =>0,
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if ( ($rec->{'sslurl'}=~m/^\[.*\]$/)){
                      return(0);
                   }
                   return(1);
                },
                group         =>'ssl',
                depend        =>['sslurl'],
                label         =>'SSL Certificate Begin',
                dataobjattr   =>'swinstance.ssl_cert_begin'),

      new kernel::Field::Date(
                name          =>'sslend',
                history       =>0,
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (($rec->{'sslurl'}=~m/^\[.*\]$/)){
                      return(0);
                   }
                   return(1);
                },
                group         =>'ssl',
                depend        =>['sslurl'],
                label         =>'SSL Certificate End',
                dataobjattr   =>'swinstance.ssl_cert_end'),

      new kernel::Field::Date(
                name          =>'sslcheck',
                history       =>0,
                readonly      =>1,
                group         =>'ssl',
                label         =>'SSL last Certificate check',
                dataobjattr   =>'swinstance.ssl_cert_check'),

      new kernel::Field::Text(
                name          =>'sslstate',
                readonly      =>1,
                group         =>'ssl',
                label         =>'SSL State',
                dataobjattr   =>'swinstance.ssl_state'),

      new kernel::Field::Text(
                name          =>'ssl_cipher',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Cipher',
                dataobjattr   =>'swinstance.ssl_cipher'),

      new kernel::Field::Text(
                name          =>'ssl_version',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Version',
                dataobjattr   =>'swinstance.ssl_version'),

      new kernel::Field::Text(
                name          =>'ssl_certdump',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Certificate',
                dataobjattr   =>'swinstance.ssl_certdump'),

      new kernel::Field::Text(
                name          =>'ssl_cert_serialno',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Certificate Serial',
                dataobjattr   =>'swinstance.ssl_certserial'),

      new kernel::Field::Text(
                name          =>'ssl_cert_issuerdn',
                readonly      =>1,
                xhtmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Issuer DN',
                dataobjattr   =>'swinstance.ssl_certissuerdn'),

      new kernel::Field::Text(
                name          =>'ssl_cert_signature_algo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                group         =>'ssl',
                label         =>'detected SSL Certificate signature algo',
                dataobjattr   =>'swinstance.ssl_certsighash'),

      new kernel::Field::Date(
                name          =>'sslexpnotify1',
                history       =>0,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'ssl',
                label         =>'Notification of Certificate Expiration',
                dataobjattr   =>'swinstance.ssl_cert_exp_notify1'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'swinstance.comments'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::swinstance',
                group         =>'attachments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>'swinstance.additional'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::swinstance'}],
                vjoininhash   =>['mdate','targetid','target','roles',
                                 'srcsys','srcid'],
                group         =>'contacts'),

#      new kernel::Field::PhoneLnk(
#                name          =>'phonenumbers',
#                label         =>'Phonenumbers',
#                group         =>'phonenumbers',
#                vjoinbase     =>[{'parentobj'=>\'itil::swinstance'}],
#                subeditmsk    =>'subedit'),

      new kernel::Field::SubList(
                name          =>'configrules',
                searchable    =>0,
                htmleditwidth =>'80%',
                label         =>'Config Rules',
                group         =>'swinstancerules',
                vjoinbase     =>{'cistatusid'=>'<=5'},
                vjointo       =>'itil::swinstancerule',
                vjoinon       =>['id'=>'swinstanceid'],
                vjoindisp     =>['fullname','cistatus'],
                vjoininhash   =>['fullname','cistatusid',
                                 'parentobj','refid']),


      new kernel::Field::Text(
                name          =>'relatedapplications',
                group         =>'swinstancerules',
                htmldetail    =>0,
                depend        =>['configrules','applid'],
                label         =>'related applications',
                onRawValue    =>\&calculateRelAppl),


      #new kernel::Field::SubList(
      #          name          =>'lnkswinstanceparam',
      #          htmldetail    =>'NotEmpty',
      #          searchable    =>0,
      #          htmleditwidth =>'80%',
      #          label         =>'Life Parameters',
      #          group         =>'swinstanceparam',
      #          vjoinbase     =>{'islatest'=>'1',mdate=>'>now-56d'},
      #          vjointo       =>'itil::lnkswinstanceparam',
      #          vjoinon       =>['id'=>'swinstanceid'],
      #          vjoindisp     =>['namegrp','name','val']),

      new kernel::Field::SubList(
                name          =>'tags',
                label         =>'ItemTags',
                group         =>'tags',
                htmldetail    =>'NotEmpty',
                vjoinbase     =>{'internal'=>'0','ishidden'=>'0'},
                vjointo       =>'itil::tag_swinstance',
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['name','value']),

      new kernel::Field::SubList(
                name          =>'alltags',
                label         =>'all ItemTags',
                group         =>'tags',
                htmldetail    =>0,
                vjointo       =>'itil::tag_swinstance',
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['name','value'],
                vjoininhash   =>['name','id','mdate','cdate']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'swinstance.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'swinstance.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'swinstance.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                uploadable    =>0,
                dataobjattr   =>"swinstance.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                uploadable    =>0,
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(swinstance.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'swinstance.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'swinstance.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'swinstance.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'swinstance.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'swinstance.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'swinstance.realeditor'),

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

      new kernel::Field::Link(
                name          =>'secsystemapplsectarget',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.target'),

      new kernel::Field::Link(
                name          =>'secsystemapplsectargetid',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secsystemapplsecroles',
                noselect      =>'1',
                dataobjattr   =>'secsystemlnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'secsystemapplmandatorid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.mandator'),

      new kernel::Field::Link(
                name          =>'secsystemapplbusinessteamid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.businessteam'),

      new kernel::Field::Link(
                name          =>'secsystemappltsmid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.tsm'),

      new kernel::Field::Link(
                name          =>'secsystemappltsm2id',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.tsm2'),

      new kernel::Field::Link(
                name          =>'secsystemapplopmid',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.opm'),

      new kernel::Field::Link(
                name          =>'secsystemapplopm2id',
                noselect      =>'1',
                dataobjattr   =>'secsystemappl.opm2'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'swinstance.lastqcheck'),
      new kernel::Field::EnrichLastDate(
                dataobjattr   =>'swinstance.lastqenrich'),

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
                dataobjattr   =>'swinstance.lrecertreqdt'),

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
                dataobjattr   =>'swinstance.lrecertreqnotify'),

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
                dataobjattr   =>'swinstance.lrecertdt'),

      new kernel::Field::Interface(
                name          =>'lrecertuser',
                group         =>'qc',
                label         =>'last recert userid',
                htmldetail    =>'0',
                dataobjattr   =>"swinstance.lrecertuser")

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{use_distinct}=1;
   $self->{workflowlink}={ workflowkey=>[id=>'id']
                         };
   $self->setDefaultView(qw(fullname mandator cistatus mdate));
   $self->setWorktable("swinstance");
   return($self);
}

sub calculateRelAppl
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();

   my @applid=($current->{applid});

   my $fo=$app->getField("configrules");
   my $f=$fo->RawValue($current);

   my $lnkapplsysobj;

   foreach my $rulerec (@$f){
      if ($rulerec->{cistatusid}>2 && $rulerec->{cistatusid}<6){
         if ($rulerec->{parentobj} eq "itil::appl" &&
             $rulerec->{refid} ne ""){
            push(@applid,$rulerec->{refid});
         }
         if ($rulerec->{parentobj} eq "itil::system" &&
             $rulerec->{refid} ne ""){
            if (!defined($lnkapplsysobj)){
               $lnkapplsysobj=$app->getPersistentModuleObject("clnkapplsys",
                                                        "itil::lnkapplsystem");
               $lnkapplsysobj->SetFilter({systemid=>\$rulerec->{refid}});
               my @rel=$lnkapplsysobj->getHashList(qw(applid));
               foreach my $lnkrec (@rel){
                  push(@applid,$lnkrec->{applid});
               }
            }
         }
      }
   }


   my $o=$app->getPersistentModuleObject("capplications","itil::appl");
   $o->SetFilter({id=>\@applid,cistatusid=>[3,4,5]});
   my @l=$o->getHashList(qw(name));

   my @names;
   foreach my $arec (@l){
      push(@names,$arec->{name});
   }
   return(\@names);
}


sub getRunOnOnChangedScript
{
   my $self=shift;

   my $d=<<EOF;

var runon=document.forms[0].elements['Formated_runon'];
var system=document.forms[0].elements['Formated_system'];
var itclusts=document.forms[0].elements['Formated_itclusts'];
var itcloudarea=document.forms[0].elements['Formated_itcloudarea'];

if (runon){
   var v=runon.options[runon.selectedIndex].value;
   if (v=="0"){
      system.disabled=false;
      itclusts.disabled=true;
      itcloudarea.disabled=true;
   }
   else if (v=="1"){
      system.disabled=true;
      itclusts.disabled=false;
      itcloudarea.disabled=true;
   }
   else if (v=="2"){
      system.disabled=true;
      itclusts.disabled=true;
      itcloudarea.disabled=false;
   }
}
EOF

   return($d)
}


sub getPosibleInstanceTypes
{
   my $self=shift;
   my $posibleinstanceidentify=shift;

   my @l;
   if ($posibleinstanceidentify ne ""){
      my @k=map({trim($_)} split(/\|/,$posibleinstanceidentify));
      foreach my $k (@k){
         push(@l,$k,$k);
      }
   }
   push(@l,"Other","Other");
   return(@l); 
}

sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub InitCopy
{
   my ($self,$copyfrom,$newrec)=@_;
   delete($newrec->{'Formated_databoss'});
}





sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/swinstance.jpg?".$cgi->query_string());
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $worktable="swinstance";
   my $from="$worktable";

   $from.=" left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::swinstance' ".
          "and $worktable.id=lnkcontact.refid ".
          "left outer join appl on $worktable.appl=appl.id ".
          "left outer join lnksoftwaresystem ".
          "on swinstance.lnksoftwaresystem=lnksoftwaresystem.id ".
          "left outer join system ".
          "on swinstance.system=system.id ".
          "left outer join software ".
          "on if (swinstance.runonclusts=2,".
                  "swinstance.software,".
                  "lnksoftwaresystem.software)=software.id ".
          "left outer join producer ".
          "on software.producer=producer.id ".

          "left outer join appl as secsystemappl ".
          "on swinstance.appl=secsystemappl.id and secsystemappl.cistatus<6 ".

          "left outer join lnkcontact secsystemlnkcontact ".
          "on secsystemlnkcontact.parentobj='itil::appl' ".
          "and appl.id=secsystemlnkcontact.refid ".

          "left outer join costcenter secsystemcostcenter ".
          "on secsystemappl.conumber=secsystemcostcenter.name ";


   return($from);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::swinstance");
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.swinstance.read 
                              w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
            [orgRoles(),qw(RMember RCFManager RCFManager2 
                           RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
                    {mandatorid=>\@mandators},
                    {databossid=>\$userid},
                    {admid=>$userid},       {adm2id=>$userid},
                    {swteamid=>\@grpids}
                   );
         $self->itil::appl::addApplicationSecureFilter(['secsystemappl'],\@addflt);
      
         push(@flt,\@addflt);
      }
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




         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) || effChanged($oldrec,$newrec,"runon")){
      my $runon=effVal($oldrec,$newrec,"runon");
      if ($runon eq "0"){
         $newrec->{itclustsid}=undef;
         $newrec->{itcloudareaid}=undef;
         $newrec->{softwareid}=undef;
         $newrec->{version}=undef;
      }
      if ($runon eq "1"){
         $newrec->{lnksoftwaresystemid}=undef;
         $newrec->{systemid}=undef;
         $newrec->{itcloudareaid}=undef;
         $newrec->{softwareid}=undef;
         $newrec->{version}=undef;
      }
      if ($runon eq "2"){
         $newrec->{itclustsid}=undef;
         $newrec->{lnksoftwaresystemid}=undef;
         $newrec->{systemid}=undef;
         $newrec->{softwareid}=undef;
         $newrec->{version}=undef;
      }
      if (effVal($oldrec,$newrec,"techrelstring") ne ""){
         $newrec->{techrelstring};
         $newrec->{techdataupdate}=undef;
      }
      if (effVal($oldrec,$newrec,"techproductstring") ne ""){
         $newrec->{techproductstring};
         $newrec->{techdataupdate}=undef;
      }
   }

   # safe cleanup for hard deleted references
   if (defined($oldrec) && 
       $oldrec->{"systemid"} ne "" &&
       $oldrec->{"system"} eq "" &&
       !exists($newrec->{systemid})){
      $newrec->{systemid}=undef;
   }
   if (defined($oldrec) && 
       $oldrec->{"lnksoftwaresystemid"} ne "" &&
       $oldrec->{"lnksoftwaresystem"} eq "" &&
       !exists($newrec->{lnksoftwaresystemid})){
      $newrec->{lnksoftwaresystemid}=undef;
   }
   if (defined($oldrec) && 
       $oldrec->{"itcloudareaid"} ne "" &&
       $oldrec->{"itcloudarea"} eq "" &&
       !exists($newrec->{itcloudareaid})){
      $newrec->{itcloudareaid}=undef;
   }
 
   foreach my $v (qw(autoname runtimeusername intallusername configdirpath)){ 
      
      if (exists($newrec->{$v})){
         my $autoname=trim(effVal($oldrec,$newrec,$v));
         my $exp="[a-z,A-Z,0-9,_,\\-,\\.]+";
         $exp="[a-z,A-Z,0-9,_,:,\\\\,\/,\\-,\\.]+" if ($v eq "configdirpath");
         if ($autoname ne ""){
            my $errmsg;
            if (!($autoname=~m/^$exp$/)){
               if ($v eq "autoname" && 
                   $self->itil::lib::Listedit::IPValidate($autoname,\$errmsg)){
                  # OK
               }
               else{
                  msg(ERROR,"IPValidate error: $errmsg");
                  $self->LastMsg(ERROR,$self->T("invalid value in field").
                                 " ".$v);
                  return(0);
               }
            }
            $newrec->{$v}=lc($autoname) if ($v eq "autoname" &&
                                            $newrec->{$v} ne $autoname)
         }
         else{
            $newrec->{$v}=undef;
         }
      }
   }
   if (effVal($oldrec,$newrec,"softwareid") ne ""){
      return(undef) if (!$self->validateSoftwareVersion($oldrec,$newrec));
   }

   if (effChanged($oldrec,$newrec,"techrelstring") ||
       effChanged($oldrec,$newrec,"techproductstring") ||
       (defined($newrec) && exists($newrec->{techrelstring})) ||
       (defined($newrec) && exists($newrec->{techproductstring}))){
      $newrec->{techdataupdate}=NowStamp("en");
   }

   my $applid=effVal($oldrec,$newrec,"applid");
   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
   if (effChanged($oldrec,$newrec,"cistatusid") ||
       !defined($oldrec)){
      if ($applid eq "" && $cistatusid>2 && $cistatusid<6){
         $self->LastMsg(ERROR,
            "CI-Status level needs a valid application specification");
         return(0);
      }
   }
   if ($cistatusid<6){ # validation process for swnature handling
      my $swnature=trim(effVal($oldrec,$newrec,"swnature"));
      my @posible=("Other");
      if (effChanged($oldrec,$newrec,"lnksoftwaresystemid") ||
          effChanged($oldrec,$newrec,"softwareid")){
         my $softwareid;

         my $lnksoftwaresystem=$newrec->{lnksoftwaresystemid};
         if ($lnksoftwaresystem ne ""){
            my $lnksoftware=getModuleObject($self->Config(),
                                            "itil::lnksoftware");
            $lnksoftware->SetFilter({id=>\$lnksoftwaresystem});
            my ($swirec)=$lnksoftware->getOnlyFirst(qw(softwareid));
            if (defined($swirec) && $swirec->{softwareid} ne ""){
               $softwareid=$swirec->{softwareid};
            }
         }
         else{
            $softwareid=effVal($oldrec,$newrec,"softwareid");
         }
         if (defined($softwareid) && $softwareid ne ""){
            my $software=getModuleObject($self->Config(),"itil::software");
            $software->SetFilter({id=>\$softwareid});
            my ($swrec)=$software->getOnlyFirst(qw(instanceid));
            if (defined($swrec)){
               my @k=$self->getPosibleInstanceTypes($swrec->{instanceid});
               @posible=();
               while(my $k=shift(@k)){
                  push(@posible,$k);
                  my $label=shift(@k);
               }
               if ($swnature eq "Other" && $#posible>0){
                  $swnature="";
               }
            }   
         }
      }
      else{
         if (defined($oldrec)){
            my $posibleinstanceidentify=effVal($oldrec,$newrec,
                                               "posibleinstanceidentify");
            my @k=$self->getPosibleInstanceTypes($posibleinstanceidentify);
            @posible=();
            while(my $k=shift(@k)){
               push(@posible,$k);
               my $label=shift(@k);
            }
         }
      }
      if (!in_array(\@posible,$swnature)){
         $swnature=$posible[0];
      }
      if ($swnature ne trim(effVal($oldrec,$newrec,"swnature"))){
         if (defined($oldrec)){
            if ($self->isDataInputFromUserFrontend()){ # prevent QC Messages
               $self->LastMsg(WARN,"automatic swnature changed");
            }
            ############################################################
            # prevent doublicate enties on automatic swnature change to Other
            if ($swnature eq "Other"){
               my $iname=effVal($oldrec,$newrec,"name");
               my $iswtype=effVal($oldrec,$newrec,"swtype");
               my $iswport=effVal($oldrec,$newrec,"swport");
               my $o=$self->Clone();
               $o->SetFilter({
                  id=>"!".$oldrec->{id},
                  name=>\$iname,
                  cistatusid=>"<6",
                  swnature=>\"Other",
                  swtype=>\$iswtype,
                  swport=>\$iswport
               });
               my @l=$o->getHashList(qw(id));
               if ($#l!=-1){
                  $iname.="-old".time();
                  $newrec->{name}=$iname;
               }
            }
            ############################################################
         }
         $newrec->{rawswnature}=$swnature;
         $newrec->{swnature}=$swnature;
      }
   }

   my $swnature=trim(effVal($oldrec,$newrec,"swnature"));
   my $name=trim(effVal($oldrec,$newrec,"name"));
   my $addname=trim(effVal($oldrec,$newrec,"addname"));
   my $swtype=trim(effVal($oldrec,$newrec,"swtype"));
   my $swport=trim(effVal($oldrec,$newrec,"swport"));
   my $swinstanceid=trim(effVal($oldrec,$newrec,"swinstanceid"));
   if (exists($newrec->{name})){
      $newrec->{name}=$name;
   }
   $name=~s/\./_/g;
   if ($name eq "" || ($name=~m/[^+-a-z0-9\._\/]/i) || length($name)>40){
      $self->LastMsg(ERROR,"invalid instance name");
      return(0);
   }

   if (exists($newrec->{swnature}) ||
       exists($newrec->{name}) || 
       exists($newrec->{addname}) ||
       exists($newrec->{swtype}) ||
       exists($newrec->{swport}) ){
      my $fname=$name;
      $fname.=($fname ne "" && $swnature ne "" ? "." : "").$swnature;
      $fname.=($fname ne "" && $swtype   ne "" ? "." : "").$swtype;
      $fname.=($fname ne "" && $swport   ne "" ? "." : "").$swport;
      $fname.=($fname ne "" && $addname  ne "" ? "." : "").$addname;
      $fname=~s/ü/ue/g;
      $fname=~s/ö/oe/g;
      $fname=~s/ä/ae/g;
      $fname=~s/Ü/Ue/g;
      $fname=~s/Ö/Oe/g;
      $fname=~s/Ä/Ae/g;
      $fname=~s/ß/ss/g;
      $fname=~s/\s/_/g;
      $newrec->{'fullname'}=$fname;
     
      my $fname=trim(effVal($oldrec,$newrec,"fullname"));
      
      if ($fname eq "" || $fname=~m/[;,\s\&\\]/){
         $self->LastMsg(ERROR,
              sprintf($self->T("invalid swinstance name '%s' specified"),
                      $fname));
         return(0);
      }
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
   if (exists($newrec->{swinstanceid})){
      if ($swinstanceid eq ""){
         $newrec->{swinstanceid}=undef;
      }
   }
   ########################################################################



   #if (defined($oldrec) &&
   #    effChanged($oldrec,$newrec,"runonclusts") &&
   #    !($oldrec->{runonclusts} eq "" && $newrec->{runonclusts} eq "0") ){
   #   $newrec->{lnksoftwaresystemid}=undef;
   #   $newrec->{itclustsid}=undef;
   #   $newrec->{systemid}=undef;
   #}
   #if (defined($newrec->{itclustsid}) &&
   #    defined($newrec->{systemid})){
   #   $newrec->{lnksoftwaresystemid}=undef;
   #   $newrec->{itclustsid}=undef;
   #   $newrec->{systemid}=undef;
   #}
  
   ########################################################################
   if (exists($newrec->{swport})){
      if (effVal($oldrec,$newrec,"swport")=~m/^\s*$/){
         $newrec->{swport}=undef;
      }
   }
   ########################################################################
   my $chksslurl=effVal($oldrec,$newrec,"sslurl");
   if ($chksslurl ne ""){
      $chksslurl=~s/^\[//; # für nicht automatisch
      $chksslurl=~s/\]$//; # gescannte URLs 
      if (!($chksslurl=~m/^(ldaps|https|http):\/\/(\S)+$/) &&
          !($chksslurl=~m/^(\S+):(\d)+$/)){
         $self->LastMsg(ERROR,"url did not looks like a ssl url");
         return(undef);
      }
   }

   if (effChanged($oldrec,$newrec,"sslurl") ||
       effChanged($oldrec,$newrec,"ssl_networkid")){
      $newrec->{sslbegin}=undef;
      $newrec->{sslend}=undef;
      $newrec->{sslstate}=undef;
      $newrec->{ssl_cipher}=undef;
      $newrec->{ssl_version}=undef;
      $newrec->{ssl_certdump}=undef;
      $newrec->{ssl_cert_serialno}=undef;
      $newrec->{ssl_cert_signature_algo}=undef;
      $newrec->{ssl_cert_issuerdn}=undef;
      $newrec->{sslcheck}=undef;
   }
   if (effChanged($oldrec,$newrec,"ssl_expnotifyleaddays")){
      $newrec->{sslcheck}=undef;
      $newrec->{sslexpnotify1}=undef;
   }



   if ((effChanged($oldrec,$newrec,"systemid") ||
        effChanged($oldrec,$newrec,"itclustsid")) &&  # reset software inst
       !exists($newrec->{lnksoftwaresystemid})){
      $newrec->{lnksoftwaresystemid}=undef;
   }


   if (effVal($oldrec,$newrec,"runon") eq "0"){
      if (effVal($oldrec,$newrec,"itclustsid") ne ""){
         $newrec->{itclustsid}=undef;
      }
   }
   if (effVal($oldrec,$newrec,"runon") eq "1"){
      if (exists($newrec->{itclustsid})){
         if ((my $clustsid=effVal($oldrec,$newrec,"itclustsid")) ne ""){ 
            my $c=getModuleObject($self->Config,"itil::lnkitclustsvcappl");
            my $applid=effVal($oldrec,$newrec,"applid");
            $c->SetFilter({itclustsvcid=>\$clustsid,applid=>\$applid});
            my ($rec,$msg)=$c->getOnlyFirst(qw(applid));
            if (!defined($rec)){
               $self->LastMsg(ERROR,"cluster service application and instance ".
                                    "application does not match");
               return(undef);
            }
         }
      }
   }
   if (effVal($oldrec,$newrec,"runon") eq "2"){
      if (exists($newrec->{itcloudareaid})){
         if ((my $cloudareaid=effVal($oldrec,$newrec,"itcloudareaid")) ne ""){ 
            my $c=getModuleObject($self->Config,"itil::itcloudarea");
            my $applid=effVal($oldrec,$newrec,"applid");
            $c->SetFilter({id=>\$cloudareaid,applid=>\$applid});
            my ($rec,$msg)=$c->getOnlyFirst(qw(applid));
            if (!defined($rec)){
               $self->LastMsg(ERROR,"CloudArea application and instance ".
                                    "application does not match");
               return(undef);
            }
         }
      }
   }

   my $cistatusid=effVal($oldrec,$newrec,"cistatusid");

   if ($self->isDataInputFromUserFrontend() &&
       ($cistatusid eq "4" || $cistatusid eq "3")){
      my $applid=effVal($oldrec,$newrec,"applid");
      if (effChanged($oldrec,$newrec,"applid") || 
          effChanged($oldrec,$newrec,"cistatusid")){
         if (effVal($oldrec,$newrec,"runonclusts") ){
            my $itclustsid=effVal($oldrec,$newrec,"itclustsid");
            if (defined($itclustsid)){
               if (!$self->ValidateApplOnClusterService($applid,$itclustsid)){
                  $self->LastMsg(ERROR,
                          "selected application not running ".
                          "on clusterservice from current instance");
                  return(0);
               }
            }
         }
         else{
            my $systemid=effVal($oldrec,$newrec,"systemid");
            if (defined($systemid)){
               if (!$self->ValidateApplOnSystem($applid,$systemid)){
                  $self->LastMsg(ERROR,
                          "selected application not running ".
                          "on logical system from current instance");
                  return(0);
               }
            }
         }
      }
      if (effChanged($oldrec,$newrec,"itclustsid") ||
          effChanged($oldrec,$newrec,"cistatusid")){
         my $itclustsid=effVal($oldrec,$newrec,"itclustsid");
         if (defined($itclustsid)){
            if (!$self->ValidateApplOnClusterService($applid,$itclustsid)){
               $self->LastMsg(ERROR,
                       "selected clusterservice is not running ".
                       "application from current instance");
               return(0);
            }

         } 
      }
      if (effChanged($oldrec,$newrec,"systemid") ||
          effChanged($oldrec,$newrec,"cistatusid")){
         my $systemid=effVal($oldrec,$newrec,"systemid");
         if (defined($systemid)){
            if (!$self->ValidateApplOnSystem($applid,$systemid)){
               $self->LastMsg(ERROR,
                       "The selected logical system is not assigned ".
                       "to the application of the current software instance");
               return(0);
            }
         }
      }
   }

   if (!$self->HandleCIStatusModification($oldrec,$newrec,"fullname")){
      return(0);
   }
   return(1);
}


sub ValidateApplOnSystem
{
   my $self=shift;
   my $applid=shift;
   my $systemid=shift;

   my $lnk=getModuleObject($self->Config,"itil::lnkapplsystem");
   $lnk->SetFilter({applid=>\$applid,systemid=>\$systemid});
   my ($lrec,$msg)=$lnk->getOnlyFirst(qw(it applid systemid reltyp));
   if (defined($lrec) && $lrec->{reltyp} ne "instance"){
      return(1);
   }
   return(0);
}

sub ValidateApplOnClusterService
{
   my $self=shift;
   my $applid=shift;
   my $itclustsvcid=shift;

   my $lnk=getModuleObject($self->Config,"itil::lnkitclustsvcappl");
   $lnk->SetFilter({applid=>\$applid,itclustsvcid=>\$itclustsvcid});
   my ($lrec,$msg)=$lnk->getOnlyFirst(qw(it applid itclustsvcid));
   if (defined($lrec)){
      return(1);
   }
   return(0);
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("header","default") if (!defined($rec));
   my @all=qw(header default adm sec ssl misc monisla env history control
              relations swinstancerules swinstancerunnodes runon
              softwareinst contacts attachments tags
              source swinstanceparam qc);
   if (defined($rec)){
      if ($rec->{'runon'} eq "0"){
         push(@all,"systems");
      }
      if ($rec->{'runon'} eq "1"){
         push(@all,"cluster");
      }
   }
   if ($rec->{isembedded}){
      @all=grep(!/^softwareinst$/,@all);
   }
   #if ($self->IsMemberOf("admin")){
   #   push(@all,"qc");
   #}
   return(@all);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default adm systems contacts ssl env monisla misc 
                       softwareinst relations runon
                       attachments cluster control sec);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
      if ($rec->{databossid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
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
               return(@databossedit);
            }
         }
      }
      if ($rec->{mandatorid}!=0 && 
         $self->IsMemberOf($rec->{mandatorid},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
      if ($rec->{swteam}!=0 && 
         $self->IsMemberOf($rec->{swteam},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
   }
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default adm runon softwareinst env monisla sec misc cluster 
             systems swinstancerunnodes contacts swinstanceparam ssl 
             control swinstancerules attachments relations tags source));
}

sub preQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   return($self->itil::lib::Listedit::preQualityCheckRecord($rec));
}








1;
