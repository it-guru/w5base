package base::infoabo;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                group         =>'source',
                searchable    =>0,
                dataobjattr   =>'infoabo.id'),

      new kernel::Field::TextDrop(
                name          =>'user',
                label         =>'User',
                group         =>['relation','newin'],
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(
                name          =>'parentobj',
                label         =>'Info Source',
                group         =>['default','newin'],
                uploadable    =>0,
                selectfix     =>1,
                htmleditwidth =>'100%',
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                getPostibleValues=>\&getPostibleParentObjs,
                jsonchanged   =>\&getOnChangedScript,
                dataobjattr   =>'infoabo.parentobj'),

      new kernel::Field::MultiDst (
                name          =>'targetname',
                htmlwidth     =>'200',
                htmleditwidth =>'400',
                uploadable    =>0,
                label         =>'Target-Name',
                uploadable    =>0,
                dst           =>[],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{parentobj} eq "base::staticinfoabo"){
                      return(0);
                   }
                   return(1);
                },
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                dsttypfield   =>'parentobj',
                dstidfield    =>'refid'),

      new kernel::Field::Select(
                name          =>'mode',
                uploadable    =>0,
                searchable    =>0,
                label         =>'Info Mode',
                selectfix     =>1,
                readonly      =>1,
                htmleditwidth =>'100%',
                getPostibleValues=>\&getPostibleModes,
                dataobjattr   =>'infoabo.mode'),

      new kernel::Field::Select(
                name          =>'modifiable',
                uploadable    =>0,
                searchable    =>0,
                label         =>'Modifiable',
                readonly      =>1,
                onRawValue    =>sub{
                    my $self=shift;
                    my $current=shift;
                    my $app=$self->getParent;
                    my $d="USERMODIFIABLE";
                    if (defined($current)){
                       if ($current->{parentobj} eq "base::staticinfoabo"){
                          foreach my $obj (values(%{$app->{staticinfoabo}})){
                             my ($ctrl)=$obj->getControlData($self);
                             while(my $trans=shift(@$ctrl)){
                                my $crec=shift(@$ctrl);
                                if ($crec->{name} eq $current->{mode}){
                                   if (exists($crec->{force})){
                                      if ($crec->{force} eq "1"){
                                         $d="FORECEDON";
                                      }
                                      if ($crec->{force} eq "0"){
                                         $d="FORECEDOFF";
                                      }
                                   }
                                }
                             }
                          }
                       }
                    }
                    return($d);
                 }),


      new kernel::Field::Date(
                name          =>'invalidsince',
                group         =>'relation',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{$self->{name}} ne ""){
                      return(1);
                   }
                   return(0);
                },
                label         =>'relation invalid since',
                uploadable    =>0,
                dataobjattr   =>'infoabo.invalidsince'),
                                                 
      new kernel::Field::Link(
                name          =>'usercistatusid',
                group         =>'relation',
                label         =>'User CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Email(
                name          =>'email',
                group         =>'relation',
                label         =>'Contact E-Mail',
                uploadable    =>0,
                readonly      =>1,
                dataobjattr   =>'contact.email'),

      new kernel::Field::Select(
                name          =>'usercistatus',
                htmleditwidth =>'40%',
                group         =>'relation',
                readonly      =>'1',
                uploadable    =>0,
                label         =>'User CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['usercistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'active',
                label         =>'Active',
                transprefix   =>'boolean.',
                value         =>[1,0],
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;

                   return(0) if ($app->isForced($param{current}));
                   return(1);
                },
                htmleditwidth =>'80px',
                dataobjattr   =>'infoabo.active'),

      new kernel::Field::Text(
                name          =>'parent',
                searchable    =>0,
                group         =>'relation',
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                label         =>'internal parent object name',
                dataobjattr   =>'infoabo.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                searchable    =>0,
                group         =>['relation','newin'],
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                depend        =>['parentobj'],
                label         =>'refid',
                dataobjattr   =>'infoabo.refid'),

      new kernel::Field::Text(
                name          =>'rawmode',
                label         =>'raw Info Mode',
                group         =>['relation','newin'],
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                dataobjattr   =>'infoabo.mode'),

      new kernel::Field::Group(
                name          =>'managedby',
                label         =>'managed by group',
                vjoinon       =>'managedbyid',
                htmldetail    =>0,
                readonly      =>1),

      new kernel::Field::Text(
                name          =>'userid',
                label         =>'W5Base UserID',
                htmldetail    =>0,
                uploadable    =>0,
                readonly      =>1,
                selectfix     =>1,
                dataobjattr   =>'infoabo.userid'),

      new kernel::Field::Text(
                name          =>'managedbyid',
                label         =>'Managed by Group ID',
                selectfix     =>1,
                htmldetail    =>0,
                uploadable    =>0,
                readonly      =>1,
                dataobjattr   =>'contact.managedby'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'comments',
                label         =>'Comments',
                dataobjattr   =>'infoabo.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'infoabo.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'infoabo.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                htmldetail    =>'0',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'infoabo.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                htmldetail    =>'0',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'infoabo.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                htmldetail    =>'0',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'infoabo.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'infoabo.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'infoabo.modifydate'),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my $app=$self->getParent;
                   my %param=@_;

                   return(0) if ($app->isForced($param{current}));
                   return(1);
                },
                dataobjattr   =>'infoabo.expiration'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'infoabo.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'infoabo.realeditor'),
      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'infoabo.lastqcheck'),
   );
   $self->setDefaultView(qw(parentobj targetname mode user active));
   $self->setWorktable("infoabo");
   $self->LoadSubObjs("ext/infoabo","infoabo");
   $self->LoadSubObjs("ext/staticinfoabo","staticinfoabo");
   $self->{admwrite}=[qw(admin w5base.base.infoabo.write)]; 
   $self->{admread}=[@{$self->{admwrite}},"w5base.base.infoabo.read"];

   $self->{history}={
      update=>[
         'local'
      ],
      delete=>[
         {dataobj=>sub{
             my $mode=shift;
             my $oldrec=shift;
             my $newrec=shift;
             my $dataobj=effVal($oldrec,$newrec,"parentobj");
             return($dataobj);
          },id=>'refid', field=>'user',as=>'infoabos'}
      ]
   };



   #
   # MultiDest Destination
   #
   my @dst=();   
   foreach my $obj (values(%{$self->{infoabo}})){
      my ($ctrl)=$obj->getControlData($self);
      foreach my $obj (keys(%$ctrl)){
         push(@dst,$obj,$ctrl->{$obj}->{target});
      }
   }
   push(@dst,"base::staticinfoabo","fullname");
   my $fo=$self->getField("targetname");
   $fo->{dst}=\@dst;

   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default relation comments source));
}


