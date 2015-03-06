package tshpsa::lnkswp;
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
   #$param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                group         =>'source',
                label         =>'ItemID',
                htmldetail    =>0,
                dataobjattr   =>"id"),

      new kernel::Field::Link(
                name          =>'systemid',
                label         =>'system id',
                dataobjattr   =>'sysid'),

      new kernel::Field::Text(
                name          =>'fullname',
                searchable    =>0,
                nowrap        =>1,
                htmlwidth     =>'120',
                htmldetail    =>0,
                label         =>'Process entry fullname',
                dataobjattr   =>'fullname'),

      new kernel::Field::Text(
                name          =>'softwarename',
                ignorecase    =>1,
                nowrap        =>1,
                searchable    =>0,
                htmlwidth     =>'120',
                label         =>'based on Software',
                depend        =>['softwareid','software','class'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $soft=$self->getParent->getField("software");
                   my $s=$soft->RawValue($current);
                   if ($s ne ""){
                      return($s);
                   }
                   return($current->{class});
                }),

      new kernel::Field::Text(
                name          =>'class',
                ignorecase    =>1,
                nowrap        =>1,
                htmlwidth     =>'120',
                label         =>'Software-Key',
                dataobjattr   =>'swclass'),

      new kernel::Field::Text(
                name          =>'version',
                label         =>'version',
                dataobjattr   =>'swvers'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Hostname',
                group         =>'rel',
                vjointo       =>'tshpsa::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'systemsystemid',
                label         =>'SystemID',
                group         =>'rel',
                vjointo       =>'tshpsa::system',
                vjoinon       =>['systemid'=>'id'],
                vjoindisp     =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5appl',
                label         =>'usable from applications',
                group         =>'w5basedata',
                searchable    =>0,
                weblinkto     =>'none',
                vjointo       =>'itil::system',
                vjoinon       =>['systemsystemid'=>'systemid'],
                vjoindisp     =>['applicationnames']),

      new kernel::Field::Text(
                name          =>'softwareid',
                label         =>'SoftwareID',
                group         =>'w5basedata',
                searchable    =>0,
                depend        =>['class'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $id;
                   if ($current->{class} ne ""){
                      my ($iid)=$current->{class}=~m/\[(\d+)\]$/;
                      $id=$iid;
                   }
                   return($id);
                }),

      new kernel::Field::TextDrop(
                name          =>'software',
                htmlwidth     =>'200px',
                label         =>'Software',
                group         =>'w5basedata',
                vjoineditbase =>{cistatusid=>[3,4]},
                vjointo       =>'itil::software',
                vjoinon       =>['softwareid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'path',
                label         =>'path',
                dataobjattr   =>'swpath'),

      new kernel::Field::Text(
                name          =>'uname',
                label         =>'ProcessUser',
                dataobjattr   =>'iname'),

      new kernel::Field::Text(
                name          =>'scandate',
                label         =>'Scandate',
                dataobjattr   =>'scandate')

   );
   $self->setDefaultView(qw(systemname class version path iname));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tshpsa"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;
(
select attr.item_id sysid,
--       attr.item_id || '-' || swi.swid id,
       replace(utl_i18n.string_to_raw(data =>
           attr.item_id||'-'||swi.swclass||'-'||
           swi.swpath||'-'||swi.iname),' ','') id,
       attr.item_id||' - 'swi.swclass||' - '||
       swi.swpath||' - '||swi.iname fullname,
       ddim.curdate,
       swi.swclass,
       swi.swvers,
       swi.swpath,
       swi.iname,
       swi.scandate

from (select DATE_DIMENSION.FULL_DATE_LOCAL curdate 
      from DATE_DIMENSION 
      where DATE_DIMENSION.FULL_DATE_LOCAL between SYSDATE-1 AND SYSDATE)  ddim
      join  SAS_SERVER_CUST_ATTRIBUTES attr
          on ddim.curdate between attr.begin_date and attr.end_date
             and attr.ATTRIBUTE_NAME='TI.CSO_ao_mw_scanner',
      XMLTable ( '//x/r'
          passing XMLType( 
           '<x><r><f>' || 
              replace(
                  replace(
                     rtrim(trim( 
                       case when length(attr.ATTRIBUTE_SHORT_VALUE)>2500 then
                       substr(attr.ATTRIBUTE_SHORT_VALUE,0,2500) || '...'
                       else
                       attr.ATTRIBUTE_SHORT_VALUE
                       end
                     ),chr(10)),chr(10),
                     '</f></r><r><f>'
                  ),';','</f><f>'
              ) ||
           '</f></r></x>' 
          )
          columns swid      FOR ORDINALITY,
                  swclass   varchar2(40)  path 'f[1]',
                  swvers    varchar2(40)  path 'f[2]',
                  swpath    varchar2(512) path 'f[3]',
                  iname     varchar2(40)  path 'f[4]',
                  scandate  varchar2(40)  path 'f[5]'
      ) swi
) lnkswi
EOF

   return($from);
}




sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","rel","w5basedata","source");
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/base/load/grp.jpg?".$cgi->query_string());
#}
         

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
