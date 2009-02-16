package base::workflow;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=6;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   $self->setWorktable("wfhead");
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->{Action}=getModuleObject($self->Config,"base::workflowaction");
   return(undef) if (!defined($self->{Action}));
   $self->{use_distinct}=0;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'WorkflowID',
                htmldetail    =>0,
                sqlorder      =>'desc',
                size          =>'10',
                readonly      =>1,
                dataobjattr   =>'wfhead.wfheadid'),
                                  
      new kernel::Field::Text(
                name          =>'name',
                uivisible     =>\&isOptionalFieldVisible,
                label         =>'Short Description',
                htmlwidth     =>'350px',
                size          =>'20',
                selectfix     =>1,
                dataobjattr   =>'wfhead.shortdescription'),
                                   
      new kernel::Field::Text(
                name          =>'nature',
                htmldetail    =>0,
                htmlwidth     =>'200px',
                searchable    =>0,
                label         =>'Workflow nature',
                onRawValue    =>sub {
                                   my $self=shift;
                                   my $current=shift;
                                   my $nature=$self->getParent->T(
                                       $current->{class},$current->{class});
                                   return($nature);
                                },
                depend        =>['class']),
                                   
      new kernel::Field::Select(
                name          =>'prio',
                uivisible     =>\&isOptionalFieldVisible,
                label         =>'Prio',
                htmleditwidth =>'40px',
                htmlwidth     =>'10px',
                value         =>[qw(1 2 3 4 5 6 7 8 9 10)],
                default       =>5,
                dataobjattr   =>'wfhead.prio'),
                                   
      new kernel::Field::Link(
                name          =>'prioid',
                uivisible     =>0,
                label         =>'PrioID',
                dataobjattr   =>'wfhead.prio'),
                                   
      new base::workflow::Field::state(
                name          =>'state',
                htmldetail    =>0,
                selectfix     =>1,
                htmlwidth     =>'100px',
                label         =>'Workflow-State',
                htmleditwidth =>'50%',
                transprefix   =>'wfstate.',
                value         =>[qw(0 1 2 3 4 5 6 7 8 9 10 16 
                                    17 21 22 23 24 25 26)],
                readonly      =>1,
                dataobjattr   =>'wfhead.wfstate'),

      new kernel::Field::Interface(
                name          =>'posibleactions',
                label         =>'Posible actions',
                onRawValue    =>\&getPosibleActions,
                depend        =>['id']),
                                   
      new kernel::Field::Link(
                name          =>'stateid',         # for fast
                label         =>'Worflow state ID',
                selectfix     =>1,
                dataobjattr   =>'wfhead.wfstate'), # querys
                                   
      new base::workflow::Textarea(
                name          =>'detaildescription',     
                label         =>'Description',
                uivisible     =>\&isOptionalFieldVisible,
                selectfix     =>1,
                dataobjattr   =>'wfhead.description'),

      new base::workflow::sactions(
                name          =>'shortactionlog',
                searchable    =>0,
                label         =>'Short Actionlog',
                group         =>'flow',
                allowcleanup  =>1,
                uivisible     =>\&isOptionalFieldVisible,
                vjointo       =>'base::workflowaction',
                vjoinon       =>['id'=>'wfheadid'],
                vjoindisp     =>[qw(ascid cdate id name actionref
                                  translation owner additional
                                  effort comments creator)]),
                                   
      new kernel::Field::WorkflowRelation(
                name          =>'relations',
                searchable    =>0,
                label         =>'Relations',
                group         =>'relations',
                allowcleanup  =>1,
                uivisible     =>\&isOptionalFieldVisible,
               # vjointo       =>'base::workflowaction',
               # vjoinon       =>['id'=>'wfheadid'],
               # vjoindisp     =>[qw(cdate id name actionref
               #                   translation owner additional
               #                   effort comments)]
                ),
                                   
      new kernel::Field::Text(
                name          =>'class',
                selectfix     =>1,
                htmlwidth     =>'1%',
                group         =>'state',
                label         =>'Workflow-Class',
                size          =>'20',
                dataobjattr   =>'wfhead.wfclass'),

      new kernel::Field::KeyText(
                name          =>'mandator',
                keyhandler    =>'kh',
                group         =>'state',
                label         =>'Mandator'),

      new kernel::Field::KeyText(
                name          =>'mandatorid',
                keyhandler    =>'kh',
                selectfix     =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'state',
                label         =>'MandatorID'),

      new kernel::Field::MultiDst (
                name          =>'fwdtargetname',
                group         =>'state',
                htmlwidth     =>'450',
                htmleditwidth =>'400',
                label         =>'Forward to',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                dsttypfield   =>'fwdtarget',
                dstidfield    =>'fwdtargetid'),

      new kernel::Field::Link(
                name          =>'fwdtarget',   
                label         =>'Target-Typ',
                dataobjattr   =>'wfhead.fwdtarget'),

      new kernel::Field::Link(
                name          =>'fwdtargetid',
                dataobjattr   =>'wfhead.fwdtargetid'),

      new kernel::Field::Link(
                name          =>'fwddebtarget',   
                dataobjattr   =>'wfhead.fwddebtarget'),

      new kernel::Field::Link(
                name          =>'fwddebtargetid',
                dataobjattr   =>'wfhead.fwddebtargetid'),

      new kernel::Field::Date(
                name          =>'eventstart',
                selectfix     =>1,
                xlswidth      =>'18',
                htmlwidth     =>'80px',
                group         =>'state',
                label         =>'Event-Start',
                dataobjattr   =>'wfhead.eventstart'),

      new kernel::Field::Text(
                name          =>'eventstartday',
                htmldetail    =>0,
                readonly      =>0,
                searchable    =>0,
                group         =>'state',
                onRawValue    =>\&getEventDay,
                label         =>'Event-Start day',
                depend        =>['eventstart']),
                                  
      new kernel::Field::Link(
                name          =>'eventstartrev',
                label         =>'Event-Start reverse',
                sqlorder      =>'desc',
                dataobjattr   =>'wfhead.eventstart'),
                                  
      new kernel::Field::Date(
                name          =>'eventend',
                htmlwidth     =>'80px',
                xlswidth      =>'18',
                sqlorder      =>'desc',
                selectfix     =>1,
                group         =>'state',
                label         =>'Event-End',
                dataobjattr   =>'wfhead.eventend'),
                                   
      new kernel::Field::Text(
                name          =>'eventendday',
                htmldetail    =>0,
                readonly      =>0,
                searchable    =>0,
                group         =>'state',
                onRawValue    =>\&getEventDay,
                label         =>'Event-End day',
                depend        =>['eventend']),
                                  
      new kernel::Field::Duration(
                name          =>'eventduration',
                htmlwidth     =>'110px',
                htmldetail    =>'0',
                group         =>'state',
                label         =>'Event-Duration',
                depend        =>['eventstart','eventend']),
                                   
      new kernel::Field::Number(
                name          =>'documentedeffort',
                group         =>'state',
                htmldetail    =>0,
                searchable    =>0,
                unit          =>'min',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($self->getParent->isEffortReadAllowed($current)){
                      my $fobj=$self->getParent->getField("shortactionlog");
                      my $d=$fobj->RawValue($current);
                      my $dsum;
                      if (defined($d) && ref($d) eq "ARRAY"){
                         foreach my $arec (@{$d}){
                            if (defined($arec->{effort}) &&
                                $arec->{effort}!=0){
                               $dsum+=$arec->{effort};
                            }
                         }
                      }
                      return($dsum);
                   }
                   return(undef);
                },
                label         =>'sum documented efforts',
                depend        =>['shortactionlog','class','mandatorid']),
                                   
      new kernel::Field::Number(
                name          =>'documentedefforth',
                group         =>'state',
                htmldetail    =>0,
                searchable    =>0,
                precision     =>2,
                unit          =>'h',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   if ($self->getParent->isEffortReadAllowed($current)){
                      my $fobj=$self->getParent->getField("shortactionlog");
                      my $d=$fobj->RawValue($current);
                      my $dsum;
                      if (defined($d) && ref($d) eq "ARRAY"){
                         foreach my $arec (@{$d}){
                            if (defined($arec->{effort}) &&
                                $arec->{effort}!=0){
                               $dsum+=$arec->{effort};
                            }
                         }
                      }
                      return(undef) if ($dsum==0);
                      $dsum=$dsum/60.0;
                      return($dsum);
                   }
                   return(undef);
                },
                label         =>'sum efforts in hours',
                depend        =>['shortactionlog','class','mandatorid']),
                                   
      new kernel::Field::Duration(
                name          =>'eventdurationmin',
                htmlwidth     =>'100px',
                htmldetail    =>'0',
                group         =>'state',
                visual        =>'minutes',
                label         =>'Event-Duration Minutes',
                depend        =>['eventstart','eventend']),
                                   
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'state',
                label         =>'Modification-Date',
                dataobjattr   =>'wfhead.modifydate'),
                                   
      new kernel::Field::Date(
                name          =>'mdaterev',
                group         =>'state',
                sqlorder      =>'desc',
                uivisible     =>0,
                label         =>'Modification-Date reverse',
                dataobjattr   =>'wfhead.modifydate'),
                                   
      new kernel::Field::Text(
                name          =>'step',
                selectfix     =>1,
                group         =>'state',
                label         =>'Workflow-Step',
                size          =>'20',
                dataobjattr   =>'wfhead.wfstep'),

      new base::workflow::Field::initiallang(    
                searchable    =>0,
                uivisible     =>0,
                name          =>'initiallang',
                group         =>'initstate',
                label         =>'Initial-Lang',
                dataobjattr   =>'wfhead.initiallang'),

      new base::workflow::Field::initialsite(    
                searchable    =>0,
                uivisible     =>0,
                name          =>'initialsite',
                group         =>'initstate',
                label         =>'Initial-Site',
                dataobjattr   =>'wfhead.initialsite'),

      new base::workflow::Field::initialconfig(    
                searchable    =>0,
                uivisible     =>0,
                name          =>'initialconfig',
                group         =>'initstate',
                label         =>'Initial-Config',
                dataobjattr   =>'wfhead.initialconfig'),

      new base::workflow::Field::initialclient(    
                searchable    =>0,
                uivisible     =>0,
                name          =>'initialclient',
                group         =>'initstate',
                label         =>'Initial-Client',
                dataobjattr   =>'wfhead.initialclient'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'wfhead.srcsys'),
                                  
      new kernel::Field::Text(
                name          =>'srcid',
                selectfix     =>1,
                weblinkto     =>\&addSRCLinkToFacility,
                xlswidth      =>'18',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'wfhead.srcid'),
                                  
      new kernel::Field::Date(
                name          =>'srcload',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'wfhead.srcload'),
                                  
      new kernel::Field::CDate(
                name          =>'createdate',
                htmlwidth     =>'170px',
                group         =>'state',
                label         =>'Creation-Date',
                dataobjattr   =>'wfhead.opendate'),
                                  
      new kernel::Field::Date(
                name          =>'closedate',
                group         =>'state',
                label         =>'Close-Date',
                dataobjattr   =>'wfhead.closedate'),
                                  
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'state',
                label         =>'Editor',
                dataobjattr   =>'wfhead.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'state',
                label         =>'RealEditor',
                dataobjattr   =>'wfhead.realeditor'),

      new kernel::Field::Container(
                name          =>'headref',
                group         =>'headref', 
                label         =>'Workflow internel data',
                selectfix     =>1,
                uivisible     =>0,
                dataobjattr   =>'wfhead.headref'),

      new kernel::Field::Text(
                name          =>'directlnktype',
                group         =>'source',
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{directlnktype} ne "");
                   return(0);
                },
                label         =>'direct link type',
                dataobjattr   =>'wfhead.directlnktype'),

      new kernel::Field::Text(
                name          =>'directlnkid',
                group         =>'source',
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{directlnkid}!=0);
                   return(0);
                },
                label         =>'direct link ID',
                dataobjattr   =>'wfhead.directlnkid'),

      new kernel::Field::Text(
                name          =>'directlnkmode',
                group         =>'source',
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{directlnkmode} ne "");
                   return(0);
                },
                label         =>'direct link mode',
                dataobjattr   =>'wfhead.directlnkmode'),

      new kernel::Field::Container(
                name          =>'additional', #no search or key
                selectfix     =>1,
                label         =>'Additionalinformations',
                group         =>'source',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (defined($rec) && !defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'wfhead.additional'),

      new kernel::Field::Text(
                name          =>'openusername',
                weblinkto     =>'base::user',
                weblinkon     =>['openuser'=>'userid'],
                group         =>'state',
                label         =>'Creator Name',
                dataobjattr   =>'wfhead.openusername'),

#      new kernel::Field::Text(  # so wird das nichts
#                name          =>'responsibilityby',
#                group         =>'state',
#                label         =>'W5Stat Responsibility by',
#                onRawValue    =>\&calcResponsibilityBy,
#                depend        =>['fwdtargetid','fwdtarget']),

      new kernel::Field::Link(
                name          =>'openuser',
                group         =>'state',
                label         =>'Creator ID',
                dataobjattr   =>'wfhead.openuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'state',
                label         =>'Owner',
                dataobjattr   =>'wfhead.modifyuser'),

      new kernel::Field::KeyText(
                name          =>'responsiblegrp',
                htmldetail    =>0,
                keyhandler    =>'kh',
                group         =>'state',
                label         =>'Responsible Group'),

      new kernel::Field::KeyText(
                name          =>'responsiblegrpid',
                htmldetail    =>0,
                keyhandler    =>'kh',
                group         =>'state',
                label         =>'Responsible Group ID'),

      new kernel::Field::Date(
                name          =>'postponeduntil',
                searchable    =>0,
                depend        =>['stateid'],
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{stateid}==5);
                   return(0);
                },
                group         =>'state',
                label         =>'postponed until',
                container     =>'headref'),
                                  
      new kernel::Field::KeyHandler(
                name          =>'kh',
                label         =>'Key Handler',
                dataobjname   =>'w5base',
                extselect     =>{
                                   createdate=>'opendate',
                                   closedate =>'closedate',
                                   eventstart=>'eventstart',
                                   eventend  =>'eventend',
                                   class     =>'wfclass',
                                   stateid   =>'wfstate'
                                },
                tablename     =>'wfkey'),

      new kernel::Field::Dynamic(
                name          =>'wffields',
                searchable    =>0,
                label         =>'Workflow specific fields',
                fields        =>\&getDynamicFields)

   );
   $self->LoadSubObjs("workflow");
   $self->setDefaultView(qw(id class state name editor));
   $self->{ResultLineClickHandler}="Process";
   $self->{history}=[qw(insert modify delete)];

   return($self);
}

