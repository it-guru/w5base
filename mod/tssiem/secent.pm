package tssiem::secent;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
use tssiem::lib::Listedit;
use kernel::Field;
use Date::Parse;
use kernel::date;
@ISA=qw(tssiem::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=5 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'ictono',
                label         =>'ICTO-ID',
                group         =>'scan',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"secscan.ictoid"),  # In Zukunft sollte die dann
                                            # irgendwann optional sein
      new kernel::Field::Text(
                name          =>'itscanobjectid',
                htmldetail    =>'NotEmpty',
                searchable    =>0,
                group         =>'scan',
                label         =>'IT-ScanObjectID',
                dataobjattr   =>"secscan.ictoid"), # da kann dann ICTOID 
                                                   # oder W5BID irgendwann 
                                                   # mal drin sein.
      new kernel::Field::Date(
                name          =>'sdate',
                label         =>'Scan date',
                dataobjattr   =>'secscan.launch_datetime'),

      new kernel::Field::Text(
                name          =>'ipaddress',
                label         =>'IP',
                dataobjattr   =>"W5SIEM_secent.ipaddress"),

      new kernel::Field::Text(
                name          =>'dnsname',
                label         =>'DNS',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"W5SIEM_secent.dns"),

      new kernel::Field::Text(
                name          =>'netbios',
                label         =>'NetBIOS',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"W5SIEM_secent.netbios"),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'possible W5Base System',
                vjointo       =>'itil::system',
                searchable    =>0,
                vjoinbase     =>[{cistatusid=>"<=4"}],
                vjoinon       =>['ipaddress'=>'ipaddresses'],
                vjoindisp     =>['name','applications']),

      new kernel::Field::Text(
                name          =>'tracking_method',
                label         =>'Tracking Meth',
                searchable    =>0,
                dataobjattr   =>"W5SIEM_secent.tracking_method"),

      new kernel::Field::Text(
                name          =>'os',
                label         =>'OS',
                htmlwidth     =>'200',
                dataobjattr   =>"W5SIEM_secent.osname"),

      new kernel::Field::Text(
                name          =>'ipstatus',
                label         =>'IP Status',
                sqlorder      =>'NONE',
                searchable    =>0,
                dataobjattr   =>"W5SIEM_secent.ipstatus"),

      new kernel::Field::Boolean(
                name          =>'islatest',
                htmldetail    =>0,
                label         =>'is latest',
                dataobjattr   =>"secscan.islatest"),

      new kernel::Field::Boolean(
                name          =>'isdup',
                htmldetail    =>0,
                selectfix     =>1,
                label         =>'is duplicate',
                dataobjattr   =>"decode(dupsecent.ref,NULL,0,1)"),

      new kernel::Field::Text(
                name          =>'qid',
                htmltablesort =>'Number',
                selectfix     =>1,
                label         =>'QID',
                dataobjattr   =>"W5SIEM_secent.qid"),

      # CERT Daten sind in QID= ...
      # 86002, 38600,38170,38173,38169,38167 sind relevant, wobei 86002 das
      # Zert.Detail hat.

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Title',
                dataobjattr   =>"W5SIEM_secent.title"),

      new kernel::Field::Text(
                name          =>'vuln_status',
                label         =>'Vuln Status',
                dataobjattr   =>"W5SIEM_secent.vuln_status"),

      new kernel::Field::Text(
                name          =>'ent_type',
                label         =>'Type',
                dataobjattr   =>"W5SIEM_secent.ent_type"),

      new kernel::Field::Text(
                name          =>'severity',
                label         =>'Severity',
                selectfix     =>1,
                dataobjattr   =>"W5SIEM_secent.severity"),

      new kernel::Field::Text(
                name          =>'port',
                htmltablesort =>'Number',
                label         =>'Port',
                dataobjattr   =>"W5SIEM_secent.port"),

      new kernel::Field::Text(
                name          =>'protocol',
                label         =>'Protocol',
                dataobjattr   =>"W5SIEM_secent.protocol"),

      new kernel::Field::Text(
                name          =>'ssl',
                label         =>'SSL',
                dataobjattr   =>"W5SIEM_secent.ssl"),

      new kernel::Field::Date(
                name          =>'firstdetect',
                label         =>'First Detect',
                dataobjattr   =>'W5SIEM_secent.first_detect'),

      new kernel::Field::Date(
                name          =>'lastdetect',
                label         =>'Last Detect',
                dataobjattr   =>'W5SIEM_secent.last_detect'),

      new kernel::Field::Text(
                name          =>'cveid',
                label         =>'CVE ID',
                dataobjattr   =>"W5SIEM_secent.cve_id"),

      new kernel::Field::Text(
                name          =>'bugtraqid',
                label         =>'Bugtraq ID',
                dataobjattr   =>"W5SIEM_secent.bugtraq_id"),

      new kernel::Field::Text(
                name          =>'sslparsedserial',
                label         =>'SSL parsed Serial',
                group         =>'sslcert',
                depend        =>'results',
                onRawValue    =>\&parseSSL),

      new kernel::Field::Text(
                name          =>'sslparsedissuer',
                label         =>'SSL parsed Issuer',
                group         =>'sslcert',
                depend        =>'results',
                onRawValue    =>\&parseSSL),

      new kernel::Field::Date(
                name          =>'sslparsedvalidfrom',
                label         =>'SSL parsed Valid From',
                group         =>'sslcert',
                depend        =>'results',
                onRawValue    =>\&parseSSL),

      new kernel::Field::Date(
                name          =>'sslparsedvalidtill',
                label         =>'SSL parsed Valid Till',
                group         =>'sslcert',
                depend        =>'results',
                onRawValue    =>\&parseSSL),

      new kernel::Field::Number(
                name          =>'sslparsedvalidity',
                label         =>'SSL parsed validity period',
                unit          =>'days',
                group         =>'sslcert',
                depend        =>'results',
                onRawValue    =>\&parseSSL),

      new kernel::Field::TextURL(
                name          =>'sslparsedw5baseref',
                label         =>'SSL Cert W5Ref',
                group         =>'sslcert',
                depend        =>['results',"sslparsedissuer","sslparsedserial"],
                onRawValue    =>\&sslparsew5baseref),


      new kernel::Field::Textarea(
                name          =>'vendor_reference',
                label         =>'Vendor Reference',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.vendor_reference'),

      new kernel::Field::Textarea(
                name          =>'impact',
                label         =>'Impact',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.impact'),

      new kernel::Field::Textarea(
                name          =>'exploitability',
                label         =>'Exploitability',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.exploitability'),

      new kernel::Field::Textarea(
                name          =>'associated_malware',
                label         =>'Associated Malware',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.associated_malware'),

      new kernel::Field::Text(
                name          =>'pci_vuln',
                label         =>'PCI Vuln',
                selectfix     =>1,
                dataobjattr   =>"W5SIEM_secent.pci_vuln"),

      new kernel::Field::Text(
                name          =>'category',
                label         =>'Category',
                dataobjattr   =>"W5SIEM_secent.category"),

      new kernel::Field::Text(
                name          =>'perspective',
                htmldetail    =>0,
                label         =>'perspective',
                dataobjattr   =>"secscan.scanperspective"),

      new kernel::Field::Text(
                name          =>'scanname',
                label         =>'Scan Title',
                sqlorder      =>'NONE',
                weblinkto     =>'tssiem::secscan',
                weblinkon     =>['scanqref'=>'qref'],
                group         =>'scan',
                dataobjattr   =>"secscan.title"),

      new kernel::Field::Text(
                name          =>'scanqref',
                group         =>'scan',
                label         =>'Scan-ID',
                dataobjattr   =>'secscan.ref'),

      new kernel::Field::Link(
                name          =>'scanid',
                label         =>'Scan ID',
                group         =>'scan',
                dataobjattr   =>"secscan.id"),

      new kernel::Field::Textarea(
                name          =>'results',
                label         =>'Results',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.results'),

      new kernel::Field::Textarea(
                name          =>'threat',
                label         =>'Threat',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.threat'),

      new kernel::Field::Textarea(
                name          =>'solution',
                label         =>'Solution',
                htmldetail    =>'NotEmpty',
                sqlorder      =>'NONE',
                dataobjattr   =>'W5SIEM_secent.solution'),


      new kernel::Field::Number(
                name          =>'ntimes',
                label         =>'Times detected',
                dataobjattr   =>"W5SIEM_secent.times_detected"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>"'Qualys'"),

      new kernel::Field::Id(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'W5SIEM_secent.id'),

      new kernel::Field::Text(
                name          =>'exptickettitle',
                group         =>'msgtracking',
                readonly      =>1,
                label         =>'expected PRM title',
                dataobjattr   =>"secscan.ictoid||' - '". #muss irgendwann objid
                                "||W5SIEM_secent.category||' - '".
                                "||secscan.scanperspective"),

      new kernel::Field::Text(
                name          =>'msghash',
                group         =>'msgtracking',
                readonly      =>1,
                selectfix     =>1,
                label         =>'Message-MD5-Hash',
                dataobjattr   =>getMsgHashSQL()),

      new kernel::Field::TextURL(
                name          =>'msghashurl',
                group         =>'msgtracking',
                readonly      =>1,
                label         =>'Message-URL',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $EventJobBaseUrl=$app->Config->Param("EventJobBaseUrl");
                   my $url=$EventJobBaseUrl;
                   $url.="/" if (!($url=~m/\/$/)); 
                   $url.="auth/tssiem/secent/ByHash/";
                   $url.=$current->{msghash};
                   return($url);
                }),

      new kernel::Field::Link(
                name          =>'ofid',
                label         =>'Overflow ID',
                readonly      =>1,
                group         =>'msgtracking',
                dataobjattr   =>'W5SIEM_secent_of.msghash'),


      new kernel::Field::Text(
                name          =>'prmid',
                label         =>'ProblemTicketID',
                group         =>'msgtracking',
                dataobjattr   =>'W5SIEM_secent_of.prmid'),

      new kernel::Field::Textarea(
                name          =>'prmidcomment',
                label         =>'ProblemTicket Comments',
                group         =>'msgtracking',
                dataobjattr   =>'W5SIEM_secent_of.prmcomment'),

      new kernel::Field::Text(
                name          =>'rskid',
                label         =>'RiskTicketID',
                group         =>'msgtracking',
                dataobjattr   =>'W5SIEM_secent_of.rskid'),

      new kernel::Field::Textarea(
                name          =>'rskidcomment',
                label         =>'RiskTicket Comments',
                group         =>'msgtracking',
                dataobjattr   =>'W5SIEM_secent_of.rskcomment'),


      new kernel::Field::RecordUrl(),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'secscan.importdate'),

      new kernel::Field::Link(
                name          =>'qref',
                group         =>'source',
                label         =>'Scan-Ref',
                dataobjattr   =>'W5SIEM_secent.ref'),

   );
   $self->{use_distinct}=0;
   $self->setDefaultView(qw(ictono 
        sdate ipaddress tracking_method os qid name vuln_status ent_type
       severity port ssl firstdetect lastdetect vendor_reference impact
       exploitability));
   $self->setWorktable("W5SIEM_secent_of");
   return($self);
}


sub getMsgHashSQL
{
   my $d="replace(standard_hash(".
         "secscan.ictoid||'-'".  # muss irgendwann objid
         "||W5SIEM_secent.ipaddress||'-'".
         "||W5SIEM_secent.port||'-'".
         "||W5SIEM_secent.qid".
         ",'MD5'),' ','')";
   return($d);
}


sub ValidatedUpdateRecord
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my @filter=@_;

   $filter[0]={ofid=>\$oldrec->{msghash}};
   $newrec->{ofid}=$oldrec->{msghash};  # als Referenz in der Overflow 
   if (!defined($oldrec->{ofid})){      # msghash verwenden
      return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;


   if (effChanged($oldrec,$newrec,"prmid")){
      my $prmid=effVal($oldrec,$newrec,"prmid");
      if ($prmid ne "" && !($prmid=~m/^PRM/)){ # da muss noch ein besserer 
                                               # check rein!
         $self->LastMsg(ERROR,"prmid could not be changed at now");
         return(undef);
      }
   }
   return($self->SUPER::Validate($oldrec,$newrec,$orgrec));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=qw(default source header scan);

   if ($rec->{qid} eq "86002"){
      push(@l,"sslcert");
   }
   if (lc($rec->{pci_vuln}) eq "yes" &&
       ($rec->{severity} eq "4" ||
        $rec->{severity} eq "5") &&
       $rec->{isdup} eq "0" ){
      push(@l,"msgtracking");
   }

   
   return(@l);
}


sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),qw(ByHash));
}


