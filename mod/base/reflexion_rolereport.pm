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
                name          =>'isapplmgr',
                label         =>'is databoos',
                dataobjattr   =>'isapplmgr'),

      new kernel::Field::Number(
                name          =>'cntapplmgr',
                label         =>'count of applmgr',
                dataobjattr   =>'cntapplmgr'),

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

      new kernel::Field::Boolean(
                name          =>'isadmin',
                label         =>'is admin (or admin2)',
                dataobjattr   =>'isadmin'),

      new kernel::Field::Number(
                name          =>'cntadmin',
                label         =>'count of admin (or admin2)',
                dataobjattr   =>'cntadmin'),

   );
   $self->setDefaultView(qw(mandator user 
                            isdataboss isapplmgr istsm isopm isadmin));
   return($self);
}


sub getFlagLine
{
   my %mod=@_;

   my @str;

   foreach my $fld (qw(isdataboss istsm isopm isapplmgr isadmin)){
     if ($mod{$fld}){
        push(@str,"''1'' $fld");
     }
     else{
        push(@str,"''0'' $fld");
     }
   }
   return(join(",",@str));

}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @filter=@_;

   my ($worktable,$db)=$self->getWorktable();

   my @view=$self->getCurrentView();

   my @sqlgen=(
   #######################################################################
"
SELECT
   CONCAT('select ',
        IF(m.COLUMN_NAME IS NOT NULL,'mandator AS mandatorid,',
           'NULL AS mandatorid,'),
        'databoss userid,".getFlagLine('isdataboss'=>1)." FROM ',c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'databoss IS NOT NULL and databoss<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'databoss';
"
,   #######################################################################
"
SELECT
   CONCAT('select ',
        IF(m.COLUMN_NAME IS NOT NULL,'mandator AS mandatorid,',
           'NULL AS mandatorid,'),
        'applmgr userid,".getFlagLine('isapplmgr'=>1)." FROM ',c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'applmgr IS NOT NULL and applmgr<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'applmgr';
"
,  #######################################################################
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ',
           'NULL AS mandatorid, '),
        'tsm userid,".getFlagLine('istsm'=>1)." FROM ', c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'tsm IS NOT NULL and tsm<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'tsm';
"
,  #######################################################################
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 
           'NULL AS mandatorid, '),
        'tsm2 userid,".getFlagLine('istsm'=>1)." FROM ', c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'tsm2 IS NOT NULL and tsm2<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'tsm2';
"
,  #######################################################################
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 
           'NULL AS mandatorid, '),
        'opm userid,".getFlagLine('isopm'=>1)." FROM ', c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'opm IS NOT NULL and opm<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'opm';
"
,  #######################################################################
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 
           'NULL AS mandatorid, '),
        'opm2 userid,".getFlagLine('isopm'=>1)." FROM ', c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'opm2 IS NOT NULL and opm2<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'opm2';
"
,  #######################################################################
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 
           'NULL AS mandatorid, '),
        'adm userid,".getFlagLine('isadmin'=>1)." FROM ', c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'adm IS NOT NULL and adm<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'adm';
"
,  #######################################################################
"
SELECT
   CONCAT('SELECT ',
        IF(m.COLUMN_NAME IS NOT NULL, 'mandator AS mandatorid, ', 
           'NULL AS mandatorid, '),
        'adm2 userid,".getFlagLine('isadmin'=>1)." FROM ', c.TABLE_NAME, 
        ' WHERE ',
        IF(cs.COLUMN_NAME IS NOT NULL, 'cistatus < 5 AND ', ''),
        'adm2 IS NOT NULL and adm2<>0'
    ) AS sqlcmd
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.COLUMNS cs
    ON c.TABLE_SCHEMA = cs.TABLE_SCHEMA AND c.TABLE_NAME = cs.TABLE_NAME AND 
       cs.COLUMN_NAME = 'cistatus'
LEFT JOIN INFORMATION_SCHEMA.COLUMNS m
    ON c.TABLE_SCHEMA = m.TABLE_SCHEMA AND c.TABLE_NAME = m.TABLE_NAME AND 
       m.COLUMN_NAME = 'mandator'
WHERE c.TABLE_SCHEMA = database() AND c.COLUMN_NAME = 'adm2';
"
   #######################################################################
);

   my @l;
   foreach my $cmd (@sqlgen){
      if ($db->execute($cmd)){
         while(my $h=$db->fetchrow()){
            push(@l,$h->{sqlcmd});
         }
      }
   }

   my @groupbyfields;

   if (in_array([qw(mandatorid mandator)],\@view)){
      push(@groupbyfields,"mandatorid");
   }
   if (in_array([qw(userid user)],\@view)){
      push(@groupbyfields,"userid");
   }
   my $groupby="";
   if ($#groupbyfields!=-1){
      $groupby="group by ".join(",",@groupbyfields);
   }


   my $from="(select mandatorid,userid,".
              "sum(isdataboss) cntdataboss,".
              "sum(isapplmgr) cntapplmgr,".
              "sum(istsm) cnttsm,".
              "sum(isopm) cntopm,".
              "sum(isadmin) cntadmin,".
              "if (sum(isdataboss)>0,'1','0') isdataboss,".
              "if (sum(isapplmgr)>0,'1','0') isapplmgr,".
              "if (sum(istsm)>0,'1','0') istsm,".
              "if (sum(isopm)>0,'1','0') isopm,".
              "if (sum(isadmin)>0,'1','0') isadmin ".
              "from (".
              join(" union all ",@l).") l1 ".$groupby.") l2";

   return($from);
}


#sub initSearchQuery
#{
#   my $self=shift;
#   my $userid=$self->getCurrentUserId();
#   if (!defined(Query->Param("search_mandator"))){
#     Query->Param("search_mandator"=>
#                  "\"TelekomIT\"");
#   }
#}







sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}




1;
