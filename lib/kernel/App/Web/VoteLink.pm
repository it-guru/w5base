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

   my $reffield="faq.faqid";
   my $userid=$self->getCurrentUserId();
   my $selfname=$self->SelfAsParentObject();
   my $logstamp=$self->getLogStamp();

   $from.=" left outer join uservote ".
          "on (uservote.refid=${reffield} and ".
          "uservote.parentobj='${selfname}' and ".
          "uservote.createuser='${userid}' and ".
          "uservote.entrymonth='${logstamp}')";

   $from.=" left outer join uservote uv  ".
          "on (uv.refid=faq.faqid and uv.parentobj='${selfname}') ";


   return($from);
}

sub extendFieldDefinition
{
   my $self=shift;

   my $selfname=$self->SelfAsParentObject();
   my $sql=
      "(sum(uv.voteval/".   # factor user voting

      # factor age of uservoting
         "(".
         "if (datediff(now(),uv.createdate)=0,1,".
             "datediff(now(),uv.createdate))".
         "*".
         "if (datediff(now(),uv.createdate)=0,1,".
             "datediff(now(),uv.createdate))".
         "/(3.65*3.65))". 
         ")".
      ")";

   $sql="if (${sql} is null,0,${sql})".
       # factor age of parent record
 
        "+(if (365-datediff(now(),faq.modifydate)>-730,".
        "(365-datediff(now(),faq.modifydate)),-730))*1.37";

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

sub extendHtmlDetailPageContent
{
   my ($self,$base,$offset,$rec)=@_;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   return("") if (!defined($rec));

   $offset+=20;

   my $selfname=$self->SelfAsParentObject();
   $selfname=~s/::/\//g;

   my $initval=<<EOF;
<img onclick='doRecordVote(this,1);' 
     title='find ich wirklich gut' 
     src='$base/base/load/up-vote.gif' 
     width=28 height=28 border=0 
     style='margin:2px;margin-right:8px;cursor:pointer' >
<img onclick='doRecordVote(this,-1);' 
     title='find ich wirklich scheisse' 
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
   console.log('vote',path);
   xmlhttp.open('POST',path);
   xmlhttp.onreadystatechange=function() {
      if (this.readyState == 4 && this.status == 200) {
         var myArr = JSON.parse(this.responseText);
         e.innerHTML=myArr[0].html;  
         console.log(myArr);
      }
   };
   xmlhttp.send();
}
</script>
<div id=RecordVote style='position:absolute;bottom:${offset}px;right:20px;border-style:solid;border-width:1px;border-color:gray;border-radius:3px;background-color:silver'>${initval}</div>
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
