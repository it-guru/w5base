package tsbmcpatrol::swinstance;
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

#
#  Das wird die zukünftige Referenzimplementation für das Overflow-Tabel
#  Konzept (Projekt-Daten an "offiziellen CIs")
#

use strict;
use vars qw(@ISA);
use kernel;
use kernel::Field;
use itil::swinstance;
@ISA=qw(itil::swinstance);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->{useMenuFullnameAsACL}=$self->Self(); # ACL über das Menü

   #
   # vorhandene Felder korrigieren
   #
   foreach my $fld ($self->getFieldObjsByView(['ALL'])){
      if (in_array([qw(source qc contacts attachments)],$fld->{group})){
         $self->DelFields($fld->Name());
      }
      # aller ausser "default" aus der HtmlDetail View entfernen und ro machen
      elsif (!in_array([qw( default)],$fld->{group})){
         $fld->{htmldetail}=0;
         $fld->{readonly}=1;
      }
      # rest soll in jedem Fall ro sein
      else{
         $fld->{readonly}=1;
      }
   }

   # keinen Karteireiter "Workflows" anzeigen
   delete($self->{workflowlink});

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'ofid',
                selectfix     =>1,
                group         =>'bmcdata',
                label         =>'Overflow ID',
                dataobjattr   =>'of_id'),

      new kernel::Field::Text(
                name          =>'oflocintserv',
                htmldetail    =>1,
                uploadable    =>1,
                group         =>'bmcdata',
                label         =>'Location Integration Service',
                dataobjattr   =>'of_locintserv'),

      new kernel::Field::Textarea(
                name          =>'ofconnectstr',
                htmldetail    =>1,
                uploadable    =>1,
                group         =>'bmcdata',
                label         =>'Connect String',
                dataobjattr   =>'of_connectstr'),

      new kernel::Field::Textarea(
                name          =>'ofcomments',
                htmldetail    =>1,
                uploadable    =>1,
                group         =>'bmcdata',
                label         =>'Comments',
                dataobjattr   =>'of_comments'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'of_modifydate'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'of_modifyuser'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"swinstance_bmcpatrol_of.of_modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(swinstance.id,35,'0')"),

   );

   $self->AddGroup("bmcdata",translation=>'tsbmcpatrol::swinstance');

   $self->setWorktable("swinstance_bmcpatrol_of");

   # ID Schreibzugriffe auf das richtige Feld umleiten
   $self->IdField()->{wrdataobjattr}="of_id";
 
   return($self);
}


# Overflow Table per outer join hinzufügen
sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $from=$self->SUPER::getSqlFrom($mode,@flt);

   $from.=" left outer join swinstance_bmcpatrol_of ".
          "on swinstance.id=swinstance_bmcpatrol_of.of_id";

   return($from);
}

sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   if (!defined($oldrec->{ofid})){
      $newrec->{ofid}=$oldrec->{id};
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}

sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($W5V2::OperationContext eq "W5Replicate"){
      if ($#flt!=0 || ref($flt[0]) ne "HASH"){
         $self->LastMsg("ERROR","invalid Filter request on $self");
         return(undef);
      }

      my %f1=(%{$flt[0]});
      $f1{ofid}='![EMPTY]';

      @flt=([\%f1]);
   }
   return($self->SUPER::SetFilter(@flt));
}



# wegen der History muß die parent Hierarchi neu begnonnen werden
sub SelfAsParentObject    
{
   return("tsbmcpatrol::swinstance");
}


# auf jeden Fall eine eigene Validate Routine installieren
sub Validate         
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}


# Ableiten von der Kern isWriteValid und die Overflow Gruppe hinzufügen
sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;

   return(undef) if (!defined($oldrec));   # new never allowed
   my @l=$self->kernel::DataObj::isWriteValid($oldrec,@_);
   if (grep(/^(default|ALL)$/,@l)){
      return("bmcdata");
   }
   return(@l);
}


# Ableiten von der Kern isWriteValid und die Overflow Gruppe hinzufügen
sub isViewValid
{
   my $self=shift;
   my @l=$self->kernel::DataObj::isViewValid(@_);
   if (grep(/^(default|ALL)$/,@l)){
      push(@l,"bmcdata");
   }
   return(@l);
}


# wenn über das Menü Zugriff da ist, dann sollen ALLE Datensätze sichtbar werden
sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   return($self->kernel::DataObj::SetFilter(@flt));
}


# Delete macht (wenn überhaupt) dann die Datebank per foregin key
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


sub isCopyValid
{
   my $self=shift;

   return(0);
}


sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l; 
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "relations");
   }
   splice(@l,$inserti,$#l-$inserti,("bmcdata",@l[$inserti..($#l+-1)]));
   return(@l);
}

    





1;
