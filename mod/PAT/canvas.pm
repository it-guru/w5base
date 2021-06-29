package PAT::canvas;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use TS::canvas;
use PAT::lib::Listedit;
@ISA=qw(TS::canvas);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                dataobjattr   =>'PAT_canvas.id'),

      new kernel::Field::Contact(
                name          =>'ibiresponse',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'ibi',
                label         =>'IBI responsible',
                vjoinon       =>'ibiresponseid'),

      new kernel::Field::Interface(
                name          =>'ibiresponseid',
                group         =>'ibi',
                dataobjattr   =>'PAT_canvas.ibiresponse'),

      new kernel::Field::Textarea(
                name          =>'ibicomments',
                group         =>'ibi',
                label         =>'IBI comments',
                dataobjattr   =>'PAT_canvas.comments'),
   );



   $self->setDefaultView(qw(canvasid name ibiresponse));
   $self->setWorktable("PAT_canvas");
   return($self);
}



sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={ofid=>\$oldrec->{id}};
   $newrec->{ofid}=$oldrec->{id};  # als Referenz in der Overflow die
   if (!defined($oldrec->{ofid})){     # SystemID verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my $worktable="swinstance";
   my $from="canvas";

   $from.=" left outer join PAT_canvas ".
          "on canvas.id=PAT_canvas.id ";
   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $comprec=shift;

   return(1);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   my @wrgrp=qw(ibi);

   return(@wrgrp) if ($self->PAT::lib::Listedit::isWriteValid($rec));
   return(undef);
}


sub isViewValid
{
   my $self=shift;
   my @l;


   my @orgl=$self->SUPER::isViewValid(@_);
 
   push(@orgl,"ibi");

   return(@orgl);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my @l=$self->SUPER::getDetailBlockPriority(@_);
   my $inserti=$#l;
   for(my $c=0;$c<=$#l;$c++){
      $inserti=$c+1 if ($l[$c] eq "default");
   }
   splice(@l,$inserti,$#l-$inserti,("ibi",@l[$inserti..($#l+-1)]));
   return(@l);
}




1;
