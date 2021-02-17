package W5Base::API;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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

=pod

=head1 NAME

W5Base::API - documentation and native W5Base SOAP calls

=begin __INTERNALS

=head1 PORTABILITY

This module is designed to be portable across operating systems
and it currently supports Unix, VMS, DOS, OS/2 and Windows. When
porting to a new OS there are generally three main issues
that have to be solved:

=end __INTERNALS


=head1 DESCRIPTION

W5Base::ATI.pm is a perl interface to make the use of SOAP calls to W5Base server a little bit easir.

=head1 FUNCTIONS

=head2 XGetOptions()

 $optresult=XGetOptions(\%P,\&Help,$prestore,undef,".W5Base.Interface",
                        [noautologin=>1|0]);

This function isn't needed to comunicate to W5Base, but it helps you to
handle your work-script parameters in a comfortable kind.
In %P you have to specify the posible parameters in Getopt::Long style.
\&Help is a callback method, witch will be called on paramater problems.
The last parameter is the filename, in witch the parameters are stored,
if the --store option is specified by user.
If you specify a callback $prestore, you can modify parameters before they
will be written to storefile.


=head2 XGetFQStoreFilename()

 $fqstorefilename=XGetFQStoreFilename([$storefile]);

Is only needed, if you need direct access to the store methods called from
XGetOptions(). XGetFQStoreFilename() calculates an full qualified storefile
name from by passing an storfilename whitch can be a relative name.

=head2 XLoadStoreFile()

 $sresult=XLoadStoreFile($storefile,$param);

Is only needed, if you need direct access to the store methods called from
XGetOptions(). XLoadStoreFile() reads all stored variables from $storefile
and write them in the hash pointer $param.

=head2 XSaveStoreFile()

 $sresult=XSaveStoreFile($storefile,$param);

Is only needed, if you need direct access to the store methods called from
XGetOptions(). XSaveStoreFile() saves all keys in hash pointer $param in
the specified $storefile.

=head2 createConfig()

 $config=createConfig($base,$loginuser,$loginpass,$lang,$apidebug);
 $config=createConfig($base,$loginuser,$loginpass,$lang,$apidebug,
                      \$exitcode,\$msgs);
 $config=createConfig($base,$loginuser,$loginpass,$lang,$apidebug,
                      undef,undef,timeout=>10000);

The createConfig() function validates the configuration, checks the communication to the desiered W5Base-SOAP-Server and returns a config object on success.
If it fails, you can get a human readable error message if you specifed 
two references (\$exitcode,\$msgs) in witch the method can store these 
informations.


=head1 OBJECT CONSTRUCTOR

=head2 getModuleObject()

 $dataobject=getModuleObject($config,$dataobjectname);
 $dataobject=getModuleObject($config,$dataobjectname,\$exitcode,\$msgs);

There is no constructor in the classical kind. The function getModuleObject
returns a dataobject or undef if it fails. If it fails, you can get a
human readable error message if you specifed two references (\$exitcode,\$msgs) in witch the method can store these informations.

=head2 getUserAgent()

 $ua=getUserAgent($config);

Returns a LWP::UserAgent Object, as base of SOAP communication to the
W5Base server.

=head1 OBJECT METHODS

=head2 showFields()

 $dataobject->showFields();

If you need informations about the availabel fields in the current dataobject,
you can read these by calling showFields. There are only these fields displayed, which are static and global in the dataobject. Record specified field informations couldn't be queried.
The return value is an array of hash references with the field informations.

=head2 SetFilter()

 $dataobject->SetFilter()

The filters are a simple hash reference. In the keys you have to use the
interal fieldnames (see showFields() ) and in the values, you can use the
same filter expressions like in the Web-Browser frontend.

Wildcards like *,? oder negation like ! - for greater or less then use < or >. For further informations about filters check the help pages in the Web-Browser interface.

Calling SetFilter is nesassary, if you wan't to use the method getHashList() . To clear all filters, ResetFilter() is to use.

=head2 ResetFilter()

 $dataobject->ResetFilter()

With ResetFilter() all filters stored with SetFilter() will be deleted.

=head2 getHashList()

 @records=$dataobject->getHashList(qw(fieldname1 fieldname2 ...));

To read the datarecords filterd with SetFilter() a call of getHashList() needs
to be used. As parameters to getHashList() you specify an array with the
list of fieldnames you want to read.
The result is a array of hash references on success.

