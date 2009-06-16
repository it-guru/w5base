package tsacinv::quality_appl;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                htmlwidth     =>'10px',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'srcsys',
                align         =>'left',
                htmlwidth     =>undef,
                sqlorder      =>'none',
                label         =>'Source-System',
                dataobjattr   =>'data.srcsys'),

      new kernel::Field::Text(
                name          =>'cicount',
                sqlorder      =>'desc',
                align         =>'right',
                htmlwidth     =>'50px',
                label         =>'Appl count',
                dataobjattr   =>'data.cicount'),

      new kernel::Field::Number(
                name          =>'avgquality',
                align         =>'right',
                htmlwidth     =>'50px',
                searchable    =>'0',
                unit          =>'%',
                precision     =>'2',
                label         =>'averanged quality',
                sqlorder      =>'desc',
                dataobjattr   =>'round((round(100*sem/cicount,2)+'.
                                'round(100*cono/cicount,2)+'.
                                'round(100*cusage/cicount,2)+'.
                                'round(100*descr/(cicount*100),2)+'.
                                'round(100*tsm/cicount,2))/5,2)'),

      new kernel::Field::Text(
                name          =>'prodcount',
                align         =>'right',
                htmlwidth     =>'50px',
                group         =>'base',
                label         =>'Production Count',
                dataobjattr   =>'data.prodcount'),

      new kernel::Field::Text(
                name          =>'usagecount',
                align         =>'right',
                htmlwidth     =>'50px',
                group         =>'base',
                label         =>'Usage count',
                dataobjattr   =>'data.cusage'),

      new kernel::Field::Number(
                name          =>'semcountp',
                align         =>'right',
                htmlwidth     =>'100px',
                group         =>'base',
                searchable    =>'0',
                unit          =>'%',
                label         =>'SeM count',
                dataobjattr   =>'round(100*sem/cicount,2)'),

      new kernel::Field::Text(
                name          =>'semcount',
                align         =>'right',
                htmlwidth     =>'50px',
                group         =>'base',
                label         =>'SeM count',
                dataobjattr   =>'data.sem'),

      new kernel::Field::Text(
                name          =>'tsmcount',
                align         =>'right',
                htmlwidth     =>'50px',
                group         =>'base',
                label         =>'TSM count',
                dataobjattr   =>'data.tsm'),

      new kernel::Field::Number(
                name          =>'tsmcountp',
                align         =>'right',
                group         =>'base',
                htmlwidth     =>'100px',
                searchable    =>'0',
                unit          =>'%',
                label         =>'TSM count',
                dataobjattr   =>'round(100*tsm/cicount,2)'),

      new kernel::Field::Text(
                name          =>'conocount',
                align         =>'right',
                htmlwidth     =>'50px',
                group         =>'base',
                label         =>'CO-Number count',
                dataobjattr   =>'data.cono'),

      new kernel::Field::Number(
                name          =>'conocountp',
                align         =>'right',
                group         =>'base',
                htmlwidth     =>'100px',
                searchable    =>'0',
                unit          =>'%',
                label         =>'CO-Number count',
                dataobjattr   =>'round(100*cono/cicount,2)'),

      new kernel::Field::Text(
                name          =>'descrcount',
                align         =>'right',
                htmlwidth     =>'50px',
                group         =>'base',
                label         =>'Description char count',
                dataobjattr   =>'data.descr'),

      new kernel::Field::Number(
                name          =>'descrcountp',
                align         =>'right',
                htmlwidth     =>'100px',
                group         =>'base',
                searchable    =>'0',
                unit          =>'%',
                label         =>'Description char count',
                dataobjattr   =>'round(100*descr/(cicount*100),2)'),

   );
   $self->setDefaultView(qw(linenumber srcsys avgquality cicount usagecount
                            prodcount
                            semcount tsmcount conocount descrcount maintcount));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}


sub getSqlFrom
{
   my $self=shift;
   my $from=<<EOF;
(select decode(externalsystem,'','AssetManager',externalsystem) as srcsys,  
        count(*)                                               as cicount,
        sum(decode(lservicecontactid,0,0,1))                   as sem,     
        sum(decode(ltechnicalcontactid,0,0,1))                 as tsm,
        sum(decode(usage,'',0,1))                              as cusage,
        sum(decode(usage,'PRODUCTION',1,0))                    as prodcount,
        sum(decode(lcostcenterid,0,0,1))                       as cono,    
        sum(length(description))                               as descr
 from AMTSICUSTAPPL
 where bdelete=0 
 group by externalsystem) data
EOF
   return($from);
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


1;
