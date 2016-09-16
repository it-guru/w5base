package base::qrule::InvalidRefChk;
#######################################################################
=pod

=head3 PURPOSE

Checks if there are contact or group references in the current
record, whitch are marked as "disposed of waste".
This qrule can check fields with type ...
kernel::Field::ContactLnk
kernel::Field::Contact
kernel::Field::Group
kernel::Field::Databoss
The rule removes references to contact or group enties, where the
target record is in state "wasted".

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Prüft, ob der Datensatz veraltete Kontaktreferenzen enthält. 
Ungültige Kontakte oder Gruppen im aktuellen Datensatz erkennt man 
anhand einer Nummer in eckigen Klammern am Ende des Kontaktes. 
Ein DataIssue wird erzeugt, wenn ein Datensatz einen oder mehrere 
veraltete Kontakt/Gruppenreferenzen enthält. Um das DataIssue zu beheben, 
muss man veraltete Kontakte am Datensatz finden und entfernen oder 
bei Bedarf durch neue Kontakpersonen bzw. Gruppen mit entsprechenden 
Rollen ersetzen.

Die QualityRule entfernt Referenzen auf Kontakte oder Gruppen, bei denen
der Zieldatensatz im Status "entsorgt" steht.

Bei Fragen wenden Sie sich bitte an den DARWIN Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


[en:]

Checks, if there are invalid contact references on the CI. 
Invalid contacts or groups can be identified 
by a number in square brackets at the end. 
A DataIssue is created when there are one or more invalid contacts on the CI. 
The DataIssue can be resolved by finding and deleting 
the invalid contact references. 
If necessary, new users or groups with the corresponding roles can be added.

If you have any questions please contact the Darwin Support:
https://darwin.telekom.de/darwin/auth/base/user/ById/12390966050001


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return([".*"]);
}

