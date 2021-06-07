package tpc::machine;
#  W5Base Framework
#  Copyright (C) 2021  Hartmut Vogler (it@guru.de)
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

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::RecordUrl(),


      new kernel::Field::Id(     
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
            label             =>'Name'),

      new kernel::Field::Text(     
            name              =>'powerState',
            searchable        =>1,
            label             =>'Online-State'),

      new kernel::Field::Text(     
            name              =>'orgId',
            searchable        =>1,
            label             =>'orgId'),

      new kernel::Field::Text(     
            name              =>'projectId',
            searchable        =>1,
            label             =>'projectId'),

      new kernel::Field::Text(     
            name              =>'project',
            vjointo           =>'tpc::project',
            vjoinon           =>['projectId'=>'id'],
            vjoindisp         =>'name',
            label             =>'Project'),

      new kernel::Field::Text(
                name          =>'osrelease',
                label         =>'OS-Release'),

      new kernel::Field::Text(
                name          =>'osclass',
                label         =>'OS-Class'),

      new kernel::Field::Number(
            name              =>'cpucount',
            label             =>'CPU-Count'),

      new kernel::Field::Number(
            name              =>'memory',
            label             =>'Memory',
            unit              =>'MB'),

      new kernel::Field::Text(     
            name              =>'address',
            searchable        =>1,
            label             =>'IP-Address'),

      new kernel::Field::Textarea(     
            name              =>'description',
            searchable        =>1,
            label             =>'Description'),

      new kernel::Field::CDate(
            name              =>'cdate',
            group             =>'source',
            label             =>'Creation-Date',
            dayonly           =>1,
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'createdAt'),

      new kernel::Field::MDate(
            name              =>'mdate',
            group             =>'source',
            label             =>'Modification-Date',
            dayonly           =>1,
            searchable        =>0,  # das tut noch nicht
            dataobjattr       =>'updatedAt'),
   );
   $self->{'data'}=\&DataCollector;
   $self->setDefaultView(qw(id name));
   return($self);
}


