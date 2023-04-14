package itil::applcitransfer;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                group         =>'source',
                dataobjattr   =>'applcitransfer.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::TextDrop(
                name          =>'eappl',
                htmlwidth     =>'250px',
                label         =>'emitting Application',
                vjoineditbase =>{'cistatusid'=>"4"},
                vjointo       =>'itil::appl',
                vjoinon       =>['eapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'eapplid',
                label         =>'emitting Application ID',
                selectfix     =>1,
                dataobjattr   =>'applcitransfer.eappl'),

      new kernel::Field::TextDrop(
                name          =>'cappl',
                htmlwidth     =>'250px',
                label         =>'collecting Application',
                vjoineditbase =>{'cistatusid'=>"4"},
                vjointo       =>'itil::appl',
                vjoinon       =>['capplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'capplid',
                label         =>'collecting Application ID',
                selectfix     =>1,
                dataobjattr   =>'applcitransfer.cappl'),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'applcitransfer.comments'),
                                                   
      new kernel::Field::Textarea(
                name          =>'configitems',
                label         =>'Config-Item adresses',
                group         =>'transitems',
                searchable    =>0,
                dataobjattr   =>'applcitransfer.configitems'),

      new kernel::Field::Contact(
                name          =>'eapplackuser',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approver',
                vjoinon       =>'eapplackuserid'),

      new kernel::Field::Interface(
                name          =>'eapplackuserid',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approve userid',
                dataobjattr   =>'applcitransfer.eappl_ack_user'),

      new kernel::Field::Date(
                name          =>'eapplackdate',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approve date',
                dataobjattr   =>'applcitransfer.eappl_ack_date'),

      new kernel::Field::Textarea(
                name          =>'eapplackcmnt',
                group         =>'eapprove',
                htmldetail    =>'NotEmpty',
                label         =>'emitting application approve comment',
                dataobjattr   =>'applcitransfer.eappl_ack_cmnt'),



      new kernel::Field::Contact(
                name          =>'capplackuser',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approver',
                vjoinon       =>'capplackuserid'),

      new kernel::Field::Interface(
                name          =>'capplackuserid',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approve userid',
                dataobjattr   =>'applcitransfer.cappl_ack_user'),

      new kernel::Field::Date(
                name          =>'capplackdate',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approve date',
                dataobjattr   =>'applcitransfer.cappl_ack_date'),

      new kernel::Field::Textarea(
                name          =>'capplackcmnt',
                group         =>'capprove',
                htmldetail    =>'NotEmpty',
                label         =>'collecting application approve comment',
                dataobjattr   =>'applcitransfer.cappl_ack_cmnt'),

      new kernel::Field::Date(
                name          =>'transferdt',
                group         =>'transfer',
                htmldetail    =>'NotEmpty',
                label         =>'Transferdate',
                dataobjattr   =>'applcitransfer.transferdt'),

      new kernel::Field::Textarea(
                name          =>'transferlog',
                group         =>'transfer',
                htmldetail    =>'NotEmpty',
                label         =>'Transferlog',
                dataobjattr   =>'applcitransfer.transferlog'),

                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'applcitransfer.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'applcitransfer.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'applcitransfer.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'applcitransfer.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'applcitransfer.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"applcitransfer.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(applcitransfer.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'applcitransfer.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'applcitransfer.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'applcitransfer.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'applcitransfer.realeditor'),
   

   );
   $self->LoadSubObjs("ext/finishCITransfer","finishCITransfer");
   $self->setDefaultView(qw(eappl cappl cdate));
   $self->setWorktable("applcitransfer");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/applcitransfer.jpg?".$cgi->query_string());
