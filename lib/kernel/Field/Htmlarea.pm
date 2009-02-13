package kernel::Field::Htmlarea;
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
use Data::Dumper;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   
   return($self);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $name=$self->Name();
   my $d=$self->RawValue($current);
   my $lang=$self->getParent->Lang();
   if ($mode eq "HtmlDetail"){
      $d="<table border=0 ".
         "style=\"width:100%;table-layout:fixed;padding:0;".
                 "border-width:0;margin:0\">".
         "<tr><td><div class=multilinehtml>$d</div></td></tr></table>";
   }
   if ($mode eq "edit" || $mode eq "workflow"){
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      my $orgd=$d;
      $orgd=~s/&/&amp;/g;
      $d="";
      $d.="<table border=0 style=\"width:100%;table-layout:fixed;".
          "padding:0;border-width:0;margin:0\">".
          "<tr><td></div>";
      $d.="<textarea name=Formated_$name class=multilinehtml>$orgd</textarea>";
      $d.="</td></tr></table>";
      $d=<<EOF.$d;
<script language=JavaScript 
        src="../../../static/tinymce/jscripts/tiny_mce/tiny_mce.js">
</script>
<script language=JavaScript>
tinyMCE.init({
	mode : "exact",
        elements : "Formated_$name",
        theme : "advanced",
        plugins: "clearbr",
        theme_advanced_buttons1 : "separator,"+
                                  "bold,italic,underline,strikethrough,"+
                                  "forecolor,backcolor,"+
                                  "separator,link,unlink,"+
                                  "separator,hr,sub,sup,separator,"+
                                  "indent,outdent,separator,bullist,numlist,"+
                                  "separator",
        theme_advanced_buttons2 : "separator,justifyleft,justifycenter,"+
                                  "justifyright,"+
                                  "justifyfull,formatselect,fontsizeselect,"+
                                  "removeformat,cleanup,"+
                                  "separator,image,separator,"+
                                  "code,clearbr,separator",
        theme_advanced_buttons3 : "",
        language : "$lang",
        theme_advanced_toolbar_align : "center",
        theme_advanced_toolbar_location : "external",
        theme_advanced_blockformats : "p,h1,h2,h3,pre,xmp",
        content_css : "../../../public/base/load/default.css,"+
                      "../../../public/base/load/work.css"
});

</script>
EOF
   }
   return($d);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
 #  if ($FormatAs eq "HtmlV01"){
 #     if (!$self->{AllowHtmlInput}){
 #        $d=~s/</&lt;/g;
 #        $d=~s/>/&gt;/g;
 #     }
 #     $d=~s/\n/<br>\n/g;
 #  }
   #printf STDERR ("fifi FormatAs=$FormatAs\n");
   return($d);
}








1;
