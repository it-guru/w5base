package TS::appl;
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
use kernel::Field;
use itil::appl;
@ISA=qw(itil::appl);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                group         =>'control',
                label         =>'Incident Assignmentgroup ID',
                dataobjattr   =>'appl.acinmassignmentgroupid'),

      new kernel::Field::Htmlarea(
                name          =>'applicationexpertgroup',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['baseaeg'],
                group         =>'technical',
                label         =>'Application Expert Group',
                onRawValue    =>\&calcApplicationExpertGroup),

      new kernel::Field::Container(
                name          =>'baseaeg',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                depend        =>['tsmid','opmid','applmgrid','contacts',
                                 'systems','businessteamid',
                                 'businessteam','businessteamid'],
                group         =>'technical',
                label         =>'base Application Expert Group',
                onRawValue    =>\&calcBaseApplicationExpertGroup),

      new kernel::Field::Container(
                name          =>'technicalaeg',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                uivisible     =>1,
                depend        =>['baseaeg'],
                group         =>'technical',
                label         =>'tec Application Expert Group',
                onRawValue    =>\&calcTecApplicationExpertGroup),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                vjoineditbase =>{isinmassign=>\'1'},
                explore       =>200,
                group         =>'inm',
                AllowEmpty    =>1,
                vjointo       =>'tsgrpmgmt::grp',
                vjoinon       =>['acinmassignmentgroupid'=>'id'],
                vjoindisp     =>'fullname'),

