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
                sqlorder      =>'desc',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),
                                                  
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
                searchable    =>0,
                label         =>'Name',
                dataobjattr   =>"$worktable.name"),

      new kernel::Field::Text(
                name          =>'shortname',
                sqlorder      =>'desc',
                searchable    =>0,
                htmleditwidth =>'50px',
                label         =>'Short name',
                dataobjattr   =>"$worktable.shortname"),


      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                default       =>4,
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>"if ($worktable.cistatus is null,".
                                "4,$worktable.cistatus)", # hack for autogen
                wrdataobjattr =>"$worktable.cistatus"),   # (entire) services

      new kernel::Field::Select(
                name          =>'nature',
                sqlorder      =>'desc',
                label         =>'Nature',
                htmleditwidth =>'40%',
                transprefix   =>'nat.',
                value         =>['','IT-S','ES','TA'],
                dataobjattr   =>"$worktable.nature"),

      new kernel::Field::Link(
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
                   return(0);
                },
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
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                label         =>'functional manager',
                vjoinon       =>'funcmgrid'),

                                                  
      new kernel::Field::Link(
                name          =>'funcmgrid',
                label         =>'functional mgr id',
                dataobjattr   =>"$worktable.funcmgr"),

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

                   return(1) if (defined($current));
                   return(0);
                }),

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
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'PCONTROL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Text(
                name          =>'reportinglabel',
                label         =>'Reporting Label',
                vjointo       =>'itil::lnkmgmtitemgroup',
                group         =>'reporting',
                searchable    =>0,
                htmldetail    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};

                   return(1) if (defined($current));
                   return(0);
                },
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
                group         =>'desc',
                label         =>'Business Service Description',
                dataobjattr   =>"$worktable.description"),

      new kernel::Field::Date(
                name          =>'validfrom',
                group         =>'desc',
                label         =>'Duration Start',
                dataobjattr   =>"$worktable.validfrom"),

      new kernel::Field::Date(
                name          =>'validto',
                group         =>'desc',
                label         =>'Duration End',
                dataobjattr   =>"$worktable.validto"),

      new kernel::Field::Text(
                name          =>'version',
                group         =>'desc',
                label         =>'Version',
                htmleditwidth =>'80px',
                dataobjattr   =>"$worktable.version"),


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
                searchable    =>0,
                vjointo       =>'itil::lnkbscomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'obj1id'],
                vjoindisp     =>['uppername']),

      new kernel::Field::SubList(
                name          =>'servicecomp',
                label         =>'service components',
                group         =>'servicecomp',
                searchable    =>0,
                subeditmsk    =>'subedit.businessservice',
                vjointo       =>'itil::lnkbscomp',
                allowcleanup  =>1,
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['lnkpos','name',"xcomments"],
                vjoininhash   =>['sortkey','lnkpos','id','objtype',
                                 'obj1id','obj2id','obj3id','comments']),

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
                vjointo       =>'itil::lnkbprocessbservice',
                vjoinon       =>['id'=>'businessserviceid'],
                vjoindisp     =>['businessprocess','customer']),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'applbusinessteam'),

      new kernel::Field::Link(
                name          =>'responseteamid',
                dataobjattr   =>'applresponseteam'),



      new kernel::Field::MatrixHeader(
                name          =>'slamatrix',
                group         =>'sla',
                label         =>[undef,'requested','implemented','current',
                                 'threshold warn','threshold crit']),

      new kernel::Field::Duration(
                name          =>'requ_mtbf',
                group         =>'sla',
                visual        =>'hh:mm',
                label         =>'MTBF in h',
                align         =>'right',
                searchable    =>0,
                extLabelPostfix=>\&extLabelPostfixRequested,
                dataobjattr   =>$worktable.'.requ_mtbf'),

      new kernel::Field::Duration(
                name          =>'impl_mtbf',
                group         =>'sla',
                visual        =>'hh:mm',
                searchable    =>0,
                label         =>'MTBF in h',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixImplemented,
                dataobjattr   =>$worktable.'.impl_mtbf'),

      new kernel::Field::Duration(
                name          =>'curr_mtbf',
                group         =>'sla',
                visual        =>'hh:mm',
                searchable    =>0,
                label         =>'MTBF in h',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixCurrent,
                dataobjattr   =>$worktable.'.curr_mtbf'),

      new kernel::Field::Number(
                name          =>'threshold_warn_mtbf',
                group         =>'sla',
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.92')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'MTBF',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHWarn,
                dataobjattr   =>$worktable.'.th_warn_mtbf'),

      new kernel::Field::Number(
                name          =>'threshold_crit_mtbf',
                group         =>'sla',
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.97')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'MTBF',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHCrit,
                dataobjattr   =>$worktable.'.th_crit_mtbf'),

      new kernel::Field::Duration(
                name          =>'requ_ttr',
                group         =>'sla',
                visual        =>'hh:mm',
                searchable    =>0,
                label         =>'TTR in h',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixRequested,
                dataobjattr   =>$worktable.'.requ_ttr'),

      new kernel::Field::Duration(
                name          =>'impl_ttr',
                group         =>'sla',
                visual        =>'hh:mm',
                searchable    =>0,
                label         =>'TTR in h',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixImplemented,
                dataobjattr   =>$worktable.'.impl_ttr'),

      new kernel::Field::Duration(
                name          =>'curr_ttr',
                group         =>'sla',
                visual        =>'hh:mm',
                searchable    =>0,
                label         =>'TTR in h',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixCurrent,
                dataobjattr   =>$worktable.'.curr_ttr'),

      new kernel::Field::Number(
                name          =>'threshold_warn_ttr',
                group         =>'sla',
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.92')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'TTR',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHWarn,
                dataobjattr   =>$worktable.'.th_warn_ttr'),

      new kernel::Field::Number(
                name          =>'threshold_crit_ttr',
                group         =>'sla',
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.97')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'TTR',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHCrit,
                dataobjattr   =>$worktable.'.th_crit_ttr'),

      new kernel::Field::MatrixHeader(
                name          =>'monimatrix',
                group         =>'moni',
                label         =>[undef,'requested','implemented','current',
                                 'threshold warn','threshold crit']),

      new kernel::Field::Percent(
                name          =>'requ_avail_p',
                precision     =>2,
                group         =>'moni',
                searchable    =>0,
                label         =>'avalability in %',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixRequested,
                dataobjattr   =>$worktable.'.requ_avail_p'),

      new kernel::Field::Percent(
                name          =>'impl_avail_p',
                precision     =>2,
                group         =>'moni',
                searchable    =>0,
                label         =>'avalability in %',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixImplemented,
                dataobjattr   =>$worktable.'.impl_avail_p'),

      new kernel::Field::Percent(
                name          =>'curr_avail_p',
                precision     =>2,
                group         =>'moni',
                searchable    =>0,
                label         =>'avalability in %',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixCurrent,
                dataobjattr   =>$worktable.'.curr_avail_p'),

      new kernel::Field::Number(
                name          =>'threshold_warn_avail',
                group         =>'moni',
                precision     =>2, 
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.92')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                label         =>'avalability',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHWarn,
                dataobjattr   =>$worktable.'.th_warn_avail'),

      new kernel::Field::Number(
                name          =>'threshold_crit_avail',
                group         =>'moni',
                precision     =>2, 
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.97')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                label         =>'avalability',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHCrit,
                dataobjattr   =>$worktable.'.th_crit_avail'),

      new kernel::Field::Number(
                name          =>'requ_respti',
                group         =>'moni',
                label         =>'responsetime in ms',
                align         =>'right',
                searchable    =>0,
                extLabelPostfix=>\&extLabelPostfixRequested,
                dataobjattr   =>$worktable.'.requ_respti'),

      new kernel::Field::Number(
                name          =>'impl_respti',
                group         =>'moni',
                searchable    =>0,
                label         =>'responsetime in ms',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixImplemented,
                dataobjattr   =>$worktable.'.impl_respti'),

      new kernel::Field::Number(
                name          =>'curr_respti',
                group         =>'moni',
                label         =>'responsetime in ms',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixCurrent,
                dataobjattr   =>$worktable.'.curr_respti'),

      new kernel::Field::Number(
                name          =>'threshold_warn_respti',
                group         =>'moni',
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.92')
                },
                background    =>\&calcBackgroundFlagColor,
                precision     =>2, 
                editrange     =>[0.01,5.0],
                label         =>'responsetime',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHWarn,
                dataobjattr   =>$worktable.'.th_warn_respti'),

      new kernel::Field::Number(
                name          =>'threshold_crit_respti',
                group         =>'moni',
                default       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;

                   return(undef) if ($mode eq "edit");
                   return('0.97')
                },
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'responsetime',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHCrit,
                dataobjattr   =>$worktable.'.th_crit_respti'),

      new kernel::Field::Percent(
                name          =>'requ_perf',
                group         =>'moni',
                label         =>'performance in %',
                align         =>'right',
                default       =>'95',
                searchable    =>0,
                extLabelPostfix=>\&extLabelPostfixRequested,
                dataobjattr   =>$worktable.'.requ_perf'),

      new kernel::Field::Percent(
                name          =>'impl_perf',
                group         =>'moni',
                searchable    =>0,
                readonly      =>1,
                label         =>'performance in %',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixImplemented,
                dataobjattr   =>$worktable.'.impl_perf'),

      new kernel::Field::Percent(
                name          =>'curr_perf',
                group         =>'moni',
                default       =>'95',
                label         =>'performance in %',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixCurrent,
                dataobjattr   =>$worktable.'.curr_perf'),

      new kernel::Field::Number(
                name          =>'threshold_warn_perf',
                group         =>'moni',
               # default       =>sub{
               #    my $self=shift;
               #    my $current=shift;
               #    my $mode=shift;
               #
               #    return(undef) if ($mode eq "edit");
               #    return('0.92')
               # },
                readonly      =>1,
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'performance',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHWarn,
                dataobjattr   =>$worktable.'.th_warn_perf'),

      new kernel::Field::Number(
                name          =>'threshold_crit_perf',
                group         =>'moni',
               # default       =>sub{
               #    my $self=shift;
               #    my $current=shift;
               #    my $mode=shift;
               #
               #    return(undef) if ($mode eq "edit");
               #    return('0.97')
               # },
                readonly      =>1,
                background    =>\&calcBackgroundFlagColor,
                editrange     =>[0.01,5.0],
                precision     =>2, 
                label         =>'performance',
                align         =>'right',
                extLabelPostfix=>\&extLabelPostfixTHCrit,
                dataobjattr   =>$worktable.'.th_crit_perf'),

      new kernel::Field::Textarea(
                name          =>'slacomments',
                group         =>'monicomments',
                label         =>'comments for alternate thresholds',
                dataobjattr   =>$worktable.'.slacomments'),

      new kernel::Field::Number(
                name          =>'reproacht',
                group         =>'reporting',
                label         =>'reproach-time',
                unit          =>'days',
                align         =>'right',
                dataobjattr   =>$worktable.'.reproacht'),

      new kernel::Field::Select(
                name          =>'durationtoav',
                group         =>'reporting',
                label         =>'Duration to availability',
                value         =>['','24:00'],
                htmleditwidth =>'90px',
                dataobjattr   =>$worktable.'.durationtoav'),

      new kernel::Field::Select(
                name          =>'repoperiod',
                group         =>'reporting',
                label         =>'Reporting-period',
                value         =>['','24:00'],
                htmleditwidth =>'90px',
                dataobjattr   =>$worktable.'.repoperiod'),

      new kernel::Field::Select(
                name          =>'reviewperiod',
                group         =>'reporting',
                label         =>'Review-period',
                transprefix   =>'REVIEW.',
                value         =>['','WEEK','MONTH','QUARTER','YEAR'],
                htmleditwidth =>'150px',
                dataobjattr   =>$worktable.'.reviewperiod'),

      new kernel::Field::Duration(
                name          =>'mperiod',
                group         =>'reporting',
                label         =>'Measure-period',
                visual        =>'hh:mm',
                dataobjattr   =>$worktable.'.mperiod'),

      new kernel::Field::Textarea(
                name          =>'commentsrm',
                group         =>'reporting',
                label         =>'Remarks on measurement procedures and reporting',
                dataobjattr   =>$worktable.'.commentsrm'),

      new kernel::Field::Textarea(
                name          =>'commentsperf',
                group         =>'reporting',
                label         =>'Performance-description',
                dataobjattr   =>$worktable.'.commentsperf'),


      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::businessservice',
                group         =>'attachments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>$worktable.'.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>$worktable.'.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>$worktable.'.srcload'),

      new kernel::Field::Text(
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
                label         =>'Owner',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>"$worktable.realeditor"),

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
   $self->{history}=[qw(insert modify delete)];

   $self->setDefaultView(qw(fullname cistatus application));
   return($self);
}

