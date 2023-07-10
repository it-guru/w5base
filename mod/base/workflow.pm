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
use Digest::MD5 qw(md5_base64);
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=7;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5base"));
   $self->setWorktable("wfhead");
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->{Action}=getModuleObject($self->Config,"base::workflowaction");
   return(undef) if (!defined($self->{Action}));
   $self->{use_distinct}=1;

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                nowrap        =>1,
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'WorkflowID',
                htmldetail    =>0,
                nowrap        =>1,
                searchable    =>1,
                sqlorder      =>'desc',
                size          =>'10',
                readonly      =>1,
                dataobjattr   =>'wfhead.wfheadid'),

      new kernel::Field::RecordUrl(),
                                  
      new kernel::Field::Text(
                name          =>'name',
                htmldetail    =>\&isOptionalFieldVisible,
                label         =>'Short Description',
                htmlwidth     =>'350px',
                size          =>'20',
                prepRawValue  =>\&camuflageOptionalField,
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
                                   
      new kernel::Field::Number(
                name          =>'urcencyindex',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'urgency index',
                htmlwidth     =>'10px',
                unit          =>'1-1000 calculated',
                sqlorder      =>'desc',
                dataobjattr   =>'if ('.
                '(datediff(curdate(),wfhead.eventstart)/30)*'.
                '(10*(10-wfhead.prio))'.
                '>1000,1000,'.
                '(datediff(curdate(),wfhead.eventstart)/30)*'.
                '(10*(10-wfhead.prio)))'),
                                   
      new base::workflow::Field::state(
                name          =>'state',
                htmldetail    =>0,
                htmltablesort =>'Number',
                selectfix     =>1,
                htmlwidth     =>'100px',
                label         =>'Workflow-State',
                htmleditwidth =>'50%',
                transprefix   =>'wfstate.',
                value         =>[qw(0 1 2 3 4 5 6 7 8 9 10 11 12 16 
                                    17 18 21 22 23 24 25 26)],
                readonly      =>1,
                dataobjattr   =>'wfhead.wfstate'),

      new kernel::Field::Interface(
                name          =>'posibleactions',
                label         =>'Possible actions',
                WSDLfieldType =>'ArrayOfStringItems',
                onRawValue    =>\&getPosibleActions,
                depend        =>['id']),
                                   
      new kernel::Field::Interface(
                name          =>'stateid',         # for fast
                label         =>'Workflow state ID',
                selectfix     =>1,
                dataobjattr   =>'wfhead.wfstate'), # querys
                                   
      new base::workflow::Textarea(
                name          =>'detaildescription',     
                label         =>'Description',
                htmldetail    =>\&isOptionalFieldVisible,
                selectfix     =>1,
                dataobjattr   =>'wfhead.description'),

      new base::workflow::sactions(
                name          =>'shortactionlog',
                searchable    =>0,
                label         =>'Short Actionlog',
                group         =>'flow',
                allowcleanup  =>1,
                htmldetail    =>\&isOptionalFieldVisible,
                vjointo       =>'base::workflowaction',
                vjoinon       =>['id'=>'wfheadid'],
                vjoindisp     =>[qw(ascid cdate id name actionref
                                  translation owner additional
                                  effort comments creator
                                  intiatornotify)]),
                                   
      new kernel::Field::Textarea(
                name          =>'lateststate',
                searchable    =>0,
                label         =>'latest state',
                group         =>'flow',
                htmldetail    =>0,
                depend        =>['shortactionlog'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;

                   my $fobj=$self->getParent->getField("shortactionlog");
                   my $d=$fobj->RawValue($current);
                   my $state;
                   if (defined($d) && ref($d) eq "ARRAY"){
                      foreach my $arec (reverse(@{$d})){
                         if ($arec->{comments} ne ""){
                            $state=$arec->{comments};
                            my $owner=$arec->{owner};
                            if ($owner ne ""){
                               my $user=getModuleObject(
                                        $self->getParent->Config,"base::user"); 
                               $user->SetFilter({userid=>\$owner});
                               my ($actu,$msg)=$user->getOnlyFirst("purename");
                               if (defined($actu)){
                                  $owner=$actu->{purename};
                               }
                            }
                            $state.="\n... by $owner" if ($owner ne "");
                            last;
                         }
                      }
                   }
                   return($state) if (defined($state));;
                   return($self->getParent->T("no action log entry"));
                }),

                                   
      new base::workflow::WorkflowRelation(
                name          =>'relations',
                searchable    =>0,
                label         =>'Relations',
                group         =>'relations',
                allowcleanup  =>1,
                htmldetail    =>\&isOptionalFieldVisible),
                                   
      new kernel::Field::Boolean(
                name          =>'isdeleted',
                selectfix     =>1,
                htmlwidth     =>'1%',
                htmldetail    =>0,
                uploadable    =>0,
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent;
                   return(0) if (defined($current) &&
                                 $app->IsMemberOf("admin"));
                   return(0) if ($app->isMarkDeleteValid($current));
                   return(1);
                },
                group         =>'state',
                label         =>'marked as delete',
                dataobjattr   =>'wfhead.is_deleted'),

      new kernel::Field::Text(
                name          =>'class',
                selectfix     =>1,
                htmlwidth     =>'1%',
                xlswidth      =>'25',
                group         =>'state',
                label         =>'Workflow-Class',
                size          =>'30',
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

      new kernel::Field::Text(
                name       =>'involvedcustomer',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Customer'),

      new kernel::Field::Text(
                name       =>'involvedcustomerid',
                htmldetail =>0,
                searchable =>0,
                container  =>'headref',
                group      =>'affected',
                label      =>'Involved Customer'),

      new kernel::Field::MultiDst (
                name          =>'fwdtargetname',
                group         =>'state',
                htmlwidth     =>'280',
                htmleditwidth =>'400',
                label         =>'Forward to',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                vjoineditbase =>[{cistatusid=>"<5"},
                                 {cistatusid=>"<5"}],
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
                searchable    =>0,
                htmldetail    =>0,
                group         =>'state',
                dataobjattr   =>'wfhead.eventstart'),
                                  
      new kernel::Field::Date(
                name          =>'eventend',
                htmlwidth     =>'80px',
                xlswidth      =>'18',
                sqlorder      =>'desc',
                selectfix     =>1,
                htmldetail    =>'NotEmpty',
                group         =>'state',
                label         =>'Event-End',
                dataobjattr   =>'wfhead.eventend'),
                                   
      new kernel::Field::Date(
                name          =>'eventendrev',
                htmldetail    =>0,
                searchable    =>0,
                group         =>'state',
                label         =>'Event-End reverse',
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

      new kernel::Field::TRange(
                name          =>'trange',
                group         =>'state',
                label         =>'Event time window',
                depend        =>[qw(ranges rangem rangee)]),

      new kernel::Field::Date(
                name          =>'ranges',
                noselect      =>'1',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                group         =>'state',
                label         =>'Range Start only',
                dataobjattr   =>'wfrange.s'),

      new kernel::Field::Date(
                name          =>'rangem',
                noselect      =>'1',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                group         =>'state',
                label         =>'Range middle',
                dataobjattr   =>'wfrange.m'),

      new kernel::Field::Date(
                name          =>'rangee',
                noselect      =>'1',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                group         =>'state',
                label         =>'Range End only',
                dataobjattr   =>'wfrange.e'),



                                  
      new kernel::Field::Date(
                name          =>'invoicedate',
                htmlwidth     =>'80px',
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{stateid}>15);
                   return(0);
                },
                xlswidth      =>'18',
                group         =>'state',
                label         =>'invoice date',
                dataobjattr   =>'wfhead.invoicedate'),
                                   
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

      new kernel::Field::Percent(
                name          =>'attainment',
                label         =>'attainment level',
                group         =>'state',
                align         =>'right',
                htmldetail    =>0,
                searchable    =>0,
                precision     =>0,
                depend        =>['stateid','headref','shortactionlog'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $headref=$self->getParent->
                                      getField("headref")->RawValue($current);
                   my $p=0;
                   if ($current->{stateid}>1){
                      $p=1;
                   }
                   if ($current->{stateid}>3){
                      $p=10;
                   }
                   if (exists($headref->{implementationeffort})){
                      my $ie=$headref->{implementationeffort};
                      $ie=$ie->[0] if (ref($ie) eq "ARRAY");
                      my $target; 
                      if (my ($a)=$ie=~
                          m/^[\<\>]{0,1}(\d+([,\.]\d{1,2}){0,1})$/){
                         $a=~s/,/./g;
                         $target=$a;
                      }
                      elsif (my ($a,$a1,$b,$b1)=$ie=~
                        m/^(\d+([,\.]\d{1,2}){0,1})-(\d+([,\.]\d{1,2}){0,1})$/){
                         $a=~s/,/./g;
                         $b=~s/,/./g;
                         $target=($a+$b)/2;
                      }
                      if (defined($target) && $target>0){
                         my $fobj=$self->getParent->getField("shortactionlog");
                         my $d=$fobj->RawValue($current);
                         my $dsum=0;
                         if (defined($d) && ref($d) eq "ARRAY"){
                            foreach my $arec (@{$d}){
                               if (defined($arec->{effort}) &&
                                   $arec->{effort}!=0){
                                  $dsum+=$arec->{effort};
                               }
                            }
                         }
                         if ($dsum>0){
                            $dsum=$dsum/60.0;
                            $p=$dsum*100.0/$target;
                         }
                      }
                   }
                   if ($current->{stateid}>15){
                      $p=100;
                   }
                   return($p);
                }),
                                   
      new kernel::Field::Duration(
                name          =>'eventdurationmin',
                htmlwidth     =>'100px',
                htmldetail    =>'0',
                group         =>'state',
                visual        =>'minutes',
                label         =>'Event-Duration Minutes',
                depend        =>['eventstart','eventend']),

      new kernel::Field::Duration(
                name          =>'eventdurationhour',
                htmlwidth     =>'100px',
                htmldetail    =>'0',
                group         =>'state',
                visual        =>'hours',
                label         =>'Event-Duration Hours',
                depend        =>['eventstart','eventend']),

      new kernel::Field::MDate(
                name          =>'mdate',
                selectfix     =>1,
                group         =>'state',
                label         =>'Modification-Date',
                dataobjattr   =>'wfhead.modifydate'),
                                   
      new kernel::Field::Date(
                name          =>'mdaterev',
                group         =>'state',
                sqlorder      =>'desc',
                uivisible     =>0,
                htmldetail    =>0,
                group         =>'state',
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

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"wfhead.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(wfhead.wfheadid,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'wfhead.srcsys'),
                                  
      new kernel::Field::Text(
                name          =>'srcid',
                selectfix     =>1,
                weblinkto     =>\&addSRCLinkToFacility,
                htmldetail    =>'NotEmpty',
                xlswidth      =>'18',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'wfhead.srcid'),
                                  
      new kernel::Field::Date(
                name          =>'srcload',
                sqlorder      =>'desc',
                htmldetail    =>'NotEmpty',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'wfhead.srcload'),
                                  
      new kernel::Field::CDate(
                name          =>'createdate',
                htmlwidth     =>'170px',
                selectfix     =>1,
                group         =>'state',
                label         =>'Creation-Date',
                dataobjattr   =>'wfhead.opendate'),
                                  
      new kernel::Field::Date(
                name          =>'closedate',
                group         =>'state',
                htmldetail    =>'NotEmpty',
                label         =>'Close-Date',
                dataobjattr   =>'wfhead.closedate'),
                                  
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'state',
                label         =>'Editor Account',
                dataobjattr   =>'wfhead.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'state',
                label         =>'real Editor Account',
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
                selectfix     =>1,
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
                selectfix     =>1,
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
                selectfix     =>1,
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
                htmlwidth     =>'280',
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

      new kernel::Field::Link(
                name          =>'md5sechash',
                group         =>'state',
                label         =>'MD5 security hash',
                dataobjattr   =>'wfhead.md5sechash'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'state',
                label         =>'last Editor',
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
                dayonly       =>2,
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
                                  
      new kernel::Field::Boolean(
                name          =>'W5StatNotRelevant',
                searchable    =>0,
                htmldetail    =>0,
                uivisible     =>0,
                group         =>'state',
                label         =>'not relevant for w5stat',
                container     =>'headref'),
                                  
      new kernel::Field::Text(
                name          =>'autocopymode',
                searchable    =>0,
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{autocopymode} ne "");
                   return(0);
                },
                group         =>'state',
                label         =>'auto copy mode',
                dataobjattr   =>'wfhead.acopymode'),

      new kernel::Field::SubList(
                name          =>'individualAttr',
                label         =>'individual attributes',
                group         =>'individualAttr',
                allowcleanup  =>1,
                forwardSearch =>1,
                htmldetail    =>'NotEmpty',
                vjointo       =>'base::grpindivworkflow',
                vjoinon       =>['id'=>'srcdataobjid'],
                vjoindisp     =>['fieldname','indivfieldvalue']),
                                  
      new kernel::Field::Date(
                name          =>'autocopydate',
                searchable    =>0,
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{autocopymode} ne "");
                   return(0);
                },
                group         =>'state',
                label         =>'last workflow copy at',
                dataobjattr   =>'wfhead.acopydate'),

      new kernel::Field::KeyHandler(
                name          =>'kh',
                label         =>'Key Handler',
                dataobjname   =>'w5base',
                extselect     =>{
                                   trange=>'wfrange',
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
                fields        =>\&getDynamicFields),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
   );
   $self->LoadSubObjsOnDemand("workflow");
   $self->setDefaultView(qw(id class state name editor));
   $self->{ResultLineClickHandler}="Process";
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{individualAttr}={
      dataobj=>'base::grpindivworkflow'
   };
   return($self);
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
   $val="UNDEF" if ($val eq "");
   $self->HtmlGoto("../Process",post=>{$idname=>$val});
   return();
}



