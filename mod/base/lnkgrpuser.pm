package base::lnkgrpuser;
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
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->{userview}=getModuleObject($self->Config,"base::userview");
   $self->{lnkgrpuserrole}=getModuleObject($self->Config,
                           "base::lnkgrpuserrole");
   my $role=$self->{lnkgrpuserrole}->getField("role");


   my $roles=new kernel::Field::Select(name       =>'roles',
                                       label      =>'Roles',
                                       translation=>$role->{translation},
                                       value      =>$role->{value});
   {
      $roles->{userrole}=$self->{lnkgrpuserrole};
      $roles->{multisize}=7;
      $roles->{searchable}=0;
      $roles->{uploadable}=1;
      $roles->{onRawValue}=
         sub {
            my $self=shift;
            my $current=shift;
            my $idname=$self->getParent->IdField->Name();
            #printf STDERR ("fifi onRawValue:%s\n",$self->Name());
            #printf STDERR ("fifi onRawValue:id=%s\n",$current->{$idname});
            if (defined($current)){
               $self->{userrole}->SetFilter({$idname=>\$current->{$idname}});
               my @l=$self->{userrole}->getHashList(qw(role));
              
               #printf STDERR ("fifi onRawValue:dump=%s\n",Dumper(\@l));
               my @l=map({$_->{role}} @l);
               return(\@l);
            }
            return([]);
         };
      $roles->{onFinishWrite}=
         sub {
            my $self=shift;
            my $oldrec=shift;
            my $newrec=shift;
            my $myname=$self->Name();
            return(undef) if (!defined($newrec) || !exists($newrec->{$myname}));
            my ($oldval,$newval);
            $oldval=$oldrec->{$myname} if (defined($oldrec) && 
                                           exists($oldrec->{$myname}));
            $newval=$newrec->{$myname} if (defined($newrec) && 
                                           exists($newrec->{$myname}));
            my @addlist=();
            my @dellist=();
            my $idname=$self->getParent->IdField->Name();
            my $relationrec=$oldrec;
            $relationrec=$newrec if (!defined($oldrec));
            $newval=[$newval] if (ref($newval) ne "ARRAY");
            
            foreach my $new (@{$newval}){
               push(@addlist,$new) if (!in_array($oldval,$new));
            }
            foreach my $old (@{$oldval}){
               push(@dellist,$old) if (!in_array($newval,$old));
            }
            my $grpid=effVal($oldrec,$newrec,"grpid");
            if ($grpid eq ""){
               $self->getParent->LastMsg(ERROR,"internal error");
               return(undef);
            }
            if ($self->getParent->isDataInputFromUserFrontend()){
               if (!$self->getParent->IsMemberOf("admin")){
                  my @allowed=(qw(RReportReceive RTimeManager RMember));
                  push(@allowed,orgRoles());
                  my $removed=0;
                  foreach my $modlist ((\@addlist,\@dellist)){
                     my @rolechk=@$modlist;
                     foreach my $rolechk (@rolechk){
                        if (!in_array(\@allowed,$rolechk)){
                           @$modlist=grep(!/^$rolechk$/,@$modlist);
                           $removed++;
                        }
                     } 
                  }

                  if ($removed){
                     $self->getParent->LastMsg(WARN,"some role changes are ".
                                       "not done - you are only Org-Admin");
                  }
               }
            }

            foreach my $add (@addlist){
               my $newrec={$idname=>\$relationrec->{$idname},
                           role=>$add};
               $self->{userrole}->ValidatedInsertRecord($newrec);
            }
            foreach my $del (@dellist){
               $self->{userrole}->SetFilter(
                                {$idname=>\$relationrec->{$idname},
                                 role=>$del});
               $self->{userrole}->SetCurrentView(qw(ALL));
               $self->{userrole}->ForeachFilteredRecord(sub{
                               $self->{userrole}->ValidatedDeleteRecord($_);
                               });
            }
            #printf STDERR ("fifi onFinishWrite in %s\n",$self->Name());
            #printf STDERR ("fifi onFinishWrite d=%s\n",Dumper($newrec));
            #printf STDERR ("fifi oldval=%s\n",join(",",@{$oldval}));
            #printf STDERR ("fifi newval=%s\n",join(",",@{$newval}));
            #printf STDERR ("fifi addlist=%s\n",join(",",@addlist));
            #printf STDERR ("fifi dellist=%s\n",join(",",@dellist));
            if ($self->getParent->isDataInputFromUserFrontend()){
               if (!$self->getParent->IsMemberOf("admin")){
                  
               }
            }
            return(undef);
         };
   }

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'lnkgrpuserid',
                label         =>'LinkID',
                size          =>'10',
                dataobjattr   =>'lnkgrpuser.lnkgrpuserid'),

      new kernel::Field::Link(
                name          =>'fullname',
                label         =>'fullname',
                onRawValue    =>sub{
                    my $self=shift;
                    my $current=shift;
                    my $fullname=$current->{lnkgrpuserid};

                    my ($f,$v);
                    $f=$self->getParent->getField("user");
                    $v=defined($f) ? $f->RawValue($current) : "?";
                    $fullname.=":".$v;
                   
                    $f=$self->getParent->getField("group");
                    $v=defined($f) ? $f->RawValue($current) : "?";
                    $fullname.=":".$v;
                   
                    $f=$self->getParent->getField("roles");
                    $v=defined($f) ? $f->RawValue($current) : "?";
                    $v=ref($v) eq "ARRAY" ? join(", ",@$v):$v;
                    $fullname.=":".$v;

                    return($fullname);
                }),

      new kernel::Field::TextDrop(
                name          =>'user',
                htmlwidth     =>'380px',
                label         =>'User',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'contact.fullname'),

      new kernel::Field::TextDrop(
                name          =>'email',
                readonly      =>1,
                htmlwidth     =>'380px',
                label         =>'E-Mail',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'email',
                dataobjattr   =>'contact.email'),

      new kernel::Field::TextDrop(
                name          =>'usertyp',
                readonly      =>1,
                label         =>'Usertyp',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'usertyp',
                dataobjattr   =>'contact.usertyp'),

      new kernel::Field::TextDrop(
                name          =>'posix',
                readonly      =>1,
                label         =>'POSIX-Identifier',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'posix'),

      new kernel::Field::TextDrop(
                name          =>'office_phone',
                readonly      =>1,
                htmldetail    =>'0',
                searchable    =>'0',
                label         =>'Office Phone',
                vjointo       =>'base::user',
                vjoinon       =>['userid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::TextDrop(
                name          =>'group',
                htmlwidth     =>'280px',
                label         =>'Group',
                vjointo       =>'base::grp',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkgrpuser.expiration'),

      new kernel::Field::Select(
                name          =>'alertstate',
                value         =>['','yellow','orange',
                                 'red'],
                uivisible     =>sub{
                    my $self=shift;
                    my $mode=shift;
                    my $app=$self->getParent;
                    my %param=@_;
                    return(1) if (!defined($param{current}));
                    return(1) if (
                       $param{current}->{alertstate} ne "");
                    return(0);
                },
                readonly      =>1,
                label         =>'Alert-State',
                dataobjattr   =>'lnkgrpuser.alertstate'),

      $roles,

      new kernel::Field::SubList(
                name          =>'lineroles',
                label         =>'LineRoles',
                htmldetail    =>'0',
                readonly      =>'1',
                searchable    =>'0',  # because low cardinality
                vjointo       =>'base::lnkgrpuserrole',
                vjoinon       =>['lnkgrpuserid'=>'lnkgrpuserid'],
                vjoindisp     =>['role'],
                vjoininhash   =>['role']),

      new kernel::Field::SubList(
                name          =>'nativroles',
                label         =>'native roles',
                htmldetail    =>'0',
                readonly      =>'1',
                searchable    =>'0',  # because low cardinality
                vjointo       =>'base::lnkgrpuserrole',
                vjoinon       =>['lnkgrpuserid'=>'lnkgrpuserid'],
                vjoindisp     =>['nativrole'],
                vjoininhash   =>['nativrole']),

      new kernel::Field::Link(
                name          =>'rawnativroles',  # search on roles only in
                noselect      =>'1',              # this field !!!
                dataobjattr   =>'lnkgrpuserrole.nativrole'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkgrpuser.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkgrpuser.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkgrpuser.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkgrpuser.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkgrpuser.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkgrpuser.lnkgrpuserid,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkgrpuser.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkgrpuser.modifydate'),

      new kernel::Field::Editor(
                name          =>'editor',
                label         =>'Editor Account',
                dataobjattr   =>'lnkgrpuser.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkgrpuser.realeditor'),

      new kernel::Field::Text(
                name          =>'grpid',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'GrpID',
                dataobjattr   =>'lnkgrpuser.grpid'),

      new kernel::Field::Select(
                name          =>'grpcistatus',
                label         =>'Group CI-State',
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['grpcistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Date(
                name          =>'grpmdate',
                label         =>'Group Modification-Date',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'grp.modifydate'),

      new kernel::Field::Interface(
                name          =>'grpcistatusid',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Grp CI-Statusid',
                dataobjattr   =>'grp.cistatus'),

      new kernel::Field::Interface(
                name          =>'is_projectgrp',
                label         =>'Group is Projectgroup',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'grp.is_projectgrp'),

      new kernel::Field::Interface(             
                name          =>'is_orggrp',     
                label         =>'Group is organisational Group', 
                readonly      =>1,
                dataobjattr   =>'if (grp.is_org=1 or '.
                                    'grp.is_line=1 or '.
                                    'grp.is_depart=1 or '.
                                    'grp.is_resort=1 or '.
                                    'grp.is_team=1 or '.
                                    'grp.is_orggroup=1'.
                                    ',1,0)'),
      new kernel::Field::Text(
                name          =>'userid',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'UserID',
                dataobjattr   =>'lnkgrpuser.userid'),

      new kernel::Field::Select(
                name          =>'usercistatus',
                label         =>'Contact CI-State',
                htmldetail    =>0,
                readonly      =>1,
                vjointo       =>'base::cistatus',
                vjoinon       =>['usercistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Date(
                name          =>'usermdate',
                label         =>'Contact Modification-Date',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'contact.modifydate'),

      new kernel::Field::Interface(
                name          =>'usercistatusid',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Contact CI-Statusid',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Date(
                name          =>'lastorgchangedt',
                readonly      =>1,
                htmldetail    =>'0',
                label         =>'last organisational change',
                dataobjattr   =>'contact.lorgchangedt'),

      new kernel::Field::DynWebIcon(
                name          =>'userweblink',
                searchable    =>0,
                depend        =>['userid','alertstate','expiration'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $userido=$self->getParent->getField("userid");
                   my $userid=$userido->RawValue($current);
                   my $expirationo=$self->getParent->getField("expiration");
                   my $expiration=$expirationo->FormatedDetail($current,
                                                               "HtmlDetail");

                   my $msg;
                   my $img="<img ";
                   if ($current->{alertstate} ne ""){
                      $img.="style=\"border-width:1px;border-color:".
                            "$current->{alertstate};border-style:solid; ".
                            "background:$current->{alertstate}\" "; 
                      $msg=$self->getParent->T("entry expires at")." ".
                           $expiration;
                   }
                   else{
                      $img.="border=0 ";
                   }
                   $msg=~s/<.*?>//g;
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   if ($msg ne ""){
                      $img.=" title=\"$msg\"";
                   }
                   $img.=" border=0>";
               
                   my $dest="../../base/user/Detail?userid=$userid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      my $d="<a";
                      if ($msg ne ""){
                         $d.=" title=\"$msg\"";
                      }
                      $d.=" href=javascript:$onclick";
                      $d.=">$img</a>";
 
                      return($d);
                   }
                   return("-");
                }),

      new kernel::Field::DynWebIcon(
                name          =>'grpweblink',
                searchable    =>0,
                depend        =>['grpid','alertstate','expiration'],
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $grpido=$self->getParent->getField("grpid");
                   my $grpid=$grpido->RawValue($current);
                   my $expirationo=$self->getParent->getField("expiration");
                   my $expiration=$expirationo->FormatedDetail($current,
                                                               "HtmlDetail");


                   my $msg;
                   my $img="<img ";
                   if ($current->{alertstate} ne ""){
                      $img.="style=\"border-width:1px;border-color:".
                            "$current->{alertstate};border-style:solid; ".
                            "background:$current->{alertstate}\" "; 
                      $msg=$self->getParent->T("entry expires at")." ".
                           $expiration;
                   }
                   else{
                      $img.="border=0 ";
                   }
                   $msg=~s/<.*?>//g;
                   $img.="src=\"../../base/load/directlink.gif\" ";
                   if ($msg ne ""){
                      $img.=" title=\"$msg\"";
                   }
                   $img.=">";
                   my $dest="../../base/grp/Detail?grpid=$grpid";
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      my $d="<a";
                      if ($msg ne ""){
                         $d.=" title=\"$msg\"";
                      }
                      $d.=" href=javascript:$onclick";
                      $d.=">$img</a>";
 
                      return($d);
                   }
                   return("-");
                }),

   );
   $self->setDefaultView(qw(lnkgrpuserid user group editor));
   $self->setWorktable("lnkgrpuser");
   $self->{history}={
      insert=>[
         {dataobj=>'base::grp', id=>'grpid',
          field=>'fullname',as=>'users'}
      ],
      update=>['local'],
      delete=>[
         {dataobj=>'base::grp', id=>'grpid',
          field=>'fullname',as=>'users'}
      ]
   };

   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join lnkgrpuserrole ".
            "on $worktable.lnkgrpuserid=lnkgrpuserrole.lnkgrpuserid ".
            "left outer join contact on $worktable.userid=contact.userid ".
            "left outer join grp on $worktable.grpid=grp.grpid";

   return($from);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if (!defined($oldrec) || effChanged($oldrec,$newrec,"userid")){
      my $userid=effVal($oldrec,$newrec,"userid");
      my $o=getModuleObject($self->Config,"base::user");
      $o->SetFilter({userid=>\$userid});
      my ($rec,$msg)=$o->getOnlyFirst("userid","usertyp");
      if (!defined($rec)){
         $self->LastMsg(ERROR,"userid invalid");
         return(undef);
      }
      if (defined($rec) && $rec->{usertyp} eq "genericAPI"){
         $self->LastMsg(ERROR,"genericAPI contacts are not allowed ".
                              "to assign to groups");
         return(undef);
      }
   }


   if (effVal($oldrec,$newrec,"grpid")==0){
      $self->LastMsg(ERROR,"invalid group specified");
      return(undef);
   }
   if (effVal($oldrec,$newrec,"userid")==0){
      $self->LastMsg(ERROR,"invalid user specified");
      return(undef);
   }
   if ((my $expiration=effVal($oldrec,$newrec,"expiration")) eq ""){
      if (effVal($oldrec,$newrec,"alertstate") ne "" &&
          !exists($newrec->{alertstate})){
        $newrec->{alertstate}=undef;
      }
   }
   else{
      if (exists($newrec->{expiration}) &&
          $newrec->{expiration} ne $oldrec->{expiration}){
         my $nowstamp=NowStamp("en");
         my $duration=CalcDateDuration($nowstamp,$expiration);
         if (defined($duration)){
            if ($duration->{days}<-14){
               $self->LastMsg(ERROR,"expiration to long in the past");
               return(undef);  
            }
            else{
               $newrec->{alertstate}=undef;
            }
         }
      }
   }
   

   my $grpid=effVal($oldrec,$newrec,"grpid");
   return(1) if (!$self->isDataInputFromUserFrontend());
   return(1) if ($self->IsMemberOf("admin")); 
   my $destuserid=effVal($oldrec,$newrec,"userid");
   my $userid=$self->getCurrentUserId();
   if ($userid==$destuserid && !$self->IsMemberOf("admin")){
      $self->LastMsg(ERROR,"you are not authorized to modify your own account");
      return(0);
   }
   if (!$self->IsMemberOf([$grpid],"RAdmin","down")){
      $self->LastMsg(ERROR,"you are not authorized to admin this group");
      return(0);
   }
   if (exists($newrec->{roles})){
      my $roles=$newrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      my $grpid=effVal($oldrec,$newrec,"grpid");
      my $grp=getModuleObject($self->Config,"base::grp");
      $grp->SetFilter({grpid=>\$grpid});
      my ($grec,$msg)=$grp->getOnlyFirst(qw(ALL));
      if (grep(/^(RBoss|RBoss2|REmployee|RApprentice|RFreelancer|RBackoffice)$/,
               @$roles)){
         if (!$grec->{is_orggrp} && !$grec->{is_projectgrp} ){
            $self->LastMsg(ERROR,"role relation with your ".
                                 "security state not allowed");
            return(0);
         }
         if (!grep(/^RMember$/,@$roles)){
            $self->LastMsg(ERROR,"incorrect role combination");
            return(0);
         }
      }
      else{
         if (grep(/^(RMember)$/,@$roles)){
            if ($grec->{is_orggrp} || $grec->{is_projectgrp}){
               $self->LastMsg(ERROR,"incorrect role combination");
               return(0);
            }
         }
      }

   }
   my $roles=effVal($oldrec,$newrec,"roles");
   if ($#{$roles}==-1){
      $self->LastMsg(ERROR,"incorrect role combination");
      return(0);
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec)){
      my $grpid=$rec->{grpid};
      return(undef) if (!$self->IsMemberOf("admin") &&
                        !$self->IsMemberOf([$grpid],"RAdmin","down"));
      my $destuserid=$rec->{userid};
      my $userid=$self->getCurrentUserId();
      return(undef) if ($userid==$destuserid &&
                        !$self->IsMemberOf("admin"));
   }
   return("default");
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateUserCache();
   my $grpid=effVal($oldrec,$newrec,"grpid");
   if ((exists($newrec->{roles}) || exists($oldrec->{roles})) && $grpid ne ""){
      $self->StoreLastKnownBoss($oldrec,$newrec,$grpid);
   }
   return($bak);
}