#      new kernel::Field::Link(
#                name          =>'scapprgroupid',
#                group         =>'control',
#                label         =>'Change Approvergroup technical ID',
#                dataobjattr   =>'appl.scapprgroupid'),
#
#      new kernel::Field::Link(
#                name          =>'scapprgroupid2',
#                group         =>'control',
#                label         =>'Change Approvergroup business ID',
#                dataobjattr   =>'appl.scapprgroupid2'),
#
#      new kernel::Field::TextDrop(
#                name          =>'scapprgroup',
#                label         =>'Change Approvergroup technical',
#                vjoineditbase =>{ischmapprov=>\'1'},
#                uivisible=>0,
#                group         =>'inmchm',
#                AllowEmpty    =>1,
#                htmldetail    =>0,
#                vjointo       =>'tsgrpmgmt::grp',
#                vjoinon       =>['scapprgroupid'=>'id'],
#                vjoindisp     =>'fullname'),
#
#      new kernel::Field::TextDrop(
#                name          =>'scapprgroup2',
#                label         =>'Change Approvergroup business',
#                uivisible=>0,
#                vjoineditbase =>{ischmapprov=>\'1'},
#                group         =>'inmchm',
#                AllowEmpty    =>1,
#                htmldetail    =>0,
#                vjointo       =>'tsgrpmgmt::grp',
#                vjoinon       =>['scapprgroupid2'=>'id'],
#                vjoindisp     =>'fullname'),


      new kernel::Field::SubList(
                name          =>'chmapprgroups',
                label         =>'Change approver groups',
                htmlwidth     =>'200px',
                group         =>'chm',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.approver',
                vjointo       =>'TS::lnkapplchmapprgrp',
                vjoinbase     =>[{parentobj=>\'TS::appl'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['group','responsibility']),

      new kernel::Field::Text(
                name          =>'ictoid',
                htmldetail    =>0,
                uploadable    =>0,
                searchable    =>0,
                group         =>'functional',
                label         =>'ICTO internal ID',
                dataobjattr   =>'appl.ictoid'),

      new kernel::Field::Text(
                name          =>'ciamapplid',
                group         =>'misc',
                label         =>'CIAM ApplicationID',
                dataobjattr   =>'appl.ciamapplid'),

      new kernel::Field::Select(
                name          =>'cloudusage',
                label         =>'Cloud-Usage',
                group         =>'technical',
                searchable    =>0,
                depend        =>['itcloudareas','systems'],
                transprefix   =>'CLOUDUSAGE.',
                onRawValue    =>sub{
                                my $self=shift;
                                my $current=shift;
                                my $d=undef;
                                my $fo=$self->getParent->getField(
                                                    "itcloudareas",$current);
                                my $cloudareas=$fo->RawValue($current);
                                my $fo=$self->getParent->getField(
                                                    "systems",$current);
                                my $systems=$fo->RawValue($current);
                                if (!defined($cloudareas) ||
                                    ref($cloudareas) ne "ARRAY" ||
                                    $#{$cloudareas}==-1){
                                   $d="NONE";
                                }
                                else{
                                   $d="FULL";
                                   my $foundNoneCloud=0;
                                   foreach my $sysrec (@{$systems}){
                                      if (!in_array([qw(OTC AWS TPrivCloud)],
                                                    $sysrec->{srcsys})){
                                         $foundNoneCloud++;
                                      }
                                   }
                                   if ($foundNoneCloud){
                                      $d="HYBRID";
                                   }
                                }
                                return($d);
                              },
                htmldetail    =>0),

      new kernel::Field::Select(
                name          =>'controlcenter',
                group         =>'monisla',
                label         =>'responsible ControlCenter',
                allowempty    =>1,
                useNullEmpty  =>1,
                vjointo       =>'base::grp',
                vjoinbase     =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @posiblegroups=(12797577180002,12788074530009);
                   if ($current->{businessteamid} ne ""){
                      push(@posiblegroups,$current->{businessteamid});
                   }
                   return({grpid=>\@posiblegroups,cistatusid=>'4'});
                },
                vjoinon       =>['controlcenterid'=>'grpid'],
                depend        =>['businessteamid'],
                vjoindisp     =>'fullname',
                htmleditwidth =>'280px'),

      new kernel::Field::Link(
                name          =>'controlcenterid',
                group         =>'control',
                label         =>'ControlCenter ID',
                dataobjattr   =>'appl.controlcenter'),

   );

   # removed based on request
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14135335110009
   # 
   #$self->AddFields(
   #   new kernel::Field::Text(
   #             name          =>'applnumber',
   #             searchable    =>0,
   #             label         =>'Application number',
   #             container     =>'additional'),
   #   insertafter=>['applid'] 
   #);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'acapplname',
                label         =>'AM: official AssetManager Applicationname',
                group         =>'external',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['applid','name'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $applid=$self->getParent->getField("applid")
                              ->RawValue($current);
                   if ($applid ne ""){
                      my $a=getModuleObject($self->getParent->Config,
                                            "tsacinv::appl");
                      if (defined($a)){
                         $a->SetFilter({applid=>\$applid});
                         my ($arec,$msg)=$a->getOnlyFirst(qw(fullname));
                         if (defined($arec)){
                            return($arec->{fullname});
                         }
                      }
                   }

                   if ($current->{name} ne "" &&
                       $current->{applid} ne ""){
                      return(uc($current->{name}." (".$current->{applid}.")"));
                   }
                   return(undef);
                }),
      new kernel::Field::Text(
                name          =>'amossprodplan',
                label         =>'AM: Production Planning OSS',
                group         =>'external',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>\'tsacinv::costcenter',
                vjoinon       =>['conumber'=>'name'],
                vjoindisp     =>'productionplanningoss')
   );


   $self->AddFields(
      new kernel::Field::Text(
                name          =>'ictono',
                htmldetail    =>0,
                uploadable    =>0,
                explore       =>150,
                group         =>'functional',
                label         =>'ICTO-ID',
                dataobjattr   =>'appl.ictono'),
     insertafter=>'systems'
   );


   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'icto',
                label         =>'ICTO Objectname',
                group         =>'functional',
                async         =>'1',
                AllowEmpty    =>1,
                vjointo       =>'tscape::archappl',
                vjoinon       =>['ictoid'=>'id'],
                vjoindisp     =>'fullname'),
      insertbefore=>'applmgr'
   );


   $self->{workflowlink}->{workflowtyp}=[qw(AL_TCom::workflow::diary
                                            OSY::workflow::diary
                                            itil::workflow::businesreq
                                            itil::workflow::businessact
                                            itil::workflow::devrequest
                                            itil::workflow::opmeasure
                                            AL_TCom::workflow::businesreq
                                            AL_TCom::workflow::riskmgmt
                                            THOMEZMD::workflow::businesreq
                                            base::workflow::DataIssue
                                            base::workflow::mailsend
                                            TS::workflow::change
                                            TS::workflow::problem
                                            TS::workflow::incident
                                            AL_TCom::workflow::change
                                            AL_TCom::workflow::problem
                                            AL_TCom::workflow::incident
                                            AL_TCom::workflow::eventnotify
                                            AL_TCom::workflow::P800
                                            AL_TCom::workflow::P800special
                                            )];
   $self->{workflowlink}->{workflowstart}=\&calcWorkflowStart;

   return($self);
}


