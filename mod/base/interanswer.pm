package base::interanswer;
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
use kernel::InterviewField;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::InterviewField);

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
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'AnswerID',
                dataobjattr   =>'interanswer.id'),

      new kernel::Field::TextDrop(
                name          =>'name',
                label         =>'question',
                readonly      =>1,
                vjointo       =>'base::interview',
                vjoinon       =>['interviewid'=>'id'],
                vjoindisp     =>'name',
                depend        =>['name_label','name_de','name_en'],
                searchable    =>0,
                onRawValue    =>\&getQuestionText),

      new kernel::Field::TextDrop(
                name          =>'name_en',
                label         =>'Question (en-default)',
                translation   =>'base::interview',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'interview.name'),

      new kernel::Field::TextDrop(
                name          =>'name_de',
                label         =>'Question (de)',
                translation   =>'base::interview',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'interview.name_de'),

      new kernel::Field::Textarea(
                name          =>'name_label',
                label         =>'Label (multilang)',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'interview.frontlabel'),

      new kernel::Field::Boolean(
                name          =>'relevant',
                markempty     =>1,
                label         =>'Relevant',
                dataobjattr   =>'interanswer.relevant'),

      new kernel::Field::Text(
                name          =>'name_cistatus',
                label         =>'Question cistatus',
                htmldetail    =>0,
                vjointo       =>'base::interview',
                vjoinon       =>['interviewid'=>'id'],
                vjoindisp     =>'cistatus'),

      new kernel::Field::Text(
                name          =>'answer',
                label         =>'answer',
                dataobjattr   =>'interanswer.answer'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'relation',
                uploadable    =>0,
                label         =>'parent Object',
                dataobjattr   =>'interanswer.parentobj'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'relation',
                uploadable    =>0,
                label         =>'parent ID',
                dataobjattr   =>'interanswer.parentid'),

      new kernel::Field::TextDrop(
                name          =>'qtag',
                label         =>'unique query tag',
                group         =>'qrelation',
                vjointo       =>'base::interview',
                vjoinon       =>['interviewid'=>'id'],
                vjoindisp     =>'qtag',
                dataobjattr   =>'interview.qtag'),

      new kernel::Field::Interface(
                name          =>'interviewid',
                group         =>'relation',
                uploadable    =>0,
                searchable    =>0,
                group         =>'qrelation',
                label         =>'Interview ID',
                dataobjattr   =>'interanswer.interviewid'),

      new kernel::Field::Interface(
                name          =>'interviewcatid',
                label         =>'Interview category id',
                group         =>'qrelation',
                dataobjattr   =>'interview.interviewcat'),

      new kernel::Field::TextDrop(
                name          =>'interviewcat',
                label         =>'Interview categorie',
                vjointo       =>'base::interviewcat',
                group         =>'qrelation',
                readonly      =>1,
                uploadable    =>0,
                vjoinon       =>['interviewcatid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'questclust',
                label         =>'Questiongroup',
                readonly      =>1,
                group         =>'qrelation',
                dataobjattr   =>'interview.questclust'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'interanswer.comments'),

      new kernel::Field::Percent(
                name          =>'answerlevel',
                label         =>'Answer level',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>
                   'if (ADDDATE(interanswer.lastverify,'.
                       'interview.necessverifyinterv)<'.
                       'now(),0, '.
                   'if (interanswer.answer is null '.
                   'or interanswer.answer="",0,'.
                   'CASE interview.questtyp '.
                   ' WHEN "percent"  THEN interanswer.answer '.
                   ' WHEN "percent4" THEN interanswer.answer '.
                   ' WHEN "percenta" THEN if (interanswer.answer<>"" and '.
                                             'interanswer.answer>0,100,0) '.
                   ' WHEN "text"     THEN if (interanswer.answer<>"",100,0) '.
                   ' WHEN "date"     THEN if (interanswer.answer<>"",100,0) '.
                   ' WHEN "select"   THEN if (interanswer.answer<>"",100,0) '.
                   ' WHEN "boolean"  THEN if (interanswer.answer="1",100,0) '.
                   ' WHEN "booleana" THEN if (interanswer.answer="0" or '.
                                             'interanswer.answer="1",100,0) '.
                   ' ELSE "0" '.
                   'END'.
                   '))'),

      new kernel::Field::Text(
                name          =>'archiv',
                group         =>'archiv',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Archiv',
                dataobjattr   =>'interanswer.archiv'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'interanswer.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'interanswer.modifydate'),

      new kernel::Field::Date(
                name          =>'lastverify',
                group         =>'source',
                label         =>'last verify of anser',
                dataobjattr   =>'interanswer.lastverify'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                uivisible     =>0, 
                label         =>'primary sync key',
                dataobjattr   =>"interanswer.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                uivisible     =>0, 
                label         =>'secondary sync key',
                dataobjattr   =>"interanswer.id"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'interanswer.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'interanswer.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'interanswer.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'interanswer.realeditor'),

   );
   $self->{use_distinct}=0;
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(mdate parentobj parentid name relevant answer));
   $self->setWorktable("interanswer");
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_name_cistatus"))){
     Query->Param("search_name_cistatus"=>
                  "\"".$self->T("CI-Status(4)","base::cistatus")."\"");
   }
}


