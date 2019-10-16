package tssm::company;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use tssm::lib::io;

@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'CustomerID',
                group         =>'source',
                dataobjattr   =>SELpref.'companym1.customer_id'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Company Fullname',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'companym1.company_full_name'),

      new kernel::Field::Text(
                name          =>'msskey',
                label         =>'Cosima MSS Key',
                group         =>'source',
                dataobjattr   =>SELpref.'companym1.tsi_cosima_mandant'),

      new kernel::Field::Text(
                name          =>'mss',
                label         =>'Cosima MSS',
                group         =>'source',
                dataobjattr   =>SELpref.'companym1.tsi_cosima_mandant_name'),

      new kernel::Field::Text(
                name          =>'code',
                label         =>'Code',
                group         =>'source',
                dataobjattr   =>SELpref.'companym1.code'),

      new kernel::Field::Text(
                name          =>'mandant',
                label         =>'ServiceManager Mandant',
                dataobjattr   =>SELpref.'companym1.tsi_mandant_name'),

      new kernel::Field::Text(
                name          =>'mandantid',
                label         =>'ServiceManager Mandant ID',
                dataobjattr   =>SELpref.'companym1.tsi_mandant'),



      new kernel::Field::Text(
                name          =>'city',
                label         =>'City',
                uppersearch   =>1,
                dataobjattr   =>SELpref.'companym1.city'),

      new kernel::Field::MDate(
                name          =>'mdate',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                group         =>'source',
                dataobjattr   =>SELpref.'companym1.sysmodtime'),
                                                   
   );
   $self->setDefaultView(qw(fullname id mandant mandantid));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tssm"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/user.jpg?".$cgi->query_string());
#}
         

sub getSqlFrom
{
   my $self=shift;
   my $from=TABpref."companym1 ".SELpref."companym1";
   return($from);
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

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","source");
}

sub isQualityCheckValid
{
   return(0);
}






1;
