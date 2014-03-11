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
   my $FormatAs=shift;
   my $name=$self->Name();
   my $d=$self->RawValue($current);
   $d=$self->FormatedDetailDereferncer($current,$FormatAs,$d);
   $d=ExpandW5BaseDataLinks($self->getParent,$FormatAs,$d);
   my $lang=$self->getParent->Lang();
   if ($FormatAs eq "HtmlDetail"){
      $d="<table border=0 ".
         "style=\"width:100%;table-layout:fixed;padding:0;".
                 "border-width:0;margin:0\">".
         "<tr><td><div class=multilinehtml>$d</div></td></tr></table>";
   }
   if ($FormatAs eq "edit" || $FormatAs eq "workflow"){
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      my $orgd=$d;
      $orgd=~s/&/&amp;/g;
      $d="";
     # $d.="<table border=0 style=\"width:100%;table-layout:fixed;".
     #     "padding:0;border-width:0;margin:0\">".
     #     "<tr><td></div>";
      $d.="<table border=0 style=\"width:100%;table-layout:fixed;padding:0;border-width:0;margin:0\"><tr><td><textarea id=Formated_$name name=Formated_$name class=multilinehtml></textarea></td></tr></table>";
      $d.="<textarea id=Data_$name style=\"visible:hidden;display:none\">$orgd</textarea>";
     # $d.="</td></tr></table>";
      $d=<<EOF.$d;
<script language=JavaScript 
        src="../../../static/tinymce/jscripts/tiny_mce/tinymce.min.js">
</script>
<script language=JavaScript>
function initTinyMCE_$name()
{
tinyMCE.init({
     	mode : "exact",
        elements : "Formated_$name",
        theme : "modern",
        plugins: "autoresize link code nonbreaking image textcolor contextmenu lists",
        nonbreaking_force_tab: true,
        target_list: [
            {title: 'New page', value: '_blank'}
        ],
        menubar : false,
        skin: "light",
        toolbar : "undo | styleselect forecolor backcolor | "+
                  "bold italic underline bulllist | "+
                  "link image hr anchor insertdatetime | nonbreaking code",
        contextmenu: "link image bold italic",
        language : "$lang",
        statusbar : false,
       // strict_loading_mode : true,
       // auto_reset_designmode : true,
       // theme_advanced_blockformats : "p,h1,h2,h3,pre,xmp",
        content_css : "../../../public/base/load/default.css,"+
                      "../../../public/base/load/work.css"
});
var e=window.document.getElementById("Formated_$name");
var d=window.document.getElementById("Data_$name");
e.value=d.value;   // data late filling - hack for IE rendering
}
addEvent(window, "load",initTinyMCE_$name);

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
   $d=$self->FormatedDetailDereferncer($current,$FormatAs,$d);
   if ($self->readonly($current) && 
       ref($self->{onRawValue}) eq "CODE" &&
       !($FormatAs=~m/^Html.*$/)){
      $d=Html2Latin1($d);
   }
   return($d);
}








1;
