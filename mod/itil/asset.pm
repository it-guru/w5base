package itil::asset;
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
use finance::costcenter;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'asset.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'80px',
                label         =>'Name',
                dataobjattr   =>'asset.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'asset.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'asset.cistatus'),


      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'asset.databoss'),

      new kernel::Field::TextDrop(
                name          =>'hwmodel',
                htmlwidth     =>'130px',
                group         =>'physasset',
                label         =>'Hardwaremodel',
                vjointo       =>'itil::hwmodel',
                vjoinon       =>['hwmodelid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                htmlwidth     =>'200px',
                group         =>'systems',
                subeditmsk    =>'stodu',
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoininhash   =>['name','systemid','cistatusid','id'],
                vjoindisp     =>['name','systemid','cistatus','shortdesc']),

      new kernel::Field::TextDrop(
                name          =>'hwproducer',
                htmlwidth     =>'130px',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                group         =>'physasset',
                label         =>'Hardwareproducer',
                vjointo       =>'itil::hwmodel',
                vjoinon       =>['hwmodelid'=>'id'],
                vjoindisp     =>'producer'),



      new kernel::Field::Link(
                name          =>'hwmodelid',
                dataobjattr   =>'asset.hwmodel'),

      new kernel::Field::Text(
                name          =>'serialno',
                group         =>'physasset',
                xlswidth      =>15,
                label         =>'Serialnumber',
                dataobjattr   =>'asset.serialnumber'),

      new kernel::Field::Text(
                name          =>'systemhandle',
                group         =>'physasset',
                label         =>'Producer System-Handle',
                dataobjattr   =>'asset.systemhandle'),

      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                group         =>'physasset',
                AllowEmpty    =>1,
                label         =>'Producer Service&Support Class',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'asset.prodmaintlevel'),

      new kernel::Field::SubList(
                name          =>'systemnames',
                label         =>'System names',
                htmlwidth     =>'200px',
                htmldetail    =>0,
                searchable    =>0,
                group         =>'systems',
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['name']),

      new kernel::Field::SubList(
                name          =>'systemids',
                label         =>'System IDs',
                htmlwidth     =>'200px',
                group         =>'systems',
                htmldetail    =>0,
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['systemid']),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                htmlwidth     =>'300px',
                group         =>'applications',
                readonly      =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoininhash   =>['appl','applcistatus','applcustomer','applid'],
                vjoindisp     =>['appl','applcistatus','applcustomer']),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Application names',
                htmlwidth     =>'300px',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['appl']),

      new kernel::Field::Text(
                name          =>'tsmemails',
                label         =>'Technical Solution Manager E-Mails',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['tsmemail']),

      new kernel::Field::SubList(
                name          =>'applicationteams',
                label         =>'Application business teams',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['businessteam']),

      new kernel::Field::SubList(
                name          =>'customer',
                label         =>'Application Customers',
                htmlwidth     =>'200px',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['applcustomer','appl']),

      new kernel::Field::Text(
                name          =>'customernames',
                label         =>'Customer names',
                htmlwidth     =>'200px',
                group         =>'applications',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5",
                                  systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>['applcustomer']),

      new kernel::Field::Number(
                name          =>'cpucount',
                xlswidth      =>10,
                group         =>'physasset',
                label         =>'CPU-Count',
                dataobjattr   =>'asset.cpucount'),

      new kernel::Field::Number(
                name          =>'cpuspeed',
                xlswidth      =>10,
                group         =>'physasset',
                unit          =>'MHz',
                label         =>'CPU-Speed',
                dataobjattr   =>'asset.cpuspeed'),

      new kernel::Field::Number(
                name          =>'corecount',
                xlswidth      =>10,
                group         =>'physasset',
                label         =>'Core-Count',
                dataobjattr   =>'asset.corecount'),

      new kernel::Field::Number(
                name          =>'memory',
                group         =>'physasset',
                xlswidth      =>10,
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>'asset.memory'),

      new kernel::Field::TextDrop(
                name          =>'location',
                group         =>'location',
                label         =>'Location',
                vjointo       =>'base::location',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                group         =>'location',
                dataobjattr   =>'asset.location'),

      new kernel::Field::Text(
                name          =>'room',
                group         =>'location',
                label         =>'Room',
                dataobjattr   =>'asset.room'),
                                                   
      new kernel::Field::Text(
                name          =>'place',
                group         =>'location',
                label         =>'Place',
                dataobjattr   =>'asset.place'),
                                                   
      new kernel::Field::Text(
                name          =>'rack',
                group         =>'location',
                label         =>'Rack identifier',
                dataobjattr   =>'asset.rack'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'asset.comments'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmlwidth     =>'100px',
                group         =>'misc',
                label         =>'CO-Number',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'asset.conumber'),

      new kernel::Field::Text(
                name          =>'kwords',
                group         =>'misc',
                label         =>'Keywords',
                dataobjattr   =>'asset.kwords'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                vjoinbase     =>[{'parentobj'=>\'itil::asset'}],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::asset'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::FileList(
                name          =>'attachments',
                searchable    =>0,
                parentobj     =>'itil::asset',
                label         =>'Attachments',
                group         =>'attachments'),

      new kernel::Field::Contact(
                name          =>'guardian',
                group         =>'guardian',
                label         =>'Guardian',
                vjoinon       =>['guardianid'=>'userid']),

      new kernel::Field::Link(
                name          =>'guardianid',
                dataobjattr   =>'asset.guardian'),

      new kernel::Field::Contact(
                name          =>'guardian2',
                group         =>'guardian',
                label         =>'Deputy Guardian',
                vjoinon       =>['guardian2id'=>'userid']),

      new kernel::Field::Link(
                name          =>'guardian2id',
                dataobjattr   =>'asset.guardian2'),

      new kernel::Field::TextDrop(
                name          =>'guardianteam',
                htmlwidth     =>'300px',
                group         =>'guardian',
                label         =>'Guardian Team',
                vjointo       =>'base::grp',
                vjoinon       =>['guardianteamid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'guardianteamid',
                dataobjattr   =>'asset.guardianteam'),

      new kernel::Field::JoinUniqMerge(
                name          =>'issox',
                label         =>'mangaged by rules of SOX',
                group         =>'sec',
                searchable    =>1,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'assetid'],
                vjoindisp     =>'assetissox'),

      new kernel::Field::Select(
                name          =>'nosoxinherit',
                group         =>'sec',
                label         =>'SOX state',
                searchable    =>0,
                transprefix   =>'SysInherit.',
                htmleditwidth =>'180px',
                value         =>['0','1'],
                dataobjattr   =>'asset.no_sox_inherit'),

         new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'asset.allowifupdate'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                htmldetail    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'asset.additional'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'asset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'asset.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'asset.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'asset.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'asset.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'asset.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'asset.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'asset.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'asset.realeditor'),

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

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'asset.lastqcheck'),
   );
   $self->{workflowlink}={ workflowkey=>\&createWorkflowQuery
                         };
   $self->{history}=[qw(insert modify delete)];
   $self->{use_distinct}=1;

   $self->setDefaultView(qw(linenumber name hwmodel serialno 
                            cistatus mandator mdate));


   $self->{PhoneLnkUsage}=\&PhoneUsage;

   $self->setDefaultView(qw(name mandator cistatus mdate));
   $self->setWorktable("asset");
   return($self);
}


