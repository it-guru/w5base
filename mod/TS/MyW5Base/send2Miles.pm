package TS::MyW5Base::send2Miles;
#  W5Base Framework
#  Copyright (C) 2011  Hartmut Vogler (it@guru.de)
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
use vars qw(@ISA $debug);
use kernel;
use kernel::MyW5Base;
use kernel::printFlushed;
@ISA=qw(kernel::MyW5Base kernel::printFlushed);

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
   return(1);
}

sub isSelectable
{
   my $self=shift;

   my $acl=$self->getParent->getMenuAcl($ENV{REMOTE_USER},
                          'TS::MyW5Base::send2Miles$',
                          func=>'Main');

   if (defined($acl)){
      return(1) if (grep(/^read$/,@$acl));
   }
   return(0);
}

sub getQueryTemplate
{
   my $self=shift;

   my $tt=$self->kernel::MyW5Base::getTimeRangeDrop("month",
                                                    $self,
                                                    qw( fixmonth));


   my $d=<<EOF;
<div class=searchframe>
<table class=searchframe>
<tr>
<td class=fname width=10%>Username:</td>
<td class=finput ><input style='width:100%' name=user></td>
<td class=fname width=10%>Password:</td>
<td class=finput nowrap>
<input type=password style='width:100%' name=password>&nbsp;&nbsp;
</td>
</tr>

<tr>
<td class=fname width=10%>Monat:</td><td class=finput>$tt</td>
<td class=fname width=20%>MilesPlus Enviroment:</td>
<td class=finput width=30% nowrap>
<select name=base>
<option value='https://websso.t-systems.com/milesplus/prod'>Prod Enviroment (WebSSO)</option>
<option value='https://milesplus-ref.t-systems.com/mpt5'>Test Enviroment</option>
</select>
</td>
</tr>

<tr>
<td class=fname width=10%>divine the forecast:</td><td class=finput>
<select name=forecast>
<option value='1'>yes</option>
<option value='0'>no</option>
</select>
</td>
<td class=fname width=20%>Debugging:</td>
<td class=finput width=30% nowrap>
<select name=debug>
<option value='1'>yes</option>
<option value='0'>no</option>
</select>
</td>
</tr>


<tr>
<td colspan=4 align=right>
<input type=button 
       style='margin:2px;margin-right:10px;'
       onclick="DoSearch();" 
       value="Transfer starten">
</td>
</tr>
</table>
</div>
EOF
   return($d);
}

sub doAutoSearch
{
   my $self=shift;

   return(0);
}


sub Result
{
   my $self=shift;
   my $app=$self->getParent;

  

#   for(my $c=0;$c<20;$c++){
#      my $l=sprintf("L=%02d time=%s",$c,time());
#
#      $self->printFlushed("L1 ".$l);
#      $self->printFlushed("L2 ".$l);
#      $self->printFlushed("L3 ".$l);
#      $self->printFlushed("L4 ".$l);
#      sleep(1);
#   }
#   $self->printFlushedFinish();



}


