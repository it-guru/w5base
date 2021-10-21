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
use Class::ISA;
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

sub IsDirectLink
{
   return(0);
}


sub getRecordImageUrl
{
   return("../../../public/base/load/icon_htmltab.gif");
}

sub Label
{
   return("HTML active List");
}
sub Description
{
   return("HTML table with active query handling");
}



sub IsModuleSelectable
{
   return(1);
}


sub FormaterOrderPrio
{
   return(10011);  # unwichtig
}


sub getHttpHeader
{  
   my $self=shift;
   my $app=$self->getParent->getParent();
   my $d="";
   my $title="";

   my $tset=Query->Param('$TITLE$');
   if ($tset ne ""){
      $tset=~s/[<>;]//g;
      $title=$tset;
   }

   $d.=$app->HttpHeader("text/html");
   $d.=$app->HtmlHeader(style=>['default.css',
                                'Output.HtmlSubList.css',
                                'Output.HtmlViewLine.css',
                                'Output.HtmlV01.css'],
                        title=>$title,
                        body=>1,
                        );


   return($d);
}


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
         "src=\"../../../public/base/load/url.js\"></script>\n";
   $d.="<script language=JavaScript type=\"text/javascript\" ".
         "src=\"../../../public/base/load/OutputHtml.js\"></script>\n";
   $d.=$self->{fieldsPageHeader};


   $d.="<div id=HtmlNativeControlBar style='display:none'>";
   $d.=$app->getTemplate("tmpl/HtmlNativeControlBar","base");
   $d.="</div>\n";


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
            if (exists($field->{htmltablesort})){
               push(@sortnames,$field->{htmltablesort});
            }
            elsif ($field->Type() eq "Number" ||
                $field->Type() eq "Linenumber" ||
                $field->Type() eq "Percent"){
               push(@sortnames,"Number");
            }
            elsif (grep(/kernel::Field::Date/,
                        Class::ISA::self_and_super_path($field->Self))>0) {
               push(@sortnames,"iDate");
            } 
            else{
               push(@sortnames,"String");
            }
         }
      }
      my $sortline=join(",",map({'"'.$_.'"'} "None",@sortnames));
      $d.="<script language=JavaScript type=\"text/javascript\" ".
            "src=\"../../../public/base/load/sortabletable.js\"></script>\n";
      $d.="<script language=JavaScript type=\"text/javascript\" ".
            "src=\"../../../public/base/load/sortabletable_sorttype_idate.js\">".
          "</script>";
      $d.="<script language=JavaScript>\n";
      $d.="var SortTableResultTable;\n";
      $d.="addEvent(window,\"load\",checkHtmlNativeControlBar);\n";
      $d.="addEvent(window,\"load\",InitTabResultTable);\n";
      $d.="function checkHtmlNativeControlBar(){\n";
      $d.=" var e=document.getElementById(\"HtmlNativeControlBar\");\n";
      $d.=" if (window.top == window.self){\n";
      $d.=" e.style.visibility='visible';\n";
      $d.=" e.style.display='block';\n";
      $d.=" e=document.getElementById(\"HtmlNativeControlBottom\");";
      $d.=" e.style.visibility='visible';\n";
      $d.=" e.style.display='block';\n";
      $d.=" }\n";
      $d.="}\n";
      $d.="function InitTabResultTable(){\n";
      $d.="SortTableResultTable=new SortableTable(".
          "document.getElementById(\"ResultTable\"), [$sortline]);\n";
      #$d.="SortTableResultTable.onsort=function (){\n";
      #$d.=" var rows = SortTableResultTable.tBody.rows\n";
      #$d.=" var l = rows.length;\n";
      #$d.="};\n";

      #$d.=" for (var i = 0; i < l; i++) { \n".
      #    "   SortableTableremoveClassName(rows[i]); \n".
      #    "   SortableTableaddClassName(rows[i], \n".
      #    "        i % 2 ? \"subline2\":\"subline1\"); } };\n"; 
      if ($self->getParent->getParent->{AutoSortTableHtmlV01}){
         my $sortdata=$self->getParent->getParent->{AutoSortTableHtmlV01};
         AUTOSORT: foreach my $fld (keys(%$sortdata)){
            for(my $c=0;$c<$#view;$c++){
               if ($view[$c]->Name() eq $fld){
                  my $col=$c+1;
                  my $mode="false";
                  $mode="true" if ($sortdata->{$fld});
                  $d.="SortTableResultTable.sort($col,$mode);\n";
                  last AUTOSORT; 
               }
            }
         }
         #$d.="SortTableResultTable.initHeader([$sortline]);\n";
      }
      $d.="}\n";
      $d.="</script>\n";
   }
   $d.="<script language=JavaScript>\n";
   $d.="addEvent(window,\"load\",add_clipIconFunc);\n";
   $d.="</script>\n";

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
            $style="min-width:$field->{htmlwidth}";
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
   $self->{fieldHeaders}={} if (!exists($self->{fieldHeaders}));
   $self->{fieldsPageHeader}="" if (!exists($self->{fieldsPageHeader}));
   my $d="";
   my $lineclass="subline";
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
               if ($app->can("getAbsolutByIdUrl")){
                  $dest=$app->getAbsolutByIdUrl($id,{});
               }
               else{
                  $dest="ById/".$id;
               }
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
   $d.="<tr class=\"$lineclass\"";
   if ($id ne "" && $idfieldname ne ""){
      my $dataid=$id;
      $dataid=~s/[^0-9a-z_-]/_/gi;
      $d.=" data-id=\"$dataid\"";
      $d.=" data-idname=\"$idfieldname\"";
      $d.=" data-obj=\"".$self->getParent->getParent->Self."\"";
   }
   $d.=">\n";
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
            if (exists($field->{onClick}) && !ref($field->{onClick})){
               $fclick=$field->{onClick};
            }
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
         $style.="min-width:$field->{htmlwidth};";
      }                                                # browser
      else{
         $style.="width:auto;";
      }
      if (defined($field->{nowrap}) && $field->{nowrap}==1){
         $style.="white-space:nowrap;";
         $nowrap=" nowrap";
      }
      if (!($data=~m/javascript/i) && 
          !($data=~m/<.*>/i) && # html code in output of field
          !($field->can("getSubListData"))){
         # if data ist javascript, no prevent of hyphen break can be done.
         # replace of hyphen by &#x2011; is a bad solution, because it is
         # no working if data is copied to clipboard.
         #$data=~s/-/&#x2011;/g;   
         # replace to &minus; creates the same clipboard Problem.
         #$data=~s/-/&minus;/g;   
         # best solution seems to be the "not W5C conform" nobr tag. It works
         # also in IE compat mode, soo we use the "Minus-V5" solution in
         # static/MinusProblem/index.html sample doc.
         $data=~s/(\S+)-(\S+)/<nobr>$1-$2<\/nobr>/g;  
      }
      my $htmlfixedfont=0;
      if ($field->{htmlfixedfont}){
         $htmlfixedfont=1;
      }
      
      $l[$self->{fieldkeys}->{$fieldname}]={data=>$data,
                                            fclick=>$fclick,
                                            htmlfixedfont=>$htmlfixedfont,
                                            align=>$align,
                                            fieldname=>$fieldname,
                                            nowrap=>$nowrap,
                                            style=>$style};
   }
   foreach my $rec (@l){
      if (!defined($rec)){
         $d.="<td></td>";
      }
      else{
         my $class="datafield$rec->{align}";
         if ($rec->{htmlfixedfont}){
            $class.=" htmlfixedfont";
         }
         $d.="<td class=\"$class\" data-name=\"$rec->{fieldname}\" ";
         my $cl=$rec->{fclick};
         $cl=~s/"/&quot;/g;
         $d.=" onClick=\"$cl\"" if ($rec->{fclick} ne "");
         $d.=" style=\"$rec->{style}\"$rec->{nowrap}>".$rec->{data};
         if (trim($rec->{data}) ne ""){
            $d.="<div class=clipicon>".
                "<img title=\"copy\" src=\"../../base/load/edit_copy.gif\">".
                "</div>\n";
         }
         $d.="</td>\n";
      }
   }
   $d.="</tr>\n";
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
   $d.="<div id=HtmlNativeControlBottom style='display:none;height:40px'>";
   $d.="</div>\n";
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
#   $d.=$app->getTemplate("css/default.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlSubList.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlViewLine.css","base");
#   $d.=$app->getTemplate("css/Output.HtmlV01.css","base");
#   $d.="\@page { size:landscape }";
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
   if ($self->getParent->getParent->can("getParsedTemplate")){
      $d.=$self->getParent->getParent->getParsedTemplate("tmpl/DataObjOffline",
          {skinbase=>"base"});
   }
   else{
      my $LastMsg=join("\n",map({rmNonLatin1($_)} 
                  $self->getParent->getParent->LastMsg()));
      $d.=join("\n",map({rmNonLatin1($_)} 
                        $self->getParent->getParent->LastMsg()));
   }
   return($d);
}







1;
