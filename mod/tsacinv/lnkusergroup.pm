package tsacinv::lnkusergroup;
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
use tsacinv::lib::tools;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB tsacinv::lib::tools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Id(      name       =>'id',
                                  label      =>'LinkID',
                                  dataobjattr=>'"id"'),

      new kernel::Field::TextDrop( name       =>'user',
                                   label      =>'Account',
                                   vjointo    =>'tsacinv::user',
                                   vjoinon    =>['lempldeptid'=>'lempldeptid'],
                                   vjoindisp  =>'loginname'),

      new kernel::Field::TextDrop( name       =>'userfullname',
                                   label      =>'User-Fullname',
                                   vjointo    =>'tsacinv::user',
                                   vjoinon    =>['lempldeptid'=>'lempldeptid'],
                                   vjoindisp  =>'fullname'),

      new kernel::Field::TextDrop( name       =>'group',
                                   label      =>'Group',
                                   vjointo    =>'tsacinv::group',
                                   vjoinon    =>['lgroupid'=>'lgroupid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::Text(     name       =>'lempldeptid',
                                   label      =>'lempldeptid',
                                   dataobjattr=>'"lempldeptid"'),
                                  
      new kernel::Field::Text(     name       =>'lgroupid',
                                   label      =>'lgroupid',
                                   dataobjattr=>'"lgroupid"'),

   );
   $self->setWorktable("lnkusergroup");
   $self->setDefaultView(qw(id lempldeptid lgroupid group userfullname));
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
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}
         

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!$self->IsMemberOf("admin"));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}


1;
