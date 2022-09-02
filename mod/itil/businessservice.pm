package itil::businessservice;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use DateTime;
use DateTime::Span;
use itil::lib::BorderChangeHandling;
use itil::lib::Listedit;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{Worktable}="businessservice";
   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                group         =>'source',
                dataobjattr   =>"$worktable.id"),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                sqlorder      =>'desc',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'Business-Service Fullname',
                dataobjattr   =>getBSfullnameSQL($worktable,"applname")),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                label         =>'Name',
                explore       =>200,
                dataobjattr   =>"$worktable.name"),

      new kernel::Field::Text(
                name          =>'shortname',
                sqlorder      =>'desc',
                htmldetail    =>'NotEmptyOrEdit',
                htmleditwidth =>'50px',
                explore       =>300,
                label         =>'Short name',
                dataobjattr   =>"$worktable.shortname"),


      new kernel::Field::Mandator( 
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if ($current->{applid} ne "");
                   return(0);
                },
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1);
                   return(1) if (defined($current));
                   return(0);
                }),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                default       =>4,
                explore       =>400,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>"$worktable.cistatus"),

      new kernel::Field::Select(
                name          =>'nature',
                sqlorder      =>'desc',
                label         =>'Nature',
                htmleditwidth =>'60%',
                selectfix     =>'1',
                explore       =>500,
                transprefix   =>'nat.',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                jsonchanged   =>\&getOnChangedScript,
                jsoninit      =>\&getOnChangedScript,
                value         =>['','SVC','PRC','BC'],
                dataobjattr   =>"$worktable.nature"),

      new kernel::Field::Interface(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"applid"),
                                                  
      new kernel::Field::Link(
                name          =>'applid',
                selectfix     =>1,
                label         =>'ApplicationID',
                dataobjattr   =>"$worktable.appl"),

      new kernel::Field::Databoss(
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current})){
                      return(1);
                   }
                   return(1);
                },
                explore       =>600,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if ($current->{applid} ne "");
                   return(0);
                }),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                label         =>'Databoss ID',
                dataobjattr   =>"if ($worktable.appl is null,".
                                "$worktable.databoss,".
                                "appldataboss)",
                wrdataobjattr  =>"$worktable.databoss"),
                                                  
      new kernel::Field::Text(
                name          =>'application',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
               
                   return(1) if (defined($current) &&
                                 $current->{applid} ne "");
                   return(0);
                },
                uploadable    =>0,
                explore       =>700,
                label         =>'primarily provided by application',
                weblinkto     =>'itil::appl',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'applname'),

      new kernel::Field::TextDrop(
                name          =>'srcapplication',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(0) if (defined($current));
                   return(1);
                },
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                uploadable    =>1,
                label         =>'provided by application',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Contact(
                name          =>'funcmgr',
                explore       =>450,
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                label         =>'functional manager',
                vjoinon       =>'funcmgrid'),

                                                  
      new kernel::Field::Link(
                name          =>'funcmgrid',
                label         =>'functional mgr id',
                dataobjattr   =>"$worktable.funcmgr"),

      new kernel::Field::Link(
                name          =>'mandatorid',
                selectfix     =>1,
                label         =>'Databoss ID',
                dataobjattr   =>"if ($worktable.appl is null,".
                                "$worktable.mandator,".
                                "applmandator)",
                wrdataobjattr  =>"$worktable.mandator"),
                                                  
      new kernel::Field::Text(
                name          =>'mgmtitemgroup',
                label         =>'central managed CI groups',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>1,
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'PCONTROL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Interface(
                name          =>'servicetrees',
                label         =>'service trees',
                readonly      =>1,
                searchable    =>0,
                depend        =>['id','fullname','nature','applid'],
                onRawValue    =>\&itil::lib::Listedit::calculateServiceTrees),


#      new kernel::Field::TimeSpans(
#                name          =>'supportReq',
#                label         =>'requested service times',
#                uploadable    =>0,
#                readonly      =>1,
#                searchable    =>0,
#                htmldetail    =>0,
#                tspantype     =>['R','K'],
#                tspanlegend   =>1,
#                tspantypeproc =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $blk=shift;
#                   $blk->[4]="transparent";
#                   if ($blk->[2] eq "on"){
#                      $blk->[4]="blue";
#                      $blk->[4]="blue" if ($blk->[3] eq "K");
#                      $blk->[4]="yellow" if ($blk->[3] eq "R");
#                   }
#                   if ($blk->[2] eq "off"){
#                      $blk->[4]="red";
#                   }
#                },
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $id=$current->{id};
#                   my $st={};
#                   $self->getParent->LoadTreeSPCheck($st,
#                                    "itil::businessservice",$id);
#                   return(
#                      dumpSpanSet(
#                         {},
#                         'K',$st->{tree}->{entry}->{DirectSS}->{supportK},
#                         'R',$st->{tree}->{entry}->{DirectSS}->{supportR})
#                   );
#                }),
#
#
#      new kernel::Field::TimeSpans(
#                name          =>'supportTreeCheck',
#                htmldetail    =>0,
#                uploadable    =>0,
#                readonly      =>1,
#                searchable    =>0,
#                label         =>'aggregated service times tree',
#                tspantype     =>{'k'=>'core replaced by border time',
#                                 ''=>'',
#                                 'r'=>'border replaced by core time',
#                                 'K'=>'continuous core time',
#                                 'R'=>'continuous border time'},
#                tspanlegend   =>1,
#                tspantypeproc =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $blk=shift;
#                   $blk->[4]="transparent";
#                   if ($blk->[2] eq "on" || $blk->[2] eq "legend"){
#                      $blk->[4]="blue";
##                      $blk->[4]="lightblue" if ($blk->[3] eq "k");
#                      $blk->[4]="lightyellow" if ($blk->[3] eq "r");
#                      $blk->[4]="yellow" if ($blk->[3] eq "R");
#                   }
#                   if ($blk->[2] eq "off" || $blk->[3] eq ""){
#                      $blk->[4]="red";
#                   }
#                },
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $id=$current->{id};
#                   my $st={};
#                   $self->getParent->LoadTreeSPCheck($st,
#                                    "itil::businessservice",$id);
#                   return(
#                      dumpSpanSet({},
#                         'r'=>$st->{tree}->{entry}->{CorelSS}->{supportr},
#                         'k'=>$st->{tree}->{entry}->{CorelSS}->{supportk},
#                         'K'=>$st->{tree}->{entry}->{CorelSS}->{supportK},
#                         'R'=>$st->{tree}->{entry}->{CorelSS}->{supportR})
#                   );
#                }),
#
#
#      new kernel::Field::TimeSpans(
#                name          =>'serivceReq',
#                label         =>'requested service times',
#                htmldetail    =>0,
#                uploadable    =>0,
#                readonly      =>1,
#                searchable    =>0,
#                tspantype     =>['R','K'],
#                tspanlegend   =>1,
#                tspantypeproc =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $blk=shift;
#                   $blk->[4]="transparent";
#                   if ($blk->[2] eq "on"){
#                      $blk->[4]="blue";
#                      $blk->[4]="blue" if ($blk->[3] eq "K");
#                      $blk->[4]="yellow" if ($blk->[3] eq "R");
#                   }
#                   if ($blk->[2] eq "off"){
#                      $blk->[4]="red";
#                   }
#                },
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $id=$current->{id};
#                   my $st={};
#                   $self->getParent->LoadTreeSPCheck($st,
#                                    "itil::businessservice",$id);
#                   return(
#                      dumpSpanSet(
#                         {},
#                         'K',$st->{tree}->{entry}->{DirectSS}->{serivceK},
#                         'R',$st->{tree}->{entry}->{DirectSS}->{serivceR})
#                   );
#                }),


