package itil::asset;
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
use finance::costcenter;
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

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
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'asset.id'),

      new kernel::Field::RecordUrl(),

                                                  
      new kernel::Field::Select(
                name          =>'class',
                label         =>'Asset Class',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (!defined($param{current})){
                      return(1);
                   }
                   return(0);
                },

                htmleditwidth =>'80px',
                jsonchanged   =>\&getOnChangedClassScript,
                jsoninit      =>\&getOnChangedClassScript,
                readonly     =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(0) if (!defined($current));
                   return(1);
                },
                selectfix     =>1,
                value         =>[qw(
                                      NATIVE
                                      BUNDLE
                                )],
                dataobjattr   =>'asset.class'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'FullName',
                readonly      =>1,
                uivisible     =>0,
                dataobjattr   =>"if (asset.kwords<>'',".
                                "concat(asset.name,' - ',".
                                "if (length(asset.kwords)>40,".
                                "concat(substr(asset.kwords,1,40),'...'),".
                                "asset.kwords)),asset.name)"),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'80px',
                label         =>'Name',
                readonly     =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(0) if (!defined($current));
                   if ($self->getParent->IsMemberOf("admin")){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'asset.name'),

      new kernel::Field::Text(
                name          =>'kwords',
                label         =>'Short Description',
                dataobjattr   =>'asset.kwords'),

      new kernel::Field::TextDrop(
                name          =>'itfarm',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Serverfarm',
                vjointo       =>'itil::lnkitfarmasset',
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>'itfarm'),

      new kernel::Field::Interface(
                name          =>'itfarmid',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'ServerfarmID',
                vjointo       =>'itil::lnkitfarmasset',
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>'itfarmid'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'asset.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
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
                dataobjattr   =>'asset.cistatus'),


      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'asset.databoss'),

      new kernel::Field::TextDrop(
                name          =>'hwmodel',
                htmlwidth     =>'130px',
                group         =>'physasset',
                label         =>'Hardwaremodel',
                vjointo       =>'itil::hwmodel',
                vjoinon       =>['hwmodelid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                htmlwidth     =>'200px',
                group         =>'systems',
                htmllimit     =>'20',
                forwardSearch =>1,
                subeditmsk    =>'stodu',
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoininhash   =>['name','systemid','cistatusid','id'],
                vjoindisp     =>['name','systemid','cistatus','shortdesc']),

      new kernel::Field::TextDrop(
                name          =>'hwproducer',
                htmlwidth     =>'130px',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'physasset',
                label         =>'Hardwareproducer',
                vjointo       =>'itil::hwmodel',
                vjoinon       =>['hwmodelid'=>'id'],
                vjoindisp     =>'producer'),



      new kernel::Field::Link(
                name          =>'hwmodelid',
                dataobjattr   =>'asset.hwmodel'),

      new kernel::Field::Text(
                name          =>'serialno',
                group         =>'physasset',
                xlswidth      =>15,
                label         =>'Serialnumber',
                dataobjattr   =>'asset.serialnumber'),

      new kernel::Field::Text(
                name          =>'systemhandle',
                group         =>'physasset',
                label         =>'Producer System-Handle',
                dataobjattr   =>'asset.systemhandle'),

      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                group         =>'physasset',
                AllowEmpty    =>1,
                label         =>'Producer Service&Support Class',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'asset.prodmaintlevel'),

      new kernel::Field::SubList(
                name          =>'systemnames',
                label         =>'System names',
                htmlwidth     =>'200px',
                htmldetail    =>0,
                searchable    =>0,
                group         =>'systems',
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['name']),

      new kernel::Field::SubList(
                name          =>'systemids',
                label         =>'System IDs',
                htmlwidth     =>'200px',
                group         =>'systems',
                htmldetail    =>0,
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['systemid']),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                htmlwidth     =>'300px',
                group         =>'applications',
                htmllimit     =>'20',
                forwardSearch =>1,
                readonly      =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoininhash   =>['appl','applcistatus','applcustomer','applid'],
                vjoindisp     =>['appl','applcistatus','applcustomer']),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Application names',
                htmlwidth     =>'300px',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Text(
                name          =>'tsmemails',
                label         =>'Technical Solution Manager E-Mails',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['tsmemail']),

      new kernel::Field::SubList(
                name          =>'applicationteams',
                label         =>'Application business teams',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['businessteam']),

      new kernel::Field::SubList(
                name          =>'customer',
                label         =>'Application Customers',
                htmlwidth     =>'200px',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['applcustomer','appl']),

      new kernel::Field::Text(
                name          =>'customernames',
                label         =>'Customer names',
                htmlwidth     =>'200px',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['applcustomer']),

      new kernel::Field::Number(
                name          =>'cpucount',
                xlswidth      =>10,
                group         =>'physasset',
                label         =>'CPU-Count',
                wrdataobjattr =>"asset.cpucount",
                dataobjattr   =>"if (asset.class='BUNDLE',1,asset.cpucount)"),

      new kernel::Field::Number(
                name          =>'cpuspeed',
                xlswidth      =>10,
                group         =>'physasset',
                unit          =>'MHz',
                label         =>'CPU-Speed',
                wrdataobjattr =>"asset.cpuspeed",
                dataobjattr   =>"if (asset.class='BUNDLE',1,asset.cpuspeed)"),

      new kernel::Field::Number(
                name          =>'corecount',
                xlswidth      =>10,
                group         =>'physasset',
                label         =>'Core-Count',
                wrdataobjattr =>"asset.corecount",
                dataobjattr   =>"if (asset.class='BUNDLE',1,asset.corecount)"),

      new kernel::Field::Number(
                name          =>'memory',
                group         =>'physasset',
                xlswidth      =>10,
                label         =>'Memory',
                unit          =>'MB',
                wrdataobjattr =>"asset.memory",
                dataobjattr   =>"if (asset.class='BUNDLE',1,asset.memory)"),

      new kernel::Field::SubList(
                name          =>'compassets',
                label         =>'composing assets',
                group         =>'compassets',
                vjointo       =>'itil::lnkassetasset',
                vjoinon       =>['id'=>'passetid'],
                vjoininhash   =>['cassetid','casset','id',
                                 'cassetlocation','cassetlocationid'],
                vjoindisp     =>['casset','cassetcistatus','cassetlocation']),

      new kernel::Field::SubList(
                name          =>'passet',
                label         =>'parent asset',
                group         =>'passet',
                readonly      =>1,
                htmldetail    =>"notEmpty",
                vjointo       =>'itil::lnkassetasset',
                vjoinon       =>['id'=>'cassetid'],
                vjoininhash   =>['passetid','passet','id'],
                vjoindisp     =>['passet']),


      new kernel::Field::TextDrop(
                name          =>'location',
                group         =>'location',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                group         =>'location',
                dataobjattr   =>'asset.location'),

      new kernel::Field::Text(
                name          =>'room',
                group         =>'location',
                label         =>'Room',
                htmldetail    =>\&hideOnBundle,
                dataobjattr   =>'asset.room'),
                                                   
      new kernel::Field::Text(
                name          =>'place',
                group         =>'location',
                label         =>'Place',
                htmldetail    =>\&hideOnBundle,
                dataobjattr   =>'asset.place'),
                                                   
      new kernel::Field::Text(
                name          =>'rack',
                group         =>'location',
                label         =>'Rack identifier',
                htmldetail    =>\&hideOnBundle,
                dataobjattr   =>'asset.rack'),

      new kernel::Field::Text(
                name          =>'slotno',
                label         =>'Slot number',
                group         =>"location",
                htmldetail    =>\&hideOnBundle,
                dataobjattr   =>'asset.slotno'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'asset.comments'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                group         =>'financeco',
                label         =>'Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'asset.conumber'),

      new kernel::Field::Select(
                name          =>'acqumode',
                label         =>'Acquisition Mode',
                jsonchanged   =>\&getOnChangedAcquScript,
                jsoninit      =>\&getOnChangedAcquScript,
                group         =>'financeco',
                selectfix     =>1,
                value         =>[qw(
                                      PURCHASE
                                      RENTAL
                                      LEASE
                                      LOAN
                                      PROVISION
                                      FREE
                                )],
                dataobjattr   =>'asset.acquMode'),

      new kernel::Field::Date(
                name          =>'startacqu',
                group         =>'financeco',
                dayonly       =>1,
                selectfix     =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{'acqumode'} ne "PURCHASE"){
                      return(1);
                   }
                   return(1) if ($param{currentfieldgroup} eq $self->{group});
                   return(0);
                },
                label         =>'Acquisition Start',
                dataobjattr   =>'asset.acquStart'),

      new kernel::Field::Date(
                name          =>'deprstart',
                depend        =>['acqumode'],
                group         =>'financeco',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{'acqumode'} eq "PURCHASE"){
                      return(1);
                   }
                   return(1) if ($param{currentfieldgroup} eq $self->{group});
                   return(0);
                },
                dayonly       =>1,
                selectfix     =>1,
                label         =>'Deprecation Start',
                dataobjattr   =>'asset.deprstart'),

      new kernel::Field::Date(
                name          =>'deprend',
                depend        =>['acqumode'],
                group         =>'financeco',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{'acqumode'} eq "PURCHASE"){
                      return(1);
                   }
                   return(1) if ($param{currentfieldgroup} eq $self->{group});
                   return(0);
                },
                dayonly       =>1,
                label         =>'Deprecation End',
                dataobjattr   =>'asset.deprend'),

      new kernel::Field::Number(
                name          =>'age',
                group         =>'financeco',
                unit          =>'days',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Hardware age',
                dataobjattr   =>"if (acqumode='PURCHASE',".
                                "datediff(sysdate(),asset.deprstart),".
                                "datediff(sysdate(),asset.acquStart))"),

      new kernel::Field::Date(
                name          =>'eohs',
                group         =>'financeco',
                dayonly       =>1,
                label         =>'end of hardware support',
                dataobjattr   =>'asset.eohsd'),

      new kernel::Field::Date(
                name          =>'plandecons',
                group         =>'financeco',
                dayonly       =>1,
                depend        =>['eohs'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;

                   my $ShowPlanedDeCons=0;

                   if (exists($param{current}) &&
                       $param{current}->{'eohs'} ne ""){
                      my $deohs=CalcDateDuration(NowStamp("en"),
                                            $param{current}->{'eohs'});
                      if ($deohs->{totaldays}<366){
                         $ShowPlanedDeCons=1;
                      }
                   }
                   if (exists($param{current}) &&
                       $param{current}->{'plandecons'} ne ""){
                      $ShowPlanedDeCons=1;
                   }
                   return($ShowPlanedDeCons);
                },
                label         =>'planned deconstruction date',
                dataobjattr   =>'asset.plandecons'),

     new kernel::Field::Textarea(
                name          =>'eohscomments',
                group         =>'financeco',
                depend        =>['eohs','plandecons'],
                htmlheight    =>'50px',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;

                   my $ShowComments=0;

                   if (exists($param{current}) &&
                       $param{current}->{'eohs'} ne ""){
                      my $deohs=CalcDateDuration(NowStamp("en"),
                                            $param{current}->{'eohs'});
                      if ($deohs->{totaldays}<366){
                         $ShowComments=1;
                      }
                   }
                   if (exists($param{current}) &&
                       $param{current}->{'plandecons'} ne ""){
                      my $dplandecons=CalcDateDuration(NowStamp("en"),
                                            $param{current}->{'plandecons'});
                      if ($dplandecons->{totaldays}<366){
                         $ShowComments=1;
                      }
                   }
                   if (exists($param{current}) &&
                       $param{current}->{'eohscomments'} ne ""){
                      $ShowComments=1;
                   }

                   return($ShowComments);
                },
                label         =>'justification when exceeding '.
                                '"end of hardware support"',
                dataobjattr   =>'asset.eohscomments'),


      new kernel::Field::Date(
                name          =>'notifyplandecons1',
                group         =>'financeco',
                uivisible     =>0,
                label         =>'notify1 planned deconstruction date',
                dataobjattr   =>'asset.notifyplandecons1'),

      new kernel::Field::Date(
                name          =>'notifyplandecons2',
                group         =>'financeco',
                uivisible     =>0,
                label         =>'notify2 planned deconstruction date',
                dataobjattr   =>'asset.notifyplandecons2'),

      new kernel::Field::Select(
                name          =>'denyupselect',
                label         =>'it is posible to refresh hardware',
                jsonchanged   =>\&itil::lib::Listedit::getupdateDenyHandlingScript,
                jsoninit      =>\&itil::lib::Listedit::getupdateDenyHandlingScript,
                group         =>'upd',
                vjointo       =>'itil::upddeny',
                vjoinon       =>['denyupd'=>'id'],
                vjoineditbase =>{id=>"!99"},   # 99 = sonstige Gründe = nicht zulässig
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'denyupd',
                group         =>'upd',
                default       =>'0',
                label         =>'UpdDenyID',
                dataobjattr   =>'asset.denyupd'),



     new kernel::Field::Date(
                name          =>'refreshpland',
                group         =>'upd',
                dayonly       =>1,
                depend        =>['denyupd'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{$self->{name}} ne ""){
                      return(1);
                   }
                   return(1) if ($param{currentfieldgroup} eq $self->{group});
                   return(0);
                },
                label         =>'planned Upgrade/Refresh date',
                dataobjattr   =>'asset.refreshpland'),

     new kernel::Field::Textarea(
                name          =>'denyupdcomments',
                group         =>'upd',
                depend        =>['deprstart'],
                label         =>'comments to Update/Refresh posibilities',
                dataobjattr   =>'asset.denyupdcomments'),

     new kernel::Field::Date(
                name          =>'denyupdvalidto',
                group         =>'upd',
                depend        =>['deprstart'],
                htmldetail    =>sub{
                                   my $self=shift;
                                   my $mode=shift;
                                   my %param=@_;
                                   if (defined($param{current})){
                                      my $d=$param{current}->{$self->{name}};
                                      return(1) if ($d ne "");
                                   }
                                   return(0);
                                },
                label         =>'Upgrade/Refresh reject valid to',
                dataobjattr   =>'asset.denyupdvalidto'),

     new kernel::Field::Date(
                name          =>'refreshinfo1',
                group         =>'upd',
                uivisible     =>0,
                label         =>'Refresh notification 1',
                dataobjattr   =>'asset.refreshinfo1'),

     new kernel::Field::Date(
                name          =>'refreshinfo2',
                group         =>'upd',
                uivisible     =>0,
                label         =>'Refresh notification 2',
                dataobjattr   =>'asset.refreshinfo2'),

