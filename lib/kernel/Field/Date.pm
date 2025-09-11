package kernel::Field::Date;
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
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{_permitted}->{timezone}=1;           # Zeitzone des feldes in DB
   $self->{dayonly}=0                    if (!defined($self->{dayonly}));
   $self->{timezone}="GMT"               if (!defined($self->{timezone}));
   $self->{htmlwidth}="150"              if (!defined($self->{htmlwidth}));
   $self->{htmleditwidth}="200"          if (!defined($self->{htmleditwidth}));
   $self->{xlswidth}="20"                if (!defined($self->{xlswidth}));
   $self->{WSDLfieldType}="xsd:dateTime" if (!defined($self->{WSDLfieldType}));
   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current,$mode);
   my $delta;
   my $dayoffset;
   my $timeonly;

   # central hack to handel iso stamps 2022-01-25T12:00:00Z (REST)
   if (defined($d) && $d ne ""){
      $d=~s/^([0-9]{4}-[0-9]{2}-[0-9]{2})T  
             ([0-9]{2}:[0-9]{2}:[0-9]{2})(\.[0-9]+)?Z?$/$1 $2/x;
   }

   my $usertimezone=$ENV{HTTP_FORCE_TZ};
   if (!defined($usertimezone)){
      $usertimezone=$self->getParent->UserTimezone();
   }
   if (defined($d)){
      ($d,$usertimezone,$dayoffset,$timeonly,$delta)=
                 $self->getFrontendTimeString($mode,$d,$usertimezone);
   }
   if (($mode eq "edit" || $mode eq "workflow")){
      my $name=$self->Name();
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      if ($self->{dayonly}){
         $d=~s/\s*\d+:\d+:\d+.*$//;
      }
      return($self->getSimpleInputField($d,$self->readonly($current)));
   }
   if ($d ne ""){
      if (length($usertimezone)<=4 && $mode=~m/html/i){
         $d.="&nbsp;"; 
         $d.="$usertimezone";
         if ($mode eq "HtmlSubList"){ 
            $d=~s/ 00:00:00//;
         }
      }
      if ($mode eq "ShortMsg"){         # SMS Modus
         if ($self->{dayonly}){
            $d=~s/\s*\d+:\d+:\d+.*$//;
         }
         $d=~s/^(.*\d+:\d+):\d+\s*$/$1/;   # cut seconds
      }
      if ($mode eq "HtmlDetail" && (!$self->{dayonly} || $self->{dayonly}==2)){
         if (defined($delta) && $delta!=0){

            my $lang=$self->getParent->Lang();
            my $absdelta=abs($delta);
            my $baseabsdelta=abs($delta);
            my @blks=();

            if ($dayoffset==0){
               if (!$self->{dayonly}){
                  if ($lang eq "de"){
                     push(@blks,"heute um $timeonly");
                  }
                  else{
                    push(@blks,"today at $timeonly");
                  }
               }
               elsif ($self->{dayonly}==2){
                  if ($lang eq "de"){
                     push(@blks,"heute");
                  }
                  else{
                    push(@blks,"today");
                  }
               }
            }
            elsif ($dayoffset==1){
               if (!$self->{dayonly}){
                  if ($lang eq "de"){
                     push(@blks,"gestern um $timeonly");
                  }
                  else{
                    push(@blks,"yesterday at $timeonly");
                  }
               }
               elsif ($self->{dayonly}==2){
                  if ($lang eq "de"){
                     push(@blks,"gestern");
                  }
                  else{
                    push(@blks,"yesterday");
                  }
               }
            }
            elsif ($dayoffset==-1){
               if (!$self->{dayonly}){
                  if ($lang eq "de"){
                     push(@blks,"morgen um $timeonly");
                  }
                  else{
                    push(@blks,"tomorrow at $timeonly");
                  }
               }
               elsif ($self->{dayonly}==2){
                  if ($lang eq "de"){
                     push(@blks,"morgen");
                  }
                  else{
                    push(@blks,"tomorrow");
                  }
               }
            }
            else{
               if (!$self->{dayonly} || $self->{dayonly}==2){
                  if ($absdelta>31536000){
                     my $years=int($absdelta/31536000);
                     $absdelta=$absdelta-($years*31536000);
                     # und noch die Tage killen
                     {
                        my $months=int($absdelta/2635200);
                        $absdelta=$months*2635200;
                     }
                     if ($lang eq "de"){
                        if ($years==1){
                           push(@blks,"einem Jahr");
                        }
                        else{
                           push(@blks,"$years Jahren");
                        }
                     }
                     else{
                        if ($years==1){
                           push(@blks,"one year");
                        }
                        else{
                           push(@blks,"$years years");
                        }
                     }
                  }
                  if ($absdelta>=2635200){
                     my $months=int($absdelta/2635200);
                     $absdelta=$absdelta-($months*2635200);
                     if ($lang eq "de"){
                        if ($months==1){
                           push(@blks,"einem Monat");
                        }
                        else{
                           push(@blks,"$months Monaten");
                        }
                     }
                     else{
                        if ($months==1){
                           push(@blks,"one month");
                        }
                        else{
                           push(@blks,"$months months");
                        }
                     }
                  }
                  if ($absdelta>86400){
                     my $days=int($absdelta/86400);
                     $absdelta=$absdelta-($days*86400);
                     if ($lang eq "de"){
                        if ($days==1){
                           push(@blks,"einem Tag");
                        }
                        else{
                           push(@blks,"$days Tagen");
                        }
                     }
                     else{
                        if ($days==1){
                           push(@blks,"one day");
                        }
                        else{
                           push(@blks,"$days days");
                        }
                     }
                  } 
                  if (!$self->{dayonly}){
                     if ($absdelta>3600 && $baseabsdelta<2635200){
                        my $hours=int($absdelta/3600);
                        $absdelta=$absdelta-($hours*3600);
                        if ($lang eq "de"){
                           if ($hours==1){
                              push(@blks,"einer Stunde");
                           }
                           else{
                              push(@blks,"$hours Stunden");
                           }
                        }
                        else{
                           if ($hours==1){
                              push(@blks,"one hour");
                           }
                           else{
                              push(@blks,"$hours hours");
                           }
                        }
                     }
                     if ($absdelta>60 && $baseabsdelta<2635200){
                        my $hours=int($absdelta/60);
                        $absdelta=$absdelta-($hours*60);
                        if ($lang eq "de"){
                           if ($hours==1){
                              push(@blks,"einer Minute");
                           }
                           else{
                              push(@blks,"$hours Minuten");
                           }
                        }
                        else{
                           if ($hours==1){
                              push(@blks,"one minute");
                           }
                           else{
                              push(@blks,"$hours minutes");
                           }
                        }
                     }
                  }
                  if ($#blks>0){
                     push(@blks,$blks[$#blks]);
                     if ($lang eq "de"){
                        $blks[$#blks-1]="und";
                     }
                     else{
                        $blks[$#blks-1]="and";
                     }
                  }
                  if ($delta<0){
                     if ($lang eq "de"){
                        unshift(@blks,"vor");
                     }
                     else{
                        push(@blks,"ago");
                     }
                  }
                  else{
                     unshift(@blks,"in");
                  }
               }
            }
            my $deltastr=join(" ",@blks);
            if ($self->{dayonly}){
               $d=~s/\s*\d+:\d+:\d+.*$//;
            }
            $d.=" &nbsp; ".
                "<span style=\"white-space:nowrap;\">( $deltastr )</span>";
            return($d);
         }
      }
      if ($mode=~m/^XlsV\d+$/){
         my $usertimezone=$self->getParent->UserTimezone();
         $d=$self->getParent->ExpandTimeExpression($d,"ISO8601",
                                                      $usertimezone,
                                                      $usertimezone);
         return($d);
      }
      if ($mode eq "SOAP"){
         my $usertimezone=$self->getParent->UserTimezone();
         $d=$self->getParent->ExpandTimeExpression($d,"SOAP",
                                                      $usertimezone,
                                                      "GMT");
         return(undef) if ($d eq ""); # prevent display in XML SOAP Response
      }
      if ($mode eq "JSON"){
         my $usertimezone=$self->getParent->UserTimezone();
         $d=$self->getParent->ExpandTimeExpression($d,"ISO8601",
                                                      $usertimezone,
                                                      $usertimezone);
         if (defined($d)){
            $d="\\Date($d)\\";
         } 
      }
      if ($self->{dayonly}){
         $d=~s/\s*\d+:\d+:\d+.*$//;
      }
      return($d);
   }
   if ($d ne ""){
      return("???");
   }
   return($d);
}

sub getFrontendTimeString
{
   my $self=shift;
   my $mode=shift;
   my $d=shift;
   my $usertimezone=shift;
   my $delta;
   my $dayoffset;
   my $timeonly;

   return(undef) if (!defined($d) || $d eq "");
   if (my ($Y,$M,$D,$h,$m,$s)=$d=~
           m/^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)(\..*){0,1}$/){
      my $tz=$self->timezone();
 
      my $time;
      eval('$time=Mktime($tz,$Y,$M,$D,$h,$m,$s);');
      if (defined($time)){
         $delta=$time-time();
      }
      if ($mode=~m/XMLV01$/ || $mode=~m/XLSV01$/){
         ($Y,$M,$D,$h,$m,$s)=Localtime("GMT",$time);
         $d=sprintf("%04d-%02d-%02d %02d:%02d:%02d",$Y,$M,$D,$h,$m,$s);
      }
      else{
         if (!defined($usertimezone)){
            my $UserCache=$self->getParent->Cache->{User}->{Cache};
            if (defined($UserCache->{$ENV{REMOTE_USER}})){
               $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
            }
            if (defined($UserCache->{tz})){
               $usertimezone=$UserCache->{tz};
            }
         }
         my ($doy, $dow, $dst);
         ($Y,$M,$D,$h,$m,$s, $doy, $dow, $dst)=Localtime($usertimezone,$time);
         {
            # calc dayoffset
            my ($Y1,$M1,$D1,$h1,$m1,$s1)=Localtime($usertimezone,$time);
            my ($Y2,$M2,$D2,$h2,$m2,$s2)=Localtime($usertimezone,time());
            my ($time1,$time2);
            eval('$time1=Mktime($usertimezone,$Y1,$M1,$D1,0,0,0);');
            eval('$time2=Mktime($usertimezone,$Y2,$M2,$D2,0,0,0);');
            my $floatdoffset=($time2-$time1)/86400;
            if ("$Y1,$M1,$D1" eq "$Y2,$M2,$D2"){
               $dayoffset=0;
            }
            elsif ("$Y1,$M1,$D1" ne "$Y2,$M2,$D2" &&
                   $floatdoffset>0.0 && $floatdoffset<1.0){
               $dayoffset=1;
            }
            elsif ("$Y1,$M1,$D1" ne "$Y2,$M2,$D2" &&
                   $floatdoffset<0.0 && $floatdoffset>-1.0){
               $dayoffset=-1;
            }
            else{
               $dayoffset=int(($time2-$time1)/86400);
            }
         }
         if ($dst){
            $usertimezone=~s/^CET$/CEST/;
         }
         my $lang=$self->getParent->Lang();
         $d=Date_to_String($lang,$Y,$M,$D,$h,$m,$s);
         $timeonly=sprintf("%02d:%02d",$h,$m);
      }
   }
   return($d,$usertimezone,$dayoffset,$timeonly,$delta);
}


sub getBackendName
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   return(undef) if (!defined($self->{dataobjattr}));
   return(undef) if (ref($self->{dataobjattr}) eq "ARRAY");
   if (($mode eq "select" || $mode eq "order") && $self->{noselect}){
      return(undef);
   }
   if ($mode eq "select"){
      if ($db->can("DriverName")){
         $_=$db->DriverName();
         case: {
            /^mysql$/i and do {
               return("date_add($self->{dataobjattr},interval 0 second)");
            };
            /^oracle$/i and do {
               return("to_char($self->{dataobjattr},'YYYY-MM-DD HH24:MI:SS')");
            };
            /^odbc$/i and do {
               return("$self->{dataobjattr}");
            };
            /^db2$/i and do {
               return("$self->{dataobjattr}");
            };
            /^pg$/i and do {
               return("$self->{dataobjattr}");
            };
            do {
               msg(ERROR,"conversion for date on ".
                         "driver '$_' not defined ToDo!");
               return(undef);
            };
         }
      }
      else{
         return("$self->{dataobjattr}");
      }
   }
   if ($mode eq "order"){
      my $ordername=shift;

      return(undef) if (lc($self->{sqlorder}) eq "none");
      if (defined($db) && $db->can("DriverName")){
         $_=$db->DriverName();
         case: {   # did not works on tsinet Oracle database
            /^oracle$/i and do {
               my $sqlorder="";
               if (defined($self->{sqlorder})){
                  $sqlorder=$self->{sqlorder};
               }
               if ($sqlorder eq ""){
                  $sqlorder="desc";
               }
               if ($sqlorder ne "none" && ($ordername=~m/^-/)){  # absteigend
                  $sqlorder="desc";
               }
               if ($sqlorder ne "none" && ($ordername=~m/^\+/)){  # aufsteigend
                  $sqlorder="asc";
               }
        
               if ($self->getParent->{use_distinct}){
                  return("to_char($self->{dataobjattr},".
                         "'YYYY-MM-DD HH24:MI:SS') ".
                         "$sqlorder ".
                         "NULLS FIRST"); # needed for QualityChecks
               }
               # ordering on nativ fields gets better performance then ordering
               # on a funktion. The result should be the same (but indexes 
               # can be used) - but if select distinct is used, you have to 
               # use the same exprestion as 
               # in select (Oracle rules are mysterious)
               return("$self->{dataobjattr} $sqlorder ".
                      "NULLS FIRST"); # needed for QualityChecks
        
            };
         }
      }
      return($self->SUPER::getBackendName($mode,$db,$ordername));
   }
   return($self->SUPER::getBackendName($mode,$db));
}  

sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;

   if (defined($formated)){
      $formated=[$formated] if (ref($formated) ne "ARRAY");
      return(undef) if (!defined($formated->[0]));
      my $usertimezone=$ENV{HTTP_FORCE_TZ};
      if (!defined($usertimezone)){
         my $UserCache=$self->getParent->Cache->{User}->{Cache};
         if (defined($UserCache->{$ENV{REMOTE_USER}})){
            $UserCache=$UserCache->{$ENV{REMOTE_USER}}->{rec};
         }
         if (defined($UserCache->{tz})){
            $usertimezone=$UserCache->{tz};
         }
      }
      $usertimezone="GMT" if ($usertimezone eq "");
      $formated=trim($formated->[0]) if (ref($formated) eq "ARRAY");
      return({$self->Name()=>undef}) if ($formated=~m/^\s*$/);
      $formated=trim($formated);
      my %dateparam=();
      if ($self->{dayonly}){      # fix format als 12:00 GMT
         $dateparam{defhour}=12;  # prevent day switch for day only fields
         $formated=~s/\s.*$//;    # if f.e. date is specified with 00:00:00 
      }
      if ($self->{dayonly} &&
          ($formated=~m/ \d+:\d+:\d+$/)){
                 # prevent day switch for day only fields
         $formated=~s/\s.*$//;    # if f.e. date is specified with 00:00:00 
         $formated.=" 12:00:00";  # time (which is not needed)
      }
      my $d=$self->getParent->ExpandTimeExpression($formated,"en",
                                                   undef,
                                                   $self->{timezone},
                                                   %dateparam);
      if ($formated ne "" && $d eq ""){
         return(undef);
      }
      if ($self->{dayonly}){  # fix format als 12:00 GMT
         $d=~s/\s.*$//;
         $d.=" 12:00:00";
      }
      return({$self->Name()=>$d});
   }
   return({});
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   my $oldval=$self->RawValue($oldrec);

   my $usertimezone=$ENV{HTTP_FORCE_TZ};
   if (!defined($usertimezone)){
      $usertimezone=$self->getParent->UserTimezone();
   }

   my ($d)=$self->getFrontendTimeString("edit",$oldval,$usertimezone);
   return($d);
}