sub Result
{
   my $self=shift;

   my $user=lc(Query->Param("user"));
   my $pass=Query->Param("password");
   my $base=Query->Param("base");
   my $month=Query->Param("month");
   $TS::MyW5Base::send2Miles::debug=Query->Param("debug");
   my $forecast=Query->Param("forecast");

   if ($user eq ""){
      $user="pmitarb";
   }
   if ($pass eq ""){
      $pass="a";
   }
   if ($user eq "" || $pass eq "" || $base eq "" || !($month=~m/^\d+\/\d+$/)){
      $self->printFlushed(msg(ERROR,"incomplet login or enviroment data"));
   }
   else{
      $self->printFlushed("Transfer of bookings from W5Base to MilesPlus");
      $self->printFlushed("=============================================");
      $self->printFlushed("Target   : ".$base);
      $self->printFlushed("User     : ".$user);
      my $xpass=$pass;
      $xpass=~s/./x/g;
      $self->printFlushed("Password : ".$xpass);
      $self->printFlushed("forecast : ".$forecast);
      $self->printFlushed("DEBUG    : ".$debug);
      $self->{base}=$base;
      if (!($self->{base}=~m/\/$/)){
         $self->{base}.="/";
      }
      my $userid=$self->getParent->getCurrentUserId();
      my $contact=getModuleObject($self->Config,"base::user");
      $contact->SetFilter({userid=>\$userid});
      my ($urec,$msg)=$contact->getOnlyFirst(qw(userid fullname givenname));
      if (!defined($urec)){
         return({exitcode=>100,msg=>'invalid user'});
         $self->printFlushed(msg(ERROR,"sorry - i do not know you"));
         $self->printFlushedFinish();
      }
      $self->printFlushed(" ");
      $self->printFlushed("Hello ".$urec->{givenname}.",");
      $self->printFlushed(" ");
      $self->printFlushed("now i start the transfer of your booking data ...");
      if ($self->initMilePlusConnection($user,$pass)){
         $self->printFlushed("* OK login done");
         my $ws=$self->getWorkspace();
         #   ##############################################################
         #   msg(INFO,"found MilesPlus labels:");
         #   foreach my $label (sort(keys(%{$ws->{bylabel}}))){
         #      msg(INFO,"personal label: ".$label);
         #   }
         $self->printFlushed("* OK loading MilesPlus Workspace done");
         my %milesd=$self->loadBookingData($urec,$month);
         $self->printFlushed("* OK loading W5Base booking data source");
         my @booksets=$self->calculateBookingSets($ws,\%milesd);
         foreach my $book (@booksets){
            $self->printFlushed(" do booking transfer of $book->[0]");
            $self->setEntries(@$book);
        #    last;
         }
         my $signOK=$self->signMonth($month);
         $self->reportStatus($month);
         if (!$signOK){
            $self->printFlushed("WARN: sign of month was not OK!");
         }
      }
      else{
         $self->printFlushed(msg(ERROR,"login to MilesPlus failed"));
      }
      $self->printFlushed(" ");
      $self->printFlushed("... transfer request finshed");
   }

   $self->printFlushedFinish();
}

sub signMonth
{
   my $self=shift;
   my $month=shift;

   $self->printFlushed("\nstart trying to sign month $month");

   my ($m,$y)=$month=~m/^(\d+)\/(\d+)$/;

   my $bumoid=sprintf("%04d%02d",$y,$m);
   $self->printFlushed("- using bumoid (YYYYMM) = $bumoid");
  
   my $param="?i_bumo_id=$bumoid";
   my $url=$self->{base}."plsql/timesheet_gc.createtimesheet";
   $url.=$param;


   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      $self->printFlushed("ERROR: fail to get signMonth report $url\n");
      printf STDERR ("ERROR: fail to get createweek $url\n");
      return(0);
   }
   #print $response->content;
   $self->{CurrentForm}={};
   eval('$self->{htmlparser}->parse($response->content);');
   if ($@ ne ""){
      printf STDERR ("%s\n",$@);
      printf STDERR ("ERROR: parsing createweek=$url\n");
      return(0);
   }
   $self->{CurrentForm}->{'form_aktion'}='Sichern';
   delete($self->{CurrentForm}->{''});
   msg(DEBUG,"month Report loaded $month OK");
   my $sendurl=$self->{base}."plsql/timesheet_gc.createtimesheet";
   my $request=POST($sendurl,
                    Content_Type=>'application/x-www-form-urlencoded',
                    'Accept-Charset'=>'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                    'Accept-Language'=>'de,en;q=0.5',
                    Content=>[%{$self->{CurrentForm}}]);
   #printf("as_string=%s\n",$request->as_string());
   my $response=$self->{ua}->request($request);
   my $res=$response->content;
   if (!($res=~m/error:/i) &&
       !($res=~m/error/i)){
      $self->printFlushed("... sign of month report seems to be OK");
      return(1);
   }
   else{
      $self->printFlushed("ERROR: sign of month failed");
      $self->printFlushed($response->content) if ($debug);
      return(0);
   }
}

