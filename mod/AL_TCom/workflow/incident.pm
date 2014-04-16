package AL_TCom::workflow::incident;
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
use kernel::WfClass;
use itil::workflow::incident;
use AL_TCom::lib::workflow;

@ISA=qw(itil::workflow::incident AL_TCom::lib::workflow);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   return($self);
}

sub Init
{
   my $self=shift;
   $self->AddGroup("tcomcod");
   return($self->SUPER::Init(@_));
}

sub isOptionalFieldVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   my $name=$param{field}->Name();

   return(1) if ($name eq "relations");
   return($self->SUPER::isOptionalFieldVisible($mode,%param));
}




sub getDynamicFields
{
   my $self=shift;
   my %param=@_;
   my @l=();
   my $rootcauseana=<<EOF;
var f=document.forms[0];
if (!f){return}
var self=f.elements['Formated_tcomcodrootcauseanalyse'];
if (!self){return}
var e=f.elements['Formated_tcomworktimeproblem'];
if (!e){return}
if (self.options[self.selectedIndex].value=="yes"){
   e.readOnly=false;
   e.style.background="white";
}
else{
   e.value="0";
   e.readOnly=true;
   e.style.background="silver";
}

EOF
   
   return($self->SUPER::getDynamicFields(%param),
          $self->InitFields(
           new kernel::Field::Select(    name       =>'tcomcodrelevant',
                                         label      =>'Workflow invoice',
                                         htmleditwidth=>'20%',
                                         value      =>['',qw(yes no)],
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Select(    name       =>'tcomcodcause',
                                         label      =>'Activity',
                                         translation=>'AL_TCom::lib::workflow',
                                         default    =>'undef',
                                         value      =>
                             [AL_TCom::lib::workflow::tcomcodcause()],
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Textarea(  name        =>'tcomcodcomments',
                                         label       =>'work details',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Select(    name       =>'tcomcodrootcauseanalyse',
                                         label      =>'RootCause Analyses',
                                         htmleditwidth=>'20%',
                                         default    =>'no',
                                         jsonchanged=>$rootcauseana,
                                         value      =>[qw(no yes)],
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Text(      name        =>'tcomexternalid',
                                         label       =>'ExternalID (I-Network)',
                                         group       =>'tcomcod',
                                         container   =>'headref'),

           new kernel::Field::Number(    name       =>'tcomworktimeproblem',
                                         unit       =>'min',
                                         label      =>'Worktime Problem-Mgmt',
                                         group      =>'tcomcod',
                                         container  =>'headref'),

           new kernel::Field::Number(    name       =>'tcomworktime',
                                         unit       =>'min',
                                         onUnformat =>
                                      \&AL_TCom::lib::workflow::minUnformat,
                                         detailadd  =>
                                      \&AL_TCom::lib::workflow::tcomworktimeadd,
                                         label      =>'Worktime',
                                         group      =>'tcomcod',
                                         container  =>'headref'),



   ));
}



sub isWriteValid
{
   my $self=shift;
   my $rec=shift;  # if $rec is not defined, insert is validated
   my @edit;

   return(undef) if (!defined($rec));
   return(undef) if ($rec->{stateid}==21);
   return(undef) if (!($rec->{step}=~m/::postreflection$/));
   if ($self->isPostReflector($rec)){
      push(@edit,"tcomcod","affected");
   }

   return(@edit);  # ALL means all groups - else return list of fieldgroups
}



sub getDetailBlockPriority                # posibility to change the block order
{
   my $self=shift;
   return("header","default","itilincident","flow","affected","tcomcod","state","relations","source");
}










1;
