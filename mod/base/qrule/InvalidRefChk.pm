package base::qrule::InvalidRefChk;
#######################################################################
=pod

=encoding latin1

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

[en:]

Checks, if there are invalid contact references on the CI. 
Invalid contacts or groups can be identified 
by a number in square brackets at the end. 
A DataIssue is created when there are one or more invalid contacts on the CI. 
The DataIssue can be resolved by finding and deleting 
the invalid contact references. 
If necessary, new users or groups with the corresponding roles can be added.

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
use Digest::MD5 qw(md5_base64);
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


sub NotifyContactDataModification
{
   my $self=shift;
   my $operation=shift;
   my $dataobj=shift;
   my $reason=shift;
   my $ref=shift;
   my $rec=shift;
   my $contactrec=shift;
   my $add=shift;

   return() if (exists($rec->{cistatusid}) && $rec->{cistatusid}>5);

   my $targetid;
   if (exists($rec->{databossid})){
      $targetid=$rec->{databossid};
   }
   if ($operation eq "databosschange"){
      $targetid=$add;
   }
   if ($operation eq "lastbossnotify"){
      $targetid=$add;
   }
   my %notifyparam;
   my $notifycontrol={};
   if ($targetid ne ""){
      my $notifymode="INFO";
      my $user=getModuleObject($dataobj->Config(),"base::user");
      $user->SetFilter(userid=>\$targetid);
      my ($targetrec)=$user->getOnlyFirst(qw(fullname email lang talklang));
      if (defined($targetrec)){
         $notifyparam{emailfrom}="\"W5Base Contact-Cleanup\" <>";
         $notifyparam{emailto}=[$targetid]; 
         $notifyparam{emailbcc}=[11634953080001];
         $notifyparam{emailcategory}=['ContactCleanup','InvalidRefChk'];
         $notifyparam{lang}=$targetrec->{lang} ne "" ? 
                                $targetrec->{lang} : $targetrec->{talklang};
         $notifyparam{lang}="en" if ($notifyparam{lang} eq "");
         my $text;
         my $lastlang;
         if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
            $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
         }
         $ENV{HTTP_FORCE_LANGUAGE}=$notifyparam{lang};
         my $subject;
         my $mtemplate="base.qrule.InvalidRefChk.Notify.".$operation;
         if ($operation eq "databosschange"){
            $subject=$dataobj->T("databoss handover to you");
         }
         elsif ($operation eq "roledel"){
            $subject=$dataobj->T("void role field");
         }
         elsif ($operation eq "contactdel"){
            $subject=$dataobj->T("remove of contact entry");
         }
         elsif ($operation eq "lastbossnotify"){
            $subject=$dataobj->T("imminent databoss handover to you");
            $notifymode="WARN";
         }

         my $fld=$dataobj->getRecordHeaderField();
         my $datarecname="???";
         my $fieldname="???";
         if (defined($fld)){
            $datarecname=$fld->RawValue($rec);
            $subject.=": ".$datarecname;
         }
         my $fld=$dataobj->getField($ref->{field},$rec);
         if (defined($fld)){
            $fieldname=$fld->Label();
         }
        
         my $text;
         $text.=$dataobj->getParsedTemplate(
             "tmpl/".$mtemplate,{
                skinbase=>'base',
                static=>{
                   FIELDNAME=>$fieldname,
                   CONFIGITEMNAME=>$datarecname,
                   CONTACTNAME=>$contactrec->{fullname},
                }
         });
         #$text.="\nDataobj: $dataobj \n";
         #$text.="\n\n$operation\n".Dumper($contactrec);
         #$text.="\n\nref\n".Dumper($ref);
         my $idfield=$dataobj->IdField();
         if (defined($idfield)){
            $notifyparam{dataobj}=$dataobj->Self();
            $notifyparam{dataobjid}=$rec->{$idfield->Name()};
         }
         if ($operation eq "lastbossnotify"){
            my $str=$operation.':'.$notifyparam{dataobj}.
                    ':'.$notifyparam{dataobjid}.':'.
                    join(",",@{$notifyparam{emailto}});
            my $informationHash=md5_base64($str);
            $notifyparam{infoHash}=$informationHash;
         }
         my ($package,$filename,$line)=caller();
         if ($package ne ""){
            $notifyparam{faqkey}="$package";
         }
         if (defined($subject) && defined($text)){
            if (!defined($notifycontrol->{wfact})){
               $notifycontrol->{wfact}=getModuleObject($dataobj->Config,
                                                       "base::workflowaction");
            }
            $notifycontrol->{wfact}->Notify($notifymode,
                                            $subject,$text,%notifyparam);
         }
         if (defined($lastlang)){
            $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
         }
         else{
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }

      }
   }
}








