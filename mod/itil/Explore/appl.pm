package itil::Explore::appl;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use kernel::ExploreApplet;
@ISA=qw(kernel::ExploreApplet);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getJSObjectClass
{
   my $self=shift;
   my $app=shift;
   my $lang=shift;
   my $selfname=$self->Self();

 #   my $addGroups=quoteHtml($self->getParent->T("add all related groups"));
 #   my $addOrgs=quoteHtml($self->getParent->T("add organisation groups"));
 #   my $orgRoles=join(" ",orgRoles());

   my $d=<<EOF;
(function(window, document, undefined) {
   var applet='${selfname}';
   ClassAppletLib[applet].class=function(app){
      ClassApplet.call(this,app);
   };
   \$.extend(ClassAppletLib[applet].class.prototype,ClassApplet.prototype);

   ClassAppletLib[applet].class.prototype.run=function(){
      var appletobj=this;
      this.app.showDialog(function(){
         var dialog = document.createElement('div');
         \$(dialog).css("height","80%");
         \$(dialog).append("<table id=SearchTab width=100% border=0>"+  
                           "<tr height=1%><td width=10%>"+
                           "<form id=SearchFrm><div class='SearchLabel'>"+
                           "Suchen:</div></td><td>"+
                           "<div class='SearchLabel'>"+
                           "<input type=text name=SearchInp id=SearchInp>"+
                           "</div></form></td></tr>"+
                           "<tr><td colspan=2 valign=top>"+
                           "<div id=SearchContainer>"+
                           "<div id=SearchResult></div>"+
                           "</div>"+
                           "</td></tr>"+
                           "</table>");
         \$(dialog).find("#SearchTab").height("200px");
         \$(dialog).find("#SearchInp").focus();
         \$(dialog).find("#SearchResult").html(
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"+
               "xc<br>"
         );
         return(dialog);
      },function(){
         appletobj.exit();
      });
   };

})(this,document);
EOF
   return($d);
}

1;