sub prepUploadRecord
{
   my $self=shift;
   my $newrec=shift;

   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   
   if (!exists($newrec->{$idname}) || $newrec->{$idname} eq ""){
      if (exists($newrec->{qtag}) && $newrec->{qtag} ne "" &&
          exists($newrec->{parentname}) && $newrec->{parentname} ne ""){
         my $fobj=$self->getField("parentname");
         if (defined($fobj)){
            my $i=$self->Clone();
            $i->SetFilter({qtag=>\$newrec->{qtag},
                           parentname=>\$newrec->{parentname}});
            my ($rec,$msg)=$i->getOnlyFirst($idname);
            if (defined($rec)){
               $newrec->{$idname}=$rec->{$idname};
               delete($newrec->{qtag});
               delete($newrec->{parentname});
            }
         }
      }
   }

   return(1);
}


sub getQuestionText
{
   my $self=shift;
   my $current=shift;
   my $lang=$self->getParent->Lang();

   if ($current->{'name_label'} ne ""){
      return(extractLangEntry($current->{'name_label'},$lang,80,0));
   }
   if ($lang eq "de" && $current->{'name_de'} ne ""){
      return($current->{'name_de'});
   }
   if ($current->{'name_en'} eq ""){
      return($current->{'name_de'});
   }
   return($current->{'name_en'});
}



sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("base::interanswer");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/interanswer.jpg?".$cgi->query_string());
}




sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $i=getModuleObject($self->Config,"base::interview");

   my $fobj=$self->getField("parentname");
   if (defined($fobj)){
      my $rec={};
      my $comprec={};
      my $rawWrRequest=$fobj->Validate($oldrec,$newrec,$rec,$comprec);
      if (defined($rawWrRequest)){
         foreach my $k (keys(%{$rawWrRequest})){
            $newrec->{$k}=$rawWrRequest->{$k};
         }
         delete($newrec->{parentname});
      }
   }
   my $qid=effVal($oldrec,$newrec,"interviewid");
   if ($qid eq ""){
      my $qtag=effVal($oldrec,$newrec,"qtag");
      if ($qtag ne ""){
         $i->SetFilter({qtag=>\$qtag});
         my ($irec,$msg)=$i->getOnlyFirst(qw(id)); 
         if (defined($irec)){
            delete($newrec->{qtag});
            $newrec->{interviewid}=$irec->{id};
         }
      }
   }

   if (defined($oldrec)){
      foreach my $k (keys(%{$newrec})){
         next if ($k eq "comments" ||
                  $k eq "answer"   ||
                  $k eq "relevant");
         delete($newrec->{$k});
      }
   }
   my $parentobj=effVal($oldrec,$newrec,"parentobj");
   my $parentid=effVal($oldrec,$newrec,"parentid");
   my $qid=effVal($oldrec,$newrec,"interviewid");
   if ($parentid eq ""){
      $self->LastMsg(ERROR,"invalid parentid"); 
      return(0);
   }
   if ($qid eq ""){
      $self->LastMsg(ERROR,"invalid question id"); 
      return(0);
   }
   my ($write,$irec)=$self->getAnswerWriteState($i,$qid,$parentid,$parentobj);
   #printf STDERR ("parentobj=$parentobj parentid=$parentid qid=$qid SecureValidate=%s\n",Dumper($newrec));
   if (!$write){
      $self->LastMsg(ERROR,"insuficient rights to answer this question"); 
      return(0);
   }
   if (!defined($oldrec)){
      if ($newrec->{parentobj} eq ""){ 
         $newrec->{parentobj}=$irec->{parentobj};
      }
      if ($irec->{parentobj} ne $newrec->{parentobj}){
         $self->LastMsg(ERROR,"parentobj doesn't macht question parentobj"); 
         return(0); 
      }
   }

   return(1);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return("") if ($mode eq "delete");
   return("") if ($mode eq "insert");
   return("") if ($mode eq "update");
   my $where="";
   if ($self->{secparentobj} ne ""){
      $where="(interanswer.parentobj='$self->{secparentobj}' or ".
             "interanswer.parentobj is null)";
   }
   return($where);
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) && !defined($newrec->{archiv})){
      $newrec->{archiv}="";
   }
   if (!defined($oldrec) ||
       !exists($newrec->{lastverify})){
      $newrec->{lastverify}=NowStamp("en");
   }
#   my $name=trim(effVal($oldrec,$newrec,"name"));
#   if ($name=~m/^\s*$/i){
#      $self->LastMsg(ERROR,"invalid question specified"); 
#      return(undef);
#   }
#   my $questclust=trim(effVal($oldrec,$newrec,"questclust"));
#   if ($questclust=~m/^\s*$/i){
#      $self->LastMsg(ERROR,"invalid question group specified"); 
#      return(undef);
#   }
   return(1);
}




sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable left outer join interview ".
          "on $worktable.interviewid=interview.id ");
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   #return("ALL") if ($self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec)){
      my $parentobj=$rec->{parentobj};
      my $parentid=$rec->{parentid};
      my $qid=$rec->{interviewid};
      my $i=getModuleObject($self->Config,"base::interview");
      my ($write,$irec,$oldans)=
                       $self->getAnswerWriteState($i,$qid,$parentid,$parentobj);

      return("default") if ($write);
      return("default") if ($self->IsMemberOf("admin"));
      return(undef);
   }
   return("default","relation");
}

