package tsacinv::lnksystemsoftware;

#
# Diese Module ist noch nicht fertig - ich begreife da einfach nicht
# die Strukturen von AC
#
#
#

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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                searchable    =>1,
                htmlwidth     =>'60px',
                label         =>'SW-Install-ID',
                dataobjattr   =>'"id"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Software',
                uppersearch   =>1,
                htmlwidth     =>'380px',
                size          =>'16',
                dataobjattr   =>'"name"'),

      new kernel::Field::TextDrop(
                name          =>'system',
                label         =>'System',
                uppersearch   =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lparentid'=>'lportfolioitemid'],
                vjoindisp     =>'systemname'),

      new kernel::Field::TextDrop(
                name          =>'systemid',
                label         =>'SystemID',
                uppersearch   =>1,
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lparentid'=>'lportfolioitemid'],
                vjoindisp     =>'systemid'),

      new kernel::Field::Number(
                name          =>'quantity',
                xhtmlwidth     =>'40px',
                label         =>'Quantity',
                dataobjattr   =>'"quantity"'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                #dataobjattr   =>'amsoftinstall.versionlevel'),
                dataobjattr   =>'"version"'),

      new kernel::Field::Text(
                name          =>'instpath',
                label         =>'Folder',
                dataobjattr   =>'"instpath"'),

      new kernel::Field::TextDrop(
                name          =>'license',
                label         =>'License',
                uppersearch   =>1,
                vjointo       =>'tsacinv::license',
                vjoinon       =>['llicense'=>'lastid'],
                vjoindisp     =>'licenseid'),

      new kernel::Field::Link(
                name          =>'lparentid',
                label         =>'ParentID',
                dataobjattr   =>'"lparentid"'),

      new kernel::Field::Text(
                name          =>'llicense',
                htmldetail    =>0,
                label         =>'LicenseID',
                dataobjattr   =>'"llicense"'),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'"cdate"'),

      new kernel::Field::Text(
                name          =>'applications',
                htmlwidth     =>'100px',
                weblinkto     =>'NONE',
                group         =>'useableby',
                htmldetail    =>0,
                label         =>'useable by application',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lparentid'=>'lportfolioitemid'],
                vjoindisp     =>'applicationnames'),

      new kernel::Field::Text(
                name          =>'applicationids',
                htmlwidth     =>'100px',
                weblinkto     =>'NONE',
                group         =>'useableby',
                htmldetail    =>0,
                label         =>'useable by applicationids',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lparentid'=>'lchildid'],
                vjoindisp     =>'applid'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"'),
   );
   $self->setDefaultView(qw(id name version system license quantity));
    $self->setWorktable("lnksystemsoftware");
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
   return("../../../public/itil/load/lnkapplsystem.jpg?".$cgi->query_string());
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