#      new kernel::Field::TimeSpans(
#                name          =>'serivceTreeCheck',
#                htmldetail    =>0,
#                uploadable    =>0,
#                readonly      =>1,
#                searchable    =>0,
#                label         =>'aggregated service times tree',
#                tspantype     =>{'k'=>'core replaced by border time',
#                                 ''=>'',
#                                 'r'=>'border replaced by core time',
#                                 'K'=>'continuous core time',
##                                 'R'=>'continuous border time'},
#                tspanlegend   =>1,
#                tspantypeproc =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $blk=shift;
#                   $blk->[4]="transparent";
#                   if ($blk->[2] eq "on" || $blk->[2] eq "legend"){
#                      $blk->[4]="blue";
#                      $blk->[4]="lightblue" if ($blk->[3] eq "k");
#                      $blk->[4]="lightyellow" if ($blk->[3] eq "r");
#                      $blk->[4]="yellow" if ($blk->[3] eq "R");
#                   }
#                   if ($blk->[2] eq "off" || $blk->[3] eq ""){
#                      $blk->[4]="red";
#                   }
#                },
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $id=$current->{id};
#                   my $st={};
#                   $self->getParent->LoadTreeSPCheck($st,
#                                    "itil::businessservice",$id);
#                   return(
#                      dumpSpanSet({},
#                         'r'=>$st->{tree}->{entry}->{CorelSS}->{serivcer},
#                         'k'=>$st->{tree}->{entry}->{CorelSS}->{serivcek},
#                         'K'=>$st->{tree}->{entry}->{CorelSS}->{serivceK},
#                         'R'=>$st->{tree}->{entry}->{CorelSS}->{serivceR})
#                   );
#                }),


      new kernel::Field::Text(
                name          =>'reportinglabel',
                label         =>'Reporting Label',
                vjointo       =>'itil::lnkmgmtitemgroup',
                group         =>'reporting',
                uploadable    =>0,
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'RLABEL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Textarea(
                name          =>'description',
                explore       =>10000,
                label         =>'Business Service Description',
                dataobjattr   =>"$worktable.description"),

