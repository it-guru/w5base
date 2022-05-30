package kernel::Formater;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::Operator;
use kernel::Universal;
use Data::Dumper;

@ISA=qw(kernel::Operator kernel::Universal);

sub new
{
   my $type=shift;
   my $parent=shift;
   my $self=bless({@_},$type);

   $self->setParent($parent);
   return($self);
}

sub IsModuleDownloadable
{
   return(1);
}


sub IsDirectLink
{
   return(1);
}


sub FormaterOrderPrio
{
   return(1000);
}


sub modeName
{
   my $self=shift;
   my ($mode)=$self=~m/^.*::(.+?)=.*$/;
   return($mode);
}

sub prepareParent    # inital parent to set f.e. the view
{
   my ($self)=@_;
   return(undef);
}

sub Init
{
   my ($self,$fh)=@_;
   $self->{recordlist}=[];
   return(undef);
}

sub Validate
{
   my ($self,$fh)=@_;
   return(1);
}


sub Config
{
   my ($self)=@_;

   return($self->getParent->getParent->Config);
}

sub setDataObj
{
   my $self=shift;
   my $o=shift;
   $self->{DataObj}=$o;
   return($o);
}

sub getDataObj
{
   my $self=shift;
   return($self->{DataObj}) if (defined($self->{DataObj}));
   return($self->getParent->getParent()); #default handler
}

sub forceDownloadAsAttachment
{
   my $self=shift;

   return(0);
}

sub DownloadHeader
{
   my $self=shift;
   my $d="";
   $d.="Content-Name: ".$self->getDownloadFilename()."\n";

   my $download=1;
   if (ref($self->getParent())){
      $download=$self->getParent->{download};
   }
   if ($download || $self->forceDownloadAsAttachment()){
      $d.="Content-Disposition: attachment; filename=".
          $self->getDownloadFilename()."\n";
   }
   else{
      $d.="Content-Disposition: inline; filename=".
          $self->getDownloadFilename()."\n";
   }
   return($d);
}

sub getDownloadFilename
{
   my $self=shift;
   my $file="report";
   if (ref($self->getParent()) eq "kernel::XLSReport" &&
       $self->getParent()->can("getDownloadFilename")){
      my $f=$self->getParent()->getDownloadFilename();
      $file=$f if ($f ne "");
   }
   else{
      if (ref($self->getParent()) && ref($self->getParent->getParent())){
         $file=lc($self->getParent->getParent()->Self());
      }
   }
   $file=~s/::/_/g;

   return($file);
}

sub isRecordHandler
{
   return(1);
}



#######################################################################
sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   return(undef);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $d;
   my @cell=();
   foreach my $fo (@{$recordview}){
      my $name=$fo->Name();
      my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   fieldbase=>$fieldbase,
                                   current=>$rec,
                                   mode=>$self->modeName(),
                                  },$name,"formated");
      $cell[$self->{fieldkeys}->{$name}]=$data;
   }
   push(@{$self->{recordlist}},\@cell);
   return(undef);
}
sub ProcessHiddenLine
{
   my ($self,$fh,$viewgroups,$rec,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   #push(@{$self->{recordlist}},[]);
   return(undef);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   return(undef);
}
sub WriteToStdout
{
   my $self=shift;
   my %param=@_;
}
sub WriteToScalar
{
   my $self=shift;
   my %param=@_;
}
sub getHttpHeader
{
   my $self=shift;
   return("Content-type:text/plain\n\n");
}

sub Finish
{
   my ($self,$fh)=@_;

   return();
}

sub getNoAccess
{
   my $self=shift;
   my (%param)=@_;
   my $d="";

   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   $d.="no Access";
   return($d);
}

sub getErrorDocument
{
   my $self=shift;
   my (%param)=@_;
   my $d="";

   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
   }
   $d.=join("\n",map({rmNonLatin1($_)} $self->getParent->getParent->LastMsg()));
   return($d);
}


sub getEmpty
{
   my $self=shift;
   my (%param)=@_;
   my $d="";

   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
      $d.=$self->getParent->getParent->HtmlHeader(
                           style=>['default.css','work.css'],
                           body=>1,form=>1,
                           title=>'Not found');
   }
   $d.=$self->getParent->getParent->getParsedTemplate(
             "tmpl/kernel.notfound",{skinbase=>'base'});
   if ($param{HttpHeader}){
      $d.=$self->getParent->getParent->HtmlBottom(body=>1,form=>1);
   }
   return($d);
}



sub getHttpFooter
{
   my $self=shift;
   return("");
}

#######################################################################


