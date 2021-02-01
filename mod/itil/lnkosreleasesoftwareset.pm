package itil::lnkosreleasesoftwareset;
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
use itil::lib::Listedit;
use itil::lnksoftware;
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
                label         =>'LinkID',
                searchable    =>0,
                dataobjattr   =>'lnkosreleasesoftwareset.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'osrelease',
                htmlwidth     =>'250px',
                label         =>'OS Release',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::osrelease',
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'fullname',
                htmlwidth     =>'250px',
                htmldetail    =>0,
                label         =>'OS-Release fullname',
                vjointo       =>'itil::osrelease',
                vjoinon       =>['osreleaseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'comparator',
                htmlwidth     =>'220px',
                htmleditwidth =>'220px',
                label         =>'Comparator',
                transprefix   =>'comp.',
                value         =>['0', '1'],
                dataobjattr   =>'lnkosreleasesoftwareset.comparator'),

      new kernel::Field::Link(
                name          =>'osreleaseid',
                label         =>'OS Release ID',
                dataobjattr   =>'lnkosreleasesoftwareset.osrelease'),

      new kernel::Field::Link(
                name          =>'softwaresetid',
                label         =>'Software-Set ID',
                dataobjattr   =>'lnkosreleasesoftwareset.softwareset'),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnkosreleasesoftwareset.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkosreleasesoftwareset.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkosreleasesoftwareset.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkosreleasesoftwareset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkosreleasesoftwareset.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnkosreleasesoftwareset.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkosreleasesoftwareset.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkosreleasesoftwareset.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkosreleasesoftwareset.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkosreleasesoftwareset.realeditor')

   );
   $self->setDefaultView(qw(fullname version comparator mdate));
   $self->setWorktable("lnkosreleasesoftwareset");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkosreleasesoftwareset.jpg?".$cgi->query_string());
#}
         


sub getDetailBlockPriority
{  
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default liccontractinfo source));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $osreleaseid=effVal($oldrec,$newrec,"osreleaseid");
   if ($osreleaseid==0){
      $self->LastMsg(ERROR,"invalid osrelease specified");
      return(undef);
   }

   my $softwaresetid=effVal($oldrec,$newrec,"softwaresetid");
   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnSoftwaresetValid($softwaresetid,"software")){
         $self->LastMsg(ERROR,"no access");
         return(undef);
      }
   }
   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $softwaresetid=effVal($oldrec,$newrec,"softwaresetid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default") if ($self->IsMemberOf("admin"));
   return("default") if ($self->isWriteOnSoftwaresetValid($softwaresetid,"software"));
   return(undef);
}





1;
