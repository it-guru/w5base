package base::workflow::mailsend;
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
use kernel::WfClass;
@ISA=qw(kernel::WfClass);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{_permitted}->{to}=1;
   $self->AddFields(
      new kernel::Field::Email(   name        =>'emailto',
                                  valign      =>'top',
                                  label       =>'Mail Target Address',
                                  group       =>'mailsend',
                                  translation =>'base::workflow::mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Email(   name        =>'emailfrom',
                                  label       =>'Mail From Address',
                                  group       =>'mailsend',
                                  translation =>'base::workflow::mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Email(   name        =>'emailcc',
                                  label       =>'Mail CC Address',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Email(   name        =>'emailbcc',
                                  label       =>'Mail BCC Address',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),
   );
   return($self);
}

sub Init
{
   my $self=shift;

   $self->AddFields(
   );

   $self->AddGroup("mailsend",translation=>'base::workflow::mailsend');
}


sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my $class;

   return($self->InitFields(   
      new kernel::Field::Text(    name        =>'emailtemplate',
                                  label       =>'Template',
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'emailsignatur',
                                  label       =>'Signatur',
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'skinbase',
                                  label       =>'Skin Base',
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'emaillang',
                                  label       =>'Mail Language',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),
                                             
      new kernel::Field::Text(    name        =>'emailcategory',
                                  label       =>'Mail Category',
                                  group       =>'mailsend',
                                  htmldetail  =>0,
                                  container   =>'headref'),
                                             
      new kernel::Field::Textarea(name        =>'emailhead',
                                  uivisible   =>0,
                                  label       =>'Mail head',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailtext',
                                  label       =>'Mail Text',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailplaintext',
                                  label       =>'Mail Plain Text',
                                  group       =>'mailsend',
                                  htmldetail  =>0,
                                  depend      =>[qw(emailtext)],
                                  onRawValue  =>sub {
                                     my $self=shift;
                                     my $current=shift;
                                     my $mode=shift;
                                     my $fld=$self->getParent->getField(
                                                    "emailtext",$current);
                                     if (defined($fld)){
                                        my $data=$fld->RawValue($current);
                                        $data=~s/<[^>]*>//g;
                                        return($data);
                                     }
                                     return("");
                                  }),

      new kernel::Field::Textarea(name        =>'emailbottom',
                                  uivisible   =>0,
                                  label       =>'Mail bottom',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailtstamp',
                                  label       =>'Mail tstamp',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailprefix',
                                  label       =>'Mail prefix',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailpostfix',
                                  label       =>'Mail postfix',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailsep',
                                  label       =>'Mail sperator',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailsubtitle',
                                  label       =>'Mail SubTitle',
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'emailsubheader',
                                  label       =>'Mail SubHeader',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Date(    name        =>'terminstart',
                                  label       =>'Mail termin request start',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Date(    name        =>'terminend',
                                  label       =>'Mail termin request end',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Text(    name        =>'terminlocation',
                                  label       =>'Mail termin location',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Number(  name        =>'terminnotify',
                                  label       =>'Mail termin notify',
                                  unit        =>'min',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Boolean( name        =>'noautobounce',
                                  label       =>'no automatic bounce handling',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Boolean( name        =>'allowsms',
                                  label       =>'allow SMS send',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),

      new kernel::Field::Textarea(name        =>'smstext',
                                  label       =>'alternate SMS Text',
                                  uivisible   =>0,
                                  group       =>'mailsend',
                                  container   =>'headref'),
     )
  );
}


sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "shortactionlog");
   return(1) if ($name eq "relations");
   return($self->SUPER::isOptionalFieldVisible($mode,@_));
}



sub IsModuleSelectable
{
   my $self=shift;
   my $to=$self->to;
  # return(1) if ($self->getParent->IsMemberOf("admin"));
   if (ref($to) eq "ARRAY"){
      my @view=$self->getParent->getCurrentView();
      foreach my $t (@$to){
         return(1) if (grep(/^$t$/,@view));
      }
      return(0);
   }
   return(0);
}

sub InitWorkflow
{
   my $self=shift;

   # Standard Init
   Query->Param("WorkflowClass"=>$self->Self);
   Query->Param("WorkflowStepList"=>"");
   Query->Param("AllowClose"=>"1");

   # Datensammlung
   my %q=$self->getParent->getSearchHash();
   $self->getParent->SetFilter(\%q);
   my %email=();
   map({
          $email{$_->{email}}={} if ($_->{email} ne "");
       } 
       $self->getParent->getHashList("email"));
   Query->Param("to"=>[keys(%email)]);
   print $self->getParent->HtmlPersistentVariables(qw(to));
   printf("fifi email=%s<br>\n",join(",",keys(%email)));
   printf("fifi workflowclass=%s<br>\n",$self->Self);
   printf("<br>... hier muß noch was gemacht werden<br>\n");
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","state","flow","mailsend","header","relations");
}

sub getDetailBlockPriority            # posibility to change the block order
{
   return("default","state","mailsend","flow","relations");
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(1) if (!defined($rec));
   return(undef);
   return("default","mailsend");
}


sub getNextStep
{
   my $self=shift;
   my $currentstep=shift;
   my $WfRec=shift;

   if ($currentstep eq "base::workflow::mailsend::dataload"){
      return("base::workflow::mailsend::verify"); 
   }
   elsif($currentstep eq "base::workflow::mailsend::verify"){
      return("base::workflow::mailsend::waitforspool"); 
   }
   elsif($currentstep eq "base::workflow::mailsend::finish"){
      return("base::workflow::mailsend::finish"); 
   }
   elsif($currentstep eq ""){
      return("base::workflow::mailsend::dataload"); 
   }
   return(undef);
}


sub getHtmlDetailPageContent
{
   my $self=shift;
   my ($p,$rec)=@_;
   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "FView");
   my $page;
   my $idname=$self->IdField->Name();
   my $idval=$rec->{$idname};

   if ($p eq "FView"){
      Query->Param("$idname"=>$idval);
      $idval="NONE" if ($idval eq "");

      my $q=new kernel::cgi({});
      $q->Param("$idname"=>$idval);
      my $urlparam=$q->QueryString();

      $page="<iframe style=\"width:100%;height:100%;border-width:0;".
            "padding:0;margin:0\" class=HtmlDetailPage name=HtmlDetailPage ".
            "src=\"WorkflowSpecView?$urlparam\"></iframe>";
   }
   $page.=$self->HtmlPersistentVariables($idname);
   return($page);
}

sub getHtmlDetailPages
{
   my $self=shift;
   my ($p,$rec)=@_;

   return($self->SUPER::getHtmlDetailPages($p,$rec),
          "WorkflowSpecView"=>$self->T("FView"));
}

sub WorkflowSpecView
{
   my $self=shift;
   my $WfRec=shift;
   my $d="<div id=ViewDiv style=\"overflow:auto\">";
   $d.="<div style=\"".
         "border-style:none;text-align:left;".
         "margin:10px;padding:5px\">";
   my %param;
   my %tr=('emailto'=>'to',
           'name'=>'subject',
           'wffields.emailprefix'=>'emailprefix',
           'wffields.emailtext'=>'emailtext',
           'wffields.emailsubheader'=>'emailsubheader',
           'wffields.emailsep'=>'emailsep',
           'emailfrom'=>'from',
           'emailcc'=>'cc');
   foreach my $fldname (keys(%tr)){
      my $fo=$self->getField($fldname,$WfRec);
      if ($fo){
         my $v=$fo->RawValue($WfRec);
         $param{$tr{$fldname}}=$v;
      }
   }

   $d.=$self->generateNotificationPreview(%param,nolabel=>1);
   $d.="</div>";
   $d.="</div>";
   $d.=<<EOF;
<script language="JavaScript">
function resize()
{
   var h=getViewportHeight();
   var w=getViewportWidth();
   var d=document.getElementById("ViewDiv");
   var ModeSelect=document.getElementById("ModeSelect");
   d.style.width=w-8+"px";
   d.style.height=h-ModeSelect.offsetHeight+"px";
}
addEvent(window, "load",   resize);
addEvent(window, "resize",   resize);
</script>
<style>
\@media print {
   body{
      background: #FFFFFF;
   }
   #ViewDiv{
      height:auto;
   }
}

</style>
EOF
   return($d);
}






#######################################################################
package base::workflow::mailsend::dataload;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
use Data::Dumper;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my @currentemaillist=Query->Param("Formated_emailto");
   if ($#currentemaillist==-1){
      if (ref($WfRec->{emailto}) eq "ARRAY"){
         push(@currentemaillist,@{$WfRec->{emailto}});
      }
      else{
         push(@currentemaillist,$WfRec->{emailto});
      }
   }
   my $emptycount=0;
   map({$emptycount++ if ($_=~m/^\s*$/);} @currentemaillist);
   for(;$emptycount<3;$emptycount++){
      push(@currentemaillist,"");
   }
   my $templ=<<EOF;
<table border=0 cellspacing=0 cellpadding=0 width=100%>
EOF
   foreach my $emailto (@currentemaillist){
      my $input=$self->getField("emailto")->getSimpleTextInputField($emailto);
      $templ.="<tr><td width=1% nowrap class=fname>%emailto(label)%:</td>".
              "<td class=finput>$input</td></tr>";
   }

   $templ.=<<EOF;
<tr>
<td class=fname>%name(label)%:</td>
<td class=finput>%name(detail)%</td>
</tr>
<tr>
<td colspan=2 class=fname>%emailtext(label)%:<br>
%emailtext(detail)%</td>
</tr>
</table>
EOF
   return($templ);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   foreach my $v (qw(name emailtext)){
      if ((!defined($oldrec) || exists($newrec->{$v})) && $newrec->{$v} eq ""){
         $self->LastMsg(ERROR,"field '%s' is empty",
                        $self->getField($v)->Label());
         return(0);
      }
   }
   if ((!defined($oldrec) || exists($newrec->{"emailto"}) ||
                             exists($newrec->{"emailbcc"}))){
      if (ref($newrec->{emailto}) ne "ARRAY"){
         $newrec->{emailto}=[$newrec->{emailto}];
      }
      if (ref($newrec->{emailbcc}) ne "ARRAY"){
         $newrec->{emailbcc}=[$newrec->{emailbcc}];
      }
      if (ref($newrec->{emailcc}) ne "ARRAY"){
         $newrec->{emailcc}=[$newrec->{emailcc}];
      }
      my %u=();
      map({trim(\$_);$u{$_}=1; } @{$newrec->{emailto}});
      @{$newrec->{emailto}}=grep(!/^\s*$/,sort(keys(%u)));
      if ($#{$newrec->{emailto}}==-1 &&
          (!exists($newrec->{emailbcc}) || $#{$newrec->{emailbcc}}==-1) &&
          (!exists($newrec->{emailcc}) || $#{$newrec->{emailcc}}==-1)){
         $self->LastMsg(ERROR,"missing any target address in mailheader");
         return(0);
      }
   }
   if (!defined($oldrec) && !exists($newrec->{emailfrom})){
      my $UserCache=$self->Cache->{User}->{Cache};
      if (defined($UserCache->{$ENV{REMOTE_USER}})){
         $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
      }
      if (defined($UserCache->{userid})){
         my $fakeFrom=$UserCache->{fullname};
         $fakeFrom=~s/"//g;
         $fakeFrom="\"$fakeFrom\" <>";   # fake from to 
         $newrec->{emailfrom}=$fakeFrom; # prevent "out of office" notices
      }
   }
   $newrec->{step}=$self->getNextStep();
   $newrec->{stateid}=1;
   $newrec->{eventstart}=NowStamp("en");
   $newrec->{eventend}=undef;
   $newrec->{closedate}=undef;
   if (!defined($newrec->{emailtemplate}) || $newrec->{emailtemplate} eq ""){
      $newrec->{emailtemplate}="sendmail";
   }
   if (!defined($newrec->{skinbase}) || $newrec->{skinbase} eq ""){
      $newrec->{skinbase}="base";
   }
   return(1);
}

sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep" || $action eq "Store"){
      if (my $id=$self->StoreRecord($WfRec,$h)){
         $h->{id}=$id;
         return(1);
      }
      return(0);
   }


   return(undef);
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      my $h=$self->getWriteRequestHash("web");
      return($self->nativProcess($action,$h,$WfRec,$actions));
   }
   if ($action eq "BreakWorkflow"){
      if (!$self->StoreRecord($WfRec,{
                                step=>'base::workflow::mailsend::break',
                                stateid=>17})){
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}


#######################################################################
package base::workflow::mailsend::verify;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;

   my $templ=<<EOF;
<br><div class=Question><table border=0><tr>
<td><input type=checkbox name=go></td>
<td>Ja, ich bin sicher, dass ich die Mail versenden möchte.</td>
</tr></table></div>
EOF
   return($templ);
}

