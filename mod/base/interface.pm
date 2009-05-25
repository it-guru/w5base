package base::interface;
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
use vars qw(@ISA);
use kernel;
use kernel::App::Web;
#use SOAP::Lite +trace => 'all', +debug=>'all';
use SOAP::Lite;
use SOAP::Transport::HTTP;
use File::Temp(qw(tempfile));
use File::Find;
use CGI;
@ISA=qw(kernel::App::Web);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->LoadSubObjs("ext/io","io");

   my $instdir=$self->Config->Param("INSTDIR");
   my $SOAPop='interface::SOAP';
   $self->{NS}={'http://w5base.net/kernel'=>$SOAPop};
   find({wanted=>sub{
            my $f=$File::Find::name;
            if (-f $f && ($f=~m/\.pm$/)){
               my $qinstdir=quotemeta($instdir);
               $f=~s#^$qinstdir##;
               $f=~s/\.pm$//; 
               if (!($f=~m/\/.svn/)){
                  $self->{NS}->{'http://w5base.net'.$f}=$SOAPop;
               }
            }
         },
         no_chdir=>1},
         $instdir."/mod");


   return($self);
}

sub getValidWebFunctions
{
   my ($self)=@_;
   return(qw(io Empty SOAP WSDL));
}

sub io
{
   my ($self)=@_;
   my $file=Query->Param("file");
   if (!defined($file)){
      print $self->HttpHeader("text/html");
      my $t=$self->T($self->Self());
      $t="" if ($t eq $self->Self());

      print $self->HtmlHeader(style=>'default.css',
                              title=>"W5Interface");
      print("<form method=post target=proc enctype=\"multipart/form-data\">");
      print("<table width=100%% height=100%%>".
            "<tr><td valign=top align=center style=\"padding-top:20px\">".
            "$ENV{SCRIPT_URI}<br><br>".
            "file:<input type=file size=30 name=file><br>".
            "<input type=submit value=\"process file via W5Interface\" ".
            "style=\"width:350px;margin-top:20px\">".
            "<br><iframe name=proc src=\"Empty\" ".
            "style=\"width:550px;margin-top:20px;height:300px\"></iframe>".
            "</td></tr></table></form>");
      print $self->HtmlBottom(body=>1);
      return();
   }
   print $self->XmlHead();
   if ($file eq ""){
      print hash2xml({exitcode=>1,
                      message =>msg(ERROR,'no input file specified')});
   }
   else{
      my $opokcount=0;
      my $failcount=0;
      my $exitcode=0;
      my $filename;
      my $f=Query->Param("file");
      if ($f ne ""){
         no strict;
         my $fh;
         ($fh, $filename)=tempfile();
         my $sizecheck=0;
         if (seek($f,0,SEEK_SET)){
            my $bsize=1024;
            my $data;
            my $fsize=0;
            while(1){
              my $nread = read($f, $data, $bsize);
              $fsize+=$nread;
              last if (!$nread);
              if ($fsize>10485760){
                 $sizecheck=1;
                 last;
              }
              syswrite($fh,$data,$nread);
            }
            close($fh);
         }
         if ($sizecheck){
            unlink($filename);
            print hash2xml({exitcode=>10,
                         message =>msg(ERROR,'request oversized')});
            print $self->XmlBottom();
            return();
         }
         ####################################################################
         ################ create a debug copy of request ####################
         ####################################################################
         my $requestdebug="io:".$ENV{REMOTE_USER};
         $requestdebug=~s/\//_/g;
         $requestdebug="/tmp/".$requestdebug.'.%02d.xml';
         my $requestdebugfile;
         for(my $c=9;$c>=0;$c--){
            $requestdebugfile=sprintf($requestdebug,$c);
            my $f2=sprintf($requestdebug,$c+1);
            if (-f $requestdebugfile){
               rename($requestdebugfile,$f2);
            }
         }
         my $oldumask=umask(0007);
         if (open(F,">$requestdebugfile")){
            binmode(F);
            if (open(FI,"<$filename")){
               binmode(FI);
               my $bsize=1024;
               my $data;
               while(1){
                 my $nread = read(FI, $data, $bsize);
                 last if (!$nread);
                 syswrite(F,$data,$nread);
               }
               close(FI);
            }
            close(F);
         }
         umask($oldumask);
         ####################################################################
         ####################################################################
         ####################################################################
      }
      if (!defined($filename)){
         print hash2xml({exitcode=>2,
                         message =>msg(ERROR,'unable to process file')});
      }
      else{
         my %op=();
         my $p;
         eval(<<EOF);
         sub XMLend {
            my (\$expat,\$e,\%attr)=\@_; 
            if (\$e eq "operation"){
               my \$res={line=>\$op{LINE},
               #         DEBUG=>Dumper(\\%op),
                        name=>\$op{NAME}};
               my (\$package)=\$op{NAME}=~m/^([^:]+)::/;
               \$res->{package}=\$package;
               \$res->{reference}=\$op{REFERENCE} if (defined(\$op{REFERENCE}));
               if (!defined(\$self->{io}->{\$package."::ext::io"})){
                  \$res->{exitcode}=100;
                  \$res->{message}=msg(ERROR,"no io handler at ".
                                            "package \$package");
               }
               else{
                  my \$iohandler=\$self->{io}->{\$package."::ext::io"};
                  msg(INFO,sprintf("W5IO-start: \%s by \%s",\$op{NAME},
                                   \$ENV{REMOTE_USER}));
                  \$W5V2::Query=new kernel::cgi({});
                  foreach my \$k (keys(\%op)){
                     \$op{\$k}=UTF8toLatin1(trim(\$op{\$k}));
                  }
                  \$res->{exitcode}=\$iohandler->Operation(\\%op,\$res);
                  if (\$res->{exitcode}!=0 || \$res->{exitcode} eq ""){
                     if (\$res->{exitcode} eq ""){
                        \$res->{exitcode}=1024;
                        \$self->LastMsg(ERROR,"unknown operation request");
                     }
                     if (!(\$self->LastMsg())){
                        \$self->LastMsg(ERROR,"unexpected W5Interface error");
                     }
                     \$failcount++; 
                  }
                  else{
                     \$opokcount++; 
                  }
                  \$exitcode+=\$res->{exitcode};
                  if (\$self->LastMsg()){
                     \$res->{message}=[\$self->LastMsg()];
                  }
                  msg(INFO,sprintf("W5IO-end  : \%s by \%s (\$res->{exitcode})",
                                   \$op{NAME}, \$ENV{REMOTE_USER}));
               }
               print hash2xml({result=>\$res});
               \%op=();
               \$self->LastMsg("");
            }
         }
         sub XMLstart {
            my (\$expat,\$e,\%attr)=\@_; 
            if (\$e eq "operation"){
               \%op=(NAME=>\$attr{name},LINE=>\$expat->current_line);
               if (defined(\$attr{reference})){
                  \$op{REFERENCE}=\$attr{reference};
               }
            }
         }
         sub XMLchar {
            my (\$expat,\$string)=\@_; 
            my \@context=\$expat->context;
            if (\$#context==2 && \$context[0] eq "root" &&
                \$context[1] eq "operation"){
               \$op{\$context[2]}.=\$string;
            }
         }
use XML::Parser;\$p = new XML::Parser();
EOF
         if (!defined($p)){
            print hash2xml({exitcode=>3,
                            message =>msg(ERROR,'XML::Parser not '.
                                                'installed or unuseable')});
         }
         else{
            $p->setHandlers(Start=>\&XMLstart,End=>\&XMLend,Char=>\&XMLchar);
            eval('$p->parsefile($filename);');
            if ($@ ne ""){
               $exitcode+=4;
               print hash2xml({codeerror=>$@,
                               message =>msg(ERROR,'XML::Parser error')});
               $failcount++;

            }
            $exitcode+=10000 if ($exitcode!=0);
            print hash2xml({exitcode=>$exitcode,
                            ok=>$opokcount,
                            fail=>$failcount});
            unlink($filename);
         }
      }
   }
   print $self->XmlBottom();
}

