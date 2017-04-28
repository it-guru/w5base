package base::lnkuserw5plug;
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
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkuserw5plug.id'),


      new kernel::Field::TextDrop(
                name          =>'plug',
                label         =>'Plug',
                vjointo       =>'base::w5plug',
                vjoinon       =>['plugid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'plugid',
                dataobjattr   =>'lnkuserw5plug.plugid'),

      new kernel::Field::Contact(
                name          =>'user',
                label         =>'Contact',
                vjoinon       =>'userid'),

      new kernel::Field::Link(
                name          =>'userid',
                readonly      =>1,
                dataobjattr   =>'lnkuserw5plug.userid'),

      new kernel::Field::Link(
                name          =>'plugname',
                readonly      =>1,
                dataobjattr   =>'w5plug.name'),

      new kernel::Field::Link(
                name          =>'plugcode',
                readonly      =>1,
                dataobjattr   =>'w5plug.plugcode'),

      new kernel::Field::Link(
                name          =>'plugmode',
                readonly      =>1,
                dataobjattr   =>'w5plug.plugmode'),

      new kernel::Field::Link(
                name          =>'parentobj',
                readonly      =>1,
                dataobjattr   =>'w5plug.dataobj'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkuserw5plug.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkuserw5plug.modifyuser'),
                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkuserw5plug.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkuserw5plug.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkuserw5plug.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkuserw5plug.realeditor')
   );
   $self->setDefaultView(qw(plug user cdate));
   $self->setWorktable("lnkuserw5plug");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkuserw5plug.jpg?".$cgi->query_string());
#}
         

sub getDetailBlockPriority
{  
   my $self=shift;
   return(qw(header default source));
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
   my $origrec=shift;

#   my $grpid=effVal($oldrec,$newrec,"grpid");
#   if ($grpid eq ""){
#      $self->LastMsg(ERROR,"no group selected with marked as oranisation");
#      return(undef);
#   }
#   my $locationid=effVal($oldrec,$newrec,"locationid");
#   if ($locationid eq ""){
#      $self->LastMsg(ERROR,"invalid location");
#      return(undef);
#   }
#   if (!$self->isLocationWriteable($locationid)){
#         $self->LastMsg(ERROR,"no write access to requested location");
#         return(undef);
#   }
   return(1);
}


sub getSqlFrom
{
   my $self=shift;
   my ($worktable,$workdb)=$self->getWorktable();
   return("$worktable join w5plug ".
          "on $worktable.plugid=w5plug.id ");
}





sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return("default") if ($self->IsMemberOf("admin"));

   return(undef);
}





1;
