package tssc::event::PassReset;
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
use Data::Dumper;
use kernel;
use kernel::Event;
@ISA=qw(kernel::Event kernel::Event::ServiceCenterSync);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{SCTagPrefix}="W5Base:SC:PassReset";
   $self->{DBname}="tsscfrontend";

   return($self);
}

sub Init
{
   my $self=shift;

   eval("use kernel::Event::ServiceCenterSync;");
   if ($@ eq ""){
      $self->RegisterEvent("tsscResyncPassReset","ResyncPassReset");
   }
   else{
      msg(DEBUG,"skip tssc::event::PassReset due initial errors");
      printf STDERR ("msg=%s\n",$@);
   }
}


sub ResyncLoop
{
   my $self=shift;

   if (my $msg=$self->ServiceCenterLogin($self->{DBname})){
      msg(ERROR,$msg);
      return({exitcode=>1});
   }
   sleep(1);
   if (my $msg=$self->ServiceCenterLogout($self->{DBname})){
      msg(ERROR,$msg);
      return({exitcode=>1});
   }
   return({exitcode=>0});
}

sub ResyncPassReset
{
   my $self=shift;
   my $param=shift;

   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfact=getModuleObject($self->Config,"base::workflowaction");
   my $user=getModuleObject($self->Config,"base::user");

   if (my $msg=$self->ServiceCenterLogin($self->{DBname})){
      msg(ERROR,$msg);
      return({exitcode=>1});
   }
   #
   # Check for Create Incident
   #
   $param=~s/^0*//;
   if ($param ne "" && $param>0){
      $wf->SetFilter(id=>\$param);
      my ($wfrec,$msg)=$wf->getOnlyFirst(qw(ALL));
      if (defined($wfrec)){
         $user->SetFilter(userid=>\$wfrec->{openuser});
         my ($urec,$msg)=$user->getOnlyFirst(qw(ALL));
         $urec={} if (!defined($urec));
         my $refn=$self->{SCTagPrefix}.":".$wfrec->{id};
         my $name="Password Reset for user $wfrec->{passresetposix} ($refn)";
         my $action="Please reset the password of the user ".
                    "'$wfrec->{passresetposix}' in the Application ".
                    "'$wfrec->{passresetsys}'.\n\n".
                    "This request has been initiated by ".
                    "'$wfrec->{openusername}' at $wfrec->{createdate}.\n".
                    "This Ticket is created automaticly. If you have problems ".
                    "with the fill out of this form, please contact the ".
                    "W5Base Administrator/Developer.";
         my %I=('brief.description'     => $name,
                'problem.shortname'     => 'TSI-D-xxxxxxx',
                'assignment'            => 'CSS.TCOM.xxxxxxx.xx.xx',
                'category'              => 'ACCESS',
                'subcategory1'          => 'OTHER',
                'cause.code'            => 'SC.PWD.xxx',
                'priority.code'         => '3',
                'business.impact'       => 'Low',
                'urgency'               => 'Medium',
                'sla.relevant'          => '0',
                'reported.lastname'     => 'W5Base',
                'reported.firstname'    => 'Vogler Hartmut W5Base Dev.',
                'reported.mail.address' => 'hartmut.vogler@xxxxxxxxxxxxx',
                'reported.phone'        => '+49 951 0000-0000',
                'contact.lastname'      => $urec->{surname},
                'contact.firstname'     => $urec->{givenname},
                'contact.mail.address'  => $urec->{email},
                'contact.phone'         => $wfrec->{passresetcontactphone},
                'reported.by'           => 'W5BASE',
                'referral.no'           => $refn,
                'action'                => $action);
         if (my $msg=$self->RefreshIncident($self->{DBname},$wf,
                                            $wfact,$wfrec,\%I)){
            msg(ERROR,"Incident Create: $msg");
            return({exitcode=>100});
         }
         $self->SyncActions($self->{DBname},$wf,$wfact,$wfrec,\%I);
         msg(INFO,"Incident Number=%s",$I{number});
         if ($wfrec->{stateid}==16){
            if (my $msg=$self->CloseIncident($self->{DBname},$wf,
                                             $wfact,$wfrec,\%I)){
               msg(ERROR,"Incident Close: $msg");
               return({exitcode=>100});
            }
         }
      }
   }
   return({exitcode=>0});
}


1;
