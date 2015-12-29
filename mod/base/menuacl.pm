package base::menuacl;
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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::App::Web::AclControl;
use kernel::DataObj::DB;
use kernel::Field;
@ISA=qw(kernel::App::Web::AclControl kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;

   $param{acltable}="menuacl";
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'fullname',
                readonly      =>1,
                depend        =>['refid','aclmode'],
                label         =>'Fullname',
                onRawValue    =>\&getFullname),
      insertafter=>'id'
   );

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'menufullname',
                vjointo       =>'base::menu',
                vjoinon       =>['refid'=>'menuid'],
                vjoindisp     =>'fullname',
                label         =>'menu fullname'),
      insertafter=>'id'
   );
   $self->setDefaultView(qw(aclid menufullname acltargetname));


   return($self);
}

sub getFullname
{
   my $self=shift;
   my $current=shift;
   my $refid=$self->getParent->getField("refid",$current)->RawValue($current);

   my $obj=getModuleObject($self->getParent->Config,"base::menu");

   $obj->SetFilter({menuid=>\$refid});
   my ($mrec,$msg)=$obj->getOnlyFirst(qw(fullname translation));
   if (defined($mrec)){
      my $d=$mrec->{fullname}." (".
             $self->getParent->T($mrec->{fullname},$mrec->{translation}).")";
      $d.=" - ".$current->{aclmode} if ($current->{aclmode} ne "");


      return($d);
   }
   return("invalid menu reference");
}

sub FinishWrite
{   
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->InvalidateMenuCache();
   return($bak);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);
   $self->InvalidateMenuCache();
   return($bak);
}

sub checkParentWriteAccess
{
   my $self=shift;
   my $pobj=shift;
   my $refid=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/menu.jpg?".$cgi->query_string());
}
         





1;