sub PhoneUsage
{
   my $self=shift;
   return('phoneRB',$self->T("phoneRB","itil::appl"));
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::asset");
}





sub createWorkflowQuery
{
   my $self=shift;
   my $q=shift;
   my $id=shift;

   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my ($rec,$msg)=$self->getOnlyFirst(qw(systems));
   my %sid=();
   if (defined($rec->{systems}) && ref($rec->{systems}) eq "ARRAY"){
      foreach my $srec (@{$rec->{systems}}){
         $sid{$srec->{id}}=1;
      }
   }
   $q->{affectedsystemid}=[keys(%sid)];   
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/asset.jpg?".$cgi->query_string());
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

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.system.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                              [orgRoles(),qw(RCFManager RCFManager2)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {databossid=>$userid},
                 {guardianid=>$userid},       {guardian2id=>$userid},
                 {guardianteamid=>\@grpids},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                ]);
   }
   return($self->SetFilter(@flt));
}


sub getSqlFrom
{  
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::asset' ".
          "and $worktable.id=lnkcontact.refid";

   return($from);
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;

   if ($#{$rec->{systems}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no system relations");
      return(0);
   }

   return(1);
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       (($newrec->{name}=~m/^\s*$/) || length($newrec->{name})<3 ||
         haveSpecialChar($newrec->{name}))){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   my $systemhandle=trim(effVal($oldrec,$newrec,"systemhandle"));
   $systemhandle=undef if ($systemhandle eq "");
   if (exists($newrec->{systemhandle}) && 
       $newrec->{systemhandle} ne $systemhandle){
      $newrec->{systemhandle}=$systemhandle;
   }

   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      return(0) if (!$self->finance::costcenter::ValidateCONumber("conumber",
                    $oldrec,$newrec));
   }


   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            $newrec->{databossid}=$userid;
         }
      }
      if (!$self->IsMemberOf("admin") && 
          (defined($newrec->{databossid}) &&
           $newrec->{databossid}!=$userid &&
           $newrec->{databossid}!=$oldrec->{databossid})){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################

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

   my @databossedit=qw(default guardian physasset contacts control location 
                       phonenumbers misc attachments sec);
   if (!defined($rec)){
      return("default","control");
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
      if ($rec->{mandatorid}!=0 &&
         $self->IsMemberOf($rec->{mandatorid},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
      if ($rec->{guardianteamid}!=0 &&
         $self->IsMemberOf($rec->{guardianteamid},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
   }
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default guardian phonenumbers location 
             physasset sec contacts misc systems 
             applications attachments control source));
}




1;
