package AL_TCom::event::mkitscm;
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
use kernel::Output;
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
   $self->RegisterEvent("mkitscm","mkitscm");
   return(1);
}

sub mkitscm
{
   my $self=shift;
   my %param=@_;
   my $tmpfile="/tmp/appl-handbook.$$.pdf";
   my $filename="handbook.pdf";
   my $wf=getModuleObject($self->Config,"itil::appl");
   $wf->ResetFilter();
   $wf->SetFilter(businessteam=>'DTAG.TSI.Prod.CSS.AO.DTAG*',
                  cistatusid=>'4',customerprio=>'1');
   $wf->SetCurrentView(qw(name conumber cistatus sem tsmphone 
                          tsmmobile ldelmgr delmgr customer 
                          customerprio criticality oncallphones 
                          interfaces systems systemnames systemids));
   $wf->SetCurrentOrder("NONE");
   my $output=new kernel::Output($wf);
   $output->setFormat("PdfV01");
   my $page=$output->WriteToScalar(HttpHeader=>0);
   msg(INFO,"page ready");
   if (open(F,">$tmpfile")){
      print F $page;
      close(F);
      if (open(F,"<$tmpfile")){
         msg(INFO,"tempfile is open for read");
         my $dir="ITSCM/Daten/auto_create";
         my $file=getModuleObject($self->Config,"base::filemgmt");
         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
                                               parent=>$dir,
                                               file=>\*F},
                                              {name=>\$filename,
                                               parent=>\$dir});
         close(F);
      }
      else{
         msg(ERROR,"unexpected problem while opening tempfile");
      }
   }else{
      msg(ERROR,"can't open $tmpfile");
   }
   unlink("$tmpfile");
   msg(DEBUG,"remove $tmpfile");
}

1;
