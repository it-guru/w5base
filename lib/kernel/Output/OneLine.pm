package kernel::Output::OneLine;
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
use base::load;
use kernel::FormaterMultiOperation;
use Text::ParseWords;

@ISA    = qw(kernel::FormaterMultiOperation);



sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   my $self=shift;
   my %param=@_;
 
   return(1) if ($param{mode} eq "Init"); 
   my $app=$self->getParent()->getParent;
#   my @l=$app->getCurrentView();
#   if ($#l==0){
#      return(1);
#   }
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_asctab.gif");
}

sub FormaterOrderPrio
{
   return(300);  # unwichtig
}


sub Label
{
   return("Output to one line");
}
sub Description
{
   return("Writes in one ASCII line.");
}

sub MimeType
{
   return("text/html");
}

sub getEmpty
{
   my $self=shift;
   my %param=@_;
   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   return($d);
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".txt");
}

sub getHttpHeader
{  
   my $self=shift;
   my $d="";
   $d.="Content-type:".$self->MimeType().";charset=iso-8859-1\n\n";
   return($d);
}

sub quoteData
{
   my $d=shift;

   $d=~s/;/\\;/g;
   $d=~s/\r\n/\\n/g;
   $d=~s/\n/\\n/g;
   return($d); 
}

sub MultiOperationTableHeader
{
   my $self=shift;

   my $d=undef;

   return($d);
}

sub ProcessLine
{
   my $self=shift;
   my ($fh,$viewgroups,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my @view=$app->getCurrentView();
   

   if ($#view!=0){
      my @useField=Query->Param("useField");
      if ($#useField==-1){
         if ($#{$self->{recordlist}}>2){
            return(undef);
         }
      }
   }

   return($self->kernel::Formater::ProcessLine(@_));
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
 

   my @l=$app->getCurrentView();
   my @useField=Query->Param("useField");
   my $useOneLineAlg=Query->Param("useOneLineAlg");
   my $d=$self->SUPER::ProcessHead($fh,$rec,$msg);

   if ($#l!=0){
      $d.="<table class=freeform width=95% border=0>";
      $d.="<tr>";
      $d.="<td nowrap>";
      $d.="&nbsp;&nbsp;&nbsp;".
          "&nbsp;&nbsp;&nbsp;".
          "<select name=useField multiple size=5 style='width:95%'>";
      foreach my $fldname (@l){
         my $fld=$app->getField($fldname);
         if (defined($fld)){
            my $fldlabel=$fld->Label($rec);
            if ($fldlabel ne ""){
               $d.="<option value=\"$fldname\"";
               $d.=" selected" if (in_array(\@useField,$fldname));
               $d.=">";
               $d.=$fldlabel;
               $d.="</option>";
            }
         }
      }
      $d.="</select>";
      $d.="</td>";
      $d.="<td width=1% valign=bottom align=center>";
      $d.="<table>";
      $d.="<tr><td align=left>";
      my @useOneLineAlg=qw(unique caseIgnoreInverse caseCheckedInverse);
      $d.="<b>".$app->T("correlation algorithm",$self->Self).":</b><br>";
      $d.="<select name=useOneLineAlg>";
      foreach my $alg (@useOneLineAlg){
         my $useOneLineAlgChecked="";
         if ($useOneLineAlg eq $alg){
            $useOneLineAlgChecked=" selected ";
         }
         $d.="<option value=\"$alg\" $useOneLineAlgChecked>$alg</option>";
      }
      $d.="</select>";
      $d.="</td></tr><tr><td align=center>";

      $d.="<br><input type=submit value=\"".
          $self->getParent->getParent->T("show",'kernel::Output::OneLine').
          "\">";
      $d.="</td></tr></table>";
      $d.="</td>";
      $d.="</tr>";
      $d.="</table><div ".
          "style=\"font-family:monospace;margin:5px;".
          "padding:5px;height:100px;overflow:auto;".
          "border-top:1px solid black\">";
   }
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d;

   my %l=();
   my @view=$app->getCurrentView();
   my @useField=Query->Param("useField");
   my %search=$app->getSearchHash();
   if ($#view==0){
      @useField=@view;
   }

   my $useOneLineAlg=Query->Param("useOneLineAlg");
   if ($useOneLineAlg ne "unique" && $useOneLineAlg ne ""){
      if ($#useField>0){
         %l=(1=>msg(ERROR,$app->T("Inverse search only posible with one field",
                        $self->Self)));
      }
      my $f=$useField[0];
      if ($search{$f}=~m/^\s*$/){
         %l=(1=>msg(ERROR,$app->T("no filter on output field",$self->Self)));
      }
      if (!keys(%l)){
         my @words=parse_line('[,;]{0,1}\s+',0,$search{$f});
         if ($useOneLineAlg eq "caseIgnoreInverse"){
            map({$l{lc($_)}=$_} @words);
         }
         if ($useOneLineAlg eq "caseCheckedInverse"){
            map({$l{$_}=$_} @words);
         }
         for(my $recno=0;$recno<=$#{$self->{recordlist}};$recno++){
            for(my $fieldno=0;$fieldno<=$#{$self->{fieldobjects}};$fieldno++){
               my $fieldobj=$self->{fieldobjects}->[$fieldno];
               if (in_array(\@useField,$fieldobj->Name())){
                  my $dval=$self->{recordlist}->[$recno]->[$fieldno];
                  if ($useOneLineAlg eq "caseCheckedInverse"){
                     if (ref($dval) eq "ARRAY"){
                        map({delete($l{$_})} @$dval);
                     }
                     else{
                        delete($l{$dval});
                     }
                  }
                  if ($useOneLineAlg eq "caseIgnoreInverse"){
                     if (ref($dval) eq "ARRAY"){
                        map({delete($l{lc($_)})} @$dval);
                     }
                     else{
                        delete($l{lc($dval)});
                     }
                  }
               }
            }
         }
      }
   }
   else{
      for(my $recno=0;$recno<=$#{$self->{recordlist}};$recno++){
         for(my $fieldno=0;$fieldno<=$#{$self->{fieldobjects}};$fieldno++){
            my $fieldobj=$self->{fieldobjects}->[$fieldno];
            if (in_array(\@useField,$fieldobj->Name())){
               my $dval=$self->{recordlist}->[$recno]->[$fieldno];
               if (ref($dval) eq "ARRAY"){
                  map({$l{$_}=$_} @$dval);
               }
               else{
                  $l{$dval}=$dval;
               }
            }
         }
      }
   }
   my @l=grep(!/^\s*$/,sort(values(%l)));
   
   if (grep(/^\S+\@\S+\.\S+$/,@l)){   # output seems to be an email list
      $d.=join("; ",@l);
   }
   elsif (!grep(/\s/,@l)){
      $d.=join(" ",@l);
   }
   elsif (!grep(/,/,@l)){
      $d.=join(", ",@l);
   }
   elsif (!grep(/;/,@l)){
      $d.=join("; ",@l);
   }
   elsif (!grep(/\t/,@l)){
      $d.=join("\t",@l);
   }
   $d.="</div>";
   $d.=$app->HtmlBottom(form=>1,body=>1);
   return($d);
}

1;
