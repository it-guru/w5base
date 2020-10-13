package tRnAI::instance;
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
                dataobjattr   =>'tRnAI_instance.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Instance-Name',
                dataobjattr   =>'tRnAI_instance.name'),

      new kernel::Field::Contact(
                name          =>'contact',
                label         =>'Contact',
                AllowEmpty    =>1,
                vjoinon       =>'contactid'),

      new kernel::Field::Link(
                name          =>'contactid',
                label         =>'ContactID',
                dataobjattr   =>'tRnAI_instance.contact'),

      new kernel::Field::Number(
                name          =>'tcpport',
                label         =>'TCP-Port',
                precision     =>'0',
                editrange     =>[1,65535],
                htmleditwidth =>'50px',
                dataobjattr   =>'tRnAI_instance.tcpport'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'logical System',
                group         =>'applsrv',
                vjointo       =>\'TS::system',
                vjoindisp     =>'name',
                vjoinon       =>['systemid'=>'id']),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'SystemID',
                dataobjattr   =>'tRnAI_instance.system'),


      new kernel::Field::TextDrop(
                name          =>'software',
                label         =>'Software',
                vjointo       =>\'itil::software',
                vjoindisp     =>'name',
                vjoinon       =>['softwareid'=>'id']),

      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'SoftwareID',
                dataobjattr   =>'tRnAI_instance.software'),

      new kernel::Field::Text(
                name          =>'softwareversion',
                label         =>'Software Version',
                dataobjattr   =>'tRnAI_instance.version'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tRnAI_instance.comments'),


      new kernel::Field::Select(
                name          =>'customer',
                label         =>'Customer',
                group         =>'customer',
                allowfree     =>1,
                allowempty    =>1,
                weblinkto     =>'none',
                htmleditwidth =>'300px',
                vjointo       =>\'tRnAI::customer',
                vjoindisp     =>'name',
                vjoinon       =>['rawcustomer'=>'name']),

      new kernel::Field::Link(
                name          =>'rawcustomer',
                label         =>'Customer raw',
                group         =>'customer',
                dataobjattr   =>'tRnAI_instance.customer'),

      new kernel::Field::Select(
                name          =>'department',
                label         =>'Department',
                group         =>'customer',
                allowfree     =>1,
                allowempty    =>1,
                weblinkto     =>'none',
                htmleditwidth =>'300px',
                vjointo       =>\'tRnAI::department',
                vjoindisp     =>'name',
                vjoinon       =>['rawdepartment'=>'name']),

      new kernel::Field::Link(
                name          =>'rawdepartment',
                label         =>'Department raw',
                group         =>'customer',
                dataobjattr   =>'tRnAI_instance.department'),



      new kernel::Field::SubList(
                name          =>'licenses',
                label         =>'licenses',
                group         =>'licenses',
                subeditmsk    =>'subedit.licenses',
                vjointo       =>\'tRnAI::lnkinstlic',
                vjoinon       =>['id'=>'instanceid'],
                vjoindisp     =>['license','ponum','expdate']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tRnAI_instance.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tRnAI_instance.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tRnAI_instance.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'tRnAI_instance.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'tRnAI_instance.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'tRnAI_instance.realeditor'),
   

   );
   $self->setDefaultView(qw(name system tcpport 
                            customer department subcustomer mdate));
   $self->setWorktable("tRnAI_instance");
   return($self);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/swinstance.jpg?".$cgi->query_string());
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default applsrv customer licenses source));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   my $name=effVal($oldrec,$newrec,"name");

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       (($name=~m/^\s*$/) || length($name)<3) || haveSpecialChar($name)){
      $self->LastMsg(ERROR,"invalid instance name specified");
      return(0);
   }

   my $tcpport=effVal($oldrec,$newrec,"tcpport");
   if ($tcpport eq ""){
      $self->LastMsg(ERROR,"missing TCP port number");
      return(0);
   }





   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(default customer applsrv licenses);

   return(@wrgrp) if ($self->tRnAI::lib::Listedit::isWriteValid($rec));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default","applsrv") if (!defined($rec));
   return("ALL") if ($self->IsMemberOf(["w5base.RnAI.inventory","admin"]));

   my @vl=("header","default","customer","applsrv","licenses","source");


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