sub calcResponsibilityBy
{
   my $self=shift;
   my $current=shift;
   my $target=$current->{fwdtarget};
   my $targetid=$current->{fwdtargetid};
   return(undef) if ($target eq "" || $targetid eq "");
   my @resp=();
   my $u=$self->getParent->getPersistentModuleObject("UcalcResponsibilityBy",
                                                        "base::user");
   my $g=$self->getParent->getPersistentModuleObject("GcalcResponsibilityBy",
                                                        "base::grp");
   if ($target eq "base::user"){
      $u->SetFilter({userid=>\$targetid,cistatusid=>[3,4]});
      my ($rec,$msg)=$u->getOnlyFirst(qw(fullname groups));
      if (defined($rec)){
         push(@resp,"User: ".$rec->{fullname});
         foreach my $grprec (sort({$a->{group} cmp $b->{group}}
                                  @{$rec->{groups}})){
            if (grep(/^(RBoss|REmployee|RBoss2)$/,@{$grprec->{roles}})){
               push(@resp,"Group: ".$grprec->{group});
            }
         }
      }
   }
   if ($target eq "base::grp"){
      $g->SetFilter({grpid=>\$targetid,cistatusid=>[3,4]});
      my ($rec,$msg)=$u->getOnlyFirst(qw(fullname));
      if (defined($rec)){
         push(@resp,"Group: ".$rec->{fullname});
      }
   }
   push(@resp,"INVALID") if ($#resp==-1);

   return(\@resp);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_mdate"))){
      Query->Param("search_mdate"=>'>now-60m');
   }
}

