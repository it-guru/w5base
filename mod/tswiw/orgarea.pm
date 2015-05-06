package tswiw::orgarea;
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
use kernel::DataObj::LDAP;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::LDAP);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->setBase("o=Organisation,o=WiW");
   $self->AddFields(
      new kernel::Field::Id(       name       =>'touid',
                                   label      =>'tOuID',
                                   size       =>'10',
                                   align      =>'left',
                                   dataobjattr=>'tOuID'),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Orgarea-Name (tOuLD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuLD'),

      new kernel::Field::Text(     name       =>'shortname',
                                   label      =>'Orgarea-ShortName (tOuSD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuSD'),

      new kernel::Field::Text(   name       =>'sapid',
                                 label      =>'SAP-OrganisationalID (tOuSapID)',
                                 dataobjattr=>'tOuSapID'),

      new kernel::Field::TextDrop( name       =>'parent',
                                   label      =>'Parentgroup (tOuSuperior)',
                                   vjointo    =>'tswiw::orgarea',
                                   vjoinon    =>['parentid'=>'touid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::TextDrop( name       =>'bossfullname',
                                   label      =>'Boss',
                                   vjointo    =>'tswiw::user',
                                   depend     =>['mgrwiwid'],
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'fullname'),

      new kernel::Field::TextDrop( name       =>'boss',
                                   label      =>'Boss (tOuMgr)',
                                   vjointo    =>'tswiw::user',
                                   depend     =>['mgrwiwid'],
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'id'),

      new kernel::Field::TextDrop( name       =>'bosssurname',
                                   label      =>'Boss (surname)',
                                   htmldetail =>0,
                                   searchable =>0,
                                   vjointo    =>'tswiw::user',
                                   depend     =>['mgrwiwid'],
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'surname'),

      new kernel::Field::TextDrop( name       =>'bossgivenname',
                                   label      =>'Boss (givenname)',
                                   htmldetail =>0,
                                   searchable =>0,
                                   depend     =>['mgrwiwid'],
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'givenname'),

      new kernel::Field::TextDrop( name       =>'bossemail',
                                   label      =>'Boss (email)',
                                   htmldetail =>0,
                                   searchable =>0,
                                   depend     =>['mgrwiwid'],
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['mgrwiwid'=>'id'],
                                   vjoindisp  =>'email'),

      new kernel::Field::SubList(  name       =>'users',
                                   label      =>'Users',
                                   group      =>'userro',
                                   vjointo    =>'tswiw::user',
                                   vjoinon    =>['touid'=>'touid'],
                                   vjoindisp  =>['surname','givenname',
                                                 'email','office_phone']),

      new kernel::Field::Text(     name       =>'parentid',
                                   label      =>'ParentID (tOuSuperior)',
                                   dataobjattr=>'tOuSuperior'),

      new kernel::Field::Link(     name       =>'mgrwiwid',
                                   htmldetail =>0,
                                   dataobjattr=>'tOuMgr'),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
   );
   $self->setDefaultView(qw(touid name users));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDirectory(LDAP=>new kernel::ldapdriver($self,"tswiw"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{tswiw}));
   return(0);
}



sub SetFilterForQualityCheck
{  
   my $self=shift;
   my $stateparam=shift;
   my @view=@_;
   return(undef);
}
   


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
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
   return(undef);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ImportOrgarea 
                                                  doParentFix
                                                  TreeView
                                                  ParentGroupFix));
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "TView"=>$self->T("Tree View"));
}


sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "TView");
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
            "padding:0;margin:0\" frameborder=\"0\" ".
            "class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"TreeView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}


