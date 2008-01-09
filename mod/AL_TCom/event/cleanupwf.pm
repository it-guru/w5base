package AL_TCom::event::cleanupwf;
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
use kernel::date;
use kernel::Event;
use kernel::database;
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


   $self->RegisterEvent("cleanupwf","cleanupwf");
   return(1);
}

sub cleanupwf
{
   my $self=shift;
   my $wf=getModuleObject($self->Config,"base::workflow");
   my $wfchk=getModuleObject($self->Config,"base::workflow");

   my $db=new kernel::database($self->getParent,"w5base");
   if (!$db->Connect()){
      return({exitcode=>1,msg=>msg(ERROR,"failed to connect database")});
   }
   my $cmd="select wfheadid,srcsys,srcid from wfhead";
   if (!$db->execute($cmd)){
      return({exitcode=>2,msg=>msg(ERROR,"can't execute '%s'",$cmd)});
   }


   while(my ($rec,$msg)=$db->fetchrow()){
      last if (!defined($rec));
      if ($rec->{srcid} ne "" && $rec->{srcsys} ne ""){
         printf("Process srcid=%s srcsys=%s\n",$rec->{srcid},$rec->{srcsys});
         $wfchk->ResetFilter();
         $wfchk->SetFilter({srcsys=>\$rec->{srcsys},srcid=>\$rec->{srcid}});
         my @l=map({$_->{id}} $wfchk->getHashList(qw(id)));
         msg(INFO,"found idlist(%s)=%s",$rec->{srcid},join(",",@l));
         if ($#l>0){
            my $minid=undef;
            foreach my $chkid (@l){
               $minid=$chkid if (!defined($minid) || $minid>$chkid);
            }
           
            foreach my $delid (@l){
               next if ($delid==$minid);
               msg(INFO,"srcid=$rec->{srcid} srcsys=$rec->{srcsys} DEL:$delid");
               $wf->ResetFilter();
               $wf->SetFilter({id=>\$delid});
               $wf->ForeachFilteredRecord(sub{
                   $wf->ValidatedDeleteRecord($_);
               });

            }
            
         }
      }
   }
   return({exitcode=>0});
}

1;
