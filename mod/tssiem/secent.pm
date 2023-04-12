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
use itil::lib::Listedit;
use kernel::Field;
use Date::Parse;
use kernel::date;
@ISA=qw(tssiem::lib::Listedit);


sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=6 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Text(
                name          =>'ictono',
                label         =>'ICTO-ID',
                group         =>'scan',
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"secscan.ictoid"),  # In Zukunft sollte die dann
                                            # irgendwann optional sein

      new kernel::Field::TextDrop(
                name          =>'appl',
                label         =>'Application',
                htmldetail    =>'NotEmpty',
                group         =>'scan',
                vjointo       =>'itil::appl',
                vjoinon       =>['applid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'itscanobjectid',
                htmldetail    =>'NotEmpty',
                group         =>'source',
                searchable    =>0,
                label         =>'IT-ScanObjectID',
                dataobjattr   =>"decode(secscan.w5baseid_appl,NULL,".
                                "secscan.ictoid,secscan.w5baseid_appl)"), 

      new kernel::Field::Text(                  
                name          =>'applid',             # primär Zuordnung
                label         =>'Application W5BaseID',
                group         =>'source',
                selectfix     =>1,
                htmldetail    =>'NotEmpty',
                dataobjattr   =>"secscan.w5baseid_appl"),

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

      new kernel::Field::Boolean(
                name          =>'ismsgtrackingactive',
                htmldetail    =>0,
                selectfix     =>1,
                label         =>'is Message Tracking active',
                dataobjattr   =>$self->getMsgTrackingFlagSQL()),

      new kernel::Field::Text(
                name          =>'name',
                label         =>'Title',
                dataobjattr   =>"W5SIEM_secent.title"),

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
                name          =>'cvssbasescore',
                htmldetail    =>'NotEmpty',
                label         =>'CVSS base score',
                dataobjattr   =>"W5SIEM_secent.cvss_basescore"),

      new kernel::Field::Text(
                name          =>'cvssscorestr',
                htmldetail    =>'NotEmpty',
                label         =>'CVSS score',
                dataobjattr   =>"W5SIEM_secent.cvss_scorestr"),

      new kernel::Field::Text(
                name          =>'vuln_status',
                htmldetail    =>'NotEmpty',
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

      new kernel::Field::Text(
                name          =>'sslparsedchainlength',
                label         =>'SSL parsed Chain Length',
                group         =>'sslcert',
                depend        =>'results',
                onRawValue    =>\&parseSSL),

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
                label         =>'Security Scan Title',
                sqlorder      =>'NONE',
                weblinkto     =>'tssiem::secscan',
                weblinkon     =>['scanqref'=>'qref'],
                group         =>'scan',
                dataobjattr   =>"secscan.title"),

      new kernel::Field::Text(
                name          =>'scanqref',
                group         =>'scan',
                label         =>'Security Scan ID',
                dataobjattr   =>'secscan.ref'),

      new kernel::Field::Link(
                name          =>'scanid',
                label         =>'Security Scan ID',
                group         =>'scan',
                dataobjattr   =>"secscan.ref"),

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
                dataobjattr   =>"'QualysIPScan:'".
                                "||secscan.ictoid||' - '".#muss irgendwann objid
                                "||W5SIEM_secent.category||' - '".
                                "||secscan.scanperspective||'-'".
                                "||'S'||W5SIEM_secent.severity"),

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
                searchable    =>0,
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

      new kernel::Field::Text(
                name          =>'prmid1st',
                label         =>'first ProblemTicketID',
                group         =>'msgtracking',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'W5SIEM_secent_of.firstprmid'),

      new kernel::Field::Date(
                name          =>'prmid1stdate',
                group         =>'msgtracking',
                htmldetail    =>0,
                readonly      =>1,
                label         =>'first ProblemTicketID Date',
                dataobjattr   =>'W5SIEM_secent_of.firstprmiddate'),

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

      new kernel::Field::Text(
                name          =>'desiredsm9applid',
                label         =>'desired SM9 ApplicationID',
                group         =>'msgtracking',
                htmldetail    =>0,
                depend        =>[qw(ictono ipaddress perspective 
                                    severity systems)],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&calcSM9desVars),

      new kernel::Field::Text(
                name          =>'desiredsm9applci',
                label         =>'desired SM9 Application CI',
                group         =>'msgtracking',
                htmldetail    =>0,
                depend        =>[qw(ictono ipaddress perspective 
                                    severity systems)],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&calcSM9desVars),

      new kernel::Field::Text(
                name          =>'desiredsm9applag',
                label         =>'desired SM9 Problem Assignmentgroup',
                group         =>'msgtracking',
                htmldetail    =>0,
                depend        =>[qw(ictono ipaddress perspective 
                                    severity systems)],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&calcSM9desVars),

      new kernel::Field::Text(
                name          =>'desiredsm9prmprio',
                label         =>'desired SM9 Problem Prio',
                group         =>'msgtracking',
                htmldetail    =>0,
                depend        =>[qw(ictono ipaddress perspective 
                                    severity systems)],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&calcSM9desVars),

      new kernel::Field::Text(
                name          =>'desiredsm9prmcbi',
                label         =>'desired SM9 Problem CBI',
                group         =>'msgtracking',
                htmldetail    =>0,
                depend        =>[qw(ictono ipaddress perspective 
                                    severity systems)],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&calcSM9desVars),

      new kernel::Field::Text(
                name          =>'desiredsm9daystofix',
                label         =>'desired SM9 Problem Days to fix',
                group         =>'msgtracking',
                htmldetail    =>0,
                depend        =>[qw(ictono ipaddress perspective 
                                    severity systems)],
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>\&calcSM9desVars),


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