sub isForced
{
   my $self=shift;
   my $rec=shift;
   return(0) if (!defined($rec));
   if ($rec->{parentobj} eq "base::staticinfoabo"){
      foreach my $obj (values(%{$self->{staticinfoabo}})){
         my ($ctrl)=$obj->getControlData($self);
         while(my $trans=shift(@$ctrl)){
            my $crec=shift(@$ctrl);
            if ($crec->{name} eq $rec->{mode}){
               return(1) if (exists($crec->{force}));
            }
         }
      }
   }
   return(0);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join contact ".
          "on $worktable.userid=contact.userid ");
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;
  
   if (!$self->isDirectFilter(@flt)){
      if (!$self->isInfoAboAdmin("read")){
         my $userid=$self->getCurrentUserId();
         my @useridlist=($userid);
     
         my %a=$self->getGroupsOf($userid, [qw(RContactAdmin)], 'direct');
         my @idl=keys(%a);
         if ($#idl!=-1 && $idl[0] ne ""){
            my $u=getModuleObject($self->Config,"base::user");
            $u->SetFilter({managedbyid=>\@idl});
            foreach my $urec ($u->getHashList("userid")){
               push(@useridlist,$urec->{userid});
            }
         }
         push(@flt,[ {userid=>\@useridlist}, ]);
      }
   }
   return($self->SetFilter(@flt));
}


sub initSearchQuery
{
   my $self=shift;

   if ($self->IsMemberOf($self->{admread},"RMember")){
      my $userid=$self->getCurrentUserId();
      my $UserCache=$self->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}}) &&
          !defined(Query->Param("search_user"))){
         Query->Param("search_user"=>'"'.
                      $UserCache->{$ENV{REMOTE_USER}}->{rec}->{fullname}.'"');
      }
   }
}




sub getOnChangedScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;
var e=document.forms[0].elements['Formated_parentobj'];
var m=document.forms[0].elements['Formated_mode'];
var found=false;
   if (e && m ){
EOF
   foreach my $obj (values(%{$app->{infoabo}})){
      my ($ctrl)=$obj->getControlData($self);
      foreach my $objn (keys(%{$ctrl})){
         my @modes=$app->getModesFor($objn);
         $d.="if (e.value==\"$objn\"){";
         my $c=0;
         while(my $k=shift(@modes)){
            my $v=shift(@modes);
            $d.="m.options[$c]=new Option(\"$v\",\"$k\");";
            $c++;
         }
         $d.="found=true;}";
         $d.="m.options.length=$c;";
      }
   }
   $d.="}if (!found){m.options.length=0;}";
   return($d);
}

sub getAboTemplateRecordsFor
{
   my $self=shift;
   my $parentobj=shift;
   my $parentobj2=shift;


   my @res=();
   my %mode=();
   if ($parentobj eq "base::staticinfoabo" || $parentobj eq ""){
      my $st=getModuleObject($self->Config,"base::staticinfoabo");
      foreach my $rec ($st->getHashList(qw(id name fullname force))){
         $mode{$rec->{name}}={
             name=>$rec->{name},
             id=>$rec->{id},
             type=>'staticinfoabo',
             fullname=>$rec->{fullname},
             force=>$rec->{force},
             parentobj=>'base::staticinfoabo'
         };
         push(@res,$mode{$rec->{name}});
      }
   }
   if ($parentobj ne "base::staticinfoabo"){
      foreach my $obj (values(%{$self->{infoabo}})){
         my ($ctrl)=$obj->getControlData($self);
         foreach my $obj (keys(%$ctrl)){
            if ($parentobj eq $obj ||
                $parentobj2 eq $obj || $parentobj eq ""){
               my @l=@{$ctrl->{$obj}->{mode}};
               while(my $m=shift(@l)){
                  my $t=shift(@l);
                  $mode{$m}={
                      name=>$m,
                      type=>'infoabo',
                      fullname=>$self->T($m,$t),
                      force=>'',
                      parentobj=>$parentobj
                  };
                  push(@res,$mode{$m});
               }
            }
         }
      }
   }
   return({mode=>\%mode,modes=>\@res});
}

