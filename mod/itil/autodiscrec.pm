package itil::autodiscrec;
#  W5Base Framework
#  Copyright (C) 2015  Hartmut Vogler (it@guru.de)
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'W5BaseID',
                dataobjattr   =>'autodiscrec.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::TextDrop(
                name          =>'entry',
                label         =>'AutoDiscEntryID',
                vjointo       =>'itil::autodiscent',
                vjoinon       =>['entryid'=>'id'],
                vjoindisp     =>'id'),
                                                  
      new kernel::Field::Link(
                name          =>'fullname',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Fullname',
                dataobjattr   =>"concat(autodiscrec.srcsys,'-',".
                                "autodiscrec.section,'-',".
                                "autodiscrec.scanname".
                                ")"),
                                                  
      new kernel::Field::Link(
                name          =>'entryid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'EntryID',
                dataobjattr   =>'autodiscrec.entryid'),
                                                  
      new kernel::Field::Text(
                name          =>'section',
                sqlorder      =>'desc',
                group         =>'state',
                label         =>'Section',
                dataobjattr   =>'autodiscrec.section'),
                                                  
      new kernel::Field::Text(
                name          =>'state',
                sqlorder      =>'desc',
                group         =>'state',
                label         =>'StateID',   # 1=erfasst ; 10= 1x  ; 20=auto; 100=fail
                dataobjattr   =>'autodiscrec.state'),

      new kernel::Field::Boolean(
                name          =>'processable',
                sqlorder      =>'desc',
                group         =>'state',
                label         =>'processable',
                dataobjattr   =>'autodiscrec.cleartoprocess'),
                                                  
      new kernel::Field::Boolean(
                name          =>'forcesysteminst',
                sqlorder      =>'desc',
                group         =>'state',
                label         =>'force system installed',
                dataobjattr   =>'autodiscrec.forcesysteminst'),
                                                  
      new kernel::Field::Text(
                name          =>'scanname',
                sqlorder      =>'desc',
                htmlwidth     =>'220px',
                group         =>'source',
                label         =>'Scanname',
                dataobjattr   =>'autodiscrec.scanname'),
                                                  
      new kernel::Field::Text(
                name          =>'scanextra1',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scan Extra1',
                dataobjattr   =>'autodiscrec.scanextra1'),
                                                  
      new kernel::Field::Text(
                name          =>'scanextra2',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scan Extra2',
                dataobjattr   =>'autodiscrec.scanextra2'),
                                                  
      new kernel::Field::Text(
                name          =>'scanextra3',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Scan Extra3',
                dataobjattr   =>'autodiscrec.scanextra3'),
                                                  
      new kernel::Field::Text(
                name          =>'discon',
                sqlorder      =>'desc',
                group         =>'source',
                readonly      =>1,
                label         =>'Discovered on',
                dataobjattr   =>'if (system.name is null,'.
                                'swinstance.fullname,system.name)'),
                                                  
      new kernel::Field::Text(
                name          =>'assumed_system',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'assumed system',
                dataobjattr   =>'autodiscrec.assumed_system'),
                                                  
      new kernel::Field::Text(
                name          =>'assumed_ipaddress',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'assumed ipaddress',
                dataobjattr   =>'autodiscrec.assumed_ipaddress'),
                                                  
      new kernel::Field::Number(
                name          =>'misscount',
                sqlorder      =>'desc',
                precision     =>0,
                group         =>'state',
                label         =>'Miss count',
                dataobjattr   =>'autodiscrec.misscount'),

      new kernel::Field::Link(
                name          =>'disc_on_systemid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'discovered on SystemID',
                dataobjattr   =>'autodiscent.discon_system'),

      new kernel::Field::Link(
                name          =>'disc_on_swinstanceid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'discovered on InstanceID',
                dataobjattr   =>'autodiscent.discon_swinstance'),

      new kernel::Field::Text(
                name          =>'lnkto_lnksoftware',
                sqlorder      =>'desc',
                label         =>'approved relation to software id',
                dataobjattr   =>'autodiscrec.lnkto_lnksoftware'),

      new kernel::Field::Text(
                name          =>'lnkto_system',
                sqlorder      =>'desc',
                label         =>'approved relation to system id',
                dataobjattr   =>'autodiscrec.lnkto_system'),


      new kernel::Field::Text(
                name          =>'approve_date',
                sqlorder      =>'desc',
                label         =>'approve date',
                dataobjattr   =>'autodiscrec.approve_date'),

      new kernel::Field::Text(
                name          =>'approve_user',
                sqlorder      =>'desc',
                htmldetail    =>0,
                label         =>'approve user userid',
                dataobjattr   =>'autodiscrec.approve_user'),

      new kernel::Field::Contact(
                name          =>'approve_user_contact',
                label         =>'approve user',
                vjoinon       =>'approve_user'),
                                                  
      new kernel::Field::Link(
                name          =>'engineid',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'EngineID',
                dataobjattr   =>'autodiscent.engine'),

      new kernel::Field::Link(
                name          =>'enginename',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Engine Name',
                dataobjattr   =>'autodiscengine.name'),

      new kernel::Field::Link(
                name          =>'enginefullname',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'Engine Fullname',
                dataobjattr   =>'autodiscengine.fullname'),

      new kernel::Field::Link(
                name          =>'sec_sys_databossid',
                noselect      =>'1',
                dataobjattr   =>'system.databoss'),

      new kernel::Field::Link(
                name          =>'allowifupdate',
                dataobjattr   =>'if (system.allowifupdate is not null,'.
                                'system.allowifupdate,0)'),

      new kernel::Field::Link(
                name          =>'sec_sys_cistatusid',
                noselect      =>'1',
                dataobjattr   =>'system.cistatus'),

      new kernel::Field::Link(
                name          =>'sec_swi_databossid',
                noselect      =>'1',
                dataobjattr   =>'swinstance.databoss'),

      new kernel::Field::Link(
                name          =>'sec_swi_cistatusid',
                noselect      =>'1',
                dataobjattr   =>'swinstance.cistatus'),

      new kernel::Field::Text(
                name          =>'autodischint',
                group         =>'source',
                htmldetail    =>'NotEmpty',
                label         =>'AutoDiscovery Relation',
                container     =>'additional'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>'autodiscrec.additional'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'autodiscrec.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'autodiscrec.modifydate'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'autodiscrec.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'autodiscrec.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'autodiscrec.srcload'),

      new kernel::Field::Date(                     # information last seen
                name          =>'backendload',     # from autodiscovery system
                history       =>0,                 # in backend engine
                htmldetail    =>'NotEmpty',
                group         =>'source',
                label         =>'Backend-Load',
                dataobjattr   =>'autodiscrec.backendload')

   );
   $self->setDefaultView(qw(section scanname scanextra1 scanextra2 discon ));
   $self->setWorktable("autodiscrec");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/autodiscrec.jpg?".$cgi->query_string());
