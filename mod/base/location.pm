package base::location;
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
use kernel::App::Web::InterviewLink;
use kernel::CIStatusTools;
use kernel::Field::OSMap;
use kernel::Field::OSMAdrChk;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB
        kernel::App::Web::InterviewLink kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);


   sub AddressBuild{
      my $self=shift;
      my $current=shift;
      my $a="";
      $a.=($a eq "" ? "" : " ").$current->{country};
      $a.=($a eq "" ? "" : " ").$current->{zipcode};
      $a.=($a eq "" ? "" : " ").$current->{location};
      $a.=($a eq "" ? "" : " ").$current->{address1};
      return($a);
   }

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'location.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                label         =>'Location name',
                dataobjattr   =>'location.name'),

      new kernel::Field::Mandator(
                allowany      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'location.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                default       =>'2',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0) if ($self->getParent->IsMemberOf("admin"));
                   return(1) if (defined($rec) &&
                                 $rec->{cistatusid}>2 &&
                                 !$self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'location.cistatus'),

      new kernel::Field::Text(
                name          =>'label',
                allowAnyLatin1=>1,
                label         =>'Location label',
                dataobjattr   =>'location.label'),

      new kernel::Field::Text(
                name          =>'address1',
                htmlwidth     =>'200px',
                allowAnyLatin1=>1,
                label         =>'Street address',
                dataobjattr   =>'location.address1'),

      #
      # country codes based on ISO-3166-Alpha2
      # http://de.wikipedia.org/wiki/ISO-3166-1-Kodierliste
      #
      new kernel::Field::Select(
                name          =>'country', 
                htmleditwidth =>'50px',
                label         =>'Country',
                vjointo       =>'base::isocountry',
                vjoinon       =>['country'=>'token'],
                vjoindisp     =>'token',
                dataobjattr   =>'location.country'),

      new kernel::Field::Text(
                name          =>'zipcode',
                htmleditwidth =>'80px',
                label         =>'ZIP Code',
                dataobjattr   =>'location.zipcode'),

      new kernel::Field::Text(
                name          =>'location',
                allowAnyLatin1=>1,
                label         =>'Location',
                dataobjattr   =>'location.location'),

      new kernel::Field::Number(
                name          =>'prio',
                label         =>'Location prio',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                depend        =>['id'],
                onRawValue    =>\&calcLocationPrio),

      new kernel::Field::Databoss(
                group         =>'management'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'location.databoss'),

      new kernel::Field::TextDrop(
                name          =>'response',
                label         =>'Location responsible',
                group         =>'management',
                AllowEmpty    =>1,
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['responseid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'responseid',
                dataobjattr   =>'location.response'),

      new kernel::Field::TextDrop(
                name          =>'response2',
                label         =>'Deputy location responsible',
                vjointo       =>'base::user',
                AllowEmpty    =>1,
                group         =>'management',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['response2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'response2id',
                dataobjattr   =>'location.response2'),

      new kernel::Field::Group(
                name          =>'buildingservgrp',
                group         =>'management',
                label         =>'Building service team',
                vjoinon       =>'buildingservgrpid'),

      new kernel::Field::Link(
                name          =>'buildingservgrpid',
                group         =>'management',
                dataobjattr   =>'location.buildingservgrp'),

      new kernel::Field::SubList(
                name          =>'grprelations',
                label         =>'Organisation Relations',
                allowcleanup  =>1,
                group         =>'grprelations',
                vjointo       =>'base::lnklocationgrp',
                vjoinon       =>['id'=>'locationid'],
                vjoindisp     =>['grp','relmode'],
                vjoininhash   =>['grpid','grp','relmode','comments','id']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'base::location'}],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'base::location'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments',
                label         =>'Comments',
                dataobjattr   =>'location.comments'),

      new kernel::Field::Text(
                name          =>'roomexpr',
                group         =>'control',
                label         =>'Room Expression',
                dataobjattr   =>'location.roomexpr'),

      new kernel::Field::OSMap(
                name          =>'osmap',
                uploadable    =>0,
                searchable    =>0,
                group         =>'map',
                htmlwidth     =>'500px',
                label         =>'OpenStreetMap',
                depend        =>['country','address1',
                                 'label',
                                 'gpslongitude',
                                 'gpslatitude',
                                 'zipcode','location']),

      new kernel::Field::OSMAdrChk(
                name          =>'osmadrchk',
                group         =>'map',
                uploadable    =>0,
                htmldetail    =>0,
                htmlwidth     =>'200px',
                label         =>'OSM Address Check',
                depend        =>['country','address1',
                                 'label',
                                 'gpslongitude',
                                 'gpslatitude',
                                 'zipcode','location']),

      new kernel::Field::Number(
                name          =>'gpslatitude',
                precision     =>8,
                decimaldot    =>'.',
                group         =>'gps',
                label         =>'latitude',
                dataobjattr   =>'location.gpslatitude'),

      new kernel::Field::Number(
                name          =>'gpslongitude',
                precision     =>8,
                decimaldot    =>'.',
                group         =>'gps',
                label         =>'longitude',
                dataobjattr   =>'location.gpslongitude'),

      new kernel::Field::Text(
                name          =>'refcode1',
                group         =>'control',
                label         =>'Reference Code1',
                dataobjattr   =>'location.refcode1'),

      new kernel::Field::Text(
                name          =>'refcode2',
                group         =>'control',
                label         =>'Reference Code2',
                dataobjattr   =>'location.refcode2'),

      new kernel::Field::Text(
                name          =>'refcode3',
                group         =>'control',
                label         =>'Reference Code3',
                dataobjattr   =>'location.refcode3'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"location.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(location.id,35,'0')"),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'location.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'location.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'location.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'location.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'location.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'location.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'location.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'location.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'location.realeditor'),

      new kernel::Field::Container(
                name          =>'additional',
                group         =>'additional',
                dataobjattr   =>'location.additional'),

      new kernel::Field::Text(
                name          =>'similarcheck',
                group         =>'control',
                uploadable    =>0,
                htmldetail    =>0,
                searchable    =>0,
                htmlwidth     =>'500px',
                label         =>'similar check',
                depend        =>['country','address1',
                                 'zipcode','location'],
                onRawValue    =>\&SimilarCheck),

      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'location.lastqcheck'),
   );
   if (getModuleObject($self->Config,"itil::mgmtitemgroup")){
      $self->AddFields(
      new kernel::Field::Text(
                name          =>'mgmtitemgroup',
                label         =>'central managed CI groups',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>1,
                htmldetail    =>1,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'PCONTROL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'locationid'],
                vjoindisp     =>'mgmtitemgroup'),
         insertafter=>['prio']
      );
      $self->AddFields(
      new kernel::Field::Text(
                name          =>'reportinglabel',
                label         =>'Reporting Label',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'RLABEL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'locationid'],
                vjoindisp     =>'mgmtitemgroup'),
         insertafter=>['prio']
      );


   }

   $self->{history}={
      delete=>[
         'local'
      ],
      update=>[
         'local'
      ]
   };

   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.base.location"],
                         uniquesize=>255};
   $self->setDefaultView(qw(location address1 name cistatus));
   $self->setWorktable("location");
   return($self);
}

