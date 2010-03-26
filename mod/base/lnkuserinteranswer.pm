package base::lnkuserinteranswer;
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
use base::interanswer;
@ISA=qw(base::interanswer);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'parentposix',
                htmlwidth     =>'100px',
                readonly      =>1,
                translation   =>'base::user',
                label         =>'POSIX-Identifier',
                vjointo       =>'base::user',
                vjoinon       =>['parentid'=>'userid'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'contact.posix_identifier'),
      insertafter=>'id'
   );
   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'parentname',
                htmlwidth     =>'100px',
                readonly      =>sub{
                   my $self=shift;
                   my $current=shift;
                   return(1) if (defined($current));
                   return(0);
                },
                label         =>'Contact',
                vjointo       =>'base::user',
                vjoinon       =>['parentid'=>'userid'],
                vjoindisp     =>'fullname',
                dataobjattr   =>'contact.fullname'),
      insertafter=>'id'
   );
   $self->AddFields(
      new kernel::Field::Link(
                name          =>'userid',
                readonly      =>1,
                label         =>'UserID',
                dataobjattr   =>'contact.userid'),
      insertafter=>'id'
   );

   $self->AddFields(
      new kernel::Field::Import( $self,
                vjointo       =>'base::user',
                dontrename    =>1,
                group         =>'relation',
                fields        =>[qw(orgunits
                                    )]),
      insertafter=>'parentname'
   );



   $self->getField("parentobj")->{searchable}=0;
   $self->getField("parentid")->{searchable}=0;
   $self->{secparentobj}='base::user';
   $self->{analyticview}=['fullname','interviewst'];
   $self->setDefaultView(qw(parentname relevant name answer mdate editor));
   return($self);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin")){
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                  ['RBoss','RBoss2','RBackoffice'],"direct");
      my $lnkgrp=getModuleObject($self->Config,"base::lnkgrpuser");
     
      $lnkgrp->SetFilter({grpid=>[keys(%grps)]});
      my $d=$lnkgrp->getHashIndexed(qw(userid));
      my @user;
      push(@user,keys(%{$d->{userid}})) if (ref($d->{userid}) eq "HASH");
      my $userid=$self->getCurrentUserId();
      push(@user,$userid) if ($userid ne "");
      if ($#user==-1){
         push(@user,-99);
      }
      push(@flt,[ {userid=>\@user}]);
   }
   return($self->SetFilter(@flt));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   my $secobj=$self->{secparentobj};

   return("contact left outer join $worktable ".
          "on $worktable.parentobj='$secobj' and ".
          "$worktable.parentid=contact.userid ".
          "left outer join interview ".
          "on $worktable.interviewid=interview.id ");
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="(contact.cistatus<=5 and contact.usertyp='user')";
   return($where);
}



1;
