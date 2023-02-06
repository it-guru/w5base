package TS::event::CleanDoublicateSWInstalls;
#  W5Base Framework
#  Copyright (C) 2023  Hartmut Vogler (it@guru.de)
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub CleanDoublicateSWInstalls
{
   my $self=shift;
   my $sw=getModuleObject($self->Config,"itil::lnksoftwaresystem");
   my $sys=getModuleObject($self->Config,"itil::system");
   my $op=$sw->Clone();

   open(F,">/tmp/CleanDoublicateSWInstalls.log");


   $sys->SetFilter({
      cistatusid=>"<6",
   #   name=>'tmv801'
   });
   $sys->SetCurrentView(qw(id name));

   my ($rec,$msg)=$sys->getFirst();
   if (defined($rec)){
      do{

         $sw->ResetFilter();
         $sw->SetFilter({systemid=>\$rec->{id}});
         my @l=$sw->getHashList(qw(cdate software version softwareid
                                   autodischint instpath id system systemid
                                   fullname));
         if ($#l!=-1){
            my %software;
            my @multi;
            foreach my $swirec (@l){
               my $softwareid=$swirec->{softwareid};
               my $checkkey=$softwareid;
               $checkkey.="-".$swirec->{instpath};
               $software{$checkkey}=[] if (!exists($software{$checkkey}));
               push(@{$software{$checkkey}},$swirec);
            }
            foreach my $k (keys(%software)){
               if ($#{$software{$k}}>0){
                  push(@multi,$software{$k});
               }
            }
            if ($#multi!=-1){
               my @stack=@multi;
               while(my $swset=shift(@stack)){
                  my $auto=0;
                  my $user=0;
                  foreach my $swrec (@$swset){
                     $auto++ if ($swrec->{autodischint} ne "");
                     $user++ if ($swrec->{autodischint} eq "");
                  }
                  @$swset=reverse(@$swset);
                  if ($auto>0){
                     for(my $c=1;$c<=$#{$swset};$c++){
                        $op->ResetFilter();
                        $op->ValidatedDeleteRecord($swset->[$c]);
                        printf F ("%-20s : %s\n",$swset->[$c]->{system},
                                                 $swset->[$c]->{id});
                        #printf STDERR ("delete %s\n",$swset->[$c]->{id});
                     }
                  }
               }

               printf STDERR ("System: %s\n",$rec->{name});
              # printf STDERR ("%s\n",Dumper(\@multi));
            }
         }

         ($rec,$msg)=$sys->getNext();
      } until(!defined($rec));
   }
   close(F);






   #print STDERR Dumper($swmap);

   #$self->UpdateBaseData();
   return({exitcode=>0});
}

1;
