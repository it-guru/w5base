package itil::swinstancerule;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
use kernel::DataObj::DB;
use kernel::Field;
use itil::lib::Listedit;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=6 if (!defined($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'RuleID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'swinstancerule.id'),
                                                 
      new kernel::Field::Interface(
                name          =>'fullname',
                label         =>'Rule full label',
                htmlwidth     =>'400px',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>"if (swinstancerule.ruletype='RESLNK',".
                                "concat(swinstancerule.rulelabel,':',".
                                "appl.name),swinstancerule.rulelabel)"),
       
      new kernel::Field::Text(
                name          =>'rulelabel',
                label         =>'Rule label',
                htmlwidth     =>'400px',
                htmldetail    =>0,
                readonly      =>1,
                dataobjattr   =>'swinstancerule.rulelabel'),
       
      new kernel::Field::TextDrop(
                name          =>'swinstance',
                htmlwidth     =>'100px',
                label         =>'Software-Instance',
                vjointo       =>'itil::swinstance',
                vjoinon       =>['swinstanceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'swinstanceid',
                label         =>'Software-InstanceID',
                dataobjattr   =>'swinstancerule.swinstance'),

      new kernel::Field::Select(
                name          =>'ruletype',
                selectfix     =>1,
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                jsonchanged   =>\&getOnChangedScript,
                label         =>'Rule Type',
                value         =>['FWAPP','FWSYS','IPCLIACL',
                                 'CFRULE','RESLNK','FREE'],
                dataobjattr   =>'swinstancerule.ruletype'),

      new kernel::Field::Interface(
                name          =>'rawruletype',
                label         =>'Rule Type (Raw)',
                selectfix     =>1,
                readonly      =>1,
                dataobjattr   =>'swinstancerule.ruletype'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                group         =>'default',
                label         =>'Rule-State',
                vjoineditbase =>{id=>[qw(2 4 5 6)]},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),


      new kernel::Field::Link(
                name          =>'cistatusid',
                group         =>'default',
                label         =>'Rule-StateID',
                dataobjattr   =>'swinstancerule.cistatus'),

      new kernel::Field::MultiDst(
                name          =>'boundcomponent',
                htmlwidth     =>'200',
                htmleditwidth =>'200',
                selectivetyp  =>1,
                group         =>'link',
                dst           =>['itil::appl'=>'name',
                                 'itil::system'=>'name'
                ],
                vjoineditbase =>[{'cistatusid'=>"<5"},
                                 {'cistatusid'=>"<5"}
                ],
                label         =>'bound target Component',
                altnamestore  =>'parentname',
                dsttypfield   =>'parentobj',
                dstidfield    =>'refid'),

      new kernel::Field::Select(
                name          =>'policy',
                selectfix     =>1,
                label         =>'Policy',
                group         =>['ipfw'],
                value         =>['ALLOW','DENY'],
                dataobjattr   =>'swinstancerule.policy'),

      new kernel::Field::Text(
                name          =>'fromaddr',
                group         =>'ipfw',
                label         =>'from IP-Address',
                dataobjattr   =>'swinstancerule.srcaddr'),

      new kernel::Field::Text(
                name          =>'fromport',
                group         =>'ipfw',
                htmleditwidth =>'80px',
                label         =>'from IP-Port',
                dataobjattr   =>'swinstancerule.srcport'),

      new kernel::Field::Text(
                name          =>'toaddr',
                group         =>'ipfw',
                label         =>'to IP-Address',
                dataobjattr   =>'swinstancerule.dstaddr'),

      new kernel::Field::Text(
                name          =>'toport',
                group         =>'ipfw',
                htmleditwidth =>'80px',
                label         =>'to IP-Port',
                dataobjattr   =>'swinstancerule.dstport'),

      new kernel::Field::Text(
                name          =>'clifromaddr',
                group         =>'ipcliacl',
                label         =>'Client IP-Address',
                dataobjattr   =>'swinstancerule.srcaddr'),

      new kernel::Field::Text(
                name          =>'clitoport',
                group         =>'ipcliacl',
                htmleditwidth =>'80px',
                label         =>'Instance IP-Port',
                dataobjattr   =>'swinstancerule.dstport'),

      new kernel::Field::Text(
                name          =>'varname',
                group         =>'varval',
                label         =>'Variable-Name',
                dataobjattr   =>'swinstancerule.varname'),

      new kernel::Field::Text(
                name          =>'varval',
                group         =>'varval',
                label         =>'Variable-Value',
                dataobjattr   =>'swinstancerule.varval'),

      new kernel::Field::Text(
                name          =>'resname',
                group         =>'res',
                label         =>'Resource-Name',
                dataobjattr   =>'swinstancerule.varval'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>['ipfw','varval','ipcliacl'],
                label         =>'Comments',
                searchable    =>0,
                dataobjattr   =>'swinstancerule.comments'),

      new kernel::Field::Textarea(
                name          =>'freetext',
                group         =>'free',
                label         =>'Free text',
                searchable    =>0,
                dataobjattr   =>'swinstancerule.comments'),

      new kernel::Field::TextDrop(
                name          =>'system',
                group         =>'system',
                label         =>'System',
                searchable    =>0,
                vjointo       =>'itil::system',
                vjoinon       =>['refid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::TextDrop(
                name          =>'application',
                group         =>'appl',
                searchable    =>0,
                label         =>'Application',
                vjointo       =>'itil::appl',
                vjoinon       =>['refid'=>'id'],
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoindisp     =>'name'),

      new kernel::Field::Interface(
                name          =>'refid',
                selectfix     =>1,
                dataobjattr   =>'swinstancerule.refid'),

      new kernel::Field::Link(
                name          =>'parentname',
                group         =>'link',
                dataobjattr   =>'swinstancerule.parentname'),

      new kernel::Field::Link(
                name          =>'parentobj',
                selectfix     =>1,
                group         =>'link',
                dataobjattr   =>'swinstancerule.parentobj'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'swinstancerule.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'swinstancerule.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'swinstancerule.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'swinstancerule.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'swinstancerule.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::Link(
                name          =>'databossid',
                selectfix     =>1,
                dataobjattr   =>'swinstance.databoss'),

      new kernel::Field::Link(
                name          =>'swteamid',
                selectfix     =>1,
                dataobjattr   =>'swinstance.swteam'),

      new kernel::Field::Link(
                name          =>'admid',
                selectfix     =>1,
                dataobjattr   =>'swinstance.adm'),

      new kernel::Field::Link(
                name          =>'adm2id',
                selectfix     =>1,
                dataobjattr   =>'swinstance.adm2'),

      new kernel::Field::Link(
                name          =>'appl_databoss',
                selectfix     =>1,
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::Link(
                name          =>'appl_tsmid',
                selectfix     =>1,
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'appl_tsm2id',
                selectfix     =>1,
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Link(
                name          =>'appl_opmid',
                selectfix     =>1,
                dataobjattr   =>'appl.opm'),

      new kernel::Field::Link(
                name          =>'appl_opm2id',
                selectfix     =>1,
                dataobjattr   =>'appl.opm2'),

      new kernel::Field::Link(
                name          =>'system_databoss',
                selectfix     =>1,
                dataobjattr   =>'system.databoss'),

      new kernel::Field::Link(
                name          =>'system_admid',
                selectfix     =>1,
                dataobjattr   =>'system.adm'),

      new kernel::Field::Link(
                name          =>'system_adm2id',
                selectfix     =>1,
                dataobjattr   =>'system.adm2'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"swinstancerule.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(swinstancerule.id,35,'0')"),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-System',
                dataobjattr   =>'swinstancerule.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                sqlorder      =>'NONE',
                label         =>'Source-Id',
                dataobjattr   =>'swinstancerule.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'swinstancerule.srcload')
                                                   
   );
   $self->{history}={
      update=>[
         'local'
      ]
   };
   $self->setDefaultView(qw(swinstance fullname cistatus mdate));

   $self->setWorktable("swinstancerule");
   return($self);
}


sub getOnChangedScript
{
   my $self=shift;
   my $app=$self->getParent();

   my $d=<<EOF;
if (mode=="onchange"){
   document.forms[0].submit();
}
EOF
   return($d);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="$worktable";

   $from.=" left outer join swinstance on ".
          " swinstancerule.swinstance=swinstance.id ".
          " left outer join lnkcontact ".
          "on lnkcontact.parentobj='itil::swinstance' ".
          "and swinstance.id=lnkcontact.refid ".
          "left outer join appl on ".
          "$worktable.parentobj='itil::appl' and $worktable.refid=appl.id ".
          "left outer join system on ".
          "$worktable.parentobj='itil::system' and $worktable.refid=system.id ";

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf([qw(admin w5base.itil.swinstance.read 
                              w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
            [orgRoles(),qw(RMember RCFManager RCFManager2 
                           RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
                    {databossid=>\$userid},
                    {admid=>$userid},       {adm2id=>$userid},
                    {swteamid=>\@grpids},
                    {appl_databoss=>\$userid},
                    {appl_tsmid=>$userid},       {appl_tsm2id=>$userid},
                    {appl_opmid=>$userid},       {appl_opm2id=>$userid},
                    {system_databoss=>\$userid},
                    {system_admid=>$userid},       {system_adm2id=>$userid},
                   );
      }
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

   my $userid=$self->getCurrentUserId();
   my $ruletype=effVal($oldrec,$newrec,"ruletype");
   my $rulelabel;
   if ($ruletype eq "FWAPP"){
      $rulelabel=sprintf("FW-A:%s:%s:%s -> %s:%s",
                effVal($oldrec,$newrec,"policy"),
                effVal($oldrec,$newrec,"fromaddr"),
                effVal($oldrec,$newrec,"fromport"),
                effVal($oldrec,$newrec,"toaddr"),
                effVal($oldrec,$newrec,"toport"));
      if (effVal($oldrec,$newrec,"parentobj") ne "itil::appl"){
         $newrec->{parentobj}="itil::appl";
      }
   }
   elsif ($ruletype eq "FWSYS"){
      $rulelabel=sprintf("FW-S:%s:%s:%s -> %s:%s",
                effVal($oldrec,$newrec,"policy"),
                effVal($oldrec,$newrec,"fromaddr"),
                effVal($oldrec,$newrec,"fromport"),
                effVal($oldrec,$newrec,"toaddr"),
                effVal($oldrec,$newrec,"toport"));
      if (effVal($oldrec,$newrec,"parentobj") ne "itil::system"){
         $newrec->{parentobj}="itil::system";
      }
   }
   elsif ($ruletype eq "IPCLIACL"){
      $rulelabel=sprintf("IPACL:%s:%s",
                effVal($oldrec,$newrec,"clifromaddr"),
                effVal($oldrec,$newrec,"clitoport"));
   }
   elsif ($ruletype eq "RESLNK"){
      $rulelabel=sprintf("RES:%s",
                effVal($oldrec,$newrec,"resname"));
      if (effVal($oldrec,$newrec,"parentobj") ne "itil::appl"){
         $newrec->{parentobj}="itil::appl";
      }
      my $resname=effVal($oldrec,$newrec,"resname");
      if (($resname eq "") || ($resname=~m/\s/) ||
          haveSpecialChar($resname)){
         $self->LastMsg(ERROR,"invalid or missing resource name");
         return(0);
      }
   }
   elsif ($ruletype eq "CFRULE"){
      $rulelabel=sprintf("VAR:%s=%s",
                effVal($oldrec,$newrec,"varname"),
                effVal($oldrec,$newrec,"varval"));
   }
   elsif ($ruletype eq "FREE"){
      my $s=effVal($oldrec,$newrec,"freetext");
      $s=~s/[^a-z0-9 ]+/ /gi;
      $s=limitlen($s,70,1);
      $rulelabel=sprintf("FREE:%s",$s);
   }

   if ($rulelabel ne effVal($oldrec,$newrec,"rulelabel")){
      $newrec->{rulelabel}=$rulelabel;
   }

   my $swinstanceid=effVal($oldrec,$newrec,"swinstanceid");

   if ($swinstanceid eq ""){
      $self->LastMsg(ERROR,"no valid software instance specified");
      return(0);
   }
   my $writeok=0;
   if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
       $swinstanceid,"swinstancerules")){
      $writeok++;
   }


   my @addrchk;
   my @portchk;
   if ($ruletype=~m/^FW/){ 
      @addrchk=qw(toaddr fromaddr);
      @portchk=qw(toport fromport);
   }
   if ($ruletype=~m/^IPCLIACL$/){ 
      @addrchk=qw(clifromaddr);
      @portchk=qw(clitoport);
   }
   foreach my $n (@portchk){
      if (exists($newrec->{$n})){
         if ($newrec->{$n} ne "any"){
            my @l=split(/\s*,\s*/,$newrec->{$n});
            foreach my $chk (@l){
               if (my ($v1,$v2)=$chk=~m/^(\d+)-(\d+)$/){
                  if ($v1>=$v2 || 
                      $v1<=0 || $v1>65535 ||
                      $v2<=0 || $v2>65535){
                     $self->LastMsg(ERROR,"invalid port range '%s'",$chk);
                     return(0);
                  }
               }
               elsif ($chk=~m/^\d+$/){
                  if (!($chk>=1 && $chk<=65535)){
                     $self->LastMsg(ERROR,"invalid port '%s'",$chk);
                     return(0);
                  }
               }
               else{
                  $self->LastMsg(ERROR,"invalid port '%s'",$chk."($n)");
                  return(0);
               }
            }
         }
      }
   }
   foreach my $n (@addrchk){
      if (exists($newrec->{$n})){
         if ($newrec->{$n} ne "any"){
            my $chk=$newrec->{$n};
            my ($o1,$o2,$o3,$o4,$net)=
               $chk=~m/^(\d+)\.(\d+)\.(\d+)\.(\d+)\/(\d+)$/;
            if ($o1 eq "" || $o1>255 || 
                $o2 eq "" || $o2>255 ||
                $o3 eq "" || $o3>255 ||
                $o4 eq "" || $o4>255 ||
                $net  eq "" || $net>32 ||
                (!defined($oldrec) && effVal($oldrec,$newrec,$n) eq "")){
               $self->LastMsg(ERROR,"invalid address '%s'",$chk);
               return(0);
            }
         }
      }
   }
   if ($ruletype eq "FWSYS"){ 
      # check write access to logical system
      my $sysid=effVal($oldrec,$newrec,"refid");
      if ($sysid ne ""){
         my $o=getModuleObject($self->Config,"itil::system");
         $o->SetFilter({id=>\$sysid});
         my ($srec,$msg)=$o->getOnlyFirst(qw(name databossid 
                                             admid adm2id));
         if (defined($srec)){
            if (!defined($oldrec) ||
                $srec->{name} ne $oldrec->{parentname}){
               $newrec->{parentname}=$srec->{name};
            }
            
            if (((!defined($oldrec) || $oldrec->{cistatusid}==2) &&
                 effVal($oldrec,$newrec,"cistatusid")==2) &&
                ( $srec->{databossid}==$userid ||
                  $srec->{admid}==$userid ||
                  $srec->{adm2id}==$userid )){
               $writeok++
            }
         }
      }
   }
   elsif ($ruletype eq "FWAPP"){ 
      # check write access to logical system
      my $appid=effVal($oldrec,$newrec,"refid");
      if ($appid ne ""){
         my $o=getModuleObject($self->Config,"itil::appl");
         $o->SetFilter({id=>\$appid});
         my ($arec,$msg)=$o->getOnlyFirst(qw(name databossid tsmid
                                             tsm2id opmid opm2id));
         if (defined($arec)){
            if (!defined($oldrec) ||
                $arec->{name} ne $oldrec->{parentname}){
               $newrec->{parentname}=$arec->{name};
            }
            if (((!defined($oldrec) || $oldrec->{cistatusid}==2) &&
                 (effVal($oldrec,$newrec,"cistatusid")==2)) &&
                ($arec->{databossid}==$userid ||
                 $arec->{tsmid}==$userid ||
                 $arec->{tsm2id}==$userid ||
                 $arec->{opmid}==$userid ||
                 $arec->{opm2id}==$userid)){
               $writeok++
            }
         }
      }
   }
   if (!$writeok){
      my $oldswiid=defined($oldrec) ? 
                   $oldrec->{swinstanceid}:$newrec->{swinstanceid};
      my $newswiid=effVal($oldrec,$newrec,"swinstanceid");

      if ($oldswiid eq $newswiid){
         if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
             $newswiid,"default")){
            $writeok++;
         }
      }
      else{
         if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
             $newswiid,"default") &&
             $self->itil::lib::Listedit::isWriteOnSwinstanceValid(
             $oldswiid,"default")){
            $writeok++;
         }
      }
   }
   if (!$writeok){
      $self->LastMsg(ERROR,"no necessary write access");
      return(0);
   }



   return(1);
}




sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=qw(default header);
   my $ruletype=Query->Param("Formated_ruletype");
   $ruletype="FWAPP" if ($ruletype eq "" && Query->Param("FUNC") eq "New");


   push(@l,"system","ipfw") if (!defined($rec) && $ruletype eq "FWSYS");
   push(@l,"appl","ipfw")   if (!defined($rec) && $ruletype eq "FWAPP");
   push(@l,"varval")        if (!defined($rec) && $ruletype eq "CFRULE");
   push(@l,"free")          if (!defined($rec) && $ruletype eq "FREE");
   push(@l,"appl","res")    if (!defined($rec) && $ruletype eq "RESLNK");
   push(@l,"ipcliacl")      if (!defined($rec) && $ruletype eq "IPCLIACL");
  
   return(@l) if (!defined($rec));

   $ruletype=$rec->{ruletype};

   push(@l,"system","ipfw","link") if ($ruletype eq "FWSYS" && defined($rec));
   push(@l,"appl","ipfw","link") if ($ruletype eq "FWAPP" && defined($rec));
   push(@l,"varval")             if ($ruletype eq "CFRULE" && defined($rec));
   push(@l,"free")               if ($ruletype eq "FREE"   && defined($rec));
   push(@l,"ipcliacl")           if ($ruletype eq "IPCLIACL" && defined($rec));
   push(@l,"appl","res")         if ($ruletype eq "RESLNK" && defined($rec));
   push(@l,"source") if (defined($rec));

   if (defined($rec)){
      if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
          $rec->{swinstanceid},"default")){
         push(@l,"history");
      }
   }
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $rw=0;

   if (!defined($rec)){
      $rw++;
   }
   else{
      if ($rec->{cistatusid}==2){  # check access by bound item
         my $userid=$self->getCurrentUserId();
         foreach my $name (qw(appl_databoss appl_tsmid appl_tsm2id
                              appl_opmid appl_opm2id 
                              system_databoss system_admid system_adm2id)){
            if ($userid==$rec->{$name}){
               $rw++;
               last;
            }
         }
      }
      if (!$rw){
         my $swid=$rec->{swinstanceid};
         if ($self->itil::lib::Listedit::isWriteOnSwinstanceValid(
             $swid,"default")){
            $rw++;
         }
      }

   }

   return(qw(default ipfw appl system varval res ipcliacl free)) if ($rw);
   return(undef);
}


sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ipfw ipcliacl res 
             varval free link system appl source));
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $userid=$self->getCurrentUserId();
   my $ruletype=effVal($oldrec,$newrec,"ruletype");
   my $swinstanceid=effVal($oldrec,$newrec,"swinstanceid");
   my $notify;



   my ($applrefrec,$sysrefrec,$swirec);
   if ($ruletype eq "FWAPP"){
      my $o=getModuleObject($self->Config,"itil::appl");
      my $refid=effVal($oldrec,$newrec,"refid");
      $o->SetFilter({id=>\$refid});
      ($applrefrec)=$o->getOnlyFirst(qw(name tsmid tsm2id opmid opm2id 
                                            databossid));
   }
   if ($ruletype eq "FWSYS"){
      my $o=getModuleObject($self->Config,"itil::system");
      my $refid=effVal($oldrec,$newrec,"refid");
      $o->SetFilter({id=>\$refid});
      ($sysrefrec)=$o->getOnlyFirst(qw(name admid adm2id databossid));
   }
   if ((defined($applrefrec) || defined($sysrefrec)) && $swinstanceid ne ""){
      my $o=getModuleObject($self->Config,"itil::swinstance");
      $o->SetFilter({id=>\$swinstanceid});
      ($swirec)=$o->getOnlyFirst(qw(rulelabel name admid adm2id databossid));
   }
   return(1) if ((!defined($sysrefrec) && !defined($applrefrec)) || 
                  !defined($swirec));


   if ((!defined($oldrec)) &&
       effVal($oldrec,$newrec,"cistatusid")==2){
      # Notify Instanz Admin 
      # CC Instanz Admin2
      # From current user
      # bcc current user
      # Subject: new request entry
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      my $emailto;
      my $emailcc=[];
      if ($swirec->{admid} ne ""){
         $emailto=$swirec->{admid};
         push(@$emailcc,$swirec->{adm2id})  if ($swirec->{adm2id} ne "");
      }
      else{
         if ($swirec->{adm2id} ne ""){
            $emailto=$swirec->{adm2id};
         }
      }
      $ENV{HTTP_FORCE_LANGUAGE}=$self->getLangFromEmailto($emailto);
      $wfa->Notify("INFO",
            $self->T("software instance rule activation request"),
            sprintf($self->T("MSG001"),$swirec->{rulelabel}),
            emailfrom=>[$userid],
            emailto=>[$swirec->{admid}],
            emailcc=>[$swirec->{adm2id}],
            emailbcc=>[$userid],
            dataobj=>$self->Self,
            dataobjid=>effVal($oldrec,$newrec,"id"));
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }

   if (defined($oldrec) &&
       $oldrec->{cistatusid}!=4 &&
       effVal($oldrec,$newrec,"cistatusid")==4){
      # Notify TSM/Admin
      # CC TSM2 OPM OPM2 Admin2
      # From current user
      # Subject: activation of entry 
      my $emailto;
      my $emailcc=[];
      $emailto=$sysrefrec->{admid}          if ($sysrefrec->{admid} ne "");
      $emailto=$applrefrec->{tsmid}         if ($applrefrec->{tsmid} ne "");
      push(@$emailcc,$applrefrec->{opmid})  if ($applrefrec->{opmid} ne "");
      push(@$emailcc,$applrefrec->{opm2id}) if ($applrefrec->{opm2id} ne "");
      push(@$emailcc,$applrefrec->{tsm2id}) if ($applrefrec->{tsm2id} ne "");
      push(@$emailcc,$sysrefrec->{adm2id})  if ($sysrefrec->{adm2id} ne "");
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      $ENV{HTTP_FORCE_LANGUAGE}=$self->getLangFromEmailto($emailto);
      $wfa->Notify("INFO",
            $self->T("activation of software instance rule entry"),
            sprintf($self->T("MSG002"),effVal($oldrec,$newrec,"rulelabel")),
            emailfrom=>[$userid],
            emailto=>$emailto,
            emailcc=>$emailcc,
            emailbcc=>[$userid],
            dataobj=>$self->Self,
            dataobjid=>effVal($oldrec,$newrec,"id"));
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   if (defined($oldrec) &&
       $oldrec->{cistatusid}==4 &&
       effVal($oldrec,$newrec,"cistatusid")>4){
      # Notify Creator
      # CC TSM Admin TSM2 OPM OPM2 Admin2
      # From current user
      # Subject: deactivation of entry 
      my $emailto;
      my $emailcc=[];
      $emailto=$applrefrec->{tsmid}         if ($applrefrec->{tsmid} ne "");
      push(@$emailcc,$sysrefrec->{admid})   if ($sysrefrec->{admid} ne "");
      push(@$emailcc,$applrefrec->{opmid})  if ($applrefrec->{opmid} ne "");
      push(@$emailcc,$applrefrec->{opm2id}) if ($applrefrec->{opm2id} ne "");
      push(@$emailcc,$applrefrec->{tsm2id}) if ($applrefrec->{tsm2id} ne "");
      push(@$emailcc,$sysrefrec->{adm2id})  if ($sysrefrec->{adm2id} ne "");
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      $ENV{HTTP_FORCE_LANGUAGE}=$self->getLangFromEmailto($emailto);
      $wfa->Notify("INFO",
            $self->T("deactivation of software instance rule entry"),
            $self->T("MSG003"),
            emailfrom=>[$userid],
            emailto=>$emailto,
            emailcc=>$emailcc,
            emailbcc=>[$userid],
            dataobj=>$self->Self,
            dataobjid=>effVal($oldrec,$newrec,"id"));
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   if (defined($oldrec) &&
       $oldrec->{cistatusid}<4 &&
       effVal($oldrec,$newrec,"cistatusid")>4){
      # Notify TSM/Admin
      # CC TSM2 OPM OPM2 Admin2
      # From current user
      # Subject: reject entry 

      my $emailto;
      my $emailcc=[];
      my $creatorid=effVal($oldrec,$newrec,"creator");
      $emailto=$creatorid                   if ($creatorid ne "");
      push(@$emailcc,$applrefrec->{tsmid})  if ($applrefrec->{tsmid} ne "");
      push(@$emailcc,$sysrefrec->{admid})   if ($sysrefrec->{admid} ne "");
      push(@$emailcc,$applrefrec->{opmid})  if ($applrefrec->{opmid} ne "");
      push(@$emailcc,$applrefrec->{opm2id}) if ($applrefrec->{opm2id} ne "");
      push(@$emailcc,$applrefrec->{tsm2id}) if ($applrefrec->{tsm2id} ne "");
      push(@$emailcc,$sysrefrec->{adm2id})  if ($sysrefrec->{adm2id} ne "");
      my $wfa=getModuleObject($self->Config,"base::workflowaction");
      $ENV{HTTP_FORCE_LANGUAGE}=$self->getLangFromEmailto($emailto);
      $wfa->Notify("INFO",
            $self->T("reject of rule request entry"),
            sprintf($self->T("MSG004"),effVal($oldrec,$newrec,"rulelabel")),
            emailfrom=>[$userid],
            emailto=>$emailto,
            emailcc=>$emailcc,
            emailbcc=>[$userid],
            dataobj=>$self->Self,
            dataobjid=>effVal($oldrec,$newrec,"id"));
      delete($ENV{HTTP_FORCE_LANGUAGE});
   }
   return(1);
}

sub getLangFromEmailto
{
   my $self=shift;
   my $userid=shift;

   if ($userid ne ""){
      my $u=getModuleObject($self->Config,"base::user");
      $u->SetFilter({userid=>\$userid});
      my ($urec)=$u->getOnlyFirst(qw(lastlang lang));
      if (defined($urec)){
         if ($urec->{lastlang} ne ""){
            return($urec->{lastlang});
         }
         if ($urec->{lang} ne ""){
            return($urec->{lang});
         }
      }
   }
   return("en");
}







sub isCopyValid
{
   my $self=shift;

   return(1);
}












1;
