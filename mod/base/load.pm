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
   my $skin=Query->Param("SKIN");
   my $content;
   my $filename;
   my %param=();

   if (!defined($ENV{HTTP_ACCEPT_LANGUAGE})){ # IE Hack while loading img's
      if (defined(Query->Param("HTTP_ACCEPT_LANGUAGE"))){
         $ENV{HTTP_ACCEPT_LANGUAGE}=Query->Param("HTTP_ACCEPT_LANGUAGE");
      }
   }
   if (defined(Query->Param("HTTP_FORCE_LANGUAGE"))){
      $ENV{HTTP_FORCE_LANGUAGE}=Query->Param("HTTP_FORCE_LANGUAGE");
   }
   #printf STDERR ("fifi load file: $func\n");

   if ($func=~m/^tmpl\//){
      my $title=Query->Param("TITLE");
      my $raw=Query->Param("RAW");
      if ($raw){
         $raw=1;
      }
      else{
         $raw=0;
      }
      my $static=Query->MultiVars();
      print $self->HttpHeader("text/html",%param);
      if (!$raw){
         print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                                 prefix=>"../",
                                 title=>$title,
                                 js=>['toolbox.js','jquery.js','jquery.ui.js'],
                                 body=>1,form=>1);
         print("<script language='JavaScript'>");
         my $focus=Query->Param("focus");
         if ($focus){
            print("window.focus();\n");
         }
         print("addEvent(document,'keydown',function(e){");
         print("e=e || window.event;");
         print("if (e.keyCode==27){");
         print("   if (window.parent && parent.hidePopWin){");
         print("      parent.hidePopWin(true,true);");
         print("      return(false);");
         print("   }");
         print("}");
         print("return(true);");
         print("});");
         print("</script>");
      }
      my $translation=$self->SkinBase();
      $translation.="::template.messages";
      my $d=$self->getParsedTemplate($func,{translation=>$translation,
                                            static=>$static});
      if (($ENV{HTTP_ACCEPT}=~m/charset=utf-{0,1}8/i) ||
          ($ENV{HTTP_ACCEPT_CHARSET}=~m/^UTF-8/i)){
         utf8::encode($d);
      }
      print $d;
      if (!$raw){
         print $self->HtmlBottom(body=>1,form=>1);
      }
      return(0);
   }
   elsif ($func=~m/^scriptpool\//){
      my ($script)=$func=~m/^scriptpool\/(.*)$/;
      my $instdirlist=$self->Config->Param("INSTDIR");
      $script=~s/[^a-z,0-9]//g;
      my $found=0;
      foreach my $instdir (split(/:/,$instdirlist)){
         if ( -f "$instdir/static/scriptpool/$script"){
            $found=1;
            print $self->HttpHeader("text/plain",filename=>$script);
            if (open(F,"<$instdir/static/scriptpool/$script")){
               my $prot=lc($ENV{SCRIPT_URI});
               $prot=~s/:.*$//;
               my $cfg=$self->Config->getCurrentConfigName();
               while(my $l=<F>){
                  $l=~s/%%%HOST%%%/$ENV{SERVER_NAME}/g;
                  $l=~s/%%%PROT%%%/$prot/g;
                  $l=~s/%%%CONFIG%%%/$cfg/g;
                  print $l;
               }
               close(F);
            }
            last;
         }
      }
      if  (!$found){
         printf("Status: 404 Not Found\n");
         printf("Content-Type: text/plain\n\n");
      }
      return(0);
   }
   else{
      if (my ($ext)=$func=~m/\.([a-z]{2,3})$/){
         my $virtualfile=$self->getSkinFile($self->Module."/virtual/".$func);
         if (-f $virtualfile){  # virtual file extension is primary to handle
            $filename=[];       # packing of multiple files in one js file
            if (open(VF,"<$virtualfile")){
               while(my $f=<VF>){ 
                  $f=trim($f);
                  if ($f ne ""){
                     $f.=";" if (!$f=~m/;$/);
                     eval("\$f=$f");
                     if ($@ eq ""){
                        push(@$filename,$f);
                     }
                  }
               }
               close(VF);
            }
         }
         if ($ext eq "jpg"){
            $content="image/jpg";
            $func=$self->Module."/img/".$func; 
            $param{cache}=3600;
            $param{inline}=1 if (Query->Param("inline"));
         }
         if ($ext eq "svg"){
            $content="image/svg+xml";
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
            if (!ref($filename)){
               $filename=$instdir."/lib/javascript/".$func; 
            }
            $param{cache}=3600;
         }
         if ($ext eq "map"){
            $content="text/javascript";
            if (!ref($filename)){
               $filename=$instdir."/lib/javascript/".$func; 
            }
            $param{cache}=3600;
         }
      }
      if (ref($filename) ne "ARRAY"){
         if ($content ne "text/javascript"){
            my %opt=();
            if ($skin ne ""){
               $skin=~s/[^a-zA-Z0-9_-]//g;
               $opt{addskin}=$skin;
            }
            $filename=$self->getSkinFile($func,%opt);
         }
         $filename=[$filename];
      }
      if ($content eq ""){
         $content="text/html";
      }
      print $self->HttpHeader($content,%param);
      foreach my $file (@$filename){
         if ($file ne ""){
            if (open(MYF,"<$file")){
               binmode MYF;
               binmode STDOUT;
               while(<MYF>){
                  print $_;
               }
               close(MYF);
            }
            else{
               msg(ERROR,"fail to open file '%s'",$file);
            }
         }
      }
   }
   return(0);
}


sub isAnonymousAccessValid
{
    my $self=shift;
    return(1);
}






1;
