package kernel::Field::FileList;
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
use kernel::MenuTree;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   $self->{'searchable'}=0;
   $self->{'showcomm'} = 0 if !defined($self->{'showcomm'});

   return($self);
}

sub ModeLine
{
   my $self=shift;
   my $oldmode=shift;
   my @modes=("FileListMode.FILEADD",
      #        "FileListMode.DIRADD",
              "FileListMode.DELENT");

   my $d="";
   while(my $e=shift(@modes)){
      $d.=" &bull; " if ($d ne "");
      $d.="<a class=FileListMode href=JavaScript:setFileListMode(\"$e\")>";
      $d.=$self->getParent->T($e,'kernel::FileList')."</a>";
   }
   $d=<<EOF;
<script language="JavaScript">
function setFileListMode(o)
{
   var op=document.forms[0].elements['OP'];
   var mode=document.forms[0].elements['MODE'];
   mode.value=o;
   op.value="";
   document.forms[0].target="_self";
   document.forms[0].submit();
}
</script>
<div class=FileListModeLine>
$d
</div>
EOF

}


sub ListFiles
{
   my $self=shift;
   my $refid=shift;
   my $mode=shift;
   my $d="";
   my $fo=$self->getFileManagementObj();
   my @filelist=();
   my $parentobj=$self->{parentobj};
   if (!defined($parentobj)){
      $parentobj=$self->getParent->Self();
   }
   $fo->SetFilter({parentobj=>$parentobj,
                   parentrefid=>$refid});
   my $ownerfield=$fo->getField("owner");
   foreach my $rec ($fo->getHashList(qw(ALL))){
      if (defined($rec)){
         #next if ($mode eq "" && !$fo->isViewValid($rec));
         next if (!$fo->isViewValid($rec));
         $d.=$rec->{name}."<br>\n";
         my %clone=(%{$rec});
         $clone{label}=$clone{name};
         if ($rec->{isprivate}){
            my $privacy=$self->getParent->T(
                        "privacy information - ".
                        "only readable with rule write or privacy read");
            $clone{label}.="&nbsp;<a title=\"$privacy\">".
                         "<font color=red><b>!</b></font></a>";
         }
         my $ownername=$ownerfield->FormatedDetail($rec,"HtmlV01");
         my $t=$self->getParent->ExpandTimeExpression($rec->{mdate},
               $self->getParent->Lang())." GMT ".
               $self->getParent->T("by","kernel::FileList").
               " ".
               $ownername;

         $clone{description}="$t";
         
         $clone{href}="ViewProcessor/load/$self->{name}/".
                      "$refid/$clone{fid}/$clone{name}";
         if ($mode eq "FileListMode.DELENT"){
            $clone{labelprefix}="<input type=checkbox name=delid$clone{fid}>";
         }
         push(@filelist,\%clone);
      }
   }
   $d="";
   if ($#filelist!=-1){
      my $lang=$self->getParent->Lang();
      my %p=('tree'     =>\@filelist,
             'rootimg'  =>"minifileroot.gif?HTTP_FORCE_LANGUAGE=$lang",
             'rootpath' =>'./',
             'hrefclass'=>'filelink',
             'showcomm' =>$self->{'showcomm'});
      $d=kernel::MenuTree::BuildHtmlTree(%p);
   }
   return($d);
}

sub getFileManagementObj
{
   my $self=shift;

   my $fo=$self->{fo};
   if (!defined($fo)){
      $fo=getModuleObject($self->getParent->Config,"base::filemgmt");
      $fo->setParent($self->getParent());
      $self->{fo}=$fo;
   } 
   return($fo);
}