sub XmlHead
{
   my $self=shift;

   
   my $d="Content-type: text/xml\n\n";
   $d.="<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<root>\n";
   return($d);
}
sub XmlBottom
{
   my $self=shift;

   return("</root>");
}

sub WSDLmodule2ns
{
   my $module=shift;

   $module=~s/\//::/g;
   my $ns="W5::".$module;
   $ns=~s/:([a-z])/":".uc($1)/eg;
   $ns=~s/://g;
   return($ns);
}



sub WSDL
{
   my $self=shift;
   my $fp=Query->Param("FunctionPath");
   $fp=~s/^\///;
   my $fileexists=1;
   my $module=$fp;
   my $instdir=$self->Config->Param("INSTDIR");
   if (($module=~m/\.\./) || ! -f $instdir."/mod/".$module.".pm"){
      $fileexists=0;
      $self->Log(ERROR,"soap","invalid or not existing NS '$module'");
   }

   $module=~s/\//::/g;
   my $ns=WSDLmodule2ns($module);
   my $uri=$ENV{SCRIPT_URI};
   $uri=~s/\/WSDL\/.*/\/SOAP/;
   $uri=~s/\/public\//\/auth\//;

   my $XMLtypes="";
   my $XMLmessage="";
   my $XMLportType="";
   my $XMLbinding="";
   my $XMLservice="";
   my $wfclass;
   my $usemodule=$module;
   if ($usemodule=~m/^.+::workflow::.+$/){
      $usemodule="base::workflow";
   }
   if (defined(my $o=getModuleObject($self->Config,$usemodule)) &&
       $fileexists==1){
      $o->setParent($self);
      $o->Init();
      $XMLservice.="<service name=\"W5Base\">";
      $XMLservice.="<port name=\"${ns}\" binding=\"${ns}:Port\">";
      $XMLservice.="<SOAP:address location=\"$uri\" />";
      $XMLservice.="</port>";
      $XMLservice.="</service>";
      $o->WSDLcommon($uri,$ns,$fp,$module,
                     \$XMLbinding,\$XMLportType,\$XMLmessage,\$XMLtypes);
      $self->Log(INFO,"soap",
              "WSDL Query from $ENV{REMOTE_ADDR} for module $module");
   }
   utf8::encode($XMLbinding);
   utf8::encode($XMLportType);
   utf8::encode($XMLmessage);
   utf8::encode($XMLtypes);

   print(<<EOF);
Content-type: text/xml

<?xml version="1.0" encoding="UTF-8" ?>
<definitions 
 xmlns="http://schemas.xmlsoap.org/wsdl/"
 xmlns:SOAP="http://schemas.xmlsoap.org/wsdl/soap/"
 xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
 xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
 xmlns:W5Kernel="http://w5base.net/lib/kernel"
 xmlns:$ns="http://w5base.net/mod/$fp"
 targetNamespace="http://w5base.net/mod/$fp">
<types>
<xsd:schema elementFormDefault="qualified" 
            targetNamespace="http://w5base.net/mod/$fp">
$XMLtypes
</xsd:schema>
</types>
$XMLmessage
<portType name="Port">$XMLportType</portType>
<binding name="Port" type="${ns}:Port">
<SOAP:binding transport="http://schemas.xmlsoap.org/soap/http"
              style="document" />
$XMLbinding

</binding>
$XMLservice
EOF
   print(<<EOF);
</definitions>
EOF
}
sub SOAP
{
   my $self=shift;

   $self->Log(INFO,"soap",
              "request: user='$ENV{REMOTE_USER}' ip='$ENV{REMOTE_ADDR}'");
   $W5Base::SOAP=$self;
   $self->{SOAP}=SOAP::Transport::HTTP::CGI   
    -> dispatch_with($self->{NS})
    -> dispatch_to('interface::SOAP');
   $self->{SOAP} -> handle;
}

