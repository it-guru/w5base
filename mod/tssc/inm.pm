package tssc::inm;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use tssc::lib::io;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tssc::lib::io);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'incidentnumber',
                sqlorder      =>'desc',
                searchable    =>1,
                label         =>'Incident No.',
                htmlwidth     =>'20',
                align         =>'left',
                dataobjattr   =>'problemm1.numberprgn'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Brief Description',
                ignorecase    =>1,
                dataobjattr   =>'problemm1.brief_description'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                htmlwidth     =>20,
                dataobjattr   =>'problemm1.status'),

      new kernel::Field::Text(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'problemm1.sw_name'),

      new kernel::Field::Text(
                name          =>'deviceid',
                label         =>'DeviceID',
                dataobjattr   =>'problemm1.logical_name'),

      new kernel::Field::Text(
                name          =>'custapplication',
                label         =>'Customer Application',
                dataobjattr   =>'probsummarym1.dsc_service'),

      new kernel::Field::Date(
                name          =>'cdate',
                timezone      =>'CET',
                label         =>'Created',
                dataobjattr   =>'probsummarym1.open_time'),

      new kernel::Field::Date(
                name          =>'downtimestart',
                timezone      =>'CET',
                label         =>'Downtime Start',
                dataobjattr   =>'problemm1.downtime_start'),

      new kernel::Field::Date(
                name          =>'downtimeend',
                timezone      =>'CET',
                label         =>'Downtime End',
                dataobjattr   =>'problemm1.downtime_end'),

      new kernel::Field::Textarea(
                name          =>'action',
                label         =>'Description',
                dataobjattr   =>'probsummarym1.action'),

      new kernel::Field::Textarea(
                name          =>'actionlog',
                label         =>'Actions',
                searchable    =>0,
                dataobjattr   =>'probsummarya5.update_action'),

      new kernel::Field::Textarea(
                name          =>'resolution',
                label         =>'Resolution',
                searchable    =>0,
                dataobjattr   =>'probsummarya1.resolution'),

      new kernel::Field::SubList(
                name          =>'history',
                label         =>'History',
                vjointo       =>'tssc::inm_assignment',
                vjoinon       =>['incidentnumber'=>'incidentnumber'],
                vjoininhash   =>['assignment','status'],
                vjoindisp     =>[qw(assignment status sysmodtime)]),

      new kernel::Field::Text(
                name          =>'hassignment',
                group         =>'status',
                label         =>'Home Assignment',
                dataobjattr   =>'problemm1.home_assignment'),

      new kernel::Field::Text(
                name          =>'iassignment',
                group         =>'status',
                label         =>'Initial Assignment',
                dataobjattr   =>'problemm1.initial_assignment'),

      new kernel::Field::Text(
                name          =>'rassignment',
                searchable    =>0,
                group         =>'status',
                depend        =>["history"],
                onRawValue    =>\&getResolvAssignment,
                label         =>'Resolved Assignment'),

      new kernel::Field::Text(
                name          =>'involvedassignment',
                searchable    =>0,
                group         =>'status',
                depend        =>["history"],
                onRawValue    =>\&getInvolvedAssignment,
                label         =>'Involved Assignment'),

      new kernel::Field::Text(
                name          =>'cassignment',
                group         =>'status',
                label         =>'Current Assignment',
                dataobjattr   =>'problemm1.assignment'),

      new kernel::Field::Text(
                name          =>'priority',
                group         =>'status',
                label         =>'Priority',
                dataobjattr   =>'problemm1.priority_code'),

      new kernel::Field::Select(
                name          =>'impact',
                group         =>'status',
                value         =>[qw(0 1 2 3 4)],
                transprefix   =>'impact.',
                label         =>'Business Impact',
                dataobjattr   =>'problemm1.business_impact'),
     
      new kernel::Field::Text(
                name          =>'causecode',
                group         =>'status',
                label         =>'Cause Code',
                dataobjattr   =>'problemm1.cause_code'),

      new kernel::Field::Text(
                name          =>'reason',
                group         =>'status',
                label         =>'Reason',
                dataobjattr   =>'problemm1.reason_type'),

      new kernel::Field::Text(
                name          =>'reasonby',
                group         =>'status',
                label         =>'Reason by',
                dataobjattr   =>'problemm1.reason_causedby'),

      new kernel::Field::Date(
                name          =>'sysmodtime',
                group         =>'status',
                timezone      =>'CET',
                label         =>'SysModTime',
                dataobjattr   =>'problemm1.sysmodtime'),

      new kernel::Field::Date(
                name          =>'createtime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Create time',
                dataobjattr   =>'problemm1.open_time'),

      new kernel::Field::Date(
                name          =>'closetime',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Closeing time',
                dataobjattr   =>'problemm1.close_time'),

      new kernel::Field::Date(
                name          =>'workstart',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work Start',
                dataobjattr   =>'problemm1.work_start'),

      new kernel::Field::Date(
                name          =>'workend',
                depend        =>['status'],
                group         =>'close',
                timezone      =>'CET',
                label         =>'Work End',
                dataobjattr   =>'problemm1.work_end'),

      new kernel::Field::Text(
                name          =>'reportedby',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Reported by',
                dataobjattr   =>'problemm1.reported_by'),

      new kernel::Field::Text(
                name          =>'openedby',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Opened by',
                dataobjattr   =>'problemm1.opened_by'),

      new kernel::Field::Text(
                name          =>'editor',
                uppersearch   =>1,
                group         =>'contact',
                label         =>'Editor',
                dataobjattr   =>'problemm1.sysmoduser'),

      new kernel::Field::Text(
                name          =>'contactlastname',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Contact Lastname',
                dataobjattr   =>'problemm1.contact_lastname'),

      new kernel::Field::Text(
                name          =>'contactname',
                ignorecase    =>1,
                group         =>'contact',
                label         =>'Contact Name',
                dataobjattr   =>'problemm1.contact_name'),

      new kernel::Field::Link(
                name          =>'page',
                dataobjattr   =>'problemm1.page'),
   );
   $self->AddFrontendFields(
      new kernel::Field::Text(
                name          =>'scname',
                label         =>'Short description'),

      new kernel::Field::Select(
                name          =>'scimpact',
                value         =>[qw(all.customer.fail
                                    all.customer.restricted
                                    some.customer.fail
                                    some.customer.restricted
                                    all.interfaces.fail
                                    all.interfaces.restricted
                                    some.interfaces.fail
                                    some.interfaces.restricted
                                    other.applications.fail
                                    other.applications.restricted
                                    onlyme
                                    none)],
                label         =>'Impact'),

      new kernel::Field::Select(
                name          =>'sctype',
                value         =>[qw(application.generic
                                    authorization
                                    interfaceproblem
                                    )],
                label         =>'Impact'),

      new kernel::Field::FlexBox(
                name          =>'sccustapplication',
                vjointo       =>'itil::appl',
                vjoindisp     =>'name',
                label         =>'Application'),

      new kernel::Field::Textarea(
                name          =>'scdescription',
                label         =>'Description'),
   );
   
   $self->{use_distinct}=0;

   $self->setDefaultView(qw(linenumber incidentnumber 
                            downtimestart downtimeend status name));
   return($self);
}

