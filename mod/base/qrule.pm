package base::qrule;
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
use kernel::Field;
use kernel::DataObj::Static;
use kernel::App::Web::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::Static);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                align         =>'left',
                label         =>'QRule ID'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'QRule Name',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return($self->getParent->{qrule}->{$id}->getName());
                }),

      new kernel::Field::Text(
                name          =>'target',
                label         =>'posible Targets'),

      new kernel::Field::Htmlarea(
                name          =>'longdescription',
                label         =>'Description',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   return($self->getParent->{qrule}->{$id}->getDescription());
                }),

      new kernel::Field::Textarea(
                name          =>'code',
                label         =>'Programmcode',
                searchable    =>0,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id=$current->{id};
                   my $instdir=$self->getParent->Config->Param("INSTDIR");
                   $id=~s/::/\//g;
                   my $d="?";
                   my $file="$instdir/mod/$id.pm";
                   if (-f $file){
                      if (open(F,"<$file")){
                         $d=join("",<F>);
                         close(F);
                      }
                   }
                   return($d);
                }),

   );
   $self->LoadSubObjs("qrule","qrule");
   $self->{'data'}=[];
   foreach my $obj (values(%{$self->{qrule}})){
      my $ctrl=$obj->getPosibleTargets();
      my $name=$obj->Self();
      my $r={id=>$obj->Self,
             target=>$obj->getPosibleTargets()};
      push(@{$self->{'data'}},$r);
   }
   $self->setDefaultView(qw(linenumber id name target));
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/qmgmt.jpg?".$cgi->query_string());
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}  

sub nativQualityCheck
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my @param=@_;
   my $parent=$self->getParent;
   my $result;
   my @alldataissuemsg;
   my $mandator=[];
   my $checkStart=NowStamp("en");

   $mandator=$rec->{mandatorid} if (exists($rec->{mandatorid}));
   $mandator=[$mandator] if (ref($mandator) ne "ARRAY");
   push(@$mandator,0);  # for rules on any mandator
   $objlist=[$objlist] if (ref($objlist) ne "ARRAY");
   my $lnkr=getModuleObject($self->Config,"base::lnkqrulemandator");
   $lnkr->SetFilter({mandatorid=>$mandator});
   foreach my $lnkrec ($lnkr->getHashList(qw(mdate qruleid))){
      my $qrulename=$lnkrec->{qruleid};
      if (defined($self->{qrule}->{$qrulename})){
         my $qrule=$self->{qrule}->{$qrulename};
         my $postargets=$qrule->getPosibleTargets();
         my $found=0;
         if (ref($postargets) eq "ARRAY"){
            foreach my $target (@$postargets){
               if (grep(/^$target$/,@$objlist)){
                  $found=1;
                  last;
               }
            }
         }
         if ($found){
            my $oldcontext=$W5V2::OperationContext;
            $W5V2::OperationContext="QualityCheck";
            my ($qresult,$control)=$qrule->qcheckRecord($parent,$rec);
            $W5V2::OperationContext=$oldcontext;
            if (defined($control->{dataissue})){
               my $dataissuemsg=$control->{dataissue};
               $dataissuemsg=[$dataissuemsg] if (ref($dataissuemsg) ne "ARRAY");
               push(@alldataissuemsg,$qrule->getName());
               foreach my $m (@{$dataissuemsg}){
                  push(@alldataissuemsg," - ".$m);
               }
            }
            my $resulttext="OK";
            $resulttext="fail"      if ($qresult!=0);
            $resulttext="messy"     if ($qresult==1);
            $resulttext="warn"      if ($qresult==2);
            $resulttext="undefined" if (!defined($qresult));
            my $qrulelongname=$qrule->getName();
            my $res={ rulelabel=>"$qrulelongname",
                      result=>$self->T($resulttext),
                      exitcode=>$qresult};
            if (defined($control->{qmsg})){
               $res->{qmsg}=$control->{qmsg};
               if (ref($res->{qmsg}) eq "ARRAY"){
                  for(my $c=0;$c<=$#{$res->{qmsg}};$c++){
                     $res->{qmsg}->[$c]=$self->T($res->{qmsg}->[$c],
                                                  $qrulename);
                  }
               }
               else{
                  $res->{qmsg}=$self->T($res->{qmsg},$qrulename);
               }
            }
            push(@{$result->{rule}},$res);
         }
      }
   }
   my $wf=getModuleObject($parent->Config,"base::workflow");
   my $dataobj=$self->getParent();
   my $affectedobject=$dataobj->Self();
   my $affectedobjectid=$rec->{id};
   if ($#alldataissuemsg>-1){
      my $directlnkmode="DataIssueMsg";
      my $detaildescription=join("\n",@alldataissuemsg);
      my $name="DataIssue: ".$dataobj->T($affectedobject,$affectedobject).": ".
               $rec->{name};
      $wf->SetFilter({stateid=>"<20",class=>\"base::workflow::DataIssue",
                      directlnktype=>\$affectedobject,
                      directlnkid=>\$affectedobjectid});
      my ($WfRec,$msg)=$wf->getOnlyFirst(qw(ALL));
      my $oldcontext=$W5V2::OperationContext;
      $W5V2::OperationContext="QualityCheck";
      if (!defined($WfRec)){
         my $newrec={name=>$name,
                     detaildescription=>$detaildescription,
                     class=>"base::workflow::DataIssue",
                     step=>"base::workflow::DataIssue::dataload",
                     affectedobject=>$affectedobject,
                     affectedobjectid=>$affectedobjectid,
                     directlnkmode=>$directlnkmode,
                     eventend=>undef,
                     eventstart=>NowStamp("en"),
                     DATAISSUEOPERATIONSRC=>$directlnkmode};
         my $bk=$wf->Store(undef,$newrec);
         printf STDERR ("store bk=%s\n",Dumper(\$bk));
      }
      else{
         my $newrec={name=>$name,
                     detaildescription=>$detaildescription};
         my $bk=$wf->Store($WfRec,$newrec);
         printf STDERR ("updstore bk=%s\n",Dumper(\$bk));
      }

      $W5V2::OperationContext=$oldcontext;
   }
   my $oldcontext=$W5V2::OperationContext;
   $W5V2::OperationContext="QualityCheck";
   #
   # cleanup deprecated DataIssues for current object
   #
   $wf->ResetFilter();
   $wf->SetFilter({stateid=>"<20",class=>\"base::workflow::DataIssue",
                   srcload=>"<\"$checkStart GMT\"",
                   directlnktype=>\$affectedobject,
                   directlnkid=>\$affectedobjectid});
   $wf->SetCurrentView(qw(ALL));
   $wf->ForeachFilteredRecord(sub{
                      $wf->Store($_,{stateid=>'21'});
                   });

   
   $W5V2::OperationContext=$oldcontext;

   return($result);

}


