package faq::article;
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
use Data::Dumper;
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

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Short-Description',
                searchable    =>1,
                htmlwidth     =>'450',
                dataobjattr   =>'faq.name'),
                                    
      new kernel::Field::KeyText(
                name          =>'kwords',
                vjoinconcat   =>' ',
                conjunction   =>'AND',
                keyhandler    =>'kh',
                label         =>'Keywords'),

      new kernel::Field::Select(
                name          =>'categorie',
                htmleditwidth =>'50%',
                label         =>'Categorie',
                vjointo       =>'faq::category',
                vjoinon       =>['faqcat'=>'faqcatid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Htmlarea(
                name          =>'data',
                searchable    =>0,
                label         =>'Article',
                dataobjattr   =>'faq.data'),
                                    
      new kernel::Field::Link(
                name          =>'faqcat',
                dataobjattr   =>'faq.faqcat'),
                                    
      new kernel::Field::Link(
                name          =>'aclmode',
                selectable    =>0,
                dataobjattr   =>'faqacl.aclmode'),
                                    
      new kernel::Field::Link(
                name          =>'acltarget',
                selectable    =>0,
                dataobjattr   =>'faqacl.acltarget'),
                                    
      new kernel::Field::Link(
                name          =>'acltargetid',
                selectable    =>0,
                dataobjattr   =>'faqacl.acltargetid'),
                                   
      new kernel::Field::Id(
                name          =>'faqid',
                label         =>'Article-No',
                depend        =>[qw(owner)],
                sqlorder      =>'desc',
                size          =>'10',
                group         =>'sig',
                dataobjattr   =>'faq.faqid'),
                                    
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'sig',
                label         =>'Owner',
                dataobjattr   =>'faq.owner'),

      new kernel::Field::Link(
                name          =>'ownerid',
                group         =>'sig',
                label         =>'OwnerID',
                dataobjattr   =>'faq.owner'),
                                   
      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.article',
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'faq::acl',
                vjoinbase     =>[{'aclparentobj'=>\'faq::article'}],
                vjoinon       =>['faqid'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),
                                    
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'sig',
                label         =>'Source-System',
                dataobjattr   =>'faq.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'sig',
                label         =>'Source-Id',
                dataobjattr   =>'faq.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'sig',
                label         =>'Source-Load',
                dataobjattr   =>'faq.srcload'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'sig',
                label         =>'Creator',
                dataobjattr   =>'faq.createuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'sig',
                label         =>'Editor',
                dataobjattr   =>'faq.editor'),
                                   
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'sig',
                label         =>'RealEditor',
                dataobjattr   =>'faq.realeditor'),
                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                label         =>'Creation-Date',
                group         =>'sig',
                dataobjattr   =>'faq.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                label         =>'Modification-Date',
                sqlorder      =>'desc',
                group         =>'sig',
                dataobjattr   =>'faq.modifydate'),
                                   
      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                group         =>'attachments'),
                                   
      new kernel::Field::KeyHandler(
                name          =>'kh',
                dataobjname   =>'w5base',
                tablename     =>'faqkey'),

   );
   $self->setDefaultView(qw(mdate categorie name editor));
   $self->setWorktable("faq");
   $self->{DetailY}=520;
   return($self);
}

sub SecureSetFilter
{  
   my $self=shift;
   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','both');
      return($self->SUPER::SecureSetFilter([{owner=>\$userid},
                                            {aclmode=>['write','read'],
                                             acltarget=>\'base::user',
                                             acltargetid=>[$userid]},
                                            {aclmode=>['write','read'],
                                             acltarget=>\'base::grp',
                                             acltargetid=>[keys(%groups),-2]},
                                            {acltargetid=>[undef]},
                                            ],@_));
   }
   return($self->SUPER::SecureSetFilter(@_));
}

sub getDetailBlockPriority
{
   my $self=shift;

   return($self->SUPER::getDetailBlockPriority(),"attachments");
}

