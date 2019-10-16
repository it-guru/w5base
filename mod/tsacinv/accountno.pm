package tsacinv::accountno;
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
use tsacinv::lib::tools;
use kernel::Field;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

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
                label         =>'RecordID',
                align         =>'left',
                dataobjattr   =>'"id"'),

      new kernel::Field::Text(
                name          =>'accnoid',
                label         =>'Account Number ID',
                ignorecase    =>1,
                dataobjattr   =>'"accnoid"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Account Number',
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'ctrlflag',
                label         =>'Control Flag',
                ignorecase    =>1,
                dataobjattr   =>'"ctrlflag"'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                dataobjattr   =>'"conumber"'),


      new kernel::Field::Text(
                name          =>'description',
                label         =>'Comments',
                dataobjattr   =>'"description"'),

      new kernel::Field::TextDrop(
                name          =>'appl',
                depend        =>['lapplicationid'],
                label         =>'Application',
                htmldetail    =>sub {
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if ($current->{lapplicationid}==0);
                   return(1);
                },
                vjointo       =>'tsacinv::appl',
                vjoinon       =>['lapplicationid'=>'id'],
                vjoindisp     =>'name'),
                             
      new kernel::Field::Link(
                name          =>'lapplicationid',
                label         =>'Application Link',
                dataobjattr   =>'"lapplicationid"')

   );
   $self->setDefaultView(qw(id accnoid name conumber ctrlflag));
   $self->setWorktable("accountno");

   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   $self->amInitializeOraSession();
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tsacinv/load/accountno.jpg?".$cgi->query_string());
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
   my $rec=shift;
   return(undef);
}


1;