sub reportStatus
{
   my $self=shift;
   my $month=shift;

   $self->printFlushed("\nstart to load month status $month");

   my ($m,$y)=$month=~m/^(\d+)\/(\d+)$/;

   my $bumoid=sprintf("%04d%02d",$y,$m);
   $self->printFlushed("- using bumoid (YYYYMM) = $bumoid");
  
   my $param="?i_bumo_id=$bumoid&".
             "i_prj_id=-99999&i_activity=j&i_leistungsart=j&i_ratetype=j";
   my $url=$self->{base}."plsql/report_gc.rptmonth";
   $url.=$param;


   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      $self->printFlushed("ERROR: fail to get signMonth report $url\n");
      printf STDERR ("ERROR: fail to get createweek $url\n");
      return(0);
   }
   print $response->content;
}

sub loadBookingData
{
   my $self=shift;
   my $urec=shift;
   my $month=shift;

   my %milesd;
   my $eff=getModuleObject($self->Config,"base::MyW5Base::myeffortsraw");
   $eff->setParent($self);
   $eff->Init();
   my $act=$eff->getDataObj();
   
   $act->SetFilter({creatorid=>\$urec->{userid},
                    bookingdate=>"(".$month.")"});
   $act->SetCurrentView(qw(bookingdate creatorposix effortrelation 
                           effortcomments effort wfheadid));
   
   my $c=0; 
   my ($rec,$msg)=$act->getFirst(unbuffered=>1);
   if (defined($rec)){
      do{
         #print Dumper($rec);
         if (my ($y,$m,$d)=$rec->{bookingdate}=~m/^(\d{4})-(\d{2})-(\d{2}) .*/){
            my $day="$d.$m.$y";
            my $label=$rec->{effortrelation};
            if ($label ne "" && $rec->{effort}!=0){
               if (!exists($milesd{$day}->{$label})){
                  $milesd{$day}->{$label}={effort=>0,wfheadid=>[]};
               }
               $milesd{$day}->{$label}->{effort}+=$rec->{effort};
               push(@{$milesd{$day}->{$label}->{wfheadid}},$rec->{wfheadid});
            }
            if (int($c/20)==$c/20){
               $self->printFlushed(sprintf(" - %-3d",$c).
                                   " W5Base booking entries loaded");
            }
            $c++;
         }
         ($rec,$msg)=$act->getNext();
      } until(!defined($rec));
   }
   return(%milesd);
}


sub initMilePlusConnection
{
   my $self=shift;
   my $user=shift;
   my $pass=shift;

   eval('use HTML::Parser;use LWP::UserAgent; use HTTP::Cookies;'.
        'use HTTP::Request::Common;'.
        '$self->{htmlparser}=new HTML::Parser();'.
        '$self->{ua}=new LWP::UserAgent(env_proxy=>1);');

   $self->{htmlparser}->handler(start=>sub {
      my ($pself,$tag,$attr)=@_;
      if (lc($tag) eq "input"){
         if (exists($self->{CurrentForm}->{"$attr->{name}"}) &&
             !ref($self->{CurrentForm}->{"$attr->{name}"})){
            $self->{CurrentForm}->{"$attr->{name}"}=
             [$self->{CurrentForm}->{"$attr->{name}"}];
         }
         if (ref($self->{CurrentForm}->{"$attr->{name}"})){
            push(@{$self->{CurrentForm}->{"$attr->{name}"}},"$attr->{value}");
         }
         else{
            $self->{CurrentForm}->{"$attr->{name}"}="$attr->{value}";
         }
      }
   },'self, tagname, attr');

   #$self->{ua}->cookie_jar(HTTP::Cookies->new(file =>"/tmp/.cookies.txt"));
   $self->{cookies}=HTTP::Cookies->new();
   $self->{ua}->cookie_jar($self->{cookies});
   $self->{ua}->timeout(20);
   $self->{ua}->agent('Mozilla/'.time().'.0');
   return($self->doLogin($user,$pass));
}


