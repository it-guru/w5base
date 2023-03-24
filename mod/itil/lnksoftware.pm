package itil::lnksoftware;
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
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                dataobjattr   =>'lnksoftwaresystem.id'),
 
      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                searchable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>$self->SoftwareInstFullnameSql()),
                                                 
      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                label         =>'Software',
                vjoineditbase =>{pclass=>\'MAIN',cistatusid=>[3,4]},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::Text(
                name          =>'version',
                htmlwidth     =>'50px',
                group         =>'instdetail',
                label         =>'Version',
                dataobjattr   =>'lnksoftwaresystem.version'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'system',
                htmlwidth     =>'100px',
                label         =>'System',
                searchable    =>0,
                vjointo       =>'itil::system',
                vjoinon       =>['systemid'=>'id'],
                vjoineditbase =>{cistatusid=>"<6",isembedded=>\'0'},
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (defined($current) &&
                                 $current->{insttyp} ne "System");
                   return(1);
                },
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'itclustsvc',
                htmlwidth     =>'100px',
                searchable    =>0,
                label         =>'ClusterService',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (defined($current) &&
                                 $current->{insttyp} ne "ClusterService");
                   return(1);
                },
                vjointo       =>'itil::lnkitclustsvc',
                vjoinon       =>['itclustsvcid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Date(
                name          =>'instdate',
                group         =>'instdetail',
                label         =>'Installation date',
                dataobjattr   =>'lnksoftwaresystem.instdate'),
                                                   
      new kernel::Field::Text(
                name          =>'instpath',
                group         =>'instdetail',
                label         =>'Installation path',
                dataobjattr   =>'lnksoftwaresystem.instpath'),
                                                   
      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'lnksoftwaresystem.comments'),

