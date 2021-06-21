package faq::QuickFind;
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
use kernel::TemplateParsing;
@ISA=qw(kernel::App::Web kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Main
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'public/faq/load/QuickFind.css'],
                           title=>"FAQ QuickFind",
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   print $self->getParsedTemplate("tmpl/QuickFind",{
            translation=>'faq::QuickFind',
            static=>{
            }});
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub mobileWAP
{
   my $self=shift;
   my $s=Query->Param("search");
   my $d=<<EOF;
<p align="center">W5Base : Quickfind</p>
<p align="center">
Schl&#xFC;sselwort:<input type="text" value="$s" name="search" size="10"/>
<anchor>Suchen
<go href="mobileWAP" method="post">
<postfield name="search" value="\$(search)"/>
</go>
</anchor>
</p>
EOF
   if ($s ne ""){
      my $tag=undef;
      if (my ($stag,$stxt)=$s=~m/^\s*(\S+)\s*:\s*(\S+.*)\S*$/){
         if (!($stxt=~m/:/)){  # MAC Search
            $tag=lc($stag);
            $s=$stxt;
         }
      }
      my $searchtext=trim($s);
      my @s;
      $self->LoadSubObjs("QuickFind","QuickFind");
      foreach my $sobj (values(%{$self->{QuickFind}})){
         my $acl=$self->getMenuAcl($ENV{REMOTE_USER},
                                   $sobj->Self());
         if (defined($acl)){
            next if (!grep(/^read$/,@$acl));
         }
         if ($sobj->can("CISearchResult")){
            push(@s,$sobj->CISearchResult($tag,$searchtext));
         }
      }
      my %s;
      foreach my $srec (@s){
         push(@{$s{$srec->{group}}},$srec);
      }
      foreach my $group (sort(keys(%s))){
         $d.="<p><b>".quoteWap($group)."</b></p>";
         foreach my $srec (sort({$a->{name} cmp $b->{name}} @{$s{$group}})){
            $d.="<p>".quoteWap($srec->{name})."</p>";
         }
      }
   }
   printf STDERR ("d=%s\n",$d);
   print $self->HttpHeader("text/vnd.wap.wml");
   print $self->Wap($d);
   return(undef);
}

