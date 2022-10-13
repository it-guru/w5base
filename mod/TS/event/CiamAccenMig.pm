package TS::event::CiamAccenMig;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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

my $trans;

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}





sub CiamAccenMig
{
   my $self=shift;

   my $ua=getModuleObject($self->Config,"base::useraccount");
   my $ue=getModuleObject($self->Config,"base::useremail");
   my $user=getModuleObject($self->Config,"base::user");
   my $wf=getModuleObject($self->Config,"base::workflow");

   my @wf;
   my %affectedUser=();
   my @trans=split(/\n/,$trans);
   my @mig=map({
     my @map;
        if (my ($new,$old)=$_=~m/^\s*([0-9]+)\s+([0-9]+)\s*$/){
           $map[0]=$old;
           $map[1]=$new;
        }
        elsif (my ($old)=$_=~m/^\s*([0-9]+)\s*$/){
           $map[0]=$old;
           $map[1]=undef;
        }
     \@map;
   } @trans);

   my $c=0;
   foreach my $map (@mig){
      msg(INFO,"migrate ".$map->[0]." to ".$map->[1]);
      if ($map->[0] ne "" && $map->[1] ne ""){
         #next if ($map->[0] ne "200121917");
         $c++;
         $user->ResetFilter();
         my $olddsid="tCID:".$map->[0];


         $user->SetFilter({dsid=>\$olddsid,cistatusid=>"<6"});
         my ($oldurec,$msg)=$user->getOnlyFirst(qw(ALL));
         next if (!defined($oldurec));

         $user->ResetFilter();
         my $newdsid="tCID:".$map->[1];
         $user->SetFilter({dsid=>\$newdsid,cistatusid=>"<6"});
         my ($newurec,$msg)=$user->getOnlyFirst(qw(ALL));

         my %emails;
         my %accounts;
         
         if (defined($newurec)){
            foreach my $emailrec (@{$newurec->{emails}}){
               $emails{$emailrec->{email}}++;
            }
            foreach my $accrec (@{$newurec->{accounts}}){
               $accounts{$accrec->{account}}++;
               $ua->ValidatedDeleteRecord($accrec);
            }
            $user->ResetFilter();
            $user->ValidatedUpdateRecord($newurec,{
               cistatusid=>'6',
               email=>$newurec->{email}.".".time().".new",
               dsid=>undef,
               posix=>undef
            },{
               userid=>\$newurec->{userid}
            });
            $user->ResetFilter();
            $user->SetFilter({userid=>$newurec->{userid}});
            ($newurec,$msg)=$user->getOnlyFirst(qw(ALL));
         }

         if (defined($oldurec)){
            #
            # update User Record to new DSID
            #
            foreach my $emailrec (@{$oldurec->{emails}}){
               $emails{$emailrec->{email}}++
            }
            my $oldurecuserid=$oldurec->{userid};
            $user->ResetFilter();
            $user->ValidatedUpdateRecord($oldurec,{
               dsid=>$newdsid,
               email=>$oldurec->{email}.".".time().".temp",
               posix=>undef,
               usertyp=>'user'
            },{
               userid=>\$oldurecuserid
            });

            #
            # Make QualityChecks to update all relations
            #
            $user->ResetFilter();
            $user->SetFilter({userid=>\$oldurecuserid});
            ($oldurec,$msg)=$user->getOnlyFirst(qw(ALL));
            if (defined($oldurec)){
               printf STDERR ("QCheck1:%s\n",$oldurec->{qcstate});
            }
            # do a second qCheck
            $user->ResetFilter();
            $user->SetFilter({userid=>\$oldurecuserid});
            ($oldurec,$msg)=$user->getOnlyFirst(qw(ALL));
            if (defined($oldurec)){
               printf STDERR ("QCheck2:%s\n",$oldurec->{qcstate});
            }
         }

         foreach my $emailrec (@{$oldurec->{emails}}){
            delete($emails{$emailrec->{email}});
         }
         foreach my $accrec (@{$oldurec->{accounts}}){
            delete($accounts{$accrec->{account}});
         }

         if (keys(%emails)){ # restore alternate E-Mails
            foreach my $email (keys(%emails)){
               if ($ue->ValidatedInsertRecord({
                       userid=>$oldurec->{userid},
                       cistatusid=>4,
                       email=>$email
                    })){
                  delete($emails{$email});
               }
            }
         }

         if (keys(%accounts)){ # restore alternate E-Mails
            foreach my $account (keys(%accounts)){
               if ($ua->ValidatedInsertRecord({
                       userid=>$oldurec->{userid},
                       account=>$account
                    })){
                  delete($accounts{$account});
               }
            }
         }



         if (keys(%emails) || keys(%accounts)){
            printf STDERR ("emails=%s\n",Dumper(\%emails));
            printf STDERR ("accounts=%s\n",Dumper(\%accounts));
            die("migration missing for ".$newurec->{fullname});
         }



         if (defined($newurec) && defined($oldurec)){
            $c++;
            printf STDERR ("Trans: %s\n".
                           "       -> %s\n\n",
                           $oldurec->{fullname},
                           $newurec->{fullname});
            if (my $id=$wf->ValidatedInsertRecord({
                  class    =>'base::workflow::ReplaceTool',
                  step     =>'base::workflow::ReplaceTool::approval',
                  name     =>'Accenture replace: '.$oldurec->{fullname},
                  stateid  =>2,
                  fwdtarget           => 'base::grp',
                  fwdtargetid         => '1',
                  replaceat           =>'ALL',
                  replaceoptype       => 'base::user',
                  replacesearchid       => $newurec->{userid},
                  replacereplacewithid  => $oldurec->{userid},
                  srcsys=>$self->Self
               })){
               printf STDERR ("Replace started at $id\n");
               push(@wf,$id);
            }
         }


      }
   }
   printf STDERR ("found %d mappings\n",$c);

   print STDERR ("UserID: ".join(" ",sort(keys(%affectedUser)))."\n\n");
   print STDERR ("Workflows: ".join(" ",@wf)."\n\n");


   return({exitcode=>0});
}



$trans=<<EOF;
CID   CID extern
286571   200122364
286668   200122356
288067   200122348
288461   200122299
288824   200122297
289078   200122291
290509   200122279
291139   200122273
301635   200106027
301825   200122142
301831   200122138
302213   200122112
302329   200122110
302349   200122108
302494   200122098
302791   200122076
302859   200122293
303071   200122068
303470   200122050
304325   200122036
306276   200122012
306993   200121992
307486   200121962
308995   200121929
309018   200121925
311551   200121917
316357   200121847
322230   200121823
325611   200121790
336683   200121744
342216   200121730
350615   200121724
575396   200121710
606882   200121686
616500   200121676
682084   200121617
1317739  200121511
3373545  200121315
10200971 200121417
74208520 200121353
118850173   200121321
EOF


1;