sub getAnswerWriteState
{
   my $self=shift;
   my $i=shift;
   my $qid=shift;
   my $parentid=shift;
   my $parentobj=shift;
   my $contextCache=shift;

   $i->ResetFilter();
   my $idfield=$i->IdField();
   if (!defined($idfield)){
      msg(ERROR,"havy error - no IdField in $i");
      exit(1);
   }
   my $idname=$idfield->Name();
   $i->SetFilter({$idname=>\$qid});
   my ($irec,$msg)=$i->getOnlyFirst(qw(ALL));
   if ($parentobj eq ""){
      $parentobj=$irec->{parentobj};
   }

   $self->ResetFilter();
   $self->SetFilter({interviewid=>\$qid,
                     parentobj=>\$parentobj,
                     parentid=>\$parentid});
   my ($oldrec,$msg)=$self->getOnlyFirst(qw(ALL));

   my $p=getModuleObject($self->Config,$parentobj);
   return(0,$irec,$oldrec,undef) if (!defined($p));

   my $idfield=$p->IdField();
   if (!defined($idfield)){
      msg(ERROR,"havy error - no IdField in $i");
      exit(1);
   }
   my $idname=$idfield->Name();

   $p->SetFilter({$idname=>\$parentid});
   my ($rec,$msg)=$p->getOnlyFirst(qw(ALL));
   my $pwrite=$i->checkParentWrite($p,$rec);
   my $write=$i->checkAnserWrite($pwrite,$irec,$p,$rec);

   my %boundpviewgroupAcl=$p->InterviewPartners($rec);

   if (!$write){
      my $userid=$self->getCurrentUserId();
      my $tag=$irec->{boundpcontact}."";
      if (exists($boundpviewgroupAcl{$tag}) &&
          in_array($boundpviewgroupAcl{$tag},$userid)){
         $write++;
      }
   }

   return($write,$irec,$oldrec,$rec);
}

sub Store
{
   my $self=shift;
   my $parentid=Query->Param("parentid");
   my $parentobj=Query->Param("parentobj");
   my $qid=Query->Param("qid");
   my $vname=Query->Param("vname");
   my $vval=Query->Param("vval");
   $vval=UTF8toLatin1($vval);

   my $i=getModuleObject($self->Config,"base::interview");
   #printf STDERR ("\n\nAjaxStore: qid=$qid parentid=$parentid ".
   #               "parentobj=$parentobj vname=$vname\nval=$vval\n\n");

   my ($write,$irec,$oldrec)=$self->getAnswerWriteState($i,$qid,
                                                        $parentid,$parentobj);
   if ($vname eq "comments" || $vname eq "answer" || 
       $vname eq "relevant" || $vname eq "lastverify"){
      if ($write){
         if ($vname eq "lastverify"){
            $vval=NowStamp("en");
         }
         my %d=($vname=>$vval);
         if ($vname eq "relevant" && $vval==0){
            $d{'answer'}="";
         }
         if (!defined($oldrec)){
            $self->ValidatedInsertRecord({%d,
                                          parentobj=>$parentobj,
                                          parentid=>$parentid,
                                          interviewid=>$qid});
         }
         else{
            $self->ValidatedUpdateRecord($oldrec,{%d},
                                         {id=>\$oldrec->{id}});
         }
      }
   }
   $self->SetFilter({interviewid=>\$qid,
                     parentobj=>\$parentobj,
                     parentid=>\$parentid});
   my ($newrec,$msg)=$self->getOnlyFirst(qw(answer comments lastverify 
                                            relevant));

   my ($HTMLanswer,$HTMLrelevant,$HTMLcomments,$HTMLVerifyButton,$HTMLjs)=
         $i->getHtmlEditElements($write,$irec,$newrec);

   $newrec->{HTMLanswer}=$HTMLanswer;
   $newrec->{HTMLrelevant}=$HTMLrelevant;
   $newrec->{HTMLverify}=$HTMLVerifyButton;
   $newrec->{HTMLcomments}=$HTMLcomments;
   $newrec->{HTMLjs}=$HTMLjs;
   
   print $self->HttpHeader("text/xml");
   my $res=hash2xml({document=>{result=>'ok',
                     interanswer=>$newrec,exitcode=>0}},{header=>1});
   print $res;
   #print STDERR $res;
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin")){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  [$self->orgRoles()],"direct");
      my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");

      $lnkgrp->SetFilter({grpid=>[keys(%grps)]});
      my $d=$lnkgrp->getHashIndexed(qw(userid));
      my @user;
      push(@user,keys(%{$d->{userid}})) if (ref($d->{userid}) eq "HASH");
      my $userid=$self->getCurrentUserId();
      push(@user,$userid) if ($userid ne "");
      if ($#user==-1){
         push(@user,-99);
      }
      my @secflt=({owner=>\@user});    # only answers from me or my team
      @secflt=();

      my $i=getModuleObject($self->Config,"base::interview");
      $i->SecureSetFilter({});  # all categories i can see
      my @iid=$i->getVal("id");
      if ($#iid!=-1){
         push(@secflt,{interviewid=>\@iid});
      }

      push(@flt,\@secflt);
   }
   return($self->SetFilter(@flt));
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","relation","qrelation","source");
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(Store));
}