sub isAnonymousAccessValid
{
    my $self=shift;
    my $method=shift;
    return(1) if ($method eq "ShowState");
    return(0);
}




sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();


   if ($mode eq "select"){
      my $rangefilter=0;
      foreach my $filter (@filter){
         if (ref($filter) eq "HASH" && 
             in_array([keys(%$filter)],[qw(ranges rangem rangee)])){
            $rangefilter++;
         }
         if (ref($filter) eq "ARRAY"){
            foreach my $filter (@$filter){
               if (ref($filter) eq "HASH" && 
                  in_array([keys(%$filter)],[qw(ranges rangem rangee)])){
                 $rangefilter++;
               }
            }
         }
      }
      if ($rangefilter){
         $worktable.=" join wfrange on wfhead.wfheadid=wfrange.wfheadid";
      }
   }



   return($worktable);
}


sub HtmlStatSetList
{
   my $self=shift;
   my $mode=shift;

   my $s={ default=>'nix',
           set=>{
                 byfwdtarget=>{
                    label=>'Hans',
                    header=>'This is the hans chart',
                    bottom=>'This is the hans bottom',
                    view=>['nature','fwdtarget','cistatus'],
                    aggregation=>'count'}
                }
         };
   return($s);
}



sub isMarkDeleteValid
{
   my $self=shift;
   my $rec=shift;
   my $class=$rec->{class};

   if (!defined($self->{SubDataObj}->{$class})){
      $class="base::workflow::Archive";
   }
   if (defined($self->{SubDataObj}->{$class})){
      return($self->{SubDataObj}->{$class}->isMarkDeleteValid($rec));
   }
   return(0);
}

sub getDetailFunctions
{
   my $self=shift;
   my $rec=shift;
   my @f;
   if (defined($rec) && $self->isMarkDeleteValid($rec)){
      if (!$rec->{isdeleted}){
         unshift(@f,$self->T("DetailMarkDelete")=>"DetailMarkDelete");
      }
      else{
         unshift(@f,$self->T("DetailUnMarkDelete")=>"DetailUnMarkDelete");
      }
   }
   return(@f);
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
   if (!defined(Query->Param("search_isdeleted"))){
      Query->Param("search_isdeleted"=>$self->T("no"));
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


sub camuflageOptionalField
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   my $ap=$self->getParent();
   return($d) if (!defined($current));
   my $class=$current->{class};
   return($d) if (!defined($ap->{SubDataObj}->{$class}));
   return($d) if (!$ap->{SubDataObj}->{$class}->can("camuflageOptionalField")); 
   return(
      $ap->{SubDataObj}->{$class}->camuflageOptionalField($self,$d,$current)
   );
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
   if ($name eq "shortactionlog"){
      return(1) if ($mode ne "HtmlDetail");
      if (defined($param{current}) && 
          defined($param{current}->{shortactionlog}) &&
          ref($param{current}->{shortactionlog}) eq "ARRAY" &&
          $#{$param{current}->{shortactionlog}}!=-1){
         return(1);
      }
   }
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
   my $current=shift;
   my $H;

   my $class=effVal(undef,$current,"class");
   if (!defined($class)){
      $class=Query->Param("WorkflowClass");
   }
   my $stateobj=$self->getField("state");
   my $state=$stateobj->FormatedDetail($current);

   my $nameobj=$self->getField("name");
   my $name=$nameobj->FormatedDetail($current);
   #if ($self->Config->Param("UseUTF8")){
   #   $name=utf8($name);
   #   $name=$name->latin1();
   #}

   my $statename=$self->T("State");

   my $wfname=$self->T($class,$class);
   my $statedisplay="";
   if (my $fld=$self->getField("dataissuestate")){
      $statedisplay=$fld->FormatedDetail($current,"HtmlDetail");
   }
   my $delstate="";
   if ($current->{isdeleted}){
      $delstate="<p><font size=+1><blink><b>".$self->T("deleted").
                ":</b></blink></font></p>";
   }
   $wfname=~s/%/\\%/g;
   $name=~s/%/\\%/g;
   $H.=<<EOF;
<table width="100%" height="100%" border=0>
<tr><td align="left">
<h1 class=detailtoplineobj>$wfname:</h1>
</td>
<td align=right width="1%">$delstate<p class=detailtoplinename>$current->{id}</p>
</td></tr>
<tr><td align="left" valign="top">
<h2 class=detailtoplinename>$name</h2>
$statedisplay
</td>
<td colspan=2 align=left valign=top nowrap>
<h2 class=detailtoplinename>$statename: $state</h2>
</td>
</tr>
</table>
EOF

   return($H);
}

sub getPosibleWorkflowDerivations
{
   my $self=shift;
   my $rec=shift;

   return() if (!defined($rec) || 
                 !defined($self->{SubDataObj}->{$rec->{class}}));
   return(
     $self->{SubDataObj}->{$rec->{class}}->getPosibleWorkflowDerivations($rec));

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
            msg(INFO,"load possible actions from $class");
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


sub TaskOpen
{
   my $self=shift;
   my $srcsys=shift;
   my $srcid=shift;
   my $directlnktype=shift;
   my $directlnkid=shift;
   my $directlnkmode=shift;
   my $fwdtarget=shift;
   my $fwdtargetid=shift;
   my $fwddebtarget=shift;
   my $fwddebtargetid=shift;
   my $subject=shift;
   my $text=shift;

}


sub TaskCleanup
{
   my $self=shift;
   my $srcsys=shift;
   my $srcid=shift;
   my $directlnktype=shift;
   my $directlnkid=shift;
   my $directlnkmode=shift;
   my $cleanupstate=shift;
   my $cleanupmsg=shift;
   my $mdatefilter=shift;

}





sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $oldrec=$param{oldrec};
   my $newrec=$param{current};
   my $class=effVal($oldrec,$newrec,"class");

   if (!defined($class) && defined($param{class})){
      $class=$param{class};
   }
   if (!defined($class)){
      $class=Query->Param("WorkflowClass");
   }
   if (defined($class)){
      if (!defined($self->getParent->{SubDataObj}->{$class})){
         $class="base::workflow::Archive";
      }
      my @subl=$self->getParent->{SubDataObj}->{$class}->getDynamicFields(
                                                                 %param);
      return(@subl);
   }
   return;
}



#######################################################################
# WSDL integration
#######################################################################
sub WSDLWorkflowFieldTypes
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLtypes.="<xsd:complexType name=\"WorkflowActions\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"record\" type=\"$ns:WorkflowAction\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"WorkflowAction\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"owner\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"creator\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"name\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"cdate\" type=\"xsd:dateTime\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" ".
               "name=\"effort\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" ".
               "name=\"comments\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" ".
               "name=\"additional\" type=\"$ns:Container\" />";
   $$XMLtypes.="<xsd:element name=\"id\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element name=\"translation\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"intiatornotify\" ".
               "minOccurs=\"0\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element name=\"actionref\" ".
               "minOccurs=\"0\" type=\"$ns:Container\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"WorkflowRelations\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"subrecord\" type=\"$ns:WorkflowRelation\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"WorkflowRelation\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"id\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element name=\"name\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"comments\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"dstwfclass\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"dstwfname\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"dstwfid\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element name=\"srcwfclass\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"srcwfname\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"srcwfid\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element name=\"mdate\" type=\"xsd:dateTime\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

}
sub WSDLcommon
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;


   $self->WSDLWorkflowFieldTypes($uri,$ns,$fp,$class,
                           $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);


   if (defined($class) && defined($self->{SubDataObj}->{$class})){
      my $classobj=$self->{SubDataObj}->{$class};
      $classobj->WSDLcommon($uri,$ns,$fp,$class,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   }

   return($self->SUPER::WSDLcommon($uri,$ns,$fp,$class,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes));
}

sub WSDLaddNativFieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $class=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   if (defined($class) && defined($self->{SubDataObj}->{$class})){
      my $classobj=$self->{SubDataObj}->{$class};
      $classobj->WSDLaddNativFieldList($uri,$ns,$fp,$class,$mode,
                              $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   }
}


