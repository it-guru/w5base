package tpc::ipaddress;
#  W5Base Framework
#  Copyright (C) 2022  Hartmut Vogler (it@guru.de)
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
use kernel::Field;
use tpc::lib::Listedit;
use JSON;
@ISA=qw(tpc::lib::Listedit);

# API at https://code.vmware.com/apis/39/vrealize-automation
# https://code.vmware.com/apis/978

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(     
            name              =>'id',
            searchable        =>1,
            group             =>'source',
            htmldetail        =>'NotEmpty',
            htmlwidth         =>'150px',
            align             =>'left',
            label             =>'MachineID'),

      new kernel::Field::Text(     
            name              =>'name',
            searchable        =>1,
            htmlwidth         =>'200px',
            label             =>'IP-Address'),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS-Name'),

      new kernel::Field::Text(
                name          =>'mac',
                label         =>'MAC'),

      new kernel::Field::Text(
                name          =>'ifname',
                htmlwidth     =>'250px',
                label         =>'System Interface'),

      new kernel::Field::Boolean(
                name          =>'isprimary',
                label         =>'is primary'),

      new kernel::Field::Text(
                name          =>'netareatag',
                label         =>'NetArea Tag'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name mac ifname isprimary netareatag));
   return($self);
}


sub getCredentialName
{
   my $self=shift;

   return("TPCX");
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $credentialName=$self->getCredentialName();

   my $Authorization=$self->getVRealizeAuthorizationToken($credentialName);

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4vRealize(
      "machines","id",
      $filterset
   );
   my $ip=getModuleObject($self->Config(),"itil::ipaddress");
   my $d=$self->CollectREST(
      dbname=>$credentialName,
      requesttoken=>$requesttoken,
      retry_count=>6,
      retry_interval=>15,
      url=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         $baseurl.="/"  if (!($baseurl=~m/\/$/));
         my $dataobjurl=$baseurl."iaas/".$dbclass;
         return($dataobjurl);
      },

      headers=>sub{
         my $self=shift;
         my $baseurl=shift;
         my $apikey=shift;
         my $headers=['Authorization'=>$Authorization,
                      'Content-Type'=>'application/json'];
 
         return($headers);
      },
      success=>sub{  # DataReformaterOnSucces
         my $self=shift;
         my $data=shift;
         if (ref($data) eq "HASH" && exists($data->{content})){
            $data=$data->{content};
         }
         if (ref($data) ne "ARRAY"){
            $data=[$data];
         }
         my @resultdata;
         map({
             $_->{NetworkInterfaces}=$self->genReadTPChref(
                  $credentialName,
                  $Authorization,
                  $_->{_links}->{'network-interfaces'}
             );
             my $nifs=$_->{NetworkInterfaces};
             $nifs=[$nifs] if (ref($nifs) ne "ARRAY");
             foreach my $nif (@$nifs){
                next if (!defined($nif));
                my $addresses=$nif->{addresses};
                $addresses=[$addresses] if (ref($addresses) ne "ARRAY");
                foreach my $address (@$addresses){
                   next if (!defined($address));
                   my $iprec={
                      id=>$_->{id},
                      name=>$address,
                      netareatag=>"ISLAND",
                      isprimary=>'0',
                      dnsname=>''
                   };
                   if ($iprec->{name}=~m/:/){ # v6 Handling
                      $iprec->{name}=$ip->Ipv6Expand($iprec->{name});
                   }
                   if (ref($nif->{customProperties}) &&
                       exists($nif->{customProperties}->{mac_address})){
                      $iprec->{mac}=$nif->{customProperties}->{mac_address};
                   }
                   if ($iprec->{name}=~m/^10\./){
                      $iprec->{netareatag}="CNDTAG";
                   }
                   if ($iprec->{name} eq $_->{address}){
                      $iprec->{isprimary}='1';
                   }
                   $iprec->{ifname}="eth".$nif->{deviceIndex};
                   push(@resultdata,$iprec);
                }
             }
         } @$data);
         return(\@resultdata);
      },
      onfail=>sub{
         my $self=shift;
         my $code=shift;
         my $statusline=shift;
         my $content=shift;
         my $reqtrace=shift;

         if ($code eq "404"){  # 404 bedeutet nicht gefunden
            return([],"200");
         }
         msg(ERROR,$reqtrace);
         $self->LastMsg(ERROR,"unexpected data TPC machine response");
         return(undef);
      }

   );
   #customProperties

   return($d);
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("default") if (!defined($rec));
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}

