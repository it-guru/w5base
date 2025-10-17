package caiman::ext::orgareaImport;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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

   my $o=getModuleObject($self->getParent->Config,'caiman::orgarea');
   my $txt='CAIMAN: ';
   $txt.=$o->getField('torgoid')->Label();

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
      if (!($name=~m/^[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$/)){
         if (!$param->{quiet}) {
            $self->getParent->LastMsg(ERROR,"invalid tOrgOID specified");
         }
         return(undef);
      }
      $flt={torgoid=>\$name};
   }

   if (!defined($flt)){
      if (!$param->{quiet}) {
         $self->getParent->LastMsg(ERROR,"no acceptable filter");
      }
      return(undef);
   }

   my @idimp;
   my $caiman=getModuleObject($self->getParent->Config,"caiman::orgarea");
   my $grp =getModuleObject($self->getParent->Config,"base::grp");

   while($#idimp<20){
      my $chkid;
      $caiman->ResetFilter();
      $caiman->SetFilter($flt);
      my ($caimanrec)=$caiman->getOnlyFirst(qw(ALL));
      if (defined($caimanrec)){
         $grp->ResetFilter();
         $grp->SetFilter({srcid=>\$caimanrec->{torgoid},srcsys=>\'CAIMAN'});
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){ # ok, grp already exists in W5Base
            if (!$param->{quiet}) {
               $self->getParent->LastMsg(
                  INFO,"$caimanrec->{torgoid} = $grprec->{fullname}"
               );
            }
            last;
         }
         else{
            msg(INFO,"caimanid $caimanrec->{torgoid} not found in W5Base");
            push(@idimp,$caimanrec->{torgoid});
         }
         last if ($caimanrec->{parentid} eq "");
         $flt={torgoid=>\$caimanrec->{parentid}};
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
   foreach my $caimanid (reverse(@idimp)){
      $caiman->ResetFilter();
      $caiman->SetFilter({torgoid=>\$caimanid});
      my ($caimanrec)=$caiman->getOnlyFirst(qw(ALL));
      if (defined($caimanrec)){
         $grp->ResetFilter();
         if ($caimanrec->{parentid} ne ""){
            $grp->SetFilter({srcid=>\$caimanrec->{parentid},
                             srcsys=>\'CAIMAN'});
         }
         else{
            $grp->SetFilter({fullname=>\'EC',parentid=>\undef});
            my ($grprec)=$grp->getOnlyFirst(qw(ALL));
            if (!defined($grprec)){
               if (my $back=$grp->ValidatedInsertRecord({
                              name=>"EC",
                              description=>'DTAG Employee Central',
                              srcsys=>'CAIMAN',
                              srcid=>'00000000-0000-0000-0000-000000000000',
                              cistatusid=>4,
                              srcload=>NowStamp(),
                              comments=>'Root Record for CAIMAN OrgTree'
                            })){
                  msg(INFO,"EC Rec created");
               }
            }
            $grp->ResetFilter();
            $grp->SetFilter({fullname=>\'EC',parentid=>\undef});
         }



         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){
            my $newname=$self->findNewValidShortname(
               $grp,
               $grprec->{grpid},
               $caimanrec
            );
            my %newgrp=(name=>$newname,
                        srcsys=>'CAIMAN',
                        srcid=>$caimanrec->{torgoid},
                        parentid=>$grprec->{grpid},
                        cistatusid=>4,
                        srcload=>NowStamp(),
                        comments=>"Description from CAIMAN: ".
                                  $caimanrec->{name});
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
            #printf STDERR ("caimanrec=%s\n",Dumper($caimanrec));
            #printf STDERR ("grprec=%s\n",Dumper($grprec));
            #printf STDERR ("fifi importing $caimanid\n");
         }
         else{
            printf STDERR ("fifi parentid $caimanrec->{parentid} not found\n");
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
   my $ciamrec=shift;
   my $newname=shift;
   my $tOuID=$ciamrec->{torgoid};

   msg(INFO,"preFixShortname:".Dumper($ciamrec));

   if (lc($newname) eq lc("Deutsche Telekom IT GmbH")){
      $newname="DTIT";
   }
   if (lc($newname) eq lc("Deutsche Telekom AG")){
      $newname="DTAG";
   }
   if (lc($newname) eq lc("T-Systems International GmbH")){
      $newname="TSI";
   }
   if (lc($newname) eq lc("DT Security")){
      $newname="DT-Sec";
   }
   if (lc($newname) eq lc("Deutsche Telekom Technik GmbH")){
      $newname="DTT";
   }
   if (lc($newname) eq lc("Deutsche Telekom Service GmbH")){
      $newname="DTS";
   }
   if (lc($newname) eq lc("Deutsche Telekom Außendienst GmbH")){
      $newname="DTA";
   }
   if (lc($newname) eq lc("Deutsche Telekom MMS GmbH")){
      $newname="MMS";
   }
   if (lc($newname) eq lc("DT Geschäftskunden GmbH")){
      $newname="DT-GKS";
   }
   if (lc($newname) eq lc("DT Individual Solutions & Products GmbH")){
      $newname="DT-ISP";
   }
   if (lc($newname) eq lc("operational services GmbH & Co. KG")){
      $newname="OS";
   }
   if (lc($newname) eq lc("T-Systems IFS GmbH")){
      $newname="TSIFS";
   }
   if (lc($newname) eq lc("T-Systems Road User Services GmbH")){
      $newname="TSRUS";
   }
   $newname=~s/^DT IT&/DTIT_/i;
   $newname=~s/^Telekom IT\s/TelIT /i;
   $newname=~s/\sHungary/ HU/i;
   $newname=~s/\sSlovakia/ SK/i;
   $newname=~s/\s+GmbH//i;

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
      $newname="OID_$tOuID";
      $newname=~s/-//g;
      $newname=substr($newname,0,15);
   }
   return($newname);
}


sub findNewValidShortname
{
   my $self=shift;
   my $grpobj=shift;
   my $pgrpid=shift;
   my $caimanrec=shift;

   my $newname=$caimanrec->{shortname};
   $newname=preFixShortname($caimanrec,$newname);
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
                   "for tOrgOID='$caimanrec->{torgoid}'");
         return($newname); # das war wohl nix mit dem eindeutig machen
      }
   }while( defined($grprec) );
   return($newname);
}



1;