sub getEventDay
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name;
   my $dep=$self->{depend}->[0];
   my $dd=$current->{$dep};
   if (my ($y,$m,$d)=$dd=~m/^(\d+)-(\d+)-(\d+)\s/){
      my $lang=$self->getParent->Lang();
      if ($lang eq "de"){
         $dd=sprintf("%02d.%02d.%04d",$d,$m,$y);
      }
      else{
         $dd=sprintf("%04d-%02d-%02d",$y,$m,$d);
      }
   }
   return($dd);
}


sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my $app=$self->getParent;
   my %param=@_;
   my $class=$param{current}->{class};
   my $name=$self->Name();
   return(1) if ($mode ne "HtmlDetail" && 
                 ($name eq "name"));
   if (!defined($app->{SubDataObj}->{$class})){
      return(1) if ($mode eq "SearchMask");
      return(1) if ($mode eq "ViewEditor");
      return(undef);
   }
   $param{field}=$self;
   return($app->{SubDataObj}->{$class}->isOptionalFieldVisible($mode,%param));
}

sub getSpecPaths
{
   my $self=shift;
   my $rec=shift;
   my $class=effVal(undef,$rec,"class");
   my $mod=$self->Module();
   my $selfname=$self->Self();
   $selfname=~s/::/./g;
   my @libs=("$mod/spec/$selfname");
   if (!defined($class)){
      $class=Query->Param("WorkflowClass");
   }
   if (defined($class)){
      my ($mod)=$class=~m/^([^:]+)::/;
      $class=~s/::/./g;
      push(@libs,"$mod/spec/$class");
   }
   return(@libs);
}



sub getRecordHtmlDetailHeader
{
   my $self=shift;
   my $rec=shift;
   my $H;

   my $class=effVal(undef,$rec,"class");
   if (!defined($class)){
      $class=Query->Param("WorkflowClass");
   }
   my $stateobj=$self->getField("state");
   my $state=$stateobj->FormatedDetail($rec);

   my $nameobj=$self->getField("name");
   my $name=$nameobj->FormatedDetail($rec);
   #if ($self->Config->Param("UseUTF8")){
   #   $name=utf8($name);
   #   $name=$name->latin1();
   #}

   my $statename=$self->T("State");

   my $wfname=$self->T($class,$class);
   $H=<<EOF;
<table width=100% height=100% border=0>
<tr><td align=left>
<p class=detailtoplineobj>$wfname:</p>
</td>
<td align=right width=1%><p class=detailtoplinename>$rec->{id}</p>
</td></tr>
<tr><td align=left valign=top>
<p class=detailtoplinename>$name</p>
</td>
<td colspan=2 align=left valign=top nowrap>
<p class=detailtoplinename>$statename: $state</p>
</td>
</tr>
</table>
EOF

  
   return($H);
}

