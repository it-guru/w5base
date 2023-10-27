package base::filemgmt;
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
use kernel::App::Web::HierarchicalList;
use kernel::DataObj::DB;
use kernel::Field;
use Fcntl qw(SEEK_SET);
use File::Temp(qw(tmpfile));
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(       name       =>'fid',
                                   label      =>'W5BaseID',
                                   size       =>'10',
                                   dataobjattr=>'filemgmt.fid'),
                                  
      new kernel::Field::Text(     name       =>'fullname',
                                   label      =>'Fullname',
                                   readonly   =>1,
                                   htmlwidth  =>'300px',
                                   size       =>'40',
                                   dataobjattr=>'filemgmt.fullname'),

      new kernel::Field::File(     name       =>'file',
                                   onDownloadUrl=>sub{
                                      my $self=shift;
                                      my $current=shift;
                                      if ($current->{realfile} eq ""){
                                         return(undef);
                                      }
                                      return("load/".$current->{fid}); 
                                   },
                                   label      =>'Fileentry'),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Name',
                                   size       =>'20',
                                   dataobjattr=>'filemgmt.name'),

      new kernel::Field::TextDrop( name       =>'parent',
                                   label      =>'Directory',
                                   vjointo    =>'base::filemgmt',
                                   vjoinon    =>['parentid'=>'fid'],
                                   xvjoinbase  =>['realfile'=>\''],
                                   vjoindisp  =>'fullname'),


      new kernel::Field::Boolean(  name       =>'inheritrights',
                                   label      =>'inherit rights',
                                   dataobjattr=>'filemgmt.inheritrights'),

      new kernel::Field::Boolean(  name       =>'isprivate',
                                   label      =>'is private',
                                   dataobjattr=>'filemgmt.isprivate'),

      new kernel::Field::Text(     name       =>'parentobj',
                                   htmldetail =>0,
                                   label      =>'parent Object',
                                   htmlwidth  =>'90',
                                   dataobjattr=>'filemgmt.parentobj'),

      new kernel::Field::Text(     name       =>'parentrefid',
                                   group      =>'source',
                                   label      =>'parent Referenz ID',
                                   htmlwidth  =>'110',
                                   readonly   =>1,
                                   dataobjattr=>'filemgmt.parentrefid'),

      new kernel::Field::Text(     name       =>'entrytyp',
                                   readonly   =>1,
                                   group      =>'state',
                                   default    =>'dir',
                                   label      =>'Entry-Type',
                                   dataobjattr=>'filemgmt.entrytyp'),

      new kernel::Field::Text(     name       =>'contenttype',
                                   readonly   =>1,
                                   group      =>'state',
                                   label      =>'Content-Type',
                                   dataobjattr=>'filemgmt.contenttype'),

      new kernel::Field::Text(     name       =>'contentsize',
                                   readonly   =>1,
                                   group      =>'state',
                                   label      =>'Content-Size',
                                   dataobjattr=>'filemgmt.contentsize'),

      new kernel::Field::Text(     name       =>'contentstate',
                                   readonly   =>1,
                                   group      =>'state',
                                   onRawValue =>\&getState,
                                   depend     =>['realfile','contenttype',
                                                 'entrytyp'],
                                   label      =>'Content-State'),

      new kernel::Field::Textarea( name       =>'comments',
                                   label      =>'Comments',
                                   dataobjattr=>'filemgmt.comments'),

      new kernel::Field::SubList(   name       =>'acls',
                                    label      =>'Accesscontrol',
                                    subeditmsk =>'subedit.file',
                                    allowcleanup=>1,
                                    forwardSearch=>1,
                                    group      =>'acl',
                                    vjoininhash=>[qw(acltarget 
                                                     acltargetid 
                                                     aclmode)],
                                    vjointo    =>'base::fileacl',
                                    vjoinbase=>{'aclparentobj'=>$self->Self()},
                                    vjoinon    =>['fid'=>'refid'],
                                    vjoindisp  =>['acltargetname','aclmode']),

      new kernel::Field::Text(     name       =>'srcsys',
                                   group      =>'source',
                                   selectfix  =>1,       # for InlineAttachment
                                   label      =>'Source-System',
                                   dataobjattr=>'filemgmt.srcsys'),

      new kernel::Field::Text(     name       =>'srcid',
                                   group      =>'source',
                                   label      =>'Source-Id',
                                   dataobjattr=>'filemgmt.srcid'),

      new kernel::Field::Date(     name       =>'srcload',
                                   group      =>'source',
                                   label      =>'Last-Load',
                                   dataobjattr=>'filemgmt.srcload'),

      new kernel::Field::MDate(    name       =>'mdate',
                                   group      =>'source',
                                   label      =>'Modification-Date',
                                   dataobjattr=>'filemgmt.modifydate'),

      new kernel::Field::CDate(    name       =>'cdate',
                                   group      =>'source',
                                   label      =>'Creation-Date',
                                   dataobjattr=>'filemgmt.createdate'),

      new kernel::Field::Owner(    name       =>'owner',
                                   group      =>'source',
                                   label      =>'last Editor',
                                   dataobjattr=>'filemgmt.owner'),

      new kernel::Field::Editor(   name       =>'editor',
                                   group      =>'source',
                                   label      =>'Editor Account',
                                   dataobjattr=>'filemgmt.editor'),

      new kernel::Field::RealEditor(name      =>'realeditor',
                                   group      =>'source',
                                   label      =>'real Editor Account',
                                   dataobjattr=>'filemgmt.realeditor'),

      new kernel::Field::Link(     name       =>'parentid',
                                   label      =>'ParentID',
                                   dataobjattr=>'filemgmt.parentid'),

      new kernel::Field::Link(     name       =>'viewcount',
                                   label      =>'ViewCount',
                                   dataobjattr=>'filemgmt.viewcount'),

      new kernel::Field::Date(     name       =>'viewlast',
                                   label      =>'ViewLast',
                                   group      =>'source',
                                   dataobjattr=>'filemgmt.viewlast'),

      new kernel::Field::Link(     name       =>'viewfreq',
                                   label      =>'ViewFreq',
                                   dataobjattr=>'filemgmt.viewfreq'),

      new kernel::Field::Text(     name       =>'realfile',
                                   group      =>'source',
                                   label      =>'Realfile',
                                   readonly   =>1,
                                   dataobjattr=>'filemgmt.realfile'),


 #     new kernel::Field::SubList(  name       =>'users',
 #                                  label      =>'Users',
 #                                  group      =>'userro',
 #                                  vjointo    =>'base::lnkgrpuser',
 #                                  vjoinon    =>['grpid'=>'grpid'],
 #                                  vjoindisp  =>['user','roles']),
   );
   $self->setWorktable("filemgmt");
   $self->setDefaultView(qw(fullname contentsize parentobj entrytyp editor));
   $self->{PathSeperator}="/";
   $self->{locktables}="filemgmt write,fileacl write,contact write, iomap write";
   return($self);
}