sub getSqlFrom
{
   my $self=shift;
   my $from="faq left outer join faqacl ".
            "on faq.faqid=faqacl.refid and ".
            "faqacl.aclmode='read' and ".
            "faqacl.aclparentobj='faq::article'";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!defined($oldrec) || defined($newrec->{name})){
      $newrec->{name}=trim($newrec->{name});
      if ($newrec->{name} eq ""){
         $self->LastMsg(ERROR,"no valid article shortdescription");
         return(0);
      }
   }
   if (!defined($oldrec) || defined($newrec->{kh})){
      if (!defined($newrec->{kh}->{kwords}) ||
          $#{$newrec->{kh}->{kwords}}==-1){
         $self->LastMsg(ERROR,"no keywords");
         return(0);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));

   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid;
   my $UserCache=$self->Cache->{User}->{Cache};

   return if (!defined($rec) && !$self->IsMemberOf("valid_user"));
   return("default") if (!defined($rec) && $self->IsMemberOf("valid_user"));
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }
   if (defined($UserCache->{tz})){
      $userid=$UserCache->{userid};
   }
   my @acl=$self->getCurrentAclModes($ENV{REMOTE_USER},$rec->{acls});
   return("default","acl","attachments") if ($rec->{owner}==$userid ||
                                             $self->IsMemberOf("admin") ||
                                             grep(/^write$/,@acl));
   return(undef);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/faq/load/faqknowledge.jpg?".$cgi->query_string());
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $id=effVal($oldrec,$newrec,"faqid");
   my $idobj=$self->IdField();
   my $idname=$idobj->Name();

   my $url=$ENV{SCRIPT_URI};
   $url=~s/[^\/]+$//;
   $url.="ById/$id";
   $url=~s#/public/#/auth/#g;
   my $lang=$self->Lang();

   my %p=(eventname=>'faqchanged',
          spooltag=>'faqchanged-'.$id,
          redefine=>'1',
          retryinterval=>600,
          firstcalldelay=>900,
          eventparam=>$id.";".$url.";".$lang,
          userid=>11634953080001);
   my $res;
   if ($self->isDataInputFromUserFrontend()){
      if (defined($res=$self->W5ServerCall("rpcCallSpooledEvent",%p)) &&
          $res->{exitcode}==0){
         msg(INFO,"FaqModifed Event sent OK");
      }
      else{
         msg(ERROR,"FaqModifed Event sent failed");
      }
   }

   return($self->SUPER::FinishWrite($oldrec,$newrec));
}


sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({faqid=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name categorie faqcat));
      print($ia->WinHandleInfoAboSubscribe({},
                      "faq::article",$id,$rec->{name},
                      "faq::category",$rec->{faqcat},$rec->{categorie},
                      "base::staticinfoabo",undef,undef)); 
   }
   else{
      print($self->noAccess());
   }
}


sub getDefaultHtmlDetailPage
{
   my $self=shift;
   return("StandardDetail");
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "FView"=>$self->T("Full-View"));
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "FView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "FView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"FullView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"FullView");
}


sub FullView
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(name data attachments));

   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>$rec->{name},
                           js=>['toolbox.js'],
                           style=>['default.css',
                                'work.css',
                                'Output.HtmlDetail.css',
                                'kernel.App.Web.css',
                                'public/faq/load/faq.css']);
#
   print("<body class=fullview><form>");
   print("<div class=fullview style=\"padding-bottom:10px\">".
         "<b><div id=WindowTitle>".$rec->{name}."</div></b></div>");
   print("<div class=fullview>".$rec->{data}."</div>");
   if (defined($rec->{attachments}) && ref($rec->{attachments}) eq "ARRAY" &&
       $#{$rec->{attachments}}!=-1){
      my $att;
      foreach my $frec (@{$rec->{attachments}}){
         if ($frec->{label}=~m/\.pdf$/i){
            $att.="\n<tr><td width=1%><a class=attlink href=\"$frec->{href}\">".
                  "<img src=\"../load/pdf_icon.gif\"></a></td>".
                  "<td><a class=attlink href=\"$frec->{href}\">".
                  "$frec->{label}</a></td></tr>";
         }
         if ($frec->{label}=~m/\.xls$/i){
            $att.="\n<tr><td width=1%><a class=attlink href=\"$frec->{href}\">".
                  "<img src=\"../load/xls_icon.gif\"></a></td>".
                  "<td><a class=attlink href=\"$frec->{href}\">".
                  "$frec->{label}</a></td></tr>";
         }
      }
      if ($att ne ""){
         print("<div class=attachments>".
               "<table width=100%>".$att."</table></div>");
      }
   }
   print(<<EOF);
<script language="JavaScript">
function setTitle()
{
   var t=window.document.getElementById("WindowTitle");
   parent.document.title=t.innerHTML;
   return(true);
}
addEvent(window, "load", setTitle);
</script>
EOF
   print("</form></body></html>");



}

sub ById
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
   $self->HtmlGoto("../Detail",post=>{$idname=>$val,
                                      ModeSelectCurrentMode=>'FView'});
   return();
}

sub getDefaultHtmlDetailPage
{
   my $self=shift;
   my $cookievar=shift;

   my $d=Query->Cookie($cookievar);
   $d="StandardDetail" if ($d eq "");
   return($d);
}














1;