sub DataCollector
{
   my $self=shift;
   my $filterset=shift;

   my $Authorization=$self->getVRealizeAuthorizationToken();

   my ($dbclass,$requesttoken)=$self->decodeFilter2Query4vRealize(
      "machines","id",
      $filterset
   );
   my $d=$self->CollectREST(
      dbname=>'TPC',
      requesttoken=>$requesttoken,
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
         map({
             $self->ExternInternTimestampReformat($_,"createdAt");
             $self->ExternInternTimestampReformat($_,"updatedAt");
             $_->{cpucount}=$_->{customProperties}->{cpuCount};
             $_->{memory}=$_->{customProperties}->{memoryInMB};
             $_->{osclass}=$_->{customProperties}->{osType};
             $_->{osrelease}=$_->{customProperties}->{softwareName};
         } @$data);
         return($data);
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
   #printf STDERR ("rawdata=%s\n",Dumper($d));

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
         $self->LastMsg(ERROR,"TPC machine not found");
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

   my $syssrcid=$sysrec->{id};
   my $w5applrec;
   my $w5carec;

   if ($sysrec->{projectId} ne ""){
      msg(INFO,"try to add cloudarea to system ".$sysrec->{name});
      $cloudarea->SetFilter({cloudid=>$cloudrec->{id},
                             srcid=>\$sysrec->{projectId}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec)){
         $w5carec=$w5cloudarearec;
         if ($w5cloudarearec->{cistatusid} ne "4"){
            $self->LastMsg(ERROR,
                           "cloudarea '%s' for  import of '%s' not active",
                           $w5cloudarearec->{fullname},$param->{importname});
            return(undef);
         }
         if ($w5cloudarearec->{cistatusid} eq "4" &&
             $w5cloudarearec->{applid} ne ""){
            msg(INFO,"try to add appl ".$w5cloudarearec->{applid}.
                     " to system ".$sysrec->{name});
            $appl->SetFilter({id=>\$w5cloudarearec->{applid}});
            my ($apprec,$msg)=$appl->getOnlyFirst(qw(ALL));
            if (defined($apprec) &&
                in_array([qw(2 3 4)],$apprec->{cistatusid})){
               $w5applrec=$apprec;
            }
         }
      }
   }
   if (!defined($w5carec)){
      $self->LastMsg(ERROR,
                     "missing cloudarea for TPC import of '%s'",
                     $param->{importname});
      return(undef);
   }
   if (!defined($w5applrec)){
      $self->LastMsg(ERROR,
                     "missing acceptable application for TPC import of '%s'",
                     $param->{importname});
      return(undef);
   }

   my $w5sysrecmodified=0;
   my $sys=getModuleObject($self->Config,"TS::system");
   $sys->ResetFilter();
   $sys->SetFilter({srcsys=>\'TPC',srcid=>$syssrcid});
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   #if (!defined($w5sysrec)){
   #   $sys->ResetFilter();
   #   $sys->SetFilter($flt);
   #   ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   #}




#   if (!defined($w5sysrec)){   # srcid update kandidaten (schneller Redeploy)
#      my @flt;
#      if ($sysrec->{id}=~m/^i-(\S{5,20})$/){
#         push(@flt,{                       # manuell erfasstes i- Instanz
#           name=>$sysrec->{id},
#           srcsys=>'w5base ""'
#         });
#      }
#
#
#      if ($sysrec->{name} ne "" && ($sysrec->{name}=~m/^[a-z0-9_-]{5,40}$/)){
#         push(@flt,{
#           name=>$sysrec->{name},
#           srcsys=>\'TPC',
#           srcid=>'!'.$syssrcid
#         });
#      }
#      if ($sysrec->{ipaddress} ne ""){
#         push(@flt,{
#            ipaddresses=>$sysrec->{ipaddress},
#            srcsys=>\'TPC',
#            srcid=>'!'.$syssrcid
#         });
#      }
#
#
#      $sys->SetFilter(\@flt);
#      my @redepl=$sys->getHashList(qw(mdate cistatusid name 
#                                      srcid srcsys applications));
#
#      my $nredepl=$#redepl+1;
#      msg(INFO,"invantar check for TPC-SystemID: $syssrcid ".
#               "on $nredepl candidates");
#      foreach my $osys (@redepl){   # find best matching redepl candidate
#         my $applok=0;
#         msg(INFO,"check TPC-SystemID: $osys->{srcid} from inventar");
#         if ($osys->{srcid} eq $syssrcid){
#            msg(ERROR,"TPC-SystemID: $osys->{srcid} already in inventar");
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
#            $self->SetFilter({idpath=>\$osys->{srcid}});
#            msg(INFO,"check exist of TPC-SystemID: $osys->{srcid}");
#            my ($chkrec,$msg)=$self->getOnlyFirst(qw(id));
#            if (!defined($chkrec)){
#               msg(INFO,"TPC-SystemID: $osys->{srcid} does not exists anymore");
#               $sysallowed++;
#            }
#         }
#         if ($applok && $sysallowed && $ageok){
#            $sys->ResetFilter();
#            $sys->SetFilter({id=>\$osys->{id}});
#            my ($oldrec,$msg)=$sys->getOnlyFirst(qw(ALL));
#            if (defined($oldrec)){
#               if ($sys->ValidatedUpdateRecord($oldrec,{
#                       srcid=>$syssrcid,srcsys=>'TPC',
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
#   }



   my $identifyby;
   if (defined($w5sysrec)){
      if (uc($w5sysrec->{srcsys}) eq "TPC"){
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
      if ($w5sysrec->{srcsys} ne "TPC" &&
          lc($w5sysrec->{srcsys}) ne "w5base" &&
          $w5sysrec->{srcsys} ne ""){
         $self->LastMsg(ERROR,"name colision - systemname $w5sysrec->{name} ".
                              "already in use. Import failed");
         return(undef);
      }
   }

#printf STDERR ("cloudrec=%s\n",Dumper($cloudrec));
#printf STDERR ("sysrec=%s\n",Dumper($sysrec));
#return(undef);


   my $curdataboss;
#   if (defined($w5sysrec)){
#      $curdataboss=$w5sysrec->{databossid};
#      my %newrec=();
#      my $userid;
#
#      if ($self->isDataInputFromUserFrontend() &&   # only admins (and databoss)
#                                                    # can force
#          !$self->IsMemberOf("admin")) {            # reimport over webrontend
#         $userid=$self->getCurrentUserId();         # if record already exists
#         if ($w5sysrec->{cistatusid}<6 && $w5sysrec->{cistatusid}>2){
#            if ($userid ne $w5sysrec->{databossid}){
#               $self->LastMsg(ERROR,
#                              "reimport only posible by current databoss");
#               if (!$self->isDataInputFromUserFrontend()){
#                  msg(ERROR,"fail to import $sysrec->{name} with ".
#                            "id $sysrec->{id}");
#               }
#               return(undef);
#            }
#         }
#      }
#      if ($w5sysrec->{cistatusid} ne "4"){
#         $newrec{cistatusid}="4";
#      }
#      if ($w5sysrec->{srcsys} ne "TPC"){
#         $newrec{srcsys}="TPC";
#      }
#      if ($w5sysrec->{srcid} ne $sysrec->{id}){
#         $newrec{srcid}=$syssrcid;
#      }
#      if ($w5sysrec->{systemtype} ne "standard"){
#         $newrec{systemtype}="standard";
#      }
#      if ($w5sysrec->{osrelease} eq ""){
#         $newrec{osrelease}="other";
#      }
#      if (defined($w5applrec) &&
#          ($w5sysrec->{isprod}==0) &&
#          ($w5sysrec->{istest}==0) &&
#          ($w5sysrec->{isdevel}==0) &&
#          ($w5sysrec->{iseducation}==0) &&
#          ($w5sysrec->{isapprovtest}==0) &&
#          ($w5sysrec->{isreference}==0) &&
#          ($w5sysrec->{iscbreakdown}==0)) { # alter Datensatz - aber kein opmode
#         if ($w5applrec->{opmode} eq "prod"){   # dann nehmen wir halt die
#            $newrec{isprod}=1;                  # Anwendungsdaten
#         }
#         elsif ($w5applrec->{opmode} eq "test"){
#            $newrec{istest}=1;
#         }
#         elsif ($w5applrec->{opmode} eq "devel"){
#            $newrec{isdevel}=1;
#         }
#         elsif ($w5applrec->{opmode} eq "education"){
#            $newrec{iseducation}=1;
#         }
#         elsif ($w5applrec->{opmode} eq "approvtest"){
#            $newrec{isapprovtest}=1;
#         }
#         elsif ($w5applrec->{opmode} eq "reference"){
#            $newrec{isreference}=1;
#         }
#         elsif ($w5applrec->{opmode} eq "cbreakdown"){
#            $newrec{iscbreakdown}=1;
#         }
#     }
#      if (defined($w5applrec) && $w5applrec->{conumber} ne "" &&
#          $w5applrec->{conumber} ne $sysrec->{conumber}){
#         $newrec{conumber}=$w5applrec->{conumber};
#      }
#      if (defined($w5applrec) && $w5applrec->{acinmassignmentgroupid} ne "" &&
#          $w5sysrec->{acinmassignmentgroupid} eq ""){
#         $newrec{acinmassignmentgroupid}=
#             $w5applrec->{acinmassignmentgroupid};
#      }
#
#      my $foundsystemclass=0;
#      foreach my $v (qw(isapplserver isworkstation isinfrastruct 
#                        isprinter isbackupsrv isdatabasesrv 
#                        iswebserver ismailserver isrouter 
#                        isnetswitch isterminalsrv isnas
#                        isclusternode)){
#         if ($w5sysrec->{$v}==1){
#            $foundsystemclass++;
#         }
#      }
#      if (!$foundsystemclass){
#         $newrec{isapplserver}="1"; 
#      }
#      if ($sys->ValidatedUpdateRecord($w5sysrec,\%newrec,
#                                      {id=>\$w5sysrec->{id}})) {
#         $identifyby=$w5sysrec->{id};
#      }
#   }
#   else{
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
                  srcsys=>'TPC',
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
                  push(@{$notifyParam{emailcategory}},"TPC");
                 
                  $itcloud->NotifyWriteAuthorizedContacts($cloudrec,
                        {},\%notifyParam,
                        {mode=>'ERROR'},sub{
                     my ($subject,$ntext);
                     my $subject="TPC system import error";
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
                        "TPC System $sysrec->{name}");
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
     # {
     #    my $newname=$newrec->{name};
     #    $sys->ResetFilter();
     #    $sys->SetFilter({name=>\$newname});
     #    my ($chkrec)=$sys->getOnlyFirst(qw(id name));
     #    if (defined($chkrec)){
     #       $newrec->{name}=$sysrec->{altname};
     #    }
     #    if (($newrec->{name}=~m/\s/) || length($newrec->{name})>60){
     #       $newrec->{name}=$sysrec->{altname};
     #    }
     # }
      $newrec->{lastqcheck}=NowStamp("en");
      $identifyby=$sys->ValidatedInsertRecord($newrec);
#   }
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






sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}


1;