#}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   #printf STDERR ("fifi SecureValidate newrec=%s\n",Dumper($newrec));

   return($self->SUPER::SecureValidate($oldrec,$newrec));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec) && !exists($newrec->{configitems})){
      my $eapplid=effVal($oldrec,$newrec,"eapplid");
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>\$eapplid});
      my ($eapplrec)=$o->getOnlyFirst(qw(systems swinstances applurl));

      my %ci;
      foreach my $srec (@{$eapplrec->{systems}}){
         next if ($srec->{'reltyp'} ne 'direct'); # only direct can be switched
         $ci{'w5base://itil::system/Show/'.$srec->{systemid}."/name"}++;
      }
      foreach my $srec (@{$eapplrec->{swinstances}}){
         $ci{'w5base://itil::swinstance/Show/'.$srec->{id}."/fullname"}++;
      }
      foreach my $srec (@{$eapplrec->{applurl}}){
         $ci{'w5base://itil::lnkapplurl/Show/'.$srec->{id}."/fullname"}++;
      }
      $newrec->{configitems}=join("\n",sort(keys(%ci)));
   }



   #my $a=$self->extractAdresses(effVal($oldrec,$newrec,"configitems"));

   return(1);
}


sub ProcessTransfer
{
   my $self=shift;
   my $tlog=shift;
   my $rec=shift;
   my $eappl=shift;
   my $cappl=shift;


   my $items=$self->extractAdresses($rec->{'configitems'});

   my $newdatabossid=$cappl->{databossid};
   my $newapplid=$cappl->{id};


   my $lc=getModuleObject($self->Config,"base::lnkcontact");
   if (exists($items->{"itil::lnkapplurl"})){
      my $o=getModuleObject($self->Config,"itil::lnkapplurl");
      my @ids=@{$items->{"itil::lnkapplurl"}};
      $o->SetFilter({id=>\@ids});
      foreach my $oldrec ($o->getHashList(qw(ALL))){
         if ($newapplid ne ""){
            my $op=$o->Clone();
            push(@$tlog,"set new applid on lnkapplurl ".
                        "$oldrec->{id} : $oldrec->{fullname}");
            $op->ValidatedUpdateRecord($oldrec,
               {applid=>$newapplid},
               {id=>$oldrec->{id}}
            );
         }
         if ($newapplid ne ""){
            foreach my $submod (sort(keys(%{$self->{finishCITransfer}}))){
               $self->{finishCITransfer}->{$submod}->ProcessTransfer(
                  'itil::lnkapplurl',
                  $oldrec->{id},
                  $oldrec->{applid},
                  $newapplid
               );
            }
         }
      }
   }
   if (exists($items->{"itil::swinstance"})){
      my $o=getModuleObject($self->Config,"itil::swinstance");
      my @ids=@{$items->{"itil::swinstance"}};
      $o->SetFilter({id=>\@ids});
      foreach my $oldrec ($o->getHashList(qw(ALL))){
         if ($newdatabossid ne ""){
            my $op=$o->Clone();
            push(@$tlog,"databoss set on swinstance ".
                        "$oldrec->{id} : $oldrec->{fullname}");
            $op->ValidatedUpdateRecord($oldrec,
               {databossid=>$newdatabossid},
               {id=>$oldrec->{id}}
            );
         }
         if ($newapplid ne ""){
            my $op=$o->Clone();
            push(@$tlog,"set new applid on swinstance ".
                        "$oldrec->{id} : $oldrec->{fullname}");
            $op->ValidatedUpdateRecord($oldrec,
               {applid=>$newapplid},
               {id=>$oldrec->{id}}
            );
         }
         if ($newapplid ne ""){
            foreach my $submod (sort(keys(%{$self->{finishCITransfer}}))){
               $self->{finishCITransfer}->{$submod}->ProcessTransfer(
                  'itil::swinstance',
                  $oldrec->{id},
                  $oldrec->{applid},
                  $newapplid
               );
            }
         }
      }
   }
   if (exists($items->{"itil::system"})){
      my $o=getModuleObject($self->Config,"itil::system");
      my $lsys=getModuleObject($self->Config,"itil::lnkapplsystem");
      my @ids=@{$items->{"itil::system"}};
      $o->SetFilter({id=>\@ids});
      foreach my $oldrec ($o->getHashList(qw(ALL))){
         if ($newdatabossid ne ""){
            my $op=$o->Clone();
            push(@$tlog,"databoss set on system ".
                        "$oldrec->{id} : $oldrec->{fullname}");
            $op->ValidatedUpdateRecord($oldrec,
               {databossid=>$newdatabossid},
               {id=>$oldrec->{id}}
            );
         }
         $lsys->ResetFilter();
         $lsys->SetFilter({applid=>[$eappl->{id}],systemid=>[$oldrec->{id}]});
         foreach my $lrec ($lsys->getHashList(qw(ALL))){
            my $op=$lsys->Clone();
            if ($lrec->{id} eq ""){  # maybe a cluster or swinstance relation
               push(@$tlog,"skip transfer appl for system ".
                           "$oldrec->{id} : $lrec->{fullname}");
               next;
            }
            push(@$tlog,"transfer appl for system ".
                        "$oldrec->{id} : $oldrec->{fullname}");

            my $chkop=$lsys->Clone();
            $chkop->ResetFilter();
            $chkop->SetFilter({applid=>[$cappl->{id}],systemid=>[$oldrec->{id}]});
            my ($curlinked)=$chkop->getOnlyFirst(qw(ALL));


            if (defined($curlinked)){
               $op->ValidatedDeleteRecord($oldrec);
            }
            else{
               $op->ValidatedUpdateRecord($oldrec,
                  {applid=>$cappl->{id}},
                  {id=>$lrec->{id}}
               );
            }
         }
         foreach my $crec (@{$oldrec->{contacts}}){
            push(@$tlog,"delete contact ".$crec->{targetname}." system ".
                        ": $oldrec->{name}");
            $lc->ValidatedDeleteRecord($crec);
         }
         if (1){
            my $op=$o->Clone();
            push(@$tlog,"add default contacts from appl to ".
                        "$oldrec->{name}");
            $op->addDefContactsFromAppl($oldrec->{id},$cappl);
         }
         if ($newapplid ne ""){
            foreach my $submod (sort(keys(%{$self->{finishCITransfer}}))){
               $self->{finishCITransfer}->{$submod}->ProcessTransfer(
                  'itil::system',
                  $oldrec->{id},
                  $eappl->{id},
                  $cappl->{id}
               );
            }
         }
      }
   }


   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!defined($oldrec)){
      my $eapplid=$newrec->{eapplid};
      my $capplid=$newrec->{capplid};
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>[$eapplid,$capplid]});
      my @l=$o->getHashList(qw(ALL));
      my $capplname;
      my $eapplname;
      foreach my $arec (@l){
         $capplname=$arec->{name} if ($arec->{id} eq $capplid);
         $eapplname=$arec->{name} if ($arec->{id} eq $eapplid);
      }

      foreach my $arec (@l){
         my $direction;
         if ($eapplid==$arec->{id}){
            $direction="EApprove";
         }
         if ($capplid==$arec->{id}){
            $direction="CApprove";
         }

         $o->NotifyWriteAuthorizedContacts($arec,{},{
                  dataobj=>$self->Self,
                  emailbcc=>11634953080001,
                  dataobjid=>effVal($oldrec,$newrec,"id"),
                  emailcategory=>'CITransfer'
               },{},sub{
            my ($subject,$ntext);
            my $subject=$self->T("CI Trans $direction",'itil::applcitransfer');
            if ($direction eq "CApprove"){
               $subject.=" ".$capplname;
            }
            if ($direction eq "EApprove"){
               $subject.=" ".$eapplname;
            }
            my $ntext=$self->T("Dear databoss",'kernel::QRule');
            $ntext.=",\n\n";

            $ntext.=$self->getParsedTemplate(
                    "tmpl/applcitransfer.".$direction.".prolog",
               {
                  static  =>{
                           CAPPL=>$capplname,
                           EAPPL=>$eapplname
                  }
               }
            );
            #$ntext.="\n\n";

            my $baseurl=$ENV{SCRIPT_URI};
            $baseurl=~s#/(auth|public)/.*$##;
            my $jobbaseurl=$self->Config->Param("EventJobBaseUrl");
            if ($jobbaseurl ne ""){
               $jobbaseurl=~s#/$##;
               $baseurl=$jobbaseurl;
            }
            my $url=$baseurl;
            if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
               $url=~s/^http:/https:/i;
            }
            $url.="/auth/itil/applcitransfer/".$direction."/".$newrec->{id};
            $ntext.="ApprovalLink:\n".$url."\n\n\n";

            my $htmlCIs=$newrec->{configitems};
            $htmlCIs=$self->ExpandW5BaseDataLinks("HtmlMail",$htmlCIs);
            $ntext.="ConfigItems:\n".$htmlCIs."\n\n";

            $ntext.="\n";

            $ntext.="DirectLink:";
            return($subject,$ntext);
         });
      }
   }

   if (effVal($oldrec,$newrec,"eapplackdate") ne "" &&
       effVal($oldrec,$newrec,"capplackdate") ne "" &&
       effVal($oldrec,$newrec,"transferdt") eq ""){
      my $res;
      my $userid=$self->getCurrentUserId();
      my $id=effVal($oldrec,$newrec,"id");
      my %p=(eventname=>'Process_applcistransfer',
             spooltag=>'Process_applcistransfer-'.$id,
             redefine=>'1',
             retryinterval=>600,
             firstcalldelay=>10,
             eventparam=>$id,
             userid=>$userid);
      if (defined($res=$self->W5ServerCall("rpcCallSpooledEvent",%p)) &&
         $res->{exitcode}==0){
         msg(INFO,"Process_applcistransfer Event sent OK");
      }
      else{
         msg(ERROR,"Process_applcistransfer Event sent failed");
      }
   }
   return(1);
}