#      new kernel::Field::Text(
#                name          =>'releasekey',
#                readonly      =>1,
#                htmldetail    =>0,
#                group         =>'releaseinfos',
#                label         =>'Releasekey',
#                dataobjattr   =>'lnksoftwaresystem.releasekey'),

      new kernel::Field::Text(
                name          =>'releasekey',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Releasekey',
                depend        =>['version'],
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $version=$current->{version};
                   return(itil::lib::Listedit::Version2Key($version));
                }),
                                                   
      new kernel::Field::Text(
                name          =>'majorminorkey',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'releaseinfos',
                label         =>'majorminorkey',
                dataobjattr   =>'lnksoftwaresystem.majorminorkey'),
                                                   
      new kernel::Field::Text(
                name          =>'patchkey',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'releaseinfos',
                label         =>'patchkey',
                dataobjattr   =>'lnksoftwaresystem.patchkey'),
                                                   
      new kernel::Field::Text(
                name          =>'insttyp',
                label         =>'Installationtyp',
                readonly      =>1,
                selectfix     =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (!defined($current));
                   return(1);
                },
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "'System',".
                   "'ClusterService')"),

      new kernel::Field::TextDrop(
                name          =>'pfullname',
                label         =>'main installation',
                vjointo       =>\'itil::lnksoftware',
                vjoinon       =>['parentsoftwareid'=>'id'],
                translation   =>'itil::lnksoftware',
                vjoindisp     =>'fullname',
                weblinkto     =>'NONE',
                searchable    =>0,
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if (!defined($current) ||
                                 $current->{softwareinstpclass} ne "OPTION");
                   return(1);
                }),
                                                 
      new kernel::Field::TextDrop(
                name          =>'liccontract',
                htmlwidth     =>'100px',
                group         =>'lic',
                AllowEmpty    =>1,
                label         =>'License contract',
                vjointo       =>'itil::liccontract',
                vjoinon       =>['liccontractid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Number(
                name          =>'quantity',
                htmlwidth     =>'40px',
                group         =>'lic',
                precision     =>2,
                label         =>'Quantity',
                dataobjattr   =>'lnksoftwaresystem.quantity'),

      new kernel::Field::Select(
                name          =>'licsubof',
                label         =>'is sub licensed product of',
                group         =>'lic',
                jsonchanged   =>\&getOnChangedScript,
                jsoninit      =>\&getOnChangedScript,
                allowempty    =>1,
                vjointo       =>'itil::lnksoftware',
                vjoinbase     =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @flt;
                   my $sys=$current->{systemid};
                   if ($sys ne ""){
                      push(@flt,{systemid=>\$sys});
                   }
                   return(\@flt);
                },
                vjoinon       =>['licsubofid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'licsubofid',
                group         =>'lic',
                dataobjattr   =>'lnksoftwaresystem.licsubof'),

      new kernel::Field::Text(
                name          =>'licproduct',
                group         =>'lic',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'License product',
                dataobjattr   =>'licproduct.name'),
                                                 
      new kernel::Field::Number(
                name          =>'licrelevantcpucount',
                group         =>'lic',
                precision     =>0,
                readonly      =>0,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant logical cpu count',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantosrelease',
                group         =>'lic',
                searchable    =>0,
                readonly      =>0,
                htmldetail    =>0,
                label         =>'license relevant os release',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantsystemclass',
                group         =>'lic',
                searchable    =>0,
                readonly      =>0,
                htmldetail    =>0,
                label         =>'license relevant system class',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantopmode',
                group         =>'lic',
                searchable    =>0,
                readonly      =>0,
                htmldetail    =>0,
                label         =>'license relevant operation mode',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Mandator(
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1,
                label         =>'Mandator of relevant Config-Item'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "system.mandator,".
                   "itclust.mandator)"),

      new kernel::Field::Select(
                name          =>'cicistatus',
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1,
                htmleditwidth =>'40%',
                label         =>'CI-State of relevant Config-Item',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cicistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                htmldetail    =>0,
                name          =>'cicistatusid',
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "system.cistatus,".
                   "itclust.cistatus)"),

      new kernel::Field::Databoss(
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'databossid',
                group         =>'link',
                dataobjattr   =>
                   "if (lnksoftwaresystem.system is not null,".
                   "system.databoss,".
                   "itclust.databoss)"),

      new kernel::Field::TextDrop(
                name          =>'softwareproducer',
                label         =>'Software Producer',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'softwaredetails',
                vjointo       =>'itil::producer',
                vjoinon       =>['softwareproducerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'softwareproducerid',
                group         =>'softwaredetails',
                dataobjattr   =>'software.producer'),

      new kernel::Field::Select(
                name          =>'softwarecistatus',
                group         =>'softwaredetails',
                searchable    =>0,
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Software CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['softwarecistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Link(
                name          =>'softwarecistatusid',
                label         =>'SoftwareCiStatusID',
                group         =>'softwaredetails',
                dataobjattr   =>'software.cistatus'),

      new kernel::Field::Text(
                name          =>'softwareinstpclass',
                label         =>'Software installation class',
                htmldetail    =>0,
                readonly      =>1,
                selectfix     =>1,
                group         =>'softwaredetails',
                dataobjattr   =>'software.productclass'),

      new kernel::Field::Boolean(
                name          =>'is_dbs',
                label         =>'is DBS (Databasesystem) software',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'softwaredetails',
                dataobjattr   =>'software.is_dbs'),

      new kernel::Field::Boolean(
                name          =>'is_mw',
                label         =>'is MW (Middleware) software',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'softwaredetails',
                dataobjattr   =>'software.is_mw'),

      new kernel::Field::Select(
                name          =>'rightsmgmt',
                label         =>'rights managed',
                readonly      =>1,
                htmldetail    =>0,
                selectfix     =>1,
                group         =>'link',
                transprefix   =>'right.',
                value         =>['OPTIONAL','YES','NO'],
                translation   =>'itil::software',
                htmleditwidth =>'100px',
                dataobjattr   =>'software.rightsmgmt'),
      
      new kernel::Field::Textarea(
                name          =>'rightsmgmtstatus',
                searchable    =>0,
                htmldetail    =>0,
                group         =>'link',
                label         =>'rights management status (BETA!)',
                onRawValue    =>\&calcRightsMgmtState),

      new kernel::Field::Mandator(
                label         =>'License Mandator',
                name          =>'liccontractmandator',
                vjoinon       =>'liccontractmandatorid',
                htmldetail    =>0,
                group         =>'link',
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'liccontractmandatorid',
                label         =>'LicenseMandatorID',
                group         =>'link',
                dataobjattr   =>'liccontract.mandator'),

      new kernel::Field::Select(
                name          =>'liccontractcistatus',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'link',
                label         =>'License CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['liccontractcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'liccontractcistatusid',
                selectfix     =>1,
                label         =>'LiccontractCiStatusID',
                dataobjattr   =>'liccontract.cistatus'),

      new kernel::Field::SubList(
                name          =>'options',
                label         =>'installed Options',
                group         =>'options',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.options',
                vjointo       =>'itil::lnksoftwareoption',
                vjoinon       =>['id'=>'parentid'],
                vjoindisp     =>['fullname']),
                                                   
      new kernel::Field::Text(
                name          =>'insoptionlist',
                label         =>'Optionlist',
                group         =>'options',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'itil::lnksoftwareoption',
                vjoinon       =>['id'=>'parentid'],
                vjoindisp     =>['software']),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                htmldetail    =>'NotEmpty',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'lnksoftwaresystemid'],
                vjoindisp     =>['fullname','appl'],
                vjoininhash   =>['fullname','swnature','is_dbs','applid',
                                 'is_mw','cistatusid','id',
                                 'systemid','itclustsid']),

      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'lnksoftwaresystem.software'),
                                                   
      new kernel::Field::Link(
                name          =>'parentsoftwareid',
                label         =>'ParentSoftwareID',
                dataobjattr   =>'lnksoftwaresystem.parent'),
                                                   
      new kernel::Field::Link(
                name          =>'liccontractid',
                label         =>'LicencenseID',
                dataobjattr   =>'lnksoftwaresystem.liccontract'),
                                                   
      new kernel::Field::Interface(
                name          =>'systemid',
                selectfix     =>1,
                label         =>'SystemId',
                dataobjattr   =>'lnksoftwaresystem.system'),

      new kernel::Field::Interface(
                name          =>'itclustsvcid',
                label         =>'ClusterServiceID',
                selectfix     =>1,
                dataobjattr   =>'lnksoftwaresystem.lnkitclustsvc'),

     new kernel::Field::Text(
                name          =>'softwareset',
                readonly      =>1,
                htmldetail    =>0,
                selectsearch  =>sub{
                   my $self=shift;
                   my $ss=getModuleObject($self->getParent->Config,
                                          "itil::softwareset");
                   $ss->SecureSetFilter({cistatusid=>4});
                   my @l=$ss->getVal("name");
                   unshift(@l,"");
                   return(@l);
                },
                searchable    =>1,
                group         =>'softsetvalidation',
                htmlwidth     =>'200px',
                htmlnowrap    =>1,
                label         =>'validate against Software Set',
                onPreProcessFilter=>sub{
                   my $self=shift;
                   my $hflt=shift;
                   if (defined($hflt->{$self->{name}})){
                      my $f=$hflt->{$self->{name}};
                      if (ref($f) ne "ARRAY"){
                         $f=~s/^"(.*)"$/$1/;
                         $f=[$f];
                      }
                      $self->getParent->Context->{FilterSet}={
                         $self->{name}=>$f
                      };
                      delete( $hflt->{$self->{name}})
                   }
                   else{
                      delete($self->getParent->Context->{FilterSet} );
                   }
                   return(0);
                },
                onRawValue    =>sub{
                   my $self=shift;
                   my $FilterSet=$self->getParent->Context->{FilterSet};
                   return($FilterSet->{softwareset});
                }),

     new kernel::Field::Text(
                name          =>'softwareinstrelstate',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                group         =>'softsetvalidation',
                label         =>'Software release state',
                onRawValue    =>\&itil::lib::Listedit::calcSoftwareState),

     new kernel::Field::Textarea(
                name          =>'softwareinstrelmsg',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                group         =>'softsetvalidation',
                label         =>'Software release message',
                onRawValue    =>\&itil::lib::Listedit::calcSoftwareState),

#     new kernel::Field::Select(
#                name          =>'denyupd',
#                group         =>'upd',
#                label         =>'installation update posible',
#                value         =>[0,10,20,30,99],
#                transprefix   =>'DENUPD.',
#                dataobjattr   =>'lnksoftwaresystem.denyupd'),

      new kernel::Field::Select(
                name          =>'denyupselect',
                label         =>'installation update posible',
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
                dataobjattr   =>'lnksoftwaresystem.denyupd'),


     new kernel::Field::Textarea(
                name          =>'denyupdcomments',
                group         =>'upd',
                label         =>'comments to Update/Upgrade posibilities',
                dataobjattr   =>'lnksoftwaresystem.denyupdcomments'),

     new kernel::Field::Date(
                name          =>'denyupdvalidto',
                group         =>'upd',
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
                label         =>'Update/Upgrade reject valid to',
                dataobjattr   =>'lnksoftwaresystem.denyupdvalidto'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnksoftwaresystem.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnksoftwaresystem.modifyuser'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnksoftwaresystem.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnksoftwaresystem.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'lnksoftwaresystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'lnksoftwaresystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'lnksoftwaresystem.srcload'),

      new kernel::Field::Text(                         # a hidden field, to
                name          =>'autodischint',        # track relation created
                label         =>'AutoDiscovery Relation',  # needs to be in 
                uivisible     =>0,
                searchable    =>0,
                container     =>'additional'),             # allow write


      new kernel::Field::Text(                         # a hidden field, to
                name          =>'srcautodischint',     # track relation created
                label         =>'AutoDiscovery Relation',  # needs to be in 
                htmldetail    =>"NotEmpty",
                group         =>'source',
                alias         =>'autodischint',
                searchable    =>0),             # allow write

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>'lnksoftwaresystem.additional'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnksoftwaresystem.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksoftwaresystem.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnksoftwaresystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnksoftwaresystem.realeditor'),
                                                   
   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(software softwareproducer 
                            version quantity insttyp cdate));
   $self->setWorktable("lnksoftwaresystem");
   return($self);
}

