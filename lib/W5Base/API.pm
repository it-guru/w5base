package W5Base::API;
#  W5Base Framework
#  Copyright (C) 2008  Hartmut Vogler (it@guru.de)
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
use vars qw(@EXPORT @ISA);
use Exporter;
use Getopt::Long;
use FindBin qw($RealScript);

@ISA = qw(Exporter);
@EXPORT = qw(&msg &ERROR &WARN &DEBUG &INFO $RealScript
             &XGetOptions
             &createConfig
             &getModuleObject);

sub ERROR() {return("ERROR")}
sub WARN()  {return("WARN")}
sub DEBUG() {return("DEBUG")}
sub INFO()  {return("INFO")}

sub msg
{
   my $type=shift;
   my $msg=shift;
   my $format="\%-6s \%s\n";

   if ($type eq "ERROR" || $type eq "WARN"){
      foreach my $submsg (split(/\n/,$msg)){
         printf STDERR ($format,$type.":",$submsg);
      }
   }
   else{
      foreach my $submsg (split(/\n/,$msg)){
         printf STDOUT ($format,$type.":",$submsg) if ($Main::VERBOSE);
      }
   }
}

#######################################################################
# my special handler
#
# $optresult=XGetOptions(\%ARGPARAM,\&Help,\&preStore,".W5Base");
# msg("INFO","xxx");
#  
sub XGetOptions
{
   my $param=shift;
   my $help=shift;
   my $prestore=shift;
   my $defaults=shift;
   my $storefile=shift;
   my $optresult;
   if (!($storefile=~m/^\//)){ # finding the home directory
      if ($ENV{HOME} eq ""){
         eval('
            while(my @pline=getpwent()){
               if ($pline[1]==$< && $pline[7] ne ""){
                  $ENV{HOME}=$pline[7];
                  last;
               }
            }
            endpwent();
         ');
      }
      if ($ENV{HOME} ne ""){
         $storefile=$ENV{HOME}."/".$storefile;
      }
   }
   my $store;
   $param->{store}=\$store;

   if (!($optresult=GetOptions(%$param))){
      if (defined($help)){
         &$help();
      }
      exit(1);
   }
   if (defined(${$param->{help}})){
      &$help();
      exit(0);
   }
   if (open(F,"<".$storefile)){
      if (defined($prestore)){
         &$prestore($param);
      }
      while(my $l=<F>){
         $l=~s/\s*$//;
         if (my ($var,$val)=$l=~m/^(\S+)\t(.*)$/){
            if (exists($param->{$var})){
               if (!(${$param->{store}}) || $var eq "webuser=s" ||
                   $var eq "webpass=s"){
                  if (!defined(${$param->{$var}})){
                     ${$param->{$var}}=unpack("u*",$val);
                  }
               }
            }
         }
      }
      close(F);
   }
   if (!defined(${$param->{'webuser=s'}})){
      my $u;
      while(1){
         printf("login user: ");
         $u=<STDIN>;
         $u=~s/\s*$//;
         last if ($u ne "");
      }
      ${$param->{'webuser=s'}}=$u;
   }
   if (!defined(${$param->{'webpass=s'}})){
      my $p="";
      system("stty -echo 2>/dev/null");
      $SIG{INT}=sub{ system("stty echo 2>/dev/null");print("\n");exit(1)};
      while(1){
         printf("password: ");
         $p=<STDIN>;
         $p=~s/\s*$//;
         printf("\n");
         last if ($p ne "");
      }
      system("stty echo 2>/dev/null");
      $SIG{INT}='default';
      ${$param->{'webpass=s'}}=$p;
   }
   if (${$param->{store}}){
      if (open(F,">".$storefile)){
         foreach my $p (keys(%$param)){
            next if ($p=~m/^verbose.*/);
            next if ($p=~m/^help$/);
            next if ($p=~m/^store$/);
            if (defined(${$param->{$p}})){
               my $pstring=pack("u*",${$param->{$p}});
               $pstring=~s/\n//g;
               printf F ("%s\t%s\n",$p,$pstring);
            }
         }
         close(F);
      }
      else{
         printf STDERR ("ERROR: $!\n");
         exit(255);
      }
   }
   if (defined($defaults)){
      &$defaults($param);
   }
   if (defined($param->{'verbose+'}) &&
       ref($param->{'verbose+'}) eq "SCALAR" &&
       ${$param->{'verbose+'}}>0){
      $Main::VERBOSE=1;
      msg(INFO,"using parameters:");
      foreach my $p (sort(keys(%$param))){
         my $pname=$p;
         $pname=~s/=.*$//;
         $pname=~s/\+.*$//;
         msg(INFO,sprintf("%8s = '%s'",$pname,${$param->{$p}}));
      }
      msg(INFO,"-----------------");
   }
   return($optresult);
}



sub SOAP::Transport::HTTP::Client::get_basic_credentials
{ 
   return($W5Base::User,$W5Base::Pass);
}


sub createConfig
{
   my $base=shift;
   my $user=shift;
   my $pass=shift;
   my $lang=shift;
   my $debug=shift;

   $W5Base::User=$user;
   $W5Base::Pass=$pass;
   $base.="/" if (!($base=~m/\/$/));
   $lang="en" if ($lang eq "");
   my $proxy=$base.="base/interface/SOAP";
   my $uri="http://w5base.net/interface/SOAP";

   if ($debug){
      eval("use SOAP::Lite +trace=>'all';");
   }
   else{
      eval("use SOAP::Lite;");
   }
   if ($@ ne ""){
      msg(ERROR,$@);
      exit(128);
   }
   my $SOAP=SOAP::Lite->uri($uri)->proxy($proxy);

   my $result=eval("\$SOAP->Ping()->result;");

   return(undef) if (!defined($result));

   return({base=>$base,user=>$user,pass=>$pass,SOAP=>$SOAP,
           lang=>$lang,debug=>$debug});
}

sub getModuleObject
{
   my $config=shift;
   my $objectname=shift;
   my $SOAP=$config->{SOAP};
   my $result=eval("\$SOAP->validateObjectname({dataobject=>\$objectname,
                                                lang=>\$config->{lang}})
                          ->result;");
   return(undef) if (!defined($result) || $result->{exitcode}!=0);
   return(new W5Base::ModuleObject(CONFIG=>$config,SOAP=>$SOAP,
                                   NAME=>$objectname));
}

package W5Base::ModuleObject;
use Data::Dumper;

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}

