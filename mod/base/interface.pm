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
#use SOAP::Lite +trace => 'all';
use SOAP::Lite;
use SOAP::Transport::HTTP;
use Time::HiRes qw(gettimeofday tv_interval);
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
      print("<table width=\"100%%\" height=\"100%%\">".
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
         if (open(my $F,">$requestdebugfile")){
            binmode($F);
            if (open(my $FI,"<$filename")){
               binmode($FI);
               my $bsize=1024;
               my $data;
               while(1){
                 my $nread = read($FI, $data, $bsize);
                 last if (!$nread);
                 syswrite($F,$data,$nread);
               }
               close($FI);
            }
            close($F);
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
            $p->setHandlers(
               Start=>\&XMLstart,
               End=>\&XMLend,
               Char=>\&XMLchar,
               ExternEnt =>sub{    # Security fix to prevent 
                                   # XML Entity Injection
                  shift; 
                  return("-INVALID EXTERNAL XMLREF-");
               }
            );
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
      $XMLservice.="<port name=\"${ns}\" binding=\"${ns}:${ns}Port\">";
      $XMLservice.="<SOAP:address location=\"$uri\" />";
      $XMLservice.="</port>";
      $XMLservice.="</service>";
      $o->WSDLcommon($uri,$ns,$fp,$module,
                     \$XMLbinding,\$XMLportType,\$XMLmessage,\$XMLtypes);
      $self->Log(INFO,"soap",
              "WSDL Query from ".getClientAddrIdString()." for module $module");
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
<xsd:import namespace="http://schemas.xmlsoap.org/soap/encoding/"
            schemaLocation="http://schemas.xmlsoap.org/soap/encoding/" />
$XMLtypes
</xsd:schema>
</types>
$XMLmessage
<portType name="${ns}Port">$XMLportType</portType>
<binding name="${ns}Port" type="${ns}:${ns}Port">
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
   my $t0=[gettimeofday()];
   $ENV{CONTENT_TYPE}=~s/application\/x-www-form-urlencoded,\s*//; # for IE JS
   $self->Log(INFO,"soap",
              "request: user='$ENV{REMOTE_USER}' ip='".getClientAddrIdString()."'");
   $W5Base::SOAP=$self;
   $self->{SOAP}=SOAP::Transport::HTTP::CGI   
    -> dispatch_with($self->{NS})
    -> dispatch_to('interface::SOAP');
   $self->{SOAP} -> handle;
   my $t=tv_interval($t0,[gettimeofday()]);
   my $s=sprintf("%0.4fsec",$t);
   $self->Log(INFO,"soap","request: user='$ENV{REMOTE_USER}' done in $s");
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
         if (exists($param->{data}) && ref($param->{data}) &&
             (exists($param->{data}->{action}) || 
              $param->{IdentifiedBy} eq "")){
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
      $ns=~s/^"//;
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
   $param={} if (!ref($param));
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
         if (exists($fo->{dataobjattr})){
            $fielddesc->{dataobjattr}=$fo->{dataobjattr};
         }
         else{
            $fielddesc->{dataobjattr}="[NULL]";
         }
         if (defined($fo->{vjointo}) && $fo->{vjointo} ne ""){
            $fielddesc->{is_vjoin}="yes";
            $fielddesc->{sourceobj}=$fo->{vjointo};
         }
         else{
            $fielddesc->{is_vjoin}="no";
         }
         if (defined($fo->{onRawValue})){
            $fielddesc->{is_vjoin}="maybee";
            $fielddesc->{sourceobj}="CALCULATED";
         }
      }
      push(@l,$fielddesc);
   }
   @l=map({SOAP::Data->type('Field')->value($_)} @l);


   return(interface::SOAP::kernel::Finish(
          {exitcode=>0, lastmsg=>[],
          records=>SOAP::Data->name("records"=>\@l)->type("ResultRecords"),
                                    }));
}

