package base::load;
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
use kernel::App::Web;
use kernel::TemplateParsing;
@ISA=qw(kernel::App::Web kernel::TemplateParsing);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Run
{
   my $self=shift;
   my $func=Query->Param("FUNC");
   my $instdir=$self->Config->Param("INSTDIR");
   my $content;
   my $filename;
   my %param=();

   if (!defined($ENV{HTTP_ACCEPT_LANGUAGE})){ # IE Hack while loading img's
      if (defined(Query->Param("HTTP_ACCEPT_LANGUAGE"))){
         $ENV{HTTP_ACCEPT_LANGUAGE}=Query->Param("HTTP_ACCEPT_LANGUAGE");
      }
   }

   if ($func=~m/^tmpl\//){
      my $title=Query->Param("TITLE");
      my $static=Query->MultiVars();
      print $self->HttpHeader("text/html",%param);
      print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                              prefix=>"../",
                              title=>$title,
                              js=>['toolbox.js','jquery.js'],
                              body=>1,form=>1);
      my $translation=$self->SkinBase();
      $translation.="::template.messages";
      print $self->getParsedTemplate($func,{translation=>$translation,
                                            static=>$static});
      print $self->HtmlBottom(body=>1,form=>1);
   }
   else{
      if (my ($ext)=$func=~m/\.([a-z]{2,3})$/){
         if ($ext eq "jpg"){
            $content="image/jpg";
            $func=$self->Module."/img/".$func; 
            $param{cache}=3600;
            $param{inline}=1 if (Query->Param("inline"));
         }
         if ($ext eq "png"){
            $content="image/png";
            $func=$self->Module."/img/".$func; 
            $param{cache}=3600;
            $param{inline}=1 if (Query->Param("inline"));
         }
         if ($ext eq "gif"){
            $content="image/gif";
            $func=$self->Module."/img/".$func; 
            $param{cache}=3600;
            $param{inline}=1 if (Query->Param("inline"));
         }
         if ($ext eq "ico"){
            $content="image/x-icon";
            $func=$self->Module."/img/".$func; 
            $param{cache}=3600;
         }
         if ($ext eq "css"){
            $content="text/css";
            $func=$self->Module."/css/".$func; 
            $param{cache}=3600;
         }
         if ($ext eq "js"){
            $content="text/javascript";
            $filename=$instdir."/lib/javascript/".$func; 
            $param{cache}=3600;
         }
      }
      if ($content ne "text/javascript"){
         $filename=$self->getSkinFile($func);
      }
      #msg(INFO,"base::load request=$func result filename=$filename");
     
      print $self->HttpHeader($content,%param);
      if (open(MYF,"<$filename")){
         binmode MYF;
         binmode STDOUT;
         while(<MYF>){
            print $_;
         }
         close(MYF);
      }
   }
   return(0);
}




1;