sub Main
{
   my $self=shift;

   if (!$self->IsMemberOf(["admin","support"])){
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
      @addgroups=qw(default state source initstate affected);
   }
   return("default","source","state") if (!defined($rec));
   if (!defined($self->{SubDataObj}->{$rec->{class}})){
      my $class="base::workflow::Archive";
      return($self->{SubDataObj}->{$class}->isViewValid($rec));
   }

   my @grplist=(@addgroups,
                $self->{SubDataObj}->{$rec->{class}}->isViewValid($rec));
   push(@grplist,"qc");
   push(@grplist,"individualAttr");
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
   return("ALL") if (!defined($rec));
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

sub handleDependenceChange
{
   my $self=shift;
   my $rec=shift;
   my $dependwfheadid=shift;
   my $dependmode=shift;
   my $dependoldstateid=shift;
   my $dependnewstateid=shift;
   return(undef) if (!defined($rec) || 
                 !defined($self->{SubDataObj}->{$rec->{class}}));
   return($self->{SubDataObj}->{$rec->{class}}->handleDependenceChange($rec,
          $dependwfheadid,$dependmode,$dependoldstateid,$dependnewstateid));
}

sub DataIssueCompleteWriteRequest
{
   my $self=shift;
   my $oldIssueRec=shift;
   my $newIssueRec=shift;
   my $rec=shift;
   return(undef) if (!defined($rec) || 
                 !defined($self->{SubDataObj}->{$rec->{class}}));
   if ($self->{SubDataObj}->{$rec->{class}}->
       can("DataIssueCompleteWriteRequest")){
      return($self->{SubDataObj}->{$rec->{class}}->
                DataIssueCompleteWriteRequest($oldIssueRec,$newIssueRec,$rec));
   }
   if ($rec->{openuser}=~m/^\d+$/){
      $newIssueRec->{fwdtarget}="base::user";
      $newIssueRec->{fwdtargetid}=$rec->{openuser};
      $newIssueRec->{mandator}=$rec->{mandator};
      $newIssueRec->{mandatorid}=$rec->{mandatorid};
   }
   return(1);
}

sub SetFilter
{
   my $self=shift;
   my @flt=@_;
   if ($self->getField("trange")->SetFilter(\@flt)){; # expand filter for 
                                                      # timerange handling 
      return($self->SUPER::SetFilter(@flt));
   }
   return(undef);
}




sub SetFilterForQualityCheck    # prepaire dataobject for automatic 
{                               # quality check (nightly)
   my $self=shift;
   my @view=@_;                 # predefinition for request view
   my $qrulelnk=getModuleObject($self->Config,"base::lnkqrulemandator");
   $qrulelnk->SetFilter({dataobj=>'*::workflow::*'});
   my @l=$qrulelnk->getHashList(qw(dataobj));
   my %wf;
   foreach my $rec (@l){
      $wf{$rec->{dataobj}}++;
   }
   $wf{none}++ if (!keys(%wf));
   
   $self->ResetFilter();
   $self->SetFilter({mdate=>">now-48h",class=>[keys(%wf)]});
   $self->SetCurrentView(@view);
   return(1);
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
      elsif ($W5V2::OperationContext eq "Enrichment"){
         if (!defined($newrec->{openuser})){
            $newrec->{openuser}=undef;
         }
         if (!defined($newrec->{openusername})){
            $newrec->{openusername}="Enrichment";
         }
      }
      else{
         my $UserCache=$self->Cache->{User}->{Cache};
         my $mycontactid=$self->getCurrentUserId();;
         my $mycontactname;
         if ($W5V2::OperationContext ne "W5Server"){
            if (defined($UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname})){
               $mycontactname=
                  $UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname};
            }
         }
         if ($W5V2::OperationContext ne "W5Server" ||
             !defined($newrec->{openuser})){
            if (defined($mycontactid)){
               $newrec->{openuser}=$mycontactid;
            }
         }
         if ($W5V2::OperationContext ne "W5Server" ||
             !defined($newrec->{openusername})){
            if (defined($mycontactname)){
               $newrec->{openusername}=$mycontactname;
            }
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

   if (exists($newrec->{name}) && defined($newrec->{name}) &&
       length($newrec->{name})>125){
      $newrec->{name}=substr($newrec->{name},0,125)."...";
      $origrec->{name}=$newrec->{name};
   }

   #
   # Attation: md5sechash can not be used for security-functionalities
   #           in base::workflow::mailsend !!!
   #
   if ((!defined($oldrec) && !exists($newrec->{md5sechash})) ||
       (defined($oldrec) && $oldrec->{md5sechash} eq "")){
      $newrec->{md5sechash}=md5_base64($newrec->{name}.rand().time().rand());
   }

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
   if (!defined($self->{SubDataObj}->{$class}) && defined($oldrec)){
      $class="base::workflow::Archive";
   }
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
   # handling of invoice reprocessing
   if ($eventend ne "" && effVal($oldrec,$newrec,"invoicedate") eq "" &&
       !exists($newrec->{invoicedate})){
      $newrec->{invoicedate}=$eventend;
   }
   ######################################################################
   my $name=effVal($oldrec,$newrec,"name");
   if ($name=~m/^\s*$/){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"invalid workflow short description spezified");
      }
      return(0);
   }

   my $stateid=effVal($oldrec,$newrec,"stateid");

   # new assign of deferred workflow if fwdtarget has changed
   if ($stateid==5 &&
       ((defined($newrec->{fwdtarget}) &&
         effChanged($oldrec,$newrec,"fwdtarget")) ||
        (defined($newrec->{fwdtargetid}) &&
         effChanged($oldrec,$newrec,"fwdtargetid")))) {
      $newrec->{stateid}=2;      
      $stateid=effVal($oldrec,$newrec,"stateid");
      $ENV{HTTP_FORCE_LANGUAGE}='en' if (!defined($ENV{HTTP_FORCE_LANGUAGE}));
      my $note="Workflow switched to state ".$self->T("wfstate.$stateid");
      $self->Action->StoreRecord($oldrec->{id},"note",
                                 {translation=>'base::workflowaction'},
                                 $note,undef);
   }
   ######################################################################
 
   if (defined($oldrec) && $stateid>1){
      if ($oldrec->{autocopymode} ne ""){
         $newrec->{autocopymode}=undef;
      }
      if ($oldrec->{autocopydate} ne ""){
         $newrec->{autocopydate}=undef;
      }
   }
   if (defined($oldrec) && $stateid>20){
      my $eventstart=effVal($oldrec,$newrec,"eventstart");
      my $eventend=effVal($oldrec,$newrec,"eventend");
      if ($eventend eq ""){   # need to create a dynamic eventend!!!
         my $closedate=effVal($oldrec,$newrec,"closedate");
         printf STDERR ("DEBUG: eventend fixup on '%s' done\n",$oldrec->{id});
         if ($closedate ne ""){
            $newrec->{eventend}=$closedate;
         }
         else{
            $newrec->{eventend}=NowStamp("en");
         }
      }
      if ($eventstart eq ""){   # need to create a dynamic eventstart!!!
         printf STDERR ("DEBUG: eventstart fixup on '%s' done\n",$oldrec->{id});
         my $createdate=effVal($oldrec,$newrec,"createdate");
         if ($createdate ne ""){
            $newrec->{eventstart}=$createdate;
         }
      }
   }

   #
   # recalculation of responsible group
   # primary depending on srcload (sec mdate) a recalculation is done at
   # maximum every 6 hours (or if the record is new created)
   #
   my $mdate=$oldrec->{srcload};
   if ($mdate eq ""){
      $mdate=$oldrec->{mdate};
   }
   my $duration;
   if ($mdate ne ""){
      $duration=CalcDateDuration($mdate,NowStamp("en"));
   }
   if ((defined($newrec->{fwdtarget}) &&
        effVal($oldrec,$newrec,"fwdtarget") ne $oldrec->{fwdtarget}) ||
       (defined($newrec->{fwdtargetid}) &&
        effVal($oldrec,$newrec,"fwdtargetid") ne $oldrec->{fwdtargetid}) ||
       $mdate eq "" ||
       $duration->{totalseconds}>3600*6){ # recalc group max every 6h
      # no the last responsegroup has to be posible changed
      my $class=defined($oldrec) && defined($oldrec->{class}) ? 
                $oldrec->{class} : $newrec->{class};
      if (defined($self->{SubDataObj}->{$class})){
         $self->{SubDataObj}->{$class}->recalcResponsiblegrp($oldrec,$newrec);
      }
   }
   #######################################################################
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
   if (defined($oldrec) 
     #  && $oldrec->{stateid}<15 && $stateid>15
       ){
      my $wfheadid=effVal($oldrec,$newrec,"id");
      if (ref($oldrec->{relations}) eq "ARRAY"){
         foreach my $relrec (@{$oldrec->{relations}}){
            my $notifywfheadid;
            my $notifymode;
            if ($relrec->{dstwfid} eq $wfheadid &&
                $relrec->{srcwfid} ne $wfheadid &&
                $relrec->{name} eq "dependson"){
               $notifywfheadid=$relrec->{srcwfid};
               $notifymode=$relrec->{name};
            }
            if ($relrec->{srcwfid} eq $wfheadid &&
                $relrec->{dstwfid} ne $wfheadid &&
                $relrec->{name} eq "isdependencyfrom"){
               $notifywfheadid=$relrec->{dstwfid};
               $notifymode=$relrec->{name};
            }
            my $newstateid=exists($newrec->{stateid}) ? 
                           $newrec->{stateid}: $stateid;
       
            if (defined($notifywfheadid)){
               $self->ResetFilter();
               $self->SetFilter({id=>\$notifywfheadid});
               my ($WfRec,$msg)=$self->getOnlyFirst(qw(ALL));
               if (defined($WfRec)){
                  $self->handleDependenceChange($WfRec,$wfheadid,$notifymode,
                                                $oldrec->{stateid},$newstateid);
               }
            }
         }
      }
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

   return();  # based on 
      # https://darwin.telekom.de/darwin/auth/base/workflow/ById/15843478470001
      # ... scheint es besser zu sein, die Felder in Workflows immer über
      # das Dynamic (wffields) element aufzulösen - da es ansonsten zu 
      # doppelt-Nennungen bei der View "ALL" kommt.
      # Falls dies nicht passt, wird es wirklich kniffelig da es sonst schwierig
      # wird, diese doppelt-Nennungen (über wffields und getFieldObjsByView
      # zu verhindern)
      #
   if (defined($param{current}) && defined($param{current}->{class})){
      $class=$param{current}->{class};
   }
   elsif (defined($param{oldrec}) && defined($param{oldrec}->{class})){
      $class=$param{oldrec}->{class};
   }
   elsif (defined($param{class})){
      $class=$param{class};
   }
   else{
      $class=Query->Param("WorkflowClass");
   }
   return() if (!defined($class));

   foreach my $SubDataObj (sort(keys(%{$self->{SubDataObj}}))){
      next if (defined($class) && $class ne $SubDataObj);
      my $sobj=$self->{SubDataObj}->{$SubDataObj};
      if ($sobj->can("getFieldObjsByView")){
    #     push(@fobjs,$sobj->getFieldObjsByView($view,%param));
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
   elsif (defined($param{class})){
      $class=$param{class};
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
   
   return(@preblk,@sub,@postblk,"individualAttr");
}



sub getValidWebFunctions
{
   my $self=shift;
   return("Process","DirectAct","ShowState","FullView","DerivateFrom",
          "externalMailHandler",
          "Adressbook",
          "DetailMarkDelete",
          "DetailUnMarkDelete",
          $self->SUPER::getValidWebFunctions());
}

sub setMarkDelete
{
   my $self=shift;
   my $mode=shift;

   my $id=Query->Param("CurrentIdToEdit");
   $id=~s/\D//g;
   my $flt={id=>\$id};
   $self->SecureSetFilter($flt);
   $self->SetCurrentView(qw(ALL));
   my ($WfRec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($WfRec)){
      if ($self->isMarkDeleteValid($WfRec)){
         my $res=$self->ValidatedUpdateRecord($WfRec,
                                              {isdeleted=>$mode},{id=>\$id});
         if ($res){
            my $msg=sprintf($self->T(
                    'Workflow %s has been successfuly marked as deleted'),$id);
            my $msgmode="mark as deleted:";
            if ($mode==0){
               $msg=sprintf($self->T(
                    'Workflow %s has been successfuly unmarked as deleted'),
                     $id);
               $msgmode="unmark as deleted:";
            }
            $self->Action->NotifyForward($id,
                                         "base::user",$self->getCurrentUserId(),
                                         undef,$msg,mode=>$msgmode);
            print $self->HttpHeader("text/xml");
            print hash2xml({document=>{ok=>'1',newstate=>$mode}},{header=>1});
            return;
         }
      }
   }
   print $self->HttpHeader("text/xml");
   print hash2xml({document=>{ok=>'0'}},{header=>1});
   return;
}

sub DetailMarkDelete
{
   my $self=shift;
   $self->setMarkDelete(1);
}

sub DetailUnMarkDelete
{
   my $self=shift;
   $self->setMarkDelete(0);
}


sub ShowState
{
   my $self=shift;
   my $func=$self->Query->Param("FUNC");
   
   if (defined(Query->Param("HTTP_ACCEPT_LANGUAGE"))){
      $ENV{HTTP_ACCEPT_LANGUAGE}=Query->Param("HTTP_ACCEPT_LANGUAGE");
   }
   my $wfstate=0;
   my $wfheadid;
   if (my ($i,$l)=$func=~m/(\d+)\/(.+.+)$/){
      $wfheadid=$i;
      $ENV{HTTP_ACCEPT_LANGUAGE}=$l;
   }
   elsif (my ($i)=$func=~m/(\d+)$/){
      $wfheadid=$i;
   }

   $wfheadid=~s/^0+//;
   if ($wfheadid ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$wfheadid});
      my ($wfrec,$msg)=$self->getOnlyFirst(qw(stateid));
      $wfstate=$wfrec->{stateid} if (defined($wfrec));
   }
   my $filename=$self->getSkinFile("base/img/wfstate$wfstate.gif");
   my %param;

   print $self->HttpHeader("image/gif",%param);
   if (open(MYF,"<$filename")){
      binmode MYF;
      binmode STDOUT;
      while(<MYF>){
         print $_;
      }
      close(MYF);
   }
   delete($ENV{HTTP_ACCEPT_LANGUAGE});
}

sub getSelectableModules
{
   my $self=shift;
   my %env=@_;
   my @l=();

   foreach my $wfclass (keys(%{$self->{SubDataObj}})){
      my $o=$self->{SubDataObj}->{$wfclass};
      if (!defined($o)){
         msg(ERROR,"Workflow Object '$wfclass' is not useable due programm".
                   "error");
         next;
      }
      next if (!$self->{SubDataObj}->{$wfclass}->IsModuleSelectable(\%env));
      push(@l,$wfclass);
   }
   return(@l);
}


sub Adressbook
{
   my $self=shift;
   my $field=Query->Param("field");
   my $label=Query->Param("label");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css','workflow.css'],
                           js=>['toolbox.js','subModal.js','J5Base.js'],
                           body=>1,form=>1,
                           title=>$self->T('Adressbook')." [".$label."]");
   delete($self->{Adressbook});
   $self->LoadSubObjs("ext/Adressbook","Adressbook");
   my @books;
   foreach my $aobj (values(%{$self->{Adressbook}})){
      push(@books,$aobj->getAdressbooks());
   }
   my @bn;
   my @bnhtml;
   while(my $label=shift(@books)){
      my $obj=shift(@books);
      push(@bn,"'$label':'$obj'");
      my $checked="";
      if ($obj eq "base::user"){
         $checked=" checked ";
      }
      push(@bnhtml,"<input type=radio $checked name=\"book\" value=\"$obj\">".
                   "$label");
   }
   my $books="var books={".join(",",@bn)."}";
   my $bookshtml=join("<br>",@bnhtml);


   print <<EOF;


<script language="JavaScript" type="text/javascript">

var W5Base=createConfig({ useUTF8:false, mode:'auth',transfer:'JSON' });
// non jsonp call should be implemented in future
//var W5Base=createConfig({ useUTF8:false, mode:'auth' });
var sepExp=new RegExp("[ ]*[;,]+[ ]*", "i");
$books;

var phoneBook;

function changeValue(o,id)
{
   var curStr=parent.\$("#$field").val();
   var curl=curStr.split(sepExp); 
   if (o.checked){
      if (jQuery.inArray(phoneBook[id].email,curl)){
         curl.push(phoneBook[id].email);
      }
   }
   else{
      curl=jQuery.grep(curl, function(value) {
         return(!(value == phoneBook[id].email));
      });
   }
   curl=jQuery.grep(curl, function(value) {
      return(value !="");
   });
   parent.\$("#$field").val(curl.join("; "));
}

function displayResult(res)
{
   var d="<table>";
   var curStr;
   if ("$field"!=""){
       curStr=parent.\$("#$field").val();
   }
   var curl=new Array();
   if (curStr){
      curl=curStr.split(sepExp); 
   }

   for(var c=0;c<res.length && c<50;c++){
      d+="<tr>";
      if ("$field"!=""){
         d+="<td valign=top><input type=checkbox";
         if (jQuery.inArray(res[c].email,curl)>-1){
            d+=" checked";
         }
         d+=" onclick=\\"changeValue(this,"+c+");\\"></td>";
      }
      d+="<td valign=top><b>"+res[c].fullname+"</b>";
      var subline="";
      if (res[c]['office_location']!="" &&
          res[c]['office_location']!=undefined){
         subline+=res[c]['office_location'];
      }
      if (res[c]['office_phone']!="" &&
          res[c]['office_phone']!=undefined){
         if (subline!="") subline+=", ";
         subline+=res[c]['office_phone'];
      }
      if (res[c]['office_mobile']!="" &&
          res[c]['office_mobile']!=undefined){
         if (subline!="") subline+=", ";
         subline+=res[c]['office_mobile'];
      }
      if (subline!=""){
         d+="<br>"+subline;
      }
      d+="</td>";
      d+="</tr>";
   }
   phoneBook=res;

   d+="</table>";
   if (res.length>=50){
      d+="<center><br><b>...</b></center>";
   }
   if (res.length==0){
      d+="<center><img height=180 border=0 "+
         "src=\\"../../base/load/notfound.jpg\\"></center>";
   }

   \$("#result").height(\$("#mainTab").height()-\$("#searchTab").height()-5);
   \$("#result").html(d);
}

function doSearch()
{
   \$("#result").html("<br><br>"+
                      "<table width=100% border=0><tr>"+
                      "<td align=center>"+
                      "<img src='../../base/load/ajaxloader.gif'>"+
                      "</td></tr></table>");
   var surname=\$("#surname").val();
   var givenname=\$("#givenname").val();
   var location=\$("#location").val();
   var flt=new Object();
   if (surname!=""){
      flt.surname=surname;
   }
   if (givenname!=""){
      flt.givenname=givenname;
   }
   if (location!=""){
      flt['office_location']=location;
   }
   var objname=\$("input[name='book']:checked").val();
   var o=getModuleObject(W5Base,objname);
   o.SetFilter(flt);
   o.Limit(51);
   o.findRecord("id,fullname,office_location,"+
                "office_phone,office_mobile,email",displayResult);
   return(false);
}
setEnterSubmit(document.forms[0],doSearch);
setFocus("");

</script>
<style>
.borderright{
   border-right-style:solid;
   border-right-color:black;
   border-right-width:1px;
}
.bordertop{
   border-top-style:solid;
   border-top-color:black;
   border-top-width:1px;
}

</style>
<table id=mainTab 
       width="100%" height="100%" style="border-collapse:collapse" border=0>
<tr height=1%>
<td valign=bottom align=center width="100" class=borderright>
<img src="../../base/load/addrbook_logo.gif" height=30>
</td>
<td valign=top>
<table border=0 width="100%" id=searchTab>
<tr>
<td width=1%>Nachname:</td><td nowrap width="30%"><input size=6 style="width:100%" type=text id=surname value="">&nbsp;</td>
<td width=1%>Vorname:</td><td nowrap width="30%"><input size=6 style="width:100%" type=text id=givenname>&nbsp;</td>
<td width=1%>Ort:</td><td nowrap width="30%"><input size=6 style="width:100%" type=text id=location>&nbsp;</td>
<td width=10><span style="cursor:pointer" onclick="doSearch();"><img src="../../base/load/search.gif" height=30></span></td>
</tr>
</table>
</td>
</tr>

<tr>
<td valign=top class=borderright>
$bookshtml
</td>
<td valign=top class=bordertop>
<div id=result style="overflow:auto;height:100%">
</div>
</td>
</tr>

</table>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}


