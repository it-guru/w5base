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
                label         =>'LinkID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'qitcloudarea.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full qualified cloud area',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                htmlwidth     =>'280px',
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
                label         =>'cloud area name',
                dataobjattr   =>'qitcloudarea.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
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

      new kernel::Field::Textarea(
                name          =>'description',
                searchable    =>0,
                label         =>'Cloud Area description',
                dataobjattr   =>'qitcloudarea.description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'qitcloudarea.comments'),

      new kernel::Field::Text(
                name          =>'conumber',
                translation   =>'itil::appl',
                htmleditwidth =>'150px',
                htmlwidth     =>'100px',
                group         =>'appl',
                readonly     =>1,
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
                vjoindisp     =>['name','cistatus','network']),

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
                vjoindisp     =>['name','systemid','cistatus']),

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
       !$self->IsMemberOf([qw(admin w5base.itil.read)],
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


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   my $itcloudid=effVal($oldrec,$newrec,"cloudid");
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (!defined($oldrec)){
         if (!$self->isWriteOnITCloudValid($itcloudid,"areas")){
            $self->LastMsg(ERROR,"no write access to specified cloud");
            return(undef);
         }
      }
   }
   my $applid=effVal($oldrec,$newrec,"applid");
   $applid=~s/[^0-9]//g;
   if ($applid eq ""){
      $self->LastMsg(ERROR,"no valid application specified");
      return(0);
   }
   if (!defined($oldrec) || effChanged($oldrec,$newrec,"applid")){
      if ($applid ne ""){
         my $o=getModuleObject($self->Config,"itil::appl");
         $o->SetFilter({id=>\$applid});
         my ($orec,$msg)=$o->getOnlyFirst(qw(cistatusid));
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
   }


   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq "" || haveSpecialChar($name)){
      $self->LastMsg(ERROR,"invalid cloud area name '%s'",$name);
      return(0);
   }

   if (!defined($oldrec) || effChanged($oldrec,$newrec,"cistatusid")){
      if ($newrec->{cistatusid}==4){
         if ($self->isDataInputFromUserFrontend() && 
             !$self->IsMemberOf("admin")){
            my $c=getModuleObject($self->Config,"itil::itcloud");
            $c->SetFilter({id=>$itcloudid});
            my ($crec,$msg)=$c->getOnlyFirst(qw(cistatusid));
            my $itcloudcistatusid;
            if (defined($crec)){
               $itcloudcistatusid=$crec->{cistatusid};
            }
            if ($itcloudcistatusid!=4){
               $self->LastMsg(ERROR,"cloud is not active");
               return(0);
            }
            if (!$self->isWriteOnApplValid($applid,"default")){
               $self->LastMsg(ERROR,"activation of cloudarea only allowed ".
                                    "for application writeables");
               return(0);
            }
         }
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
      if ($newrec->{cistatusid}<3){
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
   if ($self->isWriteOnITCloudValid($itcloudid,"default")){
      return("default");
   }
   if (defined($oldrec)){
      if ($oldrec->{cistatusid}>=3 &&
          $oldrec->{cistatusid}<=5){
         if ($self->isWriteOnApplValid($applid,"default")){
            return("default");
         }
      }
   }
   return(undef);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $doNotify=0;
   if (!defined($oldrec)){
      if (exists($newrec->{cistatusid}) &&
          $newrec->{cistatusid}==3){
         $doNotify=1;
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
            $doNotify=2;
         }
      }
      if ($oldrec->{cistatusid}==3 &&
          exists($newrec->{applid}) &&
          $oldrec->{applid} ne $newrec->{applid}){
         $doNotify=1;
      }
      if ($oldrec->{cistatusid}!=4){
         if (defined($newrec) &&
             exists($newrec->{cistatusid}) &&
             $newrec->{cistatusid}==4){
            $doNotify=3;
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
         if ($doNotify==1){
            $appl->NotifyWriteAuthorizedContacts($arec,{},{
                     dataobj=>$self->Self,
                     dataobjid=>$carec->{id}
                  },{},sub{
               my ($subject,$ntext);
               my $subject=$self->T("New Cloud-Area",'itil::itcloudarea');
               $subject.=" ";
               $subject.=$carec->{fullname};
               my $ntext=$self->T("Dear databoss",'kernel::QRule');
               $ntext.=",\n\n";                             
               $ntext.=sprintf($self->T("CMSG001"),
                               $carec->{name},$arec->{name});
               $ntext.="\n";
               return($subject,$ntext);
            });
         }
         if ($doNotify==2 || $doNotify==3){
            my $itcloud=getModuleObject($self->Config,"itil::itcloud");
            $itcloud->SetFilter({id=>\$carec->{cloudid}});
            my ($crec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
            my %notifyParam=(
                dataobj=>$self->Self,
                dataobjid=>$carec->{id},
                emailbcc=>11634953080001
            );
            if ($crec->{supportid} ne ""){
               $notifyParam{emailcc}=$crec->{supportid};
            }

            $itcloud->NotifyWriteAuthorizedContacts($crec,{},\%notifyParam,
                  {},sub{
               my ($subject,$ntext);
               my $subject="??";
               if ($doNotify==2){
                  $subject=$self->T("user deactivation of Cloud-Area",
                                    'itil::itcloudarea');
               }
               if ($doNotify==3){
                  $subject=$self->T("user activation of Cloud-Area",
                                    'itil::itcloudarea');
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
            my %notifyParam=(
               emailcategory=>[$srcsys,'ImportReject','InvalidApplication'],
               emailcc=>[],
               emailbcc=>[
                  11634953080001, # HV
               ]
            );
            $itcloud->NotifyWriteAuthorizedContacts($cloudrec,{},
                                             \%notifyParam,{mode=>'ERROR'},sub{
               my ($_self,$notifyParam,$notifycontrol)=@_;
               my $cloudcontactadded=0;
               foreach my $fld (qw(securityrespid supportid platformrespid)){
                  if ($cloudrec->{$fld} ne "" && 
                      !in_array($notifyParam->{emailcc},$cloudrec->{$fld}) &&
                      !in_array($notifyParam->{emailto},$cloudrec->{$fld})){
                     push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
                     $cloudcontactadded++;
                  }
               }
               my ($subject,$ntext);
               my $subject=$self->T("automatic import rejected",
                                    'itil::itcloudarea')." - ".
                           $self->T("invalid application in cloudarea",
                                    'itil::itcloudarea');
               my $tmpl=$self->getParsedTemplate(
                          "tmpl/genericSystemImport_BadAppInCloudArea",{
                  static=>{
                     SYSTEM=>$importname,
                     CLOUD=>$cloudrec->{name}
                  }
               });
               return($subject,$tmpl);
            });
         }
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"invalid appl record in cloudarea");
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
      $appl->NotifyWriteAuthorizedContacts($w5applrec,{},
                                           \%notifyParam,{mode=>'ERROR'},sub{
         my ($_self,$notifyParam,$notifycontrol)=@_;
         foreach my $fld (qw(securityrespid supportid)){
            if ($cloudrec->{$fld} ne "" && 
                !in_array($notifyParam->{emailcc},$cloudrec->{$fld}) &&
                !in_array($notifyParam->{emailto},$cloudrec->{$fld})){
               push(@{$notifyParam->{emailcc}},$cloudrec->{$fld});
            }
         }
         my ($subject,$ntext);
         my $subject=$self->T("automatic import rejected",
                              'itil::itcloudarea')." - ".
                     $self->T("invalid application cistatus",
                              'itil::itcloudarea');
         my $tmpl=$self->getParsedTemplate(
                    "tmpl/genericSystemImport_BadAppl",{
            static=>{
               SYSTEM=>$importname,
               URL=>$w5applrec->{urlofcurrentrec},
               CLOUDAREA=>$cloudarearec->{fullname},
               APPL=>$w5applrec->{name}
            }
         });
         return($subject,$tmpl);
      });
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
                     $self->T("invalid cloudarea cistatus",
                              'itil::itcloudarea');
         my $tmpl=$self->getParsedTemplate(
                    "tmpl/genericSystemImport_BadCloudArea",{
            static=>{
               SYSTEM=>$importname,
               URL=>$cloudarearec->{urlofcurrentrec},
               CLOUDAREA=>$cloudarearec->{fullname},
               APPL=>$w5applrec->{name}
            }
         });
         return($subject,$tmpl);
      });
      if ($self->isDataInputFromUserFrontend()){
         $self->LastMsg(ERROR,"invalid cloudarea cistatus");
      }
      return(undef);
   }
   return(1);
}









1;