sub _SOAPaction2param
{
   my $self=shift;
   my $act=shift;
   my $param=shift;
   my $ns;
   if ($param->{dataobject} eq ""){   # fill up dataobject depending on
      my $mod=$act;                      # uri if no dataobject specified
      $mod=~s/"//;
      $mod=~s/#.*$//;
      $mod=~s#http://w5base.net/##;
      if ($mod=~m/^mod\//){
         $mod=~s/^mod\///;
      }
      if ($mod=~m/\/workflow\//){
         $mod=~s/\//::/g;
         if (exists($param->{data}) && ref($param->{data}) eq "HASH"){
            $param->{data}->{class}=$mod;
         }
         $param->{class}=$mod;
         $mod="base::workflow";
      }
      $mod=~s/\//::/g;
      $param->{dataobject}=$mod;
      if ($param->{dataobject} eq "base::workflow"){
         $ns=WSDLmodule2ns($param->{class});
      }
      else{
         $ns=WSDLmodule2ns($param->{dataobject});
      }
   }
   if ($act ne ""){
      my $ns=$act;
      $ns=~s/#.*$//;
      my $ser=$self->{SOAP}->serializer();
      $ser->register_ns( $ns, 'curns' );
   }

   if ($param->{lang} eq ""){
      $param->{lang}="en";
   }
   #
   # this is the fix, to handel "default" parameters with wsdl2java
   #
   foreach my $store (grep(/^___STORE_TAG_AT_.*_PARAM___$/,keys(%$param))){
      if (my ($var,$val)=
          $store=~m/___STORE_TAG_AT_([A-Z,a-z]+)_(.*)_PARAM___$/){
         if (!exists($param->{$var})){
            $param->{$var}=$val;
         }
         delete($param->{$store});
      }
   }
   return($ns);
}

