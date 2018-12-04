package tsotc::sysreqfs;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>"id"),

      new kernel::Field::Link(
                name          =>'sysreqid',
                label         =>'sysreqid',
                dataobjattr   =>'sysreq'),

      new kernel::Field::Interface(
                name          =>'name',
                label         =>'sysreqid',
                dataobjattr   =>"concat(fsentry,'-',fssize)"),

      new kernel::Field::Text(
                name          =>'fsentry',
                editrange     =>[1,1024],
                htmlwidth     =>'400px',
                label         =>'Filesystem Entry',
                dataobjattr   =>'fsentry'),

      new kernel::Field::Number(
                name          =>'fssize',
                editrange     =>[1,1024],
                label         =>'Filesystem Size',
                unit          =>'GB',
                htmleditwidth =>'100px',
                dataobjattr   =>'fssize'),

      new kernel::Field::Text(
                name          =>'srcsys',
                selectfix     =>1,
                htmldetail    =>'NotEmpty',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Id',
                dataobjattr   =>'srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'Source-Load',
                dataobjattr   =>'srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'createdate'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'editor'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(id,35,'0')"),

   );
   $self->setDefaultView(qw(name reqstatus appl cpucount memory));
   $self->setWorktable("tsotc_sysreq_fs");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;


   if (effChanged($oldrec,$newrec,"sysreqid")){
      return(0);
   }

   my $sysreqid=effVal($oldrec,$newrec,"sysreqid");

   my $prec=$self->getSysReqRec($sysreqid);

   if (!defined($prec)){
      return(0);
   }

   my $p=$self->getPersistentModuleObject($self->Config,"tsotc::sysreq"); 
   my @l=$p->isWriteValid($prec);
   if (!in_array(\@l,[qw(storage ALL)])){
      $self->LastMsg(ERROR,"no write access");
      return(0);
   }

   if ($prec->{osclass} eq "WIN"){
      my $ent=effVal($oldrec,$newrec,"fsentry");
      if (!($ent=~m/^[a-z]:$/i)){
         $self->LastMsg(ERROR,"invalid fs entry for WIN systems");
         return(0);
      }
      if (uc($ent) ne $ent){
         $newrec->{fsentry}=uc($ent);
      }
   }
   else{
      my $ent=effVal($oldrec,$newrec,"fsentry");
      if (!($ent=~m/^\/[a-z_0-9\/]{0,128}$/i)){
         $self->LastMsg(ERROR,"invalid fs entry for UX systems");
         return(0);
      }
   }

   return(1);
}


sub getSysReqRec
{
   my $self=shift;
   my $id=shift;

   my $p=$self->getPersistentModuleObject($self->Config,"tsotc::sysreq"); 

   $p->SetFilter({id=>\$id});
   my ($prec)=$p->getOnlyFirst(qw(ALL));

   return($prec);
}






sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","storage");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/nfsnas.jpg?".$cgi->query_string());
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("default") if (!defined($rec));

   my $sysreqid=$rec->{sysreqid};
   my $prec=$self->getSysReqRec($sysreqid);

   if (!defined($prec)){
      return(undef);
   }
   my $p=$self->getPersistentModuleObject($self->Config,"tsotc::sysreq"); 
   my @l=$p->isWriteValid($prec);

   if (in_array(\@l,[qw(storage ALL)])){
      return("default");
   }
   return(undef);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


1;
