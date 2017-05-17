package itil::event::servicesupportCleanup;
#  W5Base Framework
#  Copyright (C) 2017  Markus Zeis (w5base@zeis.email)
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


sub servicesupportCleanup
{
   my $self=shift;
   my %param=@_;

   my %objs2chk;
   my $refobj=getModuleObject($self->Config,'base::reflexion_fields');
   $refobj->SetFilter({referral=>'*::servicesupport::id'});

   foreach my $rfld ($refobj->getHashList('ALL')) {
      my ($servicesupportid_fld)=$rfld->{referral}=~m/::(\w+)\s*->/;
      $objs2chk{$rfld->{modname}}{$servicesupportid_fld}++;
   }

   # calculate %objs2chk
   # key: Dataobject which uses servicesupportid field
   # val: Fieldname(s)
   foreach my $o (keys(%objs2chk)) {
      my $dataobj=getModuleObject($self->Config,$o);
      my $parent=$dataobj->SelfAsParentObject();

      if ($parent ne $dataobj->Self() &&
          exists($objs2chk{$parent})) {
         foreach my $fldname (keys(%{$objs2chk{$o}})) {
            if (exists($objs2chk{$parent}{$fldname})) {
               delete($objs2chk{$o}{$fldname});
            }
         }
      }

      my @servicesupportid_flds=keys(%{$objs2chk{$o}});
      delete($objs2chk{$o}) if ($#servicesupportid_flds==-1);
   }

   # current active servicesupport classes
   my $servsupobj=getModuleObject($self->Config,'itil::servicesupport');
   $servsupobj->SetFilter({cistatusid=>'<6'});
   my @servsupclasses=$servsupobj->getHashList(qw(id name cistatusid
                                                  databossid databoss2id
                                                  urlofcurrentrec));

   SERVICESUPPORTCLASS:
   foreach my $ssrec (@servsupclasses) {
      my $dataobj;

      foreach my $o (keys(%objs2chk)) {
         $dataobj=getModuleObject($self->Config,$o);

         my @flt=map({{$_=>$ssrec->{id}}} keys(%{$objs2chk{$o}}));

         if (defined($dataobj->getField('cistatusid'))) {
            foreach my $f (@flt) {
               $f->{cistatusid}='<6';
            }
         }

         $dataobj->SetFilter(\@flt);

         if ($dataobj->CountRecords()>0) {
            next SERVICESUPPORTCLASS;
         }
      }

      if (defined($ssrec->{id}) && $ssrec->{id} ne '') {
         my $bk=$servsupobj->ValidatedUpdateRecord($ssrec,
                                                   {cistatusid=>6},
                                                   {id=>\$ssrec->{id}});
         $self->Notify($ssrec) if ($bk);
      }
   }
}


sub Notify
{
   my $self=shift;
   my $rec=shift;

   my $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
   my %notifyparam=(adminbcc=>1);
   my $emailto;

   if (defined($rec->{databossid})) {
      $emailto=$rec->{databossid};
   }
   if (defined($rec->{databoss2id}) &&
       $rec->{databoss2id} != $rec->{databossid}) {
      if (defined($emailto)) {
         $notifyparam{emailcc}=$rec->{databoss2id};
      }
      else {
         $emailto=$rec->{databossid};
      }
   }

   if (defined($emailto)) {
      $notifyparam{emailto}=$emailto;
      my $uobj=getModuleObject($self->Config,'base::user');
      $uobj->SetFilter({userid=>$emailto,cistatusid=>4});
      my ($u,$msg)=$uobj->getOnlyFirst(qw(lastlang));
        
      if (defined($u->{lastlang})) {
         $ENV{HTTP_FORCE_LANGUAGE}=$u->{lastlang};
      }
   }

   my $subject=$self->T("Automatic data update",'kernel::QRule');
   $subject.=" : ".$rec->{name};

   my $text=$self->T("Dear databoss",'kernel::QRule').",\n\n";
   $text.=$self->T("an update has been made on a record ".
                   "for which you are responsible - based on",
                   'kernel::QRule');
   $text.=" ".$self->T("automatic cleanup").".\n\n";
   $text.=$self->T("The Service and Support Class");
   $text.=" '".$rec->{name}."' ";
   $text.=$self->T("is currently not used and ".
                   "has been deactivated therefore").".\n\n";
   $text.=$rec->{urlofcurrentrec};

   my $wfa=getModuleObject($self->Config,"base::workflowaction");
   $wfa->Notify("INFO",$subject,$text,%notifyparam);

   if (defined($lastlang)) {
      $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
   }
   else {
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }

   return(1);
}



1;
