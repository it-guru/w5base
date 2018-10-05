package itil::netintercon;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'netintercon.id'),
                                                  

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Interconnect name',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>"concat(".
                                "if (netintercon.epa_typ=1,sysa.name,".
                                "netintercon.epa__systemname),' : ',".
                                "netintercon.lineid,' : ',".
                                "if (netintercon.epb_typ=1,sysb.name,".
                                "netintercon.epb__systemname))"),
                                                  
      new kernel::Field::Text(
                name          =>'netinterconid',
                label         =>'Line Key number (LSZ)',
                dataobjattr   =>'netintercon.lineid'),


      new kernel::Field::Select(
                name          =>'linebandwidth',
                label         =>'Interconnect bandwidth',
                transprefix   =>'LBW.',
                allowempty    =>1,
                value         =>['2000','10000',
                                 '1000000','40000000','100000000'],
                htmleditwidth =>'200',
                dataobjattr   =>'netintercon.linebandwidth'),

      new kernel::Field::Interface(
                name          =>'lineipnetid',
                label         =>'IP-Network ID',
                dataobjattr   =>'netintercon.lineipnet'),

      new kernel::Field::TextDrop(
                name          =>'lineipnetname',
                htmlwidth     =>'350',
                label         =>'Interconnect Network Name',
                vjointo       =>'itil::ipnet',
                vjoinon       =>['lineipnetid'=>'id'],
                vjoindisp     =>'fullname'),

     new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'netintercon.mandator'),

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
                dataobjattr   =>'netintercon.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'netintercon.databoss'),

      new kernel::Field::Select(
                name          =>'epatype',
                label         =>'Endpoint A - reference type',
                group         =>'epa',
                transprefix   =>'EPT.',
                jsonchanged   =>\&getOnChangedScript,
                jsoninit      =>\&getOnChangedScript,
                value         =>['1'],
                htmleditwidth =>'200',
                dataobjattr   =>'netintercon.epa_typ'),

      new kernel::Field::TextDrop(
                name          =>'systemepa',
                label         =>'System A',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                vjointo       =>'itil::system',
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['epasystemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemepaname',
                label         =>'System A - Systemname',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__systemname',
                dataobjattr   =>'if (netintercon.epa_typ=1,sysa.name,'.
                                'netintercon.epa__systemname)'),

      new kernel::Field::Link(
                name          =>'systemepaadmid',
                label         =>'System A - AdminID',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__adm',
                dataobjattr   =>'if (netintercon.epa_typ=1,sysa.adm,'.
                                'netintercon.epa__adm)'),

      new kernel::Field::Contact(
                name          =>'systemepaadm',
                label         =>'System A - Admin',
                AllowEmpty    =>1,
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                vjoinon       =>['systemepaadmid'=>'userid']),

      new kernel::Field::Link(
                name          =>'systemepaadm2id',
                label         =>'System A - AdminID',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__adm2',
                dataobjattr   =>'if (netintercon.epa_typ=1,sysa.adm2,'.
                                'netintercon.epa__adm2)'),

      new kernel::Field::Contact(
                name          =>'systemepaadm2',
                label         =>'System A - Deputy Admin',
                AllowEmpty    =>1,
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                vjoinon       =>['systemepaadm2id'=>'userid']),

      new kernel::Field::Text(
                name          =>'systemepaincidentgroup',
                label         =>'System A - Incident Target Group',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__incidentgroup',
                dataobjattr   =>"if (netintercon.epa_typ=1,NULL,".
                                'netintercon.epa__incidentgroup)'),

      new kernel::Field::Text(
                name          =>'systemepalocation',
                label         =>'System A - Location',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__systemname',
                dataobjattr   =>'if (netintercon.epa_typ=1,loca.name,'.
                                'netintercon.epa__location)'),

      new kernel::Field::Text(
                name          =>'systemeparoom',
                label         =>'System A - Room',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__room',
                dataobjattr   =>'if (netintercon.epa_typ=1,assa.room,'.
                                'netintercon.epa__room)'),

      new kernel::Field::Text(
                name          =>'systemepaplace',
                label         =>'System A - Place',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epa',
                wrdataobjattr =>'netintercon.epa__place',
                dataobjattr   =>'if (netintercon.epa_typ=1,assa.place,'.
                                'netintercon.epa__place)'),

      new kernel::Field::Interface(
                name          =>'epasystemid',
                selectfix     =>1,
                dataobjattr   =>'netintercon.epa_systemid'),

      new kernel::Field::SubList(
                name          =>'epanets',
                label         =>'Endpoint A - Networks',
                group         =>'epanets',
                htmllimit     =>'20',
                vjointo       =>'itil::lnknetinterconipnet',
                vjoinbase     =>[{'endpoint'=>\'A'}],
                vjoinon       =>['id'=>'netinterconid'],
                vjoindisp     =>['ipnetname']),


      new kernel::Field::Select(
                name          =>'epbtype',
                label         =>'Endpoint B - reference type',
                group         =>'epb',
                transprefix   =>'EPT.',
                jsonchanged   =>\&getOnChangedScript,
                jsoninit      =>\&getOnChangedScript,
                value         =>['1','2'],
                htmleditwidth =>'200',
                dataobjattr   =>'netintercon.epb_typ'),

      new kernel::Field::TextDrop(
                name          =>'systemepb',
                label         =>'System B',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                vjointo       =>'itil::system',
                vjoineditbase =>{'cistatusid'=>[2,3,4]},
                vjoinon       =>['epbsystemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'epbsystemid',
                selectfix     =>1,
                dataobjattr   =>'netintercon.epb_systemid'),


      new kernel::Field::Text(
                name          =>'systemepbname',
                label         =>'System B - Systemname',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__systemname',
                dataobjattr   =>'if (netintercon.epb_typ=1,sysb.name,'.
                                'netintercon.epb__systemname)'),

      new kernel::Field::Link(
                name          =>'systemepbadmid',
                label         =>'System B - AdminID',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__adm',
                dataobjattr   =>'if (netintercon.epb_typ=1,sysb.adm,'.
                                'netintercon.epb__adm)'),

      new kernel::Field::Contact(
                name          =>'systemepbadm',
                label         =>'System B - Admin',
                AllowEmpty    =>1,
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                vjoinon       =>['systemepbadmid'=>'userid']),

      new kernel::Field::Link(
                name          =>'systemepbadm2id',
                label         =>'System B - AdminID',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__adm2',
                dataobjattr   =>'if (netintercon.epb_typ=1,sysb.adm2,'.
                                'netintercon.epb__adm2)'),

      new kernel::Field::Contact(
                name          =>'systemepbadm2',
                label         =>'System B - Deputy Admin',
                AllowEmpty    =>1,
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                vjoinon       =>['systemepbadm2id'=>'userid']),

      new kernel::Field::Text(
                name          =>'systemepbincidentgroup',
                label         =>'System B - Incident Target Group',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__incidentgroup',
                dataobjattr   =>"if (netintercon.epb_typ=1,'???',".
                                'netintercon.epb__incidentgroup)'),

      new kernel::Field::Text(
                name          =>'systemepblocation',
                label         =>'System B - Location',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__location',
                dataobjattr   =>'if (netintercon.epb_typ=1,locb.name,'.
                                'netintercon.epb__location)'),

      new kernel::Field::Text(
                name          =>'systemepbroom',
                label         =>'System B - Room',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__room',
                dataobjattr   =>'if (netintercon.epb_typ=1,assb.room,'.
                                'netintercon.epb__room)'),

      new kernel::Field::Text(
                name          =>'systemepbplace',
                label         =>'System B - Place',
                htmldetail    =>'NotEmptyOrEdit',
                group         =>'epb',
                wrdataobjattr =>'netintercon.epb__place',
                dataobjattr   =>'if (netintercon.epb_typ=1,assb.place,'.
                                'netintercon.epb__place)'),

      new kernel::Field::SubList(
                name          =>'epbnets',
                label         =>'Endpoint B - Networks',
                group         =>'epbnets',
                htmllimit     =>'20',
                vjointo       =>'itil::lnknetinterconipnet',
                vjoinbase     =>[{'endpoint'=>\'B'}],
                vjoinon       =>['id'=>'netinterconid'],
                vjoindisp     =>['ipnetname']),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'netintercon.comments'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),


      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::appl',
                group         =>'attachments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'netintercon.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'netintercon.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'netintercon.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'netintercon.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'netintercon.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'netintercon.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'netintercon.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'netintercon.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'netintercon.realeditor'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'netintercon.lastqcheck'),
      new kernel::Field::QualityResponseArea(),
   );
   $self->setDefaultView(qw(fullname cistatus mdate cdate));
   $self->setWorktable("netintercon");
   $self->{history}={
      update=>[
         'local'
      ]
   };
