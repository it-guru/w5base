package base::blacklist;
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
use kernel::App::Web::Listedit;
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
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                uivisible     =>0,
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>'objblacklist.id'),
                                                  
      new kernel::Field::Text(
                name          =>'objtype',
                label         =>'Dataobject',
                dataobjattr   =>'objblacklist.objtype'),

      new kernel::Field::Text(
                name          =>'field',
                label         =>'Datafield',
                dataobjattr   =>'objblacklist.field'),

      new kernel::Field::Link(
                name          =>'replpartnerid',
                dataobjattr   =>'objblacklist.replpartnerid'),

      new kernel::Field::Select(
                name          =>'status',
                label         =>'Blacklist status',
                transprefix   =>'status.',
                value         =>['0','1'],
                default       =>'1',
                dataobjattr   =>'objblacklist.status'),

      new kernel::Field::Date(
                name          =>'limitstart',
                label         =>'start of blocking',
                dataobjattr   =>"if (objblacklist.limitstart is null,".
                                "objblacklist.createdate,".
                                "objblacklist.limitstart)",
                wrdataobjattr =>'objblacklist.limitstart'),
                                                  
      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'objblacklist.expiration'),
                                                  
      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'objblacklist.comments'),
                                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'objblacklist.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'objblacklist.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'objblacklist.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'objblacklist.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'objblacklist.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'objblacklist.realeditor'),

   );
   $self->setDefaultView(qw(linenumber replpartner objtype
                            field status limitstart expiration));
   $self->setWorktable("objblacklist");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   # validate Dataobject
   my $objtype=trim(effVal($oldrec,$newrec,"objtype"));
   if ($objtype eq "") {
      $self->LastMsg(ERROR,"Dataobject not specified");
      return(undef);
   }
   if ($objtype=~m/^base::/){
      $self->LastMsg(ERROR,"base:: Dataobjects are not allowed in blacklist");
      return(undef);
   }


   my $replpartnerid=effVal($oldrec,$newrec,"replpartnerid");

   my $chko=getModuleObject($self->Config,$objtype);
   if (!defined($chko)){
      $self->LastMsg(ERROR,"invalid Dataobject");
      return(undef);
   }

   # validate Datafield
   $newrec->{field}=lc($newrec->{field});
   my $field=trim(effVal($oldrec,$newrec,"field"));
   if ($field ne "") {
      my $o=getModuleObject($self->Config,$newrec->{objtype});
      my @fields=$o->getFieldList();
      if (!in_array(\@fields,$field)) {
         $self->LastMsg(ERROR,"invalid Datafield");
         return(undef);
      }
   }

   # validate Expiration-Date
   my $expiration=trim(effVal($oldrec,$newrec,"expiration"));
   if (defined($expiration) && (effVal($oldrec,$newrec,"status")==1)) {
      my $d=CalcDateDuration(NowStamp('en'),$expiration);
      if ($d->{totalminutes}<9) {
         $self->LastMsg(ERROR,
                   "Expiration-Date must be at least 1h in the future");
         return(undef);
      }
   }
   my $limitstart=effVal($oldrec,$newrec,"limitstart");
   my $expiration=effVal($oldrec,$newrec,"expiration");
   if ($limitstart ne "" && $expiration ne ""){
      my $d=CalcDateDuration($limitstart,$expiration);
      if ($d->{totalseconds}<=0){
         $self->LastMsg(ERROR,"begin after end not allowed");
         return(undef);
      }
   }

   return(1);
}


sub isCopyValid
{
   my $self=shift;

   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec) && $self->IsMemberOf("admin"));
   return("ALL");
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if ($self->IsMemberOf("admin"));
   return(undef);
}



1;
