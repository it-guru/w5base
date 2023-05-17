package itil::itfarm;
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
                dataobjattr   =>'itfarm.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'190px',
                label         =>'Serverfarm name',
                readonly      =>1,
                htmldetail    =>0,
                dataobjattr   =>'itfarm.fullname'),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'190px',
                label         =>'Name',
                dataobjattr   =>'itfarm.name'),

      new kernel::Field::Text(
                name          =>'combound',
                htmlwidth     =>'190px',
                label         =>'Combound',
                dataobjattr   =>'itfarm.combound'),

      new kernel::Field::Text(
                name          =>'shortname',
                htmlwidth     =>'190px',
                label         =>'Short-Name',
                dataobjattr   =>'itfarm.shortname'),

     new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'itfarm.mandator'),

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
                dataobjattr   =>'itfarm.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'itfarm.databoss'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Farm name',
                dataobjattr   =>'itfarm.osclass'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'itfarm.comments'),

      new kernel::Field::SubList(
                name          =>'assets',
                label         =>'Assets',
                group         =>'assets',
                forwardSearch =>1,
                allowcleanup  =>1,
                subeditmsk    =>'subedit.asset',
                vjointo       =>'itil::lnkitfarmasset',
                vjoinon       =>['id'=>'itfarmid'],
                vjoindisp     =>['assetfullname','assetcistatus','comments']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                readonly      =>1,
                htmldetail    =>0,
                vjoinbase     =>{cistatusid=>'<6'},
                vjointo       =>'itil::system',
                vjoinon       =>['assetids'=>'assetid'],
                vjoindisp     =>['name','systemid']),

      new kernel::Field::Link(
                name          =>'assetids',
                label         =>'AssetsIDs',
                group         =>'assetids',
                vjointo       =>'itil::lnkitfarmasset',
                vjoinon       =>['id'=>'itfarmid'],
                vjoindisp     =>['assetid']),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Application names',
                group         =>'applications',
                searchable    =>1,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5"}],
                vjoinon       =>['assetids'=>'assetid'],
                vjoindisp     =>'appl'),

      new kernel::Field::Link(
                name          =>'applicationids',
                label         =>'Applications IDs',
                group         =>'applications',
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{applcistatusid=>"<=5"}],
                vjoinon       =>['assetids'=>'assetid'],
                vjoindisp     =>'applid'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                htmldetail    =>0,
                uploadable    =>0,
                searchable    =>0,
                vjointo       =>'itil::appl',
                vjoinon       =>['applicationids'=>'id'],
                vjoindisp     =>['name','itnormodel']),

                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'itfarm.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'itfarm.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'itfarm.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'itfarm.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'itfarm.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'itfarm.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'itfarm.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'itfarm.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'itfarm.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"itfarm.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(itfarm.id,35,'0')"),

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
                dataobjattr   =>'itfarm.lastqcheck'),
      new kernel::Field::QualityResponseArea(),
   );
   $self->setDefaultView(qw(fullname cistatus mdate cdate));
   $self->setWorktable("itfarm");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"fullname",
                         activator=>["admin","w5base.itil.itfarm"],
                         uniquesize=>255};
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj='$selfasparent' ".
            "and $worktable.id=lnkcontact.refid ";

   return($from);
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
   return("../../../public/itil/load/itfarm.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default assets systems contacts  attachments source));
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::itfarm");
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       (($newrec->{name}=~m/^\s*$/) || haveSpecialChar($newrec->{name}))){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   my $name=effVal($oldrec,$newrec,"name");
   my $combound=effVal($oldrec,$newrec,"combound");
   my $shortname=effVal($oldrec,$newrec,"shortname");

   my $fullname=$name;

   $combound=uc($combound);
   if ($combound ne ""){
      $fullname.="-".$combound;
   }
   if ($shortname ne ""){
      $fullname.="(".$shortname.")";
   }
   if ($shortname ne "" &&
       (length($shortname)<3 || haveSpecialChar($shortname))){
      $self->LastMsg(ERROR,"invalid short name specified");
      return(0);
   }
   if ($shortname eq ""){
      if (defined($oldrec) && $oldrec->{shortname} ne ""){
         $newrec->{shortname}=undef;
      }
   }

   $fullname=~s/ /_/g;
   if (length($fullname)<5){
      $self->LastMsg(ERROR,"invalid serverfarm name specified");
      return(0);
   }
   if (!defined($oldrec) || $oldrec->{fullname} ne $fullname){
      $newrec->{fullname}=$fullname;
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


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
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


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default assets contacts);


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
   return("header","default") if (!defined($rec));
   return("ALL");
}


1;
