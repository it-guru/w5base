package kernel::Field::WorkflowRelation;
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
use Data::Dumper;
use kernel::MenuTree;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}



sub ListRel
{
   my $self=shift;
   my $refid=shift;
   my $mode=shift;
   my $rootflt=shift;
   my $d="";
   my $fo=$self->getRelationObj();
   my @filelist=();

   my @oplist=({srcwfid=>\$refid},"right","");
   if ($mode ne "edit"){
      push(@oplist,({dstwfid=>\$refid},"left","REV."));
   }
               
   $d="";
   my $headadd=0;
   my $baseurl;
   if ($ENV{SCRIPT_URI} ne ""){
      $baseurl=$ENV{SCRIPT_URI};
      $baseurl=~s#/auth/.*$##;
   }


   my $linecolor=1;
   while(my $flt=shift(@oplist)){
      my $ico=shift(@oplist);
      my $transpref=shift(@oplist);
      $fo->ResetFilter();
      my %curflt=%$flt;
      if (defined($rootflt)){
         foreach my $k (keys(%$rootflt)){
            $curflt{$k}=$rootflt->{$k};
         }
      }
      $fo->SetFilter(\%curflt);

      foreach my $rec ($fo->getHashList(qw(mdate id dstwfid srcwfid
                                           translation additional
                                           dstwfheadref srcwfheadref
                                           dstwfname srcwfname name comments))){
         if (defined($rec)){
            if ($mode ne "mail"){
               if (!$headadd){
                  $d.="<div class=${mode}SubList>";
                  $d.="<table width=100% border=0 cellspacing=0 cellpadding=0>";
                  $headadd=1;
               }
            }
            my $onclick;
            my $partnerid=$rec->{dstwfid};
            if ($transpref eq "REV."){
               $partnerid=$rec->{srcwfid};
            }
           
            $onclick="onClick=openwin(\"../../base/workflow/Process?".
                     "AllowClose=1&id=$partnerid\",\"_blank\",".
                     "\"height=480,width=640,toolbar=no,status=no,".
                     "resizable=yes,scrollbars=no\")";
            if ($mode eq "edit"){
               $onclick="onClick=linkedit($rec->{id})";
            }

            my $lineclass="subline$linecolor"; 
            if ($mode ne "mail"){
               $d.="<tr class=$lineclass ".
                   "onMouseOver=\"this.className='linehighlight'\" ".
                   "onMouseOut=\"this.className='$lineclass'\"><td>";
            }
            $linecolor=1 if ($linecolor>2);


            my $rowspan=1;
            if ($mode ne "mail"){
               $d.="<table width=100% border=0 cellspacing=0 cellpadding=0>";
               $d.="<tr><td width=1% nowrap style=\"border-top:solid;".
                   "border-width:1px;border-top-color:silver\">";
               if ($mode ne "edit"){
                  $d.="<a class=sublink href=javascript:openwin(\"".
                      "../../base/workflowrelation/Detail?AllowClose=1&".
                      "id=$rec->{id}\",\"_blank\",\"height=480,width=640,".
                      "toolbar=no,status=no,resizable=yes,scrollbars=no\")>";
               }
               $d.="<img src=\"../../base/load/workflowrelation_$ico.gif\" ".
                   "border=0>";
               if ($mode ne "edit"){
                  $d.="</a>";
               }
               $d.="&nbsp;</td>";
            }
            next if ($mode eq "" && !$fo->isViewValid($rec));
            my $label=$rec->{name};
            my $partner=$rec->{dstwfname};
            my $iid=$rec->{dstwfid};
            my $lnkid=$rec->{dstwfid};
            if ($rec->{dstwfsrcid} ne ""){
               $iid.="($rec->{dstwfsrcid})"; 
            }
            if ($transpref eq "REV."){
               $iid=$rec->{srcwfid};
               if ($rec->{srcwfsrcid} ne ""){
                  $iid.="($rec->{srcwfsrcid})"; 
               }
               $lnkid=$rec->{srcwfid};
               $partner=$rec->{srcwfname};
            }
            my $trlabel=$self->getParent->T($transpref.$label,
                                            $rec->{translation}); 
            if ($trlabel=~m/\%s/){
               $trlabel=sprintf($trlabel,$iid);
            }
            else{
               $trlabel.=" $iid";
            }
            if ($mode eq "mail"){
               $d.="---\n" if ($d ne "");
               $d.="<li class=workflowrelations><b>".$trlabel."</b>\n";
               $d.="$partner\n";
               $d.="$baseurl/auth/base/workflow/ById/$lnkid </li>\n";
            }
            else{
               my $pref="";
               my @show=();
               if (ref($rec->{additional}->{show}) eq "ARRAY"){
                  @show=@{$rec->{additional}->{show}};
               }
               if (grep(/^headref.taskexecstate$/,@show)){
                  my $p="?";
                  if ($transpref eq "REV."){
                     $p=$rec->{srcwfheadref}->{taskexecstate};
                  }
                  else{
                     $p=$rec->{dstwfheadref}->{taskexecstate};
                  }
                  $p=$p->[0] if (ref($p) eq "ARRAY");
                  $pref=sprintf("%d \%",$p) if ($p ne "");
                  $pref="<font color=\"green\">$pref</font>" if ($p==100);
                  $pref="($pref)" if ($pref ne "");
                  $pref.=" " if ($pref ne "");
               }
               #print STDERR Dumper($rec->{additional});
               #print STDERR Dumper($rec->{dstwfheadref});
               #print STDERR Dumper($rec->{srcwfheadref});
               $d.="<td $onclick style=\"border-top:solid;border-width:1px;".
                   "border-top-color:silver\">$pref<b>".$trlabel.
                   "</b></td></tr>";
               if ($partner ne ""){
                  $d.="<tr><td></td><td $onclick>$partner</td></tr>";
               }
               if ($transpref ne "REV."){
                  if ($rec->{comments} ne ""){ #comment are not displayed in rev
                     $d.="<tr><td></td><td $onclick>$rec->{comments}</td></tr>";
                  }
               }
               $d.="</table>";
               $d.="</td></tr>";
            }
         }
      }
   }
   if ($mode ne "mail"){
      $d.="</table>" if ($headadd);
      $d.="</div>" if ($headadd);
   }
   else{
      $d="<ul class=workflowrelations>".$d."</ul>";
   }
   return($d);
}

