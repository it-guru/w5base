package base::lnkcontact;
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
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                dataobjattr   =>'lnkcontact.id'),
                                                 
      new kernel::Field::MultiDst (
                name          =>'targetname',
                htmlwidth     =>'200',
                htmleditwidth =>'400',
                label         =>'Target-Name',
                dst           =>['base::grp' =>'fullname',
                                 'base::user'=>'fullname'],
                vjoineditbase =>[{'cistatusid'=>[3,4]},
                                 {'cistatusid'=>[3,4,5]}
                                ],
                dsttypfield   =>'target',
                dstidfield    =>'targetid'),

      new kernel::Field::DynWebIcon(
                name          =>'targetweblink',
                searchable    =>0,
                depend        =>[qw(target targetid alertstate expiration)],
                uploadable    =>0,
                htmlwidth     =>'5px',
                htmldetail    =>0,
                weblink       =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $app=$self->getParent;

                   my $targeto=$self->getParent->getField("target");
                   my $target=$targeto->RawValue($current);

                   my $targetido=$self->getParent->getField("targetid");
                   my $targetid=$targetido->RawValue($current);

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

                   my $dest;
                   if ($target eq "base::user"){
                      $dest="../../base/user/Detail?userid=$targetid";
                   }
                   if ($target eq "base::grp"){
                      $dest="../../base/grp/Detail?grpid=$targetid";
                   }
                   my $detailx=$app->DetailX();
                   my $detaily=$app->DetailY();
                   my $onclick="openwin(\"$dest\",\"_blank\",".
                       "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                       "resizable=yes,scrollbars=no\")";

                   if ($mode=~m/html/i){
                      return("<a href=javascript:$onclick>$img</a>");
                   }
                   return("-only a web useable link-");
                }),

      new kernel::Field::Text(
                name          =>'phone',
                htmlwidth     =>'130',
                label         =>'Contact phone',
                readonly      =>1,
                depend        =>['target','targetid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $d="";
                   if ($current->{target} eq "base::user"){
                      my @t;
                      my %t;
                      my $o=getModuleObject($self->getParent->Config,
                                            $current->{target});
                      $o->SetFilter({userid=>\$current->{targetid}});
                      my @fl=qw(office_phone office_mobile privat_mobile
                                privat_phone);
                      my ($urec,$msg)=$o->getOnlyFirst(@fl);
                      if (defined($urec)){
                         foreach my $n (@fl){
                            if ($urec->{$n} ne "" && !exists($t{$urec->{$n}})){
                               $t{$urec->{$n}}++;
                               push(@t,$urec->{$n});
                            }
                         }
                         $d=join("\n",@t);
                      }
                   }
                   if ($current->{target} eq "base::grp"){
                      my @t;
                      my %t;
                      my $o=getModuleObject($self->getParent->Config,
                                            "base::phonenumber");
                      $o->SetFilter({parentobj=>\$current->{target},
                                     refid=>\$current->{targetid}});
                      foreach my $prec ($o->getHashList(qw(phonenumber))){
                         push(@t,$prec->{phonenumber});
                      }
                      $d=join("\n",@t);
                   }
                   return($d);
                }),


      new kernel::Field::Date(
                name          =>'expiration',
                htmldetail    =>'NotEmptyOrEdit',
                label         =>'Expiration-Date',
                dataobjattr   =>'lnkcontact.expiration'),

      #
      #  Achtung: Das Expiration-Handling ist NICHT sauber implementiert.
      #           Das Problem ist, das der alertstate nicht korrekt behandelt
      #           wird - und dies auch nicht so einfach machbar ist.

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
                dataobjattr   =>"if (datediff(now(),lnkcontact.expiration)>0,".
                                "'red',".
                                "if (datediff(now(),".
                                "lnkcontact.expiration)>-14,'orange',".
                                "if (datediff(now(),".
                                "lnkcontact.expiration)>-28,'yellow','')))"),

      new kernel::Field::Text(
                name          =>'comments',
                sqlorder      =>'NONE',
                htmlwidth     =>'150',
                label         =>'Comments',
                dataobjattr   =>'lnkcontact.comments'),

      new kernel::Field::Select(
                name          =>'roles',
                label         =>'Roles',
                htmleditwidth =>'100%',
                searchable    =>1,
                depend        =>['parentobj'],
                multisize     =>5,
                container     =>'croles',
                getPostibleValues=>\&getPostibleRoleValues),
                                                 
      new kernel::Field::Interface(
                name          =>'nativroles',
                label         =>'native Roles',
                readonly      =>1,
                history       =>0,
                htmldetail    =>0,
                uploadable    =>0,
                depend        =>['roles','croles'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $fld=$self->getParent->getField("roles",$current);
                   my $roles=$fld->RawValue($current);
                   $roles=[$roles] if (ref($roles) ne "ARRAY");
                   return(join(", ",@$roles));
                }),

      new kernel::Field::Link(
                name          =>'fullname',
                readonly      =>1,
                label         =>'Fullname',
                depend        =>['parentobj','refid','roles'],
                onRawValue    =>\&getFullname),
                                                 
      new kernel::Field::Text(
                name          =>'parentobj',
                frontreadonly =>1,
                sqlorder      =>'NONE',
                uploadable    =>0,
                history       =>0,
                label         =>'Parent-Object',
                dataobjattr   =>'lnkcontact.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                label         =>'RefID',
                frontreadonly =>1,
                history       =>0,
                uploadable    =>0,
                dataobjattr   =>'lnkcontact.refid'),

      new kernel::Field::Container(
                name          =>'croles',
                sqlorder      =>'NONE',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Interface(
                name          =>'target',
                label         =>'Target-Typ',
                dataobjattr   =>'target'),
                                                 
      new kernel::Field::Interface(
                name          =>'targetid',
                dataobjattr   =>'targetid'),

      new kernel::Field::Interface(
                name          =>'lastorgchangedt',
                readonly      =>1,
                dataobjattr   =>"if (lnkcontact.target='base::grp',".
                                "grp.lorgchangedt,contact.lorgchangedt)"),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Creator',
                dataobjattr   =>'lnkcontact.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'last Editor',
                dataobjattr   =>'lnkcontact.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-System',
                dataobjattr   =>'lnkcontact.srcsys'),
                                                 
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-Id',
                dataobjattr   =>'lnkcontact.srcid'),
                                                 
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-Load',
                dataobjattr   =>'lnkcontact.srcload'),
                                                 
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkcontact.createdate'),
                                                 
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkcontact.modifydate'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Editor Account',
                dataobjattr   =>'lnkcontact.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkcontact.realeditor'),

      new kernel::Field::Link(
                name          =>'secparentobj',
                label         =>'Security Parent-Object',
                sqlorder      =>'NONE',
                dataobjattr   =>'lnkcontact.parentobj'),

   );
   $self->setDefaultView(qw(parentobj targetname cdate editor));
   $self->LoadSubObjs("ext/lnkcontact","lnkcontact");
   $self->setWorktable("lnkcontact");
   $self->{history}={
      insert=>[
         'local'
      ],
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
          },id=>'refid', field=>'targetname',as=>'contacts'}
      ]
   };
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$workdb)=$self->getWorktable();
   my $from=$worktable;
   if ($mode eq "select"){
      $from="$worktable ".
            "left outer join grp ".
               "on $worktable.target='base::grp' and ".
                  "$worktable.targetid=grp.grpid ".
            "left outer join contact ".
               "on $worktable.target='base::user' and ".
                  "$worktable.targetid=contact.userid ";
   }

   return($from);
}