#}


sub getSqlFrom
{
   my $self=shift;
   my $from="autodiscent join autodiscrec ".
                 "on autodiscent.id=autodiscrec.entryid ".
            "join autodiscengine ".
                 "on autodiscent.engine=autodiscengine.id ".
            "left outer join system ".
                 "on autodiscent.discon_system=system.id ".
            "left outer join swinstance ".
                 "on autodiscent.discon_swinstance=swinstance.id";
   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_processable"))){
     Query->Param("search_processable"=>$self->T("yes"));
   }
}






sub isCopyValid
{
   my $self=shift;

   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default state autoimport source));
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return("default","autoimport","state") if ($self->IsMemberOf("admin"));
   return(undef);
}

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}








sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;



   if (effChanged($oldrec,$newrec,"state")){   # statuswechsel auf
      my $s=$newrec->{state}; 
      if ($s eq "10" || $s eq "20"){   # einmalig oder auto
         $self->doTakeAutoDiscData($oldrec,$newrec);
      }
   }
   else{
      if (effChanged($oldrec,$newrec,"scanname") ||
          effChanged($oldrec,$newrec,"scanextra1") ||
          effChanged($oldrec,$newrec,"scanextra2") ||
          effChanged($oldrec,$newrec,"scanextra3")){
         if (defined($oldrec) && $oldrec->{state}>1){
            #printf STDERR ("AutoDiscRec - scandata in autodiscrec '%s' ".
            #               "has been changed!\n",effVal($oldrec,$newrec,"id"));
         }

         if (defined($oldrec) &&
             $oldrec->{state} ne ""){  # Datensatz wurde schonmal behandelt
            #printf STDERR ("Status change on autodiscrec($oldrec->{id})".
            #               "\n      from state='$oldrec->{state}' to ".
            #               "state='$newrec->{state}'.\n");
            if ($oldrec->{state} eq "20" &&
                effVal($oldrec,$newrec,"state") eq "20"){
               #printf STDERR ("AutoDiscRec - do automatic Update!\n");
               #printf STDERR ("AutoDiscRec - old=%s\n",Dumper($oldrec));
               #printf STDERR ("AutoDiscRec - new=%s\n",Dumper($newrec));
               my ($exitcode,$exitmsg)=$self->doTakeAutoDiscData($oldrec,
                                                                 $newrec);
               if ($exitcode){  # automatic update can not be applied
                  # revert adrec to unprocessed - f.e. inst directory errors
                  my $userid=$self->getCurrentUserId();
                  $newrec->{state}=1;
                  $newrec->{lnkto_lnksoftware}=undef;     #link to softwareinst 
                  $newrec->{approve_date}=NowStamp("en"); #seems to be bad
                  $newrec->{approve_user}=$userid;
                  print STDERR "Revert AutoDisc AutoUpdate ".
                               "to unprocessed for adrec:".Dumper($oldrec);
                  print STDERR "Update it with:".Dumper($newrec);
                  #return(0);
               }
            }
            if ($oldrec->{state} eq "10" &&
                (!exists($newrec->{state}) || !defined($newrec->{state}))){
               # Datenänderungen vorhanden, es wurde aber nur einmaliges Update
               # zugelassen. Der Datensatz muß somit wieder als unbehandelt 
               # angesehen werden.
            #   printf STDERR ("AutoDiscRec - reset to unprocessed!\n");
               $newrec->{state}="1";
            }
         }
      }
   }
     
   return(1);
}


