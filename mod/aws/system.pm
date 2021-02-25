package aws::system;
#  W5Base Framework
#  Copyright (C) 2020  Hartmut Vogler (it@guru.de)
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
use kernel::cgi;
use aws::lib::Listedit;
use Data::Printer;
@ISA=qw(aws::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Id(       name       =>'idpath',
                                   htmlwidth  =>'150',
                                   searchable =>0,
                                   label      =>'AWS-IdPath'),
      new kernel::Field::Text(     name       =>'id',
                                   htmlwidth  =>'150',
                                   label      =>'EC2-InstanceID'),
      new kernel::Field::Text(     name       =>'name',
                                   label      =>'Name'),
      new kernel::Field::Text(    name       =>'ipaddress',
                                  searchable =>0,
                                  label      =>'private IP-Address',
                                  dataobjattr=>'private_ip_address'),
      new kernel::Field::Container(name       =>'interfaces',
                                   uivisible  =>1,
                                   label      =>'Interfaces'),
      new kernel::Field::Text(    name       =>'cpucount',
                                  searchable =>0,
                                  label      =>'CPU-Count'),
      new kernel::Field::Text(    name       =>'memory',
                                  searchable =>0,
                                  label      =>'Memory'),
      new kernel::Field::Text(    name       =>'type',
                                  searchable =>0,
                                  label      =>'Instance type'),
      new kernel::Field::Text(    name       =>'accountid',
                                  label      =>'AWS-AccountID'),
      new kernel::Field::Text(    name       =>'region',
                                  label      =>'AWS-Region'),
      new kernel::Field::Date(    name       =>'cdate',
                                  label      =>'Creation-Date'),
      new kernel::Field::Container(name       =>'tags',
                                   uivisible  =>1,
                                   label      =>'Tags')
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id ipaddress accountid cdate));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my @view=$self->GetCurrentView();


   my @result;

   return(undef) if (!$self->genericSimpleFilterCheck4AWS($filterset));
   my $filter=$filterset->{FILTER}->[0];

   my $query=$self->decodeFilter2Query4AWS($filter);
   if (exists($query->{idpath})){
      if (my ($id,$accountid,$region)=
          $query->{idpath}=~m/^(i-\S+)\@([0-9]+)\@(\S+)$/){
         if (exists($query->{id}) && 
             $query->{id} ne ""  &&
             $query->{id} ne $id){
            return([]);
         }
         $query->{id}=$id;
         if (exists($query->{accountid}) && 
             $query->{accountid} ne ""  &&
             $query->{accountid} ne $accountid){
            return([]);
         }
         $query->{accountid}=$accountid;
         if (exists($query->{region}) && 
             $query->{region} ne "" &&
             $query->{region} ne $region){
            return([]);
         }
         $query->{region}=$region;
      }
      else{
         return([]);
      }
   }


   if (!exists($query->{accountid}) ||
       !($query->{accountid}=~m/^\d{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary accountid filter not specifed");
      #print STDERR Dumper($query);
      return(undef);
   }
   if (!exists($query->{region}) ||
       !($query->{region}=~m/^\S{3,20}$/)){
      $self->LastMsg(ERROR,"mandatary region filter not specifed");
      #print STDERR Dumper($query);
      return(undef);
   }
   my $AWSAccount=$query->{accountid};
   my $AWSRegion=$query->{region};

   my ($awsconnect,$awspass,$awsuser)=$self->GetRESTCredentials("aws");


   my $ua;
   eval('
      use LWP::UserAgent;
      #$ua=new LWP::UserAgent(env_proxy=>0,ssl_opts =>{verify_hostname=>0});
      $ua=new LWP::UserAgent(env_proxy=>0,timeout=>60);
      push(@{$ua->requests_redirectable},"POST");
   ');
   if ($@ ne ""){
      $self->LastMsg(ERROR,"fail to create UserAgent for DoRESTcall");
      return(undef);
   }
   $ua->protocols_allowed( ['https','connect'] );
   my $probeipproxy=$self->Config->Param("http_proxy");
   if ($probeipproxy ne ""){
      $ua->proxy(['https'],$probeipproxy);
   }


   Paws->default_config->caller(new Paws::Net::LWPCaller(ua=>$ua));
   my $baseCred=Paws::Credential::Explicit->new(
         access_key=>$awsuser,
         secret_key=>$awspass
   );

   my $stscred=Paws::Credential::AssumeRole->new(
     sts=>Paws->service('STS', credentials=>$baseCred,region=>$AWSRegion),
     Name=>'W5Base',DurationSeconds=>900,
     RoleSessionName => 'SACMConfigAccess',
     RoleArn => 'arn:aws:iam::'.$AWSAccount.':'.$awsconnect
   );

   my $ec2=Paws->service('EC2',credentials=>$stscred,region =>$AWSRegion);
   my $blk=0;
   my $NextToken;
   do{
      my %param=();
      if ($NextToken ne ""){
         $param{NextToken}=$NextToken;
      }
      if (exists($query->{id}) && $query->{id} ne ""){
         $param{InstanceIds}=[$query->{id}];
      }
      else{
         $param{MaxResults}=20;
      }
      my $InstanceItr=$ec2->DescribeInstances(%param);
      foreach my $res (@{$InstanceItr->Reservations()}){
         foreach my $instance (@{$res->Instances}){
            #p $instance;
            #printf STDERR ("Account: $AWSAccount Intance:%s\n",$instance->{InstanceId});
            my $cdate=$instance->{LaunchTime};
            $cdate=~s/^(\S+)T(\S+).000Z$/$1 $2/;
            my %tag;
            foreach my $tag (@{$instance->Tags()}){
               $tag{$tag->Key()}=$tag->Value(); 
            }
            my $rec={
                id=>$instance->{InstanceId},
                type=>$instance->{InstanceType},
                accountid=>$AWSAccount,
                region=>$AWSRegion,
                name=>$tag{Name},
                tags=>\%tag,
                private_ip_address=>$instance->{PrivateIpAddress},
                cdate=>$cdate,
                idpath=>$instance->{InstanceId}.'@'.
                        $AWSAccount.'@'.
                        $AWSRegion,
            };
            if (in_array(\@view,"cpucount")){
               my $cpucount;
               my $CpuOptions=$instance->CpuOptions();
               if ($CpuOptions){
                  my $n=$CpuOptions->CoreCount();
                  $cpucount+=$n;
               }
               $rec->{cpucount}=$cpucount;
            }
            if (in_array(\@view,"interfaces")){
               my %ifs;
               foreach my $if (@{$instance->NetworkInterfaces()}){
                  my %ifrec;
                  my @v6=@{$if->Ipv6Addresses()};
                  if ($#v6!=-1){
                     msg(WARN,
                         "ipv6 handling not yet implemented in aws::system");
                  }
                  my @ips;
                  foreach my $iprec (@{$if->PrivateIpAddresses()}){
                     if ($iprec->Primary()){
                        $ifrec{primaryIp}=$iprec->PrivateIpAddress();
                     }
                     push(@ips,$iprec->PrivateIpAddress()." (".
                               $iprec->PrivateDnsName().")");
                  }
                  $ifrec{ipaddresses}=join(", ",@ips);
                  $ifrec{mac}=$if->MacAddress();
                 
                  $ifs{$if->NetworkInterfaceId()}=\%ifrec;
               }
               $rec->{interfaces}=\%ifs;
            }
            if (in_array(\@view,"memory")){
               my $mem;
               my $type=$instance->{InstanceType};
               if ($type ne ""){
                  my $types=$ec2->DescribeInstanceTypes(
                    InstanceTypes=>[$type],
                  );
                  foreach my $t (@{$types->InstanceTypes()}){
                     my $MemoryInfo=$t->MemoryInfo()->SizeInMiB();
                     $mem=$MemoryInfo;
                  }
               }
               $rec->{memory}=$mem;
            }
            push(@result,$rec);
         }
      }
      $NextToken=$InstanceItr->NextToken();
      $blk++;
   }while($NextToken ne "");


   return(\@result);
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_accountid"))){
     Query->Param("search_accountid"=>'238834862221');
   }
   if (!defined(Query->Param("search_region"))){
     Query->Param("search_region"=>'eu-central-1');
   }
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
                           title=>"AWS System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $importname;
   my ($ec2id,$accountid,$region);
   if ($param->{importname} ne ""){
      $importname=$param->{importname};
      msg(INFO,"start Import in aws::system with importname $importname");
      if (($ec2id,$accountid,$region)=$importname
              =~m/^(\S+)\@([0-9]+)\@(\S+)$/){
         $flt={
            id=>$ec2id,
            accountid=>$accountid,
            region=>$region
         };
      }
      else{
         $self->LastMsg(ERROR,"sieht schlecht aus");
         return(undef);
      }
   }
   else{
      msg(ERROR,"no importname specified while ".$self->Self." Import call");
      return(undef);
   }
   my $syssrcid=lc($importname);
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");
   my $itcloud=getModuleObject($self->Config,"itil::itcloud");
   my $cloudrec;
   {
      $itcloud->ResetFilter();
      $itcloud->SetFilter({name=>'AWS',cistatusid=>'4'});
      my ($crec,$msg)=$itcloud->getOnlyFirst(qw(ALL));
      if (defined($crec)){
         $cloudrec=$crec;
      }
      else{
         $self->LastMsg(ERROR,"no active AWS Cloud in inventory");
         return(undef);
      }
   }
   my $accountok=0;
   my $w5cloudarearec;
   foreach my $cloudarea (@{$cloudrec->{cloudareas}}){
      if ($cloudarea->{srcid} eq $accountid){
         $accountok++;
         $w5cloudarearec=$cloudarea;
      }
   }
   if (!$accountok){
      $self->LastMsg(ERROR,"AWS-AccountID %s not found in CloudAreas",$accountid);
      return(undef);
   }

   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(id name));
   if ($#l==-1){
      $self->LastMsg(ERROR,"EC2 Instanz not found in AWS");
      return(undef);
   }

   if ($#l>0){
      if ($self->isDataInputFromUserFrontend()){
         $self->LastMsg(ERROR,"Systemname '%s' not unique in AWS",
                              $param->{importname});
      }
      return(undef);
   }
   my $sysrec=$l[0];
   my $w5applrec;
   my $w5carec;

   my $applid=$w5cloudarearec->{applid};

   msg(INFO,"try to add appl ".$w5cloudarearec->{applid}.
            " to system ".$sysrec->{name});

   $appl->SetFilter({id=>\$applid});
   my ($apprec,$msg)=$appl->getOnlyFirst(qw(ALL));
   if (defined($apprec) && 
       in_array([qw(2 3 4)],$apprec->{cistatusid})){
      $w5applrec=$apprec;
   }



   my $w5sysrecmodified=0;
   my $sys=getModuleObject($self->Config,"TS::system");
   $sys->ResetFilter();
   $sys->SetFilter({srcsys=>\'AWS',srcid=>$syssrcid});
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   #if (!defined($w5sysrec)){
   #   $sys->ResetFilter();
   #   $sys->SetFilter($flt);
   #   ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   #}




   #printf STDERR ("fifi 01 $w5sysrec\n");die();


   if (!defined($w5sysrec)){   # srcid update kandidaten (schneller Redeploy)
      my @flt;

      if ($sysrec->{name} ne ""){
         push(@flt,{
           name=>\$sysrec->{name},
           srcsys=>\'AWS',
           srcid=>'!'.$syssrcid
         });
      }
      if ($sysrec->{ipaddress} ne ""){
         push(@flt,{
            ipaddresses=>\$sysrec->{ipaddress},
            srcsys=>\'AWS',
            srcid=>'!'.$syssrcid
         });
      }


#      $sys->SetFilter(\@flt);
#      my @redepl=$sys->getHashList(qw(mdate cistatusid name 
#                                      srcid srcsys applications));
#
#      msg(INFO,"invantar check for AWS-SystemID: $sysrec->{id}");
#      foreach my $osys (@redepl){   # find best matching redepl candidate
#         my $applok=0;
#         msg(INFO,"check AWS-SystemID: $osys->{srcid} from inventar");
#         if ($osys->{srcid} eq $sysrec->{id}){
#            msg(ERROR,"AWS-SystemID: $osys->{srcid} already in inventar");
#            # dieser Punkt dürfte nie erreicht werden, da ja oben bereits
#            # eine u.U. passende w5sysrec gesucht wurde.
#            last;
#         }
#         my $ageok=1;
#         if ($osys->{cistatusid} ne "4"){  # prüfen, ob das Teil nicht schon
#                                           # ewig alt ist
#            my $d=CalcDateDuration($osys->{mdate},NowStamp("en"));
#            if (defined($d) && $d->{days}>7){
#               next; # das Teil ist schon zu alt, um es wieder zu aktivieren
#            }
#         }
#         foreach my $appl (@{$osys->{applications}}){
#            if ($appl->{applid} eq $w5applrec->{id}){
#               $applok++;
#            }
#         }
#         my $sysallowed=0;
#         if ($ageok && $applok){
#            $self->ResetFilter();
#            $self->SetFilter({id=>\$osys->{srcid}});
#            msg(INFO,"check exist of AWS-SystemID: $osys->{srcid}");
#            my ($chkrec,$msg)=$self->getOnlyFirst(qw(id));
#            if (!defined($chkrec)){
#               msg(INFO,"AWS-SystemID: $osys->{srcid} does not exists anymore");
#               $sysallowed++;
#            }
#         }
#         if ($applok && $sysallowed && $ageok){
#            $sys->ResetFilter();
#            $sys->SetFilter({id=>\$osys->{id}});
#            my ($oldrec,$msg)=$sys->getOnlyFirst(qw(ALL));
#            if (defined($oldrec)){
#               if ($sys->ValidatedUpdateRecord($oldrec,{
#                       srcid=>$sysrec->{id},srcsys=>'AWS',
#                       cistatusid=>4
#                   },{id=>\$oldrec->{id}})) {
#                  $sys->ResetFilter();
#                  $sys->SetFilter({id=>\$osys->{id}});
#                  ($w5sysrec)=$sys->getOnlyFirst(qw(ALL));
#                  $w5sysrecmodified++;
#               }
#               last;
#            }
#         }
#      } 
   }

   my $identifyby;
   if (defined($w5sysrec)){
      if (uc($w5sysrec->{srcsys}) eq "AWS"){
         my $msg=sprintf($self->T("Systemname '%s' already imported in W5Base"),
                         $w5sysrec->{name});
         if ($w5sysrec->{cistatusid} ne "4" || $w5sysrecmodified){
            my %checksession;
            my $qc=getModuleObject($self->Config,"base::qrule");
            $qc->setParent($sys);
            $checksession{autocorrect}=$w5sysrec->{allowifupdate};
            $checksession{autocorrect}=1; # force import with autocorrect
            $qc->nativQualityCheck(
                 $sys->getQualityCheckCompat($w5sysrec),$w5sysrec,
                               \%checksession);
            return($w5sysrec->{id});
         }
         $self->LastMsg(ERROR,$msg);
         return(undef);
      }
   }
   if (defined($w5sysrec)){
      if ($w5sysrec->{srcsys} ne "AWS" &&
          lc($w5sysrec->{srcsys}) ne "w5base" &&
          $w5sysrec->{srcsys} ne ""){
         $self->LastMsg(ERROR,"name colision - systemname $w5sysrec->{name} ".
                              "already in use. Import failed");
         return(undef);
      }
   }

   my $curdataboss;
   if (defined($w5sysrec)){
      $curdataboss=$w5sysrec->{databossid};
      my %newrec=();
      my $userid;

      if ($self->isDataInputFromUserFrontend() &&   # only admins (and databoss)
                                                    # can force
          !$self->IsMemberOf("admin")) {            # reimport over webrontend
         $userid=$self->getCurrentUserId();         # if record already exists
         if ($w5sysrec->{cistatusid}<6 && $w5sysrec->{cistatusid}>2){
            if ($userid ne $w5sysrec->{databossid}){
               $self->LastMsg(ERROR,
                              "reimport only posible by current databoss");
               if (!$self->isDataInputFromUserFrontend()){
                  msg(ERROR,"fail to import $sysrec->{name} with ".
                            "id $sysrec->{id}");
               }
               return(undef);
            }
         }
      }
      if ($w5sysrec->{cistatusid} ne "4"){
         $newrec{cistatusid}="4";
      }
      if ($w5sysrec->{srcsys} ne "AWS"){
         $newrec{srcsys}="AWS";
      }
      if ($w5sysrec->{srcid} ne $sysrec->{id}){
         $newrec{srcid}=$syssrcid;
      }
      if ($w5sysrec->{systemtype} ne "standard"){
         $newrec{systemtype}="standard";
      }
      if ($w5sysrec->{osrelease} eq ""){
         $newrec{osrelease}="other";
      }
      if (defined($w5applrec) &&
          ($w5sysrec->{isprod}==0) &&
          ($w5sysrec->{istest}==0) &&
          ($w5sysrec->{isdevel}==0) &&
          ($w5sysrec->{iseducation}==0) &&
          ($w5sysrec->{isapprovtest}==0) &&
          ($w5sysrec->{isreference}==0) &&
          ($w5sysrec->{iscbreakdown}==0)) { # alter Datensatz - aber kein opmode
         if ($w5applrec->{opmode} eq "prod"){   # dann nehmen wir halt die
            $newrec{isprod}=1;                  # Anwendungsdaten
         }
         elsif ($w5applrec->{opmode} eq "test"){
            $newrec{istest}=1;
         }
         elsif ($w5applrec->{opmode} eq "devel"){
            $newrec{isdevel}=1;
         }
         elsif ($w5applrec->{opmode} eq "education"){
            $newrec{iseducation}=1;
         }
         elsif ($w5applrec->{opmode} eq "approvtest"){
            $newrec{isapprovtest}=1;
         }
         elsif ($w5applrec->{opmode} eq "reference"){
            $newrec{isreference}=1;
         }
         elsif ($w5applrec->{opmode} eq "cbreakdown"){
            $newrec{iscbreakdown}=1;
         }
     }
      if (defined($w5applrec) && $w5applrec->{conumber} ne "" &&
          $w5applrec->{conumber} ne $sysrec->{conumber}){
         $newrec{conumber}=$w5applrec->{conumber};
      }
      if (defined($w5applrec) && $w5applrec->{acinmassignmentgroupid} ne "" &&
          $w5sysrec->{acinmassignmentgroupid} eq ""){
         $newrec{acinmassignmentgroupid}=
             $w5applrec->{acinmassignmentgroupid};
      }

      my $foundsystemclass=0;
      foreach my $v (qw(isapplserver isworkstation isinfrastruct 
                        isprinter isbackupsrv isdatabasesrv 
                        iswebserver ismailserver isrouter 
                        isnetswitch isterminalsrv isnas
                        isclusternode)){
         if ($w5sysrec->{$v}==1){
            $foundsystemclass++;
         }
      }
      if (!$foundsystemclass){
         $newrec{isapplserver}="1"; 
      }
      if ($sys->ValidatedUpdateRecord($w5sysrec,\%newrec,
                                      {id=>\$w5sysrec->{id}})) {
         $identifyby=$w5sysrec->{id};
      }
   }
   else{
      msg(INFO,"try to import new with databoss $curdataboss ...");
      # check 1: Assigmenen Group registered
      #if ($sysrec->{lassignmentid} eq ""){
      #   $self->LastMsg(ERROR,"SystemID has no Assignment Group");
      #   return(undef);
      #}
      # check 2: Assingment Group active
      #my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      #$acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
      #my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisoremail));
      #if (!defined($acgrouprec)){
      #   $self->LastMsg(ERROR,"Can't find Assignment Group of system");
      #   return(undef);
      #}
      # check 3: Supervisor registered
      #if ($acgrouprec->{supervisoremail} eq ""){
      #   $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
      #   return(undef);
      #}
      #}

      # final: do the insert operation
      my $newrec={name=>$sysrec->{id},
                  srcid=>$syssrcid,
                  srcsys=>'AWS',
                  osrelease=>'other',
                  allowifupdate=>1,
                  cistatusid=>4};


      my $user=getModuleObject($self->Config,"base::user");
      if ($self->isDataInputFromUserFrontend()){
         $newrec->{databossid}=$self->getCurrentUserId();
         $curdataboss=$newrec->{databossid};
      }
      else{
         my $importname=$sysrec->{contactemail};
         my @l;
         if ($importname ne ""){
            $user->SetFilter({cistatusid=>[4], emails=>$importname});
            @l=$user->getHashList(qw(ALL));
         }
         if ($#l==0){
            $newrec->{databossid}=$l[0]->{userid};
            $curdataboss=$newrec->{databossid};
         }
         else{
            if ($self->isDataInputFromUserFrontend()){
               $self->LastMsg(ERROR,"can not find databoss contact record");
            }
            else{
               #msg(WARN,"invalid databoss contact rec for ".
               #          $sysrec->{contactemail});
               if (defined($w5applrec) && $w5applrec->{databossid} ne ""){
                  msg(INFO,"using databoss from application ".
                           $w5applrec->{name});
                  $newrec->{databossid}=$w5applrec->{databossid};
                  $curdataboss=$newrec->{databossid};
               }
            }
            if (!defined($curdataboss)){
               if ($self->isDataInputFromUserFrontend()){
                  msg(ERROR,"unable to import system '$sysrec->{name}' ".
                            "without databoss");
               }
               else{
                  my %notifyParam=(
                      mode=>'ERROR',
                      emailbcc=>11634953080001 # hartmut
                  );
                  if ($cloudrec->{supportid} ne ""){
                     $notifyParam{emailcc}=$cloudrec->{supportid};
                  }
                  push(@{$notifyParam{emailcategory}},"SystemImport");
                  push(@{$notifyParam{emailcategory}},"ImportFail");
                  push(@{$notifyParam{emailcategory}},"AWS");
                 
                  $itcloud->NotifyWriteAuthorizedContacts($cloudrec,
                        {},\%notifyParam,
                        {mode=>'ERROR'},sub{
                     my ($subject,$ntext);
                     my $subject="AWS system import error";
                     my $ntext="unable to import '".$sysrec->{name}."' in ".
                               "it inventory - no databoss can be detected";
                     $ntext.="\n";
                     return($subject,$ntext);
                  });
               }
               return();
            }
         }
      }
      if (!exists($newrec->{mandatorid})){
         my @m=$user->getMandatorsOf($newrec->{databossid},
                                     ["write","direct"]);
         if ($#m==-1){
            # no writeable mandator for new databoss
            if ($self->isDataInputFromUserFrontend()){
               $self->LastMsg(ERROR,"can not find a writeable mandator");
               return();
            }
         }
         $newrec->{mandatorid}=$m[0];
      }
      if (!exists($newrec->{mandatorid}) || $newrec->{mandatorid} eq ""){
         if (defined($w5applrec) && $w5applrec->{mandatorid} ne ""){
            $newrec->{mandatorid}=$w5applrec->{mandatorid};
         }
      }


      if ($newrec->{mandatorid} eq ""){
         $self->LastMsg(ERROR,"can't get mandator for import of ".
                        "AWS System $sysrec->{name}");
         #msg(ERROR,sprintf("w5applrec=%s",Dumper($w5applrec)));
         return();
      }
      if (defined($w5applrec)){
         if ($w5applrec->{conumber} ne ""){
            $newrec->{conumber}=$w5applrec->{conumber};
         }
         if ($w5applrec->{acinmassignmentgroupid} ne ""){
            $newrec->{acinmassignmentgroupid}=
                $w5applrec->{acinmassignmentgroupid};
         }
         $newrec->{isapplserver}=1;  # per Default, all is an applicationserver
         if ($w5applrec->{opmode} eq "prod"){
            $newrec->{isprod}=1;
         }
         elsif ($w5applrec->{opmode} eq "test"){
            $newrec->{istest}=1;
         }
         elsif ($w5applrec->{opmode} eq "devel"){
            $newrec->{isdevel}=1;
         }
         elsif ($w5applrec->{opmode} eq "education"){
            $newrec->{iseducation}=1;
         }
         elsif ($w5applrec->{opmode} eq "approvtest"){
            $newrec->{isapprovtest}=1;
         }
         elsif ($w5applrec->{opmode} eq "reference"){
            $newrec->{isreference}=1;
         }
         elsif ($w5applrec->{opmode} eq "cbreakdown"){
            $newrec->{iscbreakdown}=1;
         }
      }
      {
         my $newname=$newrec->{name};
         $sys->ResetFilter();
         $sys->SetFilter({name=>\$newname});
         my ($chkrec)=$sys->getOnlyFirst(qw(id name));
         if (defined($chkrec)){
            $newrec->{name}=$sysrec->{altname};
         }
         if (($newrec->{name}=~m/\s/) || length($newrec->{name})>60){
            $newrec->{name}=$sysrec->{altname};
         }
      }
      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      $sys->initialImportFillup($identifyby,$curdataboss,$w5applrec);
      if ($self->LastMsg()==0){  # do qulity checks only if all is ok
         $sys->ResetFilter();
         $sys->SetFilter({'id'=>\$identifyby});
         my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            my %checksession;
            my $qc=getModuleObject($self->Config,"base::qrule");
            $qc->setParent($sys);
            $checksession{autocorrect}=$rec->{allowifupdate};
            $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec,
                                   \%checksession);
         }
      }
   }
   return($identifyby);
}





1;