sub storeRecord
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   $param={} if (!ref($param));
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
   if (ref($newrec) ne "HASH" && ref($newrec) ne "WfRec"){
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
      else{
         $newrec->{$k}=UTF8toLatin1($newrec->{$k});
      }
   }
   if ($objectname eq "base::workflow" &&          # operations on 
       (exists($newrec->{action}) || $id eq "")){  # existing workflows always 
      my $action=$newrec->{action};                # always need to be spec.
      delete($newrec->{action});                   # an id AND a action. 
                                                   # On new create of
      if ($o->nativProcess($action,$newrec,$id)){  # workflows no id is specif.
         
         my $IdentifiedBy=$id;
         if ($IdentifiedBy eq ""){
            $IdentifiedBy=$newrec->{id};
         }
         return(interface::SOAP::kernel::Finish({exitcode=>0,
                                                IdentifiedBy=>$IdentifiedBy})); 
      }
      else{
         if ($o->LastMsg()==0){
            my $msg="unknown problem";
            $msg.=" or '$action' is not accessable via SOAP" if ($action ne "");
            $o->LastMsg(ERROR,$msg);
         }
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
   $param={} if (!ref($param));
   $self->_SOAPaction2param($self->{SOAP}->action(),$param);
   my $objectname=$param->{dataobject};
   my $filter=$param->{filter};
   my $id=$param->{IdentifiedBy};

   $self->Log(INFO,"soap",
              "deleteRecord: user='$ENV{REMOTE_USER}' ip='".getClientAddrIdString()."'");
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



sub getRelatedWorkflows
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   $param={} if (!ref($param));
   $self->_SOAPaction2param($self->{SOAP}->action(),$param);
   my $objectname=$param->{dataobject};
   my $filter=$param->{filter};
   my $id=$param->{IdentifiedBy};
   my $timerange=$param->{timerange};
   my $class=$param->{class};
   my $fulltext=$param->{fulltext};

   $self->Log(INFO,"soap",
        "getRelatedWorkflows: user='$ENV{REMOTE_USER}' ip='".getClientAddrIdString()."'");
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

   if (defined($id) || $id eq "" || ($id=~m/\*/)){
      my %param;
      $param{class}=$class if ($class ne "");
      $param{fulltext}=$class if ($fulltext ne "");
      $param{timerange}=$timerange if ($timerange ne "");
      my $l=$o->getRelatedWorkflows($id,\%param);
      if (ref($l)){
         my $v=[values(%$l)];
       #  my $v=SOAP::Data->type("curns:ArrayOfStringItems")->value(
       #       [map({SOAP::Data->type("xsd:string")->value($_);} values(%$l))]);
         return(interface::SOAP::kernel::Finish({exitcode=>0,workflows=>$v})); 
      }
      return(interface::SOAP::kernel::Finish({exitcode=>20,
             lastmsg=>[msg(ERROR,'query error')]})); 
   }
   else{
      return(interface::SOAP::kernel::Finish({exitcode=>12,
             lastmsg=>["no getRelatedWorkflows IdentifiedBy specified"]})); 
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
   $param={} if (!ref($param));
   my $ns=$self->_SOAPaction2param($self->{SOAP}->action(),$param);
   my $objectname=$param->{dataobject};
   my $limitstart=$param->{limitstart};
   my $limit=$param->{limit};
   my $view=$param->{view};
   my $filter=$param->{filter};
   $filter={} if ($filter eq "");

   $view=[split(/\s*[,;]\s*/,$view)] if (ref($view) ne "ARRAY");
   my $q=Dumper($filter);
   $q=~s/\$VAR1/query/;
   $self->Log(INFO,"soap",
              "findRecord: [$objectname] (%s)\n%s",
              join(",",@$view),$q);

   $ENV{HTTP_FORCE_LANGUAGE}=$param->{lang} if (defined($param->{lang}));
   if (!($objectname=~m/^.+::.+$/)){
      return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'invalid dataobject name')]}));
   }
   if ($objectname eq "base::workflow"){
      msg(DEBUG,"SOAP base::workflow filter %s",Dumper($filter));
      my $fltchk=0;
      for my $validkey (qw(srcid id)){
         if ((ref($filter) eq "HASH" || ref($filter) eq "Filter") &&
             keys(%$filter)==1 &&
             $filter->{$validkey}=~m/^[0-9,A-Z,_,-]{5,20}$/i){
            my $v=$filter->{$validkey};
            $filter->{$validkey}=\$v;
            $fltchk++;
         }
         if ((ref($filter) eq "HASH" || ref($filter) eq "Filter") &&
             keys(%$filter)==1 &&
             ref($filter->{$validkey}) eq "ARRAY" &&
             $filter->{$validkey}->[0]=~m/^[0-9,A-Z,_,-]{5,20}$/i){
            my $v=$filter->{$validkey}->[0];
            $filter->{$validkey}=\$v;
            $fltchk++;
         }
      }
      if (!$fltchk){
         return(interface::SOAP::kernel::Finish({exitcode=>128,
             lastmsg=>[msg(ERROR,'base::workflow allows only '.
                                 'SOAP filter to id or srcid')]}));
      }
   }
   my %f=%$filter;
   $filter=\%f;  # ensure to get an hash (instead of a tied object);
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
   if (defined($limit) && $limit>0 && $limit=~m/^\d+$/){
      $o->Limit($limit,$limitstart);
   }
   my $idfield=$o->IdField();
   my $idname=$idfield->Name();
   #msg(INFO,"SOAPgetHashList in search objectname=$objectname");
   my @sellist=@$view;
   if (!($#sellist==0 && lc($sellist[0]) eq "all")){
      push(@sellist,$idname);
   }
   my @l=$o->getHashList(@sellist);
   my @resl;
   if (defined($idfield)){
      for(my $c=0;$c<=$#l;$c++){
        # $o->SetFilter({$idname=>$l[$c]->{$idname}});
        # my ($chkrec,$msg)=$o->getOnlyFirst(qw(ALL));
         my $chkrec=$l[$c];
         if (defined($chkrec)){
            if (!exists($o->{'SoftFilter'}) ||
                 &{$o->{'SoftFilter'}}($o,$chkrec)){
               my @viewl=$o->isViewValid($chkrec);
               if ($#viewl!=-1 && !($#viewl==0 && !defined($viewl[0]))){
                  $resl[$c]=$l[$c];
                  my @fobjs=$o->getFieldObjsByView($view,
                                              current=>$resl[$c],
                                              output=>'kernel::Output::SOAP');
                  my %cprec;
                  my $objns=$ns;
                  $objns="W5Kernel" if ($ns eq "");
                  fldloop: foreach my $fobj (@fobjs){
                     my $k=$fobj->Name();
                     my $v=$fobj->UiVisible("SOAP",current=>$chkrec);
                     next if (!$v && ($fobj->Type() ne "Interface"));
                     my $grp=$fobj->{group};
                     $grp=[$grp] if (!ref($grp));
                     my $found=0;
                     foreach my $g (@$grp){
                        $found++ if (grep(/^$g$/,@viewl) || 
                                     grep(/^ALL$/,@viewl));
                     }
                     next if (!$found);
                     my $wsdl=$fobj->{WSDLfieldType};
                     $wsdl="xsd:string" if ($wsdl eq "");
                     if (!($wsdl=~m/^.*:.*$/)){
                        $wsdl="curns:".$wsdl;
                     }
                     my $v=$fobj->FormatedResult($resl[$c],"SOAP");
                     if (ref($v) eq "ARRAY"){
                        #$v=[map({latin1($_)->utf8();} @$v)];
                        if ($wsdl=~m/:ArrayOfStringItems$/){
                           $v=[map({SOAP::Data->type("xsd:string")
                                              ->value($_);} @$v)];
                        }
                     }
                     else{
                        #$v=latin1($v)->utf8() if (defined($v) &&
                        #                         $fobj->Type ne "XMLInterface");
                     }
                     if (defined($v)){
                        $cprec{$k}=SOAP::Data->type($wsdl)->value($v);
                     }
                  }
                  $resl[$c]=SOAP::Data->name('record')
                                      ->type('curns:Record')
                                      ->value(\%cprec);
                  if ($ns eq ""){
                     $resl[$c]=$resl[$c]->attr({'xmlns:'.
                                          $objns=>'http://w5base.net/kernel'});
                  }
               }
            }
         }
      }
   }
   my $reccount=$#resl+1;
   $self->Log(INFO,"soap","findRecord: return $reccount records - exitcode:0");


   return(interface::SOAP::kernel::Finish({exitcode=>0,
          lastmsg=>[],
          records=>SOAP::Data->type('curns:RecordList')->value(\@resl)}));
}

