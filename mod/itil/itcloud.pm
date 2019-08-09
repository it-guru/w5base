package itil::itcloud;
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
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;

   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'itcloud.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Full Cloud Name',
                dataobjattr   =>'itcloud.fullname'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'itcloud.mandator'),

#      new kernel::Field::Select(
#                name          =>'cloudtyp',
#                htmleditwidth =>'200px',
#                value         =>[
#                                 'Amazon',
#                                 'Azur',
#                                 'Google',
#                                 'Any'
#                                ],
#                label         =>'Cloud Type',
#                dataobjattr   =>'itcloud.cloudtyp'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Cloud Name',
                dataobjattr   =>'itcloud.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'itcloud.cistatus'),

      new kernel::Field::Link(
                name          =>'itcloudcistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'itcloud.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'itcloud.databoss'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'itcloud.description'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'itil::itcloud'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'cloudareas',
                label         =>'Cloud-Areas',
                group         =>'areas',
                forwardSearch =>1,
                allowcleanup  =>1,
                vjoinbase     =>[{cistatusid=>"<=5"}],
                subeditmsk    =>'subedit.cloudareas',
                vjointo       =>'itil::itcloudarea',
                vjoinon       =>['id'=>'cloudid'],
                vjoindisp     =>['fullname','cistatus','appl'],
                vjoininhash   =>['fullname','cistatusid','applid','name','id']),

#      new kernel::Field::Boolean(
#                name          =>'allowifupdate',
#                group         =>'control',
#                label         =>'allow automatic updates by interfaces',
#                dataobjattr   =>'itcloud.allowifupdate'),

#      new kernel::Field::Select(
#                name          =>'defrunpolicy',
#                htmleditwidth =>'80',
#                group         =>'control',
#                label         =>'default ClusterService on System Run Policy',
#                value         =>['allow','deny'],
#                dataobjattr   =>'defrunpolicy'),


      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'itcloud.comments'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::itcloud'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Boolean(
                name          =>'can_saas',
                group         =>'servicemodels',
                label         =>'Software as a Service (SaaS)',
                dataobjattr   =>'itcloud.can_saas'),

      new kernel::Field::Boolean(
                name          =>'can_iaas',
                group         =>'servicemodels',
                label         =>'Infrastructure as a Service (IaaS)',
                dataobjattr   =>'itcloud.can_iaas'),

      new kernel::Field::Boolean(
                name          =>'can_paas',
                group         =>'servicemodels',
                label         =>'Platform as a Service (PaaS)',
                dataobjattr   =>'itcloud.can_paas'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'itil::itcloud',
                label         =>'Attachments',
                group         =>'attachments'),


      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(0);
                   return(1);
                },
                dataobjattr   =>'itcloud.additional'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"itcloud.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(itcloud.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'itcloud.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'itcloud.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'itcloud.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'itcloud.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'itcloud.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'itcloud.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'itcloud.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'itcloud.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'itcloud.realeditor'),
   
      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::IssueState(),
      new kernel::Field::QualityText(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'itcloud.lastqcheck'),
      new kernel::Field::QualityResponseArea()
   );
   $self->{use_distinct}=1;
   $self->{workflowlink}={ };

   $self->{workflowlink}->{workflowtyp}=[qw(base::workflow::DataIssue
                                            base::workflow::mailsend)];

   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->{CI_Handling}={uniquename=>"fullname",
                         activator=>["admin","w5base.itil.itcloud"],
                         uniquesize=>40};

   $self->setDefaultView(qw(linenumber fullname cistatus mandator mdate));
   $self->setWorktable("itcloud");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default servicemodels 
             areas systems contacts phonenumbers misc inm control
             attachments source));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('itil::itcloud') ".
            "and $worktable.id=lnkcontact.refid";

   return($from);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}






sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;
   
   if (!$self->IsMemberOf("admin")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
          [orgRoles(),qw(RMember RCFManager RCFManager2
                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();

      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
                    {mandatorid=>\@mandators},
                    {databossid=>\$userid}
                   );
      }
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $wrgroups=shift;

   my $userid=$self->getCurrentUserId();
   if (defined($oldrec) && $oldrec->{userid}==$userid){
      delete($newrec->{cistatusid});
   }
   else{
      if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
         return(0);
      }
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec,$wrgroups));
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=effVal($oldrec,$newrec,"name");
   my $cloudtyp=effVal($oldrec,$newrec,"cloudtyp");
