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

   print treeViewHeader($label);
   my $faq=getModuleObject($self->Config,"faq::article");

   $faq->SecureSetFilter({kwords=>$searchtext});
   my $found=0;
   foreach my $rec ($faq->getHashList(qw(name faqid))){
      if (!$found){
         print treeViewHeader($label);
         $found++;
      }
      print insDoc("foldersTree",$rec->{name},
                   "../../faq/article/ById/".
                   "$rec->{faqid}");
   }
   if (!$found){
      print treeViewHeader("<font color=red>".$self->T("nothing found")."</font>",
                           1);
   }
   return(0);
}

sub insDoc
{
   my $tree=shift;
   my $label=shift;
   my $link=shift;


   $link=sprintf("javascript:openwin('%s','_blank',".
                 "'height=400,width=550,toolbar=no,".
                 "status=no,resizable=yes,scrollbars=auto')",$link); 


   my $d=sprintf("e=insDoc(%s,".
             "gLnk(\"R\",\"<div class=specialClass>%s</div>\",".
             "\"%s\"));e.target='_self';\n",$tree,$label,$link);
   return($d);
}

sub treeViewHeader
{
   my $label=shift;
   my $allopen=shift;
   $allopen=0 if (!defined($allopen));

   my $d=<<EOF;

<DIV style="position:absolute; top:0; left:0;display:none"><TABLE border=0><TR><TD><FONT size=-2><A style="font-size:7pt;text-decoration:none;color:silver" href="http://www.treemenu.net/" target=_blank>Javascript Tree Menu</A></FONT></TD></TR></TABLE></DIV>

<script langauge="JavaScript"
        src="../../../static/treeview/ua.js"></script>
<script langauge="JavaScript"
        src="../../../static/treeview/ftiens4.js"></script>

<script langauge="JavaScript">
USETEXTLINKS=1;
STARTALLOPEN=$allopen;
ICONPATH = '../../../static/treeview/';

foldersTree=gFld("<i>$label</i>");

foldersTree.treeID="Frameset";
foldersTree.iconSrc="../../base/load/help.gif";

//aux1=insFld(foldersTree,gFld("Photos example", "demoFramesetRightFrame.html"));
//aux1=insFld(foldersTree,gFld("xxx", "demoFramesetRightFrame.html"));

//docAux=insDoc(aux1, 
//              gLnk("R", "<div class=specialClass>CSS Class</div>", 
//            "http://www.treeview.net/treemenu/demopics/beenthere_newyork.jpg"));
//insDoc(foldersTree, 
//              gLnk("R", "<div class=specialClass>CSS Class</div>", 
//            "http://www.treeview.net/treemenu/demopics/beenthere_newyork.jpg"));
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
<SCRIPT>initializeDocument()</SCRIPT>
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
