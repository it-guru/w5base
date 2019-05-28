package itil::lnkapplapplurl;
#  W5Base Framework
#  Copyright (C) 2017  Hartmut Vogler (it@guru.de)
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
use itil::appl;
@ISA=qw(kernel::App::Web::Listedit itil::lib::Listedit kernel::DataObj::DB);


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
                label         =>'URL ID',
                group         =>'source',
                searchable    =>0,
                dataobjattr   =>'accessurl.id'),
      new kernel::Field::RecordUrl(),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Communication Link',
                readonly      =>1,
                dataobjattr   =>"concat(accessurl.from_fullname,' -> ',".
                                "accessurl.fullname)"),

      new kernel::Field::Text(
                name          =>'fromurl',
                label         =>'from URL',
                dataobjattr   =>'accessurl.from_fullname'),

      new kernel::Field::Text(
                name          =>'tourl',
                label         =>'to URL',
                dataobjattr   =>'accessurl.fullname'),

      new kernel::Field::TextDrop(
                name          =>'lnkapplappl',
                label         =>'Interface',
                vjointo       =>'itil::lnkapplappl',
                vjoinon       =>['lnkapplapplid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'toappl',
                group         =>'urlinfo',
                readonly      =>1,
                label         =>'to Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['toapplid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'network',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'Network',
                vjointo       =>'itil::network',
                vjoinon       =>['networkid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lnkapplapplid',
                label         =>'InterfaceID',
                dataobjattr   =>'accessurl.lnkapplappl'),

      new kernel::Field::Link(
                name          =>'targetisfromappl',
                label         =>'Connect Target is from application',
                dataobjattr   =>'accessurl.target_is_fromappl'),

      new kernel::Field::Link(
                name          =>'networkid',
                label         =>'NetworkID',
                dataobjattr   =>'accessurl.network'),

      new kernel::Field::Link(
                name          =>'toapplid',
                readonly      =>1,
                label         =>'toApplID',
                dataobjattr   =>"if (target_is_fromappl,".
                                "lnkapplappl.fromappl,lnkapplappl.toappl)"),

      new kernel::Field::Link(
                name          =>'notmultiple',
                label         =>'notmultiple',
                dataobjattr   =>'accessurl.notmultiple'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'accessurl.comments'),

      new kernel::Field::Boolean(
                name          =>'is_interface',
                group         =>'class',
                label         =>'Accessed by interface applications',
                dataobjattr   =>'accessurl.is_interface'),

      new kernel::Field::Text(
                name          =>'fromscheme',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'from Scheme',
                dataobjattr   =>'accessurl.from_scheme'),
                                                   
      new kernel::Field::Text(
                name          =>'fromhostname',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'from Hostname',
                dataobjattr   =>'accessurl.from_hostname'),

      new kernel::Field::Number(
                name          =>'fromipport',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'from IP-Port',
                dataobjattr   =>'accessurl.from_ipport'),


      new kernel::Field::Text(
                name          =>'toscheme',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'to Scheme',
                dataobjattr   =>'accessurl.scheme'),
                                                   
      new kernel::Field::Text(
                name          =>'tohostname',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'to Hostname',
                dataobjattr   =>'accessurl.hostname'),

      new kernel::Field::Number(
                name          =>'toipport',
                group         =>'urlinfo',
                readonly      =>1,
                htmldetail    =>'NotEmpty',
                label         =>'to IP-Port',
                dataobjattr   =>'accessurl.ipport'),

      new kernel::Field::Text(
                name          =>'asfirewallrule',
                group         =>'urlinfo',
                readonly      =>1,
                label         =>'as firewall rule',
                dataobjattr   =>"concat(".
                    "if (accessurl.from_hostname='' or ".
                        "accessurl.from_hostname is null,'ANY',".
                        "accessurl.from_hostname),".
                    "':',".
                    "if (accessurl.from_ipport='' or ".
                        "accessurl.from_ipport is null,'ANY',".
                        "accessurl.from_ipport),".
                    "' -> ',".
                    "if (accessurl.hostname='' or ".
                        "accessurl.hostname is null,'ANY',".
                        "accessurl.hostname),".
                    "':',".
                    "if (accessurl.ipport='' or ".
                        "accessurl.ipport is null,'ANY',".
                        "accessurl.ipport),".
                    " '   ACCEPT')"),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'accessurl.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'accessurl.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'accessurl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'accessurl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'accessurl.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"accessurl.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(accessurl.id,35,'0')"),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'accessurl.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'accessurl.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'accessurl.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'accessurl.realeditor'),

      new kernel::Field::Link(
                name          =>'secfromapplsectarget',
                noselect      =>'1',
                dataobjattr   =>'fromappllnkcontact.target'),

      new kernel::Field::Link(
                name          =>'secfromapplsectargetid',
                noselect      =>'1',
                dataobjattr   =>'fromappllnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secfromapplsecroles',
                noselect      =>'1',
                dataobjattr   =>'fromappllnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'secfromapplmandatorid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.mandator'),

      new kernel::Field::Link(
                name          =>'secfromapplbusinessteamid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.businessteam'),

      new kernel::Field::Link(
                name          =>'secfromappltsmid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.tsm'),

      new kernel::Field::Link(
                name          =>'secfromappltsm2id',
                noselect      =>'1',
                dataobjattr   =>'fromappl.tsm2'),

      new kernel::Field::Link(
                name          =>'secfromapplopmid',
                noselect      =>'1',
                dataobjattr   =>'fromappl.opm'),

      new kernel::Field::Link(
                name          =>'secfromapplopm2id',
                noselect      =>'1',
                dataobjattr   =>'fromappl.opm2')
   );
   $self->setDefaultView(qw(fullname network lnkapplappl cdate));
   $self->setWorktable("accessurl");
   return($self);
}

