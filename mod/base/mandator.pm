package base::mandator;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{history}={
      update=>[
         'local'
      ]
   };

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'mandator.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Mandator',
                dataobjattr   =>'mandator.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0 AND <7"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'mandator.cistatus'),

      new kernel::Field::Group(
                name          =>'groupname',
                label         =>'Groupname',
                vjoinon       =>['grpid'=>'grpid'],
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(0) if (!defined($rec));
                   return(1);
                },
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'grpid',
                dataobjattr   =>'mandator.grpid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'mandator.comments'),

      new kernel::Field::Number(
                name          =>'usercount',
                label         =>'Employee count',
                depend        =>['grpid'],
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my @n=$self->getParent->getMembersOf($current->{grpid},
                                                      "REmployee","down");
                   return($#n+1);
                }),

      new kernel::Field::Number(
                name          =>'orgusercount',
                label         =>'organisational user contact count',
                depend        =>['grpid'],
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $fld=$self->getParent->getField("groupname");
                   my $group=$fld->RawValue($current);
                   my $n=undef;
                   if ($group ne ""){
                      my $o=$app->getPersistentModuleObject("base::lnkgrpuser");


                      $o->SetFilter({group=>"$group $group.*",
                                     rawnativroles=>[orgRoles()],
                                     grpcistatusid=>\'4',
                                     usercistatusid=>\'4'});
                      $o->SetCurrentView(qw(userid grpid nativroles));
                      my $d=$o->getHashIndexed(qw(userid));
                      if (exists($d->{userid}) && ref($d->{userid}) eq "HASH"){
                         $n=keys(%{$d->{userid}});
                      }
                   }
                   return($n);
                }),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                class         =>'mandator',
                vjoindisp     =>[qw(targetname targetweblink comments roles)],
                vjoininhash   =>['targetid','target','roles'],
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'dataacls',
                label         =>'DataACLs',
                group         =>'dataacls',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.mandator',
                vjointo       =>'base::mandatordataacl',
                vjoinon       =>['id'=>'mid'],
                vjoindisp     =>[qw(parentobj dataname prio aclmode targetname)],
                vjoininhash   =>['mandatorid','parentobj',
                                 'dataname','prio','target','targetid','aclmode']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'mandator.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'mandator.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'mandator.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'mandator.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'mandator.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'mandator.realeditor'),

      new kernel::Field::Container(
                name       =>'additional',
                dataobjattr=>'mandator.additional'),

      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'mandator.lastqcheck'),
      new kernel::Field::QualityResponseArea(),
   );
   $self->setDefaultView(qw(linenumber name groupname cistatus cdate mdate));
   $self->setWorktable("mandator");
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default contacts dataacls source));
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/mandator.jpg?".$cgi->query_string());
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   if ($name=~m/[^a-z0-9 _-]/i){
      $self->LastMsg(ERROR,"invalid mandator '%s' specified",$name); 
      return(undef);
   }
   $newrec->{'name'}=$name;
   my $grpid=trim(effVal($oldrec,$newrec,"grpid"));
   if ($grpid==0){
      $self->LastMsg(ERROR,"invalid group"); 
      return(undef);
   }
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
   return("default","contacts","dataacls") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateMandatorCache();
   return($bak);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   $self->InvalidateMandatorCache();
   return($bak);
}




1;
