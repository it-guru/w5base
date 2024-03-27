package itil::ext::lnkcontact;
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
use kernel::Universal;
@ISA=qw(kernel::Universal);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub getPosibleRoles
{
   my $self=shift;
   my $field=shift;
   my $parentobj=shift;
   my $current=shift;
   my $newrec=shift;


   if ($parentobj=~m/^.+::appl$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::appl$/)){
      return(
         "applowner"       =>$self->getParent->T("Application owner",
                                             $self->Self),
         "applmgr2"        =>$self->getParent->T("Application manager deputy",
                                                 $self->Self),
         "developercoord"  =>$self->getParent->T("Development coordination",
                                             $self->Self),
         "developerboss"   =>$self->getParent->T("Chief Developer",
                                             $self->Self),
         "developer"       =>$self->getParent->T("Developer",
                                                 $self->Self),
         "businessemployee"=>$self->getParent->T("Business Employee",
                                             $self->Self),
         "customer"        =>$self->getParent->T("Customer Contact",
                                                 $self->Self),
         "ctm"             =>$self->getParent->T("Customer Technical Manager",
                                                 $self->Self),
         "techcontact"     =>$self->getParent->T("Technical Contact",
                                                 $self->Self),
         "techapprove"     =>$self->getParent->T("Technical Approver",
                                                 $self->Self),
         "techpriv"        =>$self->getParent->T("Technically privileged",
                                                 $self->Self),
         "vendor"          =>$self->getParent->T("Vendor Contact",
                                                 $self->Self),
         "infocontact"     =>$self->getParent->T("Information contact",
                                                 $self->Self),
         "supervisor"      =>$self->getParent->T("Supervisor",
                                                 $self->Self),
         "projectmanager"  =>$self->getParent->T("Projectmanager",
                                                 $self->Self),
         "pmdev"           =>$self->getParent->T("Projectmanager Development",
                                                 $self->Self),
         "sdesign"         =>$self->getParent->T("Solution Designer",
                                                 $self->Self),
         "support"         =>$self->getParent->T("1st level Support",
                                                 $self->Self),
         "support2d"       =>$self->getParent->T("2nd level Support",
                                                 $self->Self),
         "support3d"       =>$self->getParent->T("3rd level Support",
                                                 $self->Self),
         "orderin1"        =>$self->getParent->T("Order acceptation",
                                                 $self->Self),
         "orderin2"        =>$self->getParent->T("Order acceptation deputy",
                                                 $self->Self),
         "orderingauth"    =>$self->getParent->T("ordering authorized",
                                                 $self->Self),
         "read"            =>$self->getParent->T("read application",
                                                 $self->Self),
         "privread"        =>$self->getParent->T("privacy read",
                                                 $self->Self),
         "write"           =>$self->getParent->T("write application",
                                                 $self->Self),
        );
   }
   if ($parentobj=~m/^.+::itclust$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::itclust$/)){
      return("read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "privread"        =>$self->getParent->T("privacy read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::itcloud$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::itcloud$/)){
      return("read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::ipnet$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::ipnet$/)){
      return(
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::supcontract$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::itclust$/)){
      return("read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::swinstance$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::swinstance$/)){
      return(
             "read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "privread"        =>$self->getParent->T("privacy read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::software$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::software$/)){
      return(
             "pmanager"        =>$self->getParent->T("Productmanager",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::itfarm$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::itfarm$/)){
      return(
             "read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::liccontract$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::liccontract$/)){
      return(
             "read"            =>$self->getParent->T("read contract",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write contract",
                                                     $self->Self),
             "privread"        =>$self->getParent->T("privacy read",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::network$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::network$/)){
      return(
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
             "techcontact"     =>$self->getParent->T("Technical Contact",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::netintercon$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::netintercon$/)){
      return(
             "write"           =>$self->getParent->T("write",
                                                     $self->Self));
   }
   if ($parentobj=~m/^.+::businessservice$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->SelfAsParentObject() 
        eq "itil::businessservice")){
      return("read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::system$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::system$/)){
      return("read"            =>$self->getParent->T("read system",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write system",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::softwareset$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::softwareset$/)){
      return("read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::asset$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::asset$/)){
      return("read"            =>$self->getParent->T("read system",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write system",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^.+::mgmtitemgroup$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^.+::mgmtitemgroup$/)){
      return("read"            =>$self->getParent->T("read",
                                                     $self->Self),
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   if ($parentobj=~m/^itil::servicesupport$/ ||
       (defined($self->getParent) &&
        defined($self->getParent->getParent) &&
       $self->getParent->getParent->Self()=~m/^itil::servicesupport$/)){
      return(
             "write"           =>$self->getParent->T("write",
                                                     $self->Self),
            );
   }
   return();
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;
   my $parentobj=shift;
   my $refid=shift;
   my $app=$self->getParent();

   if (defined($newrec->{roles}) && $parentobj=~m/::appl$/){
      my $roles=$newrec->{roles};
      $roles=[$roles] if (ref($roles) ne "ARRAY");
      if (grep(/^developerboss$/,@$roles) ||
          grep(/^developercoord$/,@$roles) ||
          grep(/^orderin1$/,@$roles)){
         if ($app->isRoleMultiUsed({
               developerboss =>$self->getParent->T("Chief Developer"),
               orderin1      =>$self->getParent->T("Order acceptation"),
               developercoord=>$self->getParent->T("Development coordination")
               },$roles,$oldrec,$newrec,$parentobj,$refid)){
            return(0);
         }
      }
      if (in_array("techapprove",$roles)){
         if (effVal($oldrec,$newrec,"target") eq "base::grp"){
            $app->LastMsg(ERROR,
                "role Technical Approver cannot be assigned to groups");
            return(0);
         }
      }
   }

   return(1);
}




1;
