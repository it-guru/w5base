package tssc::group;
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
#   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Group ID',
                dataobjattr   =>'dsccentralassignmentm1.unique_id'),

      new kernel::Field::Link(
                name          =>'groupid',
                label         =>'GroupId',
                uppersearch   =>1,
                dataobjattr   =>'dsccentralassignmentm1.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                uivisible     =>0,
                searchable    =>0,
                dataobjattr   =>'dsccentralassignmentm1.name'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                ignorecase    =>1,
                dataobjattr   =>'dsccentralassignmentm1.name'),


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
                dataobjattr   =>'dsccentralassignmentm1.assgrp_response'),


      new kernel::Field::Email(
                name          =>'groupmailbox',
                label         =>'group mailbox',
                ignorecase    =>1,
                dataobjattr   =>'dsccentralassignmentm1.email_address'),

      new kernel::Field::SubList(
                name          =>'users',
                label         =>'Users',
                group         =>'users',
                forwardSearch =>1,
                searchable    =>0,
                vjointo       =>'tssc::lnkusergroup',
                vjoinon       =>['groupid'=>'lgroup'],
                vjoindisp     =>['username','luser']),

      new kernel::Field::SubList(
                name          =>'loginname',
                translation   =>'tssc::user',
                label         =>'User-Login',
                group         =>'users',
                htmldetail    =>0,
                vjointo       =>'tssc::lnkusergroup',
                vjoinon       =>['groupid'=>'lgroup'],
                vjoindisp     =>['luser']),

      new kernel::Field::SubList(
                name          =>'memberemails',
                label         =>'member email addresses',
                group         =>'users',
                searchable    =>0,
                htmldetail    =>0,
                vjointo       =>'tssc::lnkusergroup',
                vjoinon       =>['groupid'=>'lgroup'],
                vjoindisp     =>['useremail']),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                ignorecase    =>1,
                dataobjattr   =>'dsccentralassignmentm1.brief_description'),

      new kernel::Field::Boolean(
                name          =>'ismanager',
                label         =>'is manager group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(dsccentralassignmentm1.group_type_manager,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isapprover',
                label         =>'is approver group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(dsccentralassignmentm1.group_type_approver,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isassignment',
                label         =>'is assignment group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(dsccentralassignmentm1.group_type_assignment,'t',1,0)"),

      new kernel::Field::Boolean(
                name          =>'isreviewer',
                label         =>'is reviewer group',
                ignorecase    =>1,
                group         =>'grouptype',
                htmlhalfwidth =>1,
                dataobjattr   =>
                "decode(dsccentralassignmentm1.group_type_reviewer,'t',1,0)"),

   );
   $self->setDefaultView(qw(id name description));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");
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
   my $from="scadm1.dsccentralassignmentm1";
   return($from);
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
   return("header","default","control","users");
}




1;
