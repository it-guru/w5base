package AL_TCom::QuickFind::AEG;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
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
use kernel::QuickFind;
@ISA=qw(kernel::QuickFind);


sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless({%param},$type);
   return($self);
}

sub ExtendStags
{
   my $self=shift;
   my $stags=shift;
   if ($ENV{REMOTE_USER} ne "anonymous"){
      push(@$stags,"ciaeg","TelekomIT Application Expert Group");
   }
}

sub CISearchResult
{
   my $self=shift;
   my $stag=shift;
   my $tag=shift;
   my $searchtext=shift;
   my %param=@_;

   my @l;
   if (grep(/^ciaeg$/,@$stag)){
      my $flt=[{name=>"*$searchtext*", cistatusid=>"<=5",managed=>1},
              ];
      my $appl=getModuleObject($self->getParent->Config,"AL_TCom::aegmgmt");
      $appl->SetFilter($flt);
      foreach my $rec ($appl->getHashList(qw(name customer))){
         my $dispname=$rec->{name};
         if ($rec->{customer} ne ""){
            $dispname.=' @ '.$rec->{customer};
         }
         push(@l,{group=>"Application Expert Group",
                  id=>$rec->{id},
                  parent=>$self->Self,
                  name=>$dispname});
      }
   }
   return(@l);
}


sub QuickFindDetail
{
   my $self=shift;
   my $id=shift;
   my $htmlresult="?";

   my $appl=getModuleObject($self->getParent->Config,"AL_TCom::appl");
   $appl->SetFilter({id=>\$id});
   my ($rec,$msg)=$appl->getOnlyFirst(qw(applicationexpertgroup
                                         technicalaeg));

   if (defined($rec)){
      $htmlresult=$rec->{applicationexpertgroup};
      if (ref($rec->{technicalaeg}) eq "HASH" &&
          ref($rec->{technicalaeg}->{AEG_email}) eq "ARRAY"){
         my $email=join(";",@{$rec->{technicalaeg}->{AEG_email}});
         $htmlresult.=$self->addDirectLink("mailto:".$email);
      }
   }
   return($htmlresult);
}



1;
