package kernel::Field::File;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{sqlorder}="none";   
   if (!exists($self->{onDownloadUrl})){
      $self->{onDownloadUrl}=sub{
         my $self=shift;
         my $current=shift;
         my $parent=$self->getParent();
         my $idField=$parent->IdField();
         my $id;
         if (defined($idField)){
            $id=$idField->RawValue($current);
         }
         if ($id ne ""){
            return("ViewProcessor/Raw/".$self->{name}."/".$id);
         }
         return(undef);
      };
   }
   $self->{size}="14" if (!exists($self->{size}) || $self->{size} eq "");
   $self->{types}=['*'] if (!exists($self->{types}));
   if (ref($self->{types}) ne "ARRAY"){
      $self->{types}=split(/,\s*/,$self->{types});
   }
   if (!defined($self->{content})){
      $self->{content}="application/octet-stream";
   }
   if (!defined($self->{depend})){
      $self->{depend}=[];
   }
   if (ref($self->{depend}) ne "ARRAY"){
      $self->{depend}=[$self->{depend}];
   }
   if (exists($self->{filename}) && $self->{filename} ne ""){
      if (!in_array($self->{depend},$self->{filename})){
         push(@{$self->{depend}},$self->{filename});
      }
   }
   if (exists($self->{uploaddate}) && $self->{uploaddate} ne ""){
      if (!in_array($self->{depend},$self->{uploaddate})){
         push(@{$self->{depend}},$self->{uploaddate});
      }
   }
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();

   my $url;
   if (defined($self->{onDownloadUrl}) &&
       ref($self->{onDownloadUrl}) eq "CODE"){
      $url=&{$self->{onDownloadUrl}}($self,$current);
   }
   if ($mode eq "HtmlDetail"){
      if ($d ne ""){
         if (defined($url)){
            my $filename="FileEntry";
            if (exists($self->{filename}) && 
                $current->{$self->{filename}} ne ""){
               $filename= $current->{$self->{filename}};
            }
            return("&lt; <a class=filelink target=_blank ".
                   "href=\"$url\">$filename</a> &gt;");
         }
      }
      else{
         my $t=$self->getParent->T("no file",
                                   "kernel::Field::File");
         return("&lt; $t &gt;");
      }
   }
   if (($mode eq "edit" || $mode eq "workflow") && !defined($self->{vjointo})){
      my $delflag=0;
      if ($d ne ""){
         $delflag=1;
      }
      return($self->getHtmlInputArea($delflag));
   }
   if ($d ne ""){
      return($url);
   }
   return("<noFile>");
}

sub getHtmlInputArea
{
   my $self=shift;
   my $delflag=shift;
   my $name=$self->Name();
   my $size=$self->{size};

   my $delcode="";
   if ($delflag){
      my $t=$self->getParent->T("check box to delete file on save",
                                "kernel::Field::File");
      $delcode=<<EOF;
<input type=checkbox id="ClearEntry$name" onclick="onChangeClear$name(this);">
<label style="padding:0;margin:0" for="ClearEntry$name"><img title="$t" border=0 style="padding:0;margin:0" width=18 height=18 src="../../../public/base/load/trash.gif"></lable>
EOF
   }

   my $d=<<EOF;
<script>
function onChangeClear$name(e){
   s=document.getElementById('ClearEntry$name');
   f=document.getElementById('FileEntry$name');
   k=document.getElementById('KillEntry$name');
   if (s.checked){
      f.disabled=true;
      k.disabled=false;
   }
   else{
      f.disabled=false;
      k.disabled=true;
   }
}
</script>
<input id="FileEntry$name" type=file name=$name size="$size">
<input id="KillEntry$name" type=hidden name=$name disabled value="FORCECLEAR">
$delcode
EOF
   return($d);
}

sub Uploadable
{
   my $self=shift;

   return(0);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $resrec={};

   return($resrec) if (!exists($newrec->{$self->Name()}));
   if (exists($self->{maxsize})){
      if ($newrec->{$self->Name()} ne "" &&
          $newrec->{$self->Name()} ne "FORCECLEAR"){
         my $fname=sprintf("%s",$newrec->{$self->Name()});
         $fname=~s/^.*[\\\/]//; # strip path, if exists
         my ($name,$ext)=$fname=~m/^(.*)\.([a-z0-9]{1,4})$/i;
         $ext=lc($ext);
         if (length($name)>25){
            $name=substr($name,0,30);
         }
         $fname=$name.".".$ext;
         if (!in_array($self->{types},"*")){
            if (!in_array($self->{types},$ext)){
               my $t=$self->getParent->T(
                     'invalid file type - allowed are %s',
                     "kernel::Field::File"
               );
               $t=sprintf($t,join(", ",@{$self->{types}}));
               $self->getParent->LastMsg(ERROR,$t);
               return(undef);
            }
         }
         if (exists($self->{filename})){
            $resrec->{$self->{filename}}=$fname;
         }
         no strict;
         my $f=$newrec->{$self->Name()};
         seek($f,0,SEEK_SET);
         my $binstream;
         my $buffer;
         my $size=0;
         while (my $bytesread=read($f,$buffer,1024)) {
            $binstream.=$buffer;
            $size+=$bytesread;
            if ($size>$self->{maxsize}){  
               my $t=$self->getParent->T(
                     'document to large - max size %d bytes',
                     "kernel::Field::File"
               );
               $t=sprintf($t,$self->{maxsize});
               $self->getParent->LastMsg(ERROR,$t);
               return(undef);
            }
         }
         $resrec->{$self->Name()}=$binstream;
         if (exists($self->{uploaddate})){
            $resrec->{$self->{uploaddate}}=NowStamp("en");
         }
      }
      elsif($newrec->{$self->Name()} eq "FORCECLEAR"){
         $resrec->{$self->Name()}=undef;
         if (exists($self->{uploaddate})){
            $resrec->{$self->{uploaddate}}=undef;
         }
         if (exists($self->{filename})){
            $resrec->{$self->{filename}}=undef;
         }
      }
   }
   return($resrec);
}




sub ViewProcessor
{
   my $self=shift;
   my $mode=shift;
   my $refid=shift;
   if ($mode eq "Raw" && $refid ne ""){
      my $response={document=>{}};

      my $obj=$self->getParent();
      my $idfield=$obj->IdField();
      my $d="";
      if (defined($idfield)){
         $obj->ResetFilter();
         $obj->SecureSetFilter({$idfield->Name()=>\$refid});
         $obj->SetCurrentOrder("NONE");
         my ($rec,$msg)=$obj->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            if ($obj->Ping()){
               my @l=$obj->isViewValid($rec);
               if (in_array(\@l,"ALL") ||
                   in_array(\@l,$self->{group})){ 
                  my $fo=$obj->getField($self->Name(),$rec);
                  $d=$fo->RawValue($rec);
               }
               else{
                  msg(ERROR,"ileagal file attachment access $obj $refid");
               }
            }
         }
      }
      my $ext=".bin";
      if (my ($f1,$f2)=$self->{content}=~m/^(.*)\/(.*)$/){
         if ($f1 eq "image"){
            $ext=".$f2";
         }
         if ($f2 eq "pdf"){
            $ext=".pdf";
         }
      }
      my $filename=$self->{name}.$ext;

      print $self->getParent->HttpHeader($self->{content},
              filename=>$filename);
      print $d;
      return;
   }
   return;
}










1;