sub WinHandleQualityCheck
{
   my $self=shift;
   my $objlist=shift;
   my $rec=shift;
   my $dataobj=$self->getParent();
   my $CurrentIdToEdit=Query->Param("CurrentIdToEdit");
   my $mode=Query->Param("Mode");
   if (defined($mode) && $mode eq "process" && $CurrentIdToEdit ne ""){
      print $self->HttpHeader("text/xml");
      my $res=hash2xml({},{header=>1});
      print $res."<document>";
      my $checkresult=$self->nativQualityCheck($objlist,$rec);
      print STDERR Dumper($checkresult);
      foreach my $ruleres (@{$checkresult->{rule}}){
         my $res=hash2xml({rule=>$ruleres},{});
         print $res;
         printf STDERR ($res."\n");
      }
      print "</document>";
      return();
   }
   my $d=$self->HttpHeader("text/html");
   my $winlabel;
   $winlabel=$rec->{name}     if (defined($rec->{name}));
   $winlabel=$rec->{fullname} if (defined($rec->{fullname}));
   $d.=$self->HtmlHeader(style=>'default.css',
                         form=>1,body=>1,
                         js=>['toolbox.js'],
                         title=>$self->T("QC:").$winlabel);
   my $handlermask=$self->getParsedTemplate("tmpl/base.qualitycheck",
                          {static=>{winlabel=>$winlabel}});
   my $msg=$self->findtemplvar({},"LASTMSG"); 
   my $DetailClose=$self->T("DetailClose","kernel::App::Web::Listedit");
   my $DetailPrint=$self->T("DetailPrint","kernel::App::Web::Listedit");
   $d.=<<EOF;
<style>body{overflow:hidden;padding:4px}optgroup{margin-bottom:5px}
div.buttonline{
   margin:0;
   padding:0;
}
div#reslist{
   height:80px;
   overflow:auto;
   background:#FFFFFF;
   margin:0;
   padding:2px;
   border-color:black;
   border-width:1px;
   border-style:solid;
}
\@media print {
   div#reslist{
      height:auto;
      overflow:show;
   }
   div.buttonline{
      display:none;
      visibility:hidden;
   }
   body{
     padding:10px;
   }
}