#   $self->{CI_Handling}={uniquename=>"fullname",
#                         activator=>["admin","w5base.itil.netintercon"],
#                         uniquesize=>255};
   return($self);
}


sub getOnChangedScript
{
   my $self=shift;
   my $grp=$self->{group};

   my $d=<<EOF;

var s=document.forms[0].elements['Formated_${grp}type'];
var system=document.forms[0].elements['Formated_system${grp}'];
var systemname=document.forms[0].elements['Formated_system${grp}name'];
var systemadm=document.forms[0].elements['Formated_system${grp}adm'];
var systemadm2=document.forms[0].elements['Formated_system${grp}adm2'];
var systemincidentgroup=document.forms[0].elements['Formated_system${grp}incidentgroup'];
var systemlocation=document.forms[0].elements['Formated_system${grp}location'];
var systemroom=document.forms[0].elements['Formated_system${grp}room'];
var systemplace=document.forms[0].elements['Formated_system${grp}place'];

if (s){
   var v=s.options[s.selectedIndex].value;
   if (v=="1"){
      system.disabled=false;
      systemname.disabled=true;
      systemadm.disabled=true;
      systemadm2.disabled=true;
      systemincidentgroup.disabled=true;
      systemlocation.disabled=true;
      systemroom.disabled=true;
      systemplace.disabled=true;
   }
   else if (v=="2"){
      system.disabled=true;
      systemname.disabled=false;
      systemadm.disabled=false;
      systemadm2.disabled=false;
      systemincidentgroup.disabled=false;
      systemlocation.disabled=false;
      systemroom.disabled=false;
      systemplace.disabled=false;
   }
   else{
      system.disabled=true;
      systemname.disabled=true;
      systemadm.disabled=true;
      systemadm2.disabled=true;
      systemincidentgroup.disabled=true;
      systemlocation.disabled=true;
      systemroom.disabled=true;
      systemplace.disabled=true;
   }
}

EOF
   return($d);
}




sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable ".
      "left outer join system    sysa on $worktable.epa_systemid=sysa.id ".
      "left outer join asset     assa on sysa.asset=assa.id ".
      "left outer join location  loca on assa.location=loca.id ".
      "left outer join system    sysb on $worktable.epb_systemid=sysb.id ".
      "left outer join asset     assb on sysb.asset=assb.id ".
      "left outer join location  locb on assb.location=locb.id ";
   return($from);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/netintercon.jpg?".$cgi->query_string());
}


sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default epa epanets epb epbnets contacts 
              attachments source));
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::netintercon");
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;




   if (effVal($oldrec,$newrec,"epatype") eq "2"){
      if (effVal($oldrec,$newrec,"systemepaname") eq ""){
         $self->LastMsg(ERROR,"invalid systemname");
         return(0);
      }
      if (effVal($oldrec,$newrec,"epasystemid") ne ""){
         $newrec->{"epasystemid"}=undef;
      } 
   }
   if (effVal($oldrec,$newrec,"epbtype") eq "2"){
      if (effVal($oldrec,$newrec,"systemepbname") eq ""){
         $self->LastMsg(ERROR,"invalid systemname");
         return(0);
      }
      if (effVal($oldrec,$newrec,"epbsystemid") ne ""){
         $newrec->{"epbsystemid"}=undef;
      } 
   }
   my $netinterconid=effVal($oldrec,$newrec,"netinterconid");

   if (length($netinterconid)<3 || haveSpecialChar($netinterconid)){ 
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid LSZ '%s' specified"),$netinterconid));
      return(0);
   }


   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
  
   return(1);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default epa epb epanets epbnets contacts attachments);


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
      if ($rec->{mandatorid}!=0 &&
         $self->IsMemberOf($rec->{mandatorid},["RCFManager","RCFManager2"],
                           "down")){
         return(@databossedit);
      }
   }
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","epa","epb") if (!defined($rec));
   return("ALL");
}


1;
