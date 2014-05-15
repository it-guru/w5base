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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                searchable    =>0,
                dataobjattr   =>'lnksoftwaresystem.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>
                   "concat(software.name,".
                   "if (lnksoftwaresystem.version<>'',".
                   "concat('-',lnksoftwaresystem.version),''),".
                   "if (lnksoftwaresystem.parent is null,".
                   "if (lnksoftwaresystem.system is not null,".
                   "concat(' (system installed\@',system.name,')'),".
 
                   "' (cluster service installed)'),' (Option)'))"),
                                                 
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

      new kernel::Field::Text(
                name          =>'releasekey',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'releaseinfos',
                label         =>'Releasekey',
                dataobjattr   =>'lnksoftwaresystem.releasekey'),
                                                   
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
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant logical cpu count',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantosrelease',
                group         =>'lic',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant os release',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantsystemclass',
                group         =>'lic',
                searchable    =>0,
                htmldetail    =>0,
                label         =>'license relevant system class',
                onRawValue    =>\&calcLicMetrics),
                                                 
      new kernel::Field::Text(
                name          =>'licrelevantopmode',
                group         =>'lic',
                searchable    =>0,
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
                group         =>'softwaredetails',
                dataobjattr   =>'software.productclass'),

      new kernel::Field::Boolean(
                name          =>'is_dbs',
                label         =>'is DBS (Databasesystem) software',
                htmldetail    =>1,
                readonly      =>1,
                group         =>'softwaredetails',
                dataobjattr   =>'software.is_dbs'),

      new kernel::Field::Boolean(
                name          =>'is_mw',
                label         =>'is MW (Middleware) software',
                htmldetail    =>1,
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
                vjointo       =>'itil::lnksoftwareoption',
                vjoinon       =>['id'=>'parentid'],
                vjoindisp     =>['software']),
                                                   
      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'lnksoftwaresystem.software'),
                                                   
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
                onRawValue    =>\&calcSoftwareState),

     new kernel::Field::Textarea(
                name          =>'softwareinstrelmsg',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                group         =>'softsetvalidation',
                label         =>'Software release message',
                onRawValue    =>\&calcSoftwareState),

     new kernel::Field::Select(
                name          =>'denyupd',
                group         =>'upd',
                label         =>'installation update posible',
                value         =>[0,10,20,30,99],
                transprefix   =>'DENUPD.',
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
                label         =>'Owner',
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
                label         =>'Source-System',
                dataobjattr   =>'lnksoftwaresystem.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnksoftwaresystem.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnksoftwaresystem.srcload'),
                                                   
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
                label         =>'Editor',
                dataobjattr   =>'lnksoftwaresystem.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'lnksoftwaresystem.realeditor'),
                                                   
   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(software softwareproducer 
                            version quantity insttyp cdate));
   $self->setWorktable("lnksoftwaresystem");
   return($self);
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


