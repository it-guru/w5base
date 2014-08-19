package tsdina::system;
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'1%',
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Systemname',
                dataobjattr   =>'servername'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'SystemID',
                dataobjattr   =>"systemid"),

      new kernel::Field::Text(
                name          =>'w5baseid',
                label         =>'W5BaseID',
                weblinkto     =>'itil::system',
                weblinkon     =>['w5baseid'=>'id'],
                dataobjattr   =>'w5baseid'),

      new kernel::Field::Text(
                name          =>'hostid',
                label         =>'HostID',
                htmldetail    =>0,
                dataobjattr   =>'host_id'),

      new kernel::Field::Text(
                name          =>'platform',
                label         =>'Platform',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['platform'],
                weblinkto     =>'NONE',
      ),

      new kernel::Field::Text(
                name          =>'lpartype',
                group         =>'lpar',
                label         =>'LPAR Type',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['lpartype'],
                weblinkto     =>'NONE',
      ),

      new kernel::Field::Text(
                name          =>'lparmode',
                group         =>'lpar',
                label         =>'LPAR Mode',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['lparmode'],
                weblinkto     =>'NONE',
      ),

      new kernel::Field::Text(
                name          =>'lparsharedpoolid',
                group         =>'lpar',
                label         =>'LPAR Shared Pool ID',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['lparsharedpoolid'],
                weblinkto     =>'NONE',
      ),

      new kernel::Field::Number(
                name          =>'onlinevirtcpu',
                group         =>'lpar',
                label         =>'Online Virtual CPUs',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['onlinevirtcpu'],
                weblinkto     =>'NONE',
      ),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'tsdina::swinstance',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>[qw(name)],
                forwardSearch =>1,
      ),

   );
   $self->setDefaultView(qw(name id platform));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsdina"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="dina_darwin_map_vw";
   return($from);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isUploadValid
{
   return(0);
}




1;
