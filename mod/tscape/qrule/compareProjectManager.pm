package tscape::qrule::compareProjectManager;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

This quality rule compares the Project Manager specified in 
the ICTO Object on CAPE to the ApplicationManager entry in
a BusinessApplication.

=head3 IMPORTS

- name of cluster

=head3 HINTS

The Project Manager of an IT application is leading entered in CAPE via the ICT-Object and is only compared for the production environments in Darwin (valid for CI-States: "available/in project" and "installed/active")

Please contact the Support of CAPE ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549226710001

[de:]

Der Projektmanager IT-Applikation ist federf�hrend in CAPE �ber das ICTO Objekt gepflegt und wird nur f�r die Produktionsumgebungen in Darwin abgeglichen (gilt f�r CI-Status: "verf�gbar/in Projektierung" und "installiert/aktiv")

Bitte kontaktieren Sie den Support von CAPE ...

https://darwin.telekom.de/darwin/auth/base/user/ById/14549226710001

=cut
#######################################################################
#
#  W5Base Framework
#  Copyright (C) 2014  Hartmut Vogler (it@guru.de)
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

   return(0,undef) if (!($rec->{cistatusid}==3 || 
                         $rec->{cistatusid}==4));

   my %pm_soll;
   my @notifymsg;

   if ($rec->{opmode} eq "prod" && $rec->{ictono} ne ""){
      delete($rec->{contacts}); # ensure contacts are new loaded
      my $par=getModuleObject($self->getParent->Config(),"tscape::archappl");
      return(undef,undef) if ($par->isSuspended());
      return(undef,undef) if (!$par->Ping());
      $dataobj->NotifyWriteAuthorizedContacts($rec,undef,{
       #  emailcc=>['11634953080001'],
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
               if (($r->{role} eq "Project Manager IT-System" ||
                    $r->{role} eq "Project Manager IT-Application") &&
                   ($r->{email}=~m/\@/)  &&                # looks like a email
                   !($r->{email}=~m/^pn-dup.*\@external.*$/) # no pn-dups
                   ){
                  my $pmid=$user->GetW5BaseUserID($r->{email},"email",
                                                  {quiet=>1});
                  if ($pmid ne ""){
                     $pm_soll{$pmid}++;
                  }
               }
            }
         }
         my @pm_soll=sort(keys(%pm_soll));
         my $lnkcontact;
         #if ($#pm_soll!=-1){
            $lnkcontact=getModuleObject($self->getParent->Config,
                                                 "base::lnkcontact");
         #}
         my $pmexists=0;
         
         foreach my $crec (@{$rec->{contacts}}){
            my $roles=$crec->{roles};
            $roles=[$roles] if (ref($roles) ne "ARRAY");
            if (in_array($roles,"projectmanager")){
               $pmexists++;
            }
         }
         if (!$pmexists){    # Wenn in Darwin kein Projektmanager erfasst, dann
            $autocorrect=1;  # darf der PM direkt aus CAPE �bernommen werden.
         }                   # request: 14151779290001
 
         $autocorrect=1;     # Nach einer Meinungs�nderung von Peter soll nun
                             # mit dem Request 14447420560003 der 
                             # Projektmanager IMMER hart �bernommen werden.
 
         foreach my $pmid (@pm_soll){
            my $pmfound=0;
            foreach my $crec (@{$rec->{contacts}}){
               my $roles=$crec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if ($crec->{target} eq "base::user" &&
                   $crec->{targetid} eq $pmid){
                  $pmfound=1;
                  if (!in_array($roles,"projectmanager")){
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('update roles of contact %s with '.
                                      'projectmanager',$self->Self),
                             $crec->{targetname}));
                        ####################################################
                        my @newroles=grep({defined($_)} @$roles,
                                                        'projectmanager');
                        $lnkcontact->ValidatedUpdateRecord(
                                     {%$crec,
                                      refid=>$rec->{id},
                                      parentobj=>'itil::appl'},
                                     {roles=>\@newroles},
                                     {id=>\$crec->{id}});
                        ####################################################
                     }
                     else{
                        push(@dataissue,"projectmanager: ".
                             $crec->{targetname});
                     }
                  }
               }
            }
            if (!$pmfound){
               my $user=getModuleObject($self->getParent->Config,"base::user");
               $user->SetFilter({userid=>\$pmid});
               my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
               if (defined($urec)){
                  if ($autocorrect){
                     push(@notifymsg,sprintf(
                          $self->T('adding projectmanager '.
                                   'contact %s',$self->Self),
                          $urec->{fullname}));
                     #######################################################
                     $lnkcontact->ValidatedInsertRecord({
                        srcsys=>$self->Self,
                        target=>'base::user',
                        targetid=>$urec->{userid},
                        roles=>['projectmanager'],
                        refid=>$rec->{id},
                        parentobj=>'itil::appl'
                     });
                     #######################################################
                  }
                  else{
                     push(@dataissue,"projectmanager: ".
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
                 !in_array(\@pm_soll,$crec->{targetid}))){
               if (in_array($roles,"projectmanager")){
                  my @newroles=grep(!/^projectmanager$/,@{$roles});
                  if ($#newroles==-1){
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('removing projectmanager '.
                                      'contact %s',$self->Self),
                             $crec->{targetname}));
                        #################################################
                        $lnkcontact->ValidatedDeleteRecord($crec,{
                           id=>$crec->{id}
                        });

                        #################################################
                     }
                     else{
                        push(@dataissue,"no projectmanager role for: ".
                             $crec->{targetname});
                     }
                  }
                  else{
                     if ($autocorrect){
                        push(@notifymsg,sprintf(
                             $self->T('removing projectmanager role '.
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
                        push(@dataissue,"no projectmanager role for: ".
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
   if ($#dataissue!=-1){
      $errorlevel=3;
      unshift(@dataissue,"different values stored in CAPE:");
      push(@qmsg,@dataissue);
   }

   return($errorlevel,{qmsg=>\@qmsg,dataissue=>\@dataissue});
}



1;
