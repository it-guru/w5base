package tscape::qrule::compareApplMgr2;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares the "Application Manager Deputy" specified in 
the ICTO Object on CAPE with contacts in BusinessApplication.

=head3 IMPORTS

- name of cluster

=head3 HINTS

The "ApplicationManager deputy" is maintained in CAPE via the ICTO object as "Application Manager Deputy" and is only adjusted for the production environments in Darwin (valid for CI states: "available/project" and "installed/active").


Please contact the Support of CAPE ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549226710001

[de:]

Der ApplicationManager Vertreter ist federführend in CAPE über das ICTO Objekt als "Application Manager Deputy" gepflegt und wird nur für die Produktionsumgebungen in Darwin abgeglichen (gilt für CI-Status: "verfügbar/in Projektierung" und "installiert/aktiv")

Bitte kontaktieren Sie den Support von CAPE ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549226710001

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return(["TS::appl","AL_TCom::appl"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $checksession=shift;
   my $autocorrect=$checksession->{autocorrect};

   my $wfrequest={};
   my $forcedupd={};
   my @qmsg;
   my @dataissue;
   my $errorlevel=0;

   return(undef,undef) if (!($rec->{cistatusid}==3 || 
                             $rec->{cistatusid}==4));

   my %am_soll;
   my @notifymsg;

   if ($rec->{opmode} eq "prod" && $rec->{ictono} ne ""){
      my $par=getModuleObject($self->getParent->Config(),"tscape::archappl");
      return(undef,undef) if ($par->isSuspended());
      return(undef,undef) if (!$par->Ping());
      $dataobj->NotifyWriteAuthorizedContacts($rec,undef,{
      },{
         autosubject=>1,
         autotext=>1,
         mode=>'QualityCheck',
         datasource=>'CAPE'
      },sub {
         $par->ResetFilter();
         $par->SetFilter({archapplid=>\$rec->{ictono}});
         my ($parrec,$msg)=$par->getOnlyFirst(qw(ALL));
         return(undef,undef) if (!$par->Ping());
         if (defined($parrec)){
            my $user=getModuleObject($self->getParent->Config,"base::user");
            foreach my $r (@{$parrec->{roles}}){
               if (($r->{role} eq "Application Manager Deputy") &&
                   ($r->{email}=~m/\@/)  &&                # looks like a email 
                   !($r->{email}=~m/^pn-dup.*\@external.*$/) # no pn-dups
                   ){
                  my $amid=$user->GetW5BaseUserID($r->{email},"email",
                                                  {quiet=>1});
                  if ($amid ne ""){
                     $am_soll{$amid}++;
                  }
               }
            }
         }
         my @am_soll=sort(keys(%am_soll));
         my $lnkcontact;
         #if ($#am_soll!=-1){
            $lnkcontact=getModuleObject($self->getParent->Config,
                                                 "base::lnkcontact");
         #}
         my $am2exists=0;
         foreach my $crec (@{$rec->{contacts}}){
            my $roles=$crec->{roles};
            $roles=[$roles] if (ref($roles) ne "ARRAY");
            if (in_array($roles,"applmgr2")){
               $am2exists++;
            }
         }
         $autocorrect=1; 
         delete($rec->{contacts}); # ensure contacts are new loaded
         foreach my $amid (@am_soll){
            my $am2found=0;
            foreach my $crec (@{$rec->{contacts}}){
               my $roles=$crec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if ($crec->{target} eq "base::user" &&
                   $crec->{targetid} eq $amid){
                  $am2found=1;
                  if (!in_array($roles,"applmgr2")){
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('update roles of contact %s with '.
                                      'applmgr2',$self->Self),
                             $crec->{targetname}));
                        ####################################################
                        my @newroles=grep({defined($_)} @$roles,'applmgr2');
                        $lnkcontact->ValidatedUpdateRecord(
                                     {%$crec,
                                      refid=>$rec->{id},
                                      parentobj=>'itil::appl'},
                                     {roles=>\@newroles},
                                     {id=>\$crec->{id}});
                        ####################################################
                     }
                     else{
                        push(@dataissue,"ApplicationManager2: ".
                             $crec->{targetname});
                     }
                  }
               }
            }
            if (!$am2found){
               my $user=getModuleObject($self->getParent->Config,"base::user");
               $user->SetFilter({userid=>\$amid});
               my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
               if (defined($urec)){
                  if ($autocorrect){
                     push(@notifymsg,sprintf(
                          $self->T('adding applmgr2 '.
                                   'contact %s',$self->Self),
                          $urec->{fullname}));
                     #######################################################
                     $lnkcontact->ValidatedInsertRecord({
                        srcsys=>$self->Self,
                        target=>'base::user',
                        targetid=>$urec->{userid},
                        roles=>['applmgr2'],
                        refid=>$rec->{id},
                        parentobj=>'itil::appl'
                     });
                     #######################################################
                  }
                  else{
                     push(@dataissue,"applmgr2: ".
                          $urec->{fullname});
                  }
               }
            }
         }
         foreach my $crec (@{$rec->{contacts}}){
            my $roles=$crec->{roles};
            $roles=[$roles] if (ref($roles) ne "ARRAY");
            if ($crec->{target} ne "base::user" ||
                ($crec->{target} eq "base::user" &&
                 !in_array(\@am_soll,$crec->{targetid}))){
               if (in_array($roles,"applmgr2")){
                  my @newroles=grep(!/^applmgr2$/,@{$roles});
                  if ($#newroles==-1){
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('removing applmgr2 '.
                                      'contact %s',$self->Self),
                             $crec->{targetname}));
                        #################################################
                        $lnkcontact->ValidatedDeleteRecord($crec,{
                           id=>$crec->{id}
                        });

                        #################################################
                     }
                     else{
                        push(@dataissue,"no applmgr2 role for: ".
                             $crec->{targetname});
                     }
                  }
                  else{
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('removing applmgr2 role '.
                                      'from contact %s',$self->Self),
                             $crec->{targetname}));
                        #################################################
                        $lnkcontact->ValidatedUpdateRecord(
                                     {%$crec,
                                      refid=>$rec->{id},
                                      parentobj=>'itil::appl'},
                                     {roles=>\@newroles},
                                     {id=>\$crec->{id}});
                        #################################################
                     }
                     else{
                        push(@dataissue,"no applmgr2 role for: ".
                             $crec->{targetname});
                     }
                  }
               }
            }
         }


         if ($#notifymsg!=-1){
            @qmsg=@notifymsg;
            return($rec->{name},join("\n\n",map({"- ".$_} @notifymsg)));
         }
         return(undef,undef);
      });
   }
   else{
      return(undef,undef);
   }
   if ($#dataissue!=-1){
      $errorlevel=3;
      unshift(@dataissue,"different values stored in CAPE:");
      push(@qmsg,@dataissue);
   }

   return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
}



1;
