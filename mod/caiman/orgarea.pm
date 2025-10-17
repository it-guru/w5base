package caiman::orgarea;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use caiman::lib::Listedit;
@ISA=qw(caiman::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->setBase("ou=Organisation,o=dtag");
   $self->setLdapQueryPageSize(3499);
   $self->AddFields(
      new kernel::Field::Id(       name       =>'torgoid',
                                   label      =>'tOrgOID',
                                   size       =>'10',
                                   align      =>'left',
                                   dataobjattr=>'tOrgOID'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Orgarea-Name (tOuLD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuLD'),

      new kernel::Field::Text(     name       =>'shortname',
                                   label      =>'Orgarea-ShortName (tOuSD)',
                                   size       =>'10',
                                   dataobjattr=>'tOuSD'),

      new kernel::Field::Text(     name       =>'sapid',
                                   label      =>'SAP-OrganisationalID '.
                                                '(tOuSapID)',
                                   dataobjattr=>'tOuSapID'),

      new kernel::Field::Text(     name       =>'sisnumber',
                                   label      =>'SIS Number',
                                   weblinkto  =>\'caiman::organisation',
                                   weblinkon  =>['sisnumber'=>'sisnumber'],
                                   dataobjattr=>'tTSISnumber'),

      new kernel::Field::Text(     name       =>'kindoforg',
                                   label      =>'tkindOfOrg',
                                   dataobjattr=>'tkindOfOrg'),

#      new kernel::Field::Boolean(  name       =>'disabled',
#                                   value      =>['false','true'],
#                                   label      =>'inaktiv (tOuDisabled)',
#                                   dataobjattr=>'tOuDisabled'),

      new kernel::Field::Text(     name       =>'oulevel',     #eigentlich Mist
                                   label      =>'OrgUnit Level'. #da es nicht
                                                '(tOuLevel)',#das level inerhalb
                                   dataobjattr=>'tOuLevel'), #einer Organi. ist

      new kernel::Field::TextDrop( name       =>'bossfullname',
                                   label      =>'Boss',
                                   vjointo    =>'caiman::user',
                                   depend     =>['toumgr'],
                                   vjoinon    =>['toumgr'=>'tcid'],
                                   vjoindisp  =>'fullname'),

#      new kernel::Field::TextDrop( name       =>'boss',
#                                   label      =>'Boss (tOuMgr)',
#                                   vjointo    =>'caiman::user',
#                                   depend     =>['toumgr'],
#                                   vjoinon    =>['toumgr'=>'tcid'],
#                                   vjoindisp  =>'id'),

#      new kernel::Field::TextDrop( name       =>'bosssurname',
#                                   label      =>'Boss (surname)',
#                                   htmldetail =>0,
#                                   searchable =>0,
#                                   vjointo    =>'caiman::user',
#                                   depend     =>['toumgr'],
#                                   vjoinon    =>['toumgr'=>'tcid'],
#                                   vjoindisp  =>'surname'),

#      new kernel::Field::TextDrop( name       =>'bossgivenname',
#                                   label      =>'Boss (givenname)',
#                                   htmldetail =>0,
#                                   searchable =>0,
#                                   depend     =>['toumgr'],
#                                   vjointo    =>'caiman::user',
#                                   vjoinon    =>['toumgr'=>'tcid'],
#                                   vjoindisp  =>'givenname'),

#      new kernel::Field::TextDrop( name       =>'bossemail',
#                                   label      =>'Boss (email)',
#                                   htmldetail =>0,
#                                   searchable =>0,
#                                   depend     =>['toumgr'],
#                                   vjointo    =>'caiman::user',
#                                   vjoinon    =>['toumgr'=>'tcid'],
#                                   vjoindisp  =>'email'),
#


      new kernel::Field::SubList(  name       =>'users',
                                   label      =>'Users',
                                   group      =>'userro',
                                   vjointo    =>'caiman::user',
                                   vjoinon    =>['torgoid'=>'torgoid'],
                                   vjoinbase  =>{primary=>'true',
                                                 active=>'true'},
                                   htmllimit  =>50,
                                   vjoindisp  =>['fullname']),

      new kernel::Field::SubList(  name       =>'subunits',
                                   label      =>'Subunits',
                                   group      =>'subunits',
                                   vjointo    =>'caiman::orgarea',
                                   vjoinon    =>['torgoid'=>'parentid'],
                                   vjoindisp  =>['shortname','name']),

      new kernel::Field::TextDrop( name       =>'parent',
                                   label      =>'Parentgroup (tOuSuperior)',
                                   vjointo    =>\'caiman::orgarea',
                                   vjoinon    =>['parentid'=>'torgoid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::Text(     name       =>'parentid',
                                   label      =>'ParentID (tOuSuperior)',
                                   htmldetail =>'NotEmpty',
                                   dataobjattr=>'tOuSuperior'),

      new kernel::Field::Text(     name       =>'toumgr',
                                   label      =>'tOuMgr CAIMANID',
                                   htmldetail =>'NotEmpty',
                                   dataobjattr=>'tOuMgr'),

      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
   );
   $self->setDefaultView(qw(torgoid name shortname sapid sisnumber));
   return($self);
}



sub SetFilterForQualityCheck
{  
   my $self=shift;
   my @view=@_;
   return(undef);
}
   


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
}
         


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(doParentFix
                                                  TreeView
                                                  ParentGroupFix));
}

