package AL_TCom::ext::io;
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

sub Operation
{
   my $self=shift;
   my $in=shift;
   my $out=shift;

   print STDERR (Dumper($in));
   if ($in->{NAME} eq "AL_TCom::workflow::diary::HEAD"){
      return($self->AddDiary($in,$out));
   }
   return(undef);
}


sub AddDiary
{
   my $self=shift;
   my $in=shift;
   my $out=shift;
   my $app=$self->getParent;
   my ($msg,$oldrec);
  
   if ($ENV{REAL_REMOTE_USER} eq "anonymous" ||
       $ENV{REAL_REMOTE_USER} eq ""){
      $app->LastMsg(ERROR,"anonymous access rejected");
      return(99);
   }
   my $wf=$app->getPersistentModuleObject("base::workflow"); 
   if (!defined($wf)){
      $app->LastMsg(ERROR,"can't create access object");
      return(100);
   }
   my $keyfound=0;
   my $srcsys="io:".$ENV{REAL_REMOTE_USER};
   msg(INFO,"srcsys=$srcsys");
   if (defined($in->{wfheadid})){
      $wf->ResetFilter();
      $wf->SetFilter({id=>\$in->{wfheadid}});
      ($oldrec,$msg)=$wf->getOnlyFirst(qw(ALL));
      if (!defined($oldrec)){
         $app->LastMsg(ERROR,"invalid wfheadid specified");
         return(102);
      }
      if ($oldrec->{srcsys} ne $srcsys){
         $app->LastMsg(ERROR,"desired workflow not controlled by $srcsys");
         return(103);
      }
      $keyfound=1;
   }
   if (defined($in->{srcid})){
      $wf->ResetFilter();
      $wf->SetFilter({srcid=>\$in->{srcid},srcsys=>\$srcsys});
      ($oldrec,$msg)=$wf->getOnlyFirst(qw(ALL));
      $keyfound=1;
   }
   if (!$keyfound){
      $app->LastMsg(ERROR,"no key (srcid/wfheadid) specified");
      return(110);
   }
   my $newrec={};
   #
   # check field pool
   #
   my @transfer=qw(wfheadid srcid eventstart eventend name detaildescription
                   stateid affectedapplication
                   tcomcodrelevant tcomcodcause tcomcodcomments tcomworktime);
   foreach my $k (keys(%$in)){
      next if (uc($k) eq $k);
      if (defined($in->{$k})){
         if (grep(/^$k$/,@transfer)){
            $newrec->{$k}=$in->{$k};
         }
         else{
            $app->LastMsg(ERROR,"invalid operation field '$k'");
            return(121);
         }
      }
   }
   if ($newrec->{tcomcodcause} eq "sw.addeff.base"){   # this type isn't allowed
      $newrec->{tcomcodcause}="appl.base.base";        # over interface io
   }
    
   $newrec->{srcsys}=$srcsys;
   $newrec->{srcload}=$app->ExpandTimeExpression("now","en","GMT","GMT");
   #
   # timezone translation
   #
   foreach my $tvar (qw(eventstart eventend)){ # timezone and dist check
      if (defined($newrec->{$tvar})){
         $newrec->{$tvar}=$app->ExpandTimeExpression($newrec->{$tvar},"en");
         if (!defined($newrec->{$tvar})){
            return(200);
         }
      }
   }
   #
   # timerange check on eventend
   #
   if (defined($newrec->{eventend})){
      my $duration=CalcDateDuration($newrec->{eventend},$newrec->{srcload});
      print STDERR Dumper($duration);
      if (!defined($duration)){
         $app->LastMsg(ERROR,"can't calculate duration from now to eventend");
         return(201);
      }
      if ($duration->{totalminutes}<0){
         $app->LastMsg(ERROR,"eventend in the furture isn't allowed");
         return(201);
      }
      if ($duration->{totalminutes}>4320){  
         $app->LastMsg(ERROR,"eventend is older then 3 days");
         return(202);
      }
   }
   #
   # close handling
   #
   if (defined($newrec->{stateid}) && $newrec->{stateid}>16){
      if (!defined($oldrec)){
         $app->LastMsg(ERROR,"you can't close an unexisting workflow");
         return(204);
      }
      $newrec->{stateid}=17;
      $newrec->{step}="AL_TCom::workflow::diary::wfclose";
   }
   if (defined($oldrec)){
      if ($oldrec->{stateid}>20){  # temp removed
         $app->LastMsg(ERROR,"desired workflow already closed");
         return(111);
      }
      # process update
      msg(INFO,"update record oldrec=%s",Dumper($oldrec));
      delete($newrec->{affectedapplication});
      if ($wf->Store($oldrec,$newrec)){
         $out->{wfheadid}=$oldrec->{id};
         $out->{operation}="UPDATE";
         $out->{stateid}=effVal($oldrec,$newrec,"stateid");
      }
   }
   else{
      # process insert
      msg(INFO,"insert record");
      $newrec->{class}="AL_TCom::workflow::diary";
      $newrec->{step}="AL_TCom::workflow::diary::dataload";
      #Query->Param("Formated_affectedapplication"=>  # sollte nicht mehr
      #             $newrec->{affectedapplication});  # notwendig sein
      #delete($newrec->{affectedapplication});

      my $newid=$wf->Store($oldrec,$newrec);

      if ($newid && $newid ne ""){
         $wf->ResetFilter();
         $wf->SetFilter({id=>\$newid});
         ($oldrec,$msg)=$wf->getOnlyFirst(qw(ALL));
         $out->{wfheadid}=$newid;
         $out->{operation}="INSERT";
         $out->{stateid}=effVal($oldrec,$newrec,"stateid");
      }
   }
   return(0);
}



1;
