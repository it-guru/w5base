package itil::event::NotifyMgmtItemGroupOnOff;
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
use kernel::Event;
@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub NotifyMgmtItemGroupOnOff
{
   my $self=shift;
   my %param=@_;

   my $lnkobj=getModuleObject($self->Config,"itil::lnkmgmtitemgroup");
   my $user  =getModuleObject($self->Config,"base::user");
   my $msgcnt; # number of sent messages

   ## added to mgmtitemgroup
   $lnkobj->ResetFilter;
   $lnkobj->SetFilter({notify1on=>\'[EMPTY]',
                       grouptype=>\'PCONTROL',
                       lnkfrom  =>'>now AND <=now+14d'});

   # collect all data needed for Notification
   my $notifyparams=$self->getNotifyParam($lnkobj,$user);

   # notify
   foreach my $n (@$notifyparams) {
      my $r=$self->notify($n,'on');
      if (defined($r)) {
         $lnkobj->UpdateRecord({notify1on=>NowStamp("en")},
                               {id=>$n->{id}});
         $msgcnt++;
      }
   }

   ## removed from mgmtitemgroup
   $lnkobj->ResetFilter;
   $lnkobj->SetFilter({notify1off=>\'[EMPTY]',
                       grouptype =>\'PCONTROL',
                       lnkto     =>'>now AND <=now+14d'});

   # collect all data needed for Notification
   $notifyparams=undef;
   $notifyparams=$self->getNotifyParam($lnkobj,$user);

   # notify
   foreach my $n (@$notifyparams) {
      my $r=$self->notify($n,'off');
      if (defined($r)) {
         $lnkobj->UpdateRecord({notify1off=>NowStamp("en")},
                               {id=>$n->{id}});
         $msgcnt++;
      }
   }

   ## removed from mgmtitemgroup has been retracted
   $lnkobj->ResetFilter;
   $lnkobj->SetFilter({notify1off=>\'1970-00-00 00:00:00',
                       grouptype =>\'PCONTROL',
                       lnkto     =>'[EMPTY]'});

   # collect all data needed for Notification
   $notifyparams=undef;
   $notifyparams=$self->getNotifyParam($lnkobj,$user);

   # notify
   foreach my $n (@$notifyparams) {
      my $r=$self->notify($n,'roff');
      if (defined($r)) {
         $lnkobj->UpdateRecord({notify1off=>NowStamp("en")},
                               {id=>$n->{id}});
         $msgcnt++;
      }
   }

   return({exitcode=>0,exitmsg=>"$msgcnt notification(s) sent"});
}


sub notify
{
   my $self=shift;
   my $par=shift;
   my $act=shift; # 'on', 'off' or 'roff' (lnkto deleted)

   $ENV{HTTP_FORCE_LANGUAGE}=$par->{lang} if $par->{lang} ne "";
      
   my $subject=$self->T("managed itemgroups notification");

   my $sitename=$self->Config->Param("SITENAME");
   if ($sitename ne "") {
      $subject=$sitename.": ".$subject;
   }
   $sitename="W5Base" if ($sitename eq "");
   my $fromemail='"Managed Itemgroups Notification" <>';

   my $mailtxt=$self->getParsedNotifyTemplate($act,{
      role         =>$self->T($par->{role}),
      citype       =>$self->T($par->{citype}),
      rawcitype    =>$par->{citype},
      ciname       =>$par->{ciname},
      mgmtitemgroup=>$par->{mgmtitemgroup},
      lnkfrom      =>$par->{lnkfrom},
      lnkto        =>$par->{lnkto}
   });
   my %notify=(
               class        =>'base::workflow::mailsend',
               step         =>'base::workflow::mailsend::dataload',
               name         =>$subject,
               emailfrom    =>$fromemail,
               emailto      =>$par->{mailto},
               emailcc      =>$par->{mailcc},
               emailtext    =>$mailtxt,
              );
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $r=undef;
   if (my $id=$wf->Store(undef,\%notify)) {
      my %d=(step=>'base::workflow::mailsend::waitforspool');
      $r=$wf->Store($id,%d);
   }
         
   delete($ENV{HTTP_FORCE_LANGUAGE});
   return($r);
}