sub doTakeAutoDiscData
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $initrelrec=shift;

   my ($exitcode,$exitmsg);

   my $section=effVal($oldrec,$newrec,"section");

   #printf STDERR ("doTakeAutoDiscData handling for autodiscrec '%s'\n",
   #               effVal($oldrec,$newrec,"id"));
   my $systemid=effVal($oldrec,$newrec,"lnkto_system");
   if (defined($initrelrec)){  # in this case, the adrec is not yet linked
      $systemid=$oldrec->{disc_on_systemid};
   }

   my $sysrec;
   my $o=getModuleObject($self->Config,"itil::system");
   if ($systemid ne ""){
      $o->SetFilter({id=>\$systemid});
      my @l=$o->getHashList(qw(ALL));
      if ($#l==0){
         $sysrec=$l[0];
      }
   }
   #######################################################################
   #  SYSTEMNAME Handling  (direct record handling)
   #######################################################################
   if ($section eq "SYSTEMNAME"){


   }
   #######################################################################
   #  SOFTWARE Handling     (related record handling)
   #######################################################################
   elsif ($section eq "SOFTWARE"){   
      if (defined($initrelrec)){  # create a new related record for update
         #printf STDERR ("initrelrec:%s\n",Dumper($initrelrec));
         my $mapsel=$initrelrec->{lnkto_lnksoftware};
         if ($mapsel eq "newSysInst"){
            my $swi=getModuleObject($self->Config,'itil::lnksoftwaresystem');
            my $version=effVal($oldrec,$newrec,"scanextra2");
            my $instpath=effVal($oldrec,$newrec,"scanextra1");
            my $autodischint=effVal($oldrec,$newrec,"autodischint");
            my $softwareid=$initrelrec->{softwareid};
            if ($softwareid ne ""){
               #printf STDERR ("fifi 03 mapsel=$mapsel\n");


               my $alreadyExists=0;
               if (!$alreadyExists){
                  if ($instpath ne ""){
                     $swi->ResetFilter();
                     $swi->SetFilter({
                        systemid=>\$systemid,
                        version=>\$version,
                        softwareid=>\$softwareid,
                        instpath=>\$instpath
                     });
                     my @l=$swi->getHashList(qw(id));
                     if ($#l!=-1){
                        $alreadyExists=1;
                        $swi->LastMsg(ERROR,
                            "multiple software installations with the same ".
                            "version on same path are not allowed");
                     }
                  }
                  else{
                     $swi->ResetFilter();
                     $swi->SetFilter({
                        systemid=>\$systemid,
                        softwareid=>\$softwareid,
                        instpath=>\$instpath
                     });
                     my @l=$swi->getHashList(qw(id));
                     if ($#l!=-1){
                        $alreadyExists=1;
                        $swi->LastMsg(ERROR,
                            "multiple software installations of the same ".
                            "software are only allowed with instpath ".
                            "specification");
                     }
                  }
               }

               if (!$alreadyExists){
                  if ($mapsel=$swi->SecureValidatedInsertRecord({
                         systemid=>$systemid,
                         version=>$version,
                         softwareid=>$softwareid,
                         instpath=>$instpath,
                         autodischint=>$autodischint,
                         quantity=>1
                      })){
                     $exitcode=0;
                  }
                  else{
                     $exitcode=100;
                     ($exitmsg)=$swi->LastMsg();
                  }
               }
               else{
                  ($exitmsg)=$swi->LastMsg();
               }
            }
            else{
               $exitcode=200;
               $exitmsg="no softwareid selection";
            }
         }
         elsif ($mapsel eq "newClustInst"){
            my $swi=getModuleObject($self->Config,
                                    'itil::lnksoftwareitclustsvc');
            my $version=effVal($oldrec,$newrec,"scanextra2");
            my $instpath=effVal($oldrec,$newrec,"scanextra1");
            my $softwareid=$initrelrec->{softwareid};
            my $itclustsvcid=$initrelrec->{itclustsvcid};
            my $autodischint=effVal($oldrec,$newrec,"autodischint");
            if ($softwareid ne ""){
               if ($mapsel=$swi->SecureValidatedInsertRecord({
                      itclustsvcid=>$itclustsvcid,
                      version=>$version,
                      instpath=>$instpath,
                      softwareid=>$softwareid,
                      autodischint=>$autodischint,
                      quantity=>1
                   })){
                  $exitcode=0;
               }
               else{
                  $exitcode=100;
                  ($exitmsg)=$swi->LastMsg();
               }
            }
         }
         else{  # direct relate to an existing installation
            $exitcode=0;
         }
         if ($exitcode eq "0"){
            if ($mapsel eq int($mapsel)){
               my $swi=getModuleObject($self->Config,'itil::lnksoftware');
               $swi->SetFilter({id=>\$mapsel});
               my @l=$swi->getHashList(qw(ALL));
               if ($#l==0){
                  # Achtung: Hier KEIN Update des Installations-Records!
                  #          Das wird über die Validate in autodiscrec
                  #          getriggert!
                  if ($exitcode eq "0"){
                     my $userid=$self->getCurrentUserId();
                     if (!$self->ValidatedUpdateRecord($oldrec,{
                            state=>$newrec->{state},
                            lnkto_lnksoftware=>$mapsel,
                            lnkto_asset=>undef,
                            lnkto_system=>$systemid,
                            approve_date=>NowStamp("en"),
                            approve_user=>$userid
                          },{id=>\$oldrec->{id}})){
                        return(98,"ERROR: fail to link autodiscrecord");
                     }
                     else{
                        $exitcode=0;
                     }
                  }
               }
               else{
                  return(97,"ERROR: could not find desired installation record");
               }
            }
            else{
               return(99,"ERROR: operation incomplete");
            }
         }
      }
      else{  # Update handling
         my $swiid=effVal($oldrec,$newrec,"lnkto_lnksoftware");
         my $swirec;
         my $o=getModuleObject($self->Config,"itil::lnksoftware");
         if ($swiid ne ""){
            $o->SetFilter({id=>\$swiid});
            my @l=$o->getHashList(qw(ALL));
            if ($#l==0){
               $swirec=$l[0];
            }
         }
         if (defined($sysrec) && defined($swirec)){
            my %upd;
            my $scanextra2=effVal($oldrec,$newrec,"scanextra2");
            if (length($swirec->{version})>length($scanextra2)){
               my $chklen=length($scanextra2);
               my $old=substr($swirec->{version},0,$chklen+1);
               if ($old ne $scanextra2."."){
                  $upd{version}=$scanextra2;  # upd da erster Teil ungleich
               }
            }
            else{
               if ($swirec->{version} ne $scanextra2){
                  $upd{version}=$scanextra2;
               }
            }
            my $scanextra1=effVal($oldrec,$newrec,"scanextra1");
            if (trim($swirec->{instpath}) ne $scanextra1){
               $upd{instpath}=trim($scanextra1);
            }
            my $autodischint=effVal($oldrec,$newrec,"autodischint");
            if (trim($swirec->{autodischint}) ne $autodischint){
               $upd{autodischint}=trim($autodischint);
            }
            if (keys(%upd)){
               if ($o->SecureValidatedUpdateRecord($swirec,
                                                   \%upd,{id=>\$swiid})){
                  return(0);
               }
               else{
                  return(1,"ERROR: Installation Update failes");
               }
            }
            return(0);  # nothing needs to be update
         }
      }
   }
   else{
      return(1,"ERROR: inposible section handling");
   }
   return($exitcode,$exitmsg);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $id;
   my $atInsert=0;
   if (!defined($oldrec)){
      $id=$newrec->{id};
      $atInsert=1;
   }
   else{
      $id=$oldrec->{id};
   }
   my $state=effVal($oldrec,$newrec,"state");
   my $processable=effVal($oldrec,$newrec,"processable");
   my $allowifupdate=effVal($oldrec,$newrec,"allowifupdate");

   if ($id ne "" && $atInsert &&
       ($state eq "1" || $state eq "") && $processable eq "1"){
      my $opobj=$self->Clone();
      $opobj->SetFilter({id=>\$id});
      my ($rec)=$opobj->getOnlyFirst(qw(ALL)) ;
      if ($rec->{state} eq "1" && $rec->{allowifupdate}){
         my $admap=$self->getPersistentModuleObject("amap",'itil::autodiscmap');
         $admap->SetFilter({engineid=>\$rec->{engineid},
                            scanname=>"\"".$rec->{scanname}."\""});
         my @admap=$admap->getHashList(qw(probability
                                    software scanname
                                    softwareid engineid));
         if ($#admap==0){
            my $systemid=$rec->{disc_on_systemid};
            my $softwareid=$admap[0]->{softwareid};
            
            my $lnksw=$self->getPersistentModuleObject("lnksw",
                                                   'itil::lnksoftwaresystem');
            $lnksw->SetFilter({systemid=>\$systemid,
                               softwareid=>\$softwareid});
            my @cursw=$lnksw->getHashList(qw(ALL));
            if ($#cursw==-1){
               msg(INFO,"try take AutoDisc Data $rec->{id} insert to software ".
                        "installation");
               my ($exitcode,$exitmsg)=$opobj->doTakeAutoDiscData($rec,{
                     state=>20
                  },
                  { lnkto_lnksoftware=>'newSysInst',
                    softwareid=>$softwareid }
               );
               if ($exitcode!=0){
                  msg(ERROR,"fail to take (ins) AutoDisc Data ".
                            "autodiscrecid=$rec->{id}");
                  msg(ERROR,"exitmsg=$exitmsg");
               }
            }
            if ($#cursw==0){
               my $lnksoftwareid=$cursw[0]->{id};
               msg(INFO,"try take AutoDisc Data $rec->{id} link to software ".
                        "installation $lnksoftwareid");
               my ($exitcode,$exitmsg)=$opobj->doTakeAutoDiscData($rec,{
                     state=>20
                  },
                  { lnkto_lnksoftware=>$lnksoftwareid }
               );
               if ($exitcode!=0){
                  msg(ERROR,"fail to take (link) AutoDisc Data ".
                            "autodiscrecid=$rec->{id}");
                  msg(ERROR,"exitmsg=$exitmsg");
               }
            }
         }
      }

   }
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   if ($oldrec->{lnkto_lnksoftware} ne ""){
      my $allowcleanup=1;
      my $systemid=$oldrec->{lnkto_system};
      if ($systemid ne ""){
         my $sys=getModuleObject($self->Config,"itil::system");
         $sys->SetFilter({id=>\$systemid});
         my ($sysrec)=$sys->getOnlyFirst(qw(allowifupdate));
         if (defined($sysrec)){
            $allowcleanup=0;
            if ($sysrec->{allowifupdate}){
               $allowcleanup=1;
            }
         }
      }
      if ($allowcleanup){
         my $lnks=getModuleObject($self->Config,"itil::lnksoftwaresystem");
         $lnks->SetFilter({id=>\$oldrec->{lnkto_lnksoftware}});
         my @l=$lnks->getHashList(qw(ALL));
         if ($#l==0){
            foreach my $rec (@l){
               $lnks->ValidatedDeleteRecord($rec);
            }
         }
      }
   }

   return(1);
}




