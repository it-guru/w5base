package TSIS::event::TSIS_fakeIfLoad;
#  W5Base Framework
#  Copyright (C) 2024  Hartmut Vogler (it@guru.de)
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
use HTML::Parser;
use LWP::UserAgent;

@ISA=qw(kernel::Event);

sub TSIS_fakeIfLoad
{
   my $self=shift;

   msg(INFO,"fifi");
   my $ua=LWP::UserAgent->new(
      env_proxy=>0,
      ssl_opts =>{
         verify_hostname=>'0'
      }
   );
   my %p=(
      ua=>$ua,
      method=>'GET',
      base=>'https://beteiligungen.telekom.de/EN/',
      file=>'INDEX_COMPANY.html',
      headers=>[]
   );
   $p{url}=$p{base}.$p{file};
   my $req=HTTP::Request->new($p{method},$p{url},$p{headers});
   msg(INFO,"load $p{url}");

   my $response=$p{ua}->request($req);
   my $code=$response->code();
   my $message=$response->message();
   my @tsisDB;
   if ($response->is_success) {
      my $respcontent=$response->decoded_content;
      my @p=extractPageReferences($respcontent);
      foreach my $p (@p){
         my %reqp=%p;
         $reqp{file}=$p;
         my %rec;
         loadRecord(\%reqp,\%rec);
         if (exists($rec{iframe})){
            $reqp{file}=$rec{iframe};
            loadRecord(\%reqp,\%rec);
         }
         push(@tsisDB,\%rec);

      }

   }
#print Dumper(\@tsisDB);exit(0);
   return(1);
}

sub loadRecord
{
   my $p=shift;
   my $rec=shift;

   $p->{url}=$p->{base}.$p->{file};
   my $req=HTTP::Request->new($p->{method},$p->{url},$p->{headers});
   msg(INFO,"load $p->{url}");

   if (!exists($rec->{srcurl})){
      $rec->{srcurl}=[];
   }
   my $url=$p->{url};
   push(@{$rec->{srcurl}},$url);

   my $response=$p->{ua}->request($req);
   my $code=$response->code();
   my $message=$response->message();
   $rec->{httpcode}=$code;
   if ($response->is_success) {
      my $d=$response->decoded_content;
      my $p = HTML::Parser->new(
         api_version     => 3,
         text_h          => [\&text, "self, tagname, attr, dtext"],
         start_h         => [\&start, "self, tagname, attr, dtext"],
         end_h           => [\&end,   "self, tagname, dtext"],
         marked_sections => 1,
      );
      $p->{record}=$rec;
      $p->parse($d);
      $p->eof();
   }
}


sub extractPageReferences
{
   my $str=shift;
   my %f;

   while($str=~m/\G.+?"([A-Z0-9]{5,30}\.html)"/gc){
      $f{$1}++;
   }
   return(sort(keys(%f)));
}

sub start
{
   my ($self,$tagname,$attr,$dtext)=@_;
   if ($tagname eq "iframe"){
      $self->{record}->{iframe}=$attr->{src};
     # printf STDERR ("$self record: %s\n",Dumper($self->{record}));
   }
   if ($tagname eq "h2"){
      $self->{inHeader}=1;
   }
   if ($tagname eq "table" && $attr->{class} eq "alv"){
      $self->{curTableDB}={};
   }
   if ($tagname eq "tbody" && defined($self->{curTableDB})){
      $self->{curTableDB}->{tbody}=[];
   }
   if ($tagname eq "tr" && defined($self->{curTableDB})){
      $self->{curTR}=[];
      $self->{inTR}=1;
   }
   if ($tagname eq "td" && defined($self->{curTR}) && $self->{inTR}){
      push(@{$self->{curTR}},"");
      my $n=$#{$self->{curTR}};
      $self->{curTD}=\$self->{curTR}->[$n];
   }
   if ($tagname eq "th" && defined($self->{curTableDB})){
      push(@{$self->{curTableDB}->{thead}},"");
      my $n=$#{$self->{curTableDB}->{thead}};
      $self->{curTH}=\$self->{curTableDB}->{thead}->[$n];
      $self->{inTH}=1;
   }


   if ($tagname eq "td" && 
       in_array([split(/\s/,$attr->{class})],"col_label")){
      $self->{curLabel}="";
   }
   if ($tagname eq "td" && 
       in_array([split(/\s/,$attr->{class})],"col_value")){
      $self->{curValue}="";
   }
}

sub text
{
   my ($self,$tagname,$attr,$dtext)=@_;
   if ($self->{inHeader}){
      $self->{CurrentTableH2}=$dtext;
   }
   if ($self->{inTH} && defined($self->{curTH})){
      ${$self->{curTH}}=$dtext;
   }
   if (defined($self->{curTD})){
      ${$self->{curTD}}.=$dtext;
   }
   if (defined($self->{curValue}) && 
       defined($self->{curLabel}) && 
       $self->{curLabel} ne ""){
      $self->{curValue}.=$dtext;
   }
   if (defined($self->{curLabel}) && !defined($self->{curValue})){
      $self->{curLabel}.=$dtext;
   }
}

sub end
{
   my ($self,$tagname,$dtext)=@_;

   if ($tagname eq "td" && defined($self->{curValue})){
      my $key=trim($self->{curLabel});
      $key=~s/[^a-z0-9]//gi;
      $key=lc($key);
      if ($key ne ""){
         $self->{record}->{fields}->{$key}=trim($self->{curValue});
      }
      delete($self->{curValue});
      delete($self->{curLabel});
   }
   if ($tagname eq "th" && defined($self->{curTableDB}) && 
                           defined($self->{curTH})){
      $self->{inTH}=0;
      delete($self->{curTH});
   }
   if ($tagname eq "tr" && $self->{inTR}){
      if ($#{$self->{curTR}}!=-1){
         push(@{$self->{curTableDB}->{tbody}},$self->{curTR});
         if (ref($self->{curTableDB}->{thead}) eq "ARRAY"){
            my %dbrec=();
            for(my $c=0;$c<=$#{$self->{curTableDB}->{thead}};$c++){
               my $key=trim($self->{curTableDB}->{thead}->[$c]);
               $key=~s/[^a-z0-9]//gi;
               $key=lc($key);
               $self->{curTableDB}->{col}->{$key}++;
               my $val=trim($self->{curTR}->[$c]);
               $dbrec{$key}=$val;
            }
            push(@{$self->{curTableDB}->{row}},\%dbrec);
         }
      }
      $self->{curTR}=undef;
      $self->{inTR}=0;
   }
   if ($tagname eq "td"){
      $self->{curTD}=undef;
   }
   if ($tagname eq "tbody"){
      # Store TBDOY ToDo!
      $self->{curTBODY}=undef; 
   }
   if ($tagname eq "h2"){
      $self->{inHeader}=0;
      push(@{$self->{record}->{TableH2}},$self->{CurrentTableH2});
   }
   if ($tagname eq "table" && defined($self->{curTableDB})){
     # $self->{curTableDB}->{h2}=$self->{CurrentTableH2};
      my $key=trim($self->{CurrentTableH2});
      $key=~s/[^a-z0-9]//gi;
      $key=lc($key);
      my $subTable={
         row=>$self->{curTableDB}->{row},
         col=>$self->{curTableDB}->{col},
         name=>$self->{CurrentTableH2}
      };
      $self->{record}->{sublist}->{$key}=$subTable;
      $self->{curTableDB}=undef;
      
   }
}



1;
