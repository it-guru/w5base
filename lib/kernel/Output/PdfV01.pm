package kernel::Output::PdfV01;
#  W5Base Framework
#  Copyright (C) 2007  Holm Basedow (holm@blauwaerme.de)
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
use kernel::Output::JpgV01;
@ISA=qw(kernel::Output::JpgV01);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub getRecordImageUrl
{
   return("../../../public/base/load/icon_pdf.gif");
}
sub Label
{
   return("Output to PDF");
}
sub Description
{
   return("Writes the data in PDF Format.");
}

sub MimeType
{
   return("application/pdf");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".pdf");
}

sub IsModuleSelectable
{  
   my $self=shift;

printf STDERR ("fifi $self 00 $@\n");
   eval("use DTP::pdf;");
   if ($@ ne ""){
printf STDERR ("fifi $self 01 $@\n");
      return(0);
   }
   return(1);
}


sub Init
{
   my $self=shift;
   my ($fh)=@_;
   $|=1;
   binmode($$fh);
   my $dtp;
   eval('use DTP::pdf;$dtp=new DTP::pdf();');
   if ($@ eq ""){
      $self->{dtp}=$dtp;
   }
}

#sub Format
#{
#   printf STDERR ("fifi format \n\n\n");
#}
#
#sub ProcessLine
#{
#   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
#   my $app=$self->getParent->getParent();
#   my $view=$app->getCurrentViewName();
#   my @view=$app->getCurrentView();
#   my $fieldbase={};
#   my $editgroups=[$app->isWriteValid($rec)];
#   my $currentfieldgroup=Query->Param("CurrentFieldGroupToEdit");
#   my $currentid=Query->Param("CurrentIdToEdit");
#   my $spec=$self->getParent->getParent->LoadSpec($rec);
#   my $field=$app->IdField();
#   my $id=$field->RawValue($rec);
#   my $appname=$app->App();
#
#   foreach my $fo (@{$recordview}){
##      next if ($fo->Type() eq "Link");
##      next if ($fo->Type() eq "Interface");
##      next if ($fo->Type() eq "Container");
##      my $name=$fo->Name();
##      if (!defined($self->{xlscollindex}->{$name})){
##         $self->{xlscollindex}->{$name}=$self->{maxcollindex};
##         $self->{maxcollindex}++;
##      }
##
##      my $data="undef";
##
##      if ($fo->UiVisible("XlsV02",current=>$rec)){
##         if ($fo->can("getLineSubListData")){
##            $data=$fo->getLineSubListData($rec,"xls");
##         }
##         else{
##            $data=$app->findtemplvar({viewgroups=>$viewgroups,
##                                      fieldbase=>$fieldbase,
##                                      current=>$rec,
##                                      mode=>"DTP".lc($self->modeName()),
##                                     },$name,"formated");
##         }
##      }
##      else{
##         $data="-";
##      }
##      $cell[$self->{xlscollindex}->{$name}]=$data;
##      $cellobj[$self->{xlscollindex}->{$name}]=$fo;
##      foreach my $subline (split(/\n/,$data)){
##         if (length($subline)>$self->{'maxlen'}->[$self->{xlscollindex}->{$name}]){
##            $self->{'maxlen'}->[$self->{xlscollindex}->{$name}]=length($subline);
##         }
##      }
#   }
#
#
##   my $recordimg=$self->getParent->getParent->getRecordImageUrl($rec);
##   $recordimg=$ENV{SCRIPT_URI}."/../".$recordimg;
##   getstore($recordimg,"/tmp/tmp.img");
#   my $headerval="";
#   my $H="";
#   my $s=$self->getParent->getParent->T($self->getParent->getParent->Self,
#                                        $self->getParent->getParent->Self);
#
#   if (my $f=$self->getParent->getParent->getField("fullname")){
#      $headerval=quoteHtml($f->RawValue($rec));
#   }
#   elsif (my $f=$self->getParent->getParent->getField("name")){
#      $headerval=quoteHtml($f->RawValue($rec));
#   }
#   else{
#      $headerval='%objecttitle%';
#   }
#
#   $self->{dtp}->NewPage();
#   my $scale={a=>0.5,b=>0.5};
#  #$self->{dtp}->WriteLine(["Anwendung",$self->{dtp}->Image("auto","/tmp/tmp.img",30,30,"scale","0.6")],
#   $self->{dtp}->WriteLine($s.": ".$headerval,
#                           border        =>1,
#                           color         =>'white',
#                           background    =>'SteelBlue');
#   $self->{dtp}->TextOut(20,120,Dumper($editgroups));
##   $self->{dtp}->Image("auto","/tmp/tmp.img",30,100,scale=>'0.6');
##   my $self=shift;
#   printf STDERR ("fifi processline \n\n\n");
##   my $self=shift;
##   my $name=shift;
##   return($self->{format}->{$name}) if (exists($self->{format}->{$name}));
##
#}
##
##sub ProcessHead
##{
##   my ($self,$fh,$rec,$msg)=@_;
##   $self->{dtp}->NewPage(format=>'A4landscape');
#
##my $x=200;
##my $y=200;
##my $self->{font}=(font       => "Helvetica",
##                  color      => "magenta");
##   printf STDERR ("fifi processhead \n\n\n");
##   my @view=@{$self->{fieldobjects}};
##
##   $self->{'worksheet'}->set_column(0,0,40);
##   $self->{'worksheet'}->set_column(1,1,90);
##
##   return(undef);
##}
##

sub Finish
{
   my $self=shift;
   $self->{filename}="/tmp/tmp.$$.pdf";
   $self->{dtp}->GetDocument($self->{filename});
   if (open(F,"<$self->{filename}")){
      my $buf;
      while(sysread(F,$buf,8192)){
         print STDOUT $buf;
      }
      close(F);
  }
  else{
      printf STDERR ("ERROR: can't open $self->{filename}\n");
  }
   unlink($self->{filename});
   return();
}

1;
