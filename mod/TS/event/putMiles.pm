package TS::event::putMiles;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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

sub Init
{
   my $self=shift;


   $self->RegisterEvent("putMiles","putMiles");
   return(1);
}

sub putMiles
{
   my $self=shift;
   my %param=@_;

   my $user=getModuleObject($self->Config,"base::user");
   my $act=getModuleObject($self->Config,"base::workflowaction");
   my $wf=getModuleObject($self->Config,"base::workflow");
   $act->SetFilter({mdate=>">now-14d",effort=>'!""'});
   $act->SetCurrentView(qw(id cdate mdate effort comments 
                           wfheadid creatorid));

   if (open(F,">/tmp/last.putMilesPlus.xml")){
      print F hash2xml({},{header=>1});
      print F "<root>";
   }

   my %ucache=();


   my ($rec,$msg)=$act->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         #printf STDERR ("d=%s\n",Dumper($rec));
         $wf->ResetFilter();
         $wf->SetFilter({id=>\$rec->{wfheadid}});
         my ($WfRec,$msg)=$wf->getOnlyFirst(qw(name wffields.conumber)); 
         if (defined($WfRec)){ 
            my $targetcostcenter=$WfRec->{conumber};
            $targetcostcenter="???" if ($targetcostcenter eq "");
            my %put=(entryid=>$rec->{id},
                     shortdescription=>$WfRec->{name},
                     description=>$rec->{comments},
                     target_costcenter=>$targetcostcenter,
                     office_w5baseuserid=>$rec->{creatorid},
                     effort=>$rec->{effort},
                     createdate=>$rec->{cdate},
                     modifydate=>$rec->{mdate});
            if (!exists($ucache{$put{office_w5baseuserid}})){
               $user->ResetFilter();
               $user->SetFilter({userid=>\$put{office_w5baseuserid}});
               my ($urec,$msg)=$user->getOnlyFirst(qw(posix 
                                                      office_persnum 
                                                      office_costcenter 
                                                      office_accarea));
               if (defined($urec)){
                  my %u=(office_wiwuserid=>$urec->{posix},
                         office_persnum=>$urec->{office_persnum},
                         office_costcenter=>$urec->{office_costcenter},
                         office_accarea=>$urec->{office_accarea});
                  $ucache{$put{office_w5baseuserid}}=\%u;
               }
            }
            foreach my $k (keys(%{$ucache{$put{office_w5baseuserid}}})){
               $put{$k}=$ucache{$put{office_w5baseuserid}}->{$k};
            }
            if ($put{office_wiwuserid} eq "hvogler"){
               print F hash2xml({entry=>\%put},{header=>0});
            }
           
   #         printf STDERR ("put=%s\n",Dumper(\%put));
         }
         ($rec,$msg)=$act->getNext();
      } until(!defined($rec));
   }

   print F "</root>";
   close(F);

   return({exitcode=>0,msg=>'transfer ok'});
}





1;