sub DerivateFrom # Workflow ableiten
{
   my $self=shift;
   my $id=Query->Param("id");
   my $doDerivateWorkflow=Query->Param("doDerivateWorkflow");

   $id=~s/^0+//;
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($wfrec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (defined($wfrec)){
         my @l=$self->getPosibleWorkflowDerivations($wfrec);
         foreach my $derivationrec (@l){
            if ($derivationrec->{name} eq $doDerivateWorkflow &&
                ref($derivationrec->{actor}) eq "CODE"){
               my $bk=&{$derivationrec->{actor}}($self,$wfrec);
               if (ref($bk) eq "HASH"){
                  print $self->HttpHeader("text/html");
                  if ($bk->{'targeturl'} ne ""){
                     print("<html>");
                     eval("use JSON;");
                     if ($@ eq ""){
                        $bk->{'targetparam'}->{'isDerivateFrom'}=
                             $wfrec->{'class'}."::".$wfrec->{'id'};
                        my $json;
                        eval('$json='.
                             'to_json($bk->{targetparam}, {ascii => 1});');
                        print("<script language=\"JavaScript\">");
                        print("function DerivateFrom(){");
                        print("  var o=$json;");
                        print("  for(var k in o){");
                        print("     var x=document.createElement(\"input\");");
                        print("     x.type='hidden';");
                        print("     x.name=k;");
                        print("     x.value=o[k];");
                        print("     document.forms[0].appendChild(x);");
                        print("  }");
                        print("  window.setTimeout('".
                                 "document.forms[0].submit();',3000);");
                        print("}");
                        print("</script>");
                        print("<body onload='DerivateFrom(this);'>");
                        print("<form action='$bk->{targeturl}' method=POST>");
                        print("</form>");
                        print("derivation of new workflow from ".
                              $bk->{'targetparam'}->{'isDerivateFrom'}."<br>");
                        print("loading ...");
                        #print("<xmp>".$json."</xmp>");
                        print("</body>");
                     }
                     print("</html>");
                  }
                  return;
               }
               if ($bk){
                  return;
               }
            }
         }
      }
   }
   print $self->HttpHeader("text/html");
   $id=quoteHtml($id);
   $doDerivateWorkflow=quoteHtml($doDerivateWorkflow);
   print("Invalid derivation request to Workflow id=$id ".
         "(mode=$doDerivateWorkflow)");
}