sub calcLocationPrio
{
   my $self=shift;
   my $current=shift;

   my $prio=undef;

   my $lnklocationgrp=getModuleObject($self->getParent->Config,
                                      "base::lnklocationgrp");
   $lnklocationgrp->SetFilter({locationid=>\$current->{id}});
   foreach my $relrec ($lnklocationgrp->getHashList(qw(relmode))){
      $prio=3 if (!defined($prio));
      if (my ($lprio)=$relrec->{relmode}=~m/^RMbusinesrel(\d)$/){
         if ($lprio<$prio){
            $prio=$lprio;
         }
      }
   }
   return($prio);
}

sub SimilarCheck
{
   my $self=shift;
   my $current=shift;

   my $loc=$self->getParent->Clone();

   my @flt;

   {
      my $address1=$current->{address1};
      $address1=~s/\s/*/g;
      $address1=~s/[\d-]/*/g;
      $address1=~s/[a-z]$/*/i;
      my $location=$current->{location};
      $location=~s/\s/*/g;
      $location=~s/\d/*/g;
      push(@flt,{location=>$location,
                 address1=>$address1});
   }
   {
      my $location=$current->{location};
      $location=~s/^(\S{0,5}).*/$1/;
      $location=~s/[^a-z]/*/i;
      my $address1=$current->{address1};
      $address1=~s/^(\S{0,5}).*/$1/;
      $address1=~s/[^a-z]/*/i;
      push(@flt,{location=>$location,
                 address1=>$address1});
   }
   

   my %res;
   foreach my $f (@flt){
      $loc->ResetFilter();
      $loc->SetFilter($f);
      $loc->Limit(20,0,0);
      foreach my $rec ($loc->getHashList(qw(id name))){
         if ($rec->{id}!=$current->{id}){
            $res{$rec->{id}}=$rec->{name}." ( ".$rec->{id}." )";
         }
      }
      last if (keys(%res)>60);
   }
   return(join("\n",sort(values(%res))));
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","map","management","grprelations",
          "contacts","phonenumbers",
          "comments","additional","gps","control","source");
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub isCopyValid
{
   my $self=shift;

   return(1);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/location.jpg?".$cgi->query_string());
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   my $userid=$self->getCurrentUserId();
   if (defined($oldrec) && $oldrec->{userid}==$userid){
      delete($newrec->{cistatusid});
   }
   else{
      if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

         

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $country=trim(effVal($oldrec,$newrec,"country"));
   my $location=trim(effVal($oldrec,$newrec,"location"));
   my $label=trim(effVal($oldrec,$newrec,"label"));
   my $address1=trim(effVal($oldrec,$newrec,"address1"));
   my $zipcode=trim(effVal($oldrec,$newrec,"zipcode"));
   $newrec->{country}=$country   if (!exists($newrec->{country}));
   $newrec->{location}=$location if (!exists($newrec->{location}));
   $newrec->{label}=$label       if (!exists($newrec->{label}));
   $newrec->{address1}=$address1 if (!exists($newrec->{address1}));
   $newrec->{zipcode}=$zipcode   if (!exists($newrec->{zipcode}));

   my $country=trim(effVal($oldrec,$newrec,"country"));
   my $location=trim(effVal($oldrec,$newrec,"location"));
   my $label=trim(effVal($oldrec,$newrec,"label"));
   my $address1=trim(effVal($oldrec,$newrec,"address1"));
   my $zipcode=trim(effVal($oldrec,$newrec,"zipcode"));
  
   if (effChanged($oldrec,$newrec,"zipcode")){ 
      my $loc=getModuleObject($self->Config,"base::isocountry");
      $loc->SetFilter({token=>\$country});
      my ($rec,$msg)=$loc->getOnlyFirst(qw(zipcodeexp));
      if (defined($rec)){
         my $zipcodeexp=$rec->{zipcodeexp};
         if (!($zipcodeexp=~m/^\s*$/)){
            my $chk;
            eval("\$chk=\$zipcode=~m$zipcodeexp;");
            if ($@ ne "" || !($chk)){
               $self->LastMsg(ERROR,"invalid zipcode '\%s'",$zipcode);
               return(undef);
            }
         }
      }
   }

   if ($location eq "" || $location eq "0" || $address1 eq "0"){
      $self->LastMsg(ERROR,"invalid location");
      msg(ERROR,"invalid location request with ".
                "location='$location' and address1='$address1'");
      return(0);
   }

   my $name="";
   $location=~s/\./_/g;
   $name.=($name ne "" && $country  ne "" ? "." : "").$country;
   $name.=($name ne "" && $location ne "" ? "." : "").$location;
   $name.=($name ne "" && $address1 ne "" ? "." : "").$address1;
   $name.=($name ne "" && $label    ne "" ? "." : "").$label;
   $name=~s/\xFC/ue/g;
   $name=~s/\xF6/oe/g;
   $name=~s/\xE4/ae/g;
   $name=~s/\xDC/Ue/g;
   $name=~s/\xD6/Oe/g;
   $name=~s/\xC4/Ae/g;
   $name=~s/\xDF/ss/g;

   $name=~s/[ÀÁÂÃÅ]/A/g;
   $name=~s/[ÈÉÊË]/E/g;
   $name=~s/[ÌÍÎÏ]/I/g;
   $name=~s/[Ñ]/N/g;
   $name=~s/[ÒÓÔÕ]/O/g;
   $name=~s/[ÙÚÛ]/U/g;
   $name=~s/[Ý]/Y/g;
   $name=~s/[àáâãå]/a/g;
   $name=~s/[èéêë]/e/g;
   $name=~s/[ìíîï]/i/g;
   $name=~s/[ñ]/n/g;
   $name=~s/[òóôõ]/o/g;
   $name=~s/[ùúû]/u/g;
   $name=~s/[ÿý]/y/g;

   $name=~s/[\s\/,\/]+/_/g;
   $name=~s/_+/_/g;
   $newrec->{'name'}=$name;
   if (!defined($oldrec) && !defined($newrec->{label})){
      $newrec->{label}="";
   }

   ########################################################################
   # standard security handling
   #
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
   ########################################################################
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));



   return(1);
}

sub getLocationByHash
{
   my $self=shift;
   my %req=@_;
   #printf STDERR ("Request0=%s\n",Dumper(\%req));
   #printf STDERR ("Request1=%s\n",Dumper(\%req));

   return(undef) if ($req{country}=~m/^\s*$/);
   return(undef) if ($req{location}=~m/^\s*$/);
   return(undef) if ($req{address1}=~m/^\s*$/);
   msg(INFO,"getLocationByHash=%s",Dumper(\%req));

#   if (defined($req{srcid}) && defined($req{srcsys})){
#      $self->ResetFilter();
#      $self->SetFilter({'srcsys'=>\$req{srcsys},srcid=>\$req{srcid}});
#      $self->SetCurrentView(qw(ALL));
#      $self->ForeachFilteredRecord(sub{
#                         $self->ValidatedUpdateRecord($_,
#                          {srcid=>undef,srcsys=>undef},{id=>\$_->{id}});
#                      });
#
#
#   }
   $self->ResetFilter();
   $self->SetFilter({label=>\$req{label},
                     country=>\$req{country},
                     address1=>\$req{address1},
                     location=>\$req{location}});
   my ($locrec,$msg)=$self->getOnlyFirst(qw(id));
   if (!defined($locrec)){
      msg(ERROR,"fail request id of location $req{location} ; $req{address1}");
      return(undef);
   }
   return($locrec->{id});

#  no autocreate mehr!
#   my @id=$self->ValidatedInsertOrUpdateRecord(\%req,
#                                               {label=>\$req{label},
#                                                country=>\$req{country},
#                                                address1=>\$req{address1},
#                                                location=>\$req{location}});
#   return($id[0]);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","history") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   if ($self->IsMemberOf("admin")){
      return("default","contacts","grprelations","phonenumbers",
             "management","gps","control","comments");
   }
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(phonenumbers management grprelations 
                       contacts comments gps);
   if ($rec->{cistatusid}<=2){
      push(@databossedit,"default");
   }

   if (defined($rec) && $rec->{databossid}==$userid){
      return(@databossedit);
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
         if (grep(/^write$/,@roles)){
            return($rec->{mandatorid},@databossedit);
         }
      }
   }

   return();
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }

   return(1);
}


sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   return(1) if ($rec->{creator}==$userid && $rec->{cistatusid}<3);

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}



1;