sub StoreLastKnownBoss  # the storeing of last known Boss-Email is needed,
{                       # to informate the boss, if any time the group
   my $self=shift;      # is set to disposed of wast. In this cast the last
   my $oldrec=shift;    # boss has to bee ensure, that all old references
   my $newrec=shift;    # would be corrected to the posible new group
   my $grpid=shift;

   if (!defined($newrec) ||
       grep(/^(RBoss|RBoss2)$/,@{$oldrec->{roles}},@{$newrec->{roles}})){
      my $lnk=getModuleObject($self->Config,$self->Self);
      $lnk->ResetFilter();
      $lnk->SetFilter({grpid=>\$grpid,rawnativroles=>["RBoss","RBoss2"]});
      my @l=$lnk->getHashList("email");
      if ($#l!=-1){
         my @email=grep(!/^\s*$/,map({$_->{email}} @l));
         if ($#email!=-1){
            my $grp=getModuleObject($self->Config,"base::grp");
            $grp->UpdateRecord({lastknownbossemail=>join("\n",@email)},
                               {grpid=>\$grpid});
         }
      }

      # boss operation

   }
}

sub FinishDelete
{  
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->InvalidateUserCache();
   {  # cleanup lnkgrpuserrole 
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $self->{lnkgrpuserrole}->SetFilter({'lnkgrpuserid'=>$id});
      $self->{lnkgrpuserrole}->SetCurrentView(qw(ALL));
      $self->{lnkgrpuserrole}->ForeachFilteredRecord(sub{
                         $self->{lnkgrpuserrole}->ValidatedDeleteRecord($_);
                      });
   }
   my $grpid=$oldrec->{grpid};
   if ($grpid ne ""){
      $self->StoreLastKnownBoss($oldrec,undef,$grpid);
   }
   return($bak);
}