sub SetFilter
{
   my $self=shift;

   if (ref($_[0]) eq "HASH" && exists($_[0]->{softwareset})){
      my $setname=$_[0]->{softwareset};
      $setname=~s/^"(.*)"/$1/;
      $self->Context->{FilterSet}={
                                     softwareset=>$setname
                                  };
   }
   return($self->SUPER::SetFilter(@_));

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




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $instpath=effVal($oldrec,$newrec,"instpath");
   if ($instpath ne ""){
      if (!($instpath=~m/^\/[a-z0-9\.\\_\/:-]+$/i) &&
          !($instpath=~m/^[A-Za-z]:\\[a-zA-Z0-9\.\\_-]+$/)){
         $self->LastMsg(ERROR,"invalid installation path");
         return(undef);
      }
   }
   my $softwareid=effVal($oldrec,$newrec,"softwareid");
   if ($softwareid==0){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
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
   my $version=effVal($oldrec,$newrec,"version");
   my $sw=getModuleObject($self->Config,"itil::software");
   $sw->SetFilter({id=>\$softwareid});
   my ($rec,$msg)=$sw->getOnlyFirst(qw(releaseexp));
   if (!defined($rec)){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   my $releaseexp=$rec->{releaseexp};
   if (defined($ENV{SERVER_SOFTWARE})){
      if (!($releaseexp=~m/^\s*$/)){
         my $chk;
         eval("\$chk=\$version=~m$releaseexp;");
         if ($@ ne "" || !($chk)){
            $self->LastMsg(ERROR,"invalid software version specified");
            return(undef);
         }
      }
   }

   if ($version ne "" && exists($newrec->{version})){  #release details gen
      VersionKeyGenerator($oldrec,$newrec);
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
               #if (defined($oldrec)){
               #   my $mandatorid=effVal($oldrec,$newrec,"mandatorid");
               #   my @lim=$self->getMembersOf($mandatorid, 
               #                               [qw(RLIOperator)],'up');
               #   if ($#lim==-1){
               #      $self->LastMsg(ERROR,"system is not writeable for you");
               #      return(undef);
               #   }
               #}
               if ((!defined($oldrec) ||
                    !($self->isInstanceRelationWriteable($oldrec->{id}))) &&
                   !$self->isLicManager(effVal($oldrec,$newrec,"mandatorid"))){
                  $self->LastMsg(ERROR,"system is not writeable for you");
                  return(undef);
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
      my @lim=$self->getMembersOf($mandatorid, [qw(RLIOperator)],'up');
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

   my @v=split(/\./,$version);
   my @relkey=();
   for(my $relpos=0;$relpos<5;$relpos++){
      if ($v[$relpos]=~m/^\d+$/){
         $relkey[$relpos]=sprintf("%04d",$v[$relpos]);
      }
      else{
         $relkey[$relpos]="0000";
      }
   }
   $newrec->{releasekey}=join("",@relkey);
}



sub calcSoftwareState
{
   my $self=shift;
   my $current=shift;

   my $FilterSet=$self->getParent->Context->{FilterSet};
   if ($FilterSet->{softwareset} eq ""){
      return("NO SOFTSET SELECTED");
   }
   if ($FilterSet->{Set}->{name} ne $FilterSet->{softwareset} &&
       $FilterSet->{softwareset} ne ""){
      $FilterSet->{Set}={name=>$FilterSet->{softwareset}};
      my $ss=getModuleObject($self->getParent->Config,
                             "itil::softwareset");
      $ss->SecureSetFilter({cistatusid=>4,name=>\$FilterSet->{softwareset}});
      my ($rec)=$ss->getOnlyFirst("name","software","osrelease");
      if (!defined($rec)){
         return("INVALID SOFTSET SELECTED");
      }
      $FilterSet->{Set}->{data}=$rec;
      Dumper($FilterSet->{Set}->{data});
   }
   my @applid;
   my $cachekey;
   if ($self->getParent->SelfAsParentObject() eq "itil::appl"){
      @applid=($current->{id});
      $cachekey=join(",",sort(@applid));
   }
   else{
      $cachekey=$current->{id};
   }
   if ($FilterSet->{Analyse}->{id} ne $cachekey){
      $FilterSet->{Analyse}={id=>$cachekey};
      # load interessting softwareids from softwareset
      my %swid;
      foreach my $swrec (@{$FilterSet->{Set}->{data}->{software}}){
         $swid{$swrec->{softwareid}}++;
      }
      # check softwareset against installations
      $FilterSet->{Analyse}->{relevantSoftwareInst}=0;
      $FilterSet->{Analyse}->{todo}=[];
      $FilterSet->{Analyse}->{totalstate}="OK";
      $FilterSet->{Analyse}->{dstate}={};
      $FilterSet->{Analyse}->{totalmsg}=[];
      $FilterSet->{Analyse}->{softwareid}=[keys(%swid)];

      my $resdstate=$FilterSet->{Analyse}->{dstate};
      foreach my $g (qw(OS MW DB)){
         $resdstate->{group}->{$g}={
            count=>0,
            fail=>0,
            warn=>0,
         };
      }

      if ($#applid!=-1){ # load systems
         my $lnk=getModuleObject($self->getParent->Config,
                                "itil::lnkapplsystem");
         $lnk->SetFilter({applid=>\@applid,
                          systemcistatusid=>[3,4]}); 
         $FilterSet->{Analyse}->{systems}=[];
         $FilterSet->{Analyse}->{systemids}={};
         foreach my $lnkrec ($lnk->getHashList(qw(systemid osreleaseid
                                                  system 
                                                  systemdenyupd
                                                  systemdenyupdvalidto))){
            my $sid=$lnkrec->{systemid};
            if (!exists($FilterSet->{Analyse}->{systemids}->{$sid})){
               my $srec={
                  name=>$lnkrec->{system},
                  systemid=>$lnkrec->{systemid},
                  denyupd=>$lnkrec->{systemdenyupd},
                  denyupdvalidto=>$lnkrec->{systemdenyupdvalidto},
                  osrelease=>$lnkrec->{osrelease},
                  osreleaseid=>$lnkrec->{osreleaseid}
               };
               $FilterSet->{Analyse}->{systemids}->{$sid}=$srec;
               push(@{$FilterSet->{Analyse}->{systems}},
                    $FilterSet->{Analyse}->{systemids}->{$sid});
               my @ruleset=@{$FilterSet->{Set}->{data}->{osrelease}};
               @ruleset=sort({$a->{comparator}<=>$b->{comparator}} @ruleset);

               my $failpost="";
               if ($srec->{denyupd}>0){
                  $failpost=" but OK";
                  if ($srec->{denyupdvalidto} ne ""){
                      my $d=CalcDateDuration(
                                        NowStamp("en"),$srec->{denyupdvalidto});
                      if ($d->{totalminutes}<0){
                         $failpost=" and not OK";
                      }
                  }
               }

               my $dstate="OK";
               $resdstate->{group}->{OS}->{count}++;
               foreach my $osrec (@ruleset){
                  if ($srec->{osreleaseid} eq  $osrec->{osreleaseid}){
                     if ($osrec->{comparator} eq "0"){
                        $dstate="FAIL";
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- update OS '$srec->{osrelease}' ".
                                 "on $srec->{name}");
                           if (!($FilterSet->{Analyse}->{totalstate}
                                =~m/^FAIL/)){
                              $FilterSet->{Analyse}->{totalstate}=
                                 "FAIL".$failpost;
                           }
                           push(@{$FilterSet->{Analyse}->{totalmsg}},
                               "$srec->{name} OS '$srec->{osrelease}' ".
                               "is marked as not allowed");
                           $resdstate->{group}->{OS}->{fail}++;
                        }
                     }
                     if ($osrec->{comparator} eq "1"){
                        $dstate="WARN";
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- OS '$srec->{osrelease}' ".
                                 "on $srec->{name} needs soon a update");
                           if (!($FilterSet->{Analyse}->{totalstate}
                               =~m/^FAIL/)){
                              $FilterSet->{Analyse}->{totalstate}=
                                 "WARN".$failpost;
                           }
                           push(@{$FilterSet->{Analyse}->{totalmsg}},
                               "$srec->{name} OS '$srec->{osrelease}' ".
                               "is soon not allowed");
                           $resdstate->{group}->{OS}->{warn}++;
                        }
                     }
                  }
               }
               $resdstate->{system}->{$lnkrec->{system}}={
                  state=>$dstate,
               };
            }
         }
      }
      #print STDERR Dumper($FilterSet->{Analyse});
      my $lnk=getModuleObject($self->getParent->Config,
                             "itil::lnksoftwaresystem");
      if ($#applid!=-1){# load system installed software
         $lnk->SetFilter({
           systemid=>[keys(%{$FilterSet->{Analyse}->{systemids}})]
         });
      }
      else{
         $lnk->SetFilter({id=>\$current->{id}});
      }
      $lnk->SetCurrentView(qw(systemid system software denyupd denyupdvalidto
                              releasekey version softwareid is_dbs is_mw));
      $FilterSet->{Analyse}->{ssoftware}=
             $lnk->getHashIndexed(qw(id systemid softwareid));


      if ($#applid!=-1){# load related software instances
         my $sw=getModuleObject($self->getParent->Config,
                                "itil::swinstance");
         $sw->SetFilter({cistatusid=>[3,4],
                         applid=>\$current->{id}});
         $FilterSet->{Analyse}->{swi}=[
              $sw->getHashList(qw(id lnksoftwaresystemid fullname))];
      }

      my $ssoftware=$FilterSet->{Analyse}->{ssoftware}->{softwareid};

      my @ruleset=@{$FilterSet->{Set}->{data}->{software}};

      @ruleset=sort({$b->{comparator}<=>$a->{comparator}} @ruleset);


      foreach my $swi (values(%{$FilterSet->{Analyse}->{ssoftware}->{id}})){
         if ($swi->{is_mw}){
            $resdstate->{group}->{MW}->{count}++;
         }
         if ($swi->{is_dbs}){
            $resdstate->{group}->{DB}->{count}++;
         }
         RULESET: foreach my $swrec (@ruleset){
            if ($swrec->{softwareid} eq  $swi->{softwareid}){
               $FilterSet->{Analyse}->{relevantSoftwareInst}++;
               if ($swi->{version}=~m/^\s*$/){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- no version specified in software installaton ".
                        "of $swrec->{softwareid} on system $swi->{systemid}");
               }
               if ($swrec->{startwith} ne ""){
                  my $qstartwith=quotemeta($swrec->{startwith});
                  if (!($swi->{version}=~m/^$qstartwith/i)){
                     next RULESET;
                  }
               }
               my $failpost="";
               if ($swi->{denyupd}>0){
                  $failpost=" but OK";
                  if ($swi->{denyupdvalidto} ne ""){
                      my $d=CalcDateDuration(
                                        NowStamp("en"),$swi->{denyupdvalidto});
                      if ($d->{totalminutes}<0){
                         $failpost=" and not OK";
                      }
                  }
               }
               if (length($swrec->{releasekey})!=
                   length($swi->{releasekey}) ||
                   ($swi->{releasekey}=~m/^0*$/) ||
                   ($swrec->{releasekey}=~m/^0*$/)){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- releasekey missmatch in  ".
                        "$swi->{software} on $swi->{system} ");
                  $FilterSet->{Analyse}->{totalstate}="FAIL";
                  push(@{$FilterSet->{Analyse}->{totalmsg}},
                       "releasekey error");
               }
               else{
                  if ($swrec->{comparator} eq "3"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- soon update $swi->{software} on ".
                                 "system $swi->{system} ".
                                 "from $swi->{version} to  $swrec->{version}");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{warn}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{warn}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="WARN".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} needs soon >=$swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "2"){
                     if ($swrec->{releasekey} ne $swi->{releasekey} ||
                         $swrec->{version} ne $swi->{version}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- only version $swi->{version} ".
                                 " of $swi->{software} is allowed on  ".
                                 " system $swi->{system} ");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} needs $swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "12"){
                     if ($swrec->{releasekey} eq $swi->{releasekey} ||
                         $swrec->{version} eq $swi->{version}){
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "10"){
                     if ($swrec->{releasekey} eq $swi->{releasekey} ||
                         $swrec->{version} eq $swi->{version}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                               "- remove disallowed version $swi->{software} ".
                               " $swi->{version} from  system $swi->{system} ");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} disallowed $swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "11"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                               "- remove disallowed version $swi->{software} ".
                               " $swi->{version} from  system $swi->{system} ");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} disallowed $swrec->{version}");
                        last RULESET;
                     }
                  }
                  elsif ($swrec->{comparator} eq "0"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- update $swi->{software} on ".
                                 "system $swi->{system} ".
                                 "from $swi->{version} to  $swrec->{version}");
                           if ($swi->{is_mw}){
                              $resdstate->{group}->{MW}->{fail}++;
                           }
                           if ($swi->{is_dbs}){
                              $resdstate->{group}->{DB}->{fail}++;
                           }
                        }
                        if (!($FilterSet->{Analyse}->{totalstate}=~m/^FAIL/)){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} needs >=$swrec->{version}");
                        last RULESET;
                     }
                  }
               }
            }
         }
      }
   }

   my @d;
   if ($#applid!=-1){
      { # system count
         my $m=sprintf("analysed system count: %d",
                         int(keys(%{$FilterSet->{Analyse}->{systemids}})));
         if ($#{$FilterSet->{Analyse}->{systems}}==-1){
            push(@d,"<font color=red>"."WARN: ".$m."</font>");
         }
         else{
            push(@d,"INFO: ".$m);
         }
      }
      # softwareinstallation count
      if (int(keys(%{$FilterSet->{Analyse}->{systemids}}))!=0){
         my $m=sprintf("analysed software installations count: %d",
                        keys(%{$FilterSet->{Analyse}->{ssoftware}->{id}})+0);
         if (keys(%{$FilterSet->{Analyse}->{ssoftware}->{id}})==0){
            push(@d,"<font color=red>"."WARN: ".$m."</font>");
         }
         else{
            push(@d,"INFO: ".$m);
         }
         { # check software instances
            my $m=sprintf("analysed software instance count: %d",
                            $#{$FilterSet->{Analyse}->{swi}}+1);
            if ($#{$FilterSet->{Analyse}->{swi}}!=-1){
               push(@d,"INFO: ".$m);
            }
            else{
               push(@d,"<font color=red>"."WARN: ".$m."</font>");
            }
         }
         my $m=sprintf("found <b>%d</b>".
                       " relevant software installations for check",
                       $FilterSet->{Analyse}->{relevantSoftwareInst});
         push(@d,"INFO: ".$m);
      }
   }
   my $finestate="green";
   if ($FilterSet->{Analyse}->{totalstate} eq "WARN"){
      $finestate="yellow";
   }
   elsif ($FilterSet->{Analyse}->{totalstate} eq "FAIL"){
      $finestate="red";
   }
   my @resdstate;
   foreach my $g (sort(keys(%{$FilterSet->{Analyse}->{dstate}->{group}}))){
       push(@resdstate,"$g(".
              $FilterSet->{Analyse}->{dstate}->{group}->{$g}->{count}."/".
              $FilterSet->{Analyse}->{dstate}->{group}->{$g}->{warn}."/".
              $FilterSet->{Analyse}->{dstate}->{group}->{$g}->{fail}.")");
   }
   push(@d,"INFO:  total state ".$FilterSet->{Analyse}->{totalstate});
   push(@d,"INFO:  grouped state format (count/warn/fail)");
   push(@d,"INFO:  grouped state ".join(" ",@resdstate));
   push(@d,"<b>STATE:</b> <font color=$finestate>".$finestate."</font>");
   
   if ($self->Name eq "rawsoftwareanalysestate"){
      Dumper($FilterSet->{Analyse});
      return({xmlroot=>{
         totalstate=>$FilterSet->{Analyse}->{totalstate},
         dstate=>$FilterSet->{Analyse}->{dstate},
         finestate=>$finestate,
         totalmsg=>$FilterSet->{Analyse}->{totalmsg},
         systems=>$FilterSet->{Analyse}->{systems},
         software=>$FilterSet->{Analyse}->{softwareid},
         relevantSoftwareInst=>$FilterSet->{Analyse}->{relevantSoftwareInst}
      }});
   }
   if ($self->Name eq "softwareanalysestate"){
      return("<div style='width:300px'>".join("<br>",@d)."</div>");
   }
   if ($self->Name eq "softwareanalysetodo"){
      return("<div style='width:500px'>".
             join("<br>",@{$FilterSet->{Analyse}->{todo}})."</div>");
   }
   if ($self->Name eq "softwareinstrelstate"){
      return($FilterSet->{Analyse}->{totalstate});
   }
   if ($self->Name eq "softwareinstrelmsg"){
      return(join("\n",@{$FilterSet->{Analyse}->{totalmsg}}));
   }

   return(join("<br>",@d));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header","instdetail") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

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
   my ($swrec,$msg)=$sw->getOnlyFirst(qw(depcompcontactid compcontactid));
   return(0) if (!defined($swrec));
   my $userid=$self->getCurrentUserId();
   return(0) if ($swrec->{depcompcontactid} ne $userid &&
                 $swrec->{compcontactid} ne $userid);  # first release of
                                                       # trust checking - this
                                                       # is not the final 
                                                       # process!
   $newrec->{alternateCreateRight}="1";  # store information about alternate
                                         # process for FinishWrite

   return(1);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!defined($oldrec)){
      if ($newrec->{alternateCreateRight} && $newrec->{id} ne ""){
         # send a mail to system/cluster databoss with cc on current user
         my $swi=$self->Clone();
         $swi->SetFilter({id=>\$newrec->{id}});
         my ($swirec,$msg)=$swi->getOnlyFirst(qw(databossid fullname));
         if (defined($swirec) && $swirec->{databossid} ne ""){
            my $userid=$self->getCurrentUserId();
            my $u=getModuleObject($self->Config,"base::user");
            $u->SetFilter({userid=>\$swirec->{databossid},
                           cistatusid=>"<6"});
            my ($urec,$msg)=$u->getOnlyFirst(qw(lastlang));
            my $lang=$urec->{lastlang};
            my $wfa=getModuleObject($self->Config,"base::workflowaction");
            $wfa->Notify("INFO","create of software installation",
                         "Hello,\n\ni have create the software installation ".
                         "<b>".$swirec->{fullname}."</b>".
                         " for you.\n\nThis is original ".
                         "your job, but through other dependencies, i had ".
                         "need to do this for you.",
                         emailto=>$swirec->{databossid},
                         emailcc=>[11634953080001,$userid]);
         }
      }
   }
   return($self->SUPER::FinishWrite($oldrec,$newrec));
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default instdetail lic options useableby misc link 
             releaseinfos softsetvalidation
             upd source));
}








1;