package interface::SOAP;
use kernel;
use strict;
use vars qw(@ISA);
@ISA = qw(SOAP::Server::Parameters);

sub showFields
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   $self->_SOAPaction2param($self->{SOAP}->action(),$param);

   my $objectname=$param->{dataobject};

   $ENV{HTTP_FORCE_LANGUAGE}=$param->{lang} if (defined($param->{lang}));
   if (!($objectname=~m/^.+::.+$/)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>['invalid dataobject name']}));
   }
   my $o=getModuleObject($self->Config,$objectname);
   if (!defined($o)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>['invalid dataobject specified']}));
   }
   $o->setParent($self);
   $o->Init();

   my @l;
   my $idfield=$o->IdField();
   my @fieldlist=$o->getFieldList();
   foreach my $field (@fieldlist){
      my $fielddesc={name=>$field};
      my $fo=$o->getField($field);
      if (defined($fo)){
         foreach my $prop (qw(group)){
            if (defined($fo->{$prop})){
               $fielddesc->{$prop}=$fo->{$prop};
            }
         }
         if (defined($idfield) && $idfield->Name() eq $fo->Name()){
            $fielddesc->{primarykey}=1;
         }
         $fielddesc->{longtype}=$fo->Self();
         $fielddesc->{type}=$fo->Type();
      }
      push(@l,$fielddesc);
   }
   @l=map({SOAP::Data->type('Field')->value($_)} @l);


   return(interface::SOAP::kernel::Finish(
          SOAP::Data->name(output=>{exitcode=>0,
                                    lastmsg=>[],
          records=>SOAP::Data->name("records"=>\@l)->type("ResultRecords"),
                                    })->type("HASH")));
}