#      new kernel::Field::Date(
#                name          =>'validfrom',
#                group         =>'desc',
#                label         =>'Duration Start',
#                dataobjattr   =>"$worktable.validfrom"),
#
#      new kernel::Field::Date(
#                name          =>'validto',
#                group         =>'desc',
#                label         =>'Duration End',
#                dataobjattr   =>"$worktable.validto"),
#
#      new kernel::Field::Select(
#                name          =>'reviewperiod',
#                group         =>'desc',
#                label         =>'Review-period',
#                transprefix   =>'REVIEW.',
#                value         =>['','WEEK','MONTH','QUARTER','YEAR'],
#                htmleditwidth =>'150px',
#                dataobjattr   =>$worktable.'.reviewperiod'),
#
#      new kernel::Field::Text(
#                name          =>'version',
#                group         =>'desc',
#                label         =>'Version',
#                htmleditwidth =>'80px',
#                dataobjattr   =>"$worktable.version"),
#
#      new kernel::Field::TextDrop(
#                name          =>'servicesupport',
#                label         =>'demanded Service&Support Class',
#                group         =>'desc',
#                vjointo       =>'itil::servicesupport',
#                vjoineditbase =>{'cistatusid'=>[3,4]},
#                vjoinon       =>['servicesupportid'=>'id'],
#                vjoindisp     =>'name'),
#
#      new kernel::Field::Link(
#                name          =>'servicesupportid',
#                group         =>'desc',
#                dataobjattr   =>"$worktable.servicesupport"),
#
#      new kernel::Field::TextDrop(
#                name          =>'implservicesupport',
#                label         =>'implemented Service&Support Class',
#                group         =>'desc',
#                vjointo       =>'itil::servicesupport',
#                vjoineditbase =>{'cistatusid'=>[3,4]},
#                vjoinon       =>['implservicesupportid'=>'id'],
#                vjoindisp     =>'name'),
#
#      new kernel::Field::TimeSpans(
#                name          =>'implserivcetimes',
#                label         =>'implemented service times',
#                group         =>'desc',
#                readonly      =>1,
#                htmldetail    =>0,
#                tspantypeproc =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $blk=shift;
#                   $blk->[4]="transparent";
#                   if ($blk->[2] eq "on"){
#                      $blk->[4]="blue";
#                      $blk->[4]="blue" if ($blk->[3] eq "k");
#                      $blk->[4]="yellow" if ($blk->[3] eq "r");
#                   }
#                   if ($blk->[2] eq "off"){
#                      $blk->[4]="red";
#                   }
#                },
#                vjointo       =>'itil::servicesupport',
#                vjoinon       =>['implservicesupportid'=>'id'],
#                vjoindisp     =>'serivce'),
#
#      new kernel::Field::TimeSpans(
#                name          =>'implsupporttimes',
#                label         =>'implemented support times',
#                group         =>'desc',
#                readonly      =>1,
#                htmldetail    =>0,
#                tspantypeproc =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#                   my $blk=shift;
#                   $blk->[4]="transparent";
#                   if ($blk->[2] eq "on"){
#                      $blk->[4]="blue";
#                      $blk->[4]="blue" if ($blk->[3] eq "k");
#                      $blk->[4]="yellow" if ($blk->[3] eq "r");
#                   }
#                   if ($blk->[2] eq "off"){
#                      $blk->[4]="red";
#                   }
#                },
#                vjointo       =>'itil::servicesupport',
#                vjoinon       =>['implservicesupportid'=>'id'],
#                vjoindisp     =>'support'),
#
#      new kernel::Field::Link(
#                name          =>'implservicesupportid',
#                group         =>'desc',
#                dataobjattr   =>"$worktable.implservicesupport"),
#
#
#      new kernel::Field::Duration(
#                name          =>'occreactiontime',
#                group         =>'desc',
#                visual        =>'hh:mm',
#                unit          =>'hh:mm',
#                label         =>'target occurrence reaction time',
#                align         =>'right',
#                searchable    =>0,
#                dataobjattr   =>$worktable.'.occreactiontime'),
#
#      new kernel::Field::Percent(
#                name          =>'occreactiontimelevel',
#                group         =>'desc',
#                label         =>'reaction time degree of attainment',
#                searchable    =>0,
#                precision     =>0,
#                dataobjattr   =>$worktable.'.occreactiontimelevel'),
#
#      new kernel::Field::Duration(
#                name          =>'occtotaltime',
#                group         =>'desc',
#                visual        =>'hh:mm',
#                unit          =>'hh:mm',
#                label         =>'target occurrence total treatment time',
#                align         =>'right',
#                searchable    =>0,
#                dataobjattr   =>$worktable.'.occtotaltime'),
#
#      new kernel::Field::Percent(
#                name          =>'occtotaltimelevel',
#                group         =>'desc',
#                label         =>'treatment time degree of attainment',
#                searchable    =>0,
#                precision     =>0,
#                dataobjattr   =>$worktable.'.occtotaltimelevel'),


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
                dataobjattr   =>$worktable.'.additional'),

      new kernel::Field::SubList(
                name          =>'upperservice',
                label         =>'upper service',
                group         =>'uservicecomp',
                htmldetail    =>'NotEmpty',
                depend        =>['allparentids','id'],
                searchable    =>0,
                vjointo       =>'itil::businessservice',
                vjoinon       =>['allparentids'=>'id'],
                vjoindisp     =>['fullname'],
                vjoininhash   =>['id','fullname']),

      new kernel::Field::Interface(
                name          =>'allparentids',
                label         =>'all parent business service ids',
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                selectfix     =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my @p;
                   if (defined($current) && $current->{id} ne ""){
                      my $id=$current->{id};
                      my @curid=($id);
                      do{
                         my $op=$app->getPersistentModuleObject("parrentLoop",
                                "itil::lnkbscomp");
                         $op->SetFilter({objtype=>\'itil::businessservice',
                                         obj1id=>\@curid});
                         my @l=$op->getHashList(qw(businessserviceid));
                         @curid=();
                         foreach my $toprec (@l){
                            if ($toprec->{businessserviceid} ne "" &&
                                !in_array(\@p,$toprec->{businessserviceid})){
                               push(@curid,$toprec->{businessserviceid});
                               push(@p,$toprec->{businessserviceid});
                            }
                         }
                      }while($#curid!=-1);
                   }
                   return(undef) if ($#p==-1);
                   return(\@p);
                }),


      new kernel::Field::SubList(
                name          =>'servicecomp',
                label         =>'service components',
                group         =>'servicecomp',
                searchable    =>0,
                subeditmsk    =>'subedit.businessservice',
                vjointo       =>'itil::lnkbscomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['sortkey','name',"xcomments"],
                vjoininhash   =>['sortkey','variant','lnkpos','id','objtype',
                                 'obj1id','comments']),

      new kernel::Field::SubList(
                name          =>'servicecompappl',
                label         =>'full related application components',
                htmldetail    =>0,
                group         =>'servicecomp',
                vjointo       =>'itil::lnkbsappl',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Link(
                name          =>'servicecompapplid',
                label         =>'full related application components ids',
                group         =>'servicecomp',
                vjointo       =>'itil::lnkbsappl',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['applid']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::businessservice'}],
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'businessprocesses',
                label         =>'involved in Businessprocesses',
                group         =>'businessprocesses',
                htmldetail    =>'NotEmpty',
                vjointo       =>'itil::lnkbprocessbservice',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['businessprocess','customer']),

      new kernel::Field::SubList(
                name          =>'grprelations',
                label         =>'Organisation Relations',
                group         =>'grprelations',
                vjointo       =>'itil::lnkbusinessservicegrp',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['grp'],
                vjoininhash   =>['grpid','grp','comments','id']),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'applbusinessteam'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'applresponseteam'),



#      new kernel::Field::MatrixHeader(
#                name          =>'slamatrix',
#                group         =>'sla',
#                label         =>[undef,
#                                 'requested',
#                                 'current',
#                                 'implemented',
#                         #        'threshold fact. warn',
#                         #        'threshold warn',
#                         #        'threshold fact. crit',
#                         #        'threshold crit'
#                                 ]),
#
#      new kernel::Field::Duration(
#                name          =>'requ_mtbf',
#                group         =>'sla',
#                visual        =>'hh:mm',
#                label         =>'MTBF in h',
#                align         =>'right',
#                searchable    =>0,
#                extLabelPostfix=>\&extLabelPostfixRequested,
#                dataobjattr   =>$worktable.'.requ_mtbf'),
#
#      new kernel::Field::Duration(
#                name          =>'curr_mtbf',
#                group         =>'sla',
#                visual        =>'hh:mm',
#                searchable    =>0,
#                label         =>'MTBF in h',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixCurrent,
#                dataobjattr   =>$worktable.'.curr_mtbf'),

#      new kernel::Field::Duration(
#                name          =>'impl_mtbf',
#                group         =>'sla',
#                visual        =>'hh:mm',
#                searchable    =>0,
#                label         =>'MTBF in h',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixImplemented,
#                dataobjattr   =>$worktable.'.impl_mtbf'),
#
#      #new kernel::Field::Number(
#      #          name          =>'threshold_fact_warn_mtbf',
#      #          group         =>'sla',
#      #          default       =>sub{
#      #             my $self=shift;
#      #             my $current=shift;
#      #             my $mode=shift;
#      #
#      #            return(undef) if ($mode eq "edit");
#      #            return('0.97')
#      #         },
#      #         background    =>\&calcBackgroundFlagColor,
#      #         editrange     =>[0.01,5.0],
#      #         precision     =>2, 
#      #         label         =>'MTBF',
#      #         align         =>'right',
#      #         extLabelPostfix=>\&extLabelPostfixTHfactWarn,
#      #         dataobjattr   =>$worktable.'.th_warn_mtbf'),
#
#      #new kernel::Field::Duration(
#      #         name          =>'threshold_warn_mtbf',
#      #         group         =>'sla',
#      #         background    =>\&calcBackgroundFlagColor,
#      #         precision     =>2, 
#      #         visual        =>'hh:mm',
#      #         readonly      =>1,
#      #         label         =>'MTBF',
#      #         align         =>'right',
#      #         extLabelPostfix=>\&extLabelPostfixTHWarn,
#      #         dataobjattr   =>"$worktable.impl_mtbf*".
#      #                         "if ($worktable.th_warn_mtbf is null,0.97,".
#      #                         "$worktable.th_warn_mtbf)"),
#
#      #new kernel::Field::Number(
#      #         name          =>'threshold_fact_crit_mtbf',
#      #         group         =>'sla',
#      #         default       =>sub{
#      #            my $self=shift;
#      #            my $current=shift;
#      #            my $mode=shift;
#      #
#      #            return(undef) if ($mode eq "edit");
#      #            return('0.92')
#      #         },
#      #         background    =>\&calcBackgroundFlagColor,
#      #         editrange     =>[0.01,5.0],
#      #         precision     =>2,
#      #         label         =>'MTBF',
#      #         align         =>'right',
#      #         extLabelPostfix=>\&extLabelPostfixTHfactCrit,
#      #         dataobjattr   =>$worktable.'.th_crit_mtbf'),
#
#
#
#      #new kernel::Field::Duration(
#      #         name          =>'threshold_crit_mtbf',
#      #         group         =>'sla',
#      #         background    =>\&calcBackgroundFlagColor,
#      #         depend        =>['threshold_crit_mtbf'],
#      #         precision     =>2, 
#      #         readonly      =>1,
#      #         visual        =>'hh:mm',
#      #         label         =>'MTBF',
#      #         align         =>'right',
#      #         extLabelPostfix=>\&extLabelPostfixTHCrit,
#      #         dataobjattr   =>"$worktable.impl_mtbf*".
#      #                         "if ($worktable.th_crit_mtbf is null,0.92,".
#      #                         "$worktable.th_crit_mtbf)"),
#
#      new kernel::Field::Duration(
#                name          =>'requ_ttr',
#                group         =>'sla',
#                visual        =>'hh:mm',
#                searchable    =>0,
#                label         =>'TTR in h',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixRequested,
#                dataobjattr   =>$worktable.'.requ_ttr'),
#
#      new kernel::Field::Duration(
#                name          =>'curr_ttr',
#                group         =>'sla',
#                visual        =>'hh:mm',
#                searchable    =>0,
#                label         =>'TTR in h',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixCurrent,
#                dataobjattr   =>$worktable.'.curr_ttr'),
#
#      new kernel::Field::Duration(
#                name          =>'impl_ttr',
#                group         =>'sla',
#                visual        =>'hh:mm',
#                searchable    =>0,
#                label         =>'TTR in h',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixImplemented,
#                dataobjattr   =>$worktable.'.impl_ttr'),
#
#      #new kernel::Field::Number(
#      #         name          =>'threshold_fact_warn_ttr',
#      #         group         =>'sla',
#      #         default       =>sub{
#      #            my $self=shift;
#      #            my $current=shift;
#      #            my $mode=shift;
#      #
#      #            return(undef) if ($mode eq "edit");
#      #            return('0.97')
#      #         },
#      #         background    =>\&calcBackgroundFlagColor,
#      #         editrange     =>[0.01,5.0],
#      #         precision     =>2, 
#      #         label         =>'TTR',
#      #         align         =>'right',
#      #         extLabelPostfix=>\&extLabelPostfixTHfactWarn,
#      #         dataobjattr   =>$worktable.'.th_warn_ttr'),
#
#      #new kernel::Field::Duration(
#      #         name          =>'threshold_warn_ttr',
#      #         group         =>'sla',
#      #         background    =>\&calcBackgroundFlagColor,
#      #         depend        =>['threshold_fact_warn_ttr'],
#      #         readonly      =>1,
#      #         visual        =>'hh:mm',
#      #         label         =>'TTR',
#      #         align         =>'right',
#      #         extLabelPostfix=>\&extLabelPostfixTHWarn,
#      #         dataobjattr   =>"$worktable.impl_ttr*".
#      #                         "if ($worktable.th_warn_ttr is null,0.97,".
#      #                         "$worktable.th_warn_ttr)"),

      #new kernel::Field::Number(
      #         name          =>'threshold_fact_crit_ttr',
      #         group         =>'sla',
      #         default       =>sub{
      #            my $self=shift;
      #            my $current=shift;
      #            my $mode=shift;
      #
      #            return(undef) if ($mode eq "edit");
      #            return('0.92')
      #         },
      #         background    =>\&calcBackgroundFlagColor,
      #         editrange     =>[0.01,5.0],
      #         precision     =>2, 
      #         label         =>'TTR',
      #         align         =>'right',
      #         extLabelPostfix=>\&extLabelPostfixTHfactCrit,
      #         dataobjattr   =>$worktable.'.th_crit_ttr'),

      #new kernel::Field::Duration(
      #         name          =>'threshold_crit_ttr',
      #         group         =>'sla',
      #         background    =>\&calcBackgroundFlagColor,
      #         readonly      =>1,
      #         visual        =>'hh:mm',
      #         label         =>'TTR',
      #         align         =>'right',
      #         extLabelPostfix=>\&extLabelPostfixTHCrit,
      #         dataobjattr   =>"$worktable.impl_ttr*".
      #                         "if ($worktable.th_crit_ttr is null,0.92,".
      #                         "$worktable.th_crit_ttr)"),

#      new kernel::Field::MatrixHeader(
#                name          =>'monimatrix',
#                group         =>'moni',
#                label         =>[undef,
#                                 'requested',
#                                 'current',
#                                 'implemented',
#                                 'threshold fact. warn',
#                                 'threshold warn',
#                                 'threshold fact. crit',
#                                 'threshold crit'
#                                ]),
#
#      new kernel::Field::Percent(
#                name          =>'requ_avail_p',
#                precision     =>2,
#                group         =>'moni',
#                searchable    =>0,
#                label         =>'avalability in %',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixRequested,
#                dataobjattr   =>$worktable.'.requ_avail_p'),
#
#      new kernel::Field::Percent(
#                name          =>'curr_avail_p',
#                precision     =>2,
#                group         =>'moni',
#                searchable    =>0,
#                label         =>'avalability in %',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixCurrent,
#                dataobjattr   =>$worktable.'.curr_avail_p'),
#
#      new kernel::Field::Percent(
#                name          =>'impl_avail_p',
#                precision     =>2,
#                group         =>'moni',
#                searchable    =>0,
#                label         =>'avalability in %',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixImplemented,
#                dataobjattr   =>$worktable.'.impl_avail_p'),

#      new kernel::Field::Number(
#                name          =>'threshold_fact_warn_avail',
#                group         =>'moni',
#                precision     =>2, 
#                default       =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#
#                   return(undef) if ($mode eq "edit");
#                   return('0.97')
#                },
#                background    =>\&calcBackgroundFlagColor,
#                editrange     =>[0.01,5.0],
#                label         =>'avalability',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHfactWarn,
#                dataobjattr   =>$worktable.'.th_warn_avail'),

#      new kernel::Field::Percent(
#                name          =>'threshold_warn_avail',
#                group         =>'moni',
#                depend        =>['threshold_fact_warn_avail'],
#                precision     =>2, 
#                readonly      =>1,
#                background    =>\&calcBackgroundFlagColor,
#                label         =>'avalability',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHWarn,
#                dataobjattr   =>"$worktable.impl_avail_p*".
#                                "if ($worktable.th_warn_avail is null,0.97,".
#                                "$worktable.th_warn_avail)"),

#      new kernel::Field::Number(
#                name          =>'threshold_fact_crit_avail',
#                group         =>'moni',
#                precision     =>2, 
#                default       =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#
#                   return(undef) if ($mode eq "edit");
#                   return('0.92')
#                },
#                background    =>\&calcBackgroundFlagColor,
#                editrange     =>[0.01,5.0],
#                label         =>'avalability',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHfactCrit,
#                dataobjattr   =>$worktable.'.th_crit_avail'),

#      new kernel::Field::Percent(
#                name          =>'threshold_crit_avail',
#                group         =>'moni',
#                precision     =>2, 
#                background    =>\&calcBackgroundFlagColor,
#                depend        =>['threshold_fact_crit_avail'],
#                readonly      =>1,
#                label         =>'avalability',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHCrit,
#                dataobjattr   =>"$worktable.impl_avail_p*".
#                                "if ($worktable.th_crit_avail is null,0.92,".
#                                "$worktable.th_crit_avail)"),

#      new kernel::Field::Number(
#                name          =>'requ_respti',
#                group         =>'moni',
#                label         =>'responsetime in ms',
#                unit          =>'ms',
#                align         =>'right',
#                searchable    =>0,
#                extLabelPostfix=>\&extLabelPostfixRequested,
#                dataobjattr   =>$worktable.'.requ_respti'),

#      new kernel::Field::Number(
#                name          =>'curr_respti',
#                group         =>'moni',
#                label         =>'responsetime in ms',
#                unit          =>'ms',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixCurrent,
#                dataobjattr   =>$worktable.'.curr_respti'),

#      new kernel::Field::Number(
#                name          =>'impl_respti',
#                group         =>'moni',
#                searchable    =>0,
#                label         =>'responsetime in ms',
#                unit          =>'ms',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixImplemented,
#                dataobjattr   =>$worktable.'.impl_respti'),

#      new kernel::Field::Number(
#                name          =>'threshold_fact_warn_respti',
#                group         =>'moni',
#                default       =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#
#                   return(undef) if ($mode eq "edit");
#                   return('1.50')
#                },
#                background    =>\&calcBackgroundFlagColor,
#                precision     =>2, 
#                editrange     =>[0.01,5.0],
#                label         =>'responsetime',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHfactWarn,
#                dataobjattr   =>$worktable.'.th_warn_respti'),

#      new kernel::Field::Number(
#                name          =>'threshold_warn_respti',
#                group         =>'moni',
#                background    =>\&calcBackgroundFlagColor,
#                depend        =>['threshold_fact_warn_respti'],
#                unit          =>'ms',
#                readonly      =>1,
#                label         =>'responsetime',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHWarn,
#                dataobjattr   =>"$worktable.impl_respti*".
#                                "if ($worktable.th_warn_respti is null,1.50,".
#                                "$worktable.th_warn_respti)"),

#      new kernel::Field::Number(
#                name          =>'threshold_fact_crit_respti',
#                group         =>'moni',
#                default       =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $mode=shift;
#
#                   return(undef) if ($mode eq "edit");
#                   return('1.80')
#                },
#                background    =>\&calcBackgroundFlagColor,
#                editrange     =>[0.01,5.0],
#                precision     =>2, 
#                label         =>'responsetime',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHfactCrit,
#                dataobjattr   =>$worktable.'.th_crit_respti'),

#      new kernel::Field::Number(
#                name          =>'threshold_crit_respti',
#                group         =>'moni',
#                background    =>\&calcBackgroundFlagColor,
#                label         =>'responsetime',
#                depend        =>['threshold_fact_crit_respti'],
#                unit          =>'ms',
#                readonly      =>1,
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHCrit,
#                dataobjattr   =>"$worktable.impl_respti*".
#                                "if ($worktable.th_crit_respti is null,1.80,".
#                                "$worktable.th_crit_respti)"),

#      new kernel::Field::Percent(
#                name          =>'requ_perf',
#                group         =>'moni',
#                label         =>'performance in %',
#                align         =>'right',
#                default       =>'95',
#                searchable    =>0,
#                extLabelPostfix=>\&extLabelPostfixRequested,
#                dataobjattr   =>$worktable.'.requ_perf'),

#      new kernel::Field::Percent(
#                name          =>'curr_perf',
#                group         =>'moni',
#                default       =>'95',
#                label         =>'performance in %',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixCurrent,
#                dataobjattr   =>$worktable.'.curr_perf'),

#      new kernel::Field::Percent(
#                name          =>'impl_perf',
#                group         =>'moni',
#                searchable    =>0,
#                readonly      =>1,
#                label         =>'performance in %',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixImplemented,
#                dataobjattr   =>$worktable.'.impl_perf'),

#      new kernel::Field::Number(
#                name          =>'threshold_fact_warn_perf',
#                group         =>'moni',
#                readonly      =>1,
#                background    =>\&calcBackgroundFlagColor,
#                editrange     =>[0.01,5.0],
#                precision     =>2, 
#                label         =>'performance',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHfactWarn,
#                dataobjattr   =>$worktable.'.th_warn_perf'),

#      new kernel::Field::Number(
#                name          =>'threshold_warn_perf',
#                group         =>'moni',
#                readonly      =>1,
#                background    =>\&calcBackgroundFlagColor,
#                depend        =>['threshold_fact_warn_perf'],
#                precision     =>2, 
#                label         =>'performance',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHWarn,
#                dataobjattr   =>"NULL"),

#      new kernel::Field::Number(
#                name          =>'threshold_fact_crit_perf',
#                group         =>'moni',
#                readonly      =>1,
#                background    =>\&calcBackgroundFlagColor,
#                editrange     =>[0.01,5.0],
#                precision     =>2, 
#                label         =>'performance',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHfactCrit,
#                dataobjattr   =>$worktable.'.th_crit_perf'),
#
#      new kernel::Field::Number(
#                name          =>'threshold_crit_perf',
#                group         =>'moni',
#                readonly      =>1,
#                depend        =>['threshold_fact_crit_perf'],
#                background    =>\&calcBackgroundFlagColor,
#                precision     =>2, 
#                label         =>'performance',
#                align         =>'right',
#                extLabelPostfix=>\&extLabelPostfixTHCrit,
#                dataobjattr   =>"NULL"),

#      new kernel::Field::Textarea(
#                name          =>'slacomments',
#                group         =>'monicomments',
#                label         =>'comments for alternate thresholds',
#                dataobjattr   =>$worktable.'.slacomments'),

#      new kernel::Field::Number(
#                name          =>'reproacht',
#                group         =>'reporting',
#                label         =>'reproach-time',
#                unit          =>'days',
#                align         =>'right',
#                dataobjattr   =>$worktable.'.reproacht'),

#      new kernel::Field::Select(
#                name          =>'durationtoav',
#                group         =>'reporting',
#                label         =>'Duration to availability',
#                value         =>['','24:00'],
#                htmleditwidth =>'90px',
#                dataobjattr   =>$worktable.'.durationtoav'),

#      new kernel::Field::Select(
#                name          =>'repoperiod',
#                group         =>'reporting',
#                label         =>'Reporting-period',
#                value         =>['','24:00'],
#                htmleditwidth =>'90px',
#                dataobjattr   =>$worktable.'.repoperiod'),
#
#      new kernel::Field::Duration(
#                name          =>'mperiod',
#                group         =>'reporting',
#                label         =>'Measure-period',
#                visual        =>'hh:mm',
#                dataobjattr   =>$worktable.'.mperiod'),
#
#      new kernel::Field::Textarea(
#                name          =>'commentsrm',
#                group         =>'reporting',
#                label         =>'Remarks on measurement procedures and reporting',
#                dataobjattr   =>$worktable.'.commentsrm'),
#
#      new kernel::Field::Textarea(
#                name          =>'commentsperf',
#                group         =>'reporting',
#                label         =>'Performance-description',
#                dataobjattr   =>$worktable.'.commentsperf'),


      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::businessservice',
                group         =>'attachments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>$worktable.'.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>$worktable.'.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>$worktable.'.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad($worktable.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>"$worktable.createdate"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>"$worktable.createuser"),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>"$worktable.realeditor"),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>"$worktable.lastqcheck"),
      new kernel::Field::QualityResponseArea(),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontacttarget'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontacttargetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontactcroles'),

   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(fullname cistatus application));
   return($self);
}


