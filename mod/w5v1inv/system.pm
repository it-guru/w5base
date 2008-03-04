package w5v1inv::system;
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
use Data::Dumper;
use kernel;
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use base::workflow::mailsend;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5v1"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   $self->{userview}=getModuleObject($self->Config,"base::userview");
   $self->setWorktable("bchw");

   $self->AddFields(
      new kernel::Field::Id(      name       =>'w5systemid',
                                  label      =>'W5BaseID',
                                  size       =>'10',
                                  dataobjattr     =>'bchw.id'),

      new kernel::Field::Text(    name       =>'name',
                                  label      =>'Systemname',
                                  dataobjattr     =>'bchw.name'),

      new kernel::Field::Text(    name       =>'cpucount',
                                  label      =>'CPU-Count',
                                  dataobjattr     =>'bchw.cpucount',
                                  group      =>'30'),

      new kernel::Field::Text(    name       =>'cputakt',
                                  label      =>'CPU-Frequence',
                                  dataobjattr     =>'bchw.cputakt',
                                  group      =>'30'),

      new kernel::Field::Text(    name       =>'systemid',
                                  label      =>'SystemID',
                                  dataobjattr     =>'bchw.sger',
                                  group      =>'30'),

      new kernel::Field::Text(    name       =>'acname',
                                  label      =>'AC-Systemname',
                                  size       =>'20',
                                  vjointo    =>'tsacinv::system',
                                  vjoinon    =>['systemid'=>'systemid'],
                                  vjoindisp  =>'systemname',
                                  group      =>'30'),

      new kernel::Field::Textarea(name       =>'info',
                                  label      =>'Additional-Info',
                                  dataobjattr     =>'bchw.info',
                                  group      =>'30'),

      new kernel::Field::Select(  name       =>'cistatus',
                                  label      =>'CI-State',
                                  size       =>'20',
                                  dataobjattr     =>'bchw.cistatus',
                                  vjointo    =>'base::cistatus',
                                  vjoinon    =>['cistatusid'=>'id'],
                                  vjoindisp  =>'name'),

      new kernel::Field::TextDrop(name       =>'location',
                                  htmlwidth  =>'200px',
                                  label      =>'Location',
                                  vjointo    =>'w5v1inv::location',
                                  vjoinon    =>['locationid'=>'id'],
                                  vjoindisp  =>'name'),

      new kernel::Field::SubList( name       =>'ipaddresses',
                                  label      =>'IP-Adresses',
                                  xasync      =>1,
                                  group      =>'ipadresses',
                                  subeditmsk =>'subedit.system',
                                  vjoinbase  =>[{'app'=>\'bchw'}],
                                  vjointo    =>'w5v1inv::ipaddress',
                                  vjoinon    =>['w5systemid'=>'w5systemid'],
                                  vjoindisp  =>['addr','name']),

      new kernel::Field::Link(    name       =>'cistatusid',
                                  label      =>'CI-StateID',
                                  dataobjattr     =>'bchw.cistatus'),

      new kernel::Field::Link(    name       =>'locationid',
                                  label      =>'LocationID',
                                  dataobjattr     =>'bchw.loc'),
      new kernel::Field::Linenumber(name       =>'line',
                                    label      =>'Linenumber'),
   );
   $self->AddOperator(
      new base::workflow::mailsend(),
   );
   $self->setDefaultView(qw(line w5systemid name acname location cistatus systemid ipaddresses));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;

   return("bchw left outer join sysloc on bchw.loc=sysloc.id");
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
#   msg(INFO,"isViewValid in $self");
#   return(1) if (!defined($rec));
#   return(qw(10 20 30 default));
#   return("ALL");
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
#   msg(INFO,"isWriteValid in $self");
   return(undef);
}


1;
