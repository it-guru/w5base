package TS::event::send2Miles;
#  W5Base Framework
#  Copyright (C) 2010  Hartmut Vogler (it@guru.de)
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
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Cookies;
use HTML::Parser;

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


   $self->RegisterEvent("send2Miles","send2Miles");
   return(1);
}

sub send2Miles
{
   my $self=shift;
   my %param=@_;

   my $user=$param{user};
   my $pass=$param{pass};
   $self->{base}=$param{url};
   if ($self->{base} eq ""){
      $self->{base}="https://milesplus-ref.t-systems.com/mpt5";
      $self->{base}="https://milesplus.t-systems.com/prod";
   }
   if (!($self->{base}=~m/\/$/)){
      $self->{base}.="/";
   }
   if ($user eq ""){
      $user="pmitarb";
   }
   if ($pass eq ""){
      $pass="a";
   }

   my $contact=getModuleObject($self->Config,"base::user");
   $contact->SetFilter({posix=>\$user});
   my ($urec,$msg)=$contact->getOnlyFirst(qw(userid));
   if (!defined($urec)){
      return({exitcode=>100,msg=>'invalid user'});
   }


   #######################################################################
   # collect data
   my %milesd;
   if (1){
      my $eff=getModuleObject($self->Config,"base::MyW5Base::myeffortsraw");
      $eff->setParent($self);
      $eff->Init();
      my $act=$eff->getDataObj();
     
      $act->SetFilter({creatorid=>\$urec->{userid},
                       cdate=>"(03/2011)"});
      $act->SetCurrentView(qw(cdate creatorposix effortrelation 
                              effortcomments effort wfheadid));
     
     
      my ($rec,$msg)=$act->getFirst(unbuffered=>1);
      if (defined($rec)){
         do{
            #print Dumper($rec);
            if (my ($y,$m,$d)=$rec->{cdate}=~m/^(\d{4})-(\d{2})-(\d{2}) .*/){
               my $day="$d.$m.$y";
               my $label=$rec->{effortrelation};
               if ($label ne "" && $rec->{effort}!=0){
                  if (!exists($milesd{$day}->{$label})){
                     $milesd{$day}->{$label}={effort=>0,wfheadid=>[]};
                  }
                  $milesd{$day}->{$label}->{effort}+=$rec->{effort};
                  push(@{$milesd{$day}->{$label}->{wfheadid}},$rec->{wfheadid});
               }
            }
            ($rec,$msg)=$act->getNext();
         } until(!defined($rec));
      }
   }

   #######################################################################



   #######################################################################
   # init miles plus connection


   $self->{htmlparser}=new HTML::Parser();
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




   msg(INFO,"use url=".$self->{base});
   $self->{ua}=new LWP::UserAgent(env_proxy=>1); 
   #$self->{ua}->cookie_jar(HTTP::Cookies->new(file =>"/tmp/.cookies.txt"));
   $self->{cookies}=HTTP::Cookies->new();
   $self->{ua}->cookie_jar($self->{cookies});
   $self->{ua}->timeout(60);
   $self->{ua}->agent('Mozilla/'.time().'.0');
   $self->doLogin($user,$pass);
   my $ws=$self->getWorkspace();

   #######################################################################

   msg(INFO,"found MilesPlus labels:");
   foreach my $label (sort(keys(%{$ws->{bylabel}}))){
      msg(INFO,"personal label: ".$label);
   }

   my @booksets;

   foreach my $day (sort(keys(%milesd))){
      msg(INFO,"processing day $day");
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
            msg(ERROR,"found invalid label '$label'");
            msg(ERROR,"wfheadid: ".
                    join(", ",@{$milesd{$day}->{$label}->{wfheadid}}));
            exit(1);
         }
      }
      push(@booksets,[$day,
                      '00:01',
                      '23:59',
                      \@localbooks]);
   }
   foreach my $book (@booksets){
      msg(INFO,"do book $book->[0]");
      $self->setEntries(@$book);
   }
