package TS::vou;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use kernel::CIStatusTools;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);



   $self->{useMenuFullnameAsACL}=$self->Self();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>0,
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'vou.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'shortname',
                label         =>'Shortname',
                size          =>'12',
                htmlwidth     =>'80',
                htmleditwidth =>'80',
                dataobjattr   =>'vou.shortname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                selectfix     =>1,
                dataobjattr   =>'vou.name'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'vou.code'),

      new kernel::Field::Text(
                name          =>'rampupid',
                label         =>'Ramp-Up ID',
                dataobjattr   =>'vou.rampupid'),

      new kernel::Field::Select(
                name          =>'responsibleorg',
                htmleditwidth =>'40%',
                selectfix     =>1,
                label         =>'responsible organisation',
                vjoineditbase =>{grpid=>"200"},
                vjointo       =>'base::grp',
                vjoinon       =>['rorgid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'rorgid',
                label         =>'responsible organisation ID',
                selectfix     =>1,
                dataobjattr   =>'vou.rorg'),

      new kernel::Field::Select(
                name          =>'outype',
                label         =>'Unit Type',
                value         =>['HUB','SERVICE'],
                htmleditwidth =>'130px',
                dataobjattr   =>'vou.grouptype'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'50%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                selectfix     =>1,
                dataobjattr   =>'vou.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                group         =>'comments',
                dataobjattr   =>'vou.databoss'),

      new kernel::Field::Contact(
                name          =>'leader',
                label         =>'Business Owner - Business',
                AllowEmpty    =>1,
                vjoinon       =>'leaderid'),

      new kernel::Field::Link(
                name          =>'leaderid',
                dataobjattr   =>'vou.leader'),

      new kernel::Field::Contact(
                name          =>'leaderit',
                label         =>'Business Owner - IT',
                AllowEmpty    =>1,
                vjoinon       =>'leaderitid'),

      new kernel::Field::Link(
                name          =>'leaderitid',
                dataobjattr   =>'vou.leaderit'),

      new kernel::Field::Text(
                name          =>'canvasid',
                label         =>'CanvasID',
                htmleditwidth =>'80px',
                size          =>'3',
                group         =>'canvas',
                dataobjattr   =>'vou.canvasid'),

      new kernel::Field::Text(
                name          =>'canvasfield',
                label         =>'Canvas/Business field',
                group         =>'canvas',
                dataobjattr   =>'vou.canvasfield'),

      new kernel::Field::Contact(
                name          =>'canvasownerbu',
                group         =>'canvas',
                AllowEmpty    =>1,
                label         =>'Canvas Owner - Business',
                vjoinon       =>'canvasownerbuid'),

      new kernel::Field::Link(
                name          =>'canvasownerbuid',
                group         =>'canvas',
                dataobjattr   =>'vou.canvasownerbuid'),

      new kernel::Field::Contact(
                name          =>'canvasownerit',
                AllowEmpty    =>1,
                group         =>'canvas',
                label         =>'Canvas Owner - IT',
                vjoinon       =>'canvasowneritid'),

      new kernel::Field::Link(
                name          =>'canvasowneritid',
                dataobjattr   =>'vou.canvasowneritid'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'vou.description'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>0,
                dataobjattr   =>"concat(".
                                "vou.shortname,".
                                "if (vou.name<>'','-',''),".
                                "vou.name".
                                ")"),

      new kernel::Field::TextDrop(
                name          =>'reprgrp',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'representing group',
                group         =>'vouattr',
                vjointo       =>'base::grp',
                vjoinbase     =>{srcsys=>[$self->SelfAsParentObject()]},
                vjoinon       =>['id'=>'srcid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'seg',
                group         =>'vouattr',
                label         =>'Segemente/Tribe',
                dataobjattr   =>'vou.segment'),

      new kernel::Field::Contact(
                name          =>'rte',
                AllowEmpty    =>1,
                group         =>'vouattr',
                label         =>'RTE',
                vjoinon       =>'rteid'),

      new kernel::Field::Link(
                name          =>'rteid',
                group         =>'vouattr',
                dataobjattr   =>'vou.rte'),

      new kernel::Field::Contact(
                name          =>'spc',
                AllowEmpty    =>1,
                label         =>'SPC',
                group         =>'vouattr',
                vjoinon       =>'spcid'),

      new kernel::Field::Link(
                name          =>'spcid',
                group         =>'vouattr',
                dataobjattr   =>'vou.spc'),


      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'operated applications',
                htmlwidth     =>'300px',
                group         =>'appl',
                readonly      =>1,
                searchable    =>0,
                htmllimit     =>100,
                depend        =>['srcid','reprgrp'],
                vjointo       =>'itil::appl',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['reprgrp'=>'businessteam'],
                vjoinonfinish =>sub{
                   my $self=shift;
                   my $flt=shift;
                   my $current=shift;
                   my $mode=shift;

                   if (ref($flt) eq "HASH"){
                      if (exists($flt->{businessteam}) &&
                          $flt->{businessteam} ne ""){
                         $flt->{businessteam}=$flt->{businessteam}." ".
                                              $flt->{businessteam}.".*";
                      }
                   }
                   return($flt);
                },
                vjoindisp     =>['name','cistatus','businessteam']),



      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments',
                label         =>'Comments',
                dataobjattr   =>'vou.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'vou.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'vou.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'vou.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'vou.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'vou.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'vou.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'vou.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'vou.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'vou.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'vou.lastqcheck'),
      new kernel::Field::QualityResponseArea()

   );
   $self->{history}={
      insert=>[
         'local'
      ],
      update=>[
         'local'
      ],
      delete=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(shortname name cistatus code cdate mdate));
   $self->setWorktable("vou");
   $self->{CI_Handling}={
      uniquename=>"shortname",
      uniquesize=>8,
      activator=>["admin","w5base.TS.vou"]
   };
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default vouattr canvas contacts appl comments source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   if (!defined($oldrec) || defined($newrec->{shortname})){
      my $newshortname=$newrec->{shortname};
      $newshortname=~s/\[\d+\]$//;
      if ($newshortname=~m/^\s*$/ || 
          !($newshortname=~m/^[a-z0-9_-]+$/i) ||
          ($newshortname=~m/^[0-9-]/i) ||
          length($newshortname)>12){
         $self->LastMsg(ERROR,"invalid shortname specified");
         return(0);
      }
   }
   if (!defined($oldrec) || defined($newrec->{rampupid})){
      my $cistatusid=effVal($oldrec,$newrec,"cistatusid");
      if ($cistatusid>2 && $cistatusid<6){
         my $rampupid=$newrec->{rampupid};
         if ($rampupid=~m/^\s*$/ || 
             !($rampupid=~m/^XH[0-9_]+$/)){
            $self->LastMsg(ERROR,"invalid Ramp-Up ID specified");
            return(0);
         }
      }
   }
   my $ocistatusid=undef;
   $ocistatusid=$oldrec->{cistatusid} if (defined($oldrec));
   my $ncistatusid=effVal($oldrec,$newrec,"cistatusid");

   if ($ocistatusid>=4 && $ncistatusid<4){
      if (!$self->IsMemberOf($self->{CI_Handling}->{activator})){
         $self->LastMsg(ERROR,"cistatus back to planning is not allowed");
         return(0);
      }
   }
   if ($ncistatusid>=4 && $ncistatusid<6){
      if (effVal($oldrec,$newrec,"leaderid") eq "" &&
          effVal($oldrec,$newrec,"leaderitid") eq ""){
         $self->LastMsg(ERROR,
                 "a business owner is needed for selected CI-State");
         return(0);
      }
      if (length(trim(effVal($oldrec,$newrec,"name")))<5){
         $self->LastMsg(ERROR,
                 "Name field not sufficient filled");
         return(0);
      }
   }

   if (exists($newrec->{canvasid})){
      my $canvasid=$newrec->{canvasid};
      if ($canvasid ne ""){
         if ($canvasid=~m/^[0-9]+$/){
            if ($canvasid<100){
               $canvasid=sprintf("C%02d",$canvasid);
            }
            else{
               $canvasid=sprintf("C%03d",$canvasid);
            }
         }
         $canvasid=uc($canvasid);
         if (!($canvasid=~m/^C[0-9]{2,3}$/)){
            $self->LastMsg(ERROR,"invalid format of CanvasID");
            return(0);
         }
         if ($newrec->{canvasid} ne $canvasid){
            $newrec->{canvasid}=$canvasid;
         }
      }
   }



   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
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
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   if (!$self->HandleRunDownRequests($oldrec,$newrec,$comprec,
                                     %{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   if ($rec->{cistatusid}>=4){
      if ($rec->{cistatusid}>=6){
         my $d=CalcDateDuration($rec->{mdate},NowStamp("en"));
         if ($d->{days}>6){
            return($self->isWriteValid($rec));
         }
      }
      return(0);
   }
   return($self->isWriteValid($rec));
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("TS::vou");
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $rorgid=effVal($oldrec,$newrec,"rorgid");  # noch nicht ausgewertet!


   my $id=effVal($oldrec,$newrec,"id");
   my $cistatus=effVal($oldrec,$newrec,"cistatusid");
   my $shortname=effVal($oldrec,$newrec,"shortname");
   my $name=effVal($oldrec,$newrec,"name");

   my $reprgrp=effVal($oldrec,$newrec,"reprgrp"); # schon mal aktiv gewesen?

   if ($cistatus>3 || $reprgrp ne ""){
      $self->syncToGroups($id,$cistatus,$shortname,$name,$oldrec,$newrec);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub syncToGroups
{
   my $self=shift;
   my ($id,$cistatus,$shortname,$name,$oldrec,$newrec)=@_;
   my $leaderid=effVal($oldrec,$newrec,"leaderid");
   my $leaderitid=effVal($oldrec,$newrec,"leaderitid");

   my $leader=$leaderid;
   $leader=$leaderitid if ($leaderitid ne "");

   my $basegrpname=effVal($oldrec,$newrec,"responsibleorg");
   my $parentgrp=$basegrpname.".DigitalHub";
   my $fullname=$parentgrp.".".$shortname;

   my $grp=$self->getPersistentModuleObject("w5grp","base::grp");
   $grp->SetFilter([{
      fullname=>$fullname
   },
   {
      srcsys=>[$self->SelfAsParentObject()],
      srcid=>\$id
   }]);
   my @l=$grp->getHashList(qw(fullname name description srcsys srcid cistatusid
                              grpid is_orggroup parent parentid));
   my $grpid;
   if ($#l==-1){   # Gruppe muss neu erzeugt werden
      $grpid=$grp->ValidatedInsertRecord({
         name=>$shortname,
         cistatusid=>$cistatus,
         parent=>$parentgrp,
         is_orggroup=>1,
         description=>$name,
         srcsys=>$self->SelfAsParentObject(),
         srcid=>$id,
         srcload=>NowStamp("en")
      });
      msg(INFO,"group created with id=$grpid");
   }
   elsif($#l==0){  # Ein Datensatz muss aktualisiert werden
      my $upd={};
      $upd->{name}=$shortname      if ($l[0]->{name} ne $shortname);
      $upd->{description}=$name    if ($l[0]->{description} ne $name);
      $upd->{cistatusid}=$cistatus if ($l[0]->{cistatusid} ne $cistatus);
      $upd->{srcid}=$id            if ($l[0]->{srcid} ne $id);
      $upd->{is_orggroup}="1"      if ($l[0]->{is_orggroup} ne "1");
      if ($l[0]->{srcsys} ne $self->SelfAsParentObject()){
         $upd->{srcsys}=$self->SelfAsParentObject();
      }
      if (keys(%$upd)){
         $upd->{srcload}=NowStamp("en");
         $grp->ValidatedUpdateRecord($l[0],$upd,{grpid=>\$l[0]->{grpid}});
      }
      $grpid=$l[0]->{grpid};
   }
   elsif($#l==1){  # einer muss aussortiert werden
     msg(ERROR,"double grp record target in vou syncToGroups");
   }
   else{
      die("vou hard error while update on $fullname");
   }
   if ($grpid ne "" && $grpid>1){
      my %orgadmin;
      foreach my $crec (@{$oldrec->{contacts}}){
         if ($crec->{target} eq "base::user"){
            my $r=$crec->{roles};
            $r=[$r] if (ref($r) ne "ARRAY");
            if (in_array($r,"RAdmin") && $crec->{targetid} ne ""){
               $orgadmin{$crec->{targetid}}++;
            }
         }
      }
      my @orgadmin=keys(%orgadmin);

      

      #printf STDERR ("contacts=%s\n",Dumper($oldrec->{contacts}));
      my $lnkgrp=$self->getPersistentModuleObject("w5lgrp","base::lnkgrpuser");
      $lnkgrp->SetFilter({grpid=>\$grpid});
      my @l=$lnkgrp->getHashList(qw(ALL));


      $lnkgrp->RoleSyncIn(\@l,{
            RBoss=>[$leader],
            RAdmin=>\@orgadmin
         },
         {
            onInsert=>sub{
               my $self=shift;
               my $newrec=shift;
               $newrec->{grpid}=$grpid;
               $newrec->{srcsys}="TS::vou";
               $newrec->{srcload}=NowStamp("en");
               if (!in_array($newrec->{roles},"RBoss")){
                  push(@{$newrec->{roles}},"REmployee");
               }
               if (!in_array($newrec->{roles},"RMember")){
                  push(@{$newrec->{roles}},"RMember");
               }
               return(1);
            },
            onUpdate=>sub{
               my $self=shift;
               my $oldrec=shift;
               my $newrec=shift;
               if ($oldrec->{srcsys} eq ""){
                  $newrec->{srcsys}="TS::vou";
               }
               $newrec->{srcload}=NowStamp("en");
               return(1);
            },
         }
      );
   }
}






sub isWriteValid
{
   my $self=shift;
   my @l;


   if (!defined($_[0])){
      @l=$self->SUPER::isWriteValid(@_);
   }

   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   if ($userid eq $rec->{databossid}){
      push(@l,"ALL");
   }
   if ($self->IsMemberOf($self->{CI_Handling}->{activator})){
      push(@l,"ALL");
   }

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
         @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
         push(@l,"ALL") if (grep(/^write$/,@roles));
      }
   }



   if (in_array(\@l,"ALL")){
      @l=("default","vouattr","comments","canvas","contacts");
   }

   return(@l);
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