sub calculateBookingSets
{
   my $self=shift;
   my $ws=shift;
   my $pmilesd=shift;
   my %milesd=%{$pmilesd};
   my @booksets;

   foreach my $day (sort(keys(%milesd))){
      $self->printFlushed(" - calculate booking day $day");
      my @localbooks;
      foreach my $label (keys(%{$milesd{$day}})){
         if (exists($ws->{bylabel}->{$label})){
            my $e=$milesd{$day}->{$label}->{effort};
            my $eh=int($e/60);
            my $em=$e-($eh*60);
            my $h=sprintf("%02d:%02d",$eh,$em);
            push(@localbooks,{wsid=>$ws->{bylabel}->{$label}->{id},
                              effort=>$h,
                              comments=>join(", ",
                                 @{$milesd{$day}->{$label}->{wfheadid}})});
         }
         else{
            printf("%s<br>\n",msg(ERROR,"found invalid label '$label'"));
            printf("%s<br>\n",msg(ERROR,"wfheadid: ".
                    join(", ",@{$milesd{$day}->{$label}->{wfheadid}})));
            exit(1);
         }
      }
      push(@booksets,[$day,
                      '00:01',
                      '23:59',
                      \@localbooks]);
   }
      return(@booksets);
}




#   foreach my $book (@booksets){
#      msg(INFO,"do book $book->[0]");
#      $self->setEntries(@$book);
#   }
##   $self->setEntries("13.01.2011","00:01","23:59",[
##                     {'wsid'=>$ws->{bylabel}->{'9100004464'}->{id},
##                      'effort'=>'7:00',
#                      'comments'=>'Hallo Welt'},
#                     {'wsid'=>$ws->{bylabel}->{'70111192'}->{id},
#                      'effort'=>'0:50',
#                      'comments'=>'Ene2'}
#                     {'project'=>'W5Base',
#                      'effort'=>'1:00',
#                      'comments'=>'Entrie2'},
#                     ]);
#
#   $self->doLogout();
#
#   return({exitcode=>0,msg=>'transfer ok'});
#}
#
#sub doLogout
#{
#   my $self=shift;
#
#   my $url=$self->{base}."plsql/plogin.logout";
#
#   my $response=$self->{ua}->request(GET($url));
#   if ($response->code ne "200"){
#      printf STDERR ("ERROR: fail to get loginurl $url\n");
#      return(0);
#   }
#}
#
#


sub getWorkspace
{
   my $self=shift;

   my $url=$self->{base}."plsql/worktimeii_gc.showusertasks";

   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      printf STDERR ("ERROR: fail to get loginurl $url\n");
      return(0);
   }
   #print $response->content;
   my $d=$response->content;

   my %ws=();
   my $c=0;

   pos($d) = 0;
   while ($d=~m#\G.*?\<td class="btn_col">.*?\<td\>.+?\</td>.*?\<td\>(.+?)\</td>.*?showusertasks\?i_ts_id_arr=([\d-]+)&.*?i_rt_id_arr=([\d-]+)&.*?i_la_id_arr=(.+?)&.*?i_action=DELETE.*?\</tr\>#gcs){
      # printf STDERR ("Set:%d\n",$c++);
      # print  STDERR "Found name $1 .\n";
      # print  STDERR "Found i_ts_id_arr $2 .\n";
      # print  STDERR "Found i_rt_id_arr $3 .\n";
      # print  STDERR "Found i_la_id_arr $4 .\n";
      my %rec=(label=>$1,
               i_ts_id_arr=>$2,
               i_rt_id_arr=>$3,
               i_la_id_arr=>$4,
               id=>$2."#".$3."#".$4);
      if ($rec{label} eq "&nbsp;"){
         $rec{label}="";
      }
      $ws{byid}->{$rec{id}}=\%rec;
      $ws{bylabel}->{$rec{label}}=\%rec;
      $self->printFlushed(" - loading MilesPlus personal ".
                          "workspace entry '$rec{label}'");
   }
   #print Dumper(\%ws);
   return(\%ws);
}


