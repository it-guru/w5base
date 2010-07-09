package timetool::tspan;
#  W5base Framework
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
use kernel::TabSelector;
use kernel::App::Web::TimeGrid;
use kernel::date;
@ISA=qw(kernel::App::Web::TimeGrid kernel::App::Web::Listedit 
        kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5baseID',
                dataobjattr   =>'tspanentry.id'),
                                                  
      new kernel::Field::Text(
                name          =>'fullname',
                uivisible     =>0,
                dataobjattr   =>"tspanentry.tfrom"),

      new kernel::Field::Date(
                name          =>'tfrom',
                label         =>'From',
                dataobjattr   =>'tspanentry.tfrom'),

      new kernel::Field::Date(
                name          =>'tto',
                label         =>'To',
                dataobjattr   =>'tspanentry.tto'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'tspanentry.comments'),

      new kernel::Field::Text(
                name          =>'entrytyp',
                label         =>'Entry Type',
                group         =>'moduledata',
                dataobjattr   =>"tspanentry.entrytyp"),

      new kernel::Field::Select(
                name          =>'cistatus',
                group         =>'moduledata',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'tspanentry.cistatus'),

      new kernel::Field::TextDrop(
                name          =>'user',
                group         =>'moduledata',
                label         =>'UserRef',
                vjointo       =>'base::user',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['useridref'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'timeplanref',
                group         =>'moduledata',
                label         =>'TimePlanRef',
                vjointo       =>'timetool::timeplan',
                vjoinon       =>['timeplanrefid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'subsys',
                label         =>'subsys',
                dataobjattr   =>'tspanentry.subsys'),

      new kernel::Field::Link(
                name          =>'useridref',
                label         =>'UserID',
                dataobjattr   =>'tspanentry.useridref'),

      new kernel::Field::Link(
                name          =>'dataref',
                label         =>'DataRef',
                dataobjattr   =>'tspanentry.dataref'),

      new kernel::Field::Link(
                name          =>'altuseridref',
                label         =>'Alternate UserID Search field',
                dataobjattr   =>'tspanentry.useridref'),

      new kernel::Field::Link(
                name          =>'timeplanrefid',
                label         =>'TimeplanRefID',
                dataobjattr   =>'tspanentry.timeplanref'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'tspanentry.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'tspanentry.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'tspanentry.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'tspanentry.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'tspanentry.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'tspanentry.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'tspanentry.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'tspanentry.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'tspanentry.realeditor'),
   

   );
   $self->setDefaultView(qw(id tfrom tto entrytyp comments));
   $self->setWorktable("tspanentry");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $tfrom=effVal($oldrec,$newrec,"tfrom");
   my $tto=effVal($oldrec,$newrec,"tto");
   if ($tfrom=~m/^\s*$/){
      $self->LastMsg(ERROR,"no from time specified");
      return(undef);
   }
   if (defined($tto) && $tto le $tfrom){
      $self->LastMsg(ERROR,"to is less or equal to from time");
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
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return("ALL") if ($self->IsMemberOf("admin"));
   return(undef);
}
sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/timetool/load/time_entry.jpg?".$cgi->query_string());
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default moduledata misc source));
}




##########################################################################
1;