sub getState
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent;
   my $config=$app->Config->getCurrentConfigName();
   my $w5root=$app->Config->Param("W5DOCDIR");
   $w5root.="/" if (!($w5root=~m/\/$/));
   my $state="bad";
   $state="ok" if ( $current->{entrytyp} eq "dir");
   $state="ok" if ( -f "${w5root}$config/$current->{realfile}" &&
                    -r "${w5root}$config/$current->{realfile}");
   $state="ok" if ( -f "${w5root}$config/$current->{realfile}");

   return($state);
}


sub SecureSetFilter
{
   my $self=shift;
   my %flt=();
   %flt=(parentobj=>undef) if (!$self->IsMemberOf("admin"));
   return($self->SUPER::SecureSetFilter(\%flt,@_));
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),"load","browser","Empty",
          "WebRefresh","WebUpload","WebChangeInherit","WebCreateDir","WebDAV");
}


sub normalizeFilename
{
   my $self=shift;
   my $filename=shift;

   $filename.="";  # ensure remove blessed file handle
   $filename=~s/^.*[\/\\]//;

   return($filename);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec)){
      if ($newrec->{parentobj} eq ""){
         $newrec->{parentobj}="base::filemgmt";
         $newrec->{parentrefid}="0";
      }
      $newrec->{parentid}=undef if (!exists($newrec->{parentid}) ||
                                     $newrec->{parentid}==0);
      if ($newrec->{parentrefid} ne "" && 
          $newrec->{parentobj} ne "base::filemgmt"){
         my $isprivate=effVal($oldrec,$newrec,"isprivate");
         if ($isprivate){
            my $prirec=$self->loadPrivacyAcl($newrec->{parentobj},
                              $newrec->{parentrefid});
            if (!$prirec->{rw} && !$self->IsMemberOf("admin")){
               $self->LastMsg(ERROR,"insuficient rights to write privacy data");
               return(undef);
            }
         }
      }
   }
   else{
      delete($newrec->{parentobj});
      delete($newrec->{parentrefid});
   }
   if (defined($newrec->{parentid})){
      my $chkfm=getModuleObject($self->Config,"base::filemgmt");
      $chkfm->SetFilter({fid=>[$newrec->{parentid}],entrytyp=>\'dir'});
      my ($prec)=$chkfm->getOnlyFirst("fid");
      if (!defined($prec)){
         $self->LastMsg(ERROR,"invalid parentid specified");
         return(undef);
      }
   }
   
   if (defined($newrec->{file}) && $newrec->{file} ne ""){
      if (!defined($oldrec) || $newrec->{realfile} eq "" ||
          $oldrec->{realfile} eq ""){
         my $res;
         my $id;
         if (defined($res=$self->W5ServerCall("rpcGetUniqueId")) &&
             $res->{exitcode}==0){
            $id=$res->{id};
         }
         else{
            msg(ERROR,"InsertRecord: W5ServerCall returend %s",Dumper($res));
            $self->LastMsg(ERROR,"W5Server problem - can't get unique id - ".
                          "please contact the admin");
            return(undef);
         }
         $id=~tr/[0-9]/[a-z]/;
         my ($f,$d3,$d2,$d1)=$id=~m/^(.*)(\S\S)(\S\S)(\S\S)$/;
         $newrec->{realfile}="$d1/$d2/$d3/$f";
      }
      my $realfile=$newrec->{realfile};
      $realfile=$oldrec->{realfile} if (!defined($realfile));
      my $context=$self->Context();
      {
         no strict;
         my $f=$newrec->{file};
         msg(INFO,"got filetransfer request ref=$f");
         if (ref($f) eq "MIME::Entity"){
            $f=$newrec->{file}->open("r");
         }
         msg(INFO,"cleared filetransfer request ref=$f");
         my $bk=seek($f,0,SEEK_SET);
         seek($f,0,SEEK_SET);
         if (!$self->StoreFilehandle($f,$realfile,"preview")){
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"can't store file");
            }
            return(undef);
         }
         seek($f,0,SEEK_SET);
         $context->{CurrentFileHandle}=$f;
      }
      my ($size,$atime,$mtime,$ctime,$blksize,$blocks);
      my $f=$newrec->{file};
      if (ref($newrec->{file}) eq "MIME::Entity"){
         $f=$newrec->{file}->open("r");
         while(<$f>){};
         $size=$f->tell();
         $f->seek(0,0);
      }
      else{
         (undef,undef,undef,undef,undef,undef,undef,
          $size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($f);
      }
      if (!defined($f) || $size<=0){
         $self->LastMsg(ERROR,
              sprintf($self->T('invalid file upload "%s" (size=%d by %s)'),
                               $f,$size,$ENV{REMOTE_USER}));
         return(undef);
      }
      my $filename=$f;
      if (ref($newrec->{file}) eq "MIME::Entity"){
         $filename=$newrec->{file}->head()->get("Content-Disposition");
         ($filename)=$filename=~m/filename=\"(.+)\"/;
      }
      $filename=$self->normalizeFilename($filename);
      if (!defined($newrec->{name}) || $newrec->{name} eq "" ||
          ($newrec->{name}=~m/[\\\/]/)){   # if name is not set or has path
         $newrec->{name}=$filename;        # included
      }
      if (length($newrec->{name})>80){
         $self->LastMsg(ERROR,"filename '%s' to long",$newrec->{name});
         return(undef);
      }
      $newrec->{contentsize}=$size;
      if (!defined($newrec->{contenttype}) || $newrec->{contenttype} eq ""){
         my $i=Query->UploadInfo($f);
         $newrec->{contenttype}=$i->{'Content-Type'};
      }
      if (!defined($newrec->{contenttype}) || $newrec->{contenttype} eq ""){
         $self->ReadMimeTypes();
         my ($ext)=$newrec->{name}=~/\.([a-z,0-9]{1,4})$/;
         if (defined($ext) && $ext ne ""){
            if (defined($self->{MimeType}->{lc($ext)})){
               $newrec->{contenttype}=$self->{MimeType}->{lc($ext)};
            }
         }
         if ($newrec->{contenttype} eq ""){
            $newrec->{contenttype}="application/octect-bin";
         }
      }
      $newrec->{entrytyp}='file';
   }
   if ($newrec->{file} eq "" && !defined($oldrec)){
      $newrec->{entrytyp}='dir' if (!defined($newrec->{entrytyp}));
   }

   if (defined($newrec->{name}) || !defined($oldrec)){
      my $newname=$newrec->{name};
      $newname=~s/^.*[\\\/]//;
      $newname=trim(UTF8toLatin1($newname));
      $newrec->{name}=$newname;
      if ($newrec->{name} eq "" ||
          $newrec->{name} eq "W5Base" ||
          $newrec->{name}=~m/^\.\./ ||
          $newrec->{name} eq "auth" ||
          $newrec->{name} eq "public" ||
          ($newrec->{name}=~m/["'`\/\\]/) ||
          !($newrec->{name}=~m/^[[:graph:]äöüÄÖÜß \.]+$/i)){
         $self->LastMsg(ERROR,"invalid filename '%s' specified",
                        $newrec->{name});
         return(undef);
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   my $g=getModuleObject($self->Config,"base::filemgmt");
   my $grpid=$rec->{fid};
   $g->SetFilter({"parentid"=>\$grpid});
   my @l=$g->getHashList(qw(fid));
   if ($#l!=-1){
      return(undef);
   }
   return($self->isWriteValid($rec));
}

sub checkacl
{
   my $self=shift;
   my $rec=shift;
   my $mode=shift;

   my $userid=$self->getCurrentUserId();
   my $fm=$self->getPersistentModuleObject("base::filemgmt");
   my $context=$self->Context();
   $context->{aclmode}={} if (!defined($context->{aclmode}));
   $context->{privacl}={} if (!defined($context->{privacl}));
   $context=$context->{aclmode};
   my $privcontext=$context->{privacl};

   if ($rec->{parentobj} ne "base::filemgmt" && $rec->{parentrefid} ne "0" &&
       $rec->{parentrefid} ne ""){
      $context->{$rec->{fid}}={  
         'read'=>0,
         'write'=>0,
         'admin'=>0
      };
      my $pobj=$self->getPersistentModuleObject($rec->{parentobj});
      if (defined($pobj)){
         my $idfld=$pobj->IdField();
         if (defined($idfld)){
            $pobj->SetFilter({$idfld->Name()=>\$rec->{parentrefid}});
            my @l=$pobj->getHashList(qw(ALL));
            my $prec;
            if ($#l>0){
               $self->LastMsg(ERROR,"systemerror - parent rec not unique");
            }
            if ($#l==0){
               $prec=$l[0];
            }
            if (defined($prec)){
               my @wgrps=$pobj->isWriteValid($prec);
               if (in_array(\@wgrps,[qw(ALL attachments)])){
                  $context->{$rec->{fid}}->{write}=1;
                  $context->{$rec->{fid}}->{read}=1;
               }
               else{
                  if ($rec->{isprivate}){
                     if (exists($prec->{contacts}) &&
                         ref($prec->{contacts}) eq "ARRAY"){
                        my %grps=$pobj->getGroupsOf($ENV{REMOTE_USER},
                                                    ["RMember"],"both");
                        my @grpids=keys(%grps);
                        CLOOP: foreach my $contact (@{$prec->{contacts}}){
                           if ($contact->{target} eq "base::user" &&
                               $contact->{targetid} ne $userid){
                              next;
                           }
                           if ($contact->{target} eq "base::grp"){
                              my $grpid=$contact->{targetid};
                              next if (!grep(/^$grpid$/,@grpids));
                           }
                           my @roles=($contact->{roles});
                           if (ref($contact->{roles}) eq "ARRAY"){
                              @roles=@{$contact->{roles}};
                           }
                           if (grep(/^privread$/,@roles)){
                              $context->{$rec->{fid}}->{read}=1;
                              last CLOOP;
                           }
                        }
                     }
                  }
                  else{
                     my @rgrps=$pobj->isViewValid($prec);
                     if (in_array(\@rgrps,[qw(ALL attachments)])){
                        $context->{$rec->{fid}}->{read}=1;
                     }
                  }
               }
            }
            else{
               $self->LastMsg(ERROR,"systemerror - parent rec detected");
            }
         }
         else{
            $self->LastMsg(ERROR,"systemerror - IdField can not be detected");
         }
      }
   }


   if (!defined($context->{$rec->{fid}}->{$mode})){
      # acl des eigenen Records laden und im context abspeichern
      # Achtung: Die ACL's der parents müssen recursiv nach oben
      # berücksichtig werden

      my @fid=($rec->{fid});
      my $workrec=$rec;
      $context->{$workrec->{fid}}=$workrec;
      my $foundro=0;
      my $foundrw=0;
      my $foundad=0;
      while(defined($workrec)){
         if (!$workrec->{inheritrights}){
            if (exists($workrec->{admin})){
               $foundad=$workrec->{admin};
            }
            if (exists($workrec->{read})){
               $foundro=$workrec->{read};
            }
            if (exists($workrec->{write})){
               $foundrw=$workrec->{write};
            }
            last;
         }
         if (defined($workrec->{parentid})){
            my $parentid=$workrec->{parentid};
            if (!defined($context->{$parentid})){
               $fm->ResetFilter();
               $fm->SetFilter({fid=>\$parentid});
               ($workrec)=$fm->getOnlyFirst(qw(parentid acls  
                                               parentobj parentrefid
                                               inheritrights));
               $context->{$parentid}=$workrec if (defined($workrec));
            }
            unshift(@fid,$parentid);
            $workrec=$context->{$parentid};
         }
         else{
            last;
         }
      }
      my $isadmin=$self->IsMemberOf("admin");
      foreach my $fid (@fid){
         if (!defined($context->{$fid}->{$mode})){
            my $issubofdata=0;
            if ($context->{$fid}->{parentobj} ne "" &&
                $context->{$fid}->{parentobj} ne "base::filemgmt" &&
                !defined($context->{$fid}->{parentid})){
               $issubofdata=1;
            }
            if ($isadmin){
               $foundad=1;
               $foundrw=1;
               $foundro=1;
            }
            else{
               if (ref($context->{$fid}->{acls}) eq "ARRAY"){
                  my $aclsfound=0;
                  foreach my $acl (@{$context->{$fid}->{acls}}){
                     $aclsfound++;
                     if (($acl->{acltarget} eq "base::user" &&
                          $acl->{acltargetid} eq $userid) ||
                         ($acl->{acltarget} eq "base::grp" &&
                          $self->IsMemberOf($acl->{acltargetid},undef,"both"))){
                        if ($acl->{aclmode} eq "admin"){
                           $foundad=1;
                        }
                        if ($acl->{aclmode} eq "write"||
                            $acl->{aclmode} eq "admin"){
                           $foundrw=1;
                        }
                        if ($acl->{aclmode} eq "read" ||
                            $acl->{aclmode} eq "write"||
                            $acl->{aclmode} eq "admin"){
                           $foundro=1;
                        }
                     }
                  }
                  if ($issubofdata && !$aclsfound){
                     $foundad=0;
                     $foundrw=0;
                     $foundro=0;
                     if ($context->{$fid}->{isprivate}){
                        my $privkey=$context->{$fid}->{parentobj}."->".
                                    $context->{$fid}->{parentrefid};
                        if (!exists($privcontext->{$privkey})){ # cache check
                           $privcontext->{$privkey}=$self->loadPrivacyAcl(
                                         $context->{$fid}->{parentobj},
                                         $context->{$fid}->{parentrefid});
                        }
                        $foundro=$privcontext->{$privkey}->{ro};
                        $foundrw=$privcontext->{$privkey}->{rw};
                     }
                     else{
                        my $parentobj=$context->{$fid}->{parentobj};
                        my $parentid=$context->{$fid}->{parentrefid};
                        my $do=getModuleObject($self->Config,$parentobj);
                        if (defined($do) && $parentid ne ""){
                           my $idobj=$do->IdField();
                           if (defined($idobj)){
                              my $idname=$idobj->Name();
                              $do->SecureSetFilter({$idname=>\$parentid});
                              my ($prec)=$do->getOnlyFirst(qw(ALL));
                              if (defined($prec)){
                                 my @acl=$do->isViewValid($prec);
                                 if (grep(/^(ALL|attachments)$/,@acl)){ 
                                    $foundro=1;
                                 }
                              }
                           } 
                        }
                     }
                  }
               }
            }
            my $inheritrights=$context->{$fid}->{inheritrights};
            my $parentid=$context->{$fid}->{parentid};
            $context->{$fid}={    # verkürzen des Cache eintrages auf die
               'read'=>$foundro,  # "essenz".
               'write'=>$foundrw,
               'inheritrights'=>$inheritrights,
               'parentid'=>$parentid,
               'admin'=>$foundad
            };
         }
         else{  # init rights from upper level
            $foundro=$context->{$fid}->{read};
            $foundrw=$context->{$fid}->{write};
            $foundad=$context->{$fid}->{admin};
         }
      } 
      
   }
   
   return($context->{$rec->{fid}}->{$mode});

}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return(qw(header default)) if (!defined($rec));

   if (defined($rec)){
      return(qw(ALL)) if ($rec->{srcsys} eq "W5Base::InlineAttach" ||
                          $self->checkacl($rec,"read"));
   }
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
#   return(undef) if (!defined($rec));
   return(qw(default)) if (!defined($rec));
   return(qw(default acl)) if ($self->checkacl($rec,"admin"));
   return(qw(default)) if ($self->checkacl($rec,"write"));
   return(qw(default acl)) if ($self->IsMemberOf("admin"));
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec);

   my $context=$self->Context();
   if (defined($context->{CurrentFileHandle})){
      my $f=$context->{CurrentFileHandle};
      my $realfile=effVal($oldrec,$newrec,"realfile");
      if (!$self->StoreFilehandle($f,$realfile,"FinishWrite")){
         return(undef);
      }
   }

   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->RemoveFile($oldrec);
   return($bak);
}

sub sendFile
{
   my $self=shift;
   my $id=shift;
   my $inline=shift;
   my $thumbnail=shift;
   my $config=$self->Config->getCurrentConfigName();
   my $w5root=$self->Config->Param("W5DOCDIR");

   my ($rec,$msg);
   if (defined($id) && $id ne ""){
      $self->ResetFilter();
      $self->SetFilter({fid=>$id});
      $self->SetCurrentView(qw(ALL));
      ($rec,$msg)=$self->getFirst();
      if (!$self->isViewValid($rec)){
         if ($ENV{REMOTE_USER} eq "anonymous"){
            my $uri=$ENV{SCRIPT_URI};
            $uri=~s#/public/#/auth/#;  # try to logon
            $self->HtmlGoto($uri);
         }
         else{
            printf("Status: 403 Forbidden - no access to file\n");
            printf("Content-type: text/plain\n\n".
                  "Forbidden\nYou don't have access to $ENV{SCRIPT_URI}\n");
         }
         return(undef);
      }
   }
   if (defined($rec)){
      my %param=();
      #######################################################################
      # häufigkeits Berechnung - erster Versuch
      #
      my $now=NowStamp("en");
      my $viewfreq=defined($rec->{viewfreq}) ? $rec->{viewfreq}: 100;
      if ($rec->{viewlast} ne ""){
         my $t=CalcDateDuration($rec->{viewlast},$now,"GMT");
         if ($t->{totalseconds}>15120000){  # halbes Jahr
            $viewfreq=$viewfreq*0.2;
         }
         elsif ($t->{totalseconds}>604800){  # woche
            $viewfreq=$viewfreq*0.3;
         }
         elsif ($t->{totalseconds}>86400){  # tag
            $viewfreq=$viewfreq*0.8;
         }
         elsif ($t->{totalseconds}>3600){
            $viewfreq=$viewfreq*1.3;
         }
         else{
            $viewfreq=$viewfreq*1.05;
         }
         $viewfreq=int($viewfreq);
      }
      #######################################################################
      if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
         $self->UpdateRecord({viewcount=>$rec->{viewcount}+1,
                              viewlast=>$now,
                              viewfreq=>$viewfreq},{fid=>$id});
      }
      my $realfile="$w5root/$config/$rec->{realfile}";
      eval("use GD;");
      if ($@ eq "" && $thumbnail){
         msg(INFO,"do scaling $rec->{name} to thumbnail");
         my $img;
         eval('$img=new GD::Image($realfile);');
         if (defined($img)){
            my ($width,$height)=(80,80);
            my $k_h = $height / $img->height;
            my $k_w = $width / $img->width;
            my $k = ($k_h < $k_w ? $k_h : $k_w);
            if ($img->height<$height &&
                $img->width<$width){  # scale only if image is to large
               $height=$img->height;
               $width=$img->width;
            }
            else{
               $height = int($img->height * $k);
               $width  = int($img->width * $k);
            }
            my $image = GD::Image->new($width,$height); 
            $image->copyResampled($img,0,0,0,0,$width,$height,
                                  $img->width,$img->height);
            print $self->HttpHeader("image/jpeg");
            binmode STDOUT;
            print $image->jpeg;
            return(undef);
         }
         my $icon="icon_undefcode.gif";
         if ($rec->{contenttype} eq "application/pdf"){
            $icon="icon_pdf.gif";
         }
         elsif ($rec->{contenttype}=~m/application.*excel/){
            $icon="icon_xls.gif";
         }
         print $self->HttpHeader("image/gif");
         my $filename=$self->getSkinFile("base/img/$icon"); 
         if (open(F,"<$filename")){
            print join("",<F>);
            close(F);
         }
      }
      my $contenttype="application/octet-bin";
      $param{filename}="file.bin";
      $contenttype=$rec->{contenttype} if ($rec->{contenttype} ne "");
      $param{filename}=$rec->{name} if ($rec->{name} ne ""); 
      if (Query->Param("inline")){
         $param{inline}=1;
         $inline=1;
      }
      $param{attachment}=!($inline); 
      $param{cache}=10; 
      if (open(F,"<$realfile")){
         print $self->HttpHeader($contenttype,%param);
         print join("",<F>);
         return();
      }
      else{
         msg(ERROR,"base::filemgmt error - can not open $realfile");
      }
   }
   if ($thumbnail){
      print $self->HttpHeader("image/gif");
      my $filename=$self->getSkinFile("base/img/cleaned.gif"); 
      if (open(MYF,"<$filename")){
         binmode MYF;
         binmode STDOUT;
         while(<MYF>){
            print $_;
         }
         close(MYF);
      }
      return(undef);
   }
   print $self->HttpHeader("text/html");
   printf("Not found FunctionPath=%s<br>\n",Query->Param("FunctionPath"));  
}

