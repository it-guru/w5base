package article::catalog;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use kernel::MandatorDataACL;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::MandatorDataACL kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                group         =>'source',
                sqlorder      =>'none',
                dataobjattr   =>'artcatalog.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Catalog',
                depend        =>['frontlabel'],
                htmldetail    =>0,
                readonly      =>1,
                multilang     =>1,
                dataobjattr   =>'artcatalog.frontlabel'), 
#                onRawValue    =>sub{
#                   my $self=shift;
#                   my $current=shift;
#                   my $l=$self->getParent->Lang();
#                   return(extractLangEntry($current->{'frontlabel'},$l,80,0));
#                }),

      new kernel::Field::Textarea(
                name          =>'frontlabel',
                label         =>'Catalog label',
                htmlheight    =>50,
                dataobjattr   =>'artcatalog.frontlabel'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Catalog description',
                dataobjattr   =>'artcatalog.description'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoineditbase =>{id=>">0"},
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'artcatalog.cistatus'),

      new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'artcatalog.mandator'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'artcatalog.databoss'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::SubList(
                name          =>'categories',
                label         =>'Categories',
                group         =>'categories',
                vjointo       =>'article::category',
                vjoinon       =>['id'=>'catalogid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'article::catalog',
                group         =>'attachments'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'artcatalog.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'artcatalog.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'artcatalog.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'artcatalog.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'artcatalog.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artcatalog.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artcatalog.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artcatalog.realeditor'),

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
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(fullname name cdate));
   $self->setWorktable("artcatalog");
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/article/load/catalog.jpg?".$cgi->query_string());
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","categories","contacts","attachments","source");
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.article.admin)],"RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RODManager RODManager2 
                                         RODOperator
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles* *roles=?order?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles* *roles=?order?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
            {mandatorid=>\@mandators},
            {databossid=>\$userid}
         );
      }
      push(@flt,\@addflt);

   }
   return($self->SetFilter(@flt));
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
            "and $worktable.id=lnkcontact.refid";

   return($from);
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

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

   my $name=effVal($oldrec,$newrec,"frontlabel");
   if ($name eq ""){
      $self->LastMsg(ERROR,"invalid label '\%s' specified",$name);
      return(undef);
   }


   return(1);
}


sub isCatalogWriteValid
{
   my $self=shift;
   my $id=shift;

   $self->ResetFilter();
   $self->SetFilter({id=>\$id});
   my ($crec,$msg)=$self->getOnlyFirst(qw(ALL));
   if (defined($crec)){
      my @l=$self->isWriteValid($crec);
      return(1) if (in_array(\@l,[qw(ALL default)]));
   }
   return();
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();
   my @admedit=qw(default contacts attachments);
   my $write=0;

   if (!defined($rec)){
      $write++;
   }
   else{
      if (!$write &&
          $self->IsMemberOf(["admin"])){
         $write++;
      }
      if (!$write &&
          $rec->{databossid} eq $userid){
         $write++;
      }
      if (!$write &&
          defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
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
               $write++;
            }
         }
      }
   }
   if ($write){
      return($self->expandByDataACL($rec->{mandatorid},@admedit));
   }
   return();
}





1;
