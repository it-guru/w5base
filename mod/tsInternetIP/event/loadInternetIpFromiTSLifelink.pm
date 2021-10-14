package tsInternetIP::event::loadInternetIpFromiTSLifelink;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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
use File::Temp;
use LWP::UserAgent;
use MIME::Base64;
use Spreadsheet::ParseExcel;

@ISA=qw(kernel::Event);



sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   return($self);
}


sub loadInternetIpFromiTSLifelink
{
   my $self=shift;

   my ($fh,$filename)=File::Temp::tempfile('tempXXXXX',SUFFIX =>'.xls',
                                           TMPDIR=>1);

   $self->loadRemoteFile($fh);

   $self->ProcessXLS($filename);

   unlink($filename);
   return({exitcode=>0});
}

sub ProcessXLS
{
   my $self=shift;
   my $filename=shift;

   my $parser=Spreadsheet::ParseExcel->new();
   my $workbook=$parser->parse($filename);

   if (!defined($workbook)){
       die($parser->error(),".\n");
   }
   my $cnt=0;
   for my $worksheet ($workbook->worksheets()){
      my ($row_min,$row_max)=$worksheet->row_range();
      my ($col_min,$col_max)=$worksheet->col_range();
      for(my $row=$row_min;$row<=$row_max;$row++){
         for(my $col=$col_min;$col<=$col_max;$col++){
            my $cell=$worksheet->{'Cells'}[$row][$col];
            if (defined($cell)){
               my $val=$cell->Value();
               if ($val ne ""){
                  $cnt++;
                  printf STDERR ("%08d : wb(%s) %s/%s = %s\n",$cnt,
                                 $worksheet->get_name(),$row,$col,$val);
               }
            }
         }
      }
   }
}



sub loadRemoteFile
{
   my $self=shift;
   my $fh=shift;

   my $dataobjconnect=$self->Config->Param("DATAOBJCONNECT");
   my $dataobjuser=$self->Config->Param("DATAOBJUSER");
   my $dataobjpass=$self->Config->Param("DATAOBJPASS");

   my $url=$dataobjconnect->{tsInternetIP};
   my $user=$dataobjuser->{tsInternetIP};
   my $pass=$dataobjpass->{tsInternetIP};
   if ($url eq "" || $user eq "" || $pass eq ""){
      printf STDERR ("URL: %s\n",$url);
      printf STDERR ("User: %s   -  Pass: %s\n",$user,$pass);
   }
   my $ua=LWP::UserAgent->new();

   my $resp=$ua->get($url,
     "Authorization" => "Basic ".MIME::Base64::encode($user.':'.$pass,'')
   );
   if ($resp->is_success()){
      print $fh $resp->decoded_content();
      seek($fh,0,0);
      printf STDERR ("OK\n");
   }
   else{
     printf("%s\n",$resp->status_line());
   }
}