sub getFullname
{
   my $self=shift;
   my $current=shift;
   my $fld=$self->getParent->getField("parentobj",$current);
   my $parentobj=$fld->RawValue($current);
   my $fld=$self->getParent->getField("refid",$current);
   my $refid=$fld->RawValue($current);
   my $obj=getModuleObject($self->getParent->Config,$parentobj);
   if (defined($obj)){
      $parentobj=$self->getParent->T($parentobj,$parentobj);
      my $fld=$obj->IdField();
      if (defined($fld)){
         my $idfieldname=$fld->Name();
         if ($idfieldname ne ""){
            my $flt={$idfieldname=>\$refid};
            if (defined($obj->getField("cistatusid"))){
               $flt->{cistatusid}="<6";
            }
            $obj->SetFilter($flt);
            my ($refrec,$msg)=$obj->getOnlyFirst(qw(fullname name));
            if (defined($refrec)){
               if ($refrec->{fullname} ne ""){
                  $parentobj.=" ($refrec->{fullname})";
               }
               elsif ($refrec->{name} ne ""){
                  $parentobj.=" ($refrec->{name})";
               }
               else{
                  $parentobj.=" ($refid)";
               }
            }
            else{
               $parentobj.=" (deleted object with refid $refid)";
            }
         }
      }
      my $fld=$self->getParent->getField("roles",$current);
      my $roles=$fld->RawValue($current);
      if (defined($roles)){
         $roles=[$roles] if (ref($roles) ne "ARRAY");
         $parentobj.=" ".join(",",@$roles);
      }
   }
  

   return($parentobj); 

}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (defined($self->{secparentobj})){
      push(@flt,[{secparentobj=>\$self->{secparentobj}}]);
   }
   return($self->SetFilter(@flt));
}



