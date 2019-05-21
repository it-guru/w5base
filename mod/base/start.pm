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
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','mainwork.css'],
                           title=>$title,
                           js=>['toolbox.js'],
                           body=>1,form=>1);
   print "<script language=\"JavaScript\" ".
         "src=\"../../base/load/toolbox.js\"></script>";
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