sub isUploadValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem));
}



sub ImportSystem
{
   my $self=shift;
   my $importname=trim(Query->Param("importname"));
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"TPC System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $importname;
   my $sysrec;

   if ($param->{importname} ne ""){
      my $sysuuid;
      $importname=$param->{importname};
      msg(INFO,"start Import in aws::system with importname $importname");
      if (($sysuuid)=$importname
              =~m/^(\S+)$/){
         $flt={
            id=>$sysuuid
         };
      }
      else{
         $self->LastMsg(ERROR,"sieht schlecht aus");
         return(undef);
      }
      $self->ResetFilter();
      $self->SetFilter($flt);
      my @l=$self->getHashList(qw(id name projectId));
      if ($#l==-1){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"TPC machine not found");
         }
         msg(ERROR,"requested importname $importname can not be resolved");
         return(undef);
      }
    
      if ($#l>0){
         if ($self->isDataInputFromUserFrontend()){
            $self->LastMsg(ERROR,"Systemname '%s' not unique in TPC",
                                 $param->{importname});
         }
         return(undef);
      }
      $sysrec=$l[0];
   }
   elsif (ref($param->{importrec}) eq "HASH"){
      $sysrec=$param->{importrec};
   }
   else{
      msg(ERROR,"no importname specified while ".$self->Self." Import call");
      return(undef);
   }
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");
   my $itcloud=getModuleObject($self->Config,"itil::itcloud");

   my $cloudrec;
   my $w5carec;
   {
      $itcloud->ResetFilter();
      $itcloud->SetFilter({name=>'TPC TEL-IT_PrivateCloud',cistatusid=>'4'});
      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(id name fullname cistatusid));
      if (defined($crec)){
         $cloudrec=$crec;
      }
      else{
         $self->LastMsg(ERROR,"no active TPC Cloud in inventory");
         return(undef);
      }
   }

   if ($sysrec->{projectId} ne ""){
      msg(INFO,"try to add CloudArea to system ".$sysrec->{name});
      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
                             srcid=>\$sysrec->{projectId}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
      }
   }






   my $syssrcid=$sysrec->{id};
   my $system=getModuleObject($self->Config,"TS::system");

   if (!defined($w5carec)){
      my $msg;
      if (exists($param->{importname})){
         $msg=$param->{importname};
      }
      else{
         $msg=$param->{importrec}->{id};
      }
      if ($self->isDataInputFromUserFrontend()){
         # if import is from Job (W5Server f.e.) no error on missing
         # ca rec is needed - ca's are guranted by other processes
         $self->LastMsg(ERROR,"missing CloudArea for TPC import of '%s'",$msg);
      }
      return(undef);
   }


   my $sysimporttempl={
      name=>[$sysrec->{name},$sysrec->{genname}],
      initialname=>$sysrec->{id},
      id=>$sysrec->{id},
      srcid=>$sysrec->{id},
      ipaddresses=>{
      }
   };
   if ($sysrec->{address} ne ""){
      $sysimporttempl->{ipaddresses}=[{
          name=>$sysrec->{address},
          netareatag=>'CNDTAG'
      }];
   }

   if ($sysrec->{projectId} ne ""){
      msg(INFO,"try to add CloudArea to system ".$sysrec->{name});
      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
                             srcid=>\$sysrec->{projectId}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
      }
   }


   my $ImportRec={
      cloudrec=>$cloudrec,
      cloudarearec=>$w5carec,
      imprec=>$sysimporttempl,
      srcsys=>'TPC',
      checkForSystemExistsFilter=>sub{  # Nachfrage ob Reuse System-Candidat not
         my $osys=shift;                # exists in srcobj
         my $srcid=$osys->{srcid};
         return({id=>\$srcid});
      }
   };

   my $ImportObjects={   # Objects are in seperated Structur for better Dumping
      itcloud=>$itcloud,
      itcloudarea=>$cloudarea,
      appl=>$appl,
      system=>$system,
      srcobj=>$self
   };

   #printf STDERR ("ImportRec(imprec):%s\n",Dumper($ImportRec->{imprec}));
   my $ImportResult=$system->genericSystemImport($ImportObjects,$ImportRec);
   #printf STDERR ("ImportResult:%s\n",Dumper($ImportResult));
   if ($ImportResult){
      return($ImportResult->{IdentifedBy});
   }
   return();
}


sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return(qw(header default tags source));
}




sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


1;
