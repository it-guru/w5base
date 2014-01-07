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
   if (!defined($self->{content})){
      $self->{content}="application/octet-stream";
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
            return("&lt; <a class=filelink target=_blank ".
                   "href=\"$url\">FileEntry</a> &gt;");
         }
      }
      else{
         return("&lt; noFile &gt;");
      }
   }
   if (($mode eq "edit" || $mode eq "workflow") && !defined($self->{vjointo})){
      return("<input type=file name=$name size=45>");
   }
   if ($d ne ""){
      return($url);
   }
   return("<noFile>");
}

sub Uploadable
{
   my $self=shift;

   return(0);
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
               my $fo=$obj->getField($self->Name(),$rec);
               $d=$fo->RawValue($rec);
            }
         }
      }
      my $ext=".bin";
      if (my ($f1,$f2)=$self->{content}=~m/^(.*)\/(.*)$/){
         if ($f1 eq "image"){
            $ext=".$f2";
         }
      }
      print $self->getParent->HttpHeader($self->{content},
              filename=>$self->{name}.$ext);
      print $d;
      return;
   }
   return;
}










1;
