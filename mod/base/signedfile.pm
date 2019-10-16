package base::signedfile;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
                label         =>'No.'),

      new kernel::Field::Text(
                name          =>'label',
                group         =>'sig',
                label         =>'Path',
                dataobjattr   =>'signedfile.label'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                autogen       =>0,
                dataobjattr   =>'signedfile.fid'),
                                                  
      new kernel::Field::Boolean(
                name          =>'latest',
                group         =>'source',
                label         =>'latest file revision',
                dataobjattr   =>'signedfile.isnewest'),

      new kernel::Field::Text(
                name          =>'parentobj',
                group         =>'sig',
                label         =>'Parentobj',
                dataobjattr   =>'signedfile.parentobj'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'signedfile.createdate'),

      new kernel::Field::Text(
                name          =>'parentid',
                group         =>'sig',
                label         =>'Parentrefid',
                dataobjattr   =>'signedfile.parentid'),

      new kernel::Field::Text(
                name          =>'mandatorid',
                group         =>'sig',
                label         =>'MandatorID',
                dataobjattr   =>'signedfile.mandator'),

      new kernel::Field::Link(
                name          =>'isnewest',
                group         =>'sig',
                label         =>'is latest',
                dataobjattr   =>'signedfile.isnewest'),

      new kernel::Field::Textarea(
                name          =>'datafile',
                label         =>'Data File',
                dataobjattr   =>'signedfile.datafile'),

      new kernel::Field::Text(
                name          =>'filesig',
                group         =>'sig',
                label         =>'signation id',
                dataobjattr   =>'signedfile.keyid'),


   );
   $self->setDefaultView(qw(linenumber parentobj label cdate));
   $self->setWorktable("signedfile");
   return($self);
}

#sub Initialize
#{
#   my $self=shift;
#
#   my @result=$self->AddDatabase(DB=>new kernel::database($self,"sigfilestore"));
#   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
#   return(1) if (defined($self->{DB}));
#   return(0);
#}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_latest"))){
     Query->Param("search_latest"=>$self->T("yes"));
   }
   if (!defined(Query->Param("search_cdate"))){
     Query->Param("search_cdate"=>">now-14d");
   }
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","sig","source");
}

#sub SecureSetFilter
#{
#   my $self=shift;
#   my @flt=@_;
#
#   if (!$self->IsMemberOf("admin")){
#      return($self->SetFilter({id=>\'-99'}));
#   }
#   return($self->SetFilter(@flt));
#}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where;
   if ($self->{secparentobj} ne ""){
      $where="signedfile.parentobj='$self->{secparentobj}'";
   }
   return($where);
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
   return("ALL") if ($self->IsMemberOf("admin"));
   return();
}





1;