sub getPosibleActions
{
   my $self=shift;
   my $current=shift;
   my @actions;
   if (defined($current->{id}) && $current->{id} ne ""){
      my $wf=$self->getParent->Clone();
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$current->{id}});
      my ($WfRec)=$wf->getOnlyFirst(qw(ALL));
      if (defined($WfRec)){
         my $class=$WfRec->{class};
         msg(INFO,"check of actions in $class");
         my $app=$self->getParent;
         if (defined($class) && defined($app->{SubDataObj}->{$class})){
            msg(INFO,"load posible actions from $class");
            @actions=$app->{SubDataObj}->{$class}->getPosibleActions($WfRec);
         }
      }
   }
   return(\@actions);
}


sub Action                 # to access base::workflowaction
{
   my $self=shift;

   return($self->{Action});
}

sub AddToWorkspace
{
   my $self=shift;
   my $wfid=shift;
   my $target=shift;
   my $targetid=shift;

   my $ws=$self->getPersistentModuleObject("base::workflowws");
   if (defined($ws) && $wfid=~m/^\d+$/ &&
       $target ne "" && $targetid ne ""){
      $ws->ValidatedInsertOrUpdateRecord({fwdtarget=>$target,
                                          fwdtargetid=>$targetid,
                                          wfheadid=>$wfid},
                                         {fwdtarget=>\$target,
                                          fwdtargetid=>\$targetid,
                                          wfheadid=>\$wfid});
      return(1);
   }
   return(0);
}

sub CleanupWorkspace
{
   my $self=shift;
   my $wfid=shift;

   my $ws=$self->getPersistentModuleObject("base::workflowws");
   if (defined($ws)){
      $ws->SetFilter({'wfheadid'=>\$wfid});
      $ws->SetCurrentView(qw(ALL));
      $ws->ForeachFilteredRecord(sub{
                         $ws->ValidatedDeleteRecord($_);
                      });
   }
}

sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $oldrec=$param{oldrec};
   my $newrec=$param{current};
   my $class=effVal($oldrec,$newrec,"class");

   if (!defined($class)){
      $class=Query->Param("WorkflowClass");
   }
   if (defined($class) && defined($self->getParent->{SubDataObj}->{$class})){
      my @subl=$self->getParent->{SubDataObj}->{$class}->getDynamicFields(
                                                                 %param);
      return(@subl);
   }
   return;
}

sub Main
{
   my $self=shift;

   if (!$self->IsMemberOf("admin")){
      print($self->noAccess());
      return(undef);
   }

   return($self->SUPER::Main(@_));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my %param=@_;


   my @addgroups=();
   if ($param{format} ne "kernel::Output::HtmlDetail"){
      @addgroups=qw(default state source initstate);
   }
   return("default","source","state") if (!defined($rec) || 
                         !defined($self->{SubDataObj}->{$rec->{class}}));
   my @grplist=(@addgroups,
                $self->{SubDataObj}->{$rec->{class}}->isViewValid($rec));
   return(@grplist);
}

sub InitCopy
{
   my ($self,$copyfrom,$copyinit)=@_;

   if (defined($copyfrom->{class}) &&
       defined($self->{SubDataObj}->{$copyfrom->{class}})){
      return($self->{SubDataObj}->{$copyfrom->{class}}->InitCopy(
                                                 $copyfrom,$copyinit));
   }
}

sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;

   if (defined($copyfrom->{class}) &&
       defined($self->{SubDataObj}->{$copyfrom->{class}})){
      return($self->{SubDataObj}->{$copyfrom->{class}}->isCopyValid(
                                                 $copyfrom));
   }
   return(undef);
}

sub getPosibleRelations
{
   my $self=shift;
   my $WfRec=shift;
   return     if (!defined($WfRec) || 
                  !defined($self->{SubDataObj}->{$WfRec->{class}}));
   return($self->{SubDataObj}->{$WfRec->{class}}->getPosibleRelations($WfRec,@_));
}


sub isEffortReadAllowed
{
   my $self=shift;
   my $WfRec=shift;
   return     if (!defined($WfRec) || 
                  !defined($self->{SubDataObj}->{$WfRec->{class}}));
   return($self->{SubDataObj}->{$WfRec->{class}}->isEffortReadAllowed($WfRec,@_));
}


sub addSRCLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   return("none",undef) if (!defined($current) || 
                 !defined($self->getParent->{SubDataObj}->{$current->{class}}));
   return($self->getParent->{SubDataObj}->{$current->{class}}->
            addSRCLinkToFacility($d,$current));

}

sub validateRelationWrite
{
   my $self=shift;
   my $WfRec=shift;
   return(undef,undef) if (!defined($WfRec) || 
                         !defined($self->{SubDataObj}->{$WfRec->{class}}));
   return($self->{SubDataObj}->{$WfRec->{class}}->validateRelationWrite($WfRec,@_));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return("default") if (!defined($rec) || 
                         !defined($self->{SubDataObj}->{$rec->{class}}));
   return($self->{SubDataObj}->{$rec->{class}}->isWriteValid($rec));
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef) if (!defined($rec) || 
                 !defined($self->{SubDataObj}->{$rec->{class}}));
   return($self->{SubDataObj}->{$rec->{class}}->isDeleteValid($rec));
}

sub allowAutoScroll
{
   my $self=shift;
   my $rec=shift;
   return(undef) if (!defined($rec) || 
                 !defined($self->{SubDataObj}->{$rec->{class}}));
   return($self->{SubDataObj}->{$rec->{class}}->allowAutoScroll($rec));
}