sub getOnChangedScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var s=document.forms[0].elements['Formated_nature'];
var dboss=document.forms[0].elements['Formated_databoss'];
var appl=document.forms[0].elements['Formated_srcapplication'];

if (s && dboss && appl ){
   var v=s.options[s.selectedIndex].value;
   if (v==""){
      appl.disabled=false;
   }
   else{
      appl.disabled=true;
   }
   if (v=="SVC" || v=='PRC' || v=='BC'){
      dboss.disabled=false;
   }
   else{
      dboss.disabled=true;
   }
}

EOF
   return($d);
}






sub jsExploreFormatLabelMethod
{
   my $self=shift;
   my $d=<<EOF;
//newlabel=newlabel.replaceAll(':',':\\n');
newlabel=wrapText(newlabel,20);
newlabel=newlabel.replaceAll(':',':\\n');
EOF
   return($d);
}



#sub calcBackgroundFlagColor
#{
#   my $self=shift;
#   my $FormatAs=shift;
#   my $current=shift;
#
#   my $depname=$self->Name();
#   if (!($depname=~m/^threshold_fact_/)){
#      $depname=~s/^threshold_/threshold_fact_/;
#   }  
#   my $depfield=$self->getParent->getField($depname,$current);
#
#   my $def=$depfield->default($FormatAs);
#
#   my $cur=$depfield->RawValue($current);
#
#   $cur=$def if ($cur eq "");
#
#   # korrektur der Färbungen (mittlerweilen sehr komplex) Requ:
#   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14127566190001
#
#   if ($depname eq "threshold_fact_warn_mtbf" ||
#       $depname eq "threshold_fact_warn_ttr"  ||
#       $depname eq "threshold_fact_warn_avail"){
#      if ($cur>=0.92 && $cur<0.97){
#         return("yellow");
#      }
#      elsif($cur<0.92){
#         return("red");
#      }
#      elsif($cur>1.00){
#         return("red");
#      }
#   }
#   elsif ($depname eq "threshold_fact_crit_mtbf" ||
#          $depname eq "threshold_fact_crit_ttr"  ||
#          $depname eq "threshold_fact_crit_avail"){
#      if($cur<0.92){
#         return("red");
#      }
#      elsif($cur>1.00){
#         return("red");
#      }
#   }
#   elsif ($depname eq "threshold_fact_warn_respti"){
#      if ($cur>1.50 && $cur<=1.80){
#         return("yellow");
#      }
#      elsif($cur<1.00){
#         return("red");
#      }
#      elsif($cur>1.80){
#         return("red");
#      }
#   }
#   elsif ($depname eq "threshold_fact_crit_respti"){
#      if($cur<1.00){
#         return("red");
#      }
#      elsif($cur>1.80){
#         return("red");
#      }
#   }
#   else{
#      my $delta=abs($def-$cur);
#      if ($delta>0 && $def>0){
#         my $p=(100*$delta)/$def;
#         if ($p>10){
#            return("red");
#         }elsif ($p>5){
#            return("yellow");
#         }
#      }
#   }
#   return("");
#}


