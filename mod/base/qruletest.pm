package base::qruletest;
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
use kernel::Field;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub getParsedSearchTemplate
{
   my $self=shift;
   my %param=@_;

   my $DataObj=Query->Param("DataObj");
   my $suchmaske="<table width=100% border=1><tr><td><input type=text ".
                 "name=DataObj readonly=1 value=\"$DataObj\"></td>";
   if ($DataObj eq ""){
      $suchmaske="<form method=post><input type=text ".
                 "name=DataObj value=\"$DataObj\">".
                 "<input type=submit value=\"select\"></form>";
   }
   else{
      my $qrule=getModuleObject($self->Config,"base::qrule");
      my ($s)=$qrule->getHtmlSelect("QualityRule2Test","id",["fullname"]);
      $suchmaske.="<td>$s</td>";
      $suchmaske.="</tr></table>";
   }

   my $defaultMask="please select a valid DataObject !!!";
   if ($DataObj ne ""){
      my $o=$self->getOperationObject($DataObj);
      $defaultMask=$o->getParsedSearchTemplate(%param);
   }

   my $searchMask=sprintf("<tr><td height=1%% style=\"padding:1px\">".
          "%s<br><hr>%s</td></tr>",$suchmaske,$defaultMask);

   return($searchMask);
}


sub Result
{
   my $self=shift;
   my $DataObj=Query->Param("DataObj");
   my $o=$self->getOperationObject($DataObj);
   if (defined($o)){
      $o->Result(@_);
   }
}

sub getOperationObject
{
   my $self=shift;
   my $DataObj=shift;

   my $o=$self->getPersistentModuleObject("qruletest.".$DataObj,$DataObj);

   my $QualityRule2Test=Query->Param("QualityRule2Test");

   $self->{current_QualityRule2Test}=$QualityRule2Test;

   if (defined($o)){  # Objekt modifizieren
      my @defaultView=$o->getDefaultView();
      if (!in_array(\@defaultView,"QRuleTestResult")){
         push(@defaultView,"QRuleTestResult");
         $o->setDefaultView(@defaultView);
         $o->AddFields(
             new kernel::Field::Textarea(
                       name          =>'QRuleTestResult',
                       htmlwidth     =>'250px',
                       htmldetail    =>0,
                       readonly      =>1,
                       searchable    =>0,
                       label         =>'QRule Test Result',
                       onRawValue    =>\&doQRuleTestResult)
         );
      }
   }
   return($o);
}

sub doQRuleTestResult
{
   my $self=shift;
   my $current=shift;
   my $parent=$self->getParent();
   my $qruletester=$self->getParent()->getParent();
   my $QualityRule2Test=
      $qruletester->{current_QualityRule2Test};
   my $qruleobj=getModuleObject($self->Config,"base::qrule");

   my $result="";

   if (exists($qruleobj->{qrule}->{$QualityRule2Test})){
      my $qrule=$qruleobj->{qrule}->{$QualityRule2Test};
      my $do=$parent->Clone();
      my $idfield=$do->IdField();
      if (defined($idfield)){
         $do->SetFilter({$idfield->Name()=>\$current->{$idfield->Name()}});
         my ($rec)=$do->getOnlyFirst(qw(ALL));
         my $objlist=$do->getQualityCheckCompat($rec);
         my $ctrl=$qrule->getPosibleTargets();
         $ctrl=[$ctrl] if (ref($ctrl) ne "ARRAY");
         my $compat=0;
         foreach my $ct (@$ctrl){
            if ($ct=~m/[\.\^\*]/){
               foreach my $m (@$objlist){
                  if ($m=~m/$ct/){
                     $compat++;
                  }
               }
            }
            else{
               if (in_array($objlist,$ct)){
                  $compat++;
               }
            }
         }
         if ($compat){
            my $oldcontext=$W5V2::OperationContext;
            $W5V2::OperationContext="QualityCheck";
            my %param=(autocorrect=>0,checkmode=>'test',checkstart=>time());
            my $checkresult=$qrule->qcheckRecord($do,$rec,\%param);
            if (ref($checkresult) eq "HASH"){
               if (defined($checkresult->{qmsg})){
                  my $r={};
                  $qruleobj->translate_qmsg($checkresult,$r,$QualityRule2Test);
                  if (ref($r->{qmsg}) eq "ARRAY"){
                     $result.=join("\n",@{$r->{qmsg}});
                  }
                  else{
                     $result.=$r->{qmsg}."\n";
                  }
               }
            }
            $W5V2::OperationContext=$oldcontext;
         }
         else{
            $result.="ERROR: rule $QualityRule2Test not compatible";
         }
      }
   }
   else{
      $result.="ERROR - rule $QualityRule2Test not found\n";
   }
   
   return($result);
}


sub isViewValid
{
   my $self=shift;
   if ($self->IsMemberOf("admin")){
      return(1);
   }
   return(0);
}

1;