#   $self->setEntries("13.01.2011","00:01","23:59",[
#                     {'wsid'=>$ws->{bylabel}->{'9100004464'}->{id},
#                      'effort'=>'7:00',
#                      'comments'=>'Hallo Welt'},
#                     {'wsid'=>$ws->{bylabel}->{'70111192'}->{id},
#                      'effort'=>'0:50',
#                      'comments'=>'Ene2'}
#                     {'project'=>'W5Base',
#                      'effort'=>'1:00',
#                      'comments'=>'Entrie2'},
#                     ]);

   $self->doLogout();

   return({exitcode=>0,msg=>'transfer ok'});
}

sub doLogout
{
   my $self=shift;

   my $url=$self->{base}."plsql/plogin.logout";

   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      printf STDERR ("ERROR: fail to get loginurl $url\n");
      return(0);
   }
}


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
   while ($d=~m#\G.*?\<td class="tdi">&nbsp;\</td\>.*?own_def_edit.*?\<td\>(.+?)\</td>.*?showusertasks\?i_ts_id_arr=([\d-]+)&i_rt_id_arr=([\d-]+)&i_la_id_arr=(.+?)&i_action=DELETE.*?\</TR\>#gcs){
     #  printf("Set:%d\n",$c++);
     #  print "Found name $1 .\n";
     #  print "Found i_ts_id_arr $2 .\n";
     #  print "Found i_rt_id_arr $3 .\n";
     #  print "Found i_la_id_arr $4 .\n";
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

   my $param="?i_user_tasks=$tasks&i_datum=$date&i_sel_day=1";
   my $url=$self->{base}."plsql/pweektime_gc.createpage_startweek";
   $url.=$param;


   my $response=$self->{ua}->request(GET($url));
   if ($response->code ne "200"){
      printf STDERR ("ERROR: fail to get createweek $url\n");
      return(0);
   }
#   print $response->content;
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
   $self->{CurrentForm}->{'i_kw'}="";
   $self->{CurrentForm}->{'i_action'}='Speichern';
   $self->{CurrentForm}->{'i_dummy_az'}="";

   foreach my $tag (qw(i_az i_ts_lock_az_arr i_ts_lock_arr i_ts_rt_la_id
                       i_dummy_az i_kommentar)){
      if (ref($self->{CurrentForm}->{$tag}) ne "ARRAY"){
         $self->{CurrentForm}->{$tag}=[];
      }
   }

   for(my $c=0;$c<$tasks;$c++){
     # if (!defined($self->{CurrentForm}->{'i_az'}->[$c])){
       $self->{CurrentForm}->{'i_az'}->[$c]=$entries->[$c]->{'effort'};
     # }
     # if (!defined($self->{CurrentForm}->{'i_ts_rt_la_id'}->[$c])){
       $self->{CurrentForm}->{'i_ts_rt_la_id'}->[$c]=$entries->[$c]->{'wsid'};
     # }
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

   printf ("keys=%s\n",join(",",sort(keys(%{$self->{CurrentForm}}))));
   my $sendurl=$self->{base}."plsql/pweektime_gc.createpage_week";
   msg(DEBUG,"sendurl=$sendurl");
   my $request=POST($sendurl,
                    Content_Type=>'application/x-www-form-urlencoded',
                    Referer=>'https://milesplus-ref.t-systems.com/mpt5/plsql/pweektime_gc.createpage_startweek?i_datum=14.01.2011&i_wkdatum=',
                    'Accept-Charset'=>'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                    'Accept-Language'=>'de,en;q=0.5',
                    Content=>[%{$self->{CurrentForm}}]);
   my $response=$self->{ua}->request($request);
   if ($response->is_redirect){
   #   print "Result:\n".Dumper($response);

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
   my $url=$self->{base}."plsql/plogin.login";

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

   $self->{'CurrentForm'}->{i_passwd}="$pass";
   $self->{'CurrentForm'}->{i_user}="$user";
   delete($self->{'CurrentForm'}->{''});

   my $url=$self->{base}."plsql/plogin.login";
   my $request=POST($url,Content_Type=>'application/x-www-form-urlencoded',
                         Content=>[%{$self->{CurrentForm}}]);
   my $response=$self->{ua}->request($request);
   if ($response->code ne "302"){   # 302 signals login OK
      print $response->content;
      printf STDERR ("ERROR: fail to post loginurl $url code=%s\n",
                     $response->code);
      exit(101);
   }
   msg(DEBUG,"auth login cookie OK");
   return(1);
}





1;
