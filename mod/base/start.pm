package base::start;
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


sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(Main login));
}



sub login
{
   my $self=shift;

   my $posturi=Query->Param("POSTURI");
   if ($posturi ne ""){
      $self->HtmlGoto($posturi);
   }
   else{
      print $self->HttpHeader("text/html");
      printf("Hä?");
   }
}



sub Main
{
   my $self=shift;

   my $tmpl="tmpl/login";
   $tmpl="tmpl/login.successfuly" if ($self->IsMemberOf("valid_user"));
   my $title=Query->Param("TITLE");

   if (Query->Param("oidc_callback") ne ""){
      my $callback=Query->Param("oidc_callback");
      my $target_link_uri=Query->Param("target_link_uri");
      my $iss;

      if ($target_link_uri=~m/_FORCE_OIDC_ISS_/){
         my ($forceISS)=$target_link_uri=~m/_FORCE_OIDC_ISS_=([^&;]+)/;
         if ($forceISS ne ""){
            $iss=$forceISS;
            $target_link_uri=~s/_FORCE_OIDC_ISS_=[^&;]+//;
            $target_link_uri=~s/\?$//; # remove ? if query string is empty
         }
      }


      Query->Delete("oidc_iss");
      Query->Delete("oidc_callback");
      Query->Delete("MOD");
      Query->Delete("FUNC");
      if ($iss ne ""){
         Query->Param("iss"=>$iss);
      }

      if ($iss eq ""){
         $iss=Query->Cookie("openidc_iss");
         $iss=~s/^"+//;
         $iss=~s/"+$//;
         if ($iss ne ""){
            Query->Param("iss"=>$iss);
         }

      }
      if ($iss eq ""){
         if ($ENV{REMOTE_USER} ne "" &&
             ($ENV{REMOTE_USER}=~m/[a-z]{3,10}/i)){  
            # try to find iss over remote_user
            my $logintoken=$ENV{REMOTE_USER};
            my $loginhandler=$self->Config->Param("LOGINHANDLER");
            foreach my $k (keys(%$loginhandler)){
               my $lh=$loginhandler->{$k};
               $lh=~s/^.*\?//;
               if ($k=~m/$logintoken/i){
                  $iss=$lh;
                  Query->Param("iss"=>$iss);
               }
            }
         }
      }
      if ($target_link_uri=~m/\?$iss$/){
         $target_link_uri=~s/\?.*$//;
      }

      Query->Param("target_link_uri"=>$target_link_uri);

      if ($iss eq ""){
         print $self->HttpHeader("text/html");
         my $loginopenidc=$self->Config->Param("LOGINOPENIDC");
         my @OIDCMetadataDir;
         foreach my $k (keys(%$loginopenidc)){
            my $providerfile=$loginopenidc->{$k};
            if (-r $providerfile){
               push(@OIDCMetadataDir,$providerfile);
            }
         }
         printf ("<a href=\"../menu/root\">Back</a><br>");
         printf ("OpenID Browser not yet implemenated<br>");
         printf ("found OIDCMetadataDir=%s<br>\n",join(";",@OIDCMetadataDir));
         return(0);
      }
      my @cookies=("openidc_iss=$iss; SameSite=None; Secure; Path=/");
      $self->HtmlGoto($callback,get=>{Query->MultiVars()},cookies=>\@cookies);

      return(0);
   }

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'mainwork.css',
                                   'base.start.css'],
                           title=>$title,
                           onload=>'onLoad();',
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   print "<script language=\"JavaScript\" ".
         "src=\"../../base/load/toolbox.js\"></script>";
   print <<EOF;
<script language="JavaScript">

function onLoad(){
   var focusable=document.querySelectorAll(
     'button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
   );
   if (focusable && focusable[0]){
      focusable[0].focus();
   }
}

   function onFocus(e){
      var div=document.querySelectorAll('.hideHelp');
      for(var c=0;c<div.length;c++){
         div[c].classList.remove("HelpFrameVisible");
      }

      var id=e.id;
      var helpid=id+"Help";
      var e=document.getElementById(helpid);
      if (e){
         e.classList.add("HelpFrameVisible");
      }
   }
   function onMouseOver(e){
      var id=e.id;
      var helpid=id+"Help";
      var e=document.getElementById(helpid);
      if (e){
         e.classList.add("HelpFrameVisible");
      }
   }
   function onMouseOut(e){
      var id=e.id;
      var helpid=id+"Help";
      var e=document.getElementById(helpid);
      if (e){
         e.classList.remove("HelpFrameVisible");
      }
   }