#   if ($cloudtyp eq ""){
#      $self->LastMsg(ERROR,"invalid clouder typ");
#      return(0);
#   }
#
#   my $clouderid=effVal($oldrec,$newrec,"clouderid");
#   if (exists($newrec->{clouderid}) && $clouderid eq ""){
#      $newrec->{clouderid}=undef;
#   }
   if (exists($newrec->{name})){
      $newrec->{name}=$name;
   }
   $name=~s/[§\.]/_/g;
   if ($name eq "" || ($name=~m/[^-a-z0-9_]/i)){
      $self->LastMsg(ERROR,sprintf($self->T("invalid cloud name '%s'"),$name));
      return(0);
   }

   my $fname=$name;
   $fname.=($fname ne "" && $cloudtyp ne "" ? "." : "").$cloudtyp;
   $fname=~s/ü/ue/g;
   $fname=~s/ö/oe/g;
   $fname=~s/ä/ae/g;
   $fname=~s/Ü/Ue/g;
   $fname=~s/Ö/Oe/g;
   $fname=~s/Ä/Ae/g;
   $fname=~s/ß/ss/g;
   $fname=~s/\s/_/g;
   $newrec->{'fullname'}=$fname;

   my $fname=trim(effVal($oldrec,$newrec,"fullname"));


   my $name=trim(effVal($oldrec,$newrec,"name"));
   if (($name=~m/[\s]/i) || ($name=~m/^\s*$/)){
      $self->LastMsg(ERROR,"invalid clouder name '%s' specified",$name);
      return(0);
   }
   if (exists($newrec->{name}) && $newrec->{name} ne $name){
      $newrec->{name}=$name;
   }
   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend()){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            $newrec->{databossid}=$userid;
         }
      }
      if (!$self->IsMemberOf("admin")){
         if (defined($newrec->{databossid}) &&
             $newrec->{databossid}!=$userid &&
             $newrec->{databossid}!=$oldrec->{databossid}){
            $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                                 "as databoss");
            return(0);
         }
      }
   }
   ########################################################################


   if (effChanged($oldrec,$newrec,"cistatusid")){
      if ($newrec->{cistatusid}>=5){
         if ($#{$oldrec->{cloudareas}}!=-1){
            $self->LastMsg(ERROR,"there are existing cloud areas");
            return(0);
         }
      }
   }

#   if ($self->isDataInputFromUserFrontend()){
#      if (!$self->isWriteOnApplValid($applid,"systems")){
#         $self->LastMsg(ERROR,"no access");
#         return(undef);
#      }
#   }


   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"fullname"));
   return(1);
}



sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   if ( $#{$rec->{cloudareas}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no ".
          "cloud areas");
      return(0);
   }

   return(1);
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return(1);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}






sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/itcloud.jpg?".$cgi->query_string());
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return(qw(header default history source areas contacts 
             servicemodels
             attachments control phonenumbers inm misc));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default contacts attachments phonenumbers 
                       servicemodels
                       inm misc control);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
      if ($rec->{cistatusid}==4 || $rec->{cistatusid}==5){
         push(@databossedit,"areas");
      }
      if ($rec->{databossid}==$userid){
         return(@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
            return(@databossedit) if (grep(/^write$/,@roles));
         }
      }
      my @chkgroups;
      push(@chkgroups,$rec->{mandatorid}) if ($rec->{mandatorid} ne "");
      if ($#chkgroups!=-1){
         if ($self->IsMemberOf(\@chkgroups,["RDataAdmin",
                                            "RCFManager",
                                            "RCFManager2"],"down")){
            return(@databossedit);
         }
      }
   }
   return(undef);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::itcloud");
}


sub HtmlPublicDetail   # for display record in QuickFinder or with no access
{
   my $self=shift;
   my $rec=shift;
   my $header=shift;   # create a header with fullname or name

   my $htmlresult="";
   if ($header){
      $htmlresult.="<table style='margin:5px'>\n";
      $htmlresult.="<tr><td colspan=2 align=center><h1>";
      $htmlresult.=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      "name","formated");
      $htmlresult.="</h1></td></tr>";
   }
   else{
      $htmlresult.="<table>\n";
   }
   my @l=qw( databoss );
   foreach my $v (@l){
      my $name=$self->getField($v)->Label();
      my $data=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                   $v,"formated");
      $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                   "<td valign=top>$data</td></tr>\n";
   }

   #if (my $pn=$self->getField("phonenumbers")){
   #   $htmlresult.=$pn->FormatForHtmlPublicDetail($rec,["phoneRB"]);
   #}
   $htmlresult.="</table>\n";
   #if ($rec->{description} ne ""){
   #   my $desclabel=$self->getField("description")->Label();
   #   my $desc=$rec->{description};
   #   $desc=~s/\n/<br>\n/g;
   #
   #      $htmlresult.="<table><tr><td>".
   #                   "<div style=\"height:60px;overflow:auto;color:gray\">".
   #                   "\n<font color=black>$desclabel:</font><div>\n$desc".
   #                   "</div></div>\n</td></tr></table>";
   #   }
   return($htmlresult);

}







1;