sub getRecordImageUrl
{
   my $self=shift;
   return("../../../public/base/load/gnome-user-group.jpg");
}


sub RoleSyncIn
{
   my $self=shift;
   my $cur=shift;
   my $rules=shift;
   my $param=shift;


   my $oldstate=$self->isDataInputFromUserFrontend();
   $self->isDataInputFromUserFrontend(0);
   my %insrec;
   my %updrec;
   my %delrec;
   foreach my $rulerole (keys(%{$rules})){
      foreach my $uid (@{$rules->{$rulerole}}){
         next if (!($uid=~m/^[0-9]{2,20}$/));
         my $uidfound=0;
         foreach my $crec (@{$cur}){
            my $r=$crec->{roles};
            $r=[$r] if (ref($r) ne "ARRAY");
            $r=[@{$r}];
            if ($crec->{userid} eq $uid){
               if (in_array($r,$rulerole)){
                  $uidfound++;
               }
               else{
                  push(@$r,$rulerole);
                  $updrec{$crec->{userid}}=[$crec,{
                     userid=>$crec->{userid},
                     grpid=>$crec->{grpid},
                     roles=>$r,
                  }];
               }
            }
         }
         if (!$uidfound){
            if (exists($updrec{$uid})){
               if (!in_array($updrec{$uid}->[1]->{roles},$rulerole)){
                  push(@{$updrec{$uid}->[1]->{roles}},$rulerole);
               }
            }
            else{
               if (!exists($insrec{$uid})){
                  $insrec{$uid}={
                     userid=>$uid,
                     roles=>[$rulerole],
                  };
               }
               else{
                  push(@{$insrec{$uid}->{roles}},$rulerole);
               }
            }
         }
      }
   }
   foreach my $crec (@{$cur}){
      my $r=$crec->{roles};
      $r=[$r] if (ref($r) ne "ARRAY");
      $r=[@{$r}];
      foreach my $rulerole (keys(%{$rules})){
         if (in_array($r,$rulerole)){
            if (!in_array($rules->{$rulerole},$crec->{userid})){
               $r=[grep(!/^${rulerole}$/,@$r)];
               if ($#{$r}==-1){
                  $delrec{$crec->{userid}}=$crec;
               }
               else{
                  $updrec{$crec->{userid}}=[$crec,{
                     userid=>$crec->{userid},
                     grpid=>$crec->{grpid},
                     roles=>$r,
                  }];
               }
            }
         }
      }
   }
   foreach my $insrec (values(%insrec)){
      #printf STDERR ("DEBUG: insrec:%s\n",Dumper($insrec));
      my $doIt=1;
      if ($param->{onInsert}){
         $doIt=&{$param->{onInsert}}($self,$insrec);
      }
      if ($doIt){
         $self->ValidatedInsertRecord($insrec);
      }
   }
   foreach my $updrec (values(%updrec)){
      #printf STDERR ("DEBUG: updrec:%s\n",Dumper($updrec->[1]));
      my $doIt=1;
      if ($param->{onUpdate}){
         $doIt=&{$param->{onUpdate}}($self,$updrec->[0],$updrec->[1]);
      }
      if ($doIt){
         $self->ValidatedUpdateRecord($updrec->[0],$updrec->[1],
            {lnkgrpuserid=>$updrec->[0]->{lnkgrpuserid}});
      }
   }
   foreach my $delrec (values(%delrec)){
      #printf STDERR ("DEBUG: delrec:%s\n",Dumper($delrec));
      my $doIt=1;
      if (!exists($insrec{$delrec->{userid}})){  # do not delete, if update 
         if ($param->{onDelete}){                # needed
            $doIt=&{$param->{onDelete}}($self,$delrec);
         }
         if ($doIt){
            $self->ValidatedDeleteRecord($delrec);
         }
      }
   }
   $self->isDataInputFromUserFrontend($oldstate);
}




