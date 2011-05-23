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
                dataobjattr   =>'infoabo.id'),

      new kernel::Field::Select(
                name          =>'parentobj',
                label         =>'Info Source',
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
                label         =>'Target-Name',
                uploadable    =>0,
                dst           =>[],
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
                searchable    =>0,
                label         =>'Info Mode',
                readonly      =>1,
                htmleditwidth =>'100%',
                getPostibleValues=>\&getPostibleModes,
                dataobjattr   =>'infoabo.mode'),

      new kernel::Field::TextDrop(
                name          =>'user',
                label         =>'User',
                group         =>'relation',
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
                name          =>'usercistatus',
                htmleditwidth =>'40%',
                group         =>'relation',
                readonly      =>'1',
                label         =>'User CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['usercistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'usercistatusid',
                group         =>'relation',
                label         =>'User CI-StateID',
                dataobjattr   =>'contact.cistatus'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                readonly      =>1,
                dataobjattr   =>'contact.email'),

      new kernel::Field::Select(
                name          =>'active',
                label         =>'Active',
                transprefix   =>'boolean.',
                value         =>[1,0],
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
                label         =>'parent object',
                dataobjattr   =>'infoabo.parentobj'),

      new kernel::Field::Text(
                name          =>'refid',
                searchable    =>0,
                group         =>'relation',
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
                group         =>'relation',
                readonly      =>sub{
                      my $self=shift;
                      my $rec=shift;
                      return(0) if (!defined($rec));
                      return(1);
                },
                dataobjattr   =>'infoabo.mode'),


      new kernel::Field::Text(
                name          =>'userid',
                label         =>'W5Base UserID',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'infoabo.userid'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'infoabo.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
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
                dataobjattr   =>'infoabo.expiration'),
                                                 
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'infoabo.editor'),
                                                 
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'infoabo.realeditor'),
   );
   $self->setDefaultView(qw(parentobj targetname mode user active));
   $self->setWorktable("infoabo");
   $self->LoadSubObjs("ext/infoabo","infoabo");
   $self->LoadSubObjs("ext/staticinfoabo","staticinfoabo");
   $self->{admwrite}=[qw(admin w5base.base.infoabo.write)]; 
   $self->{admread}=[@{$self->{admwrite}},"w5base.base.infoabo.read"];
   $self->{history}=[qw(insert modify delete)];


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
   return(qw(header default relation source));
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
   
   if (!$self->IsMemberOf($self->{admread},"RMember")){
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {userid=>\$userid},
                ]);
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

   foreach my $obj (values(%{$app->{infoabo}})){
      my ($ctrl)=$obj->getControlData($self);
      foreach my $obj (keys(%$ctrl)){
         push(@opt,$obj,$app->T($obj,$obj));
      }
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

   my $mode=effVal($oldrec,$newrec,"mode");
   if ($mode eq "" && !defined($oldrec) && $newrec->{rawmode} eq ""){
      $self->LastMsg(ERROR,"invalid mode specified");
      return(0);
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $parent=effVal($oldrec,$newrec,"parent");
   if ($parentobj eq "" && $parent eq ""){
      $self->LastMsg(ERROR,"invalid parentobj specified");
      return(0);
   }
   
   if (!$self->IsMemberOf($self->{admwrite},"RMember")){
      my $curuserid=$self->getCurrentUserId();
      my $userid=effVal($oldrec,$newrec,"userid");
      if ($userid eq ""){
         $self->LastMsg(ERROR,"invalid userid specified");
         return(0);
      }
   }

   return(1);
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
         $d.=$self->T("Are you sure, you want to inactivate the shown InfoAbos?");
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
   return("header","default","relation") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (ref($rec) eq "HASH" &&
                         $self->getCurrentUserId() eq $rec->{userid});
   return("default","relation") if ($self->isInfoAboAdmin());
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

   my $c=0;
   if (!defined($userlist)){
      $self->ResetFilter();
      $self->SetFilter({refid=>$refid,rawmode=>$mode,
                        usercistatusid=>"<=5",
                        parent=>$parent,
                        active=>\'1'});
      foreach my $rec ($self->getHashList(qw(email))){
         next if ($rec->{email} eq ""); # ensure entries are filtered, if the
                                        # contact entry has been deleted
         if (!defined($desthash->{lc($rec->{email})})){
            $desthash->{lc($rec->{email})}=[];
         }
         push(@{$desthash->{lc($rec->{email})}},$rec->{id});
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
         next if ($rec->{usercistatusid} eq ""); # ensure entries 
                                        # are filtered, if the
                                        # contact entry has NOT been deleted
         @{$userlist}=grep(!/^$rec->{userid}$/,@{$userlist}); 
         if ($rec->{email} ne ""){
            if ($rec->{active} && $rec->{usercistatusid}<=5){
               if (!defined($desthash->{lc($rec->{email})})){
                  $desthash->{lc($rec->{email})}=[];
               }
               push(@{$desthash->{lc($rec->{email})}},$rec->{id});
               $c++;
            }
         }
      }
      my %u=();
      map({$u{$_}=1;} @$userlist);
      @$userlist=keys(%u);
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
                  $self->ValidatedInsertRecord($rec);
               }
               else{
                  msg(ERROR,"try to insert infoabo for invalid '$userid'");
               }
            }
         #}
         $self->ResetFilter();
         $self->SetFilter({refid=>$refid,mode=>$mode,active=>\'1',
                           parent=>$parent,userid=>$userlist});
         foreach my $rec ($self->getHashList(qw(email))){
            if (!defined($desthash->{lc($rec->{email})})){
               $desthash->{lc($rec->{email})}=[];
            }
            push(@{$desthash->{lc($rec->{email})}},$rec->{id});
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
   if (defined($curobj) && defined($curmode) && defined($curid) &&
       $curobj ne "" && $curmode ne "" && $curid ne ""){
      $self->ResetFilter();
      $self->SetFilter({refid=>\$curid,parentobj=>\$curobj,
                        mode=>\$curmode,userid=>\$userid});
      my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));
      if (Query->Param("ADD")){
         if (defined($rec)){
            $self->ValidatedUpdateRecord($rec,{active=>1},{id=>\$rec->{id}});
         }
         else{
            $self->ValidatedInsertRecord({refid=>$curid,parentobj=>$curobj,
                                          active=>1,
                                          mode=>$curmode,userid=>$userid});
         }
      }
      if (Query->Param("DEL")){
         if (defined($rec)){
            $self->ValidatedUpdateRecord($rec,{active=>0},{id=>\$rec->{id}});
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
   #printf STDERR ("fifi flt=%s\n",Dumper(\@flt));
   $self->ResetFilter();
   $self->SetFilter(\@flt);
   my @cur=$self->getHashList(qw(parentobj refid active mode));
   #printf STDERR ("fifi cur=%s\n",Dumper(\@cur));

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
   }
   my $optionlist="";
   while(defined(my $obj=shift(@oplist))){
      my $id=shift(@oplist);
      my $label=shift(@oplist);
      my @ml;
      if ($obj eq "base::staticinfoabo"){
         my $st=getModuleObject($self->Config,"base::staticinfoabo");
         foreach my $rec ($st->getHashList(qw(id name fullname))){
            push(@ml,$rec->{name}.";".$rec->{id});
            push(@ml,$rec->{fullname});
         }
      }
      else{
         @ml=$self->getModesFor($obj);
      }
      my $objlabel=$self->T($obj,$obj);
      $objlabel.=": ".$label if ($label ne "");
      
      $optionlist.="<optgroup label=\"$objlabel\">";
      while(defined(my $mode=shift(@ml))){
         my $modelabel=shift(@ml);
         my $key="$obj;$mode";
         $key.=";$id" if (defined($id) && $id ne "");
         my ($akobj,$akmode,$akid)=split(/;/,$key);
         my $st=isAboActiv(\@cur,$akobj,$akmode,$akid);
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
        style="width:570px;height:100%;overflow:hidden">
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

   return($self->IsMemberOf($self->{admwrite}));

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