#sub getAnalytics
#{
#   my $self=shift;
#   return('Analytics'=>$self->T('Analytics','kernel::App::Web'));
#}
#
#
#
#sub collectAnalyticsDataObjects
#{
#   my $self=shift;
#   my $q=shift;
#
#   my $parentobj=getModuleObject($self->Config,$self->{secparentobj});
#   my $pidname=$parentobj->IdField->Name();
#
#   $self->ResetFilter();
#   $self->SecureSetFilter($q);
#   $self->SetCurrentView(qw(parentid));
#   my $i=$self->getHashIndexed("parentid");
#
#   my $interview=getModuleObject($self->Config,"base::interview");
#   $interview->SetFilter({parentobj=>\$self->{secparentobj}});
#   $interview->SetCurrentView(qw(interviewcatid));
#   my $ic=$interview->getHashIndexed("interviewcatid");
#
#   if ($self->LastMsg()>0){
#      return();
#   }
#   my @dataobj=({name=>'ianswers',
#                 dataobj=>$self,
#                 view   =>[qw(parentid cdate mdate interviewcatid
#                              qtag answer relevant)]},
#                {name=>'interview',
#                 dataobj=>$interview,
#                 view=>[qw(name id interviewcatid)]},
#                {name=>'interviewcat',
#                 dataobj=>getModuleObject($self->Config,"base::interviewcat"),
#                 filter=>{id=>[keys(%{$ic->{interviewcatid}})]},
#                 view=>[qw(name id fullname)]},
#                {name=>'iparent',
#                 dataobj=>$parentobj,
#                 filter=>{$pidname=>[keys(%{$i->{parentid}})]},
#                 view=>[$pidname,@{$self->{analyticview}}]
#                }
#                );
#   return(dataobj=>\@dataobj,
#          js=>[qw(jquery.js jquery.layout.js sprintf.js 
#                  analytics.js)],
#          css=>[qw(base/css/default.css 
#                   base/css/work.css 
#                   base/css/jquery.layout.css)],
#          menu=>['m1'=>{label=>'einfache Analyse der Antwortenanzahl',
#                        js=>"AnalyticsQCount({base:'',key:'fullname'});"},
#                 'm2'=>{label=>'Erreichungsgrad analyse',
#                        js=>"AnalyticsGoal({base:'',key:'fullname'});"}]
#         );
#
#}
#
#sub Analytics
#{
#   my $self=shift;
#   my %param;
#
#   $self->doFrontendInitialize();
#   printf("Content-Type: text/html; charset=UTF-8\n\n");
#
#   my $d="<html>";
#   $d.="<head>";
#
#
#   if ($self->validateSearchQuery()){
#      my %q=$self->getSearchHash();
#      my %ctl=$self->collectAnalyticsDataObjects(\%q);
#
#      $self->AnalyticsSendData({},$ctl{dataobj});
#
#      if (0){
#         $d.="<script type='text/javascript' ";
#         $d.="src='http://getfirebug.com/releases/lite/1.2/".
#             "firebug-lite-compressed.js'>";
#         $d.="</script>";
#      }
#      if (ref($ctl{js}) eq "ARRAY"){
#         foreach my $js (@{$ctl{js}}){
#            my $instdir=$self->Config->Param("INSTDIR");
#            my $filename=$instdir."/lib/javascript/".$js;
#            if (open(F,"<$filename")){
#               $d.="<script language=\"JavaScript\">\n";
#               $d.=join("",<F>);;
#               $d.="</script>\n";
#               close(F);
#            }
#         }
#      }
#      if (ref($ctl{css}) eq "ARRAY"){
#         foreach my $css (@{$ctl{css}}){
#            my $filename=$self->getSkinFile($css);
#            if (open(F,"<$filename")){
#               $d.="<style>\n";
#               $d.=join("",<F>);;
#               $d.="</style>\n";
#               close(F);
#            }
#         }
#      }
#
#   $d.=<<EOF;
#<style type="text/css">
#   html, body {
#      width:      100%;
#      height:     100%;
#      padding: 0;
#      margin:     0;
#      overflow:   hidden;
#   }
#   #container{
#      width:      100%;
#      height:     100%;
#      padding: 0;
#      margin:     0 auto;
#   }
#   .ui-layout-pane{
#       xpadding:3px;
#       margin:0px;
#       padding:0px;
#   }
#   ul{
#      margin:0px;
#      padding:0px;
#      padding-left:15px;
#   }
#   li{
#      margin-top:5px;
#   }
#   .header{
#      border-bottom-style:solid;
#      border-width:1px;
#      border-color:black;
#      background:gainsboro;
#      font-weight:bold;
#      text-align:center;
#      postion: absoulte;
#      margin:0;
#      padding:2px;
#   }
#   .sublink{
#      cursor: pointer;
#   }
#   #outpane{
#      padding:5px;
#   }
#   #outheader{
#      padding-bottom:2px;
#      font-weight:bold;
#   }
#   table.analysedata{
#      width:100%;border-collapse:collapse;
#   }
#   table.analysedata tr th.desc{
#      text-align:center;
#      border-bottom-style:solid;
#      border-bottom-color:black;
#   }
#   table.analysedata tr th{
#      text-align:left;
#   }
#   table.analysedata tr{
#      border-bottom-style:solid;
#      border-bottom-color:silver;
#      border-bottom-width:1px;
#   }
#</style>
#EOF
#
#
#
#      $d.="</head><body>";
#$d.=<<EOF;
#<div id="container">
#   <div id="outpane" class="pane ui-layout-center">
#      <div id="outheader"></div>
#      <div id="out">[ select your analyse ]</div>
#   </div>
#   <div class="pane ui-layout-west">
#<div class="header">Analyseverfahren</div>
#<ul>
#EOF
#   my @m=@{$ctl{'menu'}};
#   while(my $key=shift(@m)){
#      my $m=shift(@m);
#      $d.="<li><span id=\"$key\" class=sublink onclick=\"".$m->{js}."\">".
#          $m->{label}."</span></li>";
#   }
#$d.=<<EOF;
#</ul>
#</div>
#</div>
#
#   <script type="text/javascript">
#
#   \$(document).ready(function () {
#      var l=\$('#container').layout({
#      });
#   });
#
#   </script>
#
#
#
#
#EOF
#      print $d;
#   }
#   else{
#      printf("problem\n");
#   }
#
#
#   print("</body></html>");
#}

#sub AnalyticsSendData
#{
#   my $self=shift;
#   my $param=shift;
#   my $data=shift;
#   my %param=%$param;
#
#   foreach my $d (@$data){
#      my $dataobj=$d->{dataobj};
#      my $output=new kernel::Output($dataobj);
#      if (exists($d->{name})){
#         $param{'AnalyticsDataName'}=$d->{name};
#      }
#      if ($output->setFormat("Analytics",%param)){
#         if (exists($d->{filter})){
#            $dataobj->SecureSetFilter($d->{filter});
#         }
#         if (exists($d->{view})){
#            $dataobj->SetCurrentView(@{$d->{view}});
#         }
#         $dataobj->SetCurrentOrder(qw(NONE));
#         $output->WriteToStdout(HttpHeader=>0);
#      }
#   }
#}







1;
