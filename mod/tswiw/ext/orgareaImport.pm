package tswiw::ext::orgareaImport;
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
   return(2000);
}


sub getImportIDFieldHelp
{
   my $self=shift;

   my $o=getModuleObject($self->getParent->Config,'tswiw::orgarea');
   my $txt='WhoIsWho: ';
   $txt.=$o->getField('touid')->Label();

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
            $self->getParent->LastMsg(ERROR,"invalid tOuID specified");
         }
         return(undef);
      }
      $flt={touid=>\$name};
   }

   if (!defined($flt)){
      if (!$param->{quiet}) {
         $self->getParent->LastMsg(ERROR,"no acceptable filter");
      }
      return(undef);
   }

   my @idimp;
   my $wiw=getModuleObject($self->getParent->Config,"tswiw::orgarea");
   my $grp=getModuleObject($self->getParent->Config,"base::grp");

   while($#idimp<20){
      my $chkid;
      $wiw->ResetFilter();
      $wiw->SetFilter($flt);
      my ($wiwrec)=$wiw->getOnlyFirst(qw(ALL));
      if (defined($wiwrec)){
         $grp->ResetFilter();
         $grp->SetFilter({srcid=>\$wiwrec->{touid},srcsys=>\'WhoIsWho'});
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){ # ok, grp already exists in W5Base
            if (!$param->{quiet}) {
               $self->getParent->LastMsg(
                  INFO,"$wiwrec->{touid} = $grprec->{fullname}"
               );
            }
            last;
         }
         else{
            msg(INFO,"wiwid $wiwrec->{touid} not found in W5Base");
            push(@idimp,$wiwrec->{touid});
         }
         last if ($wiwrec->{parentid} eq "");
         $flt={touid=>\$wiwrec->{parentid}};
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
   foreach my $wiwid (reverse(@idimp)){
      $wiw->ResetFilter();
      $wiw->SetFilter({touid=>\$wiwid});
      my ($wiwrec)=$wiw->getOnlyFirst(qw(ALL));
      if (defined($wiwrec)){
         $grp->ResetFilter();
         if ($wiwrec->{parentid} ne ""){
            $grp->SetFilter({srcid=>\$wiwrec->{parentid},
                             srcsys=>\'WhoIsWho'});
         }
         else{
            $grp->SetFilter({fullname=>\'DTAG.TSI'});
         }
         my ($grprec)=$grp->getOnlyFirst(qw(ALL));
         if (defined($grprec)){

            my $newname=$wiwrec->{shortname};
            if ($newname eq ""){
               $self->getParent->LastMsg(ERROR,"no shortname for ".
                                               "id '$wiwrec->{touid}' found");
               return(undef);
            }
            $newname=~s/[\/\s]/_/g;    # rewriting for some shit names
            $newname=~s/&/_u_/g;
            my %newgrp=(name=>$newname,
                        srcsys=>'WhoIsWho',
                        srcid=>$wiwrec->{touid},
                        parentid=>$grprec->{grpid},
                        cistatusid=>4,
                        srcload=>NowStamp(),
                        comments=>"Description from WhoIsWho: ".
                                  $wiwrec->{name});
            if (my $back=$grp->ValidatedInsertRecord(\%newgrp)){
               $ok++;
               msg(DEBUG,"ValidatedInsertRecord returned=$back");
               $grp->ResetFilter();
               $grp->SetFilter({grpid=>\$back});
               my ($grprec)=$grp->getOnlyFirst(qw(ALL));
               if ($grprec){
                  $self->getParent->LastMsg(INFO,
                            "$grprec->{srcid} = $grprec->{fullname}");
               }
            }
         }
         else{
            printf STDERR ("fifi parentid $wiwrec->{parentid} not found\n");
         }
      }
   }
   if ($ok==$#idimp+1){
      return(1);
   }
   $self->getParent->LastMsg(ERROR,"one or more operations failed");
   return(undef);

}



1;
