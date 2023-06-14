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
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use HTML::TagFilter;
use HTML::Parser;
use kernel::App::Web::VoteLink;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB
        kernel::App::Web::VoteLink);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=2;
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

      new kernel::Field::Select(
                name          =>'lang',
                label         =>'Language',
                htmleditwidth =>'50%',
                value         =>['multilang',LangTable()],
                dataobjattr   =>'faq.lang'),

      new kernel::Field::Boolean(
                name          =>'published',
                label         =>'Published',
                searchable    =>1,
                dataobjattr   =>'faq.published'),

      new kernel::Field::Htmlarea(
                name          =>'data',
                searchable    =>0,
                label         =>'Article',
                dataobjattr   =>'faq.data'),

      new kernel::Field::Text(
                name          =>'furtherkeys',
                label         =>'Further keywords',
                searchable    =>0,
                htmldetail    =>sub{
                                    my $self=shift;
                                    my $mode=shift;
                                    my %param=@_;
                                    return(0) if (!defined($param{current}));
                                    return(1);
                                },
                dataobjattr   =>'faq.furtherkeys'),
                                    
      new kernel::Field::Link(
                name          =>'faqcat',
                dataobjattr   =>'faq.faqcat'),
                                    
      new kernel::Field::Link(
                name          =>'raclmode',
                selectable    =>0,
                dataobjattr   =>'rfaqacl.aclmode'),
                                    
      new kernel::Field::Link(
                name          =>'racltarget',
                selectable    =>0,
                dataobjattr   =>'rfaqacl.acltarget'),
                                    
      new kernel::Field::Link(
                name          =>'racltargetid',
                selectable    =>0,
                dataobjattr   =>'rfaqacl.acltargetid'),
                                   
      new kernel::Field::Link(
                name          =>'waclmode',
                selectable    =>0,
                dataobjattr   =>'wfaqacl.aclmode'),
                                    
      new kernel::Field::Link(
                name          =>'wacltarget',
                selectable    =>0,
                dataobjattr   =>'wfaqacl.acltarget'),
                                    
      new kernel::Field::Link(
                name          =>'wacltargetid',
                selectable    =>0,
                dataobjattr   =>'wfaqacl.acltargetid'),
                                   
      new kernel::Field::Id(
                name          =>'faqid',
                label         =>'Article-No',
                depend        =>[qw(owner)],
                sqlorder      =>'desc',
                size          =>'10',
                group         =>'sig',
                dataobjattr   =>'faq.faqid'),

      new kernel::Field::RecordUrl(),
                                    
      new kernel::Field::Number(
                name          =>'viewcount',
                readonly      =>1,
                group         =>'sig',
                label         =>'View count',
                dataobjattr   =>'faq.viewcount'),

      new kernel::Field::Date(
                name          =>'viewlast',
                label         =>'View last',
                readonly      =>1,
                group         =>'sig',
                dataobjattr   =>'faq.viewlast'),

      new kernel::Field::Date(
                name          =>'viewlastbywriter',
                label         =>'View last by author',
                frontreadonly =>1,
                uploadable    =>0,
                group         =>'sig',
                dataobjattr   =>'faq.viewlastbywriter'),

      new kernel::Field::Date(
                name          =>'viewlastbywriternotify',
                label         =>'View last by author - notify',
                uivisible     =>0,
                frontreadonly =>1,
                group         =>'sig',
                dataobjattr   =>'faq.viewlastbywriternotify'),

      new kernel::Field::Number(
                name          =>'viewfreq',
                readonly      =>1,
                group         =>'sig',
                label         =>'View frequency',
                dataobjattr   =>'faq.viewfreq'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'sig',
                label         =>'last Editor',
                dataobjattr   =>'faq.owner'),

      new kernel::Field::Email(
                name          =>'owneremail',
                group         =>'sig',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                label         =>'last editor email',
                dataobjattr   =>'ownercontact.email'),

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
                label         =>'Editor Account',
                dataobjattr   =>'faq.editor'),
                                   
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'sig',
                label         =>'real Editor Account',
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

      new kernel::Field::Textarea(
                name          =>'rawdata',
                searchable    =>1,
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'raw data',
                dataobjattr   =>'faq.data'),

                                   
      new kernel::Field::FileList(
                name          =>'attachments',
                showcomm      =>1,
                privoption    =>0,
                searchable    =>0,
                onFileAdd     =>\&onFileAdd,
                label         =>'Attachments',
                group         =>'attachments'),
                                   
      new kernel::Field::KeyHandler(
                name          =>'kh',
                dataobjname   =>'w5base',
                tablename     =>'faqkey'),

   );

   $self->extendFieldDefinition();



   $self->setDefaultView(qw(mdate categorie name editor));
   $self->setWorktable("faq");
   $self->{DetailY}=520;
   return($self);
}

