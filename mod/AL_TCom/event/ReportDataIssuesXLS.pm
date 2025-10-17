package AL_TCom::event::ReportDataIssuesXLS;
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
use kernel::Event;
use kernel::XLSReport;

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


   $self->RegisterEvent("ReportDataIssuesXLS","ReportDataIssuesXLS");
   return(1);
}

sub ReportDataIssuesXLS
{
   my $self=shift;
   my %param=@_;
   my %flt;
   my @userid=qw(-1);
   $ENV{LANG}="de";
   msg(DEBUG,"param=%s",Dumper(\%param));
   if ($param{grp} ne ""){
      my $user=getModuleObject($self->Config,"base::user");
      my $grp=$param{grp};
      $grp=~s/[\*\?]//;
      $grp=~s/\.$//;
      $user->SetFilter({groups=>"$grp $grp.*"});
      foreach my $urec ($user->getHashList(qw(userid))){
         push(@userid,$urec->{userid});
      }
   }
   else{
      msg(DEBUG,"no grp restriction");
   }


   if ($param{'filename'} eq ""){
      $param{'filename'}="/tmp/ReportDataIssues.xls";
   }
   msg(INFO,"start Report to $param{'filename'}");
   my $t0=time();
 
   $flt{'class'}=\'base::workflow::DataIssue';
   $flt{'stateid'}='<15';
   $flt{'fwdtarget'}=\'base::user';
   $flt{'fwdtargetid'}=\@userid;

   my $out=new kernel::XLSReport($self,$param{'filename'});
   $out->initWorkbook();


   my @control=({DataObj=>'base::workflow',
                 filter=>\%flt,
                 view=>[qw(name fwdtargetname 
                                wffields.dataissueobjectname 
                                wffields.affectedobject
                           detaildescription createdate id)]},
                );
   $out->Process(@control);
   my $trep=time()-$t0;
   msg(INFO,"end Report to $param{'filename'} ($trep sec)");



#   $self->{workbook}=$self->XLSopenWorkbook();
#   if (!($self->{workbook}=$self->XLSopenWorkbook())){
#      return({exitcode=>1,msg=>'fail to create tempoary workbook'});
#   }


   return({exitcode=>0,msg=>'OK'});
}





1;