sub getParsedNotifyTemplate
{
   my $self=shift;
   my $act=shift;
   my $static=shift;

   my $mailtxt=$self->getParsedTemplate("tmpl/mgmtitemgroupmail$act",
                         {
                            skinbase=>'itil',
                            static=>$static
                         });
   return($mailtxt);
}


sub getNotifyParam
{
   my $self=shift;
   my $lnkobj=shift; # DataObject lnkmgmtitemgroup
   my $user  =shift; # DataObject user

   my @notifyparam;

   my $l=$lnkobj->getHashList(qw(id applid locationid businessserviceid
                                 lnkfrom lnkto mgmtitemgroup));
   foreach my $lnk (@$l) {
      my $mailtoid;
      my @mailccids;
      my %mylnkrec=();

      $mylnkrec{mgmtitemgroup}=$lnk->{mgmtitemgroup};
      $mylnkrec{id}=$lnk->{id};

      if (defined($lnk->{applid})) {

         my $ciobj=getModuleObject($self->Config,"itil::appl");
         $ciobj->SetFilter({id=>$lnk->{applid}});
         my ($cid)=$ciobj->getOnlyFirst(qw(name databossid applmgrid));
         $mylnkrec{ciname}=$cid->{name};
         $mylnkrec{citype}='application';
         $mylnkrec{role}  ='databoss';
         if (defined($cid->{applmgrid})) {
            $mailtoid =$cid->{applmgrid};
            @mailccids=($cid->{databossid});
            $mylnkrec{role}='application manager';
         } else {
            $mailtoid =$cid->{databossid};
         }

      } elsif (defined($lnk->{locationid})) {

         my $ciobj=getModuleObject($self->Config,"base::location");
         $ciobj->SetFilter({id=>$lnk->{locationid}});
         my ($cid)=$ciobj->getOnlyFirst(qw(name databossid));

         $mylnkrec{ciname}=$cid->{name};
         $mylnkrec{citype}='location';
         $mailtoid =$cid->{databossid};

      } elsif (defined($lnk->{businessserviceid})) {

         my $ciobj=getModuleObject($self->Config,"itil::businessservice");
         $ciobj->SetFilter({id=>$lnk->{businessserviceid}});
         my $cid=$ciobj->getOnlyFirst(qw(fullname databossid));

         $mylnkrec{ciname}=$cid->{fullname};
         $mylnkrec{citype}='businessservice';
         $mailtoid =$cid->{databossid};
      }

      my @staticCCids=$self->getStaticMailCC($mylnkrec{citype},
                                             $mylnkrec{mgmtitemgroup});
      push(@mailccids,@staticCCids);

      # mailto
      $user->ResetFilter;
      $user->SetFilter({userid=>\$mailtoid});
      my ($u)=$user->getOnlyFirst(qw(email lastlang));
      my @to=($u->{email});
      $mylnkrec{mailto}=\@to;
      $mylnkrec{lang}  =$u->{lastlang};

      # mailcc
      $user->ResetFilter;
      $user->SetFilter({userid=>\@mailccids});
      my @cc=map {$_->{email}} $user->getHashList('email');
      $mylnkrec{mailcc}=\@cc;

      # lnkfrom, lnkto
      my $format='enday';
      $format='deday' if ($mylnkrec{lang} eq 'de');
      my $lnkfrom=$lnkobj->ExpandTimeExpression($lnk->{lnkfrom},$format);
      $mylnkrec{lnkfrom}=$lnkfrom;
      my $lnkto=$lnkobj->ExpandTimeExpression($lnk->{lnkto},$format);
      $mylnkrec{lnkto}=$lnkto;

      push(@notifyparam,\%mylnkrec);
   }

   return(\@notifyparam);
}


sub getStaticMailCC {
   my $self=shift;
   my $citype=shift;
   my $mgmtitemgroup=shift;

   return(undef);
}



1;