sub getResolvAssignment
{
   my $self=shift;
   my $current=shift;
   my $fo=$self->getParent->getField("history");
   my $l=$fo->RawValue($current);
   my $a;
   foreach my $rec (@$l){
      $a=$rec->{assignment} if ($rec->{status} eq "closed");
   }
   return($a); 
}

sub SetFilterForQualityCheck
{
   my $self=shift;
   my @view=@_;
   return(undef);
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/inm.jpg?".$cgi->query_string());
}

sub getInvolvedAssignment
{
   my $self=shift;
   my $current=shift;
   my $fo=$self->getParent->getField("history");
   my $l=$fo->RawValue($current);
   my %a;
   foreach my $rec (@$l){
      $a{$rec->{assignment}}=1;
   }
   return([sort(keys(%a))]); 
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),qw(status contact));
}



sub getSqlFrom
{
   my $self=shift;
   my $from="problemm1,probsummarym1,probsummarya1,probsummarya5";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="problemm1.numberprgn=probsummarym1.numberprgn AND ".
             "problemm1.numberprgn=probsummarya1.numberprgn AND ".
             "problemm1.numberprgn=probsummarya5.numberprgn AND ".
             "problemm1.lastprgn='t'";
   return($where);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $st;
   if (defined($rec)){
      $st=$rec->{status};
   }
   #if ($st ne "closed" && $st ne "rejected"){
   #   return(qw(contact default status header software device));
   #}
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getValidWebFunctions
{
   my $self=shift;
   return("Manager","Process",
          $self->SUPER::getValidWebFunctions());
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   trim($newrec) if (defined($newrec));
   my $name=$newrec->{"scname"};
   if (($name=~m/^\s*$/) || length($name)<10){
      $self->LastMsg(ERROR,"incident name invalid or to short");
      return(undef);
   }
   my $desc=$newrec->{"scdescription"};
   if (($desc=~m/^\s*$/) || length($desc)<20){
      $self->LastMsg(ERROR,"incident description invalid or to short");
      return(undef);
   }


   my $app=$newrec->{"sccustapplication"};
   if ($app ne ""){
      my $appl=getModuleObject($self->Config,"TS::appl");
      $appl->SetFilter({name=>\$app});
      my ($arec,$msg)=$appl->getOnlyFirst(qw(acapplname acinmassingmentgroup));
      if (!defined($arec)){
         $self->LastMsg(ERROR,"invalid application specified");
         return(undef);
      }
      if ($arec->{acapplname} eq ""){
         $self->LastMsg(ERROR,"can not detect the offizial applicationname");
         return(undef);
      }
      if ($newrec->{scapplname} eq ""){
         $newrec->{scapplname}=$arec->{acapplname};
      }
      if ($newrec->{scassingmentgroup} eq ""){
         if ($arec->{acinmassingmentgroup} eq ""){
            $self->LastMsg(ERROR,"no inm assignmentgroup for application");
            return(undef);
         }
         else{
            $newrec->{scassingmentgroup}=$arec->{acinmassingmentgroup};
         }
      }
   }
   else{
      $self->LastMsg(ERROR,"no application specified");
      return(undef);
   }
printf STDERR ("fifi Validate=%s\n",Dumper($newrec));
   return(1);
}


sub InsertRecord   # fake write request to SC
{
   my $self=shift;
   my $newrec=shift;
   my $IncidentNumber;

   my $userid=$self->getCurrentUserId();
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   my $username=$newrec->{'SCUsername'};
   delete($newrec->{'SCUsername'});
   my $password=$newrec->{'SCPassword'};
   delete($newrec->{'SCPassword'});
   msg(INFO,"start SC login for $ENV{REMOTE_USER}");
   my $sc=$self->getSC($username,$password);
   if (!defined($sc)){
      $self->LastMsg(ERROR,"ServiceCenter Login failed");
      return(undef);
   }
   msg(INFO,"start SC CreateIncident for $ENV{REMOTE_USER}");
   my %Incident=(
                 'brief.description'      =>$newrec->{scname},
                 'problem.shortname'      =>'TS_DE_BAMBERG_GUTENBERG_13',
                 'reported.shortname'     =>'TS_DE_BAMBERG_GUTENBERG_13',
                 'component.shortname'    =>'TS_DE_BAMBERG_GUTENBERG_13',
                 'contact.shortname'      =>'TS_DE_BAMBERG_GUTENBERG_13',
                 'dsc.device.city'        =>"Bamberg",
                 'dsc.contact.city'       =>"Bamberg",
                 'dsc.reported.city'      =>"Bamberg",
                 'dsc.device.zip'         =>"96050",
                 'dsc.contact.zip'        =>"96050",
                 'dsc.reported.zip'       =>"96050",
                 'dsc.device.street'      =>"Gutenbergstr. 13",
                 'dsc.contact.street'     =>"Gutenbergstr. 13",
                 'dsc.reported.street'    =>"Gutenbergstr. 13",
                 'dsc.device.company'     =>"T-Systems International GmbH",
                 'dsc.contact.company'    =>"T-Systems International GmbH",
                 'dsc.reported.company'   =>"T-Systems International GmbH",
                 'contact.company'        =>"T-Systems International GmbH",
                 'contact.country.code'   =>"DE",
                 'component.country.code' =>"DE",
                 'reported.country.code'  =>"DE",
                 'assignment'             =>$newrec->{'scassingmentgroup'},
                 'home.assignment'        =>'CSS.TCOM.W5BASE',
                 'priority.code'          =>'3',
                 'urgency'                =>'Medium',
                 'business.impact'        =>'Medium',
                 'dsc.criticality'        =>'Low',
                 'sla.relevant'           =>'No',
                 'category'               =>'SOFTWARE',
                 'company'                =>'T-Systems International GmbH',
                 'subcategory1'           =>'OTHER',
                 'dsc.service'            =>$newrec->{scapplname},
                 'reported.lastname'      =>$urec->{surname},
                 'reported.firstname'     =>$urec->{givenname},
                 'reported.by'            =>uc($urec->{posix}),
                 'contact.lastname'       =>$urec->{surname},
                 'contact.firstname'      =>$urec->{givenname},
                 'contact.name'           =>uc($urec->{posix}),
                 'referral.no'            =>"W5Base",
                 'contact.mail.address'   =>$urec->{email},
                 'category.type'          =>'APPLICATION',
                 'action'                 =>$newrec->{scdescription});

   printf STDERR ("fifi d=%s\n",Dumper(\%Incident));

   if (!defined($IncidentNumber=$sc->IncidentCreate(\%Incident))){
      $self->LastMsg(ERROR,"SC: ".$sc->LastMessage());
      $sc->Logout();
      return(undef);
   }
   msg(INFO,"end SC CreateIncident for $ENV{REMOTE_USER}");

   $sc->Logout();
   return($IncidentNumber);
}


sub ValidatedInsertRecord
{
   my $self=shift;
   my $newrec=shift;

   $self->{isInitalized}=$self->Initialize() if (!$self->{isInitalized});
   if (!$self->preValidate(undef,$newrec)){
      if ($self->LastMsg()==0){
         $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                              "unknown error in ${self}::preValidate()");
      }
   }
   else{
      if ($self->Validate(undef,$newrec)){
         $self->finishWriteRequestHash(undef,$newrec);
         my $bak=$self->InsertRecord($newrec);
         $self->SendRemoteEvent("ins",undef,$newrec,$bak) if ($bak);
         $self->FinishWrite(undef,$newrec) if ($bak);
         return($bak);
      }
      else{
         if ($self->LastMsg()==0){
            $self->LastMsg(ERROR,"ValidatedInsertRecord: ".
                                 "unknown error in ${self}::Validate()");
         }
      }
   }
   return(undef);
}