sub New                   # Workflow starten
{
   my $self=shift;
   my $id=Query->Param("id");
   my $class=Query->Param("WorkflowClass");
   my @WorkflowStep=Query->Param("WorkflowStep");


   if ($class=~m/::Explore::/){
      $self->HtmlGoto("../../base/Explore/Start/$class");
      return();
   }

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
   my @selectable=$self->getSelectableModules(%env);
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      @selectable=();
   }
   my $faq=getModuleObject($self->Config(),"faq::article");

   foreach my $wfclass (@selectable){
      my $name=$self->{SubDataObj}->{$wfclass}->Label();
      $disp{$name}=$wfclass;
      my $tiptag=$wfclass."::tip";
      my $tip=$self->T($tiptag,$wfclass);
      if ($tiptag ne $tip){
         $tip="<b>".$self->T("Tip","base::workflow").":</b> $tip";
      }
      else{
         $tip="<b>".$self->T("no Tip for","base::workflow")." $wfclass</b>";
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
      my $OpenURL="$ENV{SCRIPT_URI}?WorkflowClass=$wfclass";
      if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
         $OpenURL=~s/^http:/https:/i;
         $url=~s/^http:/https:/i;
      }
      my $openquery={OpenURL=>$OpenURL};
      my $queryobj=new kernel::cgi($openquery);
      $url.="?".$queryobj->QueryString(); 
      my $a="<a href=\\\"$url\\\" ".
            "target=_blank title=\\\"$atitle\\\">".
            "<img src=\\\"../../base/load/anker.gif\\\" ".
            "height=10 border=0></a>";
      if (defined($faq)){
         my $further=$faq->getFurtherArticles("workflow ".$wfclass);
         if ($further ne ""){
            $tip.=$further;
         }
      }
      $tip=~s/\n/\\n/g;
      $tip=~s/"/\\"/g;
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

   $self->LoadSubObjsOnDemand("Explore","Explore");

   {
      my $lang=$self->Lang();

      foreach my $sobj (values(%{$self->{Explore}})){
         my $d;
         if ($sobj->isAppletVisible($self)){
            my $hidden=$sobj->getObjectHiddenState($self);
            if (!$hidden){
               if ($sobj->can("getObjectInfo")){
                  $d=$sobj->getObjectInfo($self,$lang);
               }
               if (defined($d) && $d->{formular}){
                  my $selfname=$sobj->Self();
                  $selbox.="<option value=\"$selfname\"";
                  #$selbox.=" selected" if ($disp{$name} eq $oldval);
                  $selbox.=">Formular: ".$d->{label}."</option>";
                  $tips.="tips['$selfname']=\"$d->{description}\";\n";
               #  my $jsdata=$jsengine->encode($d);
               #  utf8::encode($jsdata);
               #  printf("ClassAppletLib['%s']={desc:%s};\n",$selfname,$jsdata);
               }
            }
         }
      }
   }



   $selbox.="</select>";
   my $appheader=$self->getAppTitleBar();
   my $msg=$self->T("Please select the workflow to start:");
   my $start=$self->T("start workflow");
   print <<EOF;
<table width="100%" height="100%" border=0>
<tr height=1%><td valign=top>$appheader</td></tr>
<tr height=1%><td valign=top>$msg</td></tr>
<tr><td align=center valign=center>$selbox</td></tr>
<tr height=1%>
   <td align=right nowrap>
      <input type=submit value="$start" class=workflowbutton>&nbsp; 
   </td>
</tr>
<tr height=1%>
<td align=center valign=center>
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
   else{
      $class="base::workflow::Archive";
      $step= "base::workflow::Archive::Archive";
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

sub preparseEmail
{
   my $self=shift;
   my $tag=shift;
   if (my ($grpid)=$tag=~m/^base::grp\((\d+)\)$/){
      my $grp=getModuleObject($self->Config,"base::grp");
      $grp->SetFilter({grpid=>\$grpid});
      my ($grprec,$msg)=$grp->getOnlyFirst(qw(users));
      if (defined($grprec) && ref($grprec->{users}) eq "ARRAY"){
         my @l;
         foreach my $urec (@{$grprec->{users}}){
            push(@l,$urec->{email}) if ($urec->{email} ne "");
         }
         return(@l);
      }
   }
   if (my ($userid)=$tag=~m/^base::user\((\d+)\)$/){
      my $user=getModuleObject($self->Config,"base::user");
      $user->SetFilter({userid=>\$userid});
      my ($userrec,$msg)=$user->getOnlyFirst(qw(email));
      if (defined($userrec)){
         return($userrec->{email});
      }
   }
   return(lc($tag));
}

sub externalMailHandler 
{
   my $self=shift;

   my $jsonRequest=0;
   my $jsonResult={};

   my @accept=split(/\s*,\s*/,lc($ENV{HTTP_ACCEPT}));
   if (in_array(\@accept,["application/json","text/javascript"])){
      $jsonRequest=1;
   }


   my $parent=Query->Param("parent");
   my $addref=Query->Param("addref");
   my $mode=Query->Param("mode");
   my $id=Query->Param("id");
   if (my ($wfheadid)=$mode=~m/^workflowrepeat\((\d+)\)$/){
      my $userid=$self->getCurrentUserId();
      my $wa=getModuleObject($self->Config,"base::workflowaction");
      $wa->SetFilter({wfheadid=>\$wfheadid});
      my $i={};
      my @l=$wa->getHashList(qw(cdate name additional comments creator));
      foreach my $arec (reverse(@l)){
         my $add=$arec->{additional};
         $add={Datafield2Hash($add)} if (ref($add) ne "HASH");
         if ($arec->{name} eq "wfmailsend"){
            $i->{to}=$add->{to};
            $i->{cc}=$add->{cc};
            $i->{subject}=$add->{subject};
            $i->{msg}="\n\n---\n".$self->T("Mail from")." ".$arec->{cdate}."\n".
                      $arec->{comments};
            last if ($userid==$arec->{creator});
         }
      }
      foreach my $v (qw(to cc msg subject)){
         Query->Param($v=>$i->{$v}) if ($i->{$v} ne "");
      }
      $mode="simple";
   }


   my $from=Query->Param("from");
   my $s=Query->Param("subject");
   my $m=Query->Param("msg");
   my @t=split(/\s*[,;]\s*/,Query->Param("to"));
   my @c=split(/\s*[,;]\s*/,Query->Param("cc"));
   my %u=(); map({foreach my $t ($self->preparseEmail($_)){$u{$t}++}} @t); 
             @t=grep(!/^\s*$/,sort(keys(%u)));
   my %u=(); map({foreach my $t ($self->preparseEmail($_)){$u{$t}++}} @c); 
             @c=grep(!/^\s*$/,sort(keys(%u)));
   my $t=join("; ",@t);
   my $c=join("; ",@c);

   if ($addref ne ""){
      $addref="checked";
   }


   # calculate valid fromlist
   my $user=getModuleObject($self->Config,"base::user");
   my $userid=$self->getCurrentUserId();
   my @fromlist;
   if ($userid ne ""){
      $user->SetFilter({userid=>\$userid});
      my ($urec)=$user->getOnlyFirst(qw(userid emails));
      if (defined($urec) && ref($urec->{emails}) eq "ARRAY" &&
          $#{$urec->{emails}}>0){
         foreach my $emailrec (@{$urec->{emails}}){
            if ($emailrec->{emailtype} eq "primary"){
               unshift(@fromlist,$emailrec->{email});
            }
            else{
               push(@fromlist,$emailrec->{email});
            }
         }
      }
   }

   if (Query->Param("ACTION") eq "send"){
      my $chkfail=0;
      my $opok=0;
      if ($#t==-1 && $#c==-1){
         $chkfail=1;
         $self->LastMsg(ERROR,"no target email adress specified");
      }
      if (length(trim($s))<3){
         $self->LastMsg(ERROR,"missing subject");
      }
      if (length(trim($m))<3){
         $self->LastMsg(ERROR,"missing mail text");
      }
      my %notiy;
      $notiy{name}=$s;
      $notiy{emailtext}=$m;
      $notiy{directlnkmode}="W5BaseMail";
      $notiy{directlnkid}=$id;
      $notiy{directlnktype}=$parent;
      if ($addref ne ""){
         if ($ENV{SCRIPT_URI} ne ""){
            $notiy{emailtext}.="\n\nDirectLink:\n";
            my $baseurl=$ENV{SCRIPT_URI};
            $baseurl=~s/\/(auth|public)\/.*$//;
            my $jobbaseurl=$self->Config->Param("EventJobBaseUrl");
            if ($jobbaseurl ne ""){
               $jobbaseurl=~s#/$##;
               $baseurl=$jobbaseurl;
            }
            my $url=$baseurl;
            if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
               $url=~s/^http:/https:/i;
            }
            my $p=$parent;
            $p=~s/::/\//g;
            $url.="/auth/$p/ById/".$id;
            $notiy{emailtext}.=$url;
            $notiy{emailtext}.="\n\n";
         }
      }
      if ($from ne "" && $#fromlist>0 && in_array(\@fromlist,$from)){
         $notiy{emailfrom}=$from;
      }
      $notiy{emailto}=\@t;
      $notiy{emailcc}=\@c;
      $notiy{emailcategory}=["W5Base","W5BaseMail"];
      if ($parent ne ""){
         push(@{$notiy{emailcategory}},"DataObj:$parent");
      }
      if ($id ne ""){
         push(@{$notiy{emailcategory}},"DataID:$id");
      }
      if (Query->Param("senderbcc") ne ""){
         my $userid=$self->getCurrentUserId();
         my $UserCache=$self->Cache->{User}->{Cache};
         if ($UserCache->{$userid}->{rec}->{email} ne ""){
            $notiy{emailbcc}=$UserCache->{$userid}->{rec}->{email};
         }
      }
      $notiy{class}='base::workflow::mailsend';
      $notiy{step}='base::workflow::mailsend::dataload';

      my $file=Query->Param("file");
      my ($attinfo,$att);
      my $maxmail=$self->Config->Param("MaxMailAttachment");
      if ($self->IsMemberOf("admin")){
         $maxmail=$maxmail*2;
      }
      if (defined($attinfo=Query->UploadInfo($file))){
         no strict;
         my $f=Query->Param("file");
         seek($f,0,SEEK_SET);
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $att.=$buffer;
            $size+=$bytesread;
            if ($size>$maxmail){
               $self->LastMsg(ERROR,"file larger then max attachment size %d",
                                     $maxmail);
               last;
            }
         }
         msg(INFO,"attachment with $size bytes was send");
         Query->Delete("file");
      }
      if (!$self->LastMsg()){
         if (my $mailid=$self->Store(undef,\%notiy)){
            $jsonResult->{mailid}=$mailid;
            my $msg;
            if (defined($att) && defined($attinfo)){
               my $newrec;
               $newrec->{data}=$att;
               $newrec->{name}=trim($file);
               $newrec->{name}=~s/.*[\/\\]//;
               $newrec->{wfheadid}=$mailid;
               $newrec->{contenttype}=$attinfo->{'Content-Type'};
               my $wfa=getModuleObject($self->Config,"base::wfattach");
               my $bk=$wfa->ValidatedInsertRecord($newrec);
               $msg="\nAttachment: $newrec->{name} (".length($att)." bytes)";
            }
            my %d=(step=>'base::workflow::mailsend::waitforspool');
            if ($parent eq "base::workflow"){
               my $additional={};
               $additional->{to}=$t if ($t ne "");
               $additional->{cc}=$c if ($c ne "");
               $additional->{subject}=$s if ($s ne "");
               $t=substr($t,0,40)."..." if (length($t)>42);
               $msg="To: $t\n\n".$m.$msg;
               $self->Action->StoreRecord($id,"wfmailsend",
                                          {translation=>'kernel::WfStep',
                                           additional=>$additional},$msg);
            }
            if (my $r=$self->Store($mailid,%d)){
               $self->LastMsg(OK,
                              "mail has been successfuly transfered to spool");
               $opok=1;
            }
         }
      }
      if ($jsonRequest){
         print $self->HttpHeader("application/json");
         if ($self->LastMsg()){
            my @lastmsg=$self->LastMsg();
            $jsonResult->{lastmsg}=\@lastmsg;
         }
         if ($jsonResult->{mailid} ne ""){
            my $mailid=$jsonResult->{mailid};
            $self->ResetFilter();
            $self->SetFilter({id=>\$mailid});
            my ($wfrec,$msg)=$self->getOnlyFirst(qw(urlofcurrentrec));
            if (defined($wfrec)){
               $jsonResult->{urlofcurrentrec}=$wfrec->{urlofcurrentrec}; 
            }
         }
         my $JSON;
         eval("use JSON;\$JSON=new JSON;");
         if ($@ eq ""){
            $JSON->utf8(1);
            $JSON->allow_blessed(1);
            $JSON->convert_blessed(1);
            my $res=$JSON->pretty->encode($jsonResult);
            print $res;
         }
         return();
      }
      else{
         print $self->HttpHeader("text/html");
         print $self->HtmlHeader(style=>['default.css','work.css'],
                                 body=>1,form=>1,target=>'action',
                                 title=>'W5Base Mail Client');
         my $lastmsg=$self->findtemplvar({},"LASTMSG");
         print $lastmsg;
         if ($opok){
            print <<EOF;
<script language="JavaScript">
function doRefresh()
{ if (parent.opener){ parent.opener.document.forms[0].submit(); } }
function doClose()
{ parent.close(); }
window.setTimeout("doRefresh();",1000); window.setTimeout("doClose();",1100);
</script>

EOF
         }
         print $self->HtmlBottom(body=>1,form=>1);
         return();
      }
   }
   else{
      if ($parent eq "base::workflow" && $id ne "" && $s eq ""){
         $self->ResetFilter();
         $self->SetFilter({id=>\$id});
         my ($rec,$msg)=$self->getOnlyFirst(qw(name wffields.conumber));
         $s=$rec->{name};
      }
      $addref="checked";
      if (!($m=~m/^--$/m)){      
         my $u=getModuleObject($self->Config,"base::user");
         if (defined($u)){
            my $userid=$self->getCurrentUserId();
            $u->SetFilter({userid=>\$userid});
            my ($urec,$msg)=$u->getOnlyFirst(qw(w5mailsig 
                                                office_phone office_mobile
                                                surname givenname orgunits));
            if (defined($urec) && $urec->{w5mailsig} ne ""){
               my $tmpl=$urec->{'w5mailsig'};
               my $orgunits=$urec->{orgunits};
               if (ref($orgunits) eq "ARRAY"){
                  $orgunits=join(", ",@$orgunits);
               }
               $tmpl=~s/\%S/$urec->{surname}/g;
               $tmpl=~s/\%G/$urec->{givenname}/g;
               $tmpl=~s/\%P/$urec->{office_phone}/g;
               $tmpl=~s/\%M/$urec->{office_mobile}/g;
               $tmpl=~s/\%O/$orgunits/g;
               $m.="\n\n\n\n--\n".$tmpl;
            }
         }
      }
   }

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1,target=>'action',multipart=>1,
                           js=>['TextTranslation.js',
                                'jquery.js','toolbox.js','subModal.js'],
                           title=>'W5Base Mail Client');
   print $self->HtmlSubModalDiv();

   my $user=getModuleObject($self->Config,"base::user");
   my $userid=$self->getCurrentUserId();
   my $fromline="";
   if ($#fromlist>0){
      $fromline="<tr height=1%><td align=left>";
      $fromline.="<table border=0 width=\"100%\">";
      $fromline.="<tr><td width=50>";
      $fromline.=$self->T("from","base::workflow::mailsend").":";
      $fromline.="</td><td>";
      $fromline.="<select name=from style=\"width:80%\">";
      foreach my $fromemail (@fromlist){
         $fromline.="<option value=\"$fromemail\"";
         $fromline.=" selected" if ($from eq $fromemail);
         $fromline.=">$fromemail</option>";
      }
      $fromline.="</select>";
      $fromline.="</td>";
      $fromline.="</tr>";
      $fromline.="</table></td></tr>";
   }

   my $to=$self->T("To","base::workflow::mailsend");
   my $subject=$self->T("Subject","base::workflow::mailsend");
   my $send=$self->T("Send message","base::workflow::mailsend");
   my $bccmsg=$self->T("BCC to sender","base::workflow::mailsend");
   my $attmsg=$self->T("Attachment","base::workflow::mailsend");
   my $refmsg=$self->T("add refernce","base::workflow::mailsend");
   my $lastmsg=$self->findtemplvar({},"LASTMSG");
   my $refdialog="&nbsp;";
   if ($parent ne "" && $id ne ""){
      $refdialog="<label for=\"addref\">$refmsg:</label>";
      $refdialog.="<input id=\"addref\" name=addref $addref type=checkbox>";
   }
   $s=~s/"//g;
   $t=~s/"//g;
   $c=~s/"//g;
   print('<table class=noselect style="margin:0px;padding:0px" border=0 '.
         'cellspacing=0 cellpadding=0 width="100%" height="100%">');
   #printf("<tr><td height=1%%>Mail related to</td></tr>");
   print <<EOF;
