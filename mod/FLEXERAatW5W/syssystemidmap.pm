package FLEXERAatW5W::syssystemidmap;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
#  drop table "W5I_FLEXERA__systemidmap_of";

create table "W5I_FLEXERA__systemidmap_of" (
   flexerasystemid number(10) not null,
   systemid     varchar2(40),
   mapstate     varchar2(80),
   mapuser      number(*,0),cmt varchar2(4000),
   firstdate    date,
   constraint "W5I_FLEXERA__ystemidmap_of_pk" primary key (flexerasystemid)
);
create unique index "W5I_FLEXERA__systemidmap_k1" on "W5I_FLEXERA__systemidmap_of" (systemid);
grant select,update,insert on "W5I_FLEXERA__systemidmap_of" to W5I;
create or replace synonym W5I.FLEXERA__systemidmap_of for "W5I_FLEXERA__systemidmap_of";


create or replace view "W5I_FLEXERAsup__syssystemidmap" as
select "mview_FLEXERA_system".flexerasystemid id,
       "mview_FLEXERA_system".flexerasystemid flexerasystemid,
       "mview_FLEXERA_system".systemname,
       "W5I_FLEXERA__systemidmap_of".flexerasystemid of_id,
       "W5I_FLEXERA__systemidmap_of".mapstate,
       "W5I_FLEXERA__systemidmap_of".systemid,
       "W5I_FLEXERA__systemidmap_of".cmt,
       "W5I_FLEXERA__systemidmap_of".mapuser,
       "W5I_FLEXERA__systemidmap_of".firstdate
from "mview_FLEXERA_system"
     left outer join "W5I_FLEXERA__systemidmap_of"
        on "mview_FLEXERA_system".flexerasystemid=
           "W5I_FLEXERA__systemidmap_of".flexerasystemid;

grant select on "W5I_FLEXERAsup__syssystemidmap" to W5I;
create or replace synonym W5I.FLEXERAsup_syssystemidmap for "W5I_FLEXERAsup__syssystemidmap";

grant select on "W5I_FLEXERA__systemidmap_of" to W5_BACKUP_D1;
grant select on "W5I_FLEXERA__systemidmap_of" to W5_BACKUP_W1;

-- cleanup command for deleted flexerasystemids
delete from "W5I_FLEXERA__systemidmap_of" 
where "W5I_FLEXERA__systemidmap_of".flexerasystemid in (
select "W5I_FLEXERA__systemidmap_of".flexerasystemid 
from "W5I_FLEXERA__systemidmap_of"
left outer join "mview_FLEXERA_system"
on "W5I_FLEXERA__systemidmap_of".flexerasystemid=
"mview_FLEXERA_system".flexerasystemid
where "mview_FLEXERA_system".flexerasystemid is null);


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
                wrdataobjattr =>"flexerasystemid"),

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
                dataobjattr   =>'systemid'),

      new kernel::Field::Select(
                name          =>'webmapstate',
                label         =>'MapState',
                value         =>['MANUAL',
                                 ''
                                ],
                searchable    =>0,
                dataobjattr   =>'mapstate'),

      new kernel::Field::Text(
                name          =>'mapstate',
                htmldetail    =>0,
                label         =>'MapState',
                dataobjattr   =>'mapstate'),

      new kernel::Field::Textarea(
                name          =>'coment',
                label         =>'Comments',
                dataobjattr   =>'cmt'),

      new kernel::Field::Text(
                name          =>'flexerasystemid',
                label         =>'flexerasystemid',
                readonly      =>1,
                ignorecase    =>1,
                dataobjattr   =>'flexerasystemid'),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'firstdate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'mapuser')
   );
   $self->setWorktable("FLEXERA__systemidmap_of");
   $self->setDefaultView(qw(systemname systemid cenv denv todo));
   return($self);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from="FLEXERAsup_syssystemidmap";

   return($from);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default w5basedata am source));
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={id=>\$oldrec->{flexerasystemid}};
   $newrec->{id}=$oldrec->{flexerasystemid};  # als Referenz in der Overflow die 
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      my $o=$self->Clone();
      $o->BackendSessionName("WorkSession-$$");
      return($o->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}





sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"w5warehouse"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=$self->SUPER::isViewValid($rec);

   if (in_array(\@l,"ALL")){
      if ($rec->{cenv} eq "Both"){
         return(qw(header source am default));
      }
   }
   return(@l);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   my @l=$self->SUPER::isWriteValid($rec,@_);

   @l="defualt";


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