sub getXLSformatname
{
   my $self=shift;
   my $xlscolor=$self->xlscolor;
   my $xlsbgcolor=$self->xlsbgcolor;
   my $xlsbcolor=$self->xlsbcolor;
   my $f="date.".$self->getParent->Lang();
   if ($self->{dayonly}){
      $f="dayonly.".$self->getParent->Lang();
   }
   my $colset=0;
   if (defined($xlscolor)){
      $f.=".color=\"".$xlscolor."\"";
   }
   if (defined($xlsbgcolor)){
      $f.=".bgcolor=\"".$xlsbgcolor."\"";
      $colset++;
   }
   if ($colset || defined($xlsbcolor)){
      if (!defined($xlsbcolor)){
         $xlsbcolor="#8A8383";
      }
      $f.=".bcolor=\"".$xlsbcolor."\"";
   }


   return($f);
}



sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   my $name=$self->Name();
   if (exists($newrec->{$name})){
      if (!defined($newrec->{$name})){
         $newrec->{$name}=undef;
      }
      else{
         my $dn=$self->Unformat([$newrec->{$name}],$newrec);
         return(undef) if (!defined($dn));
         $newrec->{$name}=$dn->{$name};
      }
   }
   return(1);
}


sub finishWriteRequestHash
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $parent=$self->getParent;
   if (defined($parent->{DB}) && $parent->{DB}->DriverName() eq "oracle"){
      my $name=$self->{name};
      if (exists($newrec->{$name})){
         my $d=$newrec->{$name};
         if (defined($d)){
            my $val="to_date('$d','YYYY-MM-DD HH24:MI:SS')";
            $newrec->{$name}=\$val;
         }
      }
   }
   return(undef);
}




1;