sub nativProcess
{
   my $self=shift;
   my $action=shift;
   my $h=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "Send"){
      if (my $id=$self->StoreRecord($WfRec,
             {step=>'base::workflow::mailsend::waitforspool'})){
         return(1);
      }
      return(0);
   }


   return($self->SUPER::nativProcess($action,$h,$WfRec,$actions));
}

sub Process
{
   my $self=shift;
   my $action=shift;
   my $WfRec=shift;
   my $actions=shift;

   if ($action eq "NextStep"){
      if (defined(Query->Param("go"))){
         if (!$self->StoreRecord($WfRec,{step=>$self->getNextStep()})){
            # no step change on error - error message in LastMsg
            return(0);
         }
         return(1);
      }
      else{
         $self->LastMsg(ERROR,"no confirmation recieved");
         return(0);
      }
   }
   if ($action eq "BreakWorkflow"){
      if (!$self->StoreRecord($WfRec,{
                                step=>'base::workflow::mailsend::break',
                                stateid=>22})){
         return(0);
      }
      return(1);
   }
   return($self->SUPER::Process($action,$WfRec,$actions));
}


#######################################################################
package base::workflow::mailsend::waitforspool;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   return(undef) if (!defined($oldrec));
   $newrec->{stateid}=6;

   return(1); 
}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $res=$self->W5ServerCall("rpcCallEvent","sendmail",$oldrec->{id});
   if (defined($res) && $res->{exitcode}==0){
       #$self->StoreRecord($WfRec,{state=>5}); 
      msg(DEBUG,"W5Server has been notify about mailsend\n")
   }
}



sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Waiting for processing by the mailspooler.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}




#######################################################################
package base::workflow::mailsend::finish;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Mail handling finished.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}

sub Validate
{
   my $self=shift;
   return(1);
}



#######################################################################
package base::workflow::mailsend::break;
use vars qw(@ISA);
use kernel;
use kernel::WfStep;
@ISA=qw(kernel::WfStep);

sub generateWorkspace
{
   my $self=shift;
   my $WfRec=shift;
   my $msg=$self->T("Mail not send.");
   my $templ=<<EOF;
<br><div class=Question><table border=0><tr><td>$msg</td></tr></table></div>
EOF
   return($templ);
}

sub getPosibleButtons
{
   my $self=shift;
   my $WfRec=shift;
   return();
}

sub getWorkHeight
{
   my $self=shift;
   my $WfRec=shift;

   return(100);
}


#######################################################################


1;