sub getModesFor
{
   my $self=shift;
   my $parentobj=shift;
   my $parentobj2=shift;


   my @res=();
   if ($parentobj eq "base::staticinfoabo" || $parentobj eq ""){
      my $st=getModuleObject($self->Config,"base::staticinfoabo");
      foreach my $rec ($st->getHashList(qw(id name fullname))){
         push(@res,$rec->{name});
         push(@res,$rec->{fullname});
      }
      return(@res) if ($parentobj eq "base::staticinfoabo");
   }
   foreach my $obj (values(%{$self->{infoabo}})){
      my ($ctrl)=$obj->getControlData($self);
      foreach my $obj (keys(%$ctrl)){
         if ($parentobj eq $obj ||
             $parentobj2 eq $obj || $parentobj eq ""){
            my @l=@{$ctrl->{$obj}->{mode}};
            while(my $m=shift(@l)){
               my $t=shift(@l);
               push(@res,$m,$self->T($m,$t));
            }
         }
      }
   }
   return(@res);
}

sub getPostibleModes
{
   my $self=shift;
   my $current=shift;
   my $parent=$current->{parentobj};
   my $app=$self->getParent;

   if ($parent eq "base::staticinfoabo"){
      # find static targets and translations
      my @opt;
      foreach my $obj (values(%{$app->{staticinfoabo}})){
         my ($ctrl)=$obj->getControlData($self);
         while(my $trans=shift(@$ctrl)){
            my $rec=shift(@$ctrl);
            if ($current->{refid}==$rec->{id}){
               push(@opt,$current->{mode},$app->T($current->{mode},$trans));
            }
         }
      }
      return(@opt);
   }
   return($self->getParent->getModesFor($parent));
}

