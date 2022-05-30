package kernel::Output::JSON;
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
use kernel::Output::HtmlSubList;
@ISA    = qw(kernel::Formater);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub IsModuleSelectable
{
   eval("use JSON;");
   if ($@ ne ""){
      return(0);
   }
   return(1);
}
sub getRecordImageUrl
{
   return("../../../public/base/load/icon_json.gif");
}
sub Label
{
   return("Output to JSON");
}
sub Description
{
   return("Format as JSON Object list");
}

sub MimeType
{
   return("application/javascript");
}

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".js");
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   if ($self->{charset} ne "latin1"){
      $d.="Content-type:".$self->MimeType().";charset=UTF8\n\n";
   }
   else{
      $d.="Content-type:".$self->MimeType()."\n\n";
   }
   return($d);
}

sub Init
{
   my ($self,$fh)=@_;
   eval('use JSON;$self->{JSON}=new JSON;');
   $self->{JSON}->utf8(1);
   my $app=$self->getParent->getParent();
   return();
}


sub ProcessHiddenLine
{
   my ($self,$fh,$viewgroups,$rec,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();

   my $idname=$app->IdField();
   $idname=$idname->Name() if (defined($idname));

   if ($app->{_Limit}>1){ # if limit is set (blockwise output), show invisilbe
                          # records only with her id
      my $localrec={};
      if (exists($rec->{$idname})){
         $localrec->{$idname}=$rec->{$idname};
      }
      my $d;
      if (defined($self->{JSON})){
         if ($self->{charset} eq "latin1"){
            $self->{JSON}->property(latin1 => 1);
            $self->{JSON}->property(utf8 => 0);
         }
         $d=$self->{JSON}->encode($localrec);
      }
      $d=$self->FormatRecordStruct($d,$localrec,$idname);
      if ($lineno>0){
         $d="\n,".$d;
      }
      return($d);
   }
   return(undef);
}


sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my @view=$app->getFieldObjsByView([$app->getCurrentView()],current=>$rec);
   my $fieldbase={};
   map({$fieldbase->{$_->Name()}=$_} @view);

   my %rec=();
   my %xmlfields;
   foreach my $fo (@view){
      my $name=$fo->Name();
      my $v=$fo->UiVisible("JSON",current=>$rec);
      next if (!$v && ($fo->Type() ne "Interface"));
      if (!defined($self->{fieldkeys}->{$name})){
         push(@{$self->{fieldobjects}},$fo);
         $self->{fieldkeys}->{$name}=$#{$self->{fieldobjects}};
      }
    
      $xmlfields{$name}=$fo;
   }
   foreach my $name (sort(keys(%xmlfields))){
      my $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                   fieldbase=>$fieldbase,
                                   current=>$rec,
                                   mode=>'JSON',
                                  },$name,"formated");
      if (defined($data)){
         $rec{$name}=$data;
      }
      else{
         $rec{$name}=undef;
      }
   }
   my $idname=$app->IdField();
   $idname=$idname->Name() if (defined($idname));
   my $d;
   if (defined($self->{JSON})){
      if ($self->{charset} eq "latin1"){
         $self->{JSON}->property(latin1 => 1);
         $self->{JSON}->property(utf8 => 0);
      }
      #$d=$self->{JSON}->pretty->encode(\%rec);
      $d=$self->{JSON}->encode(\%rec);
   }
   $d=$self->FormatRecordStruct($d,$rec,$idname);
   # date hack, to get Date objects in JavaScript!
   if ($self->Self() eq "kernel::Output::nativeJSON"){
      $d=~s/"\\\\Date\((\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\)\\\\"
           /"$1-$2-$3T$4:$5:$6.000Z"/gx; # Dates should be stored in 
                                         # JavaScripts toJSON Format
   }
   else{
      $d=~s/"\\\\Date\((\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)\)\\\\"
           /new Date("$2\/$3\/$1 $4:$5:$6 UTC")/gx;
   }
   if ($lineno>0){
      $d="\n,".$d;
   }
   return($d);
}

sub FormatRecordStruct
{
   my $self=shift;
   my ($d,$rec,$idname)=@_;
   if (defined($idname)){
      my $k=$rec->{$idname};
      $d="'$k':$d";
   }
   return($d);
}

sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my ($objectname,$propname)=$self->JSON_ObjectName();
   my $d;
   my $app=$self->getParent->getParent();
   $d="};\n\n";
   $d.="window.document.W5Base['last']=window.document.$objectname.$propname;\n";
   return($d);
}

sub JSON_ObjectName
{
   my $self=shift;

   my $app=$self->getParent->getParent();
   my $appname="W5Base::".$app->Self;
   $appname=~s/::/\./g;
   my ($objectname,$propname)=$appname=~/^(.*)\.([^\.]+)$/;
   return($objectname,$propname);
}

sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $d;
   my ($objectname,$propname)=$self->JSON_ObjectName();
   
   my $d="";
   if (!$self->{no_JSON_init}){
      $d.=<<EOF;
//================================================
//
// NameSpace gernerator
//
function createNamespace(ns)
{
   ns="document."+ns;
   var splitNs = ns.split(".");
   var builtNs = splitNs[0];
   if (typeof(window)==undefined){
      window={};
   }
   var i, base = window;
   for (i = 0; i < splitNs.length; i++){
      if (typeof(base[splitNs[i]])=="undefined"){
         base[splitNs[i]] = {};
      }
      base=base[splitNs[i]];
   }
   return(base);
}
//================================================
EOF
   }
   $d.="createNamespace('$objectname')['$propname']=\n{\n";
   return($d);
}

sub getEmpty
{
   my $self=shift;
   my (%param)=@_;
   my $d="";
   if ($param{HttpHeader}){
      $d.=$self->getHttpHeader();
      $d.=$self->ProcessHead();
   }
   if ($param{HttpHeader}){
      $d.=$self->ProcessBottom();
   }
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
   my $JSONP=Query->Param("callback");
   $d.="$JSONP(" if ($JSONP ne "");

   my @msg;
   if ($param{msg}){
      push(@msg,$param{msg});
   }
   push(@msg,$self->getParent->getParent->LastMsg());
   if (defined($self->{JSON})){
      if ($self->{charset} eq "latin1"){
         $self->{JSON}->property(latin1 => 1);
         $self->{JSON}->property(utf8 => 0);
      }
      map({$_=~s/\s*$//} @msg);  #remove trailing linefeeds from msg list
      $d.=$self->{JSON}->encode({LastMsg=>\@msg});
   }
   else{
      msg(ERROR,"no JSON Object! - not good!");
   }
   $d.=");" if ($JSONP ne "");

   return($d);
}





1;