</script>
EOF
   print $self->getParsedTemplate($tmpl,{});
   print $self->HtmlBottom(body=>1,form=>1);
   return(0);
}

sub findtemplvar
{
   my $self=shift;
   my $opt=$_[0];
   my $var=$_[1];

   my $chkobj=$self;
   if ($var eq "LOGINHANDLER"){
      my $d="There is no LoginHandler configured.";
      my $loginname=$self->Config->Param("LOGINNAME");
      my $loginicon=$self->Config->Param("LOGINICON");
      my $loginhandler=$self->Config->Param("LOGINHANDLER");
      my $loginhelp=$self->Config->Param("LOGINHELP");
      my $loginopenidc=$self->Config->Param("LOGINOPENIDC");
      my $current_openidc_iss=Query->Cookie("openidc_iss");
      $current_openidc_iss=~s/^"+//; 
      $current_openidc_iss=~s/"+$//; 

      if (ref($loginname) eq "HASH"){
         $d="";
         $d.="<div id=\"LOGINTOP\">";
         $d.="<div id=\"LOGINHANDLER\" class=\"LoginHandlerMainFrame\">\n";
         my $n=0;
         foreach my $k (sort(keys(%$loginname))){
            my $openidcproviderfile=$loginopenidc->{$k};
            my $name=$loginname->{$k};
            my $handler=$loginhandler->{$k};
            my $iconpath=$loginicon->{$k};
            if ($current_openidc_iss ne ""){
               if ("?".$current_openidc_iss ne 
                   substr($handler, -1*(length($current_openidc_iss)+1))) {
                  next;
               }

            }
            my $opt="<div id=\"loginframe$k\" class=\"LoginFrame\">";
            if ($n==0){
               $opt.="<button type=\"submit\" ".
                     "aria-labelledby=\"StdHiddenLoginHelp\" ".
                     "class=\"StdHiddenLoginButton\">";
            }
            $opt.="<button type=\"submit\" class=LoginButton ".
                  "id=\"Login${k}Button\" value=\"$k\" ".
                  "onfocus=\"onFocus(this);\" ".
                  "onmouseover=\"onMouseOver(this);\" ".
                  "onmouseout=\"onMouseOut(this);\" ".
                  "aria-labelledby=\"Login${k}ButtonHelp\" ".
                  "onclick=\"parent.parent.parent.document.location.href=".
                  "'$handler';return(false);\">\n";

            $opt.="<img style=\"vertical-align: middle;cursor:pointer;\" ".
                  "src=\"$iconpath\">\n";
            $opt.="<label style=\"vertical-align:middle;cursor:pointer;".
                  "white-space:nowrap;padding-right:20px\">\n";
            $opt.="$name\n";
            $opt.="</label>\n";
            $opt.="</button>\n";
            $opt.="</div>\n";
            $d.=$opt;
            $n++;
         }
         my $templtext=$self->getTemplate("tmpl/LoginNotice","base");
         if ($templtext ne ""){
            $d.=$templtext;
         }
         $d.="</div>";
         $d.="<div id=LOGINHELP ".
            "class=\"LoginHelpMainFrame\">";
         if (ref($loginhelp) eq "HASH" && exists($loginhelp->{"BASE"})){
            my $k="BASE";
            my @l=$loginhelp->{$k}=~m#^(([^/]+)/)?(.*)$#;
            my (undef,$skin,$templ)=$loginhelp->{$k}=~m#^(([^/]+)/)?(.*)$#;
            $skin="default" if ($skin eq "");
            my $lang=$self->Lang();
            if ($lang ne "en"){
               $skin.=".".$lang;
            }
            my $templtext=$self->getTemplate("tmpl/".$templ,"base",$skin);
            if ($templtext ne ""){
               $d.="\n\n<div id=\"StdHiddenLoginHelp\" ".
                   "class=\"baseHelp\">".$templtext."</div>";
            }
         }
         foreach my $k (sort(keys(%$loginname))){
            if (ref($loginhelp) eq "HASH" && exists($loginhelp->{$k})){
               my @l=$loginhelp->{$k}=~m#^(([^/]+)/)?(.*)$#;
               my (undef,$skin,$templ)=$loginhelp->{$k}=~m#^(([^/]+)/)?(.*)$#;
               $skin="default" if ($skin eq "");
               my $lang=$self->Lang();
               if ($lang ne "en"){
                  $skin.=".".$lang;
               }
               my $templtext=$self->getTemplate("tmpl/".$templ,"base",$skin);
               if ($templtext ne ""){
                  $d.="\n\n<div  ".
                      "id=\"Login${k}ButtonHelp\" ".
                      "aria-hidden=\"true\" ".
                      "class=\"hideHelp\">".
                      $templtext.
                      "</div>";
               }
            }
         }
         $d.="</div>";
         $d.="</div>";
      }

      return($d);
   }
   if ($var eq "FORUMCHECK" && defined($_[2]) && $ENV{REMOTE_USER} ne "anonymous"){
      my $bo=getModuleObject($self->Config,"faq::forumboard");
      if (defined($bo)){
         $bo->SetFilter({name=>\$_[2]});
         my ($borec,$msg)=$bo->getOnlyFirst(qw(id));
         if (defined($borec)){
            my $userid=$self->getCurrentUserId();
            my $ia=getModuleObject($self->Config,"base::infoabo");
            $ia->SetFilter({refid=>\$borec->{id},parentobj=>\"faq::forumboard",
                            userid=>$userid,mode=>\"foaddtopic"});
            my ($iarec,$msg)=$ia->getOnlyFirst(qw(id));
            if (!defined($iarec)){
               my $msg=sprintf($self->T("You currently aren't subscribed ".
                                        "to the '%s' forum. ".
                                        "By subscribing to this forum, ".
                                        "you will get useful information. ".
                                        "Klick 'OK' if you wish to subscribe ".
                                        "to this forum."),$_[2]);
               my $code=<<EOF;
<script language="JavaScript">
function ForumCheck()
{
  var r=confirm("$msg");
  if (r){
     window.document.getElementById("ForumCheck").src=
               "../../faq/forumboard/setSubscribe/$borec->{id}/foaddtopic/1";
  }
  else{
     window.document.getElementById("ForumCheck").src=
               "../../faq/forumboard/setSubscribe/$borec->{id}/foaddtopic/0";
  }
}
window.setTimeout("ForumCheck();", 2000);
</script>
<iframe style="visibility:hidden" frameborder=0 border=0 src="../msg/Empty" width=220 height=22 name=ForumCheck id=ForumCheck></iframe>
EOF
               return($code);
            }
            return(undef);
         }
         return("ERROR: can't find form $_[2]");
      }
      return(undef);
   }

   return($self->kernel::TemplateParsing::findtemplvar(@_));
}


sub ToDoRequest
{
   my $self=shift;
   my $class=shift;     # handler (or undef if base::workflow::todo)
   my $id=shift;        # unique in class or undef
   my $subject=shift;
   my $text=shift;
   my $target=shift;    # array

   my @param=($class,$id,$subject,$text,$target);

   if (!exists($self->{todohandler})){
      $self->LoadSubObjs("todohandler","todohandler");
   }
   foreach my $k (keys(%{$self->{todohandler}})){
      if ($self->{todohandler}->{$k}->can("preHandle")){
         $self->{todohandler}->{$k}->preHandle(\@param);
      }
   }
   my $processed=0; 
   
   foreach my $k (keys(%{$self->{todohandler}})){
      if ($self->{todohandler}->{$k}->can("Handle")){
         if ($self->{todohandler}->{$k}->Handle(@param)){
            $processed++;
            last;
         }
      }
   }
   if (!$processed){
      msg(WARN,"not processed todo '$subject'");
   }
   return($processed);
}





1;
