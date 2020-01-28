package tRnAI::lnkuseraccountsystem;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.id'),
                                                  
      new kernel::Field::TextDrop(
                name          =>'useraccount',
                label         =>'User-Account',
                vjointo       =>\'tRnAI::useraccount',
                vjoinon       =>['useraccountid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'useraccountid',
                label         =>'useraccountid',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.useraccount'),

      new kernel::Field::Link(
                name          =>'uflag',
                label         =>'uflag',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.uflag'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'VDI-Systemname',
                htmlwidth     =>'140',
                vjointo       =>\'tRnAI::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'reltyp',
                label         =>'relation type',
                value         =>['PRIM','SEC'],
                htmlwidth     =>'110',
                default       =>'PRIM',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.reltyp'),


      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'systemid',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.system'),

      new kernel::Field::TextDrop(
                name          =>'email',
                label         =>'E-Mail',
                group         =>'accountinfo',
                readonly      =>1,
                htmldetail    =>0,
                vjointo       =>\'tRnAI::useraccount',
                vjoinon       =>['useraccountid'=>'id'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'comments',
                label         =>'Comments',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'accountinfo',
                vjointo       =>\'tRnAI::useraccount',
                vjoinon       =>['useraccountid'=>'id'],
                vjoindisp     =>'comments'),

      #new kernel::Field::Text(
      #          name          =>'comments',
      #          label         =>'Comments',
      #          dataobjattr   =>'tRnAI_lnkuseraccountsystem.comments'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_lnkuseraccountsystem.realeditor'),
   

   );
   $self->setDefaultView(qw(useraccount system mdate));
   $self->setWorktable("tRnAI_lnkuseraccountsystem");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/gnome-user-group.jpg?".$cgi->query_string());
}


#sub getSqlFrom
#{
#   my $self=shift;
#   my ($worktable,$workdb)=$self->getWorktable();
#   my $from="$worktable ".
#            "left outer join xxx on yyy=zzz";
#   return($from);
#}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (effVal($oldrec,$newrec,"reltyp") eq "PRIM"){
      if (effVal($oldrec,$newrec,"uflag") ne "PRIM"){
         $newrec->{uflag}="PRIM";
      }
   }
   else{
      if (effVal($oldrec,$newrec,"uflag") ne ""){
         $newrec->{uflag}=undef;
      }
   }

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default accountinfo source));
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default);

   return(@wrgrp) if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"],undef,"up"));
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