sub AutoDiscFormatEntry
{
   my $self=shift;
   my $rec=shift;
   my $adrec=shift;
   my $control=shift;

   my $usertimezone=$ENV{HTTP_FORCE_TZ};
   if (!defined($usertimezone)){
      $usertimezone=$self->UserTimezone();
   }

   my $d="<form id='AutoDiscFORM$adrec->{id}'>";

   my $s1="";
   my $s2="";
   if ($adrec->{state} eq "100"){
      $s1="<s>";
      $s2="</s>";
   }
   elsif ($adrec->{state} ne "1"){
      $s1="<font color='green'>";
      $s2="</font>";
   }
   my $label=$adrec->{scanname};
   if ($adrec->{scanextra2} ne ""){
      $label.="-".$adrec->{scanextra2};
   }
   $d.="<div class='AutoDiscTitle' adid='$adrec->{id}'>".
       "<table padding=0 margin=0>".
       "<tr><td valign=middle>$s1".
       $adrec->{section}.":<b>".$label."</b> @ ";
  
   if ($adrec->{disc_on_systemid} ne ""){
      my $onclick=
         "custopenwin('../../itil/system/ById/$adrec->{disc_on_systemid}',".
         "'normal',600,400,'_blank')";
      $d.="<span class=sublink onclick=\"$onclick\">";
   }
   $d.=$rec->{name};
   if ($adrec->{disc_on_systemid} ne ""){
      $d.="</span>";
   }
   if ($adrec->{section} eq "SOFTWARE"){
      if ($adrec->{scanextra1} ne ""){
         my $dir=$adrec->{scanextra1};
         $dir=~s/[^a-z0-9_\/\\:-]/_/gi;
         my $maxdirlen=30;
         if (length($dir)>$maxdirlen){  # limit lenght of dir to maxdirlen
            my $start=int($maxdirlen/2)-1;
            $dir=substr($dir,0,$start)."...".
                   substr($dir,length($dir)-$start,$start);
         }
         $d.=":".$dir;
      }
   }



   $d.="$s2</td>".
       "<td width=1%>".
       "<img border=0 height=15 class='AutoDiscDetailButton' ".
       "adid='$adrec->{id}' ".
       "title='".$self->T("advanced AutoDiscovery record information")."' ".
       "src=\"../../../public/base/load/details.gif\"></td></tr>".
       "</table>".
       "</div>";

   $d.="<div class='AutoDiscDetail' id=\"AutoDiscDetail$adrec->{id}\">";
   $d.="<p>";
   $d.=$self->T("First detected on AutoDiscoveryEngine");

   my $elabel=$adrec->{enginefullname};
   if ($elabel ne ""){
      $elabel.=" (".$adrec->{enginename}.")";
   }
   else{
      $elabel=$adrec->{enginename};
   }
   $d.=" <b>".$elabel."</b> ";
   $d.=$self->T("at");
   {
      my $fld=$self->getField('cdate');
      my ($dstring)=$fld->FormatedDetail($adrec,"HtmlDetail");
      $d.=" <i>".$dstring."</i>. ";
   }
   if ($adrec->{section} eq "SOFTWARE"){
      $d.=$self->T("The Software was detected as");
      $d.=" <b>\"$adrec->{scanname}\"</b> ";
      $d.=$self->T("in the Version");
      $d.=" <b>\"".$adrec->{scanextra2}."\"</b> ";
      $d.=$self->T("at the installation path");
      $d.=" <b>\"".$adrec->{scanextra1}."\"</b>. ";
      
   }
   $d.="<br>";
   $d.=sprintf($self->T('This information was last seen in %s at'),
               $adrec->{srcsys});
   {
      my $fld=$self->getField('srcload');
      my ($dstring,$tz)=$fld->getFrontendTimeString("HtmlDetail",
                                                $adrec->{srcload},
                                                $usertimezone);
      $d.=" ".$dstring." $tz ";
   }
      
   #$d.=" ($adrec->{srcload} GMT)";
   if ($adrec->{misscount}>0){
      $d.=" ";
      $d.=$self->T("and was");
      $d.=$adrec->{misscount};
      $d.=" ";
      $d.=$self->T("times not refreshed");
   }
   $d.=". ";
   if ($adrec->{backendload} ne ""){
      $d.=sprintf($self->T('The AutoDiscovery System %s has '.
                           'detect this information (scandate) at'),
                           $adrec->{srcsys});
      {
         my $fld=$self->getField('backendload');
         my ($dstring)=$fld->FormatedDetail($adrec,"HtmlDetail");
         $d.=" ".$dstring.". ";
      }
   }
   $d.="</p>";
   if ($self->Config->Param("W5BaseOperationMode") eq "dev"){
      if ($self->IsMemberOf("admin")){
         $d.="<pre>NativeDiscoveryRecord:\n".Dumper($adrec)."</pre>";
      }
   }
   $d.="</div>";

   if ($adrec->{state} eq "1"){
      if ($adrec->{section} eq "SOFTWARE"){
         if (!exists($control->{software})){
            $control->{software}={byid=>{}};
            foreach my $swrec (@{$rec->{software}}){
               $control->{software}->{byid}->{$swrec->{id}}={
                  id=>$swrec->{id},
                  softwareid=>$swrec->{softwareid},
                  typ=>'sys'
               };
            }
            if ($rec->{isclusternode} &&
                $rec->{itclustid} ne ""){ # add clusterservice installations
                my $s=getModuleObject($self->Config,
                                      'itil::lnksoftwareitclustsvc');
                $s->SetFilter({itclustid=>\$rec->{itclustid}});
                foreach my $swrec ($s->getHashList(qw(ALL))){
                   $control->{software}->{byid}->{$swrec->{id}}={
                      id=>$swrec->{id},
                      softwareid=>$swrec->{softwareid},
                      typ=>'clust'
                   };
                }
            }
            my $s=getModuleObject($self->Config,'itil::lnksoftware');
            $s->SetFilter({id=>[keys(%{$control->{software}->{byid}})]});
            foreach my $swrec ($s->getHashList(qw(fullname id 
                                                  itclustsvc system))){
                $control->{software}->{byid}->{$swrec->{id}}->{fullname}=
                   $swrec->{fullname};
                if (defined($swrec->{itclustsvc})){
                   $control->{software}->{byid}->{$swrec->{id}}->{parent}=
                      $swrec->{itclustsvc};
                }
                if (defined($swrec->{system})){
                   $control->{software}->{byid}->{$swrec->{id}}->{parent}=
                      $swrec->{system};
                }
            }
         }
     
         $d.="<div class='AutoDiscMapSel'>";
         $d.=$self->T("Software assign to: ");
         $d.="<select name=SoftwareMapSelector adid='$adrec->{id}' ".
             "class=AutoDiscMapSelector>";
         $d.="<option value=''>- ".$self->T("please select")." -</option>";
         $d.="<option value='newSysInst'>".
             $self->T('new software installation on system')."</option>";
         foreach my $swi (sort({
                            $control->{software}->{byid}->{$a}->{fullname} 
                              <=>
                            $control->{software}->{byid}->{$b}->{fullname} 
                          } keys(%{$control->{software}->{byid}}))){
            if ($control->{software}->{byid}->{$swi}->{typ} eq "sys"){
               my $foundmap=0;
               foreach my $me (@{$control->{admap}}){
                  if ($adrec->{engineid} eq $me->{engineid} &&
                      $adrec->{scanname} eq $me->{scanname} &&
                      $control->{software}->{byid}->{$swi}->{softwareid} eq 
                        $me->{softwareid}){
                     $foundmap++;
                  }
               }
               if ($foundmap){
                  $d.="<option value='$swi'>".
                      $control->{software}->{byid}->{$swi}->{fullname}.
                      "</option>";
               }
            }
         }
         my @clustsvc;
         if (!($adrec->{forcesysteminst})){
            if ($rec->{isclusternode} && $rec->{itclustid} ne "") {
               my $s=getModuleObject($self->Config,'itil::lnkitclustsvc');
               $s->SetFilter({clustid=>\$rec->{itclustid}});
               @clustsvc=$s->getHashList(qw(fullname id));
           
               if ($#clustsvc!=-1) {
                  $d.="<option value=''></option>";
                  $d.="<option value='newClustInst'>".
                     $self->T('new software installation on Cluster-Services').
                     "</option>";
                  my $oldparent=undef;
                  foreach my $swi (sort({
                                 $control->{software}->{byid}->{$a}->{fullname}
                                  <=>
                                 $control->{software}->{byid}->{$b}->{fullname} 
                              } keys(%{$control->{software}->{byid}}))){
                     if ($control->{software}->{byid}->{$swi}->{typ} 
                         eq "clust"){
                        my $foundmap=0;
                        foreach my $me (@{$control->{admap}}){
                           if ($adrec->{engineid} eq $me->{engineid} &&
                               $adrec->{scanname} eq $me->{scanname} &&
                               $control->{software}->{byid}
                                  ->{$swi}->{softwareid} eq $me->{softwareid}){
                              $foundmap++;
                           }
                        }
                        if ($foundmap){
                           if ($oldparent ne 
                               $control->{software}->{byid}->{$swi}->{parent}){
                              if ($oldparent ne ""){
                                 $d.="</optgroup>";
                              }
                              $oldparent=
                               $control->{software}->{byid}->{$swi}->{parent};
                              $d.="<optgroup label=\"".$oldparent."\">";
                           }
                           $d.="<option value='$swi'>".
                               $control->{software}->{byid}->{$swi}->{fullname}.
                               "</option>";
                        }
                     }
                  }
                  if ($oldparent ne ""){
                     $d.="</optgroup>";
                  }
               }
            }
         }
         $d.="</select>";
         $d.="</div>";
     
         $d.="<div class='AutoDiscAddForm' id='AutoDiscAddForm$adrec->{id}'>";
         $d.="<table border=0>";
         if ($#clustsvc!=-1){
            $d.="<tr class='newClustInst'><td width=20%>ClusterService:</td>";
            $d.="<td><select name=itclustsvcid>";
            if ($rec->{itclustid} ne ""){
               foreach my $clustsrec (@clustsvc) {
                  $d.="<option value=\"$clustsrec->{id}\">";
                  $d.="$clustsrec->{fullname}";
                  $d.="</option>";
               }
            }
            $d.="</select></td>";
            $d.="</tr>";
         }
         $d.="<tr><td>Software:</td>";
         $d.="<td><select name=softwareid>";
         my $foundmap=0;
         foreach my $me (@{$control->{admap}}){
            if ($adrec->{engineid} eq $me->{engineid} &&
                $adrec->{scanname} eq $me->{scanname}){
               $d.="<option value='".$me->{softwareid}."'>".
                   $me->{software}."</option>";
               $foundmap++;
            }
         }
         if (!$foundmap){
            return("");
         }
         $d.="</select></td>";
         $d.="</table>";
         $d.="</div>";
      }

      $d.="<div class='AutoDiscOpLine'>";
      $d.="<div class='AutoDiscStatus' id='AutoDiscStatus$adrec->{id}'>";
      $d.="</div>";
      $d.="<div class='AutoDiscButtonBar'>";
      $d.="<input type='image' src='../../itil/load/autodisc_once.jpg' ".
          "title='".$self->T('One time import of data')."' disabled ".
          "adid='$adrec->{id}' id='LoadOnce$adrec->{id}' ".
          "class='LoadOnce AutoDiscButton'>";
      $d.="<input type='image' src='../../itil/load/autodisc_bad.jpg' ".
          "title='".$self->T('Auto discovery data incorrect or unusable')."' ".
          "adid='$adrec->{id}' id='BadScan$adrec->{id}' ".
          "class='BadScan AutoDiscButton'>";
      $d.="<input type='image' src='../../itil/load/autodisc_auto.jpg' ".
        "title='".$self->T('Import data with automatic updates in the future')."' ".
          "adid='$adrec->{id}' disabled id='LoadAuto$adrec->{id}' ".
          "class='LoadAuto AutoDiscButton'>";
      $d.="</div>"; # end of AutoDiscButtonBar
      $d.="</div>"; # end of AutoDiscOpLine
   }
   if ($adrec->{state} ne "1"){
      $d.="<div class='AutoDiscOpLine'>";
      $d.="<div class='AutoDiscStatus' id='AutoDiscStatus$adrec->{id}'>";
      $d.="</div>";
      $d.="<div class='AutoDiscButtonBar' style='width:1%'>";
      $d.="<input type='image' src='../../itil/load/autodisc_reset.jpg' ".
          "title='".$self->T("reset to unprocessed")."' ".
          "adid='$adrec->{id}' id='ResetScan$adrec->{id}' ".
          "class='ResetScan AutoDiscButton'>";
      $d.="</div>"; # end of AutoDiscButtonBar
      $d.="</div>"; # end of AutoDiscOpLine
   }
   $d.="</form>"; 
   return($d);
}


