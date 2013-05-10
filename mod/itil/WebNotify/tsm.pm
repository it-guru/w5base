package itil::WebNotify::tsm;
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
use base::WebNotify::simple;
@ISA=qw(base::WebNotify::simple);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getQueryForm
{
   my $self=shift;
   my $data=shift;

   my $bb;
   $bb="<table width=\"100%\"  height=\"280\" border=1>";
   $bb.="<tr height=\"1%\"><td>".
        $self->getParent->T("Please specify the applications").
        ":</td></tr>";
   $bb.="<tr height=1%><td><textarea rows=3 name=sendBaseDataAppl ".
        "style='width:100%'>".
        $data->{sendBaseDataAppl}."</textarea></td></tr>";

   $bb.="<tr height=\"1%\"><td>".
        "<table width=\"100%\"><tr><td width=1% nowrap><b>".
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
   return($self->ExpandApplications($data,\@resbuf))
}


sub ExpandApplications
{
   my $self=shift;
   my $data=shift;
   my $resbuf=shift;

   my $req=$data->{sendBaseDataAppl};
   my @req=split(/[\s;,]+/,$req);
   if (!($req=~m/^\s*$/) && $#req!=-1){
      my @sreq=sort(@req);
      my $appl=getModuleObject($self->Config,"itil::appl");
      $appl->SetFilter({cistatusid=>[3,4],
                        name=>join(" ",@req)});
      my @cilist=$appl->getHashList(qw(name tsmid tsm2id));
      @{$resbuf}=@cilist;
      my @l=map({$_->{name}} @cilist);
      if (lc(join(";",sort(@l))) eq lc(join(";",@sreq))){
         return(1);
      }
      if ($#l<$#req){
         $self->LastMsg(INFO,"error in base data request");
         return(0);
      }
      $data->{sendBaseDataAppl}=join("; ",sort(@l));
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

   $self->ExpandApplications($data,\@resbuf);
   foreach my $arec (@resbuf){
      $to{$arec->{tsmid}}++  if ($arec->{tsmid} ne "");
      $cc{$arec->{tsm2id}}++ if ($arec->{tsm2id} ne "" &&
                                 !exists($to{$arec->{tsm2id}}));
   }
   $data->{messageTo}=[keys(%to)];
   $data->{messageCc}=[keys(%cc)];
   $data->{messageBcc}=[$userid];
   $data->{messageFrom}=$userid;

   return(1);
}







1;