sub addDesasterRecoveryClassFields
{
   my $self=shift;


   $self->AddFields(
      new kernel::Field::Select(
                name          =>'drclass',
                group         =>'sodrgroup',
                label         =>'Disaster Recovery Class',
                transprefix   =>'DR.',
                value         =>['',
                                 '0',
                                 '1',
                                 '2',
                                 '3',
                                 '4',
                                 '5',
                                 '6',
                                 '7',
                                 '11',
                                 '14',
                                 '18'
                                ],
                htmleditwidth =>'280px',
                dataobjattr   =>'appl.disasterrecclass'),

      new kernel::Field::Select(
                name          =>'rtolevel',
                group         =>'sodrgroup',
                label         =>'RTO Recovery Time Objective',
                readonly      =>1,
                transprefix   =>'RTO.',
                value         =>['',
                                 '0',
                                 '10',
                                 '20',
                                 '30',
                                 '40'],
                dataobjattr   =>
                                'if (appl.disasterrecclass=\'\',NULL,'.
                                'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,40,'.
                                'if (appl.disasterrecclass=2,30,'.
                                'if (appl.disasterrecclass=3,20,'.
                                'if (appl.disasterrecclass=4,10,'.
                                'if (appl.disasterrecclass=5,10,'.
                                'if (appl.disasterrecclass=6,10,'.
                                'if (appl.disasterrecclass=7,10,'.
                                'if (appl.disasterrecclass=11,10,'.
                                'if (appl.disasterrecclass=14,10,'.
                                'if (appl.disasterrecclass=18,10,'.
                                'NULL))))))))))))'),

      new kernel::Field::Select(
                name          =>'rpolevel',
                group         =>'sodrgroup',
                label         =>'RPO Recovery Point Objective',
                readonly      =>1,
                transprefix   =>'RPO.',
                value         =>['',
                                 '0',
                                 '10',
                                 '20',
                                 '25',
                                 '30',
                                 '40',
                                 '50'],
                dataobjattr   =>
                                'if (appl.disasterrecclass=\'\',NULL,'.
                                'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,30,'.
                                'if (appl.disasterrecclass=2,30,'.
                                'if (appl.disasterrecclass=3,30,'.
                                'if (appl.disasterrecclass=4,20,'.
                                'if (appl.disasterrecclass=5,20,'.
                                'if (appl.disasterrecclass=6,20,'.
                                'if (appl.disasterrecclass=7,20,'.
                                'if (appl.disasterrecclass=11,30,'.
                                'if (appl.disasterrecclass=14,20,'.
                                'if (appl.disasterrecclass=18,25,'.
                                'NULL))))))))))))'),

      new kernel::Field::Text(
                name          =>'drc',
                group         =>'sodrgroup',
                label         =>'DR Class',
                htmldetail    =>0,
                uivisible     =>0,
                dataobjattr   =>'appl.disasterrecclass'),

      new kernel::Field::Text(
                name          =>'rto',
                group         =>'sodrgroup',
                label         =>'RTO',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>
                                'if (appl.disasterrecclass=\'\',NULL,'.
                                'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,4,'.
                                'if (appl.disasterrecclass=2,3,'.
                                'if (appl.disasterrecclass=3,2,'.
                                'if (appl.disasterrecclass=4,1,'.
                                'if (appl.disasterrecclass=5,1,'.
                                'if (appl.disasterrecclass=6,1,'.
                                'if (appl.disasterrecclass=7,1,'.
                                'NULL)))))))))'),

      new kernel::Field::Text(
                name          =>'rpo',
                group         =>'sodrgroup',
                label         =>'RPO',
                depend        =>['drc'],
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>
                                'if (appl.disasterrecclass=\'\',NULL,'.
                                'if (appl.disasterrecclass=0,0,'.
                                'if (appl.disasterrecclass=1,3,'.
                                'if (appl.disasterrecclass=2,3,'.
                                'if (appl.disasterrecclass=3,3,'.
                                'if (appl.disasterrecclass=4,2,'.
                                'if (appl.disasterrecclass=5,2,'.
                                'if (appl.disasterrecclass=6,2,'.
                                'if (appl.disasterrecclass=7,2,'.
                                'NULL)))))))))'),

   );
}







