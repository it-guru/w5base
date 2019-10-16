package tssm::group;
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
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Group ID',
                dataobjattr   =>'assignmentm1.name'),

      new kernel::Field::Link(
                name          =>'groupid',
                label         =>'GroupId',
                uppersearch   =>1,
                dataobjattr   =>'assignmentm1.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                ignorecase    =>1,
                searchable    =>0,
                dataobjattr   =>'assignmentm1.name'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'assignmentm1.name'),

      new kernel::Field::Boolean(
                name          =>'active',
                label         =>'active',
                dataobjattr   =>"decode(assignmentm1.tsi_inactive,'t',0,1)"),


#      new kernel::Field::TextDrop(
#                name          =>'supervisor',
#                label         =>'Supervisor',
#                searchable    =>0,
#                vjointo       =>'tsacinv::user',
#                vjoinon       =>['supervid'=>'lempldeptid'],
#                vjoindisp     =>'fullname'),

      new kernel::Field::Text(
                name          =>'supervisor', # leider keine richtige reference
                label         =>'Supervisor',
                dataobjattr   =>'assignmentm1.wdmanagername'),


      new kernel::Field::Email(
                name          =>'groupmailbox',
                label         =>'group mailbox',
                ignorecase    =>1,
                dataobjattr   =>'assignmentm1.tsi_group_email'),

      new kernel::Field::SubList(
                name          =>'users',
                label         =>'Users',
                group         =>'users',
                forwardSearch =>1,
                searchable    =>0,
                vjointo       =>'tssm::lnkusergroup',
                vjoinon       =>['groupid'=>'lgroup'],
                vjoindisp     =>['username','luser']),

      new kernel::Field::SubList(
                name          =>'loginname',
                translation   =>'tssm::user',
                label         =>'member User-Logins',
                group         =>'users',
                htmldetail    =>0,
                vjointo       =>'tssm::lnkusergroup',
                vjoinon       =>['groupid'=>'lgroup'],
                vjoindisp     =>['luser']),

      new kernel::Field::SubList(
                name          =>'memberemails',
                label         =>'member email addresses',
                group         =>'users',
                searchable    =>1,
                htmldetail    =>0,
                vjointo       =>'tssm::lnkusergroup',
                vjoinon       =>['groupid'=>'lgroup'],
                vjoindisp     =>['useremail']),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                ignorecase    =>1,
                dataobjattr   =>'assignmentm1.tsi_description'),

      new kernel::Field::Boolean(
                name          =>'ismanager',
                label         =>'is change manager group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_flag_chm_manager,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isapprover',
                label         =>'is approver group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_flag_chm_approver,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isimplementor',
                label         =>'is implementor group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_flag_chm_implementer,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'iscoordinator',
                label         =>'is coordinator group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_flag_chm_coordinator,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'ischmassignment',
                label         =>'is change assignment group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_flag_type_change,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isinmassignment',
                label         =>'is incident assignment group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_flag_type_incident,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isreviewer',
                label         =>'is reviewer group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_chm_flag_reviewer,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isinmremote',
                label         =>'is incident remote group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_interface_name,NULL,0,1)"),

      new kernel::Field::Boolean(
                name          =>'ischmremote',
                label         =>'is change remote group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_chm_interface_name,NULL,0,1)"),

      new kernel::Field::Boolean(
                name          =>'isrespall',
                label         =>'is responsilbe for all',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(assignmentm1.tsi_resp_all,'t',1,0)"),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'assignmentm1.sysmodtime'),

      new kernel::Field::Text(
                name          =>'admingroup',
                group         =>'source',
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
                label         =>'Admin-Group',
                dataobjattr   =>'assignmentm1.tsi_responsible_group'),

      new kernel::Field::TextDrop(
                name          =>'editor',
                group         =>'source',
                weblinkto     =>'tssm::useraccount',
                weblinkon     =>['editor'=>'loginname'],
                label         =>'Editor Account',
                dataobjattr   =>'assignmentm1.sysmoduser'),


   );
   $self->setDefaultView(qw(name description));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/group.jpg?".$cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="dh_assignmentm1 assignmentm1";
   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_active"))){
     Query->Param("search_active"=>"\"".$self->T("boolean.true")."\"");
   }
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","control","grouptype","users","source");
}

sub isQualityCheckValid
{
   return(0);
}





1;
