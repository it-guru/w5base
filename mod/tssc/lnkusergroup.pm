package tssc::lnkusergroup;
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
      new kernel::Field::Id(      name       =>'id',
                                  label      =>'LinkID',
                                  align      =>'left',
                                  dataobjattr=>
         "concat(scadm1.dsccentralassignmenta1.name,concat('-',".
         "scadm1.dsccentralassignmenta1.operators))"),

      new kernel::Field::TextDrop( name       =>'groupname',
                                   label      =>'Groupname',
                                   searchable =>0,
                                   vjointo    =>'tssc::group',
                                   vjoinon    =>['lgroup'=>'groupid'],
                                   vjoindisp  =>'name'),

      new kernel::Field::TextDrop( name       =>'username',
                                   label      =>'User-Fullname',
                                   htmlwidth  =>'200px',
                                   searchable =>0,
                                   vjointo    =>'tssc::user',
                                   vjoinon    =>['luser'=>'userid'],
                                   vjoindisp  =>'fullname'),

      new kernel::Field::TextDrop( name       =>'useremail',
                                   label      =>'User-EMail',
                                   htmlwidth  =>'200px',
                                   searchable =>0,
                                   htmldetail =>0,
                                   vjointo    =>'tssc::user',
                                   vjoinon    =>['luser'=>'userid'],
                                   vjoindisp  =>'email'),

      new kernel::Field::Text(     name       =>'luser',
                                   uppersearch=>1,
                                   htmlwidth  =>'80px',
                                   label      =>'Loginname',
                                   dataobjattr=>
                                     'scadm1.dsccentralassignmenta1.operators'),
                                  
      new kernel::Field::Text(     name       =>'lgroup',
                                   uppersearch=>1,
                                   label      =>'Group',
                                   dataobjattr=>'scadm1.dsccentralassignmenta1.name'),

   );
   $self->setDefaultView(qw(id userfullname lgroup));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssc"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/gnome-user-group.jpg?".
          $cgi->query_string());
}
         

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "scadm1.dsccentralassignmenta1";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   return("");
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