sub calcTecApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;
   my $aeg=$self->getField("baseaeg")->RawValue($rec);

   my %aeg;
   foreach my $aegtag (sort({$aeg->{$a}->{sindex}<=>$aeg->{$b}->{sindex}}
                       keys(%$aeg))){
      foreach my $v (sort(keys(%{$aeg->{$aegtag}}))){
         my $tt=$aegtag."_".$v;
         next if ($v eq "sindex");
         next if ($v eq "phonename");
         $aeg{$tt}=[] if (!exists($aeg{$tt}));
         if (ref($aeg->{$aegtag}->{$v}) eq "ARRAY"){
            push(@{$aeg{$tt}},@{$aeg->{$aegtag}->{$v}});
         }
         else{
            push(@{$aeg{$tt}},$aeg->{$aegtag}->{$v});
         }
      }
   }



   return(\%aeg);
}

sub calcBaseApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;

   my $user=getModuleObject($self->getParent->Config,"base::user");
   my $index=0;
   my @aeg=('applmgr'=>{
                userid=>[$rec->{applmgrid}],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$appl->getField("applmgr")->Label(),
                sublabel=>"(System Manager)"
            },
            'tsm'=>{
                userid=>[$rec->{tsmid}],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$appl->getField("tsm")->Label(),
                sublabel=>"(technisch Verantw. Applikation)"
            },
            'opm'=>{
                userid=>[$rec->{opmid}],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$appl->getField("opm")->Label(),
                sublabel=>"(Produktions Verantw. Applikation)"
            },
            'dba'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Database Admin"),
                sublabel=>"(Verantwortlicher Datenbank)"
            },
            'developerboss'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Chief Developer",
                                           'itil::ext::lnkcontact'),
                sublabel=>"(Verantwortlicher Entwicklung)"
            },
            'projectmanager'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Projectmanager"),
                         sublabel=>"(Verantwortlicher Projektierung)"
            },
            'sdesign'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Solution Designer",
                                           'itil::ext::lnkcontact'),
            },
            'pmdev'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Projectmanager Development",
                                           'itil::ext::lnkcontact'),
            },
            'itsem'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>"IT-Servicemanager"
            },
            'opcanvasowner'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Canvas Owner",'TS::appl'),
                sublabel=>$self->getParent->T("(operational)",'TS::appl')
            },
            'opcanvasownerit'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Canvas Owner IT",'TS::appl'),
                sublabel=>$self->getParent->T("(operational)",'TS::appl')
            },
            'opbusinessowner'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Business Owner",'TS::appl'),
                sublabel=>$self->getParent->T("(operational)",'TS::appl')
            },
            'opbusinessownerit'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Business Owner IT",'TS::appl'),
                sublabel=>$self->getParent->T("(operational)",'TS::appl')
            },
            'leadprmmgr'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>"Lead Problem Manager"
            },
            'leadinmmgr'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>"Lead Incident Manager"
            },
            'chmmgr'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>"Change Manager"
            },
            'capmgr'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>"Capacity Manager"
            },
            'AEG'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                label=>"Application Expert Group",
                sublabel=>"(AEG)"
            },
           );
   my %a=@aeg;

   my $contacts=$appl->getField("contacts")->RawValue($rec);

   foreach my $crec (@{$contacts}){
      foreach my $k (qw(developerboss projectmanager sdesign pmdev)){
         if ($crec->{target} eq "base::user" &&
             in_array($crec->{roles},$k)){
            if (!in_array($a{$k}->{userid},$crec->{targetid})){
               push(@{$a{$k}->{userid}},$crec->{targetid});
            }
         }
      }
   }

   # In der GDU SAP ist generell der TSM auch DBA laut Request ...
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14273593150005
   # (auch wenns eigentlich ein Schmarren ist)
   my $m=$appl->getField("businessteam")->RawValue($rec);
   if (($m=~m/^DTAG\.TSI\.Prod\.CS\.SAPS(\.|$)/) ||
       ($m=~m/^DTAG\.GHQ\.VTS\.TSI\.ITDiv\.GITO\.SAPS(\.|$)/) ||
       ($m=~m/^DTAG\.TSY\.ITDiv\.CS\.SAPS(\.|$)/)){
      if ($rec->{tsmid} ne ""){
         push(@{$a{dba}->{userid}},$rec->{tsmid});
      }
   }
   if ($m ne ""){
      my @path=split(/\./,$m);
      my @flt;
      my $mm=$m;
      for(my $c=0;$c<=$#path;$c++){
         push(@flt,$mm);
         $mm=~s/\.[^.]+?$//;
      }
      my $vou=getModuleObject($self->getParent->Config,"TS::vou");
      $vou->SetFilter({reprgrp=>\@flt});
      my ($vourec,$msg)=$vou->getOnlyFirst(qw(
                   canvasownerbuid 
                   canvasowneritid
                   leaderitid
                   leaderid
      ));
      if (defined($vourec)){

         my $canvasownerbuid=$vourec->{canvasownerbuid};
         if (ref($canvasownerbuid) ne "ARRAY"){
            $canvasownerbuid=[$canvasownerbuid];
         }
         foreach my $uid (@{$canvasownerbuid}){
            if ($uid ne ""){
               push(@{$a{opcanvasowner}->{userid}},$uid);
            }
         }

         my $canvasowneritid=$vourec->{canvasowneritid};
         if (ref($canvasowneritid) ne "ARRAY"){
            $canvasowneritid=[$canvasowneritid];
         }
         foreach my $uid (@{$canvasowneritid}){
            if ($uid ne ""){
               push(@{$a{opcanvasownerit}->{userid}},$uid);
            }
         }

         my $leaderitid=$vourec->{leaderitid};
         if (ref($leaderitid) ne "ARRAY"){
            $leaderitid=[$leaderitid];
         }
         foreach my $uid (@{$leaderitid}){
            if ($uid ne ""){
               push(@{$a{opbusinessownerit}->{userid}},$uid);
            }
         }

         my $leaderid=$vourec->{leaderid};
         if (ref($leaderid) ne "ARRAY"){
            $leaderid=[$leaderid];
         }
         foreach my $uid (@{$leaderid}){
            if ($uid ne ""){
               push(@{$a{opbusinessowner}->{userid}},$uid);
            }
         }


      }
   }






   my $swi=getModuleObject($self->getParent->Config,"itil::swinstance");
   $swi->SetFilter({cistatusid=>\'4',applid=>\$rec->{id},
                 #   swnature=>["Oracle DB Server","MySQL","MSSQL","DB2",
                 #              "Informix","PostgreSQL"]
                    is_dbs=>1  # aus Workflow Request : 14273569140001
                   });
   foreach my $srec ($swi->getHashList(qw(admid))){
      if ($srec->{admid} ne ""){
         if (!in_array($a{dba}->{userid},$srec->{admid})){
            push(@{$a{dba}->{userid}},$srec->{admid});
         }
      }
   }

   #  add Lead Problem Manager from AEG Management based on 
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/13741398140002
   # modified by
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14074110550001
   my $aegm=getModuleObject($self->getParent->Config,"AL_TCom::aegmgmt");
   if (defined($aegm)){
      $aegm->SetFilter({id=>\$rec->{id}});
      my ($mgmtrec,$msg)=$aegm->getOnlyFirst(qw(leadprmmgrid leadinmmgrid));
      if (defined($mgmtrec)){
         if ($mgmtrec->{leadprmmgrid} ne ""){
            push(@{$a{leadprmmgr}->{userid}},$mgmtrec->{leadprmmgrid});
         }
         else{
            push(@{$a{leadprmmgr}->{userid}},14111237770001);
         }
         if ($mgmtrec->{leadinmmgrid} ne ""){
            push(@{$a{leadinmmgr}->{userid}},$mgmtrec->{leadinmmgrid});
         }
         else{
            push(@{$a{leadinmmgr}->{userid}},13581667950003);
         }
      }
   }

   # add Changemanager
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14074110550001
   my $chmm=getModuleObject($self->getParent->Config,"itil::chmmgmt");
   if (defined($chmm)){
      $chmm->SetFilter({id=>\$rec->{id}});
      my ($chmrec,$msg)=$chmm->getOnlyFirst(qw(chmgrfmbid));
      if (defined($chmrec)){
         if ($chmrec->{chmgrfmbid} ne ""){
            push(@{$a{chmmgr}->{userid}},$chmrec->{chmgrfmbid});
         }
         else{
            push(@{$a{chmmgr}->{userid}},13721598690001);
         }
      }
   }

   # add IT-SeM
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14074110550001
   my @sid=();
   foreach my $sysrec (@{$appl->getField("systems")->RawValue($rec)}){
      push(@sid,$sysrec->{systemid}); 
   }
   my $o=getModuleObject($self->getParent->Config,"itil::system");
   $o->SetFilter({id=>\@sid});
   my @co=$o->getVal("conumber");
   my $o=getModuleObject($self->getParent->Config,"itil::costcenter");
   $o->SetFilter({name=>\@co});
   foreach my $corec ($o->getHashList(qw(itsemid))){
      if ($corec->{itsemid} ne ""){
         if (!in_array($a{itsem}->{userid},$corec->{itsemid})){
            push(@{$a{itsem}->{userid}},$corec->{itsemid});
         }
      }
   }

   # add Capacitymanager
   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14074110550001
   if ($rec->{businessteamid} ne ""){
      my @uids=$user->getMembersOf($rec->{businessteamid},
                                   [qw(RCAOperator)],"firstup");
      foreach my $uid (@uids){
         push(@{$a{capmgr}->{userid}},$uid);
      }
   }
   

   foreach my $k (keys(%a)){  # fillup AEG
      next if ($k eq "AEG");
      foreach my $userid (@{$a{$k}->{userid}}){
         if (!in_array($a{AEG}->{userid},$userid)){
            push(@{$a{AEG}->{userid}},$userid);
         }
      }
   }


   my @chkuid;
   foreach my $r (values(%a)){
      @{$r->{userid}}=grep(!/^\s*$/,@{$r->{userid}});
      push(@chkuid,@{$r->{userid}});
   }
   $user->SetFilter({userid=>\@chkuid});
   $user->SetCurrentView(qw(phonename email));
   my $u=$user->getHashIndexed("userid");
   foreach my $k (keys(%a)){
      foreach my $userid (@{$a{$k}->{userid}}){
         push(@{$a{$k}->{email}},$u->{userid}->{$userid}->{email});
      }
      foreach my $userid (@{$a{$k}->{userid}}){
         push(@{$a{$k}->{phonename}},
              $u->{userid}->{$userid}->{phonename});
      }
   }

   return(\%a);
}