sub calcSoftwareState
{

   return(itil::lib::Listedit::calcSoftwareState($_[1],$_[2],
          "itil::lnksoftware"));
}

sub getOnChangedScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;

var l=document.forms[0].elements['Formated_liccontract'];
var q=document.forms[0].elements['Formated_quantity'];
var s=document.forms[0].elements['Formated_licsubof'];

if (s && q && l){
   var v=s.options[s.selectedIndex].value;
   if (v!="" && v!="[none]"){
      l.value="";
      q.value="0";
      l.disabled=true;
      q.disabled=true;
   }
   else{
      l.disabled=false;
      q.disabled=false;
   }
}

EOF
   return($d);
}



sub calcLicMetrics   # licrelevantopmode licrelevantosrelease 
{                    # licrelevantcpucount
   my $self=shift;
   my $current=shift;
   my @sysid;
   my $sysobj=getModuleObject($self->getParent->Config,"itil::system");
   my $appobj=getModuleObject($self->getParent->Config,"itil::appl");
   if ($current->{systemid} ne ""){  # is system installed
      $sysobj->SetFilter({id=>\$current->{systemid}});
   }
   else{
      my $itclustsvcid=$current->{itclustsvcid};
      if ($itclustsvcid ne ""){
         my $o=getModuleObject($self->getParent->Config,"itil::lnkitclustsvc");
         $o->SetFilter({id=>\$itclustsvcid});
         my ($svcrec)=$o->getOnlyFirst(qw(clustid applications));
         if (defined($svcrec)){
            if ($self->{name} eq "licrelevantopmode"){
               my @l;
               foreach my $apprec (@{$svcrec->{applications}}){
                  push(@l,$apprec->{applid});
               }
               if ($#l==-1){  # dieser Sonderfall muß noch behandelt werden
                  $appobj->SetFilter({id=>\@l,cistatusid=>"<6"});
               }
               else{
                  $appobj->SetFilter({id=>\@l,cistatusid=>"<6"});
               }
            }
            else{
               if ($svcrec->{clustid} ne ""){
                  $sysobj->SetFilter({cistatusid=>'<6',
                                      itclustid=>\$svcrec->{clustid}});
               }
            }
         }
         else{
            return("?");
         }
      } 
   }
   if ($self->{name} eq "licrelevantopmode"){
      if ($current->{systemid} ne ""){  # is system installed
         my $o=getModuleObject($self->getParent->Config,"itil::lnkapplsystem");
         $o->SetFilter({systemid=>\$current->{systemid}});
         my @applid=$o->getVal("applid");
         $appobj->ResetFilter();
         $appobj->SetFilter({id=>\@applid,cistatusid=>"<6"});
      }
      my %o;
      foreach my $apprec ($appobj->getHashList("opmode")){
        $o{$apprec->{opmode}}++;
      }
      return([sort(
                 map({$self->getParent->T('opmode.'.$_,"itil::appl")} keys(%o))
              )]);
   }
   my @res;
   if ($self->{name} eq "licrelevantcpucount" ||
       $self->{name} eq "licrelevantsystemclass" ||
       $self->{name} eq "licrelevantosrelease"){
      my %r;
      my %c;
      my $cpucount=0;
      foreach my $sysrec ($sysobj->getHashList(qw(cpucount osrelease osclass))){
         $r{$sysrec->{'osrelease'}}++;
         $c{$sysrec->{'osclass'}}++;
         $cpucount=$sysrec->{'cpucount'} if ($cpucount<$sysrec->{'cpucount'});
      }
      return([sort(keys(%r))]) if ($self->{name} eq "licrelevantosrelease");
      return([sort(keys(%c))]) if ($self->{name} eq "licrelevantsystemclass");
      return($cpucount) if ($self->{name} eq "licrelevantcpucount");
   }
   return(\@res);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnksoftware");
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my $from="lnksoftwaresystem left outer join software ".
            "on lnksoftwaresystem.software=software.id ".
            "left outer join lnkitclustsvc ".
            "on lnksoftwaresystem.lnkitclustsvc=lnkitclustsvc.id ".
            "left outer join itclust ".
            "on lnkitclustsvc.itclust=itclust.id ".
            "left outer join system ".
            "on lnksoftwaresystem.system=system.id ".
            "left outer join liccontract ".
            "on lnksoftwaresystem.liccontract=liccontract.id ".
            "left outer join licproduct ".
            "on liccontract.licproduct=licproduct.id ";

   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cicistatus"))){
     Query->Param("search_cicistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
   if (!defined(Query->Param("search_softwareinstpclass"))){
     Query->Param("search_softwareinstpclass"=>"MAIN");
   }
}


sub calcRightsMgmtState
{
   my $self=shift;
   my $current=shift;
   my @msg;

   if ($current->{rightsmgmt} eq "YES"){
      if ($current->{liccontractid} eq ""){
         push(@msg,"ERROR: ". 
              $self->getParent->T("missing required license contract"));
      }
   }
   if ($current->{liccontractid} ne ""){
      if ($current->{cicistatusid}==4){
         if ($current->{liccontractcistatusid}!=4){
            push(@msg,"ERROR: ". 
                 $self->getParent->T("licensing contract is not active"));
         }
      }
   }

   if ($#msg==-1){
      push(@msg,"OK");
   }
   return(join("\n",@msg));
}


sub SecureValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=$_[0];
   my $newrec=$_[1];

   if (defined($oldrec) && $oldrec->{softwareinstpclass} eq "OPTION"){
      if ($oldrec->{software} eq $newrec->{software}){
         delete($newrec->{software});  # Update of Software not allowed
      }
      delete($newrec->{systemid});  # Update of systemid not allowed
      delete($newrec->{parentid});  # Update of parentid not allowed
   }

   return($self->SUPER::SecureValidatedUpdateRecord(@_));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $softwareid=effVal($oldrec,$newrec,"softwareid");
   if ($softwareid==0){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   my $instpath=effVal($oldrec,$newrec,"instpath");
   if ($instpath ne ""){
      if (!($instpath=~m/^\/[a-z0-9\.\\_\/:-]+$/i) &&
          !($instpath=~m/^[A-Za-z]:\\[a-zA-Z0-9 \.\\_()-]+$/)){
         $self->LastMsg(ERROR,"invalid installation path");
         return(undef);
      }
      my $chkobj=$self->Clone();
      my $flt={softwareid=>\$softwareid,instpath=>\$instpath};
      my $systemid=effVal($oldrec,$newrec,"systemid");
      if ($systemid ne ""){
         $flt->{systemid}=\$systemid;
      }
      my $itclustsvcid=effVal($oldrec,$newrec,"itclustsvcid");
      if ($itclustsvcid ne ""){
         $flt->{itclustsvcid}=\$itclustsvcid;
      }
      if (defined($oldrec)){
         $flt->{id}="!\"$oldrec->{id}\"";
      }
      $chkobj->SetFilter($flt);
      if ($chkobj->CountRecords()>0){
         $self->LastMsg(ERROR,"installation with selected software ".
                              "already exists at specified installpath");
         return(undef);
      }
   }





   if (defined($oldrec)){
      if (effChanged($oldrec,$newrec,"softwareid")){
         if (ref($oldrec->{options}) eq "ARRAY" &&
             $#{$oldrec->{options}}!=-1){
            $self->LastMsg(ERROR,"change of software product not allowed ".
                                 "if there are options");
            return(undef);
         }
      }
   }
   if ((defined($newrec) && $newrec->{licsubofid} eq "") &&
       (defined($oldrec) && $oldrec->{licsubofid} eq "")){
      delete($newrec->{licsubofid});
   }
   if (effVal($oldrec,$newrec,"licsubofid") ne ""){
      if (effVal($oldrec,$newrec,"liccontractid") ne ""){
         $newrec->{liccontractid}=undef;
      }
      if (effVal($oldrec,$newrec,"quantity")!=0){
         $newrec->{quantity}=0;
      }
   }
   if (effChanged($oldrec,$newrec,"liccontractid")){
      my $licid=effVal($oldrec,$newrec,"liccontractid");
      my $quantity=effVal($oldrec,$newrec,"quantity");
      if ($quantity<=0){
         $quantity=1;
      }
      if ($licid ne ""){
         my $o=getModuleObject($self->Config,"itil::liccontract");
         $o->SetFilter({id=>\$licid});
         my ($licrec)=$o->getOnlyFirst(qw(ALL));
         if ($licrec->{units} ne ""){
            if ($licrec->{licfree}-$quantity<0){
               $self->LastMsg(ERROR,"not enouth free units in license");
               return(0);
            }
         }
      }
   }
   if (!defined($oldrec) && $newrec->{instdate} eq ""){
      $newrec->{instdate}=NowStamp("en");
   }


   return(undef) if (!$self->validateSoftwareVersion($oldrec,$newrec));

   my $version=effVal($oldrec,$newrec,"version");
   if ($version ne "" && exists($newrec->{version})){  #release details gen
      #VersionKeyGenerator($oldrec,$newrec);
      if (my ($rel,$patch)=$version=~m/^(.*\d)(p\d.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel,$patch)=$version=~m/^(.*\d)(SP\d.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel,$patch)=$version=~m/^(.*\d) (build.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel,$patch)=$version=~m/^(\d+\.\d+)\.(.*)$/){
         $newrec->{patchkey}=$patch;
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel)=$version=~m/^(\d+\.\d+)$/){
         $newrec->{patchkey}="";
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel)=$version=~m/^(\d+)$/){
         $newrec->{patchkey}="";
         $newrec->{majorminorkey}=$rel;
      }
      elsif (my ($rel)=$version=~m/^(\d+[\.\d+]{0,1})$/){
         $newrec->{patchkey}="";
         $newrec->{majorminorkey}=$rel;
      }
      else{
         $newrec->{patchkey}="?";
         $newrec->{majorminorkey}="?";
      }
      
   }
   if ($self->Self ne "itil::lnksoftwareoption"){
      my $itclustsvcid=effVal($oldrec,$newrec,"itclustsvcid");
      my $systemid=effVal($oldrec,$newrec,"systemid");
      if ($systemid==0 && $itclustsvcid==0){
         $self->LastMsg(ERROR,"invalid system specified");
         return(undef);
      }
      else{
         if (!$self->isParentWriteable($systemid,$itclustsvcid)){
            if (!defined($oldrec) &&
                $self->checkAlternateInstCreateRights($newrec)){
               msg(INFO,"alternate create of installation OK");
            }
            else{
               if (!defined($oldrec)){
                  msg(INFO,"new not allowed for any person");
                  $self->LastMsg(ERROR,"system is not writeable for you");
                  return(undef);
               }
               else{
                  if (($W5V2::OperationContext ne "QualityCheck") &&
                      !$self->isInstanceRelationWriteable($oldrec->{id}) &&
                      !$self->isLicManager(effVal($oldrec,$newrec,
                                                  "mandatorid"))){
                     msg(INFO,"no licensmanager and no instance writer");
                     $self->LastMsg(ERROR,"system is not writeable for you");
                     return(undef);
                  }
               }
            }
         }
      }
   }
   if (exists($newrec->{quantity}) && ! defined($newrec->{quantity})){
      delete($newrec->{quantity});
   }
   if (!$self->itil::lib::Listedit::updateDenyHandling($oldrec,$newrec)){
      return(0);
   } 

   return(1);
}

