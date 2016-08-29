package tsacinv::schain;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),


      new kernel::Field::Id(
                name          =>'schainid',
                label         =>'schainid',
                dataobjattr   =>'amtsisalessrvcpkg.lsrvcpkgid'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'ServiceChainID',
                uppersearch   =>1,
                dataobjattr   =>'amtsisalessrvcpkg.code'),

      new kernel::Field::Text(
                name          =>'tenant',
                label         =>'Tenant',
                group         =>'source',
                dataobjattr   =>'amtenant.code'),

      new kernel::Field::Interface(
                name          =>'tenantid',
                label         =>'Tenant ID',
                group         =>'source',
                dataobjattr   =>'amtenant.ltenantid'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Service Chain Name',
                ignorecase    =>1,
                dataobjattr   =>'amtsisalessrvcpkg.name'),

      new kernel::Field::Link(
                name          =>'lcommentid',
                dataobjattr   =>'amtsisalessrvcpkg.lcommentid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                searchable    =>0,
                vjointo       =>'tsacinv::comment',
                vjoinon       =>['lcommentid'=>'lcommentid'],
                vjoindisp     =>'comments'),

   );
   $self->setDefaultView(qw(linenumber code  fullname));
   $self->{MainSearchFieldLines}=4;
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="amtsisalessrvcpkg ".
            "join amtenant ".
            "on amtsisalessrvcpkg.ltenantid=amtenant.ltenantid ";
   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where="amtsisalessrvcpkg.bdelete=0";
   return($where);
}

#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/location.jpg?".$cgi->query_string());
#}
         

sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   $self->setWorktable("amlocation");
   return(1) if (defined($self->{DB}));
   return(0);
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