${fromline}
<tr height=1%><td height=1%>
  <table width=\"100%\">
  <tr>
  <td width=50 valign=top>
     <table border=0 cellspacing=0 cellpadding=0>
     <tr>
     <td><span class=sublink onclick=\"openAdressbook('to','$to');\">
         <img id=\"addrto\" src=\"../../base/load/addrbook.gif\"></span></td>
     <td>&nbsp;</td>
     <td><span class=sublink onclick=\"openAdressbook('to','$to');\">
         $to:</span></td>
     </tr>
     </table>
  </td>
  <td><textarea id=to name=to style="width:100%;height:40px;resize:vertical;max-height:130px;min-height:30px;">$t</textarea></td>
  </tr></table>
 </td></tr>
 <tr height=1%><td height=1%>
  <table width=\"100%\"><tr>
  <td width=50 valign=top>
  <table border=0 cellspacing=0 cellpadding=0><tr>
  <td><span class=sublink onclick=\"openAdressbook('cc','CC');\">
      <img src=\"../../base/load/addrbook.gif\"></span></td>
  <td>&nbsp;</td>
  <td><span class=sublink onclick=\"openAdressbook('cc','CC');\">
      CC:</span></td>
  </tr></table>
  </td>
  <td><textarea id=cc name=cc style="width:100%;height:30px;resize:vertical;max-height:130px;min-height:30px;">$c</textarea></td>
  </tr></table>
 </td></tr>
 <tr height=1%><td height=1%>
  <table width=\"100%\"><tr>
  <td width=50>$subject:</td>
  <td><input name=subject value="$s" style="width:100%"></td>
  </tr></table>
 </td></tr>
 <tr height=1%><td height=1%>
  <table width=\"100%\"><tr>
  <td width=50>$attmsg:</td>
  <td><input name=file size=32 type=file></td>
  <td width=140 nowrap align=right><div style="vertical-align:middle">
  $refdialog
  </div></td>
  </tr></table>
 </td></tr>
 <tr><td>
  <textarea onkeydown="textareaKeyHandler(this,event);" name=msg style="width:100%;height:100%;resize:none">$m</textarea>
 </td></tr>
 <tr height=1%><td height=1% align=left>
<iframe style="height:15px;width:100%;margin:0px;padding:0px;border-style:none; border-width:0pt;" src="Empty" name=action></iframe>
</td>
 </tr>
 <tr height=1%><td height=1% align=right>
 <input type=hidden name=parent value="$parent">
 <input type=hidden name=mode value="$mode">
 <input type=hidden name=id value="$id">
 <input type=hidden name=ACTION value="send">
 <table cellspacing=0 cellpadding=0>
 <tr>
 <td nowrap>
 <label for="senderbcc">$bccmsg</label>
 <input id="senderbcc" name=senderbcc type=checkbox>
 </td>
 <td nowrap width=30>&nbsp;</td>
 <td>
 <input type=button onclick=doSend() name=send 
        value="$send">
 </td>
 </tr></table>
 </td></tr>
</table>
<script language="JavaScript">
function refreshParent()
{
   if (opener){
      opener.ModeSelectSet("StandardDetail");
   }

}

function onAdressbookClose()
{
}

function openAdressbook(field,label)
{
   showPopWin('Adressbook?field='+field+"&label="+label,540,240,onAdressbookClose);
}


