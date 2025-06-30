package base::grp;
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
use kernel::CIStatusTools;
use base::lib::RightsOverview;
use HTML::TreeGrid;
@ISA=qw(kernel::App::Web::HierarchicalList kernel::DataObj::DB 
        kernel::CIStatusTools base::lib::RightsOverview);

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
                name          =>'grpid',
                label         =>'W5BaseID',
                size          =>'10',
                group         =>'source',
                dataobjattr   =>'grp.grpid'),

      new kernel::Field::RecordUrl(),
                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                explore       =>100,
                htmlwidth     =>'300px',
                size          =>'40',
                history       =>0,
                dataobjattr   =>'grp.fullname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                size          =>'20',
                htmlwith      =>'200px',
                nowrap        =>1,
                dataobjattr   =>'grp.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'grp.cistatus'),


      new kernel::Field::Text(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'grp.description'),

      new kernel::Field::Text(
                name          =>'sdescription',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'shorted Description',
                prepRawValue  =>sub{
                   my $self=shift;
                   my $d=shift;
                   return(TextShorter($d,70,['INDICATED']));
                },
                dataobjattr   =>'grp.description'),

      new kernel::Field::SubList(
                name          =>'users',
                subeditmsk    =>'subedit.group',
                label         =>'Users',
                group         =>'users',
                forwardSearch =>1,
                vjointo       =>'base::lnkgrpuser',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>['user','userweblink','roles'],
                vjoininhash   =>['userid','email','user',
                                 'posix','usertyp','roles',
                                 'srcsys','srcid','srcload',
                                 'mdate','cdate',
                                 'lnkgrpuserid','lastorgchangedt']),

      new kernel::Field::Text(
                name          =>'orgusers',
                label         =>'organisational members',
                readonly      =>1,
                group         =>'users',
                htmldetail    =>0,
                vjointo       =>'base::lnkgrpuser',
                vjoinbase     =>{lineroles=>[orgRoles()]},
                weblinkto     =>'NONE',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>['user']),

      new kernel::Field::Text(
                name          =>'bossusers',
                readonly      =>1,
                explore       =>200,
                label         =>'boss',
                group         =>'users',
                htmldetail    =>0,
                vjointo       =>'base::lnkgrpuser',
                vjoinbase     =>{lineroles=>['RBoss']},
                weblinkto     =>'NONE',
                vjoinon       =>['grpid'=>'grpid'],
                vjoindisp     =>['user']),

      new kernel::Field::TextDrop(
                name          =>'parent',
                AllowEmpty    =>1,
                label         =>'Parentgroup',
                vjointo       =>'base::grp',
                vjoinon       =>['parentid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'grp.comments'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinon       =>['grpid'=>'refid'],
                vjoinbase     =>[{'parentobj'=>\'base::grp'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Boolean(
                name          =>'is_org',
                label         =>'organisational Organisation',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_org'),

      new kernel::Field::Boolean(
                name          =>'is_line',
                label         =>'organisational Line',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_line'),

      new kernel::Field::Boolean(
                name          =>'is_depart',
                label         =>'organisational Department',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_depart'),

      new kernel::Field::Boolean(
                name          =>'is_resort',
                label         =>'organisational Resort',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_resort'),

      new kernel::Field::Boolean(
                name          =>'is_team',
                label         =>'organisational Team',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_team'),

      new kernel::Field::Boolean(
                name          =>'is_orggroup',
                label         =>'organisational Subunit',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_orggroup'),

      new kernel::Field::Boolean(
                name          =>'is_projectgrp',
                label         =>'Projectgroup',
                htmlhalfwidth =>1,
                group         =>'grptype',
                dataobjattr   =>'is_projectgrp'),

      new kernel::Field::Boolean(                # ACHTUNG: Das Feld ist auch 
                name          =>'is_orggrp',     #          in base::lnkgrpuser
                label         =>'organisational Group', #   definiert!
                htmlhalfwidth =>1,
                readonly      =>1,
                group         =>'grptype',
                dataobjattr   =>'if (is_org=1 or '.
                                    'is_line=1 or '.
                                    'is_depart=1 or '.
                                    'is_resort=1 or '.
                                    'is_team=1 or '.
                                    'is_orggroup=1'.
                                    ',1,0)'),

      new kernel::Field::Htmlarea(
                name          =>'grppresentation',
                label         =>'Team-View Presentation',
                searchable    =>0,
                group         =>'teamview',
                dataobjattr   =>'grp.grppresentation'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'base::grp',
                label         =>'Attachments',
                group         =>'attachments'),

      new kernel::Field::Container(
                name          =>'additional',
                group         =>'additional',
                label         =>'additional',
                selectfix     =>1,
                uivisible     =>1,
                htmldetail    =>sub {
                   my $self=shift;
                   return(1) if ($self->getParent->IsMemberOf("admin"));
                   return(0);
                },
                dataobjattr   =>'grp.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-System',
                dataobjattr   =>'grp.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'grp.srcid'),

      new kernel::Field::Text(
                name          =>'srcurl',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-URL',
                dataobjattr   =>'grp.srcurl'),

      new kernel::Field::Text(
                name          =>'ext_refid1',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'External RefID1',
                dataobjattr   =>'grp.ext_refid1'),

      new kernel::Field::Text(
                name          =>'ext_refid2',
                htmldetail    =>'NotEmpty',
                group         =>'source',
                label         =>'External RefID2',
                dataobjattr   =>'grp.ext_refid2'),

      new kernel::Field::Text(
                name          =>'sisnumber',
                group         =>'source',
                htmldetail    =>0,
                label         =>'SIS Number',
                dataobjattr   =>'grp.sisnumber'),

      new kernel::Field::Text(
                name          =>'accarea',
                group         =>'source',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Account-Area',
                dataobjattr   =>'grp.accarea'),

      new kernel::Field::Text(
                name          =>'comregnum',
                group         =>'source',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Commercial Registry Number',
                dataobjattr   =>'grp.comregnum'),

      new kernel::Field::Text(
                name          =>'nsin',
                group         =>'source',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Nat. Securities Ident. Number',
                dataobjattr   =>'grp.nsin'),

      new kernel::Field::Text(
                name          =>'isin',
                group         =>'source',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'Int. Securities Ident. Number',
                dataobjattr   =>'grp.isin'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Last-Load',
                dataobjattr   =>'grp.srcload'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'grp.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                readonly      =>1,
                dataobjattr   =>"grp.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                readonly      =>1,
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(grp.grpid,35,0)"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'grp.createuser'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'grp.createdate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'grp.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'grp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'grp.realeditor'),

      new kernel::Field::Interface(
                name          =>'parentid',
                label         =>'ParentID',
                dataobjattr   =>'grp.parentid'),

      new kernel::Field::Link(
                name          =>'lastknownbossemail',
                label         =>'last Known Boss E-Mailaddesses',
                dataobjattr   =>'grp.lastknownbossemail'),

      new kernel::Field::SubList(
                name          =>'subunits',
                subeditmsk    =>'subedit.group',
                label         =>'Subunits',
                group         =>'subunits',
                forwardSearch =>1,
                vjointo       =>'base::grp',
                vjoinbase     =>{'cistatusid'=>"<6"},
                vjoinon       =>['grpid'=>'parentid'],
                vjoindisp     =>['name','cistatus','sdescription'],
                vjoininhash   =>['grpid','name','fullname','srcsys',
                                 'description','lastorgchangedt']),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'grp.lastqcheck'),

      new kernel::Field::Date(
                name          =>'lastorgchangedt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last organisational change',
                dataobjattr   =>'grp.lorgchangedt'),

      new kernel::Field::Date(
                name          =>'lrecertreqdt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert request date',
                dataobjattr   =>'grp.lrecertreqdt'),

      new kernel::Field::Date(
                name          =>'lrecertreqnotify',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert request notification date',
                dataobjattr   =>'grp.lrecertreqnotify'),

      new kernel::Field::Date(
                name          =>'lrecertdt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert date',
                dataobjattr   =>'grp.lrecertdt'),

      new kernel::Field::Interface(
                name          =>'lrecertuser',
                group         =>'qc',
                label         =>'last recert userid',
                htmldetail    =>'0',
                dataobjattr   =>"grp.lrecertuser")


   );
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->{CI_Handling}={uniquename=>"fullname",
                         altname=>'name',
                         activator=>["admin","w5base.base.grp"],
                         uniquesize=>255};

   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->setWorktable("grp");
   $self->setDefaultView(qw(fullname cistatus editor description grpid));
   $self->{locktables}="grp write,contact write,".
                       "lnkgrpuser write,".
                       "lnkgrpuserrole write,".
                       "wfhead write, ".
                       "objblacklist write, ".
                       "wfkey write, wfaction write, iomap write, ".
                       "filemgmt write, ".
                       "phonenumber write, ".
                       "history write";
   return($self);
}

sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneMISC phoneONCALL phoneHOTLINE);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
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


sub getReCertificationUserIDs
{
   my $self=shift;
   my $rec=shift;

   my @orgadm=$self->getMembersOf($rec->{grpid},["RAdmin"],"up");

   return(@orgadm);
}






sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}



sub postQualityCheckRecord
{
   my $self=shift;
   my $rec=shift;

   my $grpid=$rec->{grpid};

   if ($grpid ne ""){
      my %upd;
      my $lnk=getModuleObject($self->Config,"base::lnkgrpuser");
      $lnk->SetFilter({
         grpid=>\$grpid,
         rawnativroles=>[orgRoles()], usercistatusid=>[3,4,5]
      });
      my @grp;
      my @orggroups=$lnk->getHashList(qw(grpid nativroles mdate)); 
      my $latestmdate;
      foreach my $lnkrec (@orggroups){
         my $roles=$lnkrec->{nativroles};
         if (!defined($latestmdate) || $latestmdate eq "" ||
             $latestmdate lt $lnkrec->{mdate}){
            $latestmdate=$lnkrec->{mdate};
         } 
      }
      foreach my $subrec (@{$rec->{subunits}}){
         if ($subrec->{lastorgchangedt} ne ""){
            if (!defined($latestmdate) || $latestmdate eq "" ||
                $latestmdate lt $subrec->{lastorgchangedt}){
               $latestmdate=$subrec->{lastorgchangedt};
            } 
         }
      }

      if ($rec->{lastorgchangedt} ne $latestmdate){
         $upd{lastorgchangedt}=$latestmdate;
      }


      if (keys(%upd)){
         $upd{mdate}=$rec->{mdate};
         my $op=$self->Clone();
         $op->ValidatedUpdateRecord($rec,\%upd,{grpid=>\$grpid});
      }
   }

   return(1);
}



sub prepareToWasted
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   $newrec->{srcsys}=undef;
   $newrec->{srcid}=undef;
   $newrec->{srcload}=undef;

   return(1);   # if undef, no wasted Transfer is allowed
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   return(1) if (effChangedVal($oldrec,$newrec,"cistatusid")==7);

   my $cistatus=effVal($oldrec,$newrec,"cistatusid");
   if (defined($newrec->{name}) || !defined($oldrec)){
      trim(\$newrec->{name});
      $newrec->{name}=~s/[\.\s\*]/_/g;
      my $chkname=$newrec->{name};
      if ($cistatus>=6 || (defined($oldrec) && $oldrec->{cistatusid}>=6)){
         $chkname=~s/\[.*?\]$//g;
      }
      if ($chkname eq "" || !($chkname=~m/^[\(\)a-zA-Z0-9_-]+$/) ||
          length($chkname)>20){
         $self->LastMsg(ERROR,"invalid groupname '\%s' specified",
                        $newrec->{name});
         return(undef);
      }
   }
   my @orgflags=qw(is_org is_line is_depart is_resort is_team  is_orggroup);

   if (effVal($oldrec,$newrec,"is_projectgrp")){
      foreach my $var (@orgflags){
         if (effVal($oldrec,$newrec,$var)){
            $newrec->{$var}=0;
         }
      }
   }


   $newrec->{cistatusid}=4 if (!defined($oldrec) && $cistatus==0);
   if (!$self->SUPER::Validate($oldrec,$newrec,$origrec)){
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
}

sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"TeamView","TreeCreate",
         "RightsOverview","RightsOverviewLoader","view",
         "ImportOrgarea");
}

sub view
{
   my ($self)=@_;
   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $val="UNDEF" if ($val eq "");
   $self->HtmlGoto("../Detail",post=>{
      $idname=>$val,
      ModeSelectCurrentMode=>'TView'
   });
   return();
}


sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("base::grp");
}



sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   if (defined($rec) && $rec->{cistatusid}==7){
      return($self->SUPER::getHtmlDetailPages($p,$rec));
   }
   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "TView"=>$self->T("Team View"),
          "RView"=>$self->T("Rights overview"));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "TView"&&
                                                               $p ne "RView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "TView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"TeamView?$urlparam\"></iframe>";
   }
   if ($p eq "RView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"RightsOverview?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getGrpDiv
{
   my $self=shift;
   my $grec=shift;
   my $d;
   $d.="<div class=groupicon>";
   my $img=$self->getRecordImageUrl($grec);
   my $desc=$grec->{description}; 
   my $comm=$grec->{comments}; 
 
   $d.="<table width=\"100%\">".
       "<tr><td width=\"1%\">".
       "<a onclick=\"return(false);\" href=\"view/$grec->{grpid}\">".
       "<img class=groupicon src=\"$img\"></a></td>".
       "<td valign=top align=left><u>$desc</u><br>$comm</td></tr></table>";

   
   $d.="</div>";
   return($d);
}

sub getUserDiv
{
   my $self=shift;
   my $user=shift;
   my $usrec=shift;
   my $urec=shift;
   my $d;
   my $name;
   $d.="<div class=\"usericon\">";
   my $img=$user->getRecordImageUrl($urec);
   $d.="<img class=usericon src=\"$img\"><br>";

   
   $name.=$urec->{surname};
   $name.=", " if ($name ne "");
   $name.=$urec->{givenname};
   $name=$urec->{email} if ($name=~m/^\s*$/);
   
   $d.="<p>".$name."</p></div>";
   return($d);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt)){ 
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);

   }
   return($self->SetFilter(@flt));
}