sub onFileAdd
{
   my $self=shift;
   my $rec=shift;

   my $dataobj=$self->getParent->Clone();
   my $parentid=$rec->{parentrefid};
   msg(INFO,"call of onFileAdd for $rec->{name}");
   if ($rec->{name}=~m/^screenshot.*\.jpg$/i){
      $dataobj->ResetFilter();
      $dataobj->SetFilter({faqid=>\$parentid});
      my ($orgrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
      if (defined($orgrec)){
         my $imgurl="ViewProcessor/load/attachments/".
                    "$parentid/$rec->{fid}/$rec->{name}";
         $dataobj->ValidatedUpdateRecord($orgrec,{data=>$orgrec->{data}.
                  "<br clear=all>".
                  "<a href=\"$imgurl?inline=1\" target=_blank ".
                  "rel=\"lytebox[screenshot]\" title=\"$rec->{name}\">".
                  "<img class=thumbnail alt=\"$rec->{name}\" src=\"$imgurl\" ".
                  "align=right width=300 height=200 border=0></a>".
                  "$rec->{name}:<br>".
                  "<br>".
                  "<br clear=all>"},{faqid=>\$parentid});
      }
   }
}

sub SecureSetFilter
{  
   my $self=shift;
   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','up');
      return($self->SUPER::SecureSetFilter([{owner=>\$userid},
                                            {raclmode=>['read'],
                                             racltarget=>\'base::user',
                                             racltargetid=>[$userid], 
                                             published => ['1']},
                                            {raclmode=>['read'],
                                             racltarget=>\'base::grp',
                                             racltargetid=>[keys(%groups),-2], 
                                             published => ['1']},
                                            {waclmode=>['write'],
                                             wacltarget=>\'base::user',
                                             wacltargetid=>[$userid]},
                                            {waclmode=>['write'],
                                             wacltarget=>\'base::grp',
                                             wacltargetid=>[keys(%groups),-2]},
                                            {racltargetid=>[undef], 
                                             published => ['1']},
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
   my $from="faq left outer join faqacl as rfaqacl ".
            "on faq.faqid=rfaqacl.refid and ".
            "rfaqacl.aclmode='read' and ".
            "rfaqacl.aclparentobj='faq::article' ".
            "left outer join contact ownercontact ".
            "on faq.owner=ownercontact.userid ".
            "and ownercontact.cistatus=4 ".
            "left outer join faqacl as wfaqacl ".
            "on faq.faqid=wfaqacl.refid and ".
            "wfaqacl.aclmode='write' and ".
            "wfaqacl.aclparentobj='faq::article' ";
   $from=$self->extendSqlFrom($from,"faq.faqid");
   return($from);
}

sub getSqlGroup
{
   my $self=shift;
   return("faq.faqid");
}



sub isAnonymousAccessValid
{
    my $self=shift;
    return(1);
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
   if (effVal($oldrec,$newrec,"data") eq ""){
      $newrec->{data}=" ";
   }
   if (!defined($oldrec)){
      my $catid=$newrec->{faqcat};
      my $userid=$self->getCurrentUserId();
      if ($catid ne ""){
         my $catobj=getModuleObject($self->Config,'faq::category');
         my $foundwrite=0;
         my $writeok=0;
         CHK: while (defined($catid) && $catid ne '') {
            $catobj->SetFilter({faqcatid=>$catid});
            my ($d,$msg)=$catobj->getOnlyFirst(qw(acls parentid));
     
            foreach my $acl (@{$d->{acls}}) {
               if ($acl->{aclmode}=='add'){
                  $foundwrite++;
               }
               if ($acl->{aclmode}=='add' ||
                   $acl->{aclmode}=='admin'){
                  if ($acl->{acltarget}=='base::user' &&
                      $acl->{acltargetid}==$userid) {
                     $writeok=1;
                     last CHK;
                  }
                  elsif ($acl->{acltarget}=='base::grp' &&
                         $self->IsMemberOf($acl->{acltargetid})) {
                     $writeok=1;
                     last CHK;
                  }
               }
            }
            $catid=$d->{parentid};
         }
         if ($foundwrite){
            if (!$writeok){
               $self->LastMsg(ERROR,"insufficient rights to create ".
                                    "articles in requested catecory");
               return(0);
            }
         }
      }
      else{
         $self->LastMsg(ERROR,"no catecory defined");
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
   if (exists($newrec->{data})){
      my $tf=new HTML::TagFilter(strip_comments => 1,
                                 verbose=>1,
                                 skip_mailto_entification=>1,
                                 log_rejects => 1);  
      $tf->clear_rules();
      $tf->allow_tags({
                       strong=>{},
                       sup=>{}, sub=>{},
                       ol=>{type=>['any'=>[]]}, ul=>{}, li=>{},
                       h1=>{style=>[any=>[]]}, 
                       h2=>{style=>[any=>[]]}, 
                       h3=>{style=>[any=>[]]}, 
                       h4=>{style=>[any=>[]]}, 
                       h5=>{style=>[any=>[]]},
                       xmp=>{},
                       div=>{style=>[any=>[]]},
                       pre=>{},
                       code=>{},
                       em=>{},
                       img=>{src=>['any'=>[]],border=>['any'=>[]],
                             align=>['any'=>[]],
                             width=>['any'=>[]],
                             alt=>['any'=>[]],
                             '/'=>['/'],
                             height=>['any'=>[]],
                             class=>['any'=>[]]},
                       a=>{href=>['any'=>[]],
                           title=>['any'=>[]],
                           rel=>['any'=>[]],
                           target=>['any'=>[]]},
                       font=>{'any'=>[]},
                       hr=>{'/'=>['/']},
                       br=>{'/'=>['/'],
                            clear=>['all']},
                       span=>{style=>[any=>[]]},
                       p=>{align=> ['left','right','center'],
                           class=>[any=>[]],
                           style=>[any=>[]]},
                      });
      $newrec->{data}=$tf->filter($newrec->{data});
      my %e;
      foreach my $le ($tf->report()){
         if ($le->{reason} eq "tag"){
            $e{sprintf("faq article tag '%s' error",
                      $le->{tag})}++;
         }
         if ($le->{reason} eq "attribute"){
            $e{sprintf("faq article tag '%s' attr '%s' val='%s'",
                      $le->{tag},$le->{attribute},$le->{value})}++;
         }
      }
      #if (keys(%e) && !grep(/FORCE_SAVE_ARTICLE/,$newrec->{data})){
      #   $self->LastMsg(ERROR,"no FORCE_SAVE_ARTICLE and invalid html tags\n".
      #                        join("\n",keys(%e)));
      #   return(0);
      #}
      $newrec->{data}=~s/FORCE_SAVE_ARTICLE//g;
   }
   if (exists($newrec->{data})){
      $newrec->{data}=~s/(^|[^>])FAQ(\d{10,20})([^<]|$)/<i>FAQ$2<\/i>/gi;
   }
   return(1);
}


sub allowAnonymousByIdAccess
{
   my $self=shift;
   my $id=shift;
   return(1);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","header") if (!defined($rec));

   if ($ENV{REMOTE_USER} eq "anonymous"){
      my $acl=getModuleObject($self->Config,"faq::acl");
      $acl->SetFilter({aclparentobj=>\'faq::article',
                       refid=>\$rec->{faqid}});
      my $annook=0;
      foreach my $arec ($acl->getHashList(qw(ALL))){
         if ($arec->{aclmode} eq "read" &&
             $arec->{acltarget} eq "base::grp" &&
             $arec->{acltargetid} eq "-2"){
            $annook=1;
            last;
         }
      }
      if (!$annook){
         return();
      }
   }
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


   # write access for category admins
   my $catobj=getModuleObject($self->Config,'faq::category');
   my $catid=$rec->{faqcat};

   while (defined($catid) && $catid ne '') {
      $catobj->SetFilter({faqcatid=>$catid});
      my ($d,$msg)=$catobj->getOnlyFirst(qw(acls parentid));

      foreach my $acl (@{$d->{acls}}) {
         if ($acl->{aclmode}=='admin' &&
             $acl->{acltarget}=='base::user' &&
             $acl->{acltargetid}==$userid) {
            return("default","acl","attachments");
         }
         elsif ($acl->{aclmode}=='admin' &&
                $acl->{acltarget}=='base::grp' &&
                $self->IsMemberOf($acl->{acltargetid})) {
            return("default","acl","attachments");
         }
      }

      $catid=$d->{parentid};
   }
   

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

   $self->resetVoteLink($id); 
   my $url=$self->getAbsolutByIdUrl($id);
   $url=~s#/public/#/auth/#g;
   my $lang=$self->Lang();
   my $userid=$self->getCurrentUserId();

   if (effVal($oldrec,$newrec,"published") eq "1"){
      my %p=(eventname=>'faqchanged',
             spooltag=>'faqchanged-'.$id,
             redefine=>'1',
             retryinterval=>600,
             firstcalldelay=>3600,
             eventparam=>$id.";".$url.";".$lang,
             userid=>$userid);
      my $res;
      if ($self->isDataInputFromUserFrontend() && 
          !defined($newrec->{viewcount})){
         if (defined($res=$self->W5ServerCall("rpcCallSpooledEvent",%p)) &&
            $res->{exitcode}==0){
            msg(INFO,"FaqModifed Event sent OK");
         }
         else{
            msg(ERROR,"FaqModifed Event sent failed");
         }
      }
   }
   
   if (!defined($oldrec)) {
      my $faqid = $newrec->{'faqid'};
      my $userid = $newrec->{'owner'};
      my $faqacl = getModuleObject($self->Config, 'faq::acl');
      $faqacl->SetFilter({
         'refid'        => $faqid,
         'aclparentobj' => \'faq::article',
         'acltargetid'  => $userid,
         'acltarget'    => \'base::user',
         'aclmode'      => \'write'
      });
      my ($faqaclrec, $msg) = $faqacl->getOnlyFirst(qw(aclid));
      if (!defined($faqaclrec)) {
         my $acl = {
            'aclparentobj' => 'faq::article',
            'aclmode'      => 'write',
            'acltargetid'  => $userid,
            'acltarget'    => 'base::user',
            'refid'        => $faqid,
            'comments'     => 'write permission by creation of faq article'
         };
         $faqacl->ValidatedInsertRecord($acl);
      }
   }

   return($self->SUPER::FinishWrite($oldrec,$newrec));
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->resetVoteLink($oldrec->{faqid}); 
   return($bak);
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


sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   if (defined($rec)){
      if ($ENV{REMOTE_USER} ne "anonymous"){
         return($self->SUPER::getHtmlDetailPages($p,$rec),
                "FView"=>$self->T("Full-View"));
      }
      return("FView"=>$self->T("Full-View"));
   }
   return($self->SUPER::getHtmlDetailPages($p,$rec));
}


sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;

   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "FView");
   $self->HandleLastView("HtmlDetail",$rec) if ($p eq "StandardDetail");

   if ($p eq "FView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();
      $page="<link rel=\"stylesheet\" ".
            "href=\"../../../static/lytebox/lytebox.css\" ".
            "type=\"text/css\" media=\"screen\" />";
      #######################################################################
      # Voting GUI Test
      $page.=$self->extendHtmlDetailPageContent("../..",0,$rec);
      #######################################################################

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
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
   my ($rec,$msg)=$self->getOnlyFirst(qw(name data attachments viewcount faqid
                                         furtherkeys kwords viewfreq viewlast
                                         owner owneremail
                                         mdate editor realeditor));

   if (defined($rec)){
      if (!$self->isViewValid($rec)){
         print($self->noAccess());
         return(undef);
      }
      $self->HandleLastView("FullView",$rec);
   }
   else{
      print($self->noAccess());
      return(undef);
   }
   my $further;
   if ($ENV{REMOTE_USER} ne "anonymous") {
      if ($rec->{furtherkeys} ne ""){
         $further=$self->getFurtherArticles(
            $rec->{furtherkeys},0,$rec->{faqid});
      }
      else{
         $further=$self->getFurtherArticles(
            $rec->{name},1,$rec->{faqid});
      }
   }
  

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
   if ($rec->{uservotelevel}<-1000){
      printf("<font color='red' size=3>%s</font><br>",
             $self->T("WARNING: This document is potentially in a bad".
                      " quality or out of date!"));
   }
   print("<div class=fullview style=\"padding-bottom:10px\">".
         "<a target=_blank class=WindowTitle ".
         "href=\"ById/$rec->{faqid}\" ".
         "title=\"".$self->T("use this link to reference this ".
         "record (f.e. in mail)")."\"><div id=WindowTitle>".
         $rec->{name}."</div></a></div>");
   my $fo=$self->getField("data",$rec);
   my $d=$fo->FormatedResult($rec,"HtmlV01"); # get HTML Code without scrollbar
   $d=ExpandW5BaseDataLinks($self,"HtmlDetail",$d);

   print("<div class=fullview>".$d."</div>");

   print("<div class=authorline>");

   my $fldobj=$self->getField("owner",$rec);
   my $downer=$fldobj->FormatedResult($rec,"HtmlDetail");

   my $fldobj=$self->getField("creator",$rec);
   my $d=$fldobj->FormatedResult($rec,"HtmlDetail");
   if ($d ne "NONE" && $downer ne $d){
      print(" created by ".$d) if ($d ne "");
   }

   print("<br>modified by ".$downer) if ($downer ne "" && $downer ne "NONE");

   my $fldobj=$self->getField("mdate",$rec);
   my $d=$fldobj->FormatedResult($rec,"HtmlV01");
   print(" at ".$d) if ($d ne "");


   my $fldobj=$self->getField("owneremail",$rec);
   my $owneremail=$fldobj->RawValue($rec);
   if ($owneremail ne ""){
      my $qs=kernel::cgi::Hash2QueryString(to=>$owneremail,
                               id=>$rec->{faqid},
                               subject=>"Feedback: ".$rec->{name},
                               parent=>$self->Self());
      my $onclick="openwin('../../base/workflow/externalMailHandler?$qs',".
                  "'_blank',".
                  "'height=640,width=800,toolbar=no,status=no,".
                  "resizable=yes,scrollbars=no')";
     
      my $feedbacktext=$self->T("feedback to last editor");
      my $clickfeedback=$self->T("click to send feedback to last editor");
      print("<span class=noprint style=\"margin:0;padding:0\">".
            "<br><span class=sublink title=\"$clickfeedback\" ".
            "onclick=\"$onclick\">${feedbacktext} ".
            $owneremail."</span></span>");
   }

   print("<br>powered by W5Base technology<br><br>");

   print("</div>");
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
         if ($frec->{label}=~m/\.zip$/i){
            $att.="\n<tr><td width=1%><a class=attlink href=\"$frec->{href}\">".
                  "<img src=\"../load/zip_icon.gif\"></a></td>".
                  "<td><a class=attlink href=\"$frec->{href}\">".
                  "$frec->{label}</a></td></tr>";
         }
      }
      if ($att ne ""){
         print("<div class=attachments>".
               "<table width=\"100%\">".$att."</table></div>");
      }
   }
   my $owner=$self->findtemplvar({current=>$rec,mode=>"HtmlDetail"},
                                  "owner","formated");
   my $mdate=$self->findtemplvar({current=>$rec,mode=>"HtmlV01"},
                                  "mdate","formated");
#   print("<div id=WindowSignature>$owner<br>$mdate</div>");
   if ($ENV{REMOTE_USER} ne "anonymous" && $further ne ""){
      print($further);
   }
   print(<<EOF);
<script type="text/javascript" src="../../../static/lytebox/lytebox.js"></script>
<link rel="stylesheet" href="../../../static/lytebox/lytebox.css" type="text/css" media="screen" />

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

   print $self->HtmlPersistentVariables($self->IdField()->Name());

   print $self->HtmlBottom(body=>1,form=>1);
}

sub getRawArticles
{
   my $self=shift;
   my $words=shift;
   my $further="";

   $self->ResetFilter();
   $self->SecureSetFilter({kwords=>$words});
   $self->Limit(11);
   my @fl=$self->getHashList(qw(mdate faqid name urlofcurrentrec));

   foreach my $frec (@fl){
      my $label=$frec->{name};
      $further.=$label."\n";
      $further.=$frec->{urlofcurrentrec}."\n\n";
   }
   if ($further ne ""){
      $further="\n\n".$self->T("related FAQ-articles").":\n".$further;
   }

   return($further);
}


sub getFurtherArticles
{
   my $self=shift;
   my $words=shift;
   my $wordMode=shift;
   my $excludeFAQ=shift;
   $wordMode=0 if (!defined($wordMode));
   my @fl;
   my $further="";
   $excludeFAQ=[] if (!defined($excludeFAQ));
   $excludeFAQ=[$excludeFAQ] if (ref($excludeFAQ) ne "ARRAY");

   my $langstr=$self->Lang();
   $langstr="en" if ($langstr eq "");
   $langstr.=" multilang";

   if ($words ne ""){
      if (!$wordMode){
         $self->ResetFilter();
         $self->SecureSetFilter({kwords=>$words,lang=>$langstr});
         $self->Limit(11);
         @fl=$self->getHashList(qw(mdate faqid name));
      }
      else{
         my @kw=grep(/^\S{3,100}$/,split(/[\s\/,]/,$words));
         if ($#kw==-1 && $words ne ""){
            @kw=($words);
         }
         if ($#kw>-1){
            my @ll;
            my @not=qw(mit einer einen eines der die das ich du er sie es wir
                       durch andere anderes infos info aus wie wird
                       auf in dem dessen ab meinen im gehe gehen vom wie was
                       und nicht für voll nach bringen bringt oder bei
                       finden finde greift gegeben zur nur 
                       ihr euer werden wird kann man muß eingegeben
                       the any for out);
            foreach my $keyword (@kw){
               my $qkeyword=quotemeta($keyword);
               next if (grep(/^$qkeyword$/i,@not));
               $self->ResetFilter();
               $self->SecureSetFilter({kwords=>$keyword,lang=>$langstr});
               $self->Limit(11);
               my @kl=$self->getHashList(qw(mdate faqid name));
               if ($#kl!=-1){
                  push(@ll,\@kl);
               }
            }
            my %kl;
            foreach my $kl (sort({$#{$a}<=>$#{$b}} @ll)){
               last if (keys(%kl)>10);
               foreach my $klrec (@$kl){
                  $kl{$klrec->{faqid}}=$klrec;
                  last if (keys(%kl)>10);
               }
            }
            if (keys(%kl)){
               @fl=values(%kl);
            }
         }
      }
   }
   foreach my $frec (@fl){
      next if (in_array($excludeFAQ,$frec->{faqid}));
      my $dest="../../faq/article/Detail?".
               "faqid=$frec->{faqid}&ModeSelectCurrentMode=FView";
      my $detailx=$self->DetailX();
      my $detaily=$self->DetailY();
      my $onclick="openwin(\"$dest\",\"_blank\",".
          "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
          "resizable=yes,scrollbars=no\")";
      my $label=$frec->{name};
      $label=~s/</&lt;/g;
      $label=~s/>/&gt;/g;
      $further.="<tr><td><ul><li><span class=sublink onclick=$onclick>".
                $label."</span></li></ul></td></tr>";
   }
   if ($further ne ""){
      my $label=$self->T("further FAQ-articles");
      if ((caller())[0] ne "faq::article"){
         $label=$self->T("related FAQ-articles");
      }
      $further="<div class=further>${label}:".
               "<table width=\"100%\">".$further."</table></div>";

   }
   return($further);
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


   if ($ENV{REMOTE_USER} eq "anonymous"){
      my $acl=getModuleObject($self->Config,"faq::acl");
      $acl->SetFilter({aclparentobj=>\'faq::article',
                       refid=>\$val});
      my $needauth=1;
      foreach my $arec ($acl->getHashList(qw(ALL))){
         if ($arec->{aclmode} eq "read" &&
             $arec->{acltarget} eq "base::grp" &&
             $arec->{acltargetid} eq "-2"){
            $needauth=0;
            last;
         }
      }
      if ($needauth){
         my $s=$self->Self();
         $s=~s/::/\//g;
         $self->HtmlGoto("../../../../auth/$s/Detail",
                         get=>{$idname=>$val,
                                ModeSelectCurrentMode=>'FView'}); 
         # HtmlGoto on get is needed, because a direct post in SSO
         # enviroment is not working to POSTs (it will redirected with
         # a location tag in header - and this will results in a GET - no
         # matter if form from HtmlGoto hast method=post
         return();
      }
   }
   $self->HtmlGoto("../Detail",post=>{$idname=>$val,
                                      ModeSelectCurrentMode=>'FView'});
   return();
}



sub HandleLastView
{
   my $self=shift;
   my $mode=shift;
   my $rec=shift;

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
   my %upd=(viewlast=>$now,
            viewfreq=>$viewfreq,
            viewcount=>$rec->{viewcount}+1);

   my @acl=$self->isWriteValid($rec);       # method to document, if a user
   if (in_array(\@acl,["default","ALL"])){  # with write rights has been 
      $upd{viewlastbywriter}=$now;          # viewed the article. This will
      $upd{viewlastbywriternotify}=undef;   # be later used for quality
   }                                        # check on faq articles

   if ($self->Config->Param("W5BaseOperationMode") ne "readonly"){
      $self->UpdateRecord(\%upd,{faqid=>\$rec->{faqid}});
   }
}

sub getDefaultHtmlDetailPage
{
   my $self=shift;

   my $d="";
   $d="StandardDetail" if ($d eq "" || $self->extractFunctionPath() eq "New");
   return($d);
}


sub initSearchQuery
{
   my $self=shift;
   my $lang=$self->Lang();
   
   if (!defined(Query->Param('search_lang'))){
     Query->Param('search_lang'=>
                  $self->T('multilang','faq::article').' '.$lang);
   }
}


sub HandleUserVote
{
   my $self=shift;
   my $faqrec=shift;
   my $voteval=shift;


   if ($voteval<0){
      printf STDERR ("HandleUserVote($voteval):\n%s\n",Dumper($faqrec));
      if ($faqrec->{ownerid}>0){
        my $emailto;
        my $user=getModuleObject($self->Config,"base::user");
        $user->SetFilter({userid=>\$faqrec->{ownerid}});
        my ($urec,$msg)=$user->getOnlyFirst(qw(email fullname lastlang));
        if (defined($urec) && $urec->{fullname} ne ""){
           $emailto=$urec->{email};
        }
        if (defined($urec) && $urec->{lastlang} ne ""){
           $ENV{HTTP_FORCE_LANGUAGE}=$urec->{lastlang};
        }
        my $wfa=getModuleObject($self->Config,"base::workflowaction");
        #my $subject="FAQ: ".$faqrec->{name};
        my $subject=$self->T("bad faq article vote");



        if ($emailto ne ""){

           my $tmpl=$self->getParsedTemplate("tmpl/VoteNotify",{
              static=>{
                 FAQNAME=>$faqrec->{name}
              }
           });
           $wfa->Notify( "WARN",$subject,$tmpl,
              emailfrom=>"\"W5Base-Notify\" <>",
              emailto=>$emailto,
              dataobj=>'faq::article',
              dataobjid=>$faqrec->{faqid},
              emailbcc=>[
                 11634953080001,   # HV
              ],
              emailcategory =>['faq',
                               'faq::article',
                               'badvote']
           );
        }
        delete($ENV{HTTP_FORCE_LANGUAGE});
      }
   }
}











1;
