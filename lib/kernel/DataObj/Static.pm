package kernel::DataObj::Static;
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
use kernel::DataObj;
use Text::ParseWords;
use JSON;
use LWP::UserAgent;

@ISA = qw(kernel::DataObj);

sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   return($self);
}

sub data
{
   my $self=shift;
   my $filterset=shift;
   if (ref($self->{data}) eq "CODE"){
      return(&{$self->{data}}($self,$filterset));
   }
   return($self->{data});
}

sub Initialize
{
   my $self=shift;
   return(1);
}

sub Fields
{
   my $self=shift;
   return(@{$self->{'FieldOrder'}});
}


sub resolvField
{
   my $self=shift;
   my $field=shift;
   my $rec=shift;
   return(undef);
}

sub tieRec
{
   my $self=shift;

   if (defined($self->{CurrentData}->[$self->{'Pointer'}])){
      my %rec;
      tie(%rec,'kernel::DataObj::Static::rec',$self,
          $self->{CurrentData}->[$self->{'Pointer'}]);
      return(\%rec);
   }
   return(undef);

}

sub getOnlyFirst
{
   my $self=shift;
   if (ref($_[0]) eq "HASH"){
      $self->SetFilter($_[0]);
      shift;
   }
   my @view=@_;
   $self->SetCurrentView(@view);
   $self->Limit(1,1);
   my @res=$self->getFirst();
   return(@res);
}