sub CreateApplicationIncident
{
   my $self=shift;
   my %param=@_;

   my $username=Query->Param("SCUsername");
   my $password=Query->Param("SCPassword");
   my $IncidentNumber;
   my $newrec=$self->getWriteRequestHash("nativweb");;
   foreach my $k (keys(%$newrec)){ # remove utf8 code while ajax request
       $newrec->{$k}=utf8($newrec->{$k})->latin1();
   }
   print STDERR "WriteRequestHash:".Dumper($newrec);

   if (my $IncidentNumber=$self->ValidatedInsertRecord($newrec)){
      $self->LastMsg(OK,"CreateIncident ($IncidentNumber) is ok");
   }
   return($IncidentNumber);
}


sub Process
{
   my $self=shift;
   if (my $op=Query->Param("Do")){
      Query->Delete("Do"); 
      if ($op eq "Login"){
         $self->LastMsg(OK,"ServiceCenter login successful");
      }
      if ($op eq "CreateApplicationIncident"){
         if (!($self->CreateApplicationIncident())){
            if ($self->LastMsg()==0){
               $self->LastMsg(ERROR,"create failed - unknown problem");
            }
         }
      }
      print $self->HttpHeader("text/xml");
      my $res=hash2xml({document=>{
             htmlresult=>$self->findtemplvar({},"LASTMSG")}},{header=>1});
      print $res;
      return;
   }
   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css',
                                   'Output.HtmlDetail.css',
                                   'jquery.autocomplete.css'
                                 ],
                           title=>'ServiceCenter Incident Creator',
                           js=>[qw( toolbox.js jquery.js jquery.autocomplete.js)],
                           body=>1,form=>1,target=>'result');
   my $mask=<<EOF;
