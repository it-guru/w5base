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
                vjoineditbase =>{cistatusid=>[3,4]},
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
                vjoindisp     =>'name'),

      new kernel::Field::Number(
                name          =>'quantity',
                htmlwidth     =>'40px',
                group         =>'lic',
                precision     =>2,
                label         =>'Quantity',
                dataobjattr   =>'lnksoftwaresystem.quantity'),

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
                label         =>'Options',
                group         =>'options',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.options',
                vjointo       =>'itil::lnksoftwareoption',
                vjoinon       =>['id'=>'parentid'],
                vjoindisp     =>['fullname']),
                                                   
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
            "on lnksoftwaresystem.liccontract=liccontract.id ";

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
                 $self->getParent->T("license contract is installed/active"));
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
            if (!defined($oldrec) ||
                !($self->isInstanceRelationWriteable($oldrec->{id}))){
               $self->LastMsg(ERROR,"system is not writeable for you");
               return(undef);
            }
         }
      }
   }
   if (exists($newrec->{quantity}) && ! defined($newrec->{quantity})){
      delete($newrec->{quantity});
   }

   if (exists($newrec->{denyupd})){
      if ($newrec->{denyupd}>0){
         if (exists($newrec->{denyupdvalidto})){
            # prüfen ob länger als 365 Tage in der Zukunft!
         }
         if (effVal($oldrec,$newrec,"denyupdvalidto") eq ""){
            $newrec->{denyupdvalidto}=$self->ExpandTimeExpression("now+365d");
         }
      }
      else{
         $newrec->{denyupdvalidto}=undef;
      }
   } 

   return(1);
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
      my ($rec)=$ss->getOnlyFirst("name","software");
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
      $FilterSet->{Analyse}->{softwareid}=[keys(%swid)];
      if ($#applid!=-1){ # load systems
         my $lnk=getModuleObject($self->getParent->Config,
                                "itil::lnkapplsystem");
         $lnk->SetFilter({applid=>\@applid,
                          systemcistatusid=>[3,4]}); 
         $FilterSet->{Analyse}->{systems}=[$lnk->getVal("systemid")];
      }
      my $lnk=getModuleObject($self->getParent->Config,
                             "itil::lnksoftwaresystem");
      if ($#applid!=-1){# load system installed software
         $lnk->SetFilter({systemid=>$FilterSet->{Analyse}->{systems}});
      }
      else{
         $lnk->SetFilter({id=>\$current->{id}});
      }
      $lnk->SetCurrentView(qw(systemid system software denyupd denyupdvalidto
                              releasekey version softwareid));
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

      # check softwareset against installations
      $FilterSet->{Analyse}->{relevantSoftwareInst}=0;
      $FilterSet->{Analyse}->{todo}=[];
      $FilterSet->{Analyse}->{totalstate}="OK";
      $FilterSet->{Analyse}->{totalmsg}=[];
      my $ssoftware=$FilterSet->{Analyse}->{ssoftware}->{softwareid};
      foreach my $swrec (@{$FilterSet->{Set}->{data}->{software}}){
         foreach my $swi (values(%{$FilterSet->{Analyse}->{ssoftware}->{id}})){
            if ($swrec->{softwareid} eq  $swi->{softwareid}){
               $FilterSet->{Analyse}->{relevantSoftwareInst}++;
               if ($swi->{version}=~m/^\s*$/){
                  push(@{$FilterSet->{Analyse}->{todo}},
                        "- no version specified in software installaton ".
                        "of $swrec->{softwareid} on system $swi->{systemid}");
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
                  if ($swrec->{comparator} eq "2"){
                     if ($swrec->{releasekey} ne $swi->{releasekey} ||
                         $swrec->{version} ne $swi->{version}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- only version $swi->{version} ".
                                 " of $swi->{software} is allowed on  ".
                                 " system $swi->{system} ");
                        }
                        if ($FilterSet->{Analyse}->{totalstate} ne "FAIL"){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} needs $swrec->{version}");
                     }
                  }
                  elsif ($swrec->{comparator} eq "1"){
                     if ($swrec->{releasekey} eq $swi->{releasekey} ||
                         $swrec->{version} eq $swi->{version}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                               "- remove disallowed version $swi->{software} ".
                               " $swi->{version} from  system $swi->{system} ");
                        }
                        if ($FilterSet->{Analyse}->{totalstate} ne "FAIL"){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} disallowed $swrec->{version}");
                     }
                  }
                  elsif ($swrec->{comparator} eq "0"){
                     if ($swrec->{releasekey} gt $swi->{releasekey}){
                        if ($failpost ne " but OK"){
                           push(@{$FilterSet->{Analyse}->{todo}},
                                 "- update $swi->{software} on ".
                                 "system $swi->{system} ".
                                 "from $swi->{version} to  $swrec->{version}");
                        }
                        if ($FilterSet->{Analyse}->{totalstate} ne "FAIL"){
                           $FilterSet->{Analyse}->{totalstate}="FAIL".$failpost;
                        }
                        push(@{$FilterSet->{Analyse}->{totalmsg}},
                             "$swi->{software} needs >=$swrec->{version}");
                     }
                  }
               }
            }
            #printf STDERR ("check $swrec->{softwareid} $swrec->{releasekey} against $swi->{softwareid} $swi->{releasekey}\n");
         }
      }

 
      
   }
 #  printf STDERR ("id=$current->{id} d=%s\n",Dumper($FilterSet->{Set}->{data}));
 #  printf STDERR ("sw=%s\n",Dumper($FilterSet->{Analyse}->{ssoftware}));

   my @d;
   if ($#applid!=-1){
      { # system count
         my $m=sprintf("analysed system count: %d",
                         $#{$FilterSet->{Analyse}->{systems}}+1);
         if ($#{$FilterSet->{Analyse}->{systems}}==-1){
            push(@d,"<font color=red>"."WARN: ".$m."</font>");
         }
         else{
            push(@d,"INFO: ".$m);
         }
      }
      # softwareinstallation count
      if ($#{$FilterSet->{Analyse}->{systems}}!=-1){
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
         my $m=sprintf("found <b>%d</b> relevant software installations for check",
                       $FilterSet->{Analyse}->{relevantSoftwareInst});
         push(@d,"INFO: ".$m);
      }
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
   return("default","header") if (!defined($rec));
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
      return("default","lic","misc","instdetail","upd","options");
   }
   else{
      # check if there is an software instance based on this installation
      if ($self->isInstanceRelationWriteable($rec->{id})){
         return(qw(instdetail options));
      }
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

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default instdetail lic options useableby misc link 
             releaseinfos softsetvalidation
             upd source));
}








1;