sub getFirst
{
   my $self=shift;
   $self->{'Pointer'}=undef;


   $self->{CurrentData}=$self->data($self->{FilterSet});

   return(undef,"DataCollectError") if (!defined($self->{CurrentData}) || 
                                        ref($self->{CurrentData}) ne "ARRAY"); 

#
#   ## hier muss bei Gelegenheit mal ein Order Verfahren rein!

   my @l=0..$#{$self->{CurrentData}};


   my @o=$self->GetCurrentOrder();
   if (!($#o==0 && uc($o[0]) eq "NONE")){
      if ($#o==-1 || ($#o==0 && $o[0] eq "")){
         @o=$self->getCurrentView();
      }
   }
   @o=grep(!/^linenumber$/,@o);
   my @orderbuf;
   for(my $c=0;$c<=$#{$self->{CurrentData}};$c++){
      push(@orderbuf,{
         id=>$c,
         ostring=>substr(join(";",map({
            my $d=$self->{CurrentData}->[$c]->{$_};
            $d=join("|",sort(@$d)) if (ref($d) eq "ARRAY");
            $d;
         } @o)),0,80),
      });
   }
   $self->{'Index'}=[map({$_->{id}}
                     sort({lc($a->{ostring}) cmp lc($b->{ostring})} @orderbuf)
                     )];

   $self->{'Pointer'}=shift(@{$self->{'Index'}});
   return(undef) if (!defined($self->{'Pointer'}));
   while(!($self->CheckFilter()) && 
         defined($self->{CurrentData}->[$self->{'Index'}->[$self->{'Pointer'}]])){ 
      $self->{'Pointer'}=shift(@{$self->{'Index'}});
      return(undef) if (!defined($self->{'Pointer'}));
   }
   return($self->tieRec());
}

sub getNext
{
   my $self=shift;
   $self->{'Pointer'}=shift(@{$self->{'Index'}});
   return(undef) if (!defined($self->{'Pointer'}));

   while(!($self->CheckFilter()) && 
         defined($self->{CurrentData}->[$self->{'Index'}->[$self->{'Pointer'}]])){ 
      $self->{'Pointer'}=shift(@{$self->{'Index'}});
      return(undef) if (!defined($self->{'Pointer'}));
   }
   return($self->tieRec());
}

sub Rows
{
   my $self=shift;

#   if (exists($self->{Index})){
#      return($#{$self->{Index}});
#   }

   return(undef);
}

sub CheckFilter
{
   my $self=shift;
   my $rec=$self->tieRec();
   my @flt=$self->getFilterSet();
   return(1) if (!defined($rec));
   return(1) if ($#flt==-1);
   my $failcount=0;
   my $okcount=0;
   CHK: foreach my $filter (@flt){
      foreach my $k (keys(%{$filter})){
         if (exists($filter->{$k}) && !defined($filter->{$k})){ # compare on 
            if (!(!defined($rec->{$k}) && exists($rec->{$k}))){ # null entrys
               $failcount=1;
               last CHK;
            }
         }
         elsif (ref($filter->{$k}) eq "SCALAR"){
            if ($rec->{$k} ne ${$filter->{$k}}){
               $failcount=1;
               last CHK;
            }
         }
         elsif (ref($filter->{$k}) eq "ARRAY"){
            my $subcheck=0;
            FLTCHK: foreach my $v (@{$filter->{$k}}){
               if (ref($rec->{$k}) eq "ARRAY"){
                  foreach my $subval (@{$rec->{$k}}){
                     if ($v eq $subval){
                        $subcheck=1;
                        last FLTCHK;
                     }
                  }
               }
               elsif (ref($rec->{$k}) eq "HASH"){
                  foreach my $subval (values(%{$rec->{$k}})){
                     if ($v eq $subval){
                        $subcheck=1;
                        last FLTCHK;
                     }
                  }
               }
               else{
                  if ($v eq $rec->{$k}){
                     $subcheck=1;
                     last FLTCHK;
                  }
               }
            }
            if ($subcheck==0){
               $failcount=1;
               last CHK;
            }
         }
         else{
            my $chk=$filter->{$k};
            my @words=parse_line('[,;]{0,1}\s+',0,$chk);
            if (!($chk=~m/^\s*$/) && $#words==-1){  # maybe an invalid " struct
               $failcount=1;
               last CHK;
            }
            else{
               my $wordschkok=0;
               my $conjunction; # AND relation

               my @dataval=($rec->{$k});
               @dataval=@{$rec->{$k}} if (ref($rec->{$k}) eq "ARRAY");
               @dataval=values(%{$rec->{$k}}) if (ref($rec->{$k}) eq "HASH");

               for (my $i=0;$i<=$#words;$i++) {
                  my $chk=$words[$i];

                  $conjunction=0; # default
                  if ($i<$#words && $words[$i+1] eq 'AND') {
                     $conjunction=1; # relation to next word is AND
                  }

                  my $recok;
                  DATACHK: foreach my $dataval (@dataval){
                     if ($chk=~m/^>/){
                        $chk=~s/^>//;
                        if (!($dataval>$chk)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              # skip all words with AND relation
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        elsif ($conjunction) {
                           $recok=0 if (!defined($recok));
                           $i+=1; # skip next word. It's AND
                        }
                     }
                     elsif ($chk=~m/^</){
                        $chk=~s/^<//;
                        if (!($dataval<$chk)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        elsif ($conjunction) {
                           $recok=0 if (!defined($recok));
                           $i+=1;
                        }
                     }
                     elsif ($chk=~m/^!/){
                        $chk=~s/^!//;
                        $chk=~s/\?/\./g;
                        $chk=~s/\*/\.*/g;
                        if (($dataval=~m/^$chk$/i)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        elsif ($conjunction) {
                           $recok=0 if (!defined($recok));
                           $i+=1;
                        }
                     }
                     else{
                        $chk=~s/\./\\./g;
                        $chk=~s/\?/\./g;
                        $chk=~s/\*/\.*/g;
                        if (!($dataval=~m/^$chk$/i)){
                           $recok=0 if (!defined($recok));
                           if ($conjunction) {
                              while ($i<$#words && $words[$i+1] eq 'AND') {
                                 $i+=2;
                              }
                           }
                        }
                        else{
                           if ($conjunction) {
                              $recok=0 if (!defined($recok));
                              $i+=1;
                           }
                           else {
                              $recok++;
                           }
                        }
                     }
                  }
                  if (defined($recok) && $recok>0){
                     $okcount++;
                  }
                  if (!(defined($recok) && $recok==0)){
                     $wordschkok++;
                  }
                   
               }
               if ($wordschkok==0 && $#words!=-1){
                  $failcount++;
                  last CHK;
               }
            }
         } 
      }
   }
   return(0) if ($failcount); 
   return(1);
}


########################################################################
# REST Extensions to handle REST Calls as Static (Cached) Data structes#
########################################################################

sub GetRESTCredentials
{
   my $self=shift;
   my $dbname=shift;
   my %p;

   $p{dbconnect}=$self->Config->Param('DATAOBJCONNECT');
   $p{dbpass}=$self->Config->Param('DATAOBJPASS');

   foreach my $v (qw(dbconnect dbpass)){
      if ((ref($p{$v}) ne "HASH" || !defined($p{$v}->{$dbname})) &&
          $v ne "dbschema"){
         my $msg=sprintf("Connect(%s): essential information '%s' missing",
                    $dbname,$v);
         $self->LastMsg(ERROR,$msg);
         return();
      }
      if (defined($p{$v}->{$dbname}) && $p{$v}->{$dbname} ne ""){
         $p{$v}=$p{$v}->{$dbname};
      }
   }
   return($p{dbconnect},$p{dbpass});
}


sub DoRESTcall
{
   my $self=shift;
   my %p=@_;

   my $ua=new LWP::UserAgent(env_proxy=>0);
   $ua->protocols_allowed( ['https','http','connect'] );
   if ($p{useproxy}){
      my $probeipproxy=$self->Config->Param("http_proxy");
      if ($probeipproxy ne ""){
         $probeipproxy=~s/^http:/connect:/;
         $ua->proxy(['https'],$probeipproxy);
      }
   }
   if ($p{method} eq "GET"){
       
   }
   my $req;
   if ($p{method} eq "GET"){
      $req=HTTP::Request->new($p{method},$p{url},$p{headers});
   }

   my $response=$ua->request($req);
   if ($response->is_success) {
      my $d=decode_json($response->decoded_content);
      if (ref($d) eq "HASH"){
         my $dd=&{$p{success}}($self,$d);
         if (defined($dd)){
            return($dd);
         }
      }
   }
   else{
       my $statusline=$response->status_line;
       $self->LastMsg(ERROR,"unexpected result from REST call: ".$statusline);
   }
   return(undef);
}


sub CollectREST
{
   my $self=shift;
   my %p=@_;

   my $cachetime=$p{cachetime};
   $cachetime=10 if (!defined($cachetime));

   my $c=$self->Context();
   if (!exists($c->{RESTCallResult}) || 
       $c->{RESTCallResult}->{t}<time()-$cachetime){
      my $dbname=$p{dbname};
      my ($baseurl,$apikey)=$self->GetRESTCredentials($dbname);
      if (!defined($baseurl) || !defined($apikey)){
         return(undef);
      }
      my $dataobjurl=&{$p{url}}($self,$baseurl,$apikey);
      if (!defined($dataobjurl)){
         $self->LastMsg(ERROR,"no REST URL can be created");
         return(undef);
      }
      my $Headers=[];
      if ($p{headers}){
         $Headers=&{$p{headers}}($self,$baseurl,$apikey);
      }

      my $Content;
      if ($p{content}){
         $Content=&{$p{content}}($self,$baseurl,$apikey)
      }
      $p{method}="GET" if (!exists($p{method}));
      $p{format}="JSON" if (!exists($p{format}));

      my $Data=$self->DoRESTcall(
         method=>$p{method}, url=>$dataobjurl,
         content=>$Content,      headers=>$Headers,
         useproxy=>$p{useproxy},
         BasicAuthUser=>undef, BasicAuthPass=>undef,
         format=>$p{format},
         success=>$p{success}
      );
      $c->{RESTCallResult}={
         DATA=>$Data,
         t=>time()
      };
   }
   if (exists($c->{RESTCallResult})){
      return($c->{RESTCallResult}->{DATA});
   }
   return(undef);
}








########################################################################



package kernel::DataObj::Static::rec;
use strict;
use vars qw(@ISA);
use Tie::Hash;

@ISA=qw(Tie::Hash);

sub getParent
{
   return($_[0]->{Parent});
}

sub TIEHASH
{
   my $type=shift;
   my $parent=shift;
   my $rec=shift;
   return(bless({Parent=>$parent,Rec=>$rec},$type));
}

sub FIRSTKEY
{
   my $self=shift;
   $self->{'keylist'}=[$self->getParent->Fields()];
   return(shift(@{$self->{'keylist'}}));
}

sub EXISTS
{
   my $self=shift;
   my $key=shift;
   return(grep(/^$key$/,$self->getParent->Fields()) ? 1:0);
}

sub NEXTKEY
{
   my $self=shift;
   return(shift(@{$self->{'keylist'}}));
}

sub FETCH
{  
   my $self=shift;
   my $key=shift;
   my $mode=shift;
   return($self->{Rec}->{$key}) if (exists($self->{Rec}->{$key}));
   my $p=$self->getParent;
   if (defined($p)){
      my $fobj;
      if (!defined($self->{View}->{$key})){
         $fobj=$p->getField($key,$self->{Rec});
      }
      else{
         $fobj=$self->{View}->{$key};
      }
      return($p->RawValue($key,$self->{Rec},$fobj,$mode));
   }
   return("- unknown parent for '$key' -");
}


sub STORE
{
   my $self=shift;
   my $key=shift;
   my $val=shift;

   $self->{View}->{$key}=undef if (!exists($self->{View}->{$key}));
   $self->{Rec}->{$key}=$val;
}

sub DELETE
{
   my $self=shift;
   my $key=shift;

   delete($self->{View}->{$key});
   delete($self->{Rec}->{$key});
}






1;
