package TS::system;
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
use itil::system;
@ISA=qw(itil::system);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'acrelassignmentgroupid',
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'lassignmentid'),

      new kernel::Field::TextDrop(
                name          =>'acrelassingmentgroup',
                label         =>'AM Assignmentgroup',
                group         =>'amrel',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['acrelassignmentgroupid'=>'lgroupid'],
                searchable    =>0,
                readonly      =>1,
                async         =>'1',
                depend        =>['acrelassignmentgroupid'],
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'assignmentgroup'),

      new kernel::Field::Link(
                name          =>'acreliassignmentgroupid',
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'lincidentagid'),

      new kernel::Field::TextDrop(
                name          =>'acreliassignmentgroup',
                label         =>'AM Incident-Assignmentgroup',
                group         =>'amrel',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['acreliassignmentgroupid'=>'lgroupid'],
                searchable    =>0,
                readonly      =>1,
                async         =>'1',
                depend        =>['acreliassignmentgroupid'],
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'iassignmentgroup'),

      new kernel::Field::Link(
                name          =>'acinmassignmentgroupid',
                group         =>'control',
                label         =>'Incident Assignmentgroup ID',
                dataobjattr   =>'system.acinmassignmentgroupid'),

      new kernel::Field::TextDrop(
                name          =>'acinmassingmentgroup',
                label         =>'Incident Assignmentgroup',
                vjoineditbase =>{isinmassign=>\'1'},
                group         =>'tsinmchm',
                AllowEmpty    =>1,
                vjointo       =>\'tsgrpmgmt::grp',
                vjoinon       =>['acinmassignmentgroupid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'scapprgroupid',
                group         =>'control',
                label         =>'Change Approvergroup technical ID',
                dataobjattr   =>'system.scapprgroupid'),

      new kernel::Field::TextDrop(
                name          =>'scapprgroup',
                label         =>'Change Approvergroup',
                vjoineditbase =>{ischmapprov=>\'1'},
                group         =>'tsinmchm',
                AllowEmpty    =>1,
                vjointo       =>\'tsgrpmgmt::grp',
                vjoinon       =>['scapprgroupid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'accontrolcenter',
                label         =>'AM System ControlCenter',
                group         =>'amrel',
                weblinkto     =>\'tsacinv::group',
                weblinkon     =>['accontrolcenter'=>'name'],
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'controlcenter'),

      new kernel::Field::TextDrop(
                name          =>'accontrolcenter2',
                label         =>'AM Application ControlCenter',
                group         =>'amrel',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['accontrolcenter2'=>'name'],
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'controlcenter2'),

      new kernel::Field::TextDrop(
                name          =>'acsystemname',
                label         =>'AM Systemname',
                group         =>'amrel',
                async         =>'1',
                searchable    =>0,
                readonly      =>1,
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'systemname'),

      new kernel::Field::Boolean(
                name          =>'acsoxrelevant',
                label         =>'AM SOX relevant',
                group         =>'amrel',
                htmldetail    =>0,
                searchable    =>0,
                weblinkto     =>'NONE',
                async         =>'1',
                readonly      =>1,
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'soxrelevant'),


      new kernel::Field::Boolean(
                name          =>'acsas70relevant',
                label         =>'AM SAS70 relevant',
                group         =>'amrel',
                searchable    =>0,
                weblinkto     =>'NONE',
                async         =>'1',
                readonly      =>1,
                vjointo       =>\'tsacinv::system',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>'sas70relevant'),


      new kernel::Field::Textarea(
                name          =>'ipanalyse',
                label         =>'IP-Analyse',
                depend        =>['name','systemid','rawipanalyse'],
                group         =>'ipaddresses',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $f=$self->getParent->getField("rawipanalyse");
                   my $a=$f->RawValue($current);
                   my $d="";
                   $d.=join("\n",
                            map({"$_->{class}(".$_->{level}."): ".
                                 $_->{label}} @{$a->{systemname}->{msg}}));
                   return($d);
                }),

      new kernel::Field::Interface(
                name          =>'rawipanalyse',
                label         =>'raw IP-Analyse',
                depend        =>['name','systemid','rawipanalyse',
                                 'ipaddresses','isclusternode','itclustid'],
                group         =>'ipaddresses',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                onRawValue    =>\&doIPanalyse),

      new kernel::Field::SubList(
                name          =>'w5w_systemref',
                label         =>'W5Warhouse itil::system reference',
                group         =>'source',
                searchable    =>0,
                readonly      =>1,
                uivisible     =>sub{
                   my $self=shift;
                   my $app=$self->getParent();
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                vjointo       =>\'W5Warehouse::itil__system',
                vjoinon       =>['id'=>'id'],
                vjoindisp     =>['name','d_w5repllastsucc','d_w5repllasttry']),

   );

   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{systemid}) && $newrec->{systemid} ne ""){
      $newrec->{systemid}=uc($newrec->{systemid}); # T-Systems Standard laut AM
   }
   return($self->SUPER::Validate($oldrec,$newrec));
}

