package itil::autodiscengine;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

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
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'autodiscengine.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmleditwidth =>'80px',
                label         =>'Name',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                dataobjattr   =>'autodiscengine.name'),

      new kernel::Field::Text(
                name          =>'fullname',
                htmlwidth     =>'250px',
                label         =>'fullname',
                dataobjattr   =>'autodiscengine.fullname'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                default       =>'4',
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'autodiscengine.cistatus'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'autodiscengine.comments'),

      new kernel::Field::Text(
                name          =>'localdataobj',
                htmlwidth     =>'250px',
                group         =>'autoimport',
                label         =>'local dataobject',
                dataobjattr   =>'autodiscengine.localdataobj'),

      new kernel::Field::Text(
                name          =>'localkey',
                htmlwidth     =>'250px',
                group         =>'autoimport',
                label         =>'local fieldname',
                dataobjattr   =>'autodiscengine.localkey'),

      new kernel::Field::Text(
                name          =>'addataobj',
                htmlwidth     =>'250px',
                group         =>'autoimport',
                label         =>'ad dataobject',
                dataobjattr   =>'autodiscengine.addataobj'),

      new kernel::Field::Text(
                name          =>'adkey',
                htmlwidth     =>'250px',
                group         =>'autoimport',
                label         =>'ad fieldname',
                dataobjattr   =>'autodiscengine.adkey'),

      new kernel::Field::Text(
                name          =>'adreccount',
                htmlwidth     =>'250px',
                readonly      =>1,
                group         =>'adstat',
                label         =>'current existing autodisc-records',
                dataobjattr   =>'(select count(*) from autodiscrec a '.
                                'join autodiscent on a.entryid=autodiscent.id '.
                                'where autodiscent.engine=autodiscengine.id)'),

      new kernel::Field::Text(
                name          =>'adent',
                htmlwidth     =>'250px',
                readonly      =>1,
                group         =>'adstat',
                label         =>'current autodisc affected config-items',
                dataobjattr   =>'(select count(*) from autodiscent '.
                                'where autodiscent.engine=autodiscengine.id)'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscengine.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'autodiscengine.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'autodiscengine.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'autodiscengine.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'autodiscengine.editor'),

      new kernel::Field::RealEditor( 
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'autodiscengine.realeditor'),
   

   );
   $self->setDefaultView(qw(name fullname cistatus mdate));
   $self->setWorktable("autodiscengine");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/autodiscengine.jpg?".$cgi->query_string());
#}

sub isCopyValid
{
   my $self=shift;

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default autoimport adstat source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","autoimport") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       !($newrec->{name}=~m/^[A-Z0-9_]+$/i)){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (exists($newrec->{localdataobj})){
      if ($newrec->{localdataobj} ne "itil::system" &&
          $newrec->{localdataobj} ne "itil::swinstance"){
         $self->LastMsg(ERROR,"invalid local dataobject specified");
         return(0);
      }
   }

   if (exists($newrec->{addataobj})){
      my $adobjname=effVal($oldrec,$newrec,"addataobj");
      my $adobj=getModuleObject($self->Config,$adobjname);
      if (!defined($adobj)){
         $self->LastMsg(ERROR, "invalid AutoDiscovery Dataobject");
         return(0);
      }
      if (!$adobj->can("extractAutoDiscData")){
         $self->LastMsg(ERROR,"incompatible AutoDiscovery Dataobject");
         return(0);
      }
   }



   return(1);
}





1;