#sub getHtmlDetailPages
#{
#   my $self=shift;
#   my ($p,$rec)=@_;
#
#   return($self->SUPER::getHtmlDetailPages($p,$rec),
#          "TView"=>$self->T("Organisation"));
#}


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
#      $page="<link rel=\"stylesheet\" ".
#            "href=\"../../../static/lytebox/lytebox.css\" ".
#            "type=\"text/css\" media=\"screen\" />";

      $page.="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" frameborder=\"0\" ".
            "class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"TreeView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}





sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_disabled"))){
     Query->Param("search_disabled"=>"\"".$self->T("boolean.false")."\"");
   }
}





#sub ImportOrgarea
#{
#   my $self=shift;
#
#   my $importname=Query->Param("importname");
#   if (Query->Param("DOIT")){
#      if ($self->Import({importname=>$importname})){
#   #      Query->Delete("importname");
#         $self->LastMsg(OK,"orgarea has been successfuly imported");
#      }
#      Query->Delete("DOIT");
#   }
#
#
#   print $self->HttpHeader("text/html");
#   print $self->HtmlHeader(style=>['default.css','work.css',
#                                   'kernel.App.Web.css'],
#                           static=>{importname=>$importname},
#                           body=>1,form=>1,
#                           title=>"WhoIsWho Import");
#   print $self->getParsedTemplate("tmpl/minitool.orgarea.import",{});
#   print $self->HtmlBottom(body=>1,form=>1);
#}

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
   my $caiman=getModuleObject($self->Config,"caiman::orgarea");
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
      print("ERROR: no torgoid in srcid of grp");
      return();
   }
   #
   # load current parent from caiman
   #
   $caiman->SecureSetFilter({torgoid=>\$grprec->{srcid}});
   my ($caimanrec)=$caiman->getOnlyFirst(qw(parentid));

   if ($caimanrec->{parentid} eq ""){
      print("ERROR: no parentid found in caiman");
      return();
   }

   #
   # find new parent fullname
   #
   $grp->ResetFilter();
   $grp->SecureSetFilter({srcid=>\$caimanrec->{parentid},srcsys=>\'CAIMAN'});
   my ($pgrprec)=$grp->getOnlyFirst(qw(fullname));
   if (!defined($pgrprec)){
      my $orgareaImport=$self->ModuleObject('caiman::ext::orgareaImport');
      $orgareaImport->processImport($caimanrec->{parentid},'srcid',{quiet=>1});
      #$self->Import({importname=>$caimanrec->{parentid}});
      $grp->ResetFilter();
      $grp->SecureSetFilter({srcid=>\$caimanrec->{parentid},srcsys=>\'CAIMAN'});
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


sub getGrpIdOf
{
    my $self=shift;
    my $caimanrec=shift;

    my $grp=getModuleObject($self->Config,"base::grp");

    $grp->SetFilter({srcid=>\$caimanrec->{torgoid},srcsys=>'CAIMAN'});
    $grp->SetCurrentView(qw(grpid srcid srcsys srcload));
    my ($rec,$msg)=$grp->getFirst();
    if (defined($rec)){
       return($rec->{grpid});
    }
    else{
       my $orgareaImport=$self->ModuleObject('caiman::ext::orgareaImport');
       my $lastimportedgrpid=$orgareaImport->processImport(
           $caimanrec->{torgoid}, 'srcid', {quiet=>1}
       );
       return($lastimportedgrpid);
       #return($self->Import({importname=>$caimanrec->{torgoid},silent=>1}));
    }
}


sub TreeView
{
   my $self=shift;
   my $g=new HTML::TreeGrid(
      fullpage=>0,
      grid_minwidth=>600,
      entity_color=>'#e0e0e0',
      label=>'',
   );



   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));


   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"Org:".$rec->{shortname},
                           js=>['toolbox.js'],
                           IEedge=>1,
                           body=>1,
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'kernel.App.Web.DetailPage.css']);
   print(<<EOF);