function doSend()
{
   if (document.forms[0].elements['subject'].value==""){
      alert("no subject");
      return(0);
   }
   if (document.forms[0].elements['to'].value==""){
      alert("no to");
      return(0);
   }
   document.forms[0].submit();

}
</script>
EOF
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
   if (defined($current) && defined($current->{class})){
      if (defined($self->{SubDataObj}->{$current->{class}})){
         return($self->{SubDataObj}->{$current->{class}}->getRecordImageUrl(
                $current));
      }
      else{
         return(
            $self->{SubDataObj}->{"base::workflow::Archive"}->getRecordImageUrl(
            $current));
      }
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
   if (!defined($self->{SubDataObj}->{$class})){
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
   return($classobj->nativProcessInitiate($action,$h,$step,$WfRec));
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
   return(undef) if (!defined($h));
   if (defined($h->{mandatorid})){
      my @curval=($h->{mandatorid});
      @curval=@{$h->{mandatorid}} if (ref($h->{mandatorid}) eq "ARRAY");
      my $mand=getModuleObject($self->Config,"base::mandator");
      $mand->ResetFilter();
      if (grep(/^all$/,@curval)){
         $mand->SetFilter({cistatusid=>[4]});
      }
      else{
         $mand->SetFilter({grpid=>\@curval});
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
            $mand->SetFilter({grpid=>\@curval}); 
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

   if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
      $sitename=~s/^http:/https:/i;
   }
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
use kernel;
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
   my $clientname=kernel::getClientAddrIdString(1);
   $clientname="127.0.0.1" if (!defined($clientname));
   return({$self->Name()=>$clientname}) if (!defined($oldrec));

   return({});
}


package base::workflow::WorkflowRelation;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::MenuTree;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   if (!defined($self->{WSDLfieldType})){
      $self->{WSDLfieldType}="WorkflowRelations";
   }
   return($self);
}



sub ListRel
{
   my $self=shift;
   my $refid=shift;
   my $mode=shift;
   my $rootflt=shift;
   my $d="";
   my $fo=$self->getRelationObj();
   my @filelist=();

   my @oplist=({srcwfid=>\$refid},"right","");
   if ($mode ne "edit"){
      push(@oplist,({dstwfid=>\$refid},"left","REV."));
   }
               
   $d="";
   my $headadd=0;
   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/auth/.*$##;
   }


   my $relcount=0;

   my $isadmin=0;
   my @relations;

   if ($mode eq "edit"){  # parameters only neasesary in edit mode
      $isadmin=$self->getParent->IsMemberOf("admin"); 
      my $wf=$self->getParent;
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$refid});
      my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
      if (defined($WfRec)){
         my %relmap=$self->getPosibleRelations($WfRec);
         @relations=values(%relmap);
      }
   }

   while(my $flt=shift(@oplist)){
      my $ico=shift(@oplist);
      my $transpref=shift(@oplist);
      $fo->ResetFilter();
      my %curflt=%$flt;
      if (defined($rootflt)){
         foreach my $k (keys(%$rootflt)){
            $curflt{$k}=$rootflt->{$k};
         }
      }
      $fo->SetFilter(\%curflt);

      foreach my $rec ($fo->getHashList(qw(mdate id dstwfid srcwfid
                                           translation additional
                                           dstwfheadref srcwfheadref
                                           dststate srcstate
                                           dstwfname srcwfname 
                                           name comments))){
         if (defined($rec)){
            if ($mode ne "mail"){
               if (!$headadd){
                  $d.="<div class=${mode}SubList>";
                  $d.="<table width=\"100%\" border=0 ".
                      "cellspacing=0 cellpadding=0>";
                  $headadd=1;
               }
            }
            my $onclick;
            my $partnerid=$rec->{dstwfid};
            if ($transpref eq "REV."){
               $partnerid=$rec->{srcwfid};
            }
           
            $onclick="onClick=openwin(\"../../base/workflow/Process?".
                     "AllowClose=1&id=$partnerid\",\"_blank\",".
                     "\"height=480,width=640,toolbar=no,status=no,".
                     "resizable=yes,scrollbars=no\")";
            if ($mode eq "edit"){
               $onclick="onClick=linkedit($rec->{id})";
            }

            my $lineclass="subline"; 
            if ($mode ne "mail"){
               $d.="<tr class=\"$lineclass\"><td>";
            }


            my $rowspan=1;
            if ($mode ne "mail"){
               $d.="<table width=\"100%\" border=0 ".
                   "cellspacing=0 cellpadding=0>";
               $d.="<tr><td width=\"1%\" valign=top ".
                   "nowrap style=\"border-top:solid;".
                   "border-width:1px;border-top-color:silver\">";
               if ($mode ne "edit"){
                  my $clicktitle=$self->getParent->T("click to open relation");
                  $d.="<a class=sublink title='$clicktitle' ".
                      "href=javascript:openwin(\"".
                      "../../base/workflowrelation/Detail?AllowClose=1&".
                      "id=$rec->{id}\",\"_blank\",\"height=480,width=640,".
                      "toolbar=no,status=no,resizable=yes,scrollbars=no\")>";
               }
               $d.="<img src=\"../../base/load/workflowrelation_$ico.gif\" ".
                   "border=0>";
               if ($mode ne "edit"){
                  $d.="</a>";
               }
               $d.="&nbsp;</td>";
            }
            next if ($mode eq "" && !$fo->isViewValid($rec));
            my $label=$rec->{name};
            my $partner=$rec->{dstwfname};
            my $partnerstateid=$rec->{dststate};
            my $stateobj=$fo->getField("dststate");
            my $partnerstate=$stateobj->FormatedDetail($rec);

            my $iid=$rec->{dstwfid};
            my $lnkid=$rec->{dstwfid};
            if ($rec->{dstwfsrcid} ne ""){
               $iid.="($rec->{dstwfsrcid})"; 
            }
            if ($transpref eq "REV."){
               $iid=$rec->{srcwfid};
               if ($rec->{srcwfsrcid} ne ""){
                  $iid.="($rec->{srcwfsrcid})"; 
               }
               $lnkid=$rec->{srcwfid};
               $partner=$rec->{srcwfname};
               $partnerstate=$rec->{srcstate};
               $stateobj=$fo->getField("srcstate");
               $partnerstate=$stateobj->FormatedDetail($rec);
            }
            my $transl=$rec->{translation};
            $transl="base::workflow::WorkflowRelation" if ($transl eq "");
            my $trlabel=$self->getParent->T($transpref.$label,$transl); 
            if ($trlabel=~m/\%s/){
               $trlabel=sprintf($trlabel,$iid);
            }
            else{
               $trlabel.=" : $iid";
            }


            $relcount++;
            if ($mode eq "mail"){
               $d.="---\n" if ($d ne "");
               $d.="<li class=workflowrelations><b>".$trlabel."</b>\n";
               $d.="$partner\n";
               $d.="$baseurl/auth/base/workflow/ById/$lnkid </li>\n";
            }
            else{
               my $pref="";
               my @show=();
               if (ref($rec->{additional}->{show}) eq "ARRAY"){
                  @show=@{$rec->{additional}->{show}};
               }
               if (grep(/^headref.taskexecstate$/,@show)){
                  my $p="?";
                  if ($transpref eq "REV."){
                     $p=$rec->{srcwfheadref}->{taskexecstate};
                  }
                  else{
                     $p=$rec->{dstwfheadref}->{taskexecstate};
                  }
                  $p=$p->[0] if (ref($p) eq "ARRAY");
                  $pref=sprintf("%d \%",$p) if ($p ne "");
                  $pref="<font color=\"green\">$pref</font>" if ($p==100);
                  $pref="($pref)" if ($pref ne "");
                  $pref.=" " if ($pref ne "");
               }
               if ($mode eq "edit"){
                  if (!$isadmin){
                     if ($transpref eq "REV."){
                        $onclick="";   # REV Records are not editable by user
                     }
                     else{
                        if (!in_array(\@relations,$rec->{name})){
                           $onclick="";
                        }
                     }
                     if ($onclick eq ""){
                        $onclick=
                           "onclick=\"alert('This record is read only');\"";
                     }
                  }
               }
               #print STDERR Dumper($rec->{additional});
               #print STDERR Dumper($rec->{dstwfheadref});
               #print STDERR Dumper($rec->{srcwfheadref});
               my $actstart="<b>";
               my $actend="<b>";
               if ($partnerstateid>20){
                  $actstart="<font color=gray>";
                  $actend="</font>";
               }
               $d.="<td $onclick valign=top ".
                   "style=\"border-top:solid;border-width:1px;".
                   "border-top-color:silver;cursor:pointer\">".
                   "<div style='float:left'>$actstart".$trlabel.
                   "$actend $pref</div>".
                   "<div style='float:right;white-space:nowrap;".
                   "width:20%;margin-right:5px;text-align:right'>".
                   "$actstart$partnerstate$actend</div>".
                   "</td></tr>";
               my $clicktitle=$self->getParent->T("click to open ".
                                                  "target workflow");
               if ($partner ne ""){
                  $d.="<tr><td></td><td $onclick style='cursor:pointer' ".
                      "title='$clicktitle'>".
                      $partner."</td></tr>";
               }
               if ($transpref ne "REV."){
                  if ($rec->{comments} ne ""){ #comment are not displayed in rev
                     $d.="<tr><td></td><td $onclick style='cursor:pointer' ".
                         "title='$clicktitle'>".
                         $rec->{comments}."</td></tr>";
                  }
               }
               $d.="</table>";
               $d.="</td></tr>";
            }
         }
      }
   }
   if (!$relcount){
      return("");
   }
   if ($mode ne "mail"){
      $d.="</table>" if ($headadd);
      $d.="</div>" if ($headadd);
   }
   else{
      $d="<ul class=workflowrelations>".$d."</ul>";
   }
   return($d);
}

sub getRelationObj
{
   my $self=shift;

   my $fo=$self->{fo};
   if (!defined($fo)){
      $fo=getModuleObject($self->getParent->Config,"base::workflowrelation");
      $fo->setParent($self->getParent());
      $self->{fo}=$fo;
   } 
   $fo->ResetFilter();
   return($fo);
}

sub getPosibleRelations
{
   my $self=shift;
   return($self->getParent->getPosibleRelations(@_));
}

sub validateRelationWrite
{
   my $self=shift;
   return($self->getParent->validateRelationWrite(@_));
}