sub isLicManager
{
   my $self=shift;
   my $mandatorid=shift;

   if ($mandatorid ne ""){
      my @lim=$self->getMembersOf($mandatorid,
                                  [qw(RLIManager RLIManager2 RLIOperator)],
                                  'up');
      if ($#lim!=-1){
         return(1);
      }
   }
   return(0);
}


sub VersionKeyGenerator
{
   my $oldrec=shift;
   my $newrec=shift;

   my $version=effVal($oldrec,$newrec,"version");
   my $k=itil::lib::Listedit::Version2Key($version);
   if (!defined($oldrec) || $oldrec->{releasekey} ne $k){
      $newrec->{releasekey}=$k;
   }
   return($k);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header","instdetail") if (!defined($rec));
   if ($rec->{softwareinstpclass} eq "OPTION"){
      return(qw(default history source instdetail lic upd misc source));

   }
   return("ALL");
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
                   # (1/ALL=Ok) or undef if record could/should be not deleted
   my @l=grep(!/^$/,grep(!/^\!.*$/,grep(!/^.*\..+$/,
              $self->isWriteValid($rec))));
   return if ($#l==-1);
   return(1) if (in_array(\@l,["ALL","default"]));

   if ($rec->{softwareinstpclass} eq "OPTION"){
      # for options the group "misc" is the flag for delete allowing 
      # (instdetail is not ok, because this can be writeable on instance
      #  contacts)
      return(1) if (in_array(\@l,["misc"]));
   }
   return;
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   return("ALL") if ($W5V2::OperationContext eq "QualityCheck");

   $rw=1 if (!defined($rec));
   $rw=1 if (defined($rec) && $self->isParentWriteable($rec->{systemid},
                                                       $rec->{itclustsvcid}));
   $rw=1 if ((!$rw) && ($self->IsMemberOf("admin")));
   if ($rw){
      if (!defined($rec) ||    # on create of a record, "default" is always
          $rec->{softwareinstpclass} eq "MAIN"){  # need to write!
            return("default","lic","misc","instdetail","upd","options");
      }
      else{
         return("lic","misc","instdetail","upd","options");
      }
   }
   else{
      # check if there is an software instance based on this installation
      if ($rec->{softwareinstpclass} eq "MAIN"){
         if ($self->isInstanceRelationWriteable($rec->{id})){
            return(qw(instdetail options lic));
         }
      }
      if ($rec->{softwareinstpclass} eq "OPTION" &&
          exists( $rec->{parentid}) &&  # this is only in lnksoftwareoption
          $rec->{parentid} ne ""){      # derivation posible !
         if ($self->isInstanceRelationWriteable($rec->{parentid})){
            return(qw(instdetail options misc options upd lic));
         }
      }
   }
   my $mandatorid=$rec->{mandatorid};
   return("lic") if ($self->isLicManager($mandatorid));
   if (defined($rec) && $self->checkAlternateInstCreateRights($rec)){
      return("instdetail");
   }
   return(undef);
}

sub isInstanceRelationWriteable
{
   my $self=shift;
   my $id=shift;

   my $swi=getModuleObject($self->Config,"itil::swinstance");
   $swi->SetFilter({lnksoftwaresystemid=>\$id,
                    cistatusid=>"<=5"});
   foreach my $swirec ($swi->getHashList(qw(ALL))){
      my @l=$swi->isWriteValid($swirec);
      if (in_array(\@l,["ALL","default"])){
         return(1);
      }
   }
   return(0);
}

sub isParentWriteable  # Eltern Object Schreibzugriff prüfen
{
   my $self=shift;
   my $systemid=shift;
   my $itclustsvcid=shift;

   return(1) if (!defined($ENV{SERVER_SOFTWARE}));
   if ($systemid ne ""){
      my $sys=$self->getPersistentModuleObject("W5BaseSystem","itil::system");
      $sys->ResetFilter();
      $sys->SetFilter({id=>\$systemid});
      my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
      if (defined($rec) && $sys->isWriteValid($rec)){
         return(1);
      }
   }
   if ($itclustsvcid ne ""){
      my $svc=$self->getPersistentModuleObject("W5BaseITClustSVC",
                                               "itil::lnkitclustsvc");
      $svc->ResetFilter();
      $svc->SetFilter({id=>\$itclustsvcid});
      my ($rec,$msg)=$svc->getOnlyFirst(qw(ALL));
      if (defined($rec) && $svc->isWriteValid($rec)){
         return(1);
      }
   }
   return(0);
}

sub checkAlternateInstCreateRights
{
   my $self=shift;     # installation create for central instance support
   my $newrec=shift;   # teams

   my $softwareid=$newrec->{softwareid};

   return(0) if ($softwareid eq "");

   my $sw=getModuleObject($self->Config,"itil::software");
   $sw->SetFilter({id=>\$softwareid});
   my ($rec,$msg)=$sw->getOnlyFirst(qw(depcompcontactid compcontactid
                                         contacts));
   return(0) if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   if ($rec->{depcompcontactid} eq $userid || 
       $rec->{compcontactid} eq $userid) {
      $newrec->{alternateCreateRight}="1";
      return(1);
   }
   my $foundpmanager=0;
   if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ["RMember"],"up");
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
         if (in_array(\@roles,"pmanager")){
            $foundpmanager++;
         }
      }
   }
   if (!$foundpmanager){
      return(0);
   }

   $newrec->{alternateCreateRight}="1";  # store information about alternate
                                         # process for FinishWrite

   return(1);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bk=$self->SUPER::FinishDelete($oldrec);

   my $lnksoftwareid=$oldrec->{id};
   # Revert Prozess for AutoDisc based Software-Installations
   if (defined($oldrec) && $oldrec->{autodischint} ne "" &&
       $lnksoftwareid ne ""){
      # check if current record is based on an autodiscovery record
      my $o=getModuleObject($self->Config,"itil::autodiscrec");
      $o->SetFilter({lnkto_lnksoftware=>\$lnksoftwareid});
      my @l=$o->getHashList(qw(ALL));
      if ($#l!=-1){
         my $op=$o->Clone();
         foreach my $autodiscrec (@l){
            # reset posible existing autodisc records to "unprocessed"
            $op->ValidatedUpdateRecord(
                  $autodiscrec,
                  {state=>1,lnkto_lnksoftware=>undef},
                  {id=>\$autodiscrec->{id}}
            );
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
   if (!defined($oldrec)){
      if ($newrec->{alternateCreateRight} && $newrec->{id} ne "" &&
          $W5V2::OperationContext ne "QualityCheck"){  # no notification in
                                                       # QualityCheck Context
         # send a mail to system/cluster databoss with cc on current user
         my $swi=$self->Clone();
         $swi->SetFilter({id=>\$newrec->{id}});
         my ($swirec,$msg)=$swi->getOnlyFirst(qw(databossid fullname 
                                                 urlofcurrentrec));
         if (defined($swirec) && $swirec->{databossid} ne ""){
            my $userid=$self->getCurrentUserId();
            my $u=getModuleObject($self->Config,"base::user");


            $u->SetFilter({userid=>\$swirec->{databossid},
                           cistatusid=>"<6"});
            my ($urec,$msg)=$u->getOnlyFirst(qw(lastlang));
            my $lang="en";
            if (defined($urec) && $urec->{lastlang} ne ""){
               $lang=$urec->{lastlang};
            }
            $ENV{HTTP_FORCE_LANGUAGE}=$lang;

            $u->ResetFilter();
            $u->SetFilter({userid=>\$userid,
                           cistatusid=>"<6"});
            my ($cururec,$msg)=$u->getOnlyFirst(qw(fullname));
            my $curname=$ENV{REMOTE_USER};
            if (defined($cururec) && $cururec->{fullname} ne ""){
               $curname=$cururec->{fullname};
            }

            my $wfa=getModuleObject($self->Config,"base::workflowaction");
            my $msg="We like to inform you as databoss of a system ".
                    "or cluster. ".
                    "A new software installation was made by %s .\n\n".
                    "%s\n%s\n\n".
                    "If this is plausible to you, there is no todo and you ".
                    "can ignore this message. If not, contact %s to ".
                    "clarify this topic.";
                    
            $wfa->Notify("INFO",
                  $self->T("create of software installation record").
                           " ".$swirec->{fullname},
                         sprintf($self->T($msg),$curname,
                                                $swirec->{fullname},
                                                $swirec->{urlofcurrentrec},
                                                $curname),
                         emailto=>$swirec->{databossid},
                         emailcc=>[11634953080001,$userid]);
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }
      }
   }
   return($self->SUPER::FinishWrite($oldrec,$newrec));
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default instdetail lic options useableby 
             swinstances misc link 
             releaseinfos softsetvalidation
             upd source));
}








1;