<script language="JavaScript">
function setTitle()
{
   parent.document.title=window.document.title;
}
addEvent(window, "load", setTitle);
</script>
EOF
   if (defined($rec)){
      my @parents;
      my @childs;
      my $parent=$rec->{parentid};
      while($parent ne ""){
         $self->ResetFilter();
         $self->SecureSetFilter({torgoid=>\$parent});
         my ($rec,$msg)=$self->getOnlyFirst(qw(torgoid name parentid shortname
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
      $self->SecureSetFilter({parentid=>\$rec->{torgoid}});
      @childs=$self->getHashList(qw(torgoid name parentid shortname
                                    bosssurname bossgivenname));

      #######################################################################
      my %hiddenchilds;
      my @hiddencheck;
      foreach my $crec (@childs){
         if ($crec->{torgoid} ne ""){
            push(@hiddencheck,$crec->{torgoid});
         }
      }
      if ($#hiddencheck!=-1){
         $self->ResetFilter();
         $self->SecureSetFilter({parentid=>join(" ",@hiddencheck)});
         my @chkchilds=$self->getHashList(qw(torgoid parentid));
         foreach my $crec (@chkchilds){
            $hiddenchilds{$crec->{parentid}}++; 
         }
      }
      #######################################################################

      my @toppos;
      my @curpos;
      my $row=2;
      my $col=10;
      @toppos=($col,$row);
      foreach my $o (@parents){
         $self->displayOrg($g,$col,$row,$o);
         $row+=8;
      }
      $row+=1;
      #######################################################################

      @curpos=($col,$row);
      $self->displayOrg($g,$col,$row,$rec,{
          current=>1,
      });
      $row+=9;
      #######################################################################

      $g->Line(@toppos,@curpos);
      for(my $c=0;$c<=$#childs;$c++){
         my $col=15;
         if (int(($c+1)/2)!=($c+1)/2){ # ungerade
            $col=5;
         }
         $self->displayOrg($g,$col,$row,$childs[$c]);
         $g->Line(@curpos,$curpos[0],$row-1);
         $g->Line($curpos[0],$row-1,$col,$row-1);
         $g->Line($col,$row-1,$col,$row);
         if (exists($hiddenchilds{$childs[$c]->{torgoid}})){
            $g->Line($col,$row,$col,$row+6);
            $self->displayFurtherLink($g,$col,$row+6);
         }
         if (int(($c+1)/2)==($c+1)/2){ # ungerade
            $row+=9;
         }
      }
      #######################################################################
      print($g->Render());
   }
   print $self->HtmlBottom(body=>1,form=>1);
}

sub displayFurtherLink
{
   my $self=shift;
   my $g=shift;   # Grid
   my $x=shift;  
   my $y=shift; 
   my $l="<div style='font-size:8px;text-align:center;".
         "border-style:solid;border-color:gray;border-width:1px'>";
   $l.="<b>. . .</b>";
   $l.="</div>";

   $g->SetBox($x,$y,20,$l);

}

sub displayOrg
{
   my $self=shift;
   my $g=shift;   # Grid
   my $x=shift;  
   my $y=shift; 
   my $prec=shift; 
   my $param=shift; 

   my $boss=$prec->{bosssurname};
   $boss.=", " if ($boss ne "" && $prec->{bossgivenname} ne "");
   $boss.=$prec->{bossgivenname}; 

   my $shortname=$prec->{shortname};
   my $eParam={};
   $eParam->{entity_width}=200;
   if ($param->{current}){
      $shortname="<b>".$shortname."</b>";
      $eParam->{entity_width}=220;
   }
   else{
      my $ac=Query->Param("AllowClose");
      my $lnk="<a target=_top class=SimpleLink ".
              "href=\"Detail?ModeSelectCurrentMode=TView&".
              "AllowClose=$ac&".
              "search_torgoid=".$prec->{torgoid}."\">";
      $shortname=$lnk.$shortname."</a>";
   }

   $g->SetEntity($x,$y,$eParam,
      Header=>$shortname,
      Description=>$prec->{name},
      Fooder=>$boss
   );
}











1;
