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
   $d.="<script language=JavaScript type=\"text/javascript\" ".
         "src=\"../../../public/base/load/toolbox.js\"></script>\n";
   $d.="<script language=JavaScript type=\"text/javascript\" ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n";
   $d.=$self->{fieldsPageHeader};
   $d.="<table class=maintable>\n";
   if (!Query->Param('$NOVIEWSELECT$')){
      $d.=$self->getHtmlViewLine($fh,$dest);
   }

   $d.="<tr><td class=mainblock>";

   my $limit=$app->Limit();
   my $rows=$self->getParent->getParent->Rows();
   if ($limit==0 || $limit>=$rows){   # add web-browser table sort function
      my @sortnames;
      foreach my $field (@view){
         my $fieldname=$field->Name();
         if (defined($field)){
            if ($field->Type() eq "Number" ||
                $field->Type() eq "Linenumber"){
               push(@sortnames,"Number");
            }
            else{
               push(@sortnames,"String");
            }
         }
      }
      my $sortline=join(",",map({'"'.$_.'"'} "None",@sortnames));
      $d.="<script language=JavaScript type=\"text/javascript\" ".
            "src=\"../../../public/base/load/sortabletable.js\"></script>\n";
      $d.="<script language=JavaScript>\n";
      $d.="var SortTableResultTable;\n";
      $d.="addEvent(window,\"load\",InitTabResultTable);\n";
      $d.="function InitTabResultTable(){\n";
      $d.="SortTableResultTable=new SortableTable(".
          "document.getElementById(\"ResultTable\"), [$sortline]);\n";
      $d.="SortTableResultTable.onsort=function (){\n";
      $d.=" var rows = SortTableResultTable.tBody.rows\n";
      $d.=" var l = rows.length;\n";
    #  $d.=" console.log(rows);\n";
      $d.=" for (var i = 0; i < l; i++) { \n".
          "   SortableTableremoveClassName(rows[i]); \n".
          "   SortableTableaddClassName(rows[i], \n".
          "        i % 2 ? \"subline2\":\"subline1\"); } };\n"; 
    #  $d.="SortTableResultTable.sort(1,false);\n";
      $d.="}\n";
      $d.="</script>\n";
   }

   $d.="<table class=datatable id=ResultTable width=\"100%\">\n".
       "<thead><tr class=headline>";
   if ($#view!=-1){
      $d.="<th class=headfield style=\"padding:0;margin:0\">".
          "<div style=\"padding:0;margin:0;width:3px\">".
          "</div></th>";
      for(my $pos=0;$pos<=$#view;$pos++){
         my $field=$view[$pos];
         my $name=$field->Name();
         my $displayname=$name;
         if (defined($field)){
            $displayname=$field->Label();
         }
         if (defined($field->{unit})){
            my $u=$field->unit("HtmlV01");
            if ($u ne ""){
               $displayname.="<br>(".$u.")";
            }
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
   $d.="</tr></thead><tbody>\n";
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
   my $dest;
   if (grep(/^$ResultLineClickHandler$/,$app->getValidWebFunctions())){
      if ($idfield){
         if ($id ne ""){
            if ($ResultLineClickHandler eq "ById"){
               $dest="ById/".$id;
            }
            else{
               if ($app->can($ResultLineClickHandler)){
                  $dest=$app->DataObjByIdHandler();
                  $dest=~s/::/\//g;
                  my $lq=new kernel::cgi({});
                  $lq->Param($idfieldname=>$id);
                  $lq->Param(AllowClose=>1);
                  my $urlparam=$lq->QueryString();
                  $dest="../../$dest/$ResultLineClickHandler?$urlparam";
               }
            }
            my $detailx=$app->DetailX();
            my $detaily=$app->DetailY();
            my $UserCache=$self->getParent->getParent->Cache->{User}->{Cache};
            if (defined($UserCache->{$ENV{REMOTE_USER}})){
               $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
            }
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
               $winname="W5B_".$app->Self."_".$id;
               $winname=~s/[^a-z0-9]/_/gi;
            }
            if ($dest ne ""){
               $lineonclick="custopenwin(\"$dest\",\"$winsize\",".
                            "$detailx,$detaily,\"$winname\")";
            }
         }
      }
   }
   $d.="<tr class=$lineclass ".
       "onMouseOver=\"this.className='linehighlight'\" ".
       "onMouseOut=\"this.className='$lineclass'\">\n";
   if ($#view!=-1){
      $d.="<td width=1><a class=lineselect href=\"$dest\" ".
          "target=_blank onfocus='window.status=\"open record\";' ".
          ">&nbsp;</a></td>";
   }
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
               my $fc=&{$field->{onClick}}($field,$self,$app,$rec);
               $fclick=$fc if ($fc ne "");
            }
            if (exists($field->{weblink})){
               $fclick=undef;
            }
            $fclick=undef if ($field->can("getSubListData"));
            $fclick=undef if ($field->Type() eq "IssueState");
            $fclick=undef if ($field->Type() eq "DatacareAssistent");
           
            if ($self->{SubListEdit}==1){
               $fclick="SubListEdit('$id')";
            }
            if (!exists($self->{fieldHeaders}->{$fieldname})){
               $self->{fieldHeaders}->{$fieldname}="";
            }
            $field->extendFieldHeader($self->{WindowMode},$rec,
                                      \$self->{fieldHeaders}->{$fieldname},
                                      $self->Self);
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
      if (defined($field->{htmlwidth}) && $c!=$#view){ # at last field, width
         $style.="width:$field->{htmlwidth};";         # should be calc by 
      }                                                # browser
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
   $d.="<tbody></table>\n";
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
   $d.=$app->getHtmlPagingLine("SUBFRAME",$pagelimit,
                               $currentlimit,$r,$limitreached,$limitstart);
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
   $d.=$app->getTemplate("css/Output.HtmlViewLine.css","base");
   $d.=$app->getTemplate("css/Output.HtmlV01.css","base");
   $d.="\@page { size:landscape }";
   return($d);
}




1;
