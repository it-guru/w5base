package base::reflexion_rolereport;
#  W5Base Framework
#  Copyright (C) 2025  Hartmut Vogler (it@guru.de)
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
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(

      new kernel::Field::Mandator(),

      new kernel::Field::Text(
                name          =>'mandatorid',
                label         =>'MandatorID',
                dataobjattr   =>'mandatorid'),

      new kernel::Field::Contact(
                name          =>'user',
                label         =>'Contact',
                vjoinon       =>'userid'),

      new kernel::Field::Text(
                name          =>'userid',
                label         =>'UserID',
                dataobjattr   =>'userid'),

      new kernel::Field::Boolean(
                name          =>'isdataboss',
                label         =>'is databoos',
                dataobjattr   =>'isdataboss'),

      new kernel::Field::Number(
                name          =>'cntdataboss',
                label         =>'count of databoos',
                dataobjattr   =>'cntdataboss'),

      new kernel::Field::Boolean(
                name          =>'istsm',
                label         =>'is tsm (or tsm2)',
                dataobjattr   =>'istsm'),

      new kernel::Field::Number(
                name          =>'cnttsm',
                label         =>'count of tsm (or tsm2)',
                dataobjattr   =>'cnttsm'),

      new kernel::Field::Boolean(
                name          =>'isopm',
                label         =>'is opm (or opm2)',
                dataobjattr   =>'isopm'),

      new kernel::Field::Number(
                name          =>'cntopm',
                label         =>'count of opm (or opm2)',
                dataobjattr   =>'cntopm'),

   );
   $self->setDefaultView(qw(mandator user isdataboss istsm isopm));
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$db)=$self->getWorktable();

   my @view=$self->getCurrentView();

print STDERR ("fifi fields=%s\n",Dumper(\@view));


   my @sqlgen=(
"
SELECT
   CONCAT('select ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 'NULL AS mandatorid, '),
        'databoss userid,''1'' isdataboss,''0'' istsm,''0'' isopm FROM ', c.TABLE_NAME, ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'databoss IS NOT NULL and databoss<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'databoss';
",
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 'NULL AS mandatorid, '),
        'tsm userid,''0'' isdataboss,''1'' istsm,''0'' isopm  FROM ', c.TABLE_NAME, ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'tsm IS NOT NULL and tsm<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'tsm';
",
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 'NULL AS mandatorid, '),
        'tsm2 userid,''0'' isdataboss,''1'' istsm,''0'' isopm  FROM ', c.TABLE_NAME, ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'tsm2 IS NOT NULL and tsm2<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'tsm2';
",
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 'NULL AS mandatorid, '),
        'opm userid,''0'' isdataboss,''0'' istsm,''1'' isopm  FROM ', c.TABLE_NAME, ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'opm IS NOT NULL and opm<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'opm';
",
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 'NULL AS mandatorid, '),
        'opm2 userid,''0'' isdataboss,''0'' istsm,''1'' isopm  FROM ', c.TABLE_NAME, ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'opm2 IS NOT NULL and opm2<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'opm2';
"
);

   my @l;
   foreach my $cmd (@sqlgen){
      if ($db->execute($cmd)){
         while(my $h=$db->fetchrow()){
            push(@l,$h->{sqlcmd});
         }
      }
   }

   my $from="(select mandatorid,userid,".
              "sum(isdataboss) cntdataboss,".
              "sum(istsm) cnttsm,".
              "sum(isopm) cntopm,".
              "if (sum(isdataboss)>0,'1','0') isdataboss,".
              "if (sum(istsm)>0,'1','0') istsm,".
              "if (sum(isopm)>0,'1','0') isopm ".
              "from (".
              join(" union all ",@l).") l1 group by mandatorid,userid) l2";

   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   my $userid=$self->getCurrentUserId();
   if (!defined(Query->Param("search_mandator"))){
     Query->Param("search_mandator"=>
                  "\"TelekomIT\"");
   }
}







sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}




1;
