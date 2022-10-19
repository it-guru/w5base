package CRaS::event::CRaSinitialLoad;
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


sub CRaSinitialLoad
{
   my $self=shift;

   $self->{notFoundICTO}={};
   $self->{CertCnt}=0;
   $self->{CertNoRel}=0;

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

   my $csteam=$self->getPersistentModuleObject("cst","CRaS::csteam");
   $csteam->SetFilter({});
   my @l=$csteam->getHashList(qw(id));
   if ($#l==-1){
      $csteam->ValidatedInsertRecord({
          orgarea=>'DTAG.GHQ.VTI.DTIT',
          grp=>'membergroup.ZertifikateDTIT',
          name=>'Cert Service Team TelekomIT'
      });
   }
   

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
                     $val=~s/^lfd\. Nr\.$/SharePointLfdNr/i;
                     $val=trim($val);
                     $val=~s/\s*:$//;
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
         # process record
         foreach my $k (keys(%rec)){
            if ($rec{$k}=~m/^\s*"\s*$/){
               $rec{$k}=$lastrec{$k};
            }
         }
         # record fixups
         if (exists($rec{ICTO}) && ($rec{ICTO}=~m/icto/i)){
            $rec{ICTO}=~s/:.*$//;
            $rec{ICTO}=~s/^ICTO /ICTO-/;
            $rec{ICTO}=~s/-+/-/;
            $rec{ICTO}=~s/^ICTO-ICTO-/ICTO-/;
            $rec{ICTO}=~s/[^0-9a-z]*$//i;
         }
         $rec{ICTO}=trim($rec{ICTO});
         if ($rec{CommonName} ne ""){
            my $aurl=$self->getPersistentModuleObject("aur","itil::lnkapplurl");
            my $hostname=lc($rec{CommonName});
            $aurl->SetFilter({hostname=>\$hostname});
            my @l=$aurl->getHashList(qw(applid));
            if ($#l>=0){
               $rec{applid}=$l[0]->{applid};
            }
         }
         if ($rec{applid} eq "" && $rec{ICTO} ne ""){
            my $appl=$self->getPersistentModuleObject("ap","TS::appl");
            $appl->SetFilter({name=>\$rec{ICTO},cistatusid=>"3 4 5"});
            my @l=$appl->getHashList(qw(opmode id));
            if ($#l>=0){
               $rec{applid}=$l[0]->{id};
            }
            if ($rec{applid} eq ""){
               $appl->ResetFilter();
               $appl->SetFilter({ictono=>\$rec{ICTO},cistatusid=>"3 4 5"});
               my @l=$appl->getHashList(qw(opmode id));
               my $fld=$appl->getField("opmode");
               my @opmodeprio=grep(!/^\s*$/,@{$fld->{value}});
               my %opmodep;
               for(my $c=0;$c<=$#opmodeprio;$c++){
                  $opmodep{$opmodeprio[$c]}=$c+1;
               }
               @l=sort({$opmodep{$a->{opmode}} <=> $opmodep{$b->{opmode}}} @l);
               if ($#l>=0){
                  $rec{applid}=$l[0]->{id};
               }
            }
         }
         if ($rec{csteamid} eq ""){
            my $csteam=$self->getPersistentModuleObject("cst","CRaS::csteam");
            $csteam->SetFilter({});
            my @l=$csteam->getHashList(qw(id));
            if ($#l>=0){
               $rec{csteamid}=$l[0]->{id};
            }
         }

         my $errmsg;
         if ($rec{CommonName} ne ""){
            $self->{CertCnt}++;
            if ($rec{applid} eq ""){
               $self->{CertNoRel}++;
               $self->{notFoundICTO}->{$rec{ICTO}}++;
               #print STDERR Dumper(\%rec);
               #printf STDERR ("CommonName: %s\n", $rec{CommonName});
            }
            my $srcid=$rec{SharePointLfdNr};
            if ($srcid eq ""){
               $srcid=$rec{lfdNr};
            }
            if ($srcid eq ""){
               printf STDERR ("Error Record no srcid: %s\n",Dumper(\%rec));
               die("Error Record no srcid");
            }
            my $csr=$self->getPersistentModuleObject("csr","CRaS::csr");
            my %csrrec=(
               name=>$rec{CommonName},
               sslcertcommon=>$rec{CommonName},
               srcid=>$srcid,
               srcload=>NowStamp("en")
            );
            if ($rec{'Gültig bis'} ne "" &&
                ($rec{'Gültig bis'}=~m/^[0-9]{4}-[0-9]+-[0-9]+$/)){
               $csrrec{ssslenddate}=$rec{'Gültig bis'}." 12:00:00";
            }
            if ($rec{'Ausgestellt am'} ne "" &&
                ($rec{'Ausgestellt am'}=~m/^[0-9]{4}-[0-9]+-[0-9]+$/)){
               $csrrec{ssslstartdate}=$rec{'Ausgestellt am'}." 12:00:00";
            }
            if ($rec{SharePointLfdNr} ne ""){
               $csrrec{comments}.="\n" if ($csrrec{comments} ne "");
               $csrrec{comments}.="SharePoint Laufende-Nummer: ".
                                  "$rec{SharePointLfdNr}";
            }
            if ($rec{applid} eq "" && $rec{ICTO} ne ""){
               $csrrec{comments}.="\n" if ($csrrec{comments} ne "");
               $csrrec{comments}.="Angefordert für $rec{ICTO}";
            }
            if ($rec{Anforderer} ne ""){
               $csrrec{comments}.="\n" if ($csrrec{comments} ne "");
               $csrrec{comments}.="Angefordert durch $rec{Anforderer}";
               if (my ($n1,$n2)=$rec{Anforderer}=~m/^(\S+)\s+(.*)$/){
                  my $u=$self->getPersistentModuleObject("usr","base::user");
                  $u->SetFilter([
                     {
                         surname=>$n1,
                         givenname=>$n2,
                         cistatusid=>"3 4 5"
                     },
                     {
                         surname=>$n2,
                         givenname=>$n1,
                         cistatusid=>"3 4 5"
                     }
                  ]);
                  my @l=$u->getHashList(qw(userid));
                  if ($#l==0){
                     $csrrec{creatorid}=$l[0]->{userid};
                  }
               }
            }

            if ($rec{applid} ne ""){
               $csrrec{applid}=$rec{applid};
            }
            if ($rec{csteamid} ne ""){
               $csrrec{csteamid}=$rec{csteamid};
            }
            $csrrec{state}=1;
            $csrrec{refno}=$rec{Referenznummer};
            if ($csrrec{refno} ne ""){
               $csrrec{state}=4;
            }
            if ($rec{'Ersatz durch  Renewal ID'} ne ""){
               $csrrec{state}=6;
               if ($rec{'Ersatz durch  Renewal ID'}=~m/^[0-9]+$/){
                  $csrrec{replacedrefno}=$rec{'Ersatz durch  Renewal ID'}; 
               }
            }
            if ($rec{'Seriennummer (hex)'} ne ""){
               $csrrec{ssslserialno}=$rec{'Seriennummer (hex)'};
            }
            if ($rec{'Service-Passwort'} ne ""){
               $csrrec{spassword}=$rec{'Service-Passwort'};
            }
            #ensure passwords are not loaded in development phase
            #$csrrec{spassword}=~s/./*/g;

            if ((my ($d,$m,$y)=$rec{'Ausgestellt am'}
                =~m/^\s*([0-9]+)\.([0-9]+)\.([0-9]+)\s*$/)){
               $csrrec{ssslstartdate}=sprintf("%04d-%02d-%02d 12:00:00",
                                              $y,$m,$d);
            }
            if ((my ($d,$m,$y)=$rec{'Gültig bis'}
                =~m/^\s*([0-9]+)\.([0-9]+)\.([0-9]+)\s*$/)){
               $csrrec{ssslenddate}=sprintf("%04d-%02d-%02d 12:00:00",
                                              $y,$m,$d);
            }

            if (1 || $rec{applid} ne ""){
               $csr->ValidatedInsertOrUpdateRecord(\%csrrec,{
                  srcid=>\$srcid
               });
            }
         }


         %lastrec=(%rec);  # store last line
      }
   }
   {
      my $csr=$self->getPersistentModuleObject("csr","CRaS::csr");
      $csr->BulkDeleteRecord({'srcload'=>"<'$start'"});
   }


   #print "\nEmployee=".Dumper(\%employee)."\n";
   #print "\nProjectname=".Dumper(\%projectname)."\n";
   #printf("MissICTO: %s\n",join(", ",sort(keys(%{$self->{notFoundICTO}}))));
   #printf("cnt/fail  %d/%d\n",$self->{CertCnt},$self->{CertNoRel});
}



sub loadRemoteFile
{
   my $self=shift;
   my $fh=shift;

   my $dataobjconnect=$self->Config->Param("DATAOBJCONNECT");
   my $dataobjuser=$self->Config->Param("DATAOBJUSER");
   my $dataobjpass=$self->Config->Param("DATAOBJPASS");

   my $url=$dataobjconnect->{CRaSinitialLoad};
   my $user=$dataobjuser->{CRaSinitialLoad};
   my $pass=$dataobjpass->{CRaSinitialLoad};
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
      #printf STDERR ("OK\n");
   }
   else{
     printf("%s\n",$resp->status_line());
   }
}