sub NotifyOrgAdminActionToAdmin
{
   my $self=shift;
   my $mode=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my %param=@_;

   my $idname=$self->IdField->Name();
   my $creator=effVal($oldrec,$newrec,"creator");
   my $userid=$self->getCurrentUserId();
   my $name=effVal($oldrec,$newrec,$param{uniquename});
   my $id=effVal($oldrec,$newrec,$idname);
   my $modulename=$self->T($self->Self,$self->Self);
   my $wf=getModuleObject($self->Config,"base::workflow");

   my $user=getModuleObject($self->Config,"base::user");
   return() if ($creator==0);
   $user->SetFilter({userid=>\$creator});
   my ($creatorrec,$msg)=$user->getOnlyFirst(qw(email givenname surname));
   return() if (!defined($creatorrec));
   my $fromname=$creatorrec->{surname};
   $fromname.=", " if ($creatorrec->{givenname} ne "" && $fromname ne "");
   $fromname.=$creatorrec->{givenname} if ($creatorrec->{givenname});
   $fromname=$creatorrec->{email} if ($fromname eq "");

   my $url=$ENV{SCRIPT_URI};
   $url=~s/[^\/]+$//;
   my $publicurl=$url;
   my $listurl=$url;
   my $itemname=$self->T($self->Self,$self->Self);;
   $url.="Detail?$idname=$id";
   $listurl.="Main";
   $publicurl=~s#/auth/#/public/#g;
   my $cistatuspath=$self->Self;
   $cistatuspath=~s/::/\//g;
   $cistatuspath.="/$id";
   $cistatuspath.="?HTTP_ACCEPT_LANGUAGE=".$self->Lang();

   my $wfname;
   my %notiy;
   my $msg;
   if ($mode eq "request"){
      $user->SetFilter({groups=>$param{activator}});
      my @admin=$user->getHashList(qw(email givenname surname));
      $notiy{emailto}=[map({$_->{email}} @admin)];
      $notiy{emailcc}=[$creatorrec->{email}];
      $wfname=$self->T("Request to activate '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG001");
      $msg=sprintf($msg,$fromname,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "reservation"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Reservation confirmation for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG002");
      $msg=sprintf($msg,$fromname,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "activate"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Activation notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG003");
      $msg=sprintf($msg,$name,$url,$itemname,$listurl);
   }
   if ($mode eq "drop"){
      $notiy{emailto}=[$creatorrec->{email}];
      $wfname=$self->T("Drop notification for '%s' in module '%s'");
      $wfname=sprintf($wfname,$name,$modulename);
      $msg=$self->T("MSG004");
      $msg=sprintf($msg,$name);
      return() if ($creator==$userid);
   }
   my $sitename=$self->Config->Param("SITENAME");
   my $subject=$wfname;
   if ($sitename ne ""){
      $subject=$sitename.": ".$subject;
   }

   my $imgtitle=$self->T("current state of the requested CI");


   $notiy{emailfrom}=$creatorrec->{email};
   $notiy{name}=$subject;
   if ($mode ne "drop"){
      $notiy{emailpostfix}=<<EOF;
<br>
<br>
<img title="$imgtitle" src="${publicurl}../../base/cistatus/show/$cistatuspath">
EOF
   }
   $notiy{emailtext}=$msg;
   $notiy{class}='base::workflow::mailsend';
   $notiy{step}='base::workflow::mailsend::dataload';
   if (my $id=$wf->Store(undef,\%notiy)){
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      my $r=$wf->Store($id,%d);
   }
   return(0);
}

sub getRecordHtmlIndex
{ return(); }




   


1;