sub storeRecord
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   $self->_SOAPaction2param($self->{SOAP}->action(),$param);
   my $envelope=pop;
   my $objectname=$param->{dataobject};
   my $filter=$param->{filter};
   my $newrec=$param->{data};
   my $id=$param->{IdentifiedBy};

   $self->Log(INFO,"soap",
              "storeRecord: [$objectname] ($id)\n%s",Dumper($newrec));
   $ENV{HTTP_FORCE_LANGUAGE}=$param->{lang} if (defined($param->{lang}));
   if (!($objectname=~m/^.+::.+$/)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>['invalid dataobject name']}));
   }
   if (ref($newrec) ne "HASH"){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid or emtpy data record specified')]}));
   }
   my $o=getModuleObject($self->Config,$objectname);
   if (!defined($o)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid dataobject specified')]}));
   }
   $o->setParent($self);
   $o->Init();
   foreach my $k (keys(%$newrec)){
      if (ref($newrec->{$k}) eq "ARRAY" &&
          $newrec->{$k}->[0] eq "MIME::Entity"){
         $newrec->{$k}=$envelope->parts()->[$newrec->{$k}->[1]];
      }
   }
   if ($objectname eq "base::workflow"){
      my $action=$newrec->{action};
      delete($newrec->{action});
      if ($o->nativProcess($action,$newrec,$id)){
         
         my $IdentifiedBy=$id;
         if ($IdentifiedBy eq ""){
            $IdentifiedBy=$newrec->{id};
         }
         return(interface::SOAP::kernel::Finish({exitcode=>0,
                                                IdentifiedBy=>$IdentifiedBy})); 
      }
      if ($o->LastMsg()==0){
         my $msg="unknown problem";
         $msg.=" or '$action' is not accessable via SOAP" if ($action ne "");
         $o->LastMsg(ERROR,$msg);
      }
      return(interface::SOAP::kernel::Finish({exitcode=>10,
                                              lastmsg=>[$o->LastMsg()]})); 
   }
   else{
      if (defined($id)){
         my $idfield=$o->IdField();
         if (defined($idfield)){
            my $idname=$idfield->Name();
            my $filter={$idname=>\$id};
            $o->SecureSetFilter($filter); 
            my ($oldrec,$msg)=$o->getOnlyFirst(qw(ALL));
            if (defined($oldrec)){
               if (my @grps=$o->isWriteValid($oldrec,$newrec)){
                  if ($o->SecureValidatedUpdateRecord($oldrec,$newrec,$filter)){
                     $id=~s/^0*//g if (defined($id) && $id=~m/^\d+$/);
                     return(interface::SOAP::kernel::Finish(
                            {exitcode=>0, IdentifiedBy=>$id})); 
                  }
                  return(interface::SOAP::kernel::Finish({exitcode=>10,
                         lastmsg=>[$o->LastMsg()]})); 
               }
               else{
                  return(interface::SOAP::kernel::Finish({exitcode=>12,
                         lastmsg=>["no write access to specified record"]})); 
               }
            }
            return(interface::SOAP::kernel::Finish({exitcode=>10,
                   lastmsg=>[msg(ERROR,'can not find record for update')]})); 
         }
         return(interface::SOAP::kernel::Finish({exitcode=>20,
                lastmsg=>[
                   msg(ERROR,'no unique idenitifier in dataobject found')]})); 
      }
      else{
         if (my @grps=$o->isWriteValid(undef,$newrec)){
            if (my $id=$o->SecureValidatedInsertRecord($newrec)){
               $id=~s/^0*//g if (defined($id) && $id=~m/^\d+$/);

               return(interface::SOAP::kernel::Finish({
                                                         exitcode=>0,
                                                         IdentifiedBy=>$id
                                                      })); 


            }
            return(interface::SOAP::kernel::Finish({exitcode=>10,
                   lastmsg=>[$o->LastMsg()]})); 
         }
         else{
            return(interface::SOAP::kernel::Finish({exitcode=>12,
                   lastmsg=>["no write (insert) access to specified data"]})); 
         }
      }
   }
   return(interface::SOAP::kernel::Finish({exitcode=>-1}));
}

