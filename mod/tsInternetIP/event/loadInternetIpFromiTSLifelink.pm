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


sub applyMap
{
   my $map=shift;
   my $var=shift;

   my @map=@{$map};

   while(my $exp=shift(@map)){
      my $rep=shift(@map);
      $$var=~s/$exp/$rep/i;
   }
   

}


sub loadInternetIpFromiTSLifelink
{
   my $self=shift;

   $self->{employeeMap}=[
      '^.*young.*$'        , 'A. Young',
      '^y$'                , 'A. Young',
      '^.*schneider.*$'    , 'A. Schneider',
      '^.*gutsche.*$'      , 'K. Gutsche',
      '^.*nosal.*$'        , 'M. Nosal',
      '^.*kyjovsk.*$'      , 'M. Kyjovsky',
      '^.*hudak.*$'        , 'J. Hudak',
      '^.*hybenova.*$'     , 'K. Hybenova',
      '^.*belej.*$'        , 'L. Belejkanic',
      '^.*olsavska.*$'     , 'E. Olsavska',
      '^.*bujnak.*$'       , 'P. Bujnak',
      '^.*Gocik.*$'        , 'P. Gocik',
      '^.*Hornak.*$'       , 'P. Hornak',
      '^.*m.*kovac.*$'     , 'M. Kovac',
      '^.*kuch.*$'         , 'V. Kuchanuk',
      '^.*seman.*$'        , 'R. Seman',
      '^.*r.*petrus.*$'    , 'R. Petrus',
      '^.*s.*kristof.*$'   , 'S. Kristof',
      '^.*a.*gradov.*$'    , 'A. Gradov',
      '^.*c.*jansen.*$'    , 'C. Jansen',
      '^.*s.*zelenak.*$'   , 'S. Zelenak',
      '^.*k.*kleinova.*$'  , 'K. Kleinova',
      '^.*m.*puchlak.*$'   , 'M. Puchlak',
      '^.*m.*simonak.*$'   , 'M. Simonak',
      '^[a-z]\.\s*'        , '',
   ];

   

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
   my $start=NowStamp("en");
   my $cnt=0;
   my %fullindex;
   my @colname=();
   my %rec;
   my %lastrec;
   my %employee;
   my %projectname;
   for my $worksheet (reverse($workbook->worksheets())){
      my $worksheetname=$worksheet->get_name();
      next if ($worksheetname=~m/overview/i); # skip Overview Page
      next if ($worksheetname=~m/peers/i); # skip "peers updated" Page

      next if ($worksheetname=~m/DO NOT USE!/); # keine Ahnung was das 
              # da für Einträge drin sind - es führt zu doppelten Einträgen

      next if ($worksheetname=~m/^IAA2_/); # scheint was mit der IAA zu tun
              # zu haben - jedenfalls din u.a. IAA2_MGB-BI und IAA2_Munich
              # doppeltet Nennungen (z.B. 10.21.10.4)

      next if ($worksheetname=~m/^IPv4 /); # Das scheinen irgendwelche 
              # Definitionen für NAT oder DMZen zu sein

      next if ($worksheetname=~m/^VDOM /); # Scheint auch was zu sein,
              # was mit NAT oder DMZ Definitionen oder Mappings zu tun hat.



      my ($row_min,$row_max)=$worksheet->row_range();
      my ($col_min,$col_max)=$worksheet->col_range();
      for(my $row=$row_min;$row<=$row_max;$row++){
         if ($row==0){
            @colname=(); 
            %lastrec=();
         }
         %rec=();
         for(my $col=$col_min;$col<=$col_max;$col++){
            my $cell=$worksheet->{'Cells'}[$row][$col];
            if (defined($cell)){
               my $val=trim($cell->Value());
               if ($val ne ""){
                  if ($row==0){  # fixups for header line
                     $val=~s/^\s*ip address\s*$/ipaddr/i;
                     $val=~s/^\s*subnet\s*$/subnet/i;
                     $val=~s/^\s*datacenter\s*$/datacenter/i;
                     $val=~s/^\s*datacenter\s*$/datacenter/i;
                     $val=~s/^\s*employee\s*$/employee/i;
                     $val=~s/^\s*do\s+number\s*$/donumber/i;
                     $val=~s/^\s*co\s+number\s*$/conumber/i;
                     $val=~s/^\s*project\s+name\s*$/projectname/i;
                     $val=~s/^\s*comment\s*$/comment/i;
                     $val=~s/^\s*netflow\s*$/netflow/i;
                     $colname[$col]=$val;
                  }
                  else{
                     if ($colname[$col] ne ""){
                        $rec{$colname[$col]}=$val; 
                     }
                  }
                  $cnt++;
#if ($row==0 && $col==0){
#                  printf STDERR ("%08d : wb(%s) %s/%s = %s\n",$cnt,
#                                 $worksheet->get_name(),$row,$col,$val);
#}
               }
            }
         }
         $rec{xlsrow}=$row+1;
         $rec{xlssheet}=$worksheet->get_name();
         # record fixups
         if ($rec{ipaddr} ne ""){
            if ($rec{route} ne ""){
               $rec{route}=~s/\s*//g;
               if (my ($netbits)=$rec{route}=~m#/([0-9]{1,2})[^0-9]#){
                  $rec{netbits}=$netbits;
               }
               $rec{ishost}=0; 
               $rec{isnet}=1; 
            }
            else{
               $rec{netbits}=4*8;
               $rec{ishost}=1; 
               $rec{isnet}=0; 
            }
            $rec{ipnetwork}=$rec{ipaddr}."/".$rec{netbits};
         }
         if ($rec{subnet} ne ""){
            $rec{subnet}=~s/\s*//g;
            if (my ($ipaddr,$netbits)=$rec{subnet}=~m/^(.*)\/([0-9]{1,2})$/){
               $rec{ipnetwork}=$rec{subnet};
               $rec{ipaddr}=$ipaddr;
               $rec{netbits}=$netbits;
               if ($netbits<32){
                  $rec{isnet}=1;
                  $rec{ishost}=0;
               }
               else{
                  $rec{isnet}=1;
                  $rec{ishost}=0;
               }
            }
         }

         # process record
         foreach my $k (keys(%rec)){
            if ($rec{$k}=~m/^\s*"\s*$/){
               $rec{$k}=$lastrec{$k};
            }
         }

         applyMap($self->{employeeMap},\$rec{employee});
         if ($rec{employee} ne ""){
            $employee{$rec{employee}}++;
         }
         if ($rec{projectname} ne ""){
            $projectname{$rec{projectname}}++;
         }
         my $errmsg;
         if (length($rec{ipaddr})>4 && $rec{netbits}>=8 && $rec{netbits}<=128){
            my $srcid=$rec{ipaddr}."-".$rec{netbits};
            my $sheetref=$rec{xlssheet}.": row ".$rec{xlsrow};
            if (!exists($fullindex{$rec{ipaddr}})){
               $fullindex{$rec{ipaddr}}=$sheetref;
               my $ipnet=$self->getPersistentModuleObject("w5ip","itil::ipnet");
               my $type=$ipnet->IPValidate($rec{ipaddr},\$errmsg);
               if ($type ne ""){
                  $rec{description}="AYoungXLS:\n".
                                    "Sheet:".$rec{xlssheet}."\n".
                                    "Row:".$rec{xlsrow}."\n";
                  $ipnet->ValidatedInsertOrUpdateRecord({ 
                     name=>$rec{ipaddr},
                     label=>$rec{ipaddr}." - NetBits".$rec{netbits},
                     netmask=>"/".$rec{netbits},
                     description=>$rec{description},
                     network=>"Internet",
                     cistatusid=>'4',
                     srcload=>NowStamp("en"),
                     srcid=>$srcid,
                     srcsys=>'AlenYoungList'
                  },{srcsys=>'AlenYoungList',srcid=>$srcid});
                  if ($ipnet->LastMsg()){
                     print STDERR "rec=".Dumper(\%rec);
                     $ipnet->LastMsg("");
                  }
               }
            }
            else{
               printf("DUP: %s and %s\n",$fullindex{$rec{ipaddr}},$sheetref);
               #print STDERR "rec=".Dumper(\%rec);
            }
         }



         %lastrec=(%rec);  # store last line
      }
   }
   {
      my $ipnet=$self->getPersistentModuleObject("w5ip","itil::ipnet");
      $ipnet->BulkDeleteRecord({'srcload'=>"<$start",
                             'srcsys'=>\'AlenYoungList'});
   }


   #print "\nEmployee=".Dumper(\%employee)."\n";
   #print "\nProjectname=".Dumper(\%projectname)."\n";
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