sub getValidWebFunctions
{
   my ($self)=@_;

   my @l=$self->SUPER::getValidWebFunctions();
   push(@l,"AutoDiscProcessor");
   return(@l);
}



sub AutoDiscProcessor
{
   my $self=shift;
   my ($func,$p)=$self->extractFunctionPath();

   my $mode=Query->Param("mode");

   my $exitcode=0;
   my $exitmsg;

   #print STDERR "AutoDiscProcessor:".Query->Dumper();
   my $adid=Query->Param("adid");
   my $adrec;
   if ($adid ne ""){
      $self->SetFilter({id=>\$adid});
      my @adrec=$self->getHashList(qw(ALL));
      if ($#adrec==0){
         $adrec=$adrec[0];
      }
   }


   $exitcode=100;
   $exitmsg="ERROR: no access to '$adid'";

   #
   # Security Check
   #
   #print STDERR Dumper($adrec);

   if (defined($adrec) && $adrec->{disc_on_systemid} ne ""){
      my $sys=getModuleObject($self->Config,"itil::system"); 
      $sys->SetFilter({id=>\$adrec->{disc_on_systemid}});
      my ($sysrec)=$sys->getOnlyFirst(qw(ALL));
      if (defined($sysrec) && $sys->isAutoDiscManagementAllowed($sysrec)){
         $exitcode=0;
         $exitmsg=undef;
      }
   }


   if (!$exitcode){
      my $userid=$self->getCurrentUserId();
      if (!defined($adrec)){
            $exitcode=10;
            $exitmsg=msg(ERROR,"invalid or empty adid reference '$adid'");
      }
      else{
         if ($mode eq "bad"){
            if (!$self->ValidatedUpdateRecord($adrec,
                                            {
                                             state=>100,
                                             lnkto_lnksoftware=>undef,
                                             lnkto_system=>undef,
                                             lnkto_asset=>undef,
                                             approve_date=>NowStamp("en"),
                                             approve_user=>$userid
                                             },
                                            {id=>\$adrec->{id}})){
               $exitcode=98;
               $exitmsg="ERROR: fail to link autodiscrecord";
            }
         }
         elsif ($mode eq "reset"){
            if (!$self->ValidatedUpdateRecord($adrec,
                                            {
                                             state=>'1',
                                             approve_date=>NowStamp("en"),
                                             approve_user=>$userid
                                             },
                                            {id=>\$adrec->{id}})){
               $exitcode=98;
               $exitmsg="ERROR: fail to link autodiscrecord";
            }
         }
         elsif ($mode eq "auto" || $mode eq "once"){
            my $state;
            $state=10 if ($mode eq "once");
            $state=20 if ($mode eq "auto");

            my $ado=getModuleObject($self->Config,"itil::autodiscrec");
            ($exitcode,$exitmsg)=$ado->doTakeAutoDiscData($adrec,{
               state=>$state,
            },{
               itclustsvcid=>scalar(Query->Param("itclustsvcid")),
               softwareid=>scalar(Query->Param("softwareid")),
               lnkto_lnksoftware=>scalar(Query->Param("SoftwareMapSelector"))
            });
         }
         else{
            $exitcode=1;
            $exitmsg=msg(ERROR,
                         "unknown ajax function call to AutoDiscProcessor");
         }
      }
   }

   print $self->HttpHeader("text/xml");
   my $res=hash2xml({
      document=>{
         exitmsg=>$exitmsg,
         exitcode=>$exitcode
      }
   },{header=>1});
   print($res);
   return(0);
}