#     new kernel::Field::Text(
#                name          =>'refreshstate',
#                group         =>'upd',
#                htmldetail    =>0,
#                searchable    =>1,
#                label         =>'Hardware refresh light',
#                dataobjattr   =>getSQLrefreshstateCommand()),

#     new kernel::Field::Text(
#                name          =>'assetrefreshstate',
#                group         =>'upd',
#                htmldetail    =>0,
#                readonly      =>1,
#                searchable    =>0,
#                label         =>'Hardware refresh state',
#                depend        =>['deprstart','denyupdvalidto','refreshstate'],
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $fo=$self->getParent->getField("refreshstate");
#                   my $f=$fo->RawValue($current);
#                   $f=~s/\s.*$//;
#                   my $s="FAIL";
#                   if ($f eq "green"){
#                      $s="OK"
#                   }
#                   elsif ($f eq "yellow"){
#                      $s="WARN"
#                   }
#                   elsif ($f eq "lightgreen"){
#                      $s="WARN but OK"
#                   }
#                   elsif ($f eq "red"){
#                      $s="FAIL"
#                   }
#                   elsif ($f eq "blue"){
#                      $s="FAIL but OK"
#                   }
#                   return($s);
#                }),
                

     new kernel::Field::Date(
                name          =>'refreshinfo3',
                group         =>'upd',
                uivisible     =>0,
                label         =>'Refresh notification 3',
                dataobjattr   =>'asset.refreshinfo3'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::asset'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::asset'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::FileList(
                name          =>'attachments',
                searchable    =>0,
                parentobj     =>'itil::asset',
                label         =>'Attachments',
                group         =>'attachments'),

      new kernel::Field::Contact(
                name          =>'guardian',
                AllowEmpty    =>1,
                group         =>'guardian',
                label         =>'Guardian',
                vjoinon       =>['guardianid'=>'userid']),

      new kernel::Field::Link(
                name          =>'guardianid',
                dataobjattr   =>'asset.guardian'),

      new kernel::Field::Contact(
                name          =>'guardian2',
                AllowEmpty    =>1,
                group         =>'guardian',
                label         =>'Deputy Guardian',
                vjoinon       =>['guardian2id'=>'userid']),

      new kernel::Field::Link(
                name          =>'guardian2id',
                dataobjattr   =>'asset.guardian2'),

      new kernel::Field::TextDrop(
                name          =>'guardianteam',
                htmlwidth     =>'300px',
                group         =>'guardian',
                label         =>'Guardian Team',
                vjointo       =>'base::grp',
                vjoinon       =>['guardianteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'guardianteamid',
                dataobjattr   =>'asset.guardianteam'),

      new kernel::Field::JoinUniqMerge(
                name          =>'issox',
                label         =>'mangaged by rules of SOX',
                group         =>'sec',
                searchable    =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>'assetissox'),

      new kernel::Field::Select(
                name          =>'nosoxinherit',
                group         =>'sec',
                label         =>'SOX state',
                searchable    =>0,
                transprefix   =>'SysInherit.',
                htmleditwidth =>'180px',
                value         =>['0','1'],
                dataobjattr   =>'asset.no_sox_inherit'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'asset.allowifupdate'),

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
                dataobjattr   =>'asset.additional'),

      new kernel::Field::Text(
                name          =>'rawclass',
                label         =>'Asset Class',
                group         =>'source',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (!defined($param{current})){
                      return(0);
                   }
                   return(1);
                },
                readonly     =>1,
                dataobjattr   =>'asset.class'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"asset.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(asset.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'asset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'asset.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                htmldetail    =>'NotEmpty',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'asset.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'asset.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'asset.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'asset.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'asset.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'asset.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'asset.realeditor'),

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

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'asset.lastqcheck'),

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
                dataobjattr   =>'asset.lrecertreqdt'),

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
                dataobjattr   =>'asset.lrecertreqnotify'),

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
                dataobjattr   =>'asset.lrecertdt'),

      new kernel::Field::Interface(
                name          =>'lrecertuser',
                group         =>'qc',
                label         =>'last recert userid',
                htmldetail    =>'0',
                dataobjattr   =>"asset.lrecertuser")

   );
   $self->{workflowlink}={ workflowkey=>\&createWorkflowQuery
                         };

   $self->{CI_Handling}={uniquename=>"name",
                         uniquesize=>40};

   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{use_distinct}=1;

   $self->setDefaultView(qw(linenumber name hwmodel serialno 
                            cistatus mandator mdate));


   $self->{PhoneLnkUsage}=\&PhoneUsage;

   $self->setDefaultView(qw(name mandator cistatus mdate));
   $self->setWorktable("asset");
   return($self);
}

