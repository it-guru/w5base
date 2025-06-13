package itil::itclust;
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
                dataobjattr   =>'itclust.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Full Cluster Name',
                dataobjattr   =>'itclust.fullname'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'itclust.mandator'),

      new kernel::Field::Select(
                name          =>'clusttyp',
                htmleditwidth =>'200px',
                value         =>[
                                 'Virtual',
                                 'MC-Service-Guard',
                                 'Sun-Cluster',
                                 'Veritas-Cluster',
                                 'Microsoft-Cluster',
                                 'Oracle-Clusterware',
                                 'HP-Metrocluster',
                                 'MSSQL-Cluster',
                                 'Loadbalancer',
                                 'Software',
                                 'OS',
                                ],
                label         =>'Cluster Type',
                dataobjattr   =>'itclust.clusttyp'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Cluster Name',
                dataobjattr   =>'itclust.name'),

      new kernel::Field::Text(
                name          =>'clusterid',
                htmleditwidth =>'100px',
                label         =>'ClusterID',
                dataobjattr   =>'itclust.itclustid'),

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
                dataobjattr   =>'itclust.cistatus'),

      new kernel::Field::Link(
                name          =>'itclustcistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'itclust.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'itclust.databoss'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'itil::itclust'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Services',
                group         =>'services',
                forwardSearch =>1,
                allowcleanup  =>1,
                subeditmsk    =>'subedit.services',
                vjointo       =>'itil::lnkitclustsvc',
                vjoinon       =>['id'=>'clustid'],
                vjoindisp     =>['fullname','itservid','applicationnames'],
                vjoininhash   =>['fullname','itservid',
                                 'applicationnames','name']),

      new kernel::Field::Text(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'itclustid'],
                vjoinbase     =>{applcistatusid=>"<6"},
                vjoindistinct =>1,
                vjoindisp     =>['appl'],
                vjoininhash   =>['appl','applid']),

      new kernel::Field::SubList(
                name          =>'appltsm',
                label         =>'Application TSMs',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'itclustid'],
                vjoinbase     =>{applcistatusid=>"<6"},
                vjoindistinct =>1,
                vjoindisp     =>['tsm']),

      new kernel::Field::SubList(
                name          =>'appltsm2',
                label         =>'Application deputy TSMs',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'itclustid'],
                vjoinbase     =>{applcistatusid=>"<6"},
                vjoindistinct =>1,
                vjoindisp     =>['tsm2']),

      new kernel::Field::SubList(
                name          =>'applapplmgr',
                label         =>'Application ApplicationManagers',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'itclustid'],
                vjoinbase     =>{applcistatusid=>"<6"},
                vjoindistinct =>1,
                vjoindisp     =>['applmgr']),


      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                readonly      =>1,
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'itclustid'],
                vjoindisp     =>['name','systemid',
                                 'cistatus',
                                 'shortdesc'],
                vjoininhash   =>['name','systemsystemid','systemcistatus',
                                 'systemid']),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                subeditmsk    =>'subedit.system',
                readonly      =>1,
                htmldetail    =>0,
                forwardSearch =>1,
                vjointo       =>'itil::lnksoftwareitclustsvc',
                vjoinbase     =>[{softwarecistatusid=>"<=5"}],
                vjoinon       =>['id'=>'itclustid'],
                vjoindisp     =>['software','version','quantity','comments'],
                vjoininhash   =>['softwarecistatusid','liccontractcistatusid',
                                 'liccontractid',
                                 'software','version','quantity']),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'itclust.allowifupdate'),

      new kernel::Field::Select(
                name          =>'defrunpolicy',
                htmleditwidth =>'80',
                group         =>'control',
                label         =>'default ClusterService on System Run Policy',
                value         =>['allow','deny'],
                dataobjattr   =>'defrunpolicy'),


      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'itclust.comments'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'itil::itclust',
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
                dataobjattr   =>'itclust.additional'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"itclust.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(itclust.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'itclust.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'itclust.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'itclust.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'itclust.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'itclust.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'itclust.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'itclust.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'itclust.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'itclust.realeditor'),
   
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
                dataobjattr   =>'itclust.lastqcheck'),
      new kernel::Field::QualityResponseArea(),

      new kernel::Field::Date(
                name          =>'lrecertreqdt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert request date',
                dataobjattr   =>'itclust.lrecertreqdt'),

      new kernel::Field::Date(
                name          =>'lrecertreqnotify',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert request notification date',
                dataobjattr   =>'itclust.lrecertreqnotify'),

      new kernel::Field::Date(
                name          =>'lrecertdt',
                group         =>'qc',
                searchable    =>sub{
                   my $self=shift;
                   my $app=$self->getParent;
                   return(1) if ($app->IsMemberOf("admin"));
                   return(0);
                },
                htmldetail    =>'0',
                label         =>'last recert date',
                dataobjattr   =>'itclust.lrecertdt'),

      new kernel::Field::Interface(
                name          =>'lrecertuser',
                group         =>'qc',
                label         =>'last recert userid',
                htmldetail    =>'0',
                dataobjattr   =>"itclust.lrecertuser")
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
   $self->setDefaultView(qw(linenumber fullname cistatus mandator mdate));
   $self->setWorktable("itclust");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default services systems applications
             software contacts misc control
             attachments source));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('itil::itclust') ".
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


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=effVal($oldrec,$newrec,"name");
   my $clusttyp=effVal($oldrec,$newrec,"clusttyp");
   if ($clusttyp eq ""){
      $self->LastMsg(ERROR,"invalid cluster typ");
      return(0);
   }

   my $clusterid=effVal($oldrec,$newrec,"clusterid");
   if (exists($newrec->{clusterid}) && $clusterid eq ""){
      $newrec->{clusterid}=undef;
   }
   if (exists($newrec->{name})){
      $newrec->{name}=$name;
   }
   $name=~s/[§\.]/_/g;
   if ($name eq "" || ($name=~m/[^-a-z0-9_]/i)){
      $self->LastMsg(ERROR,sprintf($self->T("invalid cluster name '%s'"),$name));
      return(0);
   }

   my $fname=$name;
   $fname.=($fname ne "" && $clusttyp ne "" ? "." : "").$clusttyp;
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
      $self->LastMsg(ERROR,"invalid cluster name '%s' specified",$name);
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

#   if ($self->isDataInputFromUserFrontend()){
#      if (!$self->isWriteOnApplValid($applid,"systems")){
#         $self->LastMsg(ERROR,"no access");
#         return(undef);
#      }
#   }


   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"fullname"));
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   return($bak);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/itclust.jpg?".$cgi->query_string());
#}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return(qw(header default history source services contacts applications
             attachments control systems misc));
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default services contacts attachments control);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
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
   return("itil::itclust");
}


sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   if ($lock>0 ||
       $#{$rec->{systems}}!=-1 ||
       $#{$rec->{services}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no services ".
          "or software instance relations");
      return(0);
   }

   return(1);
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
