package kernel::Output::XlsV03;
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
use Text::ParseWords;
use kernel::Output::XlsV01;
@ISA    = qw(kernel::Output::XlsV01);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}



sub FormaterOrderPrio
{
   return(10000);  # unwichtig
}



sub getRecordImageUrl
{
   return("../../../public/base/load/icon_xlso.gif");
}
sub Label
{
   return("Outer XLS Report");
}
sub Description
{
   return("Writes the data in Excel/XLS Format with first column as outer criteria.");
}

sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;

   return($self->SUPER::IsModuleSelectable(%param)) if ($param{mode} eq "Init");
   my $app=$self->getParent()->getParent;
   my @l=$app->getCurrentView();

   if (exists($param{currentFrontendFilter}) &&
       ref($param{currentFrontendFilter}) eq "HASH"){
      my $col1name=$l[0];
      if (exists($param{currentFrontendFilter}->{$col1name}) &&
          $param{currentFrontendFilter}->{$col1name} ne ""){
         my @words;
         if (ref($param{currentFrontendFilter}->{$col1name}) eq "ARRAY"){
            @words=@{$param{currentFrontendFilter}->{$col1name}};
         }
         else{
            @words=parse_line('[,;]{0,1}\s+',0,
                              $param{currentFrontendFilter}->{$col1name});
         }
         #msg(INFO,"XlsV03: col1name='%s'",$col1name);
         #msg(INFO,"XlsV03: flt=%s",Dumper(\@words));
         return(1);
      }
   }

   return(0);
}

sub getDownloadFilename
{
   my $self=shift;

   return("outerchecked.".$self->SUPER::getDownloadFilename());
}


sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getDataObj();

   if (!exists($self->{'tagsProcess'})){
      my @l=$app->getCurrentView();
      my $col1name=$l[0];
      my @words;
      my $wildchards=0;
      if (ref($self->{currentFrontendFilter}->{$col1name}) eq "ARRAY"){
         @words=@{$self->{currentFrontendFilter}->{$col1name}};
      }
      else{
         @words=parse_line('[,;]{0,1}\s+',0,
                           $self->{currentFrontendFilter}->{$col1name});
         $wildchards=1;
      }
      $self->{'tagsProcess'}={col1name=>$col1name,p=>{},
                              wildchards=>$wildchards};
      foreach my $w (@words){
         $self->{'tagsProcess'}->{'p'}->{$w}=0;
      }
   }
   my $fobj;
   foreach my $fo (@{$recordview}){
      $fobj=$fo if ($fo->Name() eq $self->{'tagsProcess'}->{'col1name'});
   }
   if (!defined($self->{'tagsProcess'}->{'col1obj'})){
      $self->{'tagsProcess'}->{'col1obj'}=$fobj;
   }
   if (defined($fobj)){
      my $raw=$fobj->RawValue($rec);
      foreach my $k (keys(%{$self->{'tagsProcess'}->{'p'}})){
         my $match=0;
         if ($k ne "" && lc($raw) eq lc($k)){
            $match++;
         }
         if ($self->{'tagsProcess'}->{'wildchards'}){
            my $chk=quotemeta($k);
            $chk=~s/\\\*/.*/g;
            $chk=~s/\\\?/+/g;
            if ($chk ne "" && $raw=~m/^$chk$/i){
               $match++;
            }
         }
         if ($match){
            $self->{'tagsProcess'}->{'p'}->{$k}++;
         }
      }
   }
   #msg(INFO,"d=%s",Dumper($self->{'tagsProcess'}));

   return($self->SUPER::ProcessLine($fh,
          $viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg));
}


sub ProcessHead
{
   my ($self,$fh,$rec,$msg,$param)=@_;
   foreach my $k (sort(keys(%{$self->{'tagsProcess'}->{'p'}}))){
      if ($self->{'tagsProcess'}->{'p'}->{$k}==0){
         $self->getParent->getParent->Context->{Linenumber}++;
         my $lineno=$self->getParent->getParent->Context->{Linenumber};
         #msg(INFO,"last line=%d",$lineno);
         #msg(INFO,"miss '%s'",$k);
         my $data=$k;
         my $field=$self->{'tagsProcess'}->{'col1obj'};
         my $format="default";
         if (defined($field)){
            $format=$field->getXLSformatname($data);
         }
         if (!defined($data)){
            $data="";
         }
         if ($format=~m/^date\./){
            $self->{'worksheet'}->write_date_time($lineno+1,0,$data,
                                                  $self->Format($format));
         }
         else{
            $data="'".$data if ($data=~m/^=/);
            $self->{'worksheet'}->write($lineno,0,$data,
                                        $self->Format($format));
         }
      }
   }
   delete($self->{'tagsProcess'});


#   my @view;
#   if (ref($self->{fieldobjects}) eq "ARRAY"){
#      @view=@{$self->{fieldobjects}};
#   }
#
#   for(my $cellno=0;$cellno<=$#view;$cellno++){
#      #next if (!($view[$cellno]->UiVisible()));   # ist nicht mehr notwendig
#      next if ($view[$cellno]->Type() eq "Interface");
#      next if ($view[$cellno]->Type() eq "Container");
#      my $xlscellno=$self->{xlscollindex}->{$view[$cellno]->Name()};
#      my $label=$view[$cellno]->Label();
#      my $format="header";
#      { # color handling
#         my $xlscolor=$view[$cellno]->xlscolor;
#         my $xlsbgcolor=$view[$cellno]->xlsbgcolor;
#         my $xlsbcolor=$view[$cellno]->xlsbcolor;
#         my $colset=0;
#         if (defined($xlscolor)){
#            $format.=".color=\"".$xlscolor."\"";
#         }
#         if (defined($xlsbgcolor)){
#            $format.=".bgcolor=\"".$xlsbgcolor."\"";
#            $colset++;
#         }
#         if ($colset || defined($xlsbcolor)){
#            if (!defined($xlsbcolor)){
#               $xlsbcolor="#000000";
#            }
#            $format.=".bcolor=\"".$xlsbcolor."\"";
#         }
#      }
#
#      if (length($label)>$self->{'maxlen'}->[$cellno]){
#         $self->{'maxlen'}->[$xlscellno]=length($label);
#      }
#      $self->{'worksheet'}->write(0,$xlscellno,$label,
#                                  $self->Format($format));
#      { # column width calculation
#         my $xlswidth;
#         if (defined($view[$cellno]->htmlwidth())){
#            $xlswidth=$view[$cellno]->htmlwidth()*0.3;
#         }
#         if (defined($view[$cellno]->xlswidth())){
#            $xlswidth=$view[$cellno]->xlswidth();
#         }
#         if (!defined($xlswidth)){
#            $xlswidth=$self->{'maxlen'}->[$xlscellno]*1.2;
#         }
#         $xlswidth=15 if (defined($xlswidth) && $xlswidth<15);
#         $xlswidth=100 if ($xlswidth>100);
#         if (defined($xlswidth)){
#            $self->{'worksheet'}->set_column($xlscellno,$xlscellno,$xlswidth);
#         }
#      }
#   }

   return($self->SUPER::ProcessHead($fh,$rec,$msg,$param));
}





1;