sub setEntries
{
   my $self=shift;
   my $date=shift;
   my $from=shift;
   my $to=shift;
   my $entries=shift;

   my $tasks=$#{$entries}+1;

   my $param="?i_user_tasks=$tasks&i_datum=$date&i_sel=j";
   my $url=$self->{base}."plsql/pweektime_gc.createpage_week";
   $url.=$param;


   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      $self->printFlushed("ERROR: fail to get createweek $url\n");
      printf STDERR ("ERROR: fail to get createweek $url\n");
      return(0);
   }
 #  print $response->content;
   $self->{CurrentForm}={};
   eval('$self->{htmlparser}->parse($response->content);');
   if ($@ ne ""){
      printf STDERR ("%s\n",$@);
      printf STDERR ("ERROR: parsing createweek=$url\n");
      return(0);
   }
   msg(DEBUG,"load dataform $date OK");


   $self->{CurrentForm}->{'i_kommt'}=[$from,''];
   $self->{CurrentForm}->{'i_geht'}=[$to,''];
   delete($self->{CurrentForm}->{'i_kw'});
   $self->{CurrentForm}->{'i_action'}='Speichern';
   delete($self->{CurrentForm}->{'i_dummy_az'});
   $self->{CurrentForm}->{'i_redirectmodus'}="";
   $self->{CurrentForm}->{'i_redirectto'}="";
   $self->{CurrentForm}->{'i_sel'}="j";
   $self->{CurrentForm}->{'i_anzahl_tage'}="1";
   $self->{CurrentForm}->{'i_user_tasks'}=$tasks;
   $self->{CurrentForm}->{'i_datum'}=$date;
   $self->{CurrentForm}->{'i_bis'}=$date;
   $self->{CurrentForm}->{''}='';
   delete($self->{CurrentForm}->{''});
   delete($self->{CurrentForm}->{'i_rows'});
   delete($self->{CurrentForm}->{'i_cols'});

   foreach my $tag (qw(i_az i_ts_lock_az_arr i_ts_lock_arr i_ts_rt_la_id
                       i_kommentar)){
      $self->{CurrentForm}->{$tag}="";
   }
   foreach my $tag (qw(i_az i_ts_lock_az_arr i_ts_lock_arr i_ts_rt_la_id
                       i_kommentar)){
      if (ref($self->{CurrentForm}->{$tag}) ne "ARRAY"){
         $self->{CurrentForm}->{$tag}=[];
      }
   }
   delete($self->{CurrentForm}->{'i_dummy_az'});

   for(my $c=0;$c<$tasks;$c++){
      if (!defined($self->{CurrentForm}->{'i_az'}->[$c])){
       $self->{CurrentForm}->{'i_az'}->[$c]=$entries->[$c]->{'effort'};
      }
      if (!defined($self->{CurrentForm}->{'i_ts_rt_la_id'}->[$c])){
       $self->{CurrentForm}->{'i_ts_rt_la_id'}->[$c]=$entries->[$c]->{'wsid'};
      }
      if (!defined($self->{CurrentForm}->{'i_ts_lock_arr'}->[$c])){
         $self->{CurrentForm}->{'i_ts_lock_arr'}->[$c]='0';
      }
      if (!defined($self->{CurrentForm}->{'i_ts_lock_az_arr'}->[$c])){
         $self->{CurrentForm}->{'i_ts_lock_az_arr'}->[$c]='0';
      }
     # if (!defined($self->{CurrentForm}->{'i_kommentar'}->[$c])){
      #   $self->{CurrentForm}->{'i_kommentar'}->[$c]='0';
      #}
      $self->{CurrentForm}->{'i_kommentar'}->[$c]=$entries->[$c]->{'comments'};
   }


   #$self->{CurrentForm}->{'i_sel_tag'}=1,

   delete($self->{CurrentForm}->{'i_col_sum'});  # these fields ar set ro
   delete($self->{CurrentForm}->{'i_row_sum'});  # these fields ar set ro

  # printf ("<xmp>keys=%s</xmp>\n",
  #         join(",",sort(keys(%{$self->{CurrentForm}}))));
  # printf ("<xmp>%s</xml>",Dumper(\%{$self->{CurrentForm}}));
   my $sendurl=$self->{base}."plsql/pweektime_gc.createpage_week";
   my $request=POST($sendurl,
                    Content_Type=>'application/x-www-form-urlencoded',
                    'Accept-Charset'=>'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                    'Accept-Language'=>'de,en;q=0.5',
                    Content=>[%{$self->{CurrentForm}}]);
  # printf("as_string=%s\n",$request->as_string());
   my $response=$self->{ua}->request($request);
   $self->printFlushed($response->content);
   if ($response->is_redirect){
      #printf("redirect:%s\n",$response->content);

      my $response=$self->{ua}->request(GET($response->header('Location')));
   }
   else{
      msg(ERROR,"request failed");
      my $d=$response->content;
      my $emsg;
      if (my ($msg)=$d=~m/FEHLER!.*?\<BR\>(.*?)\<BR\>/s){
         $emsg=$msg;
         $emsg=~s/\<br\>/\n/g;
         print $emsg;
      }
      if (my ($msg)=$d=~m/Error .* calling procedure/s){
         $emsg=$d;
         $emsg=~s/\<br\>/\n/g;
         print $emsg;
      }

   #   print $response->content;


   }


  # if ($response->code ne "302"){   # 302 signals login OK
  #    printf STDERR ("ERROR: fail to post loginurl $url code=%s\n",
  #                   $response->code);
  #    return(0);
  # }

 
}