sub getHtmlViewLine
{
   my ($self,$fh,$dest)=@_;
   my $d="";
   my @userviewlist=sort($self->getParent->getParent->getUserviewList());
   my $app=$self->getParent->getParent;
   my $curview=$app->getCurrentViewName();
   my $allowfurther=$app->allowFurtherOutput();
   my $maxdirect=20;


   $d.="<tr><td height=1% class=mainblock>\n";
   $d.="<table class=viewlist><tr>\n";
   my $ro=0;
   if ($self->Config->Param("W5BaseOperationMode") eq "readonly"){
      $ro=1;
   }
   my $userid=$app->getCurrentUserId();
   $ro=1 if ($userid<=0);   # anonymous access no view editor allowed
   if (defined($curview)){
      my $overflowselektor;
      my $overflowseleked;
      if ($#userviewlist>$maxdirect-1){
         $overflowselektor="<script type=\"text/javascript\" ".
                           "language=\"JavaScript\">";
         $overflowselektor.="function onOverflowSelect(o){";
         $overflowselektor.=" var v=o.options[o.selectedIndex].value;";
         $overflowselektor.=" ChangeView(v,\"$dest\");";
         $overflowselektor.="}";
         $overflowselektor.="</script>";
         $overflowselektor.="<select onchange=\"onOverflowSelect(this);\" ".
                            "style=\"padding:0px;margin:0px;font-size:10px\">";
         for(my $c=$maxdirect-1;$c<=$#userviewlist;$c++){
            my $view=$userviewlist[$c];
            $overflowselektor.="<option ";
            if ($view eq $curview){
               $overflowselektor.="selected ";
               $overflowseleked=$view;
            }
            $overflowselektor.="value=\"$view\">$view</option>";
         }
         $overflowselektor.="</select>";
      }
      for(my $c=0;$c<=$#userviewlist;$c++){
         next if ($c>$maxdirect-1);
         my $view=$userviewlist[$c];
         my $cClickTarget=$view;
         if ($overflowseleked){
            $cClickTarget=$overflowseleked;
         }
         my $state="inactive";
         $state="active" if ($view eq $curview ||
                             ($c==$maxdirect-1 &&
                              $#userviewlist>$maxdirect-1 && 
                              $overflowseleked));
         $d.="<td class=viewtab_spacer>&nbsp;</td>\n";
         my $w="";
         $w="style=\"width:155px\"" if ($c==$maxdirect-1 && 
                                        $#userviewlist>$maxdirect-1);
         $d.="<td class=viewtab_$state nowrap>".
             "<div class=viewtab_$state $w>".
             "<table border=0 width=100% cellpadding=0 cellspacing=0><tr>".
             "<td align=left>";
         if (!($view=~m/^\*/) && !$ro){
            $d.="<a class=viewtabedit title=\"".
                $self->getParent->getParent->T(
                "modify view or create new views").
                "\" href=JavaScript:EditView(\"$cClickTarget\")>".
                "<img border=0 src=\"../../base/load/edit_mini.gif\"></a>";
         }
         else{
            $d.="<img border=0 src=\"../../base/load/empty.gif\" ".
                "width=18 height=18>";
         }
         my $selektor="<a class=viewselect ".
             "href=JavaScript:ChangeView(\"$view\",\"$dest\")>$view</a>";
         if ($c==$maxdirect-1 &&
             $#userviewlist>$maxdirect-1){
            $selektor=$overflowselektor;
         }
         $d.="</td><td align=center>".$selektor."</td>";
         if ($allowfurther){
            $d.="<td align=right>".
                "<a class=viewtaboutput title=\"".
                $self->getParent->getParent->T("use further functions or ".
                                               "select output format").
                "\" href=JavaScript:FormatSelect(\"$cClickTarget\",\"$dest\")>".
                "<img border=0 src=\"../../base/load/functions.gif\"></a>".
                "</td>";
         }
         else{
            $d.="<td align=right>".
                "<img border=0 src=\"../../base/load/empty.gif\" ".
                "width=18 height=18></td>";
         }
         $d.="</tr></table>".
             "</div>".
             "</td>\n";
      }
   }
   $d.="<td class=viewtab_spacer_right>&nbsp;</td>\n";
   $d.="</tr></table>\n";
   $d.="</td></tr>";
   return($d);
}

sub HtmlStoreQuery
{
   my $self=shift;
   my $d="";

   my $idobj=$self->getParent->getParent->IdField;
   my $idname=undef;
   if (defined($idobj)){
      $idname=$idobj->Name();
   }
   foreach my $var (Query->Param()){
      next if ($var ne "CurrentView" &&
               (defined($idname) && $var ne $idname) &&
               $var ne "FormatAs" &&
               !($var=~m/^MyW5Base/) &&
               $var ne "NoViewEdit" &&
               !($var=~m/^search_.*$/));
      my @val=Query->Param($var);
      next if ($#val==-1 || ($#val==0 && $val[0] eq ""));
      foreach my $val (@val){
         $val=~s/"/&quot;/g;
         my $id="";
         $id=" id=$var" if ($var eq "CurrentView" || $var eq "FormatAs");
         $d.="<input type=hidden name=$var$id value=\"$val\">\n";
      }
   }

   return($d);
}



1;