sub setReferencesToNull
{
   my $self=shift;
   my $dataobj=shift;
   my $reason=shift;
   my $ref=shift;
   my $rec=shift;
   my $contactrec=shift;

   my $ReferenceIsStillInvalid=1;

   my $idfield=$dataobj->IdField();
   if (!defined($contactrec) || $contactrec->{cistatusid}==7){
      if (defined($idfield)){
         my $idname=$idfield->Name();
         if ($ref->{type} ne "ContactLnk"){
            if ($ref->{type} ne "Databoss"){
               $dataobj->UpdateRecord({$ref->{rawfield}=>undef},
                                      {$idname=>\$rec->{$idname}});
               $dataobj->StoreUpdateDelta("update",
                  {$ref->{rawfield}=>$rec->{$ref->{rawfield}},
                   $idname=>$rec->{$idname}},
                  {$ref->{rawfield}=>undef,
                   $idname=>$rec->{$idname}},
                   $self->Self().
                   "\nContact cistatus=$contactrec->{cistatusid}");
               $self->NotifyContactDataModification("roledel",
                                             $dataobj,$reason,$ref,
                                             $rec,$contactrec);
               $ReferenceIsStillInvalid=0;
            }
         }
         else{
            my $o=getModuleObject($dataobj->Config(),"base::lnkcontact");
            $o->SetFilter({id=>\$ref->{rawrecid}});
            my ($oldrec,$msg)=$o->getOnlyFirst(qw(ALL));
            if (defined($oldrec)){
               $o->DeleteRecord({id=>\$ref->{rawrecid}});
               $o->StoreUpdateDelta("delete", $oldrec, undef,
                   $self->Self().
                   "\nContact cistatus=$contactrec->{cistatusid}");
               $self->NotifyContactDataModification("contactdel",
                                             $dataobj,$reason,$ref,
                                             $rec,$contactrec);
            }
            $ReferenceIsStillInvalid=0;
         }
      }
      else{
         Stacktrace();
      }
   }
   return($ReferenceIsStillInvalid);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   #return(0,undef) if (!exists($rec->{cistatusid}) || $rec->{cistatusid}>5);

   my @chkfieldtypes=qw(ContactLnk Contact Group Databoss);
   my $chkfieldtypes=join("|",@chkfieldtypes);
   my @fobjlst;
   foreach my $fieldname ($dataobj->getFieldList(current=>$rec)){
      my $fobj=$dataobj->getField($fieldname);
      if (defined($fobj)){
         my $t=$fobj->Type();
         next if ($fobj->{readonly} eq "1");
         my $htmldetail=$fobj->htmldetail("HtmlDetail",current=>$rec);
         next if (!$htmldetail);
         if (defined($fobj) && $fobj->Type()=~m/^($chkfieldtypes)$/){
            push(@fobjlst,$fobj);
         }
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
         $rrec->{vjointo}=$fobj->getNearestVjoinTarget();
         if (ref($rrec->{vjointo}) eq "SCALAR"){
            $rrec->{vjointo}=${$rrec->{vjointo}};
         }
         my $idfobj=$dataobj->getField($fobj->{vjoinon}->[0]);
         $rrec->{rawfield}=$fobj->{vjoinon}->[0];
         $rrec->{rawvalue}=$rec->{$fobj->{vjoinon}->[0]};
         if (defined($idfobj)){
            my $id=$idfobj->RawValue($rec);
            if ($id ne ""){
               my $k=$rrec->{vjointo}."::".$id;
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
                  $rrec->{vjointo}=$r->{target};
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
      $target=$$target if (ref($target));
      my $targetid=$chklst{$k}->{targetid};
      if ($target eq "base::grp"){
         $grp->ResetFilter();
         $grp->SetFilter({grpid=>\$targetid});
         my ($chkrec)=$grp->getOnlyFirst(qw(cistatusid fullname mdate));
         if (!defined($chkrec)){
            foreach my $ref (@{$chklst{$k}->{r}}){
               $self->setReferencesToNull($dataobj,"invalid",$ref,$rec);
            }
         }
         else{
            if ($chkrec->{cistatusid}>5 || $chkrec->{cistatusid}<3){
               foreach my $ref (@{$chklst{$k}->{r}}){
                  if ($self->setReferencesToNull($dataobj,"deleted",
                                              $ref,$rec,$chkrec)){
                     my $msg=$ref->{label}.": ".$chkrec->{fullname}." ".
                             $self->T("is invalid");
                     push(@failmsg,$msg);
                     $msg=$ref->{label}.": ".$chkrec->{fullname};
                     push(@dataissue,$msg);
                  }
               }
            }
         }
      }
      if ($target eq "base::user"){
         $user->ResetFilter();
         $user->SetFilter({userid=>\$targetid});
         my ($chkrec)=$user->getOnlyFirst(qw(cistatusid fullname email
                                             mdate lastknownbossid
                                                   lastknownpbossid));
         if (!defined($chkrec)){
            foreach my $ref (@{$chklst{$k}->{r}}){
               $self->setReferencesToNull($dataobj,"invalid",$ref,$rec);
            }
         }
         else{
            if ($chkrec->{cistatusid}>5 || $chkrec->{cistatusid}<3){
               foreach my $ref (@{$chklst{$k}->{r}}){
                  if ($self->setReferencesToNull($dataobj,"deleted",
                                                $ref,$rec,$chkrec)){
                     my $msg=$ref->{label}.": ".$chkrec->{fullname}." ".
                                   $self->T("is invalid");
                     push(@failmsg,$msg);
                     $msg=$ref->{label}.": ".$chkrec->{fullname};
                     push(@dataissue,$msg);
                  }
               }
            }
         }
      }
   }
   if ($#failmsg!=-1){
      if (exists($rec->{cistatusid}) &&  $rec->{cistatusid}<=5){
         return(3,{
            qmsg=>['There are invalid contact references!',@failmsg],
            dataissue=>['There are invalid contact references!',@dataissue]
         });
      }
      else{
         return(0,{
            qmsg=>['There are invalid contact references!',@failmsg]
         });
      }
   }
   
   return(0,undef);
}



1;
