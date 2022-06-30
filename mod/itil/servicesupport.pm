package itil::servicesupport;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                dataobjattr   =>'servicesupport.id'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'servicesupport.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                uivisible     =>0,
                label         =>'fullname',
                dataobjattr   =>"if (servicesupport.fullname<>'',".
                                "servicesupport.fullname,servicesupport.name)"),

      new kernel::Field::Text(
                name          =>'description',
                label         =>'long description',
                dataobjattr   =>'servicesupport.fullname'),

      new kernel::Field::Mandator(),

      new kernel::Field::Link(
                name          =>'mandatorid',
                selectfix     =>1,
                dataobjattr   =>'servicesupport.mandator'),
                                                  
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
                dataobjattr   =>'servicesupport.cistatus'),

      new kernel::Field::Databoss(
                group         =>'responsibility'),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                group         =>'responsibility',
                dataobjattr   =>'servicesupport.databoss'),

      new kernel::Field::Contact(
                name          =>'databoss2',
                group         =>'responsibility',
                vjoineditbase =>{'cistatusid'=>[3,4],
                                 'usertyp'=>[qw(user extern)]},
                label         =>'deputy Databoss',
                vjoinon       =>'databoss2id'),



      new kernel::Field::Link(
                name          =>'databoss2id',
                selectfix     =>1,
                group         =>'responsibility',
                dataobjattr   =>'servicesupport.databoss2'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::Select(
                name          =>'tz',
                group         =>'characteristic',
                label         =>'Timezone',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'servicesupport.timezone'),

      new kernel::Field::TimeSpans(
                name          =>'oncallservice',
                htmlwidth     =>'150px',
                depend        =>['isoncallservice'],
                group         =>'oncallservice',
                label         =>'on-call service',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'isoncallservice',
                group         =>'characteristic',
                label         =>'oncall active',
                container     =>'additional'),

      new kernel::Field::TimeSpans(
                name          =>'support',
                htmlwidth     =>'150px',
                depend        =>['issupport'],
                tspantype     =>['','R'],
                tspantypeproc =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $blk=shift;
                   $blk->[4]="transparent";
                   if ($blk->[2] eq "on"){
                      $blk->[4]="blue";
                      $blk->[4]="yellow" if ($blk->[3] eq "R");
                   }
                },
                group         =>'support',
                label         =>'support',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'issupport',
                group         =>'characteristic',
                label         =>'support active',
                container     =>'additional'),

      new kernel::Field::TimeSpans(
                name          =>'serivce',
                htmlwidth     =>'150px',
                depend        =>['isservice'],
                tspantype     =>{''=>'core time',
                                 'K'=>'core time',
                                 'R'=>'border time'},
                tspantypeproc =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $blk=shift;
                   $blk->[4]="transparent";
                   if ($blk->[2] eq "on"){
                      $blk->[4]="blue";
                      $blk->[4]="yellow" if ($blk->[3] eq "R");
                   }
                },
                group         =>'service',
                label         =>'service',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'isservice',
                group         =>'characteristic',
                label         =>'service active',
                container     =>'additional'),

      new kernel::Field::TimeSpans(
                name          =>'callcenter',
                htmlwidth     =>'150px',
                depend        =>['iscallcenter'],
                group         =>'callcenter',
                label         =>'callcenter',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'iscallcenter',
                group         =>'characteristic',
                label         =>'callcenter active',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'issaprelation',
                group         =>'characteristic',
                label         =>'SAP relation posible',
                container     =>'additional'),

      new kernel::Field::Text(
                name          =>'sapcompanycode',
                label         =>'SAP Company Code',
                group         =>'saprelation',
                depend        =>['issaprelation'],
                dataobjattr   =>'servicesupport.sapcompanycode'),

      new kernel::Field::Text(
                name          =>'sapservicename',
                label         =>'SAP Service name',
                depend        =>['issaprelation'],
                group         =>'saprelation',
                dataobjattr   =>'servicesupport.sapservicename'),

      new kernel::Field::Textarea(
                name          =>'servicedescription',
                group         =>'finance',
                label         =>'Service description',
                container     =>'additional'),

      new kernel::Field::Number(
                name          =>'flathourscost',
                precision     =>2,
                unit          =>'h',
                group         =>'finance',
                label         =>'Flat hours per month (external)',
                dataobjattr   =>'servicesupport.flathourscost'),

      new kernel::Field::Number(
                name          =>'iflathourscost',
                precision     =>2,
                unit          =>'h',
                group         =>'finance',
                label         =>'Flat hours per month (internal)',
                dataobjattr   =>'servicesupport.iflathourscost'),

      new kernel::Field::Number(
                name          =>'usecountitilappl',
                precision     =>0,
                htmldetail    =>0,
                group         =>'usecount',
                label         =>'usage in itil::appl',
                dataobjattr   =>"(select count(*) from appl ".
                                "where ".
                                "appl.servicesupport=servicesupport.id ".
                                "and appl.cistatus<6 ".
                                "and appl.cistatus>1)"),

      new kernel::Field::Number(
                name          =>'usecountitilsystem',
                precision     =>0,
                htmldetail    =>0,
                group         =>'usecount',
                label         =>'usage in itil::system',
                dataobjattr   =>"(select count(*) from system ".
                                "where ".
                                "system.servicesupport=servicesupport.id ".
                                "and system.cistatus<6 ".
                                "and system.cistatus>1)"),

      new kernel::Field::Number(
                name          =>'usecountitilasset',
                precision     =>0,
                htmldetail    =>0,
                group         =>'usecount',
                label         =>'usage in itil::asset',
                dataobjattr   =>"(select count(*) from asset ".
                                "where ".
                                "asset.prodmaintlevel=servicesupport.id ".
                                "and asset.cistatus<6 ".
                                "and asset.cistatus>1)"),

      new kernel::Field::Number(
                name          =>'usecountitilswinstance',
                precision     =>0,
                htmldetail    =>0,
                group         =>'usecount',
                label         =>'usage in itil::swinstance',
                dataobjattr   =>"(select count(*) from swinstance ".
                                "where ".
                                "swinstance.servicesupport=servicesupport.id ".
                                "and swinstance.cistatus<6 ".
                                "and swinstance.cistatus>1)"),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                uivisible     =>0,
                dataobjattr   =>'servicesupport.additional'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'servicesupport.comments'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'servicesupport.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'servicesupport.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'servicesupport.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"servicesupport.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(servicesupport.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'servicesupport.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'servicesupport.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'servicesupport.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'servicesupport.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'servicesupport.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'servicesupport.realeditor'),
   
      new kernel::Field::RecordUrl(),
   );
   $self->setDefaultView(qw(name cistatus mdate cdate));
   $self->setWorktable("servicesupport");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.itil.servicesupport"],
                         uniquesize=>255};
   return($self);
}

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default responsibility contacts characteristic 
             finance oncallservice support service 
             callcenter saprelation source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   
   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!$self->IsMemberOf("admin")){
      if (defined($oldrec) && $oldrec->{cistatusid}>2 &&
          (effChanged($oldrec,$newrec,"name"))){
         $self->LastMsg(ERROR,"you are not authorized to change ".
                              "cistatus or name");
         return(undef);
      }
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

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
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
   my @blklist;
   my $databoss=0;

   my $userid=$self->getCurrentUserId();
   if (!defined($rec)){
      push(@blklist,"default","characteristic","responsibility");
   }
   if (defined($rec) && ($rec->{databossid} eq $userid ||
                         $rec->{databoss2id} eq $userid)){
      $databoss++;
   }
   elsif (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
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
         if (grep(/^write$/,@roles)){
            $databoss++;
         }
      }
   }

   push(@blklist,"default","characteristic","contacts",
                 "responsibility") if ($self->IsMemberOf("admin")||$databoss);
   if (!defined($rec) || ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
       $self->IsMemberOf($self->{CI_Handling}->{activator})){
      push(@blklist,"default","characteristic","responsibility","finance",
                    "saprelation");
   }
   if (grep(/^default$/,@blklist) && defined($rec)){
      foreach my $grp (qw(service oncallservice support callcenter 
                          saprelation)){
         push(@blklist,$grp) if ($rec->{"is".$grp});
      }
      push(@blklist,"finance");
   }
   return(@blklist);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @param=@_;
   my @adds=();
   return("header","default","responsibility",
          "characteristic") if (!defined($rec));
   foreach my $grp (qw(service oncallservice support callcenter saprelation)){
      push(@adds,$grp) if ($rec->{"is".$grp});
   }
   my $userid=$self->getCurrentUserId();
   if ($rec->{databossid} eq $userid ||
       $rec->{databoss2id} eq $userid ||
       $self->IsMemberOf("admin")){
      push(@adds,"finance");
   }
   else{
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      if (grep(/^$rec->{mandatorid}$/,@mandators)){
         push(@adds,"finance");
      }
   }

   return("header","default","responsibility","characteristic","contacts",
          "source","history","usecount",@adds);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/service_support.jpg?".$cgi->query_string());
}

1;