sub validateObjectname
{
   my $self=$W5Base::SOAP;
   my $uri=shift;
   my $param=shift;
   $param={} if ($param eq "");
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
   $param={} if (!ref($param));
   my $ns=$self->_SOAPaction2param($self->{SOAP}->action(),$param);
   $self->Log(INFO,"soap", "Ping: ".$self->{SOAP}->action());
   my $d={exitcode=>0,result=>1};
   if ($param->{'loadContext'}>0){
      my $userid=$self->getCurrentUserId();
      $d->{userid}=
              SOAP::Data->type('xsd:integer')->value($userid);
      $d->{user}=
              SOAP::Data->type('xsd:string')->value($ENV{REMOTE_USER});
      my $UserCache=$self->Cache->{User}->{Cache}->{$ENV{REMOTE_USER}}->{rec};
      foreach my $v (qw(tz posix secstate surname givenname 
                        fullname lang usertyp email)){
         my $val=$UserCache->{$v};
         utf8::encode($val);
         $d->{$v}=SOAP::Data->type('xsd:string')->value($val);
      }
  
      if ($param->{'loadContext'}>1){
         my %REmployee=$self->getGroupsOf($userid, [qw(REmployee)], 'direct');
         my %RMember=$self->getGroupsOf($userid, [qw(RMember)], 'direct');
         my %RBoss=$self->getGroupsOf($userid, [qw(RBoss)], 'direct');
         $d->{'groupids'}={
            REmployee=>[keys(%REmployee)],
            RMember=>[keys(%RMember)],
            RBoss=>[keys(%RBoss)]
         };
         $d->{'groupnames'}={
            REmployee=>[map({$_->{fullname}} values(%REmployee))],
            RMember=>[map({$_->{fullname}} values(%RMember))],
            RBoss=>[map({$_->{fullname}} values(%RBoss))]
         };
      }
   }
   return(interface::SOAP::kernel::Finish($d));
}

package interface::SOAP::kernel;
use kernel;

sub Finish
{
   my $result=shift;
   delete($ENV{HTTP_FORCE_LANGUAGE});
   if (defined($result->{lastmsg}) && ref($result->{lastmsg})){
      for(my $c=0;$c<=$#{$result->{lastmsg}};$c++){
         $result->{lastmsg}->[$c]=~s/\s*$//g;
         $result->{lastmsg}->[$c]=~s/&amp;/&/g;
         $result->{lastmsg}->[$c]=~s/&/&amp;/g;
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
      if (ref($result->{lastmsg})){
         my @l;
         map({my $u=SOAP::Data->type('xsd:string')->value($_);push(@l,$u);} 
             @{$result->{lastmsg}});
         $result->{lastmsg}=SOAP::Data->type("curns:ArrayOfStringItems")
                                      ->value(\@l);
      }
      else{
         $result->{lastmsg}=SOAP::Data->type('xsd:string')
                                      ->value($result->{lastmsg});
      }
   }
   return(SOAP::Data->name(output=>$result));
}

1;