<table border=1>
</tr>
<tr>
<td class=fname> %scname(label)% </td>
<td class=finput> %scname(forceedit)% </td>
</tr>
<tr>
<td class=fname> %sccustapplication(label)% </td>
<td class=finput> %sccustapplication(forceedit)% </td>
</tr>
<tr>
<td class=fname> %sctype(label)% </td>
<td class=finput> %sctype(forceedit)% </td>
</tr>
<tr>
<td class=fname> %scimpact(label)% </td>
<td class=finput> %scimpact(forceedit)% </td>
</tr>
<tr>
<td class=fname valign=top> %scdescription(label)% </td>
<td class=finput> %scdescription(forceedit)% </td>
</tr>
<tr>
<td colspan=2>
<input style="width:100%" type=button 
       onclick="parent.doOP(this,'CreateApplicationIncident','result')" 
       value="Create">
</td>
</table>
EOF
   $self->ParseTemplateVars(\$mask);
   print $mask;
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Manager
{
   my $self=shift;

   my $userid=$self->getCurrentUserId();
   my $user=getModuleObject($self->Config,"base::user");
   $user->SetFilter({userid=>\$userid});
   my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));

   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css',
                                   'kernel.App.Web.css',
                                   'Output.HtmlDetail.css',
                                 ],
                           title=>'ServiceCenter Incident Creator',
                           js=>[qw( toolbox.js)],
                           body=>1,form=>1,target=>'result');

   $self->ResetFilter();
   my $posix=uc($urec->{posix});
   $self->SetFilter({openedby=>\$posix,status=>'!closed'});
   print("<table>");
   print("<tr><th>Incidentnumber</th>".
         "<th>State</th><th>Short description</th></tr>");
   foreach my $irec ($self->getHashList(qw(status incidentnumber name
                                           downtimestart downtimeend))){
      printf("<form name=\"%s\">",$irec->{incidentnumber});
      printf("<tr><td>%s</td><td>%s</td><td>%s</td></tr>",
             $irec->{incidentnumber},$irec->{status},$irec->{name});
      printf("</form>");
   }
   print("</table>");


   

   print $self->HtmlBottom(body=>1,form=>1);
}


1;
