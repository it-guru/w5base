package tsotc::event::CloudAreaSync;
#  W5Base Framework
#  Copyright (C) 2019  Hartmut Vogler (it@guru.de)
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




sub Init
{
   my $self=shift;


   $self->RegisterEvent("CloudAreaSync","CloudAreaSync",timeout=>600);
}




sub CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;

   my $inscnt=0;

   my @a;
   my %itcloud;

   my $appans=getModuleObject($self->Config,"tsotc::appagilenamespace");
   my $otcpro=getModuleObject($self->Config,"tsotc::project");
   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");

   if (!($appans->Ping()) ||
       !($otcpro->Ping()) ||
       !($itcloudobj->Ping())){
      msg(ERROR,"not all dataobjects available");
      return(undef);
   }

   $appans->SetFilter({
      cluster=>'![EMPTY]',
      name=>'![EMPTY]'
   });
   foreach my $appansrec ($appans->getHashList(qw(
                           name fullname cluster id applid appl supportid
                           lastmondate))){
       $itcloud{lc($appansrec->{cluster})}++;
       my $fullname=$appansrec->{cluster}.".".$appansrec->{name};
       my %carec=(
          itcloud=>$appansrec->{cluster},
          fullname=>$fullname,
          name=>$appansrec->{name},
          srcid=>undef,
          srcsys=>$appans->Self(),
          supportid=>$appans->{supportid},
          applid=>$appansrec->{applid},
          appl=>$appansrec->{appl},
          lastmondate=>$appansrec->{lastmondate}
       );
       push(@a,\%carec);
   }
   if ($#a==-1){
      die("no appagile namespaces found - this seems to be a DB Bug");
   }

   $otcpro->SetFilter({
      name=>'![EMPTY]'
   });
   {
      my %otcpname;
      my $itcloud="OTC";
      $otcpro->SetFilter({lastmondate=>">now-14d"});
      foreach my $otcprorec ($otcpro->getHashList(qw(
                              name cluster id applid appl supportid
                              domain fullname
                              lastmondate))){
          my $fullname=$itcloud.".".$otcprorec->{name};
          $itcloud{$itcloud}++;
          $otcpname{$otcprorec->{name}}++;
          my $altname=$otcprorec->{domain}."_".$otcprorec->{fullname};
          my $altfullname=$itcloud.".".$altname;
          my %carec=(
             itcloud=>$itcloud,
             fullname=>$fullname,
             altname=>$altname,
             altfullname=>$altfullname,
             name=>$otcprorec->{name},
             srcid=>$otcprorec->{id},
             supportid=>$otcprorec->{supportid},
             srcsys=>$otcpro->Self(),
             applid=>$otcprorec->{applid},
             appl=>$otcprorec->{appl},
             lastmondate=>$otcprorec->{lastmondate}
          );
          push(@a,\%carec);
      }
      my @dupotcpname=grep({$otcpname{$_}>1} keys(%otcpname));
    
      foreach my $name (@dupotcpname){
         foreach my $arec (@a){
            if ($arec->{itcloud} eq $itcloud &&
                $arec->{name} eq $name){   # rename it
               $arec->{name}=$arec->{altname};
               $arec->{fullname}=$arec->{altfullname};
            }
         }
      }
   }

   # load all relevant itcloud records
   $itcloudobj->SetFilter({
      name=>join(" ",sort(keys(%itcloud)))
   });
   $itcloudobj->SetCurrentView(qw(name id databossid cistatusid contacts));
   my $itcloud=$itcloudobj->getHashIndexed("id","name");


   foreach my $cloudname (sort(keys(%itcloud))){
      if (!exists($itcloud->{name}->{$cloudname})){
         #msg(ERROR,"missing itcloud '$cloudname' to admin");
      }
   }

   # load all relevant itcloudarea records
   my $itcloudareaobj=getModuleObject($self->Config,"itil::itcloudarea");
   my $applobj=getModuleObject($self->Config,"itil::appl");

   $itcloudareaobj->ResetFilter();
   $itcloudareaobj->SetFilter({
      cloud=>join(" ",sort(keys(%itcloud))),
   });
   $itcloudareaobj->SetCurrentView(qw(ALL));
   my $itcloudarea=$itcloudareaobj->getHashIndexed("id","fullname","name");

   #print Dumper(\%itcloud);
   #print Dumper($itcloud);
   #print Dumper($itcloudarea);
   my $caref={};

   foreach my $a (@a){
      last if ($inscnt>50);
      my $fullname=$a->{fullname};
      my $currec;
      my @ifullname=grep(/^\Q$fullname\E$/i,keys(%{$itcloudarea->{fullname}}));
      if ($#ifullname>0){
         msg(ERROR,"not unique cloudare fullname problem for $fullname");
         next;
      }
      if ($#ifullname==0){
         $fullname=$ifullname[0];
      }
      if (exists($itcloudarea->{fullname}->{$fullname})){
         $currec=$itcloudarea->{fullname}->{$fullname};
         $caref->{$currec->{id}}=$a;
      }
      if (defined($a->{srcid}) && defined($a->{srcsys}) &&
          !defined($currec)){
         foreach my $carec (values(%{$itcloudarea->{id}})){
            if ($a->{srcsys} eq $carec->{srcsys} &&
                $a->{srcid} eq $carec->{srcid}){
               $currec=$carec;
               last;
            }
         }
      }
      if (!defined($currec)){
         my $cloudname=$a->{itcloud};
         my @icloudname=grep(/^\Q$cloudname\E$/i,keys(%{$itcloud->{name}}));
         if ($#icloudname>0){
            msg(ERROR,"not unique cloud name problem for $cloudname");
            next;
         }
         if ($#icloudname==0){
            if ($a->{itcloud} ne $icloudname[0]){
               $a->{itcloud}=$icloudname[0];
            }
         }

         if (exists($itcloud->{name}->{$a->{itcloud}})){
            my @err;
            if ($a->{appl} ne ""){
               $applobj->ResetFilter();
               $applobj->SetFilter({id=>\$a->{applid}});
               my ($achkrec,$msg)=$applobj->getOnlyFirst(qw(id cistatusid));
               if (defined($achkrec) &&
                   $achkrec->{cistatusid}>1 &&
                   $achkrec->{cistatusid}<5 &&
                   length($a->{name})<70 && length($a->{name})>1){
                  my $newrec={
                     cloud=>$a->{itcloud},
                     name=>$a->{name},
                     applid=>$a->{applid},
                     cistatusid=>'3',
                     srcsys=>$a->{srcsys}
                  };
                  if ($a->{srcid} ne ""){
                     $newrec->{srcid}=$a->{srcid}; # srcid not always set!
                  }
                  $itcloudareaobj->ValidatedInsertRecord($newrec);
                  sleep(1);
                  $inscnt++;
               }
               else{
                   push(@err,
                        "ERROR: invalid area name or releated application ".
                        "at CloudArea $fullname");
               }
            }
            else{
              # push(@err,"ERROR: missing valid application ".
              #           "W5BaseID in $fullname");
            }
            if ($#err!=-1){
               my %notifyParam=();
               $itcloudobj->NotifyWriteAuthorizedContacts(
                            $itcloud->{name}->{$a->{itcloud}},{},
                            \%notifyParam,{},sub{
                  my ($subject,$ntext);
                  my $subject="ERROR: CloudArea Sync";
                  my $tmpl=join("\n",@err);
                  return($subject,$tmpl);
               });
               @err=();
            }
         }
      }
      else{
         # check, if updates needs to be done
         my $updrec;
         my $d=CalcDateDuration($a->{lastmondate},NowStamp("en"));
         if (defined($d)){
            if ($d->{days}>6){
               if ($currec->{cistatusid}!=6){
                  $updrec->{cistatusid}=6;   # auf veraltet settzen
               }
            }
            else{
               if ($currec->{cistatusid}>5){ # reaktivieren einer bereits
                  $updrec->{cistatusid}=3;   # als veraltet markieren CloudArea
               }                             # (mit Nachfrage beim AG DV)
            }

            if ($currec->{srcsys} ne $a->{srcsys}){
               $updrec->{srcsys}=$a->{srcsys};
            }
            my $curbasename=$currec->{name};
            $curbasename=~s/\[[0-9]+\]$//;
            if ($curbasename ne $a->{name}){
               $updrec->{name}=$a->{name};
            }
            if (exists($a->{srcid}) && $a->{srcid} ne "" &&
                $currec->{srcid} ne $a->{srcid}){
               $updrec->{srcid}=$a->{srcid};
            }
            if ($currec->{applid} ne $a->{applid}){
               if ($a->{appl} ne ""){
                  $updrec->{appl}=$a->{appl};
                  if ($currec->{cistatusid} eq "4"){
                     if ($d->{days}<3){
                        $updrec->{cistatusid}=3;
                     }
                  }
               }
            }
            if (keys(%$updrec)){
               $itcloudareaobj->ValidatedUpdateRecord(
                  $currec,$updrec,{
                     id=>$currec->{id}
                  }
               );
            }
         }
         else{
            msg(ERROR,"invalid lastmondate in ".Dumper($a));
         }
      }
   }
   if (keys(%$caref)){  # cleanup only if min. one ref found
      foreach my $carec (values(%{$itcloudarea->{id}})){
          next if ($carec->{cistatusid}>=6);  # check only entries in active state
          next if (!($carec->{srcsys}=~m/^tsotc::/)); # check only from this mod
          if (!exists($caref->{$carec->{id}})){  # seems not exists anymore
             $itcloudareaobj->ValidatedUpdateRecord(
                $carec,{cistatusid=>6},{
                   id=>$carec->{id}
                }
             );
          }
      }
   }
   




   return({exitcode=>0,exitmsg=>'ok'});
}






1;
