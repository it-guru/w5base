package itil::systemjob;
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'systemjob.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'systemjob.name'),

      new kernel::Field::Textarea(
                name          =>'pcode',
                label         =>'Programm Code',
                dataobjattr   =>'systemjob.code'),

      new kernel::Field::Textarea(
                name          =>'param',
                label         =>'Programm Parameter',
                dataobjattr   =>'systemjob.param'),

      new kernel::Field::SubList(
                name          =>'acls',
                label         =>'Accesscontrol',
                subeditmsk    =>'subedit.systemjob',
                group         =>'acl',
                allowcleanup  =>1,
                vjoininhash   =>[qw(acltarget acltargetid aclmode)],
                vjointo       =>'itil::systemjobacl',
                vjoinbase     =>[{'aclparentobj'=>\'itil::systemjob'}],
                vjoinon       =>['id'=>'refid'],
                vjoindisp     =>['acltargetname','aclmode']),

      new kernel::Field::Text(
                name          =>'defaultremoteuser',
                group         =>'control',
                label         =>'default Remote-User',
                dataobjattr   =>'systemjob.remoteuser'),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                allowcleanup  =>1,
                vjointo       =>'itil::lnksystemjobsystem',
                vjoinon       =>['id'=>'jobid'],
                vjoindisp     =>['system']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'systemjob.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'systemjob.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'systemjob.createuser'),

      new kernel::Field::Owner(
                name          =>'ownername',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'systemjob.modifyuser'),

      new kernel::Field::Link(
                name          =>'owner',
                group         =>'source',
                label         =>'OwnerID',
                dataobjattr   =>'systemjob.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'systemjob.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'systemjob.realeditor'),

      new kernel::Field::Link(
                name          =>'aclmode',
                selectable    =>0,
                dataobjattr   =>'systemjobacl.aclmode'),

      new kernel::Field::Link(
                name          =>'acltarget',
                selectable    =>0,
                dataobjattr   =>'systemjobacl.acltarget'),

      new kernel::Field::Link(
                name          =>'acltargetid',
                selectable    =>0,
                dataobjattr   =>'systemjobacl.acltargetid'),

   );
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(linenumber name cistatus cdate mdate));
   $self->setWorktable("systemjob");
   return($self);
}

sub SecureSetFilter
{
   my $self=shift;
   if (!$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      my %groups=$self->getGroupsOf($ENV{REMOTE_USER},'RMember','both');
      return($self->SUPER::SecureSetFilter([{owner=>\$userid},
                                            {aclmode=>['write','read','run'],
                                             acltarget=>\'base::user',
                                             acltargetid=>[$userid]},
                                            {aclmode=>['write','read','run'],
                                             acltarget=>\'base::grp',
                                             acltargetid=>[keys(%groups)]},
                                            ],@_));
   }
   return($self->SUPER::SecureSetFilter(@_));
}



sub getSqlFrom
{
   my $self=shift;
   my $from="systemjob left outer join systemjobacl ".
            "on systemjob.id=systemjobacl.refid";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   $newrec->{'name'}=$name;
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("header","default") if (!defined($rec));

   return("ALL");
   #return("ALL") if ($userid==$rec->{owner});
   return(undef);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   return("default") if (!defined($rec));

   my $writeok=0;


   $writeok=1 if (!$writeok && $rec->{owner}==$userid);
   $writeok=1 if (!$writeok && $self->IsMemberOf("admin"));
   if (!$writeok){
      my @acl=$self->getCurrentAclModes($ENV{REMOTE_USER},$rec->{acls});
      $writeok=1 if (grep(/^write$/,@acl));
   }
   return("default","acl","control") if ($writeok);
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default acl systems control source));
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/systemjob.jpg?".$cgi->query_string());
}






1;
