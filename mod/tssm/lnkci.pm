package tssm::lnkci;
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
use tssm::lnk;
@ISA=qw(tssm::lnk);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Text (
                name          =>'descname',
                label         =>'Name',
                depend        =>['description'],
                htmlwidth     =>'200px',
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    return(split("\n",$current->{description}))[4];
                 }),

      new kernel::Field::Text (
                name          =>'dstcriticality',
                group         =>'dst',
                label         =>'Criticality',
                htmlwidth     =>'80',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my $criticality=(split("\n",$current->{description}))[0];
                    return lc $criticality;
                 }),

#      new kernel::Field::Boolean(
#                name          =>'civalid',
#                group         =>'dst',
#                label         =>'Valid',
#                translation   =>'tssm::lnk',
#                htmlwidth     =>'50',
#                dataobjattr   =>"decode(".
#                                "screlationm1.valid_ci,'t',1,'f',0,NULL)"),

      new kernel::Field::Boolean(
                name          =>'civalid',
                group         =>'dst',
                label         =>'Valid',
                translation   =>'tssm::lnk',
                htmlwidth     =>'50',
                dataobjattr   =>"'0'"),

      new kernel::Field::Text (
                name          =>'dststatus',
                group         =>'dst',
                label         =>'Status',
                htmlwidth     =>'100',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my $status = (split("\n",$current->{description}))[2];
                    return lc $status;
                 }),

      new kernel::Field::Textarea(
                name          =>'furtherciinfo',
                label         =>'further ci informations',
                depend        =>['dst','dstobj'],
                weblinkto     =>sub{
                    my $self   =shift;
                    my $d      =shift;
                    my $current=shift;
                    my $p=$self->getParent();

                    my $dstobj=$p->getField("dstobj")->RawValue($current);
                    my $dst=$p->getField("dst")->RawValue($current);

                    my $weblinkto=undef;
                    my $weblinkon=undef;
                    if ($dstobj eq "tsacinv::appl"){
                       $weblinkto="itil::appl";   
                       $weblinkon=['dst'=>'applid'];
                    }
                    if ($dstobj eq "tsacinv::system"){
                       $weblinkto="itil::system";   
                       $weblinkon=['dst'=>'systemid'];
                    }
                    return($weblinkto,$weblinkon);
                },
                onRawValue    =>sub{
                   my $self   =shift;
                   my $current=shift;
                   my $mode=shift;
                   my $p=$self->getParent();

                   my $d="unknown";

                   my $dstobj=$p->getField("dstobj")->RawValue($current);
                   my $dst=$p->getField("dst")->RawValue($current);

                   if ($dstobj eq "tsacinv::appl" && $dst ne ""){
                      my $o=getModuleObject($self->Config,"itil::appl");
                      $o->SetFilter({applid=>\$dst});
                      my ($rec)=$o->getOnlyFirst(qw(mandator opmode));
                      my @v;
                      foreach my $var (qw(mandator opmode)){
                         my $fld=$o->getField($var,$rec);
                         if (defined($fld)){
                            push(@v,$fld->Label($rec).": ".
                                    $fld->FormatedDetail($rec));
                         }
                      }
                      $d=join("\n",@v);
                   }
                   
                   if ($dstobj eq "tsacinv::system" && $dst ne ""){
                      my $o=getModuleObject($self->Config,"itil::system");
                      $o->SetFilter({systemid=>\$dst});
                      my ($rec)=$o->getOnlyFirst(qw(applications));
                      if (ref($rec->{applications}) eq "ARRAY"){
                         my %a;
                         foreach my $app (@{$rec->{applications}}){
                            $a{$app->{appl}}++;
                         }
                         my $appls=join(', ',sort(keys(%a)));
                         my $fld=$o->getField('applications',$rec);
                         my $label=$fld->Label($rec).': ';

                         $d="$label$appls";
                      }
                   }

                   return($d);
                }),
   );
   
   $self->setDefaultView(qw(linenumber dst dstname furtherciinfo));
   return($self);
}

sub isQualityCheckValid
{
   return(0);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=$self->SUPER::initSqlWhere() .
             "AND screlationm1.depend_filename='device'";
   return($where);
}


1;