sub anyQuestions
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'mainwork.css',
                                   'public/faq/load/anyQuestions.css'],
                           title=>"any Questions",
                           js=>['toolbox.js','cookie.js'],
                           body=>1,form=>1);

   my $faq=getModuleObject($self->Config,"faq::article");
   my $lang=$self->Lang();



   $faq->SecureSetFilter({
     categorie=>'W5Base*',
     kwords=>'anyQuestions',
     lang=>'multilang '.$lang
   });

   my $cnt=0;

   foreach my $rec ($faq->getHashList(qw(name uservotelevel faqid))){
      if ($rec->{uservotelevel}>-100){
         my $class="normal"; 
         if ($rec->{uservotelevel}<0){
            $class="dimgray";
         }
         if ($cnt==0){
            printf("<center><table width=80%>");
         }
         my $n=$rec->{name};
         my $link=sprintf("javascript:openwin('%s','_blank',".
                       "'height=400,width=640,toolbar=no,".
                       "status=no,resizable=yes,scrollbars=auto')",
                       "../../faq/article/ById/".$rec->{faqid}); 
         $n=~s/^\d+[\s\.]*//;
         printf("<tr><td class=\"$class\">".
                "<button class=\"selBtn $class\" onclick=\"%s\">%s</button>".
                "</td></tr>",
                $link,$n);
         
         $cnt++;
      }
   }
   if ($cnt>0){
      printf("</table></center>");
   }
   else{
      printf("<center><div class=\"normal\">%s</div></center>",
         $self->T("Sorry, there are no answers for your questions"));
   }


   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub globalHelp
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           title=>"W5Base global search and help system",
                           target=>'Result',
                           action=>'Result',
                           js=>['toolbox.js','cookie.js'],
                           body=>1,form=>1);
   my $kwords=Query->Param("searchtext");
   my $autosearch=Query->Param("AutoSearch");
   $kwords=~s/"//g;
   my $result="Result";
   $result="Empty" if ($kwords ne "");
   $autosearch="0" if ($autosearch ne "1");
   my @stags=('ci'=>$self->T("Config Item search"),
              'article'=>$self->T("FAQ article search"),
              'forum'=>$self->T("Forum fulltext search"));

   $self->LoadSubObjs("QuickFind","QuickFind");
   my @s;
   foreach my $sobj (values(%{$self->{QuickFind}})){
      if ($sobj->can("ExtendStags")){
         $sobj->ExtendStags(\@stags);
      }
   }

   my @selstags=Query->Param("stags");
   if ($#selstags==0 && $selstags[0]=~m/,/){
      @selstags=split(/,/,$selstags[0]);
   }
   if ($#selstags==-1){
      $self->defaultSTags(\@selstags);
   }
   my $s="<select name=stags style=\"width:100%\" multiple size=4>";
    while($#stags!=-1){
       my $key=shift(@stags);
       my $val=shift(@stags);
       $s.="<option value=\"$key\"";
       my $qkey=quotemeta($key);
       $s.=" selected" if (($qkey ne "" && grep(/^$qkey$/,@selstags)));
       $s.=">".$val."</option>";
    }
    $s.="</select>";



   print $self->getParsedTemplate("tmpl/globalHelp",{
               translation=>'faq::QuickFind',
               static=>{
                 result=>$result,
                 AutoSearch=>$autosearch,
                 stagsSelect=>$s,
                 searchtext=>$kwords,
                 remote_user=>$ENV{REMOTE_USER},
                 newwf=>$self->T("start a new workflow","base::MyW5Base"),
                 myjobs=>$self->T("my current jobs","base::MyW5Base")
               }});
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub Welcome
{
   my $self=shift;
   my $label=shift;
   my $searchtext=shift;

   print treeViewHeader($label,1);
   my $faq=getModuleObject($self->Config,"faq::article");

   $faq->SecureSetFilter({categorie=>'W5Base*'});

   foreach my $rec ($faq->getHashList(qw(uservotelevel name faqid))){
      if ($rec->{uservotelevel}>-100){
         my $pref=""; 
         my $post=""; 
         if ($rec->{uservotelevel}<0){
            $pref="<font color='dimgray'>"; 
            $post="</font>"; 
         }
         print insDoc("foldersTree",$pref.$rec->{name}.$post,
                      "../../faq/article/ById/".
                      "$rec->{faqid}");
      }
   }
   return(0);
}

sub defaultSTags
{
   my $self=shift;
   my $stags=shift;
   my $defaultRec;

   my @defaultSTags=qw(forum article);

   my $nobj=$self->getPersistentModuleObject("base::note"); 
   my $userid=$self->getCurrentUserId();
   my $selfname=$self->Self;
   my $selflabel=$self->Self."::STag";
   if ($#{$stags}==-1){
      $nobj->SetFilter({parentobj=>\$selfname,creatorid=>\$userid,
                        publicstate=>0,
                        name=>\$selflabel});
      ($defaultRec)=$nobj->getOnlyFirst(qw(ALL));
      if (defined($defaultRec)){
         @$stags=sort(split(/\s+/,$defaultRec->{comments}));
      }
      else{
         @$stags=@defaultSTags;
      }
   }
   if (join(" ",sort(@defaultSTags)) ne join(" ",sort(@$stags)) ||
       (defined($defaultRec) && 
        sort(split(/^s+/,$defaultRec->{comments})) ne join(" ",sort(@$stags)))){
      $nobj->ValidatedInsertOrUpdateRecord(
                        {parentobj=>$selfname,
                         parentid=>'1',
                         name=>$selflabel,
                         publicstate=>'0',
                         comments=>join(" ",sort(@$stags)),
                         creatorid=>$userid},
                        {parentobj=>\$selfname,name=>\$selflabel,parentid=>'1',
                         creatorid=>\$userid,publicstate=>\'0'});
   }
}

