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
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           title=>"FAQ QuickFind",
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   print $self->getParsedTemplate("tmpl/QuickFind",{
                                         translation=>'faq::QuickFind',
                                         static=>{}});
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
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   print $self->getParsedTemplate("tmpl/globalHelp",{
                                         translation=>'faq::QuickFind',
                                         static=>{}});
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

   foreach my $rec ($faq->getHashList(qw(name faqid))){
      print insDoc("foldersTree",$rec->{name},
                   "../../faq/article/ById/".
                   "$rec->{faqid}");
   }
   return(0);
}

sub doSearch
{
   my $self=shift;
   my $label=shift;
   my $searchtext=shift;

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




#   print treeViewHeader($label,1,\@stags);
   my $found=0;
   if (grep(/^article$/,@stags)){
      my $tree="foldersTree";
      my $faq=getModuleObject($self->Config,"faq::article");
    
      $faq->SecureSetFilter({kwords=>$searchtext});
      my @l=$faq->getHashList(qw(name faqid));
      my $loop=0;
      foreach my $rec (@l){
         if (!$found){
            print treeViewHeader($label,1);
            $found++;
         }
         if ($loop==0 && $#stags>0){
            print insFld($tree,"article","FAQ-Artikel");
            $tree="article";
            $loop++;
         }
         print insDoc($tree,$rec->{name},
                      "../../faq/article/ById/".
                      "$rec->{faqid}");
      }
   }
   if (grep(/^forum$/,@stags)){
      my $tree="foldersTree";
      my %id;

      my $fo=getModuleObject($self->Config,"faq::forumentry");
      $fo->SecureSetFilter({ftext=>$searchtext});
      my @l=$fo->getHashList(qw(forumtopic));
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
      my @l=$fo->getHashList(qw(id name));

      my $loop=0;
      foreach my $rec (@l){
         if (!$found){
            print treeViewHeader($label,1);
            $found++;
         }
         if ($loop==0 && $#stags>0){
            print insFld($tree,"forum","Forum");
            $tree="forum";
            $loop++;
         }
         print insDoc($tree,$rec->{name},
                      "../../faq/forum/Topic/".
                      "$rec->{id}");
      }
   }
   if (grep(/^ci$/,@stags)){
      my $tree="foldersTree";
      if (!$found){
         print treeViewHeader($label,1);
         $found++;
      }
      print <<EOF;
function switchTag(id)
{
   var e=document.getElementById(id);
   e.style.visibility="visible";
   e.style.display="block";
}
EOF
      print insFld($tree,"itil__appl","Application");
      $tree="itil__appl";
      print insDoc($tree,"AG XY \@ DTAG.T-Com<div id=\"xx\" style=\"visibility:hidden;display:none;text-decoration:none;color:black\">SeM:xxx<br><a href=http://www.google.com target=_blank>TSM:xxx</a><br></div>","javascript:switchTag('xx')");
      print insDoc($tree,"AG XY<br>","../../faq/forum/Topic/123");

   }


   if (!$found){
      print treeViewHeader("<font color=red>".$self->T("nothing found").
                           "</font>",1);
   }
   return(0);
}

sub insDoc
{
   my $tree=shift;
   my $label=shift;
   my $link=shift;

   $label=~s/"/\\"/g;
   if (!($link=~m/^javascript:/)){
      $link=sprintf("javascript:openwin('%s','_blank',".
                    "'height=400,width=550,toolbar=no,".
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

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           title=>"Welcome",
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   if ($searchtext eq ""){
      $self->Welcome($self->T("W5Base Documentation"),$searchtext);
   }
   else{
      $self->doSearch($self->T("Search Result"),$searchtext);
   }

   print(<<EOF);
</script>

<div style="margin:5px">
<script language="JavaScript">
initializeDocument();
</script>
</div>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main globalHelp Welcome Result));
}






1;
