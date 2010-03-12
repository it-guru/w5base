package kernel::Output::WebClip;
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
use kernel::Formater;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;

   return("../../../public/base/load/icon_WebClip.gif");
}

sub Label
{
   return("Output to WebClipboard");
}

sub Description
{
   return("WebClipboard is a area direct on this server, ".
          "in witch you can tempoary store data");
}

sub IsModuleDownloadable
{
   return(0);
}

sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my @view=$app->getFieldObjsByView([$app->getCurrentView()],current=>$rec);
   foreach my $fobj (@view){
      my $label=$fobj->Label();
      my $type=$fobj->Type();
      next if ($type eq "Linenumber");
      $self->Context->{'Fields'}->{$fobj->Name()}=$label;
   }

   if ($self->{'WCLIPFIELD'} ne "" && $self->{'WCLIPBOARD'} ne ""){
      my $nobj=$self->{'nobj'};
      my $userid=$self->getParent->getParent->getCurrentUserId();
      my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   fieldbase=>$fieldbase,
                                   current=>$rec,
                                   mode=>"WebClip",
                                  },$self->{'WCLIPFIELD'},"formated");
      $data="" if (!defined($data));
      if ($nobj->ValidatedInsertRecord({name=>$self->{'WCLIPBOARD'},
                                    publicstate=>1,
                                    parentobj=>'kernel::Output::WebClip',
                                    parentid=>'line'.$self->{'CLIPNO'},
                                    createuserid=>$userid,
                                    comments=>$data})){
         $self->{'CLIPNO'}++;
         $self->{'CLIPSZ'}+=length($data);
      }
   }
   return(undef);
}


sub Init
{
   my $self=shift;
   my ($fh,$baseview)=@_;

   $self->{'WCLIPFIELD'}=Query->Param('WCLIPFIELD');
   $self->{'WCLIPBOARD'}=Query->Param('WCLIPBOARD');
   $self->{'CLIPNO'}=0;
   $self->{'CLIPSZ'}=0;
   if (!defined($self->{'nobj'})){
      $self->{'nobj'}=getModuleObject($self->getParent->getParent->Config(),
                                      "base::note"); 
   }
   my $nobj=$self->{'nobj'};
   if ($self->{'WCLIPBOARD'} ne ""){
      my $userid=$self->getParent->getParent->getCurrentUserId();
      $nobj->ResetFilter();
      $nobj->SetFilter({creatorid=>\$userid,
                        parentobj=>\'kernel::Output::WebClip',
                        name=>\$self->{'WCLIPBOARD'}});
      $nobj->DeleteAllFilteredRecords("DeleteRecord");
   }

   return($self->SUPER::Init(@_));
}



sub MimeType
{
   return("text/html");
}


sub getHttpHeader
{
   my $self=shift;
   my $d="";
   $d.=$self->getParent->getParent->HttpHeader($self->MimeType());

   return($d);
}


sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $d=$app->HtmlHeader(style=>['default.css','work.css'],
                          body=>1,form=>1);

   my $sel="<select name=WCLIPFIELD>";
   foreach my $fname (keys(%{$self->Context->{'Fields'}})){
      $sel.="<option value=\"$fname\"";
      if ($fname eq $self->{'WCLIPFIELD'}){
         $sel.=" selected";
      }
      $sel.=">".
            $self->Context->{'Fields'}->{$fname}.
            "</option>";
   }
   $sel.="</select>";

   my $clip="<select name=WCLIPBOARD>";
   foreach my $fname (qw(WebClip WebClip1 WebClip2 WebClip2)){
      $clip.="<option value=\"$fname\"";
      if ($fname eq $self->{'WCLIPBOARD'}){
         $clip.=" selected";
      }
      $clip.=">$fname</option>";
   }
   $clip.="</select>";

   my $headlabel=$app->T("The webclipboard allows you to store temporary search results in a special data area. This data can be later used for further search operations");
   my $donelabel="";


   if ($self->{'WCLIPFIELD'} ne "" && $self->{'WCLIPBOARD'} ne ""){
      $donelabel="<hr style=\"width:80%\">".sprintf($app->T('There where %d values (%d Bytes) copied to clipboard %s - you can now use this values in search fields with the name [@%s@]'),$self->{'CLIPNO'},$self->{'CLIPSZ'},$self->{'WCLIPBOARD'},$self->{'WCLIPBOARD'});
      
   }
   my $copylabel=$app->T("copy to webclipboard");


   my $t=time();
   $d.="<center>";
   $d.=$headlabel."<br><hr>";

   $d.="$sel &nbsp;";
   $d.=<<EOF;
<input type=button onClick=doClip() value=" $copylabel ">
&nbsp;
$clip
<script language="JavaScript">
function doClip()
{


   var doc = parent.parent.document;
   var form = doc.forms[0];
   // form.action = 'put your url here';

   var el=form.elements['WCLIPBOARD'];
   if (!el){
      el=doc.createElement("input");
   }
   el.type = "hidden";
   el.name = "WCLIPBOARD";
   el.value = document.forms[0].elements['WCLIPBOARD'].value;
   form.appendChild(el);

   el=form.elements['WCLIPFIELD'];
   if (!el){
      el=doc.createElement("input");
   }
   el.type = "hidden";
   el.name = "WCLIPFIELD";
   el.value = document.forms[0].elements['WCLIPFIELD'].value;
   form.appendChild(el);

   parent.parent.DoRemoteSearch();

}

var doc = parent.parent.document;
var form = doc.forms[0];
if (form.elements['WCLIPFIELD']){
   form.elements['WCLIPFIELD'].parentNode.removeChild(form.elements['WCLIPFIELD']);
}
if (form.elements['WCLIPBOARD']){
   form.elements['WCLIPBOARD'].parentNode.removeChild(form.elements['WCLIPBOARD']);
}
</script>
</form>
$donelabel

EOF

   $d.=$app->HtmlBottom(body=>1,form=>1);


   return($d);
}

1;
