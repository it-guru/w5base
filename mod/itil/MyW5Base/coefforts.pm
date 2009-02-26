package itil::MyW5Base::coefforts;
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
use kernel::MyW5Base;
use itil::MyW5Base::efforts;
use kernel::date;
@ISA=qw(itil::MyW5Base::efforts);

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
   $self->{DataObj}=getModuleObject($self->getParent->Config,"itil::costcenter");
   return(0) if (!defined($self->{DataObj}));
   $self->{DataObj}->AddFields(
      new kernel::Field::Number(
                name          =>'efforts_treal',
                label         =>'Effort real',
                searchable    =>0,
                group         =>'efforts',
                unit          =>'min',
                depend        =>['name'],
                onSummaryValue=>sub {
                   return(112233);
                },
                onRawValue    =>sub {
                   my $fieldself=shift;
                   my $current=shift;
                   my $id=$current->{name};

                   return($self->Context->{treal}->{$id});
                }),

      new kernel::Field::Number(
                name          =>'efforts_employecount',
                label         =>'Effort employecount',
                searchable    =>0,
                group         =>'efforts',
                depend        =>['id'],
                onRawValue    =>sub {
                   my $fieldself=shift;
                   my $current=shift;
                   return($self->{usercount});
                })
   );
   $self->{DataObj}->AddGroup("efforts",translation=>'itil::MyW5Base::efforts');

   return(1);
}


sub addSpecialSearchMask
{
   my $self=shift;
   return("");
}

sub calculateEfforts
{
   my $self=shift;
   my ($year,$mon,$invoiceday,$Y1,$M1,$invoiceday1,$user,$fineQuery)=@_;

   $self->{DataObj}->setDefaultView(qw(linenumber name fullname 
                                       efforts_treal
                                       efforts_employecount
                                       efforts_tprojection
                                       ));

   my $wfact=getModuleObject($self->getParent->Config,"base::workflowaction");
   $wfact->SetFilter({creatorid=>[keys(%{$user})],
                      cdate=>">$year-$mon-${invoiceday} AND ".
                             "<=$Y1-$M1-${invoiceday1}"
                     }
                    );
   my %wfheadid=();
   foreach my $rec ($wfact->getHashList(qw(wfheadid effort creator))){
      if (defined($rec->{effort}) && $rec->{effort}!=0){
         $wfheadid{$rec->{wfheadid}}+=$rec->{effort};
      }
   }
   return(undef) if ($wfact->LastMsg());
   #print STDERR Dumper(\%wfheadid);

   #
   # find affectedapplicationid
   #
   if (keys(%wfheadid)){
      my $wf=getModuleObject($self->getParent->Config,"base::workflow");
      $wf->SetFilter({id=>[keys(%wfheadid)]});
      foreach my $rec ($wf->getHashList(qw(id wffields.conumber))){
printf STDERR Dumper(\%wfheadid);
printf STDERR Dumper($rec);
         my $conumber=$rec->{conumber};
         $conumber=[$conumber] if (ref($conumber) ne "ARRAY");
         if ($#{$conumber}!=-1){
            my $wfheadid=$rec->{id};
            my $effort=($wfheadid{$wfheadid})/($#{$conumber}+1);
printf STDERR ("effort=$effort\n");
            foreach my $lco (@$conumber){
               $self->Context->{treal}->{$lco}+=$effort;
            }
         }
      }
      $fineQuery->{name}=[keys(%{$self->Context->{treal}})];
   }
   else{
      $fineQuery->{name}=["NONE"];
   }
   return(1);
}  



1;