sub TeamView   # erster Versuch der Teamview
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));


   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"TeamView",
                           js=>['toolbox.js'],
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'public/base/load/grpteamview.css']);
   if (defined($rec)){
      my $employee;
      my $boss;
      if (ref($rec->{users}) eq "ARRAY"){
         my $user=getModuleObject($self->Config,"base::user");
         foreach my $usrec (sort({$a->{user} cmp $b->{user}} 
                                 @{$rec->{users}})){
            $user->ResetFilter();
            $user->SetFilter({userid=>\$usrec->{userid},cistatusid=>"<=4"});
            my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
            if ($usrec->{usertyp} ne "service" && defined($urec)){
               if (grep(/^RBoss$/,@{$usrec->{roles}})){
                  $boss.=$self->getUserDiv($user,$usrec,$urec);
               }
               else{
                  if (grep(/^REmployee$/,@{$usrec->{roles}})){
                     $employee.=$self->getUserDiv($user,$usrec,$urec);
                  }
               }
            }
         }
      }
      my $group=$self->getGrpDiv($rec);
      my $cleardiv="<div style=\"clear:both\"></div>";
      print "<div class=topframe>".
            "<a onclick=\"return(false);\" href=\"view/$rec->{grpid}\">".
            "$rec->{fullname}</a><div>$cleardiv";
      print "<div class=groupframe>$group$boss</div>$cleardiv";
      if ($rec->{grppresentation} ne ""){
         printf("<div class=grppresentation>%s</div>",
               $rec->{grppresentation});
      }
      print "<div class=userframe>$employee</div>$cleardiv";
   }
   print $self->HtmlBottom(body=>1,form=>1);
}




sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{grpid}==1);
   return(0) if ($rec->{grpid}==-1);
   return(0) if ($rec->{grpid}==-2);
   return(0) if (!grep(/^default$/,$self->isWriteValid($rec)));
   return($self->SUPER::isDeleteValid($rec));
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   if (defined($rec) && $rec->{cistatusid}==7){
      return(qw(header default history));
   }

   if (!defined($rec) || (defined($rec->{grpid}) && $rec->{grpid}<=0)){
      return(qw(header default source));
   }
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return(qw(default)) if (!defined($rec));
   return("default") if ($rec->{cistatusid}<3 && ($rec->{creator}==$userid ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator})));

   return(qw(default)) if (!defined($rec) && $self->IsMemberOf("admin"));
   return(undef) if ($rec->{grpid}<=0);
   return(qw(default users phonenumbers teamview
             misc grptype attachments)) if ($self->IsMemberOf("admin"));
   if (defined($rec)){
      my $grpid=$rec->{grpid};
      if ($self->IsMemberOf([$grpid],"RAdmin","down")){
         return(qw(users phonenumbers misc attachments));
      }
      if ($self->IsMemberOf([$grpid],["RBoss","RBoss2"],"direct")){
         return(qw(phonenumbers misc grptype teamview attachments));
      }
   }
   return(undef);
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{cistatusid}) &&
       $newrec->{cistatusid}==7 &&
       $oldrec->{cistatusid}!=7){
      my $grpid=$oldrec->{grpid};
      my $j=getModuleObject($self->Config,"base::lnkgrpuser");
      $j->BulkDeleteRecord({'grpid'=>\$grpid});
      return(1);
   }


   # $self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}});
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
  # $self->InvalidateGroupCache();
   $W5V2::InvalidateGroupCache++;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $grpid=$oldrec->{grpid};
   if ($grpid ne ""){
      my $lnkgrpuser=getModuleObject($self->Config,"base::lnkgrpuser");
      $lnkgrpuser->SetFilter({'grpid'=>\$grpid});
      $lnkgrpuser->SetCurrentView(qw(ALL));
      my $op=$lnkgrpuser->Clone();
      $lnkgrpuser->ForeachFilteredRecord(sub{
                         $op->ValidatedDeleteRecord($_);
                      });
   }

   $self->InvalidateGroupCache();
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::FinishDelete($oldrec));
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   if (ref($rec->{users}) eq "ARRAY" &&
       $#{$rec->{users}}!=-1){
      $self->LastMsg(WARN,"group has members!");
   }
   my $grpid=$rec->{grpid};
   if ($grpid ne ""){
      my $chk=getModuleObject($self->Config,"base::menuacl");
      $chk->SetFilter({acltarget=>\'base::grp',
                       acltargetid=>\$grpid});
      my ($chkrec,$msg)=$chk->getOnlyFirst(qw(refid));
      if (defined($chkrec)){
         $self->LastMsg(WARN,"group has references in menu acl!");
      }
      my $chk=getModuleObject($self->Config,"base::lnkcontact");
      $chk->SetFilter({target=>\'base::grp',
                       targetid=>\$grpid});
      my ($chkrec,$msg)=$chk->getOnlyFirst(qw(refid));
      if (defined($chkrec)){
         $self->LastMsg(WARN,"group has references in contact links!");
      }
   }

   return(1);
}


sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default users subunits phonenumbers grptype additional
                misc teamview attachments));
}


sub TreeCreate
{
   my $self=shift;
   my $tree=shift;
   my @log=();
   my $createid=0;

   if (!defined($tree)){
      if (!$self->IsMemberOf("admin")){
         print($self->noAccess());
         return(undef);
      }
   }
   $self->LastMsg(INFO,"TreeCreate $tree") if (defined($tree));
   my $createname;
   my $doit=0;
   if (!defined($tree)){
      $createname=Query->Param("createname");
      $doit=1 if (Query->Param("DOIT"));
   }
   else{
      $doit=1;
      $createname=$tree;
   }
   if (defined($createname) && $createname ne "" && $doit){
      my $g=getModuleObject($self->Config,"base::grp");
      $self->LastMsg(INFO,"request to create $createname") if (!defined($tree));
      my @grp=split(/\./,trim($createname));
      my $parentgrp="";
      my $fullname="";
      foreach my $grp (@grp){
         my $parentis="";
         my %parentgrp=();
         $fullname=$grp;
         if ($parentgrp ne ""){
            $fullname=$parentgrp.".".$grp;
            %parentgrp=(parent=>$parentgrp);
         }
         $parentis=" parent is $parentgrp" if ($parentgrp ne "");
         if (!defined($tree)){
            $self->LastMsg(INFO,"try create $fullname$parentis");
         }
         $g->ResetFilter();
         $g->SetFilter({fullname=>\$fullname});
         my ($grprec,$msg)=$g->getOnlyFirst(qw(ALL));
         if (!defined($grprec)){
            my $grpid;
            if ($tree){
               $grpid=$g->ValidatedInsertRecord({
                          name=>$grp,
                          cistatusid=>4,
                          %parentgrp});
            }
            else{
               $grpid=$g->SecureValidatedInsertRecord({
                          name=>$grp,
                          cistatusid=>4,
                          %parentgrp});
            }
            if ($grpid){
               $self->LastMsg(OK,"insert of $grp as $grpid OK");
               if ($createname eq $fullname){
                  $createid=$grpid;
               }
            }
            else{
               $self->LastMsg(ERROR,"insert of $grp failed");
               last;
            }
         }
         else{
            $createid=$grprec->{grpid};
         }

         $parentgrp.="." if ($parentgrp ne "");
         $parentgrp.=$grp;
      }
   } 
   if ($createname eq "" && !defined($tree) && $doit){
      $self->LastMsg(ERROR,"no group name spcified");
   }


   if (!defined($tree)){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','work.css',
                                      'kernel.App.Web.css'],
                              static=>{createname=>$createname},
                              body=>1,form=>1,
                              title=>"TreeCreate");
      print $self->getParsedTemplate("tmpl/minitool.grp.treecreate",
                           {
                             static=>{xxx=>'yyy'},
                           });
      print $self->HtmlBottom(body=>1,form=>1);

   }
   return($createid);
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({grpid=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(fullname));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{fullname},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}


