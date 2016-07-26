package base::lib::RightsOverview;
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
use kernel;

sub RightsOverview   # erster Versuch der Berechtigungsübersicht
{
   my $self=shift;

   my %flt=$self->getSearchHash();
   $self->ResetFilter();
   $self->SecureSetFilter(\%flt);
   my $idfieldname=$self->IdField()->Name();
   my ($rec,$msg)=$self->getOnlyFirst(qw(ALL));


   print $self->HttpHeader();
   print $self->HtmlHeader(
                           title=>"TeamView",
                           js=>['toolbox.js','jquery.js'],
                           style=>['default.css','work.css',
                                   'kernel.App.Web.css',
                                   'public/base/load/rightsoverview.css']);
   print($self->getParsedTemplate("tmpl/base.lib.rightsoverview",
            {static=>{target=>$rec->{fullname}}}));
   my @checkop=$self->getCheckObjects();
   my $js=""; 
   for(my $c=0;$c<=$#checkop;$c++){
      my $chk=$checkop[$c];
      $js.="\n   ,function(){" if ($js ne "");
      $js.="\$('#$chk->{token}').load('".
           "RightsOverviewLoader?$idfieldname=$rec->{$idfieldname}&".
           "token=$chk->{token}".
           "'";
      print("<div class=checkframe id=\"$chk->{token}\">");
      print("<table width=\"100%\" cellspacing=0 cellpadding=0>");
      print("<tr><td>");
      printf("checking '%s' in '%s' ($chk->{module} [$chk->{k}])...<br>",
             $chk->{label},
             $self->T($chk->{dataobj},$chk->{dataobj}));
      print("</td></tr>");
      print("<tr><td align=center>");
      print("<img src=\"../../base/load/ajaxloader.gif\"></td></tr>");
      print("</table>");
      print("</div>");
   }
   $js.=")";
   for(my $c=1;$c<=$#checkop;$c++){
      $js.="})";
   }
   $js.=";";
   print("<script language=\"JavaScript\">\n".
         "\$(document).ready(function(){\n$js\n});\n</script>");
   print $self->HtmlBottom(body=>1,form=>1);
}

sub RightsOverviewLoader
{
   my $self=shift;
   my $idfieldname=$self->IdField()->Name();
   my $token=Query->Param("token");;
   my $id=Query->Param($idfieldname);

   print $self->HttpHeader();

   my $UserCache=$self->Cache->{User}->{Cache};
   if (defined($UserCache->{$ENV{REMOTE_USER}})){
      $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
   }

   my $found;
   my $d="";
   my $topline="unknown check object!";
   foreach my $chk ($self->getCheckObjects()){
      if ($chk->{token} eq $token){
         $topline=sprintf("<b>%s</b> : %s",
                  $self->T($chk->{dataobj},$chk->{dataobj}),$chk->{label});
         my $obj=getModuleObject($self->Config,$chk->{dataobj});
         my %flt;
         if (exists($chk->{ctrlrec}->{baseflt}) &&
             ref($chk->{ctrlrec}->{baseflt}) eq "HASH"){
            %flt=%{$chk->{ctrlrec}->{baseflt}};
         }

         $flt{$chk->{ctrlrec}->{idfield}}=\$id;
         if (defined($obj->getField("cistatusid"))){
            if (!exists($flt{cistatusid})){
               $flt{cistatusid}="<6";
            }
         }
         $obj->SetFilter(\%flt);
         my $targetlabel=$chk->{ctrlrec}->{targetlabel};
         $targetlabel="fullname" if ($targetlabel eq "");
         my $idfield=$obj->IdField();
         my $idname=$idfield->Name();
         foreach my $rec ($obj->getHashList($targetlabel,$idname)){
            my $detailx=$obj->DetailX();
            my $detaily=$obj->DetailY();

            my $dest=$chk->{dataobj};
            my $weblinkto=$dest;
            my $targetval=$rec->{$chk->{ctrlrec}->{idfield}};
            $dest=~s/::/\//g;
            $dest="../../".$dest."/ById/".$rec->{$idname};

            # Click
            my $winsize="normal";
            if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
               $winsize=$UserCache->{winsize};
            }
            my $winname="_blank";
            if (defined($UserCache->{winhandling}) &&
                $UserCache->{winhandling} eq "winonlyone"){
               $winname="W5BaseDataWindow";
            }
            if (defined($UserCache->{winhandling})
                && $UserCache->{winhandling} eq "winminimal"){
               $winname="W5B_".$weblinkto."_".$targetval;
               $winname=~s/[^a-z0-9]/_/gi;
            }
            my $onclick="custopenwin('$dest','$winsize',".
                        "$detailx,$detaily,'$winname')";

            my $pre="";
            my $post="";
            if ($chk->{ctrlrec}->{target} eq "databoss"){
               $pre="<span onclick=\"$onclick\" class=\"sublink\">";
               $post="</span>";
            }

            if ($rec->{$targetlabel} ne ""){
               $d.="<li>${pre}$rec->{$targetlabel}${post}<br>";
            }
            elsif ($rec->{fullname} ne ""){
               $d.="<li>${pre}$rec->{fullname}${post}<br>";
            }
            elsif ($rec->{name} ne ""){
               $d.="<li>${pre}$rec->{name}${post}<br>";
            }
            else{
               $d.="<li>${pre}???${post}<br>";
            }
            $found++;
         }
         $d.="</ul><br>" if ($found>0);
      }
   }
   if ($found>0){
      $d=$topline." (<font color=darkred>$found ".
                  $self->T("references")."</font>)<br><ul>".$d;
   }
   else{
      $d=$topline."<br><ul><li><font color=darkgreen>".
                  $self->T("no references found")."</li></ul>";
   }
   $d=latin1($d)->utf8();
   print $d;
}



sub getCheckObjects()
{
   my $self=shift;

   $self->LoadSubObjs("ext/ReplaceTool","ReplaceTool");
   my @checkop;
   foreach my $module (sort(keys(%{$self->{ReplaceTool}}))){
      my $crec=$self->{ReplaceTool}->{$module}->getControlRecord();
      while(my $k=shift(@$crec)){
         my $data=shift(@$crec);
         if ($data->{replaceoptype} eq $self->SelfAsParentObject()){
            my $dataobj=getModuleObject($self->Config,$data->{dataobj});
            my $label;
            if ($data->{label} ne ""){
               $label=$self->T($data->{label},$data->{dataobj});
            }
            if (!defined($label) && defined($dataobj)){
               my $fldobj=$dataobj->getField($data->{target});
               if (defined($fldobj)){
                  $label=$fldobj->Label();
               }
            }
            my $token="_${module}___${k}_";
            $token=~s/:/_/g;
            push(@checkop,{module=>$module,k=>$k,label=>$label,
                           token=>$token,
                           dataobj=>$data->{dataobj},
                           ctrlrec=>$data});
         }
      }
   }
   return(@checkop)
}




1;
