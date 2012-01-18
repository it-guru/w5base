package kernel::Output::HtmlV01;
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

sub getDownloadFilename
{
   my $self=shift;

   return($self->SUPER::getDownloadFilename().".html");
}





sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->HttpHeader("text/html");
   $d.=$app->HtmlHeader();

   return($d);
}

#sub Init
#{
#   my ($self,$fh)=@_;
#   my $app=$self->getParent->getParent();
#   $self->{fieldobjects}=[];
#   $self->{fieldkeys}={};
#   my @view=$app->getFieldObjsByView([$app->getCurrentView()]);
#   for(my $c=0;$c<=$#view;$c++){
#      my $field=$view[$c];
#      my $name=$field->Name();
#      push(@{$self->{fieldobjects}},$field);
#      $self->{fieldkeys}->{$name}=$#{$self->{fieldobjects}};
#   }
#   return();
#}





sub ProcessHead
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=();
   @view=@{$self->{fieldobjects}} if (defined($self->{fieldobjects}));
   my $d="";
   my $dest=$app->Self();
   $dest=~s/::/\//g;
   $dest="../../$dest/Result";
   $d.="<form method=POST><style>";
   $d.=$self->getStyle($fh);
   $d.="</style>\n\n";
   $d.="<script language=JavaScript ".
         "src=\"../../../public/base/load/toolbox.js\"></script>\n";
   $d.="<script language=JavaScript ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n";
   $d.=$self->{fieldsPageHeader};
   $d.="<table class=maintable>\n";
   if (!Query->Param('$NOVIEWSELECT$')){
      $d.=$self->getHtmlViewLine($fh,$dest);
   }

   $d.="<tr><td class=mainblock>";
   $d.="<table class=datatable width=100%>\n<tr class=headline>";
   if ($#view!=-1){
      foreach my $field (@view){
         my $name=$field->Name();
         my $displayname=$name;
         if (defined($field)){
            $displayname=$field->Label();
         }
         if (defined($field->{unit})){
            $displayname.="<br>(".$field->unit("HtmlV01").")";
         }
         my $style="";
         if (defined($field->{htmlwidth})){
            $style="width:$field->{htmlwidth};";
         }
         $d.="<th class=headfield valign=top style=\"$style\">".
             $displayname.$self->{fieldHeaders}->{$name}."</th>";
      }
   }
   else{
      $d.="<th class=headfield>No-Fields</th>";
   }
   $d.="</tr>\n";
   return($d);
}
sub ProcessLine
{
   my ($self,$fh,$viewgroups,$rec,$recordview,$fieldbase,$lineno,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=@{$recordview};
   my $fieldbase={};
   map({$fieldbase->{$_->Name()}=$_} @view);
   $self->{lineclass}=1 if (!exists($self->{lineclass}));
   $self->{fieldHeaders}={} if (!exists($self->{fieldHeaders}));
   $self->{fieldsPageHeader}="" if (!exists($self->{fieldsPageHeader}));
   my $d="";
   my $lineclass="subline".$self->{lineclass};
   my $lineonclick;
   my $idfield=$app->IdField();
   my $idfieldname=undef;
   my $id=undef;
   if (defined($idfield)){
      $idfieldname=$idfield->Name() if (defined($idfield));
      $id=$idfield->RawValue($rec);
   }
   $id=$id->[0] if (ref($id) eq "ARRAY");
   my $ResultLineClickHandler=$app->{ResultLineClickHandler};
   $ResultLineClickHandler="ById" if (!exists($app->{ResultLineClickHandler}));
   if (grep(/^$ResultLineClickHandler$/,$app->getValidWebFunctions())){
      if ($idfield){
         my $dest;
         if ($id ne ""){
            if ($ResultLineClickHandler eq "ById"){
               $dest="ById/".$id;
            }
            else{
               $dest=$app->Self();
               $dest=~s/::/\//g;
               my $lq=new kernel::cgi({});
               $lq->Param($idfieldname=>$id);
               $lq->Param(AllowClose=>1);
               my $urlparam=$lq->QueryString();
               $dest="../../$dest/$ResultLineClickHandler?$urlparam";
            }
            my $detailx=$app->DetailX();
            my $detaily=$app->DetailY();
            my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
            if (defined($UserCache->{$ENV{REMOTE_USER}})){
               $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
            }
            my $winsize="";
            if (defined($UserCache->{winsize}) && $UserCache->{winsize} ne ""){
               $winsize=$UserCache->{winsize};
            }
            if ($winsize eq ""){
               $lineonclick="openwin(\"$dest\",\"_blank\",".
                   "\"height=$detaily,width=$detailx,toolbar=no,status=no,".
                   "resizable=yes,scrollbars=auto\")";
            }
            else{
               $lineonclick="custopenwin(\"$dest\",\"$winsize\",$detailx)";
            }
         }
      }
   }
   $d.="<tr class=$lineclass ".
       "onMouseOver=\"this.className='linehighlight'\" ".
       "onMouseOut=\"this.className='$lineclass'\">\n";
   my @l=();
   for(my $c=0;$c<=$#view;$c++){
      my $nowrap="";
      my $fieldname=$view[$c]->Name();
      my $field=$view[$c];
      my $data="undefined";
      if (!defined($self->{fieldkeys}->{$fieldname})){
         push(@{$self->{fieldobjects}},$field);
         $self->{fieldkeys}->{$fieldname}=$#{$self->{fieldobjects}};
      }
      my $fclick=$lineonclick;
      if (defined($field)){
         if ($field->UiVisible("HtmlList",current=>$rec)){
            $data=$app->findtemplvar({viewgroups=>$viewgroups,
                                      current=>$rec,
                                      WindowMode=>$self->{WindowMode},
                                      fieldbase=>$fieldbase
                                     },$fieldname,
                                        "formated");
            #if ($self->getParent->getParent->Config->Param("UseUTF8")){
            #   $data=utf8($data);
            #   $data=$data->latin1();
            #}
            if (ref($field->{onClick}) eq "CODE"){
               my $fc=&{$field->{onClick}}($self,$app);
               $fclick=$fc if ($fc ne "");
            }
            if (exists($field->{weblink})){
               $fclick=undef;
            }
            $fclick=undef if ($field->can("getSubListData"));
            $fclick=undef if ($field->Type() eq "IssueState");
           
            if ($self->{SubListEdit}==1){
               $fclick="SubListEdit('$id')";
            }
            if (!exists($self->{fieldHeaders}->{$fieldname})){
               $self->{fieldHeaders}->{$fieldname}="";
            }
            $field->extendFieldHeader($self->{WindowMode},$rec,
                                      \$self->{fieldHeaders}->{$fieldname});
            $field->extendPageHeader($self->{WindowMode},$rec,
                                     \$self->{fieldsPageHeader});
         }
         else{
            $data="-";
         }
        # my $data=$field->FormatedResult("html");
      }
      my $style;
      my $align;
      if (defined($field->{align})){
         $align=" align=$field->{align}";
      }
      if (defined($field->{htmlwidth})){
         $style.="width:$field->{htmlwidth};";
      }
      else{
         $style.="width:auto;";
      }
      if (defined($field->{nowrap}) && $field->{nowrap}==1){
         $style.="white-space:nowrap;";
         $nowrap=" nowrap";
      }
      if (!($data=~m/javascript/i)){
         $data=~s/-/&#x2011;/g;   # nicht zulässig, wenn JavaScript vorkommt
      }
      $l[$self->{fieldkeys}->{$fieldname}]={data=>$data,
                                            fclick=>$fclick,
                                            align=>$align,
                                            nowrap=>$nowrap,
                                            style=>$style};
   }
   foreach my $rec (@l){
      if (!defined($rec)){
         $d.="<td></td>";
      }
      else{
         $d.="<td class=datafield$rec->{align}";
         $d.=" onClick=$rec->{fclick}" if ($rec->{fclick} ne "");
         $d.=" style=\"$rec->{style}\"$rec->{nowrap}>".$rec->{data}."</td>\n";
      }
   }
   $d.="</tr>\n";
   $self->{lineclass}++;
   $self->{lineclass}=1 if ($self->{lineclass}>2);
   return($d);
}

sub getPagingLine
{
   my $self=shift;
   my $app=$self->getParent->getParent;
   my $pagelimit=shift;
   my $currentpage=shift;
   my $totalpages=shift;
   my $currentlimit=shift;
   my $records=shift;
   my $d="<div class=pagingline>";
   my $nextpagestart=$pagelimit*($currentpage+1);
   $nextpagestart=$totalpages*$pagelimit if ($nextpagestart>$totalpages*$pagelimit);
   my $prevpagestart=($currentpage-1)*$pagelimit;
   $prevpagestart=0 if ($prevpagestart<0);
   

   my $nexttext="&nbsp;";
   if ($currentpage<$totalpages-1 && $currentlimit>0){
      $nexttext="<a class=pageswitch ".
                "href=JavaScript:setLimitStart($nextpagestart)>".
                $app->T("next page")."</a>";
   }
   my $prevtext="&nbsp;";
   if ($currentpage>0 && $currentlimit>0){
      $prevtext="<a class=pageswitch ".
                "href=JavaScript:setLimitStart($prevpagestart)>".
                $app->T("previous page")."</a>";
   }
   my $recordstext="<b>".sprintf($app->T("Total: %d records"),$records)."</b>";
   if (($records<500 || $app->IsMemberOf("admin")) && 
       $app->allowHtmlFullList() &&
       $currentlimit>0 && $records>$currentlimit){
      $recordstext="<a class=pageswitch ".
                   "href=Javascript:showall()>$recordstext</a>";
   }
   my $maxpages=14;
   $maxpages=$totalpages-1 if ($maxpages>$totalpages-1);
   my @pages=();
   my $disppagestart=$currentpage-($maxpages/2);
   $disppagestart=1 if ($disppagestart<1);
   if ($disppagestart>$totalpages-$maxpages-1){
      $disppagestart=$totalpages-$maxpages;
   }
   for(my $c=0;$c<=$maxpages;$c++){
      $pages[$c]=$disppagestart+$c;
   }

   $pages[0]=1 if ($pages[0]!=1);
   $pages[$maxpages]=$totalpages if ($totalpages>$pages[$maxpages]);

   my $pagelist="";
   if ($totalpages>1 && $currentlimit>0){
      $pagelist.="<table border=0><tr>";
      for(my $p=0;$p<=$#pages;$p++){
         $pagelist.="<td>...</td>" if ($p==1 && $pages[$p]-1!=$pages[$p-1]);
         my $disppagesstr=$pages[$p];
         if ($currentpage+1==$pages[$p]){
            $disppagesstr="<u><b>$pages[$p]</b></u>";
         }
         my $ps=($pages[$p]-1)*$pagelimit;
         $disppagesstr="<a class=pageswitch ".
                       "href=JavaScript:setLimitStart($ps)>".
                       "$disppagesstr</a>";
         $pagelist.="<td width=20 align=center>$disppagesstr</td>";
         $pagelist.="<td>...</td>" if ($p==$#pages-1 && 
                                       $pages[$p]+1!=$pages[$#pages]);
      }
      $pagelist.="</tr></table>";
   }
   
   $d.="<center><table width=600 border=0><tr>";
   $d.="<tr>";
   $d.="<td width=90 align=center>$prevtext</td>";
   $d.="<td align=center>$recordstext</td>";
   $d.="<td width=90 align=center>$nexttext</td></tr>";
   $d.="</tr>";
   $d.="<tr>";
   $d.="<td></td>";
   $d.="<td align=center>$pagelist</td>";
   $d.="<td></td></tr>";
   $d.="</tr>";
   $d.="</table></center></div>";
   $d.=<<EOF;
<script language="JavaScript">
function setLimitStart(n)
{
   parent.document.forms[0].elements['UseLimitStart'].value=n;
   parent.document.forms[0].submit();
}
function showall()
{
   parent.document.forms[0].elements['UseLimit'].value="0";
   parent.document.forms[0].elements['UseLimitStart'].value="0";
   parent.DoRemoteSearch(undefined,undefined,undefined,undefined,1);
}
</script>
EOF
   return($d);
}
sub ProcessBottom
{
   my ($self,$fh,$rec,$msg)=@_;
   my $app=$self->getParent->getParent();
   my $view=$app->getCurrentViewName();
   my @view=$app->getCurrentView();
   my $d="</table>";

   my $limitreached=0;
   if (defined($msg)){
      if (!$self->{DisableMsg}){
         if ($msg eq "Limit reached"){
            $limitreached=1;
         }
         else{
            $d.="<hr>unexpected error = $msg<br>";
         }
      }
   }

   $d.="</td></tr>\n\n\n";
   $d.="</table>\n";
   if ($self->{SubListEdit}==1){
      $d.=<<EOF;
<script language=JavaScript>
function SubListEdit(setid)
{
   var id=document.getElementById('CurrentIdToEdit');
   var nr=document.getElementById('NewRecSelected');
   if (id){
      id.value=setid;
      nr.value="1";
      document.forms[0].submit();
   }
}
</script>
EOF
   }
   $d.="</form>";
   $d.=$self->HtmlStoreQuery();
   my $pagelimit=$self->getParent->getParent->{_Limit};
   if (!defined($pagelimit)){
      my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{pagelimit}) && $UserCache->{pagelimit} ne ""){
         $pagelimit=$UserCache->{pagelimit};
      }
   }
   my $limitstart=$self->getParent->getParent->{_LimitStart};
   my $currentlimit=$self->getParent->getParent->{_Limit};
   my $r=$self->getParent->getParent->Rows();
   if (defined($r) && $pagelimit>0){
      my $totalpages=0;
      if ($pagelimit>0){
         $totalpages=$r/$pagelimit;
      }
      $totalpages=int($totalpages)+1 if (int($totalpages)!=$totalpages);
      my $currentpage=0;
      if ($pagelimit>0){
         $currentpage=int($limitstart/$pagelimit);
      }

      $d.="<hr>" if ($limitreached || ($currentlimit>0 && $r>$currentlimit));
      $d.=$self->getPagingLine($pagelimit,$currentpage,$totalpages,
                               $currentlimit,$r);
   }


   return($d);
}


sub getHttpFooter
{  
   my $self=shift;
   my $d="";
   $d.="</body>";
   $d.="</html>";
   return($d);
}





sub getStyle
{
   my ($self,$fh)=@_;
   my $app=$self->getParent->getParent();
   my $d="";
   $d.=$app->getTemplate("css/default.css","base");
   $d.=$app->getTemplate("css/Output.HtmlSubList.css","base");
   $d.=$app->getTemplate("css/Output.HtmlV01.css","base");
   $d.="\@page { size:landscape }";
   return($d);
}




1;