sub getParentGroupIdByType
{
   my $self=shift;
   my $grpid=shift;
   my $type=shift;
   my @flags=qw(org line depart resort team orggroup);
   my @fields=qw(parentid grpid fullname);

   return(undef) if ($grpid eq "");
   return(undef) if (!grep(/^$type$/,@flags));
   foreach my $flag (@flags){
      push(@fields,"is_".$flag);
   }
   if (exists($self->Cache->{getParentGroupIdByType}->{$grpid.".".$type})){
      return($self->Cache->{getParentGroupIdByType}->{$grpid.".".$type});
   }

   $self->SetFilter({grpid=>\$grpid});
   my ($grec,$msg)=$self->getOnlyFirst(@fields);
   if (defined($grec)){
      if ($grec->{"is_".$type}){
         $self->Cache->{getParentGroupIdByType}->{$grpid.".".$type}=
                       $grec->{grpid};
         return($grec->{grpid});
      }
      my $parentid=$grec->{parentid};
      if ($parentid ne ""){
         return($self->getParentGroupIdByType($parentid,$type));
      }
   }
   return(undef);

}




#
# This is the native API for all W5Base Modules to get the W5BaseID of
# a group with AutoImport Option  (see: */ext/orgareaImport.pm)
#
sub GetW5BaseGrpID
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;   # srcid|name|fullname|grpid
   my $param=shift;

   if ($useAs eq "" || $name=~m/^\s*$/ || $name=~m/\s/ ||
       ($useAs ne "srcid" &&
        $useAs ne "grpid" &&
        $useAs ne "name" &&
        $useAs ne "fullname")){
      msg(ERROR,"invalid call of GetW5BaseGrpID in base::grp!");
      Stacktrace();
      return(undef);
   }

   for(my $loopcnt=0;$loopcnt<2;$loopcnt++){
      $self->ResetFilter();
      $self->SetFilter({$useAs=>\$name});

      my ($grprec,$msg)=$self->getOnlyFirst(qw(grpid name fullname
                                               srcsys srcid));
      if (defined($grprec)){
         if (wantarray()){
            return($grprec->{grpid},$grprec);
         }
         else{
            return($grprec->{grpid});
         }
      }
      if ($loopcnt==0){
         # try Import

         # e.g. 'tsciam::1234' forces import of group 1234 from ciam only
         my @parts=split('::',$name,2);
         if ($#parts>0) {
            ($param->{force},$name)=@parts;
         }

         my @iobj=$self->getImportObjs($name,$useAs,$param);
         foreach my $k (@iobj) {
            msg(INFO,"try Import for $name ($useAs) with=$k");
            if (my $grpid=$self->{orgareaImport}->{$k}->processImport(
                   $name,$useAs,$param)){
               $name=$grpid;
               $useAs="grpid";
               last;
            }
         }
      }
   }

   return(undef);
}