sub doSearch
{
   my $self=shift;
   my $label=shift;
   my $searchtext=shift;
   my $FormatAs; 

   my @stags=();
   if (Query->Param("forum") ne ""){
      push(@stags,"forum");
   }
   if (Query->Param("article") ne ""){
      push(@stags,"article");
   }
   if (Query->Param("ci") ne ""){
      push(@stags,"ci");
   }
   if (Query->Param("stags") ne ""){
      @stags=Query->Param("stags");
      $self->defaultSTags(\@stags);
   }
   if (Query->Param("FormatAs") ne ""){
      $FormatAs=Query->Param("FormatAs");
   }
   if (!defined($FormatAs)){
      if ($searchtext ne "" && length($searchtext)<3){
         print treeViewHeader("<font color=red>".
                              $self->T("search text to short").
                              "</font>",1);
         return();
      }
   }
   my $tag=undef;
   if (my ($stag,$stxt)=$searchtext=~m/^\s*([^:'"]{3,20})\s*:\s*(\S+.*)\S*$/){
      $tag=lc($stag);
      $searchtext=$stxt;
   }
   $searchtext=trim($searchtext);

   my $found=0;
   msg(DEBUG,"QuickFind at: '%s'",join(",",@stags));
   if (grep(/^ci/,@stags)){
      my $tree="foldersTree";
      $self->LoadSubObjs("QuickFind","QuickFind");
      my @s;
      foreach my $sobj (values(%{$self->{QuickFind}})){
         my $acl=$self->getMenuAcl($ENV{REMOTE_USER},
                                   $sobj->Self());
         if (defined($acl)){
            next if (!grep(/^read$/,@$acl));
         }
         #msg(INFO,"mod=%s acl=%s",$sobj->Self(),Dumper($acl));
         if ($sobj->can("CISearchResult")){
            push(@s,$sobj->CISearchResult(\@stags,$tag,$searchtext));
         }
      }
      if (!defined($FormatAs)){
         my $group=undef;
         foreach my $res (sort({$a->{group} cmp 
                                $b->{group}} @s)){
            if (!$found){
               print treeViewHeader($label,1);
               print <<EOF;
function switchTag(id)
{
   var e=document.getElementById(id);
   if (e.style.visibility!="visible"){
      e.innerHTML='<center><img src="../../base/load/ajaxloader.gif"></center>';
      e.style.visibility="visible";
      e.style.display="block";
      var xmlhttp=getXMLHttpRequest();
      var path='QuickFindDetail';
      xmlhttp.open("GET",path+"?id="+id);
      xmlhttp.onreadystatechange=function() {
       if (xmlhttp.readyState==4 && 
           (xmlhttp.status==200 || xmlhttp.status==304)){
          var xmlobject = xmlhttp.responseXML;
          var result=xmlobject.getElementsByTagName("htmlresult");

          var d="";
          for (var i = 0; i < result.length; ++i){
              var childNode=result[i].childNodes[0];
              if (childNode){
                 d+=childNode.nodeValue;
              }
          }
          e.innerHTML=d;
       }
      }
      var r=xmlhttp.send('');
   }
   else{
      e.style.visibility="hidden";
      e.style.display="none";
   }
}
EOF
             }
             $found++;
             if ($group ne $res->{group}){
                $tree="foldersTree";
                my $gtag=$res->{group};
                $gtag=~s/[^a-z0-9]/_/gi;
                print insFld($tree,$gtag,$res->{group});
                $tree=$gtag;
                $group=$res->{group};
             }
             my $divid="$res->{parent}::$res->{id}";
             my $html="<div class=QuickFindDetail id=\"$divid\" ".
                      "style=\"visibility:hidden;display:none\">XXX</div>";
             my $link="javascript:switchTag('$divid')";
             $link=undef if (!defined($res->{id}) || !defined($res->{parent}));

             print insDoc($tree,$res->{name},$link,appendHTML=>$html); 
         }
      }
      elsif($FormatAs eq "nativeJSON" || $FormatAs eq "JSONP"){
         if ($FormatAs eq "JSONP"){
            my $JSONP=Query->Param("callback");
            $JSONP="_JSONP" if ($JSONP eq "");
            print("$JSONP(");
         }
         print $self->{JSON}->encode(\@s);
         if ($FormatAs eq "JSONP"){
            print(");");
         }
      }
   }
   if (!defined($FormatAs)){
      if (grep(/^article$/,@stags) && 
          (!defined($tag) || grep(/^$tag$/,qw(faq)))){
         my $tree="foldersTree";
         my $faq=getModuleObject($self->Config,"faq::article");
         my @kwords=split(/\s*\|\s*/,$searchtext);
         foreach my $kwords (@kwords){
            $faq->ResetFilter();
            $faq->SecureSetFilter({kwords=>$kwords,
                                   lang=>[$self->Lang(),"multilang"]});
            my @l=$faq->getHashList(qw(uservotelevel mdate name faqid));
            my $loop=0;
            foreach my $rec (@l){
               my $pref=""; 
               my $post=""; 
               if ($rec->{uservotelevel}<-600){
                  $pref="<font color='gray'>"; 
                  $post="</font>"; 
               }
               elsif ($rec->{uservotelevel}<-100){
                  $pref="<font color='dimgray'>"; 
                  $post="</font>"; 
               }
               if (!$found){
                  print treeViewHeader($label,1);
                  $found++;
               }
               if ($loop==0 && $#stags>0){
                  print insFld($tree,"article","FAQ-Artikel");
                  $tree="article";
                  $loop++;
               }
               print insDoc($tree,$pref.$rec->{name}.$post,
                            "../../faq/article/ById/".
                            "$rec->{faqid}");
            }
            last if ($found);
         }
      }
      if (grep(/^forum$/,@stags) && 
          (!defined($tag) || grep(/^$tag$/,qw(forum)))){
         my $tree="foldersTree";
         my %id;

         my $fo=getModuleObject($self->Config,"faq::forumentry");
         $fo->SecureSetFilter({ftext=>$searchtext});
         my @l=$fo->getHashList(qw(uservotelevel forumtopic));
         foreach my $rec (@l){
            $id{$rec->{forumtopic}}++;
         }
         my $fo=getModuleObject($self->Config,"faq::forumtopic");
         $fo->SecureSetFilter({ftext=>$searchtext});
         my @l=$fo->getHashList(qw(id));
         foreach my $rec (@l){
            $id{$rec->{id}}++;
         }
         $fo->ResetFilter();
         $fo->SecureSetFilter({id=>[keys(%id)]});
         my @l=$fo->getHashList(qw(uservotelevel id name));

         my $loop=0;
         foreach my $rec (@l){
            my $pref=""; 
            my $post=""; 
            if (!$found){
               print treeViewHeader($label,1);
               $found++;
            }
            if ($loop==0 && $#stags>0){
               print insFld($tree,"forum","Forum");
               $tree="forum";
               $loop++;
            }
            if ($rec->{uservotelevel}<-600){
               $pref="<font color='gray'>"; 
               $post="</font>"; 
            }
            elsif ($rec->{uservotelevel}<-100){
               $pref="<font color='dimgray'>"; 
               $post="</font>"; 
            }
            print insDoc($tree,$pref.$rec->{name}.$post,
                         "../../faq/forum/Topic/".
                         "$rec->{id}");
         }
      }
   }
   if (!defined($FormatAs)){
      if (!$found){
         print treeViewHeader("<font color=red>".$self->T("nothing found").
                              "</font>",1);
      }
   }
   return(0);
}

sub DetailX
{
   my $self=shift;

   $self->{DetailX}=$_[0] if (defined($_[0]));
   $self->{DetailX}=640 if (!defined($self->{DetailX}));
   return($self->{DetailX});

}

sub DetailY
{
   my $self=shift;

   $self->{DetailY}=$_[0] if (defined($_[0]));
   $self->{DetailY}=480 if (!defined($self->{DetailY}));
   return($self->{DetailY});
}


sub insDoc
{
   my $tree=shift;
   my $label=shift;
   my $link=shift;
   my %param=@_;

   $label=~s/"/\\"/g;
   $label=~s/[\r\n]/ /g;
   if (defined($link) && !($link=~m/^javascript:/)){
      $link=sprintf("javascript:openwin('%s','_blank',".
                    "'height=400,width=640,toolbar=no,".
                    "status=no,resizable=yes,scrollbars=auto')",$link); 
   }
   my $mode="S";
   if ($link=~m/^javascript:/i){
      $link=~s/^javascript://i;
      $mode.="j";
   }
   $link=~s/'/\\\\\\'/g;



   my $d=sprintf("e=insDoc(%s,".
             "gLnk(\"%s\",\"<div class=specialClass>%s</div>\",".
             "\"%s\"));\n",$tree,$mode,$label,$link);
   if (exists($param{appendHTML})){
      $d.=sprintf("e.appendHTML='%s';\n",$param{appendHTML});
   }
   return($d);
}

sub insFld
{
   my $tree=shift;
   my $name=shift;
   my $label=shift;

   my $d=sprintf("%s=insFld(%s,gFld(\"%s\", \"\"));\n",$name,$tree,$label);
   return($d);
}

sub treeViewHeader
{
   my $label=shift;
   my $allopen=shift;
   my $stags=shift;
   $allopen=0 if (!defined($allopen));
   my $d=<<EOF;

<DIV style="position:absolute; top:0; left:0;display:none"><TABLE border=0><TR><TD><FONT size=-2><A style="font-size:7pt;text-decoration:none;color:silver" href="http://www.treemenu.net/" target=_blank>Javascript Tree Menu</A></FONT></TD></TR></TABLE></DIV>

<script langauge="JavaScript"
        src="../../../static/treeview/ua.js"></script>
<script langauge="JavaScript"
        src="../../../static/treeview/ftiens4.js"></script>

<script langauge="JavaScript">
USETEXTLINKS=1;
USEFRAMES=0;
USEICONS=1;
PRESERVESTATE=0;
STARTALLOPEN=$allopen;
ICONPATH = '../../../static/treeview/';
foldersTree=gFld("<i>$label</i>","");
foldersTree.treeID = "Frameless";
foldersTree.iconSrc="../../base/load/help.gif";
EOF
   return($d);
}


sub Result
{
   my $self=shift;
   my $label=shift;
   my $searchtext=Query->Param("searchtext");
   my $FormatAs=Query->Param("FormatAs");

   if (!defined($FormatAs)){
      print $self->HttpHeader("text/html");
      print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                      'public/faq/load/QuickFind.css'],
                              title=>"QuickFind Result",
                              js=>['toolbox.js'],
                              body=>1,form=>1);
   }
   elsif($FormatAs eq "nativeJSON" || $FormatAs eq "JSONP"){
      print $self->HttpHeader("application/javascript",charset=>'UTF8');
      eval('use JSON;$self->{JSON}=new JSON;');
      $self->{JSON}->utf8(1);
   }
   else{
      printf("Status: 405 Forbidden\n");
      printf("Content-type:text/html;charset=ISO-8895-1\n\n");
      printf("<html><body><h1>405 Forbidden</h1></body></html>");
      return;

   }
   if ($searchtext eq ""){
      $self->Welcome($self->T("W5Base Documentation"),$searchtext);
   }
   else{
      $self->doSearch($self->T("Search Result"),$searchtext);
   }
   if (!defined($FormatAs)){
      print(<<EOF);
</script>
<style>
body{overflow:hidden;}
</style>
<div id=result style="margin-left:2px;overflow:auto">
<script language="JavaScript">
initializeDocument();
function resizeResult()
{
   h=getViewportHeight();
   w=getViewportWidth();
   var r=document.getElementById('result');
   r.style.height=(h-2)+"px";
   r.style.width=(w-2)+"px";
}
resizeResult();
addEvent(window,"resize",resizeResult);
</script>
</div>
EOF
      print $self->HtmlBottom(body=>1,form=>1);
   }
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main anyQuestions globalHelp Welcome Result 
             QuickFindDetail mobileWAP Empty));
}

sub QuickFindDetail
{
   my $self=shift;

   my $id=Query->Param("id");
   my $htmlresult;

   $self->LoadSubObjs("QuickFind","QuickFind");
   if (my ($mod,$id)=$id=~m/^(.*)::(.*)$/){
      msg(INFO,"load $id from mod=$mod");
      if (defined($self->{QuickFind}->{$mod})){
         $htmlresult=$self->{QuickFind}->{$mod}->QuickFindDetail($id);
      }
      else{
         msg(ERROR,"can't find module $mod"); 
      }
   }
   else{
      msg(ERROR,"can't interpret $id");
   }
   # block max lenght=512 on FireFox
   $htmlresult=[split(/(.{512})/,$htmlresult)]; 

   print $self->HttpHeader("text/xml");
   my $res=hash2xml({document=>{htmlresult=>$htmlresult}},{header=>1});
   print $res;


}






1;