=head2 storeRecord()

 $id=$dataobject->storeRecord({field1=>'val',field2=>'val'}); 
 $id=$dataobject->storeRecord({field1=>'val',field2=>'val'},$id); 

If storeRecord() is called with $id, it will update the specified record. If
$id is not specified or undef, storeRecord() will try to insert a new record.
Any way, the unique identifier of the processed record will returned on success.

=head2 deleteRecord()

 $dataobject->deleteRecord($id); 

A call to deleteRecord() deletes the record identified by $id.

=head2 dieOnERROR()

 $dataobject->dieOnERROR(); 

A simple check, if in LastMsg is any error message the current programm die's.

=head2 LastMsg()



=head1 NATIVE SOAP-INTERFACE

All SOAP calls to W5Base need the call structure:

 <?xml version="1.0" encoding="UTF-8"?>
 <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
       xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
       xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
       xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
       soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <!-- SOAP Body -->
 </soap:Envelope>

The SOAP body describes the call, you want to process on the W5Base 
server. In the following documentation only the SOAP body is described.
All method calls needs  B<xmlns="http://w5base.net/interface/SOAP"> in the method call. You can specifiy in all calls a B<lang>, but at now only 'en' will be used. The lang defines the language of the lastmsg values.

The result of an method call always contains the field B<exitcode>. If this isn't 0, there will be also a field B<lastmsg> in the answer, witch contains the error in a human readable form.

=head2 SOAP-Method: Ping

With the ping method, you can do a native communication check. If this call returns an exitcode=0 your transport, authentication and SOAP call convention is correct. It is a good way to do a "Hello World!" in SOAP communication with the W5Base Server.

 <soap:Body>
   <Ping xmlns="http://w5base.net/interface/SOAP" xsi:nil="true"/>
 </soap:Body>

If all is fine, you will get a SOAP response like that:

 <soap:Body>
   <PingResponse xmlns="http://w5base.net/interface/SOAP">
     <s-gensym15>
       <exitcode xsi:type="xsd:int">0</exitcode>
       <result   xsi:type="xsd:int">1</result>
     </s-gensym15>
   </PingResponse>
 </soap:Body>

B<Input:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : Ping
  parts:
    lang          : xsd:string

B<Output:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : PingResponse
  parts:
    exitcode      : xsd:int
    lastmsg       : soapenc:arrayType [ xsd:string ]
    result        : xsd:int

=head2 SOAP-Method: validateObjectname

To verify the naming of an dataobject you can use this method. In W5Base::API this call is used in the API-Method getModuleOjbject to verify a valid objectname specification.

B<Input:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : validateObjectname
  parts:
    dataobject    : xsd:string
    lang          : xsd:string

B<Output:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : validateObjectnameResponse
  parts:
    exitcode      : xsd:int
    lastmsg       : soapenc:arrayType [ xsd:string ]

=head2 SOAP-Method: showFields

With the showFields message, you can get informations about the structure (available fields) of the specified dataobject in the output array 'records'.

B<Input:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : showFields
  parts:
    dataobject    : xsd:string
    lang          : xsd:string

B<Output:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : showFieldsResponse
  parts:
    exitcode      : xsd:int
    lastmsg       : soapenc:arrayType [ xsd:string ]
    records       : soapenc:arrayType

=head2 SOAP-Method: getHashList

The getHashList message is the basic search function. By specifing 'filter' and 'view' you can search any informations in the W5Base witch are accessable by your useraccount.

B<Input:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : getHashList
  parts:
    dataobject    : xsd:string
    view          : soapenc:arrayType [ xsd:string ]
    filter        : list of field filters
    lang          : xsd:string

B<Output:>

  namespace     : http://w5base.net/interface/SOAP
  encodingStyle : http://schemas.xmlsoap.org/soap/encoding/
  message       : getHashListResponse
  parts:
    exitcode      : xsd:int
    lastmsg       : soapenc:arrayType [ xsd:string ]
    records       : soapenc:arrayType



=head2 SOAP-Method: storeRecord

documentation is ToDo.

=head2 SOAP-Method: deleteRecord

documentation is ToDo.

=head2 SOAP-Method: getPosibleWorkflowActions

not implemented at now (02/2008)

=head2 SOAP-Method: processWorkflowAction

not implemented at now (02/2008)

=cut


use 5.005;
use strict;
use vars qw(@EXPORT @ISA $VERSION);
use Exporter;
use Getopt::Long;
use FindBin qw($RealScript);
use Config;
use POSIX qw(strftime);