sub getPostibleParentObjs
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   my @opt;
   push(@opt,"","");

   my %opt;
   foreach my $obj (values(%{$app->{infoabo}})){
      my ($ctrl)=$obj->getControlData($self);
      foreach my $obj (keys(%$ctrl)){
         $opt{$app->T($obj,$obj)." ($obj) "}=$obj;
      }
   }
   foreach my $k (sort(keys(%opt))){
      push(@opt,$opt{$k},$k);
   }
   push(@opt,"base::staticinfoabo",
        $app->T("base::staticinfoabo","base::staticinfoabo"));
   return(@opt);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if (exists($newrec->{expiration}) &&
       $newrec->{expiration} ne $oldrec->{expiration} &&
       $newrec->{expiration} ne ""){
      my $nowstamp=NowStamp("en");
      my $expiration=effVal($oldrec,$newrec,"expiration");
      my $duration=CalcDateDuration($nowstamp,$expiration);
      if (!defined($duration) || $duration->{days}<0){
         $self->LastMsg(ERROR,"expiration to long in the past");
         return(undef);
      }
   }


   my $refid=effVal($oldrec,$newrec,"refid");
   if (!($refid=~m/^[a-z,0-9,_-]+$/)){
      $self->LastMsg(ERROR,"missing correct refid");
      return(0);
   }
   my $mode=effVal($oldrec,$newrec,"mode");
   if ($mode eq ""){
      $mode=effVal($oldrec,$newrec,"rawmode");
   }
   if ($mode eq "" && !defined($oldrec) && $newrec->{rawmode} eq ""){
      $self->LastMsg(ERROR,"invalid mode specified");
      return(0);
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $parent=effVal($oldrec,$newrec,"parent");
   if ($parentobj eq "" && $parent eq ""){
      $self->LastMsg(ERROR,"no parentobj specified");
      return(0);
   }
   if ($parentobj eq ""){
      $parentobj=$parent;
   }
   if (!defined($oldrec)){
      my $pobj=getModuleObject($self->Config,$parentobj);
      if (!defined($pobj)){
         $self->LastMsg(ERROR,"invalid parentobj specified");
         return(0);
      }
      my $pobjidobj=$pobj->IdField();
      if (!defined($pobjidobj)){
         $self->LastMsg(ERROR,"can not identify id field in parentobj");
         return(0);
      }
      $pobj->SetFilter({$pobjidobj->Name()=>\$refid});
      my @l=$pobj->getHashList($pobjidobj->Name());
      if ($#l!=0){
         $self->LastMsg(ERROR,"refid does not identify exactly one record");
         return(0);
      }
   }
   else{
      delete($newrec->{refid}); 
      delete($newrec->{mode}); 
      delete($newrec->{rawmode}); 
      delete($newrec->{parent}); 
      delete($newrec->{parentobj}); 
   }

   my %modelist=$self->getModesFor($parentobj);

   my @modelist=keys(%modelist);

   if ($self->isDataInputFromUserFrontend()){
      if (!in_array(\@modelist,$mode)){
         msg(ERROR,"invalid rawmode=$mode - allowed=".join(",",@modelist));
         $self->LastMsg(ERROR,"invalid interal infomode");
         return(0);
      }
   }

   my $curuserid=$self->getCurrentUserId();
   my $userid=effVal($oldrec,$newrec,"userid");
   if ($userid eq ""){
      $self->LastMsg(ERROR,"invalid userid specified");
      return(0);
   }
   my $parentname;
   if (my $p=$self->getParent()){
      $parentname=$p->Self();
   }
   if ($parentname ne "faq::forum" &&  # not fine - but it works
       $self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){ 
      # sec check
      if ($curuserid ne $userid){
         if (effVal($oldrec,$newrec,"parent") eq "base::staticinfoabo"){
         }
         if (!$self->IsMemberOf($self->{admwrite},"RMember")){
            # now check, if $userid is managed by $curuserid
            my $u=getModuleObject($self->Config,"base::user");
            $u->SetFilter({userid=>\$userid});
            my ($urec,$msg)=$u->getOnlyFirst(qw(managedbyid));
            return(0) if (!defined($urec));
            if (!$self->IsMemberOf($urec->{managedbyid},
                                   ["RContactAdmin"],"up")){
               $self->LastMsg(ERROR,"you are not manager of this contact");
     
               return(0);
            }

         }
      }
   }

   return(1);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $userid=$self->getCurrentUserId();
   my $requserid=effVal($oldrec,$newrec,"userid");
   if ($userid ne $requserid &&
       !($self->IsMemberOf("admin")) &&
       $W5V2::OperationContext ne "QualityCheck"){
      my $ia=getModuleObject($self->Config,"base::infoabo");
      my $id=effVal($oldrec,$newrec,"id");
      $ia->SetFilter({id=>\$id});
      my ($iarec,$msg)=$ia->getOnlyFirst(qw(ALL));
      if (defined($iarec) && $iarec->{parent} ne "base::staticinfoabo"){
         my $modeobj=$ia->getField("mode");
         my $mode=$modeobj->FormatedDetail($iarec,"HtmlMail"); 
         my $msg="";
         if (!defined($oldrec) && !exists($newrec->{active})){
            $newrec->{active}=1;
         }
         if (!defined($oldrec) &&
             (exists($newrec->{active}) && $newrec->{active}==1)){
            # InfoAbo neu eingetragen im Status Aktiv (u.U. mit Verfallsdatum)
            $msg.=$self->T("I have assigned a new InfoAbo to you.");
            $msg.="\n\n";
            $msg.=$self->T("The InfoAbo")." '".
                  $mode.
                  "'".$self->T(" for ")."'".
                  $iarec->{targetname}.
                  "' ".$self->T("is now <b>active</b> for you!");
            if ((my $expiration=effVal($oldrec,$newrec,"expiration"))){
               $msg.="\n\n";
               $msg.=$self->T("The InfoAbo has an expiration date of")." ".
                     $expiration." UTC";
            }
         }
         if (defined($oldrec) &&
             $oldrec->{active}==1 &&
             exists($newrec->{active}) &&
             $newrec->{active}==0){
            # InfoAbo wurde deaktiviert
            $msg.="\n\n" if ($msg ne "");
            $msg.=$self->T("I have deactive a InfoAbo of you.");
            $msg.="\n\n";
            $msg.="The InfoAbo"." '".
                  $mode.
                  "'".$self->T(" for ")."'".
                  $iarec->{targetname}.
                  "' ".$self->T("is now <b>inactive</b> for you!");
         }
         if (defined($oldrec) &&
             $oldrec->{active}==0 &&
             exists($newrec->{active}) &&
             $newrec->{active}==1){
            # InfoAbo wurde aktiviert
            $msg.="\n\n" if ($msg ne "");
            $msg.=$self->T("I have activate a InfoAbo of you.");
            $msg.="\n";
            $msg.=$self->T("The InfoAbo")." '".
                  $mode.
                  "'".$self->T(" for ")."'".
                  $iarec->{targetname}.
                  "' ".$self->T("is now <b>active</b> for you!");
            if ((my $expiration=effVal($oldrec,$newrec,"expiration"))){
               $msg.="\n\n";
               $msg.=$self->T("The InfoAbo has an expiration date of")." ".
                     $expiration." UTC";
            }
         }
         if ($msg eq "" &&
             defined($oldrec) &&
             exists($newrec->{expiration}) &&
             $newrec->{expiration} ne $oldrec->{expiration} &&
             $newrec->{expiration} ne ""){
            # InfoAbo Verfallsdatum wurde eingetragen
            $msg.="\n\n" if ($msg ne "");
            my $expiration=effVal($oldrec,$newrec,"expiration");
            $msg.=$self->T("I have assign a new expiration date ".
                           "to your InfoAbo.");
            $msg.="\n\n";
            $msg.=$self->T("The InfoAbo")." '".
                  $mode.
                  "'".$self->T(" for ")."'".
                  $iarec->{targetname}.
                  "' ".$self->T("expires at")." ".$expiration." UTC !";
         }
         $msg="unknown change of InfoAbo" if ($msg eq "");
         if ($ENV{SCRIPT_URI} ne ""){
            $msg.="\n\nDirectLink:\n";
            my $baseurl=$ENV{SCRIPT_URI};
            $baseurl=~s/\/(auth|public)\/.*$//;
            my $url=$baseurl;
            $url.="/public/base/infoabo/ById/".effVal($oldrec,$newrec,"id");
            $msg.=$url;
            $msg.="\n\n";
         }
         my $wfa=getModuleObject($self->Config,"base::workflowaction");
         $wfa->Notify("INFO",
                      $self->T("change of your infoabo set"),
                      ,$msg,
                      emailfrom=>$userid,
                      emailto=>$requserid,
                      emailbcc=>$userid);
      }
   }
   return($self->SUPER::FinishWrite($oldrec,$newrec));
}