sub ImportOrgarea
{
   my $self=shift;

   my $importname=Query->Param("importname");
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
   #      Query->Delete("importname");
         $self->LastMsg(OK,"orgarea has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"WhoIsWho Import");
   print $self->getParsedTemplate("tmpl/minitool.orgarea.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}

#########################################################################
# minitool ParentGroupFix based on ajax technic to reconnect parent group
#
sub ParentGroupFix
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           js=>['J5Base.js'],body=>1,
                           title=>"WhoIsWho ParentGroupFix");
   print $self->getParsedTemplate("tmpl/minitool.orgarea.parentfix",{});
   print $self->HtmlBottom(body=>1);
}

sub doParentFix
{
   my $self=shift;

   print $self->HttpHeader("text/html",charset=>'utf-8');
   my $grpid=$self->Query->Param("grpid");
   if ($grpid eq ""){
      print("ERROR: no grpid sumited");
      return();
   }
   my $wiw=getModuleObject($self->Config,"tswiw::orgarea");
   my $grp=getModuleObject($self->Config,"base::grp");

   #
   # load current grprec vom w5base
   #
   $grp->ResetFilter();
   $grp->SecureSetFilter({grpid=>\$grpid});
   my ($grprec)=$grp->getOnlyFirst(qw(ALL));
   if (!$grprec){
      print("ERROR: grp not found");
      return();
   }
   if ($grprec->{srcid} eq ""){
      print("ERROR: no touid in srcid of grp");
      return();
   }
   #
   # load current parent from wiw
   #
   $wiw->SecureSetFilter({touid=>\$grprec->{srcid}});
   my ($wiwrec)=$wiw->getOnlyFirst(qw(parentid));

   if ($wiwrec->{parentid} eq ""){
      print("ERROR: no parentid found in wiw");
      return();
   }

   #
   # find new parent fullname
   #
   $grp->ResetFilter();
   $grp->SecureSetFilter({srcid=>\$wiwrec->{parentid},srcsys=>\'WhoIsWho'});
   my ($pgrprec)=$grp->getOnlyFirst(qw(fullname));
   if (!defined($pgrprec)){
      $self->Import({importname=>$wiwrec->{parentid}});
      $grp->ResetFilter();
      $grp->SecureSetFilter({srcid=>\$wiwrec->{parentid},srcsys=>\'WhoIsWho'});
      my ($pgrprec)=$grp->getOnlyFirst(qw(fullname));
      if (!defined($pgrprec)){
         if (!$self->LastMsg()){
            $self->LastMsg(ERROR,"can not create new parent group");
         }
         print(latin1(join("<hr>",grep(/ERROR/,$self->LastMsg())))->utf8());
         return();
      }
   }
   if ($pgrprec->{fullname} eq ""){
      print("ERROR: can not find valid parent groupname");
      return();
   }
   
   #
   # write new parent
   #

   if ($grp->SecureValidatedUpdateRecord($grprec,{parent=>$pgrprec->{fullname}},
                                         {grpid=>\$grprec->{grpid}})){

      $grp->ResetFilter();
      $grp->SecureSetFilter({grpid=>\$grpid});
      my ($grprec)=$grp->getOnlyFirst(qw(ALL));
      my $qcokobj=$grp->getField("qcok");
      my $qcok=$qcokobj->RawValue($grprec);
      if ($qcok){
         print("QCheck now OK");
      }
      else{
         print("QCheck still failed");
      }
      return();
   }
   print(join(";".$self->LastMsg()));
}

#########################################################################

sub Import
{
   my $self=shift;
   my $param=shift;

   my $orgid=$param->{importname};
   if (!($orgid=~m/^\S{3,10}$/)){
      $self->LastMsg(ERROR,"invalid name specified");
      return(undef);
   }
   my @idimp;
   my $wiw=getModuleObject($self->Config,"tswiw::orgarea");
   my $grp=getModuleObject($self->Config,"base::grp");

   my $ok=0;
   my $chkid=$orgid;
   while($#idimp<20){
      $wiw->ResetFilter();
      $wiw->SetFilter({touid=>\$chkid});
      my ($wiwrec)=$wiw->getOnlyFirst(qw(ALL));
      if (defined($wiwrec)){
         $grp->ResetFilter();
         $grp->SetFilter({srcid=>\$wiwrec->{touid},srcsys=>\'WhoIsWho'});
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){ # ok, grp already exists in W5Base
            $self->LastMsg(INFO,"$wiwrec->{touid} = $grprec->{fullname}");
            last;
         }
         else{
            msg(INFO,"wiwid $wiwrec->{touid} not found in W5Base");
            push(@idimp,$wiwrec->{touid});
         }
         $chkid=$wiwrec->{parentid};
         last if ($chkid eq "");
      }
      else{
         $self->LastMsg(ERROR,"invalid orgid $chkid in tree");
         return(undef);
      }
   }
   foreach my $wiwid (reverse(@idimp)){
      $wiw->ResetFilter();
      $wiw->SetFilter({touid=>\$wiwid});
      my ($wiwrec)=$wiw->getOnlyFirst(qw(ALL));
      if (defined($wiwrec)){
         my $grprec;
         $grp->ResetFilter();
         if ($wiwrec->{parentid} ne ""){
            $grp->SetFilter({srcid=>\$wiwrec->{parentid},
                             srcsys=>\'WhoIsWho'});
         }
         else{
            $grp->SetFilter({fullname=>\'DTAG.TSI'});
         }
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){

            my $newname=$wiwrec->{shortname};
            if ($newname eq ""){
               $self->LastMsg(ERROR,"no shortname for ".
                                    "id '$wiwrec->{touid}' found");
               return(undef);
            }
            $newname=~s/[\/\s]/_/g;    # rewriting for some shit names
            $newname=~s/&/_u_/g;
            my %newgrp=(name=>$newname,
                        srcsys=>'WhoIsWho',
                        srcid=>$wiwrec->{touid},
                        parentid=>$grprec->{grpid},
                        cistatusid=>4,
                        srcload=>NowStamp(),
                        comments=>"Description from WhoIsWho: ".
                                  $wiwrec->{name});
            #msg(DEBUG,"Write=%s",Dumper(\%newgrp));
            if (my $back=$grp->ValidatedInsertRecord(\%newgrp)){
               $ok++;    
               msg(DEBUG,"ValidatedInsertRecord returned=$back");
               $grp->ResetFilter();
               $grp->SetFilter({grpid=>\$back});
               my ($grprec)=$grp->getOnlyFirst(qw(ALL));
               if ($grprec){
                  $self->LastMsg(INFO,"$grprec->{srcid} = $grprec->{fullname}");
               }
           
            }
           # printf STDERR ("wiwrec=%s\n",Dumper($wiwrec));
           # printf STDERR ("grprec=%s\n",Dumper($grprec));
           # printf STDERR ("fifi importing $wiwid\n");
         }
         else{
            printf STDERR ("fifi parentid $wiwrec->{parentid} not found\n");
         }
      }
   }
   if ($ok==$#idimp+1){
      return(1);
   }
   $self->LastMsg(ERROR,"one or more operations failed");
   return(undef);
}

