package kernel::TemplateParsing;
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
use XML::Smart;
use UNIVERSAL;
@ISA    = qw(UNIVERSAL);

sub ParseTemplateVars
{
   my $self=shift;
   my $mask=shift;
   my $opt=shift;

   $$mask=~s/\\\%/\@\@\@\%\@\@\@/g;
   $$mask=~s/\%INCLUDE\(([a-zA-Z\.0-9].+?)\)\%/&TemplInclude($self,$opt,$1)/ge;
   $$mask=~s/\%([a-zA-Z0-9\.\/\[\]]+?)\%/&ProcessVar($self,$opt,$1)/ge;
   $$mask=~s/\%([a-zA-Z][^\%]+?)\%/&ProcessVar($self,$opt,$1)/ge;
   $$mask=~s/\@\@\@\%\@\@\@/\%/g;
}

sub TemplInclude
{
   my $self=shift;
   my $opt=shift;
   my $name=shift;

   my $skinbase=$opt->{skinbase};
   my $mask=$self->getTemplate("tmpl/".$name,$skinbase);
   $mask=~s/\%INCLUDE\(([a-zA-Z\.0-9].+?)\)\%/&TemplInclude($self,$opt,$1)/ge;

   return($mask);
}

sub ProcessVar
{
   my $self=shift;
   my $opt=shift;
   my $code=shift;
   my $result=$code;

   if (my ($var,$param)=$code=~m/^(.+?)\((.*)\)$/){
      my @param=split(/,/,$param);
      $result=$self->findtemplvar($opt,$var,@param);
   }
   else{
      $result=$self->findtemplvar($opt,$code);
   }
   $result=~s/\%/\@\@\@\%\@\@\@/g;
   return($result);
}

sub findtemplvar
{
   my $self=shift;
   my $opt=$_[0];
   my $var=$_[1];

   my $chkobj=$self;
   if (defined($opt->{static}) && exists($opt->{static}->{$var})){
      return($opt->{static}->{$var});
   }
   if ($var eq "TRANSLATE" && defined($_[2])){
      my $tr=$_[3];
      if (!defined($tr) || $tr eq ""){
         $tr=$opt->{translation};
      }
      my $t=$self->T($_[2],$tr);
      $self->ParseTemplateVars(\$t,$opt);
      return($t);
   }
   elsif ($var eq "CONFIG" && defined($_[2])){
      my $v=$_[2];
      return(undef) if ($v=~m/^DATAOBJPASS/);
      if (my ($var,$k)=$v=~m/^(.+)\[(.+)\]$/){
         my $h=$self->Config->Param($var);
         return($h->{$k}) if (ref($h) eq "HASH");
         return(undef);
      }
      my $val=$self->Config->Param($v);
      return($val);
   }
   elsif ($var eq "LASTMSG"){
      my $d="<div class=lastmsg>";
      if ($self->LastMsg()){
         $d.=join("<br>\n",map({
                            if ($_=~m/^ERROR/){
                               $_="<font style=\"color:red;\">".$_.
                                  "</font>";
                            }
                            if ($_=~m/^OK/){
                               $_="<font style=\"color:darkgreen;\">".$_.
                                  "</font>";
                            }
                            $_;
                           } $self->LastMsg()));
      }
      else{
         $d.="&nbsp;";
      }
      $d.="</div>";
      return($d);
   }
   while($chkobj->can("getParent")){
      if (my $p=$chkobj->getParent()){
         if ($p->can("findtemplvar")){
            return($chkobj->getParent->findtemplvar(@_));
         }
         $chkobj=$p;
      }
      else{
         last;
      }
   }
   
   return(undef);
}



######################################################################
1;