sub Main
{
   my $self=shift;
   my $cleanupid=Query->Param("DIRECT_cleanupid");
   my $cleanupmode=Query->Param("DIRECT_cleanupmode");

   return($self->SUPER::Main(@_)) if ($cleanupid eq "" &&
                                      $cleanupmode eq "");

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.App.Web.css'],
                           submodal=>1,
                           body=>1,form=>1,
                           title=>$self->T($self->Self,$self->Self));
   print ("<style>body{overflow:hidden}</style>");
   print <<EOF;
<script language=JavaScript src="../../../public/base/load/toolbox.js">
</script>
<script language=JavaScript src="../../../public/base/load/kernel.App.Web.js">
</script>
EOF
   print("<table style=\"border-collapse:collapse;width:100%;height:100%\" ".
         "border=0 cellspacing=0 cellpadding=0>");
   printf("<tr><td height=1%% style=\"padding:1px\" ".
          "valign=top>%s</td></tr>",$self->getAppTitleBar());
   my $d;
   my $userid=$self->getCurrentUserId();
   $cleanupid=~s/[:;,]/ /g;
   $self->ResetFilter();
   my $flt={userid=>\$userid};
   if ($cleanupid ne ""){
      $flt->{id}=$cleanupid;
   }
   if ($cleanupmode ne ""){
      $flt->{mode}=$cleanupmode;
   }
   if ($self->IsMemberOf("admin")){
      delete($flt->{userid});
   }
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(ALL));
   if ($#l==-1){
      $d="<br><br><center><b>requested InfoAbos not found</b></center>";
   }
   else{
      if (Query->Param("yes") eq "" && Query->Param("no") eq ""){
         $d.="<center><br><br><table border=1 width=500>";
         $d.="<tr><td><b>InfoAbo</b></td></tr>";
         foreach my $rec (@l){
            my $mode=$rec->{targetname};
            $d.="<tr><td>$mode</td></tr>";
         }
         $d.="</table>";
         $d.="<br>";
         $d.=$self->T("Are you sure, ".
                      "you want to inactivate the shown InfoAbos?");
         $d.="<input type=submit name=yes style=\"width:80px\" ".
             "value=\" ".$self->T("yes")." \">";
         $d.="<input type=submit name=no style=\"width:80px\" ".
             "value=\" ".$self->T("no")." \">";
         $d.="</center>";
         $d.="<input type=hidden name=DIRECT_cleanupmode ".
             "value=\"$cleanupmode\">";
         $d.="<input type=hidden name=DIRECT_cleanupid ".
             "value=\"$cleanupid\">";
      }
      else{
         if (Query->Param("yes") ne ""){
            foreach my $rec (@l){
               $self->ValidatedUpdateRecord($rec,{active=>0},{id=>\$rec->{id}});
            }
            $d="<br><br><center>".
               $self->T("InfoAbo has been inactivated as requested").
               "</center>";
         }
         else{
            $d="<br><br><center>".$self->T("OK - no changes has been done").
               "</center>";
         }
      }
   }

   printf("<tr><td valign=top>%s</td></tr>",$d);
   printf("</table>");
   print $self->HtmlBottom(body=>1,form=>1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","newin") if (!defined($rec));
   if ($ENV{REMOTE_USER} eq "anonymous"){
      return("header","default");
   }
   return("header","default","relation","history","comments","source","qc");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (!defined($rec)){
      return("default","relation","newin");
   }
   return(undef) if ($self->isForced($rec));
   my $userid=$rec->{userid};
   return("default","newin") if (ref($rec) eq "HASH" &&
                                 $self->getCurrentUserId() eq $userid);
   if ($self->isInfoAboAdmin() || $self->IsMemberOf("admin")){
      return("default","comments");
   }

   my %a=$self->getGroupsOf($self->getCurrentUserId(),
                            [qw(RContactAdmin)],'direct');
   my @idl=keys(%a);
   if (in_array([keys(%a)],$rec->{managedbyid})){
      return("default","comments");
   }

   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (ref($rec) eq "HASH" &&
                 $self->getCurrentUserId() eq $rec->{userid});
   return(1) if ($self->IsMemberOf("admin"));
   return(undef);
}


