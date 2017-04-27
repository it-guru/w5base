package base::iomap;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free iomap; you can redistribute it and/or modify
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB
        kernel::CIStatusTools);


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
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'iomap.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'Data-Object',
                dataobjattr   =>'iomap.dataobject'),

      new kernel::Field::Text(
                name          =>'queryfrom',
                label         =>'queryed from',
                dataobjattr   =>'iomap.queryfrom'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Rule label',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'iomap.fullname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Number(
                name          =>'mapprio',
                htmleditwidth =>'40%',
                default       =>'10000',
                label         =>'Map-Prio',
                sqlorder      =>'asc',
                dataobjattr   =>'iomap.mapprio'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'iomap.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'iomap.comments'),
   
      new kernel::Field::Text(
                name          =>'on1field',
                group         =>'criterion',
                label         =>'Field 1 name',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on1exp',
                group         =>'criterion',
                label         =>'Field 1 expresion',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on2field',
                group         =>'criterion',
                label         =>'Field 2 name',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on2exp',
                group         =>'criterion',
                label         =>'Field 2 expresion',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on3field',
                group         =>'criterion',
                label         =>'Field 3 name',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on3exp',
                group         =>'criterion',
                label         =>'Field 3 expresion',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on4field',
                group         =>'criterion',
                label         =>'Field 4 name',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on4exp',
                group         =>'criterion',
                label         =>'Field 4 expresion',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on5field',
                group         =>'criterion',
                label         =>'Field 5 name',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'on5exp',
                group         =>'criterion',
                label         =>'Field 5 expresion',
                container     =>'criterion'),

      new kernel::Field::Text(
                name          =>'op1field',
                group         =>'operation',
                label         =>'operation Field 1 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op1exp',
                group         =>'operation',
                label         =>'operation Field 1 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op2field',
                group         =>'operation',
                label         =>'operation Field 2 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op2exp',
                group         =>'operation',
                label         =>'operation Field 2 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op3field',
                group         =>'operation',
                label         =>'operation Field 3 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op3exp',
                group         =>'operation',
                label         =>'operation Field 3 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op4field',
                group         =>'operation',
                label         =>'operation Field 4 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op4exp',
                group         =>'operation',
                label         =>'operation Field 4 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op5field',
                group         =>'operation',
                label         =>'operation Field 5 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op5exp',
                group         =>'operation',
                label         =>'operation Field 5 expresion',
                container     =>'operation'),


      new kernel::Field::Container(
                name          =>'criterion',
                label         =>'criterion',
                dataobjattr   =>'iomap.criterion'),

      new kernel::Field::Container(
                name          =>'operation',
                label         =>'operation',
                dataobjattr   =>'iomap.operation'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'iomap.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'iomap.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'iomap.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'iomap.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'iomap.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'iomap.realeditor'),
   

   );
   $self->setDefaultView(qw(mapprio queryfrom dataobj fullname comments));
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.base.iomap"],
                         uniquesize=>255};
   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->setWorktable("iomap");
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/iomap.jpg?".$cgi->query_string());
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $queryfrom=effVal($oldrec,$newrec,"queryfrom");
   if (!($queryfrom=~m/^\S+::\S+$/) &&
         $queryfrom ne "preWrite"     &&
         $queryfrom ne 'any'){
      $self->LastMsg(ERROR,"invalid value in 'queryfrom'");
      return(0);
   }

   my $oldfullname=$oldrec->{fullname};
   my $fullname="";
   for(my $fno=1;$fno<=5;$fno++){
      my $n=effVal($oldrec,$newrec,"on".$fno."field");
      my $v=effVal($oldrec,$newrec,"on".$fno."exp");
      if ($n ne "" && $v ne ""){
         $fullname.=" " if ($fullname ne "");
         $v=~s/ /_/g;
         $fullname.="$n=$v";
      }
   }
   $fullname=~s/[^a-z,0-9,\/,= ]/_/ig;
   $fullname=~s/__/_/g;
   $fullname=~s/__/_/g;
   $fullname=~s/__/_/g;
   $fullname=~s/\/_/\//g;
   $fullname=~s/_\//\//g;
   $fullname=limitlen($fullname,60,1);
   if ($oldfullname ne $fullname){
      $newrec->{fullname}=$fullname;
   }
   


   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default criterion operation source));
}


sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "IOMap"=>$self->T("IOMap"));
}

sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"IOMap","MapTester");
}

sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "IOMap");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "IOMap"){
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
            "src=\"IOMap?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}



sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default","criterion","operation") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","criterion","operation") if (!defined($rec));
   return("ALL");
}


sub isCopyValid
{
   my $self=shift;

   return(1);
}



sub IOMap   
{
   my $self=shift;

   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"TeamView",
                           js=>['toolbox.js'],
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css']);
   printf("OK - comming sone");

}

sub Welcome
{
   my $self=shift;

   return($self->MapTester());
}

sub getValidWebFunctions
{
   my $self=shift;
   return("MapTester",
          $self->SUPER::getValidWebFunctions());
}


sub MapTester   
{
   my $self=shift;
   my $debug;
   my $mapsize=6;
   if (Query->Param("search_mapsize")){
      $mapsize=Query->Param("search_mapsize");
      $mapsize=3 if ($mapsize<3);
      $mapsize=10 if ($mapsize>10);
   }

   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"IO Map Tester",
                           js=>['toolbox.js'],
                           body=>1,form=>1,
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css']);

   my %q=$self->getSearchHash();
   my $d="";
   $d.="\n<table width=95%>";

   # line a
   $d.="<tr><td nowrap width=1%>".
       $self->getField("dataobj")->Label().
       "</td>";
   if ($q{databoj} eq ""){
      $self->ResetFilter();
      $self->SetFilter({cistatusid=>\'4'});
      my ($sd,$keylist,$vallist,$list)=
           $self->getHtmlSelect("search_dataobj","dataobj",["dataobj"],
                                autosubmit=>1,AllowEmpty=>1);     
      $d.="<td>".$sd."</td>";
   }
   else{
      $d.="<td>".$q{databoj}.$self->HtmlPersistentVariables("dataobj")."</td>";
   }
  # $d.="</tr>";

   # line b
   if ($q{dataobj} ne ""){
      $d.="<td nowrap width=1%>".
          $self->getField("queryfrom")->Label().
          "</td>";
      $self->ResetFilter();
      $self->SetFilter({dataobj=>\$q{dataobj}});
      my ($sd,$keylist,$vallist,$list)=
           $self->getHtmlSelect("search_queryfrom","queryfrom",["queryfrom"],
                                autosubmit=>1,AllowEmpty=>1);     
      $d.="<td>".$sd."</td>";
      $d.="</tr>\n";
   }
   $d.="</table>\n";

   if ($q{dataobj} ne "" && $q{queryfrom} ne ""){
      my $o=getModuleObject($self->Config,$q{dataobj});
      if (defined($o)){
         my @l=$o->getFieldList();
       #  $d.="<xmp>".Dumper(\@l)."</xmp>";
         $d.="\n<center>\n<table cellspacing=0 cellpadding=0 border=1 width=95%>";
         $d.="<tr>".
             "<th>Fieldname</th>".
             "<th>Query Value</th>".
             "<th>Mapped result</th>".
             "</tr>\n";
         my @outval;
         my %qrec;
         for(my $fno=1;$fno<=$mapsize;$fno++){
            my $fieldname=Query->Param("field".$fno);;
            if ($fieldname ne ""){
               my $inval="val$fno";
               $qrec{$fieldname}=Query->Param($inval);
            }
         }
         my %mrec;
         if (Query->Param("do")){
            if (keys(%qrec)){
               $debug.="DEBUG Start Log\n";
               %mrec=%qrec;
               my $projectmode=0;
               if (Query->Param("ProjectMode")){
                  $projectmode=1;
                  $debug.="process start in PROJECT mode\n";
               }
               else{
                  $debug.="process start in normal mode\n";
               }
               my $forcelike=0;
               if (Query->Param("ForceLike")){
                  $forcelike=1;
                  $debug.="process start in LIKE mode\n";
               }
               $o->getIOMap($q{queryfrom},1,$projectmode);  # bypass cache
               #$o->NormalizeByIOMap($q{queryfrom},\%mrec,DEBUG=>\$debug,
               #                                  ForceLikeSearch=>$forcelike);
               my @locid=$o->getIdByHashIOMapped($q{queryfrom},\%mrec,
                                          DEBUG=>\$debug,
                                          ForceLikeSearch=>$forcelike);
               $debug.="\n\nDEBUG End Log\n";
            }
         }

         for(my $fno=1;$fno<=$mapsize;$fno++){
            my @in;
            foreach my $fname (@l){
               push(@in,$fname,$fname);
            }

            my ($sd,$keylist,$vallist,$list)=
                 $self->getHtmlSelect("field".$fno,\@in,
                                      AllowEmpty=>1);     
            $d.="<tr>\n";
            $d.="<td width=200>".$sd."</td>";
            my $inval="val$fno";
            my $v=quoteHtml(Query->Param($inval));
            my $fieldname=Query->Param("field".$fno);
            my $mval=quoteHtml($mrec{$fieldname});
         
            $d.="<td><input size=20 type=text ".
                "style='width:100%' name=$inval value=\"$v\"></td>";
            $d.="<td><input size=20 disabled type=text ".
                "style='width:100%' value=\"$mval\"></td>";
            $d.="</tr>\n";
         }
         $d.="<tr>\n<td colspan=3><input type=submit name=do ".
             "value='process --&gt;' style=\"width:100%\"></td></tr>\n";
         $d.="</table>\n";
      }
   }

   my $p="<input type=checkbox name=ProjectMode";
   if (Query->Param("ProjectMode")){
      $p.=" checked";
   }
   $p.=">";

   my $l="<input type=checkbox name=ForceLike";
   if (Query->Param("ForceLike")){
      $l.=" checked";
   }
   $l.=">";

   
   print("<table height=100% width=100% border=0>");
   print("\n<tr height=1%><td valign=top nowrap align=center>".
         sprintf("<div style='text-align:center;cursor:pointer' ".
                "onclick=\"openwin('MapTester','_blank',".
                "'height=480,width=640,toolbar=no,status=no,".
                "resizeable=yes,scrollbars=no')\">".
                "<b>Map Tester</b></div> (project mode $p &bull; LikeMode $l)").
         "</td></tr>\n");
   printf("<tr height=1%><td valign=top>%s</td></tr>",$d);


   if (defined($debug)){
      my $out="";
      $out.="<div id=debug style=\"width:95%;text-align:left;margin-top:3px;".
          "background-color:lightgray;".
          "border-style:solid;border-color:gray;border-width:1px;".
          "height:1px;overflow:auto\">";
      $out.="<xmp>".$debug."</xmp>";
      $out.="</div>";
      printf("<tr id=l><td align=center valign=top>%s</td></tr>",$out);
   }
   else{
      printf("<tr><td valign=top>&nbsp;</td></tr>");
   }
   printf("</table>");
   print(<<EOF);
<style>
body{
   overflow:hidden;
}
</style>
<script language="JavaScript">
addEvent(window, "resize", DebugResize);
addEvent(window, "load", DebugResize);

function DebugResize(){
   var d=document.getElementById("debug");
   d.style.height="1";
   var l=document.getElementById("l");
   d.style.height=l.offsetHeight;
}


</script>
EOF

   print $self->HtmlBottom(body=>1,form=>1);
}



1;
