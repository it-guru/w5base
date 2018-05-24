package kernel::App::Web::VoteLink;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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

sub extendSqlFrom
{
   my $self=shift;
   my $from=shift;
   my $reffield=shift;

   my $userid=$self->getCurrentUserId();
   my $selfname=$self->SelfAsParentObject();
   my $logstamp=$self->getLogStamp();

   $from.=" left outer join uservote ".
          "on (uservote.refid=${reffield} and ".
          "uservote.parentobj='${selfname}' and ".
          "uservote.createuser='${userid}' and ".
          "uservote.entrymonth='${logstamp}')";

   my $sql=
      "sum(subuservote.voteval*".   # factor user voting

      # factor age of uservoting
         "(".
         "730/if (datediff(now(),subuservote.createdate)=0,1,".
             "if (datediff(now(),subuservote.createdate)>730,730,".
             "datediff(now(),subuservote.createdate)))/1".
         ")".
      ") as sumuservote";

   $from.=" left outer join (".
             "select ".
             "subuservote.refid,".
             "subuservote.parentobj,".
             "max(subuservote.voteval) voteval,".
             "$sql ".
             "from uservote subuservote ".
             "group by subuservote.refid) uv  ".
          "on (uv.refid=${reffield} and uv.parentobj='${selfname}') ";


   return($from);
}

sub resetVoteLink
{
   my $self=shift;
   my $refid=shift;

   my $selfname=$self->SelfAsParentObject();
   my $o=getModuleObject($self->Config,"base::uservote");
   $o->BulkDeleteRecord({refid=>\$refid,parentobj=>\$selfname});
}

sub extendFieldDefinition
{
   my $self=shift;

   my $selfname=$self->SelfAsParentObject();
   my $mdatefld=$self->getField("mdate");

   my $sql="if (uv.sumuservote is null,0,uv.sumuservote)";

   if (defined($mdatefld)){
      my $dobjattr=$mdatefld->{dataobjattr};
       # factor age of parent record
      $sql.="+(if (730-datediff(now(),$dobjattr)>-365,".
        "(730-datediff(now(),$dobjattr)),-365))*2.00";
   }

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'allow_uservote',
                group         =>'source',
                selectfix     =>1,
                label         =>'AllowUserVote',
                dataobjattr   =>'if (uservote.voteval is null,1,0)'),

      new kernel::Field::Number(
                name          =>'uservotelevel',
                group         =>'source',
                precision     =>0,
                searchable    =>0,
                selectfix     =>1,
                sqlorder      =>'desc',
                label         =>'UserVoteLevel',
                dataobjattr   =>"floor($sql)"),
   );


}

sub extendCurrentRating
{
   my $self=shift;
   my $vote=shift;

   my $html;

   if (defined($vote)){
      my $red=1;
      my $green=99;
      if ($vote<-900){
         $red=99;
      }
      elsif($vote<-50){
         $red=60;
      }
      elsif($vote<100){
         $red=20;
      }
      elsif($vote<500){
         $red=10;
      }
      my $green=100-$red;
      $html="<div style='float:clear'></div>".
            "<span title='QIndex:$vote'>".
            "<div style='width:100%;margin:0;padding:0'>".
            "<div style='float:left;marin:0;padding:0;width:${green}%;".
            "background-color:green;height:4px'>".
            "&nbsp;".
            "</div>".
            "<div style='float:left;marin:0;padding:0;width:${red}%;".
            "background-color:red;height:4px'>".
            "&nbsp;".
            "</div>".
            "</div></span>";
   }
   return($html);
}

sub extendHtmlDetailPageContent
{
   my ($self,$base,$offset,$rec)=@_;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   return("") if (!defined($rec));
   if ($ENV{REMOTE_USER} eq "anonymous" || $ENV{REMOTE_USER} eq ""){
      return("");
   }

   $offset+=20;

   my $selfname=$self->SelfAsParentObject();
   $selfname=~s/::/\//g;

   my $m1=$self->T("well documented and up to date record",
                   "kernel::App::Web::VoteLnk");

   my $m2=$self->T("record bad documented or out of date",
                   "kernel::App::Web::VoteLnk");

   my $initval=<<EOF;
<img onclick='doRecordVote(this,1);' title='$m1' 
     src='$base/base/load/up-vote.gif' 
     width=28 height=28 border=0 
     style='margin:2px;margin-right:8px;cursor:pointer' >
<img onclick='doRecordVote(this,-1);' title='$m2' 
     src='$base/base/load/down-vote.png' 
     style='margin:2px;cursor:pointer' width=28 height=28 border=0>
EOF


   if (!$rec->{allow_uservote}){
      $initval=
         "<img title='Analysing ...' ".
         " onload='doRecordVote(this,0);' ".
         "src='$base/base/load/loading.gif' ".
         "style='margin:2px;cursor:pointer' width=56 height=28 border=0>";
   }
   else{
      $initval.=$self->extendCurrentRating($rec->{uservotelevel});
   }

   my $jscode=<<EOF;
<script language=JavaScript>
function doRecordVote(parent,v){
   var e=document.getElementById('RecordVote');
   var uservote;
   var xmlhttp=getXMLHttpRequest();
   var path='$base/base/uservote/vote/$selfname/$idval/';
   if (v>0){
     uservote='pro';
   }
   else if (v<0){
     uservote='contra';
   }
   else{
     uservote='query';
   }
   path+=uservote;
   //console.log('vote',path);
   e.innerHTML='<img src="$base/base/load/loading.gif" '+
               'width=56 height=28 border=0>';
   xmlhttp.open('POST',path);
   xmlhttp.onreadystatechange=function() {
      if (this.readyState == 4 && this.status == 200) {
         var myArr = JSON.parse(this.responseText);
         var html=myArr[0].html;
         e.innerHTML=html.replace(/%ROOT%/,'$base');  
         //console.log(myArr);
      }
   };
   xmlhttp.send();
}
</script>
<div id=RecordVote style='position:absolute;text-align:center;bottom:${offset}px;padding:1px;right:20px;width:80px;height:40px;border-style:solid;border-width:1px;border-color:gray;border-radius:3px;background-color:silver'>${initval}</div>
EOF
   return($jscode);

}

sub getLogStamp{
   my $self=shift;
   my $stamp=substr(NowStamp("en"),0,7);

   return($stamp);
}


######################################################################

1;
