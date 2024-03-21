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

   my @notifytypes=qw(PCONTROL CFGROUP);
   my $lnkobj=getModuleObject($self->Config,"itil::lnkmgmtitemgroup");
   my $user  =getModuleObject($self->Config,"base::user");
   my $msgcnt=0; # number of sent messages

   ## added to mgmtitemgroup
   $lnkobj->ResetFilter;
   $lnkobj->SetFilter({notify1on=>\'[EMPTY]',
                       grouptype =>\@notifytypes,
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
                       grouptype =>\@notifytypes,
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

   ## 'link to' from mgmtitemgroup has been retracted
   $lnkobj->ResetFilter;
   $lnkobj->SetFilter({notify1off=>\'[EMPTY]',
                       grouptype =>\@notifytypes,
                       lnkto     =>\'[EMPTY]',
                       rlnkto    =>\'>now'});

   # collect all data needed for Notification
   $notifyparams=undef;
   $notifyparams=$self->getNotifyParam($lnkobj,$user);

   # notify
   foreach my $n (@$notifyparams) {
      my $r=$self->notify($n,'roff');
      if (defined($r)) {
         $lnkobj->UpdateRecord({notify1off=>NowStamp("en"),
                                rlnkto=>undef},
                               {id=>$n->{id}});
         $msgcnt++;
      }
   }

   return({exitcode=>0,msg=>"$msgcnt notification(s) sent"});
}


sub notify
{
   my $self=shift;
   my $par=shift;
   my $act=shift; # 'on', 'off' or 'roff' (lnkto deleted)

   my $addrok=0;
   if (defined($par->{mailto}) && 
       ((ref($par->{mailto}) eq "ARRAY" && $#{$par->{mailto}}!=-1) ||
        ($par->{mailto} ne ""))){
      $addrok++;
   }
   if (defined($par->{mailcc}) && 
       ((ref($par->{mailcc}) eq "ARRAY" && $#{$par->{mailcc}}!=-1) ||
        ($par->{mailcc} ne ""))){
      $addrok++;
   }
   return(1) if (!$addrok);  # prevent empty address mails


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
      lnkto        =>$par->{lnkto},
      tz=>$par->{tz},
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
                                 lnkfrom lnkto mgmtitemgroup grouptype
                                 cicistatusid));
   foreach my $lnk (@$l) {
      my $mailtoid;
      my @mailccids;
      my %mylnkrec=();
      next if ($lnk->{cicistatusid}>5);

      $mylnkrec{mgmtitemgroup}=$lnk->{mgmtitemgroup};
      $mylnkrec{id}=$lnk->{id};
      $mylnkrec{role}='databoss';

      if (defined($lnk->{applid})) {

         my $ciobj=getModuleObject($self->Config,"itil::appl");
         $ciobj->SetFilter({id=>$lnk->{applid}});
         my ($cid)=$ciobj->getOnlyFirst(qw(name databossid applmgrid));
         $mylnkrec{ciname}=$cid->{name};
         $mylnkrec{citype}='application';
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
      my $targetcnt=0;
      if ($mailtoid ne ""){
         $user->ResetFilter;
         $user->SetFilter({userid=>\$mailtoid});
         my ($u)=$user->getOnlyFirst(qw(email lastlang tz));
         if (defined($u)){
            my @to=($u->{email});
            $mylnkrec{mailto}=\@to;
            $mylnkrec{lang}  =$u->{lastlang};
            $mylnkrec{tz}    =$u->{tz};
            $targetcnt++;
         }
      }

      # mailcc
      if ($#mailccids!=-1){
         $user->ResetFilter;
         $user->SetFilter({userid=>\@mailccids});
         my @cc=map {$_->{email}} $user->getHashList('email');
         if ($#cc!=-1){
            $mylnkrec{mailcc}=\@cc;
            $targetcnt+=($#cc+1);
         }
      }
      if ($targetcnt>0){
         $mylnkrec{lang}="en" if ($mylnkrec{lang} eq "");
         $mylnkrec{tz}="GMT"  if ($mylnkrec{tz} eq "");

         my $format=$mylnkrec{lang};
         my $lnkfrom=$lnkobj->ExpandTimeExpression($lnk->{lnkfrom},$format,
                                                   undef,$mylnkrec{tz});
         $lnkfrom.=" ($mylnkrec{tz})";
         $mylnkrec{lnkfrom}=$lnkfrom;
         my $lnkto=$lnkobj->ExpandTimeExpression($lnk->{lnkto},$format,
                                                 undef,$mylnkrec{tz});
         $lnkto.=" ($mylnkrec{tz})";
         $mylnkrec{lnkto}=$lnkto;

         push(@notifyparam,\%mylnkrec);
      }
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
