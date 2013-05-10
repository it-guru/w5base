package kernel::Output::MultiInfoabo;
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
use kernel::FormaterMultiOperation;
use Data::Dumper;
@ISA    = qw(kernel::FormaterMultiOperation);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub Validate
{
   my $self=shift;

   my $fromquery=Query->Param("contact");
   if ($fromquery ne ""){
      my $user=getModuleObject($self->getParent->getParent->Config,
                               "base::user");
      my $filter={fullname=>'"'.$fromquery.'"'};
      my %param=();
      $user->SetFilter($filter);
      my ($dropbox,$keylist,$vallist)=$user->getHtmlSelect("contact","fullname",
                                                     ["fullname"],%param);
      if ($#{$keylist}<0 && $fromquery ne ""){
         $filter={fullname=>'"*'.$fromquery.'*"'};
         $user->ResetFilter();
         $user->SetFilter($filter);
         ($dropbox,$keylist,$vallist)=$user->getHtmlSelect(
                                                     "contact",
                                                     "fullname",
                                                     ["fullname"],%param);
      }
      if ($#{$keylist}>0){
         $self->Context->{LastDrop}=$dropbox;
         my $msg=$self->getParent->getParent->T(
               "selected contact is not unique",'kernel::Output::MultiInfoabo');
         $self->getParent->getParent->LastMsg(ERROR,$msg);
         return(undef);
      }
      elsif ($#{$keylist}<0){
         $self->getParent->getParent->LastMsg(ERROR,
         sprintf($self->getParent->getParent->T("contact '\%s' not found"),
                 $fromquery));
         return(undef);
      }
      else{
         my $in="<input class=finput name=contact value=\"$vallist->[0]\" ".
                "style=\"width:100%\">";
         $self->Context->{LastDrop}=$in;
         $filter={fullname=>[$vallist->[0]]};
         $user->ResetFilter();
         $user->SetFilter($filter);
         my ($rec,$msg)=$user->getOnlyFirst(qw(userid));
         if (defined($rec)){
            $self->Context->{LastID}=$rec->{userid};
         }
      }
   }
   return(1);
}

sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;
   return(1) if($param{mode} eq "Init");
   my $app=$self->getParent->getParent();
   $self->LoadOpObj();

   foreach my $obj (values(%{$self->{opobj}->{infoabo}})){
      my ($ctrl)=$obj->getControlData($self);
      foreach my $obj (keys(%$ctrl)){
         return(1) if ($app->SelfAsParentObject() eq $obj ||
                       $app->Self eq $obj);
      }
   }
   return(0);
}

sub Label
{
   return("Information abo");
}

sub Description
{
   return("Subscribe Information abos");
}


sub LoadOpObj
{
   my $self=shift;

   if (!defined($self->{opobj})){
      my $app=$self->getParent->getParent();
      $self->{opobj}=getModuleObject($app->Config,"base::infoabo");
   }
}


sub Init
{
   my $self=shift;
   $self->LoadOpObj();

   my $fromquery=Query->Param("contact");
   my $in="<input class=finput name=contact value=\"$fromquery\" ".
          "style=\"width:100%\">";
   $self->Context->{LastDrop}=$in;
   $self->SUPER::Init();
   return(undef);
}


sub MultiOperationHeader
{
   my $self=shift;
   my $app=shift;
   $self->LoadOpObj();
   my $d="";

   my $oldval=Query->Param("mode");
   $d.=sprintf("<table width=\"100%%\">");
   $d.=sprintf("<tr><td>");
   $d.=sprintf("<select name=mode style=\"width:100%%\">");
   if ($oldval eq ""){
      $d.="<option value=\"\">&lt;".
          $self->getParent->getParent->T("please select an information mode",
                                         'kernel::Output::MultiInfoabo').
          "&gt;</option>";
   }
   my @modes=$self->{opobj}->getModesFor($app->Self(),
                                         $app->SelfAsParentObject());
   while(my $k=shift(@modes)){
      my $v=shift(@modes);
      $d.="<option";
      $d.=" selected" if ($oldval eq $k);
      $d.=sprintf(" value=\"$k\">%s</option>",$v);
   }
   $d.=sprintf("</select>");
   $d.=sprintf("</td>");
   if ($self->{opobj}->isInfoAboAdmin() ||
       $self->{opobj}->isContactAdmin()){
      $d.=sprintf("<td width=5%% nowrap>%s:</td>",
          $self->getParent->getParent->T("Contact",
                                         'kernel::Output::MultiInfoabo'));
      my $in=$self->Context->{LastDrop};
      $d.=<<EOF;
<td width=300>
<table style="table-layout:fixed;width:100%" cellspacing=0 cellpadding=0>
<tr><td>$in
</td></tr></table></td>
EOF
   }
   $d.=sprintf("</tr>");
   $d.=sprintf("</table>");
   return($d);
}


sub MultiOperationActionOn
{
   my $self=shift;
   my $app=shift;
   my $id=shift;
   my $curruserid=$app->getCurrentUserId();
   $self->LoadOpObj();

   if (defined($self->Context->{LastID})){
    #  if ($self->{opobj}->isInfoAboAdmin()){
         $curruserid=$self->Context->{LastID};
    #  }
    #  else{
    #     $app->LastMsg(ERROR,"you are no admin");
    #     return(0);
    #  }
   }
   my $opobj=$self->{opobj};
   my $idfield=$app->IdField();
   my $mode=Query->Param("mode");
   if ($mode eq ""){
      $app->LastMsg(ERROR,
                    sprintf($self->getParent->getParent->T(
                          "invalid mode '%s' selected",$self->Self),$mode));
      return(0);
   }

   my %rec=(refid=>$id,
            parentobj=>$app->SelfAsParentObject(),
            userid=>$curruserid,
            active=>1,
            mode=>$mode);
   my %flt=(refid=>\$rec{refid},
            parentobj=>\$rec{parentobj},
            userid=>\$rec{userid},
            mode=>\$rec{mode});
   if ($opobj->ValidatedInsertOrUpdateRecord(\%rec,\%flt)){
      return(1);
   }
   return(0);
}

sub MultiOperationActor
{
   my $self=shift;
   my $app=shift;

   return($self->SUPER::MultiOperationActor($app,$app->T("Start",$self->Self)));
}


sub MultiOperationBottom
{
   my $self=shift;
   my $app=shift;

   delete($self->Context->{opobj});
   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;

   return("../../../public/base/load/icon_infoabo.gif");
}


1;
