package base::qrule::ContactRights;
#######################################################################
=pod

=encoding latin1

=head3 PURPOSE

Checks if there at least one contact with rule 'write' is documented
beside the databoss.

=head3 IMPORTS

NONE

=head3 HINTS

[de:]

Bitte hinterlegen Sie mindestens einen Kontakt mit der Rolle "schreiben", 
der nicht gleichzeitig Datenverantwortlicher für diesen Datensatz ist. 
Ist ein Config-Item älter als 4 Wochen, so wird die organisatorische
Einheit (Projektgruppen werden dabei bevorzugt verwendet) des 
Datenverantwortlichen automatisch als Kontakt mit der
Rolle "schreiben" hinzugefügt, falls keine weiteren Kontakte mit
der Rolle "schreiben" vorhanden sind.

Wenn nur "Mitarbeiter" Rollen vorhanden sind, wird die Gruppe mit
der ältesten Zuordnung verwendet. Sind keine "Mitarbeiter" Rollen
vorhanden, wird die mit den meisten Hierarchie-Stufen verwendet
und bei Gleichstand dann die, die die älteste Zuordnung hat.

[en:]

Please enter at least one person, other than the current databoss, 
into the field Contacts with the role application write.
If a config item is older than 4 weeks, the organizational unit 
(project groups will be used preferred) of the databoss is 
automatically added as a contact with the 
role "write" if there are no further contacts with the role "write".


=cut
#######################################################################
#  W5Base Framework
#  Copyright (C) 2007  Hartmut Vogler (it@guru.de)
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
use kernel::QRule;
@ISA=qw(kernel::QRule);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub getPosibleTargets
{
   return([".*"]);
}

sub qcheckRecord
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;

   return(0,undef) if (!exists($rec->{cistatusid}) || $rec->{cistatusid}>5);
   my $fo=$dataobj->getField("contacts");
   return(undef,undef) if (!defined($fo));
   if ($fo->Type() ne "ContactLnk"){
      msg(ERROR,"invalid qrule for base::qrule::ContactRights in $dataobj"); 
      return(undef,undef) if (!defined($fo));
   }
   my $l=$fo->RawValue($rec);
   my $found=0;
   my $databossid=$rec->{databossid};
   my $databossfo=$dataobj->getField("databossid");
   return(undef,undef) if (!defined($databossfo));
   if ($databossid eq ""){
      return(3,{qmsg=>['no databoss registered'],
             dataissue=>['no databoss registered']});

   }

   if (ref($l) eq "ARRAY"){
      foreach my $crec (@$l){
         my $r=$crec->{roles};
         $r=[$r] if (ref($r) ne "ARRAY");
         if ($crec->{target} eq "base::grp" && grep(/^write$/,@$r)){
            $found++;
            last;
         }
         if ($crec->{target} eq "base::user" && grep(/^write$/,@$r) &&
             $databossid ne "" && $databossid ne $crec->{targetid}){
            $found++;
            last;
         }
      }
   }
   my $age=90;
   if (exists($rec->{cdate}) && $rec->{cdate} ne ""){
      my $s=$rec->{cdate};
      my $d=CalcDateDuration($s,NowStamp("en"),"GMT");
      if (defined($d)){
         $age=$d->{days};
      }
   }
   if ($age>27 && !$found){
      # try to add team with role "write"
      my $lnkobjname=$fo->getNearestVjoinTarget();
      $lnkobjname=$$lnkobjname if (ref($lnkobjname));
      my $lnkobj=getModuleObject($dataobj->Config,$lnkobjname);
      my $vjoinon=$fo->{vjoinon};
      my $parentobj=$dataobj->SelfAsParentObject();
      my $lnkgrp=getModuleObject($dataobj->Config,"base::lnkgrpuser");
      $lnkgrp->SetFilter({userid=>\$databossid,
                          rawnativroles=>[orgRoles()],
                          grpcistatusid=>\'4',
                          alertstate=>'[EMPTY]'});
      my $grp;
      my @l=$lnkgrp->getHashList(qw(cdate group roles alertstate grpid
                                    is_projectgrp));
      my @e=grep({in_array($_->{roles},[orgRoles()])} @l);

      if ($#e>0){  # if more then one orgRole Relations, prever use 
                   # of is_projectgrp group relations.
         my %is_projectgrp=();
         map({
            if ($_->{is_projectgrp}){
               $is_projectgrp{$_->{grpid}}++;
            }
         } @e);
         if (keys(%is_projectgrp)){
            my @newe;
            foreach my $erec (@e){
               push(@newe,$erec) if ($erec->{is_projectgrp});
            }
            @e=@newe;
         }
      }

      if ($#e!=-1){  # Wenn REmployee Einträge, dann haben die Vorrang
         $grp=$e[0];
      }
      else{
         my @l2=sort({
            my $sa=$a->{group};
            $sa=~s/[^.]//g;
            my $la=length($sa)+1;
            my $sb=$b->{group};
            $sb=~s/[^.]//g;
            my $lb=length($sb)+1;
            my $bk=$lb<=>$la;  # die gruppe mit den meisten Ebenen!
            if ($lb==$la){     # ansonsten die Gruppe, in der man am längsten
               $bk=$a->{cdate}<=>$b->{cdate}; # zugeordnet ist
            }
            $bk;
         } @l);
         $grp=$l2[0];
      }

      if (defined($grp)){
         my $grpid=$grp->{grpid};
         my $refid=$rec->{$vjoinon->[0]};
         if ($refid ne ""){
            $lnkobj->ResetFilter();
            $lnkobj->SetFilter({
               targetid=>\$grp->{grpid},
               target=>\"base::grp",
               $vjoinon->[1]=>\$refid,
               parentobj=>\$parentobj
            });
            my ($oldrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL));
            if (defined($oldrec)){
               my $roles=$oldrec->{roles};
               $roles=[$roles] if (ref($roles) ne "ARRAY");
               if (!in_array($roles,"write")){
                  push(@$roles,"write");
                  my $cid=$lnkobj->ValidatedUpdateRecord($oldrec,{
                     roles=>$roles,
                  },{id=>$oldrec->{id}});
                  if ($cid){
                     return(0,{qmsg=>['group automaticly updated: '.$grp->{group}]});
                  }
               }
            }
            else{
               my $cid=$lnkobj->ValidatedInsertRecord({
                  $vjoinon->[1]=>$refid,
                  targetid=>$grp->{grpid},
                  target=>"base::grp",
                  roles=>['write'],
                  parentobj=>$parentobj
               });
               if ($cid){
                  return(0,{qmsg=>['group automaticly added: '.$grp->{group}]});
               }
            }
         }
         
         print STDERR "use=".Dumper($grp);

      }
   }
   
   if (!$found){
      return(3,{qmsg=>['no additional contacts with role write registered'],
             dataissue=>['no additional contacts with role write registered']});
   }

   return(0,undef);
}



1;