sub ByHash
{
   my ($self)=@_;
   my $idfield=$self->IdField();
   my $idname=$idfield->Name();
   my $val="undefined";
   if (defined(Query->Param("FunctionPath"))){
      $val=Query->Param("FunctionPath");
   }
   $val=~s/^\///;
   $val="UNDEF" if ($val eq "");

   $self->ResetFilter();
   $self->SetFilter({msghash=>\$val,islatest=>\'1'});
   my ($secrec,$msg)=$self->getOnlyFirst(qw(srcid)); 
   my $id=$val;
   if (defined($secrec)){
      $id=$secrec->{srcid};
   }
   $self->HtmlGoto("../ById/$id");
   return();
}






sub sslparsew5baseref
{
   my $self=shift;
   my $current=shift;

   my $issuer=$self->getParent->getField("sslparsedissuer")->RawValue($current);
   my $serial=$self->getParent->getField("sslparsedserial")->RawValue($current);

   my $swi=$self->getParent->getPersistentModuleObject("w5swi",
                                                       "itil::swinstance");

   my $wal=$self->getParent->getPersistentModuleObject("w5wal",
                                                       "itil::applwallet");


   $swi->SetFilter({
      ssl_cert_issuerdn=>'"'.$issuer.'"',
      ssl_cert_serialno=>'"'.$serial.'"',
      cistatusid=>"<6"
   });
   my ($swirec,$msg)=$swi->getOnlyFirst(qw(urlofcurrentrec));
   if (defined($swirec)){
      return($swirec->{urlofcurrentrec});
   }


   $wal->SetFilter({
      issuerdn=>'"'.$issuer.'"',
      serialno=>'"'.$serial.'"'
   });
   my ($walrec,$msg)=$wal->getOnlyFirst(qw(urlofcurrentrec));
   if (defined($walrec)){
      return($walrec->{urlofcurrentrec});
   }
   return(undef);
}


