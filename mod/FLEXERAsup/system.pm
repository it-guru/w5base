package FLEXERAsup::system;
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
use tsacinv::system;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

=head1

#
# Generierung der Support-Views in der pw5repo Kennung

# -- drop table "W5I_FLEXERAsup__system_of";

create table "W5I_FLEXERAsup__system_of" (
   systemid     varchar2(40) not null,
   comments     varchar2(4000),
   modifyuser   number(*,0),
   modifydate   date,
   constraint "W5I_TAD4Dsup__system_of_pk" primary key (systemid)
);

grant update,insert on "W5I_FLEXERAsup__system_of" to W5I;
create or replace synonym W5I.FLEXERAsup__system_of for "W5I_FLEXERAsup__system_of";



create or replace view "W5I_FLEXERAsup__system" as
select "W5I_system_universum".id,
       "W5I_system_universum".systemname,
       "W5I_system_universum".systemid,
       "W5I_system_universum".saphier,
       "W5I_system_universum".amcostelement costelement,
       decode("mview_FLEXERA_system".FLEXERASYSTEMID,NULL,0,1) flexerafnd,
       "W5I_FLEXERAsup__system_of".systemid of_id,
       "W5I_FLEXERAsup__system_of".comments,
       "W5I_FLEXERAsup__system_of".modifyuser,
       "W5I_FLEXERAsup__system_of".modifydate
from "W5I_system_universum"
     left outer join "W5I_FLEXERAsup__system_of"
        on "W5I_system_universum".systemid="W5I_FLEXERAsup__system_of".systemid
     left outer join "W5I_FLEXERA__systemidmap_of"
        on "W5I_system_universum".systemid="W5I_FLEXERA__systemidmap_of".systemid
     left outer join "mview_FLEXERA_system"
        on "W5I_FLEXERA__systemidmap_of".flexerasystemid="mview_FLEXERA_system".flexerasystemid;

grant select on "W5I_FLEXERAsup__system" to W5I;
create or replace synonym W5I.FLEXERAsup__system for "W5I_FLEXERAsup__system";



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
                dataobjattr   =>"id",
                wrdataobjattr =>"systemid"),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                lowersearch   =>1,
                size          =>'16',
                readonly      =>1,
                dataobjattr   =>'systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                label         =>'SystemID',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'systemid'),

      new kernel::Field::Boolean(
                name          =>'inflexera',
                readonly      =>1,
                label         =>'Flexera installed',
                dataobjattr   =>"flexerafnd"),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP Hier',
                uppersearch   =>1,
                readonly      =>1,
                align         =>'left',
                dataobjattr   =>'saphier'),

      new kernel::Field::Text(
                name          =>'costelement',
                label         =>'costelement',
                ignorecase    =>1,
                readonly      =>1,
                dataobjattr   =>'costelement'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                readonly      =>1,
                label         =>'W5Base Application',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_tsm',
                searchable    =>0,
                readonly      =>1,
                group         =>'w5basedata',
                label         =>'W5Base TSM',
                onRawValue    =>\&tsacinv::system::AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'modifyuser')
   );
   $self->setWorktable("FLEXERAsup__system_of");
   $self->setDefaultView(qw(systemname systemid inflexera comments));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="FLEXERAsup__system";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return( qw(header default w5basedata source));
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{systemid}};
   $newrec->{id}=$oldrec->{systemid};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # flexerasystemid verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
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
   if (!defined(Query->Param("search_saphier"))){
     Query->Param("search_saphier"=>
           "\"K001YT5ATS_ES.K001YT5A_DTIT\" \"K001YT5ATS_ES.K001YT5A_DTIT.*\" ".
           "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
   }
   if (!defined(Query->Param("search_inflexera"))){
      Query->Param("search_inflexera"=>$self->T("no"));
   }
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

#   if (in_array(\@l,"ALL")){
#      if ($rec->{cenv} eq "Both"){
#         return(qw(header source am default));
#      }
#   }
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/) &&
                     !($rec->{systemid}=~m/^\d{14,20}$/));
   my @l=$self->SUPER::isWriteValid($rec,@_);


   return("default") if ($#l!=-1);
   return(undef);
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








1;