sub preValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec)){
      if ($W5V2::OperationContext eq "Kernel"){
      }
      elsif ($W5V2::OperationContext eq "QualityCheck"){
         if (!defined($newrec->{openuser})){
            $newrec->{openuser}=undef;
         }
         if (!defined($newrec->{openusername})){
            $newrec->{openusername}="QualityCheck";
         }
      }
      else{
         my $UserCache=$self->Cache->{User}->{Cache};
         my $mycontactid=$self->getCurrentUserId();;
         my $mycontactname;
         if (defined($UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname})){
            $mycontactname=$UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname};
         }
         if (defined($mycontactid)){
            $newrec->{openuser}=$mycontactid;
         }
         if (defined($mycontactname)){
            $newrec->{openusername}=$mycontactname;
         }
      }
   }
   my $class=defined($oldrec) && defined($oldrec->{class}) ? 
             $oldrec->{class} : $newrec->{class};
   $newrec->{class}=$class;  # ensure that class is in the newrec
   if (defined($self->{SubDataObj}->{$class})){
      return($self->{SubDataObj}->{$class}->preValidate($oldrec,$newrec,
                                                         $origrec));
   }
   return(1);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   #
   # global Workflow validation
   #
   if (!defined($oldrec) && !defined($newrec->{class})){
      $self->LastMsg(ERROR,"no worflow class specified");
      return(0);
   }
   if (defined($oldrec) && defined($newrec->{class}) &&
       $newrec->{class} ne $oldrec->{class}){
      $self->LastMsg(ERROR,
                     "worflow class can't be changed in existing workflow");
      return(0);
   }
   my $class=defined($oldrec) && defined($oldrec->{class}) ? 
             $oldrec->{class} : $newrec->{class};
   if (!defined($self->{SubDataObj}->{$class})){
      $self->LastMsg(ERROR,"invalid worflow class '%s' spezified",$class);
      return(0);
   }
   my $bk=$self->{SubDataObj}->{$class}->Validate($oldrec,$newrec,$origrec);
   if (!defined($oldrec)){
      if (!exists($newrec->{closedate})){
         $newrec->{closedate}=undef;
      }
      if (!exists($newrec->{eventend})){
         $newrec->{eventend}=undef;
      }
      if (!exists($newrec->{eventstart})){
         $newrec->{eventstart}=NowStamp("en");
      }
   }
   my $eventend=effVal($oldrec,$newrec,"eventend");
   my $eventstart=effVal($oldrec,$newrec,"eventstart");
   if ($eventend ne "" && $eventstart ne ""){
      my $duration=CalcDateDuration($eventstart,$eventend);
      if ($duration->{totalseconds}<0){
         $self->LastMsg(ERROR,"eventend can't be sooner as eventstart");
         my $srcid=effVal($oldrec,$newrec,"srcid");
         msg(ERROR,"totalseconds=$duration->{totalseconds} ".
                   "start=$eventstart end=$eventend srcid=$srcid");
         return(0);
      }
   }
   my $name=effVal($oldrec,$newrec,"name");
   if ($name=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid workflow short description spezified");
      return(0);
   }
   if ((defined($newrec->{fwdtarget}) && 
        effVal($oldrec,$newrec,"fwdtarget") ne $oldrec->{fwdtarget}) ||
       (defined($newrec->{fwdtargetid}) && 
        effVal($oldrec,$newrec,"fwdtargetid") ne $oldrec->{fwdtargetid})){
      # no the last responsegroup has to be posible changed
      my $fwdtargetid=effVal($oldrec,$newrec,"fwdtargetid");
      my $fwdtarget=effVal($oldrec,$newrec,"fwdtarget");
      if ($fwdtarget eq "base::grp"){
         my $grp=getModuleObject($self->Config,"base::grp");
         $grp->SetFilter({grpid=>\$fwdtargetid});
         my ($grprec)=$grp->getOnlyFirst(qw(fullname));
         if (defined($grprec)){
            $newrec->{responsiblegrp}=[$grprec->{fullname}];
            $newrec->{responsiblegrpid}=[$fwdtargetid];
         }
      }
      if ($fwdtarget eq "base::user"){
         my $user=getModuleObject($self->Config,"base::user");
         $user->SetFilter({userid=>\$fwdtargetid});
         my ($usrrec)=$user->getOnlyFirst(qw(groups));
         if (defined($usrrec) && ref($usrrec->{groups}) eq "ARRAY"){
            my %grp;
            my %grpid;
            foreach my $grec (@{$usrrec->{groups}}){
               if (ref($grec->{roles}) eq "ARRAY"){
                  if (grep(/^(REmployee|RBoss|RBoss2)$/,@{$grec->{roles}})){
                     $grp{$grec->{group}}++;
                     $grpid{$grec->{grpid}}++;
                  }
               }
            }
            if (keys(%grp)){
               $newrec->{responsiblegrp}=[keys(%grp)];
               $newrec->{responsiblegrpid}=[keys(%grpid)];
            }
         }
      }
   }
   return($bk);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $class;
   my $step;

   if (defined($oldrec)){
      $class=$oldrec->{class}; 
      $step=$oldrec->{step};
   }
   else{
      $class=$newrec->{class}; 
   }
   if (defined($newrec->{step})){
      $step=$newrec->{step};
   } 
   if (defined($class) && defined($step) && 
       defined($self->{SubDataObj}->{$class})){
      $self->{SubDataObj}->{$class}->FinishWrite($oldrec,$newrec);
   }
   ######################################################################
   #
   # cleanup workspace
   #
   my $stateid=effVal($oldrec,$newrec,"stateid");
   if ($stateid>=20 && $oldrec->{stateid}<20){
      $self->CleanupWorkspace($oldrec->{id});
   }
   ######################################################################

   return($self->SUPER::FinishWrite($oldrec,$newrec));
}



sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $class;
   my $step;

   if (defined($oldrec)){
      $class=$oldrec->{class}; 
      $step=$oldrec->{step};
      if (defined($class) && defined($step) && 
          defined($self->{SubDataObj}->{$class})){
         $self->{SubDataObj}->{$class}->FinishDelete($oldrec);
      }
   }
   return($self->SUPER::FinishDelete($oldrec));
}

sub getSubDataObjFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;
   my @fobjs;
   my $class;

   if (defined($param{current}) && defined($param{current}->{class})){
      $class=$param{current}->{class};
   }
   elsif (defined($param{oldrec}) && defined($param{oldrec}->{class})){
      $class=$param{oldrec}->{class};
   }
   else{
      $class=Query->Param("WorkflowClass");
   }
   return() if (!defined($class));

   foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
      next if (defined($class) && $class ne $SubDataObj);
      my $sobj=$self->{SubDataObj}->{$SubDataObj};
      if ($sobj->can("getFieldObjsByView")){
         push(@fobjs,$sobj->getFieldObjsByView($view,%param));
      }
   }
   return(@fobjs);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   my $class;

   if (defined($param{current}) && defined($param{current}->{class})){
      $class=$param{current}->{class};
   }
   elsif (defined($param{oldrec}) && defined($param{oldrec}->{class})){
      $class=$param{oldrec}->{class};
   }
   my @sub=();
   if (defined($class) && exists($self->{SubDataObj}->{$class})){
      @sub=$self->{SubDataObj}->{$class}->getDetailBlockPriority($grp,%param);
   }
   my @preblk=("header","default","flow");
   my @postblk=("source","initstate","state");
   foreach my $blk (@sub){
      @preblk=grep(!/^$blk$/,@preblk);
      @postblk=grep(!/^$blk$/,@postblk);
   }
   return(@preblk,@sub,@postblk);
}