sub parseSSL
{
   my $self=shift;
   my $current=shift;
   my $results=$current->{results};
   my $id=$current->{srcid};
   my $app=$self->getParent();
   my $c=$self->getParent->Context();
   return(undef) if (!defined($results) || $results eq "");
   my $cacheKey="parsedSSL";

   if (!defined($c->{$cacheKey}->{$id})){
      my %l;
      my $lineno=0;
      my $certno;
      my $inissuer=0;
      my %issuer;
      $results=~s/\r\n/\n/g;
      my @results=split("\n",$results);
      while(my $line=shift(@results)){
         if (my ($n)=$line=~m/^\(([0-9]{1,2})\)/){
            $certno=$n;
            $inissuer=0;
         }
         if ($certno eq "0"){
            if ($inissuer){
               if (my ($s)=$line=~m/^\s*countryName\s*(.*)\s*$/){
                  $issuer{C}=$s;
               }
               if (my ($s)=$line=~m/^\s*organizationName\s*(.*)\s*$/){
                  $issuer{O}=$s;
               }
               if (my ($s)=$line=~m/^\s*stateOrProvinceName\s*(.*)\s*$/){
                  $issuer{ST}=$s;
               }
               if (my ($s)=$line=~m/^\s*postalCode\s*(.*)\s*$/){
                  $issuer{postalCode}=$s;
               }
               if (my ($s)=$line=~m/^\s*localityName\s*(.*)\s*$/){
                  $issuer{L}=$s;
               }
               if (my ($s)=$line=~m/^\s*streetAddress\s*(.*)\s*$/){
                  $issuer{street}=$s;
               }
               if (my ($s)=$line=~m/^\s*commonName\s*(.*)\s*$/){
                  $issuer{CN}=$s;
               }
               if (my ($s)=$line=~m/^\s*organizationalUnitName\s*(.*)\s*$/){
                  $issuer{OU}=$s;
               }
            }
            if (my ($s)=$line=~m/^\(0\)Serial Number\s+(.*)\s*$/){
               $s=~s/\s*\(Negative\)\s*//i;
               $s=~s/^\s*//;
               $s=~s/\s*$//;
               if ($s=~m/^[0-9a-fA-F:]+$/i){
                  $s=~s/://g;
               }
               $s=trim($s);
               if (my ($hex)=$s=~m/^[0-9]+\s*\((0x[0-9a-f]+)\)$/i){
                  $hex=~s/^0x//i;
                  $s=$hex;
               }
               $l{sslparsedserial}=uc($s);
            }
            if (my ($s)=$line=~m/^\(0\)Valid Till\s*(.*)\s*$/){
               $l{sslparsedvalidtill}=Localtime("GMT",str2time($s));
            }
            if (my ($s)=$line=~m/^\(0\)Valid From\s*(.*)\s*$/){
               $l{sslparsedvalidfrom}=Localtime("GMT",str2time($s));
            }
            if (my ($s)=$line=~m/^\(0\)ISSUER NAME\s*$/){
               $inissuer=1;
            }
         }
         $lineno++;
      }
      if (keys(%issuer)){
         my $i="";
         foreach my $k (qw(C O OU ST postalCode L street CN)){
            if (exists($issuer{$k})){
               $i.=", " if ($i ne "");
               $i.="$k=".$issuer{$k};
            }
         }
         $l{sslparsedissuer}=$i;
      } 
      $l{sslparsedvalidity}=undef;
      if ($l{sslparsedvalidfrom} ne "" &&
          $l{sslparsedvalidtill} ne ""){
         my $d=CalcDateDuration($l{sslparsedvalidfrom},$l{sslparsedvalidtill});
         if (defined($d)){
            $l{sslparsedvalidity}=$d->{days};
         }
      }
      $c->{$cacheKey}->{$id}=\%l;
   }
   return($c->{$cacheKey}->{$id}->{$self->Name});
}



