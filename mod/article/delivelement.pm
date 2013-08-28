package article::delivelement;
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
                htmlwidth     =>'10px',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'id',
                label         =>'W5BaseID',
                group         =>'source',
                sqlorder      =>'none',
                dataobjattr   =>'artdelivelement.id'),

      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Productelement',
                dataobjattr   =>'concat(artdelivprovider.name,": "'.
                                ',artdelivelement.frontlabel)'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                dataobjattr   =>'artdelivelement.frontlabel'),

      new kernel::Field::Select(
                name          =>'provider',
                label         =>'Provider',
                vjointo       =>'article::delivprovider',
                vjoinon       =>['providerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'providerid',
                label         =>'ProviderID',
                dataobjattr   =>'artdelivelement.artdelivprovider'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Description',
                dataobjattr   =>'artdelivelement.description'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'mgmt',
                label         =>'Comments',
                dataobjattr   =>'artdelivelement.comments'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'artdelivelement.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'artdelivelement.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'artdelivelement.createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'artdelivelement.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'artdelivelement.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'artdelivelement.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'artdelivelement.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'artdelivelement.realeditor'),

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

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'artdelivprovider.mandator'),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'artdelivprovider.databoss'),
   );
   $self->{history}=[qw(insert modify delete)];
   $self->setDefaultView(qw(fullname name cdate));
   $self->setWorktable("artdelivelement");
   return($self);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/article/load/delivelement.jpg?".$cgi->query_string());
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","mgmt","source");
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();

   my $from="$worktable ".
            "left outer join artdelivprovider  ".
            "on artdelivelement.artdelivprovider=artdelivprovider.id ".
            "left outer join lnkcontact on lnkcontact.parentobj='article::delivprovider' ".
            "and artdelivprovider.id=lnkcontact.refid";
   return($from);
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
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?admin?=roles* ".
                            "*roles=?read?=roles*"}
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




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;


   if (defined($oldrec)){ # check write on old category
      my $cid=$oldrec->{providerid};
      my $c=getModuleObject($self->Config,"article::delivprovider");
      if (!$c->isProviderWriteValid($cid)){
         $self->LastMsg(ERROR,"you have no right to modify this element");
         return(0);
      }
   }
   if (defined($newrec)){ # check on modifikation of a record
      my $cid=effVal($oldrec,$newrec,"providerid");
      my $c=getModuleObject($self->Config,"article::delivprovider");
      if ($cid eq "" || !$c->isProviderWriteValid($cid)){
         $self->LastMsg(ERROR,"you have no right to write in given provider");
         return(0);
      }
   }

   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq ""){
      $self->LastMsg(ERROR,"invalid name '\%s' specified",
                     $name);
      return(undef);
   }
   return(1);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","mgmt") if (!defined($rec));

   my $cid=$rec->{providerid};
   my $c=getModuleObject($self->Config,"article::delivprovider");
   if ($c->isProviderWriteValid($cid)){
      return("default","mgmt");
   }

   return(undef);

   return(undef);
}





1;
