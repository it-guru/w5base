package itil::itcloudarea;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'qitcloudarea.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full qualified CloudArea',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                htmlwidth     =>'360px',
                dataobjattr   =>"concat(itcloud.fullname,'.',".
                                "qitcloudarea.name)"),

      new kernel::Field::TextDrop(
                name          =>'cloud',
                htmlwidth     =>'150px',
                label         =>'Cloud',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                vjointo       =>'itil::itcloud',
                vjoinon       =>['cloudid'=>'id'],
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (defined($rec)){
                      my $itcloudid=$rec->{"cloudid"};
                      if ($self->getParent->isWriteOnITCloudValid($itcloudid,
                           "default")){
                         return(0);
                      }
                   }
                   return(1) if (defined($rec));
                   return(0);
                },
                label         =>'CloudArea name',
                dataobjattr   =>'qitcloudarea.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                default       =>'3',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'qitcloudarea.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (defined($rec)){
                      my $itcloudid=$rec->{"cloudid"};
                      if ($rec->{cistatusid}!=4){
                         if ($self->getParent->isWriteOnITCloudValid($itcloudid,
                             "default")){
                            return(0);
                         }
                      }
                   }
                   return(1) if (defined($rec));
                   return(0);
                },
                vjointo       =>'itil::appl',
                SoftValidate  =>1,
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'applid',
                selectfix     =>1,
                dataobjattr   =>'qitcloudarea.appl'),

      new kernel::Field::Link(
                name          =>'previousapplid',   # store the last applid
                selectfix     =>1,                  # for installed/aktive cloudarea
                dataobjattr   =>'qitcloudarea.previousappl'),

      new kernel::Field::Textarea(
                name          =>'description',
                searchable    =>0,
                label         =>'CloudArea description',
                dataobjattr   =>'qitcloudarea.description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'qitcloudarea.comments'),

      new kernel::Field::Text(
                name          =>'requestoraccount',
                htmldetail    =>'0',
                label         =>'requestor account',
                dataobjattr   =>'qitcloudarea.requestoraccount'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmleditwidth =>'150px',
                htmlwidth     =>'100px',
                readonly      =>1,
                group         =>'appl',
                label         =>'Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                forwardSearch =>1,
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                htmllimit     =>'50',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'itcloudareaid'],
                vjoindisp     =>['name','cistatus','network'],
                vjoininhash   =>['name','cistatusid','networkid','network',
                                 'systemid','itclustsvcid',
                                 'srcsys','srcid','id']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                readonly      =>1,
                htmllimit     =>'50',
                htmldetail    =>'NotEmpty',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjointo       =>'itil::system',
                vjoinon       =>['id'=>'itcloudareaid'],
                vjoindisp     =>['name','systemid','cistatus'],
                vjoininhash   =>['name','cistatusid','id',
                                 'systemid','srcsys','srcid']),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'software instances',
                group         =>'swinstances',
                forwardSearch =>1,
                readonly      =>1,
                htmllimit     =>'50',
                htmldetail    =>'NotEmpty',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjointo       =>'itil::swinstance',
                vjoinon       =>['id'=>'itcloudareaid'],
                vjoindisp     =>['fullname','cistatus']),

      new kernel::Field::Boolean(
                name          =>'deplnotify',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>
                              'Notification on successful automatic CI-Import',
                dataobjattr   =>'qitcloudarea.deplnotify'),

      new kernel::Field::Boolean(
                name          =>'ipobjectexport',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>
                              'Export IP-Objects to firewall management system',
                dataobjattr   =>'qitcloudarea.ipobjectexport'),


      new kernel::Field::TextDrop(
                name          =>'respappl',
                label         =>'responsible Application',
                readonly      =>'1',
                htmldetail    =>'0',
                vjointo       =>'itil::appl',
                vjoinon       =>['respapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'respapplid',
                selectfix     =>1,
                dataobjattr   =>"if (qitcloudarea.cistatus=3,".
                                "if (qitcloudarea.previousappl is not null,".
                                "qitcloudarea.previousappl,".
                                "if (itcloud.allowinactsysimport=1,".
                                "itcloud.appl,null)),qitcloudarea.appl)"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'qitcloudarea.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'qitcloudarea.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'qitcloudarea.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'qitcloudarea.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'qitcloudarea.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"qitcloudarea.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(qitcloudarea.id,35,'0')"),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'qitcloudarea.createdate'),
                                                
      new kernel::Field::Date(
                name          =>'cifirstactivation',
                group         =>'source',
                htmldetail    =>0,
                selectfix     =>1,
                label         =>'Config-Item first activation',
                dataobjattr   =>'qitcloudarea.cifirstactivation'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qitcloudarea.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'qitcloudarea.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'qitcloudarea.realeditor'),

      new kernel::Field::Select(
                name          =>'cloudcistatus',
                readonly      =>1,
                htmldetail    =>0,
                htmlwidth     =>'100px',
                group         =>'cloudinfo',
                label         =>'Cluster CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['itcloudcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Link(
                name          =>'itcloudcistatusid',
                label         =>'Cloud CI-State',
                readonly      =>1,
                group         =>'cloudinfo',
                dataobjattr   =>'itcloud.cistatus'),

      new kernel::Field::Link(
                name          =>'itcloudshortname',
                label         =>'cloud technical shortname',
                readonly      =>1,
                group         =>'cloudinfo',
                dataobjattr   =>'itcloud.shortname'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'Mandator ID of Cloud',
                readonly      =>1,
                group         =>'cloudinfo',
                dataobjattr   =>'itcloud.mandator'),

      new kernel::Field::Link(
                name          =>'supportid',
                label         =>'Contact SupportID of Cloud',
                readonly      =>1,
                group         =>'cloudinfo',
                dataobjattr   =>'itcloud.support'),

      new kernel::Field::Interface(
                name          =>'cloudid',
                selectfix     =>1,
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'W5Base Cloud ID',
                dataobjattr   =>'qitcloudarea.itcloud'),

      new kernel::Field::Interface(
                name          =>'allowuncleanseq',
                translation   =>'itil::itcloud',
                readonly      =>1,
                label         =>'allow unclean sequences and ci state checking',
                dataobjattr   =>'itcloud.allowuncleanseq'),

      new kernel::Field::IssueState(),
      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'qitcloudarea.lastqcheck'),
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
         {dataobj=>'itil::itcloud', id=>'cloudid',
          field=>'name',as=>'cloudareas'}
      ]
   };

   $self->setDefaultView(qw(fullname appl conumber  cdate));
   $self->setWorktable("itcloudarea");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/itcloudarea.jpg?".$cgi->query_string());
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::itcloudarea");
}



         

