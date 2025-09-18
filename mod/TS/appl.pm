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
      new kernel::Field::Interface(
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
                vjoininhash   =>['group','responsibility','id','parentobj'],
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
                name          =>'orgdomid',
                label         =>'Organisation Domain',
                htmldetail    =>0,
                group         =>'functional',
                vjointo       =>'TS::lnkorgdomappl',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'orgdomorgdomid'),

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
                vjointo       =>'TeamLeanIX::gov',
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

      new kernel::Field::Interface(
                name          =>'drc',
                group         =>'sodrgroup',
                label         =>'DR Class',
                htmldetail    =>0,
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
   my $applrec;

   my $appl=$self->getParent;

   my $addappl=$appl->Clone();
   $addappl->SetFilter({id=>\$rec->{id}});
   my ($applrec)=$addappl->getOnlyFirst(qw(name cistatusid opmode));
   

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
#            'itsem'=>{
#                userid=>[],
#                email=>[],
#                sindex=>$index++,
#                phonename=>[],
#                label=>"IT-Servicemanager"
#            },
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
            'StabilityOwner'=>{
                userid=>[],
                email=>[],
                sindex=>$index++,
                phonename=>[],
                label=>$self->getParent->T("Stability Owner",'TS::vou'),
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
                   leaderitid
                   leaderid
                   stabiownerid
      ));
      if (defined($vourec)){

         my $stabiownerid=$vourec->{stabiownerid};
         if (ref($stabiownerid) ne "ARRAY"){
            $stabiownerid=[$stabiownerid];
         }
         foreach my $uid (@{$stabiownerid}){
            if ($uid ne ""){
               push(@{$a{StabilityOwner}->{userid}},$uid);
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
            if (($m=~m/^DTAG\.GHQ\.VTI\.DTIT(\.|$)/i) &&
                $applrec->{cistatusid} eq "4" &&
                $applrec->{opmode} eq "prod"){ 
               push(@{$a{leadprmmgr}->{userid}},14111237770001);
            }
         }
         if ($mgmtrec->{leadinmmgrid} ne ""){
            push(@{$a{leadinmmgr}->{userid}},$mgmtrec->{leadinmmgrid});
         }
         else{
            if (($m=~m/^DTAG\.GHQ\.VTI\.DTIT(\.|$)/i) &&
                $applrec->{cistatusid} eq "4" &&
                $applrec->{opmode} eq "prod"){ 
               push(@{$a{leadinmmgr}->{userid}},13581667950003);
            }
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
            if (($m=~m/^DTAG\.GHQ\.VTI\.DTIT(\.|$)/i) &&
                $applrec->{cistatusid} eq "4" &&
                $applrec->{opmode} eq "prod"){ 
               push(@{$a{chmmgr}->{userid}},13721598690001);
            }
         }
      }
   }

#   # add IT-SeM
#   # https://darwin.telekom.de/darwin/auth/base/workflow/ById/14074110550001
#   my @sid=();
#   foreach my $sysrec (@{$appl->getField("systems")->RawValue($rec)}){
#      push(@sid,$sysrec->{systemid}); 
#   }
#   my $o=getModuleObject($self->getParent->Config,"itil::system");
#   $o->SetFilter({id=>\@sid});
#   my @co=$o->getVal("conumber");
#   my $o=getModuleObject($self->getParent->Config,"itil::costcenter");
#   $o->SetFilter({name=>\@co});
#   foreach my $corec ($o->getHashList(qw(itsemid))){
#      if ($corec->{itsemid} ne ""){
#         if (!in_array($a{itsem}->{userid},$corec->{itsemid})){
#            push(@{$a{itsem}->{userid}},$corec->{itsemid});
#         }
#      }
#   }

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
   $user->SetCurrentView(qw(phonename email cistatusid));
   my $u=$user->getHashIndexed("userid");
   foreach my $k (keys(%a)){

      for(my $c=0;$c<=$#{$a{$k}->{userid}};$c++){
         my $userid=$a{$k}->{userid}->[$c];
         if ($u->{userid}->{$userid}->{cistatusid}<3 ||
             $u->{userid}->{$userid}->{cistatusid}>5){
            $a{$k}->{userid}->[$c]=undef; 
         }
      }
      @{$a{$k}->{userid}}=grep({defined} @{$a{$k}->{userid}});

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

   if ((effVal($oldrec,$newrec,"ictoid") ne "" && 
       (defined($oldrec) && $oldrec->{ictono} eq "")) ||
       effChanged($oldrec,$newrec,"ictoid")){
      my $ictoid=effVal($oldrec,$newrec,"ictoid");
      my $o=getModuleObject($self->Config,"TeamLeanIX::gov");
      if (!defined($o)){
         $self->LastMsg(ERROR,"unable to connect T.EAM");
         return(undef);
      }
      if ($ictoid ne ""){
         $o->SetFilter({id=>\$ictoid});
         my ($archrec,$msg)=$o->getOnlyFirst(qw(ictoNumber));
         if (!defined($archrec)){
            $self->LastMsg(ERROR,"unable to identify archictecture record");
            return(undef);
         }
         $newrec->{ictono}=$archrec->{ictoNumber};
      }
      else{
         $newrec->{ictono}=undef;
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$orgrec));
}



