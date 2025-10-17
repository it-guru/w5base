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
use UUID::Tiny(':std');
@ISA=qw(kernel::Event);




sub Init
{
   my $self=shift;


   $self->RegisterEvent("OTC_CloudAreaSync","CloudAreaSync",timeout=>600);
   $self->RegisterEvent("CloudAreaSync","CloudAreaSync",timeout=>600);
}




sub CloudAreaSync
{
   my $self=shift;
   my $queryparam=shift;

   my $inscnt=0;
   my $minDaysOfMoni=14;

   my @a;
   my %itcloud;

   my $appans=getModuleObject($self->Config,"tsotc::appagilenamespace");
   my $otcpro=getModuleObject($self->Config,"tsotc::project");
   my $itcloudobj=getModuleObject($self->Config,"itil::itcloud");

   if (!($appans->Ping()) ||
       !($otcpro->Ping()) ||
       !($itcloudobj->Ping())){
      my $infoObj=getModuleObject($self->Config,"itil::lnkapplappl");
      if ($infoObj->NotifyInterfaceContacts($otcpro)){
         return({exitcode=>0,exitmsg=>'Interface notified'});
      }
      return({exitcode=>1,exitmsg=>'not all dataobjects available'});
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

       my $fake_srcid=create_uuid(UUID_V3,$fullname.":".$appansrec->{applid});

       my %carec=(
          itcloud=>$appansrec->{cluster},
          fullname=>$fullname,
          name=>$appansrec->{name},
          srcid=>uuid_to_string($fake_srcid),
          srcsys=>$appans->Self(),
          supportid=>$appans->{supportid},
          applid=>$appansrec->{applid},
          appl=>$appansrec->{appl},
          lastmondate=>$appansrec->{lastmondate}
       );
       #next if ($fullname=~m/test/i);
       next if ($appansrec->{appl} eq "");
       push(@a,\%carec);
   }
   if ($#a==-1){
      msg(ERROR,"no appagile namespaces found - this seems to be a DB Bug");
      exit(1);
   }

   $otcpro->SetFilter({
      name=>'![EMPTY]'
   });
   {
      my %otcpname;
      my $itcloud="OTC";
      $otcpro->SetFilter({lastmondate=>">now-${minDaysOfMoni}d"});
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
          next if ($otcprorec->{appl} eq "");
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
   my $itcloudarea=$itcloudareaobj->getHashIndexed("id","fullname",
                                                   "name","srcid");

   #print Dumper(\%itcloud);
   #print Dumper($itcloud);
   #print Dumper($itcloudarea);
   #print Dumper(\@a);
   #printf("n=%d\n",$#a+1);
   my $caref={};

   foreach my $a (@a){
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
      elsif (exists($itcloudarea->{srcid}->{$a->{srcid}})){
         $currec=$itcloudarea->{srcid}->{$a->{srcid}};
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
            if ($d->{days}>$minDaysOfMoni){
               if ($currec->{cistatusid}!=6){
                  $updrec->{cistatusid}=6;   # auf veraltet settzen
               }
            }
            else{
               if ($currec->{cistatusid}>5){ # reaktivieren einer bereits
                  $updrec->{cistatusid}=3;   # als veraltet markieren CloudArea
               }                             
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
            else{
               if ($currec->{cistatusid} eq "6"){
                  $updrec->{cistatusid}="3";
                  $updrec->{applid}=$a->{applid};
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
          next if ($carec->{cistatusid}>=6); #check only entries in active state
          if (!exists($caref->{$carec->{id}})){  # seems not exists anymore
             $itcloudareaobj->ValidatedUpdateRecord(
                $carec,{cistatusid=>6},{
                   id=>$carec->{id}
                }
             );
          }
          else{
          }
      }
   }
   




   return({exitcode=>0,exitmsg=>'ok'});
}






1;
