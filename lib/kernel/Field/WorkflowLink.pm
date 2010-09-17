package kernel::Field::WorkflowLink;
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
@ISA    = qw(kernel::Field::TextDrop);


sub new
{
   my $type=shift;
   my %param=@_;
   if (ref($param{vjoinon}) ne "ARRAY"){
      $param{vjoinon}=[$param{vjoinon}=>'id'];
   }
   $param{vjointo}='base::workflow'  if (!defined($param{vjointo}));
  # $param{vjoindisp}='fullname'  if (!defined($param{vjoindisp}));
   if (!defined($param{vjoindisp})){
      $param{vjoindisp}=['id','name','srcid'];
   }
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record
   my $comprec=shift;        # values vor History Handling
   my $name=$self->Name();
   return({}) if (!exists($newrec->{$name}));
   my $newval=$newrec->{$name};
   my $disp=$self->{vjoindisp};

   $disp=[$disp] if (ref($disp) ne "ARRAY");
   my $filter=[{id=>\$newval},{srcid=>\$newval}];

   $self->FieldCache->{LastDrop}=undef;

   if (defined($self->{vjoinbase})){
      $self->vjoinobj->SetNamedFilter("BASE",$self->{vjoinbase});
   }
   if (defined($self->{vjoineditbase})){
      $self->vjoinobj->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
   }
   if (defined($newrec->{$self->{vjoinon}->[0]}) &&  # just test !!
       $newrec->{$self->{vjoinon}->[0]} ne ""){  # if id is already specified
      $filter={$self->{vjoinon}->[1]=>\$newrec->{$self->{vjoinon}->[0]}};
   }
   $self->vjoinobj->SetFilter($filter);
   my %param=(AllowEmpty=>$self->AllowEmpty);
   my $fromquery=trim(Query->Param("Formated_$name"));
   if (defined($fromquery)){
      $param{Add}=[{key=>$fromquery,val=>$fromquery},
                   {key=>"",val=>""}];
      $param{onchange}=
         "if (this.value==''){".
         "transformElement(this,{type:'text',className:'finput'});".
         "}";
      $param{selected}=$fromquery;
   }
   my ($dropbox,$keylist,$vallist)=$self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $disp->[0],
                                                  $disp,%param);
   if ($#{$keylist}>0){
      $self->FieldCache->{LastDrop}=$dropbox;
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' is not unique",
                                      $self->Label,$newval);
      return(undef);
   }
   if ($#{$keylist}<0 && ((defined($fromquery) && $fromquery ne "") ||
                          (defined($newrec->{$name}) && 
                           $newrec->{$name} ne $oldrec->{$name}))){
      if ($newrec->{$name} eq "" && $self->{AllowEmpty}){
         if (defined($self->{altnamestore})){
            return({$self->{vjoinon}->[0]=>undef,
                    $self->{altnamestore}=>undef});
         }
         return({$self->{vjoinon}->[0]=>undef});
      }
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' not found",$self->Label,
                                      $newval);
      return(undef);
   }
   $filter={id=>\$vallist->[0]};
   Query->Param("Formated_".$name=>$vallist->[0]);
   if (defined($comprec) && ref($comprec) eq "HASH"){
      $comprec->{$name}=$vallist->[0];
   }
   my $result={$self->{vjoinon}->[0]=>
           $self->vjoinobj->getVal($self->vjoinobj->IdField->Name(),$filter)};
   if (defined($self->{altnamestore})){
      $result->{$self->{altnamestore}}=$vallist->[0];      
   }
   return($result);
}



1;
