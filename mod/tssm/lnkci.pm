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
use tssm::lib::io;

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
                htmlwidth     =>'200px',
                dataobjattr   =>SELpref.'screlationm1.depend'),

      new kernel::Field::Text (
                name          =>'dstcriticality',
                group         =>'dst',
                label         =>'Criticality',
                htmlwidth     =>'80',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my @desc=split("\n",$current->{description});
                    my $criticality=$desc[3];
                    if (uc($criticality) eq "N/A"){
                       $criticality=undef;
                    }
                    return(lc($criticality));
                 }),

      new kernel::Field::Text (
                name          =>'dstmodel',
                group         =>'dst',
                label         =>'Destination-Model',
                htmlwidth     =>'80',
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my @desc=split("\n",$current->{description});
                    my $dstmodel=$desc[4];
                    if ($dstmodel eq "" || uc($dstmodel) eq "N/A"){
                       $dstmodel="unknown";
                    }
                    return(lc($dstmodel));
                 }),

      new kernel::Field::Text (
                name          =>'dststatus',
                group         =>'dst',
                label         =>'Status',
                htmlwidth     =>'100',
                nowrap        =>1,
                depend        =>['description'],
                onRawValue    =>sub {
                    my $self   =shift;
                    my $current=shift;
                    my @desc=split("\n",$current->{description});
                    my $status=$desc[2];
                    if ($status eq "" || uc($status) eq "N/A"){
                       $status="";
                    }
                    return(lc($status));
                 }),

      new kernel::Field::Boolean(
                name          =>'civalid',
                group         =>'dst',
                label         =>'Valid',
                translation   =>'tssm::lnk',
                nowrap        =>1,
                dataobjattr   =>
                  "decode(".
                     "substr(dbms_lob.substr(dh_desc),".
                            "instr(dbms_lob.substr(dh_desc),'\n',1,1)+1,".
                            "4),".
                     "'true',1,0)"
                ),

      new kernel::Field::Textarea(
                name          =>'furtherciinfo',
                label         =>'further ci informations',
                depend        =>['dstobj','dstid'],
                weblinkto     =>sub{
                    my $self   =shift;
                    my $d      =shift;
                    my $current=shift;
                    my $p=$self->getParent();

                    my $dstobj=$p->getField("dstobj")->RawValue($current);
                    my $dst=$p->getField("dstid")->RawValue($current);

                    my $weblinkto=undef;
                    my $weblinkon=undef;
                    if ($dstobj eq "tsacinv::appl"){
                       $weblinkto="itil::appl";   
                       $weblinkon=['dstid'=>'applid'];
                    }
                    if ($dstobj eq "tsacinv::system"){
                       $weblinkto="itil::system";   
                       $weblinkon=['dstid'=>'systemid'];
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
                   my $dst=$p->getField("dstid")->RawValue($current);

                   if ($dstobj eq "tsacinv::appl" && $dst ne ""){
                      my $o=getModuleObject($self->Config,"itil::appl");
                      $o->SetFilter({applid=>\$dst});
                      my ($rec)=$o->getOnlyFirst(qw(mandator opmode));
                      my @v;
                      if (defined($rec)){
                         foreach my $var (qw(mandator opmode)){
                            my $fld=$o->getField($var,$rec);
                            if (defined($fld)){
                               push(@v,$fld->Label($rec).": ".
                                       $fld->FormatedDetail($rec));
                            }
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
   
   $self->setDefaultView(qw(linenumber descname dstmodel dstcriticality
                            civalid dststatus furtherciinfo));
   return($self);
}

sub isQualityCheckValid
{
   return(0);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=$self->SUPER::initSqlWhere();
   $where="($where) AND " if ($where ne "");
   $where.="depend_filename='device'";
   return($where);
}


1;
