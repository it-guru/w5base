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
                name          =>'efforts_effectiv',
                label         =>'effectiv Effort',
                searchable    =>0,
                group         =>'efforts',
                unit          =>'min',
                depend        =>['name'],
                onRawValue    =>sub {
                   my $fieldself=shift;
                   my $current=shift;
                   my $id=$current->{name};

                   return($self->Context->{eff}->{$id});
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
   my ($year,$mon,$invoiceday,$Y1,$M1,$invoiceday1,$user,$grpid,$fineQuery)=@_;

   $self->{DataObj}->setDefaultView(qw(linenumber name fullname 
                                       efforts_treal
                                       efforts_effectiv
                                       efforts_employecount
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
#printf STDERR Dumper(\%wfheadid);
#printf STDERR Dumper($rec);
         my $conumber=$rec->{conumber};
         $conumber=[$conumber] if (ref($conumber) ne "ARRAY");
         if ($#{$conumber}!=-1){
            my $wfheadid=$rec->{id};
            my $effort=($wfheadid{$wfheadid})/($#{$conumber}+1);
            foreach my $lco (@$conumber){
               $self->Context->{treal}->{$lco}+=$effort;
               $self->Context->{eff}->{$lco}=$self->Context->{treal}->{$lco};
            }
         }
      }
   }
   if ($grpid ne ""){
      my $f=getModuleObject($self->getParent->Config,"finance::costteamfixup");
      my $date="$invoiceday1.$mon.$year";
      $f->SetFilter([{grpid=>\$grpid,
                     durationstart=>"<=$date",durationend=>[undef]},
                    {grpid=>\$grpid,
                     durationstart=>"<=$date",durationend=>">=$date"}]);
      foreach my $rec ($f->getHashList(qw(name fixupmode fixupminutes))){
         my $lco=$rec->{name};
         if ($rec->{fixupmode} eq "fix"){
            $self->Context->{eff}->{$lco}=$rec->{fixupminutes};
         }
         if ($rec->{fixupmode} eq "min"){
            if ($self->Context->{eff}->{$lco}<$rec->{fixupminutes}){
               $self->Context->{eff}->{$lco}=$rec->{fixupminutes};
            }
         }
         if ($rec->{fixupmode} eq "max"){
            if ($self->Context->{eff}->{$lco}>$rec->{fixupminutes}){
               $self->Context->{eff}->{$lco}=$rec->{fixupminutes};
            }
         }
         if ($rec->{fixupmode} eq "delta"){
            $self->Context->{eff}->{$lco}+=$rec->{fixupminutes};
         }
      }
   }

   if (keys(%{$self->Context->{treal}}) ||
       keys(%{$self->Context->{eff}})){
      $fineQuery->{name}=[keys(%{$self->Context->{treal}}),
                          keys(%{$self->Context->{eff}})];
   }
   else{
      $fineQuery->{name}=["NONE"];
   }




   return(1);
}  



1;