sub getSqlFrom
{
   my $self=shift;
   my $from="itcloudarea qitcloudarea  ".
            "left outer join itcloud ".
            "on qitcloudarea.itcloud=itcloud.id ".
            "left outer join appl ".
            "on qitcloudarea.appl=appl.id";
   return($from);
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.itcloudarea.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      push(@flt,[
                 {mandatorid=>\@mandators},
                ]);
   }
   return($self->SetFilter(@flt));
}


sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $itcloudid=$rec->{"cloudid"};
   if ($self->isWriteOnITCloudValid($itcloudid,"default")){
      return(1);
   }
   return(0);
}


sub checkAutoactivation
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,"cifirstactivation") ne ""){
      if (!effChanged($oldrec,$newrec,"applid")){
         msg(INFO,"Autoactivation of $oldrec->{fullname} by 1stact ".
                  effVal($oldrec,$newrec,"cifirstactivation"));
         $newrec->{cistatusid}="4";
         return(1);
      }
      else{
         msg(INFO,"no Autoactivation of $oldrec->{fullname} by 1stact ");
      }
   }
   if (!defined($oldrec) || exists($newrec->{requestoraccount})){
      my $requestoraccount=$newrec->{requestoraccount};
      if ($requestoraccount ne ""){
         my $isAutoactivationOk=0;
         my $applid=effVal($oldrec,$newrec,"applid");
         my $appldataobj="itil::appl";
         $appldataobj=$self->findNearestTargetDataObj($appldataobj,
                       "itcloudarea:checkAutoactivation:".$self->Self);
         my $appl=$self->getPersistentModuleObject($appldataobj);

         my %qp=(
            email=>$requestoraccount,
            posix=>$requestoraccount,
            dsid=>$requestoraccount
         );

         my ($ur,$orderAllowed)=$appl->validateOrderingAuthorized($applid,\%qp);
         if ($orderAllowed){
            $isAutoactivationOk=1;
         }

         if ($isAutoactivationOk){
            $newrec->{cistatusid}="4";
            msg(INFO,"autoactivation by $requestoraccount");
            return(1);
         }
      }
   }

   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $applid=effVal($oldrec,$newrec,"applid");
   $applid=~s/[^0-9]//g;
   if ($applid eq ""){
      $self->LastMsg(ERROR,"no valid application specified");
      return(0);
   }
   my $app=getModuleObject($self->Config,"itil::appl");

   my $itcloudid=effVal($oldrec,$newrec,"cloudid");
   $itcloudid=~s/[^0-9]//g;
   my $c=getModuleObject($self->Config,"itil::itcloud");
   $c->SetFilter({id=>$itcloudid});
   my ($crec,$msg)=$c->getOnlyFirst(qw(cistatusid ordersupport deconssupport));
   if (!defined($crec)){
      $self->LastMsg(ERROR,"invalid cloud record");
      return(0);
   }
   if (!defined($oldrec) && 
       $crec->{cistatusid} ne "3" && $crec->{cistatusid} ne "4"){
      $self->LastMsg(ERROR,"invalid cistate in cloud record");
      return(0);
   }

   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (!defined($oldrec)){
         if (effVal($oldrec,$newrec,"cistatusid") eq "2"){ # on order
            if (!$crec->{ordersupport}){
               $self->LastMsg(ERROR,"no W5Base order support for this cloud");
               return(undef);
            }
            my $userid=$self->getCurrentUserId();
            if (!$app->validateOrderingAuthorized($applid,{userid=>$userid})){
               $self->LastMsg(ERROR,"no order access to specified application");
               return(undef);
            }
         }
      }
      if (effChanged($oldrec,$newrec,"cistatusid")){
         if (effVal($oldrec,$newrec,"cistatusid") eq "5"){ # deconstruction
            if (!$crec->{deconssupport}){
               $self->LastMsg(ERROR,
                     "no W5Base deconstruction support for this cloud");
               return(undef);
            }
         }
      }
   }
   if (effChanged($oldrec,$newrec,"applid")){
      if ($applid ne ""){
         $app->SetFilter({id=>\$applid});
         my ($orec,$msg)=$app->getOnlyFirst(qw(cistatusid));
         if (!defined($orec)){
            $self->LastMsg(ERROR,"invalid applid specified");
            return(0);
         }
         if ($orec->{cistatusid} ne "2" &&
             $orec->{cistatusid} ne "3" &&
             $orec->{cistatusid} ne "4"){
            $self->LastMsg(ERROR,
                  "specified application is no in acceptable CI-State");
            return(0);
         }
      }
      # reset cifirstactivation if applid is changed
      if (defined($oldrec) || #allow cifirstactivation insert from W5Server Jobs
          $self->isDataInputFromUserFrontend()){ 
         my $cifirstactivation=effVal($oldrec,$newrec,"cifirstactivation");
         if ($cifirstactivation ne ""){
            $newrec->{cifirstactivation}=undef;
         }
      }
      if (defined($oldrec) && (             # reset to available, if appl
           $oldrec->{cistatusid} eq "4" ||  # is changed
           $oldrec->{cistatusid} eq "5" ||
           $oldrec->{cistatusid} eq "6" )){
         $newrec->{cistatusid}="3";
      }
      if (defined($oldrec) && $oldrec->{cistatusid} eq "4"){
          $newrec->{previousapplid}=$oldrec->{applid};
      }
   }
   if (defined($oldrec) &&                # reactivation of a previous
       $oldrec->{cistatusid} eq "6" &&    # marked as deleted cloudarea
       defined($newrec) &&
       exists($newrec->{cistatusid}) &&
       $newrec->{cistatusid}<6){
      my $dd=CalcDateDuration($oldrec->{mdate},NowStamp("en"));
      if (!defined($dd) || $dd->{totaldays}>28){
         $newrec->{previousapplid}=undef;
         $newrec->{cifirstactivation}=undef;
         msg(WARN,"reactivation of an old (>28d) CloudArea (".
                  effVal($oldrec,$newrec,"id").")");
         msg(WARN,"with exclude of all previousappl and cifirstactivation");
      }
   }


   my $autoactivation=0;
   if (!defined($oldrec) || effVal($oldrec,$newrec,"cistatusid") eq "3"
                         || effVal($oldrec,$newrec,"cistatusid") eq "4"){
      if ($newrec->{cistatusid} eq "3" ||
          $newrec->{cistatusid} eq "4"){
         if ($self->checkAutoactivation($oldrec,$newrec)){
            $autoactivation=1;
         }
      }
   }


   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq "" || haveSpecialChar($name)){
      $self->LastMsg(ERROR,"invalid CloudArea name '%s'",$name);
      return(0);
   }

   if (effChanged($oldrec,$newrec,"cistatusid")){
      if ($newrec->{cistatusid}==4 && !$autoactivation){
         if ($self->isDataInputFromUserFrontend() && 
             !$self->IsMemberOf("admin")){
            my $itcloudcistatusid;
            if (defined($crec)){
               $itcloudcistatusid=$crec->{cistatusid};
            }
            if ($itcloudcistatusid!=4){
               $self->LastMsg(ERROR,"cloud is not active");
               return(0);
            }
            if (!$self->isWriteOnApplValid($applid,"default")){
               $self->LastMsg(ERROR,"activation of CloudArea only allowed ".
                                    "for application writeables");
               return(0);
            }
         }
      }
      if ($newrec->{cistatusid}==2 && 
          defined($oldrec) && $oldrec->{cistatusid}>2){
         $self->LastMsg(ERROR,"switch back to on order is not allowed");
         return(0);
      }
   }
   if (effVal($oldrec,$newrec,"cistatusid") eq "4"){
      my $cifirstactivation=effVal($oldrec,$newrec,"cifirstactivation");
      if ($cifirstactivation eq ""){
         $newrec->{cifirstactivation}=NowStamp("en");
      }
   }



   if (effChanged($oldrec,$newrec,"cistatusid")){
      if ($newrec->{cistatusid}==6){
         if ($self->isDataInputFromUserFrontend() && 
             !$self->IsMemberOf("admin")){
            if (!$self->isWriteOnITCloudValid($itcloudid,"default")){
               $self->LastMsg(ERROR,"mark as wasted only allowed ".
                                    "for cloud writeables");
               return(0);
            }
         }
      }
      if (defined($oldrec) && $oldrec->{cistatusid}==4 && 
          $newrec->{cistatusid}==6){
         $newrec->{previousapplid}=undef;
      }
      if ($newrec->{cistatusid}<2 ||
          (!defined($oldrec) && $newrec->{cistatusid}>2) ){
         if ($self->isDataInputFromUserFrontend() && 
             !$self->IsMemberOf("admin")){
            if (!$self->isWriteOnITCloudValid($itcloudid,"default")){
               $self->LastMsg(ERROR,"CI-Status not allowed to set");
               return(0);
            }
         }
      }
   }
   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));

   



   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return("default") if (!defined($oldrec));


   my $itcloudid=$oldrec->{"cloudid"};
   my $applid=$oldrec->{"applid"};
   if (defined($oldrec)){
      if ($oldrec->{cistatusid}>=3 &&
          $oldrec->{cistatusid}<=5){
         if ($self->isWriteOnApplValid($applid,"default")){
            return("default","control");
         }
      }
   }
   if ($self->isWriteOnITCloudValid($itcloudid,"default")){
      return("default");
   }
   return(undef);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $doNotify=0;
   msg(INFO,"FinishWrite itil::itcloudare");
   if (!defined($oldrec)){
      if (exists($newrec->{cistatusid}) &&
          $newrec->{cistatusid}==3){
         $doNotify=1;
      }
      if (exists($newrec->{cistatusid}) &&
          $newrec->{cistatusid}==2){  # on order
         $doNotify=4;
      }
   }
   else{
      if ($oldrec->{cistatusid}<4){
         if (defined($newrec) &&
             exists($newrec->{cistatusid}) &&
             $newrec->{cistatusid}==3){
            $doNotify=1;
         }
      }
      if ($oldrec->{cistatusid}==4 ||
          $oldrec->{cistatusid}==3){
         if (defined($newrec) &&
             exists($newrec->{cistatusid}) &&
             $newrec->{cistatusid}==5){
            if ($W5V2::OperationContext ne "W5Server" &&
                $W5V2::OperationContext ne "QualityCheck"){
               $doNotify=2;
            }
         }
      }
      if (defined($oldrec) && defined($newrec) &&
          exists($newrec->{applid}) &&
          $oldrec->{applid} ne $newrec->{applid}){
         $doNotify=1;
      }

      if ($oldrec->{cistatusid}!=4){
         if (defined($newrec) &&
             exists($newrec->{cistatusid}) &&
             $newrec->{cistatusid}==4){
            if (!defined($oldrec) || $oldrec->{cifirstactivation} eq ""){
               $doNotify=3;  # send activation mail only if they isn't send
            }                # already


            my $oldapplid=$oldrec->{previousapplid};
            if ($oldapplid eq ""){
               $oldapplid=$oldrec->{respapplid};
            } 
            my $newapplid=effVal($oldrec,$newrec,"applid");
            if ($oldapplid ne "" &&
                $newapplid ne $oldapplid){ # responsibility change
               msg(INFO,
                   "responsibity application change for $oldrec->{fullname} ".
                   "$oldapplid -> $newapplid");
               my $configitems="";
               foreach my $srec (@{$oldrec->{systems}}){
                  $configitems.="\n" if ($configitems ne "");
                  $configitems.="w5base://itil::system/Show/".
                                $srec->{id}."/fullname";
               }
               if ($configitems eq ""){
                  msg(INFO,"itil::itcloudare no configitems to transfer");
               }
               my $o=getModuleObject($self->Config,"itil::applcitransfer");
               if ($configitems ne "" && defined($o)){
                  my $cloudareaname=effVal($oldrec,$newrec,"fullname");
                  my $urlofcurrec=effVal($oldrec,$newrec,"urlofcurrentrec");
                  msg(INFO,
                      "FinishWrite itil::itcloudare create transfer record");
                  $o->ValidatedInsertRecord({
                     capplid=>$newapplid,
                     eapplid=>$oldapplid,
                     comments=>"This transfer is triggered by application ".
                               "change in CloudArea '".$cloudareaname."' at ".
                               $urlofcurrec,
                     configitems=>$configitems
                  });
               }
            }

         }
      }
      if ($oldrec->{cistatusid}==6 &&   # it it is a reactivateion without 
          exists($newrec->{applid}) &&  # aplication change, do no notification
          $oldrec->{applid} eq $newrec->{applid} &&
          exists($newrec->{cistatusid}) &&
          $newrec->{cistatusid} eq "4"){
         $doNotify=0;
      }

   }
   if ($doNotify){
      # send a mail to system/cluster databoss with cc on current user
      my $caid=effVal($oldrec,$newrec,"id");
      my $itca=$self->Clone();
      $itca->SetFilter({id=>\$caid});
      my ($carec,$msg)=$itca->getOnlyFirst(qw(name fullname applid cloudid
                                              urlofcurrentrec id));
      if (defined($carec)){
         my $appl=getModuleObject($self->Config,"itil::appl");
         $appl->SetFilter({id=>\$carec->{applid}});
         my ($arec,$msg)=$appl->getOnlyFirst(qw(ALL));

         my $itcloud=getModuleObject($self->Config,"itil::itcloud");
         $itcloud->SetFilter({id=>\$carec->{cloudid}});
         my ($crec,$msg)=$itcloud->getOnlyFirst(qw(ALL));

         my $supportcontact=$crec->{support};
         if ($supportcontact eq ""){
            $supportcontact=$crec->{platformresp};
         }
         if ($supportcontact eq ""){
            $supportcontact=$crec->{databoss};
         }
         if ($doNotify==1){
            my $urlofcurrentrec=$carec->{urlofcurrentrec};
            $appl->NotifyWriteAuthorizedContacts($arec,{},{
                     dataobj=>$self->Self,
                     emailbcc=>11634953080001,
                     dataobjid=>$carec->{id},
                     emailcategory=>'CloudAreaProcesses'
                  },{},sub{
               my ($subject,$ntext);
               my $subject=$self->T("New CloudArea",'itil::itcloudarea');
               $subject.=" ";
               $subject.=$carec->{fullname};
               my $ntext=$self->T("Dear databoss",'kernel::QRule');
               $ntext.=",\n\n";                             
               my $msgtempl=$self->T("CMSG001");
               $msgtempl=~s/%SUPPORTCONTACT%/$supportcontact/g;
               $msgtempl=~s/%URLOFCURRENTREC%/$urlofcurrentrec/g;
               $ntext.=sprintf($msgtempl,$carec->{name},$arec->{name});
               $ntext.="\n";
               return($subject,$ntext);
            });
         }
         if ($doNotify==2 || $doNotify==3 || $doNotify==4){
            my %notifyParam=(
                dataobj=>$self->Self,
                dataobjid=>$carec->{id},
                emailbcc=>11634953080001,
                emailcategory=>'CloudAreaProcesses'
            );
            if ($crec->{notifysupport}){
               if ($crec->{supportid} ne ""){
                  $notifyParam{emailcc}=$crec->{supportid};
               }
            }

            $itcloud->NotifyWriteAuthorizedContacts($crec,{},\%notifyParam,
                  {},sub{
               my ($subject,$ntext);
               my $subject="??";
               if ($doNotify==2){
                  $subject=$self->T("user deactivation of CloudArea",
                                    'itil::itcloudarea');
               }
               if ($doNotify==3){
                  $subject=$self->T("user activation of CloudArea",
                                    'itil::itcloudarea');
               }
               if ($doNotify==4){
                  $subject=$self->T("CloudArea order",'itil::itcloudarea');
               }
               $subject.=" ";
               $subject.=$carec->{fullname};
               my $ntext=$self->T("Dear databoss",'kernel::QRule');
               $ntext.=",\n\n";                             
               if ($doNotify==2){
                  $ntext.=sprintf(
                          $self->T("CMSG002"),
                                   $carec->{name},$arec->{name});
               }
               if ($doNotify==3){
                  $ntext.=sprintf(
                          $self->T("CMSG003"),
                                   $carec->{name},$arec->{name});
               }
               if ($doNotify==4){
                  my $msgtempl=$self->T("CMSG004");
                  $ntext.=sprintf($msgtempl,$carec->{name},$arec->{name});
               }
               $ntext.="\n";
               return($subject,$ntext);
            });
         }
      }
   }
   return($self->SUPER::FinishWrite($oldrec,$newrec));
}





sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default appl inm 
             systems swinstances ipaddresses misc control source));
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   if ($lock>0 ||
       $#{$rec->{swinstances}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no ".
          "software instance relations");
      return(0);
   }

   return(1);
}


sub validateCloudAreaImportState
{
   my $self=shift;
   my $importname=shift;
   my $cloudrec=shift;
   my $cloudarearec=shift;
   my $w5applrec=shift;

   my $srcsys=$cloudarearec->{srcsys};

   my $appl=getModuleObject($self->Config,"itil::appl");
   my $cloudrecFullLoaded=0;

   if (!defined($cloudrec) &&
       defined($cloudarearec) &&
       $cloudarearec->{cloudid} ne ""){ #load cloudrec if it is not already done
      my $itcloud=getModuleObject($self->Config,"itil::itcloud");
      $itcloud->SetFilter({id=>\$cloudarearec->{cloudid}});
      my ($arec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
      if (defined($arec)){
         $cloudrec=$arec;
         $cloudrecFullLoaded++;
      }
   }
   if (!defined($w5applrec) &&
       defined($cloudarearec)){
      if ($cloudarearec->{applid} ne ""){ # load applrec if it is not already
         $appl->SetFilter({id=>\$cloudarearec->{applid}});
         my ($arec,$msg)=$appl->getOnlyFirst(qw(ALL));
         if (defined($arec)){
            $w5applrec=$arec;
         }
      }
      if (!defined($w5applrec)){
         # Notify for invalid application in CloudArea
         if ($cloudrec->{id} ne ""){
            my $itcloud=getModuleObject($self->Config,"itil::itcloud");
            if (!$cloudrecFullLoaded){
               $itcloud->SetFilter({id=>\$cloudarearec->{cloudid}});
               my ($arec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
               if (defined($arec)){
                  $cloudrec=$arec;
               }
            }
            my $supportcontact=$cloudrec->{support};
            if ($supportcontact eq ""){
               $supportcontact=$cloudrec->{platformresp};
            }
            if ($supportcontact eq ""){
               $supportcontact=$cloudrec->{databoss};
            }
            my %notifyParam=(
               emailcategory=>[$srcsys,'ImportReject','InvalidApplication'],
               emailcc=>[],
               emailbcc=>[
                  11634953080001, # HV
               ]
            );
            # no notify on testenv
            if ($self->Config->Param("W5BaseOperationMode") ne "test"){
               $itcloud->NotifyWriteAuthorizedContacts($cloudrec,{},
                                            \%notifyParam,{mode=>'ERROR'},sub{
                  my ($_self,$notifyParam,$notifycontrol)=@_;
                  my $cloudcontactadded=0;
                  if (!($cloudrec->{allowuncleanseq})){
                     foreach my $fld (qw(securityrespid 
                                         supportid 
                                         platformrespid)){
                        if ($cloudrec->{$fld} ne "" && 
                            !in_array($notifyParam->{emailcc},
                                      $cloudrec->{$fld}) &&
                            !in_array($notifyParam->{emailto},
                                      $cloudrec->{$fld})){
                           push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
                           $cloudcontactadded++;
                        }
                     }
                  }
                  my ($subject,$ntext);
                  my $subject=$self->T("automatic import rejected",
                                       'itil::itcloudarea')." - ".
                              $self->T("invalid application in CloudArea",
                                       'itil::itcloudarea');
                  my $tmpl=$self->getParsedTemplate(
                             "tmpl/genericSystemImport_BadAppInCloudArea",{
                     static=>{
                        SUPPORTCONTACT=>$supportcontact,
                        SYSTEM=>$importname,
                        CLOUD=>$cloudrec->{name}
                     }
                  });
                  return($subject,$tmpl);
               });
            }
         }
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"invalid appl record in CloudArea");
         }
         return(undef);
      }
   }

   # check if $w5applrec->{cistatusid} is in 3 4 

   if (!($w5applrec->{cistatusid} eq "3" ||
         $w5applrec->{cistatusid} eq "4")){
      my %notifyParam=(
         emailcategory=>[$srcsys,'ImportReject','InvalidApplication'],
         emailcc=>[],
         emailbcc=>[
            11634953080001, # HV
         ]
      );
      # no notify on testenv
      if ($self->Config->Param("W5BaseOperationMode") ne "test"){
         $appl->NotifyWriteAuthorizedContacts($w5applrec,{},
                                              \%notifyParam,{mode=>'ERROR'},sub{
            my ($_self,$notifyParam,$notifycontrol)=@_;
            if (!($cloudrec->{allowuncleanseq})){
               foreach my $fld (qw(securityrespid supportid)){
                  if ($cloudrec->{$fld} ne "" && 
                      !in_array($notifyParam->{emailcc},$cloudrec->{$fld}) &&
                      !in_array($notifyParam->{emailto},$cloudrec->{$fld})){
                     push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
                  }
               }
            }
            my ($subject,$ntext);
            my $subject=$self->T("automatic import rejected",
                                 'itil::itcloudarea')." - ".
                        $self->T("invalid application cistatus",
                                 'itil::itcloudarea');
            my $cloudnamereference=$cloudarearec->{fullname};
            if ($cloudnamereference ne "" &&
                $cloudarearec->{srcsys} ne "" &&
                $cloudarearec->{srcid} ne ""){
               $cloudnamereference.=" (".
                                    $cloudarearec->{srcsys}.
                                    ":".
                                    $cloudarearec->{srcid}.")";
            }
            my $tmpl=$self->getParsedTemplate(
                       "tmpl/genericSystemImport_BadAppl",{
               static=>{
                  SYSTEM=>$importname,
                  URL=>$w5applrec->{urlofcurrentrec},
                  CLOUDAREA=>$cloudnamereference,
                  APPL=>$w5applrec->{name}
               }
            });
            return($subject,$tmpl);
         });
      }
      if ($self->isDataInputFromUserFrontend()){
         $self->LastMsg(ERROR,"invalid appl cistatus");
      }
      return(undef);
   }


   # check if $cloudarearec->{cistatusid} is in 4
   if (!($cloudarearec->{cistatusid} eq "4")){
      my %notifyParam=(
         emailcategory=>[$srcsys,'ImportReject','InvalidApplication'],
         emailcc=>[],
         emailbcc=>[
            11634953080001, # HV
         ]
      );
      foreach my $fld (qw(securityrespid supportid)){
         if ($cloudrec->{$fld} ne "" && 
             !in_array($notifyParam{emailcc},$cloudrec->{$fld})){
            push(@{$notifyParam{emailcc}},$cloudrec->{$fld});
         }
      }
      # no notify on testenv
      if ($self->Config->Param("W5BaseOperationMode") ne "test"){
         $appl->NotifyWriteAuthorizedContacts($w5applrec,{},
                                              \%notifyParam,{mode=>'ERROR'},sub{
            my ($_self,$notifyParam,$notifycontrol)=@_;
            my $cloudcontactadded=0;
            foreach my $fld (qw(securityrespid supportid)){
               if ($cloudrec->{$fld} ne "" && 
                   !in_array($notifyParam->{emailcc},$cloudrec->{$fld}) &&
                   !in_array($notifyParam->{emailto},$cloudrec->{$fld})){
                  push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
                  $cloudcontactadded++;
               }
            }
            if (!$cloudcontactadded){
               foreach my $fld (qw(platformrespid)){
                  if ($cloudrec->{$fld} ne "" && 
                      !in_array($notifyParam->{emailcc},$cloudrec->{$fld}) &&
                      !in_array($notifyParam->{emailto},$cloudrec->{$fld})){
                     push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
                     $cloudcontactadded++;
                  }
               }
            }
            if (!$cloudcontactadded){
               foreach my $fld (qw(databossid)){
                  if ($cloudrec->{$fld} ne "" && 
                      !in_array($notifyParam->{emailcc},$cloudrec->{$fld}) &&
                      !in_array($notifyParam->{emailto},$cloudrec->{$fld})){
                     push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
                     $cloudcontactadded++;
                  }
               }
            }
            my ($subject,$ntext);
            my $subject=$self->T("automatic import rejected",
                                 'itil::itcloudarea')." - ".
                        $self->T("invalid CloudArea cistatus",
                                 'itil::itcloudarea');

            my $cloudnamereference=$cloudarearec->{fullname};
            if ($cloudnamereference ne "" &&
                $cloudarearec->{srcsys} ne "" &&
                $cloudarearec->{srcid} ne ""){
               $cloudnamereference.=" (".
                                    $cloudarearec->{srcsys}.
                                    ":".
                                    $cloudarearec->{srcid}.")";
            }
            my $tmpl=$self->getParsedTemplate(
                       "tmpl/genericSystemImport_BadCloudArea",{
               static=>{
                  SYSTEM=>$importname,
                  URL=>$cloudarearec->{urlofcurrentrec},
                  CLOUDAREA=>$cloudnamereference,
                  APPL=>$w5applrec->{name}
               }
            });
            return($subject,$tmpl);
         });
      }
      if ($self->isDataInputFromUserFrontend()){
         $self->LastMsg(ERROR,"CloudArea:'".$cloudarearec->{fullname}."'");
         $self->LastMsg(ERROR,"invalid CloudArea cistatus");
      }
      return(undef);
   }
   return(1);
}









1;