sub load
{
   my $self=shift;
   my @fp=split(/\//,Query->Param("FunctionPath"));  
   my $inline=0;
   my $thumbnail=0;
   while($#fp>0){
      if ($fp[0] eq "thumbnail"){
         $thumbnail=1;
      }
      if ($fp[0] eq "inline"){
         $inline=1;
      }
      shift(@fp);
   }
   my $id=$fp[0];
   $self->sendFile($id,$inline,$thumbnail);
}

sub RemoveFile
{
   my $self=shift;
   my $rec=shift;
   my $config=$self->Config->getCurrentConfigName();
   my $w5root=$self->Config->Param("W5DOCDIR");

   my $f=$w5root."/".$config."/".$rec->{realfile};
   msg(DEBUG,"try to unlink %s",$f);
   if (-f $f ){
      unlink($f);
   }
}


sub StoreFilehandle
{
   my $self=shift;
   my $fh=shift;
   my $filename=shift;
   my $mode=shift;
   my $config=$self->Config->getCurrentConfigName();
   my $w5root=$self->Config->Param("W5DOCDIR");
   my $dir=$w5root;
   umask(0);
   if (! -d $dir){
      msg(ERROR,"W5DOCDIR='$dir' does not exists");
      return(undef);
   }
   my @path=split(/\//,$filename);
   unshift(@path,$config);
   for(my $sub=0;$sub<$#path;$sub++){
      $dir.="/" if (!($dir=~m/\/$/));
      $dir.=$path[$sub];
      if (! -d $dir){
         msg(INFO,"dir='$dir'");
         if (!mkdir($dir)){
            msg(ERROR,"can't mkdir dir='$dir' - $?, $!");
            return(undef);
         }
      }
   } 
   my $maxw5doc=$self->Config->Param("MaxW5DocAttachment");
   my $sz=0;
   my $buffer;
   my $realfile="$w5root/$config/$filename";
   if ($mode eq "preview"){
      if (!open(F,">$realfile")){
         msg(ERROR,"can't open for write file='$realfile'");
         return(undef);
      }
      close(F);
      while (my $bytesread=read($fh,$buffer,1024)) {
         $sz+=length($buffer);
         if ($sz>$maxw5doc){
            $self->LastMsg(ERROR,
                           "Attachment upload is limited to %d bytes per file",
                           $maxw5doc);
            return(undef);
         }
         print F $buffer;
      }
      unlink($realfile);
      return(1);
   }
   return(undef) if (!open(F,">$realfile"));
   while (my $bytesread=read($fh,$buffer,1024)) {
      $sz+=length($buffer);
      if ($sz>$maxw5doc){
         $self->LastMsg(ERROR,
                        "Attachment upload is limited to %d bytes per file",
                        $maxw5doc);
         return(undef);
      }
      print F $buffer;
   }
   close(F);
   return(1);
}


sub browser
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   my $prefix=Query->Param("RootPath");
   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              js=>['toolbox.js','subModal.js'],
                              form=>1,
                              prefix=>$prefix,
                              title=>"WebFS: ".$p);
   $header.=$self->HtmlSubModalDiv(prefix=>$prefix);
   my $bar=$self->getAppTitleBar(
       prefix=>$prefix,
       title=>'WebFS: '.$p,
       autofocus=>1
   );
   $rootpath.="/" if ($rootpath eq "..");
   $rootpath.="./" if ($rootpath eq "");
   if ($ENV{REQUEST_METHOD} eq "PUT"){
      msg(INFO,"request upload over PUT to '$p' by '$ENV{REMOTE_USER}'");
      if ($p=~m/\/$/){
         print(msg(ERROR,"unable to PUT directory '$p'"));
         return(undef);
      }
      my ($path,$file);
      my $target=$self->FindTarget($p);
      if (defined($target)){
         $path=$p;
         $file=$ENV{HTTP_CONTENT_NAME};
         if ($target->{entrytyp} eq "dir" && $file ne ""){
            msg(INFO,"store '$file' in '$path'");
         }
         else{
            $target=undef;
         }
      }
      if (!defined($target)){
         ($path,$file)=$p=~m/^(.*)\/(.*)$/;
         $path="/" if ($path eq "");
         $target=$self->FindTarget($path);
      }
      printf STDERR ("target=$path file=$file res=%s\n",Dumper($target));
      #return(undef);
      if (!defined($target)){
         my @p=split(/\//,$path);
         my $pdir="/";
         my $dir="";
         foreach my $sub (@p){
            next if ($sub eq "");
            $dir.="/$sub";
            $target=$self->FindTarget($dir);
            if (!defined($target)){
               my $ptarget=$self->FindTarget($pdir);
               if (defined($ptarget)){
                  my $actionok=0;
                  $actionok=1 if ($self->checkacl($ptarget,"write"));
                  $actionok=1 if ($self->IsMemberOf("admin"));
                  printf STDERR ("try to create $dir in $pdir\n");
                  last if (!$actionok);
                  my %rec=(name=>$sub,parent=>$ptarget->{fullname},
                           entrytyp=>'dir');
                  if (!($self->ValidatedInsertRecord(\%rec))){
                     msg(ERROR,"can't create dir $sub in $pdir");
                     last;
                  }
               }
            }
            $pdir=$dir;
         }
         $target=$self->FindTarget($path);
         if (!defined($target)){
            print("Status: 404\n");
            print($self->HttpHeader("text/plain"));
            print(msg(ERROR,"unable to find directory '$path'"));
            return(undef);
         }
      }
      my $actionok=0;
      $actionok=1 if ($self->checkacl($target,"write"));
      $actionok=1 if ($self->IsMemberOf("admin"));
      if (!$actionok){
         print("Status: 401\n");
         print($self->HttpHeader("text/plain"));
         print(msg(ERROR,"not allowed to PUT in directory '$path'"));
         return(undef);
      }

      my $clength = $ENV{'CONTENT_LENGTH'};
      #if (!$clength) { &reply(500, "Content-Length missing ($clength)"); }

      # Read the content itself
      my $toread = $clength;
      my $t=tmpfile();
      while ($toread > 0)
      {
          my $data;
          my $nread = read(STDIN, $data, $clength);
          last if (!$nread);
          syswrite($t,$data,$nread);
      }
      seek($t,0,SEEK_SET);
      my %rec=(name=>$file,file=>$t);
      my %flt=(name=>\$file);
      $path=~s/^\///;
      if ($path ne ""){
         $rec{parent}=$path;
         $flt{parent}=\$path;
      }
      print($self->HttpHeader("text/plain"));
      if (!$ENV{HTTP_XCONTENT_OVERWRITE}){
         $self->ResetFilter();
         $self->SetFilter(\%flt);
         my ($rec)=$self->getOnlyFirst("id");
         if (defined($rec)){
            printf("%-6s %s\n","ERROR:","$p/$file already exists");
            close($t);
            return(undef); 
         }
         $self->ResetFilter(); 
      }
      if ($self->ValidatedInsertOrUpdateRecord(\%rec,\%flt)){
         $file=$ENV{HTTP_CONTENT_NAME} if ($ENV{HTTP_CONTENT_NAME} ne "");
         printf("%-6s %s\n","OK:","stored '$file' in '$p'");
      }
      else{
         printf("%-6s %s\n","ERROR:","$p/$file not stored");
      }
      close($t);
      return(undef); 
   }
   my $target=$self->FindTarget($p,'*');
   if (!defined($target) && $p=~m/\/index.html$/){
      $p=~s/index.html$//;
      $target=$self->FindTarget($p,'*');
   }
   if (defined($target)){
      if ($p ne "/" && $p ne "" && !defined($self->isViewValid($target))){
         print($header);
         print("<div class=message>"); 
         printf("ERROR: ".$self->T("no access to '%s'"),$p);
         print("</div>"); 
         return(undef);
      }
      if ($target->{entrytyp} eq "file"){
         if ($target->{contenttype} eq "text/html" ||
             $target->{contenttype} eq "image/gif" ||
             $target->{contenttype} eq "image/jpeg" ||
             $target->{contenttype} eq "text/plain"){
            $self->sendFile($target->{fid},1);
         }
         else{
            $self->sendFile($target->{fid});
         }
        # print($header);
        # printf("Path=$p<br>");
        # printf("<a href=\"$up\">..</a><br>");
        # printf("sending file ...");
      } 
      else{
         my $fm=$self->getPersistentModuleObject("base::filemgmt");
         my $op=Query->Param("OP");
         my @oldval=Query->Param("fid");
         if ($op eq "delete" && $#oldval!=-1){
            Query->Delete("fid");
            Query->Delete("OP");
            $op=undef;
            $fm->SetFilter({'parentid'=>[$target->{fid}],fid=>\@oldval});
            $fm->SetCurrentView(qw(ALL));
            $fm->ForeachFilteredRecord(sub{
                                          $fm->SecureValidatedDeleteRecord($_);
                                       });
         }
         $fm->ResetFilter();
         $fm->SetFilter({parentid=>[$target->{fid}],
                         parentobj=>[undef,'base::filemgmt']});
         my @fl=$fm->getHashList(qw(ALL));
         my $up="index.html";
         if (defined($target->{fid})){
            $up="../index.html" if ($p=~m/\/$/);
         }
         my $qparam="";
         $qparam="parentid=$target->{fid}" if (defined($target->{fid}));
         my $page="<table style=\"table-layout:fixed\" ".
                  "width=\"100%\" height=\"100%\" border=0 ".
                  "cellspacing=0 cellpadding=0>";
         $page.="<tr height=1%><td valign=top>$bar</td></tr>";
         my $fileicon="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_generic.gif\">".
                      "</div>";
         my $diricon ="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_dir.gif\">".
                      "</div>";
         my $diriconinherit ="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_diri.gif\">".
                      "</div>";
         my $topicon ="<div class=fileimage>".
                      "<img border=0 ".
                      "src=\"$prefix../../base/load/filemgmt_top.gif\">".
                      "</div>";
         my $list="<div id=filelist>";
         if ($p ne "/" && $p ne "/index.html" && $p ne ""){
            if (defined($target->{fid}) && $target->{inheritrights}){
               my $info=$self->T("inherit rights from parent directory"); 
               $list.="<div class=fileline>".
                      "<a class=filelink ".
                      "title=\"$info\" href=\"$up\">${diriconinherit}".
                      "<div class=filename>..</div></a></div>";
            }
            else{
               my $info=$self->T("no rights inherit from parent directory"); 
               $list.="<div class=fileline>".
                      "<a class=filelink ".
                      "title=\"$info\" href=\"$up\">${diricon}".
                      "<div class=filename>..</div></a></div>";
            }
         }
         else{
            $list.="<div class=fileline>".
                   "<div style=\"float:none;\">${topicon}</div>".
                   "<div class=filename>&nbsp;</div></a></div>";
         }
         foreach my $fl (sort({$a->{entrytyp} cmp $b->{entrytyp}} 
                              sort({$a->{name} cmp $b->{name}} @fl))){
            if ($self->isViewValid($fl)){
               my $post="";
               my $prefix="";
               $prefix="browser/" if ($p eq "");
               $post="/index.html" if ($fl->{entrytyp} eq "dir");
               my $codedname=quoteQueryString($fl->{name});
               my $img=$fileicon;
               $img=$diriconinherit if ($fl->{entrytyp} eq "dir" &&
                                        $fl->{inheritrights});
               $img=$diricon        if ($fl->{entrytyp} eq "dir" &&
                                        !$fl->{inheritrights});
               my $name="<div class=filename>$fl->{name}</div>";
               my $select="<div class=fileselect>";
               if ($op eq "delete"){
                  $select.="<input name=fid value=$fl->{fid} ".
                           "type=checkbox class=multiselect";
                  if (grep(/^$fl->{fid}$/,@oldval)){ 
                     $select.=" checked";
                  }
                  $select.=">";
               }
               $select.="</div>";
               my $userTZ=$self->UserTimezone();
               my $t=$self->ExpandTimeExpression($fl->{mdate},$self->Lang(),
                                                 "GMT",$userTZ).
                     " by $fl->{editor}";
               $list.=sprintf("<div class=fileline>$select<a class=filelink ".
                              "href=\"$prefix%s$post\" ".
                              "title=\"$t\">%s%s</a></div>\n",
                              $codedname,$img,$name);
            }
         }
         my $actionok=0;
         $actionok=1 if ($self->checkacl($target,"write"));
         $actionok=1 if ($self->IsMemberOf("admin"));
         $list.="</div>";
         $page.="<tr id=listtr><td id=listtd valign=top>$list</td>";
         $page.="</table>";
         $page.="<input id=OP type=hidden name=OP ".
                "value=\"".Query->Param("OP")."\">";
         $page.="</form></body>";
         my $LInherit=$self->T("parent rights: inherit");
         if (!$target->{inheritrights}){
            $LInherit=$self->T("parent rights: ignore");
         }
         my $LRefresh=$self->T("Refresh");
         my $LUploadFiles=$self->T("Upload files");
         my $LDeleteFiles=$self->T("Delete");
         my $LCreateDir=$self->T("Create directory");
         my $LChangeRights=$self->T("Modify rights");
         my $InheritLine="";
         if (defined($target->{fid}) && $self->IsMemberOf("admin")){
            $InheritLine='<li>'.
                         '<a class=action href="JavaScript:ChangeInherit()">'.
                         $LInherit.
                         '</a>';
         }
         $page.=<<EOF;
<div id=actionlist
     style="position:absolute;width:240px;
            right:0px;top:19px;display:none;visible:hidden">
<div class=actionlist>
<ul class=actionlist>
<li><a class=action href="JavaScript:Refresh()">$LRefresh</a>
<li><a class=action href="JavaScript:UploadFiles()">$LUploadFiles</a>
<li><a class=action href="JavaScript:DeleteFiles()">$LDeleteFiles</a>
<li><a class=action href="JavaScript:CreateDir()">$LCreateDir</a>
<li><a class=action href="JavaScript:ChangeRights()">$LChangeRights</a>
$InheritLine
<!--
<li><a class=action href="JavaScript:MoveFiles()">Move</a>
<li><a class=action href="JavaScript:Rename()">Rename</a><br><br>
<li><a class=action href="JavaScript:DirectoryInformations()">Directory Informations</a>
-->
</ul>
</div>
</div>
<script language="JavaScript">
var list=document.getElementById("filelist");
var listtd=document.getElementById("listtd");
var listtr=document.getElementById("listtr");
var action=document.getElementById("actionlist");
list.style.height=listtr.offsetHeight+"px";
list.style.overflow="auto";

if (document.location.href.match('^http[s]{0,1}://') && $actionok==1){
   list.style.width=(listtr.offsetWidth-200)+"px";
   action.style.visible="visible";
   action.style.display="block";
}

function Refresh()
{
   return(RestartApp());
}

function UploadFiles()
{
   showPopWin('$prefix../../base/filemgmt/WebUpload?$qparam',
              500,100,RestartApp);

}
function CreateDir()
{
   showPopWin('$prefix../../base/filemgmt/WebCreateDir?$qparam',
              500,100,RestartApp);

}
function ChangeRights()
{
   showPopWin('$prefix../../base/filemgmt/EditProcessor?'+
              'Field=acls&RefFromId=$target->{fid}',
              500,300,RestartApp);
}
function ChangeInherit()
{
   showPopWin('$prefix../../base/filemgmt/WebChangeInherit?$qparam',
              500,100,RestartApp);
}
function DeleteFiles()
{
   var op=document.getElementById("OP");
   op.value="delete";
   document.forms[0].submit();

}

function RestartApp(returnVal,isbreak)
{
   if (!isbreak){
      document.location.href=document.location.href;
   }
}
</script>
EOF
         $page.="</html>";
         print $header.$page;
      }
   }
   else{
      print("Status: 404 Not Found\n");
      print($header);
      print("<div class=message>"); 
      printf($self->T("ERROR: the requested path '%s' does not exists"),$p);
      print("</div>"); 
   }
}

sub FindTarget
{
   my $self=shift;
   my $p=shift;
   my $entrytyp=shift;
   $p=~s/^\///;
   my @param=split(/\//,$p);

   $entrytyp=\"dir" if (!defined($entrytyp));
  
   my $rec={}; 
   my $parentid=undef;

   return({fid=>undef,entrytyp=>'dir'}) if ($#param==-1);

   while(my $dir=shift(@param)){
      $self->ResetFilter();
      $self->SetFilter({parentid=>[$parentid],name=>\$dir,entrytyp=>$entrytyp,
                        parentobj=>[undef,'base::filemgmt']});
      my ($currec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (!defined($currec)){
         return(undef);
      }
      $rec=$currec;
      $parentid=$rec->{fid};
   }

   return($rec);
}


sub WebRefresh
{
   my $self=shift;

}

sub WebChangeInherit
{
   my $self=shift;
   my $parentid=Query->Param("parentid");

   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              form=>1,multipart=>1,
                              js=>['toolbox.js','subModal.js'],
                              onload=>'initOnLoad();',
                              title=>$self->T("WebFS: Change rights inherit"));
   $header.=<<EOF;
<script language="JavaScript">
function initOnLoad()
{
   var o=document.getElementsByName("do");
   if (o){
      o[0].focus();
   }
   addFunctionKeyHandler(document.forms[0],
      function(e){
         if (e.keyCode == 27) {
            parent.hidePopWin(false);
            return(false);
         }
         return(true);
      }
   );
}
</script>
EOF

   $self->ResetFilter();
   $self->SetFilter({fid=>\$parentid});
   my ($rec)=$self->getOnlyFirst(qw(ALL));
   if (defined($rec) && $self->IsMemberOf("admin")){
      my $option="";
      $option.="<input type=radio name='inherit' value='1'";
      if ($rec->{inheritrights}){
         $option.=" checked";
      }
      $option.=">".$self->T("yes"); 

      $option.="<input type=radio name='inherit' value='0'";
      if (!$rec->{inheritrights}){
         $option.=" checked";
      }
      $option.=">".$self->T("no"); 
      my $msg;
      my $js="";
      if (Query->Param("do")){
         my %q=();
         $q{parentid}=Query->Param("parentid");
         my $inherit="0";
         if (Query->Param("inherit") eq "1"){
            $inherit="1";
         }
         if ($self->ValidatedUpdateRecord($rec,{inheritrights=>$inherit},
                                           {fid=>\$parentid})){
            $msg="<font color=green>OK</font>";
            $js="<script language=\"JavaScript\">parent.RestartApp()</script>";
         }
         else{
            $msg="<font color=red>".join("",$self->LastMsg())."</font>";
         }
      }
      print $header;

      

      print("<table width=\"100%\" style=\"table-layout:fixed\" ".
            "height=100% border=0>");
      print("<tr><td colspan=2 valign=left align=center>".
            $self->T("Inherit rights from parent directory").
            ": ".$option."</td></tr>");


      print("<tr><td colspan=2 valign=center align=center>".
            "<input type=submit name=do style=\"width:200px\" ".
            "value=\"".$self->T("save")."\"></td></tr>");
      printf("<tr height=1%><td colspan=2 nowrap>".
             "<div class=LastMsg style=\"overflow:hidden\">%s&nbsp;</div>".
             "</td></tr>",$msg);
      print("</table>$js");
      print($self->HtmlPersistentVariables(qw(parentid)));
      print("</form></body></html>");
   }
}

sub WebUpload
{
   my $self=shift;
   my $parentid=Query->Param("parentid");

   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              form=>1,multipart=>1,
                              js=>['toolbox.js','subModal.js'],
                              title=>"WebFS: File-Upload");
   my $msg;
   my $js="";
   if (Query->Param("do")){
      my %q=();
      $q{file}=Query->Param("file");
      $q{parentid}=Query->Param("parentid");
      if ($self->ValidatedInsertRecord(\%q)){
         $msg="<font color=green>OK</font>";
         $js="<script language=\"JavaScript\">parent.RestartApp()</script>";
      }
      else{
         $msg="<font color=red>".join("",$self->LastMsg())."</font>";
      }
   }
   print $header;
   print("<table width=\"100%\" style=\"table-layout:fixed\" ".
         "height=100% border=0>");
   print("<tr height=1%><td width=50>Datei:</td>");
   print("<td><input size=40 type=file name=file></td></tr>");
   print("<tr><td colspan=2 valign=center align=center>".
         "<input type=submit name=do style=\"width:200px\" ".
         "value=\"Upload\"></td></tr>");
   printf("<tr height=1%><td colspan=2 nowrap>".
          "<div class=LastMsg style=\"overflow:hidden\">%s&nbsp;</div>".
          "</td></tr>",$msg);
   print("</table>$js");
   print($self->HtmlPersistentVariables(qw(parentid)));
   print("</form></body></html>");
}

sub WebCreateDir
{
   my $self=shift;
   my $parentid=Query->Param("parentid");


   my $header=$self->HttpHeader("text/html");
   $header.=$self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'kernel.filemgmt.css',
                                      'kernel.filemgmt.browser.css'],
                              form=>1,multipart=>1,
                              js=>['toolbox.js','subModal.js'],
                              title=>"WebFS: Dir-Create");
   my $msg;
   my $js="";
   if (Query->Param("do")){
      my %q=();
      $q{entrytyp}='dir';
      $q{name}=Query->Param("name");
      if (defined(Query->Param("parentid"))&&
          Query->Param("parentid") ne ""){
         $q{parentid}=Query->Param("parentid");
      }
      if ($self->ValidatedInsertRecord(\%q)){
         $msg="<font color=green>OK</font>";
         $js="<script language=\"JavaScript\">parent.RestartApp()</script>";
      }
      else{
         $msg="<font color=red>".join("",$self->LastMsg())."</font>";
      }
   }
   print $header;
   my $ct=$self->T("Create directory");
   my $d=<<EOF;
<table width="100%" style="table-layout:fixed" height="100%" border=0>
<tr height="1%"><td width=120>Verzeichnisname:</td>
<td><input size=55 type=text name=name></td></tr>
<tr><td colspan=2 valign=center align=center>
<input type=submit name=do style="width:200px" value="$ct"></td></tr>
<tr height=1%><td colspan=2>${msg}&nbsp;</td></tr>
</table>
$js
<script language="JavaScript">
setEnterSubmit(document.forms[0],"do");
setFocus("name");
</script>
EOF
   print($d.$self->HtmlPersistentVariables(qw(parentid)));
   print("</form></body></html>");
}

