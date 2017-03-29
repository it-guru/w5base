package base::campus;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(        
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'campus.id'),
                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                htmldetail    =>'NotEmpty',
                readonly      =>1,
                dataobjattr   =>'campus.fullname'),

      new kernel::Field::Text(      
                name          =>'label',
                label         =>'Label',
                dataobjattr   =>'campus.label'),

      new kernel::Field::Text(
                name          =>'campusid',
                htmlwidth     =>'100px',
                htmleditwidth =>'150px',
                readonly     =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Campus ID',
                dataobjattr   =>'campus.campusid'),

      new kernel::Field::TextDrop(
                name          =>'location',
                label         =>'primary Location',
                vjointo       =>'base::location',
                vjoineditbase =>{cistatusid=>'4'},
                vjoinon       =>['locationid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'primary LocationID',
                htmlwidth     =>'200px',
                dataobjattr   =>'campus.locationid'),

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
                dataobjattr   =>'campus.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'campus.databoss'),

      new kernel::Field::TimeSpans(
                name          =>'usetimes',
                htmlwidth     =>'150px',
                depend        =>['issupport'],
                tspantype     =>{'M'=>'main use time',
                                 'S'=>'sec. use time',
                                 'O'=>'offline time'},
                tspantypeproc =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $mode=shift;
                   my $blk=shift;
                   $blk->[4]="transparent"; 
                   if ($blk->[2] eq "on" || $blk->[2] eq "legend"){
                      $blk->[4]="blue";
                      $blk->[4]="lightblue" if ($blk->[3] eq "S");
                      $blk->[4]="yellow" if ($blk->[3] eq "O");
                   }
                },
                tspantypemaper=>sub{
                   my $self=shift;
                   my $type=shift;
                   my $t=shift;
                   $type=uc($type);
                   #$type="M" if ($type eq "");
                   return($type);
                },
                tspanlegend   =>1,
                tspandaymap   =>[1,1,1,1,1,1,1,0],
                group         =>'mutimes',
                label         =>'use-times',
                dataobjattr   =>'campus.usetime'),

      new kernel::Field::Textarea(
                name          =>'tempexeptusetime',
                group         =>'mutimes',
                searchable    =>0,
                label         =>'temporary exeptions in use times',
                htmlheight    =>40,
                dataobjattr   =>'campus.tempexeptusetime'),

      new kernel::Field::SubList(
                name          =>'seclocations',
                label         =>'secondary locations',
                group         =>'seclocations',
                subeditmsk    =>'subedit.locations',
                forwardSearch =>1,
                vjointo       =>'base::lnkcampussubloc',
                vjoinon       =>['id'=>'pcampusid'],
                vjoindisp     =>['location']),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

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
                dataobjattr   =>'campus.additional'),

      new kernel::Field::Link(
                name          =>'isprim',
                label         =>'is primary Location',
                dataobjattr   =>'campus.isprim'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'campus.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'campus.modifydate'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'campus.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'campus.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'campus.srcload'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'campus.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'campus.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'campus.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'campus.realeditor'),

      new kernel::Field::IssueState(),

   );
   $self->setDefaultView(qw(fullname));
   $self->setWorktable("campus");
   return($self);
}


sub Validate
{
   my ($self,$oldrec,$newrec)=@_;

   my $locationid=effVal($oldrec,$newrec,"locationid");

   if ($locationid eq ""){
      $self->LastMsg(ERROR,"no primary Location specified"); 
      return(undef);
   }
   my $loc=getModuleObject($self->Config,"base::location");
   $loc->SetFilter({id=>\$locationid});
   my ($locrec)=$loc->getOnlyFirst(qw(country location));
   if (!defined($locrec)){
      $self->LastMsg(ERROR,"can not identify location record"); 
      return(undef);
   }
   my $label=effVal($oldrec,$newrec,"label");
   my $fullname=effVal($oldrec,$newrec,"fullname");
   my $newfullname="CAMPUS:".$locrec->{country}."-".$locrec->{location};
   if ($label ne ""){
      $newfullname.="-".$label;
   } 
   $newfullname=~s/ü/ue/g;
   $newfullname=~s/ö/oe/g;
   $newfullname=~s/ä/ae/g;
   $newfullname=~s/Ü/Ue/g;
   $newfullname=~s/Ö/Oe/g;
   $newfullname=~s/Ä/Ae/g;
   $newfullname=~s/ß/ss/g;
   $newfullname=~s/\s/_/g;
   $newfullname=~s/\s/_/g;
   if ($newfullname ne $fullname){
      $newrec->{fullname}=$newfullname;
   }

   $newrec->{isprim}='1';

   ########################################################################
   # standard security handling
   #
   my $userid=$self->getCurrentUserId();
   if (!defined($oldrec)){
      if (!defined($newrec->{databossid}) ||
          $newrec->{databossid}==0){
         my $userid=$self->getCurrentUserId();
         $newrec->{databossid}=$userid;
      }
   }
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }

   return($self->HandleCIStatusModification($oldrec,$newrec,"fullname"));
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="(campus.isprim='1')";
   return($where);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default mutimes contacts 
              seclocations source));
}




sub isViewValid
{
   my ($self,$rec)=@_;
   if (!defined($rec)){
      return("header","default");
   }
   return("ALL");
}

sub isWriteValid
{
   my ($self,$rec)=@_;
   return("default") if (!defined($rec));
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default contacts mutimes seclocations);
   if ($rec->{databossid}==$userid ||
       $self->IsMemberOf("admin")){
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
         if (grep(/^write$/,@roles)){
            return(@databossedit);
         }
      }
   }



   return(undef);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("base::campus");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/campus.jpg?".$cgi->query_string());
}

1;
