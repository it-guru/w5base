package w5v1inv::event::loaddoc;
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
use Data::Dumper;
use kernel;
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


   $self->RegisterEvent("loaddoc","LoadDoc"); 
   return(1);
}

sub LoadDoc
{
   my $self=shift;
   my $from=shift;
   my $to=$self->Config->getCurrentConfigName();
   my $doc=$self->Config->Param("W5DOCDIR");
   my $filemgmt=getModuleObject($self->Config,"base::filemgmt");
   msg(DEBUG,"docdir=%s",$doc);
   msg(DEBUG,"from  =%s",$from);
   msg(DEBUG,"to    =%s",$to);
   if (!chdir("$doc/$from")){
      msg(ERROR,"can't change working dir to '%s'","$doc/$from");
      return({exitcode=>1});
   }
   my @dir=glob('*/*');
   foreach my $dir (@dir){
      my ($mod,$id)=$dir=~m/^(\S+)\/(\d+)$/;
      next if (!defined($mod) || !defined($id));
      $id=int($id);
  #    next if (!($id==1 && $mod eq "bcapp"));
      msg(DEBUG,"process=%s",$dir);
     
      my @files=glob($dir.'/*');
      if ($mod eq "bcapp"){
         msg(DEBUG,"module=$mod id=$id");
         my $p=$self->getPersistentModuleObject("W5BaseAppl","itil::appl");
         $p->ResetFilter();
         $p->SetFilter({id=>\$id});
         my ($rec,$msg)=$p->getOnlyFirst(qw(id));
         if (defined($rec)){
            $filemgmt->SetFilter(parentobj=>\"itil::appl",
                                 parentrefid=>\$id);
            $filemgmt->SetCurrentView(qw(ALL));
            $filemgmt->ForeachFilteredRecord(sub{
                $filemgmt->ValidatedDeleteRecord($_);
            });
            foreach my $file (@files){
               if (open(F,"<".$file)){
                  msg(DEBUG,"open %s",$file);
                  $filemgmt->ValidatedInsertRecord({name=>$file,
                                                    file=>\*F,
                                                    parentobj=>'itil::appl',
                                                    parentrefid=>$id});


                  close(F);
               }
            }
         }
      }
      if ($mod eq "bchw"){
         msg(DEBUG,"module=$mod id=$id");
         my $p=$self->getPersistentModuleObject("W5BaseAppl","itil::system");
         $p->ResetFilter();
         $p->SetFilter({id=>\$id});
         my ($rec,$msg)=$p->getOnlyFirst(qw(id));
         if (defined($rec)){
            $filemgmt->SetFilter(parentobj=>\"itil::system",
                                 parentrefid=>\$id);
            $filemgmt->SetCurrentView(qw(ALL));
            $filemgmt->ForeachFilteredRecord(sub{
                $filemgmt->ValidatedDeleteRecord($_);
            });
            foreach my $file (@files){
               if (open(F,"<".$file)){
                  msg(DEBUG,"open %s",$file);
                  $filemgmt->ValidatedInsertRecord({name=>$file,
                                                    file=>\*F,
                                                    parentobj=>'itil::system',
                                                    parentrefid=>$id});
                  close(F);
               }
            }
         }
      }
      
   }
}
1;