#sub LoadTreeSPCheck
#{
#   my $self=shift;
#   my $st=shift;
#   my $dataobj=shift;
#   my $id=shift;
#   my $p=shift;
#
#   $st->{tree}={} if (!defined($st->{tree}));
#
#   $p=$st->{tree} if (!defined($p));
#   $p->{level}=0  if (!exists($p->{level}));
#
#   #######################################################################
#   # root record laden
#   #######################################################################
#
#   my $o=$self->getPersistentModuleObject("TreeBproc".$dataobj,$dataobj);
#
#   $o->SetFilter({id=>\$id});
#   my ($r)=$o->getOnlyFirst(qw(servicesupportid name));
#
#   my $entry="${dataobj}::${id}";
#   $st->{entry}->{$entry}={name=>$r->{name}};
#   if ($r->{servicesupportid} ne ""){
#      my $sspid=$r->{servicesupportid};
#      if (!exists($st->{servicesupport}->{$sspid})){
#         $st->{servicesupport}->{$sspid}={};
#      }
#      $st->{entry}->{$entry}->{servicesupport}=
#                $st->{servicesupport}->{$sspid};
#   }
#   $p->{entry}=$st->{entry}->{$entry};
#   #$p->{entry}=$entry;
#
#   #######################################################################
#   # subtree recursive load 
#   #######################################################################
#   foreach my $srec (@{$r->{servicecomp}}){
#       if ($srec->{objtype} eq "itil::businessservice" ||
#           $srec->{objtype} eq "itil::appl"){
#          $p->{child}=[] if (!defined($p->{child}));
#          my @crec={level=>$p->{level}+1};
#          push(@{$p->{child}},\@crec);
#          $self->LoadTreeSPCheck($st,$srec->{objtype},$srec->{obj1id},
#                                 $p->{child}->[$#{$p->{child}}]->[0]);
#          if ($srec->{obj2id} ne ""){
#             push(@crec,{level=>$p->{level}+1});
#             $self->LoadTreeSPCheck($st,$srec->{objtype},$srec->{obj2id},
#                                    $p->{child}->[$#{$p->{child}}]->[1]);
#          }
#          if ($srec->{obj3id} ne ""){
#             push(@crec,{level=>$p->{level}+1});
#             $self->LoadTreeSPCheck($st,$srec->{objtype},$srec->{obj3id},
#                                    $p->{child}->[$#{$p->{child}}]->[2]);
#          }
#       }
#   }
#   #######################################################################
#   # generate service support datastructure
#   #######################################################################
#   if ($p->{level}==0){ # load details of Service&Support Clases
#      my @sspid=keys(%{$st->{servicesupport}});
#      my $dataobj="itil::servicesupport"; 
#      my $o=$self->getPersistentModuleObject("TreeBproc".$dataobj,$dataobj);
#      $o->SetFilter({id=>\@sspid});
#      foreach my $srec ($o->getHashList(qw(serivce
#                                           support name))){
#         $st->{servicesupport}->{$srec->{id}}->{serivceestring}=
#              $srec->{serivce};
#         $st->{servicesupport}->{$srec->{id}}->{supportstring}=
#              $srec->{support};
#         $st->{servicesupport}->{$srec->{id}}->{name}=
#              $srec->{name};
#         foreach my $t (qw(serivce support)){
#            my @fval=();
#            foreach my $blk (split(/\+/,$srec->{$t})){
#               if (my ($n,$d)=$blk=~m/^(\d+)\((.*)\)$/){
#                  foreach my $seg (split(/,/,$d)){
#                     if (my ($label,$starth,$startm,$endh,$endm)=$seg=~
#                         m/^\s*([a-z]{0,1})(\d+):(\d+)-(\d+):(\d+)\s*$/i){
#                        $label="K" if ($label eq "");
#                        push(@{$fval[$n]},{
#                           label=>$label,
#                           starth=>int($starth),startm=>int($startm),
#                           endh=>int($endh),endm=>int($endm)
#                        });
#                     }
#                  }
#               }
#            }
#            $st->{servicesupport}->{$srec->{id}}->{"${t}struct"}=\@fval;
#         }
#      }
#      $self->ServiceTreeCorelation($st);
#   }
#}