sub getValidWebFunctions
{
   my $self=shift;
   return("Process","DirectAct","ShowState","FullView",
          $self->SUPER::getValidWebFunctions());
}


sub ShowState
{
   my $self=shift;
   my $func=$self->Query->Param("FUNC");
   
   if (defined(Query->Param("HTTP_ACCEPT_LANGUAGE"))){
      $ENV{HTTP_ACCEPT_LANGUAGE}=Query->Param("HTTP_ACCEPT_LANGUAGE");
   }
   my $wfstate=0;
   my ($wfheadid)=$func=~m/(\d+)$/;
   $wfheadid=~s/^0+//;
   if ($wfheadid ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$wfheadid});
      my ($wfrec,$msg)=$self->getOnlyFirst(qw(stateid));
      $wfstate=$wfrec->{stateid} if (defined($wfrec));
   }
   my $filename=$self->getSkinFile("base/img/wfstate$wfstate.gif");
   my %param;

   msg(INFO,"base::worflow ShowState func=$func id=$wfheadid wfstate=$wfstate filename=$filename");

   print $self->HttpHeader("image/gif",%param);
   if (open(MYF,"<$filename")){
      binmode MYF;
      binmode STDOUT;
      while(<MYF>){
         print $_;
      }
      close(MYF);
   }
}

sub getSelectableModules
{
   my $self=shift;
   my %env=@_;
   my @l=();
   foreach my $wfclass (keys(%{$self->{SubDataObj}})){
      next if (!$self->{SubDataObj}->{$wfclass}->IsModuleSelectable(\%env));
      push(@l,$wfclass);
   }
   return(@l);
}


sub New                   # Workflow starten
{
   my $self=shift;
   my $id=Query->Param("id");
   my $class=Query->Param("WorkflowClass");
   my @WorkflowStep=Query->Param("WorkflowStep");

   my $step;
   if (@WorkflowStep){
      $step=$WorkflowStep[$#WorkflowStep];
   }
   return($self->Process($class,$step)) if (defined($id));
   if (defined($class) && exists($self->{SubDataObj}->{$class})){
      return($self->Process($class,$step));
   }

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','workflow.css'],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1,
                           title=>'New Workflow Process');
   print $self->HtmlSubModalDiv();
   my %disp=();
   my $tips;
   my %env=('frontendnew'=>'1');
   foreach my $wfclass ($self->getSelectableModules(%env)){
      my $name=$self->{SubDataObj}->{$wfclass}->Label();
      $disp{$name}=$wfclass;
      my $tiptag=$wfclass."::tip";
      my $tip=$self->T($tiptag,$wfclass);
      if ($tiptag ne $tip){
         $tip="<b>Tip:</b> $tip";
      }
      else{
         $tip="<b>no Tip for $wfclass</b>";
      }
      $tip.="<br><br>";
      my $atitle=$self->T("New","kernel::DataObj").": ".
                 $self->T($wfclass,$wfclass);
#      my $a="<a href=\\\"$ENV{SCRIPT_URI}?WorkflowClass=$wfclass\\\" ".
#            "target=_blank title=\\\"$atitle\\\">".
#            "<img src=\\\"../../base/load/anker.gif\\\" border=0></a>";
      my $url=$ENV{SCRIPT_URI};
      $url=~s/\/auth\/.*$//;
      $url.="/auth/base/menu/msel/MyW5Base";
      my $openquery={OpenURL=>"$ENV{SCRIPT_URI}?WorkflowClass=$wfclass"};
      my $queryobj=new kernel::cgi($openquery);
      $url.="?".$queryobj->QueryString(); 
      my $a="<a href=\\\"$url\\\" ".
            "target=_blank title=\\\"$atitle\\\">".
            "<img src=\\\"../../base/load/anker.gif\\\" ".
            "height=10 border=0></a>";
      $tip.=sprintf($self->T("You can add a shortcut of this anker %s to ".
                    "your bookmarks, to access faster to this workflow."),$a);
      $tips.="tips['$wfclass']=\"$tip\";\n";
   }
   my $selbox="<select onchange=\"changetips();\" ".
              "size=5 id=class name=WorkflowClass class=newworkflow>";
   my $oldval=Query->Param("WorkflowClass");
   foreach my $name (sort(keys(%disp))){
      $selbox.="<option value=\"$disp{$name}\"";
      $selbox.=" selected" if ($disp{$name} eq $oldval);
      $selbox.=">$name</option>";
   }
   $selbox.="</select>";
   my $appheader=$self->getAppTitleBar();
   my $msg=$self->T("Please select the workflow to start:");
   my $start=$self->T("start workflow");
   print <<EOF;
<table width=100% height=100% border=0>
<tr height=1%><td>$appheader</td></tr>
<tr height=1%><td>$msg</td></tr>
<tr><td align=center valign=center>$selbox</td></tr>
<tr height=1%>
   <td align=right nowrap>
      <input type=submit value="$start" class=workflowbutton>&nbsp; 
   </td>
</tr>
<tr>
<td height=1% align=center valign=center>
<div class=newworkflowtip align=left id=tip>
</div>
</td>
</tr>
</table>
<script language=JavaScript>
function changetips()
{
   var cs=document.getElementById('class');
   var v=cs.options[cs.selectedIndex].value;
   var tip=document.getElementById('tip');
   var tips=new Object();

$tips

   tip.innerHTML=tips[v];
}
</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);

}

