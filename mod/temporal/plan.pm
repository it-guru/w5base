package temporal::plan;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                htmldetail    =>sub{
                   my ($self,$mode,%param)=@_;
                   return(defined($param{current}) ? 1 : 0);
                },
                label         =>'W5BaseID',
                dataobjattr   =>'timeplan.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'timeplan name',
                dataobjattr   =>'timeplan.name'),

      new kernel::Field::Mandator(allowany=>1),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'timeplan.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                default       =>'4',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'timeplan.cistatus'),

      new kernel::Field::Select(
                name          =>'planclass',
                label         =>'timeplan class',
                value         =>[qw( 
                                     TCLASS.measureplan
                                     TCLASS.holiday
                                     TCLASS.vacation
                                     TCLASS.unknown
                                 )],
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                dataobjattr   =>'timeplan.tmode'),

      new kernel::Field::Select(
                name          =>'tz',
                label         =>'Timezone',
                value         =>['CET','GMT',DateTime::TimeZone::all_names()],
                dataobjattr   =>'timeplan.timezone'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'timeplan.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'timeplan.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'timeplan.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'timeplan.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'timeplan.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'timeplan.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'timeplan.realeditor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"timeplan.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(timeplan.id,35,'0')"),

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

   );
   $self->setDefaultView(qw(linenumber name cistatus tz mdate));
   $self->setWorktable("timeplan");
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

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default contacts source));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/temporal/load/plan.jpg?".$cgi->query_string());
}


sub isWriteOnPlanValid
{
   my $self=shift;
   my $planid=shift;

   my $plan=$self->getPersistentModuleObject("temporal::plan");
   my %grps=$self->getGroupsOf($ENV{REMOTE_USER},[qw(RMember)],"up");
   my @grpids=keys(%grps);

   my $userid=$self->getCurrentUserId();
   my @addflt=(
              {sectargetid=>\$userid,sectarget=>\'base::user',
               secroles=>"*roles=?write?=roles*"},
              {sectargetid=>\@grpids,sectarget=>\'base::grp',
               secroles=>"*roles=?write?=roles*" }
             );
   $plan->SetFilter({id=>\$planid},\@addflt);
   my ($crec,$msg)=$plan->getOnlyFirst(qw(ALL));
   if ($self->IsMemberOf("admin")){
      return(1);
   }
   if (defined($crec)){
      return(1);
   }
   return(0);
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if ( !$self->IsMemberOf([qw(admin)], "RMember")){
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
         push(@addflt, {mandatorid=>\@mandators});
      }
      push(@flt,\@addflt);

   }
   if (!$self->isDirectFilter(@flt)){
      my @addflt=({cistatusid=>"!7"});
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((my $v=effVal($oldrec,$newrec,"name"))=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid internal name");
      return(undef);
   }

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","contacts") if ($self->IsMemberOf("admin"));


   return(undef);
}


sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(1);
}






1;
