package itil::lib::BorderChangeHandling;
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

sub BorderChangeHandling
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;


   #
   # border change notification
   #

   my @watched_fields;
   if ($self->SelfAsParentObject() eq "itil::appl"){
      @watched_fields=qw(cistatusid name);
   }
   if ($self->SelfAsParentObject() eq "itil::businessservice"){
      @watched_fields=qw(cistatusid name shortname nature);
   }
   if (defined($oldrec) && defined($newrec)){
      my $watchchanged=0;
      foreach my $f (@watched_fields){
         $watchchanged++ if (effChanged($oldrec,$newrec,$f));
      } 
      if ($watchchanged){
         my $ia=getModuleObject($self->Config,"base::infoabo");
         my $wfa=getModuleObject($self->Config,"base::workflowaction");
         my $id=effVal($oldrec,$newrec,"id");
         my %u=(emailto=>{},emailcc=>{},emailbcc=>{});
         my %border;
         if ($self->SelfAsParentObject() eq "itil::appl"){
            ####################################################################
            # calculation of border elements
            my $lnkappl=getModuleObject($self->Config,"itil::lnkapplappl");
            $lnkappl->SetFilter({
               toapplid=>\$id,
               cistatusid=>"<5",
               fromapplcistatus=>"<6"
            });
            foreach my $lnkrec ($lnkappl->getHashList("fromapplid")){
               $border{'itil::appl'}->{$lnkrec->{fromapplid}}=1;
            }
            my $lnk=getModuleObject($self->Config,"itil::lnkbscomp");
            $lnk->SetFilter([
               {
                  obj1id=>\$id,
                  objtype=>\'itil::appl',
               }
            ]);
            my %bsid=();
            foreach my $lnkrec ($lnk->getHashList("businessserviceid")){
               $border{'itil::businessservice'}->
                   {$lnkrec->{businessserviceid}}=1;
            }

         }
         if ($self->SelfAsParentObject() eq "itil::businessservice"){
            ####################################################################
            # calculation of border elements
            my $lnk=getModuleObject($self->Config,"itil::lnkbscomp");
            $lnk->SetFilter([
               {
                  obj1id=>\$id,
                  objtype=>\'itil::businessservice',
               }
            ]);
            my %bsid=();
            foreach my $lnkrec ($lnk->getHashList("businessserviceid")){
               $border{'itil::businessservice'}->
                   {$lnkrec->{businessserviceid}}=1;
            }
            $lnk->ResetFilter();
            $lnk->SetFilter({businessserviceid=>\$id});
            foreach my $lnkrec ($lnk->getHashList("obj1id","objtype")){
               foreach my $f (qw(obj1id obj2id obj3id)){
                  if ($lnkrec->{$f} ne ""){
                     $border{$lnkrec->{objtype}}->{$lnkrec->{$f}}=1;
                  }
               }
            }
         }
         ##################################################################
         # calculation of contacts to notify
         if (keys(%{$border{'itil::appl'}})){
            my $appl=getModuleObject($self->Config,"itil::appl");
            $appl->SetFilter({id=>[keys(%{$border{'itil::appl'}})],
                              cistatusid=>"<6"});
            foreach my $arec ($appl->getHashList(qw(id name databossid))){
               if ($arec->{databossid} ne ""){
                  $u{emailto}->{$arec->{databossid}}++;
               }
               $border{'itil::appl'}->{$arec->{id}}=$arec->{name};
               $ia->LoadTargets($u{emailcc},\'itil::appl',
                                \'genborderchange',\$arec->{id},
                                 undef,                  
                                 load=>'userid');
            }
         }
         ##################################################################
         # calculation of contacts to notify
         if (keys(%{$border{'itil::businessservice'}})){
            my $o=getModuleObject($self->Config,"itil::businessservice");
            $o->SetFilter({id=>[keys(%{$border{'itil::businessservice'}})],
                           cistatusid=>"<6"});
            foreach my $lrec ($o->getHashList(qw(id fullname databossid))){
               if ($lrec->{databossid} ne ""){
                  $u{emailto}->{$lrec->{databossid}}++;
               }
               $border{'itil::businessservice'}->{$lrec->{id}}=
                  $lrec->{fullname};
               $ia->LoadTargets($u{emailcc},\'itil::businessservice',
                                \'genborderchange',\$lrec->{id},
                                 undef,                  
                                 load=>'userid');
            }
         }
         #################################################################
         # infoabo handling
         my @to=keys(%{$u{emailto}});
         $u{emailto}={};
         $ia->LoadTargets($u{emailto},'base::staticinfoabo',
                          \'STEVborderchange','110000004',
                           \@to,
                           default=>1,
                           load=>'userid');

         ####################################################################
         # calculation of notification languages and filter activ users
         my $user=getModuleObject($self->Config,"base::user");
         $user->SetFilter({
            userid=>[keys(%{$u{emailto}}),
                     keys(%{$u{emailcc}}),
                     keys(%{$u{emailbcc}})],
            cistatusid=>[3,4,5]
         });
         my %ul;
         foreach my $urec ($user->getHashList(qw(lang lastlang userid))){ 
           my $lang=$urec->{lastlang};
           $lang=$urec->{lang} if ($lang eq "");
           $lang="en"  if ($lang eq "");
           $ul{$lang}->{$urec->{userid}}++;
         }
         #$ul{en}->{11634953080001}++;  # debug with uid=hvogler
         #$ul{de}->{11634953080001}++;
         ####################################################################
         # create and send notifications
         my $lastlang;
         if ($ENV{HTTP_FORCE_LANGUAGE} ne ""){
            $lastlang=$ENV{HTTP_FORCE_LANGUAGE};
         }
         foreach my $lang (keys(%ul)){
            $ENV{HTTP_FORCE_LANGUAGE}=$lang;
            my $subject=$self->T("attribute change on touched element:",
                                 "itil::lib::BorderChangeHandling");
            my $nameattr="name";
            my $name="unknownname";
            if ($self->SelfAsParentObject() eq "itil::appl"){
               $nameattr="name";
            }
            if (effChanged($oldrec,$newrec,$nameattr)){
               $name=$oldrec->{$nameattr}."->".$newrec->{$nameattr}; 
            }
            else{
               $name=effVal($oldrec,$newrec,$nameattr);
            }
            $subject.=" ".$name;

            my $text=$self->T("Dear user","itil::lib::BorderChangeHandling");
            $text.=",\n\n";
            $text.=sprintf(
                      $self->T("there have been attribute ".
                               "changes made on the tangent ".
                               "element '%s' (related to your ".
                               "roles/functions or infoabo subscriptions):",
                               "itil::lib::BorderChangeHandling"),
                   effVal($oldrec,$newrec,$nameattr));
                  
            $text.="\n";
            my $atext="";
            foreach my $f (@watched_fields){
               if (effChanged($oldrec,$newrec,$f)){
                  if ($f eq "cistatusid"){
                     my $cimode;
                     if ($oldrec->{cistatusid}<5 && 
                            $newrec->{cistatusid}==6){
                        # notify gelöscht
                        $cimode=$self->T("marked as delete",
                                         "itil::lib::BorderChangeHandling");
                     }
                     elsif ($oldrec->{cistatusid}!=4 && 
                            $newrec->{cistatusid}==4){
                        # notify reaktivierung
                        $cimode=$self->T("reactivate",
                                         "itil::lib::BorderChangeHandling");
                     }
                     elsif ($oldrec->{cistatusid}==4 && 
                            $newrec->{cistatusid}!=4){
                        # notify zeitweise/inaktiv
                        $cimode=$self->T("marked as inactiv",
                                         "itil::lib::BorderChangeHandling");
                     }
                     if (defined($cimode)){
                        my $fo=$self->getField("cistatus");
                        my $label=$fo->Label();
                        $atext.="<b>".$label.":</b>\n";
                        $atext.=" $cimode";
                        $atext.="\n\n";
                     }
                  }
                  else{
                     my $fo=$self->getField($f);
                     my $label=$fo->Label();
                     $atext.="<b>".$label.":</b>\n";
                     $atext.=" old: ".quoteHtml($oldrec->{$f})."\n";
                     $atext.=" new: ".quoteHtml($newrec->{$f})."\n";
                     $atext.="\n";
                  }
               }
            }
            if ($atext ne ""){
               $text.="\n".$atext."\n";
               $text.=$self->T("This changes touches the following elements:",
                               "itil::lib::BorderChangeHandling");
               $text.="\n";
               foreach my $dataobj (keys(%border)){
                  if (keys(%{$border{$dataobj}})){
                     $text.="\n<b>".$self->T($dataobj,$dataobj).":</b>"."\n";
                  }
                  foreach my $id (keys(%{$border{$dataobj}})){
                     my $baseurl;
                     if ($ENV{SCRIPT_URI} ne ""){
                        $baseurl=$ENV{SCRIPT_URI};
                        $baseurl=~s/\/auth\/.*$//;
                     }
                     else{
                        my $baseurl=$self->Config->Param("EventJobBaseUrl");
                        $baseurl.="/" if (!($baseurl=~m/\/$/));
                     }
                     if (lc($ENV{HTTP_FRONT_END_HTTPS}) eq "on"){
                        $baseurl=~s/^http:/https:/i;
                     }

                     my $p=$dataobj;
                     $p=~s/::/\//g;
                     $baseurl.="/auth/$p/ById/$id";

                     $text.=" - ".quoteHtml($border{$dataobj}->{$id})."\n".
                            "   $baseurl\n\n";
                  }
               }
               my %notifyparam=();
               foreach my $tag (keys(%u)){
                  foreach my $userid (keys(%{$u{$tag}})){
                    if (exists($ul{$lang}->{$userid})){
                       if (!defined($notifyparam{$tag})){
                          $notifyparam{$tag}=[];
                       }
                       push(@{$notifyparam{$tag}},$userid);
                    }
                  }
               }
               #printf STDERR ("notifyparam=%s\n",Dumper(\%notifyparam));
               $wfa->Notify("INFO",$subject,$text,%notifyparam);
            }
         }
         if (defined($lastlang)){
            $ENV{HTTP_FORCE_LANGUAGE}=$lastlang;
         }
         else{
            delete($ENV{HTTP_FORCE_LANGUAGE});
         }
         ####################################################################
         #printf STDERR ("u=%s\n",Dumper(\%u));
         #printf STDERR ("ul=%s\n",Dumper(\%ul));
         #printf STDERR ("border=%s\n",Dumper(\%border));
      }
   }

}
1;
