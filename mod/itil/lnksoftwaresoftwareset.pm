package itil::lnksoftwaresoftwareset;
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
                dataobjattr   =>'lnksoftwaresoftwareset.id'),
                                                 
      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'250px',
                label         =>'Software',
                vjoineditbase =>{'cistatusid'=>"<5"},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),
                                                   
      new kernel::Field::TextDrop(
                name          =>'fullname',
                htmlwidth     =>'250px',
                uploadable    =>0,
                htmldetail    =>0,
                label         =>'Software fullname',
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'softwareset',
                htmlwidth     =>'250px',
                htmldetail    =>0,
                label         =>'Software Set',
                group         =>'softwareset',
                vjointo       =>'itil::softwareset',
                vjoinon       =>['softwaresetid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'version',
                htmlwidth     =>'50px',
                label         =>'Version',
                dataobjattr   =>'lnksoftwaresoftwareset.version'),

      new kernel::Field::Htmlarea(
                name          =>'versionexp',
                htmlwidth     =>'50px',
                htmldetail    =>0,
                searchable    =>0,
                depend        =>[qw(version startwith)],
                label         =>'Version Expr.',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $d=$current->{version};
                   if ($current->{startwith} ne ""){
                      $d="<b>(".$current->{startwith}.")</b> ".$d;
                   }
                   return($d);
                }),

      new kernel::Field::Text(
                name          =>'startwith',
                htmlwidth     =>'60px',
                htmleditwidth =>'60px',
                label         =>'only if Start with',
                dataobjattr   =>'lnksoftwaresoftwareset.startwith'),

      new kernel::Field::Text(
                name          =>'releasekey',
                readonly      =>1,
                htmldetail    =>0,
                group         =>'releaseinfos',
                label         =>'Releasekey',
                dataobjattr   =>'lnksoftwaresoftwareset.releasekey'),

      new kernel::Field::Select(
                name          =>'comparator',
                htmlwidth     =>'220px',
                htmleditwidth =>'220px',
                label         =>'Comparator',
                transprefix   =>'comp.',
                value         =>['1','3','10','11','12'],
                dataobjattr   =>'lnksoftwaresoftwareset.comparator'),

      new kernel::Field::Link(
                name          =>'softwareid',
                label         =>'Software ID',
                dataobjattr   =>'lnksoftwaresoftwareset.software'),

      new kernel::Field::Link(
                name          =>'softwaresetid',
                label         =>'Software-Set ID',
                dataobjattr   =>'lnksoftwaresoftwareset.softwareset'),

      new kernel::Field::Text(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'lnksoftwaresoftwareset.comments'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnksoftwaresoftwareset.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnksoftwaresoftwareset.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnksoftwaresoftwareset.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnksoftwaresoftwareset.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'lnksoftwaresoftwareset.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnksoftwaresoftwareset.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnksoftwaresoftwareset.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnksoftwaresoftwareset.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnksoftwaresoftwareset.realeditor')

   );
   $self->setDefaultView(qw(fullname version startwith comparator mdate));
   $self->setWorktable("lnksoftwaresoftwareset");
   return($self);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnksoftwaresoftwareset.jpg?".$cgi->query_string());
#}
         


sub getDetailBlockPriority
{  
   my $self=shift;
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default liccontractinfo source));
}


sub initSqlOrder
{
   my $self=shift;
   return("lnksoftwaresoftwareset.software,".
          "lnksoftwaresoftwareset.comparator desc");
}




sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $softwareid=effVal($oldrec,$newrec,"softwareid");
   if ($softwareid==0){
      $self->LastMsg(ERROR,"invalid software specified");
      return(undef);
   }
   itil::lnksoftware::VersionKeyGenerator($oldrec,$newrec);


   my $version=effVal($oldrec,$newrec,"version");
   if ($version=~m/^\s*$/){
      $self->LastMsg(ERROR,"no version specified");
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

   return("default","softwareset") if (!defined($oldrec) && !defined($newrec));
   return("default","softwareset") if ($self->IsMemberOf("admin"));
   return("default","softwareset") if ($self->isWriteOnSoftwaresetValid($softwaresetid,"software"));
   return(undef);
}





1;
