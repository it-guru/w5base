package tscape::archapplrole;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'RoleID',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>"CONVERT(VARCHAR(32), ".
                                "HashBytes('MD5',".
                                "Internal_Key+':'+Mail+'+'+Role),2)"),

      new kernel::Field::Text(
                name          =>'ictoid',
                label         =>'ICTO-ID',
                weblinkto     =>\'tscape::archappl',
                weblinkon     =>['ictoid'=>'archapplid'],
                dataobjattr   =>'ICTO_Nummer'),

      new kernel::Field::Text(
                name          =>'role',
                htmlwidth     =>'200px',
                label         =>'role',
                dataobjattr   =>'Role'),

      new kernel::Field::Email(
                name          =>'email',
                label         =>'email',
                dataobjattr   =>'lower(Mail)')
   );
   $self->{use_distinct}=0;
   $self->{useMenuFullnameAsACL}=$self->Self;
   $self->setDefaultView(qw(ictoid role email));
   $self->setWorktable("V_DARWIN_EXPORT_AEG");
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tscape"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default");
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}





sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/base/load/user.jpg?".$cgi->query_string());
}

sub initSqlWhere
{
   my $self=shift;
   my $where="Mail not like '% %' and ".
             "Mail not like '%\@unknown-telekom.%' ";
   return($where);
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
