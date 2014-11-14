package TAD4Dsup::system;
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

=head1

#
# Generierung der Support-Views in der pw5repo Kennung
#

create table "OF-A1_W5I_TAD4Dsup__system" (
   systemid     varchar2(40) not null,
   denv         varchar2(20) not null,
   comments     varchar2(4000),
   modifyuser   number(*,0),
   modifydate   date,
   constraint "OF-A1_W5I_TAD4Dsup__system_pk" primary key (systemid)
);


create or replace view "W5I_TAD4Dsup__system" as
select "W5I_system_universum".systemname,
       "W5I_system_universum".systemid,
       "W5I_system_universum".saphier,
       (case
          when "W5I_system_universum".is_t4di=1 and 
               "W5I_system_universum".is_t4dp=1 then 'Both'
          when "W5I_system_universum".is_t4dp=1 then 'Production'
          when "W5I_system_universum".is_t4di=1 then 'Integration'
          else 'None'
       end) cenv ,
       "OF-A1_W5I_TAD4Dsup__system".comments,
       "OF-A1_W5I_TAD4Dsup__system".denv,
       "OF-A1_W5I_TAD4Dsup__system".modifyuser,
       "OF-A1_W5I_TAD4Dsup__system".modifydate
from "W5I_system_universum"
     left outer join "OF-A1_W5I_TAD4Dsup__system" 
        on "W5I_system_universum".systemid=
           "OF-A1_W5I_TAD4Dsup__system".systemid;


create or replace trigger "W5I_TAD4Dsup__system_trigger" 
  INSTEAD of UPDATE on "W5I_TAD4Dsup__system"
  REFERENCING new AS n 
              old AS o
  FOR EACH ROW
declare
   rowcnt number;
begin
   SELECT COUNT(*) INTO rowcnt 
      FROM "OF-A1_W5I_TAD4Dsup__system" 
      WHERE systemid = :o.systemid;
   IF rowcnt = 0  THEN
     INSERT 
        INTO "OF-A1_W5I_TAD4Dsup__system" 
               (   systemid,   comments,   modifyuser,   modifydate,   denv) 
        VALUES (:o.systemid,:n.comments,:n.modifyuser,:n.modifydate,:n.denv);
   ELSE
     UPDATE "OF-A1_W5I_TAD4Dsup__system" 
        SET comments   = :n.comments,
            modifyuser = :n.modifyuser,
            modifydate = :n.modifydate,
            denv       = :n.denv
        WHERE systemid = :o.systemid;
   END IF;
end;


grant select,update on "W5I_TAD4Dsup__system" to W5I;
create or replace synonym W5I.TAD4Dsup__system for "W5I_TAD4Dsup__system";


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
                dataobjattr   =>"(systemid||'-'||systemname)"),

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

      new kernel::Field::Text(
                name          =>'saphier',
                label         =>'SAP Hier',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'saphier'),

      new kernel::Field::Select(
                name          =>'cenv',
                label         =>'current Env',
                readonly      =>1,
                transprefix   =>'ENV.',
                value         =>['Production','Integration','Both','None'],
                dataobjattr   =>'cenv'),

      new kernel::Field::Select(
                name          =>'denv',
                label         =>'destination Env',
                transprefix   =>'ENV.',
                value         =>['Production','Integration',''],
                dataobjattr   =>'denv'),

      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'comments'),

      new kernel::Field::Textarea(
                name          =>'todo',
                label         =>'ToDo',
                dataobjattr   =>
                   "(case".
                   "   when cenv<>denv  then '* move system to '||denv||'\n'".
                   "   else ''".
                   "end) ||".
                   "(case".
                   "   when cenv='Both' then '* remove system ".
                                             "from one enviroment\n'".
                   "   else ''".
                   "end) ||".
                   "(case".
                   "   when denv is null and saphier like '9TS_ES.9DTIT.%' ".
                                         "then '* set destination ".
                                               "enviroment\n'".
                   "   else ''".
                   "end)"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'modifyuser')
   );
   $self->setWorktable("TAD4Dsup__system");
   $self->setDefaultView(qw(systemname systemid cenv denv todo));
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


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_saphier"))){
     Query->Param("search_saphier"=>
                  "\"9TS_ES.9DTIT\" \"9TS_ES.9DTIT.*\"");
   }
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated

   return(undef) if (!defined($rec));
   return(undef) if (!($rec->{systemid}=~m/^S.*\d+$/));
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