sub HandleFILEADD
{
   my $self=shift;
   my $refid=shift;
   my $d="";
   my $parentobj=$self->{parentobj};
   if (!defined($parentobj)){
      $parentobj=$self->getParent->Self();
   }
   if (Query->Param("DO") ne ""){
      my $isprivate=0;
      if (Query->Param("isprivate") ne ""){
         $isprivate=1;
      }
      my $fh=Query->Param("file");
      my $comments=Query->Param("comments");
      my $ok=0;
      if (defined($fh) && $fh ne ""){
         my $fo=$self->getFileManagementObj();
         my %rec=(file=>$fh,
                  isprivate=>$isprivate,
                  parentobj=>$parentobj,
                  comments=>$comments,
                  parentrefid=>$refid,
                  name=>$fh);
         if (my $fid=$fo->ValidatedInsertRecord(\%rec)){
            $self->getParent->LastMsg(INFO,"ok");
            $ok=1;
            if ($fid ne ""){
               if (ref($self->{onFileAdd}) eq "CODE"){
                  $fo->ResetFilter();
                  $fo->SetFilter({fid=>\$fid}); 
                  my ($rec,$msg)=$fo->getOnlyFirst(qw(ALL));
                  &{$self->{onFileAdd}}($self,$rec);
               }
               Query->Delete("isprivate");
               Query->Delete("comments");
               Query->Delete("file");
            }
         }
      }
      else{
         $self->getParent->LastMsg(ERROR,"no file specified");
         
      }
      print join("<br>",$self->getParent->LastMsg());

      print <<EOF  if ($ok);
<script language=JavaScript>
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   my $comments=Query->Param("comments");
   my $isprivate="";
   if (Query->Param("isprivate") ne ""){
      $isprivate=" checked ";
   }
   $d.="<div class=FileListModeWork>";
   $d.="<table width=\"100%\" height=80 border=0>";
   $d.="<tr height=\"1%\">";
   $d.="<td>".$self->getParent->T("File to upload",'kernel::FileList').":</td>";
   $d.="<td colspan=2><input type=file name=file size=40></td>";
   $d.="</tr><tr>".
       "<tr><td width=\"1%\" nowrap>".
       $self->getParent->T("comments",'kernel::FileList')."</td>".
       "<td colspan=2><input name=comments value=\"$comments\" ".
       "type=text style=\"width:100%\"></tr>".
       "<tr><td width=\"1%\" nowrap>".
       $self->getParent->T("handle file as private",'kernel::FileList')."</td>".
       "<td><input type=checkbox $isprivate name=isprivate></td>";
   $d.="<td valign=bottom>".
       "<input type=submit name=DO style=\"width:100%\" value=\"".
       $self->getParent->T("Upload",'kernel::FileList')."\"></td>";
   $d.="</tr>";
   $d.="</table>";
   $d.="</div>";
   print $d;
}

sub HandleDIRADD
{
   my $self=shift;
   my $refid=shift;
   my $d="";
   $d.=$self->getParent->getParsedTemplate(
             "tmpl/kernel.filelist.diradd",{skinbase=>'base'});
   print $d;
}

sub HandleDELENT
{
   my $self=shift;
   my $refid=shift;
   my $d="";
   my $parentobj=$self->{parentobj};
   if (!defined($parentobj)){
      $parentobj=$self->getParent->Self();
   }
   if (Query->Param("DO") ne ""){
      my $ok=0;
      my @idlist=();
      foreach my $v (Query->Param()){
         if (my ($id)=$v=~m/^delid(\d+)$/){
            push(@idlist,$id);
         }
      }
      if ($#idlist!=-1){
         my $fo=$self->getFileManagementObj();
         $fo->SetFilter({fid=>\@idlist,
                         parentobj=>\$parentobj,
                         parentrefid=>$refid});
         $fo->SetCurrentView(qw(ALL));
         $fo->ForeachFilteredRecord(sub{
                         $fo->ValidatedDeleteRecord($_);
                      });
         $ok=1;
      }
      else{
         $self->getParent->LastMsg(ERROR,"no file specified");
         
      }
      print join("<br>",$self->getParent->LastMsg());

      print <<EOF  if ($ok);
<script language=JavaScript>
parent.document.forms[0].target='_self';
parent.document.forms[0].submit();
</script>
EOF
      return();
   }
   $d.="<div class=FileListModeWork>";
   $d.="<table width=\"100%\" height=\"40\" border=\"0\">";
   $d.="<tr height=\"1%\">";
   $d.="<td><input type=submit name=DO style=\"width:100%\" value=\"".
       $self->getParent->T("delete marked files",'kernel::FileList')."\"></td>";
   $d.="</tr><tr><td></td></tr>";
   $d.="</table>";
   $d.="</div>";
   print $d;
}

sub ViewProcessor
{
   my $self=shift;
   my ($mode,$refid,$id,$field,$seq)=@_;

   my $fo=$self->getFileManagementObj();
   
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
                                              'kernel.filemgmt.css'],
                                              body=>1,form=>1,multipart=>1,
                                      formtarget=>'DO');
   if (!defined(Query->Param("MODE"))){
      Query->Param("MODE"=>"FileListMode.FILEADD");
   }
   my $mode=Query->Param("MODE");
   print("<div class=FileList>");
   if (Query->Param("DO") eq ""){
      print $self->ModeLine($mode);
   }
   CASE:{
      $mode eq "FileListMode.FILEADD" && do{
         $self->HandleFILEADD($refid);
         last CASE;
      };
      $mode eq "FileListMode.DIRADD" && do{
         $self->HandleDIRADD($refid);
         last CASE;
      };
      $mode eq "FileListMode.DELENT" && do{
         $self->HandleDELENT($refid);
         last CASE;
      };
   }
   return() if (Query->Param("DO") ne "");
   print <<EOF;
