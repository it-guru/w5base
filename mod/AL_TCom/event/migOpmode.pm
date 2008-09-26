package AL_TCom::event::migOpmode;
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

@ISA=qw(kernel::Event);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}

sub Init
{
   my $self=shift;


   $self->RegisterEvent("migopmode","MigOpmode");
   return(1);
}


sub MigOpmode
{
   my $self=shift;
   my @appid=@_;

   my $applsys=getModuleObject($self->Config,"itil::lnkapplsystem");
   my $app=getModuleObject($self->Config,"itil::appl");
   my $opapp=getModuleObject($self->Config,"itil::appl");
   my %filter;
   my %w52ac=(0 =>'',
              5 =>'',
              10=>'license',
              20=>'test',
              30=>'education',
              40=>'reference',
              50=>'approvtest',
              60=>'devel',
              70=>'prod');
  # $filter{name}="*w5base*";
   $app->SetFilter(\%filter);
   $app->SetCurrentView(qw(ALL));
  
   my ($rec,$msg)=$app->getFirst();
   $self->{jobstart}=NowStamp();
   my %grpnotfound;
   if (defined($rec)){
      do{
         $applsys->ResetFilter();
         $applsys->SetFilter({applid=>\$rec->{id},
                              systemcistatusid=>\"4"});
         my @l=$applsys->getHashList(qw(id systemsystemid system
                                        istest iseducation isref 
                                        isapprovtest isdevel isprod
                                        shortdesc systemid));
         my $ApplU=0;
         foreach my $lnk (@l){
            my $SysU=0;
            $SysU=20 if ($SysU<20 && $lnk->{istest}); 
            $SysU=30 if ($SysU<30 && $lnk->{iseducation}); 
            $SysU=40 if ($SysU<40 && $lnk->{isref}); 
            $SysU=50 if ($SysU<50 && $lnk->{isapprovtest}); 
            $SysU=60 if ($SysU<60 && $lnk->{isdevel}); 
            $SysU=70 if ($SysU<70 && $lnk->{isprod}); 
            $ApplU=$SysU if ($ApplU<$SysU);
         }
         msg(INFO,"application USAGE=$w52ac{$ApplU}\n");
         $opapp->UpdateRecord({opmode=>$w52ac{$ApplU}},{id=>\$rec->{id}});

         ($rec,$msg)=$app->getNext();
      } until(!defined($rec));
   }
   return({exitcode=>0});
}

1;