sub getWfRec
{
   my $self=shift;
   my $id=shift;
   my $WfRec;
   my $class;
   my $step;

   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my @l=$self->getHashList("ALL");
   $WfRec=$l[0];  # load from current
   my @WorkflowStep=Query->Param("WorkflowStep");
   if (@WorkflowStep &&
       (defined($WfRec) && $WorkflowStep[0] eq $WfRec->{step})){
      $step=$WorkflowStep[$#WorkflowStep];
   }
   else{
      $step=$WfRec->{step};
   }
   $class=$WfRec->{class};
   return($WfRec,$class,$step);
}

sub Process                   # Workflow bearbeiten
{
   my $self=shift;
   my $class=shift;
   my $step=shift;
   my $WfRec;

   my $id=Query->Param("id");
   if (defined($id)){   # Process old Workflow
      ($WfRec,$class,$step)=$self->getWfRec($id);
   }
   if (defined($self->{SubDataObj}->{$class})){
      my $bk=$self->{SubDataObj}->{$class}->Process($class,$step,$WfRec);
      return($bk);
   }
   my $output=new kernel::Output($self);
   my %param;
   $param{WindowMode}="Detail";
   if (!($output->setFormat("HtmlDetail",%param))){
      msg(ERROR,"can't set output format 'HtmlDetail'");
      return();
   }
   print $output->Format->getEmpty(HttpHeader=>1);
   return(undef);
}

sub Welcome 
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1,
                           title=>'MyW5Base');

   print $self->HtmlBottom(body=>1,form=>1);
}

sub DirectAct                        # Workflow User-View
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           body=>1,form=>1,
                           title=>'MyW5Base');
   my $id=Query->Param("id");
   print<<EOF;
<style>
body,form{
   margin:0;
   background-color:transparent;
   padding:0;
   border-width:0;
}
</style>
<input type=hidden name=DirectAction value="hit">
EOF
   if (Query->Param("DirectAction")){
      # process the direct action
   }
   my $state=Query->Param("state");
   my $class=Query->Param("class");
   printf("$state<br>\n");
   #printf("<select style=\"width:129px\" name=OP><option value=\"x\">[Aktion wählen]</option><option value=\"x\">freigeben</option></select>\n");
   foreach my $action (Query->Param("actions")){
      printf("<input type=submit style=\"width:100%%\" ".
            "name=$action value=\"%s\">",$self->T("DirectAction.".
            $action,$class));
   }
   print $self->HtmlPersistentVariables(qw(id state class actions));
   print $self->HtmlBottom(body=>1,form=>1);

}


sub getRecordImageUrl
{
   my $self=shift;
   my $current=shift;
   if (defined($current) && defined($current->{class}) &&
       defined($self->{SubDataObj}->{$current->{class}})){
      msg(INFO,"call getRecordImageUrl for $current->{class}");
      return($self->{SubDataObj}->{$current->{class}}->getRecordImageUrl(
             $current));
   }

   return($self->SUPER::getRecordImageUrl($current));
}



#
# Interface additional to DataObj Interface
#
sub Store
{
   my $self=shift;
   my $rec=shift;
   my $data;
   if (ref($_[0]) eq "HASH"){
      $data=$_[0];
   }
   else{
      $data={@_};
   }

   my $class;

   if (defined($rec)){
      if (ref($rec) ne "HASH"){
         $self->ResetFilter();
         $self->SetFilter({id=>$rec});
         my @l=$self->getHashList(qw(ALL));
         $rec=$l[0];
      }
      if (!defined($rec)){
         $self->LastMsg(ERROR,"can't StoreStep - desired record not found");
         return(undef);
      }
      $class=$rec->{class};
   }
   else{
      $class=$data->{class};
   }
   my $step=$data->{step};
   $step=$rec->{step} if (!defined($step));
   if (!defined($self->{SubDataObj}->{$class})){
      $self->LastMsg(ERROR,"StoreStep - create of invalid ".
                           "class '$class' requested");
      return(undef);
   }
   my $bk=$self->{SubDataObj}->{$class}->StoreRecord($rec,$step,$data);
   if ($bk){   # store new data in rec pointer for continius updates
      foreach my $k (keys(%$data)){
         $rec->{$k}=$data->{$k};
      }
   }
   return($bk);
}


#
# SOAP Interface connector
#
sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $id=shift;
   my $WfRec;
   my $class=$h->{class};
   my $step=$h->{step};
   if (defined($id)){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (!defined($rec)){
         $self->LastMsg(ERROR,"invalid workflow reference");
         return(undef);
      }
      $WfRec=$rec;
      $class=$WfRec->{class};
      $step=$WfRec->{step} if (!defined($step));
   }
   if (!defined($class)){
      $self->LastMsg(ERROR,"no class specified");
      return(undef);
   }
   if (!defined(defined($self->{SubDataObj}->{$class}))){
      $self->LastMsg(ERROR,"unknown class specified");
      return(undef);
   }
   my $classobj=$self->{SubDataObj}->{$class};
   if (!defined($step)){
      $step=$classobj->getNextStep(undef,undef);
      if (!defined($action) || $action eq ""){
         $action="NextStep";
      }
   }
   if (!defined($step)){
      $self->LastMsg(ERROR,"no step specified");
      return(undef);
   }
   if (!defined($action) || $action eq ""){
      $self->LastMsg(ERROR,"no action specified");
      return(undef);
   }
   msg(INFO,"request on class=$class step=$step");
   return($classobj->nativProcess($action,$h,$step,$WfRec));
}

sub ById
{
   my ($self)=@_;
   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $self->HtmlGoto("../Process",post=>{$idname=>$val});
   return();
}

sub getRecordHtmlIndex
{
   my $self=shift;
   my $rec=shift;
   my $id=shift;
   my $grouplist=shift;
   my $grouplabel=shift;
   my @indexlist;
   return();
}


sub getWriteRequestHash
{
   my $self=shift;
   my $h=$self->SUPER::getWriteRequestHash(@_);
   if (defined($h->{mandatorid})){
      my @curval=($h->{mandatorid});
      @curval=@{$h->{mandatorid}} if (ref($h->{mandatorid}) eq "ARRAY");
      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->ResetFilter();
      if (grep(/^all$/,@curval)){
         $mand->SetFilter({cistatusid=>[4]});
      }
      else{
         $mand->SetFilter({grpid=>\@curval,cistatusid=>[4]});
      }
      my @m=$mand->getHashList(qw(grpid name));
      if ($#m!=-1){
         $h->{mandatorid}=[map({$_->{grpid}} @m)];
         $h->{mandator}=[map({$_->{name}} @m)];
      }
      else{
         delete($h->{mandatorid});
         delete($h->{mandator});
      }
   }
   return($h);
}