sub getValidWebFunctions
{
   my $self=shift;

   my @l=$self->SUPER::getValidWebFunctions(@_);
   push(@l,"IdOrderValidate","NameSelector",
           "Analyse");
   return(@l);
}

sub NameSelector
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            name=>{
               typ=>'STRING',
               mandatory=>1,
               path=>0,
               init=>'w5'
            }
         },undef,\&doNameSelector,@_)
   );
}

sub IdOrderValidate
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            id=>{
               typ=>'STRING',
               mandatory=>1,
               path=>0,
               init=>'13736266300011'
            },
            dsid=>{
               typ=>'STRING'
            },
            email=>{
               typ=>'STRING'
            }
         },undef,\&doIdOrderValidate,@_)
   );
}

sub fltRulesOrderingAuthorized
{
   my $self=shift;
   my $applid=shift;
   my $param=shift;
   my $userid=shift;

   if ($param->{dsid} ne "" && !($param->{dsid}=~m/\@/)){
      my $dsidfilter=$param->{dsid};
      my $accountfilter=$param->{dsid};
      $accountfilter=~s/[\s"'\*\?]//;
      $accountfilter=~s/\\/\//;
      my @flt=();
      if (length($accountfilter)>3){
         push(@flt,{accounts=>$accountfilter,cistatusid=>[4,5]});
      }
      if ($dsidfilter=~m/^a[0-9]{3,10}$/i){
         $dsidfilter=~s/^a//i;
         $dsidfilter="tCID:".$dsidfilter;
         push(@flt,{dsid=>\$dsidfilter,cistatusid=>[4,5]});
      }
      if ($#flt!=-1){
         my $user=getModuleObject($self->Config,"base::user");
         $user->SetFilter(\@flt);
         my @l=$user->getHashList(qw(userid fullname));
         if ($#l==0){
            $userid->{$l[0]->{userid}}=$l[0]->{fullname}; 
         }
      }
   }
   return($self->SUPER::fltRulesOrderingAuthorized($applid,$param,$userid));
}


sub doIdOrderValidate
{
   my $self=shift;
   my $param=shift;
   my $r={};

   $self->ResetFilter();
   $self->SetFilter({id=>\$param->{id}});
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (($param->{id}=~m/^[0-9]{1,20}$/) && defined($rec)){
      my $id=$param->{id};
      $r->{data}={
         name=>$rec->{name}, 
         conumber=>$rec->{conumber}, 
         cistatusid=>$rec->{cistatusid}, 
         mandator=>$rec->{mandator}, 
         customer=>$rec->{customer},
         opmode=>$rec->{opmode},
         applmgrid=>$rec->{applmgrid},
         tsm2id=>$rec->{tsm2id},
         tsmid=>$rec->{tsmid} 
      };
      if ($rec->{cistatusid} eq "3" || $rec->{cistatusid} eq "4"){
         $r->{orderPosible}="true";
      }
      else{
         $r->{orderPosible}="false";
      }
      $r->{orderAllowed}="false";

      my ($uref,$orderAllowed)=$self->validateOrderingAuthorized($id,$param);
      if ($orderAllowed){
         $r->{orderAllowed}="true";
      }
      if (defined($uref) && ref($uref) eq "HASH"){
         $r->{userReference}=$uref;
      }
   }
   else{
      return({
         exitcode=>100,
         exitmsg=>'invalid id'
      });
   }

   
   return({
      result=>$r,
      exitcode=>0,
      exitmsg=>'OK'
   });
}

sub doNameSelector
{
   my $self=shift;
   my $param=shift;
   my $r={};
   my $limit=50;

   $param->{name}=~s/[\*\s\?,'"]//g;

   if (length($param->{name})<2){
      return({
         exitcode=>100,
         exitmsg=>"'name' filter not specific enough"
      });
   }

   $self->ResetFilter();
   $self->SetFilter({name=>"*".$param->{name}."*",cistatusid=>[3,4,5]});
   $self->Limit($limit+1);
   my @l=$self->getHashList(qw(name id cistatusid urlofcurrentrec 
                               customer mandator));
   
   $r->{data}=\@l;
   if ($#l>=$limit){
      $r->{ResultIncomplete}=1;
      $r->{data}=[@l[0..($limit-1)]];
   }
   return({
      result=>$r,
      exitcode=>0,
      exitmsg=>'OK'
   });
}


sub Analyse
{
   my $self=shift;

   return(
      $self->simpleRESTCallHandler(
         {
            query=>{
               typ=>'STRING',
               path=>0,
               init=>'APPL609531'
            },
            applid=>{
               typ=>'STRING',
            },
            name=>{
               typ=>'STRING',
            }
         },undef,\&doAnalyse,@_)
   );
}

sub doAnalyse
{
   my $self=shift;
   my $q=shift;

   my @indication;
   my $ipflt={};
   my %userid;
   my $userid;
   my @cadmin;
   my @tadmin;
   my %cadmin;
   my %tadmin;
   my @refurl;
   my @applcadminfields=qw(applmgrid);
   my @appltadminfields=qw(tsmid tsm2id opmid opm2id);
   my $notes;
   my %networks;
   my $r={};

   #print STDERR Dumper($q);
   my @cflt;
   if (exists($q->{query}) && $q->{query} ne ""){
      my $f1={cistatusid=>[3,4],applid=>[$q->{query}]};
      my $f2={cistatusid=>[3,4],name=>[$q->{query}]};
      push(@cflt,$f1,$f2);
   }
   else{
      if ((exists($q->{name}) && $q->{name} ne "") ||
          (exists($q->{applid}) && $q->{applid} ne "")){
         my $f1={cistatusid=>[3,4]};
         push(@cflt,$f1);
      }
      else{
         my $f1={id=>[-1]};
         push(@cflt,$f1);
      }
   }
   foreach my $flt (@cflt){
      if (exists($q->{name}) && $q->{name} ne ""){
         $flt->{name}=[$q->{name}]
      }
      if (exists($q->{applid}) && $q->{applid} ne ""){
         $flt->{applid}=[$q->{applid}]
      }
   }

   $self->ResetFilter();
   $self->SetFilter(\@cflt);


   my @l=$self->getHashList(qw(
      id applid name systems
   )); 

   my %applid;
   my %systemid;
   foreach my $rec (@l){
      if (ref($r->{applications}) ne "ARRAY"){
         $r->{applications}=[];
      }
      push(@{$r->{applications}},{
         name=>$rec->{name},
         applid=>$rec->{applid}
      });
      if ($rec->{id} ne ""){
         $applid{$rec->{id}}++;
      }
      foreach my $sysrec (@{$rec->{systems}}){
         $systemid{$sysrec->{systemid}}++;
      }
   }

   my @criticality;
   my @ictono;
   my %opmode;
   my @related;

   $self->finalizeAnalysedContacts(
      [keys(%applid)],
      [keys(%systemid)],
      \%userid,
      \@indication,
      \@cadmin,
      \@tadmin,
      \@criticality,
      \@ictono,
      \@refurl,
      \%opmode,
      \@related
   );

   if ($#indication!=-1){
      $r->{indication}=\@indication;
   }
   if ($#cadmin!=-1){
      $r->{'Admin-C'}=\@cadmin;
   }
   if ($#tadmin!=-1){
      $r->{'Tech-C'}=\@tadmin;
   }
   if ($#refurl!=-1){
      $r->{refurl}=\@refurl;
   }
   if ($#ictono!=-1){
      $r->{ictono}=\@ictono;
   }
   if ($#criticality!=-1){
      $r->{criticality}=$criticality[0];
   }
   if (keys(%opmode)){
      $r->{opmode}=\%opmode;
   }
   if ($#related!=-1){
      $r->{related}=\@related;
   }
   if ($notes ne ""){
      $r->{notes}=$notes;
   }
   
   return({
      result=>$r,
      exitcode=>0,
      exitmsg=>'OK'
   });
}










1;
