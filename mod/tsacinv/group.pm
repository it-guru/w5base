package tsacinv::group;
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
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                ignorecase    =>1,
                searchable    =>0,
                dataobjattr   =>'"code"'),

      new kernel::Field::Id(
                name          =>'lgroupid',
                label         =>'LGroup ID',
                dataobjattr   =>'"lgroupid"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Name',
                size          =>'20',
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Name',
                uivisible     =>0,
                size          =>'20',
                dataobjattr   =>'"fullname"'),

      new kernel::Field::Boolean(
                name          =>'deleted',
                readonly      =>1,
                label         =>'marked as delete',
                dataobjattr   =>'"deleted"'),

      new kernel::Field::Text(
                name          =>'phone',
                label         =>'Phone',
                size          =>'20',
                ignorecase    =>1,
                dataobjattr   =>'"phone"'),

      new kernel::Field::TextDrop(
                name          =>'parent',
                label         =>'Parentgroup',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['parentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'supervisor',
                label         =>'Supervisor',
                searchable    =>0,
                vjointo       =>'tsacinv::user',
                vjoinon       =>['supervid'=>'lempldeptid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'supervisorldapid',
                label         =>'Supervisor LDAPID',
                searchable    =>0,
                vjointo       =>'tsacinv::user',
                vjoinon       =>['supervid'=>'lempldeptid'],
                vjoindisp     =>'ldapid'),

      new kernel::Field::TextDrop(
                name          =>'supervisoremail',
                label         =>'Supervisor E-Mail',
                searchable    =>0,
                vjointo       =>'tsacinv::user',
                vjoinon       =>['supervid'=>'lempldeptid'],
                vjoindisp     =>'email'),

      new kernel::Field::SubList(
                name          =>'users',
                label         =>'Users',
                vjointo       =>'tsacinv::lnkusergroup',
                vjoinon       =>['lgroupid'=>'lgroupid'],
                vjoindisp     =>['user','userfullname']),

      new kernel::Field::Link(
                name          =>'parentid',
                dataobjattr   =>'"parentid"'),
                                                
      new kernel::Field::Link(
                name          =>'supervid',
                dataobjattr   =>'"supervid"'),
                                                
      new kernel::Field::Text(
                name          =>'scgoupid',
                group         =>'control',
                htmldetail    =>0,
                label         =>'ServiceCenter-GroupID',
                dataobjattr   =>'"scgoupid"'),
                                                
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),
                                                
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"'),

   );
   $self->setDefaultView(qw(lgroupid name supervisor srcsys srcid));
   $self->setWorktable("grp");

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

sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }
}



sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/group.jpg?".$cgi->query_string());
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