sub deleteRecord
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   $self->_SOAPaction2param($self->{SOAP}->action(),$param);
   my $objectname=$param->{dataobject};
   my $filter=$param->{filter};
   my $id=$param->{IdentifiedBy};

   $self->Log(INFO,"soap",
              "deleteRecord: user='$ENV{REMOTE_USER}' ip='$ENV{REMOTE_ADDR}'");
   $self->Log(INFO,"soap",
              "[$objectname] ($id)");
   $ENV{HTTP_FORCE_LANGUAGE}=$param->{lang} if (defined($param->{lang}));
   if (!($objectname=~m/^.+::.+$/)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>['invalid dataobject name']}));
   }
   my $o=getModuleObject($self->Config,$objectname);
   if (!defined($o)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>['invalid dataobject specified']}));
   }
   $o->setParent($self);
   $o->Init();

   if (defined($id)){
      my $idfield=$o->IdField();
      if (defined($idfield)){
         my $idname=$idfield->Name();
         my $filter={$idname=>\$id};
         $o->SecureSetFilter($filter); 
         my ($oldrec,$msg)=$o->getOnlyFirst(qw(ALL));
         if (defined($oldrec)){
            if ($o->SecureValidatedDeleteRecord($oldrec)){
               return(interface::SOAP::kernel::Finish({exitcode=>0,
                                                       IdentifiedBy=>$id})); 
            }
            return(interface::SOAP::kernel::Finish({exitcode=>10,
                   lastmsg=>[$o->LastMsg()]})); 
         }
         return(interface::SOAP::kernel::Finish({exitcode=>11,
                lastmsg=>[msg(ERROR,'can not find any record for delete')]})); 
      }
      return(interface::SOAP::kernel::Finish({exitcode=>20,
             lastmsg=>[
                msg(ERROR,'no unique idenitifier in dataobject found')]})); 
   }
   else{
      return(interface::SOAP::kernel::Finish({exitcode=>12,
             lastmsg=>["no delete IdentifiedBy specified"]})); 
   }
   return(interface::SOAP::kernel::Finish({exitcode=>-1}));
}



sub findRecord
{
   return(getHashList(@_));
}

sub getHashList
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   my $ns=$self->_SOAPaction2param($self->{SOAP}->action(),$param);
   my $objectname=$param->{dataobject};
   my $view=$param->{view};
   my $filter=$param->{filter};
   $filter={} if ($filter eq "");

   $view=[split(/\s*[,;]\s*/,$view)] if (ref($view) ne "ARRAY");
   $ENV{HTTP_FORCE_LANGUAGE}=$param->{lang} if (defined($param->{lang}));
   if (!($objectname=~m/^.+::.+$/)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid dataobject name')]}));
   }
   if ($objectname eq "base::workflow"){
      msg(DEBUG,"SOAP base::workflow filter %s",Dumper($filter));
      my $fltchk=0;
      for my $validkey (qw(srcid id)){
         if (ref($filter) eq "HASH" &&
             keys(%$filter)==1 &&
             $filter->{$validkey}=~m/^[0-9,A-Z,_]{5,20}$/i){
             $fltchk++;
         }
         if (ref($filter) eq "HASH" &&
             keys(%$filter)==1 &&
             ref($filter->{$validkey}) eq "ARRAY" &&
             $filter->{$validkey}->[0]=~m/^[0-9,A-Z,_]{5,20}$/i){
             $fltchk++;
         }
      }
      if (!$fltchk){
         return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'base::workflow allows only '.
                                 'SOAP filter to id or srcid')]}));
      }
   }
   my $o=getModuleObject($self->Config,$objectname);
   if (!defined($o)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid dataobject specified')]}));
   }
   $o->setParent($self);
   $o->Init();
   if (!$o->isViewValid()){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'no access to dataobject')]}));
   }
   $o->SecureSetFilter($filter); 
   msg(INFO,"SOAPgetHashList in search objectname=$objectname");
   my @fobjs=$o->getFieldObjsByView($view);
   my @l=$o->getHashList(@$view);
   for(my $c=0;$c<=$#l;$c++){
      my %cprec;
      my $objns=$ns;
      $objns="W5Kernel" if ($ns eq "");
      foreach my $fobj (@fobjs){
         my $k=$fobj->Name();
         my $wsdl=$fobj->{WSDLfieldType};
         $wsdl="xsd:string" if ($wsdl eq "");
         if (!($wsdl=~m/^.*:.*$/)){
            $wsdl=$objns.":".$wsdl;
         }
         my $v=$fobj->FormatedResult($l[$c],"SOAP");
         if (ref($v) eq "ARRAY"){
            $v=[map({latin1($_)->utf8();} @$v)];
         }
         else{
            $v=latin1($v)->utf8();
         }
         $cprec{$k}=SOAP::Data->type($wsdl)->value($v);
      }
      $l[$c]=SOAP::Data->name('record')->type('Record')->value(\%cprec);
      if ($ns eq ""){
         $l[$c]=$l[$c]->attr({'xmlns:'.$objns=>'http://w5base.net/kernel'});
      }
   }
   return(interface::SOAP::kernel::Finish(SOAP::Data->name(output=>{exitcode=>0,
          lastmsg=>[],records=>\@l})));
}