</style>
<table width=100% height=98% border=0>
<tr height=50><td>$handlermask</td></tr>
<tr>
<td valign=top>
<div id=reslist>
</div>
</td>
<tr height=20>
<td>
<table cellspacing=0 cellpadding=0 width=100%>
<tr><td>$msg</td><td align=right><div id=summary></div></td></tr>
</table>
</td>

</tr>
<tr height=1%>
<td align=right>
<div class=buttonline>
<input onclick="window.print();" type=button style="width:100px" value="$DetailPrint">
<input onclick="processCheck();" type=button style="width:100px" value="recheck">
<input onclick="window.close();" type=button style="width:100px" value="$DetailClose">
<input type=hidden name=CurrentIdToEdit value="$CurrentIdToEdit">
</div>
</td>
</tr>
</table>
<script language="JavaScript">

function addToResult(ruleid)
{
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST",document.location.href,true);
   xmlhttp.onreadystatechange=function() {
    if (xmlhttp.readyState<4){
       var r=document.getElementById("reslist");
       if (r){
          var t="Checking ...";
          if (r.innerHTML!=t){
             r.innerHTML=t;
          }
       }
       var r=document.getElementById("summary");
       if (r){
          var t="- working -";
          if (r.innerHTML!=t){
             r.innerHTML=t;
          }
       }
    }
    if (xmlhttp.readyState==4 && (xmlhttp.status==200 || xmlhttp.status==304)){
       var xmlobject = xmlhttp.responseXML;
       var r=document.getElementById("reslist");
       r.innerHTML="";
       var results=xmlobject.getElementsByTagName("rule");
       var ok=0;
       var warn=0;
       var fail=0;
       if (results.length>0){
          for(rid=0;rid<results.length;rid++){
             var ruleres=results[rid];

             var label=ruleres.getElementsByTagName("rulelabel")[0];
             var labelChildNode=label.childNodes[0];
             var labeltext=labelChildNode.nodeValue;

             var result=ruleres.getElementsByTagName("result")[0];
             var resultChildNode=result.childNodes[0];
             var resulttext=resultChildNode.nodeValue;

             var exitcode=ruleres.getElementsByTagName("exitcode")[0];
             var exitcodeChildNode=exitcode.childNodes[0];
             var exitcodetext=exitcodeChildNode.nodeValue;
             var color="<font color=green>";
             if (exitcodetext!=0){
                color="<font color=red>";
                fail++;
             }
             else{
                ok++;
             }
             if (exitcodetext==1){
                color="<font color=#D7AD08>";
             }
             if (exitcodetext==2){
                warn++;
             }
             r.innerHTML+=labeltext+": "+color+resulttext+"</font><br>";

             var qmsg=ruleres.getElementsByTagName("qmsg");

             if (qmsg.length>0){
                r.innerHTML+="<ul>";
                for(eid=0;eid<qmsg.length;eid++){
                   var qmsgChildNode=qmsg[eid].childNodes[0];
                   var qmsgtext=qmsgChildNode.nodeValue;
                   r.innerHTML+="<li>"+qmsgtext+"</li>";
                  
                }
                r.innerHTML+="</ul>";
             }
          }
          var r=document.getElementById("summary");
          if (r){
             var t="R:"+results.length+"/<font color=green>"+ok+"</font>";
             if (warn>0){
                 t+="/<font color=orange>"+warn+"</font>";
             }
             if (fail>0){
                 t+="/<font color=red>"+fail+"</font>";
             }
             if (r.innerHTML!=t){
                r.innerHTML=t;
             }
          }
       }
       else{
          r.innerHTML="no rules defined";
          var r=document.getElementById("summary");
          if (r){
             var t="-";
             if (r.innerHTML!=t){
                r.innerHTML=t;
             }
          }
       }
    }
   }
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=xmlhttp.send('Mode=process&CurrentIdToEdit='+$CurrentIdToEdit);
}
function processCheck()
{
   var r=document.getElementById("reslist");
   r.innerHTML="";
   addToResult(1);
}
addEvent(window,"load",processCheck);

</script>
EOF

   $d.=$self->HtmlBottom(body=>1,form=>1);



   return($d);
}

   



1;