#sub getSQLrefreshstateCommand
#{
#   my $shortterm="INTERVAL 36 MONTH";
#   my $longterm="INTERVAL 60 MONTH";
#   my $d=<<EOF;
#
#if (if (asset.acquMode='PURCHASE',asset.deprstart,asset.acquStart) is not null,
#   if (asset.refreshpland is not null and asset.refreshpland>sysdate(),
#      'green => refreshplaned is set',
#   /*ELSE no refresh planed is set*/
#      if (asset.denyupdvalidto is not null and asset.denyupd>0,
#         if (date_add(asset.denyupdvalidto,INTERVAL -1 MONTH)<sysdate(),
#            'yellow',
#         /*ELSE Begruendungsendezeitpunkt liegt ausreichend in der Zukunft*/
#            if (length(asset.denyupdcomments)>10,
#               'blue =>comment exists and is valid',
#            /*ELSE kein Begründungstext vorhanden*/
#               'red => 5 years and no comments'
#            )
#         ),
#      /*ELSE kein Begruendungsendezeitpunkt*/
#         if (date_add(if (asset.acquMode='PURCHASE',
#                        asset.deprstart,asset.acquStart),${longterm})<sysdate(),
#            'red => 5 years',
#         /*ELSE*/
#            if (date_add(if (asset.acquMode='PURCHASE',
#                     asset.deprstart,asset.acquStart),${shortterm})<sysdate(),
#               if (length(asset.denyupdcomments)>10,
#                  'lightgreen',
#               /*ELSE Bemerkung nicht vorhanden*/
#                  'yellow => 3 years and no comments'
#               ),
#            /*ELSE*/
#               'green'
#            )
#         )
#      )
#   ),
#/*ELSE Start nicht gesetzt*/
#   'yellow => no start date'
#)
#
#
#EOF
#
#   return($d);
#}

