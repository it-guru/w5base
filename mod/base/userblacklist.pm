package base::userblacklist;
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
use kernel::App::Web::Listedit;
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
                dataobjattr   =>'userblacklist.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Fullname',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"concat(".
                   "if (userblacklist.email is null,'',userblacklist.email),".
                   "'|',".
                   "if (userblacklist.posix_identifier is null,".
                   "'',userblacklist.posix_identifier),".
                   "'|',".
                   "if (userblacklist.account is null,'',".
                   "userblacklist.posix_identifier))"),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'E-Mail',
                dataobjattr   =>'userblacklist.email'),

      new kernel::Field::Text(
                name          =>'posix',
                label         =>'POSIX-Identifier',
                dataobjattr   =>'userblacklist.posix_identifier'),

      new kernel::Field::Text(
                name          =>'useraccount',
                label         =>'User-Account',
                dataobjattr   =>'userblacklist.account'),

      new kernel::Field::Boolean(
                name          =>'lockorgtransfer',
                group         =>'flags',
                label         =>'lock automatic organisational transfer',
                dataobjattr   =>'userblacklist.lockorgtransfer'),

#      new kernel::Field::Boolean(
#                name          =>'lockcontactcreate',
#                group         =>'flags',
#                label         =>'lock create of contact',
#                dataobjattr   =>'userblacklist.lockcontactcreate'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'userblacklist.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'userblacklist.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'userblacklist.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'userblacklist.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'userblacklist.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'userblacklist.realeditor'),

   );
   $self->setDefaultView(qw(linenumber fullname cdate mdate));
   $self->setWorktable("userblacklist");
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $email=trim(effVal($oldrec,$newrec,"email"));
   my $posix=trim(effVal($oldrec,$newrec,"posix"));
   my $account=trim(effVal($oldrec,$newrec,"useraccount"));
   if (($email=~m/^\s*$/i) &&
       ($posix=~m/^\s*$/i) &&
       ($account=~m/^\s*$/i)){
      $self->LastMsg(ERROR,"invalid blacklist key criteria"); 
      return(undef);
   }
   if ($email eq ""){
      $newrec->{email}=undef;
   }
   if ($posix eq ""){
      $newrec->{posix}=undef;
   }
   if ($account eq ""){
      $newrec->{useraccount}=undef;
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default","flags") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL") if ($self->IsMemberOf("admin"));
   return();
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","flags") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","flags","source");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/userblacklist.jpg?".$cgi->query_string());
}


sub checkLock
{
   my $self=shift;
   my $lockname=shift;
   my $filter=shift;

   $self->ResetFilter();
   $self->SetFilter($filter);
   foreach my $lckrec ($self->getHashList(qw(ALL))){
      if (!exists($lckrec->{$lockname})){
         msg(ERROR,"invalid request to check '$lockname' against blacklist");
         return(1);
      }
      else{
         if ($lckrec->{$lockname}){
            $self->Log(INFO,"blacklist",
               "applied lock on $lockname at blacklist '".$lckrec->{fullname}.
               "'");
            return(1);
         }
      }
   }
   return(0);
}









1;