sub getSqlFrom
{
   my $self=shift;
   my $from="accessurl ".
            "left outer join lnkapplappl ".
            "on accessurl.lnkapplappl=lnkapplappl.id ".

            "left outer join appl fromappl ".
            "on lnkapplappl.fromappl=fromappl.id ".

            "left outer join lnkcontact fromappllnkcontact ".
            "on fromappllnkcontact.parentobj='itil::appl' ".
            "and fromappl.id=fromappllnkcontact.refid ".

            "left outer join costcenter fromapplcostcenter ".
            "on fromappl.conumber=fromapplcostcenter.name ";

   return($from);
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_applcistatus"))){
     Query->Param("search_applcistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @addflt;
      $self->itil::appl::addApplicationSecureFilter(['secfromappl'],\@addflt);
      push(@flt,\@addflt);
   }

   return($self->SetFilter(@flt));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   my $uri;

   my $tourl=effVal($oldrec,$newrec,"tourl");

   if ($tourl eq "" || lc($tourl) eq "any"){
      $tourl="ANY";
   }
   $tourl=~s/[\s*]*//;
   $uri={host=>undef,port=>undef,scheme=>undef};
   if ($tourl ne "ANY"){
      $uri=$self->URLValidate($tourl);
      if ($uri->{error}) {
         $self->LastMsg(ERROR,$uri->{error});
         return(undef);
      }
   }
   if (effVal($oldrec,$newrec,"tohostname") ne $uri->{host}){
         $newrec->{tohostname}=$uri->{host};
      }
   if (effVal($oldrec,$newrec,"toipport") ne $uri->{port}){
         $newrec->{toipport}=$uri->{port};
   }
   if (effVal($oldrec,$newrec,"toscheme") ne $uri->{scheme}){
      $newrec->{toscheme}=$uri->{scheme};
   }
   if (effVal($oldrec,$newrec,"tourl") ne $tourl){
      $newrec->{tourl}=$tourl;
   }



   my $fromurl=effVal($oldrec,$newrec,"fromurl");
   if ($fromurl eq "" || lc($fromurl) eq "any"){
      $fromurl="ANY";
   }
   $fromurl=~s/[\s*]*//;
   $uri={host=>undef,port=>undef,scheme=>undef};
   if ($fromurl ne "ANY"){
      $uri=$self->URLValidate($fromurl);
      if ($uri->{error}) {
         $self->LastMsg(ERROR,$uri->{error});
         return(undef);
      }
   }


   if (effVal($oldrec,$newrec,"fromhostname") ne $uri->{host}){
         $newrec->{fromhostname}=$uri->{host};
      }
   if (effVal($oldrec,$newrec,"fromipport") ne $uri->{port}){
         $newrec->{fromipport}=$uri->{port};
   }
   if (effVal($oldrec,$newrec,"fromscheme") ne $uri->{scheme}){
      $newrec->{fromscheme}=$uri->{scheme};
   }
   if (effVal($oldrec,$newrec,"fromurl") ne $fromurl){
      $newrec->{fromurl}=$fromurl;
   }

   if ($fromurl eq $tourl){
      $self->LastMsg(ERROR,"from url and to url an not be the same");
      return(undef);
   }


   if (!defined($oldrec)){
      $newrec->{notmultiple}=undef;
   }

   if (effVal($oldrec,$newrec,"is_interface") ne "1"){
      $newrec->{is_interface}="1";
   }


   my $lnkapplapplid=effVal($oldrec,$newrec,"lnkapplapplid");
   my $o=getModuleObject($self->Config,"itil::lnkapplappl");
   $o->SetFilter({id=>\$lnkapplapplid});
   my ($lnkrec)=$o->getOnlyFirst(qw(ALL));
   if (!defined($lnkrec)){
      $self->LastMsg(ERROR,"invalid interface record");
      return(undef);
   }
   #
   # Need to check write access  !!!   TODO
   #


   my $srchost=effVal($oldrec,$newrec,"fromhostname");
   my $dsthost=effVal($oldrec,$newrec,"tohostname");

   #printf STDERR ("check comm from $srchost to $dsthost");
   my $ip=getModuleObject($self->Config,"itil::ipaddress");

   my (@srclist,@dstlist);

   my $TargetIsFromAppl=0;
   my $networkid;

   if ($srchost ne ""){  # check from as ip
      $ip->ResetFilter();
      $ip->SetFilter([
         {name=>\$srchost,cistatusid=>"<6"},
         {dnsname=>\$srchost,cistatusid=>"<6"}
      ]);
      foreach my $iprec ($ip->getHashList(qw(name networkid applications))){
         my $al=$iprec->{applications};
         $al=[$al] if (ref($al) ne "ARRAY");
         foreach my $arec (@$al){
            if ($arec->{applid} eq $lnkrec->{fromapplid}){
               push(@srclist,{
                  ip=>$iprec->{name},
                  networkid=>$iprec->{networkid}
               });
            }
            if ($arec->{applid} eq $lnkrec->{toapplid}){
               push(@srclist,{
                  ip=>$iprec->{name},
                  networkid=>$iprec->{networkid}
               });
            }
         }
      }
   }

   if ($dsthost ne ""){  # check to as ip
      $ip->ResetFilter();
      $ip->SetFilter([
          {name=>\$dsthost,cistatusid=>"<6"},
          {dnsname=>\$dsthost,cistatusid=>"<6"}
      ]);
      foreach my $iprec ($ip->getHashList(qw(name networkid applications))){
         my $al=$iprec->{applications};
         $al=[$al] if (ref($al) ne "ARRAY");
         foreach my $arec (@$al){
            if ($arec->{applid} eq $lnkrec->{fromapplid}){
               push(@dstlist,{
                  ip=>$iprec->{name},
                  networkid=>$iprec->{networkid},
                  TargetIsFromAppl=>1
               });
               $TargetIsFromAppl=1;
            }
            if ($arec->{applid} eq $lnkrec->{toapplid}){
               push(@dstlist,{
                  ip=>$iprec->{name},
                  networkid=>$iprec->{networkid}
               });
            }
         }
      }
   }

   if ($#srclist==-1 || $#dstlist==-1){
      my $urls=getModuleObject($self->Config,"itil::lnkapplurl");
      if ($#srclist==-1){
         $urls->ResetFilter();
         $urls->SetFilter({name=>$fromurl,lnkapplapplid=>\undef});
         foreach my $urlrec ($urls->getHashList(qw(name applid networkid))){
            if ($urlrec->{applid} eq $lnkrec->{toapplid}){
               push(@srclist,{
                  url=>$urlrec->{name},
                  networkid=>$urlrec->{networkid}
               });
            }
            if ($urlrec->{applid} eq $lnkrec->{fromapplid}){
               push(@srclist,{
                  url=>$urlrec->{name},
                  networkid=>$urlrec->{networkid}
               });
            }
         }
      }
      if ($#dstlist==-1){
         $urls->ResetFilter();
         $urls->SetFilter({name=>$tourl,lnkapplapplid=>\undef});
         foreach my $urlrec ($urls->getHashList(qw(name applid networkid))){
            if ($urlrec->{applid} eq $lnkrec->{toapplid}){
               push(@dstlist,{
                  url=>$urlrec->{name},
                  networkid=>$urlrec->{networkid}
               });
            }
            if ($urlrec->{applid} eq $lnkrec->{fromapplid}){
               push(@dstlist,{
                  url=>$urlrec->{name},
                  networkid=>$urlrec->{networkid},
                  TargetIsFromAppl=>1,
               });
               $TargetIsFromAppl=1;
            }
         }
      }
   }
      
     


   if ($#dstlist!=-1){
      $networkid=$dstlist[0]->{networkid};
   }
   else{
      if ($#srclist!=-1){
         $networkid=$srclist[0]->{networkid};
      }
   }
   if (effVal($oldrec,$newrec,"networkid") ne $networkid){
      $newrec->{networkid}=$networkid;
   }

   #printf STDERR ("fifi networkid=$networkid\nsrchost %s\ndsthost %s\n",
   #               Dumper(\@srclist),
   #               Dumper(\@dstlist)
   #);

   if ($fromurl ne "ANY"){  # if fromurl = ANY, it will treat as ANY IP of 
                            # from application
      if ($#srclist==-1 && $#dstlist==-1){
         $self->LastMsg(ERROR,
                  "can't assign any interface application to from or to URL");
         return(undef);
      }
   }

   my $targetisfromappl=effVal($oldrec,$newrec,"targetisfromappl");

   if (effVal($oldrec,$newrec,"targetisfromappl") ne $TargetIsFromAppl){
      $newrec->{targetisfromappl}=$TargetIsFromAppl;
   }

   if ($self->isDataInputFromUserFrontend()){
      if (!$self->isWriteOnApplApplValid($lnkapplapplid)){
         $self->LastMsg(ERROR,"no write access");
         return(0);
      }
   }

   return(1);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default urlinfo source));
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));

   my @l=qw(header default urlinfo history source history);

   return(@l);
}

sub initSqlWhere
{
   my $self=shift;
   my $mode=shift;
   return(undef) if ($mode eq "delete");
   return(undef) if ($mode eq "insert");
   return(undef) if ($mode eq "update");
   my $where="accessurl.lnkapplappl is not null";
   return($where);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   return(qw(default)) if (!defined($rec));

   my $lnkapplapplid=defined($rec) ? $rec->{lnkapplapplid} : undef;

   my $wrok=$self->isWriteOnApplApplValid($lnkapplapplid);

   return("default") if ($wrok);
   return(undef);
}


sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}




sub isWriteOnApplApplValid
{
   my $self=shift;
   my $lnkapplapplid=shift;

   my $userid=$self->getCurrentUserId();
   my $wrok=0;
   $wrok=1 if (!defined($lnkapplapplid));
   if ($self->itil::lib::Listedit::isWriteOnApplApplValid($lnkapplapplid,
         "default")){
      $wrok=1;
   }
   return($wrok);
}


1;