sub setReferencesToNull
{
   my $self=shift;
   my $dataobj=shift;
   my $reason=shift;
   my $chkrec=shift;
   my $rec=shift;

   my $idfield=$dataobj->IdField();
   if (defined($idfield)){
      my $idname=$idfield->Name();
      foreach my $ref (@{$chkrec->{r}}){
         #printf STDERR ("setReferencesToNull CleanupRec:%s\n",Dumper($ref));
         if ($ref->{type} ne "ContactLnk"){
            if ($ref->{type} ne "Databoss"){
               printf STDERR ("setReferencesToNull on %s (%s) with ".
                              "reason '$reason' in Field ".
                              "'%s' (old=%s)\n",$dataobj->Self(),
                              $rec->{$idname},$ref->{rawfield},
                              $rec->{$ref->{rawfield}});
               $dataobj->UpdateRecord({$ref->{rawfield}=>undef},
                                      {$idname=>\$rec->{$idname}});
            }
         }
         else{
            printf STDERR ("setReferencesToNull on %s (%s) with ".
                           "reason '$reason' in Field ".
                           "'%s' recid=%s\n",$dataobj->Self(),
                           $rec->{$idname},"lnkcontact",
                           $ref->{rawrecid});
            my $o=getModuleObject($dataobj->Config(),"base::lnkcontact");
            $o->DeleteRecord({id=>\$ref->{rawrecid}});
         }
      }
   }
   else{
      Stacktrace();
   }
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if (!exists($rec->{cistatusid}) || $rec->{cistatusid}>5);

   my @chkfieldtypes=qw(ContactLnk Contact Group Databoss);
   my $chkfieldtypes=join("|",@chkfieldtypes);
   my @fobjlst;
   foreach my $fieldname ($dataobj->getFieldList(current=>$rec)){
      my $fobj=$dataobj->getField($fieldname);
      my $t=$fobj->Type();
      next if ($fobj->{readonly} eq "1");
      my $htmldetail=$fobj->htmldetail("HtmlDetail",current=>$rec);
      next if (!$htmldetail);
      if (defined($fobj) && $fobj->Type()=~m/^($chkfieldtypes)$/){
         push(@fobjlst,$fobj);
      }
   }
   my $user=$dataobj->ModuleObject("base::user");
   my $grp=$dataobj->ModuleObject("base::grp");
   my @failmsg;
   my @dataissue;


   my %chklst;

   foreach my $fobj (@fobjlst){
      next if (!$fobj->uivisible());
      my $rrec={
         field=>$fobj->Name(),
         label=>$fobj->Label(),
         type=>$fobj->Type()
      };
      if ($fobj->Type() ne "ContactLnk"){
         my $idfobj=$dataobj->getField($fobj->{vjoinon}->[0]);
         $rrec->{rawfield}=$fobj->{vjoinon}->[0];
         if (defined($idfobj)){
            my $id=$idfobj->RawValue($rec);
            if ($id ne ""){
               my $k=$fobj->{vjointo}."::".$id;
               if (!exists($chklst{$k})){
                  $chklst{$k}={
                     target=>$fobj->{vjointo},
                     targetid=>$id,
                     r=>[$rrec]
                  }
               }
               else{
                  push(@{$chklst{$k}->{r}},$rrec);
               }
            }
         }
      }
      else{
         my $val=$fobj->RawValue($rec);
         if (ref($val) eq "ARRAY"){
            foreach my $r (@$val){
               $rrec={%{$rrec}};
               $rrec->{rawrecid}=$r->{id};
               if ($r->{targetid} ne "" &&
                   ($r->{target} eq "base::user" || 
                    $r->{target} eq "base::grp")){
                  my $k=$r->{target}."::".$r->{targetid};
                  if (!exists($chklst{$k})){
                     $chklst{$k}={
                        target=>$r->{target},
                        targetid=>$r->{targetid},
                        r=>[$rrec]
                     }
                  }
                  else{
                     push(@{$chklst{$k}->{r}},$rrec);
                  }
               }
            }
         } 
      }
   }

   foreach my $k (keys(%chklst)){
      my $target=$chklst{$k}->{target};
      my $targetid=$chklst{$k}->{targetid};
      if ($target eq "base::grp"){
         $grp->ResetFilter();
         $grp->SetFilter({grpid=>\$targetid});
         my ($chkrec)=$grp->getOnlyFirst(qw(cistatusid fullname));
         if (!defined($chkrec)){
            $self->setReferencesToNull($dataobj,"invalid",$chklst{$k},$rec);
         }
         else{
            if ($chkrec->{cistatusid}>5 || $chkrec->{cistatusid}<3){
               if ($chkrec->{cistatusid}==7){
                  $self->setReferencesToNull($dataobj,"deleted",
                                             $chklst{$k},$rec);
               }
               else{
                  foreach my $ref (@{$chklst{$k}->{r}}){
                     push(@failmsg,$ref->{label}.": ".$chkrec->{fullname}." ".
                                   $self->T("is invalid"));
                  }
                  push(@dataissue,$chkrec->{fullname});
               }
            }
         }
      }
      if ($target eq "base::user"){
         $user->ResetFilter();
         $user->SetFilter({userid=>\$targetid});
         my ($chkrec)=$user->getOnlyFirst(qw(cistatusid fullname));
         if (!defined($chkrec)){
            foreach my $ref (@{$chklst{$k}->{r}}){
               $self->setReferencesToNull($dataobj,"invalid",$chklst{$k},$rec);
            }
         }
         else{
            if ($chkrec->{cistatusid}>5 || $chkrec->{cistatusid}<3){
               if ($chkrec->{cistatusid}==7){
                  $self->setReferencesToNull($dataobj,"deleted",
                                             $chklst{$k},$rec);
               }
               else{
                  foreach my $ref (@{$chklst{$k}->{r}}){
                     push(@failmsg,$ref->{label}.": ".$chkrec->{fullname}." ".
                                   $self->T("is invalid"));
                  }
                  push(@dataissue,$chkrec->{fullname});
               }
            }
         }
      }
   }


   if ($#failmsg!=-1){
     # printf STDERR ("check fail:%s\n",Dumper(\@failmsg));
      return(3,{qmsg=>['There are invalid contact references!',@failmsg],
                dataissue=>['There are invalid contact references!',@dataissue]});
   }
   
   return(0,undef);
}



1;
