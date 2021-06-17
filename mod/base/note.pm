package base::note;
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
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

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
                label         =>'W5BaseID',
                dataobjattr   =>'postitnote.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Label',
                dataobjattr   =>'postitnote.name'),

      new kernel::Field::Group(
                name          =>'grp',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'rel',
                label         =>'share with group',
                vjoinon       =>'grpid'),

      new kernel::Field::Link(
                name          =>'grpid',
                readonly      =>1,
                group         =>'rel',
                dataobjattr   =>'postitnote.grp'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Note',
                dataobjattr   =>'postitnote.comments'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'rel',
                label         =>'parent object',
                dataobjattr   =>'postitnote.parentobj'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'rel',
                label         =>'parent id',
                dataobjattr   =>'postitnote.parentid'),

      new kernel::Field::Boolean(
                name          =>'publicstate',
                group         =>'rel',
                label         =>'direct display',
                dataobjattr   =>'publicstate'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                selectfix     =>1,
                label         =>'Source-System',
                dataobjattr   =>'postitnote.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'postitnote.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'postitnote.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'postitnote.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'postitnote.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                searchable    =>0,
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'postitnote.createuser'),

      new kernel::Field::Link(
                name          =>'creatorid',
                label         =>'CreatorID',
                dataobjattr   =>'postitnote.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'postitnote.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'postitnote.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'postitnote.realeditor'),

   );
   $self->setDefaultView(qw(linenumber name comments mdate));
   $self->setWorktable("postitnote");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_publicstate"))){
      Query->Param("search_publicstate"=>$self->T("yes"));
   }
}

sub isCopyValid
{
   my $self=shift;
   my $rec=shift; 
   return(0) if (!defined($rec));
   return(1);
}


sub prepUploadRecord                       # pre processing interface
{
   my $self=shift;
   my $newrec=shift;

   my $idobj=$self->IdField();
   my $idname;

   if (defined($idobj)){
      $idname=$idobj->Name();
      if (!exists($newrec->{$idname}) || $newrec->{$idname} eq ""){
         if (exists($newrec->{parentid}) && $newrec->{parentid} ne "" &&
             exists($newrec->{parentobj}) && $newrec->{parentobj} ne "" &&
             exists($newrec->{name}) && $newrec->{name} ne ""){
            my $i=$self->Clone();
            $i->SecureSetFilter({parentobj=>\$newrec->{parentobj},
                                 parentid=>\$newrec->{parentid},
                                 name=>\$newrec->{name}});
            my ($rec,$msg)=$i->getOnlyFirst($idname);
            if (defined($rec)){
               $newrec->{$idname}=$rec->{$idname};
               delete($newrec->{parentid});
               delete($newrec->{parentobj});
               delete($newrec->{name});
            }
         }
      }
   }
   return(1);
}




sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my $userid=$self->getCurrentUserId();
   foreach my $flt (@flt){
      $flt->{creatorid}=\$userid; 
   }
   return($self->SetFilter(@flt));
}






sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/^\s*$/i){
      $self->LastMsg(ERROR,"invalid name '%s' specified",$name); 
      return(undef);
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my $userid=$self->getCurrentUserId();
   return("ALL") if ($rec->{creatorid}==$userid || $self->IsMemberOf("admin"));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("ALL") if (!defined($rec));
   return("default","rel") if ($rec->{creatorid}==$userid || 
                         $self->IsMemberOf("admin"));
   return(undef);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Actor Display),$self->SUPER::getValidWebFunctions());
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","rel","soure");
}




sub Actor
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           js=>['toolbox.js','jquery.js','J5Base.js'],
                           form=>1,body=>1,
                           title=>"W5Notes");
   my $parentobj=Query->Param("parentobj");
   my $parentid=Query->Param("parentid");
   my $userid=$self->getCurrentUserId();
   my $precode="";
   my @flt;
   if ($parentobj ne ""){
      $precode.="var ParentObj=\"$parentobj\";\n";
      push(@flt,{creatorid=>\$userid,
                 parentobj=>[$parentobj,''],
                 name=>'UserJavaScript*'});
   }
   if ($parentobj ne "" && $parentid ne ""){
      $precode.="var ParentId=\"$parentid\";\n";
      push(@flt,{creatorid=>\$userid,
                 parentobj=>\$parentobj,
                 parentid=>\$parentid,
                 name=>'UserJavaScript*'});
   }
   if ($#flt!=-1){
      $self->ResetFilter();
      $self->SetFilter(\@flt);
      my $code="";
      foreach my $rec ($self->getHashList(qw( name comments))){
         $code.=$rec->{comments};
      }
      $code=trim($code);
      if ($code ne ""){
         print("<script language=\"JavaScript\">".$precode."\n".
               $code."</script>");
      }
   }
   print(<<EOF);
<script>
//\$(document).ready(function (){
//   var UserJavaScript=parent.document.getElementById("UserJavaScript");
//   UserJavaScript.innerHTML="xxx<br>xxx<br>xxx<br>xxx<br>xxx<br>xxx<br>xxx<br>";
//   alert("parent="+parent);
//});
if (parent){
parent.addMenu("Hallo");
parent.addMenu("Hallo");
parent.addMenu("Hallo");
parent.addMenu("Hallo");
parent.addMenu("Hallo");
parent.addMenu("Hallo");
parent.showUserJavaScript();
}

</script>


EOF
   
   print $self->HtmlBottom(body=>1,form=>1);
}








1;