sub LoadTargets
{
   my $self=shift;
   my $desthash=shift;
   my $parent=shift;
   my $mode=shift;
   my $refid=shift;
   my $userlist=shift;
   my %param=@_;

   my $load=$param{load};   # load userid or email address
   $load="email" if ($load eq "" || !($load ne "email" || $load eq "userid"));

   my $ml=$self->getAboTemplateRecordsFor($parent); 
   my $c=0;
   if (!defined($userlist)){
      $self->ResetFilter();
      $self->SetFilter({refid=>$refid,rawmode=>$mode,
                        usercistatusid=>"<=5",
                        parent=>$parent,
                        active=>\'1'});
      foreach my $rec ($self->getHashList(qw(userid email))){
         next if ($rec->{email} eq ""); # ensure entries are filtered, if the
                                        # contact entry has been deleted
         if (!defined($desthash->{lc($rec->{$load})})){
            $desthash->{lc($rec->{$load})}=[];
         }
         if (defined($desthash->{lc($rec->{$load})}) &&
             ref($desthash->{lc($rec->{$load})}) ne "ARRAY"){
            $desthash->{lc($rec->{$load})}=[];
         }
         if (!defined($desthash->{lc($rec->{$load})}) ||
              ref($desthash->{lc($rec->{$load})}) eq "ARRAY"){
            push(@{$desthash->{lc($rec->{$load})}},$rec->{id});
         }
         $c++;
      }
   }
   else{
      $mode=\$mode if (!ref($mode));
      $userlist=[$userlist] if (!ref($userlist) eq "ARRAY");
      $param{default}=0 if (!exists($param{default}));

      $self->ResetFilter();
      $self->SetFilter({refid=>$refid,mode=>$mode,
                        parent=>$parent,userid=>$userlist});
      foreach my $rec ($self->getHashList(qw(userid email id 
                                             usercistatusid
                                             active))){
         @{$userlist}=grep(!/^$rec->{userid}$/,@{$userlist}); 
         next if ($rec->{usercistatusid} eq ""); # ensure entries 
                                        # are filtered, if the
                                        # contact entry has NOT been deleted
         if ($rec->{email} ne ""){
            my $requested=$rec->{active};
            if (defined($ml) && exists($ml->{mode}->{$$mode}) &&
                $ml->{mode}->{$$mode}->{parentobj} eq "base::staticinfoabo" &&
                $ml->{mode}->{$$mode}->{force} ne ""){
               $requested=$ml->{mode}->{$$mode}->{force};
            }
            if ($requested && $rec->{usercistatusid}<=5){
               if (!defined($desthash->{lc($rec->{$load})})){
                  $desthash->{lc($rec->{$load})}=[];
               }
               push(@{$desthash->{lc($rec->{$load})}},$rec->{id});
               $c++;
            }
         }
      }
      my %u=();   # store default mode, if not forced
      map({$u{$_}=1;} @$userlist);
      @$userlist=keys(%u);
      if (defined($ml) && exists($ml->{mode}->{$$mode}) &&
          (($ml->{mode}->{$$mode}->{parentobj} eq "base::staticinfoabo" &&
            $ml->{mode}->{$$mode}->{force} eq "1"))){ 
          my $usr=getModuleObject($self->Config,"base::user");
          $usr->SetFilter({userid=>$userlist,cistatusid=>4});
          foreach my $urec ($usr->getHashList(qw(userid email))){
             if (!defined($desthash->{lc($urec->{$load})})){
                $desthash->{lc($urec->{$load})}=[];
             }
             push(@{$desthash->{lc($urec->{$load})}},$urec->{userid});
          }
      }
      if (defined($ml) && exists($ml->{mode}->{$$mode}) &&
          (($ml->{mode}->{$$mode}->{parentobj} eq "base::staticinfoabo" &&
            $ml->{mode}->{$$mode}->{force} eq "") ||
           $ml->{mode}->{$$mode}->{parentobj} ne "base::staticinfoabo")){
         if ($#{$userlist}!=-1){
            #if (!$parent=~m/^\*/){
               foreach my $userid (@$userlist){
                  # insert operation
                  my $sparent=$parent;
                  my $srefid=$refid;
                  my $smode=$mode;
                  $sparent=$$parent if (ref($parent) eq "SCALAR");
                  $srefid=$$refid if (ref($refid) eq "SCALAR");
                  $smode=$$mode if (ref($mode) eq "SCALAR");
                  if ($userid>0){
                     my $rec={userid=>$userid,active=>$param{default},
                              parent=>$sparent,mode=>$smode,refid=>$srefid};
                     $self->InsertRecord($rec);
                  }
                  else{
                     msg(ERROR,"try to insert infoabo for invalid '$userid'");
                  }
               }
            #}
            $self->ResetFilter();
            $self->SetFilter({refid=>$refid,mode=>$mode,active=>\'1',
                              parent=>$parent,userid=>$userlist});
            foreach my $rec ($self->getHashList(qw(userid email))){
               if (!defined($desthash->{lc($rec->{$load})})){
                  $desthash->{lc($rec->{$load})}=[];
               }
               push(@{$desthash->{lc($rec->{$load})}},$rec->{id});
            }
         }
      }
   }
   return($c);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/infoabo.jpg?".$cgi->query_string());
}