sub doIPanalyse
{
   my $self=shift;
   my $rec=shift;
   my $p=$self->getParent();
   return(undef) if (!defined($rec));
   my $c=$self->Cache();

   my $id=$rec->{id};
   my $systemname=$rec->{name};
   my $systemid=$rec->{systemid};
   my $isclusternode=$rec->{isclusternode};

   my $acsys=$p->getPersistentModuleObject("tsacinv::system");
   my $acautosys=$p->getPersistentModuleObject("tsacinv::autodiscsystem");
   my $neoRec=$p->getPersistentModuleObject("neo::ipaddressAnalyse");
   my $itclust=$p->getPersistentModuleObject("itil::itclust");
   my $lnkitclustsvc=$p->getPersistentModuleObject("itil::lnkitclustsvc");

   #######################################################################
   # Default Analyse Record
   my %a=($systemname=>{
         itinv=>1,
         ip=>{},
         itinvIP=>{},
         acIP=>{},
         autodiscIP=>{},
         isclusternode=>$isclusternode,
      },
      SHARED=>{
         ip=>{}
      }
   );
   #######################################################################
   # IT-Inventar lesen
   my $ipaddresses=$p->getField("ipaddresses")->RawValue($rec);
   map({$a{$systemname}->{ip}->{$_->{name}}={}}      @$ipaddresses);
   map({$a{$systemname}->{itinvIP}->{$_->{name}}={}} @$ipaddresses);
   push(@{$a{$systemname}->{nodes}},
         {name=>$systemname,systemid=>$systemid});
   
   if ($a{$systemname}->{isclusternode}){
      # load all nodes in cluster and all packages
      if ($rec->{itclustid} ne ""){
         $itclust->SetFilter({id=>\$rec->{itclustid}});
         my ($itclustrec)=$itclust->getOnlyFirst(qw(systems)); 
         if (defined($itclustrec)){
            foreach my $s (@{$itclustrec->{systems}}){
               if (!in_array([map({$_->{systemid}} 
                                  @{$a{$systemname}->{nodes}})],
                   $s->{systemid})){
                  push(@{$a{$systemname}->{nodes}},
                        {name=>$s->{name},systemid=>$s->{systemid}});
               }
            }
         }
         # load all clusterpackage IP-Adresses
         $lnkitclustsvc->SetFilter({clustid=>$rec->{itclustid}});
         foreach my $svc ($lnkitclustsvc->getHashList(qw(fullname 
                           ipaddresses))){
            foreach my $ip (@{$svc->{ipaddresses}}){
               $a{SHARED}->{ip}->{$ip->{name}}={}
            }
         }
      }
   }
   foreach my $s (@{$a{$systemname}->{nodes}}){
      my $node=$s->{name};
      my $nodesystemid=$s->{systemid};

      #####################################
      # AssetManager lesen
      if ($systemid ne ""){
         $a{$node}->{systemid}=$nodesystemid;
         $acsys->ResetFilter();
         $acsys->SetFilter({systemid=>\$nodesystemid});
         my ($acrec,$msg)=$acsys->getOnlyFirst(qw(systemname ipaddresses));
         if (defined($acrec)){
            $a{$node}->{acsystemname}=$acrec->{systemname};
            map({$a{$node}->{ip}->{$_->{ipaddress}}={}}
                @{$acrec->{ipaddresses}});
            map({$a{$node}->{acIP}->{$_->{ipaddress}}={
                   desc=>$_->{description},
                   dnsname=>$_->{dnsname}
                 }} @{$acrec->{ipaddresses}});
         }
      }
      #####################################
      # AssetManager autodiscovery lesen
      if ($systemid ne ""){
         $acautosys->ResetFilter();
         $acautosys->SetFilter({systemid=>\$nodesystemid});
         my ($acrec,$msg)=$acautosys->getOnlyFirst(qw(name ipaddresses));
         if (defined($acrec)){
            $a{$node}->{acautosystemname}=$acrec->{name};
            map({$a{$node}->{ip}->{$_->{name}}={}}
                @{$acrec->{ipaddresses}});
            map({$a{$node}->{acautoIP}->{$_->{name}}={}}
                @{$acrec->{ipaddresses}});
         }
      }
      #####################################
      # NOAH Registry lesen
    #  $noahRec->SetFilter([{systemname=>$node},
    #                      {name=>[keys(%{$a{$node}->{ip}})]}]);
    #  my @l=$noahRec->getHashList(qw(systemname name));
    #  $a{$node}->{noahRec}=\@l;
    #  foreach my $n (@l){
    #     $a{$node}->{noahIP}->{$n->{name}}={name=>$n->{systemname}};
    #  }
      #######################################################################
   }
   # Analyse durchführen
   my $a=\%a;


   # check if all found ip adresses are exists in autodisc data
   foreach my $ip (keys(%{$a->{$systemname}->{acIP}})){
      if ($a->{$systemname}->{acIP}->{$ip}->{dnsname} ne "" &&
          !($a->{$systemname}->{acIP}->{$ip}->{dnsname}=~m/\..*\./)){
         push(@{$a->{systemname}->{msg}},
            {class=>'am.valueissue',
             level=>1,
             label=>"The field 'dns name' of IP-Address '$ip' ".
                    "on system '$systemname' ($systemid) in AssetManager ".
                    "contains no valid dns name"
             });

      }
      if (!exists($a->{$systemname}->{acautoIP}->{$ip})){
         my $ok=0;
         if ($a->{$systemname}->{acIP}->{$ip}->{desc}=~m/\b(RSB|Console)\b/){  
            $ok=1;       # RSB can not be detected by autodiscovery
         }                         
         if (!$ok && $a->{$systemname}->{isclusternode}){
            if (exists($a->{SHARED}->{ip}->{$ip})){
               $ok++;  # alles Super - $ip ist eine ClusterPacket Adresse
            }
            if (!$ok){
               foreach my $node (map({$_->{name}} 
                                     @{$a->{$systemname}->{nodes}})){
                  if (exists($a->{$node}->{acautoIP}->{$ip})){
                     $ok++; # nicht schoen - aber OK - die IP ist auf einem
                  }         # anderen Node im Cluster registriert
               }
            }
         }
         if (!$ok){
            my $clusttext="";
            if ($a->{$systemname}->{isclusternode}){
               $clusttext=" or any other node in the cluster"; 
            }
            push(@{$a->{systemname}->{msg}},
               {class=>'am.ipoverhead',
                level=>2,
                label=>"The IP-Address '$ip' found in AssetManager, ".
                       "can not be detected (autodiscovery) on the ".
                       "system '$systemname' ($systemid)$clusttext."
                });
         }
      }
      if (exists($a->{$systemname}->{noahIP}->{$ip})){
         my $noahname=lc($a->{$systemname}->{noahIP}->{$ip}->{name});
         my $noahnameok=0;
         if ($noahname eq lc($systemname)){
            $noahnameok=1;
         }
         if (!$noahnameok && $a->{$systemname}->{isclusternode}){
            # check if the name in noah is for an other system in cluster
            foreach my $node (map({$_->{name}} 
                                  @{$a->{$systemname}->{nodes}})){
               if (lc($node) eq $noahname){
                  $noahnameok=1;
               }
            }
         }
         
         if (!$noahnameok){
            push(@{$a->{systemname}->{msg}},
               {class=>'noah.issue',
                level=>3,
                label=>"The IP-Address '$ip' found in AssetManager, ".
                       "on system '$systemname' belongs in NOAH to ".
                       "an other system ($noahname). ".
                       "This can be very critical." 
                });
         }
      }
   }
   foreach my $ip (keys(%{$a->{$systemname}->{acautoIP}})){
      if ($ip=~m/^fe80:0000:0000:0000:/){  # ignore Link-Local-Adressen IPv6
         next;
      }
      if ($ip=~m/^127\..*$/){  # loopback Netz IPv4 127.0.0.0/8
         next;
      }
      if (!exists($a->{$systemname}->{acIP}->{$ip})){
         my $ok=0;
         if ($a->{$systemname}->{isclusternode}){
            if (exists($a->{SHARED}->{ip}->{$ip})){
               $ok++;  # alles Super - $ip ist eine ClusterPacket Adresse
            }
            if (!$ok){
               foreach my $node (map({$_->{name}} 
                                     @{$a->{$systemname}->{nodes}})){
                  if (exists($a->{$node}->{acIP}->{$ip})){
                     $ok++; # nicht schoen - aber OK - die IP ist auf einem
                  }         # anderen Node im Cluster registriert
               }
            }
         }
         if (!$ok){
            my $clusttext="";
            if ($a->{$systemname}->{isclusternode}){
               $clusttext=" or any other node in the cluster"; 
            }
            push(@{$a->{systemname}->{msg}},
               {class=>'am.missip',
                level=>3,
                label=>"The IP-Address '$ip' found by AutoDiscovery ".
                       "on '$systemname' ($systemid) is not documented ".
                       "in AssetManager on systemid ($systemid)$clusttext."
                });
         }
      }
   }

#   print STDERR Dumper(\%a);
   return(\%a);
}