#sub ServiceTreeCorelation
#{
#   my $self=shift;
#   my $st=shift;
#   my $p=shift;
#
#   $p=$st->{tree} if (!defined($p));
#
#   my @dsets=(
#      "serivceK",   # ServiceZeit Fragmente Kernzeit
#      "serivceR",   # ServiceZeit Fragmente Randzeit
#      "supportK",   # SupportZeit Fragmente Kernzeit
#      "supportR"    # SupportZeit Fragmente Randzeit
#   );
#   my @allsets=(
#      @dsets,       # alle direkt ermittelbaren Sets
#      "supportk",  # Kernzeit muß Randzeit ersetzen
#      "supportr",  # Randzeit muß Kernzeit ersetzen
#      "serivcek",  # Kernzeit muß Randzeit ersetzen
#      "serivcer",  # Randzeit muß Kernzeit ersetzen
#   );
#   my %DirectSS;
#   map({$DirectSS{$_}=createSpanSet()} @dsets);
#   if (exists($p->{entry}->{servicesupport})){
#      $DirectSS{'serivceK'}=
#         createSpanSet('K','serivce',$p->{entry}->{servicesupport});
#      $DirectSS{'serivceR'}=
#         createSpanSet('R','serivce',$p->{entry}->{servicesupport});
#      $DirectSS{'supportK'}=
#         createSpanSet('K','support',$p->{entry}->{servicesupport});
#      $DirectSS{'supportR'}=
#         createSpanSet('R','support',$p->{entry}->{servicesupport});
#   }
#   $p->{entry}->{DirectSS}=\%DirectSS;
#
#   my %CorelSS;
#   map({$CorelSS{$_}=createSpanSet()} @allsets);
#
#   foreach my $set (@dsets){ # negation
#      $CorelSS{$set}=$CorelSS{$set}->complement();
#   }
#   
#
#  # $CorelSS{supportKR}=$CorelSS{supportKR}->union($CorelSS{supportK});
#  # $CorelSS{supportKR}=$CorelSS{supportKR}->union($CorelSS{supportR});
#  # $CorelSS{serivceKR}=$CorelSS{serivceKR}->union($CorelSS{serivceK});
#  # $CorelSS{serivceKR}=$CorelSS{serivceKR}->union($CorelSS{serivceR});
#
#   if (exists($p->{child})){
#      foreach my $c (@{$p->{child}}){
#         my %cs;
#         map({$cs{$_}=createSpanSet()} @allsets);
#         # aller redundanzen müssen serive und Support Zeiten maessig
#         # Oder verknüpft werden
#         foreach my $altc (@$c){  # alternativen durchgehen und corelieren
#            if (!exists($altc->{CorelSS})){
#               $self->ServiceTreeCorelation($st,$altc);
#            }
#            foreach my $set (@dsets){
#               $cs{$set}=$cs{$set}->union($altc->{entry}->{CorelSS}->{$set});
#            }
#            $CorelSS{supportr}=$CorelSS{supportr}->union(
#                                   $altc->{entry}->{CorelSS}->{supportr});
#            $CorelSS{supportr}=$CorelSS{supportr}->union(
#                                   $altc->{entry}->{CorelSS}->{supportk});
#
#            $CorelSS{supportk}=$CorelSS{supportk}->union(
#                                   $altc->{entry}->{CorelSS}->{supportk});
#
#            $CorelSS{supportk}=$CorelSS{supportk}->union(
#                                   $altc->{entry}->{CorelSS}->{supportr});
#
#            $CorelSS{serivcer}=$CorelSS{serivcer}->union(
#                                   $altc->{entry}->{CorelSS}->{serivcer});
#            $CorelSS{serivcer}=$CorelSS{serivcer}->union(
#                                   $altc->{entry}->{CorelSS}->{serivcek});
#
#            $CorelSS{serivcek}=$CorelSS{serivcek}->union(
#                                   $altc->{entry}->{CorelSS}->{serivcek});
#            $CorelSS{serivcek}=$CorelSS{serivcek}->union(
#                                   $altc->{entry}->{CorelSS}->{serivcer});
#         }
#         $CorelSS{supportr}=$CorelSS{supportr}->union($cs{supportK});
#         $CorelSS{supportk}=$CorelSS{supportk}->union($cs{supportR});
#         $CorelSS{serivcer}=$CorelSS{serivcer}->union($cs{serivceK});
#         $CorelSS{serivcek}=$CorelSS{serivcek}->union($cs{serivceR});
#
#
#         # jedes Child ergebnis per AND Operation an das CorelSS hinzufügen
#         foreach my $set (@dsets){
#            $CorelSS{$set}=$CorelSS{$set}->intersection($cs{$set});
#         }
#      }
#   }
#
#   $CorelSS{supportr}=$CorelSS{supportr}->intersection($DirectSS{supportR});
#   $CorelSS{supportk}=$CorelSS{supportk}->intersection($DirectSS{supportK});
#   $CorelSS{serivcer}=$CorelSS{serivcer}->intersection($DirectSS{serivceR});
#   $CorelSS{serivcek}=$CorelSS{serivcek}->intersection($DirectSS{serivceK});
#
#
#
#   foreach my $set (@dsets){ # join DirectSS as base for CorelSS
#      $CorelSS{$set}=$CorelSS{$set}->intersection($DirectSS{$set});
#   }
#
#   $p->{entry}->{CorelSS}=\%CorelSS;
#}

#sub createSpanSet
#{
#   my $type=shift;       # K|R
#   my $block=shift;     
#   my $ssentry=shift;    # service support entry
#
#   my $spanset= DateTime::SpanSet->from_spans( spans => []);
#   return($spanset) if (!defined($type));
#
#   if (exists($ssentry->{$block."struct"})){
#      #print STDERR "X($block):\n";
#      my $e=$ssentry->{$block."struct"};
#      for(my $t=0;$t<=7;$t++){
#         foreach my $tspanrec (@{$e->[$t]}){
#            if ($type eq $tspanrec->{label} ||
#                ($type eq "K" && exists($tspanrec->{label}) &&
#                 $tspanrec->{label} eq "")){
#               my $needsubstract1=1;
#               my $starth=$tspanrec->{starth}; 
#               my $startm=$tspanrec->{startm}; 
#               my $endh=$tspanrec->{endh}; 
#               my $endm=$tspanrec->{endm}; 
#               if ($endh==24 && $endm==0){
#                  $needsubstract1=0;
#                  $endh=23;
#                  $endm=59;
#               }
#               my $start=new DateTime( year=>1999,
#                                       month=>1,
#                                       day=>$t+1,
#                                       hour=>$starth,
#                                       minute=>$startm);
#               my $end  =new DateTime( year=>1999,
#                                       month=>1,
#                                       day=>$t+1,
#                                       hour=>$endh,
#                                       minute=>$endm);
#               if ($needsubstract1){ # 24:00 -> 23:59 mapping
#                  $end->subtract_duration(
#                     new DateTime::Duration(
#                        minutes=>1
#                     )
#                  );
#               }
#               my $span=DateTime::Span->from_datetimes(
#                  start=>$start,
#                  end=>$end
#               );
#               $spanset=$spanset->union($span);
#            }
#         }
#      }
#   }
#   return($spanset);
#}
#
#sub dumpSpanSet
#{
#   my $param=shift;
#   my @p=@_;
#
#   my @week;
#   while(my $tt=shift(@p)){
#      my $s=shift(@p);
#      if (defined($s)){
#         for(my $t=0;$t<=7;$t++){
#            $week[$t]=[] if (!defined($week[$t]));
#            my $t1=DateTime->new(year=>1999,month=>1,day=>$t+1,
#                                 hour=>0,minute=>0,second=>0);
#            my $t2=DateTime->new(year=>1999,month=>1,day=>$t+1,
#                                 hour=>23,minute=>59,second=>59);
#            my $dayspan=DateTime::Span->from_datetimes(start=>$t1,end=>$t2);
#            my $day=$s->intersection($dayspan);
#            my $i=$day->iterator();
#            my @day;
#            while (my $dt=$i->next()){
#               my $start=$dt->start();
#               my $end=$dt->end();
#               $end->add_duration(
#                  new DateTime::Duration(
#                     minutes=>1
#                  )
#               );
#               my $endh=$end->hour();
#               my $endm=$end->minute();
#               if ($endh==0 && $endm==0){
#                  $endh=24;
#               }
#               push(@{$week[$t]},sprintf("%s%02d:%02d-%02d:%02d",$tt,
#                                 $start->hour(),$start->minute(),
#                                 $endh,$endm));
#            }
#         }
#      }
#   }
#   my @st;
#   for(my $t=0;$t<=7;$t++){
#     my $w=$week[$t];
#     $w=[] if (!defined($w));
#     $st[$t]=$t."(".join(",",@$w).")";
#   }
#   return(join("+",@st));
#}