sub calcApplicationExpertGroup
{
   my $self=shift;
   my $rec=shift;

   my $appl=$self->getParent;
   my $aeg=$self->getField("baseaeg")->RawValue($rec);

   my $d="<table>";
   foreach my $aegtag (sort({$aeg->{$a}->{sindex}<=>$aeg->{$b}->{sindex}}
                       keys(%$aeg))){
      next if ($aegtag eq "AEG");
      my $arec=$aeg->{$aegtag};
      my $c="";
      if ($#{$arec->{userid}}!=-1){
         $d.="<tr><td valign=top><div><b>".$arec->{label}.":</b></div>\n".
             "<div>".$arec->{sublabel}."</div></td>\n";
         for(my $uno=0;$uno<=$#{$arec->{userid}};$uno++){
            $c.="\n--<br>\n" if ($c ne "");
            my @phone=split(/\n/,
                      quoteHtml($arec->{phonename}->[$uno]));
            my $htmlphone;
            for(my $l=0;$l<=$#phone;$l++){
               my $f=$phone[$l];
               if ($l==0){
                  $f="<a href='mailto:".
                     $arec->{email}->[$uno]."'>$f</a>";
                  $f.="<div style='visiblity:hidden;display:none'>\n".
                      $arec->{email}->[$uno]."</div>\n";
               }
               $f="<div>$f</div>\n";
               $htmlphone.=$f;
            }
            $c.=$htmlphone;
         }
         $d.="<td valign=top>".$c."</td></tr>\n";
      }
   }
   $d.="</table>";
   return($d);
}

