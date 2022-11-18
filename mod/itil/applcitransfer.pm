package itil::applcitransfer;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
                dataobjattr   =>'applcitransfer.id'),

      new kernel::Field::RecordUrl(),

      new kernel::Field::TextDrop(
                name          =>'eappl',
                htmlwidth     =>'250px',
                label         =>'emitting Application',
                vjoineditbase =>{'cistatusid'=>"4"},
                vjointo       =>'itil::appl',
                vjoinon       =>['eapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'eapplid',
                label         =>'emitting Application ID',
                selectfix     =>1,
                dataobjattr   =>'applcitransfer.eappl'),

      new kernel::Field::TextDrop(
                name          =>'cappl',
                htmlwidth     =>'250px',
                label         =>'collecting Application',
                vjoineditbase =>{'cistatusid'=>"4"},
                vjointo       =>'itil::appl',
                vjoinon       =>['capplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'capplid',
                label         =>'collecting Application ID',
                selectfix     =>1,
                dataobjattr   =>'applcitransfer.cappl'),


      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'applcitransfer.comments'),
                                                   
      new kernel::Field::Textarea(
                name          =>'configitems',
                label         =>'Config-Items',
                searchable    =>0,
                dataobjattr   =>'applcitransfer.configitems'),
                                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'applcitransfer.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'applcitransfer.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'applcitransfer.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'applcitransfer.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'applcitransfer.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"applcitransfer.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(applcitransfer.id,35,'0')"),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'applcitransfer.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'applcitransfer.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'applcitransfer.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'applcitransfer.realeditor'),
   

   );
   $self->setDefaultView(qw(eappl cappl cdate));
   $self->setWorktable("applcitransfer");
   $self->{history}={
      update=>[
         'local'
      ]
   };
   return($self);
}


sub initSearchQuery
{
   my $self=shift;
#   if (!defined(Query->Param("search_cistatus"))){
#     Query->Param("search_cistatus"=>
#                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
#   }
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/applcitransfer.jpg?".$cgi->query_string());
#}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

printf STDERR ("fifi SecureValidate newrec=%s\n",Dumper($newrec));

   return($self->SUPER::SecureValidate($oldrec,$newrec));
}





sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

printf STDERR ("fifi Validate newrec=%s\n",Dumper($newrec));
  
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

printf STDERR ("fifi FinishWrite newrec=%s\n",Dumper($newrec));


   return(1);
}


sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

printf STDERR ("fifi FinishDelete oldrec=%s\n",Dumper($oldrec));

   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my $userid=$self->getCurrentUserId();
   return("default");
   return(undef);
}

sub isCopyValid
{
   my $self=shift;

   return(0);
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





1;