sub getHtmlPublicDetailFields
{
   my $self=shift;
   my $rec=shift;

   my @l=qw(name systemid mandator adm adm2 databoss
            adminteam 
            aciassignmentgroup accontrolcenter accontrolcenter2
            applications);
   return(@l);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec);

   if (defined($rec)){
      if ($rec->{srcsys} eq "AssetManager"){
         if (in_array(\@l,"default")){
            push(@l,"amrel");
         }
         @l=grep(!/^inmchm$/,@l);
      }
      else{
         if (lc($rec->{adminteam}) ne "extern"){
            if (in_array(\@l,"default")){
               push(@l,"tsinmchm");
               @l=grep(!/^inmchm$/,@l);
            }
         }
      }
   }
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isWriteValid($rec);

   if (defined($rec)){
      if ($rec->{srcsys} ne "AssetManager"){
         if (in_array(\@l,"default")){
            push(@l,"tsinmchm");
         }
      }
   }
   else{
      push(@l,"tsinmchm");  # allow generell on Upload of new records
   }                      # write on tsinmchm - not good -> but needed.
   return(@l);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "default");
   }
   splice(@l,$inserti,$#l-$inserti,("tsinmchm",@l[$inserti..($#l+-1)]));
   splice(@l,$inserti,$#l-$inserti,("amrel",@l[$inserti..($#l+-1)]));
   return(@l);
}


sub genericSystemImportNotify
{
   my $self=shift;
   my $srcsys=shift;
   my $w5sys=shift;
   my $datastream=shift;
   my $wfa=shift;
   my $itcloud=shift;
   my $itcloudarea=shift;
   my $rec=shift;
   my $debug="";

   return() if (defined($itcloudarea) && !$itcloudarea->{deplnotify});

   my %notifyParam=(
      emailcategory=>[$srcsys,'SystemImport'],
      emailbcc=>[
       #  11634953080001, # HV
      ]
   );

   push(@{$notifyParam{emailcategory}},"ImportSuccess");

   my $subjectlabel=$srcsys;
   if ($srcsys ne $itcloud->{name}){
      $subjectlabel.=" (".$itcloud->{name}.")";
   }
   $subjectlabel=" ".$subjectlabel;

   $w5sys->NotifyWriteAuthorizedContacts($rec,{},\%notifyParam,{},sub{
      my ($subject,$ntext);
      my $subject=$datastream->T("automatic system import",
                                 'TS::system')." ".$subjectlabel.
                                 " : ".
                                 $rec->{name};
      my $tmpl=$datastream->getParsedTemplate("tmpl/ScanNewSystems_MailNotify",{
         skinbase=>'TS',
         static=>{
            URL=>$rec->{urlofcurrentrec},
            SYSTEMNAME=>$rec->{name}
         }
      });
      return($subject,$tmpl);
   });
}


sub genericAddApplRelation
{
   my $self=shift;
   my $replaceExisting=shift;
   my $identifyby=shift;
   my $curdataboss=shift;
   my $w5applrec=shift;

   { # create application relation
      my $lnkapplsys=getModuleObject($self->Config,"itil::lnkapplsystem");
      my $DataInputState=$lnkapplsys->isDataInputFromUserFrontend();
      $lnkapplsys->isDataInputFromUserFrontend(0); # process as sys mode
      $lnkapplsys->SetFilter({
         systemid=>\$identifyby,
         applid=>\$w5applrec->{id}
      });
      my ($lnkrec)=$lnkapplsys->getOnlyFirst(qw(ALL));
      if (!defined($lnkrec)){
         $lnkapplsys->ValidatedInsertRecord({
            systemid=>$identifyby,
            applid=>$w5applrec->{id}
         });
      }
      $lnkapplsys->isDataInputFromUserFrontend($DataInputState);
   }
   $self->addDefContactsFromAppl($identifyby,$w5applrec,$curdataboss);
}


sub genericSystemImport
{
   my $self=shift;
   my $impobjs=shift;
   my $impparam=shift;

   # Parameter Sets
   my $cloudrec=$impparam->{cloudrec};
   my $cloudarearec=$impparam->{cloudarearec};
   my $sysrec=$impparam->{imprec};
   my $srcsys=$impparam->{srcsys};

   if (!exists($sysrec->{srcid})){
      $sysrec->{srcid}=$sysrec->{id};
   }
   my $srcidFieldname="id";
   if (exists($impparam->{srcidFieldname})){
      $srcidFieldname=$impparam->{srcidFieldname}; 
   }

   # DataObjects
   my $itcloud=$impobjs->{itcloud};   
   my $cloudarea=$impobjs->{itcloudarea};   
   my $appl=$impobjs->{appl};   
   my $sys=$impobjs->{system};   
   my $srcobj=$impobjs->{srcobj};   

   if (!defined($cloudrec)){
      $self->LastMsg(ERROR,"no active $srcsys Cloud in inventory");
      return(undef);
   }

   if (!defined($cloudarea)){
      $self->LastMsg(ERROR,"no CloudArea record for $srcsys import");
      return(undef);
   }

   my $w5applrec;

   $appl->ResetFilter();
   $appl->SetFilter({id=>\$cloudarearec->{applid}});
   my ($apprec,$msg)=$appl->getOnlyFirst(qw(ALL));
   if (defined($apprec)){
      $w5applrec=$apprec;
   }
   # Check now done by validateCloudAreaImportState
   #
   #if (!defined($w5applrec)){
   #   $self->LastMsg(ERROR,"no application record for $srcsys import ".
   #                  "(system.id=$sysrec->{id},system.name=$sysrec->{name})");
   #   return(undef);
   #}

   my $importname="SYSTEM: ".$sysrec->{name};
   if (ref($sysrec->{name}) eq "ARRAY"){
      $importname="SYSTEM: ".join(", ",@{$sysrec->{name}});
   }
   my $cloudAreaOk=0;
   if ($cloudarea->validateCloudAreaImportState($importname,
                                         $cloudrec,$cloudarearec,$w5applrec)){
      $cloudAreaOk++;
   }
   else{
      # check if default app exists and is allowed to import -> if yes, 
      # load new w5applrec
      if ($cloudarearec->{cistatusid}==3 && $cloudarearec->{respapplid} ne ""){
         $appl->ResetFilter();
         $appl->SetFilter({id=>\$cloudarearec->{respapplid}});
         my ($apprec,$msg)=$appl->getOnlyFirst(qw(ALL));
         if (defined($apprec)){
            $w5applrec=$apprec;
            if ($w5applrec->{cistatusid}==4){
               $cloudAreaOk++;
            }
         }
      }
   }
   if ((!$cloudAreaOk)){
      if ($self->LastMsg()==-1){
         $self->LastMsg(ERROR,"CloudArea:'".$cloudarearec->{fullname}."'");
         $self->LastMsg(ERROR,"invalid CloudArea State");
      }
      return(undef);
   }

   my $w5sysrecmodified=0;
   my $w5autoscalegroupextend=0;
   $sys->ResetFilter();
   $sys->SetFilter({srcsys=>\$srcsys,srcid=>\$sysrec->{srcid}});
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));


   if (!defined($w5sysrec)){   # srcid update kandidaten (schneller Redeploy)
      my @flt;
      my @oldiprecords;
      if (ref($sysrec->{ipaddresses}) eq "ARRAY" &&
          $#{$sysrec->{ipaddresses}}!=-1){
         my $ip=getModuleObject($self->Config,"itil::ipaddress");

         my @ipflt;
         foreach my $iprec (@{$sysrec->{ipaddresses}}){
            push(@ipflt,{
               name=>\$iprec->{name},
               srcsys=>\$srcsys
            });
            push(@ipflt,{
               name=>$iprec->{name}."[*",
               srcsys=>\$srcsys
            });
         }
         $ip->SetFilter(\@ipflt);
         @oldiprecords=$ip->getHashList(qw(name systemid));
      }
      my $searchname=$sysrec->{name};
      if (!ref($sysrec->{name})){
         #$searchname=\$searchname;   # ACHTUNG: Erzeugt Perl Schrott!!!
         $searchname=[$searchname];
      }

      push(@flt,{
        name=>$searchname,
        srcsys=>\$srcsys,
        srcid=>'!'.$sysrec->{srcid}  # erzeugt SQL Fehler im Darwin Kern!!!
      });

      push(@flt,{          # if system is alread create by hand with systemname
        name=>$searchname,
        srcsys=>"w5base",
      });

      push(@flt,{          # if system is alread create by hand with srcid
        name=>\$sysrec->{id},
        srcsys=>"w5base",
      });


      if ($#oldiprecords!=-1){
         foreach my $oldiprec (@oldiprecords){
            if ($oldiprec->{systemid} ne ""){
               push(@flt,{
                 id=>\$oldiprec->{systemid},
                 srcsys=>\$srcsys,
                 srcid=>'!'.$sysrec->{srcid}
               });
            }
         }
      }

      $sys->ResetFilter();
      $sys->SetFilter(\@flt);
      $sys->Limit(20);
      my @redepl=$sys->getHashList(qw(mdate cistatusid name id
                                      srcid srcsys applications));
      #if ($#redepl>20){
      #   printf STDERR ("ERROR: genericSystemImport produces >20 rec\n");
      #   printf STDERR ("ERROR: sysrec=%s\n",Dumper($sysrec));
      #   printf STDERR ("ERROR: redepl=%s\n",Dumper(\@redepl));
      #   printf STDERR ("ERROR: redepl check rejected\n");
      #   @redepl=();
      #}


      msg(INFO,"invantar check for $srcsys-SystemID: $sysrec->{id}");
      foreach my $osys (@redepl){   # find best matching redepl candidate
         my $applok=0;
         msg(INFO,"check $srcsys-SystemID: $osys->{srcid} from inventar");
         if ($osys->{srcid} eq $sysrec->{id}){
            msg(ERROR,"$srcsys-SystemID: $osys->{srcid} already in inventar");
            # dieser Punkt dürfte nie erreicht werden, da ja oben bereits
            # eine u.U. passende w5sysrec gesucht wurde.
            last;
         }
         my $ageok=1;
         if ($osys->{cistatusid} ne "4"){  # prüfen, ob das Teil nicht schon
                                           # ewig alt ist
            my $d=CalcDateDuration($osys->{mdate},NowStamp("en"));
            if (defined($d) && $d->{days}>28){
               next; # das Teil ist schon zu alt, um es wieder zu aktivieren
            }
         }
         if ($cloudarearec->{cistatusid}==4){
            foreach my $appl (@{$osys->{applications}}){
               if ($appl->{applid} eq $w5applrec->{id}){
                  $applok++;
               }
            }
         }
         my $sysallowed=0;
         if ($osys->{srcsys} eq "w5base"){ #den Fall muss ich erstmal beobachten
            #printf STDERR ("genericSystemImport: try to transform w5base ".
            #               "system record to $srcsys on system %d\n",
            #               $osys->{id});
            #printf STDERR ("genericSystemImport: searchname was %s\n\n",
            #               Dumper($searchname));
            if ($osys->{cistatusid}==4){ # create manually in cistatus=4
               $sysallowed++;           
            }
         }
         if ($ageok && $applok && 
             lc($osys->{srcsys}) eq "w5base" || $osys->{srcsys} eq ""){
            if ($osys->{cistatusid}<=3){ # prepaied record for initail depl.
               $sysallowed++;            # on system cistatus=avail on projekt
            }

         }
         if ($ageok && $applok && 
             $osys->{srcsys} eq $srcsys &&   # OLDsys must be from the same 
             $osys->{srcid} ne ""){          # srcsys and have a srcid
            if (defined($impparam->{checkForSystemExistsFilter})){
               my $flt=&{$impparam->{checkForSystemExistsFilter}}($osys);
               $srcobj->ResetFilter();
               $srcobj->SetFilter($flt);
               msg(INFO,"check exist of $srcsys-SystemID: $osys->{srcid}");
               my ($chkrec,$msg)=$srcobj->getOnlyFirst(qw(ALL));
               if (!defined($chkrec)){
                  msg(INFO,"$srcsys-System: ".
                           "$osys->{srcid} does not exists anymore");
                  $sysallowed++;
               }
            }
            else{
               $self->LastMsg(ERROR,"no checkForSystemExistsFilter defined ".
                                    "for $srcsys genericSystemImport");
               return(undef);
            }
         }
         if ($applok && $sysallowed && $ageok){
            if ($osys->{cistatusid}>5){
               my $oldname=$osys->{name};
               $oldname=~s/\[.*$//; # remove del unique number
               if ($osys->{name} ne $oldname){
                  $sys->ResetFilter();
                  $sys->SetFilter({name=>\$oldname,id=>'!'.$osys->{id}});
                  my ($chkrec,$msg)=$sys->getOnlyFirst(qw(ALL));
                  if (defined($chkrec)){  # not good! - The systemname seems
                                          # to have changed his function
                    # Der alte Systemname ist bereits bei einem andern
                    # System in Verwendung. Weshalb dann der alte 
                    # Systemdatensatz nicht einfach so wieder aktiviert 
                    # werden kann (das wuerde eine DoublicateEntry erzeugen).
                    #
                    # printf STDERR ("WARN: reuse with function change ".
                    #                "of systemname %s detected while $srcsys ".
                    #                "import of %s\n",$oldname,$sysrec->{id});
                     next;
                  }
               }
            }
            $sys->ResetFilter();
            $sys->SetFilter({id=>\$osys->{id}});
            my ($oldrec,$msg)=$sys->getOnlyFirst(qw(ALL));
            if (defined($oldrec)){
               my $updrec={
                  srcid=>$sysrec->{srcid},
                  srcsys=>$srcsys
               };
               if ($oldrec->{cistatusid} ne "4"){
                  $updrec->{cistatusid}="4";
                  #if (lc($updrec->{srcsys}) eq "azure"){
                  #   printf STDERR ("reactivation with %s\n",
                  #                  Dumper($updrec));
                  #}
               }
               if ($sys->ValidatedUpdateRecord($oldrec,$updrec,
                   {id=>\$oldrec->{id}})) {
                  $sys->ResetFilter();
                  $sys->SetFilter({id=>\$osys->{id}});
                  ($w5sysrec)=$sys->getOnlyFirst(qw(ALL));
                  $w5sysrecmodified++;
               }
               last;
            }
         }
      } 
   }

   my $identifyby;
   if (defined($w5sysrec)){
      if (uc($w5sysrec->{srcsys}) eq uc($srcsys) &&
          $w5sysrec->{srcid} eq $sysrec->{srcid}){
         my $msg=sprintf($self->T("Systemname '%s' already imported in W5Base"),
                         $w5sysrec->{name});
         if ($w5sysrec->{cistatusid} ne "4" || $w5sysrecmodified){
            my %checksession;
            my $qc=getModuleObject($self->Config,"base::qrule");
            $qc->setParent($sys);
            $checksession{autocorrect}=$w5sysrec->{allowifupdate};
            $checksession{autocorrect}=1; # force import with autocorrect
            $qc->nativQualityCheck(
                 $sys->getQualityCheckCompat($w5sysrec),$w5sysrec,
                               \%checksession);
            return({IdentifiedBy=>$w5sysrec->{id}});
         }
         $self->LastMsg(ERROR,$msg);
         return(undef);
      }
   }


   if (defined($w5sysrec)){
      if ($w5sysrec->{srcsys} ne $srcsys &&
          lc($w5sysrec->{srcsys}) ne "w5base" &&
          $w5sysrec->{srcsys} ne ""){
         $self->LastMsg(ERROR,"name colision - systemname $w5sysrec->{name} ".
                              "already in use. Import failed");
         return(undef);
      }
   }
   my $curdataboss;
   #print STDERR ("fifi w5sysrec=%s\n",Dumper($w5sysrec));
   if (defined($w5sysrec)){
      $curdataboss=$w5sysrec->{databossid};
      my %newrec=();
      my $userid;

      if ($self->isDataInputFromUserFrontend() &&   # only admins (and databoss)
                                                    # can force
          !$self->IsMemberOf("admin")) {            # reimport over webrontend
         $userid=$self->getCurrentUserId();         # if record already exists
         if ($w5sysrec->{cistatusid}<6 && $w5sysrec->{cistatusid}>2){
            if ($userid ne $w5sysrec->{databossid}){
               $self->LastMsg(ERROR,
                              "reimport only posible by current databoss");
               if (!$self->isDataInputFromUserFrontend()){
                  msg(ERROR,"fail to import $sysrec->{name} with ".
                            "id $sysrec->{id}");
               }
               return(undef);
            }
         }
      }
      if ($w5sysrec->{cistatusid} ne "4"){
         $newrec{cistatusid}="4";
      }
      if ($w5sysrec->{srcsys} ne $srcsys){
         $newrec{srcsys}=$srcsys;
      }
      if ($w5sysrec->{srcid} ne $sysrec->{srcid}){
         $newrec{srcid}=$sysrec->{srcid};
      }
      if ($w5sysrec->{systemtype} ne "standard"){
         $newrec{systemtype}="standard";
      }
      if ($w5sysrec->{osrelease} eq ""){
         $newrec{osrelease}="other";
      }
      if (defined($w5applrec) &&
          ($w5sysrec->{isprod}==0) &&
          ($w5sysrec->{istest}==0) &&
          ($w5sysrec->{isdevel}==0) &&
          ($w5sysrec->{iseducation}==0) &&
          ($w5sysrec->{isapprovtest}==0) &&
          ($w5sysrec->{isreference}==0) &&
          ($w5sysrec->{iscbreakdown}==0)) { # alter Datensatz - aber kein opmode
         $self->mapApplicationOpModeToSystemOpModeFlags(
            $w5applrec,
            \%newrec
         );
     }
      if (defined($w5applrec) && $w5applrec->{conumber} ne "" &&
          $w5applrec->{conumber} ne $sysrec->{conumber}){
         $newrec{conumber}=$w5applrec->{conumber};
      }
      if (defined($w5applrec) && $w5applrec->{acinmassignmentgroupid} ne "" &&
          $w5sysrec->{acinmassignmentgroupid} eq ""){
         $newrec{acinmassignmentgroupid}=
             $w5applrec->{acinmassignmentgroupid};
      }

      my $foundsystemclass=0;
      foreach my $v (qw(isapplserver isworkstation isinfrastruct 
                        isprinter isbackupsrv isdatabasesrv 
                        iswebserver ismailserver isrouter 
                        isnetswitch isterminalsrv isnas
                        isclusternode)){
         if ($w5sysrec->{$v}==1){
            $foundsystemclass++;
         }
      }
      if (!$foundsystemclass){
         $newrec{isapplserver}="1"; 
      }
      if ($sys->ValidatedUpdateRecord($w5sysrec,\%newrec,
                                      {id=>\$w5sysrec->{id}})) {
         $identifyby=$w5sysrec->{id};
      }
   }
   else{
      msg(INFO,"try to import new with databoss $curdataboss ...");
      my $newrec={name=>$sysrec->{id},
                  srcid=>$sysrec->{srcid}, srcsys=>$srcsys,
                  osrelease=>'other', allowifupdate=>1,
                  cistatusid=>4};
      if (exists($sysrec->{autoscalinggroup})){
         $newrec->{autoscalinggroup}=$sysrec->{autoscalinggroup};
      }
      if (exists($sysrec->{autoscalingsubgroup})){
         $newrec->{autoscalingsubgroup}=$sysrec->{autoscalingsubgroup};
      }
      if (exists($sysrec->{initialname}) && $sysrec->{initialname} ne ""){
         $newrec->{name}=$sysrec->{initialname};
      }
      if (defined($cloudarearec)){
         $newrec->{itcloudareaid}=$cloudarearec->{id};
      }

      $newrec->{name}=~s/\s/_/g;

      my $user=getModuleObject($self->Config,"base::user");
      if ($self->isDataInputFromUserFrontend() &&
          !($impparam->{forceUnattended})){
         $newrec->{databossid}=$self->getCurrentUserId();
         $curdataboss=$newrec->{databossid};
      }
      else{
         my $importname=$sysrec->{contactemail};
         my @l;
         if ($importname ne ""){
            $user->SetFilter({cistatusid=>[4], emails=>$importname});
            @l=$user->getHashList(qw(ALL));
         }
         if ($#l==0){
            $newrec->{databossid}=$l[0]->{userid};
            $curdataboss=$newrec->{databossid};
         }
         else{
            if ($self->isDataInputFromUserFrontend() &&
                !($impparam->{forceUnattended})){
               $self->LastMsg(ERROR,"can not find databoss contact record");
            }
            else{
               #msg(WARN,"invalid databoss contact rec for ".
               #          $sysrec->{contactemail});
               if (defined($w5applrec) && $w5applrec->{databossid} ne ""){
                  msg(INFO,"using databoss from application ".
                           $w5applrec->{name});
                  $newrec->{databossid}=$w5applrec->{databossid};
                  $curdataboss=$newrec->{databossid};
               }
            }
            if (!defined($curdataboss)){
               if ($self->isDataInputFromUserFrontend() &&
                   !($impparam->{forceUnattended})){
                  msg(ERROR,"unable to import system '$sysrec->{name}' ".
                            "without databoss");
               }
               else{
                  my %notifyParam=(
                      mode=>'ERROR',
                      emailbcc=>11634953080001 # hartmut
                  );
                  if ($cloudrec->{supportid} ne ""){
                     $notifyParam{emailcc}=$cloudrec->{supportid};
                  }
                  push(@{$notifyParam{emailcategory}},"SystemImport");
                  push(@{$notifyParam{emailcategory}},"ImportFail");
                  push(@{$notifyParam{emailcategory}},$srcsys);
                 
                  $itcloud->NotifyWriteAuthorizedContacts($cloudrec,
                        {},\%notifyParam,
                        {mode=>'ERROR'},sub{
                     my ($subject,$ntext);
                     my $subject=$srcsys." system import error";
                     my $ntext="unable to import '".$sysrec->{name}."' in ".
                               "it inventory - no databoss can be detected";
                     $ntext.="\n";
                     return($subject,$ntext);
                  });
               }
               return(undef);
            }
         }
      }
      if (!exists($newrec->{mandatorid}) || $newrec->{mandatorid} eq ""){
         if (defined($w5applrec) && $w5applrec->{mandatorid} ne ""){
            $newrec->{mandatorid}=$w5applrec->{mandatorid};
         }
      }
      if (!exists($newrec->{mandatorid})){
         my @m=$user->getMandatorsOf($newrec->{databossid},
                                     ["write","direct"]);
         if ($#m==-1){
            # no writeable mandator for new databoss
            if ($self->isDataInputFromUserFrontend()){
               $self->LastMsg(ERROR,"can not find a writeable mandator");
               return();
            }
         }
         $newrec->{mandatorid}=$m[0];
      }


      if ($newrec->{mandatorid} eq ""){
         $self->LastMsg(ERROR,"can't get mandator for import of ".
                        "$srcsys System $sysrec->{name}");
         #msg(ERROR,sprintf("w5applrec=%s",Dumper($w5applrec)));
         return();
      }
      if (defined($w5applrec)){
         if ($w5applrec->{conumber} ne ""){
            $newrec->{conumber}=$w5applrec->{conumber};
         }
         if ($w5applrec->{acinmassignmentgroupid} ne ""){
            $newrec->{acinmassignmentgroupid}=
                $w5applrec->{acinmassignmentgroupid};
         }
         $newrec->{isapplserver}=1;  # per Default, all is an applicationserver
         if ($w5applrec->{opmode} eq "prod"){
            $newrec->{isprod}=1;
         }
         elsif ($w5applrec->{opmode} eq "test"){
            $newrec->{istest}=1;
         }
         elsif ($w5applrec->{opmode} eq "devel"){
            $newrec->{isdevel}=1;
         }
         elsif ($w5applrec->{opmode} eq "education"){
            $newrec->{iseducation}=1;
         }
         elsif ($w5applrec->{opmode} eq "approvtest"){
            $newrec->{isapprovtest}=1;
         }
         elsif ($w5applrec->{opmode} eq "reference"){
            $newrec->{isreference}=1;
         }
         elsif ($w5applrec->{opmode} eq "cbreakdown"){
            $newrec->{iscbreakdown}=1;
         }
      }
      {
         my $newname=$newrec->{name};
         $sys->ResetFilter();
         $sys->SetFilter({name=>\$newname});
         my ($chkrec)=$sys->getOnlyFirst(qw(id name));
         if (defined($chkrec)){
            $newrec->{name}=$sysrec->{altname};
         }
         if (($newrec->{name}=~m/\s/) || length($newrec->{name})>60){
            $newrec->{name}=$sysrec->{altname};
         }
      }
      # prevent parallel QCheck at night (which can result in doublicate 
      # enties)
      $newrec->{lastqcheck}=NowStamp("en");
      # QCheck will be done at end of Import anyway
      ##################################################################
      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      if (($cloudarearec->{cistatusid}==4 || $cloudarearec->{cistatusid}==3) &&
          defined($w5applrec)){  # contains respappl (if cistatusid=3)
         $self->genericAddApplRelation(0,$identifyby,$curdataboss,$w5applrec); 
      }
      if ($self->LastMsg()==0){  # do qulity checks only if all is ok
         $sys->ResetFilter();
         $sys->SetFilter({'id'=>\$identifyby});
         my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            my %checksession;
            my $qc=getModuleObject($self->Config,"base::qrule");
            $qc->setParent($sys);
            $checksession{autocorrect}=$rec->{allowifupdate};
            $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec,
                                   \%checksession);
         }
      }
   }


   if (defined($identifyby)){   # create Notification
      my $wfa=$self->getPersistentModuleObject("_W5Wfa","base::workflowaction");
      $sys->ResetFilter();
      $sys->SetFilter({id=>\$identifyby});
      my ($srec)=$sys->getOnlyFirst(qw(ALL));
      if (!defined($srec)){
         msg(ERROR,
            "something went wron while import ".
            "of $srcsys Systemname $srec->{name}");
      }
      else{
         if ($srec->{autoscalinggroup} ne ""){
            $w5autoscalegroupextend=1;  # extended
         }

         if (!$w5autoscalegroupextend){
            msg(INFO,"start doNotify $srec->{name}");
            $self->genericSystemImportNotify(
               $srcsys,$sys,$srcobj,$wfa,$cloudrec,$cloudarearec,$srec
            );
         }
      }
   }

   return({IdentifiedBy=>$identifyby});
}