sub HtmlAutoDiscManager
{
   my $self=shift;
   my $param=shift;
   my $baseflt=shift;

   my $sysobj=getModuleObject($self->Config,"itil::system");
   my $swiobj=getModuleObject($self->Config,"itil::swinstance");

   my $view=$param->{view};
   if (!exists($param->{filterTypes})){
      $param->{filterTypes}=1;
   }
   if (!exists($param->{allowReload})){
      $param->{allowReload}=1;
   }
   my $d="";
   $d.=$self->HttpHeader();
   $d.=$self->HtmlHeader(body=>1,
                           js=>['toolbox.js',
                                'jquery.js',
                               # 'firebug-lite.js',
                                ],
                           style=>['default.css','work.css',
                                   'Output.HtmlDetail.css',
                                   'kernel.App.Web.css',
                                   'public/itil/load/AutoDisc.css']);
   $d.="<div id=HtmlDetail>";
   $d.="<div id='AutoDiscManager'>";
   $d.="<div style=\"margin:3px;margin-left:5px;display:inline\">";
   if ($param->{allowReload}){
      $d.="<img src=\"../../../public/base/load/reload.gif\" ".
          "style=\"float:right;cursor:pointer\" ".
          "xalign=right id=AutoDiscoveryManagerReloadIcon>";
   }
   $d.="<img src=\"../../../public/base/load/help.gif\" ".
       "style=\"float:right;cursor:pointer\" ".
       "xalign=right id=AutoDiscoveryManagerHelpIcon>";

   $d.="<p style=\"line-height:20px\">".
       "<font size=+1><b>AutoDiscoveryManager:</b></font><br>".
       "</p>";
   $d.="</div>";
   $d.="<div style=\"display:none;dth:80%\" ".
       "id=AutoDiscoveryManagerHelp>";
   $d.=$self->getParsedTemplate("tmpl/AutoDiscManager.help",{
      skinbase=>'itil'
   });
   $d.="</div>";

   if ($param->{filterTypes}){
      $d.="<div class='AutoDiscFilterMap'>";
      $d.="<div style=\"line-height:20px;display:inline\">";

      $d.=$self->T("Discovery records").":";
      my $act=" recSelektorAct" if ($view eq "SelUnproc");
      $d.="<span id='SelUnproc' class=\"recSelektor$act\">".
          $self->T("unprocessed")."</span>";
      my $act=" recSelektorAct" if ($view eq "SelBad");
      $d.="<span id='SelBad' class=\"recSelektor$act\">".
          $self->T("marked as bad scan")."</span>";
      my $act=" recSelektorAct" if ($view eq "SelAll");
      $d.="<span id='SelAll' class=\"recSelektor$act\">".
          $self->T("all processed ones")."</span>";
      $d.="</div>";
      $d.="</div>";
   }



   if ($view eq "SelBad"){
     foreach my $r (@$baseflt){
        $r->{state}=\'100';
     }
   }
   elsif ($view eq "SelAll"){
     foreach my $r (@$baseflt){
        $r->{state}='!1';
     }
   }
   else{
     foreach my $r (@$baseflt){
        $r->{state}=\'1';
        $r->{processable}=\'1';  # nur Einträge, die zur Behandlung vorgesehen
     }
   }
   #print STDERR Dumper($baseflt);

   $self->SetFilter($baseflt);
   my @adrec=$self->getHashList(qw(ALL));

   @adrec=sort({
            my $bk=$a->{discon} cmp $b->{discon};
            if ($bk==0){
               $bk=$a->{scanname} cmp $b->{scanname};
            }
            $bk;
         } @adrec);

   my %discnam=();

   foreach my $r (@adrec){
      if ($r->{section} eq "SOFTWARE"){
         my $engine=$r->{engineid};
         my $name=$r->{scanname};
         $discnam{$engine.";".$name}={
            engineid=>\$engine,
            scanname=>\$name
         }
      }
   }
   my @admap;
   my $admap=getModuleObject($self->Config,'itil::autodiscmap');
   if (keys(%discnam)){
      $admap->SetFilter([values(%discnam)]);
      @admap=$admap->getHashList(qw(probability 
                                    software scanname 
                                    softwareid engineid));
      @admap=grep({
         my $bk=0;
         if ($_->{software} ne ""){
            $bk=1;
         }
         $bk;
      } @admap);
   }


   #print STDERR Dumper(\@adrec);
   #print STDERR Dumper(\@admap);



   my %control=(admap=>\@admap,view=>$view);
   my $rec={};
   my $oldrecid;
   foreach my $adrec (@adrec){
      my $recid;
      if (defined($adrec->{disc_on_systemid})){
         $recid="disc_on_systemid:".$adrec->{disc_on_systemid};
      }
      if (defined($adrec->{disc_on_swinstanceid})){
         $recid="disc_on_swinstanceid:".$adrec->{disc_on_swinstanceid};
      }
      if ($oldrecid ne $recid){
         if (defined($adrec->{disc_on_systemid})){
            $sysobj->ResetFilter();
            $sysobj->SetFilter({id=>\$adrec->{disc_on_systemid}});
            my @l=$sysobj->getHashList(qw(ALL));
            $rec=$l[0];
         }
         if (defined($adrec->{disc_on_swinstanceid})){
            $swiobj->ResetFilter();
            $swiobj->SetFilter({id=>\$adrec->{disc_on_swinstanceid}});
            my @l=$swiobj->getHashList(qw(ALL));
            $rec=$l[0];
         }
         $oldrecid=$recid;
         delete($control{software}); # Reset Software-Cache
      }
      my $htmlEnt=$self->AutoDiscFormatEntry($rec,$adrec,\%control);
      if ($htmlEnt ne ""){
         $d.="<div class=AutoDiscRec id='AutoDiscRec".$adrec->{id}."' ".
             "adid='$adrec->{id}'>".$htmlEnt."</div>";
      }
   }
   $d.="<div id='ControlCenterSelectJob'></div>";
   $d.="<pre>";
   #$d.=Dumper(\@adrec);
   $d.="</pre>";
   $d.=<<EOF;
<script language=JavaScript>
function resizeAutoDiscManager(step)
{
   if (step==0){
      \$('#AutoDiscManager').height(5);
      window.setTimeout(function(){resizeAutoDiscManager(10)},1);
   }
   else{
      \$('#AutoDiscManager').height(\$(document).height()-50);
   }
}

\$(document).ready(function(){
   document.title='AutoDiscovery: $rec->{name}';
   resizeAutoDiscManager(0);
});
\$(window).resize(function(){
   resizeAutoDiscManager(0);
});


function setWorking(adid){
   \$('#AutoDiscStatus'+adid).html(
       '<div style="text-align:center">'+
       '<img src="../../base/load/ajaxloader.gif">'+
       '</div>'
   );
}
\$('#AutoDiscoveryManagerHelpIcon').click(function(e){
   e.preventDefault();
   \$('#AutoDiscoveryManagerHelp').slideToggle(200);
   resizeAutoDiscManager();
   return(false);
});

\$('.AutoDiscDetailButton').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   \$('#AutoDiscDetail'+adid).slideToggle(200);
   return(false);
});