sub getPostibleRoleValues
{
   my $self=shift;
   my $current=shift;
   my $newrec=shift;
   my $app=$self->getParent();
   my @opt;
   my $parentobj;

   if (defined($current)){
      $parentobj=$current->{parentobj};
   }
   else{
      if (defined($newrec)){
         if (exists($newrec->{parentobj})){
            $parentobj=$newrec->{parentobj};
         }
         # wenn über die app secparent definiert,
         # dann geht das vor!
         if (exists($app->{secparentobj}) &&
             $app->{secparentobj} ne ""){
            $parentobj=$app->{secparentobj}
         }
      }
      if ($parentobj eq ""){
         $parentobj=Query->Param("parentobj");  # bei Neueingabe über SubList
      }
   }
   if ($parentobj eq ""){
      msg(ERROR,"internal application error - no paarentobj detected");
      msg(ERROR,"write request:".Dumper($newrec));
      return(undef);
   }

   foreach my $obj (values(%{$app->{lnkcontact}})){
      push(@opt,$obj->getPosibleRoles($self,$parentobj,$current,$newrec));
   }
   return(@opt);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/lnkcontact.jpg?".$cgi->query_string());
}


sub getRecordHtmlIndex
{ return(); }



sub prepUploadRecord                              # pre processing interface
{
   my $self=shift;
   my $inp=shift;
   if (defined($self->{secparentobj})){
      $inp->{parentobj}=$self->{secparentobj};
   }
   return(1);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $targetid=effVal($oldrec,$newrec,"targetid");
   my $target=effVal($oldrec,$newrec,"target");
   if ($target eq "" || $targetid eq ""){
      $self->LastMsg(ERROR,"no contact specified");
      return(0);
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   if (!defined($parentobj) && defined($self->{secparentobj})){
      $parentobj=$self->{secparentobj};
      $newrec->{parentobj}=$parentobj;
   }
   if (exists($newrec->{roles}) && ref($newrec->{roles}) eq "ARRAY"){
      $newrec->{roles}=[grep({defined($_) && $_ ne ""} @{$newrec->{roles}})];
   }
   my $refid=effVal($oldrec,$newrec,"refid");
   if (!defined($parentobj) || $parentobj eq ""){
      $self->LastMsg(ERROR,"empty parent object");
      return(0);
   }
   if (defined($self->{secparentobj}) && $parentobj ne $self->{secparentobj}){
      my $msg=sprintf("invalid write request to requested parentobj=%s on ".
                      "secparentobj=%s",$parentobj,$self->{secparentobj});
      $self->LastMsg(ERROR,$msg);
      return(0);
   }
   if (!defined($refid) || $refid eq ""){
      $self->LastMsg(ERROR,"empty refid");
      return(0);
   }
   foreach my $obj (values(%{$self->{lnkcontact}})){
      if ($obj->can("Validate")){
         my $bak=$obj->Validate($oldrec,$newrec,$origrec,$parentobj,$refid);
         if (!$bak){
            if (!$self->LastMsg()){
               $self->LastMsg(ERROR,"unknown error in Validate at $obj");
            }
            return(0);
         }
      }
   }
   #
   # Security check
   #
   my $p=getModuleObject($self->Config,$parentobj);
   if (!defined($p)){ 
      $self->LastMsg(ERROR,"invalid parentobj '$parentobj'");
      return(0);
   }
   my $idname=$p->IdField->Name();
   my %flt=($idname=>\$refid);
   $p->SetFilter(\%flt);
   my @l=$p->getHashList(qw(ALL));
   if ($#l!=0){
      $self->LastMsg(ERROR,
                     "invalid refid '$refid' in parent object '$parentobj'");
      return(0);
   }

   my $rold;
   my $rnew;
   if (defined($oldrec) && exists($oldrec->{roles})){
      $rold=$oldrec->{roles};
      if (ref($rold) eq "ARRAY"){
         $rold=join(",",sort(@{$rold}));
      }
   }
   if (defined($newrec) && exists($newrec->{roles})){
      $rnew=$newrec->{roles};
      if (ref($rnew) eq "ARRAY"){
         $rnew=join(",",sort(@{$rnew}));
      }
   }


   if (defined($oldrec) &&
       !effChanged($oldrec,$newrec,"comments") &&
       !effChanged($oldrec,$newrec,"refid") &&
       !effChanged($oldrec,$newrec,"target") &&
       !effChanged($oldrec,$newrec,"expiration") &&
       !effChanged($oldrec,$newrec,"alertstate") &&
       !effChanged($oldrec,$newrec,"targetid") &&
       trim($rold) eq trim($rnew)){   # prevent empty updates
      %{$newrec}=();  
   }
   return(1) if ($self->IsMemberOf("admin"));

   if ($self->isDataInputFromUserFrontend()){
      return(1) if ($self->checkWriteAccess($p,$l[0]));
   }
   else{
      return(1);
   }
   $self->LastMsg(ERROR,"no write access to requested contact");
   return(0);
}

sub checkWriteAccess
{
   my $self=shift;
   my $p=shift;
   my $current=shift;

   my @write=$p->isWriteValid($current);
   if ($#write!=-1){
      return(1) if (grep(/^ALL$/,@write));
      foreach my $fo ($p->getFieldObjsByView(["ALL"],current=>$current)){
         if ($fo->Type() eq "ContactLnk"){
            my $grp=quotemeta($fo->{group});
            $grp="default" if ($grp eq "");
            return(1) if (grep(/^$grp$/,@write));
         }
      }
   }
   return(0);
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
   my $rec=shift;
   if (defined($rec)){
      return("default") if ($self->IsMemberOf("admin"));
      my $p=getModuleObject($self->Config,$rec->{parentobj});
      my $refid=$rec->{refid};
      return(undef) if ($refid eq "");
      return(undef) if (!defined($p));
      my $idname=$p->IdField->Name();
      my %flt=($idname=>\$refid);
      $p->SetFilter(\%flt);
      my @l=$p->getHashList(qw(ALL));
      return(undef) if ($#l!=0);
      return("default") if ($self->checkWriteAccess($p,$l[0]));
      return(undef);
   }
   return("default");
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orig=shift;

   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $refid=effVal($oldrec,$newrec,"refid");
   $self->UpdateParentMdate($parentobj,$refid);
   return($self->SUPER::FinishWrite($oldrec,$newrec,$orig));
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;


   my $parentobj=$oldrec->{parentobj};
   my $refid=$oldrec->{refid};
   $self->UpdateParentMdate($parentobj,$refid);
   return($self->SUPER::FinishDelete($oldrec));
}


sub isRoleMultiUsed
{
   my $self=shift;
   my $role=shift;
   my $requestroles=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $parentobj=shift;
   my $refid=shift;
   my $id=effVal($oldrec,$newrec,"id");

   $self->ResetFilter();
   $self->SetFilter({parentobj=>\$parentobj,refid=>\$refid});
   my @l=$self->getHashList(qw(id roles));
   my $alreadyused=0;
   foreach my $rec (@l){
      next if (defined($id) && $id==$rec->{id});
      my $r=$rec->{roles};
      $r=[$r] if (ref($r) ne "ARRAY");
      foreach my $chkrole (keys(%$role)){
         if (grep(/^$chkrole$/,@$r) && grep(/^$chkrole$/,@$requestroles)){
            $self->LastMsg(ERROR,
                           sprintf($self->T("role \"%s\" already assigned at ".
                             "current data record"),$role->{$chkrole}));
            return(1);
         }
      }
   }

   return(0);
}


sub copyContacts
{
   my $self=shift;
   my $src=shift;
   my $dstdataobj=shift;
   my $dstid=shift;
   my $inscomment=shift;

   if (ref($src) eq "ARRAY"){
      my %addrole;
      foreach my $crec (@$src){
         my $roles=$crec->{roles};
         $addrole{$crec->{target}}->{$crec->{targetid}}=$roles; 
      }
      $src=\%addrole;
   }

   foreach my $ctype (keys(%$src)){
      foreach my $contactid (keys(%{$src->{$ctype}})){
         if (ref($src->{$ctype}->{$contactid}) ne "ARRAY"){
            my $roles=$src->{$ctype}->{$contactid};
            $src->{$ctype}->{$contactid}=[$roles];
         }
      }
   }

   $self->ResetFilter();
   $self->SetFilter({
      refid=>\$dstid,
      parentobj=>[$dstdataobj],
   });
   my @cur=$self->getHashList(qw(ALL));
   $self->ResetFilter();
   foreach my $ctype (keys(%$src)){
      foreach my $contactid (keys(%{$src->{$ctype}})){
         my @old=grep({
            $_->{target} eq $ctype && $_->{targetid} eq $contactid
         } @cur);
         if ($#old==-1){
            my $cobj=$self->getPersistentModuleObject("I:".$ctype,$ctype);
            my $crec;
            if ($ctype eq "base::user"){
               $cobj->SetFilter({userid=>\$contactid,cistatusid=>\'4'});
               ($crec)=$cobj->getOnlyFirst(qw(ALL));
            }
            if ($ctype eq "base::grp"){
               $cobj->SetFilter({grpid=>\$contactid,cistatusid=>\'4'});
               ($crec)=$cobj->getOnlyFirst(qw(ALL));
            }
            if (defined($crec)){
               $self->ValidatedInsertRecord({
                  target=>$ctype,
                  targetid=>$contactid,
                  roles=>$src->{$ctype}->{$contactid},
                  refid=>$dstid,
                  comments=>$inscomment,
                  parentobj=>$dstdataobj
               });
            }
         }
         else{
            my @curroles=$old[0]->{roles};
            if (ref($curroles[0]) eq "ARRAY"){
               @curroles=@{$curroles[0]};
            }
            my $changed=0;
            foreach my $addrole (@{$src->{$ctype}->{$contactid}}){
               if (!in_array(\@curroles,$addrole)){
                  push(@curroles,$addrole);
                  $changed++;
               }
            }
            if ($changed){
               $self->ValidatedUpdateRecord($old[0],{
                  roles=>[@curroles],
               },{id=>\$old[0]->{id}});
            }
         }
      }
   }
   return(0);
}





1;
