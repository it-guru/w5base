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
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'postitnote.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Label',
                dataobjattr   =>'postitnote.name'),

      new kernel::Field::Group(
                name          =>'grp',
                group         =>'rel',
                label         =>'share with group',
                vjoinon       =>'grpid'),

      new kernel::Field::Link(
                name          =>'grpid',
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
                label         =>'Owner',
                dataobjattr   =>'postitnote.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'postitnote.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'postitnote.realeditor'),

   );
   $self->setDefaultView(qw(linenumber name comments mdate));
   $self->setWorktable("postitnote");
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_isdeleted"))){
      Query->Param("search_publicstate"=>$self->T("yes"));
   }
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

 #  if (!$self->IsMemberOf([qw(admin)],"RMember")){
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
   return("default") if ($rec->{creatorid}==$userid || 
                         $self->IsMemberOf("admin"));
   return(undef);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Actor Display),$self->SUPER::getValidWebFunctions());
}


sub Display
{
   my $self=shift;
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css'],
                           form=>1,body=>1,
                           title=>"W5Notes");
   print("<style>body,form,html{background:#FDFBD6;overflow:hidden}</style>");
   printf("<textarea style=\"width:100%;height:98px;background-color:#FDFBD6;border-style:none\">xxx</textarea>");

   print $self->HtmlBottom(body=>1,form=>1);
}

sub Actor
{
   my ($self)=@_;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css',
                                   'kernel.TabSelector.css'],
                           js=>['toolbox.js','prototype.js'],
                           form=>1,body=>1,
                           title=>"W5Notes");
   if ($self->IsMemberOf("admin")){
      print "<a class=ModeSelectFunctionLink href=\"JavaScript:addPostIt(10,10)\">Add</a>";
      print "&bull;<a class=ModeSelectFunctionLink href=\"JavaScript:hidePrivate()\">Hide</a>";
      print "&bull;<a class=ModeSelectFunctionLink href=\"JavaScript:showPrivate()\">Show</a>";
   }
   print(<<EOF);
<div id="headcode" style="display:none;visible:hidden">
<div style="width:100%;height:20px;background:yellow">
PostIt
</div>
</div>
<script language="JavaScript">

parent.objDrag = null;  // Element, über dem Maus bewegt wurde

parent.mouseX   = 0;    // X-Koordinate der Maus
parent.mouseY   = 0;    // Y-Koordinate der Maus

parent.offX = 0;        // X-Offset des Elements, das geschoben werden soll
parent.offY = 0;        // Y-Offset des Elements, das geschoben werden soll

   IE = document.all&&!window.opera;
   DOM = document.getElementById&&!IE;


function init(){
   // Initialisierung der Überwachung der Events
   parent.document.onmousemove = doDrag;
   parent.document.onmouseup = stopDrag;
}

// Wird aufgerufen, wenn die Maus über einer Box gedrückt wird
function startDrag(objElem) {
   // Objekt der globalen Variabel zuweisen -> hierdurch wird Bewegung möglich
    parent.objDrag = objElem;

    // Offsets im zu bewegenden Element ermitteln
    parent.offX = parent.mouseX - parent.objDrag.offsetLeft;
    parent.offY = parent.mouseY - parent.objDrag.offsetTop;
}

// Wird ausgeführt, wenn die Maus bewegt wird
function doDrag(ereignis) {
   // Aktuelle Mauskoordinaten bei Mausbewegung ermitteln
    parent.mouseX = (IE) ? parent.event.clientX : ereignis.pageX;
    parent.mouseY = (IE) ? parent.event.clientY : ereignis.pageY;

   // Wurde die Maus über einem Element gedrück, erfolgt eine Bewegung
    if (parent.objDrag != null) {
      // Element neue Koordinaten zuweisen
      parent.objDrag.style.left = (parent.mouseX - parent.offX) + "px";
      parent.objDrag.style.top = (parent.mouseY - parent.offY) + "px";

    }
}

// Wird ausgeführt, wenn die Maustaste losgelassen wird
function stopDrag(ereignis) {
   // Objekt löschen -> beim Bewegen der Maus wird Element nicht mehr verschoben
    parent.objDrag = null;
}

init();





function addPostIt(x,y,id)
{
   if (id==""){
      id="xx";
   }
      var div = parent.document.createElement('div');
      var h=document.getElementById("headcode");
      div.innerHTML=h.innerHTML+
                    "<iframe frameborder=0 style=\\"border-style:none;\\" "+
                    "src=\\"../../base/note/Display?id="+id+"\\" "+
                    "width=100% height=100></iframe>";
      div.style.background="#FDFBD6";
      div.style.position="absolute";
      div.style.overflow="hidden";
      div.style.border="solid 1px";
      div.style.left=x+"px";
      div.style.top=y+"px";
      div.style.width="160px";
      div.style.height="120px";
      div.id=id;
      var postit=parent.document.getElementById("PostIT");
      postit.onmousedown=function (){startDrag(postit);}
      if (!postit){
         alert("postit not found");
      }
      postit.appendChild(div);
}
function showPublic()
{
   var postit=parent.document.getElementById("PostIT");
   postit.style.display="block";
   postit.style.visibility="visible";
}
function hidePublic()
{
   var postit=parent.document.getElementById("PostIT");
   postit.style.display="none";
   postit.style.visibility="hidden";

}
function showPrivate()
{

}
function hidePrivate()
{

}
function activatePostits()
{
 //  addPostIt(200,40,"postit123");
 //  addPostIt(350,50,"postit456");

}
addEvent(window, "load", activatePostits);

</script>
EOF
   print $self->HtmlBottom(body=>1,form=>1);
}








1;