#sub extLabelPostfixRequested
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("requested"));
#}
#
#sub extLabelPostfixImplemented
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("implemented"));
#}
#
#sub extLabelPostfixCurrent
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("current"));
#}
#
#sub extLabelPostfixTHCrit
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("threshold crit"));
#}
#
#sub extLabelPostfixTHWarn
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("threshold warn"));
#}
#
#
#sub extLabelPostfixTHfactCrit
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("threshold fact. crit"));
#}
#
#sub extLabelPostfixTHfactWarn
#{
#   my $self=shift;
#   return(" - ".$self->getParent->T("threshold fact. warn"));
#}




sub getBSfullnameSQL
{
   my $worktable=shift;
   my $applname=shift;

   my $d="concat(".
         "if ($worktable.nature is null ".
         "or $worktable.nature='','',concat($worktable.nature,".
         "if ($worktable.shortname is null or $worktable.shortname='','',':'),".
         "if ($worktable.shortname is null or ".
         "$worktable.shortname='',':',concat($worktable.shortname,':')))),".
         "if ($applname is null,'',".
         "concat($applname,if ($worktable.shortname is null or ".
         "$worktable.shortname='',':',".
         "concat(':',$worktable.shortname,':')))),".
         "$worktable.name)";

   return($d);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default applinfo desc  uservicecomp servicecomp
             contacts businessprocesses grprelations
             reporting sla moni monicomments 
             attachments source));
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::businessservice");
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



#sub preProcessReadedRecord
#{
#   my $self=shift;
#   my $rec=shift;
#
#   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
#      my $o=$self->Clone();
#      my $oldcontext=$W5V2::OperationContext;
#      $W5V2::OperationContext="QualityCheck";
#      $o->BackendSessionName("preProcessReadedRecord"); # prevent sesssion reuse
#                                                  # on sql cached_connect
#      my ($id)=$o->ValidatedInsertRecord({applid=>$rec->{parentid}});
#      $W5V2::OperationContext=$oldcontext;
#      $rec->{id}=$id;
#      $rec->{cistatusid}='4';
#      $rec->{replkeypri}="1970-01-01 00:00:00";
#      $rec->{replkeysec}=$id;
#   }
#   return(undef);
#}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   my $basefields="appl.id applid,appl.name applname,".
                  "appl.databoss appldataboss,".
                  "appl.mandator applmandator,".
                  "appl.businessteam applbusinessteam,".
                  "appl.responseteam applresponseteam,".
                  "lnkcontact.target lnkcontacttarget,".
                  "lnkcontact.targetid lnkcontacttargetid,".
                  "lnkcontact.croles lnkcontactcroles,".
                  "businessservice.*";

   if (ref($flt[0]) eq "HASH" &&
       ref($flt[0]->{id})){
      my $id;
      if (ref($flt[0]->{id}) eq "ARRAY"){
         $id=join(",",map({
            my $bk=$_;
            if (!defined($bk)){
               $bk="NULL";
            }
            else{
               $bk="'$bk'";
            }
            $bk;
         } @{$flt[0]->{id}}));
      }
      if (ref($flt[0]->{id}) eq "SCALAR"){
         $id=${$flt[0]->{id}};
      }
 
      $from.="(select $basefields from businessservice ".
             "left outer join lnkcontact ".
             "on lnkcontact.parentobj='itil::businessservice' ".
             "and lnkcontact.refid=businessservice.id ".
             "left outer join appl ".
             "on appl.id=businessservice.appl ".
             "where businessservice.id in ($id) ".
             ") as businessservice ";
   }
   else{
      $from.="((select $basefields ".
             "from appl join businessservice ".
             "on appl.id=businessservice.appl ".
             "left outer join lnkcontact ".
             "on lnkcontact.parentobj='itil::appl' and ".
             "appl.id=lnkcontact.refid ".
             "where appl.cistatus<6) union ".
             "(select null applid,null applname,".
             "null appldataboss,".
             "null applmandator,".
             "null applbusinessteam,".
             "null applresponseteam,".
             "lnkcontact.target lnkcontacttarget,".
             "lnkcontact.targetid lnkcontacttargetid,".
             "lnkcontact.croles lnkcontactcroles,".
             "businessservice.* ".
             "from businessservice left outer join lnkcontact ".
             "on lnkcontact.parentobj='itil::businessservice' ".
             "and lnkcontact.refid=businessservice.id ".
             "where businessservice.appl is null)) as businessservice";
   }

   return($from);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec)){
      if (effVal($oldrec,$newrec,"mandatorid") eq ""){
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         $newrec->{mandatorid}=$mandators[0] if ($mandators[0] ne "");
      }
   }

   return($self->SUPER::SecureValidate($oldrec,$newrec));
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->itil::lib::BorderChangeHandling::BorderChangeHandling(
      $oldrec,
      $newrec
   );

   return($bak);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   if (defined($oldrec) && effChanged($oldrec,$newrec,"nature")){
      $self->LastMsg(ERROR,"nature is not allowed to change");
      return(0);
   }
   my $nature=effVal($oldrec,$newrec,"nature");

   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (effChanged($oldrec,$newrec,"cistatusid")){
         my $newcistatusid=effVal($oldrec,$newrec,"cistatusid");
         if ($newcistatusid==3 ||
             $newcistatusid==4 ){
            my $mandatorid=effVal($oldrec,$newrec,"mandatorid");
            my $isok=0;
            if ($nature eq "BC"){   # BusinessCap activation check
               if ($mandatorid!=0 &&
                  $self->IsMemberOf($mandatorid,["BCManager"], "down")){
                  $isok=1;
               }
            }
            elsif ($nature eq "PRC"){ # ProcessChain activation check
               if ($mandatorid!=0 &&
                  $self->IsMemberOf($mandatorid,["PCManager"], "down")){
                  $isok=1;
               }
               
            }
            else{
               $isok=1;
            }
            if (!$isok){
               $self->LastMsg(ERROR,"activation not allowed - ".
                                    "please contact a suitable manager");
               return(0);
            }
         }
      }
   }
   


   if (!defined($oldrec) && defined($newrec->{name})
       && ($newrec->{name}=~m/^\s*$/)){
      $self->LastMsg(ERROR,"invalid service name specified");
      return(0);
   }
   if (exists($newrec->{shortname})){
      my $sn=$newrec->{shortname};
      $sn=~s/[^0-9,a-z,-]//gi;
      $newrec->{shortname}=$sn;
   }

   if (effVal($oldrec,$newrec,"name")=~m/[:\]\[]/){
      $self->LastMsg(ERROR,"invalid service name specified");
      return(0);
   }
   my $applid=effVal($oldrec,$newrec,"applid");


   if ($applid eq ""){
      if (effVal($oldrec,$newrec,"nature") eq ""){
         $self->LastMsg(ERROR,"gerneric Business Service need an application");
         return(0);
      }
      if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
         my $userid=$self->getCurrentUserId();
         if (!defined($oldrec)){
            if (!defined($newrec->{databossid}) ||
                $newrec->{databossid}==0){
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
      if (effVal($oldrec,$newrec,"mandatorid") eq ""){
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
      }
   }
   else{
      if (effVal($oldrec,$newrec,"nature") ne ""){
         $self->LastMsg(ERROR,
               "application only allowed on gerneric Business Service");
         return(0);
      }
      if ($self->isDataInputFromUserFrontend()){
         if (!$self->isParentWriteable($applid)){
            $self->LastMsg(ERROR,"no write access to specified application");
            return(0);
         }
      }
   }
 




   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l;

   return("default","sla","reporting","moni","desc",
          "monicomments") if (!defined($rec));
   if ($rec->{applid} ne ""){
      if ($self->isParentWriteable($rec->{applid})){
         push(@l,"default","desc","servicecomp");
      }
   }
   else{
      my $wr=0;
      my $userid=$self->getCurrentUserId();
      if ($userid==$rec->{databossid}){
         $wr++;
      }
      else{
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
               if (ref($contact->{roles}) eq "ARRAY"){
                  @roles=@{$contact->{roles}};
               }
               if (grep(/^write$/,@roles)){
                  $wr++;
                  last;
               }
            }
         }
         if (!$wr){
            my $nature=$rec->{"nature"};
            my $mandatorid=$rec->{"mandatorid"};
            if ($nature eq "BC"){   # BusinessCap activation check
               if ($mandatorid!=0 &&
                  $self->IsMemberOf($mandatorid,["BCManager"], "down")){
                  $wr=1;
               }
            }
            elsif ($nature eq "PC"){ # ProcessChain activation check
               if ($mandatorid!=0 &&
                  $self->IsMemberOf($mandatorid,["PCManager"], "down")){
                  $wr=1;
               }
               
            }
         }
         if (!$wr){
            if ($rec->{mandatorid}!=0 &&
               $self->IsMemberOf($rec->{mandatorid},
                                      ["RCFManager","RCFManager2"],"down")){
                    $wr++;
            }
         }
         if (!$wr){
            if ($self->IsMemberOf("admin")){
               $wr++;
            }
         }
      }
      
      if ($wr){
         push(@l,"default","contacts","desc","servicecomp","sla","moni",
                 "monicomments","grprelations",
                 "attachments","reporting");
      }
   }
   return(@l);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   return("header","default") if (!defined($rec));
   my @l=qw(header default history);
   if ($self->IsMemberOf("admin")){
      push(@l,qw(qc));
   }
   if ($rec->{applid} ne ""){
      push(@l,qw(desc uservicecomp servicecomp));
   }
   else{
      push(@l,qw(contacts desc uservicecomp servicecomp grprelations
                 attachments reporting sla moni monicomments));
   }
   push(@l,qw(businessprocesses source));
   return(@l);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/bussinessservice.jpg?".
          $cgi->query_string());
}




