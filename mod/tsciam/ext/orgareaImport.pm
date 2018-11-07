package tsciam::ext::orgareaImport;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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

sub getQuality
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;
   return(1000);
}


sub getImportIDFieldHelp
{
   my $self=shift;

   my $o=getModuleObject($self->getParent->Config,'tsciam::orgarea');
   my $txt='CIAM: ';
   $txt.=$o->getField('toucid')->Label();

   return($txt);
}


sub processImport
{
   my $self=shift;
   my $name=shift;
   my $useAs=shift;
   my $param=shift;

   return(undef) if (!$name);

   my $flt; 
   $useAs='srcid' if (!defined($useAs));

   if ($useAs eq "srcid"){
      if (!($name=~m/^\S{3,10}$/)){
         if (!$param->{quiet}) {
            $self->getParent->LastMsg(ERROR,"invalid tOuCID specified");
         }
         return(undef);
      }
      $flt={toucid=>\$name};
   }

   if (!defined($flt)){
      if (!$param->{quiet}) {
         $self->getParent->LastMsg(ERROR,"no acceptable filter");
      }
      return(undef);
   }

   my @idimp;
   my $ciam=getModuleObject($self->getParent->Config,"tsciam::orgarea");
   my $grp =getModuleObject($self->getParent->Config,"base::grp");

   while($#idimp<20){
      my $chkid;
      $ciam->ResetFilter();
      $ciam->SetFilter($flt);
      my ($ciamrec)=$ciam->getOnlyFirst(qw(ALL));
      if (defined($ciamrec)){
         $grp->ResetFilter();
         $grp->SetFilter({srcid=>\$ciamrec->{toucid},srcsys=>\'CIAM'});
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){ # ok, grp already exists in W5Base
            if (!$param->{quiet}) {
               $self->getParent->LastMsg(
                  INFO,"$ciamrec->{toucid} = $grprec->{fullname}"
               );
            }
            last;
         }
         else{
            msg(INFO,"ciamid $ciamrec->{toucid} not found in W5Base");
            push(@idimp,$ciamrec->{toucid});
         }
         last if ($ciamrec->{parentid} eq "");
         $flt={toucid=>\$ciamrec->{parentid}};
      }
      else{
         if (!$param->{quiet}) {
            $self->getParent->LastMsg(ERROR,"invalid orgid $chkid in tree");
         }
         return(undef);
      }
   }

   my $lastimportedgrpid=undef;
   my $ok=0;
   foreach my $ciamid (reverse(@idimp)){
      $ciam->ResetFilter();
      $ciam->SetFilter({toucid=>\$ciamid});
      my ($ciamrec)=$ciam->getOnlyFirst(qw(ALL));
      if (defined($ciamrec)){
         $grp->ResetFilter();
         if ($ciamrec->{parentid} ne ""){
            $grp->SetFilter({srcid=>\$ciamrec->{parentid},
                             srcsys=>\'CIAM'});
         }
         else{
            $grp->SetFilter({fullname=>\'DTAG'});
         }
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){
            my $newname=$self->findNewValidShortname(
               $grp,
               $grprec->{grpid},
               $ciamrec
            );
            my %newgrp=(name=>$newname,
                        srcsys=>'CIAM',
                        srcid=>$ciamrec->{toucid},
                        parentid=>$grprec->{grpid},
                        cistatusid=>4,
                        srcload=>NowStamp(),
                        comments=>"Description from CIAM: ".
                                  $ciamrec->{name});
            if (my $back=$grp->ValidatedInsertRecord(\%newgrp)){
               $ok++;
               $grp->ResetFilter();
               $grp->SetFilter({grpid=>\$back});
               my ($grprec)=$grp->getOnlyFirst(qw(ALL));
               if ($grprec){
                  if (!$param->{quiet}){
                     $self->getParent->LastMsg(
                        INFO,"$grprec->{srcid} = $grprec->{fullname}"
                     );
                  }
                  $lastimportedgrpid=$grprec->{grpid};
               }

            }
            #printf STDERR ("ciamrec=%s\n",Dumper($ciamrec));
            #printf STDERR ("grprec=%s\n",Dumper($grprec));
            #printf STDERR ("fifi importing $ciamid\n");
         }
         else{
            printf STDERR ("fifi parentid $ciamrec->{parentid} not found\n");
         }
      }
   }
   if ($ok==$#idimp+1){
      return($lastimportedgrpid);
   }
   $self->getParent->LastMsg(ERROR,"one or more operations failed");
   return(undef);
}


sub preFixShortname
{
   my $tOuID=shift;
   my $newname=shift;

   $newname=~s/[\/\s]/_/g;    # rewriting for some shit names
   $newname=~s/&/_u_/g;
   $newname =~ s/ä/ae/g;
   $newname =~ s/ö/oe/g;
   $newname =~ s/ü/ue/g;
   $newname =~ s/Ä/Ae/g;
   $newname =~ s/Ö/Oe/g;
   $newname =~ s/Ü/Ue/g;
   $newname =~ s/ß/sz/g;
   $newname=~s/[^a-z0-9_-]/_/gi;
   if (length($newname)>15){
      $newname=substr($newname,0,15);
   }
   if ($newname eq ""){
      $newname="tOuID_$tOuID";
   }
   return($newname);
}


sub findNewValidShortname
{
   my $self=shift;
   my $grpobj=shift;
   my $pgrpid=shift;
   my $ciamrec=shift;

   my $newname=$ciamrec->{shortname};
   $newname=preFixShortname($ciamrec->{toucid},$newname);
   my $suffix="";
   my $grprec;
   my $loop=1;
   do{
      my $chkname=$newname.$suffix;
      my %chkfld=(name=>\$chkname);
      if (defined($pgrpid)){
         $chkfld{parentid}=\$pgrpid;
      }
      else{
         $chkfld{parentid}=undef;
      }
      $grpobj->ResetFilter();
      $grpobj->SetFilter(\%chkfld);
      ($grprec)=$grpobj->getOnlyFirst(qw(grpid srcsys srcid));
      if (defined($grprec)){
         $suffix=sprintf("-%02d",$loop);
         $loop++;
      }
      else{
         $newname=$chkname;
      }
      if ($loop>99){
         msg(ERROR,"fail to create unique new shortname ".
                   "for tOuCID='$ciamrec->{toucid}'");
         return($newname); # das war wohl nix mit dem eindeutig machen
      }
   }while( defined($grprec) );
   return($newname);
}



1;