sub HandleAdd
{
   my $self=shift;
   my $refid=shift;
   my $d="";
   my $oldrec;
   my $id=Query->Param("id");
   if ($id ne ""){
      my $fo=$self->getRelationObj();
      $fo->SetFilter({id=>\$id});
      my ($rec,$msg)=$fo->getOnlyFirst(qw(ALL));
      $oldrec=$rec if (defined($rec));
   }
   

   my $wf=$self->getParent;
   $wf->ResetFilter();
   $wf->SetFilter({id=>\$refid});
   my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
   my @relations=$self->getPosibleRelations($WfRec);

   my $parentobj=$self->{parentobj};
   if (!defined($parentobj)){
      $parentobj=$self->getParent->Self();
   }
   if (Query->Param("CANCEL") ne ""){
      Query->Delete("id");
      print <<EOF;
<script language=JavaScript>
parent.document.forms[0].elements['id'].value='';
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   if (Query->Param("DEL") ne ""){
      my $fo=$self->getRelationObj();
      my $ok=0;
      if (defined($oldrec)){
         if (my $fid=$fo->ValidatedDeleteRecord($oldrec)){
            $ok=1;
         }
      }
      print join("<br>",$self->getParent->LastMsg());

      print <<EOF  if ($ok);
<script language=JavaScript>
parent.document.forms[0].elements['id'].value='';
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   if (Query->Param("ADD") ne ""){
      my $opid=Query->Param("opid");
      my $ok=0;
      $opid=~s/[\s\*\?]//g;
      if (!($opid=~m/^[0-9]+$/)){
         my ($extractopid)=$opid=~m/([0-9]{5,20})/;
         if (defined($extractopid)){
            $opid=$extractopid;
         }
      }
      if (defined($opid) && $opid ne ""){
         my $wf=$self->getParent;
         $wf->ResetFilter();
         $wf->SetFilter({id=>\$opid});
         my ($lnkWfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         if (!defined($lnkWfRec)){
            $wf->ResetFilter();
            $wf->SetFilter({srcid=>\$opid});
            ($lnkWfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         }
         if (defined($lnkWfRec)){
            my $fo=$self->getRelationObj();
            my @r=@relations;
            my $translation;
            my $name=Query->Param("name");
            while(my $trans=shift(@r)){
               my $opt=shift(@r);
               if ($opt eq $name){
                  $translation=$trans;
                  last;
               }
            }
            my $comments=Query->Param("comments");
            my %rec=(dstwfid=>$lnkWfRec->{id},
                     srcwfid=>$refid,
                     name=>$name,
                     translation=>$translation,
                     comments=>$comments);
            if (defined($oldrec)){
              if (my $fid=$fo->ValidatedUpdateRecord($oldrec,\%rec,{id=>\$id})){
                 $self->getParent->LastMsg(INFO,"ok");
                 $ok=1;
              }
            }
            else{
              if (my $fid=$fo->ValidatedInsertRecord(\%rec)){
                 $self->getParent->LastMsg(INFO,"ok");
                 $ok=1;
              }
           }
         }
      }
      else{
         $self->getParent->LastMsg(ERROR,"no WorkflowID specified");
         
      }
      print join("<br>",$self->getParent->LastMsg());

      print <<EOF  if ($ok);
<script language=JavaScript>
parent.document.forms[0].elements['id'].value='';
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   my $oldname;
   my $opid;
   my $comments;
   if ($id ne ""){
      my $wr=$self->getRelationObj();
      $wr->SetFilter({id=>\$id});
      my ($relrec,$msg)=$wr->getOnlyFirst(qw(ALL));
      if (defined($relrec)){
         $opid=$relrec->{dstwfid};
         $oldname=$relrec->{name};
         $comments=$relrec->{comments};
      }
      else{
         Query->Delete("id");
         $id=undef;
      }
   }
   my $lableADD=$self->getParent->T("Add",$self->Self);
   my $lableCANCEL=$self->getParent->T("Cancel",$self->Self);
   my $lableDELETE=$self->getParent->T("Delete",$self->Self);
   my $lableUPDATE=$self->getParent->T("Update",$self->Self);
   my $buttons="<input type=submit name=ADD ".
               "style=\"width:100px\" value=\"$lableADD\">";
   if (defined($oldrec)){
      $buttons="<input type=submit name=ADD ".
               "style=\"width:100px\" value=\"$lableUPDATE\">".
               "<input type=submit name=DEL ".
               "style=\"width:100px\" value=\"$lableDELETE\">".
               "<input type=submit name=CANCEL ".
               "style=\"width:100px\" value=\"$lableCANCEL\">";
   }
   my $namedrop="<select name=name style=\"width:100%\">";
   while(my $trans=shift(@relations)){
      my $opt=shift(@relations);
      $namedrop.="<option value=\"$opt\"";
      $namedrop.=" selected" if ($oldname eq $opt);
      $namedrop.=">";
      $namedrop.=sprintf($self->getParent->T($opt,$trans),"&lt;?&gt;");
      $namedrop.="</option>";
   }
   $namedrop.="</select>";

   my $lableComments=$self->getParent->T("Comments",$self->Self);
   my $lableRelation=$self->getParent->T("Relation",$self->Self);
   $d.=<<EOF;
<div class=EditFrame>
<table width="100%" cellpadding=1 cellspacing=1 height=40 border=0>
<tr height=1%>
<td width=1%>WorkflowID:</td>
<td><input type=text name=opid style="width:100%" value="$opid" size=20></td>
<td width=1% nowrap>$buttons</td>
</tr><tr><td></td></tr>
<tr height=1%>
<td width=1%>$lableRelation:</td>
<td colspan=2>$namedrop</td>
</tr><tr><td></td></tr>
<tr height=1%>
<td width=1%>$lableComments:</td>
<td colspan=2><input type=text name=comments value="$comments" style="width:100%"></td>
</tr><tr><td></td></tr>
</table>
</div>
<script language=JavaScript>
function linkedit(id){
   document.forms[0].elements['id'].value=id;
   document.forms[0].target='_self';
   document.forms[0].submit();
}
</script>
EOF
   print $d;
}

sub ViewProcessor
{
   my $self=shift;
   my ($mode,$refid,$id,$field,$seq)=@_;

   my $fo=$self->getRelationObj();
   
   my $idfield=$self->getParent->IdField->Name();
   $self->getParent->ResetFilter();
   $self->getParent->SetFilter({$idfield=>\$refid});
   $self->getParent->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$self->getParent->getFirst();
   my @l=$self->getParent->isViewValid($rec);
   if (defined($rec) && (grep(/^$self->{group}$/,@l) || grep(/^ALL$/,@l))){
      $fo->ResetFilter();
      $fo->SetFilter({fid=>\$id});
      $fo->SetCurrentView(qw(ALL));
      my ($frec,$msg)=$fo->getFirst();
      if (defined($frec) && $fo->isViewValid($frec)){
          $fo->sendFile($id,0);
      }
      else{
         print $self->getParent->HttpHeader("text/plain");
         print("ERROR: No Access to file");
      }
      return();
   }
   print $self->getParent->HttpHeader("text/plain");
   print("ERROR: No Access to filelist");
}


sub EditProcessor
{
   my $self=shift;
   my $edtmode=shift;
   my $refid=shift;
   my $fieldname=shift;
   my $seq=shift;
   print $self->getParent->HttpHeader("text/html");
   print $self->getParent->HtmlHeader(style=>['default.css','work.css',
                                              'kernel.workflowrelation.css'],
                                              body=>1,form=>1,
                                      formtarget=>'DO');
   if (!defined(Query->Param("MODE"))){
      Query->Param("MODE"=>"FileListMode.FILEADD");
   }
   print("<div class=WorkflowRelation>");
   $self->HandleAdd($refid);
   return() if (Query->Param("CANCEL") ne "");
   return() if (Query->Param("SAVE") ne "");
   return() if (Query->Param("ADD") ne "");
   return() if (Query->Param("DEL") ne "");
   print <<EOF;
<iframe style="width:97%;height:25px;overflow:hidden;border-style:none;padding:0;margin:0" 
        name=DO src=Empty scrolling="no" frameborder="0"></iframe>
EOF
   my $mode="edit";
   print $self->ListRel($refid,$mode);
   print $self->getParent->HtmlPersistentVariables(qw(MODE OP Field Seq id
                                                      RefFromId));
   print("</div>");
   print $self->getParent->HtmlBottom(form=>1,body=>1);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $app=$self->getParent;
   my $idfield=$app->IdField();
   my $id=$idfield->RawValue($current);
   my $name=$self->Name();
   $self->{Sequence}++;

   if ($mode eq "HtmlDetail"){
      return($self->ListRel($id));
   }
   if ($mode eq "edit"){
      my $h=$self->getParent->DetailY()-240;
      return(<<EOF);
<iframe id=iframe.sublist.$name.$self->{Sequence}.$id 
        src="EditProcessor?RefFromId=$id&Field=$name&Seq=$self->{Sequence}"
        style="width:99%;height:${h}px;border-style:solid;border-width:1px;">
</iframe>
EOF

   }
   return($self->SUPER::FormatedDetail($current,$mode));
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;

   my $fo=$self->getRelationObj();
   my $d=$self->RawValue($current);
   $d=[$d] if (ref($d) ne "ARRAY");

   if ($FormatAs eq "SOAP"){
      my $out="";
      foreach my $rel (@$d){
         $out.="<subrecord>";
         foreach my $fieldname (keys(%$rel)){
            my $fobj=$fo->getField($fieldname,$current);
            $out.="<$fieldname>".$fobj->FormatedResult($rel,$FormatAs).
                  "</$fieldname>";
         }
         $out.="</subrecord>";
      }
      return($out);
   }
   else{
      my @out;
      my $out;
      my $idfld=$self->getParent->IdField();
      my $refid=$idfld->RawValue($current);
      foreach my $rel (@$d){
         if ($refid eq $rel->{srcwfid}){
            push(@out,$rel->{name}."->".$rel->{dstwfid}.
                      "(".$rel->{dstwfclass}.")");
         }
         elsif ($refid eq $rel->{dstwfid}){
            push(@out,"REV.".$rel->{name}."<-".$rel->{srcwfid}.
                      "(".$rel->{srcwfclass}.")");
         }
      }
      $out=join("\n",@out);
      return($out);
   }
   return("-error-");
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $idfld=$self->getParent->IdField();
   my $refid=$idfld->RawValue($current);
   my $fo=$self->getRelationObj();

   my @flt=({srcwfid=>\$refid},{dstwfid=>\$refid});
   $fo->SetFilter(\@flt);
   my @lst;

   foreach my $rec ($fo->getHashList(qw(mdate id dstwfid srcwfid
                                        dstwfclass srcwfclass
                                        dststate
                                        dstwfname srcwfname name comments))){
      my %drec=(%$rec);
      push(@lst,\%drec);
   }
   return(\@lst);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   my $idfield=$self->getParent->IdField()->Name();
   my $id=$oldrec->{$idfield};
   my $wr=$self->getRelationObj();
   if ($id ne ""){ 
      $wr->SetFilter([{srcwfid=>\$id},{dstwfid=>\$id}]);
      $wr->SetCurrentView(qw(ALL));
      $wr->ForeachFilteredRecord(sub{
                         $wr->ValidatedDeleteRecord($_);
                      });
   }
   return(undef);
}



sub Uploadable
{
   my $self=shift;

   return(0);
}












package base::workflow::sactions;
use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::SubList);

sub new
{
   my $type=shift;
   my %self=@_;
   $self{WSDLfieldType}="WorkflowActions" if (!defined($self{WSDLfieldType}));

   my $self=bless($type->SUPER::new(%self),$type);
   return($self);
}

sub EditProcessor
{
   my $self=shift;
   my $edtmode=shift;
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

sub getLineSubListData
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;

   if ($mode eq "xls"){
      my $dd=$current->{$self->Name};
      my $d; 
      if (ref($dd) eq "ARRAY"){
         foreach my $arec (@{$dd}){
            $d.="--\n" if ($d ne "");
            $d.=$self->getParent->ExpandTimeExpression($arec->{cdate},
                                               $self->getParent->Lang(),"GMT");
            $d.=": ";
            $d.=$self->getParent->T($arec->{name},$arec->{translation})."\n";
            if ($arec->{comments} ne ""){
               $d.=$arec->{comments}."\n";
            }
         }
      }
      return($d);
   }
   return($self->SUPER::getLineSubListData($current,$mode));
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
