package TAD4DatW5W::software;
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
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{use_distinct}=0;
   $self->{use_dirtyread}=1;

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'Id',
                group         =>'source',
                dataobjattr   =>'prod_inv_id'),

      new kernel::Field::Text(
                name          =>'hostname',
                label         =>'Hostname',
                ignorecase    =>1,
                dataobjattr   =>'agent_hostname'),

      new kernel::Field::Text(
                name          =>'vendor',
                label         =>'Vendor',
                htmlwidth     =>180,
                ignorecase    =>1,
                dataobjattr   =>'vendor_name'),

      new kernel::Field::Text(
                name          =>'software',
                label         =>'Software',
                htmlwidth     =>380,
                ignorecase    =>1,
                dataobjattr   =>'component_name'),

      new kernel::Field::Text(
                name          =>'softwareproduct',
                label         =>'Software Product',
                htmlwidth     =>380,
                ignorecase    =>1,
                dataobjattr   =>'swproduct_name'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'Version',
                ignorecase    =>1,
                dataobjattr   =>'swproduct_version'),

      new kernel::Field::Text(
                name          =>'scope',
                label         =>'Scope',
                ignorecase    =>1,
                dataobjattr   =>'prod_inv_scope'),

      new kernel::Field::Date(
                name          =>'starttime',
                label         =>'Start-Time',
                dataobjattr   =>"prod_inv_start_time"),

      new kernel::Field::Date(
                name          =>'endtime',
                label         =>'End-Time',
                dataobjattr   =>"prod_inv_end_time"),

      new kernel::Field::Boolean(
                name          =>'isremote',
                label         =>'Remote',
                dataobjattr   =>'prod_inv_is_remote'),

      new kernel::Field::Percent(
                name          =>'confidencelevel',
                label         =>'Scan/Mapping confidence',
                dataobjattr   =>'prod_inv_confidence_level'),

      new kernel::Field::Boolean(
                name          =>'ispvu',
                label         =>'is PVU (Processor Value Unit) posible',
                group         =>'productinfo',
                dataobjattr   =>'is_pvu'),

      new kernel::Field::Boolean(
                name          =>'isrvu',
                label         =>'is RVU (Processor Value Unit) posible',
                group         =>'productinfo',
                dataobjattr   =>'is_rvu'),

      new kernel::Field::Boolean(
                name          =>'issubcap',
                label         =>'is SubCapacity posible',
                group         =>'productinfo',
                dataobjattr   =>'is_sub_cap'),

      new kernel::Field::Boolean(
                name          =>'isfreeofcharge',
                label         =>'free of charge',
                allowempty    =>1,
                group         =>'productinfo',
                dataobjattr   =>"isfreeofcharge"),

      new kernel::Field::Text(
                name          =>'agentid',
                label         =>'Agent ID',
                group         =>'source',
                dataobjattr   =>'agent_id'),

      new kernel::Field::Date(
                name          =>'scandate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Scan-Date',
                dataobjattr   =>'scan_time'),

      new kernel::Field::Text(
                name          =>'env',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Enviroment',
                translation   =>'TAD4DatW5W::system',
                dataobjattr   =>'enviroment'),
   );
   $self->setWorktable("TAD4D_software");
   $self->setDefaultView(qw(hostname vendor software softwareproduct 
                            version confidencelevel));
   return($self);
}


sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/software.jpg?".$cgi->query_string());
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_endtime"=>'[EMPTY]');
   }
}



sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
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


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default software productinfo
             source));
}  

1;