sub getSqlFrom
{
   my $self=shift;

   my $secscansql=$self->getSecscanFromSQL();
   my $from="W5SIEM_secent ".
            "join ($secscansql) secscan ".
               "on W5SIEM_secent.ref=secscan.ref ".
            "left outer join ($secscansql) dupsecscan ".
               "on secscan.ictoid=dupsecscan.ictoid ".
                   " and dupsecscan.islatest='1' ".
                   " and dupsecscan.scanperspective='CNDTAG' ".
                   " and secscan.scanperspective<>'CNDTAG' ".
            "left outer join ( ".  # prevent duplicated old messages
                  "select distinct ref,ipaddress,port,category,qid ".
                  "from W5SIEM_secent".
               ") dupsecent ".
               "on dupsecscan.ref=dupsecent.ref ".
                   " and W5SIEM_secent.ipaddress=dupsecent.ipaddress ".
                   " and W5SIEM_secent.port=dupsecent.port ".
                   " and W5SIEM_secent.category=dupsecent.category ".
                   " and W5SIEM_secent.qid=dupsecent.qid ".
            "left outer join W5SIEM_secent_of on ".
               getMsgHashSQL()."=W5SIEM_secent_of.msghash";
   return($from);
}






sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_islatest"))){
     Query->Param("search_islatest"=>$self->T("yes"));
   }
   if (!defined(Query->Param("search_isdup"))){
     Query->Param("search_isdup"=>$self->T("no"));
   }
}







sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.tssiem.secscan.read
                              w5base.tssiem.secent.read
                              w5base.tssiem.secent.write
                              w5base.tssiem.secent.read)],
                          "RMember")){
      my @addflt;
      $self->addICTOSecureFilter(\@addflt);
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
}





sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","scan","sslcert","msgtracking","source");
}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/tssiem/load/qualys_secent.jpg?".$cgi->query_string());
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if (defined($rec)){
      if ($self->IsMemberOf([qw(admin w5base.tssiem.secent.write)])){
         return("msgtracking");
      }
   }
   return(undef);
}

         

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

         



1;
