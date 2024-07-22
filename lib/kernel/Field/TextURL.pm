package kernel::Field::TextURL;
#  W5Base Framework
#  Copyright (C) 2016  Hartmut Vogler (it@guru.de)
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
use kernel::Field::Text;
use URI;
@ISA    = qw(kernel::Field::Text);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);

   return($self);
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   my $app=$self->getParent();

   if ($mode=~m/^[>]{0,1}HtmlDetail/){
      $d=[$d] if (ref($d) ne "ARRAY");
      return(join("; ",map({
         my $m=$_;
         $m=~s/</&lt;/g;
         $m=~s/>/&gt;/g;
         my $ml=$_;
         $ml=~s/"/&quote;/g;
         #$m=FancyLinks($m);
         if (length($m)>65){
            $m=TextShorter($m,65,"URL");
         }
         "<a target='_blank' ".
           "class='emaillink' ".
           "href=\"$ml\">$m</a>";
      } @{$d})));
   }
   return($self->SUPER::FormatedDetail($current,$mode));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return({}) if (!exists($newrec->{$self->Name()}));
   if (defined($newrec->{$self->Name()})){
      if ($newrec->{$self->Name()} ne ""){
         my $uri=URLValidate($newrec->{$self->Name()});
         if ($uri->{error}) {
            $self->getParent->LastMsg(ERROR,$uri->{error});
            return(undef);
         }
      }
      else{
         $newrec->{$self->Name()}=undef;
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec));
}




sub URLValidate
{
   my $name=shift;

   my %uri;

   $name=~s/^([A-Z,a-z]+)/lc($1)/ex;
   if (($name=~m/\s/) || ($name=~m/^\s*$/)){
      $uri{error}=("invalid URL specified");
      return(\%uri);
   }
   if (URI->new($name)->path() eq "/"){
      $name=~s{/\s*$}{};
   }
   $uri{path}=URI->new($name)->path();
   
   $uri{name}=$name;

   $uri{scheme}=URI->new($name)->scheme();
   if ($uri{scheme} eq ""){
      $uri{error}=("URL syntax error or no scheme specified");
      return(\%uri);
   }

   my @nonStdSchema=qw(oracle net8 mssql mysql informix scp 
                       ssh pesit sftp 
                       smtp imap imaps
                       tcp udp);

   my @sok=(qw(http ldap ldaps https file mailto ftp rlogin),@nonStdSchema);
   if (!in_array(\@sok,$uri{scheme})){
      $uri{error}=("not supported scheme specified");
      return(\%uri);
   }

   if (in_array([qw(ftp http ldap ldaps https file)],$uri{scheme})){
      $uri{host}=lc(URI->new($name)->host());
      if ($uri{host} eq ""){
         $uri{error}=("can not identify host in URL");
         return(\%uri);
      }
      $uri{port}=URI->new($name)->port();

   } else {
      my $befhost=qr{\@}; # character before the host
      $befhost=qr{://} if (index($name,'@')==-1);
         
      my ($host,$port)=$name=~m/$befhost([^:\/]+)(?:\:(\d+))?/;
      if (in_array(\@nonStdSchema,$uri{scheme})) {
         $uri{host}=$host;
         $uri{port}=$port if ($port);
      }
      if (!$uri{port}) {
         $uri{port}=22 if ($uri{scheme} eq 'ssh');
         $uri{port}=22 if ($uri{scheme} eq 'sftp');
         $uri{port}=22 if ($uri{scheme} eq 'scp');
         $uri{port}=25 if ($uri{scheme} eq 'smtp');
         $uri{port}=143 if ($uri{scheme} eq 'imap');
         $uri{port}=993 if ($uri{scheme} eq 'imaps');
      }
   }

   if ($uri{host}) {
      if ($uri{host}=~m/^\d+\.\d+\.\d+\.\d+$/ || # IPv4
          $uri{host}=~m/[\[\]]/) { # IPv6
         my $ipcheckresult;
         if (!IPValidate($uri{host},\$ipcheckresult)) {
            $uri{error}=$ipcheckresult;
            return(\%uri);
         }
      }
      elsif ($uri{host}=~m/[^A-Za-z0-9.:\-\[\]]/ || # allowed characters
          $uri{host}=~m/(^\.)|([.\-]$)/ || # must not start with .
                                           # or end with . or -
          !($uri{host}=~m/\.[a-z]{2,}$/i)) # TLD must have more than 1 character
      { 
         $uri{error}=("invalid hostname");
         return(\%uri);
      }

   }

   return(\%uri);
}

sub IPValidate {
   my $ip=shift;
   my $msg=shift;
   my $type;

   if ($ip=~m/^\s*$/){
      $$msg="invalid ip-address or empty specified";
      return(undef);
   }

   if (my ($o1,$o2,$o3,$o4)=$ip=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/){
      if (($o1<0 || $o1 >255 ||
           $o2<0 || $o2 >255 ||
           $o3<0 || $o3 >255 ||
           $o4<0 || $o4 >255)||
          ($o1==0 && $o2==0 && $o3==0 && $o4==0) ||
          ($o1==255 && $o2==255 && $o3==255 && $o4==255)){
         $$msg="invalid IPv4 address";
         return(undef);
      }
      $type="IPv4";

   } else {
      $ip=~s/^\[(.*)\]$/$1/;
      my @groups=split(/:/,$ip,-1);

      if (@groups!=8) {
         $$msg="unknown ip-address format";
         return(undef);
      }

      foreach my $g (@groups) {
         if (!($g=~m/^[0-9a-f]{0,4}$/i)) {
            $$msg="invalid IPv6 address";
            return(undef);
         }
      }
      $type="IPv6";
   }

   return($type);
}




1;
