package oradwh::mgr;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use kernel::date;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::MenuTree;
use POSIX qw(floor);
@ISA=qw(kernel::App::Web kernel::DataObj::DB);

#
# Idee: Datawarehous tool
# /darwin/auth/mod/oradwh/mgr/view/current/w5tip/ActiveApplSysRel.xls
#                                  current                        xml
#                                  20120130
#
# w5base.oradwh.w5tip
# w5base.oradwh.w5dwh
#
#
#

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}




sub getValidWebFunctions
{
   my $self=shift;
   return("view",$self->SUPER::getValidWebFunctions());
}



sub view
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();
   my $rootpath=Query->Param("RootPath");
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','menu.css'],
                           js=>['toolbox.js','subModal.js'],
                           body=>1,form=>1,action=>'../ShowEntry',
                           prefix=>$rootpath,
                           title=>"W5Base Datawarehous");
   print $self->HtmlSubModalDiv(prefix=>$rootpath);
   print("<style>body{overflow:hidden}</style>");

   print("<table width=\"100%\" height=\"100%\" ".
         "cellspacing=0 cellpadding=0 border=0>");

   printf("<tr height=1%><td>");
   print $self->getAppTitleBar(prefix=>$rootpath,
                               title=>'W5Base Statistik Presenter');
   printf("</td></tr>");
   printf("<tr><td>Data</td></tr></table>");

}






1;