sub isAboActiv
{
   my $cur=shift;
   my $parentobj=shift;
   my $mode=shift;
   my $id=shift;
   foreach my $rec (@$cur){
      if ($rec->{parentobj} eq $parentobj &&
          $rec->{mode} eq $mode && $rec->{refid} eq $id){
         return($rec->{active});
      }
   }
   return(undef);
}


sub WinHandleInfoAboSubscribe
{
   my $self=shift;
   my $param=shift;
   my @oplist=@_;
   my $parentid=shift;
   my $userid=$self->getCurrentUserId();
   my $d=$self->HttpHeader("text/html");
   $d.=$self->HtmlHeader(style=>'default.css',
                         form=>1,body=>1,
                         title=>$self->T("Subscribe managment"));

   my $oldval=Query->Param("infoabo");
   my ($curobj,$curmode,$curid)=split(/;/,$oldval);
   my $ml;
   if (defined($curobj) && defined($curmode) && defined($curid) &&
       $curobj ne "" && $curmode ne "" && $curid ne ""){
      $ml=$self->getAboTemplateRecordsFor($curobj); 
      if (exists($ml->{mode}->{$curmode})){ # check if change is valid
         my $desiredOP;
         $desiredOP="ADD" if (Query->Param("ADD"));
         $desiredOP="DEL" if (Query->Param("DEL"));
         if ($ml->{mode}->{$curmode}->{force} eq "1" &&
             defined($desiredOP)){
            $desiredOP="ADD";
         }
         $self->ResetFilter();
         $self->SetFilter({refid=>\$curid,parentobj=>\$curobj,
                           mode=>\$curmode,userid=>\$userid});
         my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
         if ($desiredOP eq "ADD"){
            if (defined($rec)){
               $self->ValidatedUpdateRecord($rec,{active=>1},{id=>\$rec->{id}});
            }
            else{
               $self->ValidatedInsertRecord({refid=>$curid,parentobj=>$curobj,
                                             active=>1,
                                             mode=>$curmode,userid=>$userid});
            }
         }
         elsif ($desiredOP eq "DEL"){
            if (defined($rec)){
               $self->ValidatedUpdateRecord($rec,{active=>0},{id=>\$rec->{id}});
            }
         }
      }
   }


   my @flt;
   my @fltoplist=@oplist;
   while(defined(my $obj=shift(@fltoplist))){
      my $id=shift(@fltoplist);
      my $label=shift(@fltoplist);
      my $localflt={parentobj=>\$obj,userid=>\$userid};
      if (defined($id) && $id ne ""){
         $localflt->{refid}=\$id;
      }
      push(@flt,$localflt);
   }
   $self->ResetFilter();
   $self->SetFilter(\@flt);
   my @cur=$self->getHashList(qw(parentobj refid active mode));

   my $statusmsg="";
   my $statusbtn;
   if ($oldval ne ""){
      $statusmsg="<b>".$self->T("Current State").":</b> ";
      my $st=isAboActiv(\@cur,$curobj,$curmode,$curid);
      if ((!defined($st)) && $curobj eq "base::staticinfoabo"){

         $statusmsg.=$self->T("default handling");
         $statusbtn="<input style=\"width:100px;margin-right:210px\" ".
                    "type=submit name=ADD value=\" ".
                    $self->T("subscribe")." \">";
      }elsif ($st eq "1"){
         $statusmsg.=$self->T("subscribed");
         $statusbtn="<input style=\"width:100px;margin-right:210px\" ".
                    "type=submit name=DEL value=\" ".
                    $self->T("unsubscribe")." \">";
      }
      else{
         $statusmsg.=$self->T("not subscribed");
         $statusbtn="<input style=\"width:100px;margin-right:210px\" ".
                    "type=submit name=ADD value=\" ".
                    $self->T("subscribe")." \">";
      }
      if ($curobj eq "base::staticinfoabo" && defined($ml) &&
          exists($ml->{mode}->{$curmode}) &&
          $ml->{mode}->{$curmode}->{force} ne ""){
         $statusbtn="";
         $statusmsg="<b>".$self->T("Current State").":</b> ";
         if ($ml->{mode}->{$curmode}->{force} eq "1"){
            $statusmsg.=$self->T("forced")." ".$self->T("subscribed");
         }
         if ($ml->{mode}->{$curmode}->{force} eq "0"){
            $statusmsg.=$self->T("forced")." ".$self->T("unsubscribe");
         }
      }
   }
   my $optionlist="";
   while(defined(my $obj=shift(@oplist))){
      my $id=shift(@oplist);
      my $label=shift(@oplist);
      my @ml;
      my $ml=$self->getAboTemplateRecordsFor($obj); 

      my $objlabel=$self->T($obj,$obj);
      $objlabel.=": ".$label if ($label ne "");
      
      $optionlist.="<optgroup label=\"$objlabel\">";
      foreach my $mrec (@{$ml->{modes}}){
         next if ($mrec->{parentobj} ne $obj);
         my $mode=$mrec->{name};
         my $modelabel=$mrec->{fullname};
         my $opobj=$mrec->{parentobj};

         my $key="$opobj;$mode";
         if ($opobj eq "base::staticinfoabo"){
            $key.=";".$mrec->{id};
         }
         else{
            $key.=";$id" if (defined($id) && $id ne "");
         }
         my ($akobj,$akmode,$akid)=split(/;/,$key);
         my $st=isAboActiv(\@cur,$akobj,$akmode,$akid);
         if ($akobj eq "base::staticinfoabo" &&
             exists($ml->{mode}->{$mode}) && 
             $ml->{mode}->{$mode}->{force} ne ""){
            $st=$ml->{mode}->{$mode}->{force};
         }
         $st="?"      if ((!defined($st)) && $akobj eq "base::staticinfoabo");
         $st="-"      if (!defined($st));
         $st="*"      if ($st eq "1");
         $st="-"      if ($st eq "0");
         $optionlist.="<option value=\"$key\"";
         $optionlist.=" selected" if ($oldval eq $key);
         $optionlist.=">$st $modelabel</option>";
      }
      $optionlist.="</optgroup>";
   }
   my $handlermask=$self->getParsedTemplate("tmpl/base.infoabohandler",{});
   my $CurrentIdToEdit=Query->Param("CurrentIdToEdit");
   $d.=<<EOF;
<style>body{overflow:hidden;padding:4px}optgroup{margin-bottom:5px}</style>
<table width=580 height=98% border=0>
<tr height=60><td>$handlermask</td></tr>
<tr>
<td>
<div style="height:100%;margin:0">
<select size=5 name=infoabo onchange="document.forms[0].submit();" 
        style="width:570px;height:100%;overflow:auto">
$optionlist</select>
</div>
</td>
<tr height=1%>
<td>
<table cellspacing=0 cellpadding=0 width=580>
<tr><td>$statusmsg</td><td align=right>$statusbtn</td></tr>
</table>
</td>

</tr>
<tr height=1%>
<td align=right>
<input onclick="parent.hidePopWin();" type=submit 
       style="width:50px;margin-right:10px" value="OK">
<input type=hidden name=CurrentIdToEdit value="$CurrentIdToEdit">
</tr>
</table>
EOF

   $d.=$self->HtmlBottom(body=>1,form=>1);
   return($d);
}


