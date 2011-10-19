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
                                                  
      new kernel::Field::Text(
                name          =>'dataobj',
                label         =>'Data-Object',
                dataobjattr   =>'iomap.dataobject'),

      new kernel::Field::Text(
                name          =>'queryfrom',
                label         =>'queryed from',
                dataobjattr   =>'iomap.queryfrom'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

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
                label         =>'Field 1 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op1exp',
                group         =>'operation',
                label         =>'Field 1 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op2field',
                group         =>'operation',
                label         =>'Field 2 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op2exp',
                group         =>'operation',
                label         =>'Field 2 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op3field',
                group         =>'operation',
                label         =>'Field 3 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op3exp',
                group         =>'operation',
                label         =>'Field 3 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op4field',
                group         =>'operation',
                label         =>'Field 4 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op4exp',
                group         =>'operation',
                label         =>'Field 4 expresion',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op5field',
                group         =>'operation',
                label         =>'Field 5 name',
                container     =>'operation'),

      new kernel::Field::Text(
                name          =>'op5exp',
                group         =>'operation',
                label         =>'Field 5 expresion',
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
                label         =>'Owner',
                dataobjattr   =>'iomap.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'iomap.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'iomap.realeditor'),
   

   );
   $self->setDefaultView(qw(cdate id dataobj queryfrom comments));
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","admin.itil.iomap"],
                         uniquesize=>255};
   $self->{history}=[qw(insert modify delete)];

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

   return($self->SUPER::getValidWebFunctions(@_),"IOMap");
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
   printf("OK");

}
1;