<iframe src=Empty style="width:100%;height:25px;overflow:hidden;border-style:none;padding:0;margin:0" 
        name=DO scrolling="no" frameborder="0"></iframe>
EOF
   print("</div>");
   print $self->ListFiles($refid,$mode);
   print $self->getParent->HtmlPersistentVariables(qw(MODE OP Field Seq 
                                                      RefFromId));
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
      return($self->ListFiles($id));
   }
   if ($mode eq "edit"){
      my $h=$self->getParent->DetailY()-80;
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

   my @files;
   my $excl='!';
   $excl="<font color=red><b>!</b></font>" if ($FormatAs=~m/^html/i);

   foreach my $attachment (@{$current->{attachments}}) {
      if (!$attachment->{isprivate}) {
         push(@files,$attachment->{name});
      }
      else {
         my $prirec=$self->getFileManagementObj->loadPrivacyAcl(
                              $attachment->{parentobj},
                              $attachment->{parentrefid});
         if ($prirec->{rw} || $self->getParent->IsMemberOf("admin")){
            push(@files,$attachment->{name}.$excl);
         }
      }
   }

   return(join(', ',@files));
}

sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   my $idfield=$app->IdField();
   my $refid=$idfield->RawValue($current);
   my $fo=$self->getFileManagementObj();
   my @filelist=();
   my $parentobj=$self->{parentobj};
   if (!defined($parentobj)){
      $parentobj=$self->getParent->Self();
   }
   $fo->SetFilter({parentobj=>$parentobj,
                   parentrefid=>$refid});
   foreach my $rec ($fo->getHashList(qw(ALL))){
      if (defined($rec)){
         my %clone=(%{$rec});
         $clone{label}=$clone{name};
         $clone{href}="ViewProcessor/load/$self->{name}/".
                      "$refid/$clone{fid}/$clone{name}";
         push(@filelist,\%clone);
      }
   }
   return(\@filelist);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   my $idfield=$self->getParent->IdField()->Name();
   my $id=$oldrec->{$idfield};
   my $fo=$self->getFileManagementObj();
   $fo->SetFilter({parentobj=>$self->getParent->Self(),
                   parentrefid=>$id});
   $fo->SetCurrentView(qw(ALL));
   $fo->ForeachFilteredRecord(sub{
                      print STDERR msg(INFO,"drop file %s",$_->{fullname});
                      $fo->ValidatedDeleteRecord($_);
                   });
   return(undef);
}


sub Uploadable
{
   my $self=shift;

   return(0);
}











1;