sub hideOnBundle{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   if (exists($param{current}) &&
       $param{current}->{'class'} eq "BUNDLE"){
      return(0);
   }
   return(1);
}


sub preQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{cistatusid}>=6){
      my ($uniquesuff)=$rec->{name}=~m/(\[[0-9]+\])$/;
      if ($self->getField("srcid")){
         if ($uniquesuff ne "" && !($rec->{srcid}=~m/\[[0-9]\]$/) &&
             $rec->{srcid} ne ""){
            my $nowstamp=NowStamp("en");
            my $age=CalcDateDuration($rec->{mdate},$nowstamp);
            if ($age->{days}>7){
               my $newmdate=$rec->{mdate};
               if ($age->{days}<60){   # bei sehr alten Datensätzen den mdate
                  $newmdate=$nowstamp; # nicht verändern - das gibt sonst 
               }                       # Probleme beim verschrotten
               my $idfield=$self->IdField();
               if (defined($idfield)){
                  my $id=$idfield->RawValue($rec);
                  if ($id ne ""){
                     $self->ValidatedUpdateRecord($rec,{
                        mdate=>$newmdate,
                        srcid=>$rec->{srcid}.$uniquesuff
                     },{$idfield->Name()=>$id});
                     #$rec->{srcid}=$rec->{srcid}.$uniquesuff;
                     $rec->{mdate}=$newmdate;  # eigentlich nicht notwendig,
                                               # da mit dem Patch  685daa5c
                                               # bereits oldrec aktualisiert
                  }                            # wird.
               }
            }
         }
      }
   }
   return(1);
}