sub DataObj_findtemplvar
{
   my $self=shift;
   my ($opt,$var,@param)=@_;
   my $fieldbase;

   if ($var eq "mandatorid" && $param[0] eq "detail"){
      shift(@param);
      my $mand=getModuleObject($self->Config,"base::mandator");
      my @sel;
      if ($param[0] eq "mode1" || $param[0] eq ""){ # eigene 1 ergebnis
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         $mand->ResetFilter();
         $mand->SetFilter({grpid=>\@mandators,cistatusid=>[4]});
      }
      if ($param[0] eq "mode2"){ # alle - eigener selected 1 ergebnis
         my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"write");
         $mand->ResetFilter();
         $mand->SetFilter({cistatusid=>[4]});
         $sel[0]=$mandators[0];
      }
      if ($param[0] eq "mode3"){ # alle - all selected 1 ergebnis
         $mand->ResetFilter();
         $sel[0]="all";
      }
      my @m=$mand->getHashList(qw(grpid name));
      my @fromq=Query->Param("Formated_$var");
      @sel=@fromq if ($#fromq!=-1);
      my $d="<select style=\"width:100%\" name=Formated_$var>";
      if ($param[0] eq "mode3"){
         $d.="<option value=\"all\">".$self->T("[all mandators]")."</option>";
      }
      foreach my $mrec (@m){
         $d.="<option value=\"$mrec->{grpid}\" ";
         $d.="selected" if ($#sel!=-1 && grep(/^$mrec->{grpid}$/,@sel));
         $d.=">".$mrec->{name}."</option>";
      }
      $d.="</select>";
      return($d);
   }
   if ($var eq "mandatorid" && $param[0] eq "storedworkspace"){
      my @curval=Query->Param("Formated_".$var);
      my $d;
      if ($#curval!=-1){
         my $mand=getModuleObject($self->Config,"base::mandator");
         $mand->ResetFilter(); 
         if (grep(/^all$/,@curval)){
            $mand->SetFilter({cistatusid=>[4]}); 
         }
         else{
            $mand->SetFilter({grpid=>\@curval,cistatusid=>[4]}); 
         }
         my @m=$mand->getHashList(qw(grpid name));
         $d.=join(", ",map({$_->{name}} @m));
      }
      foreach my $val (@curval){
         $d.="<input type=hidden name=Formated_$var value=\"$val\">";
      }
      return($d);
   }
   return($self->SUPER::DataObj_findtemplvar($opt,$var,@param));
}


package base::workflow::Field::state;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Select);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   if ($mode eq "HtmlV01"){
      my $class=$current->{class};
      my $app=$self->getParent;
      my @da=();
      if (defined($class)  && 
          defined($app->{SubDataObj}->{$class})){
         @da=$app->{SubDataObj}->{$class}->getPosibleDirectActions($current);
      }
      if ($#da!=-1){
         my $idobj=$self->getParent->IdField();
         my $idname=$idobj->Name();
         my $iddata=$idobj->RawValue($current);
         my $state=$self->SUPER::FormatedResult($current,$mode);
         my $cgi=new CGI({$idname=>$iddata,
                          state=>$state,
                          actions=>\@da,
                          class=>$class});
         my $qs=$cgi->query_string();
        
         return("<iframe border=0 frameborder=0 style=\"padding:2px\" ".
                "scrolling=no width=130 height=40 transparent ".
                "src=\"../workflow/DirectAct?$qs\">".
                "</iframe>");
      }
   }
   return($self->SUPER::FormatedResult($current,$mode));
}




package base::workflow::Field::initiallang;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Text);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return({$self->Name()=>$self->getParent->Lang()}) if (!defined($oldrec));

   return({});
}


package base::workflow::Field::initialsite;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Text);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $sitename=$ENV{SCRIPT_URI};
   $sitename=~s/\/auth\/.*?$//;
   $sitename=~s/\/public\/.*?$//;
   $sitename="JobServer" if (!defined($sitename));
   return({$self->Name()=>$sitename}) if (!defined($oldrec));

   return({});
}


package base::workflow::Field::initialconfig;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Text);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!defined($oldrec)){
      return({$self->Name()=>$self->getParent->Config->getCurrentConfigName()});   }
   return({});
}


package base::workflow::Field::initialclient;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Text);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $clientname=$ENV{REMOTE_ADDR};
   $clientname="127.0.0.1" if (!defined($clientname));
   return({$self->Name()=>$clientname}) if (!defined($oldrec));

   return({});
}

package base::workflow::sactions;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::SubList);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub EditProcessor
{
   my $self=shift;
   my $id=shift;
   return("");
}

sub getSubListData
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my %param=@_;

   $param{ParentMode}=$mode;
   $param{ShowEffort}=$self->getParent->isEffortReadAllowed($current);
   if ($mode=~m/^.{0,1}Html.*$/){
      $mode="WfShortActionlog";
   }
   return($self->SUPER::getSubListData($current,$mode,%param));
}




package base::workflow::Textarea;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Textarea);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $d=$current->{$self->{name}};

   if (defined($d) && $d=~m/^\[W5TRANSLATIONBASE=.*::.*\]$/m){
      my $dd;
      my $de;
      my $tbase=$self->getParent->Self;
      foreach my $line (split(/\n/,$d)){
         if (my ($newtbase)=$line=~m/^\[W5TRANSLATIONBASE=(.*::.*)]$/){
            $tbase=$newtbase;
         }
         else{
           my $pref;
           my $post;
           if (my ($newpref,$newline)=
                $line=~m/^([\s,\-,\!,\*]{1,3})(.*)$/){
              if (my ($t,$p)=$newline=~m/^(.*?)\s*:\s+(.*)$/){
                 $newline=$t;
                 $post=": ".$p;
              }
              $line=$newline;
              $pref=$newpref;
              
           }
           $dd.=$pref.$self->getParent->T($line,$tbase).$post."\n";
           $ENV{HTTP_FORCE_LANGUAGE}="en";
           $de.=$pref.$self->getParent->T($line,$tbase).$post."\n";
           delete($ENV{HTTP_FORCE_LANGUAGE});
         }
      }
      $d=$dd;
      if ($self->getParent->Lang() ne "en"){
         $d.="\n\n[en:]\n".$de;
      }
   }
   return($d);
}


1;