sub ResetFilter
{
   my $self=shift;
   delete($self->{FILTER});
}

sub SetFilter
{
   my $self=shift;
   my $filter=shift;
   $self->{FILTER}=$filter;
}

sub storeRecord
{
   my $self=shift;
   my $data=shift;
   my $flt=shift;
   if (ref($flt)){
      printf STDERR ("not supported\n");
      return(undef);
   }
   my $res=$self->SOAP->storeRecord({dataobject=>$self->Name,
                                     data=>$data,
                                     lang=>$self->{CONFIG}->{lang},
                                     IdentifiedBy=>$flt})->result;
   $self->{exitcode}=$res->{exitcode};
   if ($self->{exitcode}==0){
      delete($self->{lastmsg});
      return();
   }
   $self->{lastmsg}=$res->{lastmsg};
}

sub showFields
{
   my $self=shift;
   my $res=$self->SOAP->showFields({dataobject=>$self->Name,
                                    lang=>$self->{CONFIG}->{lang}
                                   })->result;

   $self->{exitcode}=$res->{exitcode};
   if ($self->{exitcode}==0){
      delete($self->{lastmsg});
      return(@{$res->{records}});
   }
   $self->{lastmsg}=$res->{lastmsg};
   return(undef);
}

sub getHashList
{
   my $self=shift;
   my @view=@_;
   my $res=$self->SOAP->getHashList({dataobject=>$self->Name,
                                     view=>\@view,
                                     lang=>$self->{CONFIG}->{lang},
                                     filter=>$self->{FILTER}
                                    })->result;
   $self->{exitcode}=$res->{exitcode};
   if ($self->{exitcode}==0){
      delete($self->{lastmsg});
      return(@{$res->{records}});
   }
   $self->{lastmsg}=$res->{lastmsg};
   return(undef);
}

sub SOAP   {$_[0]->{SOAP}}
sub Name   {$_[0]->{NAME}}
sub Filter {$_[0]->{FILTER}}
sub Config {$_[0]->{CONFIG}}




#my $SOAP=SOAP::Lite->uri('http://www.w5base.net/interface/SOAP')
#                   ->proxy('http://localhost/w5base2/auth/base/interface/SOAP');
#
#
#use Data::Dumper;
#
#
#my $res=getHashList("xx");
#
#print "d=".Dumper($res)."\n";
#
#
#sub getHashList
#{
#   my $result=$SOAP->SOAPgetHashList("base::user",
#                                     [qw(fullname surname givenname)],
#                                     undef,
#                                     {surname=>"*vog*"})->result;
#   return($result);
#}
1;

