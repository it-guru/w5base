package tRnAI::usbsrv;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use tRnAI::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{useMenuFullnameAsACL}="1";
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'tRnAI_usbsrv.id'),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'USB-Servername',
                dataobjattr   =>'tRnAI_usbsrv.name'),

      new kernel::Field::Select(
                name          =>'portcount',
                label         =>'Port-Count',
                value         =>['10','15','20','25','30'],
                htmleditwidth =>'40px',
                default       =>'20',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   if (defined($rec)){
                      return(1);
                   }
                   return(0);
                },
                dataobjattr   =>'tRnAI_usbsrv.portcount'),

      new kernel::Field::Contact(
                name          =>'contact',
                label         =>'Contact',
                AllowEmpty    =>1,
                vjoinon       =>'contactid'),

      new kernel::Field::Link(
                name          =>'contactid',
                label         =>'ContactID',
                dataobjattr   =>'tRnAI_usbsrv.contact'),

      new kernel::Field::Contact(
                name          =>'contact2',
                label         =>'deputy Contact',
                AllowEmpty    =>1,
                vjoinon       =>'contact2id'),

      new kernel::Field::Link(
                name          =>'contact2id',
                label         =>'Contact2ID',
                dataobjattr   =>'tRnAI_usbsrv.contact2'),

      new kernel::Field::Number(
                name          =>'utnport',
                label         =>'UTN-Port',
                default       =>'9200',
                dataobjattr   =>'tRnAI_usbsrv.utnport'),

      new kernel::Field::Text(
                name          =>'admuser',
                group         =>'admindata',
                label         =>'Admin-Useraccount',
                dataobjattr   =>'tRnAI_usbsrv.admuser'),

      new kernel::Field::Text(
                name          =>'admpass',
                group         =>'admindata',
                label         =>'Admin-Password',
                dataobjattr   =>'tRnAI_usbsrv.admpass'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_usbsrv.comments'),


      new kernel::Field::SubList(
                name          =>'usbports',
                label         =>'USB-Ports',
                group         =>'usbports',
                vjointo       =>\'tRnAI::usbsrvport',
                vjoinon       =>['id'=>'usbsrvid'],
                vjoindisp     =>['name','system']),


      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_usbsrv.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_usbsrv.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_usbsrv.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_usbsrv.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_usbsrv.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_usbsrv.realeditor'),
   

   );
   $self->setDefaultView(qw(name portcount cdate mdate));
   $self->setWorktable("tRnAI_usbsrv");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my ($worktable,$workdb)=$self->getWorktable();
#   my $from="$worktable ".
#            "left outer join xxx on yyy=zzz";
#   return($from);
#}


sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default admindata usbports
             source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       (($newrec->{name}=~m/^\s*$/) || length($newrec->{name})<3)){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default usbports admindata);

   return(@wrgrp) if ($self->tRnAI::lib::Listedit::isWriteValid($rec));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));
   my @vl=("header","default","source");
   if ($self->tRnAI::lib::Listedit::isViewValid($rec)){
      return(@vl);
   }
   my @l=$self->SUPER::isViewValid($rec);
   return(@vl) if (in_array(\@l,[qw(default ALL)]));
   return(undef);
}

sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
