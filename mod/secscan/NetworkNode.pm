package secscan::NetworkNode;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

=head1

#
# Generierung der Support-Views in der pw5repo Kennung

create or replace view "W5I_secscan__NetworkNode" as
   select "W5_id"        id,
          "W5_mdate"     dmdate, 
          "W5_cdate"     dcdate,
          "C01_Host"     host,
          "C02_DNSName"  dns,
          "C03_Ports"    ports,
          TO_DATE("w5secscan_NetworkNode"."C04_ScanDate",
                  'YYYY-MM-DD HH24:MI:SS')                  dscandate,
          "w5secscan_NetworkNode"."W5_isdel"                isdel
   from "W5FTPGW1"."w5secscan_NetworkNode";

grant select on "W5I_secscan__NetworkNode" to W5I;
create or replace synonym W5I.secscan__networknode 
                          for "W5I_secscan__NetworkNode";


=cut

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{useMenuFullnameAsACL}=$self->Self();

   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'ID',
                group         =>'source',
                align         =>'left',
                history       =>0,
                htmldetail    =>0,
                dataobjattr   =>"id"),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Host',
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'host'),

      new kernel::Field::Text(
                name          =>'ports',
                label         =>'TCP-Ports',
                readonly      =>1,
                dataobjattr   =>'ports'),

      new kernel::Field::Date(
                name          =>'scandate',
                label         =>'Scan-Date',
                group         =>'source',
                readonly      =>1,
                dataobjattr   =>'dscandate'),

      new kernel::Field::Boolean(
                name          =>'isdel',
                group         =>'source',
                label         =>'marked as deleted',
                dataobjattr   =>'isdel'),

      new kernel::Field::CDate(
                name          =>'cdate',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Create-Date',
                dataobjattr   =>'dcdate'),

   );
   $self->setWorktable("secscan__networknode");
   $self->setDefaultView(qw(name ports scandate));
   return($self);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default source));
}




sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub initSearchQuery
{
   my $self=shift;

   if (!defined(Query->Param("search_isdel"))){
     Query->Param("search_isdel"=>"\"".$self->T("no")."\"");
   }

}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   if ($self->IsMemberOf(["admin",
                          "w5base.secscan.read",
                          "w5base.secscan.write"])){
      my @l=qw(source default header);
      return(qw(ALL));
   }
   return(undef);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




1;
