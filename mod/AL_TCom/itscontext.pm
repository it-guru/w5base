package AL_TCom::itscontext;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
   $param{MainSearchFieldLines}=3 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(

      new kernel::Field::Link(
                name          =>'id',
                label         =>'id',
                dataobjattr   =>"concat(itsid,'-',esid,'-',taid)"),

      new kernel::Field::Link(
                name          =>'itsid',
                label         =>'itsid',
                dataobjattr   =>"itsid"),

      new kernel::Field::Link(
                name          =>'esid',
                label         =>'esid',
                dataobjattr   =>"esid"),

      new kernel::Field::Link(
                name          =>'taid',
                label         =>'taid',
                dataobjattr   =>"taid"),

      new kernel::Field::Text(
                name          =>'scontextcode',
                label         =>'Context',
                dataobjattr   =>"concat_ws('#',".
                                 "concat(itsnature,'_',itsshort),".
                                 "concat(esnature,espos),".
                                 "concat(tanature,tapos))"),

   );

   $self->setDefaultView(qw(scontextcode));
   return($self);
}




sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from=<<EOF;

   (
      select its.id itsid,
             its.nature itsnature, its.shortname itsshort,
             es.id esid,es.nature esnature,lnkits.lnkpos espos,
             ta.id taid,ta.nature tanature,lnkes.lnkpos tapos

      from businessservice as its
         left outer join lnkbscomp as lnkits
            on its.id=lnkits.businessservice
               and lnkits.objtype='itil::businessservice'
         left outer join businessservice as es
            on lnkits.obj1id=es.id
               and es.nature='ES'
         left outer join lnkbscomp as lnkes
            on es.id=lnkes.businessservice
               and lnkes.objtype='itil::businessservice'
         left outer join businessservice as ta
            on lnkes.obj1id=ta.id
               and ta.nature='TR'

      where its.nature='IT-S' and its.shortname<>''

      union

      select its.id itsid, 
             its.nature itsnature, its.shortname itsshort,
             es.id esid,es.nature esnature,lnkits.lnkpos espos,
             NULL taid,NULL tanature,NULL tapos

      from businessservice as its
         left outer join lnkbscomp as lnkits
            on its.id=lnkits.businessservice
               and lnkits.objtype='itil::businessservice'
         left outer join businessservice as es
            on lnkits.obj1id=es.id
               and es.nature='ES'

      where its.nature='IT-S' and its.shortname<>''

      union

      select its.id itsid,
             its.nature, its.shortname itsshort,
             NULL esid,NULL esnature,NULL espos,
             NULL taid,NULL tanature,NULL tapos

      from businessservice as its

      where its.nature='IT-S' and its.shortname<>''

   ) scontext

EOF


   return($from);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isUploadValid
{
   return(undef);
}



1;