sub TreeView
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));


   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"TreeView",
                           js=>['toolbox.js'],
                           IEedge=>1,
                           body=>1,
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css']);
   if (defined($rec)){
      my @parents;
      my @childs;
      my $parent=$rec->{parentid};
      while($parent ne ""){
         $self->ResetFilter();
         $self->SecureSetFilter({touid=>\$parent});
         my ($rec,$msg)=$self->getOnlyFirst(qw(touid name parentid shortname
                                               bosssurname bossgivenname));
         if (defined($rec)){
            unshift(@parents,$rec);
            $parent=$rec->{parentid};
         }
         else{
            $parent=undef;
         }
      }
      $self->ResetFilter();
      $self->SecureSetFilter({parentid=>\$rec->{touid}});
      @childs=$self->getHashList(qw(touid name parentid shortname
                                    bosssurname bossgivenname));


      print("<div id=\"orgtree\" style=\"min-width:400px;margin:5px;margin-top:15px\">");

      printf("<div id=\"parents\" style=\"width:100%%;text-align:center\">");
      my $level=0;
      foreach my $prec (@parents){
         displayOrg($prec,$level);
         $level++;
         print("<br>");
      }
      printf("</div>");

      printf("<div id=\"current\" style=\"width:100%%;text-align:center;\">");
   printf("<div style=\"width:1px;;border-left:1px solid #aaa;margin-left:50%;height:20px\"></div>");
      printf("<div style=\"padding-left:40px;padding-right:40px\">");
      printf("<div style=\"border-style:solid;border-width:1px;display:inline-block;".
          "border-color:black;height:80px;width:100%;\">");


      print($rec->{name});
      printf("</div>");
      printf("</div>");
      printf("</div>");

      $level++;


      printf("<div id=\"childs\" style=\"width:100%%;text-align:center\">");
      foreach my $crec (@childs){
         displayOrg($crec,$level);

      }
      printf("</div>");

      printf("</div>"); # end of orgtree
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub displayOrg
{
   my $prec=shift;
   my $level=shift;

   printf("<div style=\"display: inline-block;".
          "margin-left:5px;margin-right:5px;margin-top:0px\">");
   if ($level!=0){
      printf("<div style=\"width:1px;border-left:1px solid #aaa;margin-left:50%;height:20px\"></div>");
   }
   printf("<div style=\"border-style:solid;border-width:1px;display: inline-block;".
          "border-color:black;width:280px;height:80px;\">");
   print("<table border=1 height=100% width=100%>");
   my $label=$prec->{name};
   if ($prec->{shortname} ne ""){
      $label.="<br>(".$prec->{shortname}.")";
   }
   printf("<tr height=1%%><td align=center><b>%s</b></td></tr>",$label);
   my $boss=$prec->{bosssurname};
   $boss.=", " if ($boss ne "" && $prec->{bossgivenname} ne "");
   $boss.=$prec->{bossgivenname}; 
   printf("<tr><td valign=top>%s<br>&nbsp;</td></tr>",$boss);
   print("</table>");
   
   printf("</div>");
   printf("</div>");
}


1;