sub WebDAV
{
   my $self=shift;
   printf("Content-Type: text/xml\n\n".
          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
   print <<EOF if ($ENV{REQUEST_URI} eq "/WebDAV");
<D:multistatus xmlns:D="DAV:">

<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
<D:href>/WebDAV/</D:href>
<D:propstat>
<D:prop>
<lp1:resourcetype><D:collection/></lp1:resourcetype>
<D:getcontenttype>httpd/unix-directory</D:getcontenttype>
</D:prop>
<D:status>HTTP/1.1 200 OK</D:status>
</D:propstat>
</D:response>
</D:multistatus>
EOF


#
#   print(<<EOF);
#<?xml version="1.0" encoding="UTF-8"?>
#<D:multistatus xmlns:D="DAV:">
#
#<D:response xmlns:lp1="DAV:" xmlns:lp2="http://apache.org/dav/props/">
#  <D:href>/lenya/blog/authoring/entries/2003/08/24/peanuts/</D:href>
#  <D:propstat>
#    <D:prop>
#      <lp1:resourcetype>
#          <D:collection/>
#      </lp1:resourcetype>
#      <D:getcontenttype>httpd/unix-directory</D:getcontenttype>
#    </D:prop>
#    <D:status>HTTP/1.1 200 OK</D:status>
#  </D:propstat>
#</D:response>
#
#</D:multistatus>
#EOF
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/filefolder.jpg?".$cgi->query_string());
}

sub isAnonymousAccessValid
{
    my $self=shift;
    return(1) if ($_[0] eq "load");
    return($self->SUPER::isAnonymousAccessValid(@_));
}





1;