sub calcWorkflowStart
{
   my $self=shift;
   my $r={};

   my %env=('frontendnew'=>'1');
   my $wf=getModuleObject($self->Config,"base::workflow");
   my @l=$wf->getSelectableModules(%env);

   if (grep(/^AL_TCom::workflow::diary$/,@l)){
      $r->{'AL_TCom::workflow::diary'}={
                                          name=>'Formated_appl'
                                       };
   }
   foreach my $wftype (grep(/^.*::workflow::riskmgmt$/,@l)){
      $r->{$wftype}={ name=>'Formated_affectedapplication' };
   }
   if (grep(/^itil::workflow::devrequest$/,@l)){
      $r->{'itil::workflow::devrequest'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   if (grep(/^itil::workflow::businessact$/,@l)){
      $r->{'itil::workflow::businessact'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   if (grep(/^itil::workflow::businesreq$/,@l)){
      $r->{'itil::workflow::businesreq'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   if (grep(/^itil::workflow::opmeasure$/,@l)){
      $r->{'itil::workflow::opmeasure'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   if (grep(/^AL_TCom::workflow::eventnotify$/,@l)){
      $r->{'AL_TCom::workflow::eventnotify'}={
                                          name=>'Formated_affectedapplication'
                                       };
   }
   return($r);
}

sub getSpecPaths
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::getSpecPaths($rec);
   push(@l,"TS/spec/TS.appl");
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my @l=$self->SUPER::isWriteValid(@_);
   if (grep(/^(technical|ALL)$/,@l)){
      push(@l,"inmchm","chm","inm");
   }
   return(@l);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec,@_);

   return(@l);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;

   if (effChanged($oldrec,$newrec,"ictoid")){
      my $ictoid=effVal($oldrec,$newrec,"ictoid");
      my $o=getModuleObject($self->Config,"tscape::archappl");
      if (!defined($o)){
         $self->LastMsg(ERROR,"unable to connect cape");
         return(undef);
      }
      if ($ictoid ne ""){
         $o->SetFilter({id=>\$ictoid});
         my ($archrec,$msg)=$o->getOnlyFirst(qw(archapplid));
         if (!defined($archrec)){
            $self->LastMsg(ERROR,"unable to identify archictecture record");
            return(undef);
         }
         $newrec->{ictono}=$archrec->{archapplid};
      }
      else{
         $newrec->{ictono}=undef;
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$orgrec));
}









1;
