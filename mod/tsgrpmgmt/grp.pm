package tsgrpmgmt::grp;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
        kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;
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
                dataobjattr   =>'metagrpmgmt.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                dataobjattr   =>'metagrpmgmt.fullname'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                readonly      =>1,
                dataobjattr   =>'metagrpmgmt.name'),

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
                dataobjattr   =>'metagrpmgmt.cistatus'),

      new kernel::Field::Date(
                name          =>'chkdate',
                history       =>0,
                sqlorder      =>'asc',
                group         =>'chk',
                label         =>'last check date',
                dataobjattr   =>'metagrpmgmt.chkdate'),

      new kernel::Field::Text(
                name          =>'smid',
                group         =>'ref',
                binary        =>1,
                weblinkto     =>'tssm::group',
                weblinkon     =>['smid'=>'id'],
                label         =>'GroupID in ServiceManager',
                dataobjattr   =>'metagrpmgmt.smid'),

      new kernel::Field::Date(
                name          =>'smdate',
                group         =>'ref',
                history       =>0,
                label         =>'Group seen in ServiceManager',
                dataobjattr   =>'metagrpmgmt.smdate'),

      new kernel::Field::Text(
                name          =>'smadmgrp',
                group         =>'ref',
                label         =>'Admin Group in ServiceManager',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>'metagrpmgmt.smadmgrp'),

      new kernel::Field::Text(
                name          =>'snid',
                group         =>'ref',
                weblinkto     =>'SMNow::sys_user_group',
                weblinkon     =>['snid'=>'sys_id'],
                label         =>'Group Sys_Id in SMNow',
                dataobjattr   =>'metagrpmgmt.snid'),

      new kernel::Field::Date(
                name          =>'sndate',
                group         =>'ref',
                history       =>0,
                label         =>'Group seen in SMNow',
                dataobjattr   =>'metagrpmgmt.sndate'),

      new kernel::Field::Text(
                name          =>'amid',
                group         =>'ref',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['amid'=>'lgroupid'],
                label         =>'GroupID in AssetManager',
                dataobjattr   =>'metagrpmgmt.amid'),

      new kernel::Field::Date(
                name          =>'amdate',
                group         =>'ref',
                history       =>0,
                label         =>'Group seen in AssetManager',
                dataobjattr   =>'metagrpmgmt.amdate'),

      new kernel::Field::Email(
                name          =>'contactemail',
                group         =>'ref',
                label         =>'Contact EMail',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (exists($param{current}) &&
                       $param{current}->{$self->{name}} ne ""){
                      return(1);
                   }
                   return(0);
                },
                dataobjattr   =>'metagrpmgmt.contactemail'),

      new kernel::Field::Boolean(
                name          =>'ischmapprov',
                label         =>'is change approver group',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_chmapprov'),

      new kernel::Field::Boolean(
                name          =>'ischmimpl',
                label         =>'is change implementor group',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_chmimpl'),

      new kernel::Field::Boolean(
                name          =>'ischmmgr',
                label         =>'is change manager group',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_chmmgr'),

      new kernel::Field::Boolean(
                name          =>'ischmcoord',
                label         =>'is change coordinator group',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_chmcoord'),

      new kernel::Field::Boolean(
                name          =>'isinmassign',
                label         =>'is incident assinment group',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_inmassign'),

      new kernel::Field::Boolean(
                name          =>'iscfmassign',
                label         =>'is config assinment group',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_cfmassign'),

      new kernel::Field::Boolean(
                name          =>'isresp4all',
                label         =>'is responsilbe for all',
                allowempty    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>'is_resp4all'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                group         =>'chk',
                htmldetail    =>'NotEmpty',
                searchable    =>1,
                dataobjattr   =>'metagrpmgmt.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'metagrpmgmt.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'metagrpmgmt.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'metagrpmgmt.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'metagrpmgmt.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'metagrpmgmt.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'metagrpmgmt.realeditor'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'metagrpmgmt.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'metagrpmgmt.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'metagrpmgmt.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"metagrpmgmt.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(metagrpmgmt.id,35,'0')"),

   );
   $self->setDefaultView(qw(linenumber fullname mdate));
   $self->setWorktable("metagrpmgmt");
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

sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return(qw(header default grouptype ref chk source));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/group.jpg?".$cgi->query_string());
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (exists($newrec->{fullname}) && $newrec->{fullname} eq ""){
      msg(WARN,"write request with invalid fullname $self: ".
               Dumper($newrec));
      delete($newrec->{fullname});  # ensure remove wrong write requests
   }

   my $fullname=effVal($oldrec,$newrec,"fullname");
   my $name=$fullname;
   $name=~s/^.*\.//;
   $name=~s/\[.*$//;
   if (effVal($oldrec,$newrec,"name") ne $name && $name ne ""){
      $newrec->{name}=$name;
   }
   if (effVal($oldrec,$newrec,"chkdate") eq ""){
      $newrec->{chkdate}="2000-01-01 00:00:00";
   }
   if (effVal($oldrec,$newrec,"name") eq ""){
      $self->LastMsg(ERROR,"invalid MetaAssigment name");
      printf STDERR ("write request: oldrec=%s\n newrec=%s\n",
                     Dumper($oldrec),Dumper($newrec));
      return(0);
   }

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,
                                                    "fullname"));

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
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}


sub isCopyValid
{
   my $self=shift;
   my $copyfrom=shift;
   return(0);
}






1;