sub doLogin
{
   my $self=shift;
   my $user=shift;
   my $pass=shift;
   #my $url=$self->{base}."plsql/plogin.login";
   my $url=$self->{base}."plsql/prost.create_main";

   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      printf STDERR ("ERROR: fail to get loginurl $url\n");
      return(0);
   }
   $self->{CurrentForm}={};
   eval('$self->{htmlparser}->parse($response->content);');
   if ($@ ne ""){
      printf STDERR ("%s\n",$@);
      printf STDERR ("ERROR: parsing loginurl=$url\n");
      return(0);
   }
   msg(DEBUG,"get login page OK");
   #print $response->content;

   $self->{'CurrentForm'}->{password}="$pass";
   $self->{'CurrentForm'}->{username}="$user";
   $self->{'CurrentForm'}->{'login-form-type'}="pwd";
   delete($self->{'CurrentForm'}->{''});

   my $url="https://websso.t-systems.com/pkmslogin.form";

   my $request=POST($url,Content_Type=>'application/x-www-form-urlencoded',
                         Content=>[%{$self->{CurrentForm}}]);
   my $response=$self->{ua}->request($request);
   if ($response->code ne "302"){   # 302 signals login OK
      $self->printFlushed($response->content) if ($debug);
      $self->printFlushed(msg(ERROR,"fail to post loginurl $url code=%s\n",
                     $response->code));
      return(0);
   }
   #print "<xmp>".$response->content()."</xmp>";
   msg(DEBUG,"auth login cookie OK");
   return(1);
}
#
#



1;
