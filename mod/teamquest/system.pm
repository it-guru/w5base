package teamquest::system;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::DB;
use kernel::App::Web::Listedit
@ISA=qw(kernel::App::Web::Listedit  kernel::DataObj::DB);

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
                label         =>'ID',
                dataobjattr   =>'lower("System.Licenses"."System")'),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'System',
                ignorecase    =>1,
                weblinkto     =>'itil::system',
                weblinkon     =>['name'=>'name'],
                dataobjattr   =>'"System.Licenses"."System"'),

      new kernel::Field::Number(
                name          =>'collectcpucount',
                group         =>'collect',
                label         =>'collected CPU-Count',
                dataobjattr   =>'"CPU.Summary"."online_cpus"'),

      new kernel::Field::Number(
                name          =>'collectmemory',
                group         =>'collect',
                label         =>'collected Memory',
                dataobjattr   =>'"Memory"."totalmem"'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::system',
                vjoinon       =>['id'=>'name'],
                dontrename    =>1,
                group         =>'itil',
                fields        =>[qw(cpucount memory)]),

      new kernel::Field::Date(
                name          =>'lastupdate',
                label         =>'Last Update',
                dataobjattr   =>"TO_DATE('19700101000000','YYYYMMDDHH24MISS')".
                                "+NUMTODSINTERVAL(\"Timestamp\", 'SECOND')"),


   );
   $self->AddGroup("itil",translation=>'teamquest::system');

   $self->setDefaultView(qw(linenumber name 
                            cpucount collectcpucount 
                            memory collectmemory 
                            lastupdate));
   $self->setWorktable('"System.Licenses"');
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $wt=$self->{Worktable};
   my $from=$wt.',"CPU.Summary","Memory"';

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where='"System.Licenses"."System"="CPU.Summary"."System"(+) and '.
             '"System.Licenses"."Timestamp"="CPU.Summary"."Time"(+) and '.
             '"System.Licenses"."System"="Memory"."System"(+) and '.
             '"System.Licenses"."Timestamp"="Memory"."Time"(+)';
   return($where);
}





sub Initialize
{
   my $self=shift;
   
   my @result=$self->AddDatabase(DB=>new kernel::database($self,"teamquest"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}


1;
