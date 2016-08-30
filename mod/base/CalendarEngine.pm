package base::CalendarEngine;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use CGI;
@ISA=qw(kernel::App::Web);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->LoadSubObjs("Calendar","Calendar");
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main));
}


sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html",charset=>'UTF-8');

   my $getAppTitleBar=$self->getAppTitleBar();

   my $dataobj=Query->Param("dataobj");
   my $dataobjid=Query->Param("dataobjid");
   my $lang=$self->Lang();
   my $objlist="var objlist=";
   my @objlist;
   foreach my $sobj (values(%{$self->{Calendar}})){
      my $d;
      if ($sobj->can("getObjectInfo")){
         $d=$sobj->getObjectInfo($self,$lang);
      }
      if (defined($d)){
         push(@objlist,"{name:'$d->{name}',label:'$d->{label}',".
                       "prio:'$d->{prio}'}");
      }
   }
   $objlist=$objlist."[".join(",\n",@objlist)."];";
   my $fullname=$self->T("Fullname");
   my $name=$self->T("Name");
   my $objecttype=$self->T("ObjectType");
   my $opt={
      static=>{
          LANG      => $lang,
          DATAOBJ   => $dataobj,
          DATAOBJID => $dataobjid,
          OBJLIST   => $objlist,
          TITLEBAR  => $getAppTitleBar,
          NAME      => $name,
          FULLNAME  => $fullname,
          OBJECTTYPE=> $objecttype,
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.CalendarEngineMain",$opt);
   utf8::encode($prog);
   print($prog);
}


1;