\$('#AutoDiscoveryManagerReloadIcon').click(function(e){
   e.preventDefault();
   window.document.location.href=window.document.location.href;
   return(false);
});

\$('.recSelektor').click(function(e){
   var queryParameters = {};
   var queryString=location.search.substring(1);
   var re = /([^&=]+)=([^&]*)/g;
   var m;
 
   while (m = re.exec(queryString)) {
       queryParameters[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
   }
   queryParameters['view']=\$(this).attr('id');
   location.search = \$.param(queryParameters);

   e.preventDefault();
   return(false);
});



\$('.BadScan').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: \$('#AutoDiscFORM'+adid).serialize()+'&adid='+adid+'&mode=bad',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});

\$('.ResetScan').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: 'adid='+adid+'&mode=reset',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});


function handleAjaxCall(adid,data)
{
   var xml=\$(data);
   var exitcode=xml.find('exitcode');
   if (exitcode){
      exitcode=exitcode.text();
   }
   if (exitcode!="0"){
      var exitmsg=xml.find('exitmsg').text();
      exitmsg="<font color=red>"+exitmsg+"</font>";
      \$('#AutoDiscStatus'+adid).html(exitmsg);
   }
   else{
      \$('#AutoDiscRec'+adid).fadeOut();
   }
}
\$('.LoadOnce').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: \$('#AutoDiscFORM'+adid).serialize()+'&adid='+adid+'&mode=once',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});
\$('.LoadAuto').click(function(e){
   e.preventDefault();
   var adid=\$(this).attr('adid');
   if (adid!=""){
      setWorking(adid);
      \$.ajax({
         type: 'POST',
         url: '../../itil/autodiscrec/AutoDiscProcessor',
         data: \$('#AutoDiscFORM'+adid).serialize()+'&adid='+adid+'&mode=auto',
         success: function (data){ handleAjaxCall(adid,data);},
         dataType:'xml'
      });
   }
   return(false);
});
\$('select[name=SoftwareMapSelector]').change(function(e){
   var adid=\$(this).attr('adid');
   if (this.value==""){
      \$('#AutoDiscAddForm'+adid).hide();
      \$('#LoadAuto'+adid).attr('disabled','disabled');
      \$('#LoadOnce'+adid).attr('disabled','disabled');
      \$('#BadScan'+adid).removeAttr('disabled');
   }
   else if (this.value=="newSysInst"){
      \$('#AutoDiscAddForm'+adid).show();
      var rows=\$('div#AutoDiscAddForm'+adid+' table tr');
      rows.filter('.newClustInst').hide();
      \$('#LoadAuto'+adid).removeAttr('disabled');
      \$('#LoadOnce'+adid).removeAttr('disabled');
      \$('#BadScan'+adid).attr('disabled','disabled');
   }
   else if (this.value=="newClustInst"){
      \$('#AutoDiscAddForm'+adid).show();
      var rows=\$('div#AutoDiscAddForm'+adid+' table tr');
      rows.filter('.newClustInst').show();
      \$('#LoadAuto'+adid).removeAttr('disabled');
      \$('#LoadOnce'+adid).removeAttr('disabled');
      \$('#BadScan'+adid).attr('disabled','disabled');
   }
   else{
      \$('#AutoDiscAddForm'+adid).hide();
      \$('#LoadAuto'+adid).removeAttr('disabled');
      \$('#LoadOnce'+adid).removeAttr('disabled');
      \$('#BadScan'+adid).attr('disabled','disabled');
   }

   
});


</script>
EOF
   $d.="</div>";  # End of AutoDiscManager
   $d.="</div>";  # End of HtmlDetail
   $d.=$self->HtmlBottom(body=>1);
   return($d);
}




1;
