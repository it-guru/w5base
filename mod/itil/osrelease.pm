package itil::osrelease;
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
                label         =>'W5BaseID',
                dataobjattr   =>'osrelease.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'190px',
                label         =>'Name',
                dataobjattr   =>'osrelease.name'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0 AND <7"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'osrelease.cistatus'),

      new kernel::Field::Text(
                name          =>'osclass',
                readonly      =>1,
                label         =>'Operationsystem class',
                dataobjattr   =>'osrelease.osclass'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'osrelease.comments'),
                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'osrelease.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'osrelease.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'osrelease.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'osrelease.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'osrelease.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"osrelease.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(osrelease.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'osrelease.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'osrelease.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'osrelease.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'osrelease.realeditor'),
   

   );
   $self->setDefaultView(qw(name osclass cistatus mdate cdate));
   $self->setWorktable("osrelease");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->{CI_Handling}={uniquename=>"name",
                         activator=>["admin","w5base.softwaremgmt.admin"],
                         uniquesize=>255};
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/osrelease.jpg?".$cgi->query_string());
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return($self->SUPER::SecureValidate($oldrec,$newrec));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if ((!defined($oldrec) || defined($newrec->{name})) &&
       $newrec->{name}=~m/^\s*$/){
      $self->LastMsg(ERROR,"invalid name specified");
      return(0);
   }
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   my $name=effVal($oldrec,$newrec,"name");
   if ($name=~m/^AIX/i){
      $newrec->{osclass}="AIX";
   }
   elsif ($name=~m/linux/i){
      $newrec->{osclass}="LINUX";
   }
   elsif ($name=~m/^(solaris)/i){
      $newrec->{osclass}="SOLARIS";
   }
   elsif ($name=~m/^(HPUX|HP-UX)/i){
      $newrec->{osclass}="HPUX";
   }
   elsif ($name=~m/^(win)/i){
      $newrec->{osclass}="WIN";
   }
   elsif ($name=~m/^(os\/390|osd|z\/OS|z\/VM)/i){
      $newrec->{osclass}="MAINFRAME";
   }
   else{
      $newrec->{osclass}="MISC";
   }
  
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   if (!$self->HandleCIStatus($oldrec,$newrec,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   if (!$self->HandleCIStatus($oldrec,undef,%{$self->{CI_Handling}})){
      return(0);
   }
   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default") if (!defined($rec) ||
                         ($rec->{cistatusid}<3 && $rec->{creator}==$userid) ||
                         $self->IsMemberOf($self->{CI_Handling}->{activator}));
   return(undef);
}

sub isCopyValid
{
   my $self=shift;

   return(1) if ($self->IsMemberOf("admin"));
   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


1;