sub getValidWebFunctions
{
   my $self=shift;

   my @l=$self->SUPER::getValidWebFunctions(@_);
   push(@l,"Analyse");
   return(@l);
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
               init=>'qde8hv'
            },
            systemid=>{
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
      my $f1={cistatusid=>[3,4],systemid=>[$q->{query}]};
      my $f2={cistatusid=>[3,4],name=>[$q->{query}]};
      push(@cflt,$f1,$f2);
   }
   else{
      if ((exists($q->{name}) && $q->{name} ne "") ||
          (exists($q->{systemid}) && $q->{systemid} ne "")){
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
      if (exists($q->{systemid}) && $q->{systemid} ne ""){
         $flt->{systemid}=[$q->{systemid}]
      }
   }

   $self->ResetFilter();
   $self->SetFilter(\@cflt);


   my @l=$self->getHashList(qw(
      id systemid name applications urlofcurrentrec
   )); 

   my %applid;
   my %systemid;
   foreach my $rec (@l){
      if (!in_array(\@refurl,$rec->{urlofcurrentrec})){
         unshift(@refurl,$rec->{urlofcurrentrec});
      }
      if (ref($r->{systems}) ne "ARRAY"){
         $r->{systems}=[];
      }
      push(@{$r->{systems}},{
         name=>$rec->{name},
         systemid=>$rec->{systemid}
      });
      push(@indication,"system: ".$rec->{name});
      if ($rec->{id} ne ""){
         $systemid{$rec->{id}}++;
      }
      foreach my $applrec (@{$rec->{applications}}){
         push(@indication,"application: ".$applrec->{appl});
         $applid{$applrec->{applid}}++;
      }
   }

   my @criticality;
   my @ictono;
   my %opmode;

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
      \%opmode
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
   if (keys(%applid)){
      $r->{related}=[
        map({{dataobj=>'itil::appl',dataobjid=>$_}} keys(%applid))
      ];
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
