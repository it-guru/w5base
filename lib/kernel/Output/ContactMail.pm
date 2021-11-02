package kernel::Output::ContactMail;
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
   return("../../../public/base/load/icon_mail.gif");
}
sub Label
{
   return("Mail Tool");
}
sub Description
{
   return("Databased Mail target address generator.");
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


sub fieldSelectBox
{
   my $self=shift;
   my $app=shift;
   my $rec=shift;
   my $name=shift;
   my $fields=shift;
   my $preSelect=shift;

   

   my $d="<select name=\"$name\" multiple size=7 style=\"width:100%\" >";
   foreach my $fld (@$fields){
      my @fldname;
      my @fldlabel;
      if (in_array(["Contact","Databoss"],$fld->Type())){
         @fldname=($fld->Name());
         @fldlabel=($fld->Label($rec));
      }
      elsif (in_array(["Group"],$fld->Type())){
         @fldname=($fld->Name()."(groupfullname)");
         @fldlabel=($fld->Label($rec));
      }
      elsif (in_array(["ContactLnk"],$fld->Type())){
         @fldname=();
         @fldlabel=();
         my $vjoinobj=$fld->vjoinobj;
         my $p=$app->SelfAsParentObject();
         my $roles=$vjoinobj->getField("roles");
         my @l=$roles->getPostibleValues(undef,{parentobj=>$p});
         while(my $rolekey=shift(@l)){
            my $rolename=shift(@l); 
            push(@fldname,$fld->Name().":".$rolekey);
            push(@fldlabel,$fld->Label($rec).":".$rolename);
         }

      }
      elsif (exists($fld->{vjointo})){
         my $vjointo=$fld->{vjointo};
         $vjointo=$$vjointo if (ref($vjointo) eq "SCALAR");
         if ($vjointo ne ""){
            #my $vjoinobj=getModuleObject($app->Config,$vjointo);
            my $vjoinobj=$fld->vjoinobj;
            if (defined($vjointo)){
               @fldname=();
               @fldlabel=();
               my $view=$fld->{vjoindisp};
               $view=[$view] if (ref($view) ne "ARRAY");
               my @subs;
               foreach my $vfld (@$view){
                  my $subfld=$vjoinobj->getField($vfld);
                  if (defined($subfld)){
                     if (exists($subfld->{vjointo}) &&
                         $subfld->{vjointo} eq "base::user" &&
                         ref($subfld->{vjoinon}) eq "ARRAY"){
                        push(@subs,$subfld);
                     }
                  }
               }
               foreach my $subfld (@subs){
                  my $subfldname=$subfld->Name();
                  my $subfldlabel=$subfld->Label();
                  my $target=$subfld->{vjoindisp};
                  $target=$target->[0] if (ref($target) eq "ARRAY");
                  if ($target eq "fullname"){
                     push(@fldname,$fld->Name().":".$subfldname);
                     if ($#subs==0){
                        push(@fldlabel,$fld->Label($rec));
                     }
                  }
                  elsif ($target eq "email"){
                     push(@fldname,$fld->Name().":".$subfldname.
                                   "(".$target.")");
                     if ($#subs==0){
                        push(@fldlabel,$fld->Label($rec));
                     }
                  }
               }
            }
         }
      }
      for(my $fldnum=0;$fldnum<=$#fldname;$fldnum++){
         if ($fldlabel[$fldnum] ne ""){
            $d.="<option value=\"$fldname[$fldnum]\"";
            $d.=" selected" if (in_array($preSelect,$fldname[$fldnum]));
            $d.=">";
            $d.=$fldlabel[$fldnum];
            $d.="</option>";
         }
      }
   }
   $d.="</select>";

   return($d);
}



sub ProcessHead
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
 

   my @fieldlist=$app->getFieldObjsByView([qw(ALL)],
                                           opmode=>'MultiEdit');

   my @useTO=Query->Param("useTO");
   my @useCC=Query->Param("useCC");
   my $lc=Query->Param("lc");
   my $d=$self->SUPER::ProcessHead($fh,$rec,$msg);

   if ($#fieldlist!=0){
      my $country=getModuleObject($app->Config,"base::isocountry");
      $d.="<center><table class=freeform width=98% border=0>";
      $d.="<tr>";
      $d.="<td colspan=2 valign=bottom align=center>";
      $d.="<select style=\"width:50%;min-width:200px\" name=lc>";
      $d.="<option value=\"\">".
          $app->T("no language or country restriction",$self->Self)."</option>";
      $d.="<optgroup label=\"".
          $app->T("user language selection",$self->Self).
          "\">";
      foreach my $lang (LangTable()){
         my $value="talklang:$lang";
         my $selected="";
         if ($value eq $lc){
            $selected=" selected ";
         }
         $d.="<option value=\"$value\" $selected>".
             $self->getParent->getParent->T("Talk-Lang",'base::user').
             ": $lang</option>";
      }
      $d.="</optgroup>";
      $d.="<optgroup label=\"".$app->T("country",$self->Self)."\">";
      $country->SetFilter({});
      my @clist=$country->getHashList(qw(token fullname));
      foreach my $crec (@clist){
         my $value="country:".$crec->{token};
         my $selected="";
         if ($value eq $lc){
            $selected=" selected ";
         }
         $d.="<option value=\"$value\" $selected>".
             $crec->{fullname}."</option>";
      }
      $d.="</optgroup>";
      $d.="</select>";
      $d.="</td>";
      $d.="</tr>";
      $d.="<tr>";
      $d.="<td nowrap style=\"padding:10px;padding-top:0px;".
          "padding-bottom:0px\">";
      $d.=$app->T("To:",$self->Self)."<br>";
      $d.=$self->fieldSelectBox($app,$rec,"useTO",\@fieldlist,\@useTO);

      $d.="</td>";
      $d.="<td nowrap style=\"padding:15px;padding-top:0px;".
          "padding-bottom:0px\">";
      $d.=$app->T("CC:",$self->Self)."<br>";
      $d.=$self->fieldSelectBox($app,$rec,"useCC",\@fieldlist,\@useCC);
      $d.="</td>";
      $d.="</tr>";
      $d.="<tr>";
      $d.="<td colspan=2 valign=bottom align=center>";
      $d.="<img id=loader src=\"../../../public/base/load/ajaxloader.gif\" ".
          "style=\"display:none;visibility:hidden\">";
      $d.="<input id=sbutton type=submit value=\"".
          $self->getParent->getParent->T("get mail form",
                'kernel::Output::ContactMail').
          "\" onclick=\"var e=document.getElementById('sbutton');".
                       "e.style.visibility='hidden';".
                       "e.style.display='none';".
                       "var e=document.getElementById('loader');".
                       "e.style.visibility='visible';".
                       "e.style.display='block';".
                       "return(true);\" >";
      $d.="</td>";
      $d.="</tr>";
      $d.="</table></center>";

#      $d.="<div style=\"font-family:monospace;margin:5px;".
#          "padding:5px;height:100px;overflow:auto;".
#          "border-top:1px solid black\">";
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
   my @view;
   my $lc=Query->Param("lc");
   my @useTO=Query->Param("useTO");
   my @useCC=Query->Param("useCC");
   my %search=$app->getSearchHash();
   my $country;
   if (my ($token)=$lc=~m/^country:([A-Z]{2})$/){
      $country=$token;
   }
   my $talklang;
   if (my ($lang)=$lc=~m/^talklang:([a-z]{2})$/){
      $talklang=$lang;
   }


   my %view;

   foreach my $fld (@useTO,@useCC){
      my $viewfield=$fld;
      $viewfield=~s/[:(].*//;
      $view{$viewfield}++;
   }
   my @view=sort(keys(%view));

   if ($#view!=-1){
      my $opobj=$app->Clone();
      $opobj->SecureSetFilter(\%search);
      my @l=$opobj->getHashList(@view);

      my %finalTO;
      my %finalCC;

      my $res={};

      foreach my $rec (@l){
         foreach my $chkvarname (@useTO,@useCC){
            my $chkvar=$chkvarname;
            my ($fieldname,$subselector,$useas)=($chkvar);
            if ($chkvar=~m/^.+\(.+\)$/){
               ($chkvar,$useas)=$chkvar=~m/^(.+)\((.+)\)$/;
               $fieldname=$chkvar;
            }
            if ($chkvar=~m/:/){
               ($fieldname,$subselector)=$chkvar=~m/^(.*):(.*)/;
            }
            $useas="contactfullname" if ($useas eq "");
            my $fldobj=$opobj->getField($fieldname);
            if (defined($fldobj)){
               if (in_array(["ContactLnk"],$fldobj->Type())){
                  my $list=$rec->{$fieldname};
                  $list=[$list] if (ref($list) ne "ARRAY");
                  foreach my $subrec (@$list){
                     my $roles=$subrec->{roles};
                     $roles=[$roles] if (ref($roles) ne "ARRAY");
                     if (in_array($roles,$subselector)){
                        if ($subrec->{target} eq "base::grp"){
                           if (in_array(\@useTO,$chkvarname)){
                              $res->{to}->{grpid}->{$subrec->{targetid}}++;
                           }
                           if (in_array(\@useCC,$chkvarname)){
                              $res->{cc}->{grpid}->{$subrec->{targetid}}++;
                           }
                        }
                        if ($subrec->{target} eq "base::user"){
                           if (in_array(\@useTO,$chkvarname)){
                              $res->{to}->{userid}->{$subrec->{targetid}}++;
                           }
                           if (in_array(\@useCC,$chkvarname)){
                              $res->{cc}->{userid}->{$subrec->{targetid}}++;
                           }
                        }
                     }
                  }
               }
               elsif ($subselector ne ""){
                  my $list=$rec->{$fieldname};
                  $list=[$list] if (ref($list) ne "ARRAY");
                  foreach my $subrec (@$list){
                     my $contactname;
                     if (ref($subrec) eq "HASH"){
                        $contactname=$subrec->{$subselector};
                     }
                     else{
                        $contactname=$subrec;
                     }
                     if ($contactname ne ""){
                        if (in_array(\@useTO,$chkvarname)){
                           $res->{to}->{$useas}->{$contactname}++;
                        }
                        if (in_array(\@useCC,$chkvarname)){
                           $res->{cc}->{$useas}->{$contactname}++;
                        }
                     }
                  }
               }
               elsif ($subselector eq ""){
                  my $contactname=$rec->{$fieldname};
                  if ($contactname ne ""){
                     if (in_array(\@useTO,$chkvarname)){
                        $res->{to}->{$useas}->{$contactname}++;
                     }
                     if (in_array(\@useCC,$chkvarname)){
                        $res->{cc}->{$useas}->{$contactname}++;
                     }
                  }
               }
            }
         }
      }



      my $user=getModuleObject($app->Config,"base::user");
      my $grp=getModuleObject($app->Config,"base::grp");
      if (keys(%{$res->{to}->{groupfullname}}) ||
          keys(%{$res->{cc}->{groupfullname}})){
         $grp->SetFilter({
            fullname=>[keys(%{$res->{to}->{groupfullname}}),
                       keys(%{$res->{cc}->{groupfullname}})],
            cistatusid=>[4]
         });
         foreach my $grec ($grp->getHashList(qw(fullname users))){
            foreach my $lnkrec (@{$grec->{users}}){
               my $roles=$lnkrec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if (in_array($roles,"RMember")){
                  if (exists($res->{to}->{groupfullname}->{$grec->{fullname}})){
                     $res->{to}->{userid}->{$lnkrec->{userid}}++;
                  }
                  if (exists($res->{cc}->{groupfullname}->{$grec->{fullname}})){
                     $res->{cc}->{userid}->{$lnkrec->{userid}}++;
                  }
               }
            }
            if (exists($res->{to}->{groupfullname}->{$grec->{fullname}})){
               delete($res->{to}->{groupfullname}->{$grec->{fullname}});
            }
            if (exists($res->{cc}->{groupfullname}->{$grec->{fullname}})){
               delete($res->{cc}->{groupfullname}->{$grec->{fullname}});
            }
         } 
      }
      if (keys(%{$res->{to}->{grpid}}) ||
          keys(%{$res->{cc}->{grpid}})){
         $grp->SetFilter({
            grpid=>[keys(%{$res->{to}->{grpid}}),
                    keys(%{$res->{cc}->{grpid}})],
            cistatusid=>[4]
         });
         foreach my $grec ($grp->getHashList(qw(grpid users))){
            foreach my $lnkrec (@{$grec->{users}}){
               my $roles=$lnkrec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if (in_array($roles,"RMember")){
                  if (exists($res->{to}->{grpid}->{$grec->{grpid}})){
                     $res->{to}->{userid}->{$lnkrec->{userid}}++;
                  }
                  if (exists($res->{cc}->{grpid}->{$grec->{grpid}})){
                     $res->{cc}->{userid}->{$lnkrec->{userid}}++;
                  }
               }
            }
            if (exists($res->{to}->{grpid}->{$grec->{grpid}})){
               delete($res->{to}->{grpid}->{$grec->{grpid}});
            }
            if (exists($res->{cc}->{grpid}->{$grec->{grpid}})){
               delete($res->{cc}->{grpid}->{$grec->{grpid}});
            }
         } 
      }
      if (keys(%{$res->{to}->{contactfullname}}) ||
          keys(%{$res->{cc}->{contactfullname}})){
         my $ufilter={
            fullname=>[keys(%{$res->{to}->{contactfullname}}),
                       keys(%{$res->{cc}->{contactfullname}})],
            cistatusid=>[4]
         };
         if (defined($country)){
            $ufilter->{country}=\$country;
         }
         my @uview=qw(fullname email);
         if (defined($talklang)){
            push(@uview,"talklang");
         }
         $user->SetFilter($ufilter);
         foreach my $urec ($user->getHashList(@uview)){
             if (exists($res->{to}->{contactfullname}->{$urec->{fullname}})){
                if (!defined($talklang) || $talklang eq $urec->{talklang}){
                   $res->{to}->{email}->{$urec->{email}}++;
                }
                delete($res->{to}->{contactfullname}->{$urec->{fullname}});
             }
             if (exists($res->{cc}->{contactfullname}->{$urec->{fullname}})){
                if (!defined($talklang) || $talklang eq $urec->{talklang}){
                   $res->{cc}->{email}->{$urec->{email}}++;
                }
                delete($res->{cc}->{contactfullname}->{$urec->{fullname}});
             }
         } 
      }
      $user->ResetFilter();
      if (keys(%{$res->{to}->{userid}}) ||
          keys(%{$res->{cc}->{userid}})){
         my $ufilter={
            userid=>[keys(%{$res->{to}->{userid}}),
                       keys(%{$res->{cc}->{userid}})],
            cistatusid=>[4]
         };
         if (defined($country)){
            $ufilter->{country}=\$country;
         }
         my @uview=qw(userid email);
         if (defined($talklang)){
            push(@uview,"talklang");
         }
         $user->SetFilter($ufilter);
         foreach my $urec ($user->getHashList(@uview)){
             if (exists($res->{to}->{userid}->{$urec->{userid}})){
                if (!defined($talklang) || $talklang eq $urec->{talklang}){
                   $res->{to}->{email}->{$urec->{email}}++;
                }
                delete($res->{to}->{userid}->{$urec->{userid}});
             }
             if (exists($res->{cc}->{userid}->{$urec->{userid}})){
                if (!defined($talklang) || $talklang eq $urec->{talklang}){
                   $res->{cc}->{email}->{$urec->{email}}++;
                }
                delete($res->{cc}->{userid}->{$urec->{userid}});
             }
         } 
         foreach my $toaddr (keys(%{$res->{to}->{email}})){
            if (exists($res->{cc}->{email}->{$toaddr})){
               delete($res->{cc}->{email}->{$toaddr});
            }
         }
      }
      my $finalTO=join("; ",sort(keys(%{$res->{to}->{email}})));
      my $finalCC=join("; ",sort(keys(%{$res->{cc}->{email}})));


      $d.="<script language=\"JavaScript\">";
      $d.="var wnd=xopenwin(\"../../base/workflow/externalMailHandler\",".
                   "\"_blank\",".
                   "\"height=400,width=600,toolbar=no,status=no,".
                   "resizable=yes,scrollbars=no\");";
      $d.="function setVal(){";   # new is needed for IE !
      $d.="wnd.document.getElementById('to').value=\"$finalTO\";";
      $d.="wnd.document.getElementById('cc').value=\"$finalCC\";";
      $d.="wnd.opener=null;";
      $d.="}";
      $d.="if (wnd.addEventListener) {";
      $d.="   wnd.addEventListener(\"load\", setVal, false);";
      $d.="}";
      $d.="else if (wnd.attachEvent) {";
      $d.="   wnd.attachEvent('onload', setVal);";
      $d.="}";
      $d.="else{";
      $d.="   wnd.onload = setVal;";
      $d.="}";
      $d.="";

      $d.="</script>";
   }


#   $d.="</div>";
   $d.=$app->HtmlBottom(form=>1,body=>1);
   return($d);
}

1;