sub calcBackgroundFlagColor
{
   my $self=shift;
   my $FormatAs=shift;
   my $current=shift;

   my $def=$self->default($FormatAs);
   my $cur=$current->{$self->Name()};

   $cur=$def if ($cur eq "");

   my $delta=abs($def-$cur);
   if ($delta>0 && $def>0){
      my $p=(100*$delta)/$def;
      if ($p>10){
         return("red");
      }elsif ($p>5){
         return("yellow");
      }
   }
   return("");
}

sub extLabelPostfixRequested
{
   my $self=shift;
   return(" - ".$self->getParent->T("requested"));
}

sub extLabelPostfixImplemented
{
   my $self=shift;
   return(" - ".$self->getParent->T("implemented"));
}

sub extLabelPostfixCurrent
{
   my $self=shift;
   return(" - ".$self->getParent->T("current"));
}

sub extLabelPostfixTHCrit
{
   my $self=shift;
   return(" - ".$self->getParent->T("threshold crit"));
}

sub extLabelPostfixTHWarn
{
   my $self=shift;
   return(" - ".$self->getParent->T("threshold warn"));
}




sub getBSfullnameSQL
{
   my $worktable=shift;
   my $applname=shift;

   my $d="concat(".
         "if ($worktable.nature is null ".
         "or $worktable.nature='','',concat($worktable.nature,'_',".
         "if ($worktable.shortname is null or ".
         "$worktable.shortname='',':',concat($worktable.shortname,':')))),".
         "if ($applname is null,'',".
         "concat($applname,if ($worktable.shortname is null or ".
         "$worktable.shortname='',':',".
         "concat(':',$worktable.shortname,':')))),".
         "if ($worktable.name is null,'[ENTIRE]',".
         "$worktable.name))";

   return($d);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default applinfo desc  uservicecomp servicecomp
             contacts businessprocesses reporting sla moni monicomments 
             attachments source));
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::businessservice");
}






sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
      my $o=$self->Clone();
      my $oldcontext=$W5V2::OperationContext;
      $W5V2::OperationContext="QualityCheck";
      $o->BackendSessionName("preProcessReadedRecord"); # prevent sesssion reuse
                                                  # on sql cached_connect
      my ($id)=$o->ValidatedInsertRecord({applid=>$rec->{parentid}});
      $W5V2::OperationContext=$oldcontext;
      $rec->{id}=$id;
      $rec->{cistatusid}='4';
      $rec->{replkeypri}="1970-01-01 00:00:00";
      $rec->{replkeysec}=$id;
   }
   return(undef);
}



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
         $id=join(",",@{$flt[0]->{id}});
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
             "from appl left outer join businessservice ".
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
   my $org=shift;

   if (!defined($oldrec)){
      if (effVal($oldrec,$newrec,"mandatorid") eq ""){
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         $newrec->{mandatorid}=$mandators[0] if ($mandators[0] ne "");
      }
   }

   return($self->SUPER::SecureValidate($oldrec,$newrec,$org));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $autogenmode=0;

   if (!defined($oldrec) && 
       ( (keys(%$newrec)==1 && defined($newrec->{applid})) ||
         $W5V2::OperationContext eq "W5Server" ||
         $W5V2::OperationContext eq "W5Replicate" ||
         $W5V2::OperationContext eq "QualityCheck")){
      $autogenmode++;
   }



   if (exists($newrec->{version}) && $newrec->{version} ne ""){
      if (!($newrec->{version}=~m/^\d{1,2}(\.\d{1,2}){0,4}$/)){
         $self->LastMsg(ERROR,"invalid version string");
         return(0);
      }
   }

   my $validto=effVal($oldrec,$newrec,"validto");
   my $validfrom=effVal($oldrec,$newrec,"validfrom");
   if ($validto ne "" && $validfrom ne ""){
      my $duration=CalcDateDuration($validfrom,$validto);
      if ($duration->{totalseconds}<0){
         $self->LastMsg(ERROR,"validto can't be sooner as validfrom");
         return(0);
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

   if (effVal($oldrec,$newrec,"name") eq "[ENTIRE]" ||
       effVal($oldrec,$newrec,"name") eq ""){
      $newrec->{name}=undef;
   }
   if (effVal($oldrec,$newrec,"name")=~m/[:\]\[]/){
      $self->LastMsg(ERROR,"invalid service name specified");
      return(0);
   }
   my $applid=effVal($oldrec,$newrec,"applid");

   if ($applid eq ""){
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
      if (effVal($oldrec,$newrec,"mandatorid") eq ""){
         print STDERR Dumper($newrec);
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         print STDERR (Dumper(\@mandators));
      }
   }
   else{
      if (!$autogenmode){
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

   return("default") if (!defined($rec));
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
                 "monicomments",
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
   if ($rec->{applid} ne ""){
      push(@l,qw(desc uservicecomp servicecomp));
   }
   else{
      push(@l,qw(contacts desc uservicecomp servicecomp 
                 attachments reporting sla moni monicomments));
   }
   push(@l,qw(businessprocesses source));
   return(@l);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/bussinessservice.jpg?".$cgi->query_string());
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









1;