sub PhoneUsage
{
   my $self=shift;
   return('phoneRB',$self->T("phoneRB","itil::appl"));
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::asset");
}

#sub getOnChangedScript
#{
#   my $self=shift;
#   my $app=$self->getParent();
#
#   my $d=<<EOF;
#
#var d=document.forms[0].elements['Formated_denyupd'];
#var r=document.forms[0].elements['Formated_refreshpland'];
#
#if (d && r){
#   var v=d.options[d.selectedIndex].value;
#   if (v!="" && v!="0"){
#      r.value="";
#      r.disabled=true;
#   }
#   else{
#      r.disabled=false;
#   }
#}
#
#EOF
#   return($d);
#}


sub getOnChangedAcquScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var d=document.forms[0].elements['Formated_acqumode'];
var s=document.forms[0].elements['Formated_startacqu'];
var ds=document.forms[0].elements['Formated_deprstart'];
var de=document.forms[0].elements['Formated_deprend'];

if (d && s && ds && de){
   var v=d.options[d.selectedIndex].value;
   if (v=="PURCHASE"){
      s.value="";
      s.disabled=true;
      ds.disabled=false;
      de.disabled=false;
   }
   else{
      s.disabled=false;
      ds.disabled=true;
      ds.value="";
      de.disabled=true;
      de.value="";
   }
}