sub Welcome
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css'],
                           body=>1,form=>1);
   print $self->getParsedTemplate("tmpl/welcome.infoabo",{});
   print $self->HtmlBottom(body=>1,form=>1);
   return(1);
}  


sub isInfoAboAdmin
{
   my $self=shift;
   my $mode=shift;

   $mode="write" if (!defined($mode) || $mode eq "");
   $mode="read" if ($mode ne "write");

   if ($mode eq "read"){
      my $bk=$self->IsMemberOf($self->{admread});
      return($bk) if ($bk);
   }
   return($self->IsMemberOf($self->{admwrite}));
}

sub isContactAdmin
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my %a=$self->getGroupsOf($userid, [qw(RContactAdmin)], 'direct');
   return(1) if (keys(%a)>0);
   return(0);
}



sub expandDynamicDistibutionList
{
   my $self=shift;
   my $dlname=shift;
   my %email;

   $self->LoadSubObjs("ext/distlist","distlist");

   my $user=getModuleObject($self->Config,"base::user");

   foreach my $obj (values(%{$self->{distlist}})){
      my ($to,$cc,$bcc)=$obj->expandDynamicDistibutionList($self,$dlname);
      foreach my $e (@$to){ $email{'to'}->{$e}++};
      foreach my $e (@$cc){ $email{'cc'}->{$e}++};
      foreach my $e (@$bcc){ $email{'bcc'}->{$e}++};
      foreach my $et (keys(%email)){
         my @userid;
         foreach my $email (keys(%{$email{$et}})){
            if ($email=~m/^\d+$/){
               push(@userid,$email);
               delete($email{$et}->{$email});
            }
         }
     #    if ($#userid!=-1){
     #       $user->ResetFilter();
     #       $user->SetFilter({cistatuid=>\'4',userid=>\@userid});
       #     map({$email{$et}->{$_->{email}}++} $user->getHashList("email"));
     #    }
         
         msg(INFO,"process email type $et");

      }
   }
   return([sort(keys(%{$email{'to'}}))],
          [sort(keys(%{$email{'cc'}}))],
          [sort(keys(%{$email{'bcc'}}))]);
}

#sub isUploadValid  # validates if upload functionality is allowed
#{
#   my $self=shift;
#   return(0) if (!$self->IsMemberOf("admin"));
#   return(1);
#}











1;
