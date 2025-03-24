package base::WebNotify::simple;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use kernel::WebNotify;
@ISA=qw(kernel::WebNotify);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub Init
{
   my $self=shift;
   return(1);
}

sub getQueryForm
{
   my $self=shift;
   my $data=shift;

   my $bb;
   $bb="<table width=\"100%\"  height=\"280\" border=1>";
   $bb.="<tr height=\"1%\"><td>".
        $self->getParent->T("Please specify target contacts").
        ":</td></tr>";
   $bb.="<tr height=\"1%\"><td><textarea rows=2 name=sendBaseData ".
        "style='width:100%'>".
        $data->{sendBaseData}."</textarea></td></tr>";

   $bb.="<tr height=\"1%\"><td>".
        "<table width=\"100%\"><tr><td width=\"1%\" nowrap><b>".
        $self->getParent->T("Message subject").":</b></td>";
   $bb.="<td>".
        "<input style='width:100%' type=text name=messageSubject ".
        "value=\"$data->{messageSubject}\"></td></tr></table></td></tr>";
   $bb.="<tr height=1%><td><b>".
        $self->getParent->T("Message text").":</b></td></tr>";
   $bb.="<tr><td><textarea name=messageText ".
        "style='width:100%;height:100%'>".
        $data->{messageText}."</textarea></td></tr>";
   $bb.="</table>";

   $bb.=$self->getDefaultOptionLine($data);
   return($bb);
}



sub Validate
{
   my $self=shift;
   my $data=shift;
   my @resbuf;

   if ($data->{messageSubject}=~m/^\s*$/){
      $self->LastMsg(ERROR,"no subject specified");
      return(0)
   }
   if ($data->{messageText}=~m/^\s*$/){
      $self->LastMsg(ERROR,"no message text specified");
      return(0)
   }
   return($self->ExpandContacts($data,\@resbuf))
}

sub ExpandContacts
{
   my $self=shift;
   my $data=shift;
   my $resbuf=shift;

   my $req=trim($data->{sendBaseData});
   my @req=split(/[;]+\s*/,$req);
   if (!($req=~m/^\s*$/) && $#req!=-1){
      my @sreq=sort(@req);
      my $cio=getModuleObject($self->Config,"base::user");
      $cio->SetFilter({cistatusid=>[3,4],
                       fullname=>join(" ",map({'"'.$_.'"'} @req))});
      my @cilist=$cio->getHashList(qw(fullname userid));
      @{$resbuf}=@cilist;
      my @l=map({$_->{fullname}} @cilist);
      if (lc(join(";",sort(@l))) eq lc(join(";",@sreq))){
         return(1);
      }
      if ($#l<$#req){
         $self->LastMsg(ERROR,
                "requested contact count matches not found contact count");
         return(0);
      }
      $data->{sendBaseData}=join("; ",sort(@l));
      $self->LastMsg(OK,"data has been automaticly expanded");
      return(0);
   }
   else{
      $self->LastMsg(ERROR,"no base data");
      return(0);
   }
}

sub preResult
{
   my $self=shift;
   my $data=shift;
   my @resbuf;
   my %to;
   my %cc;
   my $userid=$self->getParent->getCurrentUserId();

   $self->ExpandContacts($data,\@resbuf);
   foreach my $arec (@resbuf){
      $to{$arec->{userid}}++  if ($arec->{userid} ne "");
   }
   $data->{messageTo}=[keys(%to)];
   $data->{messageBcc}=[$userid];
   $data->{messageFrom}=$userid;

   return(1);
}










1;