sub getRelationObj
{
   my $self=shift;

   my $fo=$self->{fo};
   if (!defined($fo)){
      $fo=getModuleObject($self->getParent->Config,"base::workflowrelation");
      $fo->setParent($self->getParent());
      $self->{fo}=$fo;
   } 
   $fo->ResetFilter();
   return($fo);
}

sub getPosibleRelations
{
   my $self=shift;
   return($self->getParent->getPosibleRelations(@_));
}

sub validateRelationWrite
{
   my $self=shift;
   return($self->getParent->validateRelationWrite(@_));
}


sub HandleAdd
{
   my $self=shift;
   my $refid=shift;
   my $d="";
   my $oldrec;
   my $id=Query->Param("id");
   if ($id ne ""){
      my $fo=$self->getRelationObj();
      $fo->SetFilter({id=>\$id});
      my ($rec,$msg)=$fo->getOnlyFirst(qw(ALL));
      $oldrec=$rec if (defined($rec));
   }
   

   my $wf=$self->getParent;
   $wf->ResetFilter();
   $wf->SetFilter({id=>\$refid});
   my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
   my @relations=$self->getPosibleRelations($WfRec);

   my $parentobj=$self->{parentobj};
   if (!defined($parentobj)){
      $parentobj=$self->getParent->Self();
   }
   if (Query->Param("CANCEL") ne ""){
      Query->Delete("id");
      print <<EOF;
<script language=JavaScript>
parent.document.forms[0].elements['id'].value='';
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   if (Query->Param("DEL") ne ""){
      my $fo=$self->getRelationObj();
      my $ok=0;
      if (defined($oldrec)){
         if (my $fid=$fo->ValidatedDeleteRecord($oldrec)){
            $ok=1;
         }
      }
      print join("<br>",$self->getParent->LastMsg());

      print <<EOF  if ($ok);
<script language=JavaScript>
parent.document.forms[0].elements['id'].value='';
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   if (Query->Param("ADD") ne ""){
      my $opid=Query->Param("opid");
      my $ok=0;
      $opid=~s/[\s\*\?]//g;
      if (defined($opid) && $opid ne ""){
         my $wf=$self->getParent;
         $wf->ResetFilter();
         $wf->SetFilter({id=>\$opid});
         my ($lnkWfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         if (!defined($lnkWfRec)){
            $wf->ResetFilter();
            $wf->SetFilter({srcid=>\$opid});
            ($lnkWfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
         }
         if (defined($lnkWfRec)){
            my $fo=$self->getRelationObj();
            my @r=@relations;
            my $translation;
            my $name=Query->Param("name");
            while(my $trans=shift(@r)){
               my $opt=shift(@r);
               if ($opt eq $name){
                  $translation=$trans;
                  last;
               }
            }
            my $comments=Query->Param("comments");
            my %rec=(dstwfid=>$lnkWfRec->{id},
                     srcwfid=>$refid,
                     name=>$name,
                     translation=>$translation,
                     comments=>$comments);
            if (defined($oldrec)){
              if (my $fid=$fo->ValidatedUpdateRecord($oldrec,\%rec,{id=>\$id})){
                 $self->getParent->LastMsg(INFO,"ok");
                 $ok=1;
              }
            }
            else{
              if (my $fid=$fo->ValidatedInsertRecord(\%rec)){
                 $self->getParent->LastMsg(INFO,"ok");
                 $ok=1;
              }
           }
         }
      }
      else{
         $self->getParent->LastMsg(ERROR,"no WorkflowID specified");
         
      }
      print join("<br>",$self->getParent->LastMsg());

      print <<EOF  if ($ok);
<script language=JavaScript>
parent.document.forms[0].elements['id'].value='';
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   my $oldname;
   my $opid;
   my $comments;
   if ($id ne ""){
      my $wr=$self->getRelationObj();
      $wr->SetFilter({id=>\$id});
      my ($relrec,$msg)=$wr->getOnlyFirst(qw(ALL));
      if (defined($relrec)){
         $opid=$relrec->{dstwfid};
         $oldname=$relrec->{name};
         $comments=$relrec->{comments};
      }
      else{
         Query->Delete("id");
         $id=undef;
      }
   }
   my $lableADD=$self->getParent->T("Add",$self->Self);
   my $lableCANCEL=$self->getParent->T("Cancel",$self->Self);
   my $lableDELETE=$self->getParent->T("Delete",$self->Self);
   my $lableUPDATE=$self->getParent->T("Update",$self->Self);
   my $buttons="<input type=submit name=ADD ".
               "style=\"width:100px\" value=\"$lableADD\">";
   if (defined($oldrec)){
      $buttons="<input type=submit name=ADD ".
               "style=\"width:100px\" value=\"$lableUPDATE\">".
               "<input type=submit name=DEL ".
               "style=\"width:100px\" value=\"$lableDELETE\">".
               "<input type=submit name=CANCEL ".
               "style=\"width:100px\" value=\"$lableCANCEL\">";
   }
   my $namedrop="<select name=name style=\"width:100%\">";
   while(my $trans=shift(@relations)){
      my $opt=shift(@relations);
      $namedrop.="<option value=\"$opt\"";
      $namedrop.=" selected" if ($oldname eq $opt);
      $namedrop.=">";
      $namedrop.=sprintf($self->getParent->T($opt,$trans),"&lt;?&gt;");
      $namedrop.="</option>";
   }
   $namedrop.="</select>";

   my $lableComments=$self->getParent->T("Comments",$self->Self);
   my $lableRelation=$self->getParent->T("Relation",$self->Self);
   $d.=<<EOF;
<div class=EditFrame>
<table width=100% cellpadding=1 cellspacing=1 height=40 border=0>
<tr height=1%>
<td width=1%>WorkflowID:</td>
<td><input type=text name=opid style="width:100%" value="$opid" size=20></td>
<td width=1% nowrap>$buttons</td>
</tr><tr><td></td></tr>
<tr height=1%>
<td width=1%>$lableRelation:</td>
<td colspan=2>$namedrop</td>
</tr><tr><td></td></tr>
<tr height=1%>
<td width=1%>$lableComments:</td>
<td colspan=2><input type=text name=comments value="$comments" style="width:100%"></td>
</tr><tr><td></td></tr>
</table>
</div>
<script language=JavaScript>
function linkedit(id){
   document.forms[0].elements['id'].value=id;
   document.forms[0].target='_self';
   document.forms[0].submit();
}
</script>
EOF
   print $d;
}

sub ViewProcessor
{
   my $self=shift;
   my ($mode,$refid,$id,$field,$seq)=@_;

   my $fo=$self->getRelationObj();
   
   my $idfield=$self->getParent->IdField->Name();
   $self->getParent->ResetFilter();
   $self->getParent->SetFilter({$idfield=>\$refid});
   $self->getParent->SetCurrentView(qw(ALL));
   my ($rec,$msg)=$self->getParent->getFirst();
   my @l=$self->getParent->isViewValid($rec);
   if (defined($rec) && (grep(/^$self->{group}$/,@l) || grep(/^ALL$/,@l))){
      $fo->ResetFilter();
      $fo->SetFilter({fid=>\$id});
      $fo->SetCurrentView(qw(ALL));
      my ($frec,$msg)=$fo->getFirst();
      if (defined($frec) && $fo->isViewValid($frec)){
          $fo->sendFile($id,0);
      }
      else{
         print $self->getParent->HttpHeader("text/plain");
         print("ERROR: No Access to file");
      }
      return();
   }
   print $self->getParent->HttpHeader("text/plain");
   print("ERROR: No Access to filelist");
}


sub EditProcessor
{
   my $self=shift;
   my $refid=shift;
   my $fieldname=shift;
   my $seq=shift;
   print $self->getParent->HttpHeader("text/html");
   print $self->getParent->HtmlHeader(style=>['default.css','work.css',
                                              'kernel.workflowrelation.css'],
                                              body=>1,form=>1,
                                      formtarget=>'DO');
   if (!defined(Query->Param("MODE"))){
      Query->Param("MODE"=>"FileListMode.FILEADD");
   }
   print("<div class=WorkflowRelation>");
   $self->HandleAdd($refid);
   return() if (Query->Param("CANCEL") ne "");
   return() if (Query->Param("SAVE") ne "");
   return() if (Query->Param("ADD") ne "");
   return() if (Query->Param("DEL") ne "");
   print <<EOF;
<iframe style="width:97%;height:25px;overflow:hidden;border-style:none;padding:0;margin:0" 
        name=DO src=Empty scrolling="no" frameborder="0"></iframe>
EOF
   my $mode="edit";
   print $self->ListRel($refid,$mode);
   print $self->getParent->HtmlPersistentVariables(qw(MODE OP Field Seq id
                                                      RefFromId));
   print("</div>");
   print $self->getParent->HtmlBottom(form=>1,body=>1);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $app=$self->getParent;
   my $idfield=$app->IdField();
   my $id=$idfield->RawValue($current);
   my $name=$self->Name();
   $self->{Sequence}++;

   if ($mode eq "HtmlDetail"){
      return($self->ListRel($id));
   }
   if ($mode eq "edit"){
      my $h=$self->getParent->DetailY()-240;
      return(<<EOF);
<iframe id=iframe.sublist.$name.$self->{Sequence}.$id 
        src="EditProcessor?RefFromId=$id&Field=$name&Seq=$self->{Sequence}"
        style="width:99%;height:${h}px;border-style:solid;border-width:1px;">
</iframe>
EOF

   }
   return("unknown mode '$mode'");
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;

   return("FieldHandler-Formated");
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   return("no RawValue");
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   my $idfield=$self->getParent->IdField()->Name();
   my $id=$oldrec->{$idfield};
   my $wr=$self->getRelationObj();
   if ($id ne ""){ 
      $wr->SetFilter([{srcwfid=>\$id},{dstwfid=>\$id}]);
      $wr->SetCurrentView(qw(ALL));
      $wr->ForeachFilteredRecord(sub{
                         $wr->ValidatedDeleteRecord($_);
                      });
   }
   return(undef);
}



sub Uploadable
{
   my $self=shift;

   return(0);
}











1;
