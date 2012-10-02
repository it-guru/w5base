package itil::assetphyscore;
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
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{Worktable}="assetphyscore";
   my ($worktable,$workdb)=$self->getWorktable();

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID - Core',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Text(
                name          =>'coreid',
                selectfix     =>1,
                label         =>'CoreID',
                dataobjattr   =>"$worktable.coreid"),
                                                  
      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'ParentID',
                dataobjattr   =>"asset.id"),
                                                  
      new kernel::Field::Link(
                name          =>'assetid',
                selectfix     =>1,
                label         =>'AssetID',
                dataobjattr   =>"$worktable.asset"),
                                                  
      new kernel::Field::Link(
                name          =>'seqid',
                selectfix     =>1,
                label         =>'SeqID',
                dataobjattr   =>"w5seq.id"),
                                                  
      new kernel::Field::Text(
                name          =>'asset',
                readonly      =>1,
                uploadable    =>1,
                label         =>'Asset',
                weblinkto     =>'itil::appl',
                weblinkon     =>['parentid'=>'id'],
                dataobjattr   =>'asset.name'),
   );
   $self->setDefaultView(qw(asset coreid id));
   return($self);
}




sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{parentid} ne ""){
      my $o=$self->Clone();
      my ($id)=$o->ValidatedInsertRecord({assetid=>$rec->{parentid},
                                          coreid=>$rec->{seqid}});
      $rec->{id}=$id;
      $rec->{coreid}=$rec->{seqid};
   }
   return(undef);
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="asset left outer join w5seq on w5seq.id<asset.corecount ".
          "left outer join assetphyscore on asset.id=assetphyscore.asset and ".
          "assetphyscore.coreid=w5seq.id";

   return($from);
}

sub initSqlOrder
{
   my $self=shift;
   return("w5seq.id");
   return;
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
 
   return();
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}



1;
