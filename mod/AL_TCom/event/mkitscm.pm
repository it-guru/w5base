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
   my $wf=getModuleObject($self->Config,"itil::appl");
   $wf->ResetFilter();
   $wf->SetFilter(id=>'12121501640002');
   $wf->SetCurrentView(qw(name conumber cistatus sem tsmphone tsmmobile ldelmgr delmgr customer customerprio criticality oncallphones interfaces systems systemnames systemids));
   $wf->SetCurrentOrder("NONE");
   my $output=new kernel::Output($wf);
   $output->setFormat("PdfV01");
   my $page=$output->WriteToScalar(HttpHeader=>0);
   if (open(F,">/tmp/x.pdf")){
      print F $page;
      close(F);
   }
}

sub xlsFinish
{
   my $self=shift;
   my $xlsexp=shift;
   my $repmon=shift;

#   if (defined($xlsexp->{xls}) && $xlsexp->{xls}->{state} eq "ok"){
#      $xlsexp->{xls}->{workbook}->close(); 
#      my $file=getModuleObject($self->Config,"base::filemgmt");
#      $repmon=~s/\//./g;
#      my $filename=$repmon.".xls";
#      if (open(F,"<".$xlsexp->{xls}->{filename})){
#         my $dir="TSI-Connect/Konzernstandard-Sonderleistungen";
#         $file->ValidatedInsertOrUpdateRecord({name=>$filename,
#                                               parent=>$dir,
#                                               file=>\*F},
#                                              {name=>\$filename,
#                                               parent=>\$dir});
#      }
#      else{
#         msg(ERROR,"can't open $xlsexp->{xls}->{filename}");
#      }
#   }
}


1;
