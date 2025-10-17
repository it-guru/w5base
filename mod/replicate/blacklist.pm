package replicate::blacklist;
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
                dataobjattr   =>'replicateblacklist.id'),
                                                  
      new kernel::Field::Link(
                name          =>'replpartnerid',
                dataobjattr   =>'replicateblacklist.replpartnerid'),

      new kernel::Field::Select(
                name          =>'replpartner',
                label         =>'Replication partner',
                vjointo       =>'replicate::partner',
                vjoinon       =>['replpartnerid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'objtype',
                label         =>'Dataobject',
                dataobjattr   =>'replicateblacklist.objtype'),

      new kernel::Field::Text(
                name          =>'field',
                label         =>'Datafield',
                dataobjattr   =>'replicateblacklist.field'),

      new kernel::Field::Select(
                name          =>'status',
                label         =>'Blacklist status',
                transprefix   =>'status.',
                value         =>['0','1'],
                default       =>'1',
                dataobjattr   =>'replicateblacklist.status'),

      new kernel::Field::Date(
                name          =>'expiration',
                label         =>'Expiration-Date',
                dataobjattr   =>'replicateblacklist.expiration'),
                                                  
      new kernel::Field::Textarea(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'replicateblacklist.comments'),
                                                  
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'replicateblacklist.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'replicateblacklist.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'replicateblacklist.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'replicateblacklist.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'replicateblacklist.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'replicateblacklist.realeditor'),

   );
   $self->setDefaultView(qw(linenumber replpartner objtype
                            field status expiration));
   $self->setWorktable("replicateblacklist");
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
      if ($d->{totalminutes}<60) {
         $self->LastMsg(ERROR,
                   "Expiration-Date must be at least 1h in the future");
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
