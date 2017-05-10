package kernel::Field::Mandator;
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
use kernel::Field::Select;
@ISA    = qw(kernel::Field::Select);


sub new
{
   my $type=shift;
   my $self={@_};
   if (exists($self->{vjoinon}) && ref($self->{vjoinon}) ne "ARRAY"){
      $self->{vjoinon}=[$self->{vjoinon}=>'grpid'];
   }
   $self->{name}='mandator'             if (!defined($self->{name}));
   $self->{label}='Mandator'            if (!defined($self->{label}));
   $self->{htmleditwidth}='250px'       if (!defined($self->{htmleditwidth}));
   $self->{htmlwidth}='80px'                if (!defined($self->{htmlwidth}));
   $self->{vjointo}='base::mandator'        if (!defined($self->{vjointo}));
   $self->{vjoinon}=['mandatorid'=>'grpid'] if (!defined($self->{vjoinon}));
   $self->{vjoindisp}="name"                if (!defined($self->{vjoindisp}));
   my $o=bless($type->SUPER::new(%$self),$type);
   return($o);
}

sub getPostibleValues
{
   my $self=shift;
   my $current=shift;
   my $newrec=shift;
   my $mode=shift;

   if ($mode eq "edit"){
      my $app=$self->getParent();
      my $MandatorCache=$app->Cache->{Mandator}->{Cache};
      return() if (!defined($MandatorCache));
      my @mandators=$app->getMandatorsOf($ENV{REMOTE_USER},"write","direct");
      my $cur=$current->{$self->{vjoinon}->[0]};
      if (defined($cur) && $cur!=0){
         push(@mandators,$cur);
      }
      my @res=();
      if ($self->getParent->IsMemberOf("admin")){
         foreach my $grpid (keys(%{$MandatorCache->{grpid}})){
            if (!in_array(\@mandators,$grpid)){
               push(@mandators,$grpid);
            }
         }
      }

      #######################################################################
      # sort algorithmus to order the nearest (organisational) mandators 
      # on top of the  list
      my %groups=$self->getParent->getGroupsOf($ENV{REMOTE_USER},[orgRoles()],
                               'up');
      my %dgroups=$self->getParent->getGroupsOf($ENV{REMOTE_USER},
                           [qw(RCFManager RCFManager2)], 'direct');

      @mandators=sort({ 
          my $dista=999;
          my $distb=999;
          if (exists($groups{$a}) &&
              exists($groups{$a}->{distance})){
             $dista=$groups{$a}->{distance};
          }
          if (exists($groups{$b}) &&
              exists($groups{$b}->{distance})){
             $distb=$groups{$b}->{distance};
          }
          $dista<=>$distb;
      } @mandators);
      #######################################################################
      foreach my $mandator (@mandators){
         if (defined($MandatorCache->{grpid}->{$mandator})){
            if (($MandatorCache->{grpid}->{$mandator}->{cistatusid}==4 ||
                 ($self->{allowall}))){
               push(@res,$mandator,
                    $MandatorCache->{grpid}->{$mandator}->{name});
            }
            else{
               if ($MandatorCache->{grpid}->{$mandator}->{cistatusid}==3 &&
                   (exists($dgroups{$mandator})||
                    $self->getParent->IsMemberOf("admin"))){
                  push(@res,$mandator,
                       $MandatorCache->{grpid}->{$mandator}->{name});
               }
            }
         }
      }
      if ($self->{allowany}){
         push(@res,0,"[any]");
      }
      return(@res);
   }
   my @res=$self->SUPER::getPostibleValues($current,$newrec,$mode);
   if ($self->{allowany}){
      push(@res,0,"[any]");
   }
   return(@res);
}

#sub Unformat
#{
#   my $self=shift;
#   my $formated=shift;
#   my $rec=shift;
#   my $mandatoridname=$self->{vjoinon}->[0];
#   my $r={};
#   if (!ref($formated) && $formated ne "" && 
#       !defined($rec->{$mandatoridname})){
#   }
#
#   return({$self->Name()=>$formated});
#}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record

   if (!$self->readonly($oldrec)){
      my $mandatoridname=$self->{vjoinon}->[0];
      my $requestmandator=$newrec->{$mandatoridname};
      my $app=$self->getParent();
      if ($app->isDataInputFromUserFrontend()){
         my $userid=$app->getCurrentUserId();
         if ($self->{allowany} &&
             $newrec->{$mandatoridname}==0){
            return($self->SUPER::Validate($oldrec,$newrec,$currentstate));
         }
         # Calc new mandator
         if (!exists($newrec->{$mandatoridname}) &&  # Allow write on mandator
              exists($newrec->{$self->Name()})){     # by name on W5API call
            if (my $nrec=$self->SUPER::Validate($oldrec,$newrec,$currentstate)){
               foreach my $k (keys(%$nrec)){
                  $newrec->{$k}=$nrec->{$k};
               }
            }
            else{
               return(undef);
            }
         }
         my @mandators=$app->getMandatorsOf($ENV{REMOTE_USER},"write");
         if (!defined($oldrec)){
            if (!defined($newrec->{$mandatoridname}) ||
                ($newrec->{$mandatoridname}==0 && !$self->{allowany})){
               $app->LastMsg(ERROR,"no valid mandator defined");
               return(undef);
            }
         }
         if (!$self->getParent->IsMemberOf("admin")){
            if (defined($newrec->{$mandatoridname}) &&
                !grep(/^$newrec->{$mandatoridname}$/,@mandators) &&
                (!defined($oldrec) ||
                 effVal($oldrec,$newrec,$mandatoridname) ne 
                 $newrec->{$mandatoridname})){
               $app->LastMsg(ERROR,"you are not authorized to write in the ".
                                    "requested mandator");
               return(undef);
            }
         }
         else{ # check mandatorid
            my $chkid=effVal($oldrec,$newrec,$mandatoridname);
            my $m=getModuleObject($self->getParent->Config,"base::mandator");
            if ($self->{allowall}){
               $m->SetFilter({grpid=>\$chkid});
            }
            else{
               $m->SetFilter({grpid=>\$chkid,
                              cistatusid=>"<6"});
            }
            my ($mrec,$msg)=$m->getOnlyFirst(qw(grpid));
            if (!defined($mrec)){
               $app->LastMsg(ERROR,"invalid mandatorid");
               return(undef);
            }
         }
      }
   }

   return($self->SUPER::Validate($oldrec,$newrec,$currentstate));
}





1;