sub extractAdresses
{
   my $self=shift;
   my $text=shift;
   my %ci;

   my @l=split(/\n/,$text);

   foreach my $line (@l){
      if (my ($obj,$id)=$line=~m/^w5base:\/\/([^\/]+)\/[^\/]+\/([^\/]+)\/.+$/){
         $ci{$obj}=[] if (!exists($ci{$obj}));
         push(@{$ci{$obj}},$id) if (!in_array($ci{$obj},$id));
      }
      elsif (my ($obj,$id)=$line=~m/^(.*)::(.*)$/){
         $ci{$obj}=[] if (!exists($ci{$obj}));
         push(@{$ci{$obj}},$id) if (!in_array($ci{$obj},$id));
      }
   }

   return(\%ci);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   #printf STDERR ("fifi FinishDelete oldrec=%s\n",Dumper($oldrec));

   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default");
   return(undef);
}

sub isCopyValid
{
   my $self=shift;

   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default eapprove capprove transitems transfer source));
}



sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),
           "EApprove","CApprove","Approve");
}


sub Approve
{
   my $self=shift;

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css' ],
                           submodal=>1,
                           js=>['toolbox.js','subModal.js','kernel.App.Web.js'],
                           body=>1,form=>1);

   my $id=Query->Param("id");
   my $mode=Query->Param("mode");
 
   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my ($rec)=$self->getOnlyFirst(qw(ALL));

   if (!defined($rec)){
      print $self->noAccess();
      return();
   }

   if (Query->Param("save")){
      my $doit=Query->Param("doit");
      if ($doit eq ""){
         $self->LastMsg(ERROR,"approve check box not checked");
      }
      else{
         # save approve
         my $userid=$self->getCurrentUserId();
         my %updrec;
         if ($mode eq "EApprove"){
            if ($rec->{eapplackdate} eq ""){
               %updrec=(
                  eapplackuserid=>$userid,
                  eapplackdate=>NowStamp("en") 
               );
            }
         }
         if ($mode eq "CApprove"){
            if ($rec->{capplackdate} eq ""){
               %updrec=(
                  capplackuserid=>$userid,
                  capplackdate=>NowStamp("en") 
               );
            }
         }
         if (keys(%updrec)){
            $self->ValidatedUpdateRecord($rec,\%updrec,{id=>$rec->{id}});
         }

         # reread rec
         $self->ResetFilter();
         $self->SetFilter({id=>\$id});
         ($rec)=$self->getOnlyFirst(qw(ALL));
      }
   }



   printf("<div style=\"width:80%;min-width:200px;max-width:500px;".
          "margin:auto\">");


   print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".header",
      {
         static  =>{
                  CAPPL=>$rec->{cappl},
                  EAPPL=>$rec->{eappl}
         }
      }
   ));
   #
   #
   #
   print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".prolog",
      {
         static  =>{
                  CAPPL=>$rec->{cappl},
                  EAPPL=>$rec->{eappl}
         }
      }
   ));
   if ($mode eq "EApprove"){
      if ($rec->{eapplackdate} eq ""){
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".edit",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl}
               }
            }
         ));
      }
      else{
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".show",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl},
                        CAPPLACKUSER=>$rec->{capplackuser},
                        CAPPLACKDATE=>$rec->{capplackdate},
                        EAPPLACKUSER=>$rec->{eapplackuser},
                        EAPPLACKDATE=>$rec->{eapplackdate}
               }
            }
         ));
      }
   }
   if ($mode eq "CApprove"){
      if ($rec->{capplackdate} eq ""){
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".edit",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl}
               }
            }
         ));
      }
      else{
         print($self->getParsedTemplate("tmpl/applcitransfer.".$mode.".show",
            {
               static  =>{
                        CAPPL=>$rec->{cappl},
                        EAPPL=>$rec->{eappl},
                        CAPPLACKUSER=>$rec->{capplackuser},
                        CAPPLACKDATE=>$rec->{capplackdate},
                        EAPPLACKUSER=>$rec->{eapplackuser},
                        EAPPLACKDATE=>$rec->{eapplackdate}
               }
            }
         ));
      }
   }
   ######################################################################

   printf("<br>\n");
   printf("<div style=\"border-style:solid;border-width:1px;".
          "overflow:auto;height:100px;padding-left:5px\">\n");
   my $htmlConfigItems=$rec->{configitems};
   $htmlConfigItems=~s/\n/<br>\n/g;
   $htmlConfigItems=$self->ExpandW5BaseDataLinks("HtmlDetail",$htmlConfigItems);
   printf("%s",$htmlConfigItems);
   printf("</div>");
   printf("<br>\n");


   ######################################################################

   print($self->getParsedTemplate("tmpl/applcitransfer.signaturetext",
      {
         static  =>{
                  CAPPL=>$rec->{cappl},
                  RAPPL=>$rec->{cappl}
         }
      }
   ));


   printf("</div>");
   print $self->HtmlPersistentVariables("id","mode");
   print $self->HtmlBottom(body=>1,form=>1);
}





sub EApprove
{
   my $self=shift;

   my ($func,$p)=$self->extractFunctionPath();

   if ($p ne ""){
      $p=~s/[^0-9]//g;
      $self->HtmlGoto("../Approve",post=>{id=>$p,mode=>$func});
      return();
   }
   print $self->noAccess();
   return();
}


sub CApprove
{
   my $self=shift;

   my ($func,$p)=$self->extractFunctionPath();

   if ($p ne ""){
      $p=~s/[^0-9]//g;
      $self->HtmlGoto("../Approve",post=>{id=>$p,mode=>$func});
      return();
   }
   print $self->noAccess();
   return();
}









1;