sub validateObjectname
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   my $objectname=$param->{dataobject};

   $ENV{HTTP_FORCE_LANGUAGE}=$param->{lang} if (defined($param->{lang}));
   if (!($objectname=~m/^.+::.+$/)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid dataobject name')]}));
   }
   my $o=getModuleObject($self->Config,$objectname);
   if (!defined($o)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid dataobject specified')]}));
   }
   $o->setParent($self);
   if (!$o->Init()){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'inactive dataobject specified')]}));
   }

   return(interface::SOAP::kernel::Finish({exitcode=>0}));
}

sub Ping
{
   my $self=$W5Base::SOAP;
   $self->Log(INFO,"soap","Ping:'");
   return(SOAP::Data->name(output=>{exitcode=>0,result=>1}));
}

sub doPing
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   my $ns=$self->_SOAPaction2param($self->{SOAP}->action(),$param);
   $self->Log(INFO,"soap", "Ping: ".$self->{SOAP}->action());
   my $d=SOAP::Data->name(output=>{exitcode=>0,result=>1});
   return($d);
}

package interface::SOAP::kernel;
use kernel;

sub Finish
{
   my $result=shift;
   delete($ENV{HTTP_FORCE_LANGUAGE});
   if (defined($result->{lastmsg})){
      for(my $c=0;$c<=$#{$result->{lastmsg}};$c++){
         $result->{lastmsg}->[$c]=~s/\s*$//g;
      }
   }
   if (exists($result->{IdentifiedBy})){
      $result->{IdentifiedBy}=
             SOAP::Data->type('xsd:integer')->value($result->{IdentifiedBy});
   }
   if (exists($result->{exitcode})){
      $result->{exitcode}=
             SOAP::Data->type('xsd:int')->value($result->{exitcode});
   }
   if (exists($result->{lastmsg})){  # .Net needs every element coded as string
      if (ref($result->{lastmsg}) eq "ARRAY"){
         my @l;
         map({my $u=SOAP::Data->type('xsi:string')->value($_);push(@l,$u);} 
             @{$result->{lastmsg}});
         $result->{lastmsg}=SOAP::Data->value(\@l);
      }
      else{
         $result->{lastmsg}=SOAP::Data->type('xsi:string')
                                      ->value($result->{lastmsg});
      }
   }
   return(SOAP::Data->name(output=>$result));
}

1;