EOF
   return($d);
}



sub getOnChangedClassScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;
console.log("class changed");

EOF
   return($d);
}







sub createWorkflowQuery
{
   my $self=shift;
   my $q=shift;
   my $id=shift;

   $self->ResetFilter();
   $self->SetFilter({id=>$id});
   my ($rec,$msg)=$self->getOnlyFirst(qw(systems));
   my %sid=();
   if (defined($rec->{systems}) && ref($rec->{systems}) eq "ARRAY"){
      foreach my $srec (@{$rec->{systems}}){
         $sid{$srec->{id}}=1;
      }
   }
   $q->{affectedsystemid}=[keys(%sid)];   
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/asset.jpg?".$cgi->query_string());
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.system.read w5base.itil.read)],
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
                    {guardianid=>$userid},       {guardian2id=>$userid},
                    {guardianteamid=>\@grpids}
                   );
      }
      push(@flt,\@addflt);
   }
   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);

   }
   return($self->SetFilter(@flt));
}


sub getSqlFrom
{  
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::asset' ".
          "and $worktable.id=lnkcontact.refid";

   return($from);
}


sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   if ($#{$rec->{systems}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no system relations");
      return(0);
   }

   return(1);
}


sub prepareToWasted
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{srcsys}=undef;
   $newrec->{srcid}=undef;
   $newrec->{srcload}=undef;
   my $id=effVal($oldrec,$newrec,"id");

   #my $o=getModuleObject($self->Config,"itil::lnkapplappl");
   #if (defined($o)){
   #   $o->BulkDeleteRecord({toapplid=>\$id});
   #   $o->BulkDeleteRecord({fromapplid=>\$id});
   #}

   return(1);   # if undef, no wasted Transfer is allowed
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


   if (effChangedVal($oldrec,$newrec,"cistatusid")==7){
      return(1);
   }
   if ((!defined($oldrec) || defined($newrec->{name})) &&
       (($newrec->{name}=~m/^\s*$/) || length($newrec->{name})<3 ||
         haveSpecialChar($newrec->{name}))){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   my $systemhandle=trim(effVal($oldrec,$newrec,"systemhandle"));
   $systemhandle=undef if ($systemhandle eq "");
   if (exists($newrec->{systemhandle}) && 
       $newrec->{systemhandle} ne $systemhandle){
      $newrec->{systemhandle}=$systemhandle;
   }
   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      if (!$self->finance::costcenter::ValidateCONumber(
           $self->SelfAsParentObject(),"conumber",
          $oldrec,$newrec)){
         $self->LastMsg(ERROR,
             $self->T("invalid number format '\%s' specified",
                      "finance::costcenter"),$newrec->{conumber});
         return(0);
      }
   }
   if (effChanged($oldrec,$newrec,"acqumode")){
      if ($newrec->{acqumode} ne "PURCHASE"){
         $newrec->{deprstart}=undef;
         $newrec->{deprend}=undef;
      }
      else{
         $newrec->{startacqu}=undef;
      }
   }



   my $deprend=effVal($oldrec,$newrec,"deprend");
   my $deprstart=effVal($oldrec,$newrec,"deprstart");
   if ($deprend ne "" && $deprstart ne ""){
      my $duration=CalcDateDuration($deprstart,$deprend);
      if ($duration->{totalseconds}<0){
         $self->LastMsg(ERROR,"deprend can not be sooner as deprstart");
         my $srcid=effVal($oldrec,$newrec,"srcid");
         msg(ERROR,"totalseconds=$duration->{totalseconds} ".
                   "start=$deprstart end=$deprend srcid=$srcid");
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
            $newrec->{databossid}=$userid;
         }
      }
      if (!$self->IsMemberOf("admin") && 
          (defined($newrec->{databossid}) &&
           $newrec->{databossid}!=$userid &&
           $newrec->{databossid}!=$oldrec->{databossid})){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################

   if (effVal($oldrec,$newrec,"denyupd")!=0){
      if (effVal($oldrec,$newrec,"refreshpland") ne ""){
         $newrec->{refreshpland}=undef;
      }
   }
   if (effChanged($oldrec,$newrec,"plandecons","dayonly")){
      my $eohs=effVal($oldrec,$newrec,"plandecons");
      if ($eohs ne ""){
         my $nowstamp=NowStamp("en");
         my $age=CalcDateDuration($nowstamp,$eohs);
         if (!defined($age) ||
             $age->{days}>365*5 ||
             $age->{days}<(365*1)*-1){
            $self->LastMsg(ERROR,
                       "planned deconstruction date in unexpected range");
            return(0);
         }
      }
   }
   if (effChanged($oldrec,$newrec,"eohs","dayonly")){
      my $eohs=effVal($oldrec,$newrec,"eohs");
      if ($eohs ne ""){
         my $nowstamp=NowStamp("en");
         my $age=CalcDateDuration($nowstamp,$eohs);
         if (!defined($age) ||
             $age->{days}>365*11 ||
             $age->{days}<(365*10)*-1){
            $self->LastMsg(ERROR,"End of Hardware-Support in unexpected range");
            return(0);
         }
      }
   }

   if (effChanged($oldrec,$newrec,"eohs","dayonly")){
      # reset refreshinfo if eohs changed
      foreach my $var (qw(refreshinfo3 refreshinfo2 refreshinfo1
                          notifyplandecons1 notifyplandecons2)){
         my $cur=effVal($oldrec,$newrec,$var);
         if ($cur ne ""){
            $newrec->{$var}=undef;
         }
      }
   }
   if (effChanged($oldrec,$newrec,"plandecons","dayonly")){  # reset notifypland
      foreach my $var (qw(notifyplandecons1 notifyplandecons2)){
         my $cur=effVal($oldrec,$newrec,$var);
         if ($cur ne ""){
            $newrec->{$var}=undef;
         }
      }
   }


   if ($oldrec->{class} eq "BUNDLE"){
      foreach my $fld (qw(room place rack slotno)){
         if (effVal($oldrec,$newrec,$fld) ne ""){
            $newrec->{$fld}="";
         }
      }
   }




   if (!$self->itil::lib::Listedit::updateDenyHandling($oldrec,$newrec)){
      return(0);
   }

   if (defined($oldrec)){
      if (effChanged($oldrec,$newrec,"cistatusid")){
         my $old=$oldrec->{cistatusid};
         my $new=$newrec->{cistatusid};
         if ($old==3 || $old==4){
            if ($new<$old || $new>4){
               my $found4=0;
               my $found=0;
               foreach my $sysrec (@{$oldrec->{systems}}){
                  if ($sysrec->{cistatusid}>=3 &&
                      $sysrec->{cistatusid}<6){
                     $found4++;
                  }
                  $found++;
               }
               if ($found4 && $new!=4){
                  $self->LastMsg(ERROR,"CI-State change not allowed ".
                                       "while existing active logical systems");
                  return(0);
               }
               if ($found && ($new<3 || $new>4)){
                  $self->LastMsg(ERROR,"CI-State change not allowed while ".
                                       "existing logical systems");
                  return(0);
               }
            }
         }
      }
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
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return(qw(header default)) if (defined($rec) && $rec->{cistatusid}==7);

   my @all=qw(default contacts control 
              systems source qc applications
              misc attachments history);

   if ($rec->{class} eq "NATIVE"){
      push(@all,qw(guardian physasset location sec financeco
                   phonenumbers passet));

   }
   if ($rec->{class} eq "BUNDLE"){
      push(@all,qw(location compassets));

   }
   if (($rec->{acqumode} eq "PURCHASE" && $rec->{deprstart} ne "") ||
       ($rec->{acqumode} ne "PURCHASE" && $rec->{startacqu} ne "")){
      push(@all,"upd");
   }
   return(@all);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default guardian physasset contacts control location 
                       phonenumbers misc attachments sec financeco
                       upd);
   if (defined($rec) && $rec->{class} eq "BUNDLE"){
      push(@databossedit,"compassets");
   }
   if (!defined($rec)){
      return("default","control");
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
            return(@databossedit) if (grep(/^write$/,@roles));
         }
      }
      if ($rec->{mandatorid}!=0 &&
         $self->IsMemberOf($rec->{mandatorid},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
      if ($rec->{guardianteamid}!=0 &&
         $self->IsMemberOf($rec->{guardianteamid},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
   }
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default guardian phonenumbers location compassets passet
             physasset sec financeco upd contacts misc systems 
             applications attachments control source));
}


sub getHtmlPublicDetailFields
{
   my $self=shift;
   my $rec=shift;

   my @l=qw(mandator name guardian guardian2  databoss);
   return(@l);
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
   my @l=$self->getHtmlPublicDetailFields($rec);
   foreach my $v (@l){
      if ($rec->{$v} ne ""){
         my $name=$self->getField($v)->Label();
         my $data=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      $v,"formated");
         $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                      "<td valign=top>$data</td></tr>\n";
      }
   }

   $htmlresult.="</table>\n";
   return($htmlresult);

}




1;