$VERSION = "2.0";
@ISA = qw(Exporter);
@EXPORT = qw(&msg &ERROR &WARN &DEBUG &INFO $RealScript
             &XGetOptions
             &XGetFQStoreFilename
             &XLoadStoreFile
             &XSaveStoreFile
             &createConfig
             &getModuleObject
             &getUserAgent
             );

sub ERROR() {return("ERROR")}
sub WARN()  {return("WARN")}
sub DEBUG() {return("DEBUG")}
sub INFO()  {return("INFO")}

our $MsgTimestamp="";

sub msg
{
   my $type=shift;
   my $msg=shift;
   my $format="\%-6s \%s\n";
   my $tspref="";

   if ($MsgTimestamp ne ""){
      $tspref=strftime($MsgTimestamp,localtime()); 
   } 
   if ($type eq "ERROR" || $type eq "WARN"){
      foreach my $submsg (split(/\n/,$msg)){
         printf STDERR ($tspref.$format,$type.":",$submsg);
      }
   }
   else{
      foreach my $submsg (split(/\n/,$msg)){
         printf STDOUT ($tspref.$format,$type.":",$submsg) if ($Main::VERBOSE ||
                                                       $type eq "INFO");
      }
   }
}

#######################################################################
# my special handler
#
# $optresult=XGetOptions(\%ARGPARAM,\&Help,\&preStore,".W5Base",[noautologin=>1|0]);
# msg("INFO","xxx");
#  
sub XGetOptions
{
   my $param=shift;
   my $help=shift;
   my $prestore=shift;
   my $defaults=shift;
   my $storefile=shift;
   my %param=@_;
   my $optresult;

   my $store;
   $param->{store}=\$store if (!defined($param->{store}));
   my $if;
   $param->{'initfile=s'}=\$if if (!defined($param->{'initfile=s'}));
   $param->{'initfile=s'}=\$if if (defined($param->{'initfile=s'}) &&
                                   ref($param->{'initfile=s'}) eq "SCALAR" && 
                                   defined(${$param->{'initfile=s'}}) &&
                                   ${$param->{'initfile=s'}} eq "");

   if (!($optresult=GetOptions(%$param))){
      if (defined($help)){
         &$help();
      }
      exit(1);
   }
   if (defined(${$param->{'initfile=s'}}) && ${$param->{'initfile=s'}} ne ""){
      if (! (-r ${$param->{'initfile=s'}})){
         printf STDERR ("ERROR: can't read initfile '%s'\n",
                        ${$param->{'initfile=s'}});
         exit(255);
      }
      else{
         $storefile=${$param->{'initfile=s'}};
      }
   }

   $storefile=XGetFQStoreFilename($storefile);

   if (defined(${$param->{help}}) && (${$param->{help}})){
      &$help();
      exit(0);
   }
   if (defined($prestore)){
      &$prestore($param);
   }
   my $sresult=XLoadStoreFile($storefile,$param);
   if ($sresult){
      printf STDERR ("ERROR: $!\n");
      exit(255);
   }
   if (exists($param->{'X-API-Key=s'})){
      if (!defined(${$param->{'X-API-Key=s'}}) && !$param{noautologin}){
         my $u;
         while(1){
            printf("X-API-Key: ");
            $u=<STDIN>;
            $u=~s/\s*$//;
            last if ($u ne "");
         }
         ${$param->{'X-API-Key=s'}}=$u;
      }
   }
   else{
      if (!defined(${$param->{'webuser=s'}}) && !$param{noautologin}){
         my $u;
         while(1){
            printf("login user: ");
            $u=<STDIN>;
            $u=~s/\s*$//;
            last if ($u ne "");
         }
         ${$param->{'webuser=s'}}=$u;
      }
      if (!defined(${$param->{'webpass=s'}}) && !$param{noautologin}){
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
   }
   if (${$param->{store}}){
      my $sresult=XSaveStoreFile($storefile,$param);
      if ($sresult){
         printf STDERR ("ERROR: $!\n");
         exit(255);
      }
   }
   if (defined($defaults)){
      &$defaults($param);
   }
   if (defined($param->{'verbose+'}) &&
       ref($param->{'verbose+'}) eq "SCALAR" &&
       ${$param->{'verbose+'}}>1){
      $Main::VERBOSE=1;
      msg(INFO,"using parameters:");
      foreach my $p (sort(keys(%$param))){
         my $pname=$p;
         $pname=~s/=.*$//;
         $pname=~s/\+.*$//;
         next if (($pname=~m/(pass|password)$/) &&
                   ${$param->{'verbose+'}}<4);
         my $ot=$param->{$p};
         $ot=$$ot if (ref($ot) eq "SCALAR");
         $ot=join(", ",@{$ot}) if (ref($ot) eq "ARRAY");
         msg(INFO,sprintf("%8s = '%s'",$pname,defined($ot) ? $ot : "[undef]"));
      }
      msg(INFO,"-----------------");
   }
   return($optresult);
}

sub XGetFQStoreFilename
{
   my $storefile=shift;
   my $home;
   $storefile=".W5API" if ($storefile eq "");
   if ($Config{'osname'} eq "MSWin32"){
      $home=$ENV{'HOMEPATH'};
   }else{
      $home=$ENV{'HOME'};
   }
   if (!($storefile=~m/^\//) &&
       !($storefile=~m/\\/)){ # finding the home directory
      if ($home eq ""){
         eval('
            while(my @pline=getpwent()){
               if ($pline[1]==$< && $pline[7] ne ""){
                  $home=$pline[7];
                  last;
               }
            }
            endpwent();
         ');
      }
      if ($home ne ""){
         $storefile=$home."/".$storefile;
      }
   }
   $storefile=$ENV{'HOMEDRIVE'}.$storefile if ($Config{'osname'} eq "MSWin32");
   return($storefile);
}

sub XLoadStoreFile
{
   my $storefile=shift;
   my $param=shift;
   my %forceload=();

   if (open(F,"<".$storefile)){
      while(my $l=<F>){
         $l=~s/\s*$//;
         if (my ($var,$val)=$l=~m/^(\S+)\t(.*)$/){
            if (exists($param->{$var})){
               if (!(${$param->{store}}) || $var eq "webuser=s" ||
                   $var eq "webpass=s"){
                  if (ref($param->{$var}) eq "SCALAR"){
                     if (!defined(${$param->{$var}})){
                        ${$param->{$var}}=unpack("u*",$val);
                     }
                  }
                  if (ref($param->{$var}) eq "ARRAY" &&
                      ($#{$param->{$var}}==-1 || $forceload{$var})){
                     $forceload{$var}++;
                     push(@{$param->{$var}},unpack("u*",$val));
                  }
               }
            }
         }
      }
      close(F);
   }
   return(0);
}

sub XSaveStoreFile
{
   my $storefile=shift;
   my $param=shift;

   if (open(F,">".$storefile)){
      foreach my $p (keys(%$param)){
         next if ($p=~m/^verbose.*/);
         next if ($p=~m/^help$/);
         next if ($p=~m/^store$/);
         if (ref($param->{$p}) eq "SCALAR" &&
             defined(${$param->{$p}})){
            my $pstring=pack("u*",${$param->{$p}});
            $pstring=~s/\n//g;
            printf F ("%s\t%s\n",$p,$pstring);
         }
         if (ref($param->{$p}) eq "ARRAY"){
            foreach my $val (@{$param->{$p}}){
               if (defined($val)){
                  my $pstring=pack("u*",$val);
                  $pstring=~s/\n//g;
                  printf F ("%s\t%s\n",$p,$pstring);
               }
            }
         }
      }
      close(F);
   }
   else{
      return($?);
   }
   return(0);
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
   my $backexitcode=shift;
   my $backexitmsg=shift;
   my %param=@_;

   $W5Base::User=$user;
   $W5Base::Pass=$pass;
   $base.="/" if (!($base=~m/\/$/));
   $lang="en" if ($lang eq "");
   if ($user eq "X-API-Key"){
      $base=~s#/auth/$#/public/#;  # API Keys always uses public url
   }
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
   my @proxyparam=($proxy);
   if (defined($param{timeout})){
      push(@proxyparam,"timeout",$param{timeout});
   }
   my $SOAP=SOAP::Lite->uri($uri)->proxy(@proxyparam)->xmlschema("2001");



#   my @r=$SOAP->Ping({lang=>\$lang})->result;


#   use Data::Dumper;
#
#   printf STDERR ("fifi exitcode=%s\n",Dumper(\@r));
#
#   exit(0);



   my $SOAPresult=eval("\$SOAP->Ping({lang=>\$lang});");
   my $result;
   if (!($SOAP->transport->status=~m/^(200|500)\s.*$/)){
      if (defined($backexitmsg)){
         $$backexitmsg=$SOAP->transport->status;
      }
      else{
         if (!$param{quiet}){
            msg(ERROR,"HTTP transport error");
            msg(ERROR,$SOAP->transport->status);
         }
      }
      if (defined($backexitcode)){
         $$backexitcode=255;
      }
      else{
         if (!$param{quiet}){
            exit(255);
         }
      }
   }
   if (defined($SOAPresult)){
      if ($SOAPresult->faultcode){
         if (defined($backexitmsg)){
            $backexitmsg=$SOAPresult->faultstring;
         }
         else{
            msg(ERROR,"server error: ".$SOAPresult->faultstring);
         }
         if (defined($backexitcode)){
            $$backexitcode=255;
         }
         else{
            exit(255);
         }
      }
      $result=$SOAPresult->result;
   }

   return(undef) if (!defined($result) || 
                     (ref($result) ne "HASH" && ref($result) ne "Struct") ||
                     $result->{result}==0);

   return({base=>$base,user=>$user,pass=>$pass,SOAP=>$SOAP,
           lang=>$lang,debug=>$debug});
}

sub getModuleObject
{
   my $config=shift;
   my $objectname=shift;
   my $SOAP=$config->{SOAP};
   my $SOAPresult=eval("\$SOAP->validateObjectname({dataobject=>\$objectname,
                                                lang=>\$config->{lang}})");
   return(undef) if (!defined($SOAPresult));
   my $result=$SOAPresult->result;
   if ($config->{user} eq "X-API-Key"){
      $SOAP->transport->http_request->header("X-API-Key"=>$config->{pass});
   }
   return(undef) if (!defined($result) || $result->{exitcode}!=0);
   return(new W5Base::ModuleObject(CONFIG=>$config,SOAP=>$SOAP,
                                   NAME=>$objectname));
}

sub getUserAgent
{
   my $config=shift;
   my $objectname=shift;
   my $SOAP=$config->{SOAP};
   return($SOAP->transport);
}

package W5Base::ModuleObject;
use Data::Dumper;

sub ERROR() {return("ERROR")}
sub WARN()  {return("WARN")}
sub DEBUG() {return("DEBUG")}
sub INFO()  {return("INFO")}

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   return($self);
}



#
# Information and Status methods
#

sub showFields
{
   my $self=shift;
   my $SOAPresult=$self->SOAP->showFields({dataobject=>$self->Name,
                                           lang=>$self->Config->{lang}});

   my $result=$self->_analyseSOAPresult($SOAPresult);
   if (defined($result)){
      $self->{exitcode}=$result->{exitcode};
      if ($self->{exitcode}==0){
         delete($self->{lastmsg});
         return(@{$result->{records}});
      }
      $self->{lastmsg}=$result->{lastmsg};
   }
   return;
}

sub LastMsg
{
   my $self=shift;
   my $msg=shift;

   if (wantarray()){
      return(undef) if (!defined($self->{lastmsg}));
      return(@{$self->{lastmsg}});
   }
   return(0) if (!defined($self->{lastmsg}));
   if (ref($self->{lastmsg}) ne "ARRAY"){
      $self->{lastmsg}=[$self->{lastmsg}];
   }
   return($#{$self->{lastmsg}}+1);
}

sub dieOnERROR
{
   my $self=shift;
   if ($self->LastMsg()){
      foreach my $msg ($self->LastMsg()){
         if (ref($msg) eq "ARRAY" ||
             ref($msg) eq "ArrayOfStringItems"){
            printf STDERR ("%s\n",join("\n",@$msg));
         }
         else{
            printf STDERR ("%s\n",$msg);
         }
      }
      $self->{exitcode}=-1 if ($self->{exitcode}==0);
      exit($self->{exitcode});
   }
}




#
# Read methods
#

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

sub Limit
{
   my $self=shift;
   my $limit=shift;
   my $limitstart=shift;
   if (defined($limit) && $limit=~m/^\d+$/ && $limit>0){
      $self->{LIMIT}=$limit;
   }
   else{
      delete($self->{LIMIT});
   }
   if (defined($limitstart) && $limitstart=~m/^\d+$/){
      $self->{LIMITSTART}=$limitstart;
   }
   else{
      delete($self->{LIMITSTART});
   }
}

sub getHashList
{
   my $self=shift;
   my @view=@_;

   my $req={dataobject=>$self->Name,
            view=>\@view,
            lang=>$self->Config->{lang},
            filter=>$self->Filter};
   if (defined($self->{LIMIT})){
      $req->{limit}=$self->{LIMIT};
   }
   if (defined($self->{LIMITSTART})){
      $req->{limitstart}=$self->{LIMITSTART};
   }
   my $SOAPresult;
   eval('$SOAPresult=$self->SOAP->getHashList($req);');
   if ($@){
      if ($@=~m/^500 /){
         $self->{exitcode}=500;
         $self->{lastmsg}=$@;
      }
      else{
         $self->{exitcode}=1;
         $self->{lastmsg}="unknown error: $@";
      }
      return;
   }
   else{
      my $result=$self->_analyseSOAPresult($SOAPresult);
      if (defined($result)){
         $self->{exitcode}=$result->{exitcode};
         if ($self->{exitcode}==0){
            delete($self->{lastmsg});
            return(@{$result->{records}});
         }
         $self->{lastmsg}=$result->{lastmsg};
      }
   }
   return;
}


#
# Write methods
#

sub storeRecord
{
   my $self=shift;
   my $data=shift;
   my $flt=shift;
   if (ref($flt)){
      msg(ERROR,"storeRecord didn't supports hash filters");
      exit(1);
   }
   my @ent;
   foreach my $k (keys(%$data)){
      if (ref($data->{$k}) eq "MIME::Entity"){
         push(@ent,$data->{$k});
         $data->{$k}=["MIME::Entity"=>$#ent];
      }
   } 
   my $SOAPresult=$self->SOAP->parts(\@ent)->storeRecord({dataobject=>$self->Name,
                                            data=>$data,
                                            lang=>$self->Config->{lang},
                                            IdentifiedBy=>$flt});
   my $result=$self->_analyseSOAPresult($SOAPresult);
   if (defined($result)){
      $self->{exitcode}=$result->{exitcode};
      if ($self->{exitcode}==0){
         delete($self->{lastmsg});
         return($result->{IdentifiedBy});
      }
      $self->{lastmsg}=$result->{lastmsg};
   }
   return(undef); 
}


sub deleteRecord
{
   my $self=shift;
   my $flt=shift;
   if (ref($flt)){
      msg(ERROR,"deleteRecord didn't supports hash filters");
      exit(1);
   }
   my $SOAPresult=$self->SOAP->deleteRecord({dataobject=>$self->Name,
                                             lang=>$self->Config->{lang},
                                             IdentifiedBy=>$flt});
   my $result=$self->_analyseSOAPresult($SOAPresult);
   if (defined($result)){
      $self->{exitcode}=$result->{exitcode};
      if ($self->{exitcode}==0){
         delete($self->{lastmsg});
         return($result->{IdentifiedBy});
      }
      $self->{lastmsg}=$result->{lastmsg};
   }
   return(undef); 
}


sub getRelatedWorkflows
{
   my $self=shift;
   my $dataobjectid=shift;
   my $param=shift;
   my $SOAPresult=$self->SOAP->getRelatedWorkflows({dataobject=>$self->Name,
                                             lang=>$self->Config->{lang},
                                             IdentifiedBy=>$dataobjectid,
                                             timerange=>$param->{timerange},
                                             fulltext=>$param->{fulltext},
                                             class=>$param->{class}});
   my $result=$self->_analyseSOAPresult($SOAPresult);
   if (defined($result)){
      $self->{exitcode}=$result->{exitcode};
      if ($self->{exitcode}==0){
         delete($self->{lastmsg});
         return(@{$result->{workflows}});
      }
      $self->{lastmsg}=$result->{lastmsg};
   }
   return(undef); 
}




#
# internal methods
#

sub _analyseSOAPresult
{
   my $self=shift; 
   my $SOAPresult=shift;

   if (!($self->SOAP->transport->status=~m/^(200|500)\s.*$/)){
      $self->{lastmsg}=["ERROR:  transport(".$self->SOAP->transport->status.")"];
      $self->{exitcode}=255;
      return(undef);
   }
   if (defined($SOAPresult)){
      if ($SOAPresult->faultcode){
         my $faultstring=$SOAPresult->faultstring;
         $faultstring=~s/\s*$//;
         $self->{lastmsg}=["ERROR: method($faultstring)"];
         $self->{exitcode}=254;
         return(undef);
      }
   }
   else{
      $self->{lastmsg}=["ERROR: no valid SOAP result"];
      $self->{exitcode}=253;
      return(undef);
   }
   return($SOAPresult->result);
}


sub SOAP   {$_[0]->{SOAP}}
sub Name   {$_[0]->{NAME}}
sub Filter {$_[0]->{FILTER}}
sub Config {$_[0]->{CONFIG}}

=pod

=head1 COPYRIGHT

Copyright (C) 2008 Hartmut Vogler. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;

