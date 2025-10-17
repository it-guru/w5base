package tsacinv::service;
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
                name          =>'serviceid',
                label         =>'ServiceID',
                align         =>'left',
                dataobjattr   =>'"serviceid"'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemId',
                size          =>'13',
                htmlwidth     =>50,
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'"systemid"'),

      new kernel::Field::Text(
               name           =>'systemname',
               label          =>'Systemname',
               vjoinslimit    =>100,
               vjointo        =>\'tsacinv::system',
               vjoinon        =>['systemid'=>'systemid'],
               vjoindisp      =>'systemname'),

      new kernel::Field::Interface(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'"lcomputerid"'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Service Name',
                htmlwidth     =>50,
                ignorecase    =>1,
                dataobjattr   =>'"name"'),

      new kernel::Field::Text(
                name          =>'longname',
                label         =>'Service Fullname',
                htmlwidth     =>250,
                ignorecase    =>1,
                dataobjattr   =>'"servicename"'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Service Type',
                htmlwidth     =>200,
                ignorecase    =>1,
                dataobjattr   =>'"type"'),

      new kernel::Field::Text(
                name          =>'unit',
                label         =>'Unit',
                htmlwidth     =>50,
                dataobjattr   =>'"unit"'),
                              
      new kernel::Field::Boolean(
                name          =>'bmonthly',
                label         =>'monthly factured service',
                dataobjattr   =>'"bmonthly"'),
                              
      new kernel::Field::Text(
                name          =>'description',
                label         =>'Service Description',
                dataobjattr   =>'"description"'),

      new kernel::Field::Boolean(
                name          =>'isordered',
                label         =>'is ordered',
                dataobjattr   =>'"isordered"'),

      new kernel::Field::Boolean(
                name          =>'isdelivered',
                label         =>'is delivered',
                dataobjattr   =>'"isdelivered"'),

      new kernel::Field::Float(
                name          =>'ammount',
                label         =>'Ammount',
                htmlwidth     =>50,
                align         =>'right',
                dataobjattr   =>'"ammount"'),

      new kernel::Field::Text(
                name          =>'costcenter',
                label         =>'CostCenter',
                dataobjattr   =>'"costcenter"'),

      new kernel::Field::Text(
                name          =>'sendcostcenter',
                label         =>'sender CostCenter',
                dataobjattr   =>'"sendcostcenter"'),

   );
   $self->setWorktable("service"); 
   $self->setDefaultView(qw(linenumber serviceid systemid name longname
                            type ammount unit 
                            costcenter sendcostcenter description));
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
   return("../../../public/itil/load/service.jpg?".$cgi->query_string());
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
