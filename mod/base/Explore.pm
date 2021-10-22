package base::Explore;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::App::Web;
use JSON;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->LoadSubObjsOnDemand("Explore","Explore");
   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main Start jsApplets jsLib));
}


#
# Explore Engine
#

sub Main
{
   my ($self)=@_;

   print $self->HttpHeader("text/html",charset=>'UTF-8');

   my $EventJobBaseUrl=$self->Config->Param("EventJobBaseUrl");
   if (!($EventJobBaseUrl=~m/\/$/)){
      $EventJobBaseUrl.="/";
   }
   $EventJobBaseUrl=~s#^http[s]?://[^/]+/#/#;

   my $getAppTitleBar=$self->getAppTitleBar();
   my $BASE=$ENV{REQUEST_URI};
   $BASE=~s#\?.*$##;
   $BASE=~s#^.*/(auth|public)/base/Explore/Main[/]{0,1}##;
   $BASE=~s#[^/]+#..#g;
   if ($BASE eq ""){
      $BASE="./";
   }

   my $opt={
      static=>{
         EventJobBaseUrl=>$EventJobBaseUrl,
         BASE=>$BASE
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.Explore.js",$opt);
   utf8::encode($prog);
   print($prog);
}

sub Start
{
   my ($self)=@_;

   print $self->HttpHeader("text/html",charset=>'UTF-8');

   my $EventJobBaseUrl=$self->Config->Param("EventJobBaseUrl");
   if (!($EventJobBaseUrl=~m/\/$/)){
      $EventJobBaseUrl.="/";
   }
   $EventJobBaseUrl=~s#^http[s]?://[^/]+/#/#;

   my $getAppTitleBar=$self->getAppTitleBar();
   my $BASE=$ENV{REQUEST_URI};
   $BASE=~s#\?.*$##;
   $BASE=~s#^.*/(auth|public)/base/Explore/Start[/]{0,1}##;
   $BASE=~s#[^/]+#..#g;
   if ($BASE eq ""){
      $BASE="./";
   }

   my $opt={
      static=>{
         BASE=>$BASE
      }
   };

   my $prog=$self->getParsedTemplate("tmpl/base.Explore.js",$opt);
   utf8::encode($prog);
   print($prog);
}

sub jsLib  #  base/ kernel.Explore.network
{
   my $self=shift;
   my $lang=$self->Lang();

   print $self->HttpHeader("text/javascript");

   my $appletcall;
   if (defined(Query->Param("FunctionPath"))){
      $appletcall=Query->Param("FunctionPath");
   }
   my @p=split(/\//,$appletcall);

   printf("(function(window, document, undefined){\n");
   if ($p[1] eq "base"){
      my $opt={
         static=>{
            BASE=>$p[1]
         }
      };
      my $prog=$self->getParsedTemplate("tmpl/$p[2]",$opt);
      utf8::encode($prog);
      print($prog);
   }
   printf("})(this,document);\n\n");
}

sub jsApplets
{
   my $self=shift;
   my $lang=$self->Lang();

   print $self->HttpHeader("text/javascript");

   my $appletcall;
   if (defined(Query->Param("FunctionPath"))){
      $appletcall=Query->Param("FunctionPath");
   }
   $appletcall=~s/^\///;
   $appletcall=~s/\//::/g;
   $appletcall=~s/\..*$//;

   printf("(function(window, document, undefined){\n");
   if ($appletcall ne ""){
      if (exists($self->{Explore}->{$appletcall})){
         print($self->{Explore}->{$appletcall}->getJSObjectClass($self,$lang));
      }
   }
   else{
      my $jsengine=new JSON();
      foreach my $sobj (values(%{$self->{Explore}})){
         my $d;
         if ($sobj->isAppletVisible($self)){
            if ($sobj->can("getObjectInfo")){
               $d=$sobj->getObjectInfo($self,$lang);
            }
            if (defined($d)){
               my $selfname=$sobj->Self();
               my $jsdata=$jsengine->encode($d);
               utf8::encode($jsdata);
               printf("ClassAppletLib['%s']={desc:%s};\n",$selfname,$jsdata);
            }
         }
      }
   }
   printf("})(this,document);\n\n");
}


1;