sub getImportObjs
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;
   my @ret;

   if (!exists($self->{orgareaImport})){
      $self->LoadSubObjs("ext/orgareaImport","orgareaImport");
   }

   if (defined($param->{force})) {
      my $src=$param->{force}.'::ext::orgareaImport';
      push(@ret,$src) if (exists($self->{orgareaImport}{$src}));
      return(@ret);
   }

   my %p;
   foreach my $k (sort(keys(%{$self->{orgareaImport}}))){
     my $q=$self->{orgareaImport}->{$k}->getQuality($name,$useAs,$param);
     $p{$k}=$q;
   }

   @ret=sort({$p{$a}<=>$p{$b}} keys(%p));
   return(@ret);
}


sub ImportOrgarea
{
   my $self=shift;
   my $maxCnt=5;
   my $success=0;
   my %param=(quiet=>1);

   my $importnames=Query->Param("importname");
   my @importname=split(/\s+/,trim($importnames));
   my @imported; # imported orgareas

   my @idhelp=();
   my @importObjs=$self->getImportObjs(undef,undef,\%param);
   foreach my $k (@importObjs) {
      if ($self->{orgareaImport}{$k}->can('getImportIDFieldHelp')) {
         push(@idhelp,$self->{orgareaImport}{$k}->getImportIDFieldHelp());
      }
   }
   my $idhelp=' ';
   $idhelp=' ('.join(', ',@idhelp).') ' if ($#idhelp!=-1);

   if (Query->Param("DOIT")){
      my $i=0;

      while ($i<=$#importname && $i<$maxCnt) {
         my $name=$importname[$i];

         my @res=$self->GetW5BaseGrpID($name,'srcid',\%param);
         if (defined($res[0]) &&
             !in_array(\@imported,$res[1]->{fullname})) {
            push(@imported,$res[1]->{fullname});
            $success++;
         }

         $i++;
      }

      if ($success && $success==$#importname+1) {
         if ($success==1) {
            $self->LastMsg(OK,"orgarea successful imported");
         }
         else {
            $self->LastMsg(OK,"%d orgareas successful imported",$success);
         }
      }
      else {
         $self->LastMsg(WARN,"%d from %d orgareas successful imported",
                             $success,$#importname+1);
      }

      Query->Delete("importname");
      Query->Delete("DOIT");
   }

   my $names=join("<br>",sort(@imported));
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importnames},
                           body=>1,form=>1,
                           title=>"Orgarea Import");
   print $self->getParsedTemplate("tmpl/minitool.orgarea.import",
                                  {static=>{idhelp=>$idhelp,
                                            imported=>$names}});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub jsExploreFormatLabelMethod
{
   my $self=shift;
   return(<<EOF);

newlabel=newlabel.replace(/^.*\\./,'');


EOF
}


sub jsExploreObjectMethods
{
   my $self=shift;
   my $methods=shift;

   my $label=$self->T("add members");
   $methods->{'m100addGrpMembers'}="
       label:\"$label\",
       cssicon:\"basket_add\",
       exec:function(){
          console.log(\"call m100addGrpMembers on \",this);
          var dataobjid=this.dataobjid;
          var dataobj=this.dataobj;
          var app=this.app;
          var MasterItem=this;
          app.pushOpStack(new Promise(function(methodDone){
             app.Config().then(function(cfg){
                var w5obj=getModuleObject(cfg,'base::grp');
                w5obj.SetFilter({
                   grpid:dataobjid
                });
                w5obj.findRecord(\"grpid,users\",function(data){
                   console.log(\"found:\",data);
                   for(recno=0;recno<data.length;recno++){
                      for(subno=0;subno<data[recno].users.length;subno++){
                         var curkey=MasterItem.id;
                         var nodelevel=MasterItem.level;
                         var nexkey=app.toObjKey('base::user',
                                           data[recno].users[subno].userid);
                         app.addNode('base::user',
                                     data[recno].users[subno].userid,
                                     data[recno].users[subno].user,{
                                level:nodelevel+1
                         });
                         app.addEdge(curkey,nexkey);
                      }
                   }
                   app.networkFitRequest=true;
                });
                \$(document).ajaxStop(function () {
                   methodDone(\"load of Members done\");
                });
             });
          }));
       }
   ";

}



sub generateContextMap
{
   my $self=shift;
   my $rec=shift;

   my $d={
      items=>[]
   };
   my %item;


   my $imageUrl=$self->getRecordImageUrl(undef);
   my $cursorItem;

   my $cursorItem="base::grp::".$rec->{grpid};
   if ($cursorItem){
      my $title=$rec->{name};
      my $itemrec={
         id=>$cursorItem,
         title=>$rec->{name},
         description=>$rec->{description},
         dataobj=>'base::grp',
         dataobjid=>$rec->{grpid},
         templateName=>'ultraWideTemplate'
      };
      $item{$cursorItem}=$itemrec;
      push(@{$d->{items}},$itemrec);
   }
   my %baseorg;
   $baseorg{$rec->{grpid}}++;

   foreach my $subunit (@{$rec->{subunits}}){
      my $k="base::grp::".$subunit->{grpid};
      if (!exists($item{$k})){
         my $itemrec={
            id=>$k,
            title=>$subunit->{name},
            description=>$subunit->{description},
            dataobj=>'base::grp',
            dataobjid=>$subunit->{grpid},
            templateName=>'ultraWideTemplate',
            parents=>[$cursorItem]
         };
         $item{$k}=$itemrec;
         push(@{$d->{items}},$itemrec);
      }
   }





   my $user=$self->getPersistentModuleObject("base::user");
#   if (keys(%baseorg)){
#      $grp->SetFilter({grpid=>[keys(%baseorg)],cistatusid=>'4'});
#      my @l=$grp->getHashList(qw(fullname name grpid users urlofcurrentrec));
#      foreach my $grec (@l){
#         my $gid="base::grp::".$grec->{grpid};
#         if (!exists($item{$gid})){
#            my $itemrec={
#               id=>$gid,
#               title=>$grec->{name},
#               dataobj=>'base::grp',
#               dataobjid=>$grec->{grpid}
#            };
#            $item{$gid}=$itemrec;
#            push(@{$d->{items}},$itemrec);
#            
#         }
#         foreach my $urec (@{$grec->{users}}){
#            my $roles=$urec->{roles};
#            $roles=[$roles] if (ref($roles) ne "ARRAY");
#            if (in_array($roles,[orgRoles()])){
#               my $uid="base::user::".$urec->{userid};
#               if (!exists($item{$uid})){
#                  my $itemrec={
#                     id=>$uid,
#                     dataobj=>'base::user',
#                     dataobjid=>$urec->{userid},
#                     templateName=>'contactTemplate',
#                     parents=>[]
#                  };
#                  $item{$uid}=$itemrec;
#                  push(@{$d->{items}},$itemrec);
#               }
#               if (!in_array($item{$uid}->{parents},$gid)){
#                  push(@{$item{$uid}->{parents}},$gid);
#               }
#            }
#         }
#      }
#      # fillup recursiv all parent groups
#
#
#
#
#      #
#   }
   {
      my $opobj=$user;
      my %id;
      foreach my $k (keys(%item)){
         if ($item{$k}->{dataobj} eq "base::user"){
            $id{$item{$k}->{dataobjid}}++;
         }
      }
      if (keys(%id)){
         $opobj->ResetFilter();
         $opobj->SetFilter({userid=>[keys(%id)]});
         foreach my $chkrec ($opobj->getHashList(qw(ALL))){
            my $k=$opobj->Self()."::".$chkrec->{userid};
            my $imageUrl=$opobj->getRecordImageUrl($chkrec);
            $item{$k}->{titleurl}=$chkrec->{urlofcurrentrec};
            $item{$k}->{titleurl}=~s#/ById/#/Map/#;
            $item{$k}->{image}=$imageUrl;
            $item{$k}->{title}=$chkrec->{fullname};
            $item{$k}->{title}=~s/ \(.*$//;
         }
      }
   }
   {
      my $opobj=$self;
      my %id;
      foreach my $k (keys(%item)){
         if ($item{$k}->{dataobj} eq "base::grp"){
            $id{$item{$k}->{dataobjid}}++;
         }
      }
      if (keys(%id)){
         do{
            $opobj->ResetFilter();
            $opobj->SetFilter({grpid=>[keys(%id)]});
            foreach my $chkrec ($opobj->getHashList(qw(ALL))){
               my $k=$opobj->Self()."::".$chkrec->{grpid};
               if (!exists($item{$k})){
                  my $itemrec={
                     id=>$k,
                     title=>$chkrec->{name},
                     dataobj=>'base::grp',
                     dataobjid=>$chkrec->{grpid},
                     description=>$chkrec->{description},
                     templateName=>'ultraWideTemplate'
                  };
                  $item{$k}=$itemrec;
                  push(@{$d->{items}},$itemrec);
               }
               my $imageUrl=$opobj->getRecordImageUrl($chkrec);
               $item{$k}->{titleurl}=$chkrec->{urlofcurrentrec};
               $item{$k}->{titleurl}=~s#/ById/#/Map/#;
               $item{$k}->{image}=$imageUrl;
               delete($id{$chkrec->{grpid}});
               if ($chkrec->{parentid} ne ""){
                  my $pkey="base::grp::".$chkrec->{parentid};
                  if (!exists($item{$k}->{parents})){
                     $item{$k}->{parents}=[];
                  }
                  if (!in_array($item{$k}->{parents},$pkey)){
                     push(@{$item{$k}->{parents}},$pkey);
                  }
                  if (!exists($item{$pkey})){
                     $id{$chkrec->{parentid}}++;
                  }
               }
            }
         }while(keys(%id)!=0);
      }
   }

   if ($cursorItem){
      $d->{cursorItem}=$cursorItem;
   }

   $d->{enableMatrixLayout}=1;
   $d->{minimumMatrixSize}=4;
   $d->{maximumColumnsInMatrix}=3;
   if ($#{$d->{items}}>8){
      $d->{initialZoomLevel}="5";
   }


   #print STDERR Dumper($d);
   return($d);
}




1;
