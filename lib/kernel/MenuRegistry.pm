package kernel::MenuRegistry;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (hartmut.vogler@epost.de)
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
#
use vars qw(@ISA);
use strict;
use kernel;
use kernel::SubDataObj;

@ISA=qw(kernel::SubDataObj);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub RegisterObj
{
   my $self=shift;
   my $name=shift;
   my $target=shift;
   my %param=@_;
   my $c=$self->getParent()->Context;
   my $p=$c->{MenuAccessObject};
   my $user=$c->{UserObject};
   my $grp=$c->{GroupObject};

   if (!defined($p)){
      $p=getModuleObject($self->Config,"base::menu");
      $c->{MenuAccessObject}=$p;
   }
   return(undef) if (!$p->IsMemberOf("admin"));
   if (!defined($user)){
      $user=getModuleObject($self->Config,"base::user");
      $c->{UserObject}=$user;
   }
   if (!defined($grp)){
      $grp=getModuleObject($self->Config,"base::grp");
      $c->{GroupObject}=$grp;
   }
   my $mc=$self->getParent->{CompareMenu};
   return(undef) if (!defined($mc));

   my %rec=(fullname=>$name,target=>$target);
   if (defined($param{param})){
      $rec{param}=$param{param};
   }
   if (defined($param{translation})){
      $rec{translation}=$param{translation};
   }
   else{
      $rec{translation}=$self->Self();
   }
   if (defined($param{config})){
      $rec{config}=$param{config};
   }
   else{
      $rec{config}=$p->Config->getCurrentConfigName;
   }
   if (defined($param{prio})){
      $rec{prio}=$param{prio};
   }
   else{
      $rec{prio}=1000;
   }
   if ($rec{target}=~m/^\S+::\S+$/){
      $rec{func}="Main";
      $rec{func}=$param{func} if (defined($param{func}));
   }
   if ($self->Config->Param("W5BaseOperationMode") eq "slave" ||
       $self->Config->Param("W5BaseOperationMode") eq "readonly"){
      return;
   }

   if (!defined($mc->{fullname}->{$name})){
      #printf STDERR ("fifi insert $name\n");
      if (my $mid=$p->ValidatedInsertRecord(\%rec)){
         $p->{MenuIsChanged}=1;
         printf STDERR ("new Menuid=$mid\n");
         if (defined($param{defaultacl})){
            if (ref($param{defaultacl}) ne "ARRAY"){
               $param{defaultacl}=[$param{defaultacl}];
            }
            my $aclfield=$p->getField("acls");
            foreach my $acl (@{$param{defaultacl}}){
               my $dfield=$p->getField("acls");
               my %rec=$p->getForceParamForSubedit($mid,$dfield);
               $rec{acltargetname}=$acl;
               my $found=0;
               $grp->SetFilter({fullname=>\$acl});
               my ($chkrec,$msg)=$grp->getOnlyFirst(qw(fullname));
               $found=1 if (defined($chkrec));
printf STDERR ("fifi 01: $param{defaultacl}\n");
               if (!$found){
                  $user->SetFilter({fullname=>\$acl});
                  my ($chkrec,$msg)=$user->getOnlyFirst(qw(fullname));
                  $found=1 if (defined($chkrec));
printf STDERR ("fifi 02: $param{defaultacl}\n");
               }
printf STDERR ("fifi 03: $found\n");
               if ($found){
printf STDERR ("fifi 04: %s\n",Dumper(\%rec));
                  $dfield->vjoinobj->ValidatedInsertRecord(\%rec);
               }
            }
         }
      }
   }
   else{
      if ($rec{target} ne $mc->{fullname}->{$name}->{target} ||
          $rec{func} ne $mc->{fullname}->{$name}->{func} ||
          $rec{param} ne $mc->{fullname}->{$name}->{param} ||
          ($mc->{fullname}->{$name}->{target} eq "" && $rec{tranlation} ne "")){
         #printf STDERR ("fifi update $name\n");
         if ($p->ValidatedUpdateRecord(
                            $mc->{fullname}->{$name},
                            \%rec,
                            {menuid=>\$mc->{fullname}->{$name}->{menuid}})){
            $p->{MenuIsChanged}=1;
         }
      }
   }
}

sub RegisterUrl
{
   my $self=shift;

}

1;