sub calcSM9desVars   # find SM9 App based on ip and ictoid
{
   my $self=shift;
   my $rec=shift;
   my $app=$self->getParent();
   my $C=$app->Context();
   my $name=$self->Name();
   my $idfield=$app->IdField();
   my $id=$idfield->RawValue($rec);

   $C->{sm9Cache}={} if (!exists($C->{sm9Cache}));
   $C=$C->{sm9Cache};

   if (!exists($C->{$id})){
      my $tsapp=$app->getPersistentModuleObject("w5TSappl","TS::appl");
      my $ip=$rec->{ipaddress};
      my $ictono=$rec->{ictono};
      my $systemsfld=$app->getField("systems",$rec);
      my $systems=$systemsfld->RawValue($rec);
      my $smrec={};
      my @applid;
      if ($#{$systems}!=-1){
         foreach my $sysrec (@{$systems}){
            if (ref($sysrec->{applications}) eq "ARRAY"){
               foreach my $applrec (@{$sysrec->{applications}}){
                  if (!in_array(\@applid,$applrec->{applid})){
                     push(@applid,$applrec->{applid});
                  }
               }
            }
         }
      }
      if ($#applid==-1 && $ictono ne ""){ # Hack - IP is not direct referenced
         $tsapp->ResetFilter();           # in any application - so we try to
         my $flt={                        # get first found prod application
            cistatusid=>"<6",             # in ICT-Object
            ictono=>\$ictono
         };
         $tsapp->SetFilter($flt);
         my @l=$tsapp->getHashList(qw(cistatusid opmode applid id));
         if ($#l<50){
            foreach my $arec (@l){
               if ($#applid==-1 && $arec->{opmode} eq "prod"){
                  push(@applid,$arec->{id});
               }
            }
            foreach my $arec (@l){
               if ($#applid==-1){
                  push(@applid,$arec->{id});
               }
            }
         }
      }
      if ($#applid!=-1){
         $tsapp->ResetFilter();
         my $flt={
            cistatusid=>"<6",
            id=>\@applid
         };
         if ($ictono ne ""){
            $flt->{ictono}=\$ictono;
         }
         $tsapp->SetFilter($flt);
         my @l=$tsapp->getHashList(qw(cistatusid acapplname applid 
                                    acinmassingmentgroup));
         if ($#l!=-1){
            while(my $arec=shift(@l)){
               if ($arec->{applid} ne ""){
                  $smrec->{desiredsm9applid}=$arec->{applid};
                  $smrec->{desiredsm9applci}=$arec->{acapplname};
                  $smrec->{desiredsm9applag}=$arec->{acinmassingmentgroup};
                  if (lc($rec->{perspective}) eq "internet"){
                     if ($rec->{severity} eq "5"){
                        $smrec->{desiredsm9prmprio}="HIGH"; 
                        $smrec->{desiredsm9daystofix}=2*30;  # 2 Monate
                        $smrec->{desiredsm9prmcbi}="HIGH"; 
                     }
                     if ($rec->{severity} eq "4"){
                        $smrec->{desiredsm9prmprio}="MEDIUM"; 
                        $smrec->{desiredsm9daystofix}=3*30;  # 3 Monate
                        $smrec->{desiredsm9prmcbi}="MEDIUM"; 
                     }
                     if ($rec->{severity} eq "3"){
                        $smrec->{desiredsm9prmprio}="MEDIUM"; 
                        $smrec->{desiredsm9prmcbi}="LOW"; 
                        $smrec->{desiredsm9daystofix}=6*30;  # 6 Monate
                     }
                  }
                  else{
                     if ($rec->{severity} eq "5"){
                        $smrec->{desiredsm9prmprio}="HIGH"; 
                        $smrec->{desiredsm9daystofix}=2*30;  # 2 Monate
                        $smrec->{desiredsm9prmcbi}="HIGH"; 
                     }
                     if ($rec->{severity} eq "4"){
                        $smrec->{desiredsm9prmprio}="MEDIUM"; 
                        $smrec->{desiredsm9prmcbi}="MEDIUM"; 
                        $smrec->{desiredsm9daystofix}=6*30;  # 3 Monate
                     }
                  }
                  last;
               }
            }
         }
      }
      #print STDERR Dumper($rec);
      #print STDERR Dumper(\@applid);
      $C->{$id}=$smrec;
   }

   return($C->{$id}->{$name});
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
      my $newid=$self->SUPER::ValidatedInsertRecord({ofid=>$oldrec->{msghash}});
     # return($self->SUPER::ValidatedInsertRecord($newrec));
   }
   return($self->SUPER::ValidatedUpdateRecord($oldrec,$newrec,@filter));
}



sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $orgrec=shift;

   my $prmid=effVal($oldrec,$newrec,"prmid");


   if (!defined($oldrec) || effChanged($oldrec,$newrec,"prmid")){
      if ($prmid ne ""){
         if (!($prmid=~m/^PM[0-9]+$/)){ 
            $self->LastMsg(ERROR,"problem ticket not correct formated");
            return(undef);
         }
         my $pm=$self->getPersistentModuleObject("w5sm9pm","tssm::prm");
         if (!defined($pm) || !$pm->Ping()){
            $self->LastMsg(ERROR,"SM9 not available to verify prm ticket");
            return(undef);
         }
         $pm->SetFilter({problemnumber=>\$prmid});
         my ($prmrec,$msg)=$pm->getOnlyFirst(qw(problemnumber name
                                                  description status));
         if (!defined($prmrec)){ 
            $self->LastMsg(ERROR,"PRM TicketID does not exists in SM9");
            return(undef);
         }
         if (!$self->ValidatePRMTicket($oldrec,$newrec,$prmrec)){
            return(undef);
         }
      }
   }

   if (defined($oldrec) && $oldrec->{prmid1st} eq "" && $prmid ne ""){
      $newrec->{prmid1st}=$prmid;
      $newrec->{prmid1stdate}=NowStamp("en");
   }

   return($self->SUPER::Validate($oldrec,$newrec,$orgrec));
}


sub ValidatePRMTicket
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $prmrec=shift;

   my $exptickettitle=effVal($oldrec,$newrec,"exptickettitle");

   if ($exptickettitle ne $prmrec->{name}){
      $self->LastMsg(ERROR,"PRM Ticket title is not correct");
      return(undef);
   }
   my @desc=split(/[\r\n]+/,$prmrec->{description});
   @desc=grep(/\/ByHash\/[A-Z,0-9]{5,40}\s*$/,@desc);

   my %h;
   map({
      my $l=$_;
      $l=~s/^.*\/ByHash\///;
      $l=~s/\s*$//;
      $h{$l}++;
   } @desc);

   my $msghash=effVal($oldrec,$newrec,"msghash");
   if ($msghash ne ""){
      if (!in_array([keys(%h)],$msghash)){
         $self->LastMsg(ERROR,"SecEntry is not referenced in PRM Ticket");
         return(undef);
      }
   }
   return(1);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;

   my @l=qw(default source header scan);

   if ($rec->{qid} eq "86002"){
      push(@l,"sslcert");
   }
   if ($rec->{ismsgtrackingactive} eq "1" &&
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
   
   return(
      itil::lib::Listedit::sslparsew5baseref($self,$issuer,$serial,$current)
   );
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
      my @results=grep(!/^\s*$/,split("\n",$results));
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
      if (defined($certno) && $certno ne ""){
         $l{sslparsedchainlength}=$certno+1;
      }
      else{
         $l{sslparsedchainlength}=0;
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
   my $mode=shift;
   my @filter=@_;



   my $secscansql=$self->getSecscanFromSQL();
   my $from="W5SIEM_secent ".
            "join ($secscansql) secscan ".
               "on W5SIEM_secent.ref=secscan.ref ".
            "left outer join ($secscansql) dupsecscan ".
               "on ".
                   # "(".
                   #  "(secscan.w5baseid_appl is not null and ".
                   #    "secscan.w5baseid_appl=dupsecscan.w5baseid_appl)".
                   #   " or ".
                   #  "(secscan.w5baseid_appl is null and ".
                   #    "secscan.ictoid=dupsecscan.ictoid)".
                   # ") ".
                    "(secscan.w5baseid_appl=dupsecscan.w5baseid_appl and ".
                    "secscan.ictoid=dupsecscan.ictoid)".
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
