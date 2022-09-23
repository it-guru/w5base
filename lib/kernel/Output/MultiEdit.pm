package kernel::Output::MultiEdit;
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
@ISA    = qw(kernel::FormaterMultiOperation);

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

sub Label
{
   return("multi edit");
}

sub Description
{
   return("With this module it is able to change a field value in multiple records at one step");
}


sub Init
{
   my $self=shift;
   my $app=$self->getParent->getParent();

   my $opobj=getModuleObject($app->Config,$app->Self());
   $opobj->doInitialize();  # ensure, all grpIndiv Fields are loaded
   $self->Context->{opobj}=$opobj;

   $self->SUPER::Init();
   return(undef);
}

sub getInputField
{
   my $self=shift;
   my $value=shift;
   my $name=shift;
   $value=~s/"/&quot;/g;
   my $d;

   my $size="";
   if ($name eq "OPCOMMENT"){
      $size=" maxlength=80 ";
   }

   my $inputfield="<input type=\"text\" id=\"$name\" value=\"$value\" ".
                  "name=\"$name\" style=\"width:100%\" $size>";
   my $width="100%";
   $d=<<EOF;
<table style="table-layout:fixed;width:$width" cellspacing=0 cellpadding=0>
<tr><td>$inputfield</td></tr></table>
EOF
   return($d);
}


sub cleanOPCOMMENT
{
   my $self=shift;
   my $txt=shift;

   $txt=rmNonLatin1($txt);

   $txt=~s/\n/ /g;
   $txt=~s/['"<>]/ /g;

   return($txt);
}


sub MultiOperationHeader
{
   my $self=shift;
   my $app=shift;

   my $oldOPFIELD=$app->Query->Param("OPFIELD");
   my $oldOPVALUE=$app->Query->Param("OPVALUE");
   my $oldOPCOMMENT=$self->cleanOPCOMMENT($app->Query->Param("OPCOMMENT"));

   my $s="<select name=OPFIELD style=\"width:100%\">";
   if ($oldOPFIELD eq ""){
      $s.="<option value=\"\"> - ".
          $app->T("select field to modify")." -</option>";
   }
   my @fieldlist=$app->getFieldObjsByView([qw(ALL)],
                                           opmode=>'MultiEdit');
   my @oktypes=qw(TextDrop Databoss Mandator Contact Group Number 
                  Textarea MultiDst IndividualAttr Currency
                  Text Select Boolean Date TimeSpans);
   foreach my $fo (@fieldlist){
      my $t=$fo->Type();
      if (in_array(\@oktypes,$t)){
         if ($fo->Uploadable()){
            $s.="<option value=\"".$fo->Name()."\"";
            if ($fo->Name() eq $oldOPFIELD){
               $s.=" selected";
            }
            $s.=">";
            $s.=$fo->Label();
            $s.="</option>";
         }
      }
   }
   
   $s.="</select>";


   my $d="<center><table style='margin-top:4px' class=data width=90%>";
   $d.="<tr><th width=20%>".$app->T("Field")."</th>";
   $d.="<th>".$app->T("new value")."</th>";
   $d.="<th>".$app->T("comments")."</th>";
   $d.="</tr>";
   $d.="<tr><td width=30%>".$s."</td>";
   $d.="<td width=50%>".$self->getInputField($oldOPVALUE,"OPVALUE")."</td>";
   $d.="<td width=20%>".$self->getInputField($oldOPCOMMENT,"OPCOMMENT")."</td>";
   $d.="</tr>";
   $d.="</table></center>";


   return($d);
}

sub MultiOperationActionOn
{
   my $self=shift;
   my $app=shift;
   my $id=shift;

   my $opobj=$self->Context->{opobj};
   my $idfield=$app->IdField();

   my $OPFIELD=$app->Query->Param("OPFIELD");
   my $OPVALUE=$app->Query->Param("OPVALUE");
   my $OPCOMMENT=$self->cleanOPCOMMENT($app->Query->Param("OPCOMMENT"));
   $OPVALUE=trim($OPVALUE);

   my $HistoryComments=trim($OPCOMMENT);
   if (trim($HistoryComments) ne ""){
      $W5V2::HistoryComments=$HistoryComments;
   }


   my $fail=1;

   my $chkfld=$opobj->getField($OPFIELD);
   if (!defined($chkfld)){
      $app->LastMsg(ERROR,"unknown field selected for MultiEdit");
      return(0);
   }

   $opobj->ResetFilter();
   $opobj->SetFilter({$idfield->Name()=>\$id});
   my ($oprec,$msg)=$opobj->getOnlyFirst(qw(ALL));
   if (defined($oprec)){
      my %rec=($OPFIELD=>$OPVALUE);
      my $newrec=$opobj->getWriteRequestHash("upload",$oprec,\%rec);
      if (defined($newrec)){
         $self->getParent->getParent->setTimePerEditStamp();
         if (!($opobj->SecureValidatedUpdateRecord($oprec,$newrec,
                                                   {$idfield->Name()=>\$id}))){
            $fail=1;
         }
         else{
            $fail=0;
         }
      }
      else{
         if ($opobj->LastMsg()==0){
            $opobj->LastMsg(ERROR,"invalid value for requested field");
         }
         $fail=1;
      }
   }
   $W5V2::HistoryComments=undef;
   return(1) if (!$fail);
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

   return("../../../public/base/load/icon_multiedit.gif");
}


1;
