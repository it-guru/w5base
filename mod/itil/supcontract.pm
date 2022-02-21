package itil::supcontract;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
use finance::costcenter;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;

   my $self=bless($type->SUPER::new(%param),$type);
   my $haveitsemexp="costcenter.itsem is not null ".
                    "or costcenter.itsemteam is not null ".
                    "or costcenter.itseminbox is not null ".
                    "or costcenter.itsem2 is not null";


   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'supcontract.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Contract Number',
                dataobjattr   =>'supcontract.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmldetail    =>0,
                searchable    =>0,
                label         =>'Contract',
                dataobjattr   =>"concat(producer.name,'-',supcontract.name,".
                                "if (supcontract.fullname<>'',".
                                "concat('-',supcontract.fullname),''))"),

      new kernel::Field::Text(
                name          =>'label',
                label         =>'Contract Name',
                dataobjattr   =>'supcontract.fullname'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                label         =>'Costcenter',
                weblinkto     =>'finance::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'supcontract.conumber'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'supcontract.mandator'),

      #new kernel::Field::Text(
      #          name          =>'conumber',
      #          htmlwidth     =>'100px',
      #          label         =>'Costcenter',
      #          weblinkto     =>'itil::costcenter',
      #          weblinkon     =>['conumber'=>'name'],
      #          dataobjattr   =>'supcontract.conumber'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'supcontract.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'producer',
                SoftValidate  =>1,
                label         =>'Producer',
                vjointo       =>'itil::producer',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['producerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'producerid',
                dataobjattr   =>'supcontract.producer'),


      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'supcontract.databoss'),


      new kernel::Field::Contact(
                name          =>'contractcoord',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                label         =>'Contract Coordinator',
                vjoinon       =>'contractcoordid'),

      new kernel::Field::Link(
                name          =>'contractcoordid',
                dataobjattr   =>'supcontract.contractcoord'),



      new kernel::Field::Date(
                name          =>'durationstart',
                label         =>'Duration Start',
                dataobjattr   =>'supcontract.durationstart'),

      new kernel::Field::Date(
                name          =>'durationend',
                label         =>'Duration End',
                dataobjattr   =>'supcontract.durationend'),

      new kernel::Field::Select(
                name          =>'autoexpansion',
                label         =>'Auto Expansion',
                transprefix   =>'autoexpansion.',
                htmleditwidth =>'150px',
                value         =>[qw(0 1 2 3 6 12 18 24 36)],
                dataobjattr   =>'supcontract.autoexpansion'),

      new kernel::Field::Select(
                name          =>'cancelperiod',
                label         =>'Cancel Period',
                transprefix   =>'cancelperiod.',
                htmleditwidth =>'150px',
                value         =>[qw(0 1 2 3 6 12 18 24 36)],
                dataobjattr   =>'supcontract.cancelperiod'),

      new kernel::Field::TextDrop(
                name          =>'delmgr',
                group         =>'delmgmt',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Service Delivery Manager',
                translation   =>'finance::costcenter',
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'delmgr2',
                group         =>'delmgmt',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Deputy Service Delivery Manager',
                translation   =>'finance::costcenter',
                vjointo       =>'base::user',
                vjoinon       =>['delmgr2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Group(
                name          =>'delmgrteam',
                group         =>'delmgmt',
                readonly      =>1,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                translation   =>'finance::costcenter',
                label         =>'Service Delivery-Management Team',
                vjoinon       =>'delmgrteamid'),


      new kernel::Field::Link(
                name          =>'delmgrteamid',
                readonly      =>1,
                dataobjattr   =>"if (costcenter.delmgrteam is null,".
                                "costcenter.itsemteam,costcenter.delmgrteam)"),

      new kernel::Field::Link(
                name          =>'delmgrid',
                readonly      =>1,
                dataobjattr   =>"if (costcenter.delmgr is null,".
                                "costcenter.itsem,costcenter.delmgr)"),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                readonly      =>1,
                dataobjattr   =>"if (costcenter.delmgr2 is null,".
                                "costcenter.itsem2,costcenter.delmgr2)"),

      new kernel::Field::Group(
                name          =>'itsemteam',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(1);
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                label         =>'IT Servicemanagement Team',
                translation   =>'finance::costcenter',
                vjoinon       =>'itsemteamid'),

      new kernel::Field::Link(
                name          =>'itsemteamid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsemteam'),

      new kernel::Field::TextDrop(
                name          =>'itsem',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(1);
                   }
                   return(0);
                },
                group         =>'itsem',
                label         =>'IT Servicemanager',
                translation   =>'finance::costcenter',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoinon       =>['itsemid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itsemid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem'),

      new kernel::Field::TextDrop(
                name          =>'itsem2',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(1);
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                translation   =>'finance::costcenter',
                label         =>'Deputy IT Servicemanager',
                vjointo       =>'base::user',
                vjoinon       =>['itsem2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itsem2id',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem2'),






      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoinbase     =>[{'parentobj'=>\'itil::supcontract'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::supcontract'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Contract Details',
                dataobjattr   =>'supcontract.description'),


      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                subeditmsk    =>'subedit.supcontract',
                vjointo       =>'itil::lnkapplsupcontract',
                vjoinon       =>['id'=>'supcontractid'],
                vjoindisp     =>['appl','fraction'],
                vjoinbase     =>[{applcistatusid=>'<=4'}],
                vjoininhash   =>['applid','applcistatusid',
                                 'appl']),

      new kernel::Field::SubList(
                name          =>'applicationids',
                label         =>'ApplicationIDs',
                group         =>'applications',
                uivisible     =>0,
                vjointo       =>'itil::lnkapplsupcontract',
                vjoinon       =>['id'=>'supcontractid'],
                vjoindisp     =>['applid'],
                vjoinbase     =>[{applcistatusid=>'<=4'}],
                vjoininhash   =>['applid','applcistatusid',
                                 'appl']),


      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                dataobjattr   =>'supcontract.comments'),

      new kernel::Field::FileList(
                name          =>'attachments',
                parentobj     =>'itil::supcontract',
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
                dataobjattr   =>'supcontract.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'supcontract.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'supcontract.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                history       =>0,
                label         =>'Source-Load',
                dataobjattr   =>'supcontract.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'supcontract.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'supcontract.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'supcontract.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'supcontract.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'supcontract.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'supcontract.realeditor'),

      new kernel::Field::Link(
                name          =>'haveitsem',
                readonly      =>1,
                selectfix     =>1,
                dataobjattr   =>"if ($haveitsemexp,1,0)"),

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
                dataobjattr   =>'supcontract.lastqcheck'),
   );
   $self->{use_distinct}=1;
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(linenumber name cistatus mandator mdate fullname));
   $self->setWorktable("supcontract");
   return($self);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default sem delmgmt itsem
             contacts phonenumbers applications control misc attachments));
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj in ('itil::supcontract') ".
            "and $worktable.id=lnkcontact.refid ".
            "left outer join costcenter ".
            "on supcontract.conumber=costcenter.name ".
            "left outer join producer ".
            "on supcontract.producer=producer.id";


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
      push(@flt,[
                 {mandatorid=>\@mandators},
                # {semid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                # {sem2id=>$userid}
                ]);
   }
   return($self->SetFilter(@flt));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if (($name=~m/[\s,äöüß]/i) || ($name=~m/^\s*$/)){
      $self->LastMsg(ERROR,"invalid contract number '%s' specified",$name);
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
   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      if (!$self->finance::costcenter::ValidateCONumber(
          $self->SelfAsParentObject,"conumber", $oldrec,$newrec)){
         $self->LastMsg(ERROR,
             $self->T("invalid number format '\%s' specified",
                      "itil::costcenter"),$newrec->{conumber});
         return(0);
      }
   }

   my $producerid=trim(effVal($oldrec,$newrec,"producerid"));
   if ((!defined($oldrec) || exists($newrec->{producerid})) &&
       ($producerid eq "" || $producerid eq "0")){
      $self->LastMsg(ERROR,"no valid producer specified");
      return(0);
   }
   my $durationstart=trim(effVal($oldrec,$newrec,"durationstart"));
   if ((!defined($oldrec) || exists($newrec->{durationstart})) &&
       $durationstart eq ""){
      $self->LastMsg(ERROR,"no duration start defined");
      return(0);
   }
   ########################################################################

#   if ($self->isDataInputFromUserFrontend()){
#      if (!$self->isWriteOnApplValid($applid,"systems")){
#         $self->LastMsg(ERROR,"no access");
#         return(undef);
#      }
#   }


   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
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

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/contract.jpg?".$cgi->query_string());
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default contacts sem misc control applications
                       phonenumbers attachments);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
      if ($rec->{haveitsem}){
         @databossedit=grep(!/^sem$/,@databossedit);
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
      push(@chkgroups,$rec->{responseteamid}) if ($rec->{responseteamid} ne "");
      if ($#chkgroups!=-1){
         if ($self->IsMemberOf(\@chkgroups,["RControlling",
                                            "RCFManager","RCFManager2",
                                            "RDataAdmin"],"down")){
            return(@databossedit);
         }
      }
   }
   return(undef);
}

sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneHL phoneDEV);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::supcontract");
}









1;