sub isParentWriteable
{
   my $self=shift;
   my $applid=shift;

   my $p=$self->getPersistentModuleObject($self->Config,"itil::appl");
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$applid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,"invalid application reference");
      return(0);
   }
   my @write=$p->isWriteValid($l[0]);
   if (!grep(/^ALL$/,@write) && !grep(/^default$/,@write)){
      return(0);
   }
   return(1);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (
      #!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RCFManager RCFManager2 
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      push(@flt,[
         {mandatorid=>\@mandators},
         {databossid=>\$userid},
         {businessteamid=>\@grpids},
         {responseteamid=>\@grpids},
         {sectargetid=>\$userid,sectarget=>\'base::user',
          secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                    "*roles=?read?=roles*"},
         {sectargetid=>\@grpids,sectarget=>\'base::grp',
          secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                    "*roles=?read?=roles*"}
      ]);
   }
   return($self->SetFilter(@flt));
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub generateContextMap
{
   my $self=shift;
   my $rec=shift;

   my $d={
      items=>[]
   };

   my $imageUrl=$self->getRecordImageUrl(undef);
   my $cursorItem;

   my %matrixIdLength;
   my $maxParents=0;

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
      if (($obj->{dataobj}=~m/::businessservice$/) ||
          ($obj->{dataobj}=~m/::appl$/)){ 
         $titleurl=~s#/ById/#/Map/#;
      }
      $itemrec->{titleurl}=$titleurl;
      


      my $matrixId="1"; 
      $matrixId="2" if ($obj->{dataobj}=~m/::businessservice$/);
      $matrixId="3" if ($obj->{dataobj}=~m/::appl$/);
      $itemrec->{matrixId}=$matrixId;

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
      my $l1=LengthOfLongestWord($itemrec->{title});
      my $l2=LengthOfLongestWord($itemrec->{description});
      my $l3=length($itemrec->{title});
      my $l4=length($itemrec->{description});

      if ($l1>25 || $l2>19 || $l3>40 || $l4>50){
         $matrixIdLength{$matrixId}=25 if ($matrixIdLength{$matrixId}<25);
      }
      elsif ($l1>16 || $l2>10 || $l3>30 || $l4>40){
         $matrixIdLength{$matrixId}=16 if ($matrixIdLength{$matrixId}<16);
      }
      #$itemrec->{groupTitle}=$obj->{dataobj};
      $itemrec->{levelOffset}=2 if ($obj->{dataobj}=~m/::businessservice$/);

      if (exists($obj->{directParent})){
         $itemrec->{parents}=$obj->{directParent};
         if ($#{$obj->{directParent}}+1>$maxParents){
            $maxParents=$#{$obj->{directParent}}+1;
         }
      }
      $itemrec->{labelPlacement}=3;
      push(@{$d->{items}},$itemrec);
   }
   foreach my $itemrec (@{$d->{items}}){
      my $matrixId=$itemrec->{matrixId};
      if (exists($matrixIdLength{$matrixId})){
         if ($matrixIdLength{$matrixId}==16){
            $itemrec->{templateName}="wideTemplate";
         }
         if ($matrixIdLength{$matrixId}==25){
            $itemrec->{templateName}="ultraWideTemplate";
         }
      }
   }

   if ($cursorItem){
      $d->{cursorItem}=$cursorItem;
   }
   if ($maxParents>3){
      $d->{enableMatrixLayout}=1;
   }
   else{
      $d->{enableMatrixLayout}=0;
   }
   if ($#{$d->{items}}>19){
      $d->{initialZoomLevel}="6";
   }
   elsif ($#{$d->{items}}>8){
      $d->{initialZoomLevel}="5";
   }

   #print STDERR Dumper($d);
   return($d);
}


sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;

   my $label=$self->T("add tangential elementes");
   $methods->{'m500addTangCIs'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m500addTangCIs on \",this);
          \$(\".spinner\").show();
          var app=this.app;
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'itil::businessservice');
                w5obj.SetFilter({
                   id:dataobjid
                });
                w5obj.findRecord(\"id,servicetrees\",
                     function(data){
                   //console.log(\"recive \",data);
                   for(recno=0;recno<data.length;recno++){
                      if (data[recno].servicetrees){
                         for(var dkey in data[recno].servicetrees.obj){
                            var obj=data[recno].servicetrees.obj[dkey];
                            var a=new Object();
                            a.level=3;
                            if (obj.dataobj==\"crm::businessprocess\"){
                               a.level=-2;
                            }
                            if (obj.dataobj==\"itil::businessservice\"){
                               a.level=-1;
                            }
                            a.shapeProperties=new Object();
                            a.widthConstraint=new Object();
                            a.widthConstraint.minimum=200;
                            a.shapeProperties.useBorderWithImage=true;
                            a.shapeProperties.borderDashes=true;
                            a.widthConstraint.maximum=250;
                            //a.size=40;
                            app.addNode(obj.dataobj,obj.dataobjid,obj.label,a);
                         }
                         for(var dkey in data[recno].servicetrees.obj){
                            var cobj=data[recno].servicetrees.obj[dkey];
                            if (cobj.directParent){
                               for(i=0;i<cobj.directParent.length;i++){
                                  var pkey=cobj.directParent[i];
                                  var pobj=data[recno].servicetrees.obj[pkey];
                                  var pObjKey=app.toObjKey(pobj.dataobj,
                                                           pobj.dataobjid);
                                  var cObjKey=app.toObjKey(cobj.dataobj,
                                                           cobj.dataobjid);
                                  app.addEdge(pObjKey,cObjKey,{
                                                 noAcross:true,
                                                 color:{
                                                    color:'black'
                                                 },
                                                 arrows:{
                                                    to:{
                                                       enabled:true,
                                                       type:'arrow'
                                                    }
                                                 }
                                  });
                               }
                            }
                         }
                      }
                   }
                   methodDone(\"end of am500addTangCIs\");
                });
             });
          }));
       }
   ";

}










1;
